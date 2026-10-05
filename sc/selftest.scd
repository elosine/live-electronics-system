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
//   D  the ear — a message sent to UDP 57211 arrives with every field it carried, and /le/hello is answered
//   E  the onset probe — a sound that starts 100 ms after its message is reported about 100 ms after it
//      (90 … 250 ms passes: with no hardware the server runs on the machine's default device, whose block is not known)
//   F  the crop — a synthetic attack at a known place in a recording is found to within 2 ms; the sample starts 5 ms
//      before it, ends where the sound has died, and silence alone is refused
//   G  the first object, end to end — /le/open records a player's window, the recording is cropped, saved, indexed and
//      loaded; /le/play returns it through the master as loud as it was captured (the bank is a folder in the machine's
//      temp, emptied afterwards)
// Each posts one LE_RESULT line with "pass": true | false. Exit 0 when all seven pass, 1 otherwise.
(
var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
(dir +/+ "boot.scd").load;
~le.bootEngine(\quiet, { |le|
	var s = le[\server], sr = s.sampleRate, p, tone, maxDiff = 0, lat = List.new, clickBus, backBus;
	var inDb, outDb, overDb, settledDb, expect, got, okA, okB, okC;
	var gotMsg, gotReply, msgTime, heardTime, me, p2, lead, okD, okE;
	var fAt, fData, fC, fOut, fErr, okF;
	var gDir, gFiles, p3, gSmp, gFile, gRawS, gIdx, gOut, gRow, okG;

	SynthDef(\leTestTone, { |out = 0, amp = 0.1, freq = 220|
		Out.ar(out, SinOsc.ar(freq) * amp);
	}).add;
	SynthDef(\leTestDiff, { |a = 0, b = 0|
		var d = (In.ar(a, 1) - In.ar(b, 1)).abs;
		SendReply.kr(Impulse.kr(20), '/le/diff', A2K.kr(RunningMax.ar(d)));
	}).add;
	SynthDef(\leTestBurst, { |out = 0, amp = 0.1, freq = 440|
		Out.ar(out, SinOsc.ar(freq) * EnvGen.ar(Env.perc(0.002, 0.15), doneAction: 2) * amp);
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

	// ---- D · the ear: a message arrives with its data; /le/hello is answered ----
	// ---- E · the onset probe: a sound 100 ms after its message is reported about 100 ms after it ----
	okD = false; okE = false;
	if(le.openEar) {
		le.hear(\onset, { |le, d, time| gotMsg = d; msgTime = time });
		OSCdef(\leTestReply, { |msg| gotReply = msg }, '/le/hello.reply');
		p2 = le.addPlayer(\p2, 1);
		le.onsetOn(\p2);
		le[\onHeard] = { |name, time, amp| if((name == \p2) and: { heardTime.isNil }) { heardTime = time } };
		s.sync;
		me = NetAddr("127.0.0.1", le[\earPort]);
		me.sendMsg('/le/hello', \nonce, 77);
		0.3.wait;
		me.sendMsg('/le/onset', \player, "p2", \lane, 1, \id, "brick_7", \t, 3.25, \dueMs, 100.0);
		0.1.wait;
		tone = Synth(\leTestTone, [\out, p2[\bus].index, \amp, -40.dbamp], le[\grpIn]);
		0.6.wait;
		tone.free;
		okD = gotReply.notNil and: { gotReply.indexOf(\nonce).notNil } and: { gotReply[gotReply.indexOf(\nonce) + 1] == 77 }
			and: { gotMsg.notNil } and: { gotMsg[\player] == \p2 } and: { gotMsg[\lane] == 1 } and: { gotMsg[\id] == \brick_7 }
			and: { (gotMsg[\t] - 3.25).abs < 0.001 } and: { gotMsg[\dueMs] == 100 };
		lead = if(heardTime.notNil and: { msgTime.notNil }) { ((heardTime - msgTime) * 1000).round(0.1) } { nil };
		okE = lead.notNil and: { (lead > 90) and: { lead < 250 } };
	};
	le.say("LE_RESULT", le.json((test: "D the ear", port: le[\earPort], helloAnswered: gotReply.notNil,
		got: if(gotMsg.notNil) { gotMsg.asKeyValuePairs.collect(_.asString).join(" ") } { nil }, pass: okD)));
	le.say("LE_RESULT", le.json((test: "E onset probe", sentMsAfterMessage: 100, heardMsAfterMessage: lead, pass: okE)));

	// ---- F · the crop: a synthetic attack at a known place ----
	// 0.6 s: a floor of noise at -80 dB; at 0.2 s a 220 Hz tone, 1 ms to rise, dying with a 60 ms time constant
	fAt = (0.2 * sr).asInteger;
	fData = FloatArray.fill((0.6 * sr).asInteger, { |i|
		var t = (i - fAt) / sr;
		(1.0.rand2 * 0.0001) + if(i >= fAt) { sin(2pi * 220 * t) * 0.5 * (t / 0.001).min(1) * exp(t.neg / 0.06) } { 0 }
	});
	fC = le.cropFind(fData, sr);
	okF = false;
	if(fC.notNil) {
		fOut = le.cropTake(fData, sr, fC);
		fErr = ((fC[\attack] - fAt) / sr * 1000).round(0.01);
		okF = (fErr.abs <= 2) and: { fC[\start] == (fC[\attack] - (0.005 * sr).round.asInteger) }
			and: { (fC[\end] / sr > 0.47) and: { fC[\end] / sr < 0.56 } } and: { fOut[0] == 0 }
			and: { fOut.size == (fC[\end] - fC[\start]) }
			and: { le.cropFind(FloatArray.fill(2000, { 1.0.rand2 * 0.0001 }), sr).isNil };
	};
	le.say("LE_RESULT", le.json((test: "F the crop", attackPutAtMs: 200, foundOffByMs: fErr,
		startMs: if(fC.notNil) { (fC[\start] / sr * 1000).round(0.1) }, endMs: if(fC.notNil) { (fC[\end] / sr * 1000).round(0.1) },
		pass: okF)));

	// ---- G · the first object, end to end: open -> captured, cropped, indexed, loaded; play -> out by the master ----
	okG = false;
	if(le[\earPort].notNil) {
		gDir = Platform.defaultTempDir +/+ "le_selftest_bank";
		gFiles = [gDir +/+ "index.json", gDir +/+ "p3-A.wav", gDir +/+ "raw/zn_test.wav"];
		gFiles.do({ |f| if(File.exists(f)) { File.delete(f) } });
		le.bankOn(gDir);
		le.bankHear;
		p3 = le.addPlayer(\p3, 2);
		s.sync;
		me = NetAddr("127.0.0.1", le[\earPort]);
		me.sendMsg('/le/open', \player, "p3", \lane, 1, \id, "zn_test", \name, "p3-A", \category, "attack", \t, 4.9,
			\lengthMs, 400, \dueMs, 100.0);
		0.2.wait;
		Synth(\leTestBurst, [\out, p3[\bus].index, \amp, -20.dbamp], le[\grpIn]);
		1.6.wait;
		gSmp = le[\samples]['p3-A'];
		gRow = if(gSmp.notNil) { gSmp[\row] };
		if(File.exists(gFiles[2])) {
			gFile = SoundFile.openRead(gFiles[2]);
			if(gFile.notNil) { gRawS = gFile.numFrames / gFile.sampleRate; gFile.close };
		};
		gIdx = if(File.exists(gFiles[0])) { gFiles[0].parseJSONFile };
		le.resetPeaks;
		me.sendMsg('/le/play', \name, "p3-A", \id, "zn_play", \lane, 1, \t, 8.0, \dueMs, 50.0);
		0.6.wait;
		gOut = le.peakDb(\out);
		okG = gRow.notNil and: { gRawS.notNil } and: { (gRawS - 0.5).abs < 0.01 }
			and: { File.exists(gFiles[1]) }
			and: { (gRow[\lengthMs] > 40) and: { gRow[\lengthMs] < 260 } }
			and: { (gRow[\attackMs] > 150) and: { gRow[\attackMs] < 330 } }
			and: { (gRow[\peakDb] + 20).abs < 1 }
			and: { gIdx.notNil } and: { gIdx["samples"].size == 1 } and: { gIdx["samples"][0]["name"] == "p3-A" }
			and: { (gOut - gRow[\peakDb]).abs < 1 };
		gFiles.do({ |f| if(File.exists(f)) { File.delete(f) } });
	};
	le.say("LE_RESULT", le.json((test: "G the first object", rawSeconds: if(gRawS.notNil) { gRawS.round(0.001) },
		sampleMs: if(gRow.notNil) { gRow[\lengthMs] }, attackAtMs: if(gRow.notNil) { gRow[\attackMs] },
		capturedPeakDb: if(gRow.notNil) { gRow[\peakDb] }, indexRows: if(gIdx.notNil) { gIdx["samples"].size },
		playedBackPeakDb: gOut, pass: okG)));

	le.leave(if(okA and: { okB } and: { okC } and: { okD } and: { okE } and: { okF } and: { okG }) { 0 } { 1 });
});
)
