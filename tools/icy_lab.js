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

function file(res, p) {
    fs.readFile(p, (err, data) => {
        if (err) { res.statusCode = 404; res.end('not found'); return; }
        res.setHeader('Content-Type', MIME[path.extname(p).toLowerCase()] || 'application/octet-stream');
        res.setHeader('Cache-Control', 'no-store');
        res.end(data);
    });
}

http.createServer((req, res) => {
    const url = (req.url || '/').split('?')[0];
    if (url === '/api/elec') return relay(req, res);
    if (url === '/' || url === '/icy_lab.html') return file(res, path.join(SCORE_DIR, 'icy_lab.html'));
    if (url === '/samples.json') return file(res, SAMPLES);
    if (url === '/menu.json') return file(res, path.join(SCORE_DIR, 'icy_menu.json'));   // the menu of settings (the engine's, for every piece)
    if (FILES && url.startsWith('/files/')) {
        const rel = path.normalize(decodeURIComponent(url.slice('/files/'.length))).replace(/^(\.\.[/\\])+/, '');
        return file(res, path.join(FILES, rel));
    }
    if (url.startsWith('/electronics/')) {
        const rel = path.normalize(url.slice('/electronics/'.length)).replace(/^(\.\.[/\\])+/, '');
        return file(res, path.join(SCORE_DIR, rel));
    }
    res.statusCode = 404; res.end('not found');
}).listen(PORT, () => {
    console.log(`icy lab at http://localhost:${PORT}/  (samples ${SAMPLES}; the engine's address from ${CONFIG})`);
});
