// calibrate.scd — THE SOUND CHECK'S CALIBRATION (the engine plan's part 13; the Decibel piece's PLAN 1.4 · 11.7 b, 2026-10-06).
//   node electronics/tools/sc.js run electronics/sc/calibrate.scd LE_PLAYERS=bcl:0,bfl:1 LE_MODE=live --timeout 300 --verbose
// Each player in turn plays ONE reference dynamic on cue; the engine listens for a few seconds THROUGH the venue's own input
// chain (its high-pass, its EQ, its trim as it stands), reads the loudest 400 ms on the players' scale (level.scd), and says
// the trim that would put that reading ON the ladder's mark — so that afterwards "as played" means what the player meant:
// a capture of their mf reads mf, and a return scored `as played` comes back at the electronics' mf.
//   LE_PLAYERS      name:channel pairs, as session.scd takes them — the order is the order of the cues
//   LE_MODE         sim (a piece's rack over ReaRoute) | live (LE_DEVICE) — as boot.scd
//   LE_LEVEL        the ladder (session.scd) — where the mark lies
//   LE_VENUE        the venue as it stands (session.scd): its chain is in the path, its trim is what the new one is counted from
//   LE_CAL_MARK     the dynamic asked of each player (mf)      LE_CAL_SECONDS  how long each is listened to (6)
//   LE_CAL_GAP      seconds of warning before each (3)
// One line a player:  LE_RESULT {"msg": "listen", …}  when the listening starts (a tool's cue — the simulation plays its note
// then), and  LE_RESULT {"msg": "calibrated", "player", "heard", "loudDb", "peakDb", "hadTrimDb", "trimDb", …}  after it.
// Nothing is written here: the tool that ran it writes the venue's file. It boots the engine's own server — a living engine
// must be closed first (tools/sc.js refuses beside one).
(
var dir = PathName(thisProcess.nowExecutingPath).pathOnly;
var mode = ("LE_MODE".getenv ? "sim").asSymbol;
var spec = ("LE_PLAYERS".getenv ? "p1:0");
var secs = ("LE_CAL_SECONDS".getenv ? "6").asFloat.clip(2, 30);
var gap = ("LE_CAL_GAP".getenv ? "3").asFloat.clip(1, 30);
var mark = ("LE_CAL_MARK".getenv ? "mf");
(dir +/+ "boot.scd").load;
~le.takeSpecs;
~le.bootEngine(mode, { |le|
	var s = le[\server], sr = s.sampleRate, target = le.markDb(mark) ? le.markDb("mf"), order = List.new;
	spec.split($,).do({ |pair|
		var b = pair.split($:), name = b[0].asSymbol;
		le.addPlayer(name, (b[1] ? "0").asInteger);
		order.add(name);
	});
	s.sync;
	le.say("LE_READY", le.json((device: le[\device], sr: sr, players: order.asArray.collect(_.asString), seconds: secs, mark: mark, targetLufs: target)));
	if(le[\venue].notNil) { le.say("LE_INFO", "the house · " ++ le.micSaid) };
	order.do({ |name|
		var p = le[\players][name], v = if(le[\venue].notNil) { le[\venue][name] }, had = if(v.notNil and: { v[\trimDb].notNil }) { v[\trimDb].asString.asFloat } { 0 };
		var buf, data, cond = Condition.new, m, peak;
		le.say("LE_INFO", "NEXT · " ++ name ++ " — one " ++ mark ++ ", in " ++ gap ++ " s");
		gap.wait;
		buf = Buffer.alloc(s, (secs * sr).asInteger, 1);
		s.sync;
		le.say("LE_RESULT", le.json((msg: "listen", player: name, seconds: secs)));
		le.say("LE_INFO", "NOW · " ++ name ++ " — play (" ++ secs ++ " s)");
		Synth(\leCapture, [\in, p[\bus].index, \buf, buf.bufnum], le[\grpFx], \addToTail);
		(secs + 0.3).wait;
		buf.loadToFloatArray(action: { |d| data = d; cond.test = true; cond.signal });
		cond.wait;
		buf.free;
		m = le.loudOf(data, sr);
		peak = if(data.size > 0) { data.abs.maxItem } { 0 };
		if(m.isNil or: { m[\loudDb] < -70 }) {
			le.say("LE_INFO", "nothing heard · " ++ name ++ " — its trim is left as it is (" ++ had ++ " dB)");
			le.say("LE_RESULT", le.json((msg: "calibrated", player: name, heard: false, hadTrimDb: had)));
		} {
			le.say("LE_INFO", "heard · " ++ name ++ " · " ++ m[\loudDb] ++ " LUFS (peak " ++ le.db(peak) ++ " dB) — " ++ mark ++ " is " ++ target.round(0.1)
				++ ": its trim " ++ had ++ " → " ++ (had + (target - m[\loudDb])).round(0.1) ++ " dB");
			le.say("LE_RESULT", le.json((msg: "calibrated", player: name, heard: true, loudDb: m[\loudDb], peakDb: le.db(peak), hadTrimDb: had,
				trimDb: (had + (target - m[\loudDb])).round(0.1), mark: mark, targetLufs: target.round(0.01))));
		};
	});
	le.say("LE_INFO", "the calibration is done");
	le.leave(0);
});
)
