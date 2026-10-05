// crop_report.js — A PICTURE OF EACH CROP (the engine's part 4, the bank; the Decibel piece's RUNNING_LOG §71, 2026-10-05, his word:
// "it would be worth at least running through the crop, the simulated record, live mic, and then crop"). Given captures — each a raw
// window, its cropped sample and the engine's row — writes ONE HTML page: per capture the numbers, the raw waveform with the kept
// region shaded and the attack marked, the cropped waveform, and the two sounds to play. No library; the WAVs are read here
// (the engine writes mono 24-bit PCM; 16-bit and 32-bit float are read too).
//   const { report } = require('electronics/tools/crop_report.js');  report(outDir, items)  → outDir/report.html
//   an item: { name, category, rawFile, sampleFile, row }  (file paths relative to outDir; row = the engine's `captured` result)
'use strict';
const fs = require('fs'), path = require('path');

function readWav(file) {
    const b = fs.readFileSync(file);
    if (b.toString('ascii', 0, 4) !== 'RIFF' || b.toString('ascii', 8, 12) !== 'WAVE') throw new Error('not a WAV: ' + file);
    let p = 12, fmt = null, data = null;
    while (p + 8 <= b.length) {
        const id = b.toString('ascii', p, p + 4), len = b.readUInt32LE(p + 4);
        if (id === 'fmt ') fmt = { format: b.readUInt16LE(p + 8), channels: b.readUInt16LE(p + 10), rate: b.readUInt32LE(p + 12), bits: b.readUInt16LE(p + 22) };
        if (id === 'data') { data = { at: p + 8, len: Math.min(len, b.length - p - 8) }; }
        p += 8 + len + (len % 2);
    }
    if (!fmt || !data) throw new Error('no fmt/data chunk: ' + file);
    const bytes = fmt.bits / 8, n = Math.floor(data.len / bytes / fmt.channels), out = new Float32Array(n);
    for (let i = 0; i < n; i++) {
        const q = data.at + i * bytes * fmt.channels;
        let v;
        if (fmt.bits === 24) { v = ((b[q + 2] << 24) | (b[q + 1] << 16) | (b[q] << 8)) >> 8; v /= 8388608; }
        else if (fmt.bits === 16) v = b.readInt16LE(q) / 32768;
        else if (fmt.bits === 32 && fmt.format === 3) v = b.readFloatLE(q);
        else if (fmt.bits === 32) v = b.readInt32LE(q) / 2147483648;
        else v = 0;
        out[i] = v;
    }
    return { rate: fmt.rate, data: out };
}

function envelope(data, rate, hopMs) {
    const hop = Math.max(1, Math.round(rate * hopMs / 1000)), n = Math.ceil(data.length / hop), env = new Float32Array(n);
    for (let k = 0; k < n; k++) { let m = 0; const i0 = k * hop, i1 = Math.min(data.length, i0 + hop); for (let i = i0; i < i1; i++) { const a = Math.abs(data[i]); if (a > m) m = a; } env[k] = m; }
    return { env, hop };
}

const db = (a) => (a > 0 ? Math.round(20 * Math.log10(a) * 10) / 10 : -150);

// the raw window: its envelope mirrored, the kept region shaded, the attack a line; a time axis in ms
function svgRaw(wav, row, width, height) {
    const { env, hop } = envelope(wav.data, wav.rate, 1), ms = wav.data.length / wav.rate * 1000, peak = Math.max(1e-6, ...env);
    const x = (t) => (t / ms) * width, mid = height / 2, yAmp = (a) => (a / peak) * (mid - 6);
    const pts = [];
    for (let k = 0; k < env.length; k++) pts.push(x(k * hop / wav.rate * 1000).toFixed(1) + ',' + (mid - yAmp(env[k])).toFixed(1));
    for (let k = env.length - 1; k >= 0; k--) pts.push(x(k * hop / wav.rate * 1000).toFixed(1) + ',' + (mid + yAmp(env[k])).toFixed(1));
    const at = row && row.attackMs != null ? +row.attackMs : null, kept = row && row.cropped ? { a: Math.max(0, at - (row.preMs != null ? row.preMs : 5)), b: Math.max(0, at - (row.preMs != null ? row.preMs : 5)) + (+row.lengthMs) } : null;
    let s = '<svg viewBox="0 0 ' + width + ' ' + height + '" width="' + width + '" height="' + height + '" style="background:#fff;border:1px solid #ddd">';
    if (kept) s += '<rect x="' + x(kept.a).toFixed(1) + '" y="0" width="' + (x(kept.b) - x(kept.a)).toFixed(1) + '" height="' + height + '" fill="#c8e6c9" opacity="0.7"/>';
    s += '<polygon points="' + pts.join(' ') + '" fill="#37474f"/>';
    if (at != null) s += '<line x1="' + x(at).toFixed(1) + '" y1="0" x2="' + x(at).toFixed(1) + '" y2="' + height + '" stroke="#d32f2f" stroke-width="1.5"/>';
    const step = ms > 3000 ? 500 : ms > 1200 ? 200 : 100;
    for (let t = 0; t <= ms; t += step) s += '<line x1="' + x(t).toFixed(1) + '" y1="' + (height - 8) + '" x2="' + x(t).toFixed(1) + '" y2="' + height + '" stroke="#999"/><text x="' + (x(t) + 2).toFixed(1) + '" y="' + (height - 10) + '" font-size="9" fill="#666">' + t + '</text>';
    s += '<text x="4" y="11" font-size="10" fill="#333">raw · ' + Math.round(ms) + ' ms · peak ' + db(peak) + ' dB' + (kept ? ' · kept ' + Math.round(kept.a) + ' → ' + Math.round(kept.b) + ' ms (green) · attack ' + at + ' ms (red)' : ' · NOTHING KEPT') + '</text></svg>';
    return s;
}

function svgSample(wav, width, height) {
    const { env, hop } = envelope(wav.data, wav.rate, 1), ms = wav.data.length / wav.rate * 1000, peak = Math.max(1e-6, ...env);
    const x = (t) => (t / Math.max(ms, 1)) * width, mid = height / 2, yAmp = (a) => (a / peak) * (mid - 6), pts = [];
    for (let k = 0; k < env.length; k++) pts.push(x(k * hop / wav.rate * 1000).toFixed(1) + ',' + (mid - yAmp(env[k])).toFixed(1));
    for (let k = env.length - 1; k >= 0; k--) pts.push(x(k * hop / wav.rate * 1000).toFixed(1) + ',' + (mid + yAmp(env[k])).toFixed(1));
    return '<svg viewBox="0 0 ' + width + ' ' + height + '" width="' + width + '" height="' + height + '" style="background:#f1f8e9;border:1px solid #ddd"><polygon points="' + pts.join(' ') + '" fill="#2e7d32"/>' +
        '<text x="4" y="11" font-size="10" fill="#333">the sample · ' + Math.round(ms) + ' ms · peak ' + db(peak) + ' dB</text></svg>';
}

function report(outDir, items, opts) {
    const o = opts || {}, W = 900;
    const esc = (s) => String(s == null ? '' : s).replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
    let h = '<!doctype html><html><head><meta charset="utf-8"><title>Crop test</title><style>body{font:13px/1.5 system-ui,sans-serif;margin:18px;color:#222;max-width:960px}h1{font-size:18px}h2{font-size:14px;margin:26px 0 4px}table{border-collapse:collapse;font-size:12px;margin:4px 0}td,th{border:1px solid #ddd;padding:2px 8px;text-align:left}audio{height:28px;vertical-align:middle}.k{color:#666}</style></head><body>';
    h += '<h1>Crop test — ' + esc(o.title || 'one of each kind') + '</h1><p class="k">' + esc(o.when || '') + (o.crop ? ' · the crop\'s rule: ' + esc(JSON.stringify(o.crop)) : '') + '</p>';
    h += '<p class="k">Each capture: the raw window as the engine recorded it (grey), the region it KEPT (green), the attack it found (red line); below it the cropped sample as it will be played back. Play both. The crop\'s numbers are the engine\'s defaults unless the route table overrides them.</p>';
    for (const it of items) {
        const row = it.row || {};
        h += '<h2>' + esc(it.name) + (it.category ? ' <span class="k">· ' + esc(it.category) + '</span>' : '') + (it.note ? ' <span class="k">· ' + esc(it.note) + '</span>' : '') + '</h2>';
        h += '<table><tr><th>window</th><th>raw peak</th><th>attack found at</th><th>kept</th><th>sample peak</th><th>verdict</th></tr><tr><td>' + esc(row.rawMs) + ' ms</td><td>' + esc(row.rawPeakDb != null ? row.rawPeakDb : row.peakDb) + ' dB</td><td>' +
            (row.cropped ? esc(row.attackMs) + ' ms' : '—') + '</td><td>' + (row.cropped ? esc(row.lengthMs) + ' ms' : '—') + '</td><td>' + (row.cropped ? esc(row.peakDb) + ' dB' : '—') + '</td><td>' + (row.cropped ? 'cropped' : 'NOTHING TO CROP — no attack above the floor') + '</td></tr></table>';
        try { h += svgRaw(readWav(path.join(outDir, it.rawFile)), row, W, 150); } catch (e) { h += '<p>raw: ' + esc(e.message) + '</p>'; }
        h += '<div><audio controls src="' + esc(it.rawFile) + '"></audio> <span class="k">raw</span> ';
        if (it.sampleFile && fs.existsSync(path.join(outDir, it.sampleFile))) {
            h += '<audio controls src="' + esc(it.sampleFile) + '"></audio> <span class="k">the sample</span></div>';
            try { h += svgSample(readWav(path.join(outDir, it.sampleFile)), W, 90); } catch (e) { h += '<p>sample: ' + esc(e.message) + '</p>'; }
        } else h += '</div>';
    }
    h += '</body></html>';
    fs.writeFileSync(path.join(outDir, 'report.html'), h);
    return path.join(outDir, 'report.html');
}

module.exports = { report, readWav, envelope };
