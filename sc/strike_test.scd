// strike_test.scd — THE STRIKE WINDOW, HEADLESS (the Decibel piece's PLAN 1.9 · 17.1, 2026-10-09): strike.scd in a bare sclang — no
// server, no port, no clock: the TIME is handed in, a scripted strike is fed as the page's ear would tell it, and the answer the
// engine would hand to the pattern path is read back. A living engine beside it is untouched, and nothing sounds.
//   THE CORRESPONDENCE   the nine transformations and the five timings on ONE strike (six onsets, seed 3) give, to the tenth of a
//                        millisecond, what the page's StrikeCalc gives (score/le_strike.js, run in node — the numbers pasted here)
//   ONE ONSET            every transformation leaves it; call and response counts it minMs long
//   THE WINDOW           a message becomes a window; the onsets inside it are collected with their marks; not over until gapMs of
//                        silence after the last; then ONE answer: the onsets from the last + the timing, a sample a player in turn,
//                        each at its onset's level under the loudest (mimic), the loudest the base mark
//   NO ONSET             a window that heard nothing answers nothing
//   THE COME-BACK        a window that answers an earlier one takes that strike's rhythm, placed from its own end
//   THE DEAL · THE NAMES every player at every onset · named samples dealt in order
//   THE DECKS            a player's samples none twice until all are used
//   A NEW PASS · A STOP  the windows of the pass before are dropped; a stop drops them and keeps what was heard
//   THE CALL             the answer is handed to the pattern path a second ahead, with the right dueMs
//   THE CASCADE          a window with a chain answers 1 + its links times: each answer the rhythm of the ANSWER BEFORE IT transformed,
//                        begun by its timing after that answer's last onset — a real window of the Decibel piece, the page's numbers;
//                        its grace keeps the next strike's first onset out
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/strike_test.scd
// It ends STRIKE_TEST PASS (exit 0) or STRIKE_TEST FAIL (exit 1) and names each check.
(
var dir = thisProcess.nowExecutingPath.dirname;
var fails = List.new, check, said = List.new, near, ons, ids, rel, want, w, msg, t0 = 100, ans, w2, ans2, w3, ans3, w4, ans4, names, deck, mk, m, cnt;
(dir +/+ "boot.scd").load;
~le[\say] = { |self, kind, text| said.add(text); self };   // the lines are kept, not printed
~le[\strikeManual] = true;                                  // no clock of its own: this file steps it
check = { |what, ok, detail| ("  " ++ if(ok) { "ok   " } { "FAIL " } ++ what ++ " — " ++ detail).postln; if(ok.not) { fails.add(what) } };
near = { |a, b, tol = 0.01| (a - b).abs <= tol };
// a fake bank: two captures and one processed version a player, five players
~le[\samples] = IdentityDictionary.new;
[\bfl, \bcl, \perc, \va, \vc].do({ |p|
	[1, 2].do({ |i| ~le[\samples][(p ++ "-impulse-" ++ i).asSymbol] = (row: (name: p ++ "-impulse-" ++ i, player: p.asString), buf: nil) });
	~le[\samples][(p ++ "-impulse-1~k1-tail").asSymbol] = (row: (name: p ++ "-impulse-1~k1-tail", player: p.asString, kind: "processed"), buf: nil);
});
// [§337, DEC-113] THE DECK'S FILTERS — a processed version is in only with an allowed ending; a row only with an allowed category (nil = any).
// On a sixth, throwaway player, taken out again before the rest runs.
~le[\samples]["zz-impulse-1".asSymbol] = (row: (name: "zz-impulse-1", player: "zz", category: "impulse"), buf: nil);
~le[\samples]["zz-drone-1".asSymbol] = (row: (name: "zz-drone-1", player: "zz", category: "drone"), buf: nil);
~le[\samples]["zz-impulse-1~k1-tail".asSymbol] = (row: (name: "zz-impulse-1~k1-tail", player: "zz", kind: "processed", end: "tail"), buf: nil);
~le[\samples]["zz-impulse-1~k2-perc".asSymbol] = (row: (name: "zz-impulse-1~k2-perc", player: "zz", kind: "processed", end: "perc"), buf: nil);
check.("the pool with no filter: every row of the player", ~le.strikePool(\zz, true, nil, nil).size == 4, ~le.strikePool(\zz, true, nil, nil).join(" "));
check.("the pool with envs perc: the captures and the perc version, the tail out", ~le.strikePool(\zz, true, ["perc"], nil) == ["zz-drone-1", "zz-impulse-1", "zz-impulse-1~k2-perc"], ~le.strikePool(\zz, true, ["perc"], nil).join(" "));
check.("the pool with cats impulse: the drone out, a processed version by its source", ~le.strikePool(\zz, true, ["perc"], ["impulse"]) == ["zz-impulse-1", "zz-impulse-1~k2-perc"], ~le.strikePool(\zz, true, ["perc"], ["impulse"]).join(" "));
check.("the pool without processed: the capture alone", ~le.strikePool(\zz, false, ["perc"], ["impulse"]) == ["zz-impulse-1"], ~le.strikePool(\zz, false, ["perc"], ["impulse"]).join(" "));
check.("[17.3] the pool with raw false: the processed version alone — the captures out", ~le.strikePool(\zz, true, ["perc"], nil, false) == ["zz-impulse-1~k2-perc"], ~le.strikePool(\zz, true, ["perc"], nil, false).join(" "));
["zz-impulse-1", "zz-drone-1", "zz-impulse-1~k1-tail", "zz-impulse-1~k2-perc"].do({ |k| ~le[\samples].removeAt(k.asSymbol) });
ons = [[0, \f], [98, \mf], [157, \f], [191, \mp], [237, \ff], [397, \f]].collect({ |x| (atMs: x[0], mark: x[1]) });
rel = { |a| a.collect({ |o| o[\atMs] }) };
mk = { |a| a.collect({ |o| o[\mark] }).join(" ") };

"STRIKE_TEST the correspondence (the page's numbers, seed 3):".postln;
// what score/le_strike.js gives for these six onsets at seed 3 (node: StrikeCalc.answer) — each row the transformation with `rightAfter`
want = (
	asPlayed: [[0, 98, 157, 191, 237, 397], "f mf f mp ff f", 302.793],
	retrograde: [[0, 160, 206, 240, 299, 397], "f ff mp f mf f", 302.793],
	invert: [[0, 96, 231, 391, 539, 573], "f mf f mp ff f", 302.793],
	spread: [[0, 147.821, 236.816, 288.101, 357.486, 598.827], "f mf f mp ff f", 747.893],
	compress: [[0, 29.619, 47.451, 57.727, 71.63, 119.987], "f mf f mp ff f", 747.893],
	scramble: [[0, 160, 194, 253, 299, 397], "f mf f mp ff f", 632.017],
	rotate: [[0, 59, 93, 139, 299, 397], "f mf f mp ff f", 747.893],
	thin: [[0, 157, 237, 397], "f f ff f", 504.487],
	thicken: [[0, 89.728, 98, 157, 191, 237, 254.27, 397], "f f mf f mp ff mp f", 678.648]
);
~le[\strikeTypes].do({ |type|
	var ww = (seed: 3, type: type, timing: \rightAfter, dials: (), level: \mimic, deal: \robin, processed: false, samples: ["x"]);
	var a = ~le.strikeAnswer(ww, ons), ex = want[type];
	check.(type.asString ++ " · the onsets, the marks, the timing", (rel.(a[\onsets]).size == ex[0].size) and: { rel.(a[\onsets]).every({ |v, i| near.(v, ex[0][i]) }) } and: { mk.(a[\onsets]) == ex[1] } and: { near.(a[\afterMs], ex[2]) },
		rel.(a[\onsets]).collect({ |v| v.round(0.001) }).join(" ") ++ " · " ++ mk.(a[\onsets]) ++ " · +" ++ a[\afterMs].round(0.001) ++ " ms");
});
want = (rightAfter: 302.793, aBeatLater: 1005.587, callResponse: 318.487, muchLater: 6050.28, inLaterWindow: 10027.934);
~le[\strikeTimings].do({ |tm|
	var a = ~le.strikeAnswer((seed: 3, type: \asPlayed, timing: tm, dials: (), level: \mimic, deal: \robin, processed: false, samples: ["x"]), ons);
	check.(tm.asString ++ " · the timing", near.(a[\afterMs], want[tm]), "+" ++ a[\afterMs].round(0.001) ++ " ms");
});
{ var a = ~le.strikeAnswer((seed: 3, type: \thicken, timing: \callResponse, dials: (), level: \mimic, deal: \robin, processed: false, samples: ["x"]), ons);
  check.("thicken with call and response: the draws in one order", rel.(a[\onsets]).every({ |v, i| near.(v, [0, 89.728, 98, 157, 191, 237, 254.27, 397][i]) }) and: { near.(a[\afterMs], 437.859) }, "+" ++ a[\afterMs].round(0.001)) }.value;
{ var a = ~le.strikeAnswer((seed: 3, type: \thin, timing: \muchLater, dials: (), level: \mimic, deal: \robin, processed: false, samples: ["x"]), ons);
  check.("thin with much later", rel.(a[\onsets]).every({ |v, i| near.(v, [0, 157, 237, 397][i]) }) and: { near.(a[\afterMs], 9680.764) }, "+" ++ a[\afterMs].round(0.001)) }.value;
{ var a = ~le.strikeAnswer((seed: 3, type: \spread, timing: \rightAfter, dials: (lo: 2, hi: 2), level: \mimic, deal: \robin, processed: false, samples: ["x"]), ons);
  check.("the message's dials override the defaults (spread 2 … 2: every gap doubled)", rel.(a[\onsets]).every({ |v, i| near.(v, [0, 196, 314, 382, 474, 794][i]) }), rel.(a[\onsets]).join(" ")) }.value;
"STRIKE_TEST one onset:".postln;
~le[\strikeTypes].do({ |type|
	var a = ~le.strikeAnswer((seed: 5, type: type, timing: \callResponse, dials: (), level: \mimic, deal: \robin, processed: false, samples: ["x"]), [(atMs: 0, mark: \p)]);
	// the page's numbers: a type that draws nothing on one onset leaves the timing its first draw (255.545); spread · compress · thin · thicken draw once first (262.953)
	var ex = if([\spread, \compress, \thin, \thicken].includes(type)) { 262.953 } { 255.545 };
	check.(type.asString ++ " leaves one onset at 0 · call and response counts it 300 ms long · the draws as the page's", (rel.(a[\onsets]) == [0]) and: { mk.(a[\onsets]) == "p" } and: { near.(a[\afterMs], ex) }, rel.(a[\onsets]).join(" ") ++ " · +" ++ a[\afterMs].round(0.001));
});

"STRIKE_TEST the window:".postln;
msg = { |id, more| var d = (id: id, dueMs: 0, lengthMs: 2000, type: "retrograde", timing: "aBeatLater", seed: 3, gapMs: 500, level: "mimic", deal: "robin", processed: 1, dials: "wLo=1,wHi=2", pass: 1); if(more.notNil) { d.putAll(more) }; d };
~le.strikeClear(false);
w = ~le.strikeTake(msg.(\W1), t0);
check.("a message becomes a window: its span, its type and timing, its seed, its gap", (w[\start] == t0) and: { w[\end] == (t0 + 2) } and: { w[\type] == \retrograde } and: { w[\timing] == \aBeatLater } and: { w[\seed] == 3 } and: { w[\gapS] == 0.5 } and: { w[\dials][\wLo] == 1 }, said.last);
[[0, \bfl, \f], [0.098, \va, \mf], [0.157, \vc, \f], [0.191, \perc, \mp], [0.237, \bcl, \ff], [0.397, \bfl, \f]].do({ |x| ~le.strikeOnset(x[1], t0 + x[0], x[2]) });
cnt = ~le.strikeOnset(\va, t0 + 2.4, \f);   // a note after the window: a hair past end + gap? no — 2.4 is inside end + gap (2.5): collected; 2.6 is not
check.("the onsets inside the window are collected with their marks; one past end + gap is not", (w[\onsets].size == 7) and: { cnt == 1 } and: { ~le.strikeOnset(\va, t0 + 2.6, \f) == 0 } and: { w[\onsets][4][\mark] == \ff }, w[\onsets].size.asString ++ " collected");
w[\onsets].pop;   // the late one taken back for the counts below
check.("not over 300 ms after the last onset", ~le.strikeStep(w, t0 + 0.397 + 0.3).isNil and: { w[\over].not }, "nil");
ans = ~le.strikeStep(w, t0 + 0.397 + 0.5);
check.("over 500 ms after the last: ONE answer — retrograde, a beat later, from the last onset", ans.notNil and: { w[\over] } and: { ans[\onsets].size == 6 } and: { near.(ans[\atS], t0 + 0.397 + 1.005587, 0.001) } and: { rel.(ans[\onsets]).every({ |v, i| near.(v, [0, 160, 206, 240, 299, 397][i]) }) },
	if(ans.notNil) { ans[\atS].round(0.001).asString ++ " s · " ++ rel.(ans[\onsets]).join(" ") } { "no answer" });
check.("stepped again it answers no more", ~le.strikeStep(w, t0 + 3).isNil, "nil");
names = ans[\pattern].split($,).collect({ |e| e.split($:) });
check.("a sample a player, the five in turn, the sixth a player twice; the loudest mark (ff) is the base; each onset so many dB under it",
	(names.size == 6) and: { names.collect({ |e| e[0].split($-)[0] }).asSet.size == 5 } and: { ans[\dyn] == "mark:ff" }
	and: { names.collect({ |e| e[2].asFloat }) == [-4.0, 0.0, -12.0, -4.0, -8.0, -4.0] } and: { names.collect({ |e| e[1].asFloat }).every({ |v, i| near.(v, [0, 160, 206, 240, 299, 397][i]) }) },   // the retrograde's marks f ff mp f mf f under ff
	ans[\pattern]);
m = ~le.strikePlayMsg(w, ans, t0 + 0.3);
check.("the call a second ahead with the right dueMs; the pattern path's fields", near.(m[\call], ans[\atS] - 1, 0.001) and: { near.(m[\d][\dueMs], 1000, 0.1) } and: { m[\d][\behaviour] == "pattern" } and: { m[\d][\dyn] == "mark:ff" }, m[\d][\dueMs].round(0.1).asString ++ " ms");
m = ~le.strikePlayMsg(w, ans, ans[\atS] - 0.2);
check.("a late step calls at once, the dueMs what is left", (m[\call] == (ans[\atS] - 0.2)) and: { near.(m[\d][\dueMs], 200, 0.1) }, m[\d][\dueMs].round(0.1).asString ++ " ms");
// no onset
w2 = ~le.strikeTake(msg.(\W2, (dueMs: 5000)), t0);
check.("a window that heard nothing answers nothing at its end + gap", ~le.strikeStep(w2, t0 + 5 + 2 + 0.4).isNil and: { w2[\over].not } and: { ~le.strikeStep(w2, t0 + 7.5).isNil } and: { w2[\over] } and: { said.last.contains("NO ONSET") }, said.last);
// the come-back
w3 = ~le.strikeTake(msg.(\W3, (dueMs: 10000, answerOf: "W1", type: "asPlayed", timing: "rightAfter", dials: "wLo=0.5,wHi=0.5")), t0);
ans3 = ~le.strikeStep(w3, t0 + 12.5);
check.("a window answering W1 with no strike of its own takes W1's six onsets, placed from its own end", ans3.notNil and: { ans3[\onsets].size == 6 } and: { ans3[\source] == \W1 } and: { near.(ans3[\atS], t0 + 12 + 0.5, 0.001) } and: { rel.(ans3[\onsets]).every({ |v, i| near.(v, [0, 98, 157, 191, 237, 397][i]) }) },
	if(ans3.notNil) { ans3[\source].asString ++ " · " ++ rel.(ans3[\onsets]).join(" ") ++ " · at " ++ ans3[\atS].round(0.001) } { "no answer" });
// deal all · named samples · a mark
w4 = ~le.strikeTake(msg.(\W4, (dueMs: 20000, deal: "all", level: "p", type: "asPlayed")), t0);
[[0, \bfl, \f], [0.3, \va, \mf]].do({ |x| ~le.strikeOnset(x[1], t0 + 20 + x[0], x[2]) });
ans4 = ~le.strikeStep(w4, t0 + 20.3 + 0.5);
check.("deal all: every player at every onset — two onsets × five players; a mark: every onset at it, 0 dB", ans4.notNil and: { ans4[\pattern].split($,).size == 10 } and: { ans4[\dyn] == "mark:p" } and: { ans4[\pattern].split($,).every({ |e| e.split($:)[2].asFloat == 0 }) }, ans4[\dyn] ++ " · " ++ ans4[\pattern].split($,).size.asString ++ " entries");
w4 = ~le.strikeTake(msg.(\W5, (dueMs: 30000, samples: "x-one,y-two", type: "asPlayed")), t0);
[[0, \bfl, \f], [0.1, \va, \mf], [0.2, \vc, \mf]].do({ |x| ~le.strikeOnset(x[1], t0 + 30 + x[0], x[2]) });
ans4 = ~le.strikeStep(w4, t0 + 30.2 + 0.5);
check.("named samples are dealt in order, wrapping", ans4[\pattern].split($,).collect({ |e| e.split($:)[0] }) == ["x-one", "y-two", "x-one"], ans4[\pattern]);
// the decks
~le[\strikeDecks] = IdentityDictionary.new;
deck = 4.collect({ ~le.strikeNext((rs: 12345, processed: true), \bfl) });
check.("a player's deck: its three samples (the processed one among them) none twice, then the deck again", (deck.keep(3).asSet.size == 3) and: { deck.keep(3).includesEqual("bfl-impulse-1~k1-tail") } and: { deck.keep(3).includesEqual(deck[3]) }, deck.join(" "));
deck = 3.collect({ ~le.strikeNext((rs: 12345, processed: false), \bfl) });
check.("without the processed versions: the two captures, then one again", (deck.keep(2).asSet.size == 2) and: { deck.every({ |n| n.contains("~").not }) } and: { deck.keep(2).includesEqual(deck[2]) }, deck.join(" "));
check.("the players the bank holds, in order", ~le.strikePlayers == [\bcl, \bfl, \perc, \va, \vc], ~le.strikePlayers.join(" "));
// a new pass · a stop
cnt = ~le[\strikeWins].size;
~le.strikeTake(msg.(\W6, (pass: 2)), t0 + 100);
check.("the first message of a new pass drops the windows of the pass before and what they heard", (~le[\strikeWins].size == 1) and: { ~le[\strikeHeard].size == 0 }, cnt.asString ++ " → " ++ ~le[\strikeWins].size);
~le.strikeOnset(\bfl, t0 + 100.1, \f); ~le.strikeStep(~le[\strikeWins][0], t0 + 100.7);
~le.strikeStop;
check.("a stop drops every window and keeps the strikes heard for a come-back", (~le[\strikeWins].size == 0) and: { ~le[\strikeHeard].size == 1 }, said.last);
// the mic ear's rough level
~le[\strikeEar] = \mic; ~le.strikeClear(false); w = ~le.strikeTake(msg.(\W7, (pass: 3)), t0 + 200);
~le.strikeMicOnset(\bcl, t0 + 200.2, 0.5); ~le.strikeMicOnset(\va, t0 + 200.4, 0.001);
check.("the microphone's hit becomes an onset with a mark read against the ladder (loud near the top, quiet near the floor)", (w[\onsets].size == 2) and: { ~le.strikeMarkIx(w[\onsets][0][\mark]) >= 5 } and: { ~le.strikeMarkIx(w[\onsets][1][\mark]) <= 2 }, w[\onsets].collect({ |o| o[\who].asString ++ " " ++ o[\mark] }).join(" · "));
~le[\strikeEar] = \sim;

// THE CASCADE [the Decibel piece's 17.3, DEC-120] — on the piece's own numbers: window W32 of its section 5B (a strike of four onsets,
// answered three times: rotated · then that answer as played · then the retrograde of THAT). The numbers are the page's
// (score/le_strike.js StrikeCalc.cascade, run in node on the score), pasted here.
"STRIKE_TEST the cascade (the piece's window W32; the page's numbers):".postln;
~le.strikeClear(false);
w = ~le.strikeTake((id: \W32, dueMs: 0, lengthMs: 359, type: "rotate", timing: "callResponse", seed: 10321, gapMs: 163, graceMs: 163, level: "mimic", deal: "robin", processed: 1,
	dials: "wLo=0.8,wHi=1.2,minMs=300", mode: "notated", answers: 3, chain: "asPlayed:inLaterWindow:10322,retrograde:callResponse:10323", dials2: "wLo=10,wHi=15", dials3: "wLo=0.8,wHi=1.2,minMs=300", pass: 9), t0 + 300);
check.("a message with a chain becomes a window with its links, each with its own numbers; its word is kept; its grace is its own",
	(w[\chain].size == 2) and: { w[\chain][0][\type] == \asPlayed } and: { w[\chain][0][\timing] == \inLaterWindow } and: { w[\chain][0][\seed] == 10322 } and: { w[\chain][0][\dials][\wLo] == 10 }
	and: { w[\chain][1][\type] == \retrograde } and: { w[\chain][1][\dials][\minMs] == 300 } and: { w[\mode] == "notated" } and: { near.(w[\graceS], 0.163, 0.0001) } and: { w[\gapS] == 0.163 }, said.last);
[[0, \bcl], [0.083, \perc], [0.098, \vc], [0.159, \bfl]].do({ |x| ~le.strikeOnset(x[1], t0 + 300.1 + x[0], \mf) });
check.("the NEXT strike's first onset, 291 ms after this window's end, is not taken by it (its grace is 163 ms)", (~le.strikeOnset(\va, t0 + 300.65, \mf) == 0) and: { w[\onsets].size == 4 }, w[\onsets].size.asString ++ " collected");
ans = ~le.strikeStep(w, t0 + 300.259 + 0.17);
check.("over 163 ms after the last onset: THREE answers; the first is the strike rotated, from the strike's last onset",
	ans.notNil and: { ans[\chain].size == 2 } and: { rel.(ans[\onsets]).every({ |v, i| near.(v, [0, 15, 76, 159][i]) }) } and: { near.(ans[\atS], t0 + 300.259 + 0.278584, 0.001) },
	if(ans.notNil) { rel.(ans[\onsets]).collect(_.round(0.1)).join(" ") ++ " · at +" ++ (ans[\atS] - (t0 + 300.259)).round(0.001) ++ " s" } { "no answer" });
check.("answer 2 is ANSWER 1 as played, begun by its timing after answer 1's last onset",
	rel.(ans[\chain][0][\onsets]).every({ |v, i| near.(v, [0, 15, 76, 159][i]) }) and: { near.(ans[\chain][0][\atS], t0 + 300.259 + 13.169770, 0.001) } and: { ans[\chain][0][\k] == 2 },
	rel.(ans[\chain][0][\onsets]).collect(_.round(0.1)).join(" ") ++ " · at +" ++ (ans[\chain][0][\atS] - (t0 + 300.259)).round(0.001) ++ " s");
check.("answer 3 is the retrograde of ANSWER 2 — not of the strike (that would be 0 61 76 159)",
	rel.(ans[\chain][1][\onsets]).every({ |v, i| near.(v, [0, 83, 144, 159][i]) }) and: { near.(ans[\chain][1][\atS], t0 + 300.259 + 13.641779, 0.001) } and: { ans[\chain][1][\k] == 3 },
	rel.(ans[\chain][1][\onsets]).collect(_.round(0.1)).join(" ") ++ " · at +" ++ (ans[\chain][1][\atS] - (t0 + 300.259)).round(0.001) ++ " s");
check.("each answer is dealt its own samples, one an onset; a call carries the window's name and the answer's number",
	([ans] ++ ans[\chain]).every({ |a| a[\pattern].split($,).size == 4 }) and: { ~le.strikePlayMsg(w, ans[\chain][1], t0 + 301)[\d][\id] == "W32-3" } and: { ~le.strikePlayMsg(w, ans, t0 + 301)[\d][\id] == "W32" },
	ans[\pattern] ++ " | " ++ ans[\chain][0][\pattern] ++ " | " ++ ans[\chain][1][\pattern]);
check.("the engine says each answer of the cascade", said.any({ |s| s.contains("answer 2 of 3") }) and: { said.any({ |s| s.contains("answer 3 of 3") }) } and: { said.any({ |s| s.contains("answer 1 of 3") }) }, said.last);

if(fails.size == 0) { "STRIKE_TEST PASS".postln; 0.exit } { ("STRIKE_TEST FAIL — " ++ fails.size ++ " check(s): " ++ fails.join(" · ")).postln; 1.exit };
)
