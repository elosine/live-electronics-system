// sine.scd — THE GENERATED VOICES: a sound the engine MAKES, where the bank's are sounds it caught (the engine plan's part 5,
// re-read; first built in the Decibel piece, 2026-10-06 — its PLAN 1.5 · 12.1, RUNNING_LOG §177). Loaded by boot.scd after
// level.scd. Its first member is a SINE: a pitch, a length, a level that is a LINE and a pitch that may GLIDE — the tone a
// player holds a long note against and bends until the two beat.
//
//   /le/sine  id · lane · t · dueMs · midi · lengthMs · [level · levelCurve · gliss · pass]
//       THE SINE. Played to the master dueMs from now ON THE ENGINE'S CLOCK — it starts where the score's brick is, as a return
//       does, earlier by the master's look-ahead.
//         midi         the pitch as a MIDI number WITH its cents: 57 = A3 · 57.12 = A3 + 12 cents
//         lengthMs     how long it sounds (a 10 ms rise and a 30 ms fall stand inside it)
//         level        a MARK — mf · 4 · 4.5 (ppp = 0 … fff = 7, fractions between; below 0 goes on down, 4 dB a step) — or a
//                      LINE of them, breakpoints from the sine's own start:   0:mp,3000:f,end:p   (ms:mark; ms may be `end`).
//                      Eight points at the most. Absent = mf. levelCurve: one curve for every segment (0 = straight in
//                      decibels — an even hairpin to the ear).
//         gliss        a line of CENTS against the pitch:   0:-28,end:0   — the sine starts 28 cents under and arrives.
//                      Straight in cents. Absent = it holds its pitch.
//         pass         a number that changes when the score is started again or its playhead jumps: the first sine of a NEW
//                      pass lets go of every sine of the pass before (so no message has to arrive before another to do it).
//                      Absent (an audition): no pass, nothing let go.
//         gate · player · ear · follow · capDb     THE SINE AS A WINDOW ON A PLAYER (track.scd, 2026-10-08): with `gate 1` it is
//                      armed for its span and silent until its player sounds at this pitch; it enters with them at its level,
//                      follows their rise and fall, holds through a breath, leaves when they stop; its gliss begins again at
//                      each entry. Absent: it sounds for its whole span, as it always did.
//   /le/sinestop     every sine sounding lets go in 50 ms (a score that stops: a long tone must not hang over the silence);
//                     one begun AFTER the word is not touched — each sine is known by its own node
//
// THE LEVEL IS EXACT — a sine's loudness needs no measurement. A mark is a loudness on the players' ladder (level.scd markDb:
// fff = `reference` LUFS, 4 dB a step); BS.1770 reads a sine of peak A on BOTH channels (as \leSine sends it) as
//       LUFS = −0.691 + 20·log10(A) + K(f)
// with K(f) the K-weighting's gain at the sine's own frequency, from level.scd's two filters (kGainDb, below: +0.69 dB at
// 1 kHz, about −0.3 at 220 Hz, +3 and more above 2 kHz — a crotale's octave is played that much softer for the same mark).
// So the peak for a mark is  markDb + 0.691 − K(f) : ONE ladder for the samples and the sines, moved by the piece's one number.
// The K is taken at the written pitch; a glide of some cents does not move it.
//
//   ~le.kGainDb(freq)         the K-weighting's gain at a frequency, dB
//   ~le.markNum(token)        a mark as a NUMBER: a name or a number -> 0 … 7 (fractions kept; −10 the floor)
//   ~le.sineGain(freq, mark)  the PEAK in dBFS of a sine that reads that mark
//   ~le.sineSpec(d)           a message's fields -> (freq · dur · envDb 8 · envDt 7 · curve · glissCents 8 · glissDt 7 · …)
//   ~le.sineArgs(sp)          … as \leSine takes them          ~le.sineSaid(sp)   … as the window says them
//   ~le.sinePlay(d) · ~le.sineStop · ~le.sineHear   the two message kinds, on the ear (session.scd — with or without a bank)
// Pure language but for sinePlay and sineStop: proven offline (sine_test.scd).
(
~le[\kGainDb] = { |self, freq, sr|
	var rate = sr ? self[\sr] ? 48000, co = self.kCoefs(rate), w = 2pi * freq.clip(1, rate * 0.49) / rate;
	10 * log10((self.kGain2(co[\shelf], w) * self.kGain2(co[\hp], w)).max(1e-12))
};

~le[\markNum] = { |self, token|
	var t = (token ? "mf").asString.stripWhiteSpace, i = self[\levelMarks].indexOf(t.asSymbol);
	if(i.notNil) { i.asFloat } {
		if((t.size > 0) and: { "0123456789.-+".includes(t[0]) }) { t.asFloat.clip(-10, 7) } { 4.0 }
	}
};

~le[\sineGain] = { |self, freq, mark|
	var o = self.levelOf;
	(o[\reference] - ((7 - mark) * o[\stepDb]) + 0.691 - self.kGainDb(freq)).min(-3)
};

// "ms:value,ms:value" (ms may be `end`), or one bare value -> up to 8 points [ms, value], in time order, the first at 0
~le[\sinePoints] = { |self, text, lenMs, valueOf, default|
	var pts = List.new;
	(text ? "").asString.stripWhiteSpace.split($,).do({ |x|
		var b = x.asString.stripWhiteSpace.split($:);
		case
		{ b.size >= 2 } { pts.add([if(b[0].asString.stripWhiteSpace == "end") { lenMs } { b[0].asString.asFloat.clip(0, lenMs) }, valueOf.value(b[1])]) }
		{ (b.size == 1) and: { b[0].asString.size > 0 } } { pts.add([0, valueOf.value(b[0])]) };
	});
	pts = pts.asArray.sort({ |p, q| p[0] < q[0] });
	if(pts.size == 0) { pts = [[0, default]] };
	if(pts[0][0] > 0) { pts = [[0, pts[0][1]]] ++ pts };
	pts.keep(8)
};

// the points as an envelope's two arrays: 8 values, 7 times in seconds, the last value held
~le[\sineLine] = { |self, pts|
	var v = pts.collect({ |p| p[1] }), dt = Array.fill(pts.size - 1, { |i| ((pts[i + 1][0] - pts[i][0]) / 1000).max(0.005) });
	while { v.size < 8 } { v = v.add(v.last) };
	while { dt.size < 7 } { dt = dt.add(0.01) };
	(v: v, dt: dt)
};

~le[\sineSpec] = { |self, d|
	var midi = (d[\midi] ? 57).asString.asFloat.clip(0, 135), lenMs = (d[\lengthMs] ? 4000).asString.asFloat.clip(50, 600000);
	var freq = midi.midicps;
	var lp = self.sinePoints(d[\level], lenMs, { |t| self.markNum(t) }, 4.0);
	var gp = self.sinePoints(d[\gliss], lenMs, { |t| t.asString.asFloat.clip(-2400, 2400) }, 0.0);
	var lv = self.sineLine(lp.collect({ |p| [p[0], self.sineGain(freq, p[1])] })), gl = self.sineLine(gp);
	(freq: freq, midi: midi, dur: lenMs / 1000, levelPts: lp, glissPts: gp, envDb: lv[\v], envDt: lv[\dt],
		glissCents: gl[\v], glissDt: gl[\dt], curve: (d[\levelCurve] ? 0).asString.asFloat.clip(-8, 8))
};

~le[\sineArgs] = { |self, sp|
	[\freq, sp[\freq], \dur, sp[\dur], \envDb, sp[\envDb], \envDt, sp[\envDt], \envCurve, sp[\curve], \glissCents, sp[\glissCents], \glissDt, sp[\glissDt]]
};

// a pitch as its name with its cents: 57.12 -> "A3 +12c"
~le[\sineNote] = { |self, midi|
	var n = midi.round.asInteger, c = ((midi - n) * 100).round.asInteger;
	["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][n % 12] ++ ((n div: 12) - 1)
		++ if(c != 0) { " " ++ if(c > 0) { "+" } { "" } ++ c ++ "c" } { "" }
};

~le[\sineSaid] = { |self, sp|
	var mk = { |m| var i = m.round.asInteger.clip(0, 7), r = (m - i).round(0.1); self[\levelMarks][i].asString ++ if(r != 0) { if(r > 0) { "+" } { "" } ++ r } { "" } };
	var lv = sp[\levelPts], gl = sp[\glissPts];
	self.sineNote(sp[\midi]) ++ " · " ++ sp[\freq].round(0.01) ++ " Hz · " ++ sp[\dur].round(0.01) ++ " s · "
		++ lv.collect({ |p| mk.(p[1]) }).join(" → ") ++ " (peak " ++ sp[\envDb].maxItem.round(0.1) ++ " dB)"
		++ if(gl.any({ |p| p[1] != 0 })) { " · gliss " ++ gl.collect({ |p| p[1].round(0.1) }).join(" → ") ++ " c" } { "" }
};

// ---- the sine: /le/sine -----------------------------------------------------------------------------------------------
~le[\sinePlay] = { |self, d|
	var s = self[\server], due = ((d[\dueMs] ? 0).asString.asFloat / 1000).clip(0, 5), la = (self[\masterDelay] ? 0);
	var sp = self.sineSpec(d), at = (due - la).max(0), now = SystemClock.seconds, pass = d[\pass], gone = 0, node, spT = sp;
	// A WINDOW (track.scd): the message says `gate 1` — the sine is armed for its span, in with its player, following them, out with them.
	// nil: a plain sine, as before (no gate said — or no ear to hear the player with, which trackFor says in the window)
	var tr = if(self[\trackFor].notNil) { try { self.trackFor(d, sp) } { |e| self.say("LE_INFO", "sine · the tracker failed (" ++ e.errorString ++ ") — a plain sine"); nil } };
	if(tr.notNil) { spT = sp.copy; spT[\glissCents] = tr[\glissCents]; spT[\glissDt] = tr[\glissDt] };
	node = Synth.basicNew(if(tr.notNil) { \leSineTrack } { \leSine }, s);
	// a NEW PASS of the score (it was started again, or the playhead jumped): the sines of the pass before let go first
	if(pass.notNil and: { self[\sinePass] != pass }) { gone = self.sineLetGo(pass); self[\sinePass] = pass };
	s.sendBundle(if(at > 0.005) { at }, node.newMsg(self[\grpFx], [\out, self[\busMaster].index] ++ self.sineArgs(spT) ++ if(tr.notNil) { tr[\args] } { [] }, \addToTail));
	// each sine is remembered until its length is over — by its own node, so a stop lets go of THESE and of none begun after it
	self[\sines] = (self[\sines] ? List.new).reject({ |x| x[\end] < now }).asList;
	self[\sines].add((node: node, start: now + at, end: now + at + sp[\dur] + 0.1, pass: pass));
	if(gone > 0) { self.say("LE_INFO", "sine · a new pass — " ++ gone ++ " of the pass before let go") };
	self.say("LE_INFO", "sine · " ++ self.sineSaid(sp) ++ " · in " ++ (at * 1000).round(1).asInteger ++ " ms" ++ if(tr.notNil) { tr[\said] } { "" });
	self.say("LE_RESULT", self.json((msg: "sine", id: (d[\id] ? "").asString, midi: sp[\midi], hz: sp[\freq].round(0.01),
		lengthMs: (sp[\dur] * 1000).round(1), dueMs: (at * 1000).round(0.1), peakDb: sp[\envDb].maxItem.round(0.1))));
	self
};

// the remembered sines let go — all, or all but those of the pass `keep`: one that sounds, by its gate (50 ms); one sent ahead
// that has not begun is freed as it begins. Answers how many.
~le[\sineLetGo] = { |self, keep|
	var s = self[\server], now = SystemClock.seconds, n = 0, stay = List.new;
	(self[\sines] ? []).do({ |x|
		if(x[\end] > now) {
			if(keep.notNil and: { x[\pass] == keep }) { stay.add(x) } {
				if(x[\start] > now) { s.sendBundle((x[\start] - now) + 0.002, x[\node].freeMsg) } { s.sendBundle(nil, x[\node].setMsg(\gate, 0)) };
				n = n + 1;
			};
		};
	});
	self[\sines] = stay;
	n
};

~le[\sineStop] = { |self|
	var n = self.sineLetGo(nil);
	if(self[\trackSimClear].notNil) { self.trackSimClear(nil) };   // the levels a score told (track.scd): silence on every sim bus
	if(n > 0) { self.say("LE_INFO", "sine · stopped — " ++ n ++ " let go") };
	self
};

~le[\sineHear] = { |self|
	self.hear(\sine, { |le, d| le.sinePlay(d) });
	self.hear(\sinestop, { |le, d| le.sineStop });
	self
};
)
