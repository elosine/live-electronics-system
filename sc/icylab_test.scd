// icylab_test.scd — ICY LIVE proven with NO hardware (mode \quiet): the samples load, each voice SOUNDS on the master bus,
// a knob moves while it plays, a change of voice keeps the sample, stop is silent.
//   node electronics/tools/sc.js run electronics/sc/icylab_test.scd LE_ICYLAB=<folder of wavs>
// One LE_RESULT line per check, "pass": true | false; exit 0 when all pass.
(
var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
var folder = "LE_ICYLAB".getenv;
(dir +/+ "boot.scd").load;
if(folder.isNil or: { folder.size == 0 }) { "LE_ERROR icylab_test: LE_ICYLAB=<folder of wavs> is needed".postln; 1.exit };
~le.bootEngine(\quiet, { |le|
	var s = le[\server], rms = 0, meter, fails = 0, names, first, ripple, rS, rG;
	var check = { |name, ok, detail|
		if(ok.not) { fails = fails + 1 };
		le.say("LE_RESULT", le.json((test: name, pass: ok, detail: detail)));
	};
	var level = { |secs|
		var got = 0, done = false;
		OSCFunc({ |m| got = max(got, m[4]); }, '/icytest', s.addr).oneShot;   // the first reply is enough: peak RMS of a block
		rms = 0;
		secs.wait;
		{ var o = OSCFunc({ |m| rms = m[4]; done = true }, '/icytest', s.addr); 0.3.wait; o.free }.fork;
		0.35.wait;
		rms
	};
	le.icyLabDefs;
	s.sync;
	le.icyLabHear;
	meter = { SendPeakRMS.kr(In.ar(le[\busMaster].index, 2).sum, 200, 3, '/icytest') }.play(le[\grpMeter]);
	s.sync;

	// A the samples and the windows load
	le.icyLabDo((do: "load", dir: folder));
	names = le[\icyLab][\samples].keys.asArray.collect(_.asString).sort;
	check.("A samples and windows loaded", (names.size > 0) and: { le[\icyLab][\envs].size == 10 },
		names.size.asString ++ " samples · windows " ++ le[\icyLab][\envNames].join(" "));
	first = names.first;

	// B the grain voice sounds at the defaults (×30, expodec)
	le.icyLabDo((do: "start", sample: first, voice: "grain", slowerBy: 30, grainEnvelope: "expodec"));
	level.(1.0);
	check.("B grain voice sounds", rms > 0.0005, "rms " ++ rms.ampdb.round(0.1) ++ " dB on " ++ first);

	// C a knob moves while it plays (the scatter, the overlap, an assorted set) — still sounding, no error
	le.icyLabDo((do: "set", scatter: 0.04, overlaps: 24, envelopeSet: "A", panSpread: 0.5));
	level.(0.8);
	check.("C knobs set live", rms > 0.0005, "rms " ++ rms.ampdb.round(0.1) ++ " dB after scatter · overlaps · envelopeSet A · panSpread");

	// D the warp voice (his Warp1) on the same sample, at the same read
	le.icyLabDo((do: "set", voice: "warp", grainLength: 0.8, overlaps: 33, lengthVary: 0.2, grainEnvelope: "expodec"));
	level.(1.0);
	check.("D warp voice sounds", (rms > 0.0005) and: { le[\icyLab][\voice] == \warp }, "rms " ++ rms.ampdb.round(0.1) ++ " dB");

	// F the stretch voice (PaulStretch) sounds — its frames made first (a real-time pass of the sample)
	le.icyLabDo((do: "set", voice: "stretch", windowSeconds: 1.49, slowerBy: 30));
	4.0.wait;
	level.(1.0);
	check.("F stretch voice sounds", (rms > 0.0005) and: { le[\icyLab][\voice] == \stretch }, "rms " ++ rms.ampdb.round(0.1) ++ " dB");
	// G it is SMOOTHER than the grain voice: the FAST flutter of the level — the mean step between successive 5 ms RMS readings
	//   over 3 s, as a share of the mean level — is lower (the slow wander of the partials is the stretch's nature and not counted)
	ripple = { |secs| var v = List.new, o = OSCFunc({ |m| v.add(m[4]) }, '/icytest', s.addr); secs.wait; o.free;
		if(v.size > 4) { var mean = v.sum / v.size, d = 0; (1..(v.size - 1)).do({ |i| d = d + (v[i] - v[i - 1]).abs }); (d / (v.size - 1)) / mean.max(1e-9) } { 9 } };
	rS = ripple.(3.0);
	le.icyLabDo((do: "set", voice: "grain", grainLength: 0.6, overlaps: 17, grainEnvelope: "expodec", lengthVary: 0.2, scatter: 0, slowerBy: 30));
	1.0.wait;
	rG = ripple.(3.0);
	check.("G stretch smoother than grain", rS < rG, "ripple stretch " ++ rS.round(0.001) ++ " · grain " ++ rG.round(0.001));
	// E stop is silent
	le.icyLabDo((do: "stop"));
	level.(0.8);
	check.("E stop is silent", rms < 0.0005, "rms " ++ rms.ampdb.round(0.1) ++ " dB");

	meter.free;
	le.say("LE_INFO", "icylab_test (seven checks): " ++ if(fails == 0) { "all pass" } { fails.asString ++ " failed" });
	le.leave(if(fails == 0) { 0 } { 1 });
});
)
