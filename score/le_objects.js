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
//       Played through, it sends   /le/play   name · id · lane · t · dueMs   and the engine plays the banked sample WHERE THE
//       BRICK IS. Its length is the sample's, read from the bank's index; its lane says whose staff it is drawn on.
//       KEY (`r` in the first): at the playhead — the sample of the selected opening, else of the nearest opening before
//       the playhead; the panel's picker lists every sample in the index.
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
    };
    const r3 = (x) => Math.round(x * 1000) / 1000;
    const safe = (s) => (s === '*' ? '*' : String(s == null ? '' : s).replace(/[^A-Za-z0-9_-]/g, '').slice(0, 64));   // a name is a file name (sc/bank.scd); '*' = every sample

    const LEObjects = {
        MODELS, host: null, index: [], _pass: null, _prev: null,
        opts: { keys: { open: 'm', play: 'r' }, portOf: () => null, laneLabel: (l) => 'lane ' + l, lanes: 99,
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
                if (z._els) h.renderZone(z);
            }
        },

        // ---- the drawing: the label says what the brick is ----------------------------------------------------------------
        decorate(zone) {
            const g = zone._els && zone._els.group, e = zone.elec;
            if (!g || !e) return;
            const M = MODELS[zone.midiModel], label = g.querySelector('text');
            let text = M.sign + ' ' + (e.name || '?');
            if (zone.midiModel === 'elecOpen') {
                const p = this.playerOf(zone.layer);
                if (p !== undefined) { e.player = p || ''; if (!p) text += ' — no microphone on this lane'; }
            } else {
                if ((e.behaviour === 'chain' || e.behaviour === 'arChain') && Array.isArray(e.names) && e.names.length) text = M.sign + ' ' + (e.names.includes('*') ? 'ALL ' + this.index.length + ' samples' : e.names.join(' + '));
                if (e.behaviour) text += ' ~ ' + String(e.behaviour).toUpperCase();
                if (!this.row(e.name)) text += ' — not captured yet';
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
                sec.appendChild(rowEl('Sample', pick));
                // the behaviour (step 9): plain = the sample where the brick is · ar = rolled by the engine around the brick's centre
                const beh = el('select');
                beh.appendChild(el('option', { value: '', textContent: 'where the brick is', selected: !e.behaviour }));
                beh.appendChild(el('option', { value: 'ar', textContent: 'anticipation-reaction around the centre', selected: e.behaviour === 'ar' }));
                beh.appendChild(el('option', { value: 'chain', textContent: 'chain — the samples follow the live note, one after another', selected: e.behaviour === 'chain' }));
                beh.appendChild(el('option', { value: 'arChain', textContent: 'ar + chain — one sample around the live note, the rest after it', selected: e.behaviour === 'arChain' }));
                beh.addEventListener('change', () => {
                    beh.blur();
                    commit(() => {
                        const R = this.opts.arRegionMs / 1000, x = this.row(e.name);
                        const ref = e.behaviour === 'ar' ? r3((zone.startTime + zone.endTime) / 2) : e.behaviour === 'arChain' ? r3(zone.startTime + R) : zone.startTime;   // where the live note is, whatever the brick was
                        if (beh.value === 'ar') { e.behaviour = 'ar'; zone.startTime = r3(Math.max(0, ref - R)); zone.endTime = r3(ref + R); }
                        else if (beh.value === 'chain') { e.behaviour = 'chain'; if (!Array.isArray(e.names) || !e.names.length) e.names = [e.name]; zone.startTime = ref; zone.endTime = r3(ref + this.opts.chainLinkS * e.names.length); }
                        else if (beh.value === 'arChain') { e.behaviour = 'arChain'; if (!Array.isArray(e.names) || !e.names.length) e.names = [e.name]; zone.startTime = r3(Math.max(0, ref - R)); zone.endTime = r3(ref + R + this.opts.chainLinkS * (e.names.length - 1)); }
                        else { delete e.behaviour; zone.startTime = ref; zone.endTime = r3(ref + ((x && x.lengthMs > 0 ? x.lengthMs : this.opts.openMs) / 1000)); }
                    });
                });
                sec.appendChild(rowEl('Behaviour', beh));
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
                sec.appendChild(note(row ? 'from ' + row.player + (row.category ? ' · ' + row.category : '') + ' · ' + Math.round(row.lengthMs) + ' ms · peak ' + row.peakDb + ' dB · taken ' + String(row.captured || '').replace('T', ' ')
                    : 'its length becomes the sample\'s once it is captured'));
            }
            panelEl.appendChild(sec);
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
