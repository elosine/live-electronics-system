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
	var s = le[\server], rms = 0, meter, fails = 0, names, first;
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
	meter = { SendPeakRMS.kr(In.ar(le[\busMaster].index, 2).sum, 10, 3, '/icytest') }.play(le[\grpMeter]);
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

	// E stop is silent
	le.icyLabDo((do: "stop"));
	level.(0.8);
	check.("E stop is silent", rms < 0.0005, "rms " ++ rms.ampdb.round(0.1) ++ " dB");

	meter.free;
	le.say("LE_INFO", "icylab_test: " ++ if(fails == 0) { "all pass" } { fails.asString ++ " failed" });
	le.leave(if(fails == 0) { 0 } { 1 });
});
)
