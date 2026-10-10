// le_strike.js — THE SIXTH COMPOSER-SCORE OBJECT FOR THE ELECTRONICS: A STRIKE WINDOW — the ensemble strikes in here; the
// electronics answers AFTER the strike with a version of its RHYTHM (first built in the Decibel piece, 2026-10-09 — its PLAN 1.9 ·
// 17.1, RUNNING_LOG §297; the engine's sc/strike.scd). A piece's composer page loads it with ONE tag, after le_objects.js —
//     <script src="/electronics/le_strike.js"></script>
// It is a MIXIN on LEObjects, as le_performer.js is: that file hands this one the label, the panel, the key and the tick.
//
//   midiModel 'elecStrike'   THE ENSEMBLE STRIKES INSIDE THIS WINDOW — notated, or freely. NOTHING IS RECORDED: only the onset
//       times are taken (and each onset's loudness), from every player at once — the microphones POOLED, one voice. When the
//       strike is over (gapMs of silence after its last onset, or the window's end + gapMs at the latest) the ENGINE answers:
//       the rhythm TRANSFORMED (type), placed AFTER the strike (timing), one banked sample a player, each onset at the strike's
//       loudness (level 'mimic') or at a mark.
//       elec: { id?, type, timing, seed, gapMs?, level?, deal?, players?, samples?, processed?, answerOf?, label? }
//         type       asPlayed · retrograde · invert · spread · compress · scramble · rotate · thin · thicken   (StrikeCalc.TYPES)
//         timing     rightAfter · aBeatLater · callResponse · muchLater · inLaterWindow                        (StrikeCalc.TIMINGS)
//         seed       the window's dice: the same seed, the same draws — in this page's preview and in the engine alike
//         gapMs      the silence that ends a strike (the catalogue's, 500)
//         level      mimic — each answer onset at the level of the strike onset it came from · a mark (ppp … fff) — every onset at it
//         deal       robin — the players in turn over the answer's onsets (a sixth onset: one player twice) · all — every player at every onset
//         players    the players who answer (the engine's names); empty = every player the bank has
//         samples    'bank' — one sample a player, rolled, none twice until all are used · or a list of names, dealt in order
//         processed  true: the processed versions are in the roll beside the raw captures
//         raw        [17.3] false: the raw captures are OUT of the deck — the processed versions only; absent = the catalogue's samples.raw, else in
//         envs       [§337] the endings a processed version must have to be rolled (perc, expodec …; the index row's end) — absent: the catalogue's samples.envs; empty: any
//         cats       [§337] the categories a capture must have to be rolled (impulse …; the index row's category) — absent: the catalogue's samples.categories; empty: any
//         answerOf   the id of an EARLIER window: this window's answer uses THAT strike's rhythm (the come-back, the piece's 17.3) —
//                    carried on the brick and in the message from the first build; the engine keeps every strike it heard
//         mode       [the Decibel piece's 17.3, DEC-119] notated — the strike is played as written · open — the ensemble strikes freely inside
//                    the window (in a simulation the score's notes stand in for them). A WORD for the score and its notation: the engine
//                    listens the same way to both. Absent = unsaid.
//         graceMs    [17.3] how long after the window's END an onset still belongs to it; absent = gapMs (as it always was). Small where
//                    windows stand close, so the next strike's first onset is not taken by this one.
//         chain      [17.3, DEC-120] THE CASCADE — a list of further answers, each { type, timing, seed }: the window answers 1 + chain.length
//                    times. Answer 1 is the brick's own type · timing · seed on the STRIKE's rhythm; each link transforms the rhythm of the
//                    ANSWER BEFORE IT (never the strike's again) and is placed by its timing after that answer's last onset; its samples
//                    are dealt afresh. A plain link (asPlayed) is a link. Absent or empty = one answer, as it always was.
//       Its lane is only where it is drawn: it listens to ALL the players. Played through, it sends ONE message at its start —
//           /le/strike   id · t · dueMs · lengthMs · [offsetMs · wholeMs] · type · timing · seed · gapMs · level · deal · [players ·
//                        samples · processed · answerOf · mode · answers · chain · dials2 · dials3 …] · dials · pass · zone · lane
//                        (chain: type:timing:seed,type:timing:seed — dialsN: the catalogue's numbers for answer N, as `dials` is answer 1's)
//       — and from then on the ENGINE collects the onsets and answers (sc/strike.scd). The score's stop:  /le/strikestop .
//
//   THE SIMULATED EAR (the correspondence rule, the Decibel piece's D10): in a concert the engine hears the pooled microphones.
//   In a simulation the players are NOTES of the score — so while a window is near, this file tells the engine of every note that
//   BEGINS INSIDE a window, as it is about to sound, with its loudness as a mark:
//       /le/onset   player · lane · id · t · dueMs · sim 1 · mark
//   A note outside every window is not told. The engine's collection and answer are ONE code path; the ear is the only difference.
//
//   THE CATALOGUE — the piece's numbers (opts.strikeUrl, by default /bank/strike_responses.json): a draw range per transformation
//   and per timing. The brick's message CARRIES the numbers it uses (dials), so the engine needs no file: a piece's catalogue lives in
//   its page and its tools; the engine's own defaults mirror this module's (StrikeCalc.DEFAULTS).
//
//   StrikeCalc — THE PURE PART, the same function the engine runs in SC (proven equal on the check's lists): the dice (a Lehmer
//   generator, 16807 mod 2^31 − 1 — the performer's), the transformations, the timing. In node: require('…/le_strike.js') is StrikeCalc.
//
// Nothing here knows a piece. What it asks of LEObjects: MODELS · host · opts · zones · is · say · MARKS · playerOf · make · tick ·
// attach · fire · panel. What it asks of the page: window.LE (le_msg.js). What it WRAPS of the host: stopPlay (so a stop reaches the engine).
(function (root) {
    'use strict';
    const r3 = (x) => Math.round(x * 1000) / 1000, r1 = (x) => Math.round(x * 10) / 10;
    const safe = (s) => String(s == null ? '' : s).replace(/[^A-Za-z0-9_~-]/g, '').slice(0, 64);
    const MARKS = ['ppp', 'pp', 'p', 'mp', 'mf', 'f', 'ff', 'fff'];

    // ---------------------------------------------------------------- StrikeCalc: the pure part --------------------------------
    const TYPES = ['asPlayed', 'retrograde', 'invert', 'spread', 'compress', 'scramble', 'rotate', 'thin', 'thicken'];
    const TIMINGS = ['rightAfter', 'aBeatLater', 'callResponse', 'muchLater', 'inLaterWindow'];
    const TYPE_NAME = { asPlayed: 'as played', retrograde: 'retrograde', invert: 'inverted', spread: 'spread', compress: 'compressed', scramble: 'scrambled', rotate: 'rotated', thin: 'thinned', thicken: 'thickened' };
    const TIMING_NAME = { rightAfter: 'right after', aBeatLater: 'a beat later', callResponse: 'call and response', muchLater: 'much later', inLaterWindow: 'in a later window' };
    // the module's own numbers — a piece's catalogue (bank/strike_responses.json) overrides them; the engine's strikeDefaults mirror them
    const DEFAULTS = {
        gapMs: 500, level: 'mimic', deal: 'robin', samples: { processed: true, raw: true, envs: [], categories: [] },   // [§337] envs · categories: the deck's filters (empty = any) · [17.3] raw: the captures in the deck (false = the processed versions only)
        transformations: {
            asPlayed: {}, retrograde: {}, invert: {},
            spread: { range: [1.5, 3] }, compress: { range: [0.3, 0.7] },
            scramble: {}, rotate: {},
            thin: { share: [0.3, 0.5] }, thicken: { share: [0.3, 0.5], copyMs: [40, 120] },
        },
        timings: {
            rightAfter: { rangeS: [0.3, 0.8] }, aBeatLater: { rangeS: [1, 2] },
            callResponse: { ofStrike: [0.8, 1.2], minMs: 300 },
            muchLater: { rangeS: [6, 15] }, inLaterWindow: { rangeS: [10, 15], offsetS: [0, 0.5] },
        },
    };
    // the dice: a Lehmer generator (16807 mod 2^31 − 1), the performer's — the same seed, the same draws, here and in the engine
    const rng = (seed) => { let rs = ((Math.max(1, Math.round(+seed) || 1) * 7919) + 104729) % 2147483646 + 1; return () => { rs = (rs * 16807) % 2147483647; return rs / 2147483647; }; };
    const shuffle = (a, rnd) => { for (let i = a.length - 1; i > 0; i--) { const j = Math.min(i, Math.floor(rnd() * (i + 1))); const t = a[i]; a[i] = a[j]; a[j] = t; } return a; };
    const draw = (lo, hi, rnd) => lo + (hi - lo) * rnd();
    // the dials a brick's message carries — the catalogue's numbers for its type and its timing, flat
    const dialsFor = (cat, type, timing) => {
        const C = cat || DEFAULTS, T = ((C.transformations || {})[type]) || DEFAULTS.transformations[type] || {}, W = ((C.timings || {})[timing]) || DEFAULTS.timings[timing] || {};
        const d = {};
        const r = T.range || T.share; if (r) { d.lo = +r[0]; d.hi = +r[1]; }
        if (T.copyMs) { d.copyLo = +T.copyMs[0]; d.copyHi = +T.copyMs[1]; }
        const w = W.rangeS || W.ofStrike; if (w) { d.wLo = +w[0]; d.wHi = +w[1]; }
        if (W.minMs != null) d.minMs = +W.minMs;
        return d;
    };
    const dialsText = (d) => Object.entries(d || {}).filter(([k, v]) => /^[A-Za-z][A-Za-z0-9]*$/.test(k) && Number.isFinite(+v)).map(([k, v]) => k + '=' + v).join(',');
    const dialsParse = (s) => { const d = {}; String(s || '').split(',').forEach((kv) => { const b = kv.split('='); if (b.length === 2 && Number.isFinite(+b[1])) d[b[0].trim()] = +b[1]; }); return d; };
    const rebuild = (gaps, marks) => { const out = [{ atMs: 0, mark: marks[0] }]; let t = 0; gaps.forEach((g, i) => { t += g; out.push({ atMs: t, mark: marks[i + 1] }); }); return out; };
    // the transformation: a list of (atMs from the first, mark) → a new list; the gaps are the material; the draws in ONE fixed order
    const transform = (type, ons, D, rnd) => {
        const n = ons.length; if (!n) return [];
        const marks = ons.map((o) => o.mark), gaps = ons.slice(1).map((o, i) => o.atMs - ons[i].atMs), m = gaps.length, d = D || {};
        const num = (k, def) => (Number.isFinite(+d[k]) ? +d[k] : def);
        switch (type) {
            case 'retrograde': { const span = ons[n - 1].atMs; return ons.map((_, i) => ({ atMs: span - ons[n - 1 - i].atMs, mark: ons[n - 1 - i].mark })); }
            case 'invert': { if (!m) return ons.map((o) => ({ atMs: o.atMs, mark: o.mark })); const hi = Math.max(...gaps), lo = Math.min(...gaps); return rebuild(gaps.map((g) => hi + lo - g), marks); }
            case 'spread': case 'compress': { const def = type === 'spread' ? [1.5, 3] : [0.3, 0.7]; const f = draw(num('lo', def[0]), num('hi', def[1]), rnd); return rebuild(gaps.map((g) => g * f), marks); }
            case 'scramble': return rebuild(shuffle(gaps.slice(), rnd), marks);
            case 'rotate': { if (m < 2) return ons.map((o) => ({ atMs: o.atMs, mark: o.mark })); const k = 1 + Math.floor(rnd() * (m - 1)); return rebuild(gaps.slice(k).concat(gaps.slice(0, k)), marks); }
            case 'thin': {
                const share = draw(num('lo', 0.3), num('hi', 0.5), rnd), k = Math.max(0, Math.min(n - 1, Math.round(share * n)));
                const idx = shuffle(Array.from({ length: n - 1 }, (_, i) => i + 1), rnd), drop = new Set(idx.slice(0, k));
                return ons.filter((_, i) => !drop.has(i)).map((o) => ({ atMs: o.atMs, mark: o.mark }));   // the first is never dropped: it stays at 0
            }
            case 'thicken': {
                const share = draw(num('lo', 0.3), num('hi', 0.5), rnd), k = Math.max(0, Math.min(n, Math.round(share * n)));
                const pick = shuffle(Array.from({ length: n }, (_, i) => i), rnd).slice(0, k).sort((a, b) => a - b);
                const out = ons.map((o, i) => ({ atMs: o.atMs, mark: o.mark, seq: i }));
                pick.forEach((i, j) => out.push({ atMs: ons[i].atMs + draw(num('copyLo', 40), num('copyHi', 120), rnd), mark: ons[i].mark, seq: n + j }));
                return out.sort((a, b) => a.atMs - b.atMs || a.seq - b.seq).map((o) => ({ atMs: o.atMs, mark: o.mark }));
            }
            default: return ons.map((o) => ({ atMs: o.atMs, mark: o.mark }));
        }
    };
    // the timing: how long after the strike's LAST onset the answer's first onset falls (ms)
    const timing = (kind, strikeLenMs, D, rnd) => {
        const d = D || {}, num = (k, def) => (Number.isFinite(+d[k]) ? +d[k] : def), W = DEFAULTS.timings[kind] || DEFAULTS.timings.rightAfter;
        if (kind === 'callResponse') { const f = draw(num('wLo', W.ofStrike[0]), num('wHi', W.ofStrike[1]), rnd); return Math.max(num('minMs', W.minMs), strikeLenMs) * f; }
        return draw(num('wLo', W.rangeS[0]), num('wHi', W.rangeS[1]), rnd) * 1000;
    };
    // a whole answer from a strike: the transformation, then the timing — the draws in this order, the engine's the same
    const answer = (ons, e, D) => {
        const rnd = rng(e && e.seed), type = TYPES.includes(e && e.type) ? e.type : 'asPlayed', tm = TIMINGS.includes(e && e.timing) ? e.timing : 'rightAfter';
        const out = transform(type, ons, D, rnd), len = ons.length ? ons[ons.length - 1].atMs - ons[0].atMs : 0;
        return { onsets: out, afterMs: timing(tm, len, D, rnd), rnd };
    };
    const markIndex = (m) => Math.max(0, MARKS.indexOf(String(m)));
    // THE CASCADE [17.3, DEC-120]: a brick's further answers, each { type, timing, seed } — read whole or not at all (an unknown word is dropped)
    const MAXLINKS = 4, MODES = ['notated', 'open'];
    const chainOf = (e) => (Array.isArray(e && e.chain) ? e.chain : []).filter((l) => l && TYPES.includes(l.type) && TIMINGS.includes(l.timing)).slice(0, MAXLINKS)
        .map((l) => ({ type: l.type, timing: l.timing, seed: Math.max(1, Math.round(+l.seed) || 1) }));
    const spanMs = (ons) => ons.reduce((m, o) => Math.max(m, o.atMs), 0);
    // every answer of a window, in order: answer 1 from the strike; answer k from ANSWER k − 1's onsets — each link its own dice (its seed), its
    // own catalogue numbers. `fromMs` is where an answer's first onset falls, counted from the STRIKE's last onset: the answer before's start +
    // its span + this one's timing. The engine's strikeCascade is this function.
    const cascade = (ons, e, cat) => {
        const out = []; let mat = ons, from = 0;
        [{ type: e && e.type, timing: e && e.timing, seed: e && e.seed }].concat(chainOf(e)).forEach((l, k) => {
            const a = answer(mat, l, dialsFor(cat, l.type, l.timing));
            from = (k ? from + spanMs(mat) : 0) + a.afterMs;
            out.push({ k: k + 1, type: TYPES.includes(l.type) ? l.type : 'asPlayed', timing: TIMINGS.includes(l.timing) ? l.timing : 'rightAfter', seed: Math.max(1, Math.round(+l.seed) || 1), onsets: a.onsets, afterMs: a.afterMs, fromMs: from });
            mat = a.onsets;
        });
        return out;
    };
    const StrikeCalc = { TYPES, TIMINGS, TYPE_NAME, TIMING_NAME, DEFAULTS, MARKS, MODES, MAXLINKS, rng, shuffle, draw, dialsFor, dialsText, dialsParse, transform, timing, answer, markIndex, chainOf, spanMs, cascade };
    if (typeof module !== 'undefined' && module.exports) module.exports = StrikeCalc;
    root.StrikeCalc = StrikeCalc;

    // ---------------------------------------------------------------- the mixin: the brick ------------------------------------
    const L = root.LEObjects;
    if (!L) return;
    L.MODELS.elecStrike = { kind: 'strike', sign: '⊡', color: '#9E9D24', yOffset: 0, title: 'Strike window — the ensemble strikes here; the electronics answers after' };   // yOffset: a fraction of the lane (0 top · 1 bottom)

    const attach = L.attach;
    L.attach = function (host, opts) {
        const first = !this.host, r = attach.apply(this, arguments);
        if (first && host) {
            if (typeof host.stopPlay === 'function') { const stop = host.stopPlay; host.stopPlay = function () { const out = stop.apply(this, arguments); L.strikeStop(); return out; }; }
            this.strikeCat = null;
            const url = (opts && opts.strikeUrl) || this.opts.strikeUrl || '/bank/strike_responses.json';
            try { fetch(url, { cache: 'no-store' }).then((x) => (x && x.ok ? x.json() : null)).then((j) => { if (j && j.transformations) this.strikeCat = j; }).catch(() => {}); } catch (err) { /* no catalogue: the module's own numbers */ }
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
        this.strikeEar(host, from, to);
        return r;
    };

    Object.assign(L, {
        strikeCat: null,
        strikeDefaults() { const C = this.strikeCat || DEFAULTS, S = C.samples || DEFAULTS.samples; return Object.assign({ type: 'asPlayed', timing: 'rightAfter', seed: 1, gapMs: +C.gapMs || DEFAULTS.gapMs, level: C.level || 'mimic', deal: C.deal || 'robin', players: [], samples: 'bank', processed: !!S.processed }, S.raw === false ? { raw: false } : {}); },
        strikeDials(e) { return dialsFor(this.strikeCat, e.type, e.timing); },
        // a note's loudness as a mark: the host's own rule (opts.noteMark), else the drawn anchor — a struck note's velocity (recVel), or its
        // height on the written scale (65 + 62 · h, the page's held-note law), the nearest of the eight marks
        noteMark(o) {
            if (typeof this.opts.noteMark === 'function') { const m = this.opts.noteMark(o); if (MARKS.includes(m)) return m; }
            const y = o && o.nodes && o.nodes[0] ? +o.nodes[0].y : 5, anchor = o && Number.isFinite(+o.recVel) ? +o.recVel : 65 + 62 * Math.max(0, Math.min(10, y)) / 10;
            return MARKS[Math.max(0, Math.min(7, Math.round((anchor - 65) / 62 * 7)))];
        },
        // the notes a window hears in the simulation: every note that BEGINS inside it (a hair before, for a note the window was drawn on)
        strikeNotes(host, z) {
            const out = [];
            for (const o of host.objects) {
                if (o.type !== 'waveCurve' || o.sonifyNote == null || !(o.layer < this.opts.lanes)) continue;
                if (o.startSeconds < z.startTime - 0.05 || o.startSeconds > z.endTime) continue;
                if (host.isPartAudible && !host.isPartAudible(o.layer)) continue;
                out.push(o);
            }
            return out.sort((a, b) => a.startSeconds - b.startSeconds || String(a.id).localeCompare(String(b.id)));
        },
        // what the engine will answer, by the same dice — shown under the brick; null with no note under the window
        strikeExpected(host, z) {
            const e = z.elec || {}, notes = this.strikeNotes(host, z);
            if (!notes.length) return null;
            const first = notes[0].startSeconds, last = notes[notes.length - 1].startSeconds;
            const ons = notes.map((o) => ({ atMs: r1((o.startSeconds - first) * 1000), mark: this.noteMark(o) }));
            const a = answer(ons, e, this.strikeDials(e));
            // [17.3] every answer of the cascade, each with the second it begins at (the first is `a` again, by the same dice)
            const answers = cascade(ons, e, this.strikeCat).map((x) => Object.assign(x, { startS: last + x.fromMs / 1000 }));
            return { notes, ons, onsets: a.onsets, afterMs: a.afterMs, lastS: last, startS: last + a.afterMs / 1000, answers };
        },
        // ---- the label ------------------------------------------------------------------------------------------------------
        strikeLabel(zone) {
            const e = zone.elec || {}, M = this.MODELS.elecStrike, ch = chainOf(e), nm = (k) => TYPE_NAME[k] || k || '?';
            // [17.3] the mode's word after the name; a cascade says its count and its chain of rhythms (the timings are in the panel)
            return M.sign + ' ' + (e.label ? String(e.label).slice(0, 48) + ' · ' : '') + (e.id ? e.id + ' · ' : '') + (MODES.includes(e.mode) ? e.mode + ' · ' : '')
                + (ch.length ? '×' + (ch.length + 1) + ' · ' + [e.type].concat(ch.map((l) => l.type)).map(nm).join(' → ') : nm(e.type) + ' · ' + (TIMING_NAME[e.timing] || e.timing || '?'))
                + (e.level && e.level !== 'mimic' ? ' · ' + e.level : '') + ' · s' + (Math.max(1, Math.round(+e.seed) || 1)) + (e.answerOf ? ' · answers ' + e.answerOf : '');
        },
        // ---- the message ----------------------------------------------------------------------------------------------------
        strikeMessage(zone, at0, dueMs) {
            const e = zone.elec || {}, a = zone.startTime, start = Math.max(a, at0 == null ? a : at0), def = this.strikeDefaults();
            const m = { id: safe(e.id) || String(zone.id), t: r3(start), dueMs: dueMs || 0, lengthMs: Math.max(50, Math.round((zone.endTime - start) * 1000)),
                type: TYPES.includes(e.type) ? e.type : 'asPlayed', timing: TIMINGS.includes(e.timing) ? e.timing : 'rightAfter', seed: Math.max(1, Math.round(+e.seed) || 1),
                gapMs: Math.max(50, Math.round(+e.gapMs || def.gapMs)), level: MARKS.includes(String(e.level)) ? String(e.level) : 'mimic', deal: e.deal === 'all' ? 'all' : 'robin',
                processed: (e.processed == null ? def.processed : !!e.processed) ? 1 : 0, zone: String(zone.id), lane: zone.layer };
            // [§337, DEC-113] THE DECK'S FILTERS — the endings a processed version may have (`envs`) and the categories a capture may have (`cats`):
            // the piece's catalogue (samples.envs · samples.categories), a brick's own e.envs · e.cats over it; absent or empty = any. The engine filters.
            const S = (this.strikeCat || DEFAULTS).samples || {}, envs = Array.isArray(e.envs) ? e.envs : (S.envs || []), cats = Array.isArray(e.cats) ? e.cats : (S.categories || []);
            if (envs.length) m.envs = envs.map(safe).filter(Boolean).join(',');
            if (cats.length) m.cats = cats.map(safe).filter(Boolean).join(',');
            if (!(e.raw == null ? S.raw !== false : !!e.raw)) m.raw = 0;   // [17.3] the raw captures out of the deck — the processed versions only (absent = in, as before)
            if (start > a + 0.001) { m.offsetMs = Math.round((start - a) * 1000); m.wholeMs = Math.round((zone.endTime - a) * 1000); }
            if (Array.isArray(e.players) && e.players.length) m.players = e.players.map(safe).filter(Boolean).join(',');
            if (Array.isArray(e.samples) && e.samples.length) m.samples = e.samples.map(safe).filter(Boolean).join(',');
            if (e.answerOf) m.answerOf = safe(e.answerOf);
            const dials = dialsText(this.strikeDials(e)); if (dials) m.dials = dials;
            // [17.3] the mode's word, and THE CASCADE: how many answers, the links, and each link's own numbers from the catalogue
            if (MODES.includes(e.mode)) m.mode = e.mode;
            if (e.graceMs != null && Number.isFinite(+e.graceMs)) m.graceMs = Math.max(0, Math.round(+e.graceMs));   // how long after its end an onset still belongs to it (absent: the gap)
            const ch = chainOf(e);
            if (ch.length) {
                m.answers = ch.length + 1; m.chain = ch.map((l) => l.type + ':' + l.timing + ':' + l.seed).join(',');
                ch.forEach((l, i) => { const dt = dialsText(dialsFor(this.strikeCat, l.type, l.timing)); if (dt) m['dials' + (i + 2)] = dt; });
            }
            if (this._passN) m.pass = this._passN;
            return m;
        },
        strikeFire(host, z, at0, dueMs) { if (root.LE) LE.send('strike', this.strikeMessage(z, at0, dueMs)); },
        strikeStop() { if (root.LE && this.host && this.zones('elecStrike').length) LE.send('strikestop', {}); },
        // ---- the simulated ear: a note that begins inside a window, told as it is about to sound, with its loudness --------
        strikeEar(host, from, to) {
            if (!root.LE) return 0;
            const zs = this.zones('elecStrike').filter((z) => z.elec);
            if (!zs.length) return 0;
            let n = 0;
            for (const o of host.objects) {
                if (o.type !== 'waveCurve' || o.sonifyNote == null || !(o.layer < this.opts.lanes)) continue;
                const s = o.startSeconds;
                if (!(s > from && s <= to)) continue;
                if (!zs.some((z) => s >= z.startTime - 0.05 && s <= z.endTime)) continue;   // outside every window: not told
                if (host.isPartAudible && !host.isPartAudible(o.layer)) continue;
                const player = this.playerOf(o.layer);
                if (!player) continue;
                const perf = host.playStartTime + (s - host.playStartOffset / host.pixelsPerSecond) * 1000;
                const dueMs = Math.max(0, Math.round(((Number.isFinite(perf) ? perf : performance.now()) - performance.now()) * 10) / 10);
                LE.send('onset', { player, lane: o.layer, id: String(o.id), t: r3(s), dueMs, sim: 1, mark: this.noteMark(o) });
                n++;
            }
            return n;
        },
        // ---- the gesture: a window over the selected strike, else at the playhead --------------------------------------------
        addStrike() {
            const h = this.host, o = this.opts, sel = h.selectedObject, def = this.strikeDefaults();
            let layer = h.activeLane, start, end, said = '';
            const grp = sel && sel.type === 'waveCurve' && sel.sonifyNote != null && sel.groupId && /^grp-strike-/.test(String(sel.groupId)) ? String(sel.groupId) : null;
            if (grp) {
                const notes = h.objects.filter((x) => x.type === 'waveCurve' && x.sonifyNote != null && x.groupId === grp && x.layer < o.lanes);
                start = Math.max(0, Math.min(...notes.map((x) => x.startSeconds)) - 0.3); end = Math.max(...notes.map((x) => x.startSeconds)) + 0.5; layer = sel.layer;
                said = ' over ' + notes.length + ' notes of ' + grp;
            } else { start = Math.max(0, h.getTimeAtPlayhead()); end = start + 2; }
            if (layer == null || layer < 0 || layer >= o.lanes) { this.say('a strike window is drawn on a player\'s lane — click a lane first'); return null; }
            const n = this.zones('elecStrike').length + 1;
            const z = this.make('elecStrike', layer, start, end, Object.assign(def, { id: 'W' + n, seed: n }));
            this.say('strike window ' + z.elec.id + ' ' + z.startTime.toFixed(2) + ' → ' + z.endTime.toFixed(2) + ' s' + said + ' — the electronics answers after it: ' + TYPE_NAME[z.elec.type] + ', ' + TIMING_NAME[z.elec.timing]);
            return z;
        },
        // ---- the panel ------------------------------------------------------------------------------------------------------
        strikeSettings(e) {
            const o = {};
            for (const k of ['id', 'mode', 'type', 'timing', 'seed', 'gapMs', 'graceMs', 'level', 'deal', 'processed', 'raw', 'envs', 'cats', 'answerOf', 'label']) if (e[k] != null && e[k] !== '') o[k] = e[k];
            if (chainOf(e).length) o.chain = chainOf(e);   // [17.3]
            if (Array.isArray(e.players) && e.players.length) o.players = e.players;
            o.samples = Array.isArray(e.samples) ? e.samples : 'bank';
            return o;
        },
        strikeApply(zone, o) {
            const e = zone.elec; if (!o || typeof o !== 'object') return;
            if (o.id != null) { if (safe(o.id)) e.id = safe(o.id); else delete e.id; }
            if (TYPES.includes(o.type)) e.type = o.type;
            if (TIMINGS.includes(o.timing)) e.timing = o.timing;
            if (o.seed != null && Number.isFinite(+o.seed)) e.seed = Math.max(1, Math.round(+o.seed));
            if (o.gapMs != null && Number.isFinite(+o.gapMs)) e.gapMs = Math.max(50, Math.round(+o.gapMs));
            if (o.level != null) e.level = MARKS.includes(String(o.level)) ? String(o.level) : 'mimic';
            if (o.deal != null) e.deal = o.deal === 'all' ? 'all' : 'robin';
            if (o.processed != null) e.processed = !!o.processed;
            if (o.raw != null) e.raw = !!o.raw;   // [17.3]
            if (Array.isArray(o.envs)) e.envs = o.envs.map(String); if (Array.isArray(o.cats)) e.cats = o.cats.map(String);   // [§337]
            if (o.players != null) e.players = Array.isArray(o.players) ? o.players.map(safe).filter(Boolean) : [];
            if (o.samples != null) e.samples = Array.isArray(o.samples) && o.samples.length ? o.samples.map(safe).filter(Boolean) : 'bank';
            if (o.answerOf != null) { if (safe(o.answerOf)) e.answerOf = safe(o.answerOf); else delete e.answerOf; }
            if (typeof o.label === 'string') e.label = o.label.trim().slice(0, 48);
            if (o.mode != null) { if (MODES.includes(o.mode)) e.mode = o.mode; else delete e.mode; }                                   // [17.3]
            if (o.graceMs != null) { if (o.graceMs !== '' && Number.isFinite(+o.graceMs)) e.graceMs = Math.max(0, Math.round(+o.graceMs)); else delete e.graceMs; }
            if (o.chain != null) { const c = chainOf({ chain: o.chain }); if (c.length) e.chain = c; else delete e.chain; }         // [17.3] absent from the box = left as it is
        },
        // [17.3] the panel's Answers: the cascade made n answers long — the links kept as they are, a new one drawn from the window's seed
        strikeAnswers(e, n) {
            const want = Math.max(0, Math.min(MAXLINKS, Math.round(+n || 1) - 1)), ch = chainOf(e), base = Math.max(1, Math.round(+e.seed) || 1);
            while (ch.length < want) { const k = ch.length + 2, rnd = rng(base * 131 + k); ch.push({ type: TYPES[Math.min(TYPES.length - 1, Math.floor(rnd() * TYPES.length))], timing: TIMINGS[Math.min(TIMINGS.length - 1, Math.floor(rnd() * TIMINGS.length))], seed: base * 10 + k }); }
            ch.length = want;
            if (ch.length) e.chain = ch; else delete e.chain;
        },
        strikePanel(zone, sec, ui) {
            const e = zone.elec, { el, rowEl, note, commit } = ui, h = this.host, def = this.strikeDefaults();
            const text = (value, fn, title, width) => { const i = el('input', { type: 'text', value: String(value == null ? '' : value), title: title || '', style: width ? 'width:' + width : '' }); i.addEventListener('change', () => commit(() => fn(String(i.value || '').trim()))); return i; };
            const num = (value, fn, step, min, title) => { const i = el('input', { type: 'number', value: String(value), step: String(step), min: String(min), style: 'width:80px', title: title || '' }); i.addEventListener('change', () => commit(() => fn(+i.value))); return i; };
            const pick = (value, opts, fn, title) => { const s = el('select', { title: title || '' }); for (const [k, t] of opts) s.appendChild(el('option', { value: k, textContent: t, selected: k === value })); s.addEventListener('change', () => { s.blur(); commit(() => fn(s.value)); }); return s; };
            sec.appendChild(rowEl('Window', text(e.id || '', (v) => { if (safe(v)) e.id = safe(v); else delete e.id; }, 'this window\'s name — W1 · W2 …; another window may answer this one\'s strike later (its "Answer of")', '70px')));
            sec.appendChild(rowEl('Rhythm', pick(TYPES.includes(e.type) ? e.type : 'asPlayed', TYPES.map((k) => [k, TYPE_NAME[k]]), (v) => { e.type = v; }, 'how the strike\'s rhythm is changed in the answer')));
            sec.appendChild(rowEl('Timing', pick(TIMINGS.includes(e.timing) ? e.timing : 'rightAfter', TIMINGS.map((k) => [k, TIMING_NAME[k]]), (v) => { e.timing = v; }, 'when the answer\'s first onset falls, from the strike\'s last onset')));
            sec.appendChild(rowEl('Seed', num(Math.max(1, Math.round(+e.seed) || 1), (v) => { e.seed = Math.max(1, Math.round(v) || 1); }, 1, 1, 'the window\'s dice: the same seed, the same draws, here and in the engine')));
            // [17.3] the mode's word · THE CASCADE: how many answers, then a row a link — its rhythm (of the answer before), its timing (after it), its dice
            sec.appendChild(rowEl('Mode', pick(MODES.includes(e.mode) ? e.mode : '', [['', '—'], ['notated', 'notated — played as written'], ['open', 'open — struck freely inside the window']], (v) => { if (MODES.includes(v)) e.mode = v; else delete e.mode; }, 'what the players do here — a word for the score and its notation; the electronics listens the same way to both')));
            const links = chainOf(e);
            sec.appendChild(rowEl('Answers', pick(String(links.length + 1), [['1', '1'], ['2', '2 — a cascade'], ['3', '3 — a cascade']].concat(links.length > 2 ? [[String(links.length + 1), String(links.length + 1)]] : []), (v) => { this.strikeAnswers(e, +v); }, 'how many times the electronics answers this strike — each further answer changes the rhythm of the answer before it')));
            links.forEach((l, i) => {
                const set = (fn) => { const c = chainOf(e); if (c[i]) { fn(c[i]); e.chain = c; } };
                sec.appendChild(rowEl('Answer ' + (i + 2), el('span', {}, [
                    pick(l.type, TYPES.map((k) => [k, TYPE_NAME[k]]), (v) => set((c) => { c.type = v; }), 'how the rhythm of answer ' + (i + 1) + ' is changed'),
                    pick(l.timing, TIMINGS.map((k) => [k, TIMING_NAME[k]]), (v) => set((c) => { c.timing = v; }), 'when it begins, from the last onset of answer ' + (i + 1)),
                    num(l.seed, (v) => set((c) => { c.seed = Math.max(1, Math.round(v) || 1); }), 1, 1, 'this answer\'s dice')])));
            });
            sec.appendChild(rowEl('Gap (ms)', num(Math.round(+e.gapMs || def.gapMs), (v) => { e.gapMs = Math.max(50, Math.round(v) || def.gapMs); }, 50, 50, 'the silence that says the strike is over; the answer is placed from then')));
            sec.appendChild(rowEl('Level', pick(MARKS.includes(String(e.level)) ? String(e.level) : 'mimic', [['mimic', 'mimic — as the players struck']].concat(MARKS.map((m) => [m, m])), (v) => { e.level = v; }, 'each answer onset at the level of the strike onset it came from, or every onset at a mark')));
            sec.appendChild(rowEl('Deal', pick(e.deal === 'all' ? 'all' : 'robin', [['robin', 'the players in turn, one sample an onset'], ['all', 'every player at every onset']], (v) => { e.deal = v; })));
            const proc = el('input', { type: 'checkbox', checked: e.processed == null ? def.processed : !!e.processed, title: 'the processed versions are rolled beside the raw captures' });
            proc.addEventListener('change', () => commit(() => { e.processed = !!proc.checked; }));
            sec.appendChild(rowEl('Processed too', proc));
            const S0 = (this.strikeCat || DEFAULTS).samples || {}, rawBox = el('input', { type: 'checkbox', checked: e.raw == null ? S0.raw !== false : !!e.raw, title: 'the raw captures in the deck beside the processed versions; off = the processed versions only' });
            rawBox.addEventListener('change', () => commit(() => { e.raw = !!rawBox.checked; }));
            sec.appendChild(rowEl('Raw captures too', rawBox));   // [17.3]
            sec.appendChild(rowEl('Players', text(Array.isArray(e.players) ? e.players.join(' ') : '', (v) => { e.players = v.split(/[\s,]+/).map(safe).filter(Boolean); }, 'who answers — the engine\'s names, e.g. bfl bcl perc va vc; empty = every player the bank has', '160px')));
            sec.appendChild(rowEl('Samples', text(Array.isArray(e.samples) ? e.samples.join(' ') : 'bank', (v) => { const l = v.split(/[\s,]+/).map(safe).filter(Boolean); e.samples = v === 'bank' || !l.length ? 'bank' : l; }, '"bank" — one a player, rolled, none twice until all are used · or sample names, dealt in order', '160px')));
            sec.appendChild(rowEl('Answer of', text(e.answerOf || '', (v) => { if (safe(v)) e.answerOf = safe(v); else delete e.answerOf; }, 'an EARLIER window\'s name: this answer uses that strike\'s rhythm (the come-back) — empty: this window\'s own', '70px')));
            sec.appendChild(rowEl('Label', text(e.label || '', (v) => { e.label = v.slice(0, 48); }, 'a tag shown first on the brick', '160px')));
            const x = h ? this.strikeExpected(h, zone) : null;
            sec.appendChild(note(x ? x.notes.length + ' notes under the window (' + [...new Set(x.notes.map((o) => this.playerOf(o.layer) || this.opts.laneLabel(o.layer)))].join(' ') + ') · ' + (x.ons.length > 1 ? Math.round(x.ons[x.ons.length - 1].atMs) + ' ms long' : 'one onset')
                + ' → ' + TYPE_NAME[e.type] + ': ' + x.onsets.map((o) => Math.round(o.atMs) + (o.mark !== 'mf' ? o.mark : '')).join(' · ') + ' ms · ' + TIMING_NAME[e.timing] + ': the answer ' + (x.afterMs / 1000).toFixed(2) + ' s after the last note, at ' + x.startS.toFixed(2) + ' s'
                + x.answers.slice(1).map((a) => ' ⟶ answer ' + a.k + ', ' + TYPE_NAME[a.type] + ' of answer ' + (a.k - 1) + ': ' + a.onsets.map((o) => Math.round(o.atMs)).join(' · ') + ' ms · ' + TIMING_NAME[a.timing] + ', at ' + a.startS.toFixed(2) + ' s').join('')
                : 'no note begins inside this window yet — in the simulation the window hears the score\'s notes; in a concert, the pooled microphones'));
            const box = el('textarea', { value: JSON.stringify(this.strikeSettings(e), null, 1), rows: 6, spellcheck: false, style: 'width:100%;box-sizing:border-box;font:10px/1.3 monospace' });
            box.addEventListener('change', () => { let o; try { o = JSON.parse(box.value); } catch (err) { this.say('the box is not valid JSON: ' + err.message); return; } commit(() => this.strikeApply(zone, o)); });
            sec.appendChild(el('div', { className: 'pp-row' }, [box]));
        },
    });
})(typeof window !== 'undefined' ? window : (typeof self !== 'undefined' ? self : this));
