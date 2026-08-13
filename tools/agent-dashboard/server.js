'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');

const { StateStore } = require('./state-store');
const { ClaudeCodeAdapter } = require('./claude-adapter');
const { AgentMonitor } = require('./agent-monitor');
const { GitMonitor } = require('./git-monitor');
const { TestRunner } = require('./test-runner');
const { readProjectDocs } = require('./docs-reader');
const { readAgentRoster } = require('./config-reader');
const { AgentSpawner } = require('./agent-spawner');

const REPO_ROOT = path.resolve(__dirname, '..', '..');
const PUBLIC_DIR = path.join(__dirname, 'public');
const HOOK_ACTIVITY_PATH = path.join(__dirname, 'data', 'hook-activity.jsonl');

const store = new StateStore();
const adapter = new ClaudeCodeAdapter();
const agentMonitor = new AgentMonitor({
  adapter,
  store,
  projectCwd: REPO_ROOT,
  hookActivityPath: HOOK_ACTIVITY_PATH,
});
const gitMonitor = new GitMonitor(REPO_ROOT);
const testRunner = new TestRunner({ store, repoRoot: REPO_ROOT });
const agentSpawner = new AgentSpawner({ store, repoRoot: REPO_ROOT });

async function pollGit() {
  const snap = await gitMonitor.snapshot();
  const prev = store.state.git;
  store.update('git', snap);
  if (snap.ok && (!prev || !prev.ok || prev.commitHash !== snap.commitHash)) {
    store.addLog('git', `HEAD ${snap.commitHash} on ${snap.branch}: ${snap.commitLine}`);
  }
  if (
    snap.ok &&
    prev &&
    prev.ok &&
    (prev.modified !== snap.modified || prev.staged !== snap.staged || prev.untracked !== snap.untracked)
  ) {
    store.addLog('git', `Working tree changed: ${snap.modified} modified, ${snap.staged} staged, ${snap.untracked} untracked`);
  }
}

function loadDocs() {
  try {
    const docs = readProjectDocs(REPO_ROOT);
    store.update('project', docs.project);
    store.update('architecture', docs.architecture);
  } catch (err) {
    store.addLog('bridge', `Failed to read docs: ${err.message}`, 'warn');
    store.update('project', null);
    store.update('architecture', null);
  }
}

// ---- SSE ----
const sseClients = new Set();
function broadcast(type, payload) {
  const data = `event: ${type}\ndata: ${JSON.stringify(payload)}\n\n`;
  for (const res of sseClients) {
    try {
      res.write(data);
    } catch (_) {
      sseClients.delete(res);
    }
  }
}
store.on('state', ({ key, value }) => broadcast('state', { key, value }));
store.on('log', (entry) => broadcast('log', entry));

// ---- static files ----
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
};

function serveStatic(req, res) {
  let reqPath = decodeURIComponent(req.url.split('?')[0]);
  if (reqPath === '/') reqPath = '/index.html';
  const filePath = path.normalize(path.join(PUBLIC_DIR, reqPath));
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(filePath)] || 'application/octet-stream' });
    res.end(data);
  });
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (c) => {
      body += c;
      if (body.length > 1e6) req.destroy();
    });
    req.on('end', () => resolve(body));
    req.on('error', reject);
  });
}

function sendJson(res, status, obj) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(obj));
}

const server = http.createServer(async (req, res) => {
  try {
    const url = req.url.split('?')[0];

    if (url === '/events') {
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
      });
      res.write(`event: hello\ndata: ${JSON.stringify(store.getSnapshot())}\n\n`);
      sseClients.add(res);
      const keepAlive = setInterval(() => {
        try {
          res.write(': ping\n\n');
        } catch (_) {
          clearInterval(keepAlive);
        }
      }, 15000);
      req.on('close', () => {
        clearInterval(keepAlive);
        sseClients.delete(res);
      });
      return;
    }

    if (url === '/api/state' && req.method === 'GET') {
      sendJson(res, 200, store.getSnapshot());
      return;
    }

    const agentMatch = url.match(/^\/api\/agents\/([^/]+)$/);
    if (agentMatch && req.method === 'GET') {
      const sessionId = decodeURIComponent(agentMatch[1]);
      const found =
        store.state.agents.find((a) => a.sessionId === sessionId) ||
        store.state.otherSessions.find((a) => a.sessionId === sessionId);
      if (!found) {
        sendJson(res, 404, { ok: false, error: 'agent not found' });
        return;
      }
      sendJson(res, 200, { ok: true, agent: found, hookActive: agentMonitor.isHookActive() });
      return;
    }

    // Real `claude stop <id>` — see agent-spawner.js's `stop()` doc comment
    // for the session-ownership check (must already be a real, currently
    // observed Office agent) and the short-id-vs-full-UUID CLI quirk.
    const stopMatch = url.match(/^\/api\/agents\/([^/]+)\/stop$/);
    if (stopMatch && req.method === 'POST') {
      const sessionId = decodeURIComponent(stopMatch[1]);
      const result = await agentSpawner.stop(sessionId);
      sendJson(res, result.ok ? 200 : 400, result);
      return;
    }

    if (url === '/api/config/agents' && req.method === 'GET') {
      sendJson(res, 200, readAgentRoster(REPO_ROOT));
      return;
    }

    if (url === '/api/agents/spawn' && req.method === 'POST') {
      const body = await readBody(req);
      let parsed = {};
      try {
        parsed = JSON.parse(body || '{}');
      } catch (_) {
        parsed = {};
      }
      const result = await agentSpawner.spawn({ department: parsed.department, task: parsed.task, name: parsed.name });
      sendJson(res, result.ok ? 200 : 400, result);
      return;
    }

    if (url === '/api/tests/run' && req.method === 'POST') {
      const body = await readBody(req);
      let parsed = {};
      try {
        parsed = JSON.parse(body || '{}');
      } catch (_) {
        parsed = {};
      }
      const result = testRunner.start(parsed.target, parsed.cmd);
      sendJson(res, result.ok ? 200 : 409, result);
      return;
    }

    if (url.startsWith('/api/')) {
      sendJson(res, 404, { error: 'not found' });
      return;
    }

    serveStatic(req, res);
  } catch (err) {
    store.addLog('bridge', `Unhandled server error: ${err.message}`, 'error');
    res.writeHead(500);
    res.end('Internal error');
  }
});

function findPort(startPort, cb) {
  const tryPort = (p) => {
    if (p >= startPort + 20) {
      cb(new Error(`no free port found in range ${startPort}-${startPort + 19}`));
      return;
    }
    const probe = http.createServer();
    probe.once('error', () => tryPort(p + 1));
    probe.once('listening', () => probe.close(() => cb(null, p)));
    probe.listen(p, '127.0.0.1');
  };
  tryPort(startPort);
}

loadDocs();
setInterval(loadDocs, 10000);
agentMonitor.start();
pollGit();
setInterval(pollGit, 5000);

findPort(4500, (err, port) => {
  if (err) {
    console.error(`[agent-dashboard] ${err.message}`);
    process.exit(1);
  }
  server.listen(port, '127.0.0.1', () => {
    const url = `http://localhost:${port}`;
    console.log(`\nONDAM Engineering Command Center\n  ${url}\n`);
    store.addLog('bridge', `Server listening on ${url}`);
  });
});

process.on('SIGINT', () => {
  server.close(() => process.exit(0));
});
