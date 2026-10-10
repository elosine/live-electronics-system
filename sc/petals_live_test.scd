// petals_live_test.scd — THE PETALS LIVE, OFFLINE (the Decibel piece's PLAN 10.14, 2026-10-07): petals_live.scd's rule in a bare
// sclang, and \lePetalsLive played by a second scsynth with no device and no port (NRT) into files, the files measured. No server
// of the engine's is asked anything: a living engine beside it is untouched, and nothing sounds.
//   THE RULE      a plan of five variants: the petals at its own opening is LIVE; the same petals three seconds later, a comb, a
//                 petals stacked with a pedal, a petals under an envelope are NOT · not in the mode \remote, not with `on` 0 ·
//                 a new plan queues the render it lacks, made AS LIVE (the source entering where the note stood in the window) ·
//                 /le/open answers the served variant with its gains — estimated before that render, exact after; a sample
//                 that reads under ppp is not trusted ·
//                 /le/play sets the level by the ladder and plays no buffer; another name is not touched
//   THE SYNTH     made with no level, it is silent (the engine gives it the as-played level with its making) · it RINGS five seconds and more · the window: a second sound AFTER it closes
//                 changes nothing, to the sample · THE CORRESPONDENCE: the same sound through the offline render of the same
//                 variant reads within 1 dB of the live one, and is as long within a tenth · written at a mark, it reads the mark
//                 · it ends, and is silent after
//   The dials are the Decibel piece's first hit (pp01: 42.3 Hz · first partial 1.41 · spread 0.55 · bank B +2.49 st · ring 8.7 … 11.6 s).
//   The sound is a made-up burst — or, with LE_TEST_SRC=<a mono wav>, a banked impulse of a piece: proven on the piece's own numbers.
//   "C:/Program Files/SuperCollider-3.14.1/sclang.exe" electronics/sc/petals_live_test.scd        (under `timeout`: it forks)
// It ends PETALS_LIVE_TEST PASS (exit 0) or PETALS_LIVE_TEST FAIL (exit 1) and names each check.
(
var dir = thisProcess.nowExecutingPath.dirname;
var tmp = Platform.defaultTempDir +/+ "le_petals_live_test_" ++ Date.localtime.stamp;
var own = "LE_TEST_SRC".getenv, sr = 48000, fails = List.new, check, near, db, render, pk, slice, span, read, rowOf, waitFor, src, sf, n;
var dials = "poMix:1,poFund:42.3,poFirst:1.41,poSpread:0.55,poOffset:2.49,poRingLo:8.7,poRingHi:11.6,poInLen:1";
var even = "poMix:1,poFund:42.3,poFirst:1.41,poSpread:0.55,poOffset:2.49,poRingLo:9,poRingHi:9,poInLen:1";   // ring lo = hi: no dice on the server — a render repeats itself
var plan;
(dir +/+ "boot.scd").load;
// the sound: a piece's impulse when one is named, else 5 ms of silence and a 300 ms burst — 330 Hz and its octave, falling fast
if(own.notNil and: { own.size > 0 } and: { File.exists(own) }) {
	sf = SoundFile.new;
	if(sf.openRead(own)) { sr = sf.sampleRate.asInteger; src = FloatArray.newClear(sf.numFrames); sf.readData(src); sf.close };
};
if(src.isNil) {
	own = nil;
	n = (0.305 * sr).asInteger;
	src = FloatArray.fill(n, { |i|
		var t = (i / sr) - 0.005;
		if(t < 0) { 0 } { (sin(2pi * 330 * t) + (0.5 * sin(2pi * 660 * t))) * exp(t * -12) * 0.17 }
	});
};
~le[\sr] = sr;
(dir +/+ "synths.scd").load;   // no server: the SynthDefs are built — \lePetalsLive among them — and kept in the library
~le.bankOn(tmp);                // a scratch bank: no server, the index empty
~le[\mode] = \sim;
~le[\players] = (bcl: (bus: (index: 20)), bfl: (bus: (index: 21)), va: (bus: (index: 22)), vc: (bus: (index: 23)));
~le.wavWrite(tmp +/+ "bcl-petal-1.wav", src, sr);
~le.petalsLiveDef.writeDefFile(tmp);
SynthDef(\leTestFeed, { |buf = 0, out = 0| Out.ar(out, PlayBuf.ar(1, buf, BufRateScale.kr(buf), doneAction: 2)) }).writeDefFile(tmp);
check = { |what, ok, detail| ("  " ++ if(ok) { "ok   " } { "FAIL " } ++ what ++ " — " ++ detail).postln; if(ok.not) { fails.add(what) } };
near = { |a, b, tol| a.notNil and: { b.notNil } and: { (a - b).abs <= tol } };
db = { |x| if(x > 0) { x.ampdb.round(0.01) } { -200 } };
rowOf = { |name| ~le[\indexRows].detect({ |r| r[\name].asString == name }) };
waitFor = { |name, secs = 60, test|
	var t = 0, r;
	while { r = rowOf.(name); (r.isNil or: { test.notNil and: { test.(r).not } }) and: { t < secs } } { 0.25.wait; t = t + 0.25 };
	r
};
read = { |path|
	var f = SoundFile.new, data, frames, ch;
	if(File.exists(path) and: { f.openRead(path) }) { ch = f.numChannels; data = FloatArray.newClear(f.numFrames * ch); f.readData(data); frames = f.numFrames; f.close };
	if(data.isNil) { nil } { ch.collect({ |c| FloatArray.fill(frames, { |i| data[(i * ch) + c] }) }) }
};
// the live synth in NRT: `feeds` are the times a copy of the sound is played onto the microphone's bus; `sets` are [time, [name, value …]]
render = { |name, args, feeds, sets, dur|
	var osc = tmp +/+ name ++ ".osc", wav = tmp +/+ name ++ ".wav", done = false, opts, msgs;
	opts = ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(2).numAudioBusChannels_(64).memSize_(131072).numWireBufs_(256);
	// in time order: the defs and the buffer, the synth, then the feeds and the sets as their times fall (a set AT the synth's own time follows it)
	msgs = [
		[0.0, ['/d_load', tmp +/+ "lePetalsLive.scsyndef"]],
		[0.0, ['/d_load', tmp +/+ "leTestFeed.scsyndef"]],
		[0.0, ['/b_allocRead', 0, tmp +/+ "bcl-petal-1.wav", 0, 0]],
		[0.05, ['/s_new', \lePetalsLive, 1001, 1, 0, \in, 20, \out, 0] ++ args.asOSCArgArray]
	] ++ (feeds.collect({ |t, i| [0.05 + t, ['/s_new', \leTestFeed, 1100 + i, 0, 0, \buf, 0, \out, 20]] })
		++ sets.collect({ |x| [0.05 + x[0], ['/n_set', 1001] ++ x[1].asOSCArgArray] })).sort({ |a, b| a[0] < b[0] })
		++ [[dur, ['/c_set', 0, 0]]];
	Score(msgs).recordNRT(osc, wav, nil, sr, "WAV", "float", opts, "", nil, { done = true });
	while { done.not } { 0.05.wait };
	read.(wav)
};
pk = { |x, from, to| var a = (from * sr).asInteger, b = ((to * sr).asInteger - 1).min(x.size - 1), m = 0; (a..b).do({ |i| m = max(m, x[i].abs) }); m };
// from the first sample within 60 dB of the peak to the last: [start s, end s, peak]
span = { |x|
	var p = x.abs.maxItem, thr = p * 0.001, a = x.detectIndex({ |v| v.abs >= thr }), b = x.size - 1;
	if(p <= 0) { [0, 0, 0] } { while { (b > a) and: { x[b].abs < thr } } { b = b - 1 }; [a / sr, b / sr, p] }
};
plan = { |extra = ""|
	~le.planTake((stamp: "t" ++ 100000.rand, part: 1, of: 1, render: 0, rows: [
		"bcl-petal-1;pp01-tail;petalsOrig;tail;0;1.75;1;155.228;16000;" ++ dials ++ ";normalized",
		"bcl-petal-1;x2-tail;comb;tail;0;1;1;155.228;4000;combMix:1,combTime:0.012,combFb:0.8;normalized",
		"va-petal-3;pp03-tail;petalsOrig;tail;0;1.75;1;164.5;16000;" ++ dials ++ ";normalized",
		"vc-petal-4;pg04-tail;petalsOrig;tail;0;1.75;1;162.317;16000;" ++ dials ++ ",odMix:0.6,odDrive:8;normalized",
		"bfl-petal-2;pp02-perc;petalsOrig;perc;3;1.75;1;158.185;0;" ++ dials ++ ";normalized"
	].join("|")));
};
fork {
	var v = "bcl-petal-1~pp01-tail", openD = (player: 'bcl', name: 'bcl-petal-1', t: 155.128, lengthMs: 500, dueMs: 91);
	var sv, est, ref, r, lv, want, kind, wait = 0.091, win = 0.5, pre, args, live, quiet, a, b, late, diff, off, sOff, sLive, lLive, lOff, mark, lMark, end;
	("PETALS_LIVE_TEST the scratch folder: " ++ tmp ++ " · the sound: " ++ if(own.notNil) { own } { "a made-up burst" } ++ " · " ++ sr ++ " Hz").postln;

	"PETALS_LIVE_TEST the rule:".postln;
	plan.value;
	kind = ~le.liveKind(~le[\plan].detect({ |x| x[\suffix] == "pp01-tail" }));
	check.("a petals under its tail is a live kind, with its own dials; the mix is kept apart",
		kind.notNil and: { kind[\mix] == 1 } and: { kind[\args].includes(\poFund) } and: { kind[\args].includes(\poMix).not } and: { kind[\args][kind[\args].indexOf(\poFund) + 1] == 42.3 },
		if(kind.notNil) { kind[\args].asString ++ " · mix " ++ kind[\mix] } { "nil" });
	check.("a comb · a petals stacked with a pedal · a petals under an envelope are NOT",
		~le[\plan].select({ |x| ["x2-tail", "pg04-tail", "pp02-perc"].any({ |s| s == x[\suffix] }) }).every({ |x| ~le.liveKind(x).isNil }) and: { ~le[\plan].size == 5 },
		~le[\plan].collect({ |x| x[\suffix] ++ ":" ++ ~le.liveKind(x).notNil }).join(" · "));
	sv = ~le.liveOpen(openD);
	est = if(sv.notNil) { sv[\ref] };
	check.("/le/open at the petals' own opening: SERVED LIVE — the variant, the window, the player's bus",
		sv.notNil and: { sv[\variant] == v } and: { near.(sv[\wait], 0.091, 1e-6) } and: { near.(sv[\win], 0.5, 1e-6) } and: { near.(sv[\cap], 16, 1e-6) } and: { sv[\player] == \bcl },
		if(sv.notNil) { sv[\variant] ++ " · opens in " ++ (sv[\wait] * 1000) ++ " ms for " ++ (sv[\win] * 1000) ++ " ms · the cap " ++ sv[\cap] ++ " s" } { "not served" });
	check.("with no render of the variant yet its level is an ESTIMATE, and says so", est.notNil and: { est[\exact] == false },
		if(est.notNil) { "driven " ++ est[\inDb].round(0.1) ++ " dB · " ++ est[\outDb].round(0.1) ++ " dB after it" } { "nil" });
	check.("the same petals three seconds after its opening · the stack · the envelope: NOT served — the offline road",
		~le.liveOpen((player: 'va', name: 'va-petal-3', t: 161.278, lengthMs: 500, dueMs: 90)).isNil
			and: { ~le.liveOpen((player: 'vc', name: 'vc-petal-4', t: 162.217, lengthMs: 500, dueMs: 90)).isNil }
			and: { ~le.liveOpen((player: 'bfl', name: 'bfl-petal-2', t: 158.085, lengthMs: 500, dueMs: 90)).isNil },
		"va-petal-3 (used at 164.5 s, opened at 161.278) · vc-petal-4 (odMix in its dials) · bfl-petal-2 (ended by perc)");
	~le[\mode] = \remote; a = ~le.liveOpen(openD); ~le[\mode] = \sim;
	~le[\liveOpts] = (on: 0); b = ~le.liveOpen(openD); ~le[\liveOpts] = nil;
	check.("not in the mode \\remote (no microphones) · not with `on` 0", a.isNil and: { b.isNil }, "remote: " ++ a.isNil ++ " · on 0: " ++ b.isNil);
	check.("a /le/play for a name that is not served is not touched", ~le.livePlay((name: "bcl-petal-1~x2-tail", dueMs: 90), "bcl-petal-1~x2-tail", 0.09) == false, "livePlay answers false: the buffer's road");

	"PETALS_LIVE_TEST a new plan renders what it lacks, AS LIVE:".postln;
	// the sample's row as a capture writes it: the window opened at 155.128 s; the recording began 91 ms before; the attack 215 ms into it
	~le[\indexRows].add((name: "bcl-petal-1", player: "bcl", lane: 1, scoreTime: 155.128, windowMs: 500, attackMs: 215, leadMs: 91,
		lengthMs: (src.size / sr * 1000).round(0.1), peakDb: ~le.db(src.abs.maxItem), file: "bcl-petal-1.wav").putAll(~le.loudOf(src, sr)));
	pre = ~le.liveRowPre(~le[\plan].detect({ |x| x[\suffix] == "pp01-tail" }));
	check.("where the note stood in its window: attackMs − leadMs − the crop's pre-roll", near.(pre, 215 - 91 - 5, 0.01), pre.asString ++ " ms (215 − 91 − 5 = 119)");
	plan.value;   // … and the plan again: it finds the sample, and no render made as live
	r = waitFor.(v, 60, { |x| x[\preMs].notNil });
	check.("the variant is rendered by the plan's own road, the source entering 119 ms in; its row carries the three numbers",
		r.notNil and: { near.(r[\preMs], 119, 0.01) } and: { r[\driveDb].notNil } and: { r[\outGainDb].notNil } and: { r[\planned] == 1 },
		if(r.notNil) { "preMs " ++ r[\preMs] ++ " · driveDb " ++ r[\driveDb] ++ " · outGainDb " ++ r[\outGainDb] ++ " · " ++ r[\lengthMs] ++ " ms · loud " ++ r[\loudDb] ++ " LUFS" } { "no row in 60 s" });
	if(r.notNil) {
		a = ~le.livePlanCheck;
		check.("a plan that lacks nothing queues nothing", a == 0, a.asString ++ " queued");
		// the Decibel piece's §369: with its reference in hand a new capture renders nothing — until the preset or the hit's level moves
		a = ~le[\plan].detect({ |x| x[\suffix] == "pp01-tail" });
		b = rowOf.("bcl-petal-1"); want = b[\loudDb];
		est = [~le.liveHasRef(a), ~le.liveHasRef(a.copy.put(\args, a[\args].asString.replace("poFund:", "poFund:1"))),
			{ b[\loudDb] = want - 6; ~le.liveHasRef(a) }.value, { b[\loudDb] = want; ~le.liveHasRef(~le[\plan].detect({ |x| x[\suffix] == "x2-tail" })) }.value];
		check.("its level reference IN HAND: a new take renders nothing — but a changed dial, a hit 6 dB softer, a variant not served live do",
			est == [true, false, false, false], "in hand " ++ est[0] ++ " · a changed dial " ++ est[1] ++ " · 6 dB softer " ++ est[2] ++ " · the comb " ++ est[3]);
		sv = ~le.liveOpen(openD);
		ref = sv[\ref];
		check.("/le/open again: the level is EXACT now — the render's own drive before the bank, its own level after",
			(ref[\exact] == true) and: { near.(ref[\inDb], r[\driveDb], 1e-6) } and: { near.(ref[\outDb], r[\outGainDb], 1e-6) },
			"driven " ++ ref[\inDb] ++ " dB · " ++ ref[\outDb] ++ " dB after");
		a = ~le.livePlay((name: v, id: "zn-459", dyn: "mark:fff", dueMs: 95), v, 0.095);
		lv = sv[\level];
		want = r[\outGainDb] + ~le.liftCap(r[\loudDb], ~le.markDb(\fff) - r[\loudDb]);
		check.("/le/play for the served variant: its level is the render's own gain and the mark's, by the ladder — and it answers that it played",
			(a == true) and: { lv.notNil } and: { near.(lv[\db][0], want, 0.01) },
			if(lv.notNil) { lv[\db][0].round(0.01).asString ++ " dB (the render's " ++ r[\outGainDb] ++ " + fff against " ++ r[\loudDb] ++ " LUFS = " ++ want.round(0.01) ++ ")" } { "no level" });
		// a WEAK sample (it reads under ppp — a capture that caught next to nothing) is not trusted, whatever its render says
		b = rowOf.("bcl-petal-1"); a = b[\loudDb]; b[\loudDb] = ~le.markDb(\ppp) - 10;
		est = ~le.liveRef(v, "bcl-petal-1"); b[\loudDb] = a;
		check.("a sample that reads under ppp is NOT TRUSTED: the level is estimated from mf, not from its render's gains",
			(est[\exact] == false) and: { est[\weak] == true } and: { near.(est[\inDb], ~le.levelOf[\driveRef] - ~le.markDb(\mf), 1e-6) },
			"driven " ++ est[\inDb].round(0.1) ++ " dB (driveRef − mf), not the render's " ++ r[\driveDb]);
		~le.samplePlay((name: v, id: "zn-459", dyn: "mark:fff", dueMs: 95));   // the whole road, with no server: it must not reach for a buffer
		check.("samplePlay takes that road — no buffer is looked for", true, "it returned (a buffer's road has no server here to play on)");

		"PETALS_LIVE_TEST the synth, as sound:".postln;
		args = { |text, inDb| [\wait, wait, \win, win, \cap, 16, \inAmp, inDb.dbamp, \mix, 1] ++ ~le.liveKind((effect: "petalsOrig", end: "tail", args: text))[\args] };
		pre = 0.119;
		// the level set as /le/play sets it, at the note
		lv = ~le.levelFor(r, (dyn: "played"), r[\outGainDb]);
		live = render.("live", args.(dials, r[\driveDb]), [wait + pre], [[wait + pre - 0.005, [\on, 1] ++ ~le.levelArgs(lv) ++ [\t_go, 1]]], 14.5);
		quiet = render.("quiet", args.(dials, r[\driveDb]), [wait + pre], [], 3);
		check.("made with no level it is silent — the engine sets the as-played level with the making, the mark at /le/play (§238)", quiet.notNil and: { quiet[0].abs.maxItem == 0 },
			if(quiet.notNil) { "the loudest sample of 3 s: " ++ quiet[0].abs.maxItem } { "no file" });
		if(live.notNil) {
			sLive = span.(live[0]);
			check.("it RINGS: within 60 dB of its peak five seconds and more after the note", (sLive[1] - sLive[0]) >= 5 and: { live[0] == live[1] },
				"from " ++ sLive[0].round(0.001) ++ " s to " ++ sLive[1].round(0.001) ++ " s — " ++ (sLive[1] - sLive[0]).round(0.01) ++ " s · peak " ++ db.(sLive[2]) ++ " dB · both channels the same samples");
			// THE CORRESPONDENCE: the offline render of the same variant, made as live, is the bank's file
			off = read.(tmp +/+ v ++ ".wav");
			lLive = ~le.loudOf(live[0], sr)[\loudDb];
			lOff = r[\loudDb];
			sOff = if(off.notNil) { span.(off[0]) } { [0, 0, 0] };
			check.("THE CORRESPONDENCE — the same sound through the offline render of the same variant: the loudness within 1 dB",
				near.(lLive, lOff, 1.0), "live " ++ lLive ++ " LUFS · offline " ++ lOff ++ " LUFS · peaks " ++ db.(sLive[2]) ++ " / " ++ db.(sOff[2]) ++ " dB");
			check.("… and as long, within a tenth", ((sLive[1] - sLive[0]) / (sOff[1] - sOff[0]).max(0.001) - 1).abs <= 0.1,
				"live " ++ (sLive[1] - sLive[0]).round(0.01) ++ " s · offline " ++ (sOff[1] - sOff[0]).round(0.01) ++ " s");
			end = pk.(live[0], 13.4, 14.4);
			check.("it ends by itself, and is silent after", end == 0, "the last second of 14.4: the loudest sample " ++ end);
		} { check.("the live render was made", false, "no file") };
		// written at a mark: it reads the mark
		mark = \f;
		lv = ~le.levelFor(r, (dyn: "mark:" ++ mark), r[\outGainDb]);
		a = render.("mark", args.(dials, r[\driveDb]), [wait + pre], [[wait + pre - 0.005, [\on, 1] ++ ~le.levelArgs(lv) ++ [\t_go, 1]]], 14.5);
		lMark = if(a.notNil) { ~le.loudOf(a[0], sr)[\loudDb] };
		check.("written f, it READS f — by the measure the bank's samples are read with", near.(lMark, ~le.markDb(mark), 1.0),
			lMark.asString ++ " LUFS (f = " ++ ~le.markDb(mark).round(0.01) ++ ") · the gain " ++ lv[\db][0].round(0.01) ++ " dB");
		// the window: a second sound 200 ms after it closes changes nothing — to the sample (ring lo = hi: no dice)
		lv = ~le.levelFor(r, (dyn: "played"), 0);
		a = render.("win1", args.(even, r[\driveDb]), [wait + pre], [[0, [\on, 1] ++ ~le.levelArgs(lv) ++ [\t_go, 1]]], 4);
		b = render.("win2", args.(even, r[\driveDb]), [wait + pre, wait + win + 0.2], [[0, [\on, 1] ++ ~le.levelArgs(lv) ++ [\t_go, 1]]], 4);
		late = render.("win3", args.(even, r[\driveDb]), [wait + win + 0.2], [[0, [\on, 1] ++ ~le.levelArgs(lv) ++ [\t_go, 1]]], 4);
		diff = if(a.notNil and: { b.notNil }) { (a[0] - b[0]).abs.maxItem } { 1 };
		check.("THE WINDOW: a second sound after it has closed changes nothing, to the sample; alone, it excites nothing",
			(diff == 0) and: { a[0].abs.maxItem > 0 } and: { late.notNil } and: { late[0].abs.maxItem == 0 },
			"with and without the late sound: the largest difference " ++ diff ++ " · the late sound alone: the loudest sample " ++ if(late.notNil) { late[0].abs.maxItem } { "?" });
	};
	if(fails.size == 0) { try { File.deleteAll(tmp) }; "PETALS_LIVE_TEST PASS".postln; 0.exit } { ("PETALS_LIVE_TEST FAIL — " ++ fails.join(" · ")).postln; 1.exit };
};
)
