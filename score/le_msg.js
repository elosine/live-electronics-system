// le_msg.js — the composer score's VOICE to the engine (the engine plan's 4.2 d; the first file of the composer-score seam).
// A piece's composer page loads it with ONE tag —   <script src="/electronics/le_msg.js"></script>   — and calls it from
// ONE hook, where its playback hands a note to the sound:   if (window.LE) LE.noteOn(port, lane, id, tSec, atPerf);
//
//   LE.send(kind, data)     one message to the engine:  POST /api/elec { kind, data }  ->  /le/<kind>  name value …
//                           It returns at once and never throws: a score does not wait on the electronics, or stop for them.
//   LE.noteOn(port, lane, id, tSec, atPerf)
//                           THE TEST HOOK, until the mic opening is a brick of its own: a note on a lane whose MIDI port
//                           belongs to one of the engine's players becomes   /le/onset  player  lane  id  t  dueMs
//                           (dueMs: how far ahead of the note's own start the message left — the page schedules ahead).
//                           Only while the piece's route table says  "testOnsets": true.
//   LE.hello()              -> { ok, engine: true | false, ms }      is the engine there?
//   LE.cfg                  what GET /api/elec answered: the players, the engine's address, testOnsets (null: no relay)
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
            const p = ps.find((x) => String(x.port || '').toLowerCase() === k);
            return p ? p.name : null;
        },
        noteOn(port, lane, id, tSec, atPerf) {
            if (!this.cfg || !this.cfg.testOnsets) return;
            const player = this.playerOf(port);
            if (!player) return;
            this.send('onset', { player, lane, id: String(id), t: Math.round(tSec * 1000) / 1000,
                dueMs: Math.max(0, Math.round((atPerf - performance.now()) * 10) / 10) });
        },
        hello() { return this.send('hello', {}); },
    };
    window.LE = LE;
    LE.init();
})();
