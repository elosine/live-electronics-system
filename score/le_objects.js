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
//   midiModel 'elecPlay'   THE RETURN.   elec: { name, behaviour?, label? }   (label: a tag shown first on the brick — a number, a word)
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
//       elec.pattern = [{ name, atMs, db?, variant? }]
//       from the brick's START (the live note), its length the span. ONE message carries the onsets and the engine plays each
//       on time — the same in concert and in simulation. A message onset is name:atMs or name:atMs:db (a level ramp). The simple
//       shapes are this file's own (rhythm()); a run's calculator comes in through attach() — the module leans on no file of a
//       piece's stack, it is HANDED what it may use.
//       Played through, it sends   /le/play   name · id · lane · t · dueMs   and the engine plays the banked sample WHERE THE
//       BRICK IS. Its length is the sample's, read from the bank's index; its lane says whose staff it is drawn on.
//       KEY (`r` in the first): at the playhead — the sample of the selected opening, else of the nearest opening before
//       the playhead; the panel's picker lists every sample in the index.
//
//       THE PROCESSED RETURN (the same day; the first piece's "every return a transformation"): elec.variants = { '<sample>':
//       '<key>-<env>' } — per sample the brick plays, a PRESET of the piece's presets file (opts.presetsUrl: one effect of the
//       chain, a class that sets its length as a multiple of the sample's) under an ENVELOPE of that file. The brick then asks for
//       <sample>~<key>-<env>. The score is a PLAN:   /le/plan   stamp · part · of · rows · [render]   tells the engine every
//       variant the bricks will ask for, with the time of its first use (at a pass's start · a second after a change · with the
//       panel's button, render 1); the engine renders each right after its sample's capture and falls back to the sample, raw,
//       when one is asked for too early (sc/process.scd · sc/bank.scd sampleFor).
//       A PATTERN DEALS A PRESET PER IMPACT (the first piece's DEC-28, 2026-10-05): elec.fx = { mode 'none' | 'each', env, cls, seed }
//       — at Generate every onset gets its own preset, round robin through the file's presets (one shuffle by the seed, none twice
//       until all are used; cls narrows the pool to one class), under ONE envelope or the file's mix; written as
//       pattern[i].variant = '<key>-<env>', so that onset asks for <sample>~<key>-<env> and the plan carries each variant at the
//       onset's own time. The brick's two rows of boxes offer the RAW samples only — captured, never a render of any kind.
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
        elecProcess: { kind: 'process', sign: '⟳', color: '#EF6C00', yOffset: 0.5, title: 'Process — a stage of the chain' },   // le_process.js · yOffset is a FRACTION of the lane (0 top · 1 bottom): 2 drew the brick a lane too low (SWEEP_LIST #5)
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
    // a pattern's effects (DEC-28): none — the samples raw · each — a preset per impact; env one of the file's envelopes or 'mix'; cls 'all' or one class
    const DEFAULT_FX = { mode: 'none', env: 'tail', cls: 'all', seed: 1 };
    const SHAPES = [['unison', 'unison'], ['even', 'even'], ['front', 'front-loaded'], ['back', 'back-loaded'], ['centre', 'centre'], ['edges', 'edges'], ['random', 'random'], ['accel', 'accel · round robin'], ['containers', 'containers']];
    const DIAL_KEY = { curve: 'aCurve', ease: 'aEase', knee: 'aKnee', gamma: 'aGamma' };   // a run shape's one dial (AccelCalc.SHAPES[].dial.key) → the brick's field
    const shuffled = (arr, rnd) => { const a = arr.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
    const permutations = (arr) => { if (arr.length <= 1) return [arr.slice()]; const out = []; arr.forEach((x, i) => { permutations(arr.slice(0, i).concat(arr.slice(i + 1))).forEach((p) => out.push([x].concat(p))); }); return out; };

    const LEObjects = {
        MODELS, host: null, index: [], _pass: null, _prev: null, _info: {},   // _info: a pattern brick's readout by zone id (never saved)
        presets: null,   // the piece's presets file { classes, envelopes, presets } (opts.presetsUrl) — null: this piece has none, every return is raw
        opts: { keys: { open: 'm', play: 'r', process: 'e' }, portOf: () => null, laneLabel: (l) => 'lane ' + l, lanes: 99,
            indexUrl: '/bank/samples/index.json', presetsUrl: '/bank/presets.json', lookAheadS: 0.1, openMs: 500, preMs: 100, arRegionMs: 400, chainLinkS: 0.5 },

        is(o) { return !!(o && o.type === 'zone' && MODELS[o.midiModel]); },
        zones(model) { return (this.host ? this.host.objects : []).filter((o) => this.is(o) && (!model || o.midiModel === model)); },
        row(name) { return this.index.find((x) => x.name === name) || null; },
        captured() { return this.index.filter((x) => x.kind !== 'processed'); },   // what '*' plays: a render is not one of "every sample"
        choosable() { return this.index.filter((x) => !x.planned); },             // what a picker offers: a plan's variant is chosen on its brick, never as a sample
        raw(r) { return !!r && r.kind !== 'processed' && !r.planned && !String(r.name || '').includes('~'); },   // a RAW sample: captured, not a render of any kind — what a pattern's boxes offer (DEC-28)
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
            this.loadPresets();
            // the plan follows the bricks: a second after the score last changed, if what it asks of the engine is different
            const dirty = host.markDirty;
            if (typeof dirty === 'function') host.markDirty = function () { const r = dirty.apply(this, arguments); self.planSoon(); return r; };
            return this;
        },

        // ---- THE PROCESSED RETURN (2026-10-05; the Decibel piece's 10.8 · DEC-21 · 22): every return may be a TRANSFORMATION ----------
        // elec.variants = { '<sample>': '<key>-<env>' } — one per sample the brick plays: a PRESET of the piece's file (one effect of
        // the engine's chain) under an ENVELOPE. The brick then asks for  <sample>~<key>-<env>  instead of the sample. THE SCORE IS A
        // PLAN: the page tells the engine every variant its bricks will ask for (/le/plan — at a pass's start, after a change, with the
        // button) and the ENGINE renders each as soon as its sample is captured, the soonest-needed first; asked for before it is ready,
        // a variant falls back to the sample, raw (sc/bank.scd sampleFor). The same messages in concert and in simulation.
        loadPresets() {
            return fetch(this.opts.presetsUrl, { cache: 'no-store' })
                .then((r) => (r.ok ? r.json() : null))
                .then((doc) => { this.presets = doc && Array.isArray(doc.presets) ? doc : null; this.redraw(); return this.presets; })
                .catch(() => this.presets);
        },
        // the samples a return brick plays, by name ('*' is the bank at playback: it has no variant)
        samplesOf(e) {
            if (!e) return [];
            if (e.behaviour === 'pattern') return [...new Set((Array.isArray(e.pattern) ? e.pattern : []).map((p) => p && p.name).filter(Boolean))];
            if ((e.behaviour === 'chain' || e.behaviour === 'arChain') && Array.isArray(e.names) && e.names.length) return e.names.filter((n) => n && n !== '*');
            return e.name && e.name !== '*' ? [e.name] : [];
        },
        variantOf(e, name) { const v = e && e.variants && e.variants[name]; return v ? safe(v) : ''; },
        splitVariant(v) { const s = String(v || ''), i = s.lastIndexOf('-'); return i > 0 ? { key: s.slice(0, i), env: s.slice(i + 1) } : { key: s, env: '' }; },
        // the name a brick asks the engine for: the sample's, or its variant's
        vname(e, name) { const v = this.variantOf(e, name); return safe(safe(name) + (v && name !== '*' ? '~' + v : '')); },
        // every variant the score's bricks ask for, once each, with the time of its first use — what the engine must have rendered by then
        planRows() {
            const P = this.presets, out = new Map();
            if (!P) return [];
            const add = (name, v, t) => {
                const { key, env } = this.splitVariant(v), p = P.presets.find((x) => x.key === key), E = (P.envelopes || {})[env];
                if (!p || !E) return;   // a preset or an envelope the file no longer has: the sample returns raw
                const id = safe(name) + '~' + v, was = out.get(id), cls = (P.classes || {})[p.class] || {};
                if (was) { if (t < was.t) was.t = t; return; }
                out.set(id, { base: safe(name), suffix: v, effect: String(p.effect || '').replace(/[^A-Za-z0-9 _+-]/g, '').slice(0, 40), end: env === 'tail' ? 'tail' : env,
                    atkMs: +E.atkMs || 0, durX: +(p.durX || cls.durX || 1), match: p.match === 0 ? 0 : 1, t, capMs: env === 'tail' ? (p.capMs || E.capMs || 4000) : 0, args: p.args || {} });   // capMs may be a range [lo, hi]: drawn at the send
            };
            for (const z of this.zones('elecPlay')) {
                const e = z.elec;
                if (!e) continue;
                if (e.behaviour === 'pattern') {   // a preset per impact (DEC-28): each onset's own variant, at the onset's own time — else the brick's per-sample one
                    for (const p of (Array.isArray(e.pattern) ? e.pattern : [])) { const v = p && p.name ? (p.variant ? safe(p.variant) : this.variantOf(e, p.name)) : ''; if (v) add(p.name, v, r3(z.startTime + (+p.atMs || 0) / 1000)); }
                    continue;
                }
                if (!e.variants) continue;
                for (const name of this.samplesOf(e)) { const v = this.variantOf(e, name); if (v) add(name, v, r3(z.startTime)); }
            }
            return [...out.values()].sort((a, b) => a.t - b.t);
        },
        planSig(rows) { return JSON.stringify(rows.map((r) => [r.base, r.suffix, r.t])); },
        // the plan to the engine, in parts of six variants (a part is one small message; they share a stamp and may arrive in any
        // order). A dial given as a RANGE [lo, hi] is drawn here, fresh at every send. render: the engine then renders them all.
        sendPlan(render) {
            if (!window.LE || !this.presets) return 0;
            const rows = this.planRows();
            if (!rows.length && this._planSent === false) return 0;   // nothing planned, and the engine has been told so (the first send of a page goes even when empty: it clears a plan left from before)
            const lines = rows.map((r) => {
                const args = Object.keys(r.args).filter((k) => /^[A-Za-z][A-Za-z0-9]*$/.test(k)).map((k) => {
                    const v = r.args[k], x = Array.isArray(v) && v.length === 2 ? Math.round((Math.min(+v[0], +v[1]) + Math.random() * Math.abs(+v[1] - +v[0])) * 100) / 100 : +v;
                    return Number.isFinite(x) ? k + ':' + x : null;
                }).filter(Boolean).join(',');
                const cap = Array.isArray(r.capMs) && r.capMs.length === 2 ? Math.round(Math.min(+r.capMs[0], +r.capMs[1]) + Math.random() * Math.abs(+r.capMs[1] - +r.capMs[0])) : (+r.capMs || 0);   // a ring time drawn fresh (the tail's [950, 1350])
                return [r.base, r.suffix, r.effect, r.end, r.atkMs, r.durX, r.match, r.t, cap, args].join(';');
            });
            const per = 6, n = Math.max(1, Math.ceil(lines.length / per)), stamp = 'p' + Date.now().toString(36);
            for (let i = 0; i < n; i++) LE.send('plan', { stamp, part: i + 1, of: n, rows: lines.slice(i * per, (i + 1) * per).join('|'), render: render ? 1 : 0 });
            this._planSent = rows.length > 0; this._planSig = this.planSig(rows);
            return rows.length;
        },
        planSoon() {
            clearTimeout(this._planTimer);
            this._planTimer = setTimeout(() => { if (this.presets && this.planSig(this.planRows()) !== (this._planSig || '[]')) this.sendPlan(false); }, 1000);
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
                const lab = (n) => { const v = this.variantOf(e, n); return n + (v ? '~' + this.splitVariant(v).key : ''); };   // a PROCESSED return says its preset: bfl-impulse-1~crush4
                text = M.sign + ' ' + (e.name ? lab(e.name) : '?');
                if ((e.behaviour === 'chain' || e.behaviour === 'arChain') && Array.isArray(e.names) && e.names.length) text = M.sign + ' ' + (e.names.includes('*') ? 'ALL ' + this.captured().length + ' samples' : e.names.map(lab).join(' + '));
                if (e.behaviour === 'pattern') { const n = Array.isArray(e.pattern) ? e.pattern.length : 0; text = M.sign + ' ' + (n ? n + ' samples · ' + Math.round((zone.endTime - zone.startTime) * 1000) + ' ms' + (e.pattern.some((p) => p && p.variant) ? ' · a preset each' : '') : 'no sample picked'); }
                if (e.behaviour) text += ' ~ ' + String(e.behaviour).toUpperCase();
                if (e.behaviour !== 'pattern' && !this.row(e.name)) text += ' — not captured yet';
                if (e.label) text = M.sign + ' ' + String(e.label).slice(0, 48) + ' · ' + text.slice(M.sign.length + 1);   // a brick's own tag, first: a number in an audition, a chord's name, a word of his
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
                const rows = this.choosable().sort((a, b) => String(a.name).localeCompare(String(b.name)));
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
                    commit(() => {
                        const was = e.name;
                        e.name = pick.value;
                        if (e.variants && e.variants[was] && was !== e.name) { e.variants[e.name] = e.variants[was]; delete e.variants[was]; }   // the transformation stays on the brick
                        const x = this.row(e.name); if (x && x.lengthMs > 0) zone.endTime = r3(zone.startTime + x.lengthMs / 1000);
                    });
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
                        const n = e.names.includes('*') ? Math.max(1, this.captured().length) : e.names.length;   // '*': as many as the bank holds today (the captured ones)
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
                if (e.behaviour !== 'pattern') this.variantPanel(zone, sec, { el, rowEl, note, commit });
            }
            panelEl.appendChild(sec);
        },

        // ---- the processed return, in the panel: per sample the brick plays — a preset · an envelope · ▶; and the button for them all ----
        variantPanel(zone, sec, ui) {
            const h = this.host, e = zone.elec, P = this.presets, { el, rowEl, note, commit } = ui, small = 'font-size:11px';
            const names = this.samplesOf(e);
            if (!P || !names.length) return;
            const envs = Object.keys(P.envelopes || {});
            const tiny = (t) => el('span', { textContent: t, style: 'font-size:10px;color:#888;white-space:nowrap' });
            const pair = (...kids) => el('span', { style: 'display:inline-flex;align-items:center;gap:4px;flex-wrap:wrap;' + small }, kids);
            const btn = (t, fn, title) => { const b = el('button', { type: 'button', textContent: t, title: title || '', style: small }); b.addEventListener('click', fn); return b; };
            sec.appendChild(el('h5', { textContent: 'Processed as' }));
            for (const name of names) {
                const cur = this.splitVariant(this.variantOf(e, name)), known = P.presets.find((p) => p.key === cur.key);
                const set = (key, env) => commit(() => {
                    if (!e.variants) e.variants = {};
                    if (key) e.variants[name] = safe(key + '-' + (envs.includes(env) ? env : envs[0])); else delete e.variants[name];
                    if (!Object.keys(e.variants).length) delete e.variants;
                });
                const ps = el('select', { style: 'max-width:170px;' + small, title: 'the transformation this sample returns as — one effect of the chain; — raw — returns the sample as it is' });
                ps.appendChild(el('option', { value: '', textContent: '— raw —', selected: !cur.key }));
                if (cur.key && !known) ps.appendChild(el('option', { value: cur.key, textContent: cur.key + ' — not in the presets: raw', selected: true }));
                for (const p of P.presets) ps.appendChild(el('option', { value: p.key, textContent: p.name, selected: p.key === cur.key }));
                ps.addEventListener('change', () => { ps.blur(); set(ps.value, cur.env); });
                const es = el('select', { style: small, disabled: !cur.key, title: envs.map((k) => k + ' — ' + ((P.envelopes[k] || {}).what || '')).join('\n') });
                for (const k of envs) es.appendChild(el('option', { value: k, textContent: k, selected: k === cur.env }));
                es.addEventListener('change', () => { es.blur(); set(cur.key, es.value); });
                const hear = btn('▶', () => { if (window.LE) LE.send('play', { name: this.vname(e, name), id: 'audition', lane: -1, t: 0, dueMs: 0 }); this.say('▶ ' + this.vname(e, name)); },
                    'this sample as the brick will ask for it, now — raw if its variant is not rendered yet (the engine\'s window says)');
                const made = cur.key ? this.row(safe(name) + '~' + this.variantOf(e, name)) : null;
                sec.appendChild(rowEl(name, pair(ps, es, hear, tiny(!cur.key ? '' : made ? Math.round(made.lengthMs) + ' ms' : 'not rendered'))));
            }
            const rows = this.planRows(), have = rows.filter((r) => this.row(r.base + '~' + r.suffix)).length;
            sec.appendChild(rowEl('', pair(
                btn('render all planned', () => {
                    const n = this.sendPlan(true);
                    this.say(n ? 'render all planned: ' + n + ' variants asked of the engine — its window names each as it lands' : 'nothing is planned in this score — pick a preset on a return brick first');
                    for (const ms of [4000, 12000, 30000]) setTimeout(() => this.loadIndex().then(() => { if (h.selectedObject === zone) h.showPropertyPanel(); }), ms);
                }, 'the engine renders EVERY variant this score plans, from the samples the bank holds now — as it does by itself after each capture when the score is played through its openings'),
                tiny(rows.length + ' planned in this score · ' + have + ' in the bank'))));
            sec.appendChild(note('a processed return: the sample through ONE effect, under an envelope, as long as a multiple of the sample — rendered by the engine right after the sample\'s capture; asked for before it is ready, the sample returns raw (the engine\'s window says "late")'));
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
            return this.index.filter((r) => this.raw(r) && (!P || P.includes(String(r.player))) && (!T || T.includes(this.tagOf(r))));   // RAW samples only (DEC-28): a render — the workshop's or the plan's — never joins a pattern's deal
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
        // THE EFFECTS OF A PATTERN (DEC-28): the pool — the file's presets, or one class of them
        // (a preset marked `deal: false` is never dealt — a piece's audition sets, kept beside the ones it deals; the first piece's §151)
        fxPool(fx) { const P = this.presets; if (!P) return []; const pool = P.presets.filter((p) => p.deal !== false); return fx && fx.cls && fx.cls !== 'all' ? pool.filter((p) => p.class === fx.cls) : pool; },
        // a preset per impact: n variants '<key>-<env>' — the pool shuffled ONCE by the seed and dealt round robin (none twice until
        // all are used; past the pool it comes round again), under the one envelope asked for, or the file's mix as exact shares of
        // the n (the largest remainders round it), shuffled by the seed — tools/deal_variants.js's rule, for the onsets of one brick
        dealVariants(n, fx) {
            const P = this.presets, pool = this.fxPool(fx);
            if (!P || !pool.length || !(n > 0)) return [];
            const seed = +fx.seed || 0, order = shuffled(pool, mulberry32(seed * 7919 + 3)), envsAll = Object.keys(P.envelopes || {});
            let envs;
            if (fx.env === 'mix') {
                const mix = Object.entries(P.mix || { perc: 1 }).filter(([k, w]) => envsAll.includes(k) && w > 0), wSum = mix.reduce((s, [, w]) => s + w, 0) || 1;
                const share = mix.map(([k, w]) => ({ k, exact: n * w / wSum })); share.forEach((s) => { s.n = Math.floor(s.exact); });
                for (let left = n - share.reduce((s, x) => s + x.n, 0); left > 0; left--) share.slice().sort((a, b) => (b.exact - b.n) - (a.exact - a.n))[0].n++;
                envs = shuffled(share.flatMap((s) => Array(s.n).fill(s.k)), mulberry32(seed * 104729 + 17));
            } else envs = Array(n).fill(envsAll.includes(fx.env) ? fx.env : (envsAll[0] || 'tail'));
            return [...Array(n)].map((_, i) => order[i % order.length].key + '-' + envs[i]);
        },
        // Generate: the samples picked, in the order asked, on the shape's onsets → elec.pattern = [{ name, atMs, db?, variant? }]; the brick
        // runs from the live note to the last onset (a simple shape: to its span); with fx.mode 'each', a preset per onset (DEC-28)
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
            const fx = e.fx || (e.fx = Object.assign({}, DEFAULT_FX));
            for (const k of Object.keys(DEFAULT_FX)) if (fx[k] === undefined) fx[k] = DEFAULT_FX[k];
            if (fx.mode === 'each') { const vs = this.dealVariants(events.length, fx); events.forEach((ev, i) => { if (vs[i]) ev.variant = vs[i]; }); }   // a preset per impact (DEC-28)
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
            const rawRows = this.index.filter((r) => this.raw(r));   // the RAW samples only (DEC-28): no render of the workshop's, none of the plan's
            const players = [...new Set(rawRows.map((r) => String(r.player)))].sort(byName);
            const tags = [...new Set(rawRows.map((r) => this.tagOf(r)))].sort(byName);
            const P = e.pick && Array.isArray(e.pick.players) ? e.pick.players : players, T = e.pick && Array.isArray(e.pick.impulses) ? e.pick.impulses : tags;
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
            // THE EFFECTS — a preset per impact (DEC-28): the file's presets dealt round robin onto the onsets, under one envelope or the mix
            const fx = e.fx || (e.fx = Object.assign({}, DEFAULT_FX)), PR = this.presets;
            for (const k of Object.keys(DEFAULT_FX)) if (fx[k] === undefined) fx[k] = DEFAULT_FX[k];
            const fsel = (key, options) => { const s = el('select'); for (const [v, t] of options) s.appendChild(el('option', { value: v, textContent: t, selected: String(fx[key]) === String(v) })); s.addEventListener('change', () => { s.blur(); regen(() => { fx[key] = s.value; }); }); return s; };
            if (!PR) sec.appendChild(rowEl('Effects', tiny('this piece has no presets file — the samples play raw')));
            else {
                const pool = this.fxPool(fx), envs = Object.keys(PR.envelopes || {});
                const fseed = el('input', { type: 'number', value: String(fx.seed), min: '0', max: '999999', step: '1', style: 'width:62px' });
                fseed.addEventListener('change', () => regen(() => { fx.seed = Math.max(0, +fseed.value || 0); }));
                const more = fx.mode === 'each' ? [tiny('envelope'), fsel('env', envs.map((k) => [k, k === 'tail' ? 'tail — the ring version' : k]).concat([['mix', 'the mix (' + Object.entries(PR.mix || {}).map(([k, w]) => k + ' ' + Math.round(w * 100)).join(' · ') + ')']])),
                    tiny('class'), fsel('cls', [['all', 'all']].concat(Object.keys(PR.classes || {}).map((c) => [c, c]))),
                    tiny('seed'), fseed, btn('redeal', () => regen(() => { fx.seed = (+fx.seed || 0) + 1; }), 'the presets dealt again: seed + 1')] : [];
                sec.appendChild(rowEl('Effects', pair(fsel('mode', [['none', 'none — the samples raw'], ['each', 'a preset for every impact']]), ...more)));
                if (fx.mode === 'each') sec.appendChild(note(pool.length + ' presets' + (fx.cls !== 'all' ? ' of class ' + fx.cls : '') + ' dealt round robin, none twice until all are used'
                    + (pat.length > pool.length ? ' — ' + pat.length + ' onsets: a preset comes round again after ' + pool.length : '') + ' · ' + (fx.env === 'mix' ? 'the envelopes by the mix' : 'envelope ' + fx.env) + ' · each onset asks for <sample>~<preset>-<envelope>; the plan renders each by its own time'));
            }
            if (info) sec.appendChild(note(info));
            sec.appendChild(note(pat.length ? pat.length + ' onsets over ' + Math.round((zone.endTime - zone.startTime) * 1000) + ' ms from the brick\'s start (the live note) · one message carries them all; the engine plays each on time, no dice'
                : 'no sample picked — tick a player and an impulse, or play through the openings with the engine up'));
            if (pat.length) sec.appendChild(note(pat.slice(0, 12).map((p) => p.name + (p.variant ? '~' + p.variant : '') + ' ' + Math.round(p.atMs) + (p.db != null ? ' (' + p.db + ' dB)' : '')).join(' · ') + (pat.length > 12 ? ' · … (' + pat.length + ')' : '')));
        },

        // ---- the transport: each brick's message, once, ahead of its start ------------------------------------------------
        tick(host, t) {
            const look = this.opts.lookAheadS;
            const newPass = this._pass !== host.playStartTime;
            const fresh = newPass || this._prev == null || Math.abs(t - this._prev) > 0.5;
            const from = fresh ? t - 1e-6 : this._prev + look, to = t + look;
            this._pass = host.playStartTime; this._prev = t;
            if (!window.LE) return;
            if (newPass) this.sendPlan(false);   // a pass begins: the engine is told what the bricks will ask for, before the first capture ends (it may have been restarted since)
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
                const names = (Array.isArray(e.names) && e.names.length ? e.names : [e.name]).map((n) => this.vname(e, n));   // each sample's variant, if it has one (10.8)
                const ref = r3(z.startTime + this.opts.arRegionMs / 1000), perfR = host.playStartTime + (ref - host.playStartOffset / host.pixelsPerSecond) * 1000;
                const dueR = Math.max(0, Math.round(((Number.isFinite(perfR) ? perfR : performance.now()) - performance.now()) * 10) / 10);
                LE.send('play', { name: names[0], names: names.join(','), id: String(z.id), lane: z.layer, t: ref, dueMs: dueR, behaviour: 'arChain' });
            } else if (e.behaviour === 'chain') {   // the live note is the brick's START; the samples, in order, go with the message
                const names = (Array.isArray(e.names) && e.names.length ? e.names : [e.name]).map((n) => this.vname(e, n));
                LE.send('play', { name: names[0], names: names.join(','), id: String(z.id), lane: z.layer, t: r3(at), dueMs, behaviour: 'chain' });
            } else if (e.behaviour === 'pattern') {   // the composed rhythm: ONE message, every onset from the brick's START; the engine plays each on time, no dice
                const pat = Array.isArray(e.pattern) ? e.pattern.filter((p) => p && safe(p.name)) : [];
                if (!pat.length) { this.say('pattern on ' + this.opts.laneLabel(z.layer) + ': no sample picked — nothing is played'); return; }
                const nm = (p) => (p.variant ? safe(safe(p.name) + '~' + safe(p.variant)) : this.vname(e, p.name));   // a preset per impact (DEC-28), else the brick's per-sample variant
                LE.send('play', { name: nm(pat[0]), pattern: pat.map((p) => nm(p) + ':' + (Math.round((+p.atMs || 0) * 10) / 10) + (p.db != null && isFinite(+p.db) ? ':' + (Math.round(+p.db * 10) / 10) : '')).join(','), id: String(z.id), lane: z.layer, t: r3(at), dueMs, behaviour: 'pattern' });
            } else if (e.behaviour) {   // the message points at the CENTRE (the live note) and names the behaviour; the engine rolls
                const c = r3((z.startTime + z.endTime) / 2), perfC = host.playStartTime + (c - host.playStartOffset / host.pixelsPerSecond) * 1000;
                const dueC = Math.max(0, Math.round(((Number.isFinite(perfC) ? perfC : performance.now()) - performance.now()) * 10) / 10);
                LE.send('play', { name: this.vname(e, e.name), id: String(z.id), lane: z.layer, t: c, dueMs: dueC, behaviour: String(e.behaviour) });
            } else {
                LE.send('play', { name: this.vname(e, e.name), id: String(z.id), lane: z.layer, t: r3(at), dueMs });
            }
        },
    };
    window.LEObjects = LEObjects;
})();
