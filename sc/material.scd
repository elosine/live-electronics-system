// material.scd — THE MATERIAL: a long, mastered file from a piece's FUND, streamed from disk — a STRETCH of it (an offset into the file,
// a length), faded at both edges so nothing clicks, at a level that may follow a line (a crescendo drawn as a curve). The Switch~ piece's
// 1a.7 (its RUNNING_LOG §80 · §102 · §103), 2026-11-09. Loaded by boot.scd after sine.scd; its SynthDefs are made in synths.scd.
//
// WHY A FILE OF ITS OWN. The return (bank.scd · \leSample) plays a banked CAPTURE whole from a buffer in memory: a few seconds, mono,
// at its captured level. The fund's materials are minutes long, stereo, mastered, several at once — ten minutes of stereo float is
// 200 MB; the fund is hours. They are STREAMED (DiskIn from a cued buffer), never loaded; a brick plays its own stretch; the file is
// the ground truth and the score's save says which stretch, where, how loud.
//
// THE MESSAGES (le_material.js sends them; concert and simulation the same road):
//   /le/material      id · lane · t · dueMs · name · offsetMs · lengthMs · [fadeInMs · fadeOutMs] · [gainDb] · [level · levelCurve] · [pass]
//                     name: a row of the materials index (below) · offsetMs: where in the file the brick's sound begins · lengthMs: how
//                     much of it · the fades (30 ms when absent) · gainDb: a plain trim (0) · level: a mark of the ladder, or a line
//                     `ms:mark,…` with `end` for the last (as the sine's — up to 16 points; mf = the file as mastered, each step ±stepDb)
//   /le/materialstop  [id] — that brick lets go in 30 ms; no id: every material playing (the score stopped)
//
// THE INDEX (LE_MATERIALS, a JSON file the piece writes — tools/materials_index.js there):
//   { root: "<folder>", materials: [ { name, file (relative to root, or absolute), seconds, channels (1 | 2), sr, kind, note }, … ] }
//
//   ~le.materialsOn(path)      read the index; the files are NOT opened until a brick plays
//   ~le.materialPlay(d)        /le/material — cue the file at the offset, start the synth at its time (the master's look-ahead counted)
//   ~le.materialStop(d)        /le/materialstop
//   ~le.materialSpec(d)        the message as the synth's arguments (pure; material_test.scd proves it)
//   ~le.materialDefs           the two SynthDefs — \leMaterial1 (a mono file, dual mono out) · \leMaterial2 (a stereo file)
(
~le[\materialDefaults] = (fadeMs: 30, maxPoints: 16, cueFrames: 262144);

// ---- the synths --------------------------------------------------------------------------------------------------------
// DiskIn streams the cued buffer; the level is a line in decibels (16 points, the last held) × the edge fades (a sine's quarter) ×
// a let-go on gate 0 (30 ms); amp is the trim. The fades' middle is the length less both fades, never under a millisecond.
~le[\materialDefs] = { |self|
	if(self[\materialDefObjs].isNil) {
		self[\materialDefObjs] = [1, 2].collect({ |nCh|
			SynthDef(("leMaterial" ++ nCh).asSymbol, { |out = 0, buf = 0, amp = 1, dur = 10, fadeIn = 0.03, fadeOut = 0.03, gate = 1, rate = 1|
				var db = \envDb.ir(0 ! 16), dt = \envDt.ir(0.01 ! 15), cv = \envCurve.ir(0);
				var lvl = EnvGen.kr(Env(db, dt, cv)).dbamp;
				var fades = EnvGen.kr(Env([0, 1, 1, 0], [fadeIn.max(0.002), (dur - fadeIn - fadeOut).max(0.001), fadeOut.max(0.002)], \sin), doneAction: 2);
				var let = EnvGen.kr(Env.asr(0, 1, 0.03), gate, doneAction: 2);
				// VDiskIn at `rate` = the file's rate over the server's (the Switch~ piece's §111): the fund is 44.1 kHz, the engine runs at Reaper's
				// 48 kHz — DiskIn would play it 8.8 % fast and 147 cents sharp. rate 1 = the file's own rate (the test's case).
				var sig = VDiskIn.ar(nCh, buf, rate, 0) * amp * lvl * fades * let;
				Out.ar(out, if(nCh == 1) { [sig, sig] } { sig });
			})
		});
	};
	self[\materialDefObjs]
};

// ---- the index ---------------------------------------------------------------------------------------------------------
~le[\materialsOn] = { |self, path|
	var doc, root, rows = IdentityDictionary.new, n = 0;
	self[\materials] = rows;
	self[\materialNodes] = IdentityDictionary.new;
	if(path.notNil and: { File.exists(path.asString) }) {
		try { doc = path.asString.parseJSONFile } { doc = nil };
		if(doc.notNil and: { doc["materials"].notNil }) {
			root = (doc["root"] ? "").asString;
			doc["materials"].do({ |m|
				var file = (m["file"] ? "").asString, abs;
				abs = if((file.size > 1) and: { (file[1] == $:) or: { file[0] == $/ } }) { file } { root +/+ file };
				if(m["name"].notNil and: { file.size > 0 }) {
					rows[m["name"].asString.asSymbol] = (name: m["name"].asString, path: abs, seconds: (m["seconds"] ? 0).asFloat, channels: (m["channels"] ? 2).asInteger.clip(1, 2),
						sr: (m["sr"] ? 44100).asInteger, kind: (m["kind"] ? "").asString);
					n = n + 1;
				};
			});
			self.say("LE_INFO", "materials · " ++ n ++ " in the fund (" ++ path ++ ") — streamed from disk when a brick plays");
		} {
			self.say("LE_ERROR", "materials · the index could not be read: " ++ path);
		};
	} {
		if(path.notNil) { self.say("LE_ERROR", "materials · no such index: " ++ path) };
	};
	n
};

~le[\materialHear] = { |self|
	self.hear(\material, { |le, d| le.materialPlay(d) });
	self.hear(\materialstop, { |le, d| le.materialStop(d) });
	self
};

// ---- the level line: a mark of the ladder (or a number on it, mf = 4 = the file as mastered) -> decibels against the file ------
~le[\materialMarkDb] = { |self, text|
	var o = self.levelOf, t = (text ? "").asString.stripWhiteSpace, i = self[\levelMarks].indexOf(t.asSymbol), n;
	n = if(i.notNil) { i } { if(t.size > 0) { t.asFloat.clip(-10, 7) } { 4 } };
	(n - 4) * o[\stepDb]
};

~le[\materialPoints] = { |self, text, lenMs|
	var pts = List.new, maxP = self[\materialDefaults][\maxPoints];
	(text ? "").asString.stripWhiteSpace.split($,).do({ |x|
		var b = x.asString.stripWhiteSpace.split($:);
		case
		{ b.size >= 2 } { pts.add([if(b[0].asString.stripWhiteSpace == "end") { lenMs } { b[0].asString.asFloat.clip(0, lenMs) }, self.materialMarkDb(b[1])]) }
		{ (b.size == 1) and: { b[0].asString.size > 0 } } { pts.add([0, self.materialMarkDb(b[0])]) };
	});
	pts = pts.asArray.sort({ |p, q| p[0] < q[0] });
	if(pts.size == 0) { pts = [[0, 0]] };
	if(pts[0][0] > 0) { pts = [[0, pts[0][1]]] ++ pts };
	pts.keep(maxP)
};

~le[\materialLine] = { |self, pts|
	var maxP = self[\materialDefaults][\maxPoints], v = pts.collect({ |p| p[1] }), dt = Array.fill(pts.size - 1, { |i| ((pts[i + 1][0] - pts[i][0]) / 1000).max(0.005) });
	while { v.size < maxP } { v = v.add(v.last) };
	while { dt.size < (maxP - 1) } { dt = dt.add(0.01) };
	(v: v, dt: dt)
};

// the message as the synth's arguments (and what is said) — nothing of the server in it
~le[\materialSpec] = { |self, d, row|
	var o = self[\materialDefaults], total = if(row.notNil) { row[\seconds] } { 1e9 };
	var offS = ((d[\offsetMs] ? 0).asString.asFloat / 1000).clip(0, total.max(0)), lenS = ((d[\lengthMs] ? 1000).asString.asFloat / 1000).clip(0.05, 3600);
	var fin = ((d[\fadeInMs] ? o[\fadeMs]).asString.asFloat / 1000).clip(0.002, 30), fout = ((d[\fadeOutMs] ? o[\fadeMs]).asString.asFloat / 1000).clip(0.002, 30);
	var gainDb = (d[\gainDb] ? 0).asString.asFloat.clip(-60, 24), curve = (d[\levelCurve] ? 0).asString.asFloat.clip(-8, 8), pts, line;
	lenS = lenS.min((total - offS).max(0.05));   // never past the file's end
	pts = self.materialPoints(d[\level], lenS * 1000);
	line = self.materialLine(pts);
	(offS: offS, lenS: lenS, fadeIn: fin, fadeOut: fout, gainDb: gainDb, points: pts,
		args: [\amp, gainDb.dbamp, \dur, lenS, \fadeIn, fin, \fadeOut, fout, \envDb, line[\v], \envDt, line[\dt], \envCurve, curve],
		said: offS.round(0.01).asString ++ " s into it · " ++ lenS.round(0.01) ++ " s · fades " ++ (fin * 1000).round(1).asInteger ++ "/" ++ (fout * 1000).round(1).asInteger ++ " ms"
			++ if(gainDb != 0) { " · " ++ if(gainDb > 0) { "+" } { "" } ++ gainDb.round(0.1) ++ " dB" } { "" }
			++ if((pts.size > 1) or: { pts[0][1] != 0 }) { " · level " ++ pts.collect({ |p| (p[0] / 1000).round(0.1).asString ++ "s " ++ if(p[1] >= 0) { "+" } { "" } ++ p[1].round(0.1) }).join(" → ") ++ " dB" } { "" })
};

// ---- /le/material ------------------------------------------------------------------------------------------------------
~le[\materialPlay] = { |self, d|
	var s = self[\server], name = self.safeName(d[\name]), id = (d[\id] ? "").asString, row = if(self[\materials].notNil) { self[\materials][name.asSymbol] };
	var due = ((d[\dueMs] ? 0).asString.asFloat / 1000).clip(0, 5), la = (self[\masterDelay] ? 0), at = (due - la).max(0), t0 = SystemClock.seconds;
	var sp, buf, node, key, frame, def;
	case
	{ self[\materials].isNil or: { self[\materials].size == 0 } } { self.say("LE_INFO", "material · " ++ name ++ " — the engine was started with no materials index (LE_MATERIALS): nothing is played") }
	{ row.isNil } { self.say("LE_INFO", "material · " ++ name ++ " — not in the fund's index: nothing is played") }
	{ File.exists(row[\path]).not } { self.say("LE_ERROR", "material · " ++ name ++ " — its file is not there: " ++ row[\path]) }
	{ s.isNil } { self.say("LE_INFO", "material · " ++ name ++ " — no server") }
	{ true } {
		sp = self.materialSpec(d, row);
		if(sp[\offS] >= (row[\seconds] - 0.05)) {
			self.say("LE_INFO", "material · " ++ name ++ " — the offset " ++ sp[\offS].round(0.01) ++ " s is past the file's end (" ++ row[\seconds].round(0.01) ++ " s): nothing is played");
		} {
			frame = (sp[\offS] * row[\sr]).round.asInteger;
			def = ("leMaterial" ++ row[\channels]).asSymbol;
			key = (id ++ "·" ++ name ++ "·" ++ t0.round(0.001)).asSymbol;
			node = Synth.basicNew(def, s);
			// the file is cued at the offset (a quarter-million frames read ahead); the synth starts when the cue is IN, the lead less the time it took.
			// THE FIRST LIVE RUN (the Switch~ piece's §111, 2026-11-09): Buffer.cueSoundFile's completion FUNCTION is evaluated when the read
			// message is BUILT — before the read — so a synth started inside it streamed an empty buffer and was silent (the synth stood in the
			// tree, the return read −150). Now the read's own /done is waited for (an OSCFunc on this buffer's number), then the synth starts.
			buf = Buffer.alloc(s, self[\materialDefaults][\cueFrames], row[\channels], { |b| b.readMsg(row[\path], frame, self[\materialDefaults][\cueFrames], 0, true) });
			OSCFunc({ |msg|
				var wait = (at - (SystemClock.seconds - t0)).max(0);
				s.sendBundle(if(wait > 0.005) { wait }, node.newMsg(self[\grpFx], [\out, self[\busMaster].index, \buf, buf.bufnum, \rate, (row[\sr] / (self[\sr] ? s.sampleRate ? row[\sr]))] ++ sp[\args], \addToTail));
			}, '/done', s.addr, argTemplate: ['/b_read', buf.bufnum]).oneShot;
			node.onFree({ buf.close; buf.free; if(self[\materialNodes].notNil) { self[\materialNodes].removeAt(key) } });
			self[\materialNodes][key] = (node: node, buf: buf, id: id, name: name, until: t0 + at + sp[\lenS]);
			self.say("LE_INFO", "material · " ++ name ++ " · in " ++ (at * 1000).round(1).asInteger ++ " ms · " ++ sp[\said]);
			self.say("LE_RESULT", self.json((msg: "material", name: name, id: id, dueMs: (at * 1000).round(0.1), offsetMs: (sp[\offS] * 1000).round(0.1), lengthMs: (sp[\lenS] * 1000).round(0.1), channels: row[\channels])));
		};
	};
	self
};

// ---- /le/materialstop --------------------------------------------------------------------------------------------------
~le[\materialStop] = { |self, d|
	var id = if(d.notNil) { (d[\id] ? "").asString } { "" }, n = 0;
	if(self[\materialNodes].notNil) {
		self[\materialNodes].copy.keysValuesDo({ |k, m|
			if((id.size == 0) or: { m[\id] == id }) { m[\node].set(\gate, 0); n = n + 1 };
		});
	};
	if(n > 0) { self.say("LE_INFO", "material · " ++ n ++ if(n == 1) { " let go" } { " let go" } ++ if(id.size > 0) { " (" ++ id ++ ")" } { " — the score stopped" }) };
	n
};
)
