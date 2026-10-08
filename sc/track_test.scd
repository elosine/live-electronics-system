// track_test.scd — THE TRACKER, OFFLINE (the Decibel piece's PLAN 1.8 · 16.1 f, 2026-10-08): track.scd's rules in a bare sclang, and
// \leSineTrack heard by a second scsynth with no device and no port (NRT) into files, the files measured. No server of the engine's
// is asked anything: a living engine beside it is untouched, and nothing sounds.
//   THE RULES     no `gate`: a plain sine · the piece's ear when none is said · a microphone's threshold by what the house gives ·
//                 the sound check's guard: a microphone that hears the sine too well follows nothing · the pitch line led by a jump ·
//                 a told level as \leTrackSim's line
//   THE MICROPHONE  a synthetic player on a bus — silence 1 s · in at −20 dB · up to −14 · up to −8 · a 0.75 s breath · back at −8
//                 for 1 s · silence — and the tracked sine measured: silent before the entry · AT ITS WRITTEN MARK at the reference ·
//                 +6 dB where the player is +6 · held at the cap where the player is +12 · sounding through the breath · gone after
//                 the hold · its glide begun again at the re-entry
//   HALF          the same with follow 0.5: half the rise — and through the breath it stands where it stood
//   THE ROOM      a player under the threshold never opens the gate
//   TOLD          the simulated ear: a level told on the sim bus (p for 0.6 s, then to f) — in with it, at the cap by its end,
//                 held through a gap to the next told note, gone after the last
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/track_test.scd
// It ends TRACK_TEST PASS (exit 0) or TRACK_TEST FAIL (exit 1) and names each check.
(
var dir = thisProcess.nowExecutingPath.dirname;
var tmp = Platform.defaultTempDir +/+ "le_track_test_" ++ Date.localtime.stamp;
var sr = 44100, fails = List.new, check, near, db, defs, render, pk, freqAt, cents, player, sineMsg;
(dir +/+ "boot.scd").load;
~le[\sr] = sr;
(dir +/+ "synths.scd").load;   // no server: the SynthDefs are built, and kept in the library
// the synthetic player: a sine at the pitch whose level is a line in decibels (13 points). The line runs at AUDIO rate: at control
// rate a 10 ms segment is seven steps and lands 13 dB short of its node (measured here, 2026-10-08) — the entry would be a slow rise
SynthDef(\ttPlayer, { |out = 10, freq = 220|
	var d = \envDb.ir(-120 ! 13), t = \envDt.ir(0.01 ! 12);
	Out.ar(out, SinOsc.ar(freq) * EnvGen.ar(Env(d, t, 0)).dbamp);
}).add;
File.mkdir(tmp);
check = { |what, ok, detail| ("  " ++ if(ok) { "ok   " } { "FAIL " } ++ what ++ " — " ++ detail).postln; if(ok.not) { fails.add(what) } };
near = { |a, b, tol| a.notNil and: { (a - b).abs <= tol } };
db = { |x| if(x > 0) { x.ampdb.round(0.01) } { -200 } };
defs = [\leSineTrack, \leTrackSim, \ttPlayer].collect({ |n| [0.0, ['/d_recv', SynthDescLib.global[n].def.asBytes]] });
render = { |name, msgs, dur, chans = 2|
	var osc = tmp +/+ name ++ ".osc", wav = tmp +/+ name ++ ".wav", done = false, sf, data, frames, opts;
	opts = ServerOptions.new.numOutputBusChannels_(chans).numInputBusChannels_(2).numAudioBusChannels_(64).memSize_(65536);
	Score(defs ++ msgs ++ [[dur, ['/c_set', 0, 0]]]).recordNRT(osc, wav, nil, sr, "WAV", "float", opts, "", nil, { done = true });
	while { done.not } { 0.05.wait };
	sf = SoundFile.new;
	if(File.exists(wav) and: { sf.openRead(wav) }) { data = FloatArray.newClear(sf.numFrames * sf.numChannels); sf.readData(data); frames = sf.numFrames; sf.close };
	if(data.isNil) { nil } { chans.collect({ |c| FloatArray.fill(frames, { |i| data[(i * chans) + c] }) }) }
};
pk = { |x, from, to| var a = (from * sr).asInteger, b = ((to * sr).asInteger - 1).min(x.size - 1), m = 0; (a..b).do({ |i| m = max(m, x[i].abs) }); m };
freqAt = { |x, t, win = 0.1|
	var a = ((t - (win / 2)) * sr).asInteger, b = ((t + (win / 2)) * sr).asInteger, first, last, n = 0, z;
	(a..(b - 1)).do({ |i|
		if((x[i] < 0) and: { x[i + 1] >= 0 }) {
			z = i + (x[i].neg / (x[i + 1] - x[i]));
			if(first.isNil) { first = z } { n = n + 1 };
			last = z;
		};
	});
	if(n > 0) { n * sr / (last - first) } { 0 }
};
cents = { |f, ref| 1200 * log2(f / ref) };
// the player's line, from its own start: silence 1 s · −20 · → −14 by 3.1 · → −8 by 4.1 · a breath 4.61 … 5.35 · −8 until 6.35 · silence
player = { |t0, id, levels|
	[t0, ['/s_new', \ttPlayer, id, 0, 0, \out, 10, \freq, 220] ++ [\envDb, levels ? [-120, -120, -20, -20, -14, -14, -8, -8, -120, -120, -8, -8, -120],
		\envDt, [1.0, 0.01, 0.59, 1.5, 0.5, 0.5, 0.5, 0.01, 0.74, 0.01, 0.99, 0.01]].asOSCArgArray]
};
// a tracked sine as sine.scd's sinePlay makes it: the message's own fields, the tracker's numbers, the buses said here
sineMsg = { |t0, id, d, extra|
	var sp = ~le.sineSpec(d), tr = ~le.trackSpec(d, sp), spT = sp.copy;
	spT[\glissCents] = tr[\glissCents]; spT[\glissDt] = tr[\glissDt];
	[t0, ['/s_new', \leSineTrack, id, 1, 0, \out, 0] ++ (~le.sineArgs(spT) ++ tr[\args] ++ extra).asOSCArgArray]
};
fork {
	var t0 = 0.05, mf = ~le.sineGain(220, 4), sp, tr, r, a, b, c, e, f1, f2, sim, d, ok;
	("TRACK_TEST the scratch folder: " ++ tmp).postln;

	"TRACK_TEST the rules:".postln;
	sp = ~le.sineSpec((midi: 57, lengthMs: 10000, level: "mf", gliss: "0:-50,4000:0"));
	check.("a sine with no gate is a plain sine", ~le.trackSpec((midi: 57), sp).isNil and: { ~le.trackSpec((midi: 57, gate: 0), sp).isNil }, "trackSpec answers nil without `gate 1`");
	tr = ~le.trackSpec((midi: 57, gate: 1, player: "bcl"), sp);
	check.("a window with nothing more said: the piece's ear, its follow, its cap, the floor as the threshold",
		tr.notNil and: { tr[\who] == \bcl } and: { tr[\ear] == \sim } and: { tr[\follow] == 1 } and: { tr[\capDb] == 8 } and: { tr[\thrDb] == -60 },
		"who " ++ tr[\who] ++ " · ear " ++ tr[\ear] ++ " · follow " ++ tr[\follow] ++ " · cap " ++ tr[\capDb] ++ " · threshold " ++ tr[\thrDb]);
	check.("its pitch line is led by a jump to its own first value (it begins again at each entry)",
		(tr[\glissCents].keep(3) == [-50.0, -50.0, 0.0]) and: { near.(tr[\glissDt][0], 0.005, 1e-9) } and: { near.(tr[\glissDt][1], 4, 1e-6) } and: { tr[\glissCents].size == 8 } and: { tr[\glissDt].size == 7 },
		"cents " ++ tr[\glissCents].keep(3) ++ " … · times " ++ tr[\glissDt].keep(2).round(0.001) ++ " …");
	tr = ~le.trackSpec((midi: 57, gate: 1, lane: 3, ear: "mic", follow: 0.5, capDb: 6), sp);
	check.("what a message says stands: the ear, the follow, the cap; a lane with no player's name is lane<N>",
		(tr[\ear] == \mic) and: { tr[\follow] == 0.5 } and: { tr[\capDb] == 6 } and: { tr[\who] == \lane3 }, "who " ++ tr[\who] ++ " · ear " ++ tr[\ear] ++ " · follow " ++ tr[\follow] ++ " · cap " ++ tr[\capDb]);
	~le[\venue] = (bcl: (roomBandDb: "-70"), va: (roomDb: "-45"), vc: (roomBandDb: "-70", sineBleedDb: "-30"), bfl: (roomBandDb: "-70", sineBleedDb: "-62"));
	check.("a microphone's threshold: the band's own room + the gate · a broadband room + the band's share + the gate · else the floor",
		(~le.trackThr(\bcl) == -60) and: { ~le.trackThr(\va) == -55 } and: { ~le.trackThr(\perc) == -60 },
		"bcl (its band's room −70) " ++ ~le.trackThr(\bcl) ++ " · va (a room of −45) " ++ ~le.trackThr(\va) ++ " · perc (nothing measured) " ++ ~le.trackThr(\perc));
	~le.trackGuard;
	a = ~le.trackSpec((midi: 57, gate: 1, player: "vc", ear: "mic"), sp); b = ~le.trackSpec((midi: 57, gate: 1, player: "bfl", ear: "mic"), sp); c = ~le.trackSpec((midi: 57, gate: 1, player: "vc", ear: "sim"), sp);
	check.("the sound check's guard: a microphone that hears the sine 40 dB over its room follows nothing; one that hears it 8 dB over does; a told level is not a microphone",
		(a[\follow] == 0) and: { a[\bled] } and: { b[\follow] == 1 } and: { c[\follow] == 1 }, "vc by its microphone: follow " ++ a[\follow] ++ " · bfl: follow " ++ b[\follow] ++ " · vc told: follow " ++ c[\follow]);
	~le[\venue] = nil; ~le[\trackNoFollow] = nil;
	sim = ~le.trackSimSpec((lengthMs: 2000, level: "0:p,600:p,end:f"));
	check.("a told level becomes \\leTrackSim's line: a mark as its distance under fff, 4 dB a step",
		(sim[\envDb].keep(3) == [-20.0, -20.0, -8.0]) and: { near.(sim[\envDt][0], 0.6, 1e-6) } and: { near.(sim[\envDt][1], 1.4, 1e-6) } and: { sim[\dur] == 2 } and: { ~le.trackSimSpec((lengthMs: 500))[\envDb][0] == -12 },
		"p · p · f over 2 s -> " ++ sim[\envDb].keep(3) ++ " dB over " ++ sim[\envDt].keep(2).round(0.001) ++ " s · nothing said is mf, −12");

	"TRACK_TEST the microphone — a synthetic player on a bus, the tracked sine measured:".postln;
	d = (midi: 57, lengthMs: 10000, level: "mf", gliss: "0:-50,4000:0", gate: 1, player: "bcl", ear: "mic");
	r = render.("a", [player.(t0, 1001), sineMsg.(t0, 1000, d, [\in, 10, \simBus, 0, \id, 1])], 10.3);
	check.("silent until the player sounds", pk.(r[0], 0, t0 + 0.99) == 0, "the loudest sample of its first second " ++ pk.(r[0], 0, t0 + 0.99));
	a = db.(pk.(r[0], t0 + 1.45, t0 + 1.58));
	check.("it enters with them, AT ITS WRITTEN MARK at the reference", near.(a, mf, 0.5) and: { pk.(r[0], t0 + 1.12, t0 + 1.2) > 0 },
		"sounding 110 ms after the entry (" ++ db.(pk.(r[0], t0 + 1.12, t0 + 1.2)) ++ " dB) · at the reference its peak " ++ a ++ " dB (mf at A3 = " ++ mf.round(0.01) ++ ")");
	b = db.(pk.(r[0], t0 + 3.4, t0 + 3.58));
	check.("it follows the rise: the player +6 dB, the sine +6 dB", near.(b - a, 6, 0.5), "the player −20 → −14 · the sine " ++ a ++ " → " ++ b ++ " dB = +" ++ (b - a).round(0.01));
	c = db.(pk.(r[0], t0 + 4.4, t0 + 4.58));
	check.("the cap: the player +12 dB, the sine +8 dB and no more", near.(c - a, 8, 0.5), "the player −20 → −8 · the sine " ++ a ++ " → " ++ c ++ " dB = +" ++ (c - a).round(0.01));
	e = db.(pk.(r[0], t0 + 4.9, t0 + 5.3));
	check.("it holds through a 0.75 s breath, and stands there when they are back", near.(e - a, 8, 0.5) and: { near.(db.(pk.(r[0], t0 + 5.8, t0 + 6.3)) - a, 8, 0.5) },
		"in the breath +" ++ (e - a).round(0.01) ++ " dB · after the re-entry +" ++ (db.(pk.(r[0], t0 + 5.8, t0 + 6.3)) - a).round(0.01));
	check.("it leaves when they stop: there for the hold, gone after it", (pk.(r[0], t0 + 7.0, t0 + 7.5) > 0) and: { pk.(r[0], t0 + 8.7, t0 + 9.9) == 0 },
		"1 s after their last sound " ++ db.(pk.(r[0], t0 + 7.0, t0 + 7.5)) ++ " dB · from 2.35 s after it the loudest sample " ++ pk.(r[0], t0 + 8.7, t0 + 9.9));
	f1 = cents.(freqAt.(r[0], t0 + 4.5), 220); f2 = cents.(freqAt.(r[0], t0 + 5.7), 220);
	check.("its glide (−50 → 0 cents over 4 s) runs from the entry — and begins again at the re-entry", near.(f1, -50 + (50 * 3.47 / 4), 4) and: { near.(f2, -50 + (50 * 0.32 / 4), 4) },
		"3.5 s after the first entry " ++ f1.round(0.1) ++ " c (the line −6.6) · 0.3 s after the re-entry " ++ f2.round(0.1) ++ " c (the line −46; had it run on: 0)");

	"TRACK_TEST half the follow:".postln;
	d = (midi: 57, lengthMs: 10000, level: "mf", gate: 1, player: "bcl", ear: "mic", follow: 0.5);
	r = render.("b", [player.(t0, 1001), sineMsg.(t0, 1000, d, [\in, 10, \simBus, 0, \id, 1])], 10.3);
	a = db.(pk.(r[0], t0 + 1.45, t0 + 1.58)); b = db.(pk.(r[0], t0 + 3.4, t0 + 3.58)); c = db.(pk.(r[0], t0 + 4.4, t0 + 4.58)); e = db.(pk.(r[0], t0 + 4.95, t0 + 5.3));
	check.("follow 0.5: half the player's rise — and through the breath the sine stands where it stood", near.(b - a, 3, 0.5) and: { near.(c - a, 6, 0.5) } and: { near.(e, c, 0.5) },
		"the player +6: the sine +" ++ (b - a).round(0.01) ++ " · the player +12: +" ++ (c - a).round(0.01) ++ " · in the breath " ++ (e - c).round(0.01) ++ " dB against just before it");

	"TRACK_TEST the room:".postln;
	d = (midi: 57, lengthMs: 4000, level: "mf", gate: 1, player: "bcl", ear: "mic");
	r = render.("c", [player.(t0, 1001, [-120, -70, -70, -70, -70, -70, -70, -70, -70, -70, -70, -70, -70]), sineMsg.(t0, 1000, d, [\in, 10, \simBus, 0, \id, 1])], 4.3);
	check.("a sound under the threshold (−70 dB against −60) never opens the gate", pk.(r[0], 0, 4.2) == 0, "the loudest sample of four seconds " ++ pk.(r[0], 0, 4.2));

	"TRACK_TEST told — the simulated ear:".postln;
	d = (midi: 57, lengthMs: 8000, level: "mf", gate: 1, player: "bcl", ear: "sim");
	sim = ~le.trackSimSpec((lengthMs: 2000, level: "0:p,600:p,end:f"));
	r = render.("d", [[0.0, ['/c_set', 5, -120]],
		[t0 + 1.0, ['/s_new', \leTrackSim, 1001, 0, 0, \bus, 5, \dur, sim[\dur]] ++ [\envDb, sim[\envDb], \envDt, sim[\envDt]].asOSCArgArray],
		[t0 + 3.6, ['/s_new', \leTrackSim, 1002, 0, 0, \bus, 5, \dur, 1] ++ [\envDb, -8 ! 8, \envDt, 0.01 ! 7].asOSCArgArray],
		sineMsg.(t0, 1000, d, [\in, 10, \simBus, 5, \id, 1])], 8.3);
	a = db.(pk.(r[0], t0 + 1.45, t0 + 1.58)); b = db.(pk.(r[0], t0 + 2.9, t0 + 2.98)); c = db.(pk.(r[0], t0 + 3.2, t0 + 3.55)); e = db.(pk.(r[0], t0 + 4.0, t0 + 4.5));
	ok = (pk.(r[0], 0, t0 + 0.99) == 0) and: { near.(a, mf, 0.5) } and: { near.(b - a, 8, 0.5) } and: { near.(c - a, 8, 0.5) } and: { near.(e - a, 8, 0.5) }
		and: { pk.(r[0], t0 + 5.3, t0 + 5.8) > 0 } and: { pk.(r[0], t0 + 6.7, t0 + 7.9) == 0 };
	check.("a told p that rises to f: silent before it · in at the written mark · at the cap by its end · held through the gap and the next told note · gone after the last", ok,
		"before " ++ pk.(r[0], 0, t0 + 0.99) ++ " · at the reference " ++ a ++ " dB (mf " ++ mf.round(0.01) ++ ") · by the note's end +" ++ (b - a).round(0.01) ++ " · in the gap +" ++ (c - a).round(0.01)
			++ " · in the next note +" ++ (e - a).round(0.01) ++ " · 1 s after the last " ++ db.(pk.(r[0], t0 + 5.3, t0 + 5.8)) ++ " dB · then " ++ pk.(r[0], t0 + 6.7, t0 + 7.9));

	if(fails.size == 0) { try { File.deleteAll(tmp) }; "TRACK_TEST PASS".postln; 0.exit } { ("TRACK_TEST FAIL — " ++ fails.join(" · ")).postln; 1.exit };
};
)
