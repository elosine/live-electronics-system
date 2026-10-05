// le_process.js — THE THIRD COMPOSER-SCORE OBJECT FOR THE ELECTRONICS: THE PROCESS BRICK, and the catalogue of effects it offers
// (the engine plan's parts 6 · 11; first built in the Decibel piece, 2026-10-05 — its PLAN 1.3 · RUNNING_LOG §103).
// A piece's composer page loads it with ONE tag, after le_objects.js —   <script src="/electronics/le_process.js"></script>
// — and names its key in the attach line (keys.process; `e` in the first piece). It is a MIXIN on LEObjects: that file knows
// only that 'elecProcess' is one of its models and hands this one the label, the panel, the redraw, the key and the tick.
//
//   midiModel 'elecProcess'   A STAGE OF A CHAIN.   elec: { source, out, label, effect, args, end, … , rendered }
//       A banked sample (source) put through ONE configuration of the engine's chain (sc/process.scd) and banked again under a
//       name of its own (out) — <root>~1, ~2, … : the root is the sample the chain began from. The next brick's source is this
//       brick's out: each stage is made FROM the one before, and every stage is kept ("I am sitting in a room").
//       RENDER (the panel's button) sends   /le/process   source · out · effect · args · end · … · id   and the engine renders it
//       OFFLINE and indexes it; this file waits for the row that carries its id, then the brick is as long as its sample.
//       Played through, a rendered brick sends exactly a plain return's message:   /le/play   name = out.
//       KEY: at the playhead — its source the selected brick's sample, else the nearest return or stage before the playhead.
//
//   THE CATALOGUE (EFFECTS, below) is the chain's stages, by name, each with the few dials that matter and the engine's own
//   control names under them: a brick's args are   { controlName: value }   — what the message carries. A stage is ALONE when
//   its mix is up and nothing else is; the JSON box takes ANY of the chain's controls, so two stages at once is a brick too.
//   HOW IT ENDS: shape — an envelope after the effect (attack · length · release · curve): the processed timbre with a struck
//   shape · tail — it rings out to floorDb under its own peak, or to capMs past the source. LEVEL: its peak as its source's
//   (match), then gainDb.
//
// Nothing in this file knows a piece. What it asks of LEObjects: MODELS.elecProcess · host · opts · index · row · zones · make ·
// is · say · redraw · loadIndex · _info. What it asks of the page: window.LE (le_msg.js).
(function () {
    'use strict';
    const L = window.LEObjects;
    if (!L) return;
    const r3 = (x) => Math.round(x * 1000) / 1000;
    const safe = (s) => String(s == null ? '' : s).replace(/[^A-Za-z0-9_~-]/g, '').slice(0, 64);   // a name is a file name (sc/bank.scd)
    const byName = (a, b) => String(a).localeCompare(String(b), undefined, { numeric: true });
    const D = (key, label, min, max, step, def, unit) => ({ key, label, min, max, step, def, unit: unit || '' });
    const O = (key, label, options, def) => ({ key, label, options, def });

    // THE CATALOGUE — the chain's stages in the order the chain runs them (sc/process.scd); `on` is what the stage needs besides its dials
    const EFFECTS = [
        { key: 'tape', label: 'tape — speed and direction', dials: [D('rate', 'speed ×', 0.05, 8, 0.01, 0.5), O('rev', 'direction', [[0, 'forward'], [1, 'reversed']], 0)] },
        { key: 'noise', label: 'noise bed — follows the sample\'s envelope', dials: [D('noise', 'amount', 0, 1, 0.05, 0.5), D('noiseCut', 'cutoff', 200, 16000, 100, 8000, 'Hz')] },
        { key: 'resonator', label: 'resonator bank — four ringing bands', dials: [D('resMix', 'mix', 0, 1, 0.05, 1), D('resDcy', 'decay', 0.02, 3, 0.02, 0.6, 's'), D('rlo', '110 Hz', 0, 1, 0.05, 0.5), D('rlomid', '440 Hz', 0, 1, 0.05, 0.5), D('rhimid', '1600 Hz', 0, 1, 0.05, 0.5), D('rhi', '5200 Hz', 0, 1, 0.05, 0.5)] },
        { key: 'cres', label: 'complex resonator — one ringing partial', dials: [D('cresMix', 'mix', 0, 1, 0.05, 1), D('cresFreq', 'pitch', 20, 8000, 1, 300, 'Hz'), D('cresDcy', 'decay', 0.01, 0.99, 0.01, 0.6)] },
        { key: 'drive', label: 'drive — six shapers', dials: [D('shapeMix', 'mix', 0, 1, 0.05, 1), O('driveType', 'shaper', [[0, 'tanh'], [1, 'sine'], [2, 'crossover'], [3, 'fold'], [4, 'bitcrush'], [5, 'disintegrate']], 0), D('drive', 'drive', 1, 40, 0.5, 8), D('driveArg', 'character', 0.05, 1, 0.05, 0.5)] },
        { key: 'ring', label: 'ring modulation — a sine carrier', dials: [D('rmMix', 'mix', 0, 1, 0.05, 1), D('rmFreq', 'carrier', 20, 8000, 1, 300, 'Hz')] },
        { key: 'diode', label: 'diode ring modulation — the circuit, gritty', dials: [D('drmMix', 'mix', 0, 1, 0.05, 1), D('drmFreq', 'carrier', 10, 6000, 1, 180, 'Hz')] },
        { key: 'shift', label: 'frequency shift — detunes, inharmonic', dials: [D('fsMix', 'mix', 0, 1, 0.05, 1), D('fsHz', 'shift', -1200, 1200, 1, 120, 'Hz')] },
        { key: 'comb', label: 'comb — a delay that rings at a pitch', dials: [D('combMix', 'mix', 0, 1, 0.05, 1), D('combTime', 'delay', 0.002, 0.5, 0.001, 0.012, 's'), D('combFb', 'ring', 0.01, 4, 0.05, 0.8, 's')] },
        { key: 'filter', label: 'filter — four models', dials: [D('filtMix', 'mix', 0, 1, 0.05, 1), O('filtType', 'model', [[0, 'MoogFF'], [1, 'Moog ladder'], [2, 'LPF18'], [3, 'RLPFD']], 0), D('cut', 'cutoff', 80, 16000, 10, 1200, 'Hz'), D('res', 'resonance', 0, 3.9, 0.05, 0.5), D('filtDist', 'distortion', 0, 1, 0.05, 0.4), D('hpf', 'high-pass', 20, 2000, 5, 30, 'Hz')] },
        { key: 'string', label: 'string resonator — a plucked string', dials: [D('stresMix', 'mix', 0, 1, 0.05, 1), D('stresTime', 'delay', 0.0002, 0.05, 0.0001, 0.003, 's'), D('stresRes', 'resonance', 0, 0.99, 0.01, 0.9)] },
        { key: 'diffusion', label: 'diffusion — smears the attack, no tail', dials: [D('diffMix', 'mix', 0, 1, 0.05, 1), D('diffTime', 'time', 0.0005, 0.05, 0.0005, 0.02, 's'), D('diffGain', 'amount', 0, 0.9, 0.05, 0.6)] },
        { key: 'smear', label: 'smear — spectral blur', dials: [D('smear', 'bins', 0, 24, 1, 8)] },
        { key: 'gate', label: 'spectral gate — the loudest bins only', dials: [D('gate', 'threshold', 0, 60, 0.1, 2)] },
        { key: 'freeze', label: 'freeze — the spectrum, held', on: { freeze: 1 }, dials: [D('freezeAtMs', 'at', 0, 2000, 5, 60, 'ms'), D('smear', 'smear', 0, 24, 1, 0)] },
        { key: 'reverb', label: 'reverb — a room', dials: [D('revMix', 'mix', 0, 1, 0.05, 0.5), D('revTime', 'time', 0.1, 20, 0.1, 2, 's'), D('revDamp', 'damping', 0, 1, 0.05, 0.4), D('revRoom', 'room', 1, 90, 1, 22)] },
        { key: 'greyhole', label: 'Greyhole — a delay and a reverb at once', dials: [D('ghMix', 'mix', 0, 1, 0.05, 0.6), D('ghTime', 'delay', 0.01, 4, 0.01, 0.4, 's'), D('ghSize', 'size', 0.5, 5, 0.1, 1), D('ghFb', 'feedback', 0, 1, 0.05, 0.7), D('ghDiff', 'diffusion', 0, 1, 0.05, 0.7), D('ghDamp', 'damping', 0, 1, 0.05, 0.2)] },
        { key: 'jpverb', label: 'JPverb — a reverb with a decay per band', dials: [D('jpMix', 'mix', 0, 1, 0.05, 0.6), D('jpT60', 'time', 0.1, 20, 0.1, 2, 's'), D('jpSize', 'size', 0.5, 5, 0.1, 1.2), D('jpDamp', 'damping', 0, 1, 0.05, 0.3), D('jpLow', 'low ×', 0, 2, 0.05, 1), D('jpMid', 'mid ×', 0, 2, 0.05, 1), D('jpHigh', 'high ×', 0, 2, 0.05, 1)] },
    ];
    // how a render ends and how loud it is — a new brick's
    const END = { end: 'shape', atkMs: 2, durMs: 600, relMs: 600, curve: -4, floorDb: -60, capMs: 8000, gainDb: 0, match: 1 };
    const RANGE = { atkMs: [0, 10000], durMs: [10, 120000], relMs: [0, 120000], curve: [-12, 12], floorDb: [-120, -6], capMs: [100, 60000], gainDb: [-60, 24], match: [0, 1] };
    const clamp = (k, v) => Math.max(RANGE[k][0], Math.min(RANGE[k][1], v));

    Object.assign(L, {
        EFFECTS, PROCESS_END: END,
        effect(key) { return EFFECTS.find((f) => f.key === key) || null; },
        effectDefaults(key) { const f = this.effect(key), a = {}; if (f) for (const d of f.dials) a[d.key] = d.def; return a; },
        // every control the engine gets: what turns the stage on, then the brick's own
        processArgs(e) { const f = this.effect(e.effect); return Object.assign({}, f && f.on, e.args || {}); },
        rootOf(name) { return String(name || '').split('~')[0]; },
        nextOut(source, skip) {
            const root = this.rootOf(source) || 'sample', used = new Set(this.index.map((r) => r.name));
            for (const z of this.zones('elecProcess')) if (z !== skip && z.elec && z.elec.out) used.add(z.elec.out);
            for (let n = 1; n < 10000; n++) if (!used.has(root + '~' + n)) return root + '~' + n;
            return root + '~' + Date.now();
        },
        // the brick's settings as one string: has anything changed since its render?
        processSig(e) {
            const a = this.processArgs(e), keys = Object.keys(a).sort();
            return JSON.stringify([e.source, e.effect, keys.map((k) => [k, +a[k]]), e.end, e.end === 'shape' ? [+e.atkMs, +e.durMs, +e.relMs, +e.curve] : [+e.floorDb, +e.capMs], +e.gainDb, +e.match]);
        },
        // what the message carries (the engine's field names)
        processMessage(zone, id) {
            const e = zone.elec, a = this.processArgs(e);
            const args = Object.keys(a).filter((k) => /^[A-Za-z][A-Za-z0-9]*$/.test(k) && Number.isFinite(+a[k])).map((k) => k + ':' + (+a[k])).join(',');
            const m = { id, source: safe(e.source), out: safe(e.out), effect: String(e.effect || '').slice(0, 40), args, end: e.end === 'tail' ? 'tail' : 'shape', gainDb: +e.gainDb || 0, match: +e.match > 0 ? 1 : 0 };
            if (m.end === 'shape') Object.assign(m, { atkMs: +e.atkMs || 0, durMs: +e.durMs || END.durMs, relMs: +e.relMs || 0, curve: +e.curve || 0 });
            else Object.assign(m, { floorDb: +e.floorDb || END.floorDb, capMs: +e.capMs || END.capMs });
            return m;
        },
        // none: not in the bank · changed: its settings since the render · older: its source was made after it · ok
        processState(zone) {
            const e = zone.elec, row = this.row(e.out), src = this.row(e.source);
            if (!row) return 'none';
            if (e.rendered && e.rendered.sig && e.rendered.sig !== this.processSig(e)) return 'changed';
            if (src && src.captured && row.captured && String(src.captured) > String(row.captured)) return 'older';
            return 'ok';
        },
        processLabel(zone) {
            const e = zone.elec, st = this.processState(zone);
            return this.MODELS.elecProcess.sign + ' ' + (e.label ? e.label + ' · ' : '') + (e.out || '?') + ' = ' + (e.effect || '?') + ' ← ' + (e.source || '?')
                + (st === 'none' ? ' — not rendered' : st === 'changed' ? ' — changed: render again' : st === 'older' ? ' — its source is newer: render again' : '');
        },
        // a rendered brick is as long as its sample
        processRedraw(zone) {
            const row = this.row(zone.elec && zone.elec.out);
            if (row && row.lengthMs > 0) zone.endTime = r3(zone.startTime + row.lengthMs / 1000);
        },

        // ---- the gesture --------------------------------------------------------------------------------------------------
        addProcess() {
            const h = this.host, o = this.opts, sel = h.selectedObject, t = Math.max(0, h.getTimeAtPlayhead());
            const nameOf = (z) => (z.midiModel === 'elecProcess' ? z.elec.out : z.elec.name);
            const fromSel = this.is(sel) && sel.elec && nameOf(sel) ? sel : null;
            let layer = fromSel ? fromSel.layer : h.activeLane;
            if (layer == null || layer < 0 || layer >= o.lanes) { this.say('a process brick goes on a player\'s lane — click the lane first'); return null; }
            // its source: the selected brick's sample · else the latest return or stage before the playhead (this lane's first) · else the index's first
            const before = this.zones().filter((z) => z.elec && (z.midiModel === 'elecProcess' || (z.midiModel === 'elecPlay' && !z.elec.behaviour)) && nameOf(z) && z.startTime <= t)
                .sort((a, b) => b.startTime - a.startTime);
            const src = fromSel || before.find((z) => z.layer === layer) || before[0] || null;
            const source = src ? nameOf(src) : (this.index[0] ? this.index[0].name : '');
            if (!source) { this.say('nothing to process yet — capture a sample first (' + String(o.keys.open).toUpperCase() + ' over a note)'); return null; }
            if (src) layer = src.layer;
            const row = this.row(source), len = row && row.lengthMs > 0 ? row.lengthMs : o.openMs, effect = 'comb';
            const elec = Object.assign({ source, out: this.nextOut(source), label: '', effect, args: this.effectDefaults(effect), rendered: null }, END);
            const z = this.make('elecProcess', layer, t, t + len / 1000, elec);
            this.say('process brick ' + elec.out + ' ← ' + source + ' on ' + o.laneLabel(layer) + ' — its effect and its dials are in the panel; Render makes it');
            this.loadIndex();
            return z;
        },
        // a new name for the brick's sample: the bricks that play it or are made from it follow
        renameOut(zone, now) {
            const e = zone.elec, was = e.out;
            e.out = now; e.rendered = null;
            for (const z of this.zones()) {
                if (z === zone || !z.elec) continue;
                if (z.midiModel === 'elecProcess' && z.elec.source === was) z.elec.source = now;
                if (z.midiModel === 'elecPlay' && z.elec.name === was) z.elec.name = now;
            }
        },
        setSource(zone, source) {
            const e = zone.elec;
            e.source = source;
            if (this.rootOf(source) !== this.rootOf(e.out)) this.renameOut(zone, this.nextOut(source, zone));   // another sample's chain: a name of that chain
        },
        processSettings(e) {
            const o = {};
            for (const k of ['source', 'out', 'label', 'effect', 'args', 'end', 'atkMs', 'durMs', 'relMs', 'curve', 'floorDb', 'capMs', 'gainDb', 'match']) o[k] = e[k];
            return o;
        },
        // the whole setting written at once (the panel's box): what is not a setting is left out, what is out of range is brought in
        processApply(zone, o) {
            const e = zone.elec;
            if (!o || typeof o !== 'object') return;
            if (typeof o.effect === 'string') e.effect = o.effect.slice(0, 40);
            if (o.args && typeof o.args === 'object') {
                e.args = {};
                for (const k of Object.keys(o.args)) if (/^[A-Za-z][A-Za-z0-9]*$/.test(k) && Number.isFinite(+o.args[k])) e.args[k] = +o.args[k];
            }
            if (o.end === 'shape' || o.end === 'tail') e.end = o.end;
            for (const k of Object.keys(RANGE)) if (o[k] != null && Number.isFinite(+o[k])) e[k] = clamp(k, +o[k]);
            if (typeof o.label === 'string') e.label = o.label.trim().slice(0, 40);
            if (typeof o.source === 'string' && safe(o.source) && safe(o.source) !== e.source) this.setSource(zone, safe(o.source));
            if (typeof o.out === 'string' && safe(o.out) && safe(o.out) !== e.out && safe(o.out) !== e.source) this.renameOut(zone, safe(o.out));
        },

        // ---- the panel ----------------------------------------------------------------------------------------------------
        processPanel(zone, sec, ui) {
            const e = zone.elec, { el, rowEl, note, commit } = ui, doc = sec.ownerDocument, small = 'font-size:11px';
            for (const k of Object.keys(END)) if (e[k] === undefined) e[k] = END[k];
            if (!e.args || typeof e.args !== 'object') e.args = {};
            const fx = this.effect(e.effect);
            const tiny = (t) => el('span', { textContent: t, style: 'font-size:10px;color:#888;white-space:nowrap' });
            const pair = (...kids) => el('span', { style: 'display:inline-flex;align-items:center;gap:4px;flex-wrap:wrap;' + small }, kids);
            const btn = (t, fn, title) => { const b = el('button', { type: 'button', textContent: t, title: title || '', style: small }); b.addEventListener('click', fn); return b; };
            const num = (obj, key, min, max, step, width) => {
                const n = el('input', { type: 'number', value: obj[key] == null ? '' : String(obj[key]), min: String(min), max: String(max), step: String(step), style: 'width:' + (width || 64) + 'px' });
                n.addEventListener('change', () => { const v = +n.value; if (n.value === '' || !Number.isFinite(v)) { n.value = obj[key] == null ? '' : String(obj[key]); return; } commit(() => { obj[key] = Math.max(min, Math.min(max, v)); }); });
                return n;
            };
            const pick = (value, options, write) => {
                const s = el('select', { style: 'max-width:230px' });
                for (const [v, t] of options) s.appendChild(el('option', { value: String(v), textContent: t, selected: String(value) === String(v) }));
                s.addEventListener('change', () => { s.blur(); commit(() => write(s.value)); });
                return s;
            };
            const text = (value, write, width) => { const n = el('input', { type: 'text', value: value || '', style: 'width:' + (width || 150) + 'px' }); n.addEventListener('change', () => write(n)); return n; };

            // THE SOURCE — any sample of the bank, or a stage placed and not yet rendered
            const srcs = this.index.map((r) => r.name).filter((n) => n !== e.out).sort(byName).map((n) => {
                const r = this.row(n);
                return [n, n + ' · ' + Math.round(r.lengthMs) + ' ms' + (r.kind === 'processed' ? ' · ' + (r.effect || 'processed') : '')];
            });
            for (const z of this.zones('elecProcess')) { const n = z.elec && z.elec.out; if (z !== zone && n && !this.row(n) && !srcs.some(([x]) => x === n)) srcs.push([n, n + ' — not rendered yet']); }
            if (!srcs.some(([n]) => n === e.source)) srcs.unshift([e.source || '', (e.source || '?') + ' — not in the bank']);
            sec.appendChild(rowEl('Source', pick(e.source, srcs, (v) => this.setSource(zone, v))));
            sec.appendChild(rowEl('Name', text(e.out, (n) => {
                const now = safe(n.value);
                if (!now || now === e.out || now === e.source) { n.value = e.out || ''; return; }
                commit(() => this.renameOut(zone, now));
            })));
            sec.appendChild(rowEl('Label', text(e.label, (n) => commit(() => { e.label = String(n.value || '').trim().slice(0, 40); }))));

            // THE EFFECT and its dials
            const fxs = EFFECTS.map((f) => [f.key, f.label]);
            if (!fx) fxs.unshift([e.effect || '', (e.effect || '?') + ' — not in the catalogue (its controls are in the box below)']);
            sec.appendChild(rowEl('Effect', pick(e.effect, fxs, (v) => { e.effect = v; e.args = this.effectDefaults(v); })));
            if (fx) {
                for (const d of fx.dials) {
                    if (e.args[d.key] === undefined) e.args[d.key] = d.def;
                    sec.appendChild(rowEl(d.label, d.options
                        ? pick(e.args[d.key], d.options, (v) => { e.args[d.key] = +v; })
                        : pair(num(e.args, d.key, d.min, d.max, d.step), tiny(d.unit))));
                }
                const more = Object.keys(e.args).filter((k) => !fx.dials.some((d) => d.key === k));
                if (more.length) sec.appendChild(note('also set, from the box below: ' + more.map((k) => k + ' ' + e.args[k]).join(' · ')));
            }

            // HOW IT ENDS · HOW LOUD
            sec.appendChild(rowEl('Ends by', pick(e.end, [['shape', 'shape — an envelope; its length is the object\'s'], ['tail', 'tail — it rings out']], (v) => { e.end = v; })));
            if (e.end === 'shape') {
                sec.appendChild(rowEl('', pair(tiny('attack'), num(e, 'atkMs', 0, 10000, 1, 52), tiny('length'), num(e, 'durMs', 10, 120000, 10, 64), tiny('ms'))));
                sec.appendChild(rowEl('', pair(tiny('release'), num(e, 'relMs', 0, 120000, 10, 64), tiny('ms · curve'), num(e, 'curve', -12, 12, 0.5, 52))));
                sec.appendChild(note('a release as long as the length = a struck shape, falling from the attack · curve −4 falls fast first, 0 is a straight line'));
            } else {
                sec.appendChild(rowEl('', pair(tiny('until'), num(e, 'floorDb', -120, -6, 1, 52), tiny('dB under its peak · at most'), num(e, 'capMs', 100, 60000, 100, 64), tiny('ms past the source'))));
            }
            const match = el('input', { type: 'checkbox', checked: +e.match > 0, style: 'margin:0 3px 0 0;vertical-align:middle' });
            match.addEventListener('change', () => commit(() => { e.match = match.checked ? 1 : 0; }));
            const matchLabel = el('label', { style: small }, [match]);
            matchLabel.appendChild(doc.createTextNode('peak as its source\'s'));
            sec.appendChild(rowEl('Level', pair(matchLabel, tiny('then'), num(e, 'gainDb', -60, 24, 0.5, 52), tiny('dB'))));

            // RENDER · LISTEN
            sec.appendChild(rowEl('', pair(
                btn('Render', () => this.render(zone), 'the engine puts the source through the effect, offline, and banks the result under the name'),
                btn('▶ hear it', () => this.audition(e.out), 'the rendered sample, now'),
                btn('▶ its source', () => this.audition(e.source), 'the sample it is made from, now'))));
            const st = this.processState(zone), row = this.row(e.out), info = this._info['p' + zone.id];
            if (info) sec.appendChild(note(info));
            sec.appendChild(note(row ? 'in the bank: ' + Math.round(row.lengthMs) + ' ms · peak ' + row.peakDb + ' dB · made ' + String(row.captured || '').replace('T', ' ')
                + (row.effect ? ' · ' + row.effect + ' ← ' + (row.source || '?') : '')
                : 'not rendered yet — Render, with the engine up; then it plays where the brick is'));
            if (st === 'changed') sec.appendChild(note('its settings have changed since that render — Render again'));
            if (st === 'older') sec.appendChild(note('its source was made after it — Render again to follow it'));

            // THE WHOLE SETTING, as text
            const box = el('textarea', { value: JSON.stringify(this.processSettings(e), null, 1), rows: 7, spellcheck: false, style: 'width:100%;box-sizing:border-box;font:10px/1.3 monospace' });
            sec.appendChild(el('div', { className: 'pp-row' }, [box]));
            sec.appendChild(rowEl('', pair(btn('Apply', () => {
                let o = null;
                try { o = JSON.parse(box.value); } catch (err) { this.say('the box is not valid JSON: ' + err.message); return; }
                commit(() => this.processApply(zone, o));
            }, 'the whole setting, as written in the box'), tiny('the whole setting — args takes any control of the chain'))));
        },

        // ---- the render: one message, then the bank's index until the row with this render's id is there ---------------------
        render(zone) {
            const h = this.host, e = zone.elec, key = 'p' + zone.id;
            const tell = (t) => { this._info[key] = t; this.say(t); if (h.selectedObject === zone) h.showPropertyPanel(); };
            this._rendering = this._rendering || {};
            if (this._rendering[key]) return this._rendering[key];
            if (!window.LE) { tell('NOT rendered: this page has no road to the engine (le_msg.js)'); return Promise.resolve(null); }
            if (!safe(e.source) || !safe(e.out) || safe(e.source) === safe(e.out)) { tell('NOT rendered: a source and a name of its own are needed'); return Promise.resolve(null); }
            const id = safe(String(zone.id) + '-' + Date.now().toString(36)), sig = this.processSig(e), started = Date.now();
            tell('rendering ' + e.out + ' ← ' + e.source + ' through ' + e.effect + ' …');
            const p = LE.send('process', this.processMessage(zone, id)).then((ans) => {
                if (!ans || !ans.ok) throw new Error('the score server did not take the message');
                return new Promise((resolve, reject) => {
                    const poll = () => this.loadIndex().then(() => {
                        const row = this.row(e.out);
                        if (row && row.openingId === id) return resolve(row);
                        if (Date.now() - started > 20000) return reject(new Error('no answer in 20 s — is the engine up, and started since the process brick was built? Its window says what it did.'));
                        setTimeout(poll, 400);
                    });
                    setTimeout(poll, 500);
                });
            }).then((row) => {
                e.rendered = { lengthMs: row.lengthMs, peakDb: row.peakDb, when: row.captured, sig };
                zone.endTime = r3(zone.startTime + row.lengthMs / 1000);
                h.markDirty();
                this.redraw();
                tell('rendered ' + e.out + ' — ' + Math.round(row.lengthMs) + ' ms · peak ' + row.peakDb + ' dB');
                return row;
            }).catch((err) => { tell('NOT rendered: ' + err.message); return null; })
                .then((r) => { delete this._rendering[key]; return r; });
            this._rendering[key] = p;
            return p;
        },
        // a sample, now — the engine plays it at once (the same message a return sends)
        audition(name) {
            if (!window.LE || !name) return;
            if (!this.row(name)) { this.say(name + ' is not in the bank yet'); return; }
            LE.send('play', { name: safe(name), id: 'audition', lane: -1, t: 0, dueMs: 0 });
            this.say('▶ ' + name);
        },
        // played through: a rendered stage is a return of its own sample
        processFire(host, z, at, dueMs) {
            const e = z.elec;
            if (!this.row(e.out)) { this.say('process brick ' + (e.out || '?') + ': not rendered — nothing is played'); return; }
            LE.send('play', { name: safe(e.out), id: String(z.id), lane: z.layer, t: r3(at), dueMs });
        },
    });
})();
