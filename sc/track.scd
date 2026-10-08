// track.scd — THE TRACKER: a generated voice that is a WINDOW on a player (first built in the Decibel piece, 2026-10-08 — its
// PLAN 1.8 · 16.1, RUNNING_LOG §260). Loaded by boot.scd after sine.scd. A sine brick that says `gate 1` is no longer a sine that
// sounds for its span: it is ARMED for its span, silent until its player sounds at the written pitch, it enters with them at the
// written mark, FOLLOWS their rise and fall, holds through a breath, and leaves when they stop. No pitch is tracked: the sine
// keeps its written pitch — the player bends against it.
//
//   /le/sine  …  gate 1 · [player · ear · follow · capDb]         (sine.scd has the rest of the message)
//         gate      1 = the brick is a window (absent or 0: the sine sounds for its whole span, as before this file)
//         player    whose window — the name of a player (the piece's route table); a lane with no microphone says lane<N>
//         ear       mic — the player's microphone (a concert; in a simulation the rack's own sound, coming in where the
//                   microphone would) · sim — a level a score TELLS (/le/simlevel, below). Absent: the piece's (LE_TRACK earSim)
//         follow    how much of the player's CHANGE the sine takes: 1 = all of it · 0.5 = half · 0 = none (it enters and leaves
//                   with the player at its written mark and never moves). Absent: the piece's.
//         capDb     the most it moves, either way. Absent: the piece's.
//   /le/simlevel  player · [lane · id · t] · dueMs · lengthMs · [level · pass]
//         THE SIMULATED EAR: a score's simulated player is about to sound — for lengthMs, dueMs from now, at `level`: a MARK
//         (mf · 4 · 4.5) or a LINE of marks from the note's own start (0:p,end:f — as /le/sine's level). The engine puts that
//         level on the player's SIM BUS for the note's length, silence after. `pass` as /le/sine's: the first told level of a new
//         pass lets go of the pass before.
//
// THE LAW (the Decibel piece's RUNNING_LOG §255 · §256): two tones beat fully only at EQUAL loudness, so the sine wants to stand
// where the player stands — and the player's level cannot be known without a calibration of every microphone. So the tracker
// follows CHANGE, not level:
//       the sine's level = its WRITTEN mark + (the player's level now − their level at a REFERENCE) × follow, within ±capDb
// The reference is taken refMs after they enter. Any microphone, any placement: nothing is calibrated.
//
// HOW IT HEARS (one synth a sine, \leSineTrack — the ear and the voice in one, so nothing has to be put in order):
//   THE BAND     ear mic: the player's bus through a band-pass AT THE WRITTEN PITCH (rq — a semitone either side at the half
//                power), its peak in dB. The other players and the room fall away: in that band a room stands some 20 … 30 dB
//                under its own broadband figure. ear sim: the player's sim bus, as told.
//   THE GATE     it opens when the band stands over the THRESHOLD for openMs, and closes when it has stood under it for holdMs
//                (a re-breath never drops the sine). The sine rises in riseMs and falls in fallMs.
//                The threshold of a microphone, the first that the house gives (boot.scd LE_VENUE):
//                    roomBandDb + gateDb               the band's own room, measured at the sound check (calibrate.scd, the sine's bleed)
//                    roomDb + bandRelDb + gateDb       a broadband room figure, and the band's share of it
//                    floorDb                           nothing measured: the dial (a simulation's inputs are digital silence)
//   THE REFERENCE  latched refMs after the gate opens — each opening a fresh one; through a breath it stands.
//   THE FOLLOW   the band's level smoothed (attackMs up, releaseMs down) against the reference. A STOP IS NOT A DIMINUENDO:
//                when the level falls away faster than dropDbS decibels a second (it stands downDb under a ceiling that sinks
//                only that fast) or stands under the threshold — a breath, a bow change — the follower HOLDS what it had: the
//                sine does not sink in the gap and come back. It reads the level backMs late, so that what it holds is from
//                before the stop was known (measured: a stop is known some 45 ms after it), and takes the level up again
//                only when the player has been back that long.
//   THE GLISS    begins again at each ENTRY of the player — a rise after reMs of silence (the first too): each bowing gets the
//                approach or the departure that was drawn. The line is led by a jump of glissLeadMs to its first value.
//   /le/track    the synth tells the language when its gate opens and closes: a line in the window, each time.
//
//   ~le.trackOf                the dials — a piece's LE_TRACK over the defaults
//   ~le.trackThr(who)          a microphone's threshold, by the rule above
//   ~le.trackSpec(d, sp)       PURE: a message's fields -> the tracked sine's numbers, or nil (no gate: a plain sine)
//   ~le.trackFor(d, sp)        … with the buses: what sine.scd sinePlay adds to \leSineTrack's arguments — or nil, said
//   ~le.trackSimSpec(d)        PURE: a told level -> \leTrackSim's line in dB (a mark as its distance under fff)
//   ~le.trackSimPlay(d) · ~le.trackSimClear(keepPass) · ~le.trackSimBus(who)       the simulated ear
//   ~le.trackGuard             at a session's start: a player whose microphone hears the SINE too well follows nothing (the sound check)
//   ~le.trackHear              the message kinds, on the ear (session.scd)
//   ~le.trackDefs              the two SynthDefs (synths.scd adds them)
// Pure language but for trackFor · trackSim* · trackHear: proven offline (track_test.scd — the rules, and the two SynthDefs in NRT).
(
~le[\trackDefaults] = (follow: 1, capDb: 8, attackMs: 100, releaseMs: 500, gateDb: 10, bandRelDb: -20, floorDb: -60, openMs: 50, holdMs: 1500,
	refMs: 300, riseMs: 50, fallMs: 300, rq: 0.12, downDb: 6, dropDbS: 40, backMs: 150, reMs: 200, glissLeadMs: 5, earSim: 1, bleedUnderDb: 6, bleedOverRoomDb: 20);

~le[\trackOf] = { |self|
	var o = self[\trackDefaults].copy;
	if(self[\trackOpts].notNil) { self[\trackOpts].keysValuesDo({ |k, v| o[k] = v }) };
	o
};

// ---- the two SynthDefs ----------------------------------------------------------------------------------------------------
~le[\trackDefs] = { |self|
	if(self[\trackDefObjs].isNil) {
		self[\trackDefObjs] = [
			// leSineTrack — \leSine with an ear: the level line, the pitch line, the guard and the let-go are \leSine's own
			SynthDef(\leSineTrack, { |out = 0, in = 0, simBus = 0, ear = 0, freq = 220, dur = 4, amp = 1, gate = 1, id = 0,
					follow = 1, capDb = 8, thrDb = -60, rq = 0.12, atk = 0.1, rel = 0.5, openS = 0.05, holdS = 1.5, refS = 0.3,
					riseS = 0.05, fallS = 0.3, downDb = 6, dropDbS = 40, backS = 0.15, reS = 0.2|
				var db = \envDb.ir(-60 ! 8), dt = \envDt.ir(0.01 ! 7), cv = \envCurve.ir(0);
				var gc = \glissCents.ir(0 ! 8), gt = \glissDt.ir(0.01 ! 7);
				var mic, lvl, thr, above, opens, closes, g, quiet, sounding, refTrig, hasRef, ref, drop, can, sm, delta, gain, genv, mark, cents, guard, let, sig;
				// the ear: the band at the written pitch — or what a score tells
				mic = A2K.kr(Amplitude.ar(BPF.ar(In.ar(in, 1), freq.clip(20, 18000), rq.clip(0.01, 1)), 0.005, 0.08)).max(1e-6).ampdb;
				lvl = Select.kr(ear, [mic, In.kr(simBus, 1)]);
				thr = Select.kr(ear, [thrDb, -100]);
				// the gate: over the threshold for openS = open · under it for holdS = closed
				above = lvl > thr;
				opens = above * (Sweep.kr(above, 1) >= openS);
				closes = (1 - above) * (Sweep.kr(1 - above, 1) >= holdS);
				g = SetResetFF.kr(opens, closes);
				// an ENTRY: a rise after reS of silence — the first rise too (the gliss begins again there)
				quiet = (1 - above) * (Sweep.kr(1 - above, 1) >= reS);
				sounding = SetResetFF.kr(above, quiet);
				// the follow: the change since the reference. A STOP is not a diminuendo: when the level falls away faster than dropDbS
				// (it stands downDb under a ceiling that sinks only that fast), or stands under the threshold, the follower HOLDS what it had.
				// It reads the level backS LATE, so that what it holds is the level from BEFORE the stop was known; and it takes the
				// level up again only once the player has been back for backS and a little more — so it never reads the gap itself.
				refTrig = TDelay.kr(g, refS);
				hasRef = SetResetFF.kr(refTrig, 1 - g);
				drop = lvl < (Slew.kr(lvl.max(thr), 2000, dropDbS) - downDb);
				can = hasRef * above * (1 - drop);
				can = can * DelayN.kr(can, 1, backS + 0.05);
				sm = LagUD.kr(Gate.kr(DelayN.kr(lvl, 1, backS), (1 - hasRef) + can), atk, rel);
				// the reference: the followed level refS after the gate opened, held until it closes
				ref = Latch.kr(sm, refTrig);
				delta = (sm - ref) * hasRef;
				gain = Lag.kr((delta * follow).clip(capDb.neg, capDb), 0.05).dbamp;
				genv = EnvGen.kr(Env.asr(riseS, 1, fallS, \sin), g);
				SendReply.kr(Changed.kr(g), '/le/track', [id, g, lvl]);
				// the voice: \leSine's, its pitch line begun at each entry
				mark = EnvGen.kr(Env(db, dt, cv)).dbamp;
				cents = EnvGen.ar(Env(gc, gt, 0), sounding);
				guard = EnvGen.kr(Env([0, 1, 1, 0], [0.01, (dur - 0.04).max(0.01), 0.03], \sin), doneAction: 2);
				let = EnvGen.kr(Env.asr(0, 1, 0.05), gate, doneAction: 2);
				sig = SinOsc.ar(freq * (cents / 100).midiratio) * amp * mark * guard * let * genv * gain;
				Out.ar(out, [sig, sig]);
			}),
			// leTrackSim — a told level on a player's sim bus for a note's length, then silence written, then gone
			SynthDef(\leTrackSim, { |bus = 0, dur = 1|
				var db = \envDb.ir(-120 ! 8), dt = \envDt.ir(0.01 ! 7);
				var on = EnvGen.kr(Env([1, 1, 0, 0], [dur.max(0.01), 0.001, 0.03]), doneAction: 2);
				ReplaceOut.kr(bus, Select.kr(on > 0.5, [DC.kr(-120), EnvGen.kr(Env(db, dt, 0))]));
			}),
			// leTrackProbe — the loudest a band of a bus has stood since its last reset, in dB, on a control bus (the sound check)
			SynthDef(\leTrackProbe, { |in = 0, freq = 220, rq = 0.12, cb = 0, t_reset = 0|
				var a = A2K.kr(Amplitude.ar(BPF.ar(In.ar(in, 1), freq.clip(20, 18000), rq.clip(0.01, 1)), 0.005, 0.08));
				Out.kr(cb, RunningMax.kr(a, t_reset).max(1e-6).ampdb);
			})
		];
	};
	self[\trackDefObjs]
};

// ---- a microphone's threshold ---------------------------------------------------------------------------------------------
~le[\trackThr] = { |self, who|
	var o = self.trackOf, v = if(self[\venue].notNil) { self[\venue][who] }, num = { |x| x.asString.asFloat };
	case
	{ v.notNil and: { v[\roomBandDb].notNil } } { num.(v[\roomBandDb]) + o[\gateDb] }
	{ v.notNil and: { v[\roomDb].notNil } } { num.(v[\roomDb]) + o[\bandRelDb] + o[\gateDb] }
	{ o[\floorDb] }
};

// ---- a tracked sine's numbers, from its message (pure) ---------------------------------------------------------------------
~le[\trackSpec] = { |self, d, sp|
	var o, who, ear, follow, cap, bled, lead;
	if(d[\gate].isNil or: { d[\gate].asString.asFloat <= 0 }) { nil } {
		o = self.trackOf;
		who = (d[\player] ? ("lane" ++ (d[\lane] ? 0).asString)).asString.asSymbol;
		ear = if((d[\ear] ? if(o[\earSim] > 0) { "sim" } { "mic" }).asString == "mic") { \mic } { \sim };
		follow = (d[\follow] ? o[\follow]).asString.asFloat.clip(0, 2);
		bled = (ear == \mic) and: { self[\trackNoFollow].notNil } and: { self[\trackNoFollow][who] == true };
		if(bled) { follow = 0 };
		cap = (d[\capDb] ? o[\capDb]).asString.asFloat.clip(0, 24);
		lead = (o[\glissLeadMs] / 1000).max(0.002);
		(who: who, ear: ear, follow: follow, capDb: cap, thrDb: self.trackThr(who), bled: bled,
			// the pitch line begins again at each entry from wherever it stands: led by a jump to its own first value (its eighth point gives way)
			glissCents: [sp[\glissCents][0]] ++ sp[\glissCents].keep(7), glissDt: [lead] ++ sp[\glissDt].keep(6),
			args: [\ear, if(ear == \mic) { 0 } { 1 }, \follow, follow, \capDb, cap, \thrDb, self.trackThr(who), \rq, o[\rq],
				\atk, o[\attackMs] / 1000, \rel, o[\releaseMs] / 1000, \openS, o[\openMs] / 1000, \holdS, o[\holdMs] / 1000,
				\refS, o[\refMs] / 1000, \riseS, o[\riseMs] / 1000, \fallS, o[\fallMs] / 1000, \downDb, o[\downDb], \dropDbS, o[\dropDbS], \backS, (o[\backMs] / 1000).clip(0.01, 0.9), \reS, o[\reMs] / 1000])
	}
};

// ---- … with the buses: what sinePlay hands \leSineTrack — or nil (a plain sine), and why -----------------------------------
~le[\trackSimBus] = { |self, who|
	var b;
	if(self[\trackSim].isNil) { self[\trackSim] = IdentityDictionary.new };
	b = self[\trackSim][who];
	if(b.isNil) {
		b = Bus.control(self[\server], 1);
		self[\server].sendMsg("/c_set", b.index, -120);   // a control bus is born at 0 — which here would be a player at full
		self[\trackSim][who] = b;
	};
	b
};

~le[\trackFor] = { |self, d, sp|
	var t = self.trackSpec(d, sp), p, id;
	if(t.isNil) { nil } {
		p = if(self[\players].notNil) { self[\players][t[\who]] };
		if((t[\ear] == \mic) and: { p.isNil or: { self[\mode] == \remote } }) {
			self.say("LE_INFO", "sine · a window on " ++ t[\who] ++ "'s microphone, and there is none here"
				++ if(self[\mode] == \remote) { " (the remote mode)" } { "" } ++ " — it sounds for its whole span, as a plain sine");
			nil
		} {
			if(self[\trackNull].isNil) { self[\trackNull] = Bus.audio(self[\server], 1) };
			if(self[\trackIds].isNil) { self[\trackIds] = IdentityDictionary.new };
			self[\trackN] = ((self[\trackN] ? 0) + 1) % 4096;
			id = self[\trackN];
			self[\trackIds][id] = (who: t[\who], note: self.sineNote(sp[\midi]), ear: t[\ear]);
			t[\args] = t[\args] ++ [\in, if(p.notNil) { p[\bus].index } { self[\trackNull].index }, \simBus, self.trackSimBus(t[\who]).index, \id, id];
			t[\said] = " · a WINDOW on " ++ t[\who] ++ " (" ++ if(t[\ear] == \mic) { "its microphone, over " ++ t[\thrDb].round(0.1) ++ " dB in the band" } { "told by the score" }
				++ ") · follows × " ++ t[\follow].round(0.01) ++ " within ±" ++ t[\capDb].round(0.1) ++ " dB"
				++ if(t[\bled]) { " — FOLLOW 0: the sine bleeds into this microphone (the sound check)" } { "" };
			t
		}
	}
};

// ---- the simulated ear -----------------------------------------------------------------------------------------------------
// a told level -> \leTrackSim's line: a mark as its distance under fff, in dB (the ladder's step) — pure
~le[\trackSimSpec] = { |self, d|
	var lenMs = (d[\lengthMs] ? 1000).asString.asFloat.clip(20, 600000), step = self.levelOf[\stepDb];
	var pts = self.sinePoints(d[\level], lenMs, { |t| self.markNum(t) }, 4.0);
	var line = self.sineLine(pts.collect({ |p| [p[0], (p[1] - 7) * step] }));
	(dur: lenMs / 1000, pts: pts, envDb: line[\v], envDt: line[\dt])
};

// the told levels let go — all, or all but those of the pass `keep`; a bus no kept level stands on is silent again
~le[\trackSimClear] = { |self, keep|
	var s = self[\server], now = SystemClock.seconds, stay = List.new, n = 0;
	(self[\trackSims] ? []).do({ |x|
		if(x[\end] > now) {
			if(keep.notNil and: { x[\pass] == keep }) { stay.add(x) } {
				if(x[\start] > now) { s.sendBundle((x[\start] - now) + 0.002, x[\node].freeMsg, ["/c_set", x[\bus].index, -120]) }
				{ s.sendBundle(nil, x[\node].freeMsg, ["/c_set", x[\bus].index, -120]) };
				n = n + 1;
			};
		};
	});
	self[\trackSims] = stay;
	n
};

~le[\trackSimPlay] = { |self, d|
	var s = self[\server], who = (d[\player] ? '?').asString.asSymbol, due = ((d[\dueMs] ? 0).asString.asFloat / 1000).clip(0, 5), la = (self[\masterDelay] ? 0);
	var sp = self.trackSimSpec(d), bus = self.trackSimBus(who), at = (due - la).max(0), now = SystemClock.seconds, node = Synth.basicNew(\leTrackSim, s), pass = d[\pass];
	if(pass.notNil and: { self[\trackSimPass] != pass }) { self.trackSimClear(pass); self[\trackSimPass] = pass };
	s.sendBundle(if(at > 0.005) { at }, node.newMsg(self[\grpIn], [\bus, bus.index, \dur, sp[\dur], \envDb, sp[\envDb], \envDt, sp[\envDt]], \addToTail));
	self[\trackSims] = (self[\trackSims] ? List.new).reject({ |x| x[\end] < now }).asList;
	self[\trackSims].add((node: node, bus: bus, start: now + at, end: now + at + sp[\dur] + 0.05, pass: pass));
	self
};

// ---- the sound check's guard: a microphone that hears the SINE too well follows nothing --------------------------------------
// The house's numbers for a player (LE_VENUE): sineBleedDb — the sine alone at fff, in that microphone's band — against
// what the player's own mf stands at (a calibrated house: the ladder's mf) less bleedUnderDb, or, uncalibrated, the band's
// room plus bleedOverRoomDb. Over the line: follow 0 for that player, said.
~le[\trackGuard] = { |self|
	var o = self.trackOf, num = { |x| x.asString.asFloat };
	self[\trackNoFollow] = IdentityDictionary.new;
	if(self[\venue].notNil) {
		self[\venue].keysValuesDo({ |who, v|
			var bleed = if(v[\sineBleedDb].notNil) { num.(v[\sineBleedDb]) }, limit, why;
			if(bleed.notNil) {
				case
				{ v[\cal].notNil and: { self.markDb(\mf).notNil } } { limit = self.markDb(\mf) - o[\bleedUnderDb]; why = (self.markDb(\mf) - bleed).round(0.1).asString ++ " dB under its mf" }
				{ v[\roomBandDb].notNil } { limit = num.(v[\roomBandDb]) + o[\bleedOverRoomDb]; why = (bleed - num.(v[\roomBandDb])).round(0.1).asString ++ " dB over the room in its band" };
				if(limit.notNil and: { bleed > limit }) {
					self[\trackNoFollow][who] = true;
					self.say("LE_INFO", "track · " ++ who ++ " · the sine bleeds into this microphone at " ++ bleed.round(0.1) ++ " dB, " ++ why ++ " — FOLLOW 0: its sines enter and leave with it and do not move");
				};
			};
		});
	};
	self
};

// ---- the message kinds, on the ear -------------------------------------------------------------------------------------------
~le[\trackHear] = { |self|
	self.hear(\simlevel, { |le, d| le.trackSimPlay(d) });
	OSCdef(\leTrack, { |msg|
		var x = if(self[\trackIds].notNil) { self[\trackIds][msg[3].asInteger] };
		if(x.notNil) {
			self.say("LE_INFO", "sine · " ++ x[\note] ++ " · " ++ x[\who] ++ if(msg[4] > 0) { " ENTERED (" ++ msg[5].round(0.1) ++ " dB" ++ if(x[\ear] == \sim) { ", told" } { " in the band" } ++ ") — the sine comes in with it" } { " has stopped — the sine goes" });
		};
	}, '/le/track', self[\server].addr);
	self
};
)
