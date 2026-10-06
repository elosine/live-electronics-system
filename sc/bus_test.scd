// bus_test.scd — THE BUS AND THE SYNTHS, OFFLINE (the engine plan's part 13; the Decibel piece's PLAN 1.4 · 11.6, 2026-10-06):
// the engine's own SynthDefs (synths.scd) played by a second scsynth with no device and no port (NRT), into files, and the files
// measured. No server of the engine's is asked anything: a living engine beside it is untouched, and nothing sounds.
//   THE MASTER   under the ceiling with every switch off, what leaves is what came in, sample for sample, one look-ahead later ·
//                how late that is · a tone 6 dB OVER full scale leaves at the ceiling, at its onset and settled, at three pitches ·
//                a struck burst 6 dB over never passes the ceiling · the glue leaves a quiet tone exactly alone, takes 4.5 dB off
//                one 9 dB over its threshold, and bends between (the soft knee) · the high-pass and the low-pass, on and off
//   THE METER    the players' reference tone reads −17.0 LUFS and its peak · a peak that falls BETWEEN the samples is found
//   THE SAMPLE   \leSample's envelope as SOUND: 0 dB to −12 dB over half a second, joined in decibels
//   THE INPUT    \leIn flat is the input sample for sample · its trim · its high-pass
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/bus_test.scd
// It ends BUS_TEST PASS (exit 0) or BUS_TEST FAIL (exit 1) and names each check.
(
var dir = thisProcess.nowExecutingPath.dirname;
var tmp = Platform.defaultTempDir +/+ "le_bus_test_" ++ Date.localtime.stamp;
var sr = 44100, la = 0.005, fails = List.new, check, defs, render, pk, db, at, near;
(dir +/+ "boot.scd").load;
~le[\sr] = sr;
(dir +/+ "synths.scd").load;   // no server: the SynthDefs are built, and kept in the library
File.mkdir(tmp);
check = { |what, ok, detail| ("  " ++ if(ok) { "ok   " } { "FAIL " } ++ what ++ " — " ++ detail).postln; if(ok.not) { fails.add(what) } };
near = { |a, b, tol| a.notNil and: { (a - b).abs <= tol } };
db = { |x| if(x > 0) { x.ampdb.round(0.01) } { -200 } };
// the test's own sources and probes
SynthDef(\btTone, { |out = 0, freq = 220, amp = 0.1, phase = 0| var s = SinOsc.ar(freq, phase) * amp; Out.ar(out, [s, s]) }).add;
SynthDef(\btBurst, { |out = 0, freq = 220, amp = 2| var s = SinOsc.ar(freq) * EnvGen.ar(Env.perc(0.001, 0.2)) * amp; Out.ar(out, [s, s]) }).add;
SynthDef(\btClick, { |out = 0, amp = 0.5| var s = Impulse.ar(0) * amp; Out.ar(out, [s, s]) }).add;
SynthDef(\btCopy, { |in = 16, out = 2| Out.ar(out, In.ar(in, 1)) }).add;
SynthDef(\btLate, { |in = 16, out = 2, delay = 0.005| Out.ar(out, DelayN.ar(In.ar(in, 1), 0.05, delay)) }).add;
SynthDef(\btLoud, { |in = 0, out = 2| Out.ar(out, ~le.loudGraph(In.ar(in, 2))) }).add;
defs = [\btTone, \btBurst, \btClick, \btCopy, \btLate, \btLoud, \leMaster, \leSample, \leIn].collect({ |n| [0.0, ['/d_recv', SynthDescLib.global[n].def.asBytes]] });
// one offline render -> its channels, each a FloatArray
render = { |name, msgs, dur, chans = 3|
	var osc = tmp +/+ name ++ ".osc", wav = tmp +/+ name ++ ".wav", done = false, sf, data, frames, opts;
	opts = ServerOptions.new.numOutputBusChannels_(chans).numInputBusChannels_(2).numAudioBusChannels_(64).memSize_(65536);
	Score(defs ++ msgs ++ [[dur, ['/c_set', 0, 0]]]).recordNRT(osc, wav, nil, sr, "WAV", "float", opts, "", nil, { done = true });
	while { done.not } { 0.05.wait };
	sf = SoundFile.new;
	if(File.exists(wav) and: { sf.openRead(wav) }) { data = FloatArray.newClear(sf.numFrames * sf.numChannels); sf.readData(data); frames = sf.numFrames; sf.close };
	if(data.isNil) { nil } { chans.collect({ |c| FloatArray.fill(frames, { |i| data[(i * chans) + c] }) }) }
};
pk = { |x, from, to| var a = (from * sr).asInteger, b = ((to * sr).asInteger - 1).min(x.size - 1), m = 0; (a..b).do({ |i| m = max(m, x[i].abs) }); m };
at = { |x, t| x[(t * sr).asInteger.min(x.size - 1)] };
// the master on bus 16 -> output 0; a list of its dials
~bus = { |args| [0.0, ['/s_new', \leMaster, 1001, 1, 0, \in, 16, \out, 0, \lookahead, la] ++ args] };
fork {
	var r, d, i0, i1, on, set, worst, low, mid, a, b, q, tp;
	("BUS_TEST the scratch folder: " ++ tmp).postln;

	"BUS_TEST the master:".postln;
	// A · under the ceiling, every switch off: the output against the input one look-ahead late — the same DelayN, the same samples
	r = render.("a", [[0.0, ['/s_new', \btLate, 1002, 1, 0, \in, 16, \out, 2, \delay, la]], ~bus.([]), [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 16, \freq, 220, \amp, -20.dbamp]]], 0.5);
	worst = 0; ((0.1 * sr).asInteger..(0.45 * sr).asInteger).do({ |i| worst = max(worst, (r[0][i] - r[2][i]).abs) });
	check.("under the ceiling, nothing switched on: what leaves is what came in, to the sample", (worst == 0) and: { near.(db.(pk.(r[0], 0.1, 0.45)), -20, 0.05) } and: { r[0] == r[1] },
		"the largest difference " ++ worst ++ " · peak " ++ db.(pk.(r[0], 0.1, 0.45)) ++ " dB · the two channels alike");
	// B · how late: one click
	r = render.("b", [[0.0, ['/s_new', \btCopy, 1002, 1, 0, \in, 16, \out, 2]], ~bus.([]), [0.1, ['/s_new', \btClick, 1000, 0, 0, \out, 16]]], 0.3);
	i0 = r[2].indexOf(r[2].maxItem); i1 = r[0].indexOf(r[0].maxItem);
	check.("it is one look-ahead late, and says how much", ((i1 - i0) - (la * sr)).abs <= 1, (i1 - i0).asString ++ " samples = " ++ ((i1 - i0) / sr * 1000).round(0.01) ++ " ms (the look-ahead " ++ (la * 1000) ++ " ms)");
	// C · 6 dB over full scale, three pitches: at its onset and settled it leaves AT the ceiling, never over
	[60, 220, 1000].do({ |f|
		r = render.("c" ++ f, [~bus.([]), [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 16, \freq, f, \amp, 6.dbamp]]], 1.0, 2);
		on = db.(pk.(r[0], 0.05, 0.3)); set = db.(pk.(r[0], 0.6, 0.95));
		check.("a " ++ f ++ " Hz tone 6 dB over full scale leaves at the ceiling", (on <= -0.99) and: { near.(set, -1, 0.2) }, "the loudest sample of its onset " ++ on ++ " dB · settled " ++ set ++ " dB (the ceiling −1)");
	});
	// D · a struck burst, 1 ms to rise, 6 dB over
	r = render.("d", [~bus.([]), [0.05, ['/s_new', \btBurst, 1000, 0, 0, \out, 16, \freq, 220, \amp, 6.dbamp]]], 0.5, 2);
	check.("a struck burst 6 dB over never passes the ceiling", db.(pk.(r[0], 0, 0.5)) <= -0.99, "its loudest sample " ++ db.(pk.(r[0], 0, 0.5)) ++ " dB");
	// E · the glue: quiet = exactly alone · 9 dB over the threshold = 4.5 dB off · at the threshold = inside the knee
	r = render.("e1", [[0.0, ['/s_new', \btLate, 1002, 1, 0, \in, 16, \out, 2, \delay, la]], ~bus.([\glueOn, 1]), [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 16, \freq, 220, \amp, -20.dbamp]]], 0.5);
	worst = 0; ((0.1 * sr).asInteger..(0.45 * sr).asInteger).do({ |i| worst = max(worst, (r[0][i] - r[2][i]).abs) });
	check.("the glue leaves a tone under its knee exactly alone", worst == 0, "a −20 dB tone (RMS −23, the knee begins at −21): the largest difference " ++ worst);
	r = render.("e2", [~bus.([\glueOn, 1]), [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 16, \freq, 220, \amp, -6.dbamp]]], 1.2, 2);
	check.("9 dB over its threshold at 2:1, it takes 4.5 dB off", near.(db.(pk.(r[0], 0.9, 1.15)), -10.5, 0.3), "a −6 dB tone (RMS −9) leaves at " ++ db.(pk.(r[0], 0.9, 1.15)) ++ " dB");
	r = render.("e3", [~bus.([\glueOn, 1]), [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 16, \freq, 220, \amp, -15.dbamp]]], 1.2, 2);
	check.("AT its threshold it bends: the soft knee", near.(db.(pk.(r[0], 0.9, 1.15)), -15.375, 0.15), "a −15 dB tone (RMS −18) leaves at " ++ db.(pk.(r[0], 0.9, 1.15)) ++ " dB (a hard knee would leave −15.0)");
	// F · the high-pass at 30 Hz · G · the low-pass at 2 kHz
	low = render.("f1", [~bus.([\hpfOn, 1, \hpfFreq, 30]), [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 16, \freq, 20, \amp, -20.dbamp]]], 1.6, 2);
	mid = render.("f2", [~bus.([\hpfOn, 1, \hpfFreq, 30]), [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 16, \freq, 1000, \amp, -20.dbamp]]], 0.6, 2);
	check.("the high-pass at 30 Hz: 20 Hz goes down, 1 kHz passes", near.(db.(pk.(low[0], 1.0, 1.55)), -27.8, 1.5) and: { near.(db.(pk.(mid[0], 0.3, 0.55)), -20, 0.1) },
		"20 Hz at " ++ db.(pk.(low[0], 1.0, 1.55)) ++ " dB · 1 kHz at " ++ db.(pk.(mid[0], 0.3, 0.55)) ++ " dB (both came in at −20)");
	low = render.("g1", [~bus.([\lpfOn, 1, \lpfFreq, 2000]), [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 16, \freq, 200, \amp, -20.dbamp]]], 0.6, 2);
	mid = render.("g2", [~bus.([\lpfOn, 1, \lpfFreq, 2000]), [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 16, \freq, 8000, \amp, -20.dbamp]]], 0.6, 2);
	check.("the low-pass at 2 kHz: 8 kHz goes down, 200 Hz passes", near.(db.(pk.(low[0], 0.3, 0.55)), -20, 0.2) and: { db.(pk.(mid[0], 0.3, 0.55)) < -38 },
		"200 Hz at " ++ db.(pk.(low[0], 0.3, 0.55)) ++ " dB · 8 kHz at " ++ db.(pk.(mid[0], 0.3, 0.55)) ++ " dB (both came in at −20)");

	"BUS_TEST the meter:".postln;
	// H · the players' reference tone straight onto the output, and the reading written beside it
	r = render.("h1", [[0.0, ['/s_new', \btLoud, 1002, 1, 0, \in, 0, \out, 2]], [0.0, ['/s_new', \btTone, 1000, 0, 0, \out, 0, \freq, 1000, \amp, -20.dbamp * 2.sqrt]]], 1.2, 4);
	check.("the reference tone reads −17.0 LUFS, and its peak", near.(at.(r[2], 1.1), -17, 0.3) and: { near.(db.(pk.(r[3], 0.9, 1.15)), -16.99, 0.3) },
		at.(r[2], 1.1).round(0.01).asString ++ " LUFS · true peak " ++ db.(pk.(r[3], 0.9, 1.15)) ++ " dBTP");
	// a quarter of the sample rate, an eighth of a cycle off: every SAMPLE is 3 dB under the wave's real peak
	r = render.("h2", [[0.0, ['/s_new', \btLoud, 1002, 1, 0, \in, 0, \out, 2]], [0.0, ['/s_new', \btTone, 1000, 0, 0, \out, 0, \freq, sr / 4, \amp, 0.5, \phase, pi / 4]]], 0.6, 4);
	tp = db.(pk.(r[3], 0.3, 0.55));
	check.("a peak that falls BETWEEN the samples is found", near.(tp, -6.02, 0.5) and: { near.(db.(pk.(r[0], 0.3, 0.55)), -9.03, 0.1) },
		"the loudest sample " ++ db.(pk.(r[0], 0.3, 0.55)) ++ " dB · the true peak read " ++ tp ++ " dBTP (the wave's own: −6.02)");

	"BUS_TEST the sample's dynamic, as sound:".postln;
	// I · a one-second tone in a file, played by \leSample under 0 dB -> −12 dB over half a second, then held
	~le.wavWrite(tmp +/+ "tone.wav", FloatArray.fill(sr, { |i| sin(2pi * 441 * i / sr) * 0.5 }), sr);
	r = render.("i", [[0.0, ['/b_allocRead', 0, tmp +/+ "tone.wav", 0, 0]],
		[0.05, ['/s_new', \leSample, 1000, 0, 0, \out, 0, \buf, 0, \envDb, $[, 0, -12, -12, -12, -12, -12, -12, -12, $], \envDt, $[, 0.5, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, $], \envCurve, 0]]], 1.2, 2);
	a = db.(pk.(r[0], 0.051, 0.06)); b = db.(pk.(r[0], 0.295, 0.305)); q = db.(pk.(r[0], 0.7, 0.9));
	check.("\\leSample: 0 dB, −6 dB half way, −12 dB — joined in decibels", near.(a, -6.02, 0.3) and: { near.(b, -12.02, 0.5) } and: { near.(q, -18.02, 0.2) },
		"a −6.02 dB tone: at its start " ++ a ++ " · half way down " ++ b ++ " · held " ++ q ++ " dB");
	r = render.("i2", [[0.0, ['/b_allocRead', 0, tmp +/+ "tone.wav", 0, 0]], [0.05, ['/s_new', \leSample, 1000, 0, 0, \out, 0, \buf, 0]]], 0.6, 2);
	check.("\\leSample given no dynamic plays the file as it is", near.(db.(pk.(r[0], 0.1, 0.5)), -6.02, 0.02), db.(pk.(r[0], 0.1, 0.5)).asString ++ " dB");

	"BUS_TEST the input chain:".postln;
	// J · \leIn from a bus the test writes: flat · trimmed 6 dB down · high-passed at 90 Hz
	r = render.("j1", [[0.0, ['/s_new', \btCopy, 1002, 1, 0, \in, 20, \out, 1]], [0.0, ['/s_new', \leIn, 1001, 1, 0, \in, 20, \out, 0]], [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 20, \freq, 220, \amp, -20.dbamp]]], 0.4, 2);
	check.("\\leIn with nothing switched on is the input, to the sample", (r[0] == r[1]) and: { near.(db.(pk.(r[0], 0.1, 0.35)), -20, 0.05) }, "peak " ++ db.(pk.(r[0], 0.1, 0.35)) ++ " dB · the same samples");
	r = render.("j2", [[0.0, ['/s_new', \leIn, 1001, 1, 0, \in, 20, \out, 0, \amp, -6.dbamp]], [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 20, \freq, 220, \amp, -20.dbamp]]], 0.4, 2);
	check.("its trim: 6 dB down", near.(db.(pk.(r[0], 0.1, 0.35)), -26, 0.05), db.(pk.(r[0], 0.1, 0.35)).asString ++ " dB");
	r = render.("j3", [[0.0, ['/s_new', \leIn, 1001, 1, 0, \in, 20, \out, 0, \hpfOn, 1, \hpfFreq, 90]], [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 20, \freq, 40, \amp, -20.dbamp]]], 0.9, 2);
	check.("its high-pass at 90 Hz takes a 40 Hz rumble down", near.(db.(pk.(r[0], 0.5, 0.85)), -34.3, 2), db.(pk.(r[0], 0.5, 0.85)).asString ++ " dB (it came in at −20)");
	r = render.("j4", [[0.0, ['/s_new', \leIn, 1001, 1, 0, \in, 20, \out, 0, \eq1On, 1, \eq1Freq, 220, \eq1Db, -6, \eq1Rq, 1]], [0.05, ['/s_new', \btTone, 1000, 0, 0, \out, 20, \freq, 220, \amp, -20.dbamp]]], 0.6, 2);
	check.("a band of its EQ: 6 dB off at its centre", near.(db.(pk.(r[0], 0.3, 0.55)), -26, 0.3), db.(pk.(r[0], 0.3, 0.55)).asString ++ " dB");

	if(fails.size == 0) { try { File.deleteAll(tmp) }; "BUS_TEST PASS".postln; 0.exit } { ("BUS_TEST FAIL — " ++ fails.join(" · ")).postln; 1.exit };
};
)
