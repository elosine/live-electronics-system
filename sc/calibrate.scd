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
//   LE_CAL_SINE     ANOTHER MEASURE, instead of the trims (2026-10-08, track.scd): THE SINE'S BLEED — name:midi pairs; with no one
//                   playing, the room in each player's band at that pitch, then the sine alone at fff in it (below)
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
var sineSpec = "LE_CAL_SINE".getenv;   // THE SINE'S BLEED instead of the trims:  bcl:63,bfl:76,perc:102.17 — each player's name and the pitch (MIDI, cents in it) of its sines
var trackSpec = "LE_TRACK".getenv;
(dir +/+ "boot.scd").load;
~le.takeSpecs;
if(trackSpec.notNil and: { trackSpec.size > 0 }) { ~le[\trackOpts] = (); trackSpec.split($,).do({ |kv| var b = kv.split($=); if(b.size == 2) { ~le[\trackOpts][b[0].asSymbol] = b[1].asFloat } }) };
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
	// THE SINE'S BLEED (track.scd; the Decibel piece's PLAN 1.8 · 16.1 e, 2026-10-08): with NO ONE PLAYING, for each player named in
	// LE_CAL_SINE — the loudest its microphone stands in the band at its sine's pitch for two seconds (the room in that band), then
	// the sine alone at fff through the master for three, the loudest the same band stands (the bleed). One line a player:
	//   LE_RESULT {"msg": "bleed", "player", "midi", "roomBandDb", "sineBleedDb"}
	// The tracker's threshold for that microphone is then its own room + the gate, and a microphone that hears the sine too well
	// follows nothing (track.scd trackThr · trackGuard). The trims are not touched in this run.
	if(sineSpec.notNil and: { sineSpec.size > 0 }) {
		sineSpec.split($,).do({ |pair|
			var b = pair.split($:), name = b[0].asSymbol, midi = (b[1] ? "57").asFloat.clip(0, 135), p = le[\players][name], o = le.trackOf, cb, probe, room, bleed, sp;
			if(p.notNil) {
				cb = Bus.control(s, 1);
				le.say("LE_INFO", "NEXT · " ++ name ++ " — NO ONE PLAYS: the room in its band at " ++ le.sineNote(midi) ++ " (2 s), then the sine alone (3 s)");
				probe = Synth(\leTrackProbe, [\in, p[\bus].index, \freq, midi.midicps, \rq, o[\rq], \cb, cb.index], le[\grpFx], \addToTail);
				2.0.wait;
				cb.get({ |v| room = v }); s.sync; 0.05.wait;
				probe.set(\t_reset, 1);
				sp = le.sineSpec((midi: midi, lengthMs: 3000, level: "fff"));
				Synth(\leSine, [\out, le[\busMaster].index] ++ le.sineArgs(sp), le[\grpFx], \addToTail);
				3.2.wait;
				cb.get({ |v| bleed = v }); s.sync; 0.05.wait;
				probe.free; cb.free;
				room = (room ? -120).round(0.1); bleed = (bleed ? -120).round(0.1);
				le.say("LE_INFO", "heard · " ++ name ++ " · the room in its band " ++ room ++ " dB · the sine in it " ++ bleed ++ " dB (" ++ (bleed - room).round(0.1) ++ " over)");
				le.say("LE_RESULT", le.json((msg: "bleed", player: name, midi: midi, roomBandDb: room, sineBleedDb: bleed)));
			};
		});
		order = List.new;   // the trims are another run
	};
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
