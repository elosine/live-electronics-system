// petals_live.scd — THE PETALS LIVE: a player's microphone straight into the composer's petals of resonance, IN REAL TIME
// (first built in the Decibel piece, 2026-10-07 — its PLAN 10.14 · DEC-46 · RUNNING_LOG §230 … §232; the engine's §57).
// Loaded by boot.scd after process.scd; its SynthDef is made in synths.scd, once the server is up.
//
// WHY. A processed return is an OFFLINE render, made from a capture some seconds after it (process.scd — the plan). That is right
// for a return placed LATER in the score. A return placed AT ITS OWN MIC OPENING cannot be that render: the sound it is made of
// is only now being played. Until this file it played the take before (or the sample raw, or the backup's) — never the live
// impulse through the filter. Here it is the live impulse: the window opens, the player plays into it, the bank rings at once.
// Concert and simulation are one road (the piece's D10): in the simulation the DAW's sampler on the player's bus IS the player.
//
// THE RULE — nothing new in a score, nothing new in a message. At /le/open (bank.scd captureOpen), before anything else:
//     the PLAN (process.scd planTake) has a variant of THIS sample  ·  whose first use lies within `windowMs` (300) after the
//     opening's start (10 ms of grace before it)  ·  whose effect is `petalsOrig`, ended by its `tail`, its dials the petals' own
//  →  \lePetalsLive starts on the player's input bus with that variant's dials, its window the opening's.
// At the /le/play for that variant (bank.scd samplePlay): the synth's LEVEL is set for the message's dyn · env, and NO BUFFER IS
// PLAYED — one source, never two. A /le/play for any other name is as it was. The capture, its crop, its banking and the plan's
// offline render of the variant go on unchanged — the record, and what a LATER return of the same variant plays.
// Not live: a petals stacked with another stage · a dial on a line · an envelope other than tail · the mode \remote (no
// microphones there) · `on` 0. Such a return takes the offline road, as before.
//
// THE SYNTH — \lePetalsLive (petalsLiveDef):
//     the microphone — In.ar(in) × inAmp — through A WINDOW: it opens `wait` s after the synth is made (the opening's own start;
//     the message comes ahead of it) and closes `win` s later, 10 ms of fade. Then the input is shut and the bank rings on.
//     ~le.petalsGraph (process.scd) — HIS SynthDef's lines, the same as the offline chain's — with his three envelopes started BY
//     THE WINDOW: his 20 ms rise and his fall over `input length` are the microphone's gate, as he wrote them for a microphone.
//     THE ATTACK ENTERS WHOLE: the window is open before the note. (An offline render of a cropped sample starts his rise ON the
//     attack, and softens its first 20 ms — which is why the plan's render of a live variant is made "as live": below.)
//     THE END is a tail's: it frees itself once it has fallen 60 dB under its own peak, or `cap` s after the window (150 ms fade).
//     THE LEVEL is \leSample's law: envDb (8) · envDt (7) · envCurve, joined in decibels — set by /le/play (`on` 1 · t_go), and
//     until then the synth is SILENT: a return whose brick is muted in the score makes no sound, though its window was opened.
//
// THE LEVEL IS BY CONSTRUCTION — nothing is measured when it plays. The offline road gives a variant three gains: the DRIVE
// before the chain (the source brought to driveRef, held under full scale), the LEVEL SET after it (the render's peak matched to
// its source's), and the PLAY gain (the mark against the render's own loudness, the lift capped — level.scd). Each render now
// writes the first two into its row as numbers (driveDb · outGainDb) and how late its source entered (preMs). A live petals is
// played with EXACTLY those three, from the LATEST render of the same variant made as live — the take before, or the backup's
// (liveRef). So for the same sound in, the live petals IS that render, to the decibel; a louder attack rings louder, a softer
// one softer — the player leads, as in a hall. His limiter is inside the graph: the drive goes in BEFORE it, as offline.
//     NO SUCH RENDER YET (a hit never captured · a bank from before this file) — or its sample reads UNDER ppp (a capture that
//     caught next to nothing: its gains would crush a real note in his limiter): the level is ESTIMATED and the window says so —
//     the input to driveRef by the sample's own loudness (mf when it has none), the bank's output taken as driveRef + kDb. The
//     capture that follows is rendered as live, and the next pass is exact. livePlanCheck renders a missing one as soon as a plan
//     arrives, when the sample is already in the bank.
//     AS LIVE (liveRowPre): the plan's render of such a variant is given preMs — the gap from the window's opening to the
//     cropped sample's first frame: the row's attackMs − leadMs (how far ahead of the window the recording began; a capture
//     writes it since this file) − the crop's pre-roll.
//
//   ~le.liveOf                 the dials: on · windowMs · leadMs (a row without one) · kDb (the estimate) — a piece's LE_LIVE over the defaults
//   ~le.liveIsOn               on, and not \remote
//   ~le.liveKind(r)            a plan's row as a live petals -> (args: \lePetalsLive's dials, mix:) or nil
//   ~le.liveAt(r, openT)       does the row's first use sit at the opening that starts at openT?
//   ~le.liveRowOf(name)        a sample's row — the write bank's, else the one its buffer was filled from (the backup's)
//   ~le.liveRowPre(r)          the preMs the plan's render of r is made with, or nil when r is not a live petals at its opening
//   ~le.liveRef(variant, base) -> (inDb:, outDb:, row:, exact:) — the gains above
//   ~le.liveOpen(d)            /le/open: the synth begins; the variant is remembered as SERVED. Answers its record, or nil.
//   ~le.livePlay(d, name, due) /le/play: a served variant's level is set. Answers true when it was — then no buffer is played.
//   ~le.livePlanCheck          the reference renders a new plan still lacks, queued. Answers how many.
// Pure language but for the two bundles: proven offline (petals_live_test.scd — the synth in NRT, the rule with no server).
(
// kDb: MEASURED on the Decibel piece's six hits through their own petals (2026-10-07, its RUNNING_LOG §232): the bank's output stood
// +6.6 … +16.9 dB over its input in loudness (his limiter included) — 14 is the middle of the six, a little to the quiet side
~le[\liveDefaults] = (on: 1, windowMs: 300, leadMs: 90, kDb: 14);
~le[\liveDials] = [\poFund, \poFirst, \poSpread, \poOffset, \poRingLo, \poRingHi, \poInLen, \poBloom, \poDrive, \poHold];

~le[\liveOf] = { |self|
	var o = self[\liveDefaults].copy;
	if(self[\liveOpts].notNil) { o.putAll(self[\liveOpts]) };
	o
};

~le[\liveIsOn] = { |self| (self.liveOf[\on] > 0) and: { self[\mode] != \remote } };

// ---- the synth --------------------------------------------------------------------------------------------------------
~le[\petalsLiveDef] = { |self|
	if(self[\petalsLiveDefObj].isNil) {
		self[\petalsLiveDefObj] = SynthDef(\lePetalsLive, { |in = 0, out = 0, wait = 0, win = 0.5, cap = 16, inAmp = 1, mix = 1, on = 0, t_go = 0,
				poFund = 200, poFirst = 2, poSpread = 0.33, poOffset = 0.25, poRingLo = 7.75, poRingHi = 9.5, poInLen = 1, poBloom = 0, poDrive = 6, poHold = 6|
			var db = \envDb.kr(0 ! 8), dt = \envDt.kr(0.01 ! 7), cv = \envCurve.kr(0);
			var open, mic, back, g, wet, lvl, amp, pk, age;
			open = Sweep.kr(0, 1) >= wait;                                  // the window opens: his envelopes start here
			mic = In.ar(in, 1) * inAmp * EnvGen.ar(Env([1, 1, 0], [(win - 0.01).max(0.01), 0.01]), open);   // … and closes; before it his own rise holds the input shut
			back = LocalIn.ar(1).asArray[0];                                // the loop around the bank (poBloom; nothing while it is 0)
			g = self.petalsGraph(mic, back, poFund, poFirst, poSpread, poOffset, poRingLo, poRingHi, poInLen, poBloom, poDrive, poHold, open);
			LocalOut.ar([g[1]]);
			wet = g[0] * (mix.clip(0, 1) * 0.5pi).sin;                      // the chain's mix law (XFade2), the wet side — the dry is the player, in the room
			// the end, a tail's: 60 dB under its own peak (never before the window has closed), or the cap
			age = Sweep.kr(open, 1) * open;
			amp = A2K.kr(Amplitude.ar(wet, 0.005, 0.3));
			pk = RunningMax.kr(amp);
			FreeSelf.kr((age > (win + 0.5)) * (amp < (pk * 0.001).max(1e-7)));
			wet = wet * EnvGen.kr(Env([1, 1, 0], [win + cap, 0.15]), open, doneAction: 2);
			// the level: \leSample's envelope, begun by /le/play (t_go) — silent until then
			lvl = EnvGen.kr(Env(db, dt, cv), t_go).dbamp * Lag.kr(on, 0.005);
			Out.ar(out, [wet, wet] * lvl);
		});
	};
	self[\petalsLiveDefObj]
};

// ---- the rule ---------------------------------------------------------------------------------------------------------
// a plan's row as a LIVE petals: its dials as \lePetalsLive takes them — or nil when the live road cannot make it
~le[\liveKind] = { |self, r|
	var dials = self[\liveDials], args = List.new, mix = 1, text = (r[\args] ? "").asString, ok;
	ok = ((r[\effect] ? "").asString == "petalsOrig") and: { (r[\end] ? "").asString == "tail" } and: { text.includes($@).not };
	if(ok) {
		text.split($,).do({ |kv|
			var b = kv.asString.stripWhiteSpace.split($:), k;
			if(b.size == 2) {
				k = b[0].asString.stripWhiteSpace.asSymbol;
				case
				{ k == \poMix } { mix = b[1].asString.asFloat }
				{ dials.includes(k) } { args.add(k); args.add(b[1].asString.asFloat) }
				{ true } { ok = false };   // a dial of another stage: a stack — the offline road
			};
		});
	};
	if(ok and: { mix > 0 }) { (args: args.asArray, mix: mix) } { nil }
};

~le[\liveAt] = { |self, r, openT|
	var w = self.liveOf[\windowMs] / 1000;
	(r[\t] >= (openT - 0.01)) and: { r[\t] <= (openT + w) }
};

~le[\liveRowOf] = { |self, name|
	var nm = (name ? "").asString, row = (self[\indexRows] ? []).detect({ |x| x[\name].asString == nm }), e;
	if(row.isNil) {
		e = if(self[\samples].notNil) { self[\samples][nm.asSymbol] };
		if(e.notNil) { row = e[\row] };
	};
	row
};

~le[\liveRowPre] = { |self, r|
	var o = self.liveOf, b, crop;
	if(self.liveIsOn and: { self.liveKind(r).notNil }) {
		b = self.liveRowOf(r[\base]);
		if(b.notNil and: { b[\scoreTime].notNil } and: { self.liveAt(r, b[\scoreTime].asFloat) }) {
			crop = (self[\cropOpts] ? ())[\preMs] ? self[\cropDefaults][\preMs];
			((b[\attackMs] ? 0).asFloat - (b[\leadMs] ? o[\leadMs]).asFloat - crop).clip(0, (b[\windowMs] ? 500).asFloat).round(0.1)
		}
	}
};

// ---- the level --------------------------------------------------------------------------------------------------------
~le[\liveRef] = { |self, variant, base|
	var row = self.liveRowOf(variant), b = self.liveRowOf(base), o = self.liveOf, lv = self.levelOf, mf = self.markDb(\mf), inLoud, inDb;
	// A WEAK SAMPLE IS NOT TRUSTED: one that reads under ppp is a capture that caught next to nothing (the Decibel piece's viola hit,
	// banked at −55.8 LUFS from a key that barely sounded — its render was driven +35.8 dB). A live note played through THOSE gains
	// would be crushed in his limiter; the level is estimated from mf instead, until a real take is in.
	var weak = b.notNil and: { b[\loudDb].notNil } and: { b[\loudDb].asFloat < self.markDb(\ppp) };
	if(weak.not and: { row.notNil } and: { row[\preMs].notNil } and: { row[\outGainDb].notNil } and: { row[\driveDb].notNil }) {
		(inDb: row[\driveDb].asFloat, outDb: row[\outGainDb].asFloat, row: row, exact: true, weak: false)
	} {
		inLoud = if(weak.not and: { b.notNil } and: { b[\loudDb].notNil }) { b[\loudDb].asFloat } { mf };
		inDb = (lv[\driveRef] - inLoud).clip(-40, 40);
		if(weak.not and: { b.notNil } and: { b[\peakDb].notNil }) { inDb = inDb.min(-1 - b[\peakDb].asFloat) };   // held under full scale, as a render's drive is
		// the bank's output taken as driveRef + kDb; said as a sample at mf that has been given the difference — so a mark's lift stays under the cap
		(inDb: inDb, outDb: mf - (lv[\driveRef] + o[\kDb]), row: (loudDb: mf, lengthMs: 1000), exact: false, weak: weak)
	}
};

// ---- /le/open ---------------------------------------------------------------------------------------------------------
~le[\liveOpen] = { |self, d|
	var s = self[\server], name = self.safeName(d[\name]), who = (d[\player] ? '?').asSymbol, p = if(self[\players].notNil) { self[\players][who] };
	var openT = (d[\t] ? 0).asFloat, now = SystemClock.seconds, r, kind, variant, ref, node, win, wait, cap, sv, fund;
	if(self.liveIsOn and: { p.notNil } and: { name.size > 0 } and: { self[\plan].notNil }) {
		r = self[\plan].detect({ |x| (x[\base] == name) and: { self.liveAt(x, openT) } and: { self.liveKind(x).notNil } });
	};
	if(r.notNil) {
		kind = self.liveKind(r);
		variant = name ++ "~" ++ r[\suffix];
		ref = self.liveRef(variant, name);
		win = (d[\lengthMs] ? 500).asFloat.clip(20, 30000) / 1000;
		wait = ((d[\dueMs] ? 0).asFloat / 1000).clip(0, 5);
		cap = (if((r[\capMs] ? 0) > 0) { r[\capMs] } { 16000 }) / 1000;
		// made NOW, its window opening by itself `wait` later: the node is there when /le/play sets its level
		if(s.notNil) {
			node = Synth.basicNew(\lePetalsLive, s);
			s.sendBundle(nil, node.newMsg(self[\grpFx], [\in, p[\bus].index, \out, self[\busMaster].index, \wait, wait, \win, win, \cap, cap,
				\inAmp, ref[\inDb].dbamp, \mix, kind[\mix]] ++ kind[\args], \addToTail));
		};
		sv = (node: node, variant: variant, base: name, player: who, ref: ref, kind: kind, wait: wait, win: win, cap: cap, until: now + wait + win + cap + 1);
		if(self[\liveServed].isNil) { self[\liveServed] = IdentityDictionary.new };
		self[\liveServed][variant.asSymbol] = sv;
		fund = kind[\args].indexOf(\poFund);
		self.say("LE_INFO", "live · " ++ name ++ " → " ++ r[\suffix] ++ " · the petals" ++ if(fund.notNil) { " at " ++ kind[\args][fund + 1] ++ " Hz" } { "" }
			++ " · the microphone open " ++ (win * 1000).round(1).asInteger ++ " ms, in " ++ (wait * 1000).round(1).asInteger ++ " ms · driven "
			++ if(ref[\inDb] >= 0) { "+" } { "" } ++ ref[\inDb].round(0.1) ++ " dB"
			++ if(ref[\exact]) { "" } { " · LEVEL ESTIMATED — " ++ if(ref[\weak]) { "its banked sample reads under ppp and is not trusted; exact once a real take is in" }
				{ "no render of this variant made as live yet; exact once one is in" } });
	};
	sv
};

// ---- /le/play ---------------------------------------------------------------------------------------------------------
~le[\livePlay] = { |self, d, name, due|
	var s = self[\server], key = (name ? "").asString.asSymbol, sv = if(self[\liveServed].notNil) { self[\liveServed][key] };
	var now = SystemClock.seconds, la = (self[\masterDelay] ? 0), lv, at;
	if(sv.isNil or: { sv[\until] < now }) { false } {
		lv = self.levelFor(sv[\ref][\row], d, sv[\ref][\outDb]);
		at = ((due ? 0) - la).max(0);
		if(s.notNil and: { sv[\node].notNil }) {
			s.sendBundle(if(at > 0.005) { at }, sv[\node].setMsg(\on, 1, \envDb, lv[\db], \envDt, lv[\dt], \envCurve, lv[\curve], \t_go, 1));
		};
		sv[\level] = lv;
		self.say("LE_INFO", "live · " ++ name ++ " · the petals ring from the microphone — no buffer · in " ++ (at * 1000).round(1).asInteger ++ " ms · "
			++ if(lv[\db][0] >= 0) { "+" } { "" } ++ lv[\db][0].round(0.1) ++ " dB" ++ self.levelSaid(lv) ++ if(sv[\ref][\exact]) { "" } { " · estimated" });
		self.say("LE_RESULT", self.json((msg: "play", name: name.asString, id: (d[\id] ? "").asString, dueMs: (at * 1000).round(0.1), live: true,
			gainDb: lv[\db][0].round(0.01), driveDb: sv[\ref][\inDb].round(0.01), exact: sv[\ref][\exact])));
		true
	}
};

// ---- a new plan: the reference renders it still lacks -------------------------------------------------------------------
~le[\livePlanCheck] = { |self|
	var n = 0, names = List.new;
	if(self.liveIsOn and: { self[\planAdd].notNil } and: { self[\bankDir].notNil }) {
		(self[\plan] ? []).do({ |r|
			var v, row;
			if(self.liveRowPre(r).notNil) {
				v = r[\base] ++ "~" ++ r[\suffix];
				row = self.liveRowOf(v);
				if((row.isNil or: { row[\preMs].isNil } or: { row[\outGainDb].isNil }) and: { self.processFile(r[\base]).notNil }
						and: { self[\processBusy].includes(v.asSymbol).not }) {
					self.planAdd(r); names.add(v); n = n + 1;
				};
			};
		});
		if(n > 0) {
			self.say("LE_INFO", "live · " ++ n ++ if(n == 1) { " petals" } { " petals" } ++ " at their own opening have no render made as live yet — rendering now, for their level: " ++ names.join(" · "));
			self.planNext;
		};
	};
	n
};
)
