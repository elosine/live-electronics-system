#!/usr/bin/env node
// sc.js — find sclang and run one of the engine's SuperCollider files headless (the engine plan's 4.1 b).
//
//   node electronics/tools/sc.js where                       # the sclang this machine has
//   node electronics/tools/sc.js devices                     # the audio devices SuperCollider can open
//   node electronics/tools/sc.js run <file.scd> [KEY=VALUE …] [--timeout 90] [--verbose]
//
// As a module:   const sc = require('./sc.js');  const p = sc.start(file, { env, timeoutS });
//                await p.waitFor(/^LE_READY/);  …  const { code, results, errors } = await p.done;
//
// THE LINE PROTOCOL (every engine script speaks it; sc/boot.scd has the two helpers):
//   LE_READY  {json}   the server is up and the patch is running
//   LE_RESULT {json}   a result (one line per result)
//   LE_ERROR  text     what stopped it, in plain words
//   LE_INFO   text     a line worth showing
// Exit codes of the scripts: 0 done · 2 the device is not there · 3 the server did not boot · 4 a timeout.
//
// THE ENGINE'S SERVER LISTENS ON UDP 57210, never on 57110 — so an sclang or an IDE the composer has open for something
// else is never touched. After a run this tool removes a scsynth left on 57210, and only that one.
// (Where sclang is on this machine: the sandbox's rule, live-electronics-engine/docs/audio-workflow.md — the Windows
// installer puts it under Program Files and not always on PATH.)
'use strict';
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const PORT = 57210;
const SC_DIR = path.resolve(__dirname, '..', 'sc');

function sclang() {
    if (process.env.SCLANG && fs.existsSync(process.env.SCLANG)) return process.env.SCLANG;
    if (process.platform === 'win32') {
        const found = [];
        for (const base of [process.env['ProgramFiles'], process.env['ProgramFiles(x86)']].filter(Boolean)) {
            if (!fs.existsSync(base)) continue;
            for (const d of fs.readdirSync(base)) {
                if (!/^SuperCollider/i.test(d)) continue;
                const exe = path.join(base, d, 'sclang.exe');
                if (fs.existsSync(exe)) found.push(exe);
            }
        }
        if (found.length) return found.sort().reverse()[0];   // the newest version folder
    }
    const w = cp.spawnSync(process.platform === 'win32' ? 'where' : 'which', ['sclang'], { encoding: 'utf8' });
    if (w.status === 0 && w.stdout.trim()) return w.stdout.trim().split(/\r?\n/)[0];
    throw new Error('sclang not found — install SuperCollider, or set SCLANG to the full path of sclang');
}

// every scsynth on the ENGINE's port (57210): [{ pid, parent }]
function engineProcs() {
    if (process.platform !== 'win32') return [];
    const r = cp.spawnSync('powershell', ['-NoProfile', '-Command',
        "Get-CimInstance Win32_Process -Filter \"name='scsynth.exe'\" | Where-Object { $_.CommandLine -match '-u " + PORT + "' } | ForEach-Object { '' + $_.ProcessId + ' ' + $_.ParentProcessId }"],
        { encoding: 'utf8' });
    return (r.stdout || '').split(/\r?\n/).map((l) => l.trim().split(/\s+/).map(Number)).filter((a) => a.length === 2 && a[0] > 0).map(([pid, parent]) => ({ pid, parent }));
}
// is an engine up — in his own window, or another run's?
function engineUp() { return engineProcs().length > 0; }
// a scsynth left behind by THIS run's own sclang, and no other. (It swept every scsynth on the port until 2026-10-04:
// a look-only probe then took down the engine he had started in his own window — the piece's RUNNING_LOG §55.)
function sweep(sclangPid) {
    for (const p of engineProcs()) if (p.parent === sclangPid) cp.spawnSync('taskkill', ['/PID', String(p.pid), '/F'], { stdio: 'ignore' });
}

// opts.boots === false: the file boots no server (devices.scd) and may run beside a live engine
function start(file, opts = {}) {
    const abs = path.resolve(file);
    if (!fs.existsSync(abs)) throw new Error('no such file: ' + abs);
    if (opts.boots !== false && engineUp()) throw new Error('the engine is already running (a scsynth on UDP ' + PORT + ', in another window) — close that window first');
    const child = cp.spawn(sclang(), [abs], { cwd: path.dirname(abs), env: { ...process.env, ...(opts.env || {}) }, windowsHide: true });
    const lines = [], results = [], errors = [], waiters = [];
    let buf = '', ended = false;
    const onLine = (line) => {
        lines.push(line);
        if (opts.onLine) opts.onLine(line);
        const m = /^LE_RESULT\s+(.*)$/.exec(line);
        if (m) { try { results.push(JSON.parse(m[1])); } catch (e) { errors.push('unreadable result: ' + m[1]); } }
        const e = /^LE_ERROR\s+(.*)$/.exec(line);
        if (e) errors.push(e[1]);
        for (let i = waiters.length - 1; i >= 0; i--) if (waiters[i].re.test(line)) { clearTimeout(waiters[i].timer); waiters.splice(i, 1)[0].resolve(line); }
    };
    const feed = (d) => { buf += d.toString(); let k; while ((k = buf.indexOf('\n')) >= 0) { onLine(buf.slice(0, k).replace(/\r$/, '')); buf = buf.slice(k + 1); } };
    child.stdout.on('data', feed); child.stderr.on('data', feed);
    let timedOut = false;
    const timer = setTimeout(() => { timedOut = true; kill(); }, (opts.timeoutS || 90) * 1000);
    function kill() {
        if (process.platform === 'win32') cp.spawnSync('taskkill', ['/PID', String(child.pid), '/T', '/F'], { stdio: 'ignore' });
        else child.kill('SIGKILL');
    }
    const done = new Promise((resolve) => {
        child.on('exit', (code) => {
            ended = true; clearTimeout(timer); if (buf) onLine(buf);
            for (const w of waiters.splice(0)) { clearTimeout(w.timer); w.reject(new Error('sclang ended before ' + w.re)); }
            sweep(child.pid);
            resolve({ code: timedOut ? 4 : code, timedOut, results, errors, lines });
        });
    });
    const waitFor = (re, ms = 60000) => new Promise((resolve, reject) => {
        const hit = lines.find((l) => re.test(l)); if (hit) return resolve(hit);
        if (ended) return reject(new Error('sclang already ended'));
        const w = { re, resolve, reject }; w.timer = setTimeout(() => { const i = waiters.indexOf(w); if (i >= 0) waiters.splice(i, 1); reject(new Error('timeout waiting for ' + re)); }, ms);
        waiters.push(w);
    });
    return { child, lines, results, errors, waitFor, done, kill };
}

module.exports = { sclang, start, sweep, engineUp, engineProcs, PORT, SC_DIR };

if (require.main === module) (async () => {
    const args = process.argv.slice(2), cmd = args[0];
    if (!cmd || cmd === '-h') { console.log(fs.readFileSync(__filename, 'utf8').split('\n').slice(1, 20).join('\n')); return; }
    if (cmd === 'where') { console.log(sclang()); return; }
    let file, env = {}, timeoutS = 90, verbose = false;
    if (cmd === 'devices') file = path.join(SC_DIR, 'devices.scd');
    else if (cmd === 'run') file = args[1];
    else { console.error('unknown command ' + cmd); process.exit(2); }
    for (let i = (cmd === 'run' ? 2 : 1); i < args.length; i++) {
        if (args[i] === '--timeout') timeoutS = +args[++i];
        else if (args[i] === '--verbose') verbose = true;
        else if (/^[A-Z_][A-Z0-9_]*=/.test(args[i])) { const k = args[i].indexOf('='); env[args[i].slice(0, k)] = args[i].slice(k + 1); }
    }
    const p = start(file, { env, timeoutS, boots: cmd !== 'devices', onLine: (l) => { if (verbose || /^LE_/.test(l)) console.log(l); } });
    const r = await p.done;
    if (r.timedOut) console.error('LE_ERROR timed out after ' + timeoutS + ' s');
    process.exit(r.code == null ? 1 : r.code);
})();
