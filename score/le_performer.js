// le_performer.js — THE FIFTH COMPOSER-SCORE OBJECT FOR THE ELECTRONICS: A PERFORMER'S CONTAINER — the first that DECIDES
// (first built in the Decibel piece, 2026-10-06 — its PLAN 1.6 · 14.4 · 14.5, RUNNING_LOG §190; the engine's sc/performer.scd).
// A piece's composer page loads it with ONE tag, after le_objects.js —   <script src="/electronics/le_performer.js"></script>
// It is a MIXIN on LEObjects, as le_process.js and le_sine.js are: that file hands this one the label, the panel and the tick.
//
//   midiModel 'elecPerformer'   A COMPUTER PLAYER IS IN A STATE for the length of the brick.
//       elec: { id, state, from?, to?, target?, targetFrom?, pal: [names], mark, seed, silenceMs?, ear?, dials?, label? }
//       Its place is when the state begins; its LENGTH is how long it lasts; its lane is only where it is drawn. Played through,
//       it sends ONE message at its start —
//           /le/performer   id · state · [from · to] · t · dueMs · lengthMs · [offsetMs · wholeMs] · pal · [target · targetFrom] ·
//                           seed · mark · [silenceMs · ear · dials] · pass · zone · lane
//       — and from then on the ENGINE decides, sound by sound, by the state's rule and by what it hears (sc/performer.scd).
//       A playhead that STARTS INSIDE the brick still starts it, for what is left (offsetMs · wholeMs say where it stands).
//       When the score stops:   /le/performerstop  . When it is started again or its playhead jumps, `pass` is a new number and
//       the engine ends the performers of the pass before.
//
//         id          which computer player: e1 · e2 · …  (a performer keeps its memory and its place in its palette by its id)
//         state       far · approaching · closePass · breakRejoin · change (then from · to: the two states it lies between)
//         target      who it listens to — a player's name (the route table's) · another performer's id · any · cluster
//         pal         THE PALETTE: the names of the banked samples it plays, dealt round robin
//         mark        its dynamic on the players' ladder (ppp … fff)
//         silenceMs   a break's silence, from the brick's own start
//         ear         sim — the page tells the engine each simulated note (below) · mic — the engine listens to the microphones
//         dials       the piece's numbers over the engine's defaults, under the engine's own names: { beatLo: 300, … }
//
//   THE SIMULATED EAR. In a concert the engine hears the players through their microphones. In a simulation the players are
//   NOTES of the score — so while a performer's brick is near, this file tells the engine of every note on a player's lane, as it
//   is about to sound:     /le/onset   player · lane · id · t · dueMs · sim 1
//   (the lane's player by the piece's route table, as a mic opening finds its microphone). Nothing is sent where every brick
//   says ear 'mic': then the rack's own sound, coming in where the microphone would, is what the engine hears.
//
// Nothing here knows a piece. What it asks of LEObjects: MODELS · host · opts · zones · is · say · MARKS · playerOf · tick · attach.
// What it asks of the page: window.LE (le_msg.js). What it WRAPS of the host: stopPlay (so a stop reaches the engine).
(function () {
    'use strict';
    const L = window.LEObjects;
    if (!L) return;
    const r3 = (x) => Math.round(x * 1000) / 1000;
    const safe = (s) => String(s == null ? '' : s).replace(/[^A-Za-z0-9_~-]/g, '').slice(0, 64);
    const STATES = [['far', 'far apart'], ['approaching', 'approaching'], ['closePass', 'close pass'], ['breakRejoin', 'break and rejoin'], ['change', 'change — between two states']];
    const NAME = { far: 'far apart', approaching: 'approaching', closePass: 'close pass', breakRejoin: 'break and rejoin', change: 'change' };
    const listens = (s) => s === 'approaching' || s === 'closePass';

    L.MODELS.elecPerformer = { kind: 'performer', sign: '◍', color: '#546E7A', yOffset: 1, title: 'Performer — a computer player in a state' };   // yOffset: a fraction of the lane (0 top · 1 bottom)

    // a stop reaches the engine: the host's stopPlay is wrapped once, when the composer is attached
    const attach = L.attach;
    L.attach = function (host) {
        const first = !this.host, r = attach.apply(this, arguments);
        if (first && host && typeof host.stopPlay === 'function') {
            const stop = host.stopPlay;
            host.stopPlay = function () { const out = stop.apply(this, arguments); L.performerStop(); return out; };
        }
        return r;
    };
    // the simulated ear rides on the transport's tick: the same window of time the bricks are fired in
    const tick = L.tick;
    L.tick = function (host, t) {
        const look = this.opts.lookAheadS, newPass = this._pass !== host.playStartTime;
        const fresh = newPass || this._prev == null || Math.abs(t - this._prev) > 0.5;
        const from = fresh ? t - 1e-6 : this._prev + look, to = t + look;
        const r = tick.apply(this, arguments);
        this.performerEar(host, from, to);
        return r;
    };

    Object.assign(L, {
        // ---- the label ------------------------------------------------------------------------------------------------------
        performerLabel(zone) {
            const e = zone.elec || {}, M = this.MODELS.elecPerformer, secs = (Math.round((zone.endTime - zone.startTime) * 10) / 10).toFixed(1) + ' s';
            let what = NAME[e.state] || String(e.state || '?');
            if (e.state === 'change') what = 'change: ' + (NAME[e.from] || e.from || '?') + ' → ' + (NAME[e.to] || e.to || '?');
            const tg = e.state === 'change' ? (listens(e.to) ? e.target : listens(e.from) ? e.targetFrom : '') : (listens(e.state) ? e.target : '');
            return M.sign + ' ' + (e.label ? String(e.label).slice(0, 48) + ' · ' : '') + (e.id || '?') + ' · ' + what + (tg ? ' → ' + tg : '')
                + (e.state === 'breakRejoin' && +e.silenceMs > 0 ? ' · silent ' + (Math.round(+e.silenceMs / 100) / 10).toFixed(1) + ' s' : '') + ' · ' + secs
                + (Array.isArray(e.pal) && e.pal.length ? '' : ' — NO PALETTE');
        },

        // ---- the message ----------------------------------------------------------------------------------------------------
        performerDials(d) {
            if (!d || typeof d !== 'object') return '';
            return Object.entries(d).filter(([k, v]) => /^[A-Za-z][A-Za-z0-9]*$/.test(k) && typeof v === 'number' && Number.isFinite(v)).map(([k, v]) => k + '=' + v).join(',');
        },
        // what the brick sends for a start at `at0` (its own start, or later: the playhead began inside it)
        performerMessage(zone, at0, dueMs) {
            const e = zone.elec || {}, a = zone.startTime, start = Math.max(a, at0 == null ? a : at0);
            const m = { id: safe(e.id) || 'e1', state: STATES.some((s) => s[0] === e.state) ? e.state : 'far', t: r3(start), dueMs: dueMs || 0,
                lengthMs: Math.max(50, Math.round((zone.endTime - start) * 1000)), pal: (Array.isArray(e.pal) ? e.pal : []).map(safe).filter(Boolean).join(','),
                seed: Math.max(1, Math.round(+e.seed) || 1), mark: this.MARKS.includes(String(e.mark)) ? String(e.mark) : 'mf', zone: String(zone.id), lane: zone.layer };
            if (start > a + 0.001) { m.offsetMs = Math.round((start - a) * 1000); m.wholeMs = Math.round((zone.endTime - a) * 1000); }
            if (m.state === 'change') { m.from = safe(e.from) || 'far'; m.to = safe(e.to) || 'far'; }
            if (e.target) m.target = safe(e.target);
            if (e.targetFrom) m.targetFrom = safe(e.targetFrom);
            if (m.state === 'breakRejoin') m.silenceMs = Math.max(0, Math.round(+e.silenceMs || 0));
            if (e.ear === 'sim' || e.ear === 'mic') m.ear = e.ear;
            const dials = this.performerDials(e.dials);
            if (dials) m.dials = dials;
            if (this._passN) m.pass = this._passN;   // this pass of the score (le_objects.js tick): the engine ends the performers of the pass before
            return m;
        },
        // played through: one message, and the engine decides from there
        performerFire(host, z, at0, dueMs) {
            if (!window.LE) return;
            LE.send('performer', this.performerMessage(z, at0, dueMs));
        },
        // the score stopped — said only where the score has a performer
        performerStop() {
            if (window.LE && this.host && this.zones('elecPerformer').length) LE.send('performerstop', {});
        },

        // ---- the simulated ear: a player's note, told to the engine as it is about to sound ---------------------------------
        performerEar(host, from, to) {
            if (!window.LE) return 0;
            const zs = this.zones('elecPerformer').filter((z) => z.elec);
            if (!zs.length || zs.every((z) => z.elec.ear === 'mic')) return 0;
            let lo = Infinity, hi = -Infinity;
            for (const z of zs) { if (z.startTime < lo) lo = z.startTime; if (z.endTime > hi) hi = z.endTime; }
            if (to < lo - 0.5 || from > hi) return 0;   // no performer is near: nothing to tell
            let n = 0;
            for (const o of host.objects) {
                if (o.type !== 'waveCurve' || o.sonifyNote == null || !(o.layer < this.opts.lanes)) continue;
                const s = o.startSeconds;
                if (!(s > from && s <= to)) continue;
                if (host.isPartAudible && !host.isPartAudible(o.layer)) continue;
                const player = this.playerOf(o.layer);
                if (!player) continue;
                const perf = host.playStartTime + (s - host.playStartOffset / host.pixelsPerSecond) * 1000;
                const dueMs = Math.max(0, Math.round(((Number.isFinite(perf) ? perf : performance.now()) - performance.now()) * 10) / 10);
                LE.send('onset', { player, lane: o.layer, id: String(o.id), t: r3(s), dueMs, sim: 1 });
                n++;
            }
            return n;
        },

        // ---- the panel ------------------------------------------------------------------------------------------------------
        performerSettings(e) {
            const o = { id: e.id, state: e.state };
            if (e.state === 'change') { o.from = e.from; o.to = e.to; }
            for (const k of ['target', 'targetFrom', 'mark', 'seed', 'silenceMs', 'ear', 'label']) if (e[k] != null && e[k] !== '') o[k] = e[k];
            o.pal = Array.isArray(e.pal) ? e.pal : [];
            if (e.dials && typeof e.dials === 'object') o.dials = e.dials;
            return o;
        },
        // the whole setting written at once (the panel's box): what is not a setting is left out, what is out of range is brought in
        performerApply(zone, o) {
            const e = zone.elec, st = (s) => (STATES.some((x) => x[0] === s) ? s : null);
            if (!o || typeof o !== 'object') return;
            if (o.id != null && safe(o.id)) e.id = safe(o.id);
            if (st(o.state)) e.state = o.state;
            if (e.state === 'change') { e.from = st(o.from) && o.from !== 'change' ? o.from : (e.from || 'far'); e.to = st(o.to) && o.to !== 'change' ? o.to : (e.to || 'approaching'); }
            else { delete e.from; delete e.to; }
            for (const k of ['target', 'targetFrom']) if (o[k] != null) { if (safe(o[k])) e[k] = safe(o[k]); else delete e[k]; }
            if (o.mark != null && this.MARKS.includes(String(o.mark))) e.mark = String(o.mark);
            if (o.seed != null && Number.isFinite(+o.seed)) e.seed = Math.max(1, Math.round(+o.seed));
            if (o.silenceMs != null && Number.isFinite(+o.silenceMs)) e.silenceMs = Math.max(0, Math.round(+o.silenceMs));
            if (o.ear === 'sim' || o.ear === 'mic') e.ear = o.ear;
            if (Array.isArray(o.pal)) e.pal = o.pal.map(safe).filter(Boolean).slice(0, 200);
            if (o.dials && typeof o.dials === 'object') e.dials = Object.fromEntries(Object.entries(o.dials).filter(([k, v]) => /^[A-Za-z][A-Za-z0-9]*$/.test(k) && Number.isFinite(+v)).map(([k, v]) => [k, +v]));
            if (typeof o.label === 'string') e.label = o.label.trim().slice(0, 48);
        },
        performerPanel(zone, sec, ui) {
            const e = zone.elec, { el, rowEl, note, commit } = ui, small = 'font-size:11px';
            if (!Array.isArray(e.pal)) e.pal = [];
            const text = (value, fn, title, width) => { const i = el('input', { type: 'text', value: String(value == null ? '' : value), title: title || '', style: width ? 'width:' + width : '' }); i.addEventListener('change', () => commit(() => fn(String(i.value || '').trim()))); return i; };
            const pick = (value, opts, fn, title) => {
                const s = el('select', { title: title || '' });
                for (const [k, t] of opts) s.appendChild(el('option', { value: k, textContent: t, selected: k === value }));
                s.addEventListener('change', () => { s.blur(); commit(() => fn(s.value)); });
                return s;
            };
            const four = STATES.filter((s) => s[0] !== 'change');
            sec.appendChild(rowEl('Player', text(e.id || 'e1', (v) => { if (safe(v)) e.id = safe(v); }, 'which computer player — e1 · e2 · e3: it keeps its memory and its place in its palette by this name', '70px')));
            sec.appendChild(rowEl('State', pick(e.state || 'far', STATES, (v) => { e.state = v; if (v === 'change') { e.from = e.from || 'far'; e.to = e.to || 'approaching'; } else { delete e.from; delete e.to; } })));
            if (e.state === 'change') {
                sec.appendChild(rowEl('From', pick(e.from || 'far', four, (v) => { e.from = v; })));
                sec.appendChild(rowEl('To', pick(e.to || 'approaching', four, (v) => { e.to = v; })));
                sec.appendChild(note('each decision in a change is a coin weighted by the place in the brick: the state before at its start, the state after at its end'));
            }
            const hint = 'a player\'s name (as the engine knows it) · another computer player · any · cluster — whoever plays';
            if (listens(e.state) || (e.state === 'change' && listens(e.to))) sec.appendChild(rowEl('Listens to', text(e.target || 'any', (v) => { e.target = safe(v) || 'any'; }, hint, '90px')));
            if (e.state === 'change' && listens(e.from)) sec.appendChild(rowEl('… before', text(e.targetFrom || 'any', (v) => { e.targetFrom = safe(v) || 'any'; }, hint + ' — in the state it leaves', '90px')));
            if (e.state === 'breakRejoin') {
                const sil = el('input', { type: 'number', value: String(Math.round(+e.silenceMs || 0)), step: '100', min: '0', style: 'width:80px', title: 'its silence, from the brick\'s start; then it comes in as a cluster breaks up' });
                sil.addEventListener('change', () => commit(() => { e.silenceMs = Math.max(0, Math.round(+sil.value || 0)); }));
                sec.appendChild(rowEl('Silence (ms)', sil));
            }
            sec.appendChild(rowEl('Dynamic', pick(this.MARKS.includes(String(e.mark)) ? String(e.mark) : 'mf', this.MARKS.map((m) => [m, m]), (v) => { e.mark = v; }, 'its dynamic on the players\' ladder')));
            sec.appendChild(rowEl('Hears', pick(e.ear === 'mic' ? 'mic' : 'sim', [['sim', 'the score\'s notes, told by this page (a simulation)'], ['mic', 'the players\' microphones (a concert)']], (v) => { e.ear = v; })));
            const pal = el('textarea', { value: e.pal.join('\n'), rows: 5, spellcheck: false, title: 'THE PALETTE: the banked samples it plays, one a line, dealt round robin', style: 'width:100%;box-sizing:border-box;font:10px/1.3 monospace' });
            pal.addEventListener('change', () => commit(() => { e.pal = String(pal.value || '').split(/[\s,]+/).map(safe).filter(Boolean).slice(0, 200); }));
            sec.appendChild(el('div', { className: 'pp-row' }, [pal]));
            const missing = e.pal.filter((n) => !this.row(n));
            sec.appendChild(note(e.pal.length + ' samples in its palette' + (missing.length ? ' — ' + missing.length + ' NOT IN THE BANK: ' + missing.slice(0, 3).join(' · ') + (missing.length > 3 ? ' …' : '') : '')
                + ' · the engine decides each sound as it plays: its window says why'));
            const box = el('textarea', { value: JSON.stringify(this.performerSettings(e), null, 1), rows: 6, spellcheck: false, style: 'width:100%;box-sizing:border-box;font:10px/1.3 monospace' });
            box.addEventListener('change', () => {
                let o;
                try { o = JSON.parse(box.value); } catch (err) { this.say('the box is not valid JSON: ' + err.message); return; }
                commit(() => this.performerApply(zone, o));
            });
            sec.appendChild(el('div', { className: 'pp-row' }, [box]));
        },
    });
})();
