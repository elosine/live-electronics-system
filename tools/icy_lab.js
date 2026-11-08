#!/usr/bin/env node
// icy_lab.js — THE ICY LAB'S OWN SERVER: the lab page and the road to the engine, and nothing of a piece's composer score
// (his word, 2026-11-07: "maybe we stay out of the composer score" — the lab is a development stage before any sound reaches it).
//
//   node electronics/tools/icy_lab.js --samples <samples.json> --config <elec_route.json> [--port 5620]
//
//   /                      electronics/score/icy_lab.html — the page (one thing at a time; ?all shows every knob)
//   /electronics/<file>    the engine's page code (le_msg.js — the page's voice)
//   /samples.json          the piece's list of samples, with the folder the engine loads them from (--samples)
//   /menu.json             the menu of settings, electronics/score/icy_menu.json — the page's buttons
//   /files/<path>          a folder of the piece's audio (--files), for the auditioning pages
//   /api/elec              the relay (electronics/tools/relay.js): POST { kind: 'icy', data } -> /le/icy to the engine's
//                          language port, from the piece's route table (--config, its "message" block)
//
// The engine itself is started as always (the piece's start_electronics.bat); the sound leaves by its bus. This server only
// serves the page and relays its messages. Nothing here knows a piece: the two files it is pointed at are the piece's.
'use strict';
const fs = require('fs');
const http = require('http');
const path = require('path');

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 && args[i + 1] ? args[i + 1] : d; };
const PORT = +opt('--port', 5620);
const SAMPLES = path.resolve(opt('--samples', 'samples.json'));
const CONFIG = path.resolve(opt('--config', 'bank/elec_route.json'));
const FILES = opt('--files', '');   // a folder served at /files/ — the set's audio on his drive, for the auditioning pages (2026-11-08)
const SCORE_DIR = path.join(__dirname, '..', 'score');
const relay = require('./relay.js')({ configFile: CONFIG });
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.wav': 'audio/wav', '.ogg': 'audio/ogg', '.mp3': 'audio/mpeg', '.flac': 'audio/flac' };

function file(res, p, req) {
    // a file is served with BYTE RANGES (206): a browser's <audio> seeks, resumes and buffers a long WAV by ranges; served whole,
    // a 150 MB file stalled and could not be advanced (his word, 2026-11-09)
    fs.stat(p, (err, st) => {
        if (err || !st.isFile()) { res.statusCode = 404; res.end('not found'); return; }
        const type = MIME[path.extname(p).toLowerCase()] || 'application/octet-stream';
        res.setHeader('Content-Type', type);
        res.setHeader('Cache-Control', 'no-store');
        res.setHeader('Accept-Ranges', 'bytes');
        const range = req && req.headers.range && /^bytes=(\d*)-(\d*)$/.exec(req.headers.range);
        let start = 0, end = st.size - 1;
        if (range && (range[1] || range[2])) {
            if (range[1]) { start = parseInt(range[1], 10); if (range[2]) end = Math.min(parseInt(range[2], 10), st.size - 1); }
            else { start = Math.max(0, st.size - parseInt(range[2], 10)); }
            if (start > end || start >= st.size) { res.statusCode = 416; res.setHeader('Content-Range', 'bytes */' + st.size); res.end(); return; }
            res.statusCode = 206;
            res.setHeader('Content-Range', 'bytes ' + start + '-' + end + '/' + st.size);
        }
        res.setHeader('Content-Length', end - start + 1);
        if (req && req.method === 'HEAD') { res.end(); return; }
        fs.createReadStream(p, { start, end }).on('error', () => { try { res.end(); } catch (e) { /* closed */ } }).pipe(res);
    });
}

http.createServer((req, res) => {
    const url = (req.url || '/').split('?')[0];
    if (url === '/api/elec') return relay(req, res);
    if (url === '/' || url === '/icy_lab.html') return file(res, path.join(SCORE_DIR, 'icy_lab.html'), req);
    if (url === '/samples.json') return file(res, SAMPLES, req);
    if (url === '/menu.json') return file(res, path.join(SCORE_DIR, 'icy_menu.json'), req);   // the menu of settings (the engine's, for every piece)
    if (FILES && url.startsWith('/files/')) {
        const rel = path.normalize(decodeURIComponent(url.slice('/files/'.length))).replace(/^(\.\.[/\\])+/, '');
        return file(res, path.join(FILES, rel), req);
    }
    if (url.startsWith('/electronics/')) {
        const rel = path.normalize(url.slice('/electronics/'.length)).replace(/^(\.\.[/\\])+/, '');
        return file(res, path.join(SCORE_DIR, rel), req);
    }
    res.statusCode = 404; res.end('not found');
}).listen(PORT, () => {
    console.log(`icy lab at http://localhost:${PORT}/  (samples ${SAMPLES}; the engine's address from ${CONFIG})`);
});
