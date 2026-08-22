"""로컬 전용 프로젝트 콘솔 서버.

이 저장소의 .claude/, docs/, pubspec.yaml, git 상태를 읽어 대시보드로 보여준다.
외부 패키지 의존성 없이 표준 라이브러리만 사용한다.

실행: python tools/cc_console/server.py
접속: http://localhost:8787
"""
from __future__ import annotations

import hmac
import json
import os
import re
import secrets
import shutil
import subprocess
import threading
import time
from http.cookies import SimpleCookie
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

ROOT = Path(__file__).resolve().parents[2]
CLAUDE_DIR = ROOT / ".claude"
STATIC_DIR = Path(__file__).resolve().parent / "static"
APPS = ["guardian", "senior"]

AUTH_TOKEN = secrets.token_urlsafe(16)
AUTH_COOKIE_NAME = "cc_token"

ANALYZE_TIMEOUT_SEC = 600
TEST_TIMEOUT_SEC = 600
_sdk_cache: dict[str, str | None] = {}


class AsyncTask:
    """flutter analyze/test처럼 오래 걸리는 명령을 백그라운드 스레드에서 한 번에 하나씩만 실행하고,
    현재 상태를 스레드 안전하게 조회할 수 있게 하는 공용 러너."""

    def __init__(self, initial_state: dict):
        self._lock = threading.Lock()
        self._state = dict(initial_state)

    def snapshot(self) -> dict:
        with self._lock:
            return dict(self._state)

    def finish(self, **fields) -> None:
        with self._lock:
            self._state.update(fields)

    def start(self, target) -> dict:
        with self._lock:
            if self._state["status"] == "running" or not self._state["available"]:
                return dict(self._state)
            self._state["status"] = "running"
        threading.Thread(target=target, daemon=True).start()
        return self.snapshot()


_analyze_task = AsyncTask({
    "available": shutil.which("flutter") is not None,
    "status": "idle",  # idle | running | done | error
    "errorCount": None,
    "warningCount": None,
    "infoCount": None,
    "summary": None,
    "ranAt": None,
    "durationSec": None,
})
_test_task = AsyncTask({
    "available": shutil.which("flutter") is not None,
    "status": "idle",  # idle | running | done | error
    "passCount": None,
    "failCount": None,
    "perApp": None,
    "summary": None,
    "ranAt": None,
    "durationSec": None,
})

KNOWN_CONNECTORS = {
    "supabase_flutter": ("Supabase", "DB / Auth 백엔드"),
    "firebase_core": ("Firebase Core", "Firebase 초기화"),
    "firebase_messaging": ("Firebase Cloud Messaging", "푸시 알림"),
    "firebase_analytics": ("Firebase Analytics", "사용자 분석"),
    "dio": ("Dio", "공유 HTTP 클라이언트"),
    "flutter_dotenv": ("flutter_dotenv", "환경변수(.env) 로딩"),
}

CONNECTOR_ENV_KEYS: dict[str, list[str]] = {
    "supabase_flutter": ["SUPABASE_URL", "SUPABASE_ANON_KEY"],
    "firebase_core": [],
    "firebase_messaging": [],
    "firebase_analytics": [],
    "dio": [],
    "flutter_dotenv": [],
}


def read_text(path: Path, limit: int | None = None) -> str | None:
    if not path.is_file():
        return None
    text = path.read_text(encoding="utf-8", errors="replace")
    if limit is not None and len(text) > limit:
        text = text[:limit] + "\n\n... (생략)"
    return text


def run_git(args: list[str], cwd: Path = ROOT) -> str:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=cwd,
            capture_output=True,
            encoding="utf-8",
            errors="replace",
            timeout=5,
        )
        return result.stdout.strip() if result.returncode == 0 else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def worktree_branch(worktree_dir: Path) -> str:
    """워크트리의 .git 파일 → gitdir/HEAD를 직접 읽어 서브프로세스 스폰 없이 브랜치명을 구한다.
    실패하면 git rev-parse로 폴백한다."""
    try:
        git_file = worktree_dir / ".git"
        content = git_file.read_text(encoding="utf-8").strip()
        if content.startswith("gitdir:"):
            gitdir = Path(content.split(":", 1)[1].strip())
            head_content = (gitdir / "HEAD").read_text(encoding="utf-8").strip()
            if head_content.startswith("ref:"):
                return head_content.split(":", 1)[1].strip().rsplit("/", 1)[-1]
            return head_content[:12]  # detached HEAD
    except OSError:
        pass
    return run_git(["rev-parse", "--abbrev-ref", "HEAD"], cwd=worktree_dir) or "(알 수 없음)"


def run_toolchain(args: list[str], cwd: Path = ROOT, timeout: int = 30) -> subprocess.CompletedProcess | None:
    """flutter/dart는 Windows에서 .BAT라 cmd 경유가 필요하다."""
    try:
        cmd = ["cmd", "/c", *args] if os.name == "nt" else args
        return subprocess.run(
            cmd, cwd=cwd, capture_output=True, encoding="utf-8", errors="replace", timeout=timeout,
        )
    except (OSError, subprocess.SubprocessError):
        return None


def get_sdk_versions() -> dict:
    if not _sdk_cache:
        for key, args in (("flutter", ["flutter", "--version"]), ("dart", ["dart", "--version"])):
            result = run_toolchain(args, timeout=20)
            text = (result.stdout or "").strip() if result and result.returncode == 0 else ""
            _sdk_cache[key] = text.splitlines()[0].strip() if text else None
    return dict(_sdk_cache)


def run_flutter_analyze() -> None:
    start = time.time()
    result = run_toolchain(["flutter", "analyze", "--no-pub"], timeout=ANALYZE_TIMEOUT_SEC)
    duration = round(time.time() - start, 1)
    if result is None:
        _analyze_task.finish(status="error", summary="실행 실패 (flutter 명령을 찾을 수 없거나 시간 초과)", ranAt=time.time(), durationSec=duration)
        return
    output = (result.stdout or "") + (result.stderr or "")
    error_count = len(re.findall(r"^\s*error\s+-", output, re.MULTILINE))
    warning_count = len(re.findall(r"^\s*warning\s+-", output, re.MULTILINE))
    info_count = len(re.findall(r"^\s*info\s+-", output, re.MULTILINE))
    summary_match = re.search(r"^(No issues found!.*|\d+ issues? found\..*)$", output, re.MULTILINE)
    if summary_match:
        summary = summary_match.group(0).strip()
    else:
        stripped = output.strip()
        summary = stripped.splitlines()[-1] if stripped else "완료"
    _analyze_task.finish(
        status="done", errorCount=error_count, warningCount=warning_count, infoCount=info_count,
        summary=summary, ranAt=time.time(), durationSec=duration,
    )


def start_flutter_analyze() -> dict:
    return _analyze_task.start(run_flutter_analyze)


def parse_test_summary(output: str) -> tuple[int, int]:
    match = re.search(r"\+(\d+)(?:\s+-(\d+))?:\s*(?:All tests passed!|Some tests failed\.)", output)
    if not match:
        return 0, 0
    passed = int(match.group(1))
    failed = int(match.group(2)) if match.group(2) else 0
    return passed, failed


def run_flutter_test() -> None:
    start = time.time()
    per_app: dict[str, dict] = {}
    total_pass = 0
    total_fail = 0
    any_ran = False
    for app in APPS:
        app_dir = ROOT / "apps" / app
        if not (app_dir / "test").is_dir():
            per_app[app] = {"pass": 0, "fail": 0, "note": "test 디렉터리 없음"}
            continue
        result = run_toolchain(["flutter", "test", "--no-pub", "--reporter", "compact"], cwd=app_dir, timeout=TEST_TIMEOUT_SEC)
        if result is None:
            per_app[app] = {"pass": 0, "fail": 0, "note": "실행 실패"}
            continue
        output = (result.stdout or "") + (result.stderr or "")
        passed, failed = parse_test_summary(output)
        per_app[app] = {"pass": passed, "fail": failed}
        total_pass += passed
        total_fail += failed
        any_ran = True
    duration = round(time.time() - start, 1)
    status = "done" if any_ran else "error"
    summary = f"통과 {total_pass}건 · 실패 {total_fail}건" if any_ran else "실행 실패 (테스트를 하나도 돌리지 못함)"
    _test_task.finish(
        status=status, passCount=total_pass, failCount=total_fail, perApp=per_app,
        summary=summary, ranAt=time.time(), durationSec=duration,
    )


def start_flutter_test() -> dict:
    return _test_task.start(run_flutter_test)


def parse_frontmatter(text: str) -> dict:
    match = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
    if not match:
        return {}
    data = {}
    for line in match.group(1).splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            data[key.strip()] = value.strip()
    return data


def parse_pubspec(path: Path) -> dict:
    text = read_text(path)
    if text is None:
        return {}
    lines = text.splitlines()
    info = {"name": "", "description": "", "version": "", "dependencies": []}
    in_deps = False
    desc_block = False
    for raw in lines:
        if desc_block:
            if raw.startswith("  ") and raw.strip():
                info["description"] += " " + raw.strip()
                continue
            desc_block = False
        if raw.startswith("name:"):
            info["name"] = raw.split(":", 1)[1].strip().strip('"')
        elif raw.startswith("version:"):
            info["version"] = raw.split(":", 1)[1].strip().strip('"')
        elif raw.startswith("description:"):
            value = raw.split(":", 1)[1].strip()
            if value == ">":
                desc_block = True
            else:
                info["description"] = value.strip('"')
        elif raw.strip() == "dependencies:":
            in_deps = True
            continue
        elif in_deps:
            if raw.startswith("  ") and not raw.startswith("   ") and ":" in raw:
                key = raw.strip().split(":", 1)[0].strip()
                if key and key != "flutter":
                    info["dependencies"].append(key)
            elif raw and not raw.startswith(" "):
                in_deps = False
    info["description"] = info["description"].strip()
    return info


def get_brief(root_status: str) -> dict:
    branch = run_git(["rev-parse", "--abbrev-ref", "HEAD"]) or "(알 수 없음)"
    last_commit = run_git(["log", "-1", "--pretty=format:%h %s (%ar)"]) or "커밋 없음"
    uncommitted = len([l for l in root_status.splitlines() if l.strip()])
    skills = sorted((CLAUDE_DIR / "skills").glob("*/SKILL.md")) if (CLAUDE_DIR / "skills").is_dir() else []
    rules = sorted((CLAUDE_DIR / "rules").glob("*.md")) if (CLAUDE_DIR / "rules").is_dir() else []
    workspace_pubspec = parse_pubspec(ROOT / "pubspec.yaml")
    test_state = _test_task.snapshot()
    return {
        "branch": branch,
        "lastCommit": last_commit,
        "uncommitted": uncommitted,
        "skillCount": len(skills),
        "ruleCount": len(rules) + 1,  # +CLAUDE.md
        "appCount": len(APPS),
        "packageName": workspace_pubspec.get("name") or "ondam",
        "test": test_state,
    }


def get_instructions() -> list[dict]:
    items = []
    claude_md = CLAUDE_DIR / "CLAUDE.md"
    if claude_md.is_file():
        items.append({
            "title": "CLAUDE.md",
            "path": ".claude/CLAUDE.md",
            "content": read_text(claude_md, limit=20000),
        })
    rules_dir = CLAUDE_DIR / "rules"
    if rules_dir.is_dir():
        for f in sorted(rules_dir.glob("*.md")):
            items.append({
                "title": f"rules/{f.name}",
                "path": f".claude/rules/{f.name}",
                "content": read_text(f, limit=20000),
            })
    return items


def get_skills() -> list[dict]:
    items = []
    skills_dir = CLAUDE_DIR / "skills"
    if not skills_dir.is_dir():
        return items
    for f in sorted(skills_dir.glob("*/SKILL.md")):
        text = read_text(f) or ""
        meta = parse_frontmatter(text)
        items.append({
            "name": meta.get("name", f.parent.name),
            "description": meta.get("description", ""),
        })
    return items


def read_env_keys(path: Path) -> dict[str, str]:
    keys: dict[str, str] = {}
    if not path.is_file():
        return keys
    for line in path.read_text(encoding="utf-8-sig", errors="replace").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        keys[key.strip()] = value.strip()
    return keys


def connector_status(app: str, package: str) -> tuple[str, list[str]]:
    required = CONNECTOR_ENV_KEYS.get(package, [])
    if not required:
        return "n_a", []
    env_path = ROOT / "apps" / app / ".env"
    if not env_path.is_file():
        return "no_env_file", []
    values = read_env_keys(env_path)
    missing = [k for k in required if not values.get(k)]
    return ("missing_keys", missing) if missing else ("configured", [])


def get_connectors() -> list[dict]:
    items = []
    for app in APPS:
        info = parse_pubspec(ROOT / "apps" / app / "pubspec.yaml")
        for dep in info.get("dependencies", []):
            if dep in KNOWN_CONNECTORS:
                label, note = KNOWN_CONNECTORS[dep]
                status, missing_keys = connector_status(app, dep)
                items.append({
                    "app": app, "package": dep, "label": label, "note": note,
                    "status": status, "missingKeys": missing_keys,
                })
    return items


def get_hooks() -> dict:
    settings_path = CLAUDE_DIR / "settings.json"
    if not settings_path.is_file():
        return {"configured": False, "items": []}
    try:
        data = json.loads(settings_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"configured": False, "items": []}
    hooks = data.get("hooks", {})
    if not hooks:
        return {"configured": False, "items": []}
    items = []
    for event, groups in hooks.items():
        if not isinstance(groups, list):
            continue
        for group in groups:
            matcher = group.get("matcher", "") if isinstance(group, dict) else ""
            for entry in (group.get("hooks", []) if isinstance(group, dict) else []):
                if not isinstance(entry, dict) or entry.get("type") != "command":
                    continue
                items.append({
                    "event": event,
                    "matcher": matcher,
                    "command": entry.get("command", ""),
                    "timeout": entry.get("timeout"),
                })
    return {"configured": bool(items), "items": items}


def infer_app(name: str, branch: str) -> str | None:
    haystack = f"{name} {branch}".lower()
    for app in APPS:
        if app in haystack:
            return app
    return None


def infer_focus(paths: list[str]) -> str | None:
    feature_counts: dict[str, int] = {}
    top_counts: dict[str, int] = {}
    for p in paths:
        m = re.search(r"features/([^/]+)/", p)
        if m:
            feature_counts[m.group(1)] = feature_counts.get(m.group(1), 0) + 1
            continue
        top = p.split("/", 1)[0]
        if top:
            top_counts[top] = top_counts.get(top, 0) + 1
    if feature_counts:
        return max(feature_counts, key=feature_counts.get)
    if top_counts:
        return max(top_counts, key=top_counts.get)
    return None


def get_agents() -> list[dict]:
    worktrees_dir = CLAUDE_DIR / "worktrees"
    if not worktrees_dir.is_dir():
        return []
    items = []
    for d in sorted(worktrees_dir.iterdir()):
        if not d.is_dir():
            continue
        branch = worktree_branch(d)
        status_out = run_git(["status", "--porcelain"], cwd=d)
        changed_paths = [l[3:] for l in status_out.splitlines() if l.strip()]
        uncommitted = len(changed_paths)
        last_commit = run_git(["log", "-1", "--pretty=format:%ar"], cwd=d) or "커밋 없음"
        items.append({
            "name": d.name,
            "branch": branch,
            "mtime": d.stat().st_mtime,
            "uncommitted": uncommitted,
            "lastCommit": last_commit,
            "status": "working" if uncommitted else "idle",
            "app": infer_app(d.name, branch),
            "focus": infer_focus(changed_paths) if uncommitted else None,
        })
    return items


def get_plugins() -> list[dict]:
    workspace_text = read_text(ROOT / "pubspec.yaml") or ""
    match = re.search(r"^workspace:\s*\n((?:  - .+\n?)+)", workspace_text, re.MULTILINE)
    paths = []
    if match:
        paths = [l.strip("- ").strip() for l in match.group(1).splitlines() if l.strip()]
    items = []
    for rel in paths:
        info = parse_pubspec(ROOT / rel / "pubspec.yaml")
        items.append({
            "path": rel,
            "name": info.get("name") or rel,
            "description": info.get("description", ""),
            "depCount": len(info.get("dependencies", [])),
        })
    return items


def get_settings() -> list[str]:
    settings_path = CLAUDE_DIR / "settings.json"
    if not settings_path.is_file():
        return []
    try:
        data = json.loads(settings_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []
    return data.get("permissions", {}).get("allow", [])


def get_guide() -> list[dict]:
    docs_dir = ROOT / "docs"
    if not docs_dir.is_dir():
        return []
    items = []
    for f in sorted(docs_dir.rglob("*.md")):
        text = read_text(f, limit=20000) or ""
        title_match = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
        items.append({
            "path": str(f.relative_to(ROOT)).replace("\\", "/"),
            "title": title_match.group(1) if title_match else f.stem,
            "content": text,
        })
    return items


def get_monitor(root_status: str) -> dict:
    modified, untracked = [], []
    for line in root_status.splitlines():
        if not line.strip():
            continue
        code, path = line[:2], line[3:]
        (untracked if code.strip() == "??" else modified).append(path)
    return {"modified": modified, "untracked": untracked}


def get_apps() -> list[dict]:
    items = []
    for app in APPS:
        features_dir = ROOT / "apps" / app / "lib" / "features"
        features = sorted(p.name for p in features_dir.iterdir() if p.is_dir()) if features_dir.is_dir() else []
        items.append({"app": app, "features": features})
    return items


def get_harness() -> dict:
    return {
        "localMd": read_text(CLAUDE_DIR / "CLAUDE.local.md", limit=10000),
        "sdk": get_sdk_versions(),
        "analyze": _analyze_task.snapshot(),
    }


def get_assistant() -> list[dict]:
    log = run_git(["log", "-15", "--pretty=format:%h|%an|%ar|%s"])
    items = []
    for line in log.splitlines():
        parts = line.split("|", 3)
        if len(parts) == 4:
            items.append({"hash": parts[0], "author": parts[1], "relDate": parts[2], "subject": parts[3]})
    return items


def build_state() -> dict:
    root_status = run_git(["status", "--porcelain"])
    return {
        "brief": get_brief(root_status),
        "instr": get_instructions(),
        "skill": get_skills(),
        "conn": get_connectors(),
        "hook": get_hooks(),
        "agent": get_agents(),
        "plugin": get_plugins(),
        "set": get_settings(),
        "guide": get_guide(),
        "mon": get_monitor(root_status),
        "apps": get_apps(),
        "harness": get_harness(),
        "assist": get_assistant(),
    }


CONTENT_TYPES = {
    ".html": "text/html; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".js": "application/javascript; charset=utf-8",
}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass

    def _token_from_request(self) -> str | None:
        query = parse_qs(urlsplit(self.path).query)
        if "token" in query:
            return query["token"][0]
        cookie_header = self.headers.get("Cookie")
        if cookie_header:
            cookie: SimpleCookie = SimpleCookie()
            cookie.load(cookie_header)
            if AUTH_COOKIE_NAME in cookie:
                return cookie[AUTH_COOKIE_NAME].value
        return None

    def _authorized(self) -> bool:
        token = self._token_from_request()
        return token is not None and hmac.compare_digest(token, AUTH_TOKEN)

    def _auth_cookie_header(self) -> str:
        return f"{AUTH_COOKIE_NAME}={AUTH_TOKEN}; Path=/; SameSite=Lax; Max-Age=2592000"

    def _send_json(self, data: dict) -> None:
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlsplit(self.path).path

        if path == "/api/state":
            if not self._authorized():
                self.send_error(401, "token required")
                return
            self._send_json(build_state())
            return

        rel = "index.html" if path == "/" else path.lstrip("/")
        file_path = (STATIC_DIR / rel).resolve()
        if STATIC_DIR not in file_path.parents and file_path != STATIC_DIR:
            self.send_error(404)
            return
        if not file_path.is_file():
            self.send_error(404)
            return
        body = file_path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", CONTENT_TYPES.get(file_path.suffix, "application/octet-stream"))
        self.send_header("Content-Length", str(len(body)))
        if path == "/" and self._authorized():
            # URL의 ?token= 으로 최초 접속했다면, 이후 요청은 쿠키만으로 인증되게 한다.
            self.send_header("Set-Cookie", self._auth_cookie_header())
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if not self._authorized():
            self.send_error(401, "token required")
            return
        if self.path == "/api/harness/analyze":
            self._send_json(start_flutter_analyze())
            return
        if self.path == "/api/brief/test":
            self._send_json(start_flutter_test())
            return
        self.send_error(404)


def main():
    port = 8787
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print(f"CC 콘솔: http://localhost:{port}/?token={AUTH_TOKEN}")
    print(f"(같은 네트워크의 다른 기기에서는 이 PC의 LAN IP로: http://<LAN IP>:{port}/?token={AUTH_TOKEN})")
    print("토큰 없이는 데이터를 볼 수 없습니다. 한 번 접속하면 쿠키로 기억됩니다.")
    print("(Ctrl+C 로 종료)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
