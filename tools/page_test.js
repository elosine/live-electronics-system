#!/usr/bin/env node
// page_test.js — THE COMPOSER-SCORE MODULE UNDER A STUB WINDOW (the engine plan's part 13; the Decibel piece's PLAN 1.4, 2026-10-06):
// le_objects.js and le_process.js loaded into node with the few things of a page they touch faked — no browser, no score server,
// no engine. It checks what a brick SENDS, what its label SAYS and what its panel DOES:
//   THE DYNAMIC   a brick with none sends none · a mark · a hairpin · a step · a line · relative with a floor and a ceiling ·
//                 on a chain and on a pattern · the label · the panel's Level menu writes and clears the field · the bank's line
//   THE DRIVE     a variant with a drive of its own asks for a name of its own and the plan carries it (11.4)
//   node electronics/tools/page_test.js          exit 0: PAGE_TEST PASS · 1: FAIL, each check named
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const DIR = path.join(__dirname, '..', 'score');
const sent = [];
const mkEl = (tag) => ({ tag, children: [], on: {}, appendChild(k) { this.children.push(k); return k; }, addEventListener(ev, fn) { this.on[ev] = fn; }, setAttribute() {}, blur() {}, querySelector() { return null; } });
const doc = { createElement: mkEl };
const win = { addEventListener() {}, document: doc };
win.LE = { cfg: { players: [{ name: 'bcl', port: 'P1', ports: ['P1'] }] }, ready: Promise.resolve(), playerOf: (p) => (p === 'P1' ? 'bcl' : null),
    send: (kind, data) => { sent.push({ kind, data }); return Promise.resolve(null); } };
const ctx = vm.createContext({ window: win, LE: win.LE, document: doc, fetch: () => Promise.resolve({ ok: false }), performance: { now: () => 0 }, setTimeout, clearTimeout, console, Promise });
for (const f of ['le_objects.js', 'le_process.js']) vm.runInContext(fs.readFileSync(path.join(DIR, f), 'utf8'), ctx, { filename: f });
const LEO = win.LEObjects;

let fails = 0;
const check = (what, ok, detail) => { console.log('  ' + (ok ? 'ok   ' : 'FAIL ') + what + ' — ' + detail); if (!ok) fails++; };
const host = { objects: [], selectedObject: null, playStartTime: 0, playStartOffset: 0, pixelsPerSecond: 100, undo: 0, dirty: 0,
    pushUndoState() { this.undo++; }, renderZone(z) { LEO.decorate(z); }, markDirty() { this.dirty++; }, showPropertyPanel() {}, isPartAudible: () => true };
LEO.host = host;
LEO.opts = Object.assign({}, LEO.opts, { portOf: () => 'P1', lanes: 6 });
LEO.index = [
    { name: 'bcl-impulse-1', player: 'bcl', lengthMs: 375, peakDb: -26, loudDb: -33.4, loudIntDb: -33.1, played: 'ff', captured: '2026-10-05T08:25:00' },
    { name: 'bcl-impulse-2', player: 'bcl', lengthMs: 600, peakDb: -14, loudDb: -22.1, played: 'fff', captured: '2026-10-05T09:00:00' },
];
let nz = 0;
const zone = (elec, model) => { const label = { textContent: '' }; const z = { id: 'zn-' + (++nz), type: 'zone', midiModel: model || 'elecPlay', layer: 1, startTime: 5, endTime: 5.6, elec, _els: { group: { querySelector: () => label } }, _label: label }; host.objects.push(z); return z; };
const fire = (z) => { sent.length = 0; LEO.fire(host, z, z.startTime); return sent.filter((m) => m.kind === 'play').map((m) => m.data)[0] || {}; };
const find = (n, pred, out = []) => { if (!n) return out; if (pred(n)) out.push(n); (n.children || []).forEach((k) => find(k, pred, out)); return out; };
const panelOf = (z) => { const p = mkEl('div'); p.ownerDocument = doc; LEO.panel(z, p); return p; };

console.log('PAGE_TEST the dynamic:');
let z = zone({ name: 'bcl-impulse-1' }), m = fire(z);
check('a brick with no dynamic sends none', !('dyn' in m) && !('env' in m) && m.name === 'bcl-impulse-1', JSON.stringify(m));
host.renderZone(z);
const plainLabel = z._label.textContent;
check('and its label is as it was', plainLabel === '▶ bcl-impulse-1', plainLabel);

z = zone({ name: 'bcl-impulse-1', dyn: { mode: 'mark', mark: 'ff' } }); m = fire(z);
check('a mark', m.dyn === 'mark:ff' && !('env' in m), JSON.stringify({ dyn: m.dyn, env: m.env }));

z = zone({ name: 'bcl-impulse-1', dyn: { mode: 'mark', mark: 'mp', shape: { kind: 'hairpin', to: 'ff', curve: -2 } } }); m = fire(z);
check('a hairpin, with its curve', m.dyn === 'mark:mp' && m.env === '0:=,end:ff' && m.envCurve === -2, JSON.stringify({ dyn: m.dyn, env: m.env, envCurve: m.envCurve }));
host.renderZone(z);
check('the label says it', z._label.textContent === '▶ bcl-impulse-1 · mp→ff', z._label.textContent);

z = zone({ name: 'bcl-impulse-1', dyn: { mode: 'played', shape: { kind: 'step', atMs: 400, to: 'p' } } }); m = fire(z);
check('a step from as played', m.dyn === 'played' && m.env === '0:=,400:=,405:p' && !('envCurve' in m), JSON.stringify({ dyn: m.dyn, env: m.env }));
host.renderZone(z);
check('its label', z._label.textContent === '▶ bcl-impulse-1 · ▲|p', z._label.textContent);

z = zone({ name: 'bcl-impulse-1', dyn: { mode: 'mark', mark: 'mf', shape: { kind: 'line', points: [[0, 'mf'], [1200, 'ff'], [1250, 'p']] } } }); m = fire(z);
check('a line', m.dyn === 'mark:mf' && m.env === '0:mf,1200:ff,1250:p', JSON.stringify({ dyn: m.dyn, env: m.env }));

z = zone({ name: 'bcl-impulse-1', dyn: { mode: 'rel', rel: 1, floor: 'p', ceil: 'f' } }); m = fire(z);
check('relative, with a floor and a ceiling', m.dyn === 'rel:+1:floor:p:ceil:f', String(m.dyn));
z = zone({ name: 'bcl-impulse-1', dyn: { mode: 'rel', rel: -2 } }); m = fire(z);
check('relative, two steps down', m.dyn === 'rel:-2', String(m.dyn));

z = zone({ name: 'bcl-impulse-1', names: ['bcl-impulse-1', 'bcl-impulse-2'], behaviour: 'chain', dyn: { mode: 'mark', mark: 'p' } }); m = fire(z);
check('on a chain: every link takes it', m.behaviour === 'chain' && m.names === 'bcl-impulse-1,bcl-impulse-2' && m.dyn === 'mark:p', JSON.stringify({ names: m.names, dyn: m.dyn }));
z = zone({ name: 'bcl-impulse-1', behaviour: 'pattern', pattern: [{ name: 'bcl-impulse-1', atMs: 0 }, { name: 'bcl-impulse-2', atMs: 250, db: -6 }], dyn: { mode: 'mark', mark: 'f', shape: { kind: 'hairpin', to: '-2' } } }); m = fire(z);
check('on a pattern: its onsets and their own levels are kept', m.pattern === 'bcl-impulse-1:0,bcl-impulse-2:250:-6' && m.dyn === 'mark:f' && m.env === '0:=,end:-2', JSON.stringify({ pattern: m.pattern, dyn: m.dyn, env: m.env }));

console.log('PAGE_TEST the panel:');
z = zone({ name: 'bcl-impulse-1' });
let p = panelOf(z);
const texts = find(p, (n) => typeof n.textContent === 'string').map((n) => n.textContent);
check('the bank\'s line says how loud the sample is', texts.some((t) => /peak -26 dB · loud -33 LUFS \(ff\)/.test(t)), texts.find((t) => /peak/.test(t)) || '(no such line)');
check('the Dynamic rows are there, and say what was played', texts.includes('Dynamic') && texts.some((t) => t === 'played: ff (-33 LUFS)'), texts.filter((t) => /^played:/.test(t)).join(' | '));
let mode = find(p, (n) => n.tag === 'select' && n.children.some((o) => o.value === 'rel'))[0];
mode.value = 'mark'; mode.on.change();
check('the Level menu writes the field, once, undoably', JSON.stringify(z.elec.dyn) === '{"mode":"mark","mark":"mf"}' && host.undo === 1 && host.dirty === 1, JSON.stringify(z.elec.dyn) + ' · undo ' + host.undo);
p = panelOf(z);
let shape = find(p, (n) => n.tag === 'select' && n.children.some((o) => o.value === 'hairpin'))[0];
shape.value = 'hairpin'; shape.on.change();
check('the Shape menu adds a hairpin', z.elec.dyn && z.elec.dyn.shape && z.elec.dyn.shape.kind === 'hairpin' && fire(z).env === '0:=,end:ff', JSON.stringify(z.elec.dyn));
p = panelOf(z);
shape = find(p, (n) => n.tag === 'select' && n.children.some((o) => o.value === 'hairpin'))[0];
shape.value = ''; shape.on.change();
p = panelOf(z);
mode = find(p, (n) => n.tag === 'select' && n.children.some((o) => o.value === 'rel'))[0];
mode.value = 'played'; mode.on.change();
check('back to as played with no shape: the field is gone', !('dyn' in z.elec) && !('dyn' in fire(z)), JSON.stringify(z.elec));

if (typeof LEO.driveTag === 'function') {
    console.log('PAGE_TEST the drive:');
    LEO.presets = { classes: { colour: { durX: 1 } }, envelopes: { tail: { capMs: 1000 }, perc: { atkMs: 3 } }, presets: [{ key: 'fb1', name: 'feedback one', effect: 'feedback', class: 'colour', args: { fbMix: 1, fbDrive: '2@0,8@6000' } }, { key: 'fz', name: 'fuzz', effect: 'fuzz', class: 'colour', drive: 'played', args: { fzMix: 1 } }] };
    z = zone({ name: 'bcl-impulse-1', variants: { 'bcl-impulse-1': 'fb1-tail' } }); m = fire(z);
    let rows = LEO.planRows().filter((r) => r.base === 'bcl-impulse-1');
    check('a variant as it was: its name, and the drive is the default', m.name === 'bcl-impulse-1~fb1-tail' && rows.some((r) => r.suffix === 'fb1-tail' && r.drive === 'normalized'), m.name + ' · ' + JSON.stringify(rows.map((r) => [r.suffix, r.drive])));
    z = zone({ name: 'bcl-impulse-1', variants: { 'bcl-impulse-1': { v: 'fb1-tail', drive: '+12' } } }); m = fire(z);
    rows = LEO.planRows();
    check('a drive of its own: a name of its own, and the plan carries it', m.name === 'bcl-impulse-1~fb1-tail_d12' && rows.some((r) => r.suffix === 'fb1-tail_d12' && r.drive === '+12'), m.name + ' · ' + JSON.stringify(rows.map((r) => [r.suffix, r.drive])));
    z = zone({ name: 'bcl-impulse-2', variants: { 'bcl-impulse-2': 'fz-perc' } });
    rows = LEO.planRows().filter((r) => r.base === 'bcl-impulse-2');
    check('a preset may say its own drive', rows.length === 1 && rows[0].drive === 'played', JSON.stringify(rows.map((r) => [r.suffix, r.drive])));
    sent.length = 0; LEO.sendPlan(false);
    const line = sent.filter((x) => x.kind === 'plan').map((x) => x.data.rows).join('|').split('|').find((l) => l.startsWith('bcl-impulse-1;fb1-tail_d12;'));
    check('the plan\'s row: eleven fields, a dial as a line kept whole, the drive last', !!line && line.split(';').length === 11 && line.split(';')[9] === 'fbMix:1,fbDrive:2@0,8@6000' && line.split(';')[10] === '+12', String(line));
}

console.log(fails ? 'PAGE_TEST FAIL — ' + fails + ' check(s)' : 'PAGE_TEST PASS');
process.exit(fails ? 1 : 0);
