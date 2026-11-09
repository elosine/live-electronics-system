// le_material.js — THE MATERIAL BRICK: a stretch of a long, mastered file from the piece's FUND, placed in the composer score like a
// note — dragged, shortened from either end, split at the playhead, faded at its edges, at a level that may follow a drawn curve.
// The Switch~ piece's 1a.7 (its RUNNING_LOG §80 · §102 · §103), 2026-11-09. A MIXIN on LEObjects, as le_sine.js is: ONE tag in the
// piece's page after le_objects.js —   <script src="/electronics/le_material.js"></script>   — its key `material` in the attach line's
// keys (`n` in the first piece), its index `materialsUrl` there ('/bank/materials.json' by default).
//
//   midiModel 'elecMaterial'   elec: { name, offsetMs, fadeInMs, fadeOutMs, gainDb, level: { mode, mark, to, curveRef }, label? }
//       name      a row of the fund's index (tools/materials_index.js in the piece; the engine reads the same file, LE_MATERIALS)
//       offsetMs  where in the FILE the brick's sound begins. THE RULE OF THE EDGES: drag the brick and the offset stays (the same
//                 sound, later); drag its LEFT edge and the offset moves with it (the sound stays where it was, the brick shows less
//                 of it — a MIDI region's way); drag its RIGHT edge and only the length changes. A brick never outlasts its file.
//       fades     a few tens of ms at each edge by default (the engine's 30), longer by hand — nothing clicks
//       gainDb    a plain trim (0: the file as mastered)
//       level     flat (one mark) · hairpin (from a mark to another over the brick) · curve A | B | C | lane (a drawn curve read
//                 through the host's reader, as the sine's is: 16 heights over the brick → marks 0 … 7). mf = the file as mastered.
//   KEY: at the playhead on the active lane, the last material chosen (the first of the index when none); SHIFT+key: the selected
//        material brick is SPLIT at the playhead — two bricks, the second's offset carried on, both faded.
//   Played through:   /le/material   id · lane · t · dueMs · name · offsetMs · lengthMs · fadeInMs · fadeOutMs · gainDb · level · pass
//   — the engine streams that stretch from disk (sc/material.scd). A playhead that STARTS INSIDE a brick plays what is left of it:
//   the offset moved on, the length cut, a short fade in. The score stopped:   /le/materialstop .
//   LAYERS: a brick may sit on any lane; bricks overlap freely, on one lane or across lanes — the engine plays them all, through its
//   master bus (the glue and the limiter), which is the rough mix while composing (§102). The bounce is the plan's step 6.
//   THE WAVEFORM (the piece's 1a.8, 2026-11-09): a rough shape per material — bank/materials_peaks.json (peaksUrl), the index tool's
//   PEAK_BINS loudest-sample slices 0 … 255 — drawn inside the brick for the stretch it plays (offset → offset + length). The drawer
//   (le_drawer.js) draws the same data whole and places a brick by a drop: materialAdd(name, layer, t).
(function () {
    'use strict';
    const L = window.LEObjects;
    if (!L) return;
    const r3 = (x) => Math.round(x * 1000) / 1000, r1 = (x) => Math.round(x * 10) / 10, r2 = (x) => Math.round(x * 100) / 100;
    const MARKS = ['ppp', 'pp', 'p', 'mp', 'mf', 'f', 'ff', 'fff'];
    const LEVELS = [['flat', 'flat — one dynamic'], ['hairpin', 'hairpin — from one dynamic to another'], ['A', 'curve A'], ['B', 'curve B'], ['C', 'curve C'], ['lane', 'a curve on this lane']];
    const safe = (s) => String(s == null ? '' : s).replace(/[^A-Za-z0-9_~-]/g, '').slice(0, 64);
    const mmss = (s) => Math.floor(s / 60) + ':' + String(Math.floor(s % 60)).padStart(2, '0');
    // a line [[x, v] …] read at x; the same line from fraction f0 on (a playhead inside the brick); as the engine reads it: ms:value,… (16 at most)
    const at = (pts, x) => { if (!pts.length) return 0; if (x <= pts[0][0]) return pts[0][1]; for (let i = 1; i < pts.length; i++) if (x <= pts[i][0]) { const a = pts[i - 1], b = pts[i], w = b[0] > a[0] ? (x - a[0]) / (b[0] - a[0]) : 1; return a[1] + (b[1] - a[1]) * w; } return pts[pts.length - 1][1]; };
    const from = (pts, f0) => { if (!pts.length || f0 <= 0) return pts; const rest = 1 - f0; if (rest <= 1e-6) return [[0, at(pts, 1)], [1, at(pts, 1)]]; return [[0, at(pts, f0)]].concat(pts.filter((p) => p[0] > f0 + 1e-6).map((p) => [(p[0] - f0) / rest, p[1]])); };
    const wire = (pts, lenMs) => { const p = pts.slice(0, 16); if (p.length === 1 || p.every((x) => x[1] === p[0][1])) return String(r2(p[0][1])); return p.map((x, i) => (i === p.length - 1 && x[0] >= 1 - 1e-6 ? 'end' : Math.round(x[0] * lenMs)) + ':' + r2(x[1])).join(','); };
    const markNum = (x) => { const i = MARKS.indexOf(String(x == null ? '' : x).trim()); if (i >= 0) return i; return Number.isFinite(+x) && String(x).trim() !== '' ? Math.max(-10, Math.min(7, +x)) : 4; };

    L.MODELS.elecMaterial = { kind: 'material', sign: '▬', color: '#6D4C41', yOffset: 0.25, title: 'Material — a stretch of a file from the fund' };

    // the index is read at attach; a stop reaches the engine (the host's stopPlay wrapped once, the sine's way)
    const attach = L.attach;
    L.attach = function (host) {
        const first = !this.host, r = attach.apply(this, arguments);
        if (first) {
            this.materialLoad();
            this.peaksLoad();
            if (host && typeof host.stopPlay === 'function') {
                const stop = host.stopPlay;
                host.stopPlay = function () { const out = stop.apply(this, arguments); L.materialStop(); return out; };
            }
        }
        return r;
    };

    Object.assign(L, {
        materials: [],
        materialLoad() {
            const url = (this.opts && this.opts.materialsUrl) || '/bank/materials.json';
            return fetch(url, { cache: 'no-store' }).then((r) => r.json()).then((d) => { this.materials = Array.isArray(d.materials) ? d.materials : []; if (this.host) this.redraw(); return this.materials.length; }).catch(() => 0);
        },
        materialRow(name) { return this.materials.find((m) => m.name === name) || null; },
        // the peaks (the rough waveform): { name: { p: [0 … 255 × bins] } }; absent, nothing is drawn
        peaks: null,
        peaksLoad() {
            const url = (this.opts && this.opts.peaksUrl) || '/bank/materials_peaks.json';
            return fetch(url, { cache: 'no-store' }).then((r) => (r.ok ? r.json() : null)).then((d) => { this.peaks = d && d.peaks ? d.peaks : null; if (this.host) this.redraw(); if (this._drawer && this._drawer.root.classList.contains('open')) this.drawerFill(); return this.peaks ? Object.keys(this.peaks).length : 0; }).catch(() => 0);
        },
        peaksOf(name) { const q = this.peaks && this.peaks[name]; return q && Array.isArray(q.p) ? q.p : null; },
        materialDefaults() { return { fadeInMs: 30, fadeOutMs: 30, gainDb: 0 }; },

        // ---- the brick ------------------------------------------------------------------------------------------------------
        materialAdd(name, layer, t0) {   // (name) by the key: the active lane, the playhead · (name, layer, t) by the drawer's drop
            const h = this.host; if (!h) return null;
            const nm = name || this._lastMaterial || (this.materials[0] && this.materials[0].name);
            if (!nm) { this.say('no materials in the fund\'s index yet — tools/materials_index.js writes it'); return null; }
            const row = this.materialRow(nm), t = r3(t0 == null ? h.getTimeAtPlayhead() : Math.max(0, +t0 || 0)), M = this.MODELS.elecMaterial;
            const len = Math.min(30, row ? Math.max(1, row.seconds) : 30);
            const z = h.createZone({ layer: layer == null ? h.activeLane : layer, startTime: t, endTime: r3(t + len), midiModel: 'elecMaterial', color: M.color, opacity: 0.3, yOffset: M.yOffset, zoneHeight: 0.22, player: '', instrument: '' });
            z.elec = Object.assign({ name: nm, offsetMs: 0, level: { mode: 'flat', mark: 'mf' } }, this.materialDefaults());
            z._mat = { s: z.startTime, e: z.endTime };
            this._lastMaterial = nm;
            h.renderZone(z); h.markDirty();
            this.say('▬ ' + nm + ' at ' + mmss(t) + ' on ' + this.opts.laneLabel(z.layer) + ' — drag its edges; SHIFT+' + ((this.opts.keys || {}).material || 'key') + ' splits it at the playhead');
            return z;
        },
        // the selected material brick cut in two at the playhead: the second carries the offset on; both keep their fades
        materialSplit() {
            const h = this.host, z = h && h.selectedObject;
            if (!z || z.midiModel !== 'elecMaterial' || !z.elec) { this.say('select a material brick to split'); return null; }
            const t = r3(h.getTimeAtPlayhead());
            if (t <= z.startTime + 0.05 || t >= z.endTime - 0.05) { this.say('the playhead must stand inside the brick to split it'); return null; }
            h.pushUndoState();
            const e = z.elec, M = this.MODELS.elecMaterial;
            const z2 = h.createZone({ layer: z.layer, startTime: t, endTime: z.endTime, midiModel: 'elecMaterial', color: M.color, opacity: z.opacity, yOffset: z.yOffset, zoneHeight: z.zoneHeight, player: '', instrument: '' });
            z2.elec = JSON.parse(JSON.stringify(e));
            z2.elec.offsetMs = r1((+e.offsetMs || 0) + (t - z.startTime) * 1000);
            z2._mat = { s: z2.startTime, e: z2.endTime };
            z.endTime = t; z._mat = { s: z.startTime, e: z.endTime };
            h.renderZone(z); h.renderZone(z2); h.markDirty();
            this.say('split at ' + mmss(t) + ' — the second brick plays from ' + r1(z2.elec.offsetMs / 1000) + ' s into ' + e.name);
            return z2;
        },
        // called from the host's renderZone (le_objects decorate): the rule of the edges, the clamp to the file, the label
        materialDecorate(zone, label) {
            const e = zone.elec, row = this.materialRow(e.name), p = zone._mat;
            if (p) {
                const ds = zone.startTime - p.s, de = zone.endTime - p.e;
                if (Math.abs(ds) > 1e-6 && Math.abs(de) < 1e-6) e.offsetMs = Math.max(0, r1((+e.offsetMs || 0) + ds * 1000));   // the LEFT edge dragged: the sound stays where it was
            }
            if (row && row.seconds > 0) {
                const rem = Math.max(0.05, row.seconds - (+e.offsetMs || 0) / 1000);
                if (zone.endTime - zone.startTime > rem + 1e-3) { zone.endTime = r3(zone.startTime + rem); setTimeout(() => { if (zone._els) this.host.renderZone(zone); }, 0); }   // never past the file's end
            }
            zone._mat = { s: zone.startTime, e: zone.endTime };
            this.materialWave(zone, row);
            if (label) {
                const lv = e.level || {}, lvText = lv.mode === 'hairpin' ? (lv.mark || 'mf') + ' → ' + (lv.to || 'mf') : lv.mode && lv.mode !== 'flat' ? 'curve ' + (lv.mode === 'lane' ? 'lane' : lv.mode) : (lv.mark && lv.mark !== 'mf' ? lv.mark : '');
                label.textContent = this.MODELS.elecMaterial.sign + ' ' + (e.label ? String(e.label).slice(0, 48) + ' · ' : '') + (e.name || '?') + ' · from ' + mmss((+e.offsetMs || 0) / 1000) + ' · ' + mmss(zone.endTime - zone.startTime)
                    + (lvText ? ' · ' + lvText : '') + (+e.gainDb ? ' · ' + (+e.gainDb > 0 ? '+' : '') + r1(+e.gainDb) + ' dB' : '') + (row ? '' : ' — NOT IN THE FUND');
            }
        },

        // the rough waveform inside the brick: the peaks of the stretch it plays, mirrored round the brick's middle, behind the label
        materialWave(zone, row) {
            const g = zone._els && zone._els.group; if (!g) return;
            const old = g.querySelector('path.leWave'); if (old) old.remove();
            const p = this.peaksOf(zone.elec && zone.elec.name); if (!p || !row || !(row.seconds > 0)) return;
            const rect = Array.from(g.querySelectorAll('rect')).find((r) => r.getAttribute('fill') === this.MODELS.elecMaterial.color); if (!rect) return;
            const x = +rect.getAttribute('x'), y = +rect.getAttribute('y'), w = +rect.getAttribute('width'), hh = +rect.getAttribute('height');
            if (!(w > 2) || !(hh > 2)) return;
            const f0 = Math.max(0, Math.min(1, ((+zone.elec.offsetMs || 0) / 1000) / row.seconds)), f1 = Math.max(f0, Math.min(1, f0 + (zone.endTime - zone.startTime) / row.seconds));
            const n = Math.max(2, Math.min(600, Math.round(w / 2))), mid = y + hh / 2, amp = hh / 2 - 1, bins = p.length;
            const top = [], bot = [];
            for (let i = 0; i <= n; i++) {
                const fa = f0 + (f1 - f0) * (i / n), fb = f0 + (f1 - f0) * ((i + 1) / n);
                const b0 = Math.min(bins - 1, Math.floor(fa * bins)), b1 = Math.max(b0 + 1, Math.min(bins, Math.ceil(fb * bins)));
                let v = 0; for (let b = b0; b < b1; b++) if (p[b] > v) v = p[b];
                const px = r2(x + (w * i) / n), dy = Math.max(0.4, (v / 255) * amp);
                top.push(px + ',' + r2(mid - dy)); bot.push(px + ',' + r2(mid + dy));
            }
            const d = 'M' + top.join(' L') + ' L' + bot.reverse().join(' L') + ' Z';
            const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
            path.setAttribute('class', 'leWave'); path.setAttribute('d', d);
            path.setAttribute('fill', '#4a2f27'); path.setAttribute('fill-opacity', '0.35'); path.setAttribute('stroke', 'none');
            path.style.pointerEvents = 'none';
            rect.parentNode.insertBefore(path, rect.nextSibling);
        },

        // ---- the level ------------------------------------------------------------------------------------------------------
        // the level over [t0, t1] of the brick: [[fraction, mark number] …] and its source
        materialLevel(zone, t0, t1) {
            const lv = (zone.elec && zone.elec.level) || {}, mark = markNum(lv.mark == null ? 'mf' : lv.mark), a = zone.startTime, span = Math.max(1e-6, zone.endTime - a);
            const s = t0 == null ? a : t0, e = t1 == null ? zone.endTime : t1;
            if (lv.mode === 'hairpin') return { pts: from([[0, mark], [1, markNum(lv.to == null ? mark : lv.to)]], (s - a) / span), src: 'hairpin' };
            if (lv.mode && lv.mode !== 'flat') {
                const read = this.opts.curveAt;
                let h = null;
                try { h = typeof read === 'function' ? read(String(lv.mode === 'lane' ? 'lane' : lv.mode), { layer: zone.layer, startTime: s, endTime: e }, 16) : null; } catch (err) { h = null; }
                if (Array.isArray(h) && h.length >= 2 && h.every((v) => Number.isFinite(+v))) return { pts: h.map((v, i) => [i / (h.length - 1), r2(Math.max(0, Math.min(1, +v)) * 7)]), src: 'curve' };
                return { pts: [[0, mark]], src: 'nocurve' };
            }
            return { pts: [[0, mark]], src: 'flat' };
        },

        // ---- the sound ------------------------------------------------------------------------------------------------------
        // what the brick sends for a start at `at0` (its own start, or later: the playhead began inside it)
        materialMessage(zone, at0, dueMs) {
            const e = zone.elec || {}, a = zone.startTime, start = Math.max(a, at0 == null ? a : at0), inside = start > a + 1e-3;
            const lenMs = Math.max(50, Math.round((zone.endTime - start) * 1000)), offsetMs = r1((+e.offsetMs || 0) + (start - a) * 1000);
            const lv = this.materialLevel(zone, start, zone.endTime);
            const m = { id: String(zone.id), lane: zone.layer, t: r3(start), dueMs: dueMs || 0, name: safe(e.name), offsetMs, lengthMs: lenMs,
                fadeInMs: inside ? 15 : Math.max(2, Math.round(+e.fadeInMs || 30)), fadeOutMs: Math.max(2, Math.round(+e.fadeOutMs || 30)), gainDb: r1(+e.gainDb || 0), level: wire(lv.pts, lenMs) };
            if (this._passN) m.pass = this._passN;
            return m;
        },
        materialFire(host, z, at0, dueMs) { if (window.LE) LE.send('material', this.materialMessage(z, at0, dueMs)); },
        materialStop() { if (window.LE && this.host && this.zones('elecMaterial').length) LE.send('materialstop', {}); },
        // the panel's ear: six seconds from the brick's offset, at its trim, flat
        materialHear(zone) {
            if (!window.LE) { this.say('no road to the engine on this page'); return; }
            const e = zone.elec || {};
            LE.send('material', { id: 'audition', lane: -1, t: 0, dueMs: 0, name: safe(e.name), offsetMs: r1(+e.offsetMs || 0), lengthMs: 6000, fadeInMs: 20, fadeOutMs: 300, gainDb: r1(+e.gainDb || 0), level: String(markNum((e.level || {}).mark || 'mf')) });
            this.say('▶ ' + e.name + ' from ' + mmss((+e.offsetMs || 0) / 1000) + ' — six seconds');
        },

        // ---- the panel ------------------------------------------------------------------------------------------------------
        materialPanel(zone, sec, ui) {
            const e = zone.elec, { el, rowEl, note, commit } = ui, h = this.host;
            if (!e.level || typeof e.level !== 'object') e.level = { mode: 'flat', mark: 'mf' };
            const lv = e.level, row = this.materialRow(e.name);
            const label = el('input', { type: 'text', value: e.label || '', title: 'a tag shown first on the brick — a word of yours' });
            label.addEventListener('change', () => commit(() => { e.label = String(label.value || '').trim().slice(0, 48); }));
            sec.appendChild(rowEl('Label', label));
            // the material
            const pick = el('select', { title: 'a file of the fund (bank/materials.json)' });
            if (!row) pick.appendChild(el('option', { value: e.name || '', textContent: (e.name || '?') + ' — not in the fund', selected: true }));
            let kind = null;
            for (const m of this.materials) {
                if (m.kind !== kind) { kind = m.kind; pick.appendChild(el('option', { textContent: '— ' + kind + ' —', disabled: true })); }
                pick.appendChild(el('option', { value: m.name, textContent: m.name + ' · ' + mmss(m.seconds) + (m.channels === 1 ? ' · mono' : ''), selected: m.name === e.name }));
            }
            pick.addEventListener('change', () => { pick.blur(); commit(() => { e.name = pick.value; e.offsetMs = 0; this._lastMaterial = e.name; const r = this.materialRow(e.name); if (r) zone.endTime = r3(zone.startTime + Math.min(zone.endTime - zone.startTime, r.seconds)); }); });
            sec.appendChild(rowEl('Material', pick));
            if (row) sec.appendChild(note((row.kind || '') + ' · ' + mmss(row.seconds) + ' long · ' + (row.channels === 1 ? 'mono' : 'stereo') + (row.note ? ' · ' + String(row.note).slice(0, 160) : '')));
            // the stretch
            const off = el('input', { type: 'number', value: String(r2((+e.offsetMs || 0) / 1000)), step: '0.1', min: '0', style: 'width:80px', title: 'where in the file the brick\'s sound begins, in seconds' });
            off.addEventListener('change', () => commit(() => { e.offsetMs = Math.max(0, r1((+off.value || 0) * 1000)); }));
            const len = el('input', { type: 'number', value: String(r2(zone.endTime - zone.startTime)), step: '0.1', min: '0.05', style: 'width:80px', title: 'the brick\'s length in seconds (or drag its right edge)' });
            len.addEventListener('change', () => commit(() => { zone.endTime = r3(zone.startTime + Math.max(0.05, +len.value || 1)); }));
            sec.appendChild(rowEl('From (s)', off));
            sec.appendChild(rowEl('Length (s)', len));
            if (row) sec.appendChild(note('the file has ' + mmss(Math.max(0, row.seconds - (+e.offsetMs || 0) / 1000 - (zone.endTime - zone.startTime))) + ' left after this brick · drag the LEFT edge: the sound stays, the brick shows less of it · the RIGHT edge: the length'));
            // the fades and the trim
            const fin = el('input', { type: 'number', value: String(Math.round(+e.fadeInMs || 30)), step: '10', min: '2', style: 'width:64px' });
            fin.addEventListener('change', () => commit(() => { e.fadeInMs = Math.max(2, Math.min(30000, Math.round(+fin.value || 30))); }));
            const fout = el('input', { type: 'number', value: String(Math.round(+e.fadeOutMs || 30)), step: '10', min: '2', style: 'width:64px' });
            fout.addEventListener('change', () => commit(() => { e.fadeOutMs = Math.max(2, Math.min(30000, Math.round(+fout.value || 30))); }));
            const fades = el('span', { style: 'display:inline-flex;align-items:center;gap:4px;font-size:11px' }, [el('span', { textContent: 'in', style: 'font-size:10px;color:#888' }), fin, el('span', { textContent: 'out', style: 'font-size:10px;color:#888' }), fout, el('span', { textContent: 'ms', style: 'font-size:10px;color:#888' })]);
            sec.appendChild(rowEl('Fades', fades));
            const gain = el('input', { type: 'number', value: String(r1(+e.gainDb || 0)), step: '0.5', min: '-60', max: '24', style: 'width:64px', title: 'a plain trim in dB; 0 = the file as mastered' });
            gain.addEventListener('change', () => commit(() => { e.gainDb = Math.max(-60, Math.min(24, r1(+gain.value || 0))); }));
            sec.appendChild(rowEl('Trim (dB)', gain));
            // the level
            const marks = (value, fn) => { const s = el('select'); for (const k of MARKS) s.appendChild(el('option', { value: k, textContent: k, selected: k === String(value) })); s.addEventListener('change', () => { s.blur(); commit(() => fn(s.value)); }); return s; };
            const mode = el('select', { title: 'the level over the brick — mf is the file as mastered; a curve is read where the brick stands' });
            for (const [v, t] of LEVELS) mode.appendChild(el('option', { value: v, textContent: t, selected: (lv.mode || 'flat') === v }));
            mode.addEventListener('change', () => { mode.blur(); commit(() => { lv.mode = mode.value; }); });
            sec.appendChild(rowEl('Level', mode));
            if (!lv.mode || lv.mode === 'flat') sec.appendChild(rowEl('Mark', marks(lv.mark || 'mf', (v) => { lv.mark = v; })));
            else if (lv.mode === 'hairpin') sec.appendChild(rowEl('From → to', el('span', { style: 'display:inline-flex;gap:6px;align-items:center' }, [marks(lv.mark || 'mf', (v) => { lv.mark = v; }), el('span', { textContent: '→' }), marks(lv.to || 'mf', (v) => { lv.to = v; })])));
            else { const got = this.materialLevel(zone); sec.appendChild(note(got.src === 'curve' ? 'the curve is read under this brick: ' + got.pts.length + ' points, ' + MARKS[Math.max(0, Math.min(7, Math.round(got.pts[0][1])))] + ' … ' + MARKS[Math.max(0, Math.min(7, Math.round(got.pts[got.pts.length - 1][1])))] : typeof this.opts.curveAt === 'function' ? 'no curve is drawn under this brick there — it plays mf until one is' : 'this page has no curve reader — it plays mf')); }
            // the buttons
            const hear = el('button', { textContent: '▶ hear 6 s', title: 'six seconds from the offset, through the engine' }); hear.addEventListener('click', () => this.materialHear(zone));
            const split = el('button', { textContent: '✂ split at playhead', title: 'two bricks; the second plays on from where the first stops' }); split.addEventListener('click', () => { h.selectObject(zone); this.materialSplit(); });
            sec.appendChild(rowEl('', el('span', { style: 'display:inline-flex;gap:6px' }, [hear, split])));
        },
    });
})();
