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
//     t-src~9 · ~10   the two granular voices (the cloud · icy), each cut at its cap
//     t-src~11 · ~12  HIS PETALS OF RESONANCE — the original · the cleaned path (the Decibel piece's DEC-32, §151): each rings past its source
//     t-src~13        the FEEDBACK with EVERY STRING SINGING (fbOwn 1, §151): a chord that shares no harmonic holds, each pitch in it
//     t-src~16        THE LOOP AROUND THE PETALS (poBloom, DEC-40 route (c), §203): the ring is HELD by the loop, broken at the hold, dies
//     t-src~17 · ~18  the feedback's strings as RINGING PARTIALS (fbRes 1, route (b)): in the one loop the chord takes off (the strongest
//                     wins — printed); with each string singing, all three pitches hold
//     THE PLAN  three variants of t-src (t-src~x1-perc …) sent in two parts, out of order; planRender as a capture's end calls it —
//               a queue two wide, lengths as multiples of the source's (durX), a tape's speed counted in; the fallback to the base
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
	var p1, p2, p3, fb, lenOf = { |r| if(r.notNil) { r[\lengthMs] } { -1 } };
	var r9, f9, d9, gfHeld, r10, f10, d10, icHeld, r14, f14, d14, r15, f15, d15, lpLate, hdLate, lateOf;
	var r11, r12, tP, r13, f13, d13, own, tones, r16, f16, d16, poPk, poHeld, poLate, poProf, r17, r18, goertzel;
	var dA, dB, dC, dD, dE, dF, dG, parsedL, ln;
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
	// §120: the GRANULAR FREEZE — the cloud from 80 ms, grains of 200 ms at 40/s, under a tail capped 1.5 s past the source: it must be
	// SOUNDING a second in (the source is over at 0.35 s), and it never falls — so it is cut at the cap
	~le.processRender((source: 't-src', out: 't-src~9', effect: 'cloud', args: 'gfMix:1,gfAtMs:80,gfDur:200,gfDens:40,gfSpread:20,gfPitch:0', end: 'tail', capMs: 1500, id: 'test-9'));
	r9 = waitFor.("t-src~9");
	check.("~9 granular freeze · tail", r9.notNil and: { File.exists(tmp +/+ "t-src~9.wav") }, if(r9.notNil) { r9[\lengthMs].asString ++ " ms · peak " ++ r9[\peakDb] ++ " dB" } { "no row" });
	if(r9.notNil) {
		f9 = SoundFile.new;
		if(f9.openRead(tmp +/+ "t-src~9.wav")) { d9 = FloatArray.newClear(f9.numFrames); f9.readData(d9); f9.close };
		gfHeld = if(d9.notNil and: { d9.size > (1.1 * sr) }) { (d9.copyRange((0.6 * sr).asInteger, (1.1 * sr).asInteger).abs.maxItem / d9.abs.maxItem).ampdb.round(0.1) } { -999 };
		check.("~9 the cloud holds and is cut at the cap", (gfHeld > -20) and: { r9[\lengthMs] > 1500 } and: { r9[\lengthMs] < 1900 },
			"0.6 … 1.1 s into it, " ++ gfHeld ++ " dB under its peak (the source ended at 0.35 s) · " ++ r9[\lengthMs] ++ " ms long, the cap 1500 past the source");
	};
	// §122: ICY — his Warp1 freeze: the read point crawls from 60 ms at 0.03 of real time, 0.6 s windows, 17 grains, his expodec window
	// (buffer 4 of the ten the render loads) — it must be SOUNDING a second in, and be cut at the cap
	~le.processRender((source: 't-src', out: 't-src~10', effect: 'icy', args: 'icMix:1,icSpeed:0.03,icFromMs:60,icWin:0.6,icOverlaps:17,icRand:0.2,icPitch:0,icEnv:4', end: 'tail', capMs: 1500, id: 'test-10'));
	r10 = waitFor.("t-src~10");
	check.("~10 icy · tail", r10.notNil and: { File.exists(tmp +/+ "t-src~10.wav") }, if(r10.notNil) { r10[\lengthMs].asString ++ " ms · peak " ++ r10[\peakDb] ++ " dB" } { "no row" });
	if(r10.notNil) {
		f10 = SoundFile.new;
		if(f10.openRead(tmp +/+ "t-src~10.wav")) { d10 = FloatArray.newClear(f10.numFrames); f10.readData(d10); f10.close };
		icHeld = if(d10.notNil and: { d10.size > (1.1 * sr) }) { (d10.copyRange((0.6 * sr).asInteger, (1.1 * sr).asInteger).abs.maxItem / d10.abs.maxItem).ampdb.round(0.1) } { -999 };
		check.("~10 icy stretches past its source and is cut at the cap", (icHeld > -20) and: { r10[\lengthMs] > 1500 } and: { r10[\lengthMs] < 1900 },
			"0.6 … 1.1 s into it, " ++ icHeld ++ " dB under its peak (the source ended at 0.35 s) · " ++ r10[\lengthMs] ++ " ms long, the cap 1500 past the source");
	};
	// DEC-34b (the Decibel piece's §169 · §171): THE LOOP — icLoop 1: the read point wraps at the source's end and reads it again from 0;
	// icLoop 0 holds at the end. At half speed over a 0.35 s source the point wraps every 0.7 s: a second in, the looping render is still
	// revisiting the burst while the holding one sits on the source's dying end (−31 dB under its peak by then). Both cut at the cap.
	~le.processRender((source: 't-src', out: 't-src~14', effect: 'icy', args: 'icMix:1,icSpeed:0.5,icFromMs:0,icWin:0.1,icOverlaps:8,icRand:0.1,icPitch:0,icEnv:4,icLoop:1', end: 'tail', capMs: 1500, id: 'test-14'));
	~le.processRender((source: 't-src', out: 't-src~15', effect: 'icy', args: 'icMix:1,icSpeed:0.5,icFromMs:0,icWin:0.1,icOverlaps:8,icRand:0.1,icPitch:0,icEnv:4,icLoop:0', end: 'tail', capMs: 1500, id: 'test-15'));
	r14 = waitFor.("t-src~14"); r15 = waitFor.("t-src~15");
	lateOf = { |name| var f = SoundFile.new, d; if(f.openRead(tmp +/+ name)) { d = FloatArray.newClear(f.numFrames); f.readData(d); f.close };
		if(d.notNil and: { d.size > (1.4 * sr) }) { (d.copyRange((1.0 * sr).asInteger, (1.4 * sr).asInteger).abs.maxItem / d.abs.maxItem).ampdb.round(0.1) } { -999 } };
	lpLate = if(r14.notNil) { lateOf.("t-src~14.wav") } { -999 }; hdLate = if(r15.notNil) { lateOf.("t-src~15.wav") } { -999 };
	// the holding render sits on the source's dying end, so its tail falls under −60 dB and the render ENDS before 1.4 s (lateOf gives −999 then)
	check.("~14 icy LOOPS: a second in it is still reading the burst; ~15 holds at the end and dies", r14.notNil and: { r15.notNil } and: { lpLate > -18 } and: { (hdLate == -999) or: { (lpLate - hdLate) > 8 } } and: { r14[\lengthMs] > 1500 } and: { r14[\lengthMs] < 1900 },
		"1.0 … 1.4 s into it: looping " ++ lpLate ++ " dB under its peak · holding " ++ if(hdLate == -999) { "over at " ++ lenOf.(r15) ++ " ms — its tail died at the source's end" } { hdLate.asString ++ " dB" } ++ " · the looping render " ++ lenOf.(r14) ++ " ms long (the cap 1500 past the source)");
	// DEC-32 (the Decibel piece's §151): HIS PETALS OF RESONANCE, twice — the original (his SynthDef UGen for UGen: 26 DynKlanks, the
	// limiter, his fade) and the cleaned path (one bank of 26 Ringz, the draws per render) — fund 110 (partials on the source's 330 and
	// 660), a ring of 1 … 2 s, a cap of 5 s past the source: each must RING well past its source (over at 0.35 s) and die before the cap
	tP = Main.elapsedTime;
	~le.processRender((source: 't-src', out: 't-src~11', effect: 'petalsOrig', args: 'poMix:1,poFund:110,poFirst:2,poSpread:1,poOffset:3,poRingLo:1,poRingHi:2,poInLen:1', end: 'tail', capMs: 5000, id: 'test-11'));
	~le.processRender((source: 't-src', out: 't-src~12', effect: 'petals', args: 'ptMix:1,ptFund:110,ptFirst:2,ptSpread:1,ptOffset:3,ptRingLo:1,ptRingHi:2,ptInLen:1', end: 'tail', capMs: 5000, id: 'test-12'));
	r11 = waitFor.("t-src~11", 120);
	r12 = waitFor.("t-src~12", 120);
	tP = (Main.elapsedTime - tP).round(0.1);
	check.("~11 petals, his original · tail", r11.notNil and: { File.exists(tmp +/+ "t-src~11.wav") }, if(r11.notNil) { r11[\lengthMs].asString ++ " ms · peak " ++ r11[\peakDb] ++ " dB" } { "no row" });
	check.("~12 petals, the cleaned path · tail", r12.notNil and: { File.exists(tmp +/+ "t-src~12.wav") }, if(r12.notNil) { r12[\lengthMs].asString ++ " ms · peak " ++ r12[\peakDb] ++ " dB" } { "no row" });
	if(r11.notNil and: { r12.notNil }) {
		check.("the petals ring past their source and die before the cap", (r11[\lengthMs] > 1000) and: { r11[\lengthMs] < 5000 } and: { r12[\lengthMs] > 1000 } and: { r12[\lengthMs] < 5000 },
			"the source 300 ms, the ring 1 … 2 s, the cap 5000 — the original " ++ r11[\lengthMs] ++ " ms · the cleaned " ++ r12[\lengthMs] ++ " ms · the two renders of 5.35 s, side by side, took " ++ tP ++ " s");
	};
	// DEC-40 (the Decibel piece's §203, 2026-10-07): THE LOOP AROUND THE PETALS (poBloom > 0) — the bank of ~11 (ring 1 … 2 s), the loop
	// set to lift it 60 dB in a QUARTER SECOND (a loop gain of 7: a break to a quarter of it would still be above unity — the break must
	// go to nothing, §204), held 2 s, the amp at drive 6: at 1.5 … 2 s it must be HELD within 6 dB of its peak (the bare ~11 has
	// fallen 40 dB by then), at 3.5 … 4 s (the loop broken at 2 s) it must be at least 6 dB further down, and it must die before the cap.
	// The profile (RMS per 500 ms) is printed: the bloom's constant is read from it, not asserted.
	~le.processRender((source: 't-src', out: 't-src~16', effect: 'petalsOrig', args: 'poMix:1,poFund:110,poFirst:2,poSpread:1,poOffset:3,poRingLo:1,poRingHi:2,poInLen:1,poBloom:0.25,poDrive:6,poHold:2', end: 'tail', capMs: 8000, id: 'test-16'));
	r16 = waitFor.("t-src~16", 120);
	check.("~16 petals with the loop around them · tail", r16.notNil and: { File.exists(tmp +/+ "t-src~16.wav") }, if(r16.notNil) { r16[\lengthMs].asString ++ " ms · peak " ++ r16[\peakDb] ++ " dB" } { "no row" });
	if(r16.notNil) {
		f16 = SoundFile.new;
		if(f16.openRead(tmp +/+ "t-src~16.wav")) { d16 = FloatArray.newClear(f16.numFrames); f16.readData(d16); f16.close };
		if(d16.notNil and: { d16.size > (4.0 * sr) }) {
			poPk = d16.abs.maxItem;
			poHeld = (d16.copyRange((1.5 * sr).asInteger, (2.0 * sr).asInteger).abs.maxItem / poPk).ampdb.round(0.1);
			poLate = (d16.copyRange((3.5 * sr).asInteger, (4.0 * sr).asInteger).abs.maxItem / poPk).ampdb.round(0.1);
			poProf = (d16.size / (0.5 * sr)).floor.asInteger.collect({ |k| var seg = d16.copyRange((k * 0.5 * sr).asInteger, (((k + 1) * 0.5 * sr).asInteger - 1).min(d16.size - 1)); (seg.squared.sum / seg.size.max(1)).sqrt.max(1e-9).ampdb.round(1) });
		} { poHeld = -999; poLate = -999; poProf = [] };
		check.("~16 the loop HOLDS the ring (1.5 … 2 s within 6 dB of the peak), is broken at 2 s, and the ring dies before the cap", (poHeld > -6) and: { poLate < (poHeld - 6) } and: { r16[\lengthMs] > 2500 } and: { r16[\lengthMs] < 8000 },
			"1.5 … 2.0 s: " ++ poHeld ++ " dB under the peak · 3.5 … 4.0 s: " ++ poLate ++ " dB · " ++ r16[\lengthMs] ++ " ms long · RMS per 500 ms: " ++ poProf);
	};
	// DEC-40 (§203): THE FEEDBACK'S STRINGS AS RINGING PARTIALS (fbRes 1), twice: ~17 in the ONE loop (fbOwn 0) on a LOW chord — E2 · F2 ·
	// A2, every string under the comb loop's 120 Hz high-pass, which killed such partials each round trip (§204: B1 · C#2 never bloomed;
	// 20 Hz for partials now); the source's 330 Hz burst touches them only by its onset — as partials they must take off from that and HOLD
	// (0.9 … 1.4 s within 6 dB of its peak); which pitches survive is PRINTED (a shared amp lets the strongest win, as a guitar's does);
	// the level at 0.3 … 0.5 s is printed too (a right normalization is still blooming there; a wrong one is at the ceiling already).
	// ~18 with EACH STRING SINGING (fbOwn 1) — all three partials must hold within 12 dB of the strongest, as ~13's combs did.
	~le.processRender((source: 't-src', out: 't-src~17', effect: 'feedback', args: 'fbMix:1,fbOwn:0,fbRes:1,fbRing:1.5,fbBloom:0.5,fbHold:1.5,fbDrive:4,fbS1:82.41,fbS2:87.31,fbS3:110,fbS4:0,fbS5:0,fbS6:0', end: 'tail', capMs: 5000, id: 'test-17'));
	~le.processRender((source: 't-src', out: 't-src~18', effect: 'feedback', args: 'fbMix:1,fbOwn:1,fbRes:1,fbRing:1.5,fbBloom:0.5,fbHold:1.5,fbDrive:4,fbS1:329.63,fbS2:369.99,fbS3:440,fbS4:0,fbS5:0,fbS6:0', end: 'tail', capMs: 5000, id: 'test-18'));
	r17 = waitFor.("t-src~17", 60);
	r18 = waitFor.("t-src~18", 60);
	goertzel = { |data, f, from, len|
		var c = 2 * cos(2pi * f / sr), s0 = 0, s1 = 0, s2 = 0;
		len.do({ |k| s0 = data[from + k] + (c * s1) - s2; s2 = s1; s1 = s0 });
		((s1 * s1) + (s2 * s2) - (c * s1 * s2)).max(1e-30).sqrt.ampdb
	};
	[[r17, "t-src~17", "one loop", [82.41, 87.31, 110]], [r18, "t-src~18", "each string sings", [329.63, 369.99, 440]]].do({ |row|
		var r = row[0], nm = row[1], what = row[2], pitches = row[3], f, d, held, early, tones;
		check.(nm.copyRange(5, 20) ++ " feedback, the strings as partials, " ++ what ++ " · tail", r.notNil and: { File.exists(tmp +/+ (nm ++ ".wav")) }, if(r.notNil) { r[\lengthMs].asString ++ " ms · peak " ++ r[\peakDb] ++ " dB" } { "no row" });
		if(r.notNil) {
			f = SoundFile.new;
			if(f.openRead(tmp +/+ (nm ++ ".wav"))) { d = FloatArray.newClear(f.numFrames); f.readData(d); f.close };
			if(d.notNil and: { d.size > (1.5 * sr) }) {
				held = (d.copyRange((0.9 * sr).asInteger, (1.4 * sr).asInteger).abs.maxItem / d.abs.maxItem).ampdb.round(0.1);
				early = (d.copyRange((0.3 * sr).asInteger, (0.5 * sr).asInteger).abs.maxItem / d.abs.maxItem).ampdb.round(0.1);
				tones = pitches.collect({ |fq| goertzel.(d, fq, (0.9 * sr).asInteger, (0.5 * sr).asInteger) });
				tones = (tones - tones.maxItem).round(0.1);
			} { held = -999; early = -999; tones = [-999, -999, -999] };
			if(what == "one loop") {
				check.("~17 the partials in the one loop take off and hold, then die", (held > -6) and: { r[\lengthMs] > 1500 } and: { r[\lengthMs] < 4800 },
					"0.9 … 1.4 s: " ++ held ++ " dB under the peak · 0.3 … 0.5 s: " ++ early ++ " dB (still blooming if well under) · E2 F2 A2 against the strongest: " ++ tones ++ " dB (the winner is the guitar's) · " ++ r[\lengthMs] ++ " ms");
			} {
				check.("~18 each partial sings: the chord holds, all three in it, then it dies", (held > -6) and: { tones.minItem > -12 } and: { r[\lengthMs] > 1500 } and: { r[\lengthMs] < 4800 },
					"0.9 … 1.4 s: " ++ held ++ " dB under the peak · E4 F#4 A4 against the strongest: " ++ tones ++ " dB · " ++ r[\lengthMs] ++ " ms");
			};
		};
	});
	// DEC-32 (§151): EVERY STRING SINGS (fbOwn 1) — a chord whose notes share no harmonic: E4 (on the source's 330) · F#4 · A4 (both
	// barely touched by it). In the loop of ~7 none of it would bloom; here the chord must HOLD at its peak a second in, EACH of the
	// three pitches must be in it (a Goertzel on each, 0.9 … 1.4 s: the weakest within 12 dB of the strongest), and it must ring down
	~le.processRender((source: 't-src', out: 't-src~13', effect: 'feedback', args: 'fbMix:1,fbOwn:1,fbBloom:0.5,fbHold:1.5,fbDrive:4,fbS1:329.63,fbS2:369.99,fbS3:440,fbS4:0,fbS5:0,fbS6:0', end: 'tail', capMs: 5000, id: 'test-13'));
	r13 = waitFor.("t-src~13", 60);
	check.("~13 feedback, every string sings · tail", r13.notNil and: { File.exists(tmp +/+ "t-src~13.wav") }, if(r13.notNil) { r13[\lengthMs].asString ++ " ms · peak " ++ r13[\peakDb] ++ " dB" } { "no row" });
	if(r13.notNil) {
		f13 = SoundFile.new;
		if(f13.openRead(tmp +/+ "t-src~13.wav")) { d13 = FloatArray.newClear(f13.numFrames); f13.readData(d13); f13.close };
		if(d13.notNil and: { d13.size > (1.5 * sr) }) {
			own = (d13.copyRange((0.9 * sr).asInteger, (1.4 * sr).asInteger).abs.maxItem / d13.abs.maxItem).ampdb.round(0.1);
			tones = [329.63, 369.99, 440].collect({ |f|
				var c = 2 * cos(2pi * f / sr), s0 = 0, s1 = 0, s2 = 0, from = (0.9 * sr).asInteger;
				(0.5 * sr).asInteger.do({ |k| s0 = d13[from + k] + (c * s1) - s2; s2 = s1; s1 = s0 });
				((s1 * s1) + (s2 * s2) - (c * s1 * s2)).max(1e-30).sqrt.ampdb
			});
			tones = (tones - tones.maxItem).round(0.1);
		} { own = -999; tones = [-999, -999, -999] };
		check.("~13 the chord holds, all three strings in it, then it dies", (own > -6) and: { tones.minItem > -12 } and: { r13[\lengthMs] > 1500 } and: { r13[\lengthMs] < 4800 },
			"0.9 … 1.4 s into it, " ++ own ++ " dB under its peak · E4 · F#4 · A4 at " ++ tones ++ " dB of the strongest · " ++ r13[\lengthMs] ++ " ms long (the hold 1.5 s, the cap 5000)");
	};
	~le.indexWrite;   // §228: a render's banking no longer writes the index at once (one breathing write 2 s after the last change) — flushed here as leave does
	check.("the index on disk holds the eighteen", ~le.indexRowsOf(tmp).size == 18, ~le.indexRowsOf(tmp).collect({ |r| r[\name] }).join(" · "));
	// what a chain's "*" plays: every CAPTURED sample — a render does not join it (bank.scd chainNames)
	~le[\samples].put('t-src', (row: (name: "t-src")));
	if(r1.notNil) { ~le[\samples].put('t-src~1', (row: r1)) };
	check.("\"*\" is every CAPTURED sample", ~le.chainNames("*") == ["t-src"], "of t-src and t-src~1 it plays " ++ ~le.chainNames("*"));
	// THE PLAN (the Decibel piece's 10.8 · DEC-21 · 22, §116): three variants of t-src as a score's page sends them — in TWO parts, the
	// second FIRST (the order of arrival must not matter); then planRender, as a capture's end calls it. Three for a queue two wide: the
	// third waits for a slot. Their lengths are multiples of the source's 350 ms — 1.0 · 1.75 · and 1.0 of a tape at half speed (700).
	~le.planTake((stamp: 'pt1', part: 2, of: 2, rows: 't-src;x3-tri;tape;tri;0;1;1;12;0;rate:0.5,rev:0'));
	check.("a plan waits for all its parts", ~le[\plan].isNil, "part 2 of 2 alone: " ++ if(~le[\plan].isNil) { "no plan yet" } { "a plan of " ++ ~le[\plan].size });
	~le.planTake((stamp: 'pt1', part: 1, of: 2,
		rows: 't-src;x2-expodec;diffusion;expodec;0;1.75;1;9.5;0;diffMix:1,diffTime:0.02,diffGain:0.55|t-src;x1-perc;crush;perc;3;1;1;6.2;0;crMix:0.4,crBits:4,crRate:10400'));
	check.("the plan is whole, the soonest-needed first", ~le[\plan].notNil and: { ~le[\plan].size == 3 } and: { ~le[\plan][0][\suffix] == "x1-perc" } and: { ~le[\plan][2][\suffix] == "x3-tri" },
		if(~le[\plan].notNil) { ~le[\plan].collect({ |r| r[\suffix] ++ " at " ++ r[\t] }).join(" · ") } { "no plan" });
	~le.planRender("t-src");
	check.("the queue is two wide", (~le[\processBusy].size == 2) and: { ~le[\planQueue].size == 1 }, ~le[\processBusy].size.asString ++ " rendering · " ++ ~le[\planQueue].size ++ " waiting");
	p1 = waitFor.("t-src~x1-perc");
	p2 = waitFor.("t-src~x2-expodec");
	p3 = waitFor.("t-src~x3-tri");
	check.("the three variants are banked under their names", p1.notNil and: { p2.notNil } and: { p3.notNil } and: { File.exists(tmp +/+ "t-src~x1-perc.wav") },
		[p1, p2, p3].collect({ |r| if(r.notNil) { r[\name].asString ++ " " ++ r[\lengthMs] ++ " ms" } { "no row" } }).join(" · "));
	check.("their lengths are multiples of the source's", ((lenOf.(p1) - 350).abs < 0.5) and: { (lenOf.(p2) - 612.5).abs < 0.5 } and: { (lenOf.(p3) - 700).abs < 0.5 },
		"350 · 612.5 · 700 asked — " ++ lenOf.(p1) ++ " · " ++ lenOf.(p2) ++ " · " ++ lenOf.(p3) ++ " made");
	if(p1.notNil) { check.("a variant's row says what it is", (p1[\planned] == 1) and: { p1[\kind].asString == "processed" } and: { p1[\source].asString == "t-src" } and: { p1[\end].asString == "perc" },
		"planned " ++ p1[\planned] ++ " · kind " ++ p1[\kind] ++ " · source " ++ p1[\source] ++ " · end " ++ p1[\end]) };
	// the fallback: a variant with no buffer plays its base, raw (t-src stands in the samples since the "*" check above)
	fb = ~le.sampleFor("t-src~nope-perc");
	check.("a variant not rendered yet falls back to its base", fb.notNil and: { fb[\row][\name].asString == "t-src" }, if(fb.notNil) { "t-src~nope-perc plays " ++ fb[\row][\name] } { "nothing" });
	check.("a name that is nobody's variant plays nothing", ~le.sampleFor("no-such~x-perc").isNil and: { ~le.sampleFor("no-such").isNil }, "no-such~x-perc · no-such");
	// THE DRIVE (the Decibel piece's PLAN 1.4 · 11.4): the same stage from a LOUD source and a QUIET one — a copy of the source 20 dB
	// down, banked beside it. NORMALIZED: the feedback is hit as hard either way, and the two renders come out as loud as each other
	// (match 0: the level the chain itself made). PLAYED, through a linear stage (the comb): they differ by the sources' own 20 dB.
	~le.wavWrite(tmp +/+ "t-q.wav", FloatArray.fill(src.size, { |i| src[i] * 0.1 }), sr);
	[["t-src", "dn1"], ["t-q", "dn2"]].do({ |p| ~le.processRender((source: p[0], out: p[0] ++ "~" ++ p[1], effect: 'feedback', args: 'fbMix:1,fbBloom:0.3,fbHold:1,fbDrive:6',
		end: 'tail', capMs: 4000, match: 0, srcDrive: "normalized", id: "test-" ++ p[1])) });
	dA = waitFor.("t-src~dn1"); dB = waitFor.("t-q~dn2");
	check.("the drive, NORMALIZED: the feedback speaks alike from a loud source and a quiet one", dA.notNil and: { dB.notNil } and: { dA[\loudDb].notNil } and: { (dA[\loudDb] - dB[\loudDb]).abs < 1 },
		if(dA.notNil and: { dB.notNil }) { "from the loud " ++ dA[\loudDb] ++ " LUFS (" ++ dA[\drive] ++ ") · from the quiet " ++ dB[\loudDb] ++ " LUFS (" ++ dB[\drive] ++ ")" } { "no rows" });
	[["t-src", "dp1"], ["t-q", "dp2"]].do({ |p| ~le.processRender((source: p[0], out: p[0] ++ "~" ++ p[1], effect: 'comb', args: 'combMix:1,combTime:0.012,combFb:0.5',
		end: 'shape', atkMs: 2, durMs: 600, relMs: 600, curve: -4, match: 0, srcDrive: "played", id: "test-" ++ p[1])) });
	dC = waitFor.("t-src~dp1"); dD = waitFor.("t-q~dp2");
	check.("the drive, AS PLAYED: through a linear stage the renders keep the sources' 20 dB", dC.notNil and: { dD.notNil } and: { ((dC[\loudDb] - dD[\loudDb]) - 20).abs < 1 },
		if(dC.notNil and: { dD.notNil }) { "from the loud " ++ dC[\loudDb] ++ " · from the quiet " ++ dD[\loudDb] ++ " LUFS (" ++ (dD[\drive] ? "as played: nothing in its row") ++ ")" } { "no rows" });
	~le.processRender((source: 't-q', out: 't-q~db1', effect: 'comb', args: 'combMix:1,combTime:0.012,combFb:0.5', end: 'shape', atkMs: 2, durMs: 600, relMs: 600, curve: -4, match: 0, srcDrive: "+12", id: 'test-db1'));
	dE = waitFor.("t-q~db1");
	check.("the drive, a BOOST: +12 dB in, +12 dB out of a linear stage", dE.notNil and: { dD.notNil } and: { ((dE[\loudDb] - dD[\loudDb]) - 12).abs < 1 },
		if(dE.notNil and: { dD.notNil }) { dD[\loudDb].asString ++ " → " ++ dE[\loudDb] ++ " LUFS (" ++ dE[\drive] ++ ")" } { "no rows" });
	// measured, not asserted: what the FEEDBACK does with the two sources as played (a loop that saturates need not keep their difference)
	[["t-src", "df1"], ["t-q", "df2"]].do({ |p| ~le.processRender((source: p[0], out: p[0] ++ "~" ++ p[1], effect: 'feedback', args: 'fbMix:1,fbBloom:0.3,fbHold:1,fbDrive:6',
		end: 'tail', capMs: 4000, match: 0, srcDrive: "played", id: "test-" ++ p[1])) });
	dF = waitFor.("t-src~df1"); dG = waitFor.("t-q~df2");
	("  note the feedback AS PLAYED (measured, not a check) — from the loud " ++ if(dF.notNil) { dF[\loudDb].asString ++ " LUFS · " ++ dF[\lengthMs] ++ " ms" } { "no render" }
		++ " · from the quiet " ++ if(dG.notNil) { dG[\loudDb].asString ++ " LUFS · " ++ dG[\lengthMs] ++ " ms" } { "no render" }).postln;
	if(p1.notNil) { check.("a plan's variant that names no drive is driven normalized", (p1[\drive] ? "").asString.beginsWith("normalized"), (p1[\drive] ? "no drive in its row").asString) };
	// A DIAL AS A LINE: value@ms breakpoints. Read: the dial's start is its first value, the rest are its steps. Rendered: the reverb's
	// OUTPUT taken from 1 to 0 over 300 ms — the tail that rang 1.6 s (~2 above) is over well inside one
	parsedL = ~le.processArgs("fbDrive:2@0,8@6000,fbMix:1,noSuch:3@0,4@9,revMix:0.6");
	check.("a dial as a line is read", (parsedL[\args] == [\fbDrive, 2.0, \fbMix, 1.0, \revMix, 0.6]) and: { parsedL[\lines].size == 1 } and: { parsedL[\lines][0][\pts].asArray == [[2.0, 0.0], [8.0, 6000.0]] } and: { parsedL[\unknown] == [\noSuch] },
		parsedL[\args].asString ++ " · the line " ++ parsedL[\lines].collect({ |l| l[\key].asString ++ " " ++ l[\pts].asArray }).asString ++ " · unknown " ++ parsedL[\unknown]);
	~le.processRender((source: 't-src', out: 't-src~ln', effect: 'reverb', args: 'revMix:0.6,revTime:1.5,amp:1@0,0@300', end: 'tail', capMs: 6000, id: 'test-ln'));
	ln = waitFor.("t-src~ln");
	check.("a dial as a line is played: the reverb's level drawn down to nothing in 300 ms ends its tail", ln.notNil and: { r2.notNil } and: { ln[\lengthMs] < 700 } and: { ln[\args].asString.contains("amp:1.0@0,0.0@300") },
		if(ln.notNil) { ln[\lengthMs].asString ++ " ms (the same reverb left alone: " ++ lenOf.(r2) ++ " ms) · args " ++ ln[\args] } { "no row" });
	// a pass leaves nothing behind; a failure keeps the scratch bank to be looked at
	if(fails.size == 0) { try { File.deleteAll(tmp) }; "PROCESS_TEST PASS".postln; 0.exit } { ("PROCESS_TEST FAIL — " ++ fails.join(" · ")).postln; 1.exit };
};
)
