// session.scd — the engine, up and listening, for as long as its window is open (the engine plan's 4.1 … 4.4).
//   node electronics/tools/sc.js run electronics/sc/session.scd LE_PLAYERS=bcl:0 LE_BANK=<folder> --timeout 86400 --verbose
// What it does:
//   THE PLAYERS   each player named in LE_PLAYERS has a bus of its own — its microphone. NOTHING of it goes to the master
//                 by itself: the engine returns what it MAKES (a sample played back), not the player's own sound — the
//                 player is already heard in the room (in the simulation: in the rack).
//   THE BANK      with LE_BANK: the folder's index is read and its samples loaded. /le/open — a mic opening — records the
//                 player for its window, crops the recording to the attack, saves it under its name, adds its row to the
//                 index. /le/play returns a sample through the master, where the score's brick is (bank.scd).
//   THE MESSAGES  it listens on UDP 57211 (boot.scd § the ear). Each is shown as ONE LINE. /le/onset — a route check: a
//                 score saying "this player's note is about to sound" — is shown, and when that player's sound then
//                 ARRIVES a second line says how many ms after its message it came.
//   LE_PLAYERS   name:channel pairs, comma-separated — the hardware input (0-based) each player's microphone is on
//   LE_MODE      sim (default) | live | remote (a Windows device: listening over a remote desktop — boot.scd) | quiet (no hardware, nothing sounds — a tool's test of the messages alone)
//   LE_BANK      the bank's folder (the piece's; made if it is not there). Without it nothing is recorded or played.
//   LE_CROP      the crop's rule, where a piece overrides the defaults:  attackDb=-30,endDb=-45,holdMs=50  (bank.scd)
//   LE_AR        the return behaviour 'ar', where a piece overrides the defaults:  before=0.35,afterLo=100,…  (bank.scd arDefaults)
//   LE_CHAIN     the return behaviour 'chain':  after=0.7,lazy=0.2,far=0.1,unison=0,before=0,follow=1,shuffle=1  (bank.scd chainDefaults)
//   LE_LIVE      the petals live, where a piece overrides the defaults:  on=1,windowMs=300  (petals_live.scd liveDefaults)
//   LE_LEVEL     the ladder of marks, where a piece overrides the defaults:  reference=-29.54,stepDb=4,liftCapDb=20,floorDb=-60  (level.scd)
//   LE_MASTER    the bus's dials, where a piece overrides the engine's neutral defaults:  hpfHz=30,glueOn=1,glueThr=-18,ceilingDb=-1,lookaheadMs=5  (boot.scd § the bus)
//   LE_VENUE     a hall's numbers for each microphone:  name=<n>;bcl:trimDb=-2.5:hpfHz=90:eq1=250/-3/1,bfl:…  (boot.scd § the house; absent = flat)
//   LE_REFUSE_BLEED  1: a capture whose attack stands under bleedDb over the room is refused, and the buffer keeps what it had (a concert)
//   LE_ECHO      A ROUTE CHECK: seconds each player is returned BEHIND the note — the route heard as a second sound.
//   LE_PASS      A ROUTE CHECK: 1 = each player straight to the master (two DAW blocks behind: not heard as a second sound).
//   LE_SOURCE    the folder the buffers are FILLED from at start (the bank itself when absent) — the backup bank in rehearsal and concert (§71)
//   LE_RECORD    1: an opening records, buffer and file replaced (the default) · 0: an opening changes nothing — the buffers keep what the files gave them
//   LE_SECONDS   leave by itself after this many seconds (0 = never: his window). A tool's bounded run.
// While it runs it posts the loudest input and output of the last two seconds, when there was any — the output's peak, its
// momentary loudness and its true peak. /le/master moves the bus's dials while it runs; /le/leave says the session's loudest.
(
var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
var mode = ("LE_MODE".getenv ? "sim").asSymbol;
var spec = ("LE_PLAYERS".getenv ? "p1:0");
var echo = ("LE_ECHO".getenv ? "0").asFloat;
var pass = ("LE_PASS".getenv ? "0").asFloat > 0;
var secs = ("LE_SECONDS".getenv ? "0").asFloat;
var bank = "LE_BANK".getenv;
var cropSpec = "LE_CROP".getenv;
var arSpec = "LE_AR".getenv;
var chainSpec = "LE_CHAIN".getenv;
var liveSpec = "LE_LIVE".getenv;
var source = "LE_SOURCE".getenv;
var record = ("LE_RECORD".getenv ? "1").asFloat > 0;
(dir +/+ "boot.scd").load;
~le.takeSpecs;   // the ladder · the bus (needed BEFORE the boot: the master is made in it) · the venue · the bleed's refusal — boot.scd
~le.bootEngine(mode, { |le|
	var s = le[\server], names = List.new, pending = IdentityDictionary.new, lastOpen = IdentityDictionary.new, t0 = Main.elapsedTime, crop, nSamples = 0;
	spec.split($,).do({ |pair|
		var bits = pair.split($:), name = bits[0].asSymbol, ch = (bits[1] ? "0").asInteger, p;
		p = le.addPlayer(name, ch);
		if((echo > 0) or: { pass }) { le.passThrough(name, 1, echo) };
		le.meterOn(name, p[\bus], 1);
		le.onsetOn(name);
		names.add(name);
	});
	le.meterOn(\out, le[\busOut], 2);
	le.loudOn;
	if(cropSpec.notNil and: { cropSpec.size > 0 }) {
		crop = ();
		cropSpec.split($,).do({ |kv| var b = kv.split($=); if(b.size == 2) { crop[b[0].asSymbol] = b[1].asFloat } });
	};
	if(arSpec.notNil and: { arSpec.size > 0 }) {
		le[\arOpts] = ();
		arSpec.split($,).do({ |kv| var b = kv.split($=); if(b.size == 2) { le[\arOpts][b[0].asSymbol] = b[1].asFloat } });
	};
	if(chainSpec.notNil and: { chainSpec.size > 0 }) {
		le[\chainOpts] = ();
		chainSpec.split($,).do({ |kv| var b = kv.split($=); if(b.size == 2) { le[\chainOpts][b[0].asSymbol] = b[1].asFloat } });
	};
	if(liveSpec.notNil and: { liveSpec.size > 0 }) {
		le[\liveOpts] = ();
		liveSpec.split($,).do({ |kv| var b = kv.split($=); if(b.size == 2) { le[\liveOpts][b[0].asSymbol] = b[1].asFloat } });
	};
	if(bank.notNil and: { bank.size > 0 }) { nSamples = le.bankOn(bank, crop, source, record) };
	s.sync;
	if(le[\bankDir].notNil and: { le[\measureBank].notNil }) { le.measureBank };   // the rows with no loudness figure yet, in the background (level.scd)
	// ---- the messages ----
	if(le.openEar) {
		if(le[\bankDir].notNil) {
			le.bankHear;
			// THE WINDOW AGAINST THE SOUND (the Decibel piece's SWEEP_LIST #10, 2026-10-08): a mic opening's message is remembered by its
			// arrival, and when the player's sound then arrives (the onset probe, below) a line says how long after the message it came —
			// against the recording's own span. The recording begins at the message: a sound outside that span was not caught.
			le.hear(\open, { |le, d, time|
				lastOpen[(d[\player] ? '?').asSymbol] = (time: time, untilMs: (d[\dueMs] ? 0).asFloat + (d[\lengthMs] ? 500).asFloat);
				le.captureOpen(d);
			});
		};
		if(le[\sineHear].notNil) { le.sineHear };   // the generated voices (sine.scd) — with or without a bank
		if(le[\performerHear].notNil) { le.performerHear };   // the computer players (performer.scd): /le/performer · /le/performerstop
		// a tool's run ends on a message, gracefully — the server quits its device before the process goes (§71: an engine killed from
		// outside left ReaRoute wedged, and no engine could boot until Reaper was restarted). His own window still closes as before.
		le.hear(\leave, { |le, d| le.say("LE_INFO", "leaving on request" ++ if(le.loudSaid(\loudMax).size > 0) { " — the session's loudest" ++ le.loudSaid(\loudMax) } { "" }); le.leave(0) });
		le.hear(\master, { |le, d| le.masterSet(d) });   // the bus's dials, moved while it runs
		le.hear(\tone, { |le, d| le.toneOut(d) });       // the house's line-up tone
		// an onset is shown; the player's own sound, when it comes, is timed against it (a route check)
		// … EXCEPT an onset marked `sim`: a score's SIMULATED player, told to the computer players (performer.scd's ear `sim`) — a
		// line for each would bury the window, so it is not shown
		le.hear(\onset, { |le, d, time|
			var name = (d[\player] ? '?').asSymbol;
			if(d[\sim].notNil) { if(le[\perfSimOnset].notNil) { le.perfSimOnset(d) } } {
				pending[name] = (time: time, id: d[\id], lane: d[\lane], t: d[\t], dueMs: d[\dueMs]);
				le.say("LE_INFO", "onset · " ++ name ++ " · lane " ++ d[\lane] ++ " · brick " ++ d[\id]
					++ " · at " ++ (d[\t] ? 0).round(0.001) ++ " s · due in " ++ (d[\dueMs] ? 0).round(1) ++ " ms");
			};
		});
		le[\onHeard] = { |name, time, amp|
			var pd = pending[name], lead, op = lastOpen[name], after;
			if(le[\perfMicOnset].notNil) { le.perfMicOnset(name) };   // the computer players' ear `mic`: a player's own sound at its microphone
			if(op.notNil and: { (time - op[\time]) < 4 }) {
				after = ((time - op[\time]) * 1000).round(1);
				le.say("LE_INFO", "heard · " ++ name ++ " · its sound came " ++ after ++ " ms after its mic opening's message — the recording ran 0 … "
					++ op[\untilMs].round(1) ++ " ms: " ++ if(after < op[\untilMs]) { "INSIDE the window" } { "OUTSIDE the window — not caught" });
				lastOpen.removeAt(name);
			};
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
		msgPort: le[\earPort], samples: nSamples)));
	le.say("LE_INFO", "the bus · " ++ le.masterSaid);
	if(le[\liveIsOn].notNil and: { le[\bankDir].notNil }) {
		le.say("LE_INFO", "the petals live · " ++ if(le.liveIsOn) { "ON — a petals return within " ++ le.liveOf[\windowMs].round(1).asInteger
			++ " ms of its own mic opening is made from the microphone, as it is played" }
			{ "off" ++ if(mode == \remote) { " (no microphones in this mode)" } { "" } ++ " — such a return plays its earlier render" });
	};
	if(le[\venue].notNil) { le.say("LE_INFO", "the house · " ++ le.micSaid ++ if(le[\refuseBleed] == true) { " · a bled capture is REFUSED" } { "" }) };
	le.say("LE_INFO", "the engine is listening — close this window to stop it. "
		++ if(le[\bankDir].notNil) { "The bank holds " ++ nSamples ++ " sample" ++ if(nSamples == 1) { "" } { "s" } ++ ". "
			++ if(le[\sourceDir] != le[\bankDir]) { "Loaded from " ++ le[\sourceDir] ++ "; captures go to " ++ le[\bankDir] ++ ". " } { "" }
			++ if(le[\record] == false) { "RECORDING IS OFF: an opening leaves its buffer as it is. " } { "" } }
			{ "NO BANK: nothing will be recorded or played. " }
		++ case { echo > 0 } { "ROUTE CHECK: each note comes back " ++ echo ++ " s later." }
			{ pass } { "ROUTE CHECK: each note is passed straight through." } { true } { "" });
	loop {
		2.wait;
		if(le[\peaks].values.any({ |v| v > 0.001 })) {
			le.say("LE_INFO", names.asArray.collect({ |n| n.asString ++ " in " ++ le.peakDb(n) ++ " dB" }).join(" · ")
				++ " · out " ++ le.peakDb(\out) ++ " dB" ++ le.loudSaid(\loudNow));
		};
		le.resetPeaks;
		if((secs > 0) and: { (Main.elapsedTime - t0) >= secs }) { le.leave(0) };
	};
});
)
