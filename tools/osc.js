#!/usr/bin/env node
// osc.js — an OSC message, written and read in plain Node, and sent over UDP (the engine plan's 4.2 b).
// No dependency: the pieces' stacks are dependency-free Node and stay that way.
//
//   node electronics/tools/osc.js selftest                         # the encoder against bytes written out by hand
//   node electronics/tools/osc.js send /le/hello [key=value …] [--host 127.0.0.1] [--port 57211] [--wait 400]
//
// As a module:   const osc = require('./osc.js');
//                osc.encode('/le/onset', ['player', 'bcl', 'lane', 1, 't', 3.25])    -> a Buffer
//                osc.pairs({ player: 'bcl', lane: 1 })                               -> ['player', 'bcl', 'lane', 1]
//                await osc.send({ host, port, address, args, waitMs })               -> the reply { address, args }, or null
//
// THE ENGINE'S MESSAGE PORT is UDP 57211 — SuperCollider's LANGUAGE, pinned there by sc/boot.scd (its server is 57210).
// A MESSAGE TO THE ENGINE is  /le/<kind>  followed by NAME, VALUE pairs — it says what each number is, so a field can be
// added without breaking a reader:   /le/onset  player bcl  lane 1  id wc_12  t 3.25  dueMs 87
// THE TYPES: a string -> s · a whole number -> i (int32) · any other number -> f (float32) · true / false -> i 1 / 0 ·
// { type: 'f', value: 3 } forces one. Read back: i · f · d · s (what SuperCollider answers with).
'use strict';
const dgram = require('dgram');

const PORT = 57211;

const pad4 = (n) => (4 - (n % 4)) % 4;
function str(s) {                                   // an OSC string: its bytes, a zero, padded to a multiple of four
    const b = Buffer.from(String(s), 'utf8');
    return Buffer.concat([b, Buffer.alloc(1 + pad4(b.length + 1))]);
}
function one(v) {
    if (v && typeof v === 'object' && 'type' in v) {
        const b = Buffer.alloc(4);
        if (v.type === 'i') { b.writeInt32BE(Math.round(v.value)); return ['i', b]; }
        if (v.type === 'f') { b.writeFloatBE(+v.value); return ['f', b]; }
        if (v.type === 's') return ['s', str(v.value)];
        throw new Error('osc: unknown type ' + v.type);
    }
    if (typeof v === 'boolean') return one({ type: 'i', value: v ? 1 : 0 });
    if (typeof v === 'number') {
        if (!Number.isFinite(v)) throw new Error('osc: not a finite number');
        return one({ type: Number.isInteger(v) && Math.abs(v) < 2147483648 ? 'i' : 'f', value: v });
    }
    if (v == null) return ['s', str('')];
    return ['s', str(v)];
}
function encode(address, args = []) {
    if (!/^\/[\x21-\x7e]+$/.test(address)) throw new Error('osc: bad address ' + address);
    const parts = args.map(one);
    return Buffer.concat([str(address), str(',' + parts.map((p) => p[0]).join('')), ...parts.map((p) => p[1])]);
}
function decode(buf) {
    let o = 0;
    const rs = () => { let e = o; while (e < buf.length && buf[e] !== 0) e++; const s = buf.toString('utf8', o, e); o = e + 1 + pad4(e + 1); return s; };
    const address = rs(), tags = rs(), args = [];
    if (tags[0] !== ',') return { address, args };
    for (const t of tags.slice(1)) {
        if (t === 'i') { args.push(buf.readInt32BE(o)); o += 4; }
        else if (t === 'f') { args.push(buf.readFloatBE(o)); o += 4; }
        else if (t === 'd') { args.push(buf.readDoubleBE(o)); o += 8; }
        else if (t === 's') args.push(rs());
        else break;                                  // a type this reader does not know: stop, keep what was read
    }
    return { address, args };
}
// { player: 'bcl', lane: 1 } -> ['player', 'bcl', 'lane', 1]   (null and undefined are left out)
function pairs(obj) {
    const out = [];
    for (const k of Object.keys(obj || {})) if (obj[k] != null) out.push(k, obj[k]);
    return out;
}
// ['player', 'bcl', 'lane', 1] -> { player: 'bcl', lane: 1 }
function unpairs(args) {
    const o = {};
    for (let i = 0; i + 1 < args.length; i += 2) o[String(args[i])] = args[i + 1];
    return o;
}
// One message out; with waitMs, the first datagram that comes back (the engine answers /le/hello), or null.
// It never throws and never leaves a socket open: a closed port answers with an error on Windows, which is swallowed.
function send({ host = '127.0.0.1', port = PORT, address, args = [], waitMs = 0 }) {
    return new Promise((resolve) => {
        let done = false, timer = null;
        const sock = dgram.createSocket('udp4');
        const finish = (v) => { if (done) return; done = true; clearTimeout(timer); try { sock.close(); } catch (e) {} resolve(v); };
        sock.on('error', () => finish(null));
        sock.on('message', (m) => { try { finish(decode(m)); } catch (e) { finish(null); } });
        let buf;
        try { buf = encode(address, args); } catch (e) { return finish(null); }
        sock.send(buf, port, host, (err) => {
            if (err || !waitMs) return finish(null);
            timer = setTimeout(() => finish(null), waitMs);
        });
    });
}

module.exports = { PORT, encode, decode, pairs, unpairs, send };

if (require.main === module) (async () => {
    const a = process.argv.slice(2), cmd = a[0];
    if (!cmd || cmd === '-h') { console.log(require('fs').readFileSync(__filename, 'utf8').split('\n').slice(1, 18).join('\n')); return; }
    if (cmd === 'selftest') {
        // the bytes of  /le/t ,sif "ab" 1 0.5  written out by hand from the OSC 1.0 specification
        const want = Buffer.from([0x2f, 0x6c, 0x65, 0x2f, 0x74, 0, 0, 0, 0x2c, 0x73, 0x69, 0x66, 0, 0, 0, 0, 0x61, 0x62, 0, 0, 0, 0, 0, 1, 0x3f, 0, 0, 0]);
        const got = encode('/le/t', ['ab', 1, 0.5]);
        const back = decode(encode('/le/onset', pairs({ player: 'bcl', lane: 1, id: 'wc_12', t: 3.25, on: true })));
        const tests = [
            ['the bytes', got.equals(want)],
            ['a multiple of four', encode('/le/hello', ['abcd', 'abc', 'ab', 'a', '']).length % 4 === 0],
            ['there and back', JSON.stringify(unpairs(back.args)) === JSON.stringify({ player: 'bcl', lane: 1, id: 'wc_12', t: 3.25, on: 1 }) && back.address === '/le/onset'],
            ['a whole number is an int, a fraction a float', one(3)[0] === 'i' && one(3.5)[0] === 'f' && one({ type: 'f', value: 3 })[0] === 'f'],
            ['a bad address is refused', (() => { try { encode('le', []); return false; } catch (e) { return true; } })()],
        ];
        for (const [n, ok] of tests) console.log((ok ? 'pass  ' : 'FAIL  ') + n);
        process.exit(tests.every((t) => t[1]) ? 0 : 1);
    }
    if (cmd === 'send') {
        const o = { address: a[1], args: [], waitMs: 400 };
        for (let i = 2; i < a.length; i++) {
            if (a[i] === '--host') o.host = a[++i]; else if (a[i] === '--port') o.port = +a[++i]; else if (a[i] === '--wait') o.waitMs = +a[++i];
            else { const k = a[i].indexOf('='); const v = a[i].slice(k + 1); o.args.push(a[i].slice(0, k), v !== '' && !isNaN(v) ? +v : v); }
        }
        const t0 = process.hrtime.bigint(), r = await send(o);
        console.log(r ? JSON.stringify({ ms: Number(process.hrtime.bigint() - t0) / 1e6, ...r }) : 'sent — no answer within ' + o.waitMs + ' ms');
        process.exit(r ? 0 : 1);
    }
    console.error('unknown command ' + cmd); process.exit(2);
})();
