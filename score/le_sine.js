// le_sine.js — THE FOURTH COMPOSER-SCORE OBJECT FOR THE ELECTRONICS: THE SINE BRICK — the first sound the engine MAKES
// (first built in the Decibel piece, 2026-10-06 — its PLAN 1.5 · 12.2 · 12.3, RUNNING_LOG §178; the engine's sc/sine.scd).
// A piece's composer page loads it with ONE tag, after le_objects.js —   <script src="/electronics/le_sine.js"></script>
// — names its key in the attach line (keys.sine; `s` in the first piece) and may hand it its curve reader (curveAt, below).
// It is a MIXIN on LEObjects, as le_process.js is: that file hands this one the label, the panel, the key and the tick.
//
//   midiModel 'elecSine'   A SINE TONE.   elec: { midi, gliss: { kind, from, to, points? }, level: { mode, mark, to?, curveRef? }, label }
//       Its place is when the sine begins; its LENGTH is the sine's; its lane says whose staff it is drawn on — the player who
//       holds a long tone against it. Played through, it sends
//           /le/sine   id · lane · t · dueMs · midi · lengthMs · level · [gliss] · pass
//       and the engine plays the sine where the brick is (sc/sine.scd). A playhead that STARTS INSIDE the brick still starts it,
//       for what is left of it — its lines taken up where they stand. When the score stops:   /le/sinestop  . When it is started
//       again or its playhead jumps, `pass` is a new number and the engine lets go of the sines of the pass before.
//
//       midi     the pitch WITH its cents: 57 = A3 · 57.12 = A3 + 12 cents. The panel takes a name ("A3 +12") or a number.
//       gliss    how the pitch moves, in CENTS against `midi`:
//                  none · to (it starts `from` cents off and ARRIVES at unison) · from (it starts on and leaves to `to`) ·
//                  through (`from` → `to`) · around (out to `from` and back) · line (points: [[fraction 0…1, cents] …])
//       level    how loud, on the players' ladder — the engine turns a mark into the sine's exact peak (no measurement):
//                  flat     one mark (a name ppp … fff, or a number 0 … 7)
//                  hairpin  mark → to, over its length
//                  curve    IT FOLLOWS A DRAWN CURVE: curveRef names it (the first piece: 'A' · 'B' · 'C' — its three reference
//                           curves — or 'lane', a curve drawn on the brick's own lane). The curve's height 0 … 1 over the brick's
//                           span is ppp … fff. It is read AT THE FIRE, eight points — a curve redrawn between two passes is heard
//                           at the next with no touch of the brick. No curve drawn there: the flat mark, and the label says so.
//       KEY: over the SELECTED NOTE — its lane, its span, its pitch — else at the playhead on the active lane, four seconds,
//       the pitch of the lane's nearest earlier note.
//
//   THE BRICK AS A WINDOW ON ITS PLAYER (the Decibel piece's PLAN 1.8 · 16.1, 2026-10-08; the engine's sc/track.scd):
//       track    { on, follow?, ear? }   on: the sine is ARMED for the brick's span and silent until the player of its lane sounds
//                at its pitch; it enters with them at its level, FOLLOWS their rise and fall, holds through a breath and leaves when
//                they stop. The message then carries   gate 1 · player · [follow · ear]   . follow 0 … 1: how much of the player's
//                change it takes (absent: the piece's) · ear sim | mic: who the engine listens to (absent: the piece's).
//       gliss.overS   with a window, the gliss begins again at each ENTRY of the player: how long one glide lasts, in seconds
//                (absent: the brick's whole length).
//   THE SIMULATED EAR. In a concert the engine hears the player through a microphone. In a simulation the player is the NOTES of
//   the score — so this file tells the engine of every note on a lane, as it is about to sound under a window there:
//           /le/simlevel   player · lane · id · t · dueMs · lengthMs · level · pass
//   `level` is the note's dynamic as a line of marks. A note may SAY its own (a tool's shaped note):
//           properties.simLevel = [[fraction 0 … 1, mark 0 … 7] …]
//   else the host may hand a reader in —   opts.noteLevel(note, n) -> n marks over its span, or null   — else the note is steady
//   (the engine follows CHANGE: a steady level, whatever it is, leaves the sine at its written mark). Nothing is told under a
//   window that says ear 'mic'.
//
//   THE CURVE READER IS THE HOST'S, HANDED IN (the pattern of the pattern brick's calculators):
//       opts.curveAt(ref, { layer, startTime, endTime }, n)  ->  n heights 0 … 1 over that span, or null (nothing drawn there)
//   This file leans on no file of a piece's stack; without a reader a curve level is the flat mark.
//
// Nothing here knows a piece. What it asks of LEObjects: MODELS · host · opts · zones · make · is · say · MARKS.
// What it asks of the page: window.LE (le_msg.js). What it WRAPS of the host: stopPlay (so a stop reaches the engine).
(function () {
    'use strict';
    const L = window.LEObjects;
    if (!L) return;
    const r3 = (x) => Math.round(x * 1000) / 1000;
    const r2 = (x) => Math.round(x * 100) / 100;
    const NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    const STEP = { c: 0, d: 2, e: 4, f: 5, g: 7, a: 9, b: 11 };
    const SPARK = '▁▂▃▄▅▆▇█';
    const GLISS = [['none', 'none — it holds its pitch'], ['to', 'to unison — it starts off and arrives'], ['from', 'from unison — it starts on and leaves'],
        ['through', 'through — from one side to the other'], ['around', 'around — out and back'], ['line', 'a line — fraction:cents points']];
    const LEVELS = [['flat', 'flat — one dynamic'], ['hairpin', 'hairpin — from one dynamic to another'], ['A', 'curve A'], ['B', 'curve B'], ['C', 'curve C'], ['lane', 'a curve on this lane']];
    const cents = (c) => Math.max(-2400, Math.min(2400, Number.isFinite(+c) ? +c : 0));
    const minus = (n) => String(n).replace('-', '−');
    // a line [[x, v] …] (x rising) read at x, straight between its points
    const at = (pts, x) => {
        if (!pts.length) return 0;
        if (x <= pts[0][0]) return pts[0][1];
        for (let i = 1; i < pts.length; i++) if (x <= pts[i][0]) { const a = pts[i - 1], b = pts[i], w = b[0] > a[0] ? (x - a[0]) / (b[0] - a[0]) : 1; return a[1] + (b[1] - a[1]) * w; }
        return pts[pts.length - 1][1];
    };
    // the same line from fraction f0 on, its own 0 … 1 (a playhead that starts inside a brick)
    const from = (pts, f0) => {
        if (!pts.length || f0 <= 0) return pts;
        const rest = 1 - f0; if (rest <= 1e-6) return [[0, at(pts, 1)], [1, at(pts, 1)]];
        return [[0, at(pts, f0)]].concat(pts.filter((p) => p[0] > f0 + 1e-6).map((p) => [(p[0] - f0) / rest, p[1]]));
    };
    // … as the engine reads it:  ms:value,…  — the last point `end`, eight at the most (noEnd: every point in ms — a line shorter than the sine)
    const wire = (pts, lenMs, fmt, noEnd) => {
        let p = pts.slice(0, 8);
        if (p.length === 1 || p.every((x) => x[1] === p[0][1])) return fmt(p[0][1]);
        return p.map((x, i) => (!noEnd && i === p.length - 1 && x[0] >= 1 - 1e-6 ? 'end' : Math.round(x[0] * lenMs)) + ':' + fmt(x[1])).join(',');
    };
    const EARS = [['', 'as the piece says'], ['sim', 'the score\'s notes, told by this page (a simulation)'], ['mic', 'the player\'s microphone (a concert)']];

    L.MODELS.elecSine = { kind: 'sine', sign: '∿', color: '#1E88E5', yOffset: 0.75, title: 'Sine tone' };   // yOffset: a fraction of the lane (0 top · 1 bottom)

    // a stop reaches the engine: the host's stopPlay is wrapped once, when the composer is attached
    const attach = L.attach;
    L.attach = function (host) {
        const first = !this.host, r = attach.apply(this, arguments);
        if (first && host && typeof host.stopPlay === 'function') {
            const stop = host.stopPlay;
            host.stopPlay = function () { const out = stop.apply(this, arguments); L.sineStop(); return out; };
        }
        return r;
    };
    // the simulated ear rides on the transport's tick: the same window of time the bricks are fired in (le_performer.js's way)
    const tick = L.tick;
    L.tick = function (host, t) {
        const look = this.opts.lookAheadS, newPass = this._pass !== host.playStartTime;
        const fresh = newPass || this._prev == null || Math.abs(t - this._prev) > 0.5;
        const a = fresh ? t - 1e-6 : this._prev + look, b = t + look;
        const r = tick.apply(this, arguments);
        this.sineEar(host, a, b);
        return r;
    };

    Object.assign(L, {
        // ---- the pitch --------------------------------------------------------------------------------------------------
        sinePitchName(midi) {
            const m = Number.isFinite(+midi) ? +midi : 57, n = Math.round(m), c = Math.round((m - n) * 100);
            return NAMES[((n % 12) + 12) % 12] + (Math.floor(n / 12) - 1) + (c ? ' ' + (c > 0 ? '+' : '−') + Math.abs(c) + 'c' : '');
        },
        // "A3" · "a#3 +12" · "Bb2 -30c" · "57.12"  ->  a MIDI number with its cents, or null
        sineParsePitch(text) {
            const t = String(text == null ? '' : text).trim().replace(/−/g, '-');
            if (/^-?\d+(\.\d+)?$/.test(t)) { const v = +t; return v >= 0 && v <= 135 ? v : null; }
            const m = /^([A-Ga-g])\s*([#b♯♭]?)\s*(-?\d)\s*(?:([+-]\s*\d+(?:\.\d+)?)\s*c?)?$/.exec(t);
            if (!m) return null;
            const acc = m[2] === '#' || m[2] === '♯' ? 1 : m[2] === 'b' || m[2] === '♭' ? -1 : 0;
            const v = STEP[m[1].toLowerCase()] + acc + (+m[3] + 1) * 12 + (m[4] ? +m[4].replace(/\s+/g, '') / 100 : 0);
            return v >= 0 && v <= 135 ? Math.round(v * 10000) / 10000 : null;
        },
        sineHz(midi) { return 440 * Math.pow(2, ((Number.isFinite(+midi) ? +midi : 57) - 69) / 12); },
        // the beating a detune of c cents makes against this pitch, in beats per second
        sineBeats(midi, c) { return Math.abs(this.sineHz(midi) * (Math.pow(2, c / 1200) - 1)); },

        // ---- the level ----------------------------------------------------------------------------------------------------
        // a mark as a NUMBER on the ladder: ppp = 0 … fff = 7 (the engine's markNum) — a name or a number
        sineMark(x) {
            const i = this.MARKS.indexOf(String(x == null ? '' : x).trim());
            if (i >= 0) return i;
            return Number.isFinite(+x) && String(x).trim() !== '' ? Math.max(-10, Math.min(7, +x)) : 4;
        },
        sineMarkText(n) { const i = Math.max(0, Math.min(7, Math.round(n))); return this.MARKS[i]; },
        // the level over [t0, t1] of the brick: { pts: [[fraction, mark] …], src: 'flat' | 'hairpin' | 'curve' | 'nocurve', heights? }
        sineLevel(zone, t0, t1) {
            const lv = (zone.elec && zone.elec.level) || {}, mark = this.sineMark(lv.mark == null ? 'mf' : lv.mark), a = zone.startTime, span = Math.max(1e-6, zone.endTime - a);
            if (lv.mode === 'hairpin') {
                const whole = [[0, mark], [1, this.sineMark(lv.to == null ? mark : lv.to)]];
                return { pts: from(whole, ((t0 == null ? a : t0) - a) / span), src: 'hairpin' };
            }
            if (lv.mode === 'curve') {
                const read = this.opts.curveAt, s = t0 == null ? a : t0, e = t1 == null ? zone.endTime : t1;
                let h = null;
                try { h = typeof read === 'function' ? read(String(lv.curveRef || 'A'), { layer: zone.layer, startTime: s, endTime: e }, 8) : null; } catch (err) { h = null; }
                if (Array.isArray(h) && h.length >= 2 && h.every((v) => Number.isFinite(+v))) {
                    const hs = h.map((v) => Math.max(0, Math.min(1, +v)));
                    return { pts: hs.map((v, i) => [i / (hs.length - 1), r2(v * 7)]), src: 'curve', heights: hs };
                }
                return { pts: [[0, mark]], src: 'nocurve' };
            }
            return { pts: [[0, mark]], src: 'flat' };
        },

        // ---- the gliss ----------------------------------------------------------------------------------------------------
        // the pitch's line over the whole brick: [[fraction, cents] …] — empty when it holds its pitch
        sineGliss(e) {
            const g = (e && e.gliss) || {}, a = cents(g.from), b = cents(g.to);
            switch (g.kind) {
                case 'to': return a ? [[0, a], [1, 0]] : [];
                case 'from': return b ? [[0, 0], [1, b]] : [];
                case 'through': return a || b ? [[0, a], [1, b]] : [];
                case 'around': return a ? [[0, 0], [0.5, a], [1, 0]] : [];
                case 'line': {
                    const p = (Array.isArray(g.points) ? g.points : []).filter((x) => Array.isArray(x) && Number.isFinite(+x[0]) && Number.isFinite(+x[1]))
                        .map((x) => [Math.max(0, Math.min(1, +x[0])), cents(x[1])]).sort((x, y) => x[0] - y[0]);
                    return p.length >= 2 && p.some((x) => x[1] !== 0) ? p : [];
                }
                default: return [];
            }
        },
        sineGlissText(e) {
            const p = this.sineGliss(e); if (!p.length) return '';
            const c = (v) => minus(Math.round(v * 10) / 10), a = p[0][1], z = p[p.length - 1][1];
            if (p.length === 2) return ' ' + (z > a ? '↗' : '↘') + ' ' + c(a) + 'c → ' + c(z);
            return ' ↷ ' + p.map((x) => c(x[1])).join(' → ') + 'c';
        },

        // ---- the message --------------------------------------------------------------------------------------------------
        // what the brick sends for a start at `at` (its own start, or later: the playhead began inside it)
        sineMessage(zone, at0, dueMs) {
            const e = zone.elec || {}, a = zone.startTime, start = Math.max(a, at0 == null ? a : at0), span = Math.max(1e-6, zone.endTime - a);
            const lenMs = Math.max(50, Math.round((zone.endTime - start) * 1000)), f0 = (start - a) / span;
            const lv = this.sineLevel(zone, start, zone.endTime), gl = from(this.sineGliss(e), f0);
            const m = { id: String(zone.id), lane: zone.layer, t: r3(start), dueMs: dueMs || 0, midi: Math.round((Number.isFinite(+e.midi) ? +e.midi : 57) * 10000) / 10000,
                lengthMs: lenMs, level: wire(lv.pts, lenMs, (v) => String(r2(v))) };
            const tr = this.sineTrack(e), fmtC = (v) => String(Math.round(v * 10) / 10);
            if (tr) {
                // A WINDOW: the engine arms the sine and waits for the player. Its gliss begins again at each entry — the WHOLE line, over
                // gliss.overS where the brick says how long one glide is (a line shorter than the sine: every point in ms)
                const whole = this.sineGliss(e), overMs = Number.isFinite(+(e.gliss || {}).overS) && +e.gliss.overS > 0 ? Math.min(lenMs, Math.round(+e.gliss.overS * 1000)) : 0;
                if (whole.length && whole.some((x) => x[1] !== 0)) m.gliss = overMs ? wire(whole, overMs, fmtC, true) : wire(whole, lenMs, fmtC);
                m.gate = 1; m.player = this.sineWho(zone.layer);
                if (tr.follow != null) m.follow = tr.follow;
                if (tr.ear) m.ear = tr.ear;
            } else if (gl.length && gl.some((x) => x[1] !== 0)) m.gliss = wire(gl, lenMs, fmtC);
            if (this._passN) m.pass = this._passN;   // this pass of the score (le_objects.js tick): the engine lets go of the sines of the pass before
            return m;
        },

        // ---- the window --------------------------------------------------------------------------------------------------
        // a brick's track, as it stands: null (it sounds for its whole span) or { follow?: 0 … 2, ear?: 'sim' | 'mic' }
        sineTrack(e) {
            const t = e && e.track;
            if (!t || !t.on) return null;
            const o = {};
            if (t.follow != null && t.follow !== '' && Number.isFinite(+t.follow)) o.follow = Math.max(0, Math.min(2, Math.round(+t.follow * 100) / 100));
            if (t.ear === 'sim' || t.ear === 'mic') o.ear = t.ear;
            return o;
        },
        // whose window: the lane's player by the piece's route table — a lane with no microphone is told of all the same, under its own name
        sineWho(layer) { return this.playerOf(layer) || ('lane' + layer); },
        // a note's dynamic over its own span, as a line of marks [[fraction, mark] …]: what it says of itself, what the host reads, else steady
        sineNoteLevel(o) {
            const said = o && o.properties && o.properties.simLevel;
            if (Array.isArray(said)) {
                const p = said.filter((x) => Array.isArray(x) && Number.isFinite(+x[0]) && Number.isFinite(+x[1])).map((x) => [Math.max(0, Math.min(1, +x[0])), Math.max(-10, Math.min(7, +x[1]))]).sort((x, y) => x[0] - y[0]).slice(0, 8);
                if (p.length) return p;
            }
            const read = this.opts.noteLevel;
            if (typeof read === 'function') {
                let h = null;
                try { h = read(o, 8); } catch (err) { h = null; }
                if (Array.isArray(h) && h.length >= 2 && h.every((v) => Number.isFinite(+v))) return h.map((v, i) => [i / (h.length - 1), Math.max(-10, Math.min(7, +v))]);
            }
            return [[0, 4]];
        },
        // THE SIMULATED EAR: every note that begins in (from, to] on a lane, under a window there that is not on a microphone, told to the engine
        sineEar(host, from, to) {
            if (!window.LE) return 0;
            const zs = this.zones('elecSine').filter((z) => { const tr = this.sineTrack(z.elec); return tr && tr.ear !== 'mic'; });
            if (!zs.length) return 0;
            let n = 0;
            for (const o of host.objects) {
                if (o.type !== 'waveCurve' || o.sonifyNote == null || !(o.layer < this.opts.lanes)) continue;
                const s = o.startSeconds;
                if (!(s > from && s <= to)) continue;
                if (!zs.some((z) => z.layer === o.layer && z.startTime <= s + 0.05 && z.endTime > s)) continue;
                if (host.isPartAudible && !host.isPartAudible(o.layer)) continue;
                const perf = host.playStartTime + (s - host.playStartOffset / host.pixelsPerSecond) * 1000;
                const dueMs = Math.max(0, Math.round(((Number.isFinite(perf) ? perf : performance.now()) - performance.now()) * 10) / 10);
                const lengthMs = Math.max(20, Math.round((o.endSeconds - s) * 1000));
                const m = { player: this.sineWho(o.layer), lane: o.layer, id: String(o.id), t: r3(s), dueMs, lengthMs, level: wire(this.sineNoteLevel(o), lengthMs, (v) => String(r2(v))) };
                if (this._passN) m.pass = this._passN;
                LE.send('simlevel', m);
                n++;
            }
            return n;
        },

        // ---- the label ------------------------------------------------------------------------------------------------------
        sineLabel(zone) {
            const e = zone.elec || {}, M = this.MODELS.elecSine, lv = this.sineLevel(zone), mode = (e.level && e.level.mode) || 'flat';
            const secs = (Math.round((zone.endTime - zone.startTime) * 10) / 10).toFixed(1) + ' s';
            let level;
            if (lv.src === 'curve') level = 'curve ' + (e.level.curveRef === 'lane' ? 'on this lane' : e.level.curveRef || 'A') + ' ' + lv.heights.map((h) => SPARK[Math.round(h * 7)]).join('');
            else if (lv.src === 'nocurve') level = 'curve ' + (e.level.curveRef === 'lane' ? 'on this lane' : e.level.curveRef || 'A') + ' — none drawn: ' + this.sineMarkText(lv.pts[0][1]);
            else if (mode === 'hairpin') level = this.sineMarkText(this.sineMark(e.level.mark)) + ' → ' + this.sineMarkText(this.sineMark(e.level.to == null ? e.level.mark : e.level.to));
            else level = Number.isInteger(lv.pts[0][1]) ? this.sineMarkText(lv.pts[0][1]) : String(lv.pts[0][1]);
            const tr = this.sineTrack(e);
            return M.sign + ' ' + (e.label ? String(e.label).slice(0, 48) + ' · ' : '') + this.sinePitchName(e.midi) + this.sineGlissText(e) + ' · ' + secs + ' · ' + level
                + (tr ? (tr.follow === 0 ? ' · with the player' : ' · follows' + (tr.follow != null && tr.follow !== 1 ? ' ×' + tr.follow : '')) : '');
        },

        // ---- the gesture ----------------------------------------------------------------------------------------------------
        addSine() {
            const h = this.host, o = this.opts, sel = h.selectedObject, t = Math.max(0, h.getTimeAtPlayhead());
            const onNote = !!(sel && sel.type === 'waveCurve' && sel.sonifyNote != null && sel.layer < o.lanes);
            const layer = onNote ? sel.layer : h.activeLane;
            if (layer == null || layer < 0 || layer >= o.lanes) { this.say('a sine goes on a player\'s lane — click the lane first, or select a note'); return null; }
            let midi = 57, start = t, end = t + 4;
            if (onNote) { midi = +sel.sonifyNote; start = sel.startSeconds; end = Math.max(sel.endSeconds, start + 0.2); }
            else {
                const before = h.objects.filter((x) => x.type === 'waveCurve' && x.sonifyNote != null && x.layer === layer && x.startSeconds <= t).sort((x, y) => y.startSeconds - x.startSeconds)[0];
                if (before) midi = +before.sonifyNote;
            }
            const z = this.make('elecSine', layer, start, end, { midi, gliss: { kind: 'none', from: 0, to: 0 }, level: { mode: 'flat', mark: 'mf' }, label: '' });
            this.say('sine ' + this.sinePitchName(midi) + ' on ' + o.laneLabel(layer) + ' — ' + (end - start).toFixed(1) + ' s from ' + z.startTime.toFixed(2) + ' s'
                + (onNote ? ' (over the note: its pitch, its length)' : '') + ' — its pitch, its gliss and its level are in the panel');
            return z;
        },

        // ---- the panel ------------------------------------------------------------------------------------------------------
        sineSettings(e) { const o = { midi: e.midi, gliss: e.gliss, level: e.level, label: e.label || '' }; if (e.track) o.track = e.track; return o; },
        // the whole setting written at once (the panel's box): what is not a setting is left out, what is out of range is brought in
        sineApply(zone, o) {
            const e = zone.elec;
            if (!o || typeof o !== 'object') return;
            if (o.midi != null) { const m = typeof o.midi === 'string' ? this.sineParsePitch(o.midi) : (Number.isFinite(+o.midi) ? +o.midi : null); if (m != null && m >= 0 && m <= 135) e.midi = m; }
            if (o.gliss && typeof o.gliss === 'object') {
                const k = GLISS.some((x) => x[0] === o.gliss.kind) ? o.gliss.kind : 'none';
                e.gliss = { kind: k, from: cents(o.gliss.from), to: cents(o.gliss.to) };
                if (k === 'line' && Array.isArray(o.gliss.points)) e.gliss.points = o.gliss.points.filter((x) => Array.isArray(x) && x.length >= 2).slice(0, 8).map((x) => [Math.max(0, Math.min(1, +x[0] || 0)), cents(x[1])]);
                if (Number.isFinite(+o.gliss.overS) && +o.gliss.overS > 0) e.gliss.overS = Math.min(600, Math.round(+o.gliss.overS * 100) / 100);
            }
            if ('track' in o) {
                const t = o.track;
                if (!t || typeof t !== 'object' || !t.on) delete e.track;
                else {
                    e.track = { on: true };
                    if (t.follow != null && t.follow !== '' && Number.isFinite(+t.follow)) e.track.follow = Math.max(0, Math.min(2, Math.round(+t.follow * 100) / 100));
                    if (t.ear === 'sim' || t.ear === 'mic') e.track.ear = t.ear;
                }
            }
            if (o.level && typeof o.level === 'object') {
                const mode = ['flat', 'hairpin', 'curve'].includes(o.level.mode) ? o.level.mode : 'flat', mk = (v) => (this.MARKS.includes(String(v)) ? String(v) : this.sineMark(v));
                e.level = { mode, mark: mk(o.level.mark == null ? 'mf' : o.level.mark) };
                if (mode === 'hairpin') e.level.to = mk(o.level.to == null ? e.level.mark : o.level.to);
                if (mode === 'curve') e.level.curveRef = ['A', 'B', 'C', 'lane'].includes(o.level.curveRef) ? o.level.curveRef : 'A';
            }
            if (typeof o.label === 'string') e.label = o.label.trim().slice(0, 48);
        },
        sinePanel(zone, sec, ui) {
            const e = zone.elec, { el, rowEl, note, commit } = ui, small = 'font-size:11px';
            if (!e.gliss || typeof e.gliss !== 'object') e.gliss = { kind: 'none', from: 0, to: 0 };
            if (!e.level || typeof e.level !== 'object') e.level = { mode: 'flat', mark: 'mf' };
            const g = e.gliss, lv = e.level;
            const pair = (...kids) => el('span', { style: 'display:inline-flex;align-items:center;gap:4px;flex-wrap:wrap;' + small }, kids);
            const tiny = (t) => el('span', { textContent: t, style: 'font-size:10px;color:#888;white-space:nowrap' });
            const num = (value, step, fn, title) => { const i = el('input', { type: 'number', value: String(value), step: String(step), title: title || '', style: 'width:64px' }); i.addEventListener('change', () => commit(() => fn(+i.value))); return i; };
            const marks = (value, fn, title) => {
                const s = el('select', { title: title || '' }), cur = this.MARKS.includes(String(value)) ? String(value) : String(this.sineMark(value));
                if (!this.MARKS.includes(cur)) s.appendChild(el('option', { value: cur, textContent: cur, selected: true }));
                for (const k of this.MARKS) s.appendChild(el('option', { value: k, textContent: k, selected: k === cur }));
                s.addEventListener('change', () => { s.blur(); commit(() => fn(s.value)); });
                return s;
            };
            // the label
            const label = el('input', { type: 'text', value: e.label || '', title: 'a tag shown first on the brick — a word of yours' });
            label.addEventListener('change', () => commit(() => { e.label = String(label.value || '').trim().slice(0, 48); }));
            sec.appendChild(rowEl('Label', label));
            // the pitch
            const pitch = el('input', { type: 'text', value: this.sinePitchName(e.midi).replace('−', '-').replace(/c$/, ''), title: 'a note name with its cents — A3 · A3 +12 · Bb2 -30 — or a MIDI number: 57.12' });
            pitch.addEventListener('change', () => {
                const m = this.sineParsePitch(pitch.value);
                if (m == null) { this.say('a pitch is a note name with its cents (A3 +12) or a MIDI number (57.12)'); pitch.value = this.sinePitchName(e.midi); return; }
                commit(() => { e.midi = m; });
            });
            sec.appendChild(rowEl('Pitch', pair(pitch, tiny(Math.round(this.sineHz(e.midi) * 100) / 100 + ' Hz'))));
            // the length
            sec.appendChild(rowEl('Length (s)', num(r3(zone.endTime - zone.startTime), 0.1, (v) => { zone.endTime = r3(zone.startTime + Math.max(0.05, Math.min(600, v || 4))); })));
            // the gliss
            const kind = el('select');
            for (const [k, text] of GLISS) kind.appendChild(el('option', { value: k, textContent: text, selected: k === (g.kind || 'none') }));
            kind.addEventListener('change', () => {
                kind.blur();
                commit(() => {
                    g.kind = kind.value;
                    if ((g.kind === 'to' || g.kind === 'around' || g.kind === 'through') && !cents(g.from)) g.from = -30;
                    if ((g.kind === 'from' || g.kind === 'through') && !cents(g.to)) g.to = 30;
                    if (g.kind === 'line' && !Array.isArray(g.points)) g.points = [[0, cents(g.from) || -30], [1, 0]];
                });
            });
            sec.appendChild(rowEl('Gliss', kind));
            if (g.kind === 'to' || g.kind === 'around' || g.kind === 'through') sec.appendChild(rowEl(g.kind === 'around' ? 'Out to (cents)' : 'Starts (cents)', num(cents(g.from), 1, (v) => { g.from = cents(v); }, 'cents against the pitch: − under, + over')));
            if (g.kind === 'from' || g.kind === 'through') sec.appendChild(rowEl('Ends (cents)', num(cents(g.to), 1, (v) => { g.to = cents(v); }, 'cents against the pitch: − under, + over')));
            if (g.kind === 'line') {
                const line = el('input', { type: 'text', value: (g.points || []).map((x) => x[0] + ':' + x[1]).join(', '), title: 'fraction of the length : cents — 0:-28, 0.5:10, 1:0 (eight points at the most)' });
                line.addEventListener('change', () => commit(() => {
                    g.points = String(line.value || '').split(',').map((s) => s.trim().split(':')).filter((b) => b.length === 2 && b[0] !== '' && Number.isFinite(+b[0]) && Number.isFinite(+b[1].replace('−', '-')))
                        .map((b) => [Math.max(0, Math.min(1, +b[0])), cents(b[1].replace('−', '-'))]).sort((x, y) => x[0] - y[0]).slice(0, 8);
                }));
                sec.appendChild(rowEl('Points', line));
            }
            const gp = this.sineGliss(e);
            if (gp.length) sec.appendChild(note('against a steady ' + this.sinePitchName(e.midi) + ' it beats ' + gp.map((x) => (Math.round(this.sineBeats(e.midi, x[1]) * 10) / 10)).join(' → ') + ' times a second'));
            // the level
            const mode = el('select'), cur = lv.mode === 'curve' ? (['A', 'B', 'C', 'lane'].includes(lv.curveRef) ? lv.curveRef : 'A') : (lv.mode === 'hairpin' ? 'hairpin' : 'flat');
            for (const [k, text] of LEVELS) mode.appendChild(el('option', { value: k, textContent: text, selected: k === cur }));
            mode.addEventListener('change', () => {
                mode.blur();
                commit(() => {
                    const v = mode.value;
                    if (v === 'flat') { lv.mode = 'flat'; delete lv.to; delete lv.curveRef; }
                    else if (v === 'hairpin') { lv.mode = 'hairpin'; if (lv.to == null) lv.to = 'f'; delete lv.curveRef; }
                    else { lv.mode = 'curve'; lv.curveRef = v; delete lv.to; }
                });
            });
            sec.appendChild(rowEl('Level', mode));
            const read = this.sineLevel(zone);
            if (lv.mode === 'hairpin') sec.appendChild(rowEl('From → to', pair(marks(lv.mark, (v) => { lv.mark = v; }), tiny('→'), marks(lv.to == null ? lv.mark : lv.to, (v) => { lv.to = v; }))));
            else sec.appendChild(rowEl(lv.mode === 'curve' ? 'With no curve' : 'Dynamic', marks(lv.mark == null ? 'mf' : lv.mark, (v) => { lv.mark = v; }, lv.mode === 'curve' ? 'what it plays where no curve is drawn under it' : 'its dynamic on the players\' ladder')));
            if (lv.mode === 'curve') sec.appendChild(note(read.src === 'curve'
                ? 'it follows the curve: ' + read.heights.map((h) => SPARK[Math.round(h * 7)]).join('') + '  ' + this.sineMarkText(Math.min(...read.pts.map((p) => p[1]))) + ' … ' + this.sineMarkText(Math.max(...read.pts.map((p) => p[1]))) + ' — the curve\'s height is ppp … fff; it is read again at every pass'
                : typeof this.opts.curveAt === 'function' ? 'no curve is drawn under this brick there — it plays the dynamic above until one is' : 'this page has no curve reader — it plays the dynamic above'));
            // the window: Follow — the sine armed for the brick's span, in with its player, following them, out with them
            const tr = this.sineTrack(e), fol = el('select', { title: 'off: the sine sounds for the whole brick · on: the brick is a WINDOW — the sine is silent until the player of this lane sounds at its pitch, enters with them at the dynamic above, follows their rise and fall, holds through a breath, leaves when they stop' });
            for (const [k, text] of [['off', 'off — it sounds for its whole span'], ['on', 'on — it enters with the player and follows them']]) fol.appendChild(el('option', { value: k, textContent: text, selected: (k === 'on') === !!tr }));
            fol.addEventListener('change', () => { fol.blur(); commit(() => { if (fol.value === 'on') e.track = Object.assign({}, e.track, { on: true }); else delete e.track; }); });
            sec.appendChild(rowEl('Follow', fol));
            if (tr) {
                const how = el('input', { type: 'number', value: tr.follow == null ? '' : String(tr.follow), step: '0.1', min: '0', max: '2', placeholder: 'the piece\'s', style: 'width:76px',
                    title: 'how much of the player\'s CHANGE the sine takes: 1 = all of it · 0.5 = half · 0 = none (it enters and leaves with the player at its own dynamic and never moves). Empty: the piece\'s number' });
                how.addEventListener('change', () => commit(() => { if (how.value === '' || !Number.isFinite(+how.value)) delete e.track.follow; else e.track.follow = Math.max(0, Math.min(2, Math.round(+how.value * 100) / 100)); }));
                sec.appendChild(rowEl('How much', pair(how, tiny('0 … 1 of their rise and fall'))));
                const ear = el('select', { title: 'who the engine listens to for this brick' });
                for (const [k, text] of EARS) ear.appendChild(el('option', { value: k, textContent: text, selected: k === (tr.ear || '') }));
                ear.addEventListener('change', () => { ear.blur(); commit(() => { if (ear.value) e.track.ear = ear.value; else delete e.track.ear; }); });
                sec.appendChild(rowEl('Hears', ear));
                if (this.sineGliss(e).length) {
                    const over = el('input', { type: 'number', value: Number.isFinite(+g.overS) && +g.overS > 0 ? String(g.overS) : '', step: '0.5', min: '0', placeholder: 'the brick\'s', style: 'width:76px',
                        title: 'the gliss begins again each time the player enters: how long ONE glide lasts, in seconds. Empty: the brick\'s whole length' });
                    over.addEventListener('change', () => commit(() => { if (over.value === '' || !(+over.value > 0)) delete g.overS; else g.overS = Math.min(600, Math.round(+over.value * 100) / 100); }));
                    sec.appendChild(rowEl('One glide (s)', over));
                }
                sec.appendChild(note('a WINDOW: silent until ' + (this.playerOf(zone.layer) || 'the player of this lane') + ' sounds at ' + this.sinePitchName(e.midi) + ' — then in with them at the dynamic above, following their rise and fall, held through a breath, gone when they stop'
                    + (this.sineGliss(e).length ? '; its gliss begins again at each entry' : '') + '. The engine\'s window says each entry.'));
            }
            // hear it · the whole setting
            const hear = el('button', { type: 'button', textContent: '▶ hear', title: 'two seconds of it through the engine — its pitch, its gliss over the two seconds, its first dynamic', style: small });
            hear.addEventListener('click', () => this.sineHear(zone));
            sec.appendChild(rowEl('', hear));
            const box = el('textarea', { value: JSON.stringify(this.sineSettings(e), null, 1), rows: 6, spellcheck: false, style: 'width:100%;box-sizing:border-box;font:10px/1.3 monospace' });
            box.addEventListener('change', () => {
                let o;
                try { o = JSON.parse(box.value); } catch (err) { this.say('the box is not valid JSON: ' + err.message); return; }
                commit(() => this.sineApply(zone, o));
            });
            sec.appendChild(el('div', { className: 'pp-row' }, [box]));
        },

        // ---- the sound ------------------------------------------------------------------------------------------------------
        sineHear(zone) {
            if (!window.LE) { this.say('no road to the engine on this page'); return; }
            const e = zone.elec || {}, lv = this.sineLevel(zone), gl = this.sineGliss(e);
            const m = { id: 'audition', lane: -1, t: 0, dueMs: 0, midi: Number.isFinite(+e.midi) ? +e.midi : 57, lengthMs: 2000, level: String(r2(lv.pts[0][1])) };
            if (gl.length) m.gliss = wire(gl, 2000, (v) => String(Math.round(v * 10) / 10));
            LE.send('sine', m);
            this.say('▶ ' + this.sinePitchName(e.midi) + this.sineGlissText(e) + ' — two seconds');
        },
        // played through: one message, the engine plays the sine where the brick is
        sineFire(host, z, at0, dueMs) {
            if (!window.LE) return;
            LE.send('sine', this.sineMessage(z, at0, dueMs));
        },
        // the score stopped: a long tone must not hang over the silence — said only where the score has a sine
        sineStop() {
            if (window.LE && this.host && this.zones('elecSine').length) LE.send('sinestop', {});
        },
    });
})();
