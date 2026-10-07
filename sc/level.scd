// level.scd — THE LEVEL: how loud a banked sample IS, and how loud it is PLAYED (the engine plan's part 13; first built in the
// Decibel piece, 2026-10-06 — its PLAN 1.4 · 11.1 … 11.3, RUNNING_LOG §161 …). Loaded by boot.scd after bank.scd; pure language —
// nothing here needs a server, so all of it is proven headless (level_test.scd).
//
// THE MEASURE (11.1) — a loudness figure on every row of the bank's index, on the scale the players' own levels are kept on:
//   loudDb      the loudest 400 ms of the sample (a one-shot's figure: what a momentary meter would show at its most)
//   loudIntDb   the whole sample
//   both in LUFS (ITU-R BS.1770: the K-weighting, then the mean square, − 0.691), measured on the sample AS IT WILL SOUND —
//   \leSample sends it to both channels at unity, so the sum the standard takes is twice one channel's. A 1 kHz tone at
//   −20 dBFS RMS reads −17.0: the players' reference tone (a piece's bank/reference.json).
//   HOW: the K-weighting is applied in the FREQUENCY domain — each 400 ms window through the language's own FFT (a primitive),
//   its power spectrum weighted by |H|² of the standard's two filters (the coefficients computed for the file's own sample rate,
//   in double precision; at 48 kHz they are the standard's table — level_test.scd asserts it). A window every 100 ms; a sample
//   shorter than 400 ms is one window, the rest silence — what a meter reads. Sample-by-sample filtering in the language would
//   hold it for seconds on a long render; this is a few milliseconds a window.
//   ~le.loudOf(data, sr)      -> (loudDb:, loudIntDb:)      ~le.loudOfFile(path)
//   ~le.measureBank           the rows that have no figure yet, in the background, a few a second; the index written once
//
// THE LADDER (11.2) — a written dynamic is a number of decibels, the players' own law:
//   fff = `reference` LUFS · each name below it `stepDb` (4) less · ppp = 28 dB under. A piece gives the numbers at the engine's
//   START (LE_LEVEL, session.scd); the defaults below stand where it says nothing.
//   liftCapDb   a sample is never raised by more than this (a whisper is not lifted into the room's noise)
//   floorDb     a sample quieter than this is never raised at all
//   ~le.markDb(mark)          the LUFS of a name                 ~le.playedMark(loudDb)   the name nearest a loudness
//   ~le.gainFor(row, dyn)     -> (db:, note:) — how many dB a sample is played at, for a brick's dynamic:
//       played                 as it was captured: 0 dB — THE DEFAULT (a player's own dynamic leads)
//       mark:mf                AT a mark, whatever was captured: markDb − the row's loudDb
//       rel:+1                 as played, n steps up or down         rel:-1:floor:p:ceil:f   … held inside two marks
//     A row with no figure is played as captured, and the window says "unmeasured".
//
// THE DYNAMIC IN TIME (11.3) — /le/play carries `dyn` (above) and `env`, breakpoints from the SAMPLE'S OWN START:
//       env  0:mf,1200:ff,1250:p        ms:level pairs. ms may be `end` (the sample's length). A level is a mark · `=` (the brick's
//                                       own dynamic) · +n / -n (steps from it).   envCurve: one curve for every segment (0 = straight
//                                       in dB — an even hairpin to the ear).
//   ~le.levelFor(row, d)      -> (db: 8 values, dt: 7 times, curve:, note:) — \leSample's envelope (synths.scd): the levels in dB
//   of gain, padded with the last one. Deterministic: the same message, the same envelope, in concert and in simulation.
(
~le[\levelDefaults] = (reference: -29.54, stepDb: 4, liftCapDb: 20, floorDb: -60, driveRef: -20, bleedDb: 12);
~le[\levelMarks] = [\ppp, \pp, \p, \mp, \mf, \f, \ff, \fff];
~le[\levelOf] = { |self|
	var o = self[\levelDefaults].copy;
	if(self[\levelOpts].notNil) { o.putAll(self[\levelOpts]) };
	o
};

// ---- the measure ------------------------------------------------------------------------------------------------------
// BS.1770's two filters as biquads [b0, b1, b2, a1, a2] for ANY sample rate (the standard tabulates 48 kHz; these are the
// analogue prototypes it was made from, as libebur128 computes them)
~le[\kCoefs] = { |self, sr|
	var f0 = 1681.974450955533, g = 3.999843853973347, q = 0.7071752369554196;
	var k = tan(pi * f0 / sr), vh = 10 ** (g / 20), vb = vh ** 0.4996667741545416, a0 = 1 + (k / q) + (k * k);
	var f1 = 38.13547087602444, q1 = 0.5003270373238773, k1 = tan(pi * f1 / sr), d1 = 1 + (k1 / q1) + (k1 * k1);
	(shelf: [(vh + (vb * k / q) + (k * k)) / a0, 2 * ((k * k) - vh) / a0, (vh - (vb * k / q) + (k * k)) / a0, 2 * ((k * k) - 1) / a0, (1 - (k / q) + (k * k)) / a0],
		hp: [1, -2, 1, 2 * ((k1 * k1) - 1) / d1, (1 - (k1 / q1) + (k1 * k1)) / d1])
};

// |H|² of one biquad at w radians per sample
~le[\kGain2] = { |self, c, w|
	var cw = cos(w), c2 = cos(2 * w);
	var num = (c[0] * c[0]) + (c[1] * c[1]) + (c[2] * c[2]) + (2 * ((c[0] * c[1]) + (c[1] * c[2])) * cw) + (2 * c[0] * c[2] * c2);
	var den = 1 + (c[3] * c[3]) + (c[4] * c[4]) + (2 * (c[3] + (c[3] * c[4])) * cw) + (2 * c[4] * c2);
	num.max(0) / den.max(1e-30)
};

// what one sample rate needs, made once: the window (400 ms, a hop of 100), the transform's size, the weights of every bin, the
// transform's own scale (read off a unit impulse, so no convention is assumed)
~le[\kKit] = { |self, sr|
	var key = sr.asInteger, kit = if(self[\kKits].notNil) { self[\kKits][key] }, hop, win, n, co, half, w, cosT, imp, c;
	if(kit.isNil) {
		hop = (0.1 * sr).round.asInteger; win = hop * 4; n = win.nextPowerOfTwo;
		co = self.kCoefs(sr);
		half = Array.fill((n div: 2) + 1, { |i| var x = 2pi * i / n; self.kGain2(co[\shelf], x) * self.kGain2(co[\hp], x) });
		w = (half ++ half.copyRange(1, (n div: 2) - 1).reverse).as(Signal);
		cosT = Signal.fftCosTable(n);
		imp = Signal.newClear(n); imp[0] = 1;
		c = imp.fft(Signal.newClear(n), cosT);
		kit = (hop: hop, win: win, size: n, weights: w, cosTable: cosT, scale: 1 / ((c.real * c.real) + (c.imag * c.imag)).integral);
		if(self[\kKits].isNil) { self[\kKits] = IdentityDictionary.new };
		self[\kKits][key] = kit;
	};
	kit
};

// the K-weighted energy of one window of the samples, from `from`
~le[\kEnergy] = { |self, kit, data, from|
	var seg = data.copyRange(from, (from + kit[\win] - 1).min(data.size - 1)), re, c;
	re = (seg.as(FloatArray) ++ FloatArray.newClear(kit[\size] - seg.size)).as(Signal);
	c = re.fft(Signal.newClear(kit[\size]), kit[\cosTable]);
	(((c.real * c.real) + (c.imag * c.imag)) * kit[\weights]).integral * kit[\scale]
};

~le[\lufs] = { |self, meanSquare| if(meanSquare > 1e-12) { ((10 * log10(meanSquare)) - 0.691).round(0.1) } { -120 } };

~le[\loudOf] = { |self, data, sr|
	var kit, n = if(data.notNil) { data.size } { 0 }, off = 0, e, best = 0, whole = 0, nextWhole = 0, early;
	if(n < 1) { nil } {
		kit = self.kKit(sr);
		early = kit[\win] * 5;   // a window every 100 ms through the first 2 s — where a struck sound has its most — then side by side
		while { off < n } {
			e = self.kEnergy(kit, data, off);
			// THE BREATH (the Decibel piece's RUNNING_LOG §195, 2026-10-06): a window's energy is ~20 … 50 ms of language time, and a render
			// measured here held the language for the whole file — the next /le/open was heard late and its recording began inside the
			// note (ten windows refused by the room rule in one pass). Inside a Routine (captureDone · processDone are forked now) the
			// loop yields between windows, so a message is never kept waiting longer than one window; the figures are unchanged.
			if(thisThread.isKindOf(Routine)) { 0.002.wait };
			best = max(best, e);
			if(off == nextWhole) { whole = whole + e; nextWhole = nextWhole + kit[\win] };   // the windows that stand side by side: together, the whole sample
			off = off + if(off < early) { kit[\hop] } { kit[\win] };
		};
		(loudDb: self.lufs(best / kit[\win] * 2), loudIntDb: self.lufs(whole / n * 2))
	}
};

~le[\loudOfFile] = { |self, path|
	var sf = SoundFile.new, data, m;
	if(File.exists(path) and: { sf.openRead(path) }) {
		if(sf.numChannels == 1) {
			data = FloatArray.newClear(sf.numFrames);
			sf.readData(data);
			m = self.loudOf(data, sf.sampleRate);
		};
		sf.close;
	};
	m
};

// the figure INTO a row: the two numbers, and the name of the capture on the ladder
~le[\loudInto] = { |self, row, m|
	if(row.notNil and: { m.notNil }) { row[\loudDb] = m[\loudDb]; row[\loudIntDb] = m[\loudIntDb]; row[\played] = self.playedMark(m[\loudDb]).asString };
	row
};

// the bank as it stands: every row without a figure, measured from its file — in the background, `perSecond` of them a second
// (each holds the language for a few milliseconds), the index written ONCE at the end. Afterwards only captures and renders.
~le[\measureBank] = { |self, perSecond = 8|
	var work = List.new, dir = self[\bankDir], src = self[\sourceDir], done = 0, wrote = false;
	if(dir.notNil) {
		(self[\indexRows] ? []).do({ |r| if(r[\loudDb].isNil and: { r[\file].notNil }) { work.add((row: r, path: dir +/+ r[\file].asString, own: true)) } });
		// the buffers were filled from another folder (the backup): its rows are measured for the playing, and its index is left alone
		if(self[\samples].notNil) {
			self[\samples].keysValuesDo({ |name, e|
				var r = e[\row];
				if(r.notNil and: { r[\loudDb].isNil } and: { r[\file].notNil } and: { work.detect({ |x| x[\row] === r }).isNil }) {
					work.add((row: r, path: (src ? dir) +/+ r[\file].asString, own: false));
				};
			});
		};
	};
	if(work.size > 0) {
		self.say("LE_INFO", "measuring · " ++ work.size ++ " samples have no loudness figure yet — in the background; nothing waits on it");
		Routine({
			work.do({ |x, i|
				var m = try { self.loudOfFile(x[\path]) } { nil }, twin;
				if(m.notNil) {
					self.loudInto(x[\row], m);
					done = done + 1;
					if(x[\own]) { wrote = true };
					// the same sample's row in the buffers' table, when it is another object
					twin = if(self[\samples].notNil) { self[\samples][x[\row][\name].asSymbol] };
					if(twin.notNil and: { twin[\row].notNil } and: { twin[\row] !== x[\row] } and: { twin[\row][\loudDb].isNil }) { self.loudInto(twin[\row], m) };
				};
				if(((i + 1) % 200) == 0) { self.say("LE_INFO", "measured · " ++ (i + 1) ++ " of " ++ work.size) };
				(1 / perSecond).wait;
			});
			if(wrote) { if(self.indexWrite.not) { self.say("LE_INFO", "the index was NOT written — the figures hold until this engine stops") } };
			self.say("LE_INFO", "measured · " ++ done ++ " of " ++ work.size ++ " — every sample has its loudness now");
		}).play(SystemClock);
	};
	work.size
};

// ---- the ladder -------------------------------------------------------------------------------------------------------
~le[\markDb] = { |self, mark|
	var o = self.levelOf, i = self[\levelMarks].indexOf((mark ? "").asString.stripWhiteSpace.asSymbol);
	if(i.isNil) { nil } { o[\reference] - ((7 - i) * o[\stepDb]) }
};

~le[\playedMark] = { |self, loudDb|
	var o = self.levelOf;
	self[\levelMarks][(7 + ((loudDb - o[\reference]) / o[\stepDb])).round.asInteger.clip(0, 7)]
};

// a gain, held to what the piece allows: never more than the cap up, and nothing up at all for a sample under the floor
~le[\liftCap] = { |self, loud, g|
	var o = self.levelOf;
	if(loud.notNil and: { loud < o[\floorDb] }) { g.min(0) } { g.min(o[\liftCapDb]) }
};

~le[\gainFor] = { |self, row, dyn|
	var o = self.levelOf, loud = if(row.notNil and: { row[\loudDb].notNil }) { row[\loudDb].asFloat };
	var b = (dyn ? "played").asString.split($:), mode = b[0].asString, target, g = 0, note = "", raw;
	case
	{ mode == "mark" } { target = self.markDb(b[1]); if(target.notNil) { note = b[1].asString.stripWhiteSpace } }
	{ mode == "rel" } {
		note = "as played " ++ (b[1] ? "0").asString;
		if(loud.notNil) {
			target = loud + ((b[1] ? "0").asString.asFloat * o[\stepDb]);
			b.drop(2).pairsDo({ |k, v|
				var m = self.markDb(v);
				if(m.notNil) {
					if(k.asString == "floor") { target = max(target, m) };
					if(k.asString == "ceil") { target = min(target, m) };
				};
			});
		} { target = 0 };
	};
	if(target.notNil) {
		if(loud.isNil) { note = note ++ " · UNMEASURED: as captured" } {
			raw = target - loud;
			g = self.liftCap(loud, raw);
			if(g < raw) { note = note ++ if(loud < o[\floorDb]) { " · under the floor: not lifted" } { " · the lift held at " ++ o[\liftCapDb] ++ " dB (it asked " ++ raw.round(0.1) ++ ")" } };
		};
	};
	(db: g, note: note)
};

// one LEVEL of an envelope -> dB of gain: a mark · "=" the brick's own dynamic · "+n" / "-n" steps from it
~le[\levelGain] = { |self, loud, token, baseDb|
	var o = self.levelOf, t = (token ? "=").asString.stripWhiteSpace, m = self.markDb(t);
	case
	{ m.notNil } { if(loud.isNil) { baseDb } { self.liftCap(loud, m - loud) } }
	{ (t.size > 1) and: { (t[0] == $+) or: { t[0] == $- } } } { self.liftCap(loud, baseDb + (t.asFloat * o[\stepDb])) }
	{ true } { baseDb }
};

~le[\levelFor] = { |self, row, d, extraDb = 0|
	var base = self.gainFor(row, if(d.notNil) { d[\dyn] }), loud = if(row.notNil and: { row[\loudDb].notNil }) { row[\loudDb].asFloat };
	var lenMs = if(row.notNil and: { row[\lengthMs].notNil }) { row[\lengthMs].asFloat } { 1000 };
	var text = if(d.notNil and: { d[\env].notNil }) { d[\env].asString } { "" }, pts = List.new, db, dt, note = base[\note], more;
	text.split($,).do({ |x|
		var b = x.asString.stripWhiteSpace.split($:), ms;
		if(b.size >= 2) {
			ms = if(b[0].asString == "end") { lenMs } { b[0].asString.asFloat.max(0) };
			pts.add([ms, self.levelGain(loud, b[1], base[\db]), b[1].asString]);
		};
	});
	pts = pts.asArray.sort({ |p, q| p[0] < q[0] });
	if(pts.size == 0) { pts = [[0, base[\db], "="]] };
	if(pts[0][0] > 0) { pts = [[0, base[\db], "="]] ++ pts };   // until the first point: the brick's own dynamic
	more = pts.size > 8;
	pts = pts.keep(8);
	db = pts.collect({ |p| p[1] + extraDb });
	dt = Array.fill(pts.size - 1, { |i| ((pts[i + 1][0] - pts[i][0]) / 1000).max(0.005) });
	if(pts.size > 1) { note = note ++ " · " ++ pts.collect({ |p| p[0].round(1).asInteger.asString ++ " ms " ++ p[1].round(0.1) ++ " dB" }).join(" → ") };
	if(more) { note = note ++ " · MORE THAN 8 POINTS: the rest left out" };
	while { db.size < 8 } { db = db.add(db.last) };
	while { dt.size < 7 } { dt = dt.add(0.01) };
	(db: db, dt: dt, curve: (if(d.notNil) { d[\envCurve] } ? 0).asString.asFloat.clip(-8, 8), baseDb: base[\db], points: pts, note: note)
};

// the envelope as \leSample takes it, and what the window says of it (nothing, for a sample played as captured)
~le[\levelArgs] = { |self, lv| [\envDb, lv[\db], \envDt, lv[\dt], \envCurve, lv[\curve]] };
~le[\levelSaid] = { |self, lv|
	if((lv[\points].size > 1) or: { lv[\baseDb] != 0 } or: { lv[\note].size > 0 }) {
		" · " ++ if(lv[\note].size > 0) { lv[\note] } { "as played" } ++ if(lv[\points].size == 1) { " " ++ if(lv[\baseDb] >= 0) { "+" } { "" } ++ lv[\baseDb].round(0.1) ++ " dB" } { "" }
	} { "" }
};
)
