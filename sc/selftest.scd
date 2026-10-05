// selftest.scd — the engine's own test, with NO hardware in the path: every bus is private and nothing sounds.
//   node electronics/tools/sc.js run electronics/sc/selftest.scd
//
// It proves what can be proven without a device, so that the one thing a device adds is the device:
//   A  the pass-through is untouched — what leaves the master is, sample for sample, what the player's bus holds
//   B  the safety holds — a signal 6 dB over full scale never leaves over full scale, at its onset or settled, and is
//      held more than 5 dB under what came in. (The -1 dB is where the squeeze STARTS, not a ceiling: with a 2 ms attack and
//      no look-ahead the follower reads under a wave's crest, so a 220 Hz tone at +6 settles at -0.1 dBFS, not -0.65.
//      The ceiling is the clip at full scale. Measured 2026-10-04.)
//   C  the latency probe measures a delay it is given (512 samples + one block of the server)
// Each posts one LE_RESULT line with "pass": true | false. Exit 0 when all three pass, 1 otherwise.
(
var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
(dir +/+ "boot.scd").load;
~le.bootEngine(\quiet, { |le|
	var s = le[\server], sr = s.sampleRate, p, tone, maxDiff = 0, lat = List.new, clickBus, backBus;
	var inDb, outDb, overDb, settledDb, expect, got, okA, okB, okC;

	SynthDef(\leTestTone, { |out = 0, amp = 0.1, freq = 220|
		Out.ar(out, SinOsc.ar(freq) * amp);
	}).add;
	SynthDef(\leTestDiff, { |a = 0, b = 0|
		var d = (In.ar(a, 1) - In.ar(b, 1)).abs;
		SendReply.kr(Impulse.kr(20), '/le/diff', A2K.kr(RunningMax.ar(d)));
	}).add;
	SynthDef(\leTestDelay, { |in = 0, out = 0, time = 0.01|
		Out.ar(out, DelayN.ar(In.ar(in, 1), 0.2, time));
	}).add;
	s.sync;
	le.say("LE_READY", le.json((mode: "quiet", sr: sr, block: s.options.blockSize)));

	// ---- A · the pass-through, untouched ----
	p = le.addPlayer(\p1, 0);
	le.passThrough(\p1);
	le.meterOn(\in, p[\bus], 1);
	le.meterOn(\out, le[\busOut], 2);
	OSCdef(\leDiff, { |msg| maxDiff = max(maxDiff, msg[3]) }, '/le/diff', s.addr);
	tone = Synth(\leTestTone, [\out, p[\bus].index, \amp, -20.dbamp], le[\grpIn]);
	Synth(\leTestDiff, [\a, p[\bus].index, \b, le[\busOut].index], le[\grpMeter]);
	1.5.wait;
	inDb = le.peakDb(\in); outDb = le.peakDb(\out);
	okA = (maxDiff == 0) and: { (inDb - outDb).abs < 0.05 } and: { (inDb + 20).abs < 0.2 };
	le.say("LE_RESULT", le.json((test: "A pass-through", inPeakDb: inDb, outPeakDb: outDb, maxSampleDiff: maxDiff, pass: okA)));

	// ---- B · the safety ----
	le.resetPeaks; tone.set(\amp, 6.dbamp);
	0.6.wait;
	overDb = le.peakDb(\out);
	le.resetPeaks; 0.8.wait;
	settledDb = le.peakDb(\out);
	okB = (overDb <= 0) and: { settledDb <= 0 } and: { settledDb < (6 - 5) };
	le.say("LE_RESULT", le.json((test: "B safety", inPeakDb: 6, outPeakAtOnsetDb: overDb, outPeakSettledDb: settledDb, pass: okB)));
	tone.free;

	// ---- C · the latency probe ----
	clickBus = Bus.audio(s, 1); backBus = Bus.audio(s, 1);
	OSCdef(\leLat, { |msg| lat.add(msg[3]) }, '/le/latency', s.addr);
	Synth(\leLatency, [\out, clickBus.index, \in, backBus.index, \period, 0.25], le[\grpIn]);
	Synth(\leTestDelay, [\in, clickBus.index, \out, backBus.index, \time, 512 / sr], le[\grpFx]);
	2.2.wait;
	expect = (512 + s.options.blockSize) / sr;
	got = if(lat.size > 0) { lat.asArray.median } { nil };
	okC = got.notNil and: { ((got - expect) * sr).abs <= 2 };
	le.say("LE_RESULT", le.json((test: "C latency probe", clicks: lat.size, expectMs: (expect * 1000).round(0.001),
		gotMs: if(got.notNil) { (got * 1000).round(0.001) } { nil }, pass: okC)));

	le.leave(if(okA and: { okB } and: { okC }) { 0 } { 1 });
});
)
