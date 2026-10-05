// check_route.scd — the proof of the audio route (the engine plan's 4.1 e): for LE_SECONDS the engine runs one player
// passed through to the master, and reports the loudest thing it heard coming in and the loudest thing it sent out.
//   node electronics/tools/sc.js run electronics/sc/check_route.scd LE_SECONDS=8 LE_IN=0
// The piece's own check (its tools/) starts this, waits for LE_READY, plays a note into its rack, and reads LE_RESULT.
//   LE_IN       the hardware input channel of the player, 0-based (ReaRoute 1 = 0)
//   LE_AMP      the preamp, a linear gain (1)
//   LE_MODE     sim (default) | live
(
var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
var secs = ("LE_SECONDS".getenv ? "8").asFloat;
var inCh = ("LE_IN".getenv ? "0").asInteger;
var amp = ("LE_AMP".getenv ? "1").asFloat;
var mode = ("LE_MODE".getenv ? "sim").asSymbol;
(dir +/+ "boot.scd").load;
~le.bootEngine(mode, { |le|
	var s = le[\server], p;
	p = le.addPlayer(\p1, inCh, amp);
	le.passThrough(\p1);
	le.meterOn(\in, p[\bus], 1);
	le.meterOn(\out, le[\busOut], 2);
	s.sync;
	le.say("LE_READY", le.json((device: le[\device], sr: s.sampleRate, block: s.options.blockSize, inChannel: inCh, seconds: secs)));
	secs.wait;
	le.say("LE_RESULT", le.json((check: "route", inPeakDb: le.peakDb(\in), outPeakDb: le.peakDb(\out),
		device: le[\device], sr: s.sampleRate)));
	le.leave(0);
});
)
