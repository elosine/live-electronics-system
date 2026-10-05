// relay.js — a piece's score server -> the engine: a browser's JSON becomes an OSC message (the engine plan's 4.2 c).
//
// A piece's server adds THREE lines (electronics/docs/SEAMS.md):
//     const elecRelay = require('../electronics/tools/relay.js')({ configFile: <the piece's route table> });
//     if (url === '/api/elec') return elecRelay(req, res);
//     if (url.startsWith('/electronics/')) { base = <electronics/score>; rel = url.slice('/electronics'.length); }
//
//   POST /api/elec   { kind: 'onset', data: { player: 'bcl', lane: 1, id: 'wc_12', t: 3.25, dueMs: 87 } }
//                    -> /le/onset  player bcl  lane 1  id wc_12  t 3.25  dueMs 87     to the engine's address.
//                    Answers { ok: true } AT ONCE: UDP gives no receipt, and a score must not wait on one.
//                    kind 'hello' DOES wait (400 ms) and answers { ok, engine: true | false, ms, reply }.
//   GET  /api/elec   what the score's page needs: { ok, engine: { host, port }, players: [{ name, port }], testOnsets }
//                    ?ping=1 adds engine.up and engine.ms (one hello).
//
// THE ADDRESS is never taken from a request — only from the piece's route table, its "message" block:
//     "message": { "host": "127.0.0.1", "port": 57211, "testOnsets": true }
// Concert and simulation use this same road; the address is the one thing that may differ between them.
// The table is read at every request (a few hundred bytes), so a changed table needs no restart of the server.
// NOTHING HERE CAN STOP THE SERVER: every socket has an error handler (osc.js), every failure is an answer.
'use strict';
const fs = require('fs');
const osc = require('./osc.js');

// only what an OSC message can carry: strings, numbers, true / false — anything else is left out
function flat(data) {
    const o = {};
    for (const k of Object.keys(data || {})) {
        const v = data[k];
        if (typeof v === 'string' || typeof v === 'boolean' || (typeof v === 'number' && Number.isFinite(v))) o[k] = v;
    }
    return o;
}

module.exports = function relay({ configFile }) {
    const cfg = () => {
        let c = {};
        try { c = JSON.parse(fs.readFileSync(configFile, 'utf8')); } catch (e) { /* no table: the defaults */ }
        const m = c.message || {};
        return { host: m.host || '127.0.0.1', port: +m.port || osc.PORT, testOnsets: !!m.testOnsets,
            players: (c.players || []).map((p) => ({ name: p.name, port: p.port })) };
    };
    const answer = (res, code, obj) => {
        try { res.statusCode = code; res.setHeader('Content-Type', 'application/json'); res.setHeader('Cache-Control', 'no-store'); res.end(JSON.stringify(obj)); } catch (e) { /* the client left */ }
    };
    const hello = async (c) => {
        const t0 = process.hrtime.bigint();
        const r = await osc.send({ host: c.host, port: c.port, address: '/le/hello', args: ['from', 'relay'], waitMs: 400 });
        return { up: !!r, ms: r ? Math.round(Number(process.hrtime.bigint() - t0) / 1e4) / 100 : null, reply: r ? osc.unpairs(r.args) : null };
    };
    return function handle(req, res) {
        const c = cfg();
        if (req.method === 'GET') {
            const out = { ok: true, engine: { host: c.host, port: c.port }, players: c.players, testOnsets: c.testOnsets };
            if (/[?&]ping=1/.test(req.url || '')) return hello(c).then((h) => { out.engine.up = h.up; out.engine.ms = h.ms; answer(res, 200, out); });
            return answer(res, 200, out);
        }
        if (req.method !== 'POST') return answer(res, 405, { ok: false, error: 'GET or POST' });
        let body = '';
        req.on('data', (d) => { body += d; if (body.length > 65536) req.destroy(); });
        req.on('error', () => answer(res, 400, { ok: false, error: 'the request broke off' }));
        req.on('end', () => {
            let m;
            try { m = JSON.parse(body || '{}'); } catch (e) { return answer(res, 400, { ok: false, error: 'bad JSON' }); }
            const kind = String((m && m.kind) || '');
            if (!/^[a-z][a-zA-Z0-9_]{0,31}$/.test(kind)) return answer(res, 400, { ok: false, error: 'kind: a short name, letters and digits' });
            if (kind === 'hello') return hello(c).then((h) => answer(res, 200, { ok: true, engine: h.up, ms: h.ms, reply: h.reply }));
            let args;
            try { args = osc.pairs(flat(m.data)); osc.encode('/le/' + kind, args); }
            catch (e) { return answer(res, 400, { ok: false, error: String(e.message) }); }
            osc.send({ host: c.host, port: c.port, address: '/le/' + kind, args });
            answer(res, 200, { ok: true });
        });
    };
};
