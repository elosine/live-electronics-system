#!/usr/bin/env node
// sine_page_test.js — THE SINE BRICK UNDER A STUB WINDOW (the Decibel piece's PLAN 1.5 · 12.2 · 12.3, 2026-10-06): le_objects.js
// and le_sine.js loaded into node with the few things of a page they touch faked — no browser, no score server, no engine.
// It checks what the brick IS, what it SENDS, what its label SAYS and what its panel DOES:
//   THE PITCH     a name with its cents <-> a MIDI number, both ways
//   THE GESTURE   the key over a selected note makes a brick with the note's lane, span and pitch; with none, at the playhead
//   THE MESSAGE   /le/sine: its pitch, its length, a flat level, a hairpin, the gliss kinds as ms:cents lines
//   THE CURVE     its level from a drawn curve, read through the host's reader: eight points, the label's sparkline; nothing
//                 drawn = the flat mark, said; a reader that throws = the flat mark
//   INSIDE        a playhead that starts inside the brick: what is left of it, its lines taken up where they stand
//   THE TICK      ahead of its start · inside · a silenced part sends nothing · the pass's number · a stop reaches the engine
//   THE PANEL     it builds; the pitch box, the gliss menu, the level menu and the JSON box write the brick, undoably
//   THE SAVE      the brick's data through JSON and back sends the same message
//   node electronics/tools/sine_page_test.js          exit 0: SINE_PAGE_TEST PASS · 1: FAIL, each check named
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
const DIR = path.join(__dirname, '..', 'score');
const sent = [], keydown = [];
const doc = {};
const mkEl = (tag) => {
    const st = { cssText: '' };
    const n = { tag, children: [], on: {}, ownerDocument: doc, appendChild(k) { this.children.push(k); return k; }, addEventListener(ev, fn) { this.on[ev] = fn; }, setAttribute() {}, blur() {}, querySelector() { return null; } };
    Object.defineProperty(n, 'style', { get: () => st, set: (v) => { st.cssText = String(v); } });
    Object.defineProperty(n, 'firstChild', { get() { return this.children[0] || null; } });
    return n;
};
doc.createElement = mkEl;
doc.createTextNode = (t) => ({ tag: '#text', textContent: String(t), children: [] });
const win = { addEventListener(ev, fn) { if (ev === 'keydown') keydown.push(fn); }, document: doc };
win.LE = { cfg: { players: [] }, ready: Promise.resolve(), playerOf: () => null, send: (kind, data) => { sent.push({ kind, data }); return Promise.resolve(null); } };
const ctx = vm.createContext({ window: win, LE: win.LE, document: doc, fetch: () => Promise.resolve({ ok: false }), performance: { now: () => 0 }, setTimeout, clearTimeout, console, Promise });
for (const f of ['le_objects.js', 'le_sine.js']) vm.runInContext(fs.readFileSync(path.join(DIR, f), 'utf8'), ctx, { filename: f });
const LEO = win.LEObjects;

let fails = 0;
const check = (what, ok, detail) => { console.log('  ' + (ok ? 'ok   ' : 'FAIL ') + what + ' — ' + detail); if (!ok) fails++; };
let nz = 0, audible = true, stops = 0, curve = null, asked = [];
const host = { objects: [], selectedObject: null, activeLane: 1, playhead: 20, playStartTime: 1000, playStartOffset: 0, pixelsPerSecond: 100, undo: 0, dirty: 0, saveStatus: { textContent: '' },
    createZone(o) { const label = { textContent: '' }; const z = Object.assign({ id: 'zn-' + (++nz), type: 'zone', _els: { group: { querySelector: () => label } }, _label: label }, o); this.objects.push(z); return z; },
    getTimeAtPlayhead() { return this.playhead; }, pushUndoState() { this.undo++; }, renderZone() {}, markDirty() { this.dirty++; }, showPropertyPanel() {}, isPartAudible: () => audible, stopPlay() { stops++; } };
LEO.attach(host, { keys: { open: 'm', play: 'r', process: 'e', sine: 's' }, lanes: 6, laneLabel: (l) => 'L' + l,
    curveAt: (ref, z, n) => { asked.push({ ref, layer: z.layer, from: z.startTime, to: z.endTime, n }); return typeof curve === 'function' ? curve(ref, z, n) : curve; } });
const key = (k) => keydown.forEach((fn) => fn({ key: k, target: null, preventDefault() {} }));
const msg = (z, at) => LEO.sineMessage(z, at, 0);
const find = (n, pred, out = []) => { if (!n) return out; if (pred(n)) out.push(n); (n.children || []).forEach((k) => find(k, pred, out)); return out; };
const panelOf = (z) => { const p = mkEl('div'); p.ownerDocument = doc; LEO.panel(z, p); return p; };
const label = (z) => { host.renderZone(z); return z._label.textContent; };

console.log('SINE_PAGE_TEST the pitch:');
check('a name with its cents is a MIDI number, and back', LEO.sineParsePitch('A3') === 57 && LEO.sineParsePitch('a3 +12') === 57.12 && LEO.sineParsePitch('Bb2 -30c') === 45.7 && LEO.sineParsePitch('C#4') === 61 && LEO.sineParsePitch('57.5') === 57.5
    && LEO.sineParsePitch('H3') === null && LEO.sinePitchName(57.12) === 'A3 +12c' && LEO.sinePitchName(45.7) === 'A#2 −30c' && LEO.sinePitchName(60) === 'C4',
    ['A3', 'a3 +12', 'Bb2 -30c', 'C#4', '57.5', 'H3'].map((t) => t + ' → ' + LEO.sineParsePitch(t)).join(' · ') + ' · 57.12 → ' + LEO.sinePitchName(57.12));
check('its frequency, and the beating a detune makes', Math.abs(LEO.sineHz(57) - 220) < 1e-9 && Math.abs(LEO.sineBeats(57, 28) - 3.587) < 0.01 && Math.abs(LEO.sineBeats(96, 24.6) - 29.95) < 0.2,
    'A3 ' + LEO.sineHz(57) + ' Hz · 28 c off A3 beats ' + LEO.sineBeats(57, 28).toFixed(3) + ' /s · 24.6 c off C7 beats ' + LEO.sineBeats(96, 24.6).toFixed(2) + ' /s');

console.log('SINE_PAGE_TEST the gesture:');
const noteObj = { id: 'wc-1', type: 'waveCurve', layer: 3, startSeconds: 10, endSeconds: 16, sonifyNote: 57 };
host.objects.push(noteObj); host.selectedObject = noteObj;
key('s');
let z = host.objects.find((o) => o.midiModel === 'elecSine');
check('the key over a selected note: a sine brick on its lane, over its span, at its pitch', !!z && z.layer === 3 && z.startTime === 10 && z.endTime === 16 && z.elec.midi === 57 && z.zoneFunction === 'elec' && z.yOffset === 0.75,
    z ? JSON.stringify({ layer: z.layer, start: z.startTime, end: z.endTime, model: z.midiModel, elec: z.elec }) : '(no brick)');
check('its label', label(z) === '∿ A3 · 6.0 s · mf', z._label.textContent);
host.selectedObject = null; host.activeLane = 3; host.playhead = 30;
key('s');
let z2 = host.objects.filter((o) => o.midiModel === 'elecSine')[1];
check('with nothing selected: at the playhead on the active lane, four seconds, the pitch of the lane\'s nearest earlier note', !!z2 && z2.layer === 3 && z2.startTime === 30 && z2.endTime === 34 && z2.elec.midi === 57,
    z2 ? JSON.stringify({ layer: z2.layer, start: z2.startTime, end: z2.endTime, midi: z2.elec.midi }) : '(no brick)');
host.activeLane = 7; const before = host.objects.length; key('s');
check('a lane that is no player\'s is refused, and says so', host.objects.length === before && /player's lane/.test(host.saveStatus.textContent), host.saveStatus.textContent);

console.log('SINE_PAGE_TEST the message:');
let m = msg(z);
check('a plain sine: its pitch, its length, one dynamic, no gliss', m.midi === 57 && m.lengthMs === 6000 && m.level === '4' && !('gliss' in m) && m.lane === 3 && m.t === 10 && m.id === z.id, JSON.stringify(m));
z.elec.midi = 57.12; z.elec.gliss = { kind: 'to', from: -28, to: 0 };
m = msg(z);
check('to unison: it starts 28 cents under and arrives', m.midi === 57.12 && m.gliss === '0:-28,end:0', JSON.stringify({ midi: m.midi, gliss: m.gliss }));
check('and the label says it', label(z) === '∿ A3 +12c ↗ −28c → 0 · 6.0 s · mf', z._label.textContent);
z.elec.gliss = { kind: 'from', from: 0, to: 40 }; const gFrom = msg(z).gliss;
z.elec.gliss = { kind: 'through', from: 30, to: -30 }; const gThrough = msg(z).gliss;
z.elec.gliss = { kind: 'around', from: 25, to: 0 }; const gAround = msg(z).gliss;
z.elec.gliss = { kind: 'line', points: [[0, -10], [0.25, 20], [1, 0]] }; const gLine = msg(z).gliss;
check('from unison · through · around · a line', gFrom === '0:0,end:40' && gThrough === '0:30,end:-30' && gAround === '0:0,3000:25,end:0' && gLine === '0:-10,1500:20,end:0', [gFrom, gThrough, gAround, gLine].join('  |  '));
z.elec.gliss = { kind: 'none', from: 0, to: 0 }; z.elec.midi = 57;
z.elec.level = { mode: 'hairpin', mark: 'mp', to: 'ff' };
m = msg(z);
check('a hairpin mp → ff', m.level === '0:3,end:6' && label(z) === '∿ A3 · 6.0 s · mp → ff', m.level + ' · ' + z._label.textContent);

console.log('SINE_PAGE_TEST the curve:');
z.elec.level = { mode: 'curve', mark: 'p', curveRef: 'A' };
curve = [0, 0.25, 0.5, 0.75, 1, 0.75, 0.5, 0.25]; asked = [];
m = msg(z);
check('it follows the drawn curve: eight points over its span, the height 0 … 1 as ppp … fff', m.level === '0:0,857:1.75,1714:3.5,2571:5.25,3429:7,4286:5.25,5143:3.5,end:1.75'
    && asked.length === 1 && asked[0].ref === 'A' && asked[0].layer === 3 && asked[0].from === 10 && asked[0].to === 16 && asked[0].n === 8, m.level + ' · asked ' + JSON.stringify(asked[0]));
check('the label draws what was read', label(z) === '∿ A3 · 6.0 s · curve A ▁▃▅▆█▆▅▃', z._label.textContent);
curve = null;
m = msg(z);
check('nothing drawn under it: the flat mark, and the label says so', m.level === '2' && label(z) === '∿ A3 · 6.0 s · curve A — none drawn: p', m.level + ' · ' + z._label.textContent);
curve = () => { throw new Error('the reader broke'); };
check('a reader that throws: the flat mark, nothing breaks', msg(z).level === '2', msg(z).level);
z.elec.level.curveRef = 'lane'; curve = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]; asked = [];
m = msg(z);
check('a curve on its own lane; a level curve is one value', asked[0].ref === 'lane' && m.level === '3.5' && /curve on this lane/.test(label(z)), m.level + ' · ' + z._label.textContent);

console.log('SINE_PAGE_TEST inside:');
z.elec.level = { mode: 'hairpin', mark: 'pp', to: 'f' }; z.elec.gliss = { kind: 'to', from: -28, to: 0 };
m = msg(z, 13);
check('the playhead starts half way in: three seconds left, the gliss and the hairpin taken up where they stand', m.lengthMs === 3000 && m.t === 13 && m.gliss === '0:-14,end:0' && m.level === '0:3,end:5', JSON.stringify(m));
z.elec.gliss = { kind: 'around', from: 24, to: 0 };
check('past the middle of an out-and-back, only the way back is left', msg(z, 14.5).gliss === '0:12,end:0' && msg(z, 11.5).gliss === '0:12,1500:24,end:0', msg(z, 14.5).gliss + '  |  from 1.5 s: ' + msg(z, 11.5).gliss);
z.elec.level = { mode: 'curve', mark: 'p', curveRef: 'B' }; curve = [0, 0, 0, 0, 1, 1, 1, 1]; asked = [];
m = msg(z, 13);
check('a curve is read again over what is left', asked.length === 1 && asked[0].from === 13 && asked[0].to === 16 && m.level === '0:0,429:0,857:0,1286:0,1714:7,2143:7,2571:7,end:7', JSON.stringify(asked[0]) + ' · ' + m.level);

console.log('SINE_PAGE_TEST the tick:');
host.objects.length = 0; nz = 0; curve = null;
host.selectedObject = { id: 'wc-2', type: 'waveCurve', layer: 0, startSeconds: 5, endSeconds: 9, sonifyNote: 60 }; key('s');
z = host.objects[0]; z.elec.gliss = { kind: 'to', from: -20, to: 0 };
sent.length = 0; host.playStartTime = 2000; LEO._prev = null;
LEO.tick(host, 4.95);
let s1 = sent.filter((x) => x.kind === 'sine');
check('ahead of its start: one message, the whole brick, this pass\'s number', s1.length === 1 && s1[0].data.t === 5 && s1[0].data.lengthMs === 4000 && s1[0].data.gliss === '0:-20,end:0' && s1[0].data.pass > 0, JSON.stringify(s1.map((x) => x.data)));
const pass1 = s1[0] && s1[0].data.pass;
LEO.tick(host, 4.97); LEO.tick(host, 5.05);
check('and only once', sent.filter((x) => x.kind === 'sine').length === 1, sent.filter((x) => x.kind === 'sine').length + ' message(s) over three frames');
sent.length = 0; host.playStartTime = 3000;
LEO.tick(host, 7);
s1 = sent.filter((x) => x.kind === 'sine');
check('a pass that begins INSIDE it: it sounds for what is left, under a new pass number', s1.length === 1 && s1[0].data.t === 7 && s1[0].data.lengthMs === 2000 && s1[0].data.gliss === '0:-10,end:0' && s1[0].data.pass > pass1, JSON.stringify(s1.map((x) => x.data)));
sent.length = 0; host.playStartTime = 4000; audible = false;
LEO.tick(host, 7);
check('a silenced part sends nothing', sent.filter((x) => x.kind === 'sine').length === 0, sent.filter((x) => x.kind === 'sine').length + ' message(s)');
audible = true; sent.length = 0; stops = 0;
host.stopPlay();
check('the score stops: the host\'s own stop runs, and the engine is told', stops === 1 && sent.some((x) => x.kind === 'sinestop'), 'the host\'s stop ran ' + stops + ' time(s) · sent ' + sent.map((x) => x.kind).join(','));
const keep = host.objects.splice(0); sent.length = 0; host.stopPlay(); host.objects.push(...keep);
check('a score with no sine says nothing at a stop', sent.length === 0, sent.length + ' message(s)');

console.log('SINE_PAGE_TEST the panel:');
host.undo = 0; host.dirty = 0;
let p = null, perr = '';
try { p = panelOf(z); } catch (err) { perr = String(err && err.stack || err).split('\n').slice(0, 3).join(' | '); }
const labels = p ? find(p, (n) => n.tag === 'label').map((n) => n.textContent).filter(Boolean) : [];
check('it builds: Label · Pitch · Length · Gliss · Level, a ▶ and the box', !!p && ['Label', 'Pitch', 'Length (s)', 'Gliss', 'Starts (cents)', 'Level', 'Dynamic'].every((t) => labels.includes(t))
    && find(p, (n) => n.tag === 'button' && n.textContent === '▶ hear').length === 1 && find(p, (n) => n.tag === 'textarea').length === 1, p ? labels.join(' · ') : perr);
check('the gliss says how it beats', !!p && find(p, (n) => typeof n.textContent === 'string' && /it beats 3 → 0 times a second/.test(n.textContent)).length === 1,
    p ? (find(p, (n) => typeof n.textContent === 'string' && /beats/.test(n.textContent))[0] || {}).textContent || '(no such line)' : perr);
const pitch = find(p, (n) => n.tag === 'input' && n.type === 'text' && /^C4/.test(n.value))[0];
pitch.value = 'Bb2 -30'; pitch.on.change();
check('the pitch box writes it, once, undoably', z.elec.midi === 45.7 && host.undo === 1 && host.dirty >= 1, z.elec.midi + ' · undo ' + host.undo);
p = panelOf(z);
const lvSel = find(p, (n) => n.tag === 'select' && n.children.some((o) => o.value === 'hairpin'))[0];
lvSel.value = 'B'; lvSel.on.change();
check('the Level menu names a curve', JSON.stringify(z.elec.level) === '{"mode":"curve","mark":"mf","curveRef":"B"}', JSON.stringify(z.elec.level));
p = panelOf(z);
const gSel = find(p, (n) => n.tag === 'select' && n.children.some((o) => o.value === 'around'))[0];
gSel.value = 'from'; gSel.on.change();
check('the Gliss menu changes its kind and gives it somewhere to go', z.elec.gliss.kind === 'from' && z.elec.gliss.to === 30 && msg(z).gliss === '0:0,end:30', JSON.stringify(z.elec.gliss) + ' → ' + msg(z).gliss);
p = panelOf(z);
const box = find(p, (n) => n.tag === 'textarea')[0];
box.value = JSON.stringify({ midi: 'C6 +5', gliss: { kind: 'to', from: 24.6, to: 0 }, level: { mode: 'hairpin', mark: 'p', to: 'mf' }, label: 'crotale', junk: 1 }); box.on.change();
check('the box writes the whole setting, and leaves out what is not one', z.elec.midi === 84.05 && z.elec.gliss.kind === 'to' && z.elec.gliss.from === 24.6 && z.elec.level.to === 'mf' && z.elec.label === 'crotale' && !('junk' in z.elec)
    && label(z) === '∿ crotale · C6 +5c ↘ 24.6c → 0 · 4.0 s · p → mf', JSON.stringify(z.elec) + ' · ' + z._label.textContent);
sent.length = 0; find(panelOf(z), (n) => n.tag === 'button' && n.textContent === '▶ hear')[0].on.click();
check('▶ hear: two seconds, its gliss over them, no pass', sent.length === 1 && sent[0].kind === 'sine' && sent[0].data.lengthMs === 2000 && sent[0].data.gliss === '0:24.6,end:0' && sent[0].data.level === '2' && !('pass' in sent[0].data), JSON.stringify(sent.map((x) => x.data)));

// ---- THE WINDOW (the Decibel piece's PLAN 1.8 · 16.1, 2026-10-08): the brick armed for its player, and the simulated ear ----
console.log('SINE_PAGE_TEST the window:');
host.objects.length = 0; nz = 0; curve = null; win.LE.playerOf = () => 'bcl';
host.selectedObject = { id: 'wc-9', type: 'waveCurve', layer: 0, startSeconds: 5, endSeconds: 9, sonifyNote: 57 }; key('s');
z = host.objects[0];
m = msg(z);
check('a brick as it always was says no gate', !('gate' in m) && !('player' in m) && !/follows|with the player/.test(label(z)), JSON.stringify(m) + ' · ' + z._label.textContent);
z.elec.track = { on: true };
m = msg(z);
check('Follow on: gate 1 and whose window — the follow and the ear left to the piece', m.gate === 1 && m.player === 'bcl' && !('follow' in m) && !('ear' in m) && / · follows$/.test(label(z)), JSON.stringify(m) + ' · ' + z._label.textContent);
z.elec.track = { on: true, follow: 0.5, ear: 'mic' };
m = msg(z);
check('what the brick says of itself goes with it', m.follow === 0.5 && m.ear === 'mic' && / · follows ×0\.5$/.test(label(z)), JSON.stringify(m) + ' · ' + z._label.textContent);
z.elec.track = { on: true, follow: 0 };
check('follow 0: in and out with the player, and never moved', msg(z).follow === 0 && / · with the player$/.test(label(z)), z._label.textContent);
win.LE.playerOf = () => null;
check('a lane with no microphone is a window all the same, under its own name', msg(z).player === 'lane0', msg(z).player);
win.LE.playerOf = () => 'bcl';
z.elec.track = { on: true }; z.elec.gliss = { kind: 'to', from: -30, to: 0 };
check('a window\'s gliss is sent WHOLE even from a start inside it (the engine begins it again at each entry)', msg(z, 7).gliss === '0:-30,end:0' && msg(z, 7).lengthMs === 2000, msg(z, 7).gliss);
z.elec.gliss.overS = 1.5;
check('one glide\'s own length: every point in ms, shorter than the sine', msg(z).gliss === '0:-30,1500:0', msg(z).gliss);
// the simulated ear: the notes under the window, told as they are about to sound
const note1 = { id: 'wc-9', type: 'waveCurve', layer: 0, startSeconds: 5, endSeconds: 6.8, sonifyNote: 57 };
const note2 = { id: 'wc-10', type: 'waveCurve', layer: 0, startSeconds: 7.5, endSeconds: 9, sonifyNote: 57, properties: { simLevel: [[0, 2], [1, 5]] } };
const other = { id: 'wc-11', type: 'waveCurve', layer: 2, startSeconds: 5, endSeconds: 7, sonifyNote: 60 };
host.objects.push(note1, note2, other);
sent.length = 0; host.playStartTime = 5000; LEO._prev = null;
LEO.tick(host, 4.95);
let told = sent.filter((x) => x.kind === 'simlevel');
check('the note under the window is told as it is about to sound — a steady one as one mark; a note on another lane is not', told.length === 1 && told[0].data.id === 'wc-9' && told[0].data.player === 'bcl' && told[0].data.lane === 0
    && told[0].data.lengthMs === 1800 && told[0].data.level === '4' && told[0].data.pass > 0 && sent.filter((x) => x.kind === 'sine').length === 1, JSON.stringify(told.map((x) => x.data)));
LEO.tick(host, 4.97); LEO.tick(host, 5.06);
check('and only once', sent.filter((x) => x.kind === 'simlevel').length === 1, sent.filter((x) => x.kind === 'simlevel').length + ' told over three frames');
sent.length = 0; LEO.tick(host, 7.45);
told = sent.filter((x) => x.kind === 'simlevel');
check('a note that SAYS its level (a tool\'s shaped note) is told as a line of marks', told.length === 1 && told[0].data.id === 'wc-10' && told[0].data.level === '0:2,end:5' && told[0].data.lengthMs === 1500, JSON.stringify(told.map((x) => x.data)));
z.elec.track = { on: true, ear: 'mic' };
sent.length = 0; host.playStartTime = 6000; LEO._prev = null; LEO.tick(host, 4.95);
check('a window on a MICROPHONE is told nothing: the engine hears the player itself', sent.filter((x) => x.kind === 'simlevel').length === 0 && sent.filter((x) => x.kind === 'sine').length === 1, sent.map((x) => x.kind).join(','));
delete z.elec.track;
sent.length = 0; host.playStartTime = 7000; LEO._prev = null; LEO.tick(host, 4.95);
check('with no window nothing is told', sent.filter((x) => x.kind === 'simlevel').length === 0, sent.map((x) => x.kind).join(','));
// the panel's rows
host.undo = 0;
p = panelOf(z);
let folSel = find(p, (n) => n.tag === 'select' && n.children.length === 2 && n.children.some((o) => o.value === 'on'))[0];
check('the panel has Follow, off', !!folSel && find(p, (n) => n.tag === 'label').map((n) => n.textContent).includes('Follow') && folSel.children.find((o) => o.value === 'off').selected === true, folSel ? folSel.children.map((o) => o.value + (o.selected ? '*' : '')).join(' ') : 'no such menu');
folSel.value = 'on'; folSel.on.change();
p = panelOf(z);
const rows = find(p, (n) => n.tag === 'label').map((n) => n.textContent).filter(Boolean);
check('turned on: the brick is a window, undoably — and the panel shows how much, who it hears, one glide', JSON.stringify(z.elec.track) === '{"on":true}' && host.undo === 1 && ['How much', 'Hears', 'One glide (s)'].every((t) => rows.includes(t)), JSON.stringify(z.elec.track) + ' · ' + rows.join(' · '));
const howBox = find(p, (n) => n.tag === 'input' && n.type === 'number' && n.placeholder === 'the piece\'s' && n.max === '2')[0];
howBox.value = '0.6'; howBox.on.change();
check('How much writes the follow', z.elec.track.follow === 0.6 && msg(z).follow === 0.6, JSON.stringify(z.elec.track));
const box2 = find(panelOf(z), (n) => n.tag === 'textarea')[0];
check('the box shows the window', JSON.parse(box2.value).track.on === true && JSON.parse(box2.value).track.follow === 0.6, box2.value.replace(/\s+/g, ' '));
box2.value = JSON.stringify({ track: { on: true, follow: 5, ear: 'nose' }, gliss: { kind: 'to', from: -30, to: 0, overS: 2 } }); box2.on.change();
check('and writes it, brought into range', JSON.stringify(z.elec.track) === '{"on":true,"follow":2}' && z.elec.gliss.overS === 2, JSON.stringify(z.elec.track) + ' · ' + JSON.stringify(z.elec.gliss));
box2.value = JSON.stringify({ track: null }); box2.on.change();
check('track: null in the box takes the window off', !('track' in z.elec), JSON.stringify(z.elec));
host.objects.splice(host.objects.indexOf(note1), 3); z.elec.track = { on: true, follow: 0.6 }; z.elec.label = 'crotale';

console.log('SINE_PAGE_TEST the save:');
const copy = host.createZone({ layer: z.layer, startTime: z.startTime, endTime: z.endTime, zoneFunction: 'elec', midiModel: 'elecSine' });
copy.elec = JSON.parse(JSON.stringify(z.elec));
const a = msg(z), b = msg(copy); delete a.id; delete b.id;
check('through JSON and back it sends the same message', JSON.stringify(a) === JSON.stringify(b) && LEO.is(copy), JSON.stringify(b));

console.log(fails ? 'SINE_PAGE_TEST FAIL — ' + fails + ' check(s)' : 'SINE_PAGE_TEST PASS');
process.exit(fails ? 1 : 0);
