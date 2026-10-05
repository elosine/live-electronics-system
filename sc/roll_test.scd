// roll_test.scd — THE ROLLS, HEADLESS (the engine's RUNNING_LOG §22; the Decibel piece's §91, 2026-10-05): bank.scd into a bare sclang,
// no server, no sound — what arChain · chain · ar produce for three samples, with a piece's dials inline (edit them to yours).
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/roll_test.scd
// A living engine beside it is untouched: nothing here opens a port or a device.
(
var dir = thisProcess.nowExecutingPath.dirname;
~le = ();
~le[\say] = { |self, kind, text| (kind ++ " " ++ text).postln; self };
(dir +/+ "bank.scd").load;
// the piece's dials as the engine gets them (tools/elec.js: LE_AR · LE_CHAIN), parsed as session.scd does
~le[\arOpts] = ();
"before=0.35,after=0.35,lazy=0.15,unison=0.15,afterLo=150,afterHi=270,beforeLo=90,beforeHi=225,lazyLo=270,lazyHi=600,unisonLo=10,unisonHi=40,skew=2,missRate=0.1,missLateShare=0.67,missLateLo=0,missLateHi=120,missEarlyLo=225,missEarlyHi=450"
	.split($,).do({ |kv| var b = kv.split($=); ~le[\arOpts][b[0].asSymbol] = b[1].asFloat });
~le[\chainOpts] = ();
"after=0.7,lazy=0.2,unison=0.1,before=0,follow=1,shuffle=1".split($,).do({ |kv| var b = kv.split($=); ~le[\chainOpts][b[0].asSymbol] = b[1].asFloat });
"ROLL_TEST arChain — 8 rolls of three samples:".postln;
8.do({ |n|
	var links = ~le.chainRoll(["vc-impulse-1", "vc-impulse-2", "vc-impulse-3"], true);
	("  roll " ++ (n + 1) ++ ": " ++ links.size ++ " links · " ++ links.collect({ |k| k[\name] ++ " " ++ k[\stance] ++ " at " ++ k[\atMs].round(1).asInteger ++ " ms (" ++ k[\ref] ++ ")" }).join(" · ")).postln;
});
"ROLL_TEST chain — 4 rolls:".postln;
4.do({ |n|
	var links = ~le.chainRoll(["a", "b", "c"], false);
	("  roll " ++ (n + 1) ++ ": " ++ links.size ++ " links · " ++ links.collect({ |k| k[\name] ++ " " ++ k[\stance] ++ " at " ++ k[\atMs].round(1).asInteger ++ " ms (" ++ k[\ref] ++ ")" }).join(" · ")).postln;
});
"ROLL_TEST ar — 6 rolls:".postln;
6.do({ |n| var r = ~le.arRoll; ("  " ++ r[\stance] ++ " " ++ r[\offsetMs].round(1).asInteger ++ " ms").postln });
"ROLL_TEST chainNames — the names a chain plays:".postln;
~le[\samples] = IdentityDictionary.new; [\p_1, \q_2, \r_3].do({ |k| ~le[\samples].put(k, ()) });
("  \"a,b,c\" -> " ++ ~le.chainNames("a,b,c")).postln;
("  \"*\" -> " ++ ~le.chainNames("*")).postln;
("  \"a, *\" -> " ++ ~le.chainNames("a,*")).postln;
("  \"\" -> " ++ ~le.chainNames("")).postln;
"ROLL_TEST patternOnsets — a composed rhythm parsed (behaviour pattern):".postln;
~le.patternOnsets("a:0,b:250.5").collect({ |k| k[\name] ++ " at " ++ k[\atMs] ++ " ms" }).join(" · ").postln;
~le.patternOnsets("vc-impulse-1: 10, x/y:-5, :3,").collect({ |k| k[\name] ++ " at " ++ k[\atMs] ++ " ms" }).join(" · ").postln;
("  \"\" -> " ++ ~le.patternOnsets("").size ++ " onsets").postln;
~le.patternOnsets("a:0:-6,b:250:3.5,c:500:40").collect({ |k| k[\name] ++ " at " ++ k[\atMs] ++ " ms " ++ k[\db] ++ " dB (amp " ++ k[\db].dbamp.round(0.001) ++ ")" }).join(" · ").postln;
"ROLL_TEST done".postln;
0.exit;
)
