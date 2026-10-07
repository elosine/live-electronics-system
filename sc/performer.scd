// performer.scd — THE COMPUTER PLAYERS: the electronics as PERFORMERS who listen (the engine plan's part 11, re-read; first built
// in the Decibel piece, 2026-10-06 — its PLAN 1.6 · 14.4, RUNNING_LOG §189; docs/THREE_BODY.md § 4). Loaded by boot.scd after
// sine.scd. A performer is not a brick that returns one sample: it is IN A STATE for a stretch of time (a container), it HEARS
// the players' onsets, and it decides, sound by sound, when to play one of the samples it holds — by the state's rule.
//
//   /le/performer  id · state · [from · to] · t · dueMs · lengthMs · [offsetMs · wholeMs] · pal · [target · targetFrom] ·
//                  [seed · mark · silenceMs · ear · dials · pass · zone]
//       A CONTAINER BEGINS for the performer `id` (e1 …), dueMs from now ON THE ENGINE'S CLOCK, lengthMs long. Sent by the score
//       at each container's start; a playhead that starts inside one sends it with offsetMs (how far in) and wholeMs (its whole
//       length), so a change and a break know where they stand.
//         state        far · approaching · closePass · breakRejoin · change (then from · to: the two states it lies between)
//         pal          THE PALETTE: the names of the samples this performer plays, comma-separated — dealt round robin, shuffled
//                      once by its seed. The same palette in the next message keeps its place.
//         target       who it listens to in the state it is in (or goes to): a player's name · another performer's id ·
//                      `any` · `cluster` (whoever plays). targetFrom: the same for the state a change leaves.
//         mark         its dynamic on the players' ladder (level.scd) — mf where absent
//         silenceMs    a break's silence, from the container's own start
//         ear          sim — it hears what a score TELLS it (/le/onset … sim 1: a simulated player's note, announced)
//                      mic — it hears each player's microphone (the onset probe, boot.scd). One road each; never both.
//         dials        the piece's numbers over the defaults below:  beatLo=300,beatHi=900,…
//         pass         a number that changes when the score is started again or its playhead jumps: the first message of a
//                      NEW pass ends every performer of the pass before.
//   /le/performerstop  every performer stops (a score that stops)
//
// THE RULES (the same ones the piece's simulated players follow — its score/public/three_body_sim.js):
//   far          ITS OWN PACE — a gap drawn once per container (gapLo … gapHi), kept within ± jitter: a clock. It hears nothing.
//   approaching  on its target's onset it waits a BEAT (beatLo … beatHi), then one sound; never within holdMs of its own last.
//   closePass    just AFTER an onset (tightLo … tightHi) — or, beforeShare of the time, a BET: the target's next onset is
//                predicted from its last two, and the sound is played betLo … betHi BEFORE the prediction. A performer cannot
//                see a player breathe: the bet is all the anticipation it has. A prediction more than missMs wrong is a MISS —
//                said in the window when the target next plays.
//   unprompted   a listener (approaching · closePass) who has had nothing to answer for waitLo … waitHi plays one sound.
//   breakRejoin  silence for silenceMs; then it watches: `count` onsets of two players or more inside windowMs is a cluster; once one has been there
//                and nothing follows for breakGapMs, it enters within enterLo … enterHi and keeps its own pace from there.
//                With no cluster it enters at the last third of the container.
//   change       each decision is a coin weighted by the place in the container: the state before at its start, after at its end.
//   depth        a sound of generation depthA / depthC is not answered (0 = a player's note, a pace, an unprompted sound;
//                an answer is one more than what it answers) — or two performers would answer each other for ever.
//   guardMs      never WITH — the close pass's: a sound of it that would land inside guardMs of a known onset is moved to just after it.
// A performer hears the PLAYERS and the OTHER PERFORMERS (the engine tells them of each other's sounds as it plays them).
//
//   ~le.perfTake(d, now)          a message -> the performer's next container (made if it is new)
//   ~le.perfNote(who, at, gen)    an onset is known: every performer hears it
//   ~le.perfStep(p, t, dt, hz)    the performer's clockwork at time t -> the sounds now due [(atS, role, ref, refAt, gen, …)]
//   ~le.perfSound(p, play, t)     … one of them, played: the next sample of the palette, at the performer's mark
//   ~le.perfRun · ~le.perfStop    the 10 ms clock that steps them all · every performer ended
//   ~le.performerHear             the two message kinds on the ear (session.scd)
//   ~le.perfSimOnset(d) · ~le.perfMicOnset(name)   the two ears
// Everything but perfSound and perfRun is PURE LANGUAGE with the time handed in: proven with no server (performer_test.scd).
(
~le[\perfDefaults] = (
	gapLo: 2500, gapHi: 6000, jitter: 0.08,
	beatLo: 300, beatHi: 900, holdMs: 400, depthA: 3, waitALo: 2500, waitAHi: 6000,
	tightLo: 60, tightHi: 150, betLo: 40, betHi: 120, missMs: 250, beforeShare: 0.5, selfMs: 150, depthC: 2,
	waitCLo: 900, waitCHi: 2400, predictLo: 150, predictHi: 3000,
	windowMs: 1500, count: 3, breakGapMs: 450, enterLo: 40, enterHi: 220,
	guardMs: 25
);
~le[\perfNames] = (far: "far apart", approaching: "approaching", closePass: "close pass", breakRejoin: "break and rejoin", change: "change", idle: "idle");

// each performer's own dice (Lehmer): the same seed, the same decisions for the same things heard
~le[\perfRand] = { |self, p| p[\rs] = (p[\rs] * 16807.0) % 2147483647.0; p[\rs] / 2147483647.0 };
~le[\perfMs] = { |self, p, lo, hi| (lo + ((hi - lo) * self.perfRand(p))) / 1000 };   // a draw from a range of ms, in seconds
~le[\perfListens] = { |self, r| (r == \approaching) or: { r == \closePass } };
// the listening rule a container holds: its own, or the one a change goes to / comes from
~le[\perfListenRule] = { |self, c|
	case
	{ self.perfListens(c[\state]) } { c[\state] }
	{ c[\state] == \change } { case { self.perfListens(c[\to]) } { c[\to] } { self.perfListens(c[\from]) } { c[\from] } { true } { nil } }
	{ true } { nil }
};
~le[\perfWait] = { |self, p, r|
	var o = p[\o];
	if(r == \closePass) { self.perfMs(p, o[\waitCLo], o[\waitCHi]) } { self.perfMs(p, o[\waitALo], o[\waitAHi]) }
};
~le[\perfPaces] = { |self, p|
	var c = p[\c];
	c.notNil and: { (c[\state] == \far) or: { (c[\state] == \change) and: { (c[\from] == \far) or: { c[\to] == \far } } }
		or: { (c[\state] == \breakRejoin) and: { p[\rejoined] == true } } }
};
// the rule that decides at time t: the container's state — in a change, a coin weighted by the place in it
~le[\perfRule] = { |self, p, t|
	var c = p[\c], w;
	case
	{ c.isNil } { \idle }
	{ c[\state] != \change } { if((c[\state] == \breakRejoin) and: { p[\rejoined] == true }) { \far } { c[\state] } }
	{ c[\from] == \breakRejoin } { \far }   // back from the break it already keeps its own pace
	{ true } { w = (t - c[\start]) / (c[\end] - c[\start]).max(1e-6); if(self.perfRand(p) < w) { c[\to] } { c[\from] } }
};
~le[\perfStateSaid] = { |self, c|
	var n = self[\perfNames];
	if(c[\state] == \change) { "change (" ++ (n[c[\from]] ? c[\from]) ++ " → " ++ (n[c[\to]] ? c[\to]) ++ ")" } { (n[c[\state]] ? c[\state]).asString }
};

~le[\perfEnter] = { |self, p, t|
	var c = p[\c], o = p[\o], lr = self.perfListenRule(c);
	if(c[\state] == \far) {
		p[\gap] = self.perfMs(p, o[\gapLo], o[\gapHi]);
		if(p[\nextPace].isNil or: { p[\nextPace] < t }) { p[\nextPace] = t + (p[\gap] * (0.15 + (0.85 * self.perfRand(p)))) };
	};
	if(self.perfListens(c[\state])) { p[\nextPace] = nil };
	if(c[\state] == \breakRejoin) {
		p[\queue] = List.new; p[\bet] = nil; p[\armed] = false; p[\rejoined] = false; p[\nextPace] = nil;
		p[\silenceEnd] = c[\start] + c[\silence];
	};
	p[\waitUntil] = if(lr.notNil) { t + self.perfWait(p, lr) };
	self.say("LE_INFO", p[\id].asString ++ " → " ++ self.perfStateSaid(c) ++ " · " ++ (c[\end] - t).round(0.1) ++ " s"
		++ if(lr.notNil) { " · listening to " ++ (if(c[\state] == \change) { if(self.perfListens(c[\to])) { c[\target] } { c[\targetFrom] } } { c[\target] } ? \any) } { "" }
		++ if(c[\state] == \far) { " · a sound every " ++ p[\gap].round(0.01) ++ " s" } { "" }
		++ if(c[\state] == \breakRejoin) { " · silent for " ++ (p[\silenceEnd] - t).max(0).round(0.1) ++ " s" } { "" });
	self
};

// ---- what a performer does on hearing an onset --------------------------------------------------------------------------
~le[\perfHear] = { |self, p, who, at, gen|
	var c = p[\c], o = p[\o], hl, prevAny, r, tg, depth, own, at2, prev, iv, predicted, play, err;
	if(who != p[\id]) {
		hl = p[\heard][who] ? List.new; hl.add(at); if(hl.size > 4) { hl.removeAt(0) }; p[\heard][who] = hl;
		prevAny = p[\anyLast]; p[\anyLast] = at;
		if(p[\bet].notNil and: { (p[\bet][\who] == who) or: { p[\bet][\who] == \cluster } }) {   // the bet's answer
			err = ((at - p[\bet][\predicted]) * 1000).round(1);
			self.say("LE_INFO", p[\id].asString ++ " · the bet on " ++ p[\bet][\ref] ++ " · " ++ if(err.abs <= o[\missMs]) { "HIT" } { "MISS" }
				++ " — " ++ who ++ " played " ++ err.abs.asInteger ++ " ms " ++ if(err < 0) { "before" } { "after" } ++ " the prediction");
			p[\betLast] = (errMs: err, hit: err.abs <= o[\missMs]);
			p[\bet] = nil;
		};
		if(c.notNil) {
			r = self.perfRule(p, at);
			if(self.perfListens(r)) {
				tg = (if(c[\state] == \change) { if(r == c[\to]) { c[\target] } { c[\targetFrom] } } { c[\target] }) ? \any;
				if((tg == who) or: { tg == \any } or: { tg == \cluster }) {
					depth = if(r == \approaching) { o[\depthA] } { o[\depthC] };
					if(gen < depth) {
						own = p[\queue].inject(p[\lastOwn], { |m, q| max(m, q[\atS]) });
						if(r == \approaching) {
							at2 = at + self.perfMs(p, o[\beatLo], o[\beatHi]);
							if(((at2 - own) * 1000) >= o[\holdMs]) { p[\queue].add((atS: at2, gen: gen + 1, role: \beat, ref: who, refAt: at, rule: r)) };
						} {
							prev = if(tg == \cluster) { prevAny } { if(hl.size > 1) { hl[hl.size - 2] } };
							if((self.perfRand(p) < o[\beforeShare]) and: { prev.notNil }) {
								iv = (at - prev) * 1000;
								if((iv >= o[\predictLo]) and: { iv <= o[\predictHi] }) {
									predicted = at + (iv / 1000); at2 = predicted - self.perfMs(p, o[\betLo], o[\betHi]);
									if((at2 >= (at + ((o[\guardMs] + 10) / 1000))) and: { ((at2 - own) * 1000) >= o[\selfMs] }) {
										play = (atS: at2, gen: gen + 1, role: \bet, ref: who, refAt: at, rule: r, predicted: predicted);
										p[\bet] = (who: if(tg == \cluster) { \cluster } { who }, predicted: predicted, ref: who);
									};
								};
							};
							if(play.isNil) {
								at2 = at + self.perfMs(p, o[\tightLo], o[\tightHi]);
								if(((at2 - own) * 1000) >= o[\selfMs]) { play = (atS: at2, gen: gen + 1, role: \after, ref: who, refAt: at, rule: r) };
							};
							if(play.notNil) { p[\queue].add(play) };
						};
					};
				};
			};
		};
	};
	self
};

// an onset is known — a player's (from one of the two ears) or a performer's own sound: the others hear it
~le[\perfNote] = { |self, who, at, gen = 0|
	if(self[\performers].notNil and: { self[\performers].size > 0 }) {
		self[\perfOnsets] = self[\perfOnsets] ? List.new;
		self[\perfOnsets].add((atS: at, who: who));
		self[\performers].do({ |p| self.perfHear(p, who, at, gen) });
	};
	self
};

// ---- the clockwork: one performer at time t -> the sounds now due --------------------------------------------------------
// dt: the step it is called at · hz: how far ahead a sound is handed over (so the server places it to the sample)
~le[\perfStep] = { |self, p, t, dt = 0.01, hz = 0.03|
	var c, o = p[\o], out = List.new, r, lr, n, last, who, broke, alone, at2, play, moved, go, onsets = self[\perfOnsets] ? [];
	// 1 · the container: the next one begins; one that is over with nothing after it leaves the performer idle
	if(p[\next].notNil and: { p[\c].isNil or: { t >= p[\next][\beginAt] } }) { p[\c] = p[\next]; p[\next] = nil; self.perfEnter(p, t) };
	if(p[\c].notNil and: { t >= p[\c][\end] }) {
		self.say("LE_INFO", p[\id].asString ++ " · its container is over — idle");
		p[\c] = nil; p[\queue] = List.new; p[\bet] = nil; p[\waitUntil] = nil; p[\nextPace] = nil;
	};
	c = p[\c];
	if(c.notNil) {
		// 2 · its own pace
		if(self.perfPaces(p) and: { p[\nextPace].notNil } and: { (t + hz) >= p[\nextPace] }) {
			if(self.perfRule(p, p[\nextPace]) == \far) { p[\queue].add((atS: max(t, p[\nextPace]), gen: 0, role: \pace, rule: \far)) };
			if(p[\gap].isNil) { p[\gap] = self.perfMs(p, o[\gapLo], o[\gapHi]) };
			p[\nextPace] = p[\nextPace] + (p[\gap] * (1 + (((self.perfRand(p) * 2) - 1) * o[\jitter])));
		};
		// 3 · a listener who has heard nothing to answer
		if(p[\waitUntil].notNil and: { t >= p[\waitUntil] }) {
			r = self.perfRule(p, t); lr = self.perfListenRule(c);
			if(self.perfListens(r) and: { p[\queue].size == 0 }) { p[\queue].add((atS: t + dt, gen: 0, role: \unprompted, rule: r)) };
			p[\waitUntil] = if(lr.notNil) { t + self.perfWait(p, lr) };
		};
		// 4 · the break: silence, then in as a cluster breaks up
		if((c[\state] == \breakRejoin) and: { p[\rejoined] != true } and: { t >= p[\silenceEnd] }) {
			n = 0; last = -1e9; who = IdentitySet.new;
			onsets.do({ |x|
				if(x[\who] != p[\id]) {
					if((t - x[\atS]) <= (o[\windowMs] / 1000)) { n = n + 1; who.add(x[\who]) };
					if(x[\atS] > last) { last = x[\atS] };
				};
			});
			if((n >= o[\count]) and: { who.size >= 2 }) { p[\armed] = true };   // a cluster: several sounds close together, of more than one player
			broke = (p[\armed] == true) and: { ((t - last) * 1000) >= o[\breakGapMs] };
			alone = t >= (p[\silenceEnd] + (((c[\end] - p[\silenceEnd]) * 2) / 3));
			if(broke or: { alone }) {
				at2 = t + self.perfMs(p, o[\enterLo], o[\enterHi]);
				p[\queue].add((atS: at2, gen: 0, role: if(broke) { \rejoin } { \rejoinAlone }, rule: \breakRejoin));
				p[\rejoined] = true; p[\gap] = self.perfMs(p, o[\gapLo], o[\gapHi]); p[\nextPace] = at2 + p[\gap];
			};
		};
		// 5 · what is due is handed over — never WITH another
		if(p[\queue].size > 0) {
			p[\queue] = p[\queue].asArray.sort({ |a, b| a[\atS] < b[\atS] }).asList;
			go = true;
			while { go and: { p[\queue].size > 0 } and: { p[\queue][0][\atS] <= (t + hz) } } {
				play = p[\queue][0];
				if((c[\state] == \breakRejoin) and: { p[\rejoined] != true }) { p[\queue].removeAt(0) } {   // the break is silent
					moved = false;
					onsets.do({ |x|   // the guard is the close pass's ("as close as you can … without playing at the same time"): far apart ignores the others
						if((play[\rule] == \closePass) and: { x[\who] != p[\id] } and: { ((x[\atS] - play[\atS]).abs * 1000) < o[\guardMs] }) {
							play[\atS] = x[\atS] + ((o[\guardMs] + (15 * self.perfRand(p))) / 1000); moved = true;
						};
					});
					if(moved and: { play[\atS] > (t + hz) }) { go = false } {
						p[\queue].removeAt(0);
						play[\state] = c[\state];
						out.add(play);
						p[\lastOwn] = play[\atS];
						lr = self.perfListenRule(c);
						if(lr.notNil) { p[\waitUntil] = play[\atS] + self.perfWait(p, lr) };
					};
				};
			};
		};
	};
	out.asArray
};

// ---- a container arrives: /le/performer -----------------------------------------------------------------------------------
~le[\perfClear] = { |self|
	self[\performers] = IdentityDictionary.new;
	self[\perfOnsets] = List.new;
	self
};

~le[\perfTake] = { |self, d, now|
	var id = (d[\id] ? \e1).asString.asSymbol, p, o, pal, c, i, j, seed, pass = d[\pass];
	var num = { |k, def| if(d[k].isNil) { def } { d[k].asString.asFloat } };
	var sym = { |k, def| var v = d[k]; if(v.isNil or: { v.asString.size == 0 }) { def } { v.asString.asSymbol } };
	var due = (num.(\dueMs, 0) / 1000).clip(0, 5), len = (num.(\lengthMs, 1000) / 1000).max(0.05), off = (num.(\offsetMs, 0) / 1000).max(0);
	if(pass.notNil and: { self[\perfPass] != pass }) {   // a NEW PASS of the score: the performers of the pass before end first
		if(self[\performers].notNil and: { self[\performers].size > 0 }) { self.say("LE_INFO", "performers · a new pass — the pass before ends") };
		self.perfClear; self[\perfPass] = pass;
	};
	self[\performers] = self[\performers] ? IdentityDictionary.new;
	p = self[\performers][id];
	if(p.isNil) {
		seed = num.(\seed, 1).abs;
		p = (id: id, rs: (((seed * 7919) + 104729 + (id.hash.abs % 9973)) % 2147483646.0) + 1, queue: List.new, heard: IdentityDictionary.new,
			lastOwn: -1e9, palIx: 0, pal: [], palSent: "", rejoined: false, armed: false);
		self[\performers][id] = p;
	};
	o = self[\perfDefaults].copy;
	if(self[\perfOpts].notNil) { o.putAll(self[\perfOpts]) };
	(d[\dials] ? "").asString.split($,).do({ |kv| var b = kv.asString.split($=); if(b.size == 2) { o[b[0].asString.stripWhiteSpace.asSymbol] = b[1].asString.asFloat } });
	p[\o] = o;
	if(d[\pal].notNil and: { d[\pal].asString != p[\palSent] }) {   // a new palette: shuffled once by the performer's own dice
		p[\palSent] = d[\pal].asString;
		pal = p[\palSent].split($,).collect({ |x| self.safeName(x.asString.stripWhiteSpace) }).reject({ |x| x.size == 0 });
		i = pal.size - 1;
		while { i > 0 } { j = (self.perfRand(p) * (i + 1)).floor.asInteger.min(i); pal.swap(i, j); i = i - 1 };
		p[\pal] = pal; p[\palIx] = 0;
	};
	p[\mark] = (d[\mark] ? "mf").asString;
	if(d[\ear].notNil) { self[\perfEar] = d[\ear].asString.asSymbol };
	c = (state: sym.(\state, \far), from: sym.(\from, nil), to: sym.(\to, nil), target: sym.(\target, \any), targetFrom: sym.(\targetFrom, \any),
		beginAt: now + due, start: (now + due) - off, end: now + due + len, silence: num.(\silenceMs, 0) / 1000, zone: (d[\zone] ? "").asString);
	p[\next] = c;
	if(self[\perfManual] != true) { self.perfRun };
	p
};

// ---- a sound: the next sample of the palette, at the performer's mark ----------------------------------------------------
~le[\perfSaid] = { |self, p, play|
	var n = self[\perfNames], ms = { |a, b| ((a - b) * 1000).round(1).asInteger };
	p[\id].asString ++ " · " ++ (n[play[\rule]] ? play[\rule]) ++ " · " ++ switch(play[\role],
		\pace, { "its own pace" },
		\beat, { "a beat after " ++ play[\ref] ++ " (+" ++ ms.(play[\atS], play[\refAt]) ++ " ms)" },
		\after, { "just after " ++ play[\ref] ++ " (+" ++ ms.(play[\atS], play[\refAt]) ++ " ms)" },
		\bet, { "a BET before " ++ play[\ref] ++ "'s next (predicted " ++ ms.(play[\predicted], play[\atS]) ++ " ms on)" },
		\unprompted, { "unprompted — nothing to answer" },
		\rejoin, { "REJOINS — a cluster broke up" },
		\rejoinAlone, { "rejoins — no cluster came" },
		{ play[\role].asString })
};
~le[\perfSound] = { |self, p, play, t|
	var s = self[\server], la = (self[\masterDelay] ? 0), name, sk, lv, when = (play[\atS] - t - la).max(0);
	if(p[\pal].size == 0) { self.say("LE_INFO", self.perfSaid(p, play) ++ " — NO PALETTE: nothing sounds") } {
		name = p[\pal].wrapAt(p[\palIx]); p[\palIx] = p[\palIx] + 1;
		sk = self.sampleFor(name);
		if(sk.isNil) { self.say("LE_INFO", self.perfSaid(p, play) ++ " · " ++ name ++ " — no such sample in the bank") } {
			lv = if(self[\levelFor].notNil) { self.levelFor(sk[\row], (dyn: p[\mark])) };
			s.makeBundle(if(when > 0.005) { when }, {
				Synth(\leSample, [\out, self[\busMaster].index, \buf, sk[\buf].bufnum] ++ if(lv.notNil) { self.levelArgs(lv) } { [] }, self[\grpFx], \addToTail);
			});
			self.say("LE_INFO", self.perfSaid(p, play) ++ " · " ++ name);
		};
	};
	self
};

// ---- the clock: every 10 ms each performer is stepped, its sounds played and told to the others ------------------------------
~le[\perfRun] = { |self|
	if(self[\perfRoutine].isNil) {
		self[\perfRoutine] = Routine({
			var dt = 0.01, hz = 0.03, t, idle = 0;
			while { self[\performers].notNil and: { self[\performers].size > 0 } } {
				t = thisThread.seconds;
				try {
					self[\perfOnsets] = (self[\perfOnsets] ? List.new).select({ |x| x[\atS] > (t - 6) }).asList;
					self[\performers].values.do({ |p|
						self.perfStep(p, t, dt, hz).do({ |play|
							self.perfSound(p, play, t);
							self.perfNote(p[\id], play[\atS], play[\gen]);
						});
					});
					if(self[\performers].values.every({ |p| p[\c].isNil and: { p[\next].isNil } })) { idle = idle + dt } { idle = 0 };
					if(idle > 3) { self.perfClear };   // nobody has a container: the clock rests until the next message
				} { |err| self.say("LE_ERROR", "performer · " ++ err.errorString) };
				dt.wait;
			};
			self[\perfRoutine] = nil;
		}).play(SystemClock);
	};
	self
};

~le[\perfStop] = { |self|
	var n = if(self[\performers].notNil) { self[\performers].size } { 0 };
	self.perfClear;
	if(n > 0) { self.say("LE_INFO", "performers · stopped — " ++ n ++ " ended") };
	self
};

// ---- the two ears -----------------------------------------------------------------------------------------------------------
// sim: a score tells the engine a simulated player's note is about to sound (/le/onset player · dueMs · sim 1)
~le[\perfSimOnset] = { |self, d|
	var due = ((d[\dueMs] ? 0).asString.asFloat / 1000).clip(0, 5);
	if((self[\perfEar] ? \sim) == \sim) { self.perfNote((d[\player] ? '?').asString.asSymbol, SystemClock.seconds + due, 0) };
	self
};
// mic: a player's own sound arrived at its microphone (the onset probe)
~le[\perfMicOnset] = { |self, name|
	if(self[\perfEar] == \mic) { self.perfNote(name.asString.asSymbol, SystemClock.seconds, 0) };
	self
};

~le[\performerHear] = { |self|
	self.hear(\performer, { |le, d| le.perfTake(d, SystemClock.seconds) });
	self.hear(\performerstop, { |le, d| le.perfStop });
	self
};
)
