// strike.scd — THE STRIKE WINDOW: the ensemble strikes; the electronics takes ONLY the onset times (and each onset's loudness) from
// the players at once — the microphones POOLED, one voice — and answers AFTER the strike with a version of its RHYTHM on the banked
// impulses, one sample a player (first built in the Decibel piece, 2026-10-09 — its PLAN 1.9 · 17.1, RUNNING_LOG §297; the page's
// score/le_strike.js). Loaded by boot.scd after performer.scd.
//
//   /le/strike  id · t · dueMs · lengthMs · [offsetMs · wholeMs] · type · timing · seed · gapMs · level · deal · [players · samples ·
//               processed · answerOf] · dials · pass · zone · lane
//       A WINDOW OPENS dueMs from now ON THE ENGINE'S CLOCK, lengthMs long: every onset inside it (a hair before, for a note the window
//       was drawn on) is collected with its level. The strike is OVER gapMs after its last onset (with one heard), or at the window's
//       end + gapMs at the latest; then THE ANSWER: the onsets' rhythm TRANSFORMED (type) · placed after the last onset (timing) · one
//       banked sample a player, dealt over the answer's onsets (deal) · each at the level of the onset it came from (level mimic) or at
//       a mark · played on the pattern path (bank.scd samplePlay, behaviour pattern) — the SAME path a composed rhythm takes.
//         type        asPlayed · retrograde · invert · spread · compress · scramble · rotate · thin · thicken
//         timing      rightAfter · aBeatLater · callResponse · muchLater · inLaterWindow
//         seed        the window's dice (a Lehmer generator, the performers'): the page's preview draws the same
//         dials       the piece's numbers: lo=1.5,hi=3 (the transformation's draw) · copyLo · copyHi (thicken) · wLo · wHi (the timing's) · minMs
//         level       mimic · a mark        deal   robin · all        players   a,b,c (the engine's names; absent = every player in the bank)
//         samples     names, dealt in order (absent = the bank: one a player, a shuffled deck each, none twice until all are used)
//         processed   1: the processed versions in the deck beside the captures
//         envs        [§337] the endings a processed version must have to be in the deck (perc,expodec — the index row's end); absent = any
//         cats        [§337] the categories a capture must have to be in the deck (impulse — the index row's category; a processed version
//                     goes by its source's, the name before the ~); absent = any
//         answerOf    an EARLIER window's id: THIS answer takes THAT strike's onsets (the come-back) — every strike heard is kept
//         mode        [the Decibel piece's 17.3] notated · open — a word of the score's; the engine listens the same way to both, and says it
//         graceMs     [17.3] how long after the window's END an onset still belongs to it (absent = gapMs, as before) — small where the
//                     windows stand close, so the next strike's first onset is not taken by this window
//         chain       [17.3] THE CASCADE — type:timing:seed,type:timing:seed: FURTHER answers. Answer 1 is the window's own (type · timing ·
//                     seed) on the strike's rhythm; each link transforms the rhythm of the ANSWER BEFORE IT and begins by its timing after
//                     that answer's last onset; its samples dealt afresh from the decks. dials2 · dials3 …: each link's own numbers, as
//                     `dials` is answer 1's. `answers` (the count) is said for the reader; the chain is what is read.
//   /le/strikestop   every window dropped (a score that stops); the strikes heard are kept for a come-back until the next pass
//   /le/onset … sim 1 · mark   the simulated ear (the page): session.scd hands it to strikeSimOnset
//   the microphones: session.scd's onHeard hands each probe's hit to strikeMicOnset (ear \mic) — a rise out of silence only: a
//   detector of attacks is the concert's (the piece's 17.5; NITS)
//
//   ~le.strikeTake(d, now)                 a message -> a window record
//   ~le.strikeOnset(who, at, mark)         an onset is known: every open window that holds `at` collects it
//   ~le.strikeStep(w, t)                   the window's clockwork at time t -> its answer when the strike is over (once), else nil
//   ~le.strikeAnswer(w, ons)               PURE: the onsets -> (onsets:, afterMs:, pattern:, dyn:) — the transformation, the timing, the deal
//   ~le.strikeCascade(w, first)            PURE: the window's chain -> the further answers, each from the one before (the page's StrikeCalc.cascade)
//   ~le.strikeTransform(type, ons, dd, w)   PURE: the same function as the page's StrikeCalc.transform, the draws in the same order
//   ~le.strikeTiming(kind, lenMs, dd, w)    PURE: … StrikeCalc.timing
//   ~le.strikePlay(w, ans, t)              the answer handed to samplePlay at its time
//   ~le.strikeRun · ~le.strikeStop         the 20 ms clock that steps the windows · every window dropped
//   ~le.strikeHear                         the message kinds on the ear (session.scd)
// Everything but strikePlay and strikeRun is PURE LANGUAGE with the time handed in: proven with no server (strike_test.scd).
(
~le[\strikeDefaults] = (
	gapMs: 500,
	// the catalogue's numbers (the piece's bank/strike_responses.json), as the page sends them; a message's dials override
	spread: (lo: 1.5, hi: 3), compress: (lo: 0.3, hi: 0.7), thin: (lo: 0.3, hi: 0.5), thicken: (lo: 0.3, hi: 0.5, copyLo: 40, copyHi: 120),
	rightAfter: (wLo: 0.3, wHi: 0.8), aBeatLater: (wLo: 1, wHi: 2), callResponse: (wLo: 0.8, wHi: 1.2, minMs: 300),
	muchLater: (wLo: 6, wHi: 15), inLaterWindow: (wLo: 10, wHi: 15)
);
~le[\strikeTypes] = [\asPlayed, \retrograde, \invert, \spread, \compress, \scramble, \rotate, \thin, \thicken];
~le[\strikeTimings] = [\rightAfter, \aBeatLater, \callResponse, \muchLater, \inLaterWindow];
~le[\strikeTypeNames] = (asPlayed: "as played", retrograde: "retrograde", invert: "inverted", spread: "spread", compress: "compressed", scramble: "scrambled", rotate: "rotated", thin: "thinned", thicken: "thickened");
~le[\strikeTimingNames] = (rightAfter: "right after", aBeatLater: "a beat later", callResponse: "call and response", muchLater: "much later", inLaterWindow: "in a later window");
~le[\strikeMarks] = [\ppp, \pp, \p, \mp, \mf, \f, \ff, \fff];
~le[\strikeMarkIx] = { |self, m| self[\strikeMarks].indexOf((m ? \mf).asSymbol) ? 4 };

// the dice: the window's own Lehmer state, seeded as the page seeds it — the same seed, the same draws on both sides
~le[\strikeSeed] = { |self, seed| ((((seed ? 1).asFloat.max(1).round * 7919) + 104729) % 2147483646) + 1 };
~le[\strikeRand] = { |self, w| w[\rs] = (w[\rs] * 16807.0) % 2147483647.0; w[\rs] / 2147483647.0 };
~le[\strikeDraw] = { |self, w, lo, hi| lo + ((hi - lo) * self.strikeRand(w)) };
~le[\strikeShuffle] = { |self, w, arr|   // Fisher–Yates, the page's: i from the end, j = floor(r · (i + 1))
	var a = arr.copy, i = a.size - 1, j;
	while { i > 0 } { j = (self.strikeRand(w) * (i + 1)).floor.asInteger.min(i); a.swap(i, j); i = i - 1 };
	a
};
~le[\strikeNum] = { |self, dd, k, def| if(dd.notNil and: { dd[k].notNil }) { dd[k].asFloat } { def } };
~le[\strikeRebuild] = { |self, gaps, marks|
	var out = List.new, t = 0;
	out.add((atMs: 0, mark: marks[0]));
	gaps.do({ |g, i| t = t + g; out.add((atMs: t, mark: marks[i + 1])) });
	out.asArray
};

// ---- the transformation: a list of (atMs from the first, mark) -> a new list; the gaps are the material ----------------------
~le[\strikeTransform] = { |self, type, ons, dd, w|
	var n = ons.size, marks, gaps, m, def, f, k, idx, drop, share, pick, out, seq;
	if(n == 0) { [] } {
		marks = ons.collect({ |o| o[\mark] }); gaps = if(n > 1) { (1..(n - 1)).collect({ |i| ons[i][\atMs] - ons[i - 1][\atMs] }) } { [] }; m = gaps.size;   // (1..0) would be [1, 0] in SC
		switch(type.asSymbol,
			\retrograde, { var span = ons[n - 1][\atMs]; ons.collect({ |o, i| (atMs: span - ons[n - 1 - i][\atMs], mark: ons[n - 1 - i][\mark]) }) },
			\invert, { if(m == 0) { ons.collect({ |o| (atMs: o[\atMs], mark: o[\mark]) }) } { var hi = gaps.maxItem, lo = gaps.minItem; self.strikeRebuild(gaps.collect({ |g| hi + lo - g }), marks) } },
			\spread, { f = self.strikeDraw(w, self.strikeNum(dd, \lo, 1.5), self.strikeNum(dd, \hi, 3)); self.strikeRebuild(gaps.collect({ |g| g * f }), marks) },
			\compress, { f = self.strikeDraw(w, self.strikeNum(dd, \lo, 0.3), self.strikeNum(dd, \hi, 0.7)); self.strikeRebuild(gaps.collect({ |g| g * f }), marks) },
			\scramble, { self.strikeRebuild(self.strikeShuffle(w, gaps), marks) },
			\rotate, { if(m < 2) { ons.collect({ |o| (atMs: o[\atMs], mark: o[\mark]) }) } { k = 1 + (self.strikeRand(w) * (m - 1)).floor.asInteger; self.strikeRebuild(gaps.drop(k) ++ gaps.keep(k), marks) } },
			\thin, {
				share = self.strikeDraw(w, self.strikeNum(dd, \lo, 0.3), self.strikeNum(dd, \hi, 0.5)); k = (share * n).round.asInteger.clip(0, n - 1);
				idx = self.strikeShuffle(w, if(n > 1) { (1..(n - 1)) } { [] }); drop = idx.keep(k);
				ons.collect({ |o, i| if(drop.includes(i)) { nil } { (atMs: o[\atMs], mark: o[\mark]) } }).reject(_.isNil)
			},
			\thicken, {
				share = self.strikeDraw(w, self.strikeNum(dd, \lo, 0.3), self.strikeNum(dd, \hi, 0.5)); k = (share * n).round.asInteger.clip(0, n);
				pick = self.strikeShuffle(w, (0..(n - 1))).keep(k).sort;
				out = ons.collect({ |o, i| (atMs: o[\atMs], mark: o[\mark], seq: i) }).asList; seq = n;
				pick.do({ |i| out.add((atMs: ons[i][\atMs] + self.strikeDraw(w, self.strikeNum(dd, \copyLo, 40), self.strikeNum(dd, \copyHi, 120)), mark: ons[i][\mark], seq: seq)); seq = seq + 1 });
				out.asArray.sort({ |a, b| (a[\atMs] < b[\atMs]) or: { (a[\atMs] == b[\atMs]) and: { a[\seq] < b[\seq] } } }).collect({ |o| (atMs: o[\atMs], mark: o[\mark]) })
			},
			{ ons.collect({ |o| (atMs: o[\atMs], mark: o[\mark]) }) }
		)
	}
};
// ---- the timing: how long after the strike's LAST onset the answer's first onset falls (ms) ------------------------------------
~le[\strikeTiming] = { |self, kind, lenMs, dd, w|
	var def = self[\strikeDefaults][kind.asSymbol] ? self[\strikeDefaults][\rightAfter];
	if(kind.asSymbol == \callResponse) {
		max(self.strikeNum(dd, \minMs, def[\minMs] ? 300), lenMs) * self.strikeDraw(w, self.strikeNum(dd, \wLo, def[\wLo]), self.strikeNum(dd, \wHi, def[\wHi]))
	} {
		self.strikeDraw(w, self.strikeNum(dd, \wLo, def[\wLo]), self.strikeNum(dd, \wHi, def[\wHi])) * 1000
	}
};

// ---- the samples: a deck a player, shuffled by the window's dice when empty — none twice until all are used -------------------
~le[\strikePlayers] = { |self|   // every player the bank holds a capture for, in name order
	var set = IdentitySet.new;
	if(self[\samples].notNil) { self[\samples].keysValuesDo({ |k, e| var r = e[\row]; if(r.notNil and: { r[\player].notNil } and: { r[\kind].asString != "processed" }) { set.add(r[\player].asString.asSymbol) } }) };
	set.asArray.collect(_.asString).sort.collect(_.asSymbol)
};
// [§337, DEC-113] THE POOL'S FILTERS: a processed version is in only with `processed` and an allowed ENDING (envs: the row's end); a row is in
// only with an allowed CATEGORY (cats: the row's category — a processed version by its SOURCE's, the name before the ~). nil or empty = any.
// (compared by CONTENT: an Array's includes is by identity in SC — ["perc"].includes("perc") is false; measured by the test, §337)
~le[\strikePool] = { |self, player, processed, envs, cats|
	var out = List.new;
	var rowOf = { |name| var e = self[\samples][name.asSymbol]; if(e.notNil) { e[\row] } { nil } };
	var isProc = { |r| r[\kind].asString == "processed" };
	var envOk = { |r| if(isProc.(r).not) { true } { processed and: { envs.isNil or: { envs.size == 0 } or: { envs.any({ |x| x.asString == r[\end].asString }) } } } };
	var catOk = { |r| var src; if(cats.isNil or: { cats.size == 0 }) { true } { src = if(isProc.(r)) { rowOf.(r[\name].asString.split($~)[0]) } { r }; src.notNil and: { cats.any({ |x| x.asString == src[\category].asString }) } } };
	if(self[\samples].notNil) { self[\samples].keysValuesDo({ |k, e| var r = e[\row]; if(r.notNil and: { r[\player].asString == player.asString } and: { envOk.(r) } and: { catOk.(r) }) { out.add(k.asString) } }) };
	out.asArray.sort
};
~le[\strikeNext] = { |self, w, player|
	var decks = self[\strikeDecks] ? IdentityDictionary.new, key = (player.asString ++ if(w[\processed]) { "+" } { "" } ++ "|" ++ (w[\envs] ? []).join("/") ++ "|" ++ (w[\cats] ? []).join("/")).asSymbol, deck = decks[key], pool;   // [§337] a deck per filter
	self[\strikeDecks] = decks;
	if(deck.isNil or: { deck.size == 0 }) {
		pool = self.strikePool(player, w[\processed], w[\envs], w[\cats]);
		deck = if(pool.size > 0) { self.strikeShuffle(w, pool).asList } { List.new };
		decks[key] = deck;
	};
	if(deck.size > 0) { deck.removeAt(0) } { nil }
};

// ---- the answer, pure: the onsets -> the transformation, the timing, the deal, the level ---------------------------------------
~le[\strikeAnswer] = { |self, w, ons|
	var dd = w[\dials], out, lenMs, afterMs, players, names, offset, pattern = List.new, base, baseDb, said = List.new, dyn, give;
	w[\rs] = self.strikeSeed(w[\seed]);   // the draws begin again from the seed: the page's preview drew the same
	out = self.strikeTransform(w[\type], ons, dd, w);
	lenMs = if(ons.size > 0) { ons.last[\atMs] - ons.first[\atMs] } { 0 };
	afterMs = self.strikeTiming(w[\timing], lenMs, dd, w);
	// the level: mimic — the loudest mark present is the base; each onset so many dB under it (the ladder's step); a mark — every onset at it, 0 dB
	if(w[\level] == \mimic) {   // the loudest mark present is the base (an unknown mark reads as mf)
		base = out.inject(\ppp, { |m, o| if(self.strikeMarkIx(o[\mark]) > self.strikeMarkIx(m)) { self[\strikeMarks][self.strikeMarkIx(o[\mark])] } { m } });
	} { base = if(self[\strikeMarks].includes(w[\level])) { w[\level] } { \mf } };
	baseDb = if(self[\markDb].notNil) { self.markDb(base) };
	// the samples: named, dealt in order — or a deck a player
	players = if(w[\players].notNil and: { w[\players].size > 0 }) { w[\players] } { self.strikePlayers };
	if(w[\samples].notNil and: { w[\samples].size > 0 }) { names = w[\samples]; players = nil };
	offset = if(players.notNil and: { players.size > 1 }) { (self.strikeRand(w) * players.size).floor.asInteger.min(players.size - 1) } { 0 };
	give = { |o, i, k| var nm = if(names.notNil) { names.wrapAt(k) } { self.strikeNext(w, players.wrapAt(k + offset)) }, db;
		if(nm.notNil) {
			db = if(w[\level] == \mimic and: { baseDb.notNil }) { (self.markDb(self[\strikeMarks][self.strikeMarkIx(o[\mark])]) ? baseDb) - baseDb } { 0 };
			pattern.add(nm.asString ++ ":" ++ (o[\atMs].round(0.1)) ++ ":" ++ db.round(0.1));
			said.add(nm.asString);
		};
	};
	out.do({ |o, i|
		if(w[\deal] == \all and: { players.notNil }) { players.do({ |p, k| give.(o, i, k) }) } { give.(o, i, i) };
	});
	(onsets: out, afterMs: afterMs, lenMs: lenMs, pattern: pattern.join(","), dyn: "mark:" ++ base, base: base, samples: said.asArray, players: players ? [])
};
// ---- THE CASCADE, pure [the Decibel piece's 17.3, DEC-120]: the window's chain -> its further answers. Each link is the window with the
// link's own type · timing · seed · dials, answering THE ANSWER BEFORE IT (its onsets the material, never the strike's again); it begins
// at that answer's start + its span + the link's timing. The decks go on from where the answer before left them: other samples each time.
~le[\strikeCascade] = { |self, w, first|
	var out = List.new, prev = first, total = (w[\chain] ? []).size + 1;
	(w[\chain] ? []).do({ |lk, i|
		var wk = w.copy, a, span;
		wk[\type] = lk[\type]; wk[\timing] = lk[\timing]; wk[\seed] = lk[\seed]; wk[\dials] = lk[\dials]; wk[\rs] = 0;
		a = self.strikeAnswer(wk, prev[\onsets]);
		span = prev[\onsets].inject(0, { |m, o| max(m, o[\atMs]) });
		a[\atS] = prev[\atS] + (span / 1000) + (a[\afterMs] / 1000); a[\k] = i + 2; a[\heard] = first[\heard]; a[\source] = first[\source];
		self.say("LE_INFO", "strike · " ++ w[\id] ++ " · answer " ++ (i + 2) ++ " of " ++ total ++ " · " ++ self[\strikeTypeNames][lk[\type]] ++ " of answer " ++ (i + 1)
			++ " · " ++ self[\strikeTimingNames][lk[\timing]] ++ " → " ++ a[\onsets].size ++ " onsets, " ++ (a[\atS] - first[\atS]).round(0.01) ++ " s after answer 1 began"
			++ " · " ++ a[\dyn] ++ " · " ++ a[\samples].join(" "));
		out.add(a); prev = a;
	});
	out.asArray
};

// ---- a window arrives: /le/strike -------------------------------------------------------------------------------------------------
~le[\strikeClear] = { |self, keepHeard = true|
	self[\strikeWins] = List.new;
	if(keepHeard.not) { self[\strikeHeard] = IdentityDictionary.new; self[\strikeDecks] = IdentityDictionary.new };
	self
};
~le[\strikeTake] = { |self, d, now|
	var num = { |k, def| if(d[k].isNil) { def } { d[k].asString.asFloat } };
	var str = { |k, def| var v = d[k]; if(v.isNil or: { v.asString.size == 0 }) { def } { v.asString } };
	var list = { |k| var v = d[k]; if(v.isNil or: { v.asString.size == 0 }) { nil } { v.asString.split($,).collect({ |x| self.safeName(x.asString.stripWhiteSpace) }).reject({ |x| x.size == 0 }) } };
	var due = (num.(\dueMs, 0) / 1000).clip(0, 60), len = (num.(\lengthMs, 2000) / 1000).max(0.05), off = (num.(\offsetMs, 0) / 1000).max(0), pass = d[\pass], w, dd = ();   // the page sends a window ~100 ms ahead; a minute is the guard
	if(pass.notNil and: { self[\strikePass] != pass }) {   // a NEW PASS of the score: the windows of the pass before are dropped, the strikes heard forgotten
		if(self[\strikeWins].notNil and: { self[\strikeWins].size > 0 }) { self.say("LE_INFO", "strike · a new pass — the windows of the pass before are dropped") };
		self.strikeClear(false); self[\strikePass] = pass;
	};
	self[\strikeWins] = self[\strikeWins] ? List.new; self[\strikeHeard] = self[\strikeHeard] ? IdentityDictionary.new;
	(d[\dials] ? "").asString.split($,).do({ |kv| var b = kv.asString.split($=); if(b.size == 2) { dd[b[0].asString.stripWhiteSpace.asSymbol] = b[1].asString.asFloat } });
	w = (id: str.(\id, "W?").asSymbol, start: (now + due) - off, beginAt: now + due, end: now + due + len, gapS: num.(\gapMs, self[\strikeDefaults][\gapMs]).max(50) / 1000,
		type: str.(\type, "asPlayed").asSymbol, timing: str.(\timing, "rightAfter").asSymbol, seed: num.(\seed, 1), dials: dd,
		level: str.(\level, "mimic").asSymbol, deal: str.(\deal, "robin").asSymbol, players: list.(\players), samples: list.(\samples), processed: num.(\processed, 1) > 0,
		envs: list.(\envs), cats: list.(\cats),   // [§337] the deck's filters
		answerOf: if(d[\answerOf].notNil and: { d[\answerOf].asString.size > 0 }) { d[\answerOf].asString.asSymbol }, zone: str.(\zone, ""), onsets: List.new, over: false, rs: 0);
	if(self[\strikeTypes].includes(w[\type]).not) { self.say("LE_INFO", "strike · " ++ w[\id] ++ " · no such rhythm '" ++ w[\type] ++ "' — as played"); w[\type] = \asPlayed };
	if(self[\strikeTimings].includes(w[\timing]).not) { self.say("LE_INFO", "strike · " ++ w[\id] ++ " · no such timing '" ++ w[\timing] ++ "' — right after"); w[\timing] = \rightAfter };
	// [17.3] the mode's word, and THE CASCADE: the links as type:timing:seed, each with its own dials (dials2 for answer 2 …); four at the most
	w[\mode] = str.(\mode, "");
	// [17.3] graceMs: how long after the window's END an onset still belongs to it — by default the gap (as before). Windows that stand close
	// say less, so that the next strike's first onset is not taken by this one; the gap stays the silence that ends a strike.
	w[\graceS] = if(d[\graceMs].notNil) { num.(\graceMs, 0).max(0) / 1000 } { w[\gapS] };
	w[\chain] = List.new;
	if(d[\chain].notNil and: { d[\chain].asString.size > 0 }) {
		d[\chain].asString.split($,).do({ |x, i|
			var f = x.asString.split($:), ddk = (), lk;
			if(f.size >= 2 and: { w[\chain].size < 4 }) {
				(d[("dials" ++ (i + 2)).asSymbol] ? "").asString.split($,).do({ |kv| var b = kv.asString.split($=); if(b.size == 2) { ddk[b[0].asString.stripWhiteSpace.asSymbol] = b[1].asString.asFloat } });
				lk = (type: f[0].asString.stripWhiteSpace.asSymbol, timing: f[1].asString.stripWhiteSpace.asSymbol, seed: if(f.size > 2) { f[2].asString.asFloat.max(1) } { w[\seed] + i + 1 }, dials: ddk);
				if(self[\strikeTypes].includes(lk[\type]).not) { self.say("LE_INFO", "strike · " ++ w[\id] ++ " · answer " ++ (i + 2) ++ ": no such rhythm '" ++ lk[\type] ++ "' — as played"); lk[\type] = \asPlayed };
				if(self[\strikeTimings].includes(lk[\timing]).not) { self.say("LE_INFO", "strike · " ++ w[\id] ++ " · answer " ++ (i + 2) ++ ": no such timing '" ++ lk[\timing] ++ "' — right after"); lk[\timing] = \rightAfter };
				w[\chain].add(lk);
			};
		});
	};
	self[\strikeWins] = self[\strikeWins].reject({ |x| x[\id] == w[\id] }).asList;   // the same window again (a jump back): the earlier record goes
	self[\strikeWins].add(w);
	self.say("LE_INFO", "strike · " ++ w[\id] ++ " · a WINDOW " ++ (w[\end] - w[\beginAt]).round(0.01) ++ " s" ++ if(off > 0) { " (begun " ++ off.round(0.1) ++ " s in)" } { "" }
		++ if(w[\mode].size > 0) { " · " ++ w[\mode] } { "" }
		++ " · " ++ self[\strikeTypeNames][w[\type]] ++ " · " ++ self[\strikeTimingNames][w[\timing]] ++ " · seed " ++ w[\seed].asInteger ++ " · level " ++ w[\level] ++ " · deal " ++ w[\deal]
		++ if(w[\chain].size > 0) { " · ×" ++ (w[\chain].size + 1) ++ " a cascade: then " ++ w[\chain].collect({ |lk| self[\strikeTypeNames][lk[\type]] ++ " (" ++ self[\strikeTimingNames][lk[\timing]] ++ ")" }).join(", then ") } { "" }
		++ if(w[\answerOf].notNil) { " · answers " ++ w[\answerOf] ++ "'s strike" } { "" });
	if(self[\strikeManual] != true) { self.strikeRun };
	w
};

// ---- an onset is known: every open window that holds it collects it ------------------------------------------------------------
~le[\strikeOnset] = { |self, who, at, mark|
	var n = 0;
	(self[\strikeWins] ? []).do({ |w|
		if(w[\over].not and: { at >= (w[\start] - 0.05) } and: { at <= (w[\end] + (w[\graceS] ? w[\gapS])) }) {   // [17.3] the grace after the end: graceMs, else the gap as it always was
			w[\onsets].add((atS: at, who: who.asSymbol, mark: (mark ? \mf).asSymbol)); n = n + 1;
		};
	});
	n
};
// the two ears
~le[\strikeSimOnset] = { |self, d|
	var due = ((d[\dueMs] ? 0).asString.asFloat / 1000).clip(0, 5);
	if((self[\strikeEar] ? \sim) == \sim) { self.strikeOnset((d[\player] ? '?').asString.asSymbol, SystemClock.seconds + due, (d[\mark] ? "mf").asString.asSymbol) };
	self
};
~le[\strikeMicOnset] = { |self, name, time, amp|   // the probe's hit: a peak, read as a mark against the ladder's fff — a rough level until the concert's detector (17.5)
	var db, mark = \mf, marks = self[\strikeMarks], ref;
	if(self[\strikeEar] == \mic) {
		if(amp.notNil and: { amp > 0 } and: { self[\markDb].notNil }) {
			db = amp.ampdb; ref = self.markDb(\fff);
			if(ref.notNil) { mark = marks[((marks.size - 1) + ((db - ref) / 4)).round.asInteger.clip(0, marks.size - 1)] };
		};
		self.strikeOnset(name.asString.asSymbol, time ? SystemClock.seconds, mark);
	};
	self
};

// ---- the clockwork: a window at time t -> its answer, once, when the strike is over ---------------------------------------------
~le[\strikeStep] = { |self, w, t|
	var ons, last, over = false, src, rel, ans, startS;
	if(w[\over]) { nil } {
		if(w[\onsets].size > 0) { last = w[\onsets].inject(-1e9, { |m, o| max(m, o[\atS]) }); if(t >= (last + w[\gapS])) { over = true } };
		if(t >= (w[\end] + w[\gapS])) { over = true };
		if(over.not) { nil } {
			w[\over] = true;
			ons = w[\onsets].asArray.sort({ |a, b| a[\atS] < b[\atS] });
			if(ons.size > 0) { self[\strikeHeard][w[\id]] = (id: w[\id], onsets: ons, lastAt: last) };
			// the come-back: an earlier window's strike is the material, placed from THIS window's end (or its last onset, if it heard one)
			src = if(w[\answerOf].notNil) { self[\strikeHeard][w[\answerOf]] };
			if(w[\answerOf].notNil and: { src.isNil }) { self.say("LE_INFO", "strike · " ++ w[\id] ++ " answers " ++ w[\answerOf] ++ " — no strike of that window was heard: its own") };
			if(src.notNil) { ons = src[\onsets] };
			if(ons.size == 0) {
				self.say("LE_INFO", "strike · " ++ w[\id] ++ " · the window closed — NO ONSET heard: nothing to answer");
				nil
			} {
				rel = ons.collect({ |o| (atMs: (o[\atS] - ons[0][\atS]) * 1000, mark: o[\mark]) });
				ans = self.strikeAnswer(w, rel);
				startS = (if(w[\onsets].size > 0) { last } { w[\end] }) + (ans[\afterMs] / 1000);
				ans[\atS] = startS; ans[\heard] = w[\onsets].size; ans[\source] = if(src.notNil) { src[\id] } { w[\id] };
				self.say("LE_INFO", "strike · " ++ w[\id] ++ " · " ++ w[\onsets].size ++ " onsets heard (" ++ w[\onsets].collect({ |o| o[\who] }).asSet.asArray.collect(_.asString).sort.join(" ") ++ ")"
					++ if(w[\onsets].size > 0) { ", over " ++ ((t - last) * 1000).round(1).asInteger ++ " ms after the last" } { ", the window's end" }
					++ if(src.notNil) { " · answering " ++ src[\id] ++ "'s strike" } { "" }
					++ " · " ++ self[\strikeTypeNames][w[\type]] ++ " · " ++ self[\strikeTimingNames][w[\timing]] ++ " → " ++ ans[\onsets].size ++ " onsets from +" ++ (ans[\afterMs] / 1000).round(0.01) ++ " s"
					++ if((w[\chain] ? []).size > 0) { " · answer 1 of " ++ (w[\chain].size + 1) } { "" } ++ " · " ++ ans[\dyn] ++ " · " ++ ans[\samples].join(" "));
				ans[\k] = 1; ans[\chain] = self.strikeCascade(w, ans);   // [17.3] the further answers, each from the one before
				ans
			}
		}
	}
};
// the answer handed to the pattern path at its time: the call a second ahead (samplePlay clips dueMs at 5 s), the onsets from the first
~le[\strikePlayMsg] = { |self, w, ans, t|   // pure: when the call is made and what it carries
	var lead = 1.0, call = max(t, ans[\atS] - lead);
	(call: call, d: (behaviour: "pattern", pattern: ans[\pattern], dyn: ans[\dyn], id: w[\id].asString ++ if((ans[\k] ? 1) > 1) { "-" ++ ans[\k] } { "" }, lane: 0, dueMs: ((ans[\atS] - call) * 1000).max(0)))
};
~le[\strikePlay] = { |self, w, ans, t|
	var m = self.strikePlayMsg(w, ans, t);
	if(ans[\pattern].size == 0) { self.say("LE_INFO", "strike · " ++ w[\id] ++ " · no sample to answer with — the bank holds none for these players") } {
		SystemClock.schedAbs(m[\call], { self.samplePlay(m[\d]); nil });
	};
	self
};
// ---- the clock: every 20 ms each window is stepped; one that has answered is dropped a while after its answer -----------------
~le[\strikeRun] = { |self|
	if(self[\strikeRoutine].isNil) {
		self[\strikeRoutine] = Routine({
			var dt = 0.02, t, idle = 0;
			while { self[\strikeWins].notNil and: { self[\strikeWins].size > 0 } } {
				t = thisThread.seconds;
				try {
					self[\strikeWins].copy.do({ |w|
						var ans = self.strikeStep(w, t);
						if(ans.notNil) {   // [17.3] every answer of a cascade is handed over now, each at its own time; the window is done at the last
							self.strikePlay(w, ans, t); w[\doneAt] = ans[\atS];
							(ans[\chain] ? []).do({ |a| self.strikePlay(w, a, t); w[\doneAt] = a[\atS] });
						};
						if(w[\over] and: { w[\doneAt].isNil }) { w[\doneAt] = t };
					});
					self[\strikeWins] = self[\strikeWins].reject({ |w| w[\doneAt].notNil and: { t > (w[\doneAt] + 2) } }).asList;
				} { |err| self.say("LE_ERROR", "strike · " ++ err.errorString) };
				dt.wait;
			};
			self[\strikeRoutine] = nil;
		}).play(SystemClock);
	};
	self
};
~le[\strikeStop] = { |self|
	var n = if(self[\strikeWins].notNil) { self[\strikeWins].size } { 0 };
	self.strikeClear(true);
	if(n > 0) { self.say("LE_INFO", "strike · stopped — " ++ n ++ " window" ++ if(n > 1) { "s" } { "" } ++ " dropped") };
	self
};
~le[\strikeHear] = { |self|
	self.hear(\strike, { |le, d| le.strikeTake(d, SystemClock.seconds) });
	self.hear(\strikestop, { |le, d| le.strikeStop });
	self
};
)
