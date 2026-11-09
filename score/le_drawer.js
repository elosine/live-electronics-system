// le_drawer.js — THE MATERIALS DRAWER: the piece's fund (bank/materials.json) as a full-width drawer that drops from the top bar, one
// row per material with its rough waveform; hear a material straight from its file (click anywhere on the waveform to start there);
// drag a row onto a lane to place a material brick (le_material.js) at the drop. The Switch~ piece's PLAN 1a.8 (its RUNNING_LOG §106 ·
// §108), 2026-11-09. A MIXIN on LEObjects after le_material.js — ONE tag in the piece's page:
//     <script src="/electronics/le_drawer.js"></script>
// and in the attach line:   drawerButton: 'leDrawerBtn'   (the id of a button in the piece's bar; absent, the drawer gets a tab of its own)
//                           fundUrl: '/fund/'              (the piece's server serves the fund's root there, with byte ranges — the player seeks)
//                           peaksUrl: '/bank/materials_peaks.json'   (tools/materials_index.js writes it; read by le_material.js)
//
// What the drawer KNOWS of the piece: nothing — the index, the peaks and the fund's URL are handed in; the brick it places is le_material's.
// What it needs of the host (le_objects.js lists the contract): lanes · clientXToTime · selectObject · saveStatus.
(function () {
    'use strict';
    const L = window.LEObjects;
    if (!L) return;
    const mmss = (s) => Math.floor(s / 60) + ':' + String(Math.floor(s % 60)).padStart(2, '0');
    const el = (tag, props, kids) => { const n = document.createElement(tag); if (props) for (const [k, v] of Object.entries(props)) { if (k === 'style') n.style.cssText = v; else if (k in n) n[k] = v; else n.setAttribute(k, v); } (kids || []).forEach((k) => n.appendChild(k)); return n; };
    const BROWN = '#6D4C41', PALE = '#faf8f3';
    const CSS = `
#leDrawer { position: fixed; top: var(--barH, 32px); left: 0; right: 0; height: 42vh; z-index: 95; background: ${PALE}; border-bottom: 2px solid ${BROWN};
  box-shadow: 0 6px 18px rgba(0,0,0,0.18); display: none; overflow: auto; font: 11px 'Segoe UI', sans-serif; color: #333; }
#leDrawer.open { display: block; }
#leDrawer .leDrawerHead { position: sticky; top: 0; z-index: 2; display: flex; align-items: center; gap: 10px; padding: 4px 10px; background: ${PALE}; border-bottom: 1px solid #d9cfc4; }
#leDrawer .leDrawerHead b { color: ${BROWN}; }
#leDrawer .leDrawerHead input { width: 160px; font-size: 11px; padding: 1px 4px; }
#leDrawer .leDrawerHead .now { color: ${BROWN}; margin-left: auto; font-variant-numeric: tabular-nums; }
#leDrawer .leDrawerHead button { font-size: 11px; padding: 1px 7px; cursor: pointer; }
#leDrawer .leKind { padding: 6px 10px 2px; color: #8a6d3b; font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; }
#leDrawer .leRow { display: flex; align-items: center; gap: 8px; padding: 2px 10px; border-top: 1px solid #eee6dc; cursor: grab; }
#leDrawer .leRow:hover { background: rgba(109,76,65,0.06); }
#leDrawer .leRow.playing { background: rgba(109,76,65,0.10); }
#leDrawer .leRow .nm { width: 230px; flex: none; font-weight: 600; color: #4a3b35; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
#leDrawer .leRow .mt { width: 92px; flex: none; color: #888; font-size: 10px; white-space: nowrap; }
#leDrawer .leRow canvas { flex: 1 1 auto; height: 34px; display: block; cursor: pointer; border-radius: 2px; background: rgba(255,255,255,0.6); }
#leDrawer .leRow .pb { flex: none; width: 24px; height: 22px; font-size: 11px; padding: 0; cursor: pointer; }
#leDrawer .leRow .nt { width: 220px; flex: none; color: #999; font-size: 10px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.lane.leDropHere { outline: 2px dashed ${BROWN}; outline-offset: -2px; background: rgba(109,76,65,0.08) !important; }
#leDrawerTab { position: fixed; top: var(--barH, 32px); right: 12px; z-index: 94; font: 11px 'Segoe UI', sans-serif; padding: 2px 8px; cursor: pointer; background: ${PALE}; border: 1px solid ${BROWN}; border-top: none; color: ${BROWN}; }
`;

    const attach = L.attach;
    L.attach = function (host) {
        const first = !this.host, r = attach.apply(this, arguments);
        if (first) { try { this.drawerInit(); } catch (e) { console.warn('[le_drawer] init', e); } }
        return r;
    };

    Object.assign(L, {
        _drawer: null, _audio: null, _playingRow: null, _dropLane: null,

        // ---- the drawer ----------------------------------------------------------------------------------------------------
        drawerInit() {
            const h = this.host, o = this.opts || {};
            document.head.appendChild(el('style', { textContent: CSS }));
            const d = el('div', { id: 'leDrawer' });
            const filter = el('input', { type: 'text', placeholder: 'filter…', title: 'show the materials whose name or kind has this' });
            filter.addEventListener('input', () => this.drawerFill());
            const now = el('span', { className: 'now', textContent: '' });
            const stop = el('button', { textContent: '■ stop', title: 'stop the preview' }); stop.addEventListener('click', () => this.drawerStop());
            const close = el('button', { textContent: '✕ collapse', title: 'collapse the drawer (the Materials button opens it again)' }); close.addEventListener('click', () => this.drawerToggle(false));
            const count = el('span', { className: 'cnt', textContent: '' });
            d.appendChild(el('div', { className: 'leDrawerHead' }, [el('b', { textContent: '▬ Materials' }), count, filter, el('span', { textContent: 'drag a row onto an electronics lane · click a waveform to hear from there', style: 'color:#888' }), now, stop, close]));
            d.appendChild(el('div', { className: 'leRows' }));
            document.body.appendChild(d);
            this._drawer = { root: d, filter, now, count, rows: d.querySelector('.leRows') };
            // the button in the piece's bar, or a tab of our own
            const btn = o.drawerButton ? document.getElementById(o.drawerButton) : null;
            if (btn) btn.addEventListener('click', () => this.drawerToggle());
            else { const tab = el('button', { id: 'leDrawerTab', textContent: '▬ Materials ▾' }); tab.addEventListener('click', () => this.drawerToggle()); document.body.appendChild(tab); }
            // the audio: one player, the file itself
            const a = new Audio(); a.preload = 'none';
            a.addEventListener('timeupdate', () => this.drawerTick());
            a.addEventListener('ended', () => { this.drawerTick(); this._drawer.now.textContent = ''; });
            a.addEventListener('error', () => this.say('the drawer could not read ' + (this._playingRow ? this._playingRow.row.file : 'the file') + ' — is /fund/ served?'));
            this._audio = a;
            // THE DROP (rewritten 2026-11-09 after his first try, the piece's §109: "the drag doesn't land on the lane"): ONE listener on the
            // lanes' container, not one per lane — the lane is found from the cursor's Y against the lanes' boxes, so whatever element
            // sits under the cursor (an svg, an overlay, a brick) the drop lands; and the drag is known by a flag set at dragstart, never
            // by dataTransfer.types, which Chrome does not always expose during dragover.
            // THE LANES EXIST ONLY AFTER THE HOST'S init — the attach line runs before it (so a loaded score draws with its labels), and
            // h.lanes is undefined here. The first build read its length, threw inside attach's try, and nothing after it was wired: the
            // drawer worked, the drop did not (his first try, §109). So the wiring waits for the lanes.
            const wire = () => {
            if (!h.lanes || !h.lanes.length || !h.lanes[0]) { setTimeout(wire, 150); return; }
            const n = Math.min(h.lanes.length, o.lanes || h.lanes.length);
            const box = (h.lanes[0] && h.lanes[0].parentElement) || document.getElementById('laneContainer') || document.body;
            const laneAt = (y) => { for (let i = 0; i < n; i++) { const el2 = h.lanes[i]; if (!el2) continue; const r = el2.getBoundingClientRect(); if (y >= r.top && y < r.bottom && r.height > 0) return i; } return -1; };
            const mark = (i) => { const lane = i >= 0 ? h.lanes[i] : null; if (this._dropLane !== lane) { if (this._dropLane) this._dropLane.classList.remove('leDropHere'); this._dropLane = lane; if (lane) lane.classList.add('leDropHere'); } };
            box.addEventListener('dragover', (e) => { if (!this._dragName && !this.drawerDragged(e)) return; const i = laneAt(e.clientY); mark(i); if (i < 0) return; e.preventDefault(); try { e.dataTransfer.dropEffect = 'copy'; } catch (err) { /* read-only in some states */ } });
            box.addEventListener('dragleave', (e) => { if (!box.contains(e.relatedTarget)) mark(-1); });
            box.addEventListener('drop', (e) => { const name = this._dragName || (e.dataTransfer && e.dataTransfer.getData('text/x-le-material')) || ''; const i = laneAt(e.clientY); mark(-1); if (!name || i < 0) return; e.preventDefault(); e.stopPropagation(); this.drawerDrop(e, i, name); });
            // a drop anywhere else is swallowed, so the browser never opens the "file" (and the drag ends cleanly)
            document.addEventListener('dragover', (e) => { if (this._dragName) e.preventDefault(); });
            document.addEventListener('drop', (e) => { if (this._dragName) { e.preventDefault(); this._dragName = null; mark(-1); } });
            };
            wire();
            window.addEventListener('resize', () => { if (this._drawer.root.classList.contains('open')) this.drawerFill(); });
        },
        drawerDragged(e) { const t = e.dataTransfer && e.dataTransfer.types; return !!(t && Array.from(t).includes('text/x-le-material')); },
        drawerToggle(open) {
            const d = this._drawer; if (!d) return;
            const on = open == null ? !d.root.classList.contains('open') : !!open;
            d.root.classList.toggle('open', on);
            if (on) this.drawerFill(); else this.drawerStop();
        },
        drawerFill() {
            const d = this._drawer; if (!d) return;
            const q = String(d.filter.value || '').trim().toLowerCase();
            const rows = this.materials.filter((m) => !q || (m.name + ' ' + (m.kind || '') + ' ' + (m.note || '')).toLowerCase().includes(q));
            d.count.textContent = rows.length + (rows.length === this.materials.length ? '' : ' of ' + this.materials.length) + ' · ' + mmss(rows.reduce((a, m) => a + (m.seconds || 0), 0));
            d.rows.innerHTML = '';
            const W = Math.max(240, (d.root.clientWidth || window.innerWidth) - 230 - 92 - 220 - 24 - 8 * 5 - 24);
            let kind = null;
            for (const m of rows) {
                if (m.kind !== kind) { kind = m.kind; d.rows.appendChild(el('div', { className: 'leKind', textContent: kind || 'mix' })); }
                const cv = el('canvas', { width: W, height: 34, title: 'click: hear from here · drag the row onto a lane' });
                const pb = el('button', { className: 'pb', textContent: '▶', title: 'hear from the start' });
                const row = el('div', { className: 'leRow', draggable: true, 'data-name': m.name }, [
                    el('span', { className: 'nm', textContent: m.name, title: m.name }),
                    el('span', { className: 'mt', textContent: mmss(m.seconds) + (m.channels === 1 ? ' · mono' : '') }),
                    cv, pb,
                    el('span', { className: 'nt', textContent: m.note || '', title: m.note || '' }),
                ]);
                row._le = { row: m, cv };
                this.drawerWave(row._le);
                cv.addEventListener('click', (e) => { const r = cv.getBoundingClientRect(); this.drawerPlay(row, Math.max(0, Math.min(1, (e.clientX - r.left) / r.width))); });
                pb.addEventListener('click', (e) => { e.stopPropagation(); this.drawerPlay(row, 0); });
                row.addEventListener('dragstart', (e) => { this._dragName = m.name; try { e.dataTransfer.setData('text/x-le-material', m.name); e.dataTransfer.setData('text/plain', m.name); e.dataTransfer.effectAllowed = 'copy'; } catch (err) { /* the flag carries the name */ } row.classList.add('dragging'); this.say('drag ' + m.name + ' onto a lane…'); });
                row.addEventListener('dragend', () => { row.classList.remove('dragging'); this._dragName = null; if (this._dropLane) { this._dropLane.classList.remove('leDropHere'); this._dropLane = null; } });
                d.rows.appendChild(row);
                if (this._playingRow && this._playingRow.row.name === m.name) { this._playingRow = row._le; row.classList.add('playing'); }
            }
        },
        // the waveform of a row: the peaks mirrored round the middle; the playhead where the preview stands
        drawerWave(le, frac) {
            const cv = le.cv, ctx = cv.getContext('2d'), W = cv.width, H = cv.height, p = this.peaksOf ? this.peaksOf(le.row.name) : null;
            ctx.clearRect(0, 0, W, H);
            if (!p) { ctx.fillStyle = '#bbb'; ctx.font = '10px Segoe UI'; ctx.fillText('no waveform yet — node tools/materials_index.js', 6, 21); return; }
            ctx.fillStyle = 'rgba(109,76,65,0.55)';
            const n = p.length, mid = H / 2;
            for (let x = 0; x < W; x++) {
                const b0 = Math.floor(x / W * n), b1 = Math.max(b0 + 1, Math.floor((x + 1) / W * n));
                let v = 0; for (let b = b0; b < b1 && b < n; b++) if (p[b] > v) v = p[b];
                const hh = Math.max(0.5, v / 255 * (mid - 1));
                ctx.fillRect(x, mid - hh, 1, hh * 2);
            }
            if (frac != null) { ctx.fillStyle = '#F04B00'; ctx.fillRect(Math.round(frac * W), 0, 2, H); }
        },
        drawerPlay(rowEl, frac) {
            const a = this._audio, le = rowEl._le, url = ((this.opts && this.opts.fundUrl) || '/fund/') + le.row.file;
            if (this._playingRow && this._playingRow !== le) { const prev = this._drawer.rows.querySelector('.leRow.playing'); if (prev) prev.classList.remove('playing'); this.drawerWave(this._playingRow); }
            this._playingRow = le; rowEl.classList.add('playing');
            const seek = () => { const d = a.duration; if (Number.isFinite(d) && d > 0) a.currentTime = frac * d; else if (le.row.seconds) a.currentTime = frac * le.row.seconds; a.play().catch((e) => this.say('the preview did not start: ' + e.message)); };
            if (a.src !== new URL(url, location.href).href) { a.src = url; a.addEventListener('loadedmetadata', seek, { once: true }); a.load(); }
            else seek();
            this.say('▶ ' + le.row.name + ' from ' + mmss(frac * (le.row.seconds || 0)));
        },
        drawerStop() { const a = this._audio; if (a && !a.paused) a.pause(); if (this._playingRow) { this.drawerWave(this._playingRow); } if (this._drawer) this._drawer.now.textContent = ''; },
        drawerTick() {
            const a = this._audio, le = this._playingRow; if (!a || !le) return;
            const d = Number.isFinite(a.duration) && a.duration > 0 ? a.duration : le.row.seconds || 1;
            this.drawerWave(le, a.currentTime / d);
            this._drawer.now.textContent = (a.paused ? '' : '▶ ') + le.row.name + ' · ' + mmss(a.currentTime) + ' / ' + mmss(d);
        },
        // a row dropped on lane i: a material brick at the drop's time, selected
        drawerDrop(e, layer, name) {
            const h = this.host; name = name || (e.dataTransfer && e.dataTransfer.getData('text/x-le-material')) || this._dragName;
            this._dragName = null;
            if (!name || !this.materialAdd) return;
            const t = Math.max(0, h.clientXToTime(e.clientX));
            if (h.pushUndoState) h.pushUndoState();
            const z = this.materialAdd(name, layer, t);
            if (z && h.selectObject) h.selectObject(z);
        },
    });
})();
