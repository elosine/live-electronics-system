// session.scd — the engine, up and listening, for as long as its window is open (the engine plan's 4.1 · 4.2).
//   node electronics/tools/sc.js run electronics/sc/session.scd LE_PLAYERS=bcl:0 --timeout 86400 --verbose
// What it does TODAY:
//   THE SOUND     each player named in LE_PLAYERS is passed straight through to the master — a note played into the rack
//                 is heard a second time, from the engine. The capture, the bank and the playback hang on these buses next.
//   THE MESSAGES  it listens on UDP 57211 (boot.scd § the ear). /le/onset — a piece's score saying "this player's note is
//                 about to sound" — is shown as ONE LINE; when that player's sound then ARRIVES, a second line says how many
//                 ms after its message it came (and one LE_RESULT line carries the same, for a tool to read).
//   LE_PLAYERS   name:channel pairs, comma-separated — the hardware input (0-based) each player's microphone is on
//   LE_MODE      sim (default) | live | quiet (no hardware, nothing sounds — a tool's test of the messages alone)
//   LE_ECHO      seconds each player is returned BEHIND the note (0 = at once). At once, the return sits two DAW blocks
//                after the note and is not heard as a second sound; LE_ECHO=1 makes it one — a listening aid for the route.
//   LE_SECONDS   leave by itself after this many seconds (0 = never: his window). A tool's bounded run.
// While it runs it posts the loudest input and output of the last two seconds, when there was any.
(
var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
var mode = ("LE_MODE".getenv ? "sim").asSymbol;
var spec = ("LE_PLAYERS".getenv ? "p1:0");
var echo = ("LE_ECHO".getenv ? "0").asFloat;
var secs = ("LE_SECONDS".getenv ? "0").asFloat;
(dir +/+ "boot.scd").load;
~le.bootEngine(mode, { |le|
	var s = le[\server], names = List.new, pending = IdentityDictionary.new, t0 = Main.elapsedTime;
	spec.split($,).do({ |pair|
		var bits = pair.split($:), name = bits[0].asSymbol, ch = (bits[1] ? "0").asInteger, p;
		p = le.addPlayer(name, ch);
		le.passThrough(name, 1, echo);
		le.meterOn(name, p[\bus], 1);
		le.onsetOn(name);
		names.add(name);
	});
	le.meterOn(\out, le[\busOut], 2);
	s.sync;
	// ---- the messages: an onset is shown; the player's own sound, when it comes, is timed against it ----
	if(le.openEar) {
		le.hear(\onset, { |le, d, time|
			var name = (d[\player] ? '?').asSymbol;
			pending[name] = (time: time, id: d[\id], lane: d[\lane], t: d[\t], dueMs: d[\dueMs]);
			le.say("LE_INFO", "onset · " ++ name ++ " · lane " ++ d[\lane] ++ " · brick " ++ d[\id]
				++ " · at " ++ (d[\t] ? 0).round(0.001) ++ " s · due in " ++ (d[\dueMs] ? 0).round(1) ++ " ms");
		});
		le[\onHeard] = { |name, time, amp|
			var pd = pending[name], lead;
			if(pd.notNil and: { (time - pd[\time]) < 3 }) {
				lead = ((time - pd[\time]) * 1000).round(0.1);
				le.say("LE_INFO", "heard · " ++ name ++ " · its sound arrived " ++ lead ++ " ms after its message");
				le.say("LE_RESULT", le.json((msg: "onset", player: name, id: pd[\id], lane: pd[\lane], t: pd[\t],
					dueMs: pd[\dueMs], leadMs: lead)));
				pending.removeAt(name);
			};
		};
	};
	le.say("LE_READY", le.json((device: le[\device], sr: s.sampleRate, players: names.asArray.collect(_.asString),
		msgPort: le[\earPort])));
	le.say("LE_INFO", "the engine is listening — close this window to stop it. "
		++ if(echo > 0) { "Each note comes back " ++ echo ++ " s later." } { "Each note is passed straight through." });
	loop {
		2.wait;
		if(le[\peaks].values.any({ |v| v > 0.001 })) {
			le.say("LE_INFO", names.asArray.collect({ |n| n.asString ++ " in " ++ le.peakDb(n) ++ " dB" }).join(" · ")
				++ " · out " ++ le.peakDb(\out) ++ " dB");
		};
		le.resetPeaks;
		if((secs > 0) and: { (Main.elapsedTime - t0) >= secs }) { le.leave(0) };
	};
});
)
