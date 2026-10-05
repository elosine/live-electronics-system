// le_msg.js — the composer score's VOICE to the engine (the engine plan's 4.2 d; the first file of the composer-score seam).
// A piece's composer page loads it with ONE tag —   <script src="/electronics/le_msg.js"></script>   . The objects that
// speak through it are le_objects.js's (the mic opening, the return).
//
//   LE.send(kind, data)     one message to the engine:  POST /api/elec { kind, data }  ->  /le/<kind>  name value …
//                           It returns at once and never throws: a score does not wait on the electronics, or stop for them.
//   LE.playerOf(port)       the engine's player whose MIDI port this is (the piece's route table) — or null
//   LE.hello()              -> { ok, engine: true | false, ms }      is the engine there?
//   LE.cfg                  what GET /api/elec answered: the players, the engine's address (null: no relay)
//   (The test hook of the message route's first proof — LE.noteOn, a note's onset told to the engine — went out when the
//   mic opening became a brick of its own: the engine plan's 4.3, 2026-10-04.)
//   LE.sent                 the last 50 messages, newest last — for a look from the console
//
// CONCERT AND SIMULATION use the same call and the same road: this page -> the score server -> OSC -> the engine.
// In concert the page is on a player's tablet and the note is the player's; in the simulation the page also plays the
// sampled player. Nothing in this file knows a piece: the players and their ports come from the piece's route table.
(function () {
    'use strict';
    const LE = {
        url: '/api/elec', cfg: null, ready: null, sent: [],
        init() {
            this.ready = fetch(this.url, { cache: 'no-store' })
                .then((r) => (r.ok ? r.json() : null))
                .then((c) => { this.cfg = c && c.ok ? c : null; return this.cfg; })
                .catch(() => null);
            return this.ready;
        },
        send(kind, data) {
            const m = { kind, data: data || {} };
            this.sent.push(m); if (this.sent.length > 50) this.sent.shift();
            try {
                return fetch(this.url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(m), keepalive: true })
                    .then((r) => r.json()).catch(() => null);
            } catch (e) { return Promise.resolve(null); }
        },
        playerOf(port) {
            const k = String(port || '').toLowerCase(), ps = (this.cfg && this.cfg.players) || [];
            const p = ps.find((x) => (x.ports || [x.port]).some((q) => String(q || '').toLowerCase() === k));   // a player may own several ports — the percussionist's two lanes
            return p ? p.name : null;
        },
        hello() { return this.send('hello', {}); },
    };
    window.LE = LE;
    LE.init();
})();
