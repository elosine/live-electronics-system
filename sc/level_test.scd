// level_test.scd — THE LEVEL, HEADLESS (the engine plan's part 13; the Decibel piece's PLAN 1.4, 2026-10-06): boot.scd's functions
// into a bare sclang — NO server, no device, no port, no sound — and the figures checked:
//   THE MEASURE   the K-weighting's coefficients at 48 kHz are the standard's table · the players' reference tone (1 kHz at −20 dBFS
//                 RMS) reads −17.0 LUFS at 48 kHz and at 44.1 kHz, from the samples and from a FILE · a 100 ms burst of it reads
//                 6 dB less in its loudest 400 ms and the same over its own length · how long a 7.5 s sample holds the language
//   THE LADDER    the marks' decibels · the name nearest a loudness · a brick's dynamic as a gain: played · a mark · relative, with
//                 a floor and a ceiling · the lift's cap · the floor · a row with no figure
//   THE ENVELOPE  a line of three points and a hairpin, as \leSample is given them: the dB at each breakpoint, the times between
//   THE INDEX     a row's figure is written and read back as a NUMBER
//   THE BUS       a piece's dials become the master's arguments, and a message moves them (the sound of the bus is bus_test.scd's)
//   THE FILES     every file of the engine that boots a server still PARSES — they cannot be run beside a living engine
//   THE GUARD     (11.7 c) a capture whose attack stands too little over the room is flagged; a clean one is not
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/level_test.scd
// LE_TEST_FILE=<a mono wav>  adds one line: that file's two figures (a cross-check against another implementation).
// A living engine beside it is untouched. It ends LEVEL_TEST PASS (exit 0) or LEVEL_TEST FAIL (exit 1) and names each check.
(
var dir = thisProcess.nowExecutingPath.dirname;
var tmp = Platform.defaultTempDir +/+ "le_level_test_" ++ Date.localtime.stamp;
var fails = List.new, check, near, tone, co, m, m44, mShort, mFile, long, t0, took, row, quiet, faint, bare, g, lv, rows, extra, f, b, sd, ma, bad;
(dir +/+ "boot.scd").load;
check = { |what, ok, detail| ("  " ++ if(ok) { "ok   " } { "FAIL " } ++ what ++ " — " ++ detail).postln; if(ok.not) { fails.add(what) } };
near = { |a, b, tol| a.notNil and: { (a - b).abs <= tol } };
tone = { |sr, secs, rmsDb = -20, freq = 1000| FloatArray.fill((secs * sr).asInteger, { |i| sin(2pi * freq * i / sr) * (rmsDb.dbamp * 2.sqrt) }) };

"LEVEL_TEST the measure:".postln;
co = ~le.kCoefs(48000);
check.("the K-weighting at 48 kHz is the standard's table",
	[[co[\shelf], [1.53512485958697, -2.69169618940638, 1.19839281085285, -1.69065929318241, 0.73248077421585]],
		[co[\hp], [1, -2, 1, -1.99004745483398, 0.99007225036621]]].every({ |p| p[0].every({ |x, i| (x - p[1][i]).abs < 1e-6 }) }),
	"shelf " ++ co[\shelf].collect(_.round(1e-8)) ++ " · high-pass " ++ co[\hp].collect(_.round(1e-8)));
t0 = Main.elapsedTime; m = ~le.loudOf(tone.(48000, 2), 48000); took = ((Main.elapsedTime - t0) * 1000).round(1);
check.("the reference tone at 48 kHz reads −17.0 LUFS", near.(m[\loudDb], -17, 0.3) and: { near.(m[\loudIntDb], -17, 0.3) },
	"loudest 400 ms " ++ m[\loudDb] ++ " · whole " ++ m[\loudIntDb] ++ " LUFS (2 s measured in " ++ took ++ " ms, the weights made in it)");
m44 = ~le.loudOf(tone.(44100, 2), 44100);
check.("the same tone at 44.1 kHz reads the same", near.(m44[\loudDb], -17, 0.3) and: { near.(m44[\loudIntDb], -17, 0.3) }, m44[\loudDb].asString ++ " · " ++ m44[\loudIntDb] ++ " LUFS");
mShort = ~le.loudOf(tone.(48000, 0.1), 48000);
check.("100 ms of it: 6 dB less in its loudest 400 ms, the same over its own length", near.(mShort[\loudDb], -23, 0.3) and: { near.(mShort[\loudIntDb], -17, 0.3) },
	mShort[\loudDb].asString ++ " · " ++ mShort[\loudIntDb] ++ " LUFS");
check.("a tone 10 dB lower reads 10 dB lower", near.(~le.loudOf(tone.(48000, 1, -30), 48000)[\loudDb], -27, 0.3), ~le.loudOf(tone.(48000, 1, -30), 48000)[\loudDb].asString ++ " LUFS");
check.("the weighting's shape: 100 Hz reads about 1.9 dB under 1 kHz, 4 kHz about 3.2 over",
	near.(~le.loudOf(tone.(48000, 1, -20, 100), 48000)[\loudIntDb], -18.87, 0.4) and: { near.(~le.loudOf(tone.(48000, 1, -20, 4000), 48000)[\loudIntDb], -13.76, 0.4) },
	"100 Hz " ++ ~le.loudOf(tone.(48000, 1, -20, 100), 48000)[\loudIntDb] ++ " · 4 kHz " ++ ~le.loudOf(tone.(48000, 1, -20, 4000), 48000)[\loudIntDb] ++ " LUFS");
check.("silence has no figure to speak of", ~le.loudOf(FloatArray.newClear(24000), 48000)[\loudDb] == -120, "−120");
long = tone.(48000, 7.5);
t0 = Main.elapsedTime; ~le.loudOf(long, 48000); took = ((Main.elapsedTime - t0) * 1000).round(1);
check.("a 7.5 s sample is measured without holding the language long", took < 1500, took.asString ++ " ms for 7.5 s of sound");
File.mkdir(tmp);
~le.wavWrite(tmp +/+ "tone.wav", tone.(48000, 1), 48000);
mFile = ~le.loudOfFile(tmp +/+ "tone.wav");
check.("the same from a FILE", mFile.notNil and: { near.(mFile[\loudDb], -17, 0.3) }, if(mFile.notNil) { mFile[\loudDb].asString ++ " LUFS" } { "no figure" });
if("LE_TEST_FILE".getenv.notNil) {
	extra = ~le.loudOfFile("LE_TEST_FILE".getenv);
	("  file " ++ "LE_TEST_FILE".getenv ++ " — " ++ if(extra.notNil) { "loudest 400 ms " ++ extra[\loudDb] ++ " · whole " ++ extra[\loudIntDb] ++ " LUFS" } { "could not be measured" }).postln;
};

"LEVEL_TEST the ladder (reference −29.54 LUFS = fff, 4 dB a step):".postln;
check.("the marks", near.(~le.markDb("fff"), -29.54, 0.001) and: { near.(~le.markDb("mf"), -41.54, 0.001) } and: { near.(~le.markDb(\ppp), -57.54, 0.001) } and: { ~le.markDb("loud").isNil },
	"fff " ++ ~le.markDb("fff") ++ " · mf " ++ ~le.markDb("mf") ++ " · ppp " ++ ~le.markDb("ppp") ++ " · a word that is no mark: " ++ ~le.markDb("loud"));
check.("the name nearest a loudness", (~le.playedMark(-41) == \mf) and: { ~le.playedMark(-10) == \fff } and: { ~le.playedMark(-90) == \ppp } and: { ~le.playedMark(-47) == \mp },
	"−41 → " ++ ~le.playedMark(-41) ++ " · −10 → " ++ ~le.playedMark(-10) ++ " · −90 → " ++ ~le.playedMark(-90) ++ " · −47 → " ++ ~le.playedMark(-47));
row = (name: "t", loudDb: -30, lengthMs: 600);
check.("as played = 0 dB", (~le.gainFor(row, "played")[\db] == 0) and: { ~le.gainFor(row, nil)[\db] == 0 }, "0 dB, said or not");
g = ~le.gainFor(row, "mark:mf");
check.("AT a mark: mf on a sample at −30 LUFS", near.(g[\db], -11.54, 0.001), g[\db].round(0.01).asString ++ " dB (−41.54 − −30)");
check.("relative: one step up, two down", near.(~le.gainFor(row, "rel:+1")[\db], 4, 0.001) and: { near.(~le.gainFor(row, "rel:-2")[\db], -8, 0.001) },
	"+1 → " ++ ~le.gainFor(row, "rel:+1")[\db] ++ " dB · −2 → " ++ ~le.gainFor(row, "rel:-2")[\db] ++ " dB");
check.("relative, held inside two marks", near.(~le.gainFor(row, "rel:+1:ceil:f")[\db], -7.54, 0.001) and: { near.(~le.gainFor(row, "rel:-6:floor:p")[\db], -19.54, 0.001) },
	"+1 under a ceiling of f → " ++ ~le.gainFor(row, "rel:+1:ceil:f")[\db].round(0.01) ++ " dB · −6 over a floor of p → " ++ ~le.gainFor(row, "rel:-6:floor:p")[\db].round(0.01) ++ " dB");
quiet = (name: "q", loudDb: -58, lengthMs: 400);
g = ~le.gainFor(quiet, "mark:fff");
check.("the lift is capped", near.(g[\db], 20, 0.001) and: { g[\note].contains("held") }, g[\db].asString ++ " dB · " ++ g[\note]);
faint = (name: "f", loudDb: -70, lengthMs: 400);
g = ~le.gainFor(faint, "mark:ff");
check.("a sample under the floor is not lifted — and may still be lowered", (g[\db] == 0) and: { near.(~le.gainFor((loudDb: -70), "rel:-1")[\db], -4, 0.001) }, g[\db].asString ++ " dB · " ++ g[\note]);
bare = (name: "b", lengthMs: 400);
g = ~le.gainFor(bare, "mark:ff");
check.("a row with no figure is played as captured, and it is said", (g[\db] == 0) and: { g[\note].contains("UNMEASURED") }, g[\note]);

"LEVEL_TEST the envelope:".postln;
lv = ~le.levelFor(row, (dyn: "mark:mf", env: "0:mf,1200:ff,1250:p"));
check.("a line of three points: the dB at each, the times between", near.(lv[\db][0], -11.54, 0.001) and: { near.(lv[\db][1], -3.54, 0.001) } and: { near.(lv[\db][2], -19.54, 0.001) }
	and: { near.(lv[\dt][0], 1.2, 0.0001) } and: { near.(lv[\dt][1], 0.05, 0.0001) } and: { lv[\db].size == 8 } and: { lv[\dt].size == 7 } and: { near.(lv[\db][7], -19.54, 0.001) },
	lv[\db].keep(3).collect(_.round(0.01)).asString ++ " dB at 0 · 1200 · 1250 ms; held at the last; " ++ lv[\note]);
lv = ~le.levelFor(row, (dyn: "mark:mp", env: "0:=,end:ff"));
check.("a hairpin over the sample's own length", near.(lv[\db][0], -15.54, 0.001) and: { near.(lv[\db][1], -3.54, 0.001) } and: { near.(lv[\dt][0], 0.6, 0.0001) },
	lv[\db].keep(2).collect(_.round(0.01)).asString ++ " dB over " ++ lv[\dt][0] ++ " s");
lv = ~le.levelFor(row, (env: "0:=,400:=,405:-2"));
check.("a step from as played, two steps down", (lv[\db][0] == 0) and: { lv[\db][1] == 0 } and: { near.(lv[\db][2], -8, 0.001) } and: { near.(lv[\dt][1], 0.005, 0.0001) },
	lv[\db].keep(3).asString ++ " dB · the step takes " ++ (lv[\dt][1] * 1000) ++ " ms");
lv = ~le.levelFor(row, (dyn: "played"));
check.("as played: a flat 0 dB, and the window says nothing of it", lv[\db].every({ |x| x == 0 }) and: { ~le.levelSaid(lv) == "" }, lv[\db].asString);
lv = ~le.levelFor(row, (dyn: "mark:ff"), -6);
check.("a pattern's own level rides on top", near.(lv[\db][0], -9.54, 0.001), lv[\db][0].round(0.01).asString ++ " dB (ff −3.54, the onset's −6)");

(dir +/+ "synths.scd").load;   // no server: the SynthDefs are BUILT, which is what is asked here
sd = SynthDescLib.global[\leSample];
check.("\\leSample is built to take it: eight levels, seven times, a curve", sd.notNil and: { sd.controlDict[\envDb].notNil } and: { sd.controlDict[\envDb].defaultValue.asArray.size == 8 }
	and: { sd.controlDict[\envDt].defaultValue.asArray.size == 7 } and: { sd.controlDict[\envCurve].notNil },
	if(sd.notNil) { sd.controlNames.asString } { "no such SynthDef" });
check.("every SynthDef of the engine is built", [\leIn, \lePass, \leEcho, \leMaster, \leMeter1, \leMeter2, \leLatency, \leOnset, \leCapture, \leSample].every({ |n| SynthDescLib.global[n].notNil }),
	[\leIn, \lePass, \leEcho, \leMaster, \leMeter1, \leMeter2, \leLatency, \leOnset, \leCapture, \leSample].reject({ |n| SynthDescLib.global[n].notNil }).asString ++ " missing");

"LEVEL_TEST the bus's dials:".postln;
ma = ().putPairs(~le.masterArgs);
check.("the engine's own bus is neutral: no filter, no glue, a ceiling", (ma[\hpfOn] == 0) and: { ma[\lpfOn] == 0 } and: { ma[\glueOn] == 0 } and: { ma[\ceilDb] == -1 }, ~le.masterSaid);
~le[\masterOpts] = (hpfHz: 30, lpfHz: 0, glueOn: 1, glueThr: -18, glueRatio: 2, glueKnee: 6, glueAtkMs: 30, glueRelMs: 250, ceilingDb: -1, lookaheadMs: 5, limRelMs: 100);
ma = ().putPairs(~le.masterArgs);
check.("a piece's dials become the master's arguments", (ma[\hpfOn] == 1) and: { ma[\hpfFreq] == 30 } and: { ma[\lpfOn] == 0 } and: { ma[\glueOn] == 1 } and: { (ma[\glueAtk] - 0.03).abs < 1e-9 } and: { (ma[\glueRel] - 0.25).abs < 1e-9 } and: { (ma[\limRel] - 0.1).abs < 1e-9 },
	~le.masterSaid);
~le.masterSet((glueOn: 0, lpfHz: 6000, nonsense: 3));
ma = ().putPairs(~le.masterArgs);
check.("a message moves them, and leaves out what the bus does not know", (ma[\glueOn] == 0) and: { ma[\lpfOn] == 1 } and: { ma[\lpfFreq] == 6000 } and: { ma[\hpfOn] == 1 } and: { ~le[\masterOpts][\nonsense].isNil }, ~le.masterSaid);
~le[\masterOpts] = nil;

"LEVEL_TEST what a session is started with (the environment a piece's tool hands over):".postln;
"LE_LEVEL".setenv("reference=-31,stepDb=4,liftCapDb=20,floorDb=-60,driveRef=-20,bleedDb=9");
"LE_MASTER".setenv("hpfHz=30,lpfHz=0,glueOn=1,glueThr=-18,glueRatio=2,glueKnee=6,glueAtkMs=30,glueRelMs=250,glueGainDb=0,ceilingDb=-1,lookaheadMs=5,limRelMs=100");
"LE_VENUE".setenv("name=hall;bcl:trimDb=-2.5:hpfHz=50:eq1=250/-3/1,bfl:trimDb=0:hpfHz=90,perc");
"LE_REFUSE_BLEED".setenv("1");
~le.takeSpecs;
ma = ().putPairs(~le.micArgs(\bcl));
check.("the ladder, the bus, the venue and the bleed's refusal are all taken", (~le.levelOf[\reference] == -31) and: { ~le.levelOf[\bleedDb] == 9 } and: { near.(~le.markDb("mf"), -43, 0.001) }
	and: { ~le.masterOf[\glueOn] == 1 } and: { ~le.masterOf[\hpfHz] == 30 }
	and: { ~le[\venueName] == "hall" } and: { (ma[\amp] - -2.5.dbamp).abs < 1e-6 } and: { ma[\hpfFreq] == 50 } and: { ma[\eq1Db] == -3 } and: { ~le.micArgs(\perc).size == 0 }
	and: { ~le[\refuseBleed] == true },
	"fff " ++ ~le.levelOf[\reference] ++ " LUFS · " ++ ~le.masterSaid ++ " · the house " ++ ~le.micSaid ++ " · a bled capture refused: " ++ ~le[\refuseBleed]);
["LE_LEVEL", "LE_MASTER", "LE_VENUE", "LE_REFUSE_BLEED"].do({ |k| k.unsetenv });
~le[\levelOpts] = nil; ~le[\masterOpts] = nil; ~le[\venue] = nil; ~le[\venueName] = nil; ~le[\refuseBleed] = false;

"LEVEL_TEST the files that boot a server:".postln;
bad = ["session.scd", "selftest.scd", "check_route.scd", "latency.scd", "devices.scd", "calibrate.scd"].select({ |n| File.exists(dir +/+ n) }).select({ |n|
	thisProcess.interpreter.compile(File.readAllString(dir +/+ n)).isNil
});
check.("they parse", bad.size == 0, if(bad.size == 0) { "session · selftest · check_route · latency · devices" ++ if(File.exists(dir +/+ "calibrate.scd")) { " · calibrate" } { "" } } { "DO NOT PARSE: " ++ bad.join(" · ") });

"LEVEL_TEST the index:".postln;
~le.bankOn(tmp);
~le[\indexRows] = List.new;
~le[\indexRows].add(~le.loudInto((id: "smp_1", name: "tone", player: "p", lane: 0, lengthMs: 1000.0, peakDb: -17.0, file: "tone.wav"), mFile));
check.("the index is written", ~le.indexWrite, tmp +/+ "index.json");
rows = ~le.indexRead;
check.("a row's figure comes back as a number, its name on the ladder with it", (rows.size == 1) and: { rows[0][\loudDb].isNumber } and: { near.(rows[0][\loudDb], mFile[\loudDb], 0.001) } and: { rows[0][\played].asString == "fff" },
	if(rows.size == 1) { "loudDb " ++ rows[0][\loudDb] ++ " · loudIntDb " ++ rows[0][\loudIntDb] ++ " · played " ++ rows[0][\played] } { "no row" });

if(~le[\bleedOf].notNil) {
	"LEVEL_TEST the guard:".postln;
	// a room at −40 dB and an attack 8 dB over it — bleed; the same room and an attack 30 dB over it — a capture
	f = { |attackDb, roomDb = -40| FloatArray.fill(24000, { |i| (1.0.rand2 * roomDb.dbamp) + if(i >= 9600) { sin(2pi * 220 * i / 48000) * attackDb.dbamp * exp((i - 9600) / 48000 / -0.08) } { 0 } }) };
	b = ~le.bleedOf(f.(-33), 48000);
	check.("an attack about 10 dB over the room is flagged", b[\bleed] == true, "the room " ++ b[\floorDb] ++ " dB · the attack " ++ b[\overDb] ++ " dB over it");
	b = ~le.bleedOf(f.(-8), 48000);
	check.("an attack 30 dB over the room is a capture", b[\bleed] == false, "the room " ++ b[\floorDb] ++ " dB · the attack " ++ b[\overDb] ++ " dB over it");
	b = ~le.bleedOf(FloatArray.fill(24000, { |i| if(i >= 9600) { sin(2pi * 220 * i / 48000) * 0.2 } { 0 } }), 48000);
	check.("a silent room (the simulation) never flags", b[\bleed] == false, "the room " ++ b[\floorDb] ++ " dB");
	// the crop in a room: without the room's level the murmur is taken for the attack; with it, the attack is found where it is
	g = f.(-8, -30);   // a louder room: 22 dB under the attack — over the crop's own threshold (30 under the peak)
	check.("the crop finds the attack OVER the room, not the room", (~le.cropFind(g, 48000)[\attack] < 480) and: { (~le.cropFind(g, 48000, (roomAmp: ~le.bleedOf(g, 48000)[\room]))[\attack] - 9600).abs < 200 },
		"told nothing of the room, the attack is put at " ++ (~le.cropFind(g, 48000)[\attack] / 48).round(0.1) ++ " ms · told of it, at " ++ (~le.cropFind(g, 48000, (roomAmp: ~le.bleedOf(g, 48000)[\room]))[\attack] / 48).round(0.1) ++ " ms (it is at 200)");
	check.("a window that holds only the room has nothing to crop", ~le.cropFind(FloatArray.fill(24000, { 1.0.rand2 * -40.dbamp }), 48000, (roomAmp: -40.dbamp)).isNil, "nil");
	// a venue's numbers become a microphone's arguments
	~le[\venue] = (bcl: (trimDb: "-6", hpfHz: "90", eq1: "250/-3/2"), bfl: ());
	ma = ().putPairs(~le.micArgs(\bcl));
	check.("a venue's numbers become a microphone's arguments", ((ma[\amp] - -6.dbamp).abs < 1e-6) and: { ma[\hpfOn] == 1 } and: { ma[\hpfFreq] == 90 } and: { ma[\eq1On] == 1 } and: { ma[\eq1Freq] == 250 } and: { ma[\eq1Db] == -3 } and: { (ma[\eq1Rq] - 0.5).abs < 1e-6 }
		and: { ~le.micArgs(\bfl).size == 0 } and: { ~le.micArgs(\nobody).size == 0 }, ~le.micSaid);
	~le[\venue] = nil;
};

[tmp +/+ "tone.wav", tmp +/+ "index.json"].do({ |p| if(File.exists(p)) { File.delete(p) } });
if(fails.size == 0) { "LEVEL_TEST PASS".postln; 0.exit } { ("LEVEL_TEST FAIL — " ++ fails.join(" · ")).postln; 1.exit };
)
