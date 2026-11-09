// material_test.scd — THE MATERIAL, HEADLESS (the Switch~ piece's 1a.7, 2026-11-09): the spec with no server, and \leMaterial2 in NRT on
// a made stereo file — the stretch is the offset's, the edges fade, the level follows its line. No server, no device, no sound; a living
// engine beside it is untouched.
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/material_test.scd
// It ends MATERIAL_TEST PASS (exit 0) or MATERIAL_TEST FAIL (exit 1) and names each check.
(
var dir = thisProcess.nowExecutingPath.dirname;
var tmp = Platform.defaultTempDir +/+ "le_material_test_" ++ Date.localtime.stamp;
var sr = 44100, secs = 4, n = sr * secs, src, sf, fails = List.new, check, render, rms, zc, sp, idx, r1, r2, defs, a1, b1, a2, b2, mid1, mid2;
(dir +/+ "boot.scd").load;
File.mkdir(tmp);
check = { |what, ok, detail| ("  " ++ if(ok) { "ok   " } { "FAIL " } ++ what ++ " — " ++ detail).postln; if(ok.not) { fails.add(what) } };
// THE FILE: stereo, 4 s — 440 Hz for the first two seconds, 880 Hz for the last two, at -12 dBFS peak (the "material")
src = FloatArray.newClear(n * 2);
n.do({ |i| var t = i / sr, f = if(t < 2) { 440 } { 880 }, v = sin(2pi * f * t) * 0.25; src[2 * i] = v; src[(2 * i) + 1] = v });
sf = SoundFile.new.headerFormat_("WAV").sampleFormat_("float").numChannels_(2).sampleRate_(sr);
sf.openWrite(tmp +/+ "mat.wav"); sf.writeData(src); sf.close;
// THE INDEX, as a piece writes it
File.use(tmp +/+ "materials.json", "w", { |f| f.write("{\"root\": \"" ++ tmp.replace("\\", "/") ++ "\", \"materials\": [{\"name\": \"mat\", \"file\": \"mat.wav\", \"seconds\": 4, \"channels\": 2, \"sr\": 44100, \"kind\": \"test\"}]}") });
~le.materialsOn(tmp +/+ "materials.json");
check.("the index read", ~le[\materials].size == 1 and: { ~le[\materials][\mat][\path].asString.endsWith("mat.wav") }, ~le[\materials].size.asString ++ " material(s)");
// THE SPEC, pure
sp = ~le.materialSpec((offsetMs: 2500, lengthMs: 1000, fadeInMs: 50, fadeOutMs: 100, level: "f"), ~le[\materials][\mat]);
check.("the spec: offset · length · fades", (sp[\offS] == 2.5) and: { sp[\lenS] == 1.0 } and: { sp[\fadeIn] == 0.05 } and: { sp[\fadeOut] == 0.1 }, sp[\said]);
check.("a mark is decibels against the file: f = +4, mf = 0, p = -8", (~le.materialMarkDb("f") == 4) and: { ~le.materialMarkDb("mf") == 0 } and: { ~le.materialMarkDb("p") == -8 } and: { ~le.materialMarkDb("5.5") == 6 }, "f " ++ ~le.materialMarkDb("f") ++ " · p " ++ ~le.materialMarkDb("p") ++ " · 5.5 " ++ ~le.materialMarkDb("5.5"));
sp = ~le.materialSpec((offsetMs: 3500, lengthMs: 5000), ~le[\materials][\mat]);
check.("the length is held to the file's end", (sp[\lenS] - 0.5).abs < 0.001, sp[\lenS].asString ++ " s of the 5 asked, 0.5 left in the file");
sp = ~le.materialSpec((offsetMs: 0, lengthMs: 2000, level: "0:p,1000:mf,end:ff"), ~le[\materials][\mat]);
check.("a level line: three points in decibels", (sp[\points].size == 3) and: { sp[\points][0][1] == -8 } and: { sp[\points][1][1] == 0 } and: { sp[\points][2][1] == 8 } and: { sp[\points][2][0] == 2000 }, sp[\said]);
// THE SYNTH IN NRT: a stretch from 2.5 s (the 880 Hz half), 1 s long, fades 50/100 ms, at f (+4 dB)
defs = ~le.materialDefs;
render = { |out, offS, lenS, extra|
	var frame = (offS * sr).asInteger, score, path = tmp +/+ out, opts = ServerOptions.new.numOutputBusChannels_(2);
	score = Score([
		[0.0, ['/d_recv', defs[1].asBytes]],
		[0.0, ['/b_alloc', 0, 65536, 2]],
		[0.0, ['/b_read', 0, tmp +/+ "mat.wav", frame, -1, 0, 1]],
		[0.05, ['/s_new', \leMaterial2, 1000, 0, 0, \buf, 0, \out, 0, \dur, lenS] ++ extra.asOSCArgArray],   // the control arrays as $[ … $] — an NRT s_new dies on a nested array (bus_test.scd's way)
		[0.05 + lenS + 0.2, ['/c_set', 0, 0]]
	]);
	score.recordNRT(tmp +/+ out ++ ".osc", path, nil, sr, "WAV", "float", opts, "", nil, { |code| idx = code });
	while { idx.isNil } { 0.1.wait };
	idx = nil;
	path
};
rms = { |data, from, to| var acc = 0, k = 0; (from..(to - 1)).do({ |i| acc = acc + data[2 * i].squared; k = k + 1 }); if(k > 0) { (acc / k).sqrt } { 0 } };
zc = { |data, from, to| var c = 0; (from..(to - 2)).do({ |i| if((data[2 * i] >= 0) != (data[2 * (i + 1)] >= 0)) { c = c + 1 } }); c };
fork {
	var p1, p2, d1, d2, f, start = (0.05 * sr).asInteger, len = sr;
	p1 = render.("r1.wav", 2.5, 1.0, [\fadeIn, 0.05, \fadeOut, 0.1, \envDb, 4 ! 16, \envDt, 0.01 ! 15]);
	f = SoundFile.openRead(p1); d1 = FloatArray.newClear(f.numFrames * 2); f.readData(d1); f.close;
	// the stretch is the second half's: 880 Hz = 1760 zero crossings a second
	a1 = zc.(d1, start + (0.2 * sr).asInteger, start + (0.8 * sr).asInteger);
	check.("the stretch is the offset's — 880 Hz in the middle 0.6 s", (a1 - 1056).abs < 12, a1.asString ++ " zero crossings (880 Hz gives 1056)");
	// the level: +4 dB on a -12 dBFS sine (rms 0.1768) -> rms 0.280
	mid1 = rms.(d1, start + (0.3 * sr).asInteger, start + (0.7 * sr).asInteger);
	check.("the level: f = +4 dB over the file", ((mid1 / 0.17678).ampdb - 4).abs < 0.3, (mid1 / 0.17678).ampdb.round(0.01).asString ++ " dB");
	// the edges: the first 5 ms and the last 10 ms stand well under the middle
	b1 = rms.(d1, start, start + (0.005 * sr).asInteger); b2 = rms.(d1, start + len - (0.01 * sr).asInteger, start + len);
	check.("the edges fade — the first 5 ms and the last 10 ms under -12 dB of the middle", (b1 < (mid1 * 0.25)) and: { b2 < (mid1 * 0.25) }, (b1 / mid1).ampdb.round(0.1).asString ++ " dB · " ++ (b2 / mid1).ampdb.round(0.1) ++ " dB");
	// it ends: nothing 0.15 s after the length
	check.("it ends at its length", rms.(d1, start + len + (0.15 * sr).asInteger, (d1.size / 2).asInteger - 1) < 0.001, "after the length: " ++ rms.(d1, start + len + (0.15 * sr).asInteger, (d1.size / 2).asInteger - 1).round(0.0001));
	// a level line p -> ff over the second: the last 100 ms about 16 dB over the first 100 ms (after the fade)
	p2 = render.("r2.wav", 0.0, 1.0, [\fadeIn, 0.01, \fadeOut, 0.01, \envDb, [-8, 8] ++ (8 ! 14), \envDt, [1.0] ++ (0.01 ! 14)]);
	f = SoundFile.openRead(p2); d2 = FloatArray.newClear(f.numFrames * 2); f.readData(d2); f.close;
	a2 = rms.(d2, start + (0.03 * sr).asInteger, start + (0.1 * sr).asInteger); b2 = rms.(d2, start + (0.88 * sr).asInteger, start + (0.95 * sr).asInteger);
	check.("a level line: p → ff over the second, the end 14 … 17 dB over the start", ((b2 / a2).ampdb > 13.5) and: { (b2 / a2).ampdb < 17.5 }, (b2 / a2).ampdb.round(0.1).asString ++ " dB");
	("MATERIAL_TEST " ++ if(fails.size == 0) { "PASS" } { "FAIL (" ++ fails.join(" · ") ++ ")" }).postln;
	if(fails.size == 0) { 0.exit } { 1.exit };
};
)
