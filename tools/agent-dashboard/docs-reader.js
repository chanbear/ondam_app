'use strict';

const fs = require('fs');
const path = require('path');

const PHASES = [
  [1, 'Foundation'],
  [2, 'Authentication'],
  [3, 'Home / UX'],
  [4, 'Document Scan'],
  [5, 'Senior ↔ Guardian Connection'],
  [6, 'Guardian Core'],
  [7, 'SMS / Risk'],
  [8, 'Notification'],
  [9, 'UI Refinement'],
  [10, 'Voice Assistant'],
  [11, 'Integration Test'],
];

function readIfExists(p) {
  try {
    return fs.readFileSync(p, 'utf8');
  } catch (_) {
    return null;
  }
}

/** Parses docs/product/implementation-plan.md's "### Phase N — ..." headers.
 * Real text parsing, not a hardcoded snapshot — re-reads on every call so it
 * reflects whatever is actually in the file at request time (which may be
 * edited concurrently by another Claude Code session working on the repo). */
function parsePhases(planText) {
  if (!planText) return null;

  const results = [];
  for (const [num, label] of PHASES) {
    const headerRegex = new RegExp(`^###\\s*Phase\\s*${num}\\b[^\\n]*$`, 'm');
    const match = headerRegex.exec(planText);
    if (!match) {
      results.push({ number: num, label, status: 'UNKNOWN', headline: null, inferred: false });
      continue;
    }
    const headerLine = match[0];
    const startIdx = match.index + headerLine.length;
    const rest = planText.slice(startIdx, startIdx + 3000);
    const nextHeaderIdx = rest.search(/\n###\s|\n---/);
    const body = nextHeaderIdx === -1 ? rest : rest.slice(0, nextHeaderIdx);

    const doneSignal = /구현\s*완료|완료\)/.test(headerLine) || /구현\s*완료/.test(body.slice(0, 500));
    let status = 'PLANNED';
    if (doneSignal) status = 'DONE';
    else if (/선행\s*조건[^\n]*완료/.test(body)) status = 'READY';

    results.push({
      number: num,
      label,
      status,
      headline: headerLine.replace(/^###\s*/, '').trim(),
      inferred: false,
    });
  }

  // Transitive inference: phases are sequential (each says "선행 조건: Phase N-1
  // 완료"), so if a later phase's own text confirms DONE, earlier phases must
  // be done too even if their own section text doesn't literally say so
  // (observed for Phase 1, whose text never says "구현 완료" even once later
  // phases are). Marked `inferred: true` so the UI can show this honestly
  // rather than implying every phase's own doc text says "done".
  let sawLaterDone = false;
  for (let i = results.length - 1; i >= 0; i -= 1) {
    if (results[i].status === 'DONE') {
      sawLaterDone = true;
    } else if (sawLaterDone && results[i].status !== 'DONE') {
      results[i].status = 'DONE';
      results[i].inferred = true;
    }
  }

  const currentPhase = results.find((r) => r.status !== 'DONE') || results[results.length - 1];
  return { phases: results, currentPhase };
}

function readArchitecture(repoRoot) {
  const archPath = path.join(repoRoot, 'docs', 'architecture', 'architecture.md');
  const exists = fs.existsSync(archPath);

  let packages = [];
  try {
    packages = fs
      .readdirSync(path.join(repoRoot, 'packages'), { withFileTypes: true })
      .filter((d) => d.isDirectory())
      .map((d) => d.name)
      .sort();
  } catch (_) {
    packages = [];
  }

  const apps = ['senior', 'guardian'].map((name) => ({
    name,
    exists: fs.existsSync(path.join(repoRoot, 'apps', name)),
  }));

  return {
    docsAvailable: exists,
    sourcePath: exists ? path.relative(repoRoot, archPath) : null,
    packages,
    apps,
  };
}

function readProjectDocs(repoRoot) {
  const planPath = path.join(repoRoot, 'docs', 'product', 'implementation-plan.md');
  const planText = readIfExists(planPath);
  const parsed = parsePhases(planText);
  const project = parsed || { phases: null, currentPhase: null };
  project.sourcePath = planText ? path.relative(repoRoot, planPath) : null;
  project.docsAvailable = !!planText;

  const architecture = readArchitecture(repoRoot);

  return { project, architecture };
}

module.exports = { readProjectDocs };
