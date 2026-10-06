// sine_test.scd — THE GENERATED SINE, OFFLINE (the Decibel piece's PLAN 1.5 · 12.1, 2026-10-06): sine.scd's figures in a bare
// sclang, and \leSine played by a second scsynth with no device and no port (NRT) into files, the files measured. No server of
// the engine's is asked anything: a living engine beside it is untouched, and nothing sounds.
//   THE FIGURES   the K-weighting's gain at 1 kHz is the standard's +0.69 dB, so a sine at fff peaks AT the reference there ·
//                 a message's fields become the two lines as \leSine takes them (8 levels, 7 times; a name, a number, a line)
//   THE PITCH     a 3 s sine on A3 gliding −50 → 0 cents: its frequency, read from the file's zero crossings early and late,
//                 lies on the line
//   THE LEVEL     its level pp+ … ff: half way up the ramp it is half way IN DECIBELS; held at ff it reads ff — by the same
//                 measure the bank's samples are read with (level.scd loudOf), and its peak is the formula's
//   THE SHELF     a sine two octaves above a crotale's lowest (C7, 2093 Hz) written mf reads mf: the K-weighting is counted
//   THE STOP      a sine told to let go is silent a tenth of a second later
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/sine_test.scd
// It ends SINE_TEST PASS (exit 0) or SINE_TEST FAIL (exit 1) and names each check.
(
var dir = thisProcess.nowExecutingPath.dirname;
var tmp = Platform.defaultTempDir +/+ "le_sine_test_" ++ Date.localtime.stamp;
var sr = 44100, fails = List.new, check, near, db, defs, render, pk, freqAt, slice, cents;
(dir +/+ "boot.scd").load;
~le[\sr] = sr;
(dir +/+ "synths.scd").load;   // no server: the SynthDefs are built, and kept in the library
File.mkdir(tmp);
check = { |what, ok, detail| ("  " ++ if(ok) { "ok   " } { "FAIL " } ++ what ++ " — " ++ detail).postln; if(ok.not) { fails.add(what) } };
near = { |a, b, tol| a.notNil and: { (a - b).abs <= tol } };
db = { |x| if(x > 0) { x.ampdb.round(0.01) } { -200 } };
defs = [\leSine].collect({ |n| [0.0, ['/d_recv', SynthDescLib.global[n].def.asBytes]] });
render = { |name, msgs, dur, chans = 2|
	var osc = tmp +/+ name ++ ".osc", wav = tmp +/+ name ++ ".wav", done = false, sf, data, frames, opts;
	opts = ServerOptions.new.numOutputBusChannels_(chans).numInputBusChannels_(2).numAudioBusChannels_(64).memSize_(65536);
	Score(defs ++ msgs ++ [[dur, ['/c_set', 0, 0]]]).recordNRT(osc, wav, nil, sr, "WAV", "float", opts, "", nil, { done = true });
	while { done.not } { 0.05.wait };
	sf = SoundFile.new;
	if(File.exists(wav) and: { sf.openRead(wav) }) { data = FloatArray.newClear(sf.numFrames * sf.numChannels); sf.readData(data); frames = sf.numFrames; sf.close };
	if(data.isNil) { nil } { chans.collect({ |c| FloatArray.fill(frames, { |i| data[(i * chans) + c] }) }) }
};
pk = { |x, from, to| var a = (from * sr).asInteger, b = ((to * sr).asInteger - 1).min(x.size - 1), m = 0; (a..b).do({ |i| m = max(m, x[i].abs) }); m };
slice = { |x, from, to| x.copyRange((from * sr).asInteger, ((to * sr).asInteger - 1).min(x.size - 1)) };
// the mean frequency over `win` seconds around t: the upward zero crossings, each placed between its two samples
freqAt = { |x, t, win = 0.1|
	var a = ((t - (win / 2)) * sr).asInteger, b = ((t + (win / 2)) * sr).asInteger, first, last, n = 0, z;
	(a..(b - 1)).do({ |i|
		if((x[i] < 0) and: { x[i + 1] >= 0 }) {
			z = i + (x[i].neg / (x[i + 1] - x[i]));
			if(first.isNil) { first = z } { n = n + 1 };
			last = z;
		};
	});
	if(n > 0) { n * sr / (last - first) } { 0 }
};
cents = { |f, ref| 1200 * log2(f / ref) };
fork {
	var sp, flat, r, t0 = 0.05, f1, f2, c1, c2, e1, e2, mid, held, loud, k1, k2;
	("SINE_TEST the scratch folder: " ++ tmp).postln;

	"SINE_TEST the figures:".postln;
	k1 = ~le.kGainDb(1000, 48000);
	check.("the K-weighting's gain at 1 kHz is the standard's", near.(k1, 0.691, 0.02), k1.round(0.001).asString ++ " dB (the standard: +0.691) · at 220 Hz " ++ ~le.kGainDb(220).round(0.01) ++ " · at 2093 Hz " ++ ~le.kGainDb(2093).round(0.01) ++ " · at 4186 Hz " ++ ~le.kGainDb(4186).round(0.01));
	check.("a sine written fff at 1 kHz peaks AT the ladder's reference", near.(~le.sineGain(1000, 7), ~le.levelOf[\reference], 0.03) and: { near.(~le.sineGain(1000, 4), ~le.levelOf[\reference] - 12, 0.03) },
		"fff " ++ ~le.sineGain(1000, 7).round(0.01) ++ " dBFS (the reference " ++ ~le.levelOf[\reference] ++ " LUFS) · mf " ++ ~le.sineGain(1000, 4).round(0.01));
	sp = ~le.sineSpec((midi: 57, lengthMs: 3000, level: "0:1.5,2000:ff", gliss: "0:-50,end:0"));
	check.("a message's lines become \\leSine's: 8 levels, 7 times, the last value held",
		near.(sp[\freq], 220, 0.001) and: { sp[\envDb].size == 8 } and: { sp[\envDt].size == 7 } and: { near.(sp[\envDb][0], ~le.sineGain(220, 1.5), 1e-6) }
			and: { near.(sp[\envDb][1], ~le.sineGain(220, 6), 1e-6) } and: { sp[\envDb][7] == sp[\envDb][1] } and: { near.(sp[\envDt][0], 2, 1e-6) }
			and: { sp[\glissCents].keep(2) == [-50.0, 0.0] } and: { near.(sp[\glissDt][0], 3, 1e-6) },
		~le.sineSaid(sp) ++ " · envDb " ++ sp[\envDb].keep(3).round(0.01) ++ " … · envDt " ++ sp[\envDt].keep(2).round(0.001) ++ " … · gliss over " ++ sp[\glissDt][0] ++ " s");
	flat = ~le.sineSpec((midi: 60.25, lengthMs: 1000, level: "mf"));
	check.("a bare mark is a flat level; a pitch carries its cents; nothing said is mf and no glide",
		flat[\envDb].every({ |x| x == flat[\envDb][0] }) and: { near.(flat[\freq], 60.midicps * (2 ** (25 / 1200)), 0.001) } and: { flat[\glissCents].every({ |x| x == 0 }) }
			and: { ~le.sineSpec((midi: 60, lengthMs: 1000))[\envDb][0] == ~le.sineGain(60.midicps, 4) } and: { ~le.markNum("pp") == 1 } and: { ~le.markNum("5.5") == 5.5 },
		~le.sineSaid(flat));

	"SINE_TEST the pitch and the level, as sound:".postln;
	r = render.("a", [[t0, ['/s_new', \leSine, 1000, 0, 0, \out, 0] ++ ~le.sineArgs(sp).asOSCArgArray]], 3.3);
	f1 = freqAt.(r[0], t0 + 0.2); f2 = freqAt.(r[0], t0 + 2.8);
	c1 = cents.(f1, 220); c2 = cents.(f2, 220); e1 = -50 + (50 * 0.2 / 3); e2 = -50 + (50 * 2.8 / 3);
	check.("the glide −50 → 0 cents over 3 s: the frequency lies on the line, early and late", near.(c1, e1, 0.5) and: { near.(c2, e2, 0.5) },
		"at 0.2 s " ++ f1.round(0.001) ++ " Hz = " ++ c1.round(0.01) ++ " c (the line " ++ e1.round(0.01) ++ ") · at 2.8 s " ++ f2.round(0.001) ++ " Hz = " ++ c2.round(0.01) ++ " c (the line " ++ e2.round(0.01) ++ ")");
	mid = db.(pk.(r[0], t0 + 0.99, t0 + 1.01)); held = db.(pk.(r[0], t0 + 2.3, t0 + 2.9));
	check.("the level's ramp is joined in decibels: half way up it is half way", near.(mid, (sp[\envDb][0] + sp[\envDb][1]) / 2, 0.3),
		"at 1 s of 2 its peak " ++ mid ++ " dB (from " ++ sp[\envDb][0].round(0.01) ++ " to " ++ sp[\envDb][1].round(0.01) ++ ": half way " ++ ((sp[\envDb][0] + sp[\envDb][1]) / 2).round(0.01) ++ ")");
	loud = ~le.loudOf(slice.(r[0], t0 + 2.3, t0 + 2.9), sr)[\loudDb];
	check.("held at ff it READS ff, by the measure the bank's samples are read with — and its peak is the formula's", near.(loud, ~le.markDb(\ff), 0.3) and: { near.(held, sp[\envDb][1], 0.05) },
		loud.asString ++ " LUFS (ff = " ++ ~le.markDb(\ff).round(0.01) ++ ") · peak " ++ held ++ " dB (the formula " ++ sp[\envDb][1].round(0.01) ++ ")");
	check.("it is on both channels alike, and silent once its length is over", (r[0] == r[1]) and: { pk.(r[0], t0 + 3.01, 3.25) == 0 }, "the two channels the same samples · after 3 s the loudest sample " ++ pk.(r[0], t0 + 3.01, 3.25));

	"SINE_TEST the shelf:".postln;
	sp = ~le.sineSpec((midi: 96, lengthMs: 1200, level: "mf"));
	r = render.("b", [[t0, ['/s_new', \leSine, 1000, 0, 0, \out, 0] ++ ~le.sineArgs(sp).asOSCArgArray]], 1.4);
	loud = ~le.loudOf(slice.(r[0], t0 + 0.3, t0 + 0.9), sr)[\loudDb]; k2 = ~le.kGainDb(sp[\freq]);
	check.("a sine at C7 written mf reads mf: the K-weighting's shelf is counted", near.(loud, ~le.markDb(\mf), 0.3) and: { near.(freqAt.(r[0], t0 + 0.6), sp[\freq], 0.05) },
		loud.asString ++ " LUFS (mf = " ++ ~le.markDb(\mf).round(0.01) ++ ") · " ++ freqAt.(r[0], t0 + 0.6).round(0.01) ++ " Hz · K there " ++ k2.round(0.01) ++ " dB, so its peak " ++ db.(pk.(r[0], t0 + 0.3, t0 + 0.9)) ++ " dB against " ++ ~le.sineGain(220, 4).round(0.01) ++ " at A3");

	"SINE_TEST the stop:".postln;
	sp = ~le.sineSpec((midi: 57, lengthMs: 3000, level: "f"));
	r = render.("c", [[t0, ['/s_new', \leSine, 1000, 0, 0, \out, 0] ++ ~le.sineArgs(sp).asOSCArgArray], [1.0, ['/n_set', 1000, \gate, 0]]], 1.6);
	check.("told to let go, it is silent a tenth of a second later", (pk.(r[0], 0.5, 0.99) > 0) and: { pk.(r[0], 1.1, 1.55) == 0 },
		"sounding before (" ++ db.(pk.(r[0], 0.5, 0.99)) ++ " dB) · from 100 ms after the word the loudest sample " ++ pk.(r[0], 1.1, 1.55));

	if(fails.size == 0) { try { File.deleteAll(tmp) }; "SINE_TEST PASS".postln; 0.exit } { ("SINE_TEST FAIL — " ++ fails.join(" · ")).postln; 1.exit };
};
)
