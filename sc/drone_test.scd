// drone_test.scd — THE DRONE SECTION'S ADDITIONS, HEADLESS (the Decibel piece's PLAN 15.2 e, 2026-10-08; its RUNNING_LOG §249; the
// engine's §60): boot.scd's functions in a bare sclang — NO server, no device, no port, no sound — a scratch bank, a made-up source
// (200 Hz for 3.5 s · 300 ms of silence · 400 Hz for 4.5 s — the second region the longer), and the icy stage rendered offline:
//     the REGIONS   found on the source as 0-3500,3800-8300 (bank.scd regionsFind)                      — 15.2 a
//     the START     "icFromMs:region@0.5" resolved along the longest region's usable span (regionStart)   — 15.2 b
//     t-dsrc~r1     a 3 s stretch from there is 400 Hz, not 200 (the buffer as long as the source; the clip widened)
//     t-dsrc~r2     a 20 s stretch with icWin on a LINE 0.15 → 1.5 s: the level flutters faster at the start than at the end   — 15.2 c
//     t-dsrc~dn1    through THE PLAN ROAD with a shape row "8000ms" · rise 1500 · fall 1500 (the chain dry — a stretch's own level
//                   wanders; the envelope on a stretch is process_test's ~1 and ~5): exactly 8 s, up over 1.5 s, down over 1.5 s;
//                   asked for BEFORE its render: NOTHING played and said (sampleFor)                                             — 15.2 d
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/drone_test.scd      (under a time limit: a routine that throws never exits)
// A living engine beside it is untouched. It ends DRONE_TEST PASS (exit 0) or DRONE_TEST FAIL (exit 1) and names each check.
(
var dir = thisProcess.nowExecutingPath.dirname;
var tmp = Platform.defaultTempDir +/+ "le_drone_test_" ++ Date.localtime.stamp;
var sr = 44100, n, src, fails = List.new, rowOf, waitFor, check, regs, rowSrc, rs, startMs;
(dir +/+ "boot.scd").load;
~le.bankOn(tmp);
// the source: 200 Hz for 3.5 s, 300 ms of silence, 400 Hz for 4.5 s — 20 ms edges, peak about -12 dB; the SECOND region is the longer
// (a tie keeps the first)
n = (8.3 * sr).asInteger;
src = FloatArray.fill(n, { |i|
	var t = i / sr, f, e;
	case
	{ t < 3.5 } { f = 200; e = min(1, t / 0.02, (3.5 - t) / 0.02) }
	{ t < 3.8 } { f = 0; e = 0 }
	{ true } { f = 400; e = min(1, (t - 3.8) / 0.02, (8.3 - t) / 0.02) };
	if(f > 0) { sin(2pi * f * t) * e * 0.25 } { 0 }
});
~le.wavWrite(tmp +/+ "t-dsrc.wav", src, sr);
rowOf = { |name| ~le[\indexRows].detect({ |r| r[\name].asString == name }) };
check = { |what, ok, detail| ("  " ++ if(ok) { "ok   " } { "FAIL " } ++ what ++ " — " ++ detail).postln; if(ok.not) { fails.add(what) } };
fork {
	var r1, r2, r3, f1, d1, goertzel, lvl, env10, res, cross, late, planRow, t0 = Main.elapsedTime, gA, gB, up, mid, down, dEnv;
	waitFor = { |name, secs = 90|
		var t = 0;
		while { rowOf.(name).isNil and: { t < secs } } { 0.25.wait; t = t + 0.25 };
		rowOf.(name)
	};
	("DRONE_TEST the scratch bank: " ++ tmp).postln;
	// ---- 15.2 a: the regions ----
	regs = ~le.regionsFind(src, sr);
	check.("the regions of the source are found", (~le.regionsText(regs[\list]) == "0-3500,3800-8300") and: { regs[\whole].not }, ~le.regionsText(regs[\list]) ++ if(regs[\whole]) { " (whole)" } { "" });
	// the source's row, as a capture would leave it (the regions in it)
	rowSrc = (name: "t-dsrc", lengthMs: 8300, regions: ~le.regionsText(regs[\list]));
	~le[\indexRows] = ~le[\indexRows].asList; ~le[\indexRows].add(rowSrc);
	// ---- 15.2 b: the start as a fraction — 0.5 of the usable span of the longest region (3800-8300 less the 3 s drone's read of 100 ms at 1/30) = 6000
	rs = ~le.regionStart("icMix:1,icSpeed:0.0333,icFromMs:region@0.5,icWin:0.6,icOverlaps:17,icRand:0.2,icPitch:0,icEnv:0,icLoop:1", "t-dsrc", 8300, 3000);
	startMs = rs[\args].split($,).detect({ |it| it.beginsWith("icFromMs:") }).split($:)[1].asFloat;
	check.("the fraction is resolved inside the longest region", (startMs - (3800 + (0.5 * (4500 - 100)))).abs < 2, rs[\args] ++ " · " ++ (rs[\said] ? ""));
	// ---- the render from there is 400 Hz (the buffer as long as the source; the clip widened past 3 s) ----
	~le.processRender((source: 't-dsrc', out: 't-dsrc~r1', effect: 'icy', args: rs[\args], end: 'shape', atkMs: 10, durMs: 3000, relMs: 10, curve: 0, match: 1, srcDrive: "played", id: 'test-r1'));
	r1 = waitFor.("t-dsrc~r1");
	goertzel = { |data, freq, from, len|   // the power at one frequency over len samples from `from`
		var w = 2pi * freq / sr, c = 2 * cos(w), s0 = 0.0, s1 = 0.0, s2 = 0.0;
		len.do({ |i| s0 = data[from + i] + (c * s1) - s2; s2 = s1; s1 = s0 });
		(s1 * s1) + (s2 * s2) - (c * s1 * s2)
	};
	if(r1.notNil) {
		f1 = SoundFile.new; f1.openRead(tmp +/+ "t-dsrc~r1.wav"); d1 = FloatArray.newClear(f1.numFrames); f1.readData(d1); f1.close;
		gA = goertzel.(d1, 200, (1.0 * sr).asInteger, (1.0 * sr).asInteger); gB = goertzel.(d1, 400, (1.0 * sr).asInteger, (1.0 * sr).asInteger);
		check.("~r1 a stretch from 6 s into the source is the 400 Hz half, not the 200", gB > (gA * 10), "400 Hz " ++ (10 * log10(gB.max(1e-12))).round(0.1) ++ " dB · 200 Hz " ++ (10 * log10(gA.max(1e-12))).round(0.1) ++ " dB · " ++ r1[\lengthMs] ++ " ms");
	} { check.("~r1 rendered", false, "no row") };
	// ---- 15.2 c: the grain size on a line — the flutter faster at the start (0.15 s grains) than at the end (1.5 s) ----
	~le.processRender((source: 't-dsrc', out: 't-dsrc~r2', effect: 'icy', args: "icMix:1,icSpeed:0.0333,icFromMs:500,icWin:0.15@0,1.5@20000,icOverlaps:17,icRand:0.2,icPitch:0,icEnv:0,icLoop:1",
		end: 'shape', atkMs: 10, durMs: 20000, relMs: 10, curve: 0, match: 1, srcDrive: "played", id: 'test-r2'));
	r2 = waitFor.("t-dsrc~r2");
	if(r2.notNil) {
		f1 = SoundFile.new; f1.openRead(tmp +/+ "t-dsrc~r2.wav"); d1 = FloatArray.newClear(f1.numFrames); f1.readData(d1); f1.close;
		// the level every 10 ms, the ±100 ms trend taken out, the crossings of zero counted: fluctuations a second
		env10 = { |from, to|
			var hop = (sr / 100).asInteger, a = (from * sr).asInteger, z = (to * sr).asInteger, out = List.new, i = a;
			while { (i + hop) <= z } { var acc = 0.0; hop.do({ |j| acc = acc + (d1[i + j] * d1[i + j]) }); out.add(20 * log10((acc / hop).sqrt.max(1e-7))); i = i + hop };
			out.asArray
		};
		cross = { |e|
			var k = 10, m = e.size, r = Array.fill(m, { |i| var a = (i - k).max(0), z = (i + k + 1).min(m); e[i] - (e.copyRange(a, z - 1).sum / (z - a)) }), c = 0;
			(m - 1).do({ |i| if((r[i] >= 0) != (r[i + 1] >= 0)) { c = c + 1 } });
			c / (m / 100)
		};
		up = cross.(env10.(1, 4)); down = cross.(env10.(16, 19));
		check.("~r2 the grain size on a line: the level flutters faster under short grains than under long", up > (down * 1.3), "crossings a second · at the start (0.15 … 0.35 s grains) " ++ up.round(0.1) ++ " · at the end (1.2 … 1.5 s) " ++ down.round(0.1) ++ " · " ++ r2[\lengthMs] ++ " ms · args " ++ r2[\args]);
	} { check.("~r2 rendered", false, "no row") };
	// ---- 15.2 d: the plan road — a shape row with an absolute length, a fall and a curve; the late rule before it lands ----
	~le.planTake((stamp: "dt", part: 1, of: 1, rows: "t-dsrc;dn1;icy;shape;1500;8000ms;1;10;0;icMix:0,icSpeed:0.0333,icFromMs:region@0.25,icWin:0.6,icOverlaps:17,icRand:0.2,icPitch:0,icEnv:0,icLoop:1;normalized;1500;0"));
	planRow = ~le[\plan].detect({ |r| r[\suffix] == "dn1" });
	check.("the plan row reads an absolute length, a fall and a curve", planRow.notNil and: { planRow[\durMs] == 8000 } and: { planRow[\durX] == 0 } and: { planRow[\relMs] == 1500 } and: { planRow[\curve] == "0" } and: { planRow[\atkMs] == 1500 },
		if(planRow.notNil) { "durMs " ++ planRow[\durMs] ++ " · durX " ++ planRow[\durX] ++ " · atkMs " ++ planRow[\atkMs] ++ " · relMs " ++ planRow[\relMs] ++ " · curve " ++ planRow[\curve] } { "no row" });
	late = ~le.sampleFor("t-dsrc~dn1");
	check.("asked for before its render, a shaped stretch plays NOTHING", late.isNil and: { ~le[\lateSilent].asString == "t-dsrc~dn1" }, "sampleFor → " ++ late ++ " · lateSilent " ++ ~le[\lateSilent]);
	~le[\planLastTouch] = -1e9;   // no hold: the capture is long over
	~le.planRender("t-dsrc");
	r3 = waitFor.("t-dsrc~dn1");
	if(r3.notNil) {
		f1 = SoundFile.new; f1.openRead(tmp +/+ "t-dsrc~dn1.wav"); d1 = FloatArray.newClear(f1.numFrames); f1.readData(d1); f1.close;
		lvl = { |at, len = 0.2| var a = (at * sr).asInteger, m = (len * sr).asInteger, pk = 0.0; m.do({ |i| pk = max(pk, d1[a + i].abs) }); if(pk > 0) { pk.ampdb } { -150 } };
		up = lvl.(0.75) - lvl.(3.0); down = lvl.(7.25) - lvl.(3.0);   // half-way up the rise and half-way down the fall: about -6 dB
		check.("~dn1 by the plan: exactly 8 s, up over 1.5 s, down over 1.5 s", ((r3[\lengthMs] - 8000).abs < 1) and: { (up + 6).abs < 2.5 } and: { (down + 6).abs < 2.5 } and: { r3[\end].asString == "shape" },
			r3[\lengthMs].asString ++ " ms · half-way up the rise " ++ up.round(0.1) ++ " dB · half-way down the fall " ++ down.round(0.1) ++ " dB (−6 expected) · end " ++ r3[\end]);
	} { check.("~dn1 rendered by the plan", false, "no row in 90 s") };
	("DRONE_TEST " ++ (Main.elapsedTime - t0).round(0.1) ++ " s").postln;
	if(fails.size == 0) { try { File.deleteAll(tmp) }; "DRONE_TEST PASS".postln; 0.exit } { ("DRONE_TEST FAIL — " ++ fails.join(" · ")).postln; 1.exit };
};
)
