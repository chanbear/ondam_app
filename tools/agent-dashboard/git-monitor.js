'use strict';

const { execFile } = require('child_process');
const fs = require('fs');

function run(cwd, args, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    execFile('git', args, { cwd, timeout: timeoutMs, windowsHide: true, maxBuffer: 4 * 1024 * 1024 }, (err, stdout, stderr) => {
      if (err) {
        reject(new Error((stderr && stderr.trim()) || err.message));
        return;
      }
      resolve(stdout.trim());
    });
  });
}

/** Real git branch for an arbitrary directory — used to attribute a branch to
 * *other* Claude Code sessions' cwds. This is genuine git data about that
 * directory, not something Claude Code told us — label it as such in the UI. */
async function quickBranch(cwd) {
  if (!cwd || !fs.existsSync(cwd)) return null;
  try {
    const branch = await run(cwd, ['rev-parse', '--abbrev-ref', 'HEAD'], 3000);
    return branch || null;
  } catch (_) {
    return null;
  }
}

class GitMonitor {
  constructor(repoRoot) {
    this.repoRoot = repoRoot;
  }

  async snapshot() {
    try {
      const [branch, commitHash, commitLine, statusPorcelain] = await Promise.all([
        run(this.repoRoot, ['rev-parse', '--abbrev-ref', 'HEAD']),
        run(this.repoRoot, ['rev-parse', '--short', 'HEAD']),
        run(this.repoRoot, ['log', '-1', '--pretty=%h %s (%an, %ar)']),
        run(this.repoRoot, ['status', '--porcelain']),
      ]);

      const lines = statusPorcelain ? statusPorcelain.split('\n').filter(Boolean) : [];
      let staged = 0;
      let modified = 0;
      let untracked = 0;
      for (const line of lines) {
        const x = line[0];
        const y = line[1];
        if (x === '?' && y === '?') {
          untracked += 1;
          continue;
        }
        if (x !== ' ' && x !== '?') staged += 1;
        if (y !== ' ' && y !== '?') modified += 1;
      }

      const recentLogRaw = await run(this.repoRoot, ['log', '-8', '--pretty=%h|%s|%an|%ar']);
      const recentCommits = recentLogRaw
        .split('\n')
        .filter(Boolean)
        .map((l) => {
          const [hash, subject, author, when] = l.split('|');
          return { hash, subject, author, when };
        });

      return {
        ok: true,
        repoRoot: this.repoRoot,
        branch,
        commitHash,
        commitLine,
        staged,
        modified,
        untracked,
        clean: lines.length === 0,
        recentCommits,
        checkedAt: Date.now(),
      };
    } catch (err) {
      return { ok: false, error: err.message, checkedAt: Date.now() };
    }
  }
}

module.exports = { GitMonitor, quickBranch };
