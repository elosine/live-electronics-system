// latency.scd — the round trip, measured (the engine plan's 4.1 e): a click leaves the engine's output LE_OUT, the piece's
// rack sends it straight back to the engine's input LE_IN, and the engine times the gap — eight clicks, the median.
//   node electronics/tools/sc.js run electronics/sc/latency.scd LE_OUT=0 LE_IN=2
// The rack must loop the click back for the length of the run (the piece's own check sets that up and takes it down).
// NOTHING ELSE runs: no pass-through, so the loop cannot feed itself.
(
var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
var outCh = ("LE_OUT".getenv ? "0").asInteger;
var inCh = ("LE_IN".getenv ? "2").asInteger;
var mode = ("LE_MODE".getenv ? "sim").asSymbol;
(dir +/+ "boot.scd").load;
~le.bootEngine(mode, { |le|
	var s = le[\server], lat = List.new, got;
	le[\master].free;
	OSCdef(\leLat, { |msg| lat.add(msg[3]) }, '/le/latency', s.addr);
	s.sync;
	le.say("LE_READY", le.json((device: le[\device], sr: s.sampleRate, clickOut: outCh, listenIn: inCh)));
	Synth(\leLatency, [\out, outCh, \in, s.options.numOutputBusChannels + inCh, \period, 0.5, \amp, 0.1], le[\grpIn]);
	4.4.wait;
	got = if(lat.size > 0) { lat.asArray.median } { nil };
	le.say("LE_RESULT", le.json((check: "latency", clicks: lat.size,
		roundTripMs: if(got.notNil) { (got * 1000).round(0.01) } { nil },
		roundTripSamples: if(got.notNil) { (got * s.sampleRate).round(1) } { nil },
		sr: s.sampleRate, block: s.options.blockSize)));
	le.leave(if(got.notNil) { 0 } { 1 });
});
)
