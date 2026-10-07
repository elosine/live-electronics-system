// performer_test.scd — THE COMPUTER PLAYERS, HEADLESS (the Decibel piece's PLAN 1.6 · 14.4, 2026-10-06): performer.scd in a bare
// sclang — no server, no port, no clock: the TIME is handed in, ten milliseconds a step, and a scripted stream of onsets is fed
// as a score would tell it (a tenth of a second before each sounds). A living engine beside it is untouched, and nothing sounds.
//   THE MESSAGE   a container's fields become the performer's: its start, its end, where a playhead that began inside it stands
//   FAR APART     its own pace: every gap within the jitter of ONE gap, and the same sounds whatever it hears
//   APPROACHING   every answer a beat (300 … 900 ms) after its TARGET's onset; another player is not answered; never within
//                 400 ms of its own last; with nothing to answer it plays unprompted
//   CLOSE PASS    just after (60 … 150 ms) — and, betting on a player who is a clock, 40 … 120 ms BEFORE the next onset;
//                 never within 25 ms of an onset it knows
//   THE DEPTH     an answer to an answer is not answered: two performers passing each other fall silent after one seed
//   THE BREAK     silent through its silence; in within 700 ms of a cluster breaking up; alone at the last third with none
//   A CHANGE      far apart → approaching: the pace thins out as the answers come in
//   A NEW PASS    the first message of a new pass ends the performers of the pass before
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/performer_test.scd
// It ends PERFORMER_TEST PASS (exit 0) or PERFORMER_TEST FAIL (exit 1) and names each check.
(
var dir = thisProcess.nowExecutingPath.dirname;
var fails = List.new, check, run, msg, between, said = List.new;
(dir +/+ "boot.scd").load;
~le[\say] = { |self, kind, text| said.add(text); self };   // the performers' lines are kept, not printed
~le[\perfManual] = true;                                   // no clock of its own: this file steps it
check = { |what, ok, detail| ("  " ++ if(ok) { "ok   " } { "FAIL " } ++ what ++ " — " ++ detail).postln; if(ok.not) { fails.add(what) } };
between = { |x, lo, hi| (x >= lo) and: { x <= hi } };
// a container's message, as the score sends it
msg = { |id, state, lenS, more|
	var d = (id: id, state: state, dueMs: 0, lengthMs: lenS * 1000, pal: "a,b,c,d", seed: 3, mark: "mf", pass: 1);
	if(more.notNil) { d.putAll(more) };
	d
};
// T seconds of virtual time: `onsets` [[atS, who, gen]] are told 0.1 s ahead; the performers are stepped every 10 ms, their
// sounds told to each other. Answers the sounds: [(id, atS, role, ref, refAt, gen, …)]
run = { |secs, onsets|
	var t = 0, dt = 0.01, hz = 0.03, out = List.new, ix = 0, list = (onsets ? []).copy.sort({ |a, b| a[0] < b[0] });
	while { t < secs } {
		while { (ix < list.size) and: { (list[ix][0] - 0.1) <= t } } { ~le.perfNote(list[ix][1], list[ix][0], list[ix][2] ? 0); ix = ix + 1 };
		~le[\performers].values.do({ |p|
			~le.perfStep(p, t, dt, hz).do({ |play|
				play[\id] = p[\id]; out.add(play);
				~le.perfNote(p[\id], play[\atS], play[\gen]);
			});
		});
		t = t + dt;
	};
	out.asArray
};
try {
	var p, plays, gaps, base, a, b, clock, k, n1, n2, h1, h2, lone, q, w;

	"PERFORMER_TEST the message:".postln;
	~le.perfClear;
	p = ~le.perfTake((id: \e1, state: \change, from: \far, to: \approaching, dueMs: 100, lengthMs: 6000, offsetMs: 4000, wholeMs: 10000, pal: "x,y", target: \bcl, seed: 5, silenceMs: 0, ear: \sim, dials: "beatLo=350, holdMs=410", pass: 9), 50.0);
	k = p[\next];
	check.("a container's fields become the performer's", (k[\state] == \change) and: { k[\from] == \far } and: { k[\to] == \approaching } and: { k[\target] == \bcl }
		and: { (k[\beginAt] - 50.1).abs < 1e-9 } and: { (k[\start] - 46.1).abs < 1e-9 } and: { (k[\end] - 56.1).abs < 1e-9 },
		"change far → approaching, listening to " ++ k[\target] ++ " · it begins at " ++ k[\beginAt] ++ ", its own start was " ++ k[\start] ++ " (4 s in), its end " ++ k[\end]);
	check.("the piece's dials lie over the defaults; the palette is held; the ear is the message's", (p[\o][\beatLo] == 350) and: { p[\o][\holdMs] == 410 } and: { p[\o][\beatHi] == 900 }
		and: { p[\pal].size == 2 } and: { ~le[\perfEar] == \sim },
		"beatLo " ++ p[\o][\beatLo] ++ " · holdMs " ++ p[\o][\holdMs] ++ " · beatHi " ++ p[\o][\beatHi] ++ " (the default) · palette " ++ p[\pal] ++ " · ear " ++ ~le[\perfEar]);

	"PERFORMER_TEST far apart:".postln;
	~le.perfClear; ~le.perfTake(msg.(\e1, \far, 40), 0);
	plays = run.(40, nil);
	gaps = (plays.size - 1).collect({ |i| plays[i + 1][\atS] - plays[i][\atS] });
	base = gaps.sum / gaps.size.max(1);
	check.("its own pace: a clock", (plays.size >= 5) and: { plays.every({ |x| x[\role] == \pace }) } and: { between.(base, 2.4, 6.1) } and: { gaps.every({ |g| (g - base).abs <= (base * 0.2) }) },
		plays.size.asString ++ " sounds in 40 s · the gap " ++ base.round(0.01) ++ " s · every gap within " ++ ((gaps.collect({ |g| (g - base).abs }).maxItem ? 0) / base * 100).round(0.1) ++ " % of it");
	a = plays.collect({ |x| x[\atS].round(0.001) });
	~le.perfClear; ~le.perfTake(msg.(\e1, \far, 40), 0);
	b = run.(40, Array.fill(60, { |i| [0.5 + (i * 0.61), \bcl, 0] })).collect({ |x| x[\atS].round(0.001) });
	check.("it hears nothing: the same sounds beside sixty onsets of another", a == b, a.size.asString ++ " sounds, the same times");

	"PERFORMER_TEST approaching:".postln;
	~le.perfClear; ~le.perfTake(msg.(\e1, \approaching, 20, (target: \bcl)), 0);
	clock = Array.fill(8, { |i| [1.0 + (i * 1.5), \bcl, 0] }) ++ Array.fill(8, { |i| [1.4 + (i * 1.5), \va, 0] });
	plays = run.(20, clock);
	a = plays.select({ |x| x[\role] == \beat });
	check.("every answer is a beat after its target", (a.size >= 6) and: { a.every({ |x| (x[\ref] == \bcl) and: { between.((x[\atS] - x[\refAt]) * 1000, 299, 950) } }) },
		a.size.asString ++ " answers, each " ++ a.collect({ |x| ((x[\atS] - x[\refAt]) * 1000).round(1).asInteger }).minItem ++ " … " ++ a.collect({ |x| ((x[\atS] - x[\refAt]) * 1000).round(1).asInteger }).maxItem ++ " ms after bcl; va (not its target) answered " ++ plays.count({ |x| x[\ref] == \va }) ++ " times");
	gaps = (plays.size - 1).collect({ |i| (plays[i + 1][\atS] - plays[i][\atS]) * 1000 });
	check.("never within 400 ms of its own last", gaps.every({ |g| g >= 399 }), "its closest two: " ++ (gaps.minItem ? 0).round(1) ++ " ms");
	lone = plays.select({ |x| x[\role] == \unprompted });
	check.("with nothing to answer it plays unprompted", (lone.size >= 1) and: { lone.every({ |x| x[\atS] > 13 }) },
		lone.size.asString ++ " unprompted, the first at " ++ (lone.collect({ |x| x[\atS] }).minItem ? 0).round(0.01) ++ " s (bcl's last onset: 11.5 s)");

	"PERFORMER_TEST close pass:".postln;
	~le.perfClear; ~le.perfTake(msg.(\e1, \closePass, 20, (target: \bcl, dials: "beforeShare=0")), 0);
	clock = Array.fill(18, { |i| [1.0 + (i * 1.0), \bcl, 0] });
	plays = run.(20, clock);
	a = plays.select({ |x| x[\role] == \after });
	check.("just after: 60 … 150 ms behind the onset", (a.size >= 15) and: { a.every({ |x| between.((x[\atS] - x[\refAt]) * 1000, 59, 151) }) },
		a.size.asString ++ " sounds, " ++ a.collect({ |x| ((x[\atS] - x[\refAt]) * 1000).round(1).asInteger }).minItem ++ " … " ++ a.collect({ |x| ((x[\atS] - x[\refAt]) * 1000).round(1).asInteger }).maxItem ++ " ms after");
	~le.perfClear; said.clear; ~le.perfTake(msg.(\e1, \closePass, 20, (target: \bcl, dials: "beforeShare=1")), 0);
	plays = run.(20, clock);
	b = plays.select({ |x| (x[\role] == \bet) and: { x[\predicted] <= 18.01 } });   // (the bet after bcl's LAST onset predicts one that never comes)
	// a clock's next onset is where it was predicted: each bet lands 40 … 120 ms before one of bcl's onsets
	check.("a bet on a clock lands 40 … 120 ms BEFORE its next onset", (b.size >= 12) and: { b.every({ |x| clock.any({ |o| between.((o[0] - x[\atS]) * 1000, 39, 121) }) }) },
		b.size.asString ++ " bets, " ++ b.collect({ |x| ((x[\predicted] - x[\atS]) * 1000).round(1).asInteger }).minItem ++ " … " ++ b.collect({ |x| ((x[\predicted] - x[\atS]) * 1000).round(1).asInteger }).maxItem ++ " ms before the prediction; said HIT " ++ said.count({ |s| s.contains("HIT") }) ++ " times, MISS " ++ said.count({ |s| s.contains("MISS") }));
	check.("never WITH: no sound within 25 ms of an onset it knows", plays.every({ |x| clock.every({ |o| ((o[0] - x[\atS]).abs * 1000) >= 24.9 }) }),
		"the closest: " ++ plays.collect({ |x| clock.collect({ |o| (o[0] - x[\atS]).abs * 1000 }).minItem }).minItem.round(0.1) ++ " ms");
	// a bet on a player who does NOT come where predicted is said a miss
	~le.perfClear; said.clear; ~le.perfTake(msg.(\e1, \closePass, 10, (target: \bcl, dials: "beforeShare=1")), 0);
	plays = run.(10, [[1.0, \bcl, 0], [2.0, \bcl, 0], [3.9, \bcl, 0]]);
	check.("a bet on a player who is not a clock is said a MISS", (plays.count({ |x| x[\role] == \bet }) >= 1) and: { said.any({ |s| s.contains("MISS") }) },
		(said.detect({ |s| s.contains("MISS") }) ? "(nothing said)").asString);

	"PERFORMER_TEST the depth:".postln;
	~le.perfClear;
	~le.perfTake(msg.(\e1, \closePass, 6, (target: \e2, dials: "beforeShare=0,waitCLo=90000,waitCHi=90000")), 0);
	~le.perfTake(msg.(\e2, \closePass, 6, (target: \e1, dials: "beforeShare=0,waitCLo=90000,waitCHi=90000")), 0);
	plays = run.(6, [[1.0, \e9, 0]]);   // nobody's target plays: silence
	n1 = plays.size;
	~le.perfClear;
	~le.perfTake(msg.(\e1, \closePass, 6, (target: \cluster, dials: "beforeShare=0,waitCLo=90000,waitCHi=90000")), 0);
	~le.perfTake(msg.(\e2, \closePass, 6, (target: \cluster, dials: "beforeShare=0,waitCLo=90000,waitCHi=90000")), 0);
	plays = run.(6, [[1.0, \va, 0]]);   // one seed: each answers it, then each other's answer once — and it stops
	check.("two performers passing each other do not answer for ever", (n1 == 0) and: { between.(plays.size, 2, 4) } and: { plays.every({ |x| x[\gen] <= 2 }) } and: { plays.every({ |x| x[\atS] < 1.6 }) },
		"a stranger's onset: " ++ n1 ++ " sounds · one seed in a cluster: " ++ plays.size ++ " sounds (" ++ plays.collect({ |x| x[\id].asString ++ " gen " ++ x[\gen] ++ " at " ++ x[\atS].round(0.001) }).join(" · ") ++ "), then silence");

	"PERFORMER_TEST the break:".postln;
	~le.perfClear; ~le.perfTake(msg.(\e1, \breakRejoin, 20, (silenceMs: 5000)), 0);
	// a player sounds through its silence (sparse: no cluster), then a cluster of four at 8.0 … 8.3 s, then nothing
	clock = Array.fill(4, { |i| [0.5 + (i * 1.2), \bcl, 0] }) ++ [[8.0, \va, 0], [8.1, \vc, 0], [8.2, \bcl, 0], [8.3, \va, 0]];
	plays = run.(20, clock);
	check.("silent through its silence, and until a cluster has come and gone", (plays.size >= 1) and: { plays[0][\atS] > 8.3 } and: { plays[0][\role] == \rejoin },
		"its first sound at " ++ (if(plays.size > 0) { plays[0][\atS].round(0.001) } { "—" }) ++ " s (" ++ (if(plays.size > 0) { plays[0][\role] } { "—" }) ++ "); the silence ended at 5 s, the cluster at 8.3 s");
	check.("in within 700 ms of the cluster breaking up, then its own pace", (plays.size >= 2) and: { between.((plays[0][\atS] - 8.3) * 1000, 440, 700) } and: { plays[1..].every({ |x| x[\role] == \pace }) },
		"in " ++ (if(plays.size > 0) { ((plays[0][\atS] - 8.3) * 1000).round(1).asInteger } { "—" }) ++ " ms after the last onset · then " ++ (plays.size - 1) ++ " sounds at its own pace");
	~le.perfClear; ~le.perfTake(msg.(\e1, \breakRejoin, 20, (silenceMs: 5000)), 0);
	plays = run.(20, nil);
	check.("with no cluster it comes in alone at the last third", (plays.size >= 1) and: { plays[0][\role] == \rejoinAlone } and: { between.(plays[0][\atS], 15.0, 15.3) },
		"its first sound at " ++ (if(plays.size > 0) { plays[0][\atS].round(0.001) } { "—" }) ++ " s (the silence ended at 5 s; two thirds of the rest: 15 s)");

	"PERFORMER_TEST a change:".postln;
	~le.perfClear;
	~le.perfTake(msg.(\e1, \far, 10), 0); run.(9.95, nil);   // it has its pace before the change begins
	~le.perfTake((id: \e1, state: \change, from: \far, to: \approaching, dueMs: 50, lengthMs: 60000, pal: "a,b", target: \bcl, seed: 3, pass: 1), 9.95);
	clock = Array.fill(110, { |i| [10.5 + (i * 0.53), \bcl, 0] });
	{
		var t = 9.95, ix = 0, out = List.new;
		while { t < 70 } {
			while { (ix < clock.size) and: { (clock[ix][0] - 0.1) <= t } } { ~le.perfNote(clock[ix][1], clock[ix][0], 0); ix = ix + 1 };
			~le.perfStep(~le[\performers][\e1], t, 0.01, 0.03).do({ |play| out.add(play) });
			t = t + 0.01;
		};
		plays = out.asArray;
	}.value;
	n1 = plays.count({ |x| (x[\role] == \pace) and: { x[\atS] < 40 } }); n2 = plays.count({ |x| (x[\role] == \pace) and: { x[\atS] >= 40 } });
	h1 = plays.count({ |x| (x[\role] == \beat) and: { x[\atS] < 40 } }); h2 = plays.count({ |x| (x[\role] == \beat) and: { x[\atS] >= 40 } });
	check.("far apart → approaching: the pace thins out as the answers come in", (n1 > n2) and: { h2 > h1 } and: { h1 >= 1 },
		"its own pace: " ++ n1 ++ " sounds in the first half, " ++ n2 ++ " in the second · answers: " ++ h1 ++ " in the first half, " ++ h2 ++ " in the second");

	"PERFORMER_TEST a new pass:".postln;
	~le.perfClear;
	~le.perfTake(msg.(\e1, \far, 10), 0); ~le.perfTake(msg.(\e2, \far, 10), 0);
	q = ~le[\performers].size;
	~le.perfTake(msg.(\e3, \far, 10, (pass: 2)), 0);
	w = ~le[\performers].size;
	~le.perfStop;
	check.("the first message of a new pass ends the performers of the pass before; a stop ends them all", (q == 2) and: { w == 1 } and: { ~le[\performers][\e3].notNil.not } and: { ~le[\performers].size == 0 },
		"two performers · a message of pass 2: " ++ w ++ " (the new one) · after the stop: " ++ ~le[\performers].size);

	if(fails.size == 0) { "PERFORMER_TEST PASS".postln; 0.exit } { ("PERFORMER_TEST FAIL — " ++ fails.size ++ ": " ++ fails.join(" · ")).postln; 1.exit };
} { |err|
	err.reportError;
	"PERFORMER_TEST FAIL — the test itself stopped".postln;
	1.exit;
};
)
