// le_objects.js — THE COMPOSER-SCORE OBJECTS FOR THE ELECTRONICS (the engine plan's part 11 — its first two members).
// A piece's composer page loads it with ONE tag, after le_msg.js —   <script src="/electronics/le_objects.js"></script>
// — and gives it TWO lines (electronics/docs/SEAMS.md has them):
//     LEObjects.attach(Composer, { … })     once, when the composer exists: the piece's keys, and how a lane is read
//     LEObjects.tick(this, timeSec)         in the transport's frame, beside the playback ticks
//
// THE TWO OBJECTS ARE ZONES WITH A MODEL OF THEIR OWN. The stack's zone already draws on a lane, selects, moves, resizes,
// duplicates, saves and has a panel; this file adds only what the model MEANS — a label, a panel section, a key, a message:
//
//   midiModel 'elecOpen'   THE MIC OPENING.   elec: { name, category, player }
//       Its place is when the microphone opens; its length is the window. Played through, it sends
//           /le/open   player · lane · id · name · category · t · lengthMs · dueMs
//       and the engine records that player for the window, crops the recording to the attack and banks it under the name.
//       KEY (the piece's; `m` in the first): over the SELECTED NOTE — the window opens `preMs` (100) before the note and is
//       `openMs` (500) long, the crop finds the attack — or, with no note selected, at the playhead on the active lane.
//       Its name: the player's name and the next free letter (bcl-A, bcl-B …), the composer's to rename in the panel.
//
//   midiModel 'elecPlay'   THE RETURN.   elec: { name, behaviour? }
//       behaviour 'ar' (2026-10-05, step 9): the brick is a REGION around its CENTRE, the live note; the message points at the
//       centre and names the behaviour; the ENGINE rolls where the sample lands (before, after, lazily after, near unison, a
//       miss) — never the page: the score stays still, the simulation runs the same dice. Its panel chooses the behaviour.
//       behaviour 'chain' (the same day): elec.names, the samples IN ORDER; the brick STARTS at the live note and runs 0.5 s per
//       sample; the engine rolls which follows the live note and the rest follow the one before (the piece's DEC-10).
//       behaviour 'arChain' (DEC-11): the region runs from arRegionMs BEFORE the live note to arRegionMs after it plus a link per
//       further sample; one sample anticipates or reacts to the live note, the rest chain after it.
//       behaviour 'pattern' (DEC-15, the same day): a COMPOSED rhythm — no dice. elec.pick names the samples by two rows of
//       boxes (the players · the tags after them, bcl-impulse-1 → bcl · impulse-1; no pick = every sample the bank holds);
//       elec.rhythm is the dials — the Strikes drawer's menu (DEC-15b): unison · even · front-loaded · back-loaded · centre · edges ·
//       random (this module's own) · accel · round robin and containers (the HOST's calculators, opts.accel · opts.containers, the
//       samples DEALT onto the run's onsets under the re-attack rule) · order · seed · reverse · rotate; Generate writes
//       elec.pattern = [{ name, atMs, db? }]
//       from the brick's START (the live note), its length the span. ONE message carries the onsets and the engine plays each
//       on time — the same in concert and in simulation. A message onset is name:atMs or name:atMs:db (a level ramp). The simple
//       shapes are this file's own (rhythm()); a run's calculator comes in through attach() — the module leans on no file of a
//       piece's stack, it is HANDED what it may use.
//       Played through, it sends   /le/play   name · id · lane · t · dueMs   and the engine plays the banked sample WHERE THE
//       BRICK IS. Its length is the sample's, read from the bank's index; its lane says whose staff it is drawn on.
//       KEY (`r` in the first): at the playhead — the sample of the selected opening, else of the nearest opening before
//       the playhead; the panel's picker lists every sample in the index.
//
//   midiModel 'elecProcess'   A STAGE OF A CHAIN (2026-10-05) — the THIRD object: a banked sample through one configuration of
//       the engine's chain, banked again under a name of its own (<root>~1, ~2 …). Its catalogue, its panel and its render are
//       le_process.js — a mixin on this object, one more tag; this file only knows that it IS one of its bricks and hands it
//       the label, the panel, the redraw, the key and the tick. Rendered, it is played exactly as a plain return.
//
// A MESSAGE LEAVES AHEAD of its brick by the look-ahead (0.1 s), as a note does, and says by how much (dueMs): the engine
// schedules a return on ITS OWN clock dueMs later, and starts a capture at once (early is right — the crop finds the attack).
// An opening the playhead STARTS INSIDE still opens, for what is left of its window. A brick on a silenced part sends nothing.
//
// CONCERT AND SIMULATION: the same objects, the same messages, the same road (le_msg.js). In concert the page is on a
// player's tablet and has no MIDI at all — which is why the tick is this file's own, not the MIDI playback's.
//
// WHAT IT ASKS OF THE HOST (the stack's composer, the same in every piece that takes the engine): objects · createZone ·
// renderZone · showPropertyPanel · propertyPanel · selectedObject · activeLane · getTimeAtPlayhead · pushUndoState ·
// markDirty · saveStatus · playStartTime · playStartOffset · pixelsPerSecond · isPartAudible. renderZone and
// showPropertyPanel are WRAPPED (the way the stack's own mixins go in): no line of theirs is changed.
// Nothing in this file knows a piece: the keys, the lanes and the index's address come in through attach().
(function () {
    'use strict';
    const MODELS = {
        elecOpen: { kind: 'open', sign: '◉', color: '#00897B', yOffset: 0, title: 'Mic opening' },
        elecPlay: { kind: 'play', sign: '▶', color: '#8E24AA', yOffset: 1, title: 'Sample — the return' },
        elecProcess: { kind: 'process', sign: '⟳', color: '#EF6C00', yOffset: 2, title: 'Process — a stage of the chain' },   // le_process.js
    };
    const r3 = (x) => Math.round(x * 1000) / 1000;
    const safe = (s) => (s === '*' ? '*' : String(s == null ? '' : s).replace(/[^A-Za-z0-9_~-]/g, '').slice(0, 64));   // a name is a file name (sc/bank.scd); '*' = every sample; ~ = a processed sample, <root>~<n>
    // a seeded random (mulberry32): the same seed, the same rhythm — a save reproduces what he heard
    const mulberry32 = (a) => () => { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
    const byName = (a, b) => String(a).localeCompare(String(b), undefined, { numeric: true });   // impulse-2 before impulse-10
    const DEFAULT_RHYTHM = {
        shape: 'even', spanMs: 2000, gapMs: 0, jitterMs: 0, seed: 1, order: 'named', oSeed: 1, reverse: false, rotate: 0,
        // accel · round robin — the host's calculator (opts.accel = the stack's AccelCalc); the drawer's dials under the drawer's names
        aShape: 'geometric', aLen: 'ratio', aFirst: 100, aFloor: 45, aRatio: 0.85, aCount: 12, aDur: 2000, aCurve: 0, aEase: 2, aKnee: 0.5, aGamma: 2,
        aJit: 0, aJitEnd: '', aHold: 0, aMirror: false, aDeal: 'robin', aMin: 250, aDb0: '', aDb1: '', aDbCurve: 0,
        // containers — the host's roller (opts.containers = the stack's TimeContainers); values in units of cUnit seconds, filling cTotal
        cValues: '2 5 7 15', cWeights: '', cUnit: 1, cTotal: 20, cStick: 0.8, cJump: 0.1, cContour: 'flat', cTurn: 0.5, cBow: 1, cDepth: 1,
    };
    const SHAPES = [['unison', 'unison'], ['even', 'even'], ['front', 'front-loaded'], ['back', 'back-loaded'], ['centre', 'centre'], ['edges', 'edges'], ['random', 'random'], ['accel', 'accel · round robin'], ['containers', 'containers']];
    const DIAL_KEY = { curve: 'aCurve', ease: 'aEase', knee: 'aKnee', gamma: 'aGamma' };   // a run shape's one dial (AccelCalc.SHAPES[].dial.key) → the brick's field
    const shuffled = (arr, rnd) => { const a = arr.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
    const permutations = (arr) => { if (arr.length <= 1) return [arr.slice()]; const out = []; arr.forEach((x, i) => { permutations(arr.slice(0, i).concat(arr.slice(i + 1))).forEach((p) => out.push([x].concat(p))); }); return out; };

    const LEObjects = {
        MODELS, host: null, index: [], _pass: null, _prev: null, _info: {},   // _info: a pattern brick's readout by zone id (never saved)
        opts: { keys: { open: 'm', play: 'r', process: 'e' }, portOf: () => null, laneLabel: (l) => 'lane ' + l, lanes: 99,
            indexUrl: '/bank/samples/index.json', lookAheadS: 0.1, openMs: 500, preMs: 100, arRegionMs: 400, chainLinkS: 0.5 },

        is(o) { return !!(o && o.type === 'zone' && MODELS[o.midiModel]); },
        zones(model) { return (this.host ? this.host.objects : []).filter((o) => this.is(o) && (!model || o.midiModel === model)); },
        row(name) { return this.index.find((x) => x.name === name) || null; },
        say(text) { const h = this.host; if (h && h.saveStatus) h.saveStatus.textContent = text; },
        // the engine's player on this lane: a name · null (the lane has no microphone) · undefined (the route table has not come yet)
        playerOf(layer) {
            if (!window.LE || !LE.cfg) return undefined;
            return LE.playerOf(this.opts.portOf(layer)) || null;
        },

        attach(host, opts) {
            if (this.host) return this;
            this.host = host;
            this.opts = Object.assign({}, this.opts, opts || {});
            const self = this, render = host.renderZone, show = host.showPropertyPanel;
            host.renderZone = function (zone) {
                const r = render.apply(this, arguments);
                if (self.is(zone)) self.decorate(zone);
                return r;
            };
            host.showPropertyPanel = function () {
                const r = show.apply(this, arguments);
                const o = this.selectedObject, p = this.propertyPanel;
                if (self.is(o) && o.elec && p && p.style.display !== 'none') self.panel(o, p);
                return r;
            };
            window.addEventListener('keydown', (e) => {
                if (e.ctrlKey || e.altKey || e.metaKey) return;
                const t = e.target;
                if (t && t.matches && t.matches('input, textarea, select')) return;
                const k = String(e.key || '').toLowerCase(), keys = this.opts.keys || {};
                if (k === keys.open) { e.preventDefault(); this.addOpening(); }
                else if (k === keys.play) { e.preventDefault(); this.addReturn(); }
                else if (keys.process && k === keys.process && this.addProcess) { e.preventDefault(); this.addProcess(); }   // le_process.js
            });
            if (window.LE && LE.ready) LE.ready.then(() => this.redraw());
            this.loadIndex();
            return this;
        },

        // ---- the bank's index: what has been captured -------------------------------------------------------------------
        loadIndex() {
            return fetch(this.opts.indexUrl, { cache: 'no-store' })
                .then((r) => (r.ok ? r.json() : null))
                .then((doc) => { this.index = doc && Array.isArray(doc.samples) ? doc.samples : []; this.redraw(); return this.index; })
                .catch(() => this.index);
        },
        // a return is as long as its sample; every electronics brick is drawn again (a name, a player may have changed)
        redraw() {
            const h = this.host; if (!h) return;
            for (const z of this.zones()) {
                if (z.midiModel === 'elecPlay' && z.elec && !z.elec.behaviour) {   // a behaviour's brick keeps its region
                    const row = this.row(z.elec.name);
                    if (row && row.lengthMs > 0) z.endTime = r3(z.startTime + row.lengthMs / 1000);
                }
                if (z.midiModel === 'elecProcess' && this.processRedraw) this.processRedraw(z);   // as long as its render (le_process.js)
                if (z._els) h.renderZone(z);
            }
        },

        // ---- the drawing: the label says what the brick is ----------------------------------------------------------------
        decorate(zone) {
            const g = zone._els && zone._els.group, e = zone.elec;
            if (!g || !e) return;
            const M = MODELS[zone.midiModel], label = g.querySelector('text');
            if (zone.midiModel === 'elecProcess') { if (label && this.processLabel) label.textContent = this.processLabel(zone); return; }   // le_process.js
            let text = M.sign + ' ' + (e.name || '?');
            if (zone.midiModel === 'elecOpen') {
                const p = this.playerOf(zone.layer);
                if (p !== undefined) { e.player = p || ''; if (!p) text += ' — no microphone on this lane'; }
            } else {
                if ((e.behaviour === 'chain' || e.behaviour === 'arChain') && Array.isArray(e.names) && e.names.length) text = M.sign + ' ' + (e.names.includes('*') ? 'ALL ' + this.index.length + ' samples' : e.names.join(' + '));
                if (e.behaviour === 'pattern') { const n = Array.isArray(e.pattern) ? e.pattern.length : 0; text = M.sign + ' ' + (n ? n + ' samples · ' + Math.round((zone.endTime - zone.startTime) * 1000) + ' ms' : 'no sample picked'); }
                if (e.behaviour) text += ' ~ ' + String(e.behaviour).toUpperCase();
                if (e.behaviour !== 'pattern' && !this.row(e.name)) text += ' — not captured yet';
            }
            if (label) label.textContent = text;
        },

        // ---- the gestures ---------------------------------------------------------------------------------------------------
        nextName(prefix) {
            const used = new Set(this.zones('elecOpen').map((z) => z.elec && z.elec.name));
            for (let i = 0; i < 2600; i++) {
                const n = prefix + '-' + String.fromCharCode(65 + (i % 26)) + (i < 26 ? '' : String(Math.floor(i / 26) + 1));
                if (!used.has(n)) return n;
            }
            return prefix + '-' + Date.now();
        },
        make(model, layer, start, end, elec) {
            const h = this.host, M = MODELS[model];
            const z = h.createZone({ layer, startTime: r3(start), endTime: r3(end), zoneFunction: 'elec', midiModel: model,
                color: M.color, opacity: 0.35, zoneHeight: 0.2, yOffset: M.yOffset });
            z.elec = elec;
            h.renderZone(z);
            h.showPropertyPanel();
            h.markDirty();
            return z;
        },
        addOpening() {
            const h = this.host, o = this.opts, sel = h.selectedObject;
            const onNote = !!(sel && sel.type === 'waveCurve' && sel.sonifyNote != null && sel.layer < o.lanes);
            const layer = onNote ? sel.layer : h.activeLane;
            if (layer == null || layer < 0 || layer >= o.lanes) { this.say('a mic opening goes on a player\'s lane — click the lane first'); return null; }
            const start = Math.max(0, onNote ? sel.startSeconds - o.preMs / 1000 : h.getTimeAtPlayhead());
            const player = this.playerOf(layer);
            const name = this.nextName(safe(player || o.laneLabel(layer)).toLowerCase() || 'mic');
            const z = this.make('elecOpen', layer, start, start + o.openMs / 1000, { name, category: 'attack', player: player || '' });
            this.say('mic opening ' + name + ' on ' + o.laneLabel(layer) + ' — ' + o.openMs + ' ms from ' + z.startTime.toFixed(2) + ' s' +
                (onNote ? ' (' + o.preMs + ' ms before the note; the engine crops to the attack)' : '') +
                (player ? '' : ' — THIS LANE HAS NO MICROPHONE IN THE ENGINE YET: it will record nothing'));
            return z;
        },
        addReturn() {
            const h = this.host, o = this.opts, sel = h.selectedObject, t = Math.max(0, h.getTimeAtPlayhead());
            const fromSel = this.is(sel) && sel.midiModel === 'elecOpen' && sel.elec ? sel : null;
            let layer = fromSel ? fromSel.layer : h.activeLane;
            if (layer == null || layer < 0 || layer >= o.lanes) { this.say('a return goes on a player\'s lane — click the lane first'); return null; }
            // whose sample: the selected opening's · else the latest opening before the playhead (this lane's first) · else the index's first
            const before = this.zones('elecOpen').filter((z) => z.elec && z.elec.name && z.startTime <= t).sort((a, b) => b.startTime - a.startTime);
            const src = fromSel || before.find((z) => z.layer === layer) || before[0] || null;
            const name = src ? src.elec.name : (this.index[0] ? this.index[0].name : '');
            if (!name) { this.say('no sample to return yet — place a mic opening first (' + String(o.keys.open).toUpperCase() + ' over a note)'); return null; }
            if (src) layer = src.layer;
            const row = this.row(name), len = row && row.lengthMs > 0 ? row.lengthMs : o.openMs;
            const z = this.make('elecPlay', layer, t, t + len / 1000, { name });
            this.say('return of ' + name + ' at ' + z.startTime.toFixed(2) + ' s on ' + o.laneLabel(layer) +
                (row ? ' — ' + Math.round(row.lengthMs) + ' ms' : ' — not captured yet: play through its opening with the engine up'));
            this.loadIndex();
            return z;
        },

        // ---- the panel: a section under the zone's own rows --------------------------------------------------------------
        panel(zone, panelEl) {
            const h = this.host, e = zone.elec, M = MODELS[zone.midiModel], doc = panelEl.ownerDocument;
            const el = (tag, props, kids) => { const n = doc.createElement(tag); Object.assign(n, props || {}); (kids || []).forEach((k) => n.appendChild(k)); return n; };
            const rowEl = (label, control) => el('div', { className: 'pp-row' }, [el('label', { textContent: label }), control]);
            const note = (text) => el('div', { className: 'pp-row' }, [el('span', { textContent: text, style: 'font-size:10px;color:#666' })]);
            const commit = (fn) => { h.pushUndoState(); fn(); h.renderZone(zone); h.markDirty(); h.showPropertyPanel(); };
            const sec = el('div', { className: 'pp-section' }, [el('h5', { textContent: M.title })]);
            sec.setAttribute('data-le-panel', zone.midiModel);
            if (zone.midiModel === 'elecOpen') {
                const name = el('input', { type: 'text', value: e.name || '' });
                name.addEventListener('change', () => {
                    const was = e.name, now = safe(name.value);
                    if (!now || now === was) { name.value = was || ''; return; }
                    commit(() => {
                        e.name = now;
                        // the returns of the old name follow it, unless another opening still holds that name
                        if (!this.zones('elecOpen').some((z) => z !== zone && z.elec && z.elec.name === was)) {
                            for (const z of this.zones('elecPlay')) if (z.elec && z.elec.name === was) { z.elec.name = now; if (z._els) h.renderZone(z); }
                        }
                    });
                });
                const cat = el('input', { type: 'text', value: e.category || '' });
                cat.addEventListener('change', () => commit(() => { e.category = String(cat.value || '').trim().slice(0, 40); }));
                const win = el('input', { type: 'number', value: String(Math.round((zone.endTime - zone.startTime) * 1000)), step: '10', min: '20' });
                win.addEventListener('change', () => {
                    const ms = Math.max(20, Math.min(30000, +win.value || this.opts.openMs));
                    commit(() => { zone.endTime = r3(zone.startTime + ms / 1000); });
                });
                const p = this.playerOf(zone.layer);
                sec.appendChild(rowEl('Name', name));
                sec.appendChild(rowEl('Category', cat));
                sec.appendChild(rowEl('Window (ms)', win));
                sec.appendChild(rowEl('Player', el('span', { textContent: p ? p + '  (' + this.opts.laneLabel(zone.layer) + ')' : p === null ? 'no microphone on this lane yet' : '—', style: 'font-size:11px;color:#666' })));
                const row = this.row(e.name);
                sec.appendChild(note(row ? 'in the bank: ' + Math.round(row.lengthMs) + ' ms, peak ' + row.peakDb + ' dB, taken ' + String(row.captured || '').replace('T', ' ')
                    : 'not in the bank yet — play through it with the engine up; the engine crops the window to the attack'));
            } else if (zone.midiModel === 'elecProcess') {
                if (this.processPanel) this.processPanel(zone, sec, { el, rowEl, note, commit });   // le_process.js
                else sec.appendChild(note('this brick\'s panel is le_process.js — not loaded on this page'));
            } else {
                const rows = this.index.slice().sort((a, b) => String(a.name).localeCompare(String(b.name)));
                const pick = el('select');
                if (!this.row(e.name)) pick.appendChild(el('option', { value: e.name || '', textContent: (e.name || '?') + ' — not captured yet', selected: true }));
                for (const x of rows) pick.appendChild(el('option', { value: x.name, textContent: x.name + ' · ' + x.player + ' · ' + Math.round(x.lengthMs) + ' ms', selected: x.name === e.name }));
                // an opening placed in the score but not yet played through can be chosen too
                for (const z of this.zones('elecOpen')) {
                    const n = z.elec && z.elec.name;
                    if (n && n !== e.name && !this.row(n)) pick.appendChild(el('option', { value: n, textContent: n + ' — not captured yet' }));
                }
                pick.addEventListener('change', () => {
                    pick.blur();
                    commit(() => { e.name = pick.value; const x = this.row(e.name); if (x && x.lengthMs > 0) zone.endTime = r3(zone.startTime + x.lengthMs / 1000); });
                });
                if (e.behaviour !== 'pattern') sec.appendChild(rowEl('Sample', pick));   // a pattern picks its samples by the rows below
                // the behaviour (step 9): plain = the sample where the brick is · ar = rolled by the engine around the brick's centre
                const beh = el('select');
                beh.appendChild(el('option', { value: '', textContent: 'where the brick is', selected: !e.behaviour }));
                beh.appendChild(el('option', { value: 'ar', textContent: 'anticipation-reaction around the centre', selected: e.behaviour === 'ar' }));
                beh.appendChild(el('option', { value: 'chain', textContent: 'chain — the samples follow the live note, one after another', selected: e.behaviour === 'chain' }));
                beh.appendChild(el('option', { value: 'arChain', textContent: 'ar + chain — one sample around the live note, the rest after it', selected: e.behaviour === 'arChain' }));
                beh.appendChild(el('option', { value: 'pattern', textContent: 'pattern — a composed rhythm for the samples picked', selected: e.behaviour === 'pattern' }));
                beh.addEventListener('change', () => {
                    beh.blur();
                    commit(() => {
                        const R = this.opts.arRegionMs / 1000, x = this.row(e.name);
                        const ref = e.behaviour === 'ar' ? r3((zone.startTime + zone.endTime) / 2) : e.behaviour === 'arChain' ? r3(zone.startTime + R) : zone.startTime;   // where the live note is, whatever the brick was
                        if (beh.value === 'ar') { e.behaviour = 'ar'; zone.startTime = r3(Math.max(0, ref - R)); zone.endTime = r3(ref + R); }
                        else if (beh.value === 'chain') { e.behaviour = 'chain'; if (!Array.isArray(e.names) || !e.names.length) e.names = [e.name]; zone.startTime = ref; zone.endTime = r3(ref + this.opts.chainLinkS * e.names.length); }
                        else if (beh.value === 'arChain') { e.behaviour = 'arChain'; if (!Array.isArray(e.names) || !e.names.length) e.names = [e.name]; zone.startTime = r3(Math.max(0, ref - R)); zone.endTime = r3(ref + R + this.opts.chainLinkS * (e.names.length - 1)); }
                        else if (beh.value === 'pattern') { e.behaviour = 'pattern'; zone.startTime = ref; if (!e.rhythm) e.rhythm = Object.assign({}, DEFAULT_RHYTHM); this.generate(zone); }
                        else { delete e.behaviour; zone.startTime = ref; zone.endTime = r3(ref + ((x && x.lengthMs > 0 ? x.lengthMs : this.opts.openMs) / 1000)); }
                    });
                });
                sec.appendChild(rowEl('Behaviour', beh));
                if (e.behaviour === 'pattern') this.patternPanel(zone, sec, { el, rowEl, note, commit });
                if (e.behaviour === 'ar') sec.appendChild(note('rolled by the engine at every playback — just before · just after · lazily after · near unison · a miss; the dials are the piece\'s route table, return.ar (A … F); the engine window shows each roll'));
                if (e.behaviour === 'chain' || e.behaviour === 'arChain') {
                    const names = el('input', { type: 'text', value: (e.names || [e.name]).join(', '), title: 'the samples, in order, comma-separated' });
                    names.addEventListener('change', () => commit(() => {
                        e.names = String(names.value || '').split(',').map((s) => safe(s.trim())).filter(Boolean);
                        if (!e.names.length) e.names = [e.name]; e.name = e.names[0];
                        const n = e.names.includes('*') ? Math.max(1, this.index.length) : e.names.length;   // '*': as many as the bank holds today
                        zone.endTime = e.behaviour === 'arChain' ? r3(zone.startTime + 2 * this.opts.arRegionMs / 1000 + this.opts.chainLinkS * (n - 1)) : r3(zone.startTime + this.opts.chainLinkS * n);
                    }));
                    sec.appendChild(rowEl('Samples, in order', names));
                    if ((e.names || []).includes('*')) sec.appendChild(note('* = every sample the bank holds at playback — all players, all impulses so far; the engine shuffles them (I)'));
                    sec.appendChild(note(e.behaviour === 'arChain'
                        ? 'rolled by the engine: one sample anticipates or reacts to the live note (the brick\'s start + the region), the rest follow the one before — the dials return.ar (A … C) and return.chain (G · H · I)'
                        : 'rolled by the engine: which sample follows the live note (the brick\'s start) and the rest follow the one before — just after · lazily after · near unison; the dials return.chain (G · H · I), the ranges ar\'s B'));
                }
                const row = this.row(e.name);
                if (e.behaviour !== 'pattern') sec.appendChild(note(row ? 'from ' + row.player + (row.category ? ' · ' + row.category : '') + ' · ' + Math.round(row.lengthMs) + ' ms · peak ' + row.peakDb + ' dB · taken ' + String(row.captured || '').replace('T', ' ')
                    : 'its length becomes the sample\'s once it is captured'));
            }
            panelEl.appendChild(sec);
        },

        // ---- behaviour 'pattern': the samples by two rows of boxes, the rhythm's dials, Generate ----------------------------
        // (2026-10-05, DEC-15 · DEC-15b): the shape menu is the Strikes drawer's — the six shapes and unison this module's own
        // (rhythm()); accel · round robin and containers are the HOST's calculators, handed in at attach (opts.accel = the stack's
        // AccelCalc · opts.containers = its TimeContainers) and absent from the menu when a page has none. A run has its own count
        // of onsets; the samples are DEALT onto them (deal(): round robin or free, under the re-attack rule). Left out, no meaning
        // for samples: as played · span × · amount · drop rests · pitches / re-deal.
        tagOf(row) { const n = String(row.name || ''), p = String(row.player || ''); return p && n.startsWith(p + '-') ? n.slice(p.length + 1) : n; },
        // the samples a brick picks: no pick = every sample the bank holds today; a pick = the players ticked × the tags ticked
        picked(e) {
            const P = e.pick && Array.isArray(e.pick.players) ? e.pick.players : null, T = e.pick && Array.isArray(e.pick.impulses) ? e.pick.impulses : null;
            return this.index.filter((r) => (!P || P.includes(String(r.player))) && (T ? T.includes(this.tagOf(r)) : r.kind !== 'processed'));   // a PROCESSED sample only by its own box: a render does not change what "every sample" is
        },
        // the simple shapes: n onsets in ms over a span — the first at 0 (the live note), the last at the span; seeded
        rhythm(n, cfg) {
            if (!(n > 0)) return [];
            const S = Math.max(0, +cfg.spanMs || 0), u = (i) => (n > 1 ? i / (n - 1) : 0), rnd = mulberry32((+cfg.seed || 0) * 48611 + 5), ix = [...Array(n)].map((_, i) => i);
            switch (cfg.shape) {
                case 'unison': return ix.map(() => 0);                                                          // every onset at the live note
                case 'front': return ix.map((i) => S * u(i) * u(i));                                            // dense at the start
                case 'back': return ix.map((i) => S * Math.sqrt(u(i)));                                           // dense at the end
                case 'centre': return ix.map((i) => S * (Math.asin(2 * u(i) - 1) / Math.PI + 0.5));              // dense in the middle
                case 'edges': return ix.map((i) => { const x = u(i); return S * (x * x * (3 - 2 * x)); });         // dense at both ends
                case 'random': return [0].concat(ix.slice(1).map(() => rnd() * S)).sort((a, b) => a - b);
                default: return ix.map((i) => S * u(i));                                                         // even
            }
        },
        // the onsets for a shape: the simple ones one per sample; a run (accel · containers) its own count, the samples dealt after
        runOnsets(cfg, n) {
            const o = this.opts, blank = (v) => v === '' || v == null;
            if (cfg.shape === 'accel' && o.accel) {   // the drawer's spec, the drawer's names (strike_drawer.js accelSpec)
                const lenBy = (cfg.aShape === 'even' && cfg.aLen !== 'count') ? 'duration' : cfg.aLen;
                const L = lenBy === 'count' ? { count: +cfg.aCount || 2 } : lenBy === 'duration' ? { duration: +cfg.aDur || 1 } : { ratio: +cfg.aRatio || 0.85 };
                const spec = { gapStart: Math.max(1, +cfg.aFirst || 1), gapEnd: Math.max(1, +cfg.aFloor || 45), length: L, shape: cfg.aShape || 'geometric',
                    curve: +cfg.aCurve || 0, ease: +cfg.aEase || 2, knee: +cfg.aKnee || 0, gamma: +cfg.aGamma || 2,
                    jitter: { pct: +cfg.aJit || 0, pctEnd: blank(cfg.aJitEnd) ? null : +cfg.aJitEnd, seed: +cfg.seed || 1 },
                    hold: { gaps: +cfg.aHold || 0 }, mirror: !!cfg.aMirror,
                    level: (!blank(cfg.aDb0) && !blank(cfg.aDb1)) ? { start: +cfg.aDb0, end: +cfg.aDb1, curve: +cfg.aDbCurve || 0 } : null };
                const R = o.accel.run(spec);
                return { onsets: R.onsets.slice(), levels: R.levels ? R.levels.slice() : null, dealt: true,
                    info: o.accel.describe(R, spec) + (R.fit && Math.abs(R.fit.residual || 0) > 0.5 ? ' · fit off by ' + R.fit.residual.toFixed(1) + ' ms' : '') };
            }
            if (cfg.shape === 'containers' && o.containers) {
                const T = o.containers, nums = String(cfg.cValues || '').split(/[\s,]+/).map(Number).filter((x) => isFinite(x) && x > 0);
                const ws = String(cfg.cWeights || '').trim() ? String(cfg.cWeights).trim().split(/[\s,]+/).map((w) => (w === '' || isNaN(+w) ? null : +w)) : null;
                const opt = { values: nums.length ? nums : T.DEFAULTS.values.slice(), weights: ws, unit: +cfg.cUnit || 1, total: +cfg.cTotal || 60, stick: +cfg.cStick || 0, jump: +cfg.cJump || 0,
                    contour: cfg.cContour || 'flat', turn: +cfg.cTurn || 0.5, bow: +cfg.cBow || 1, depth: +cfg.cDepth || 1, seed: +cfg.seed || 1 };
                const res = T.roll(opt);
                return { onsets: T.onsetsMs(res, 0), levels: null, dealt: true, info: T.describe(opt, res) };
            }
            const span = +cfg.gapMs > 0 ? +cfg.gapMs * Math.max(0, n - 1) : Math.max(0, +cfg.spanMs || 0);
            return { onsets: this.rhythm(n, Object.assign({}, cfg, { spanMs: span })), levels: null, dealt: false, info: '' };
        },
        // the dealing (the drawer's U13, for samples): N onsets, n samples. round robin — every sample once per lap, lap 1 in order,
        // each later lap a shuffle that keeps the re-attack rule (the same sample not struck again within aMin ms) against the known
        // times — every order tried for ≤ 7 samples, 3000 draws above — else the order again, flagged. free — no lap: each onset to
        // any sample the rule allows, at random, never the one just played while another is free, leaning to the longest wait.
        deal(rows, onsets, cfg, rnd) {
            const n = rows.length, N = onsets.length, minMs = Math.max(0, +cfg.aMin || 0), last = new Map(), out = [];
            let viol = 0;
            if (!n || !N) return { events: out, info: '' };
            const fits = (r, t, L) => !L.has(r.name) || t - L.get(r.name) >= minMs;
            const flag = () => (viol ? ' ⚠ ' + viol + ' re-attack' + (viol > 1 ? 's' : '') + ' < ' + minMs + ' ms' : '');
            if (cfg.aDeal === 'free') {
                let prev = null;
                onsets.forEach((t) => {
                    const wait = (r) => (last.has(r.name) ? t - last.get(r.name) : Infinity);
                    let free = rows.filter((r) => wait(r) >= minMs);
                    if (free.length > 1 && prev) free = free.filter((r) => r.name !== prev);
                    let pick;
                    if (free.length) {
                        const finite = free.map(wait).filter((w) => w !== Infinity), top = (finite.length ? Math.max(...finite) : 0) + 1;
                        const ws = free.map((r) => (wait(r) === Infinity ? top * 2 : wait(r)) + 1), tot = ws.reduce((a, b) => a + b, 0);
                        let x = rnd() * tot; pick = free[free.length - 1]; for (let j = 0; j < free.length; j++) { x -= ws[j]; if (x <= 0) { pick = free[j]; break; } }
                    } else { viol++; pick = rows.reduce((b, r) => (wait(r) > wait(b) ? r : b), rows[0]); }
                    out.push({ name: pick.name, atMs: t }); last.set(pick.name, t); prev = pick.name;
                });
                return { events: out, info: 'free dealing over ' + n + ' samples' + flag() };
            }
            const checkPerm = (perm, times) => { const L = new Map(last); for (let j = 0; j < times.length; j++) { if (!fits(perm[j], times[j], L)) return false; L.set(perm[j].name, times[j]); } return true; };
            let pos = 0, laps = 0, shuffledLaps = 0, again = 0;
            while (pos < N) {
                const len = Math.min(n, N - pos), times = onsets.slice(pos, pos + len);
                let order = null;
                if (laps === 0) order = rows.slice(0, len);
                else {
                    if (n <= 7) { const valid = permutations(rows).filter((p) => checkPerm(p.slice(0, len), times)); if (valid.length) { order = valid[Math.floor(rnd() * valid.length)].slice(0, len); shuffledLaps++; } }
                    else { for (let a = 0; a < 3000 && !order; a++) { const p = shuffled(rows, rnd); if (checkPerm(p.slice(0, len), times)) { order = p.slice(0, len); shuffledLaps++; } } }
                    if (!order) { order = rows.slice(0, len); again++; }
                }
                order.forEach((r, j) => { const t = times[j]; if (!fits(r, t, last)) viol++; out.push({ name: r.name, atMs: t }); last.set(r.name, t); });
                pos += len; laps++;
            }
            return { events: out, info: 'round robin · ' + laps + (laps === 1 ? ' lap' : ' laps') + (shuffledLaps ? ' · ' + shuffledLaps + ' shuffled' : '') + (again ? ' · ' + again + ' in order again (no shuffle kept the rule)' : '') + flag() };
        },
        // Generate: the samples picked, in the order asked, on the shape's onsets → elec.pattern = [{ name, atMs, db? }]; the brick
        // runs from the live note to the last onset (a simple shape: to its span)
        generate(zone) {
            const e = zone.elec, cfg = e.rhythm || (e.rhythm = Object.assign({}, DEFAULT_RHYTHM));
            for (const k of Object.keys(DEFAULT_RHYTHM)) if (cfg[k] === undefined) cfg[k] = DEFAULT_RHYTHM[k];   // a brick saved before a dial existed
            let rows = this.picked(e).slice().sort((a, b) => byName(a.name, b.name));
            if (cfg.order === 'byImpulse') rows.sort((a, b) => byName(this.tagOf(a), this.tagOf(b)) || byName(a.name, b.name));
            if (cfg.order === 'shuffled') rows = shuffled(rows, mulberry32((+cfg.oSeed || 0) * 7877 + 11));
            const run = rows.length ? this.runOnsets(cfg, rows.length) : { onsets: [], levels: null, dealt: false, info: '' };
            let on = run.onsets, lv = run.levels;
            // reverse: mirrored within its own span, the first onset still at 0 · rotate: the gaps turned by so many places
            if (cfg.reverse && on.length) { const L = on[on.length - 1]; on = on.map((t) => L - t).reverse(); if (lv) lv = lv.slice().reverse(); }
            if (+cfg.rotate && on.length > 2) { const gaps = on.slice(1).map((t, i) => t - on[i]), k = ((Math.round(+cfg.rotate) % gaps.length) + gaps.length) % gaps.length, g = gaps.slice(k).concat(gaps.slice(0, k)); on = [0]; g.forEach((x) => on.push(on[on.length - 1] + x)); }
            if (+cfg.jitterMs > 0 && cfg.shape !== 'accel') { const jr = mulberry32((+cfg.seed || 0) * 31 + 9); on = on.map((t, i) => (i ? Math.max(0, t + (jr() * 2 - 1) * +cfg.jitterMs) : t)); if (run.dealt) on.sort((a, b) => a - b); }   // the first stays at the live note
            on = on.map((t) => Math.round(t * 10) / 10);
            let events, info = run.info;
            if (run.dealt) { const d = this.deal(rows, on, cfg, mulberry32((+cfg.seed || 1) * 7727 + 29)); events = d.events; info = [run.info, d.info].filter(Boolean).join(' · '); }
            else events = rows.map((r, i) => ({ name: r.name, atMs: on[i] }));
            if (lv) events.forEach((ev, i) => { if (lv[i] != null && isFinite(lv[i])) ev.db = Math.round(lv[i] * 10) / 10; });
            e.pattern = events;
            this._info[String(zone.id)] = info;
            if (events.length) e.name = events[0].name;
            const last = events.reduce((m, p) => Math.max(m, p.atMs), 0);
            const span = !events.length || run.dealt || cfg.shape === 'unison' ? 0 : (+cfg.gapMs > 0 ? +cfg.gapMs * Math.max(0, rows.length - 1) : Math.max(0, +cfg.spanMs || 0));
            zone.endTime = r3(zone.startTime + Math.max(span, last, 100) / 1000);
            return e.pattern;
        },
        patternPanel(zone, sec, ui) {
            const e = zone.elec, o = this.opts, cfg = e.rhythm || (e.rhythm = Object.assign({}, DEFAULT_RHYTHM)), { el, rowEl, note, commit } = ui;
            for (const k of Object.keys(DEFAULT_RHYTHM)) if (cfg[k] === undefined) cfg[k] = DEFAULT_RHYTHM[k];
            const regen = (fn) => commit(() => { fn(); this.generate(zone); });
            const small = 'font-size:11px';
            const sel = (key, options) => { const s = el('select'); for (const [v, t, dis] of options) s.appendChild(el('option', { value: v, textContent: t, selected: String(cfg[key]) === String(v), disabled: !!dis })); s.addEventListener('change', () => { s.blur(); regen(() => { cfg[key] = s.value; }); }); return s; };
            const num = (key, min, max, step, blankOk, width) => { const n = el('input', { type: 'number', value: cfg[key] == null ? '' : String(cfg[key]), min: String(min), max: String(max), step: String(step), style: 'width:' + (width || 62) + 'px' }); n.addEventListener('change', () => regen(() => { cfg[key] = blankOk && n.value === '' ? '' : Math.max(min, Math.min(max, +n.value || 0)); })); return n; };
            const text = (key, width) => { const n = el('input', { type: 'text', value: String(cfg[key] == null ? '' : cfg[key]), style: 'width:' + (width || 110) + 'px' }); n.addEventListener('change', () => regen(() => { cfg[key] = n.value; })); return n; };
            const chk = (key, label) => { const c = el('input', { type: 'checkbox', checked: !!cfg[key], style: 'margin:0 3px 0 0;vertical-align:middle' }); c.addEventListener('change', () => regen(() => { cfg[key] = !!c.checked; })); return el('label', { style: small + ';white-space:nowrap' }, [c, el('span', { textContent: label })]); };
            const btn = (t, fn, title) => { const b = el('button', { type: 'button', textContent: t, title: title || '', style: small }); b.addEventListener('click', fn); return b; };
            const tiny = (t) => el('span', { textContent: t, style: 'font-size:10px;color:#888;white-space:nowrap' });
            const pair = (...kids) => el('span', { style: 'display:inline-flex;align-items:center;gap:4px;flex-wrap:wrap;' + small }, kids);
            // THE SAMPLES — two rows of boxes: the players × the tags after them
            const players = [...new Set(this.index.map((r) => String(r.player)))].sort(byName);
            const tags = [...new Set(this.index.map((r) => this.tagOf(r)))].sort(byName);
            const P = e.pick && Array.isArray(e.pick.players) ? e.pick.players : players, T = e.pick && Array.isArray(e.pick.impulses) ? e.pick.impulses : tags.filter((t) => !this.index.some((r) => r.kind === 'processed' && this.tagOf(r) === t));
            const boxes = (all, on, label, write) => {
                const wrap = el('span', { style: 'display:inline-flex;flex-wrap:wrap;gap:2px 8px;' + small });
                for (const v of all) {
                    const cb = el('input', { type: 'checkbox', checked: on.includes(v), style: 'margin:0 2px 0 0;vertical-align:middle' });
                    cb.addEventListener('change', () => regen(() => { const now = all.filter((x) => (x === v ? cb.checked : on.includes(x))); write(now); }));
                    wrap.appendChild(el('label', { style: 'white-space:nowrap' }, [cb, el('span', { textContent: label(v) })]));
                }
                return wrap;
            };
            const pickSet = (k) => (now) => { if (!e.pick) e.pick = {}; e.pick[k] = now; };
            sec.appendChild(rowEl('Players', boxes(players, P, (v) => v, pickSet('players'))));
            sec.appendChild(rowEl('Impulses', boxes(tags, T, (v) => v.replace(/^impulse-/, ''), pickSet('impulses'))));
            // THE SHAPE — the drawer's menu; a run's calculator the host's, absent from the menu when the page has none
            const shapes = SHAPES.map(([v, t]) => { const none = (v === 'accel' && !o.accel) || (v === 'containers' && !o.containers); return [v, t + (none ? ' (not in this page)' : ''), none]; });
            sec.appendChild(rowEl('Shape', sel('shape', shapes)));
            if (cfg.shape === 'accel' && o.accel) {
                const AC = o.accel, sh = AC.shapeOf(cfg.aShape);
                sec.appendChild(rowEl('run', sel('aShape', AC.SHAPES.map((s) => [s.key, s.label]))));
                if (sh.dial) sec.appendChild(rowEl(sh.dial.label, num(DIAL_KEY[sh.dial.key], sh.dial.min, sh.dial.max, sh.dial.step)));
                sec.appendChild(rowEl('gap (first)', pair(num('aFirst', 1, 60000, 1), tiny('ms'))));
                sec.appendChild(rowEl('→ last', pair(num('aFloor', 1, 60000, 1), tiny('ms' + (sh.flat ? ' (ignored: an even run)' : '')))));
                const lenBy = (cfg.aShape === 'even' && cfg.aLen !== 'count') ? 'duration' : cfg.aLen;
                const lenSel = sel('aLen', [['ratio', 'steep', !!sh.flat], ['count', 'notes'], ['duration', '= ms']]);
                sec.appendChild(rowEl('length by', pair(lenSel, lenBy === 'ratio' ? num('aRatio', 0.5, 0.99, 0.01) : lenBy === 'count' ? num('aCount', 2, 500, 1) : num('aDur', 1, 600000, 10, false, 72), tiny(lenBy === 'ratio' ? 'each gap this fraction of the one before' : lenBy === 'count' ? 'notes' : 'ms'))));
                sec.appendChild(rowEl('jitter %', pair(num('aJit', 0, 100, 1), tiny('→'), num('aJitEnd', 0, 100, 1, true), tiny('(blank = same)'))));
                sec.appendChild(rowEl('hold', pair(num('aHold', 0, 200, 1), tiny('gaps at → last'), chk('aMirror', 'mirror'))));
                sec.appendChild(rowEl('level dB', pair(num('aDb0', -60, 12, 1, true), tiny('→'), num('aDb1', -60, 12, 1, true), tiny('curve'), num('aDbCurve', -1, 1, 0.05), tiny('(blank = unity)'))));
                sec.appendChild(rowEl('deal', pair(sel('aDeal', [['robin', 'round robin'], ['free', 'free']]), tiny('re-attack ≥'), num('aMin', 0, 10000, 10), tiny('ms, the same sample'))));
            } else if (cfg.shape === 'containers' && o.containers) {
                const T = o.containers;
                sec.appendChild(rowEl('values', pair(text('cValues', 100), tiny('×'), num('cUnit', 0.001, 60, 0.1, false, 52), tiny('s'))));
                sec.appendChild(rowEl('weights', pair(text('cWeights', 100), tiny('(blank = even)'))));
                sec.appendChild(rowEl('total', pair(num('cTotal', 0.1, 3600, 1), tiny('s to fill'))));
                sec.appendChild(rowEl('order', pair(tiny('stick'), num('cStick', 0, 3, 0.05, false, 52), tiny('jump'), num('cJump', 0, 1, 0.01, false, 52))));
                sec.appendChild(rowEl('contour', sel('cContour', T.CONTOURS.map(([k, t]) => [k, t]))));
                if (cfg.cContour !== 'flat') sec.appendChild(rowEl('', pair(tiny('turn'), num('cTurn', 0, 1, 0.05, false, 52), tiny('bow'), num('cBow', 0.1, 5, 0.1, false, 52), tiny('depth'), num('cDepth', 0, 3, 0.1, false, 52))));
            } else if (cfg.shape !== 'unison') {
                sec.appendChild(rowEl('= ms', num('spanMs', 0, 600000, 10, false, 72)));
                sec.appendChild(rowEl('gap', pair(num('gapMs', 0, 60000, 10), tiny('ms (above 0: the span = gap × (n − 1))'))));
            }
            if (cfg.shape !== 'accel') sec.appendChild(rowEl('jitter', pair(num('jitterMs', 0, 5000, 5), tiny('ms, all but the first'))));
            sec.appendChild(rowEl('order', pair(sel('order', [['named', 'as named'], ['byImpulse', 'by impulse, then name'], ['shuffled', 'shuffled']]),
                btn('shuffle order', () => regen(() => { cfg.order = 'shuffled'; cfg.oSeed = (+cfg.oSeed || 0) + 1; }), 'another shuffle of the samples (its own seed)'))));
            sec.appendChild(rowEl('seed', pair(num('seed', 0, 999999, 1), btn('reshuffle', () => regen(() => { cfg.seed = (+cfg.seed || 0) + 1; }), 'the rhythm rolled again: seed + 1'))));
            sec.appendChild(rowEl('', pair(
                btn('generate', () => regen(() => {}), 'again, from the bank as it is now'),
                btn(cfg.reverse ? 'reverse ✓' : 'reverse', () => regen(() => { cfg.reverse = !cfg.reverse; }), 'the rhythm mirrored within its span'),
                btn('rotate' + (+cfg.rotate ? ' (' + cfg.rotate + ')' : ''), () => regen(() => { cfg.rotate = (Math.round(+cfg.rotate) || 0) + 1; }), 'the gaps turned by one more place'),
                btn('reset rhythm', () => regen(() => { e.rhythm = Object.assign({}, DEFAULT_RHYTHM); }), 'every dial back to its default'))));
            const pat = Array.isArray(e.pattern) ? e.pattern : [], info = this._info[String(zone.id)] || '';
            if (info) sec.appendChild(note(info));
            sec.appendChild(note(pat.length ? pat.length + ' onsets over ' + Math.round((zone.endTime - zone.startTime) * 1000) + ' ms from the brick\'s start (the live note) · one message carries them all; the engine plays each on time, no dice'
                : 'no sample picked — tick a player and an impulse, or play through the openings with the engine up'));
            if (pat.length) sec.appendChild(note(pat.slice(0, 12).map((p) => p.name + ' ' + Math.round(p.atMs) + (p.db != null ? ' (' + p.db + ' dB)' : '')).join(' · ') + (pat.length > 12 ? ' · … (' + pat.length + ')' : '')));
        },

        // ---- the transport: each brick's message, once, ahead of its start ------------------------------------------------
        tick(host, t) {
            const look = this.opts.lookAheadS;
            const fresh = this._pass !== host.playStartTime || this._prev == null || Math.abs(t - this._prev) > 0.5;
            const from = fresh ? t - 1e-6 : this._prev + look, to = t + look;
            this._pass = host.playStartTime; this._prev = t;
            if (!window.LE) return;
            for (const z of host.objects) {
                if (!this.is(z) || !z.elec) continue;
                const ahead = z.startTime > from && z.startTime <= to;
                const inside = fresh && z.midiModel === 'elecOpen' && z.startTime <= t && z.endTime > t + 0.02;   // the playhead starts inside an opening
                if (!ahead && !inside) continue;
                if (host.isPartAudible && !host.isPartAudible(z.layer)) continue;
                this.fire(host, z, inside ? t : z.startTime);
            }
        },
        fire(host, z, at) {
            const e = z.elec, perf = host.playStartTime + (at - host.playStartOffset / host.pixelsPerSecond) * 1000;
            const dueMs = Math.max(0, Math.round(((Number.isFinite(perf) ? perf : performance.now()) - performance.now()) * 10) / 10);
            if (z.midiModel === 'elecProcess') { if (this.processFire) this.processFire(host, z, at, dueMs); return; }   // le_process.js: a rendered stage is played as a return
            if (z.midiModel === 'elecOpen') {
                const player = this.playerOf(z.layer);
                if (!player) { this.say('mic opening ' + e.name + ': no microphone on ' + this.opts.laneLabel(z.layer) + ' — nothing is recorded'); return; }
                const lengthMs = Math.round((z.endTime - at) * 1000);
                LE.send('open', { player, lane: z.layer, id: String(z.id), name: safe(e.name), category: String(e.category || ''), t: r3(at), lengthMs, dueMs });
                setTimeout(() => this.loadIndex(), dueMs + lengthMs + 1200);   // the engine has cropped and indexed it by then
            } else if (e.behaviour === 'arChain') {   // the live note is the brick's start + the region; the first sample's ar roll needs the lead
                const names = (Array.isArray(e.names) && e.names.length ? e.names : [e.name]).map(safe);
                const ref = r3(z.startTime + this.opts.arRegionMs / 1000), perfR = host.playStartTime + (ref - host.playStartOffset / host.pixelsPerSecond) * 1000;
                const dueR = Math.max(0, Math.round(((Number.isFinite(perfR) ? perfR : performance.now()) - performance.now()) * 10) / 10);
                LE.send('play', { name: names[0], names: names.join(','), id: String(z.id), lane: z.layer, t: ref, dueMs: dueR, behaviour: 'arChain' });
            } else if (e.behaviour === 'chain') {   // the live note is the brick's START; the samples, in order, go with the message
                const names = (Array.isArray(e.names) && e.names.length ? e.names : [e.name]).map(safe);
                LE.send('play', { name: names[0], names: names.join(','), id: String(z.id), lane: z.layer, t: r3(at), dueMs, behaviour: 'chain' });
            } else if (e.behaviour === 'pattern') {   // the composed rhythm: ONE message, every onset from the brick's START; the engine plays each on time, no dice
                const pat = Array.isArray(e.pattern) ? e.pattern.filter((p) => p && safe(p.name)) : [];
                if (!pat.length) { this.say('pattern on ' + this.opts.laneLabel(z.layer) + ': no sample picked — nothing is played'); return; }
                LE.send('play', { name: safe(pat[0].name), pattern: pat.map((p) => safe(p.name) + ':' + (Math.round((+p.atMs || 0) * 10) / 10) + (p.db != null && isFinite(+p.db) ? ':' + (Math.round(+p.db * 10) / 10) : '')).join(','), id: String(z.id), lane: z.layer, t: r3(at), dueMs, behaviour: 'pattern' });
            } else if (e.behaviour) {   // the message points at the CENTRE (the live note) and names the behaviour; the engine rolls
                const c = r3((z.startTime + z.endTime) / 2), perfC = host.playStartTime + (c - host.playStartOffset / host.pixelsPerSecond) * 1000;
                const dueC = Math.max(0, Math.round(((Number.isFinite(perfC) ? perfC : performance.now()) - performance.now()) * 10) / 10);
                LE.send('play', { name: safe(e.name), id: String(z.id), lane: z.layer, t: c, dueMs: dueC, behaviour: String(e.behaviour) });
            } else {
                LE.send('play', { name: safe(e.name), id: String(z.id), lane: z.layer, t: r3(at), dueMs });
            }
        },
    };
    window.LEObjects = LEObjects;
})();
