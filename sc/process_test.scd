// process_test.scd — THE PROCESSING, HEADLESS (the engine's RUNNING_LOG §26; the Decibel piece's §103, 2026-10-05): boot.scd's
// functions into a bare sclang — NO server, no device, no port, no sound — a scratch bank in the temp folder, one made-up sample,
// and four renders through the real chain, offline:
//     t-src~1   t-src   through the COMB, ended by a SHAPE of 600 ms            (the envelope; a core stage)
//     t-src~2   t-src   through the REVERB, ended by its TAIL                   (the ring-out; the source ends OFF zero on purpose —
//                                                                                the player's held last value once kept a tail from ending)
//     t-src~3   t-src~1 through GREYHOLE, ended by its tail                     (a render OF a render; a ~ name as a source; an sc3-plugins stage)
//     t-src~4   t-src   through the FREEZE, a shape of 1.5 s                    (the held spectrum still sounds a second after the source)
//     t-src~5   t-src   through BUFFER OVERRIDE, a shape of 800 ms             (DEC-17, §106: the mini-buffer machinery compiles and renders)
//     t-src~6   t-src   through FUZZ INTO A CABINET, ended by its tail         (two of the new stages in ONE brick, by the JSON road)
//     t-src~7   t-src   through the FEEDBACK, ended by its tail               (DEC-18 · 19, §110: six strings in a loop — it must BLOOM and HOLD past the source)
//     t-src~8   t-src   through NONE, ended by PERC over 700 ms                (§111: a fixed-curve ending — exactly its length, nearly gone at 90 % of it)
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/process_test.scd
// A living engine beside it is untouched: nothing here opens a port or a device; the renderer is a second scsynth in NRT mode.
// It ends PROCESS_TEST PASS (exit 0) or PROCESS_TEST FAIL (exit 1) and names each check.
(
var dir = thisProcess.nowExecutingPath.dirname;
var tmp = Platform.defaultTempDir +/+ "le_process_test_" ++ Date.localtime.stamp;
var sr = 48000, n, src, fails = List.new, rowOf, waitFor, check;
(dir +/+ "boot.scd").load;
~le.bankOn(tmp);   // makes the folder; no server: the index is empty, nothing is loaded
// the source: 50 ms of silence, then a 300 ms burst — 330 Hz and its octave, falling fast; its peak about -12 dB
n = (0.35 * sr).asInteger;
src = FloatArray.fill(n, { |i|
	var t = (i / sr) - 0.05;
	if(t < 0) { 0 } { (sin(2pi * 330 * t) + (0.5 * sin(2pi * 660 * t))) * exp(t * -12) * 0.17 }
});
~le.wavWrite(tmp +/+ "t-src.wav", src, sr);
rowOf = { |name| ~le[\indexRows].detect({ |r| r[\name].asString == name }) };
check = { |what, ok, detail| ("  " ++ if(ok) { "ok   " } { "FAIL " } ++ what ++ " — " ++ detail).postln; if(ok.not) { fails.add(what) } };
fork {
	var r1, r2, r3, r4, r5, r6, r7, r8, f4, d4, held, f7, d7, fbHeld, f8, d8, late8, srcDb = ~le.db(src.abs.maxItem), t0 = Main.elapsedTime;
	waitFor = { |name, secs = 30|
		var t = 0;
		while { rowOf.(name).isNil and: { t < secs } } { 0.25.wait; t = t + 0.25 };
		rowOf.(name)
	};
	("PROCESS_TEST the scratch bank: " ++ tmp).postln;
	~le.processRender((source: 't-src', out: 't-src~1', effect: 'comb', args: 'combMix:1,combTime:0.012,combFb:0.8,noSuchDial:3',
		end: "shape", atkMs: 2, durMs: 600, relMs: 600, curve: -4, id: "test-1"));
	~le.processRender((source: 't-src', out: 't-src~2', effect: 'reverb', args: 'revMix:0.6,revTime:1.5', end: 'tail', capMs: 6000, id: 'test-2'));
	r1 = waitFor.("t-src~1");
	r2 = waitFor.("t-src~2");
	if(r1.notNil) {
		~le.processRender((source: 't-src~1', out: 't-src~3', effect: 'greyhole', args: 'ghMix:0.7,ghSize:0.5,ghTime:0.1,ghFb:0.8', end: 'tail', capMs: 6000, id: 'test-3'));
		r3 = waitFor.("t-src~3");
	};
	("PROCESS_TEST the checks (" ++ (Main.elapsedTime - t0).round(0.1) ++ " s for the first three renders):").postln;
	check.("the chain is whole", ~le[\processMissing].size == 0, if(~le[\processMissing].size == 0) { "every stage is installed" } { "missing: " ++ ~le[\processMissing].join(", ") });
	check.("~1 comb · shape", r1.notNil and: { File.exists(tmp +/+ "t-src~1.wav") }, if(r1.notNil) { r1[\lengthMs].asString ++ " ms · peak " ++ r1[\peakDb] ++ " dB" } { "no row" });
	if(r1.notNil) {
		check.("~1 is exactly its envelope", (r1[\lengthMs] - 600).abs < 0.5, "600 ms asked, " ++ r1[\lengthMs] ++ " ms made");
		check.("~1 peak = the source's", (r1[\peakDb] - srcDb).abs < 0.3, "the source " ++ srcDb ++ " dB · the render " ++ r1[\peakDb] ++ " dB");
		check.("~1 row says what it is", (r1[\kind].asString == "processed") and: { r1[\source].asString == "t-src" } and: { r1[\openingId].asString == "test-1" },
			"kind " ++ r1[\kind] ++ " · source " ++ r1[\source] ++ " · id " ++ r1[\openingId] ++ " · args " ++ r1[\args]);
		check.("an unknown dial is left out", r1[\args].asString.contains("noSuchDial").not, r1[\args].asString);
	};
	check.("~2 reverb · tail", r2.notNil and: { File.exists(tmp +/+ "t-src~2.wav") }, if(r2.notNil) { r2[\lengthMs].asString ++ " ms · peak " ++ r2[\peakDb] ++ " dB" } { "no row" });
	if(r2.notNil) { check.("~2 rings past its source and ends before the cap", (r2[\lengthMs] > 450) and: { r2[\lengthMs] < 6000 }, "the source 300 ms · the render " ++ r2[\lengthMs] ++ " ms · the cap 6000") };
	check.("~3 a render of a render · an sc3-plugins stage", r3.notNil and: { File.exists(tmp +/+ "t-src~3.wav") }, if(r3.notNil) { r3[\lengthMs].asString ++ " ms · peak " ++ r3[\peakDb] ++ " dB · source " ++ r3[\source] } { "no row" });
	if(r3.notNil) { check.("~3 names its source", r3[\source].asString == "t-src~1", r3[\source].asString) };
	// the freeze: the spectrum 120 ms in, held under a 1.5 s shape — it must still be SOUNDING a second later (the source is long over)
	~le.processRender((source: 't-src', out: 't-src~4', effect: 'freeze', args: 'freeze:1,freezeAtMs:120,smear:4', end: 'shape', atkMs: 5, durMs: 1500, relMs: 300, curve: -2, id: 'test-4'));
	r4 = waitFor.("t-src~4");
	check.("~4 freeze · shape", r4.notNil and: { File.exists(tmp +/+ "t-src~4.wav") }, if(r4.notNil) { r4[\lengthMs].asString ++ " ms · peak " ++ r4[\peakDb] ++ " dB" } { "no row" });
	if(r4.notNil) {
		f4 = SoundFile.new;
		if(f4.openRead(tmp +/+ "t-src~4.wav")) { d4 = FloatArray.newClear(f4.numFrames); f4.readData(d4); f4.close };
		held = if(d4.notNil and: { d4.size > (1.1 * sr) }) { (d4.copyRange((0.6 * sr).asInteger, (1.1 * sr).asInteger).abs.maxItem / d4.abs.maxItem).ampdb.round(0.1) } { -999 };
		check.("~4 the freeze holds", held > -30, "0.6 … 1.1 s into it, " ++ held ++ " dB under its peak (the source ended at 0.35 s)");
	};
	// DEC-17 (§106): buffer override — the mini-buffer machinery (a LocalBuf, two readers, the crossfade) compiles and renders under a
	// shape; and a pedal stack — fuzz into the cabinet in ONE brick (two mixes up by the JSON road), ringing out. The sc3-plugins
	// shredders (Squiz · WaveLoss) are covered by "the chain is whole". What they SOUND like is his, on a brick (D13).
	~le.processRender((source: 't-src', out: 't-src~5', effect: 'override', args: 'ovrMix:1,ovrBuf:120,ovrDiv:24,ovrSmooth:0.1', end: 'shape', atkMs: 2, durMs: 800, relMs: 100, curve: -2, id: 'test-5'));
	~le.processRender((source: 't-src', out: 't-src~6', effect: 'fuzz', args: 'fzMix:1,fzGain:60,fzBias:0.3,cabMix:1', end: 'tail', capMs: 3000, id: 'test-6'));
	r5 = waitFor.("t-src~5");
	r6 = waitFor.("t-src~6");
	check.("~5 buffer override · shape", r5.notNil and: { File.exists(tmp +/+ "t-src~5.wav") }, if(r5.notNil) { r5[\lengthMs].asString ++ " ms · peak " ++ r5[\peakDb] ++ " dB" } { "no row" });
	if(r5.notNil) { check.("~5 is its envelope, at the source's peak", ((r5[\lengthMs] - 800).abs < 0.5) and: { (r5[\peakDb] - srcDb).abs < 0.3 }, r5[\lengthMs].asString ++ " ms · " ++ r5[\peakDb] ++ " dB (the source " ++ srcDb ++ ")") };
	check.("~6 fuzz into a cabinet, one brick · tail", r6.notNil and: { File.exists(tmp +/+ "t-src~6.wav") }, if(r6.notNil) { r6[\lengthMs].asString ++ " ms · peak " ++ r6[\peakDb] ++ " dB · args " ++ r6[\args] } { "no row" });
	if(r6.notNil) { check.("~6 carries both stages and ends before the cap", r6[\args].asString.contains("fzMix") and: { r6[\args].asString.contains("cabMix") } and: { r6[\lengthMs] < 3000 }, r6[\args].asString ++ " · " ++ r6[\lengthMs] ++ " ms") };
	// DEC-18 · 19 (§110): the feedback — six open strings in a loop with the amp's clipping (LocalIn/Out): the source is 330 Hz, string 6 is
	// E4 329.63 — the tone must BLOOM (bloom 0.3 s) and HOLD (1 s) past the source's 0.35 s, then die before the cap
	~le.processRender((source: 't-src', out: 't-src~7', effect: 'feedback', args: 'fbMix:1,fbBloom:0.3,fbHold:1,fbDrive:6', end: 'tail', capMs: 4000, id: 'test-7'));
	r7 = waitFor.("t-src~7");
	check.("~7 feedback · tail", r7.notNil and: { File.exists(tmp +/+ "t-src~7.wav") }, if(r7.notNil) { r7[\lengthMs].asString ++ " ms · peak " ++ r7[\peakDb] ++ " dB" } { "no row" });
	if(r7.notNil) {
		f7 = SoundFile.new;
		if(f7.openRead(tmp +/+ "t-src~7.wav")) { d7 = FloatArray.newClear(f7.numFrames); f7.readData(d7); f7.close };
		fbHeld = if(d7.notNil and: { d7.size > (1.0 * sr) }) { (d7.copyRange((0.5 * sr).asInteger, (1.0 * sr).asInteger).abs.maxItem / d7.abs.maxItem).ampdb.round(0.1) } { -999 };
		check.("~7 the feedback blooms and holds, then dies", (fbHeld > -20) and: { r7[\lengthMs] > 1000 } and: { r7[\lengthMs] < 4000 },
			"0.5 … 1.0 s into it, " ++ fbHeld ++ " dB under its peak (the source ended at 0.35 s) · " ++ r7[\lengthMs] ++ " ms long, the hold 1 s, the cap 4000");
	};
	// §111: an ENDING of the new kind — Env.perc over 700 ms on the plain sample (`none`): exactly its length, nearly gone at 90 % of it
	~le.processRender((source: 't-src', out: 't-src~8', effect: 'none', args: '', end: 'perc', atkMs: 10, durMs: 700, id: 'test-8'));
	r8 = waitFor.("t-src~8");
	check.("~8 none · perc", r8.notNil and: { File.exists(tmp +/+ "t-src~8.wav") }, if(r8.notNil) { r8[\lengthMs].asString ++ " ms · peak " ++ r8[\peakDb] ++ " dB · end " ++ r8[\end] } { "no row" });
	if(r8.notNil) {
		f8 = SoundFile.new;
		if(f8.openRead(tmp +/+ "t-src~8.wav")) { d8 = FloatArray.newClear(f8.numFrames); f8.readData(d8); f8.close };
		late8 = if(d8.notNil and: { d8.size > 100 }) { (d8.copyRange((d8.size * 0.9).asInteger, d8.size - 1).abs.maxItem / d8.abs.maxItem).ampdb.round(0.1) } { 0 };
		check.("~8 is its length and falls on the perc curve", ((r8[\lengthMs] - 700).abs < 0.5) and: { late8 < -25 } and: { r8[\end].asString == "perc" },
			r8[\lengthMs].asString ++ " ms · the last tenth " ++ late8 ++ " dB under the peak · end " ++ r8[\end]);
	};
	check.("the index on disk holds the eight", ~le.indexRowsOf(tmp).size == 8, ~le.indexRowsOf(tmp).collect({ |r| r[\name] }).join(" · "));
	// what a chain's "*" plays: every CAPTURED sample — a render does not join it (bank.scd chainNames)
	~le[\samples].put('t-src', (row: (name: "t-src")));
	if(r1.notNil) { ~le[\samples].put('t-src~1', (row: r1)) };
	check.("\"*\" is every CAPTURED sample", ~le.chainNames("*") == ["t-src"], "of t-src and t-src~1 it plays " ++ ~le.chainNames("*"));
	// a pass leaves nothing behind; a failure keeps the scratch bank to be looked at
	if(fails.size == 0) { try { File.deleteAll(tmp) }; "PROCESS_TEST PASS".postln; 0.exit } { ("PROCESS_TEST FAIL — " ++ fails.join(" · ")).postln; 1.exit };
};
)
