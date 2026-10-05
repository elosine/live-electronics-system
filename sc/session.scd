// session.scd — the engine, up and listening, for as long as its window is open (the engine plan's 4.1).
//   node electronics/tools/sc.js run electronics/sc/session.scd LE_PLAYERS=bcl:0 --timeout 86400 --verbose
// What it does TODAY: each player named in LE_PLAYERS is passed straight through to the master — a note played into the
// rack is heard a second time, from the engine. The capture, the bank and the playback hang on these same buses next.
//   LE_PLAYERS   name:channel pairs, comma-separated — the hardware input (0-based) each player's microphone is on
//   LE_MODE      sim (default) | live
//   LE_ECHO      seconds each player is returned BEHIND the note (0 = at once). At once, the return sits two DAW blocks
//                after the note and is not heard as a second sound; LE_ECHO=1 makes it one — a listening aid for the route.
// While it runs it posts the loudest input and output of the last two seconds, when there was any.
(
var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
var mode = ("LE_MODE".getenv ? "sim").asSymbol;
var spec = ("LE_PLAYERS".getenv ? "p1:0");
var echo = ("LE_ECHO".getenv ? "0").asFloat;
(dir +/+ "boot.scd").load;
~le.bootEngine(mode, { |le|
	var s = le[\server], names = List.new;
	spec.split($,).do({ |pair|
		var bits = pair.split($:), name = bits[0].asSymbol, ch = (bits[1] ? "0").asInteger, p;
		p = le.addPlayer(name, ch);
		le.passThrough(name, 1, echo);
		le.meterOn(name, p[\bus], 1);
		names.add(name);
	});
	le.meterOn(\out, le[\busOut], 2);
	s.sync;
	le.say("LE_READY", le.json((device: le[\device], sr: s.sampleRate, players: names.asArray.collect(_.asString))));
	le.say("LE_INFO", "the engine is listening — close this window to stop it. "
		++ if(echo > 0) { "Each note comes back " ++ echo ++ " s later." } { "Each note is passed straight through." });
	loop {
		2.wait;
		if(le[\peaks].values.any({ |v| v > 0.001 })) {
			le.say("LE_INFO", names.asArray.collect({ |n| n.asString ++ " in " ++ le.peakDb(n) ++ " dB" }).join(" · ")
				++ " · out " ++ le.peakDb(\out) ++ " dB");
		};
		le.resetPeaks;
	};
});
)
