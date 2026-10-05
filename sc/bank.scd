// bank.scd — THE BANK: a window of a player's sound CAPTURED, CROPPED to its attack, NAMED, INDEXED and PLAYED BACK
// (the engine plan's 4.3 · 4.3b · 4.4 · the index). Loaded by boot.scd; nothing here runs until a session calls bankOn.
//
//   ~le.bankOn(dir, cropOpts)   the bank's folder (made if it is not there, with raw/ inside it); the index read; every
//                               sample it lists loaded into a buffer. Answers how many. The folder comes from the piece
//                               at the engine's START (LE_BANK) — never from a message.
//   ~le.bankHear                the two message kinds, on the ear (boot.scd):
//
//   /le/open  player · lane · id · name · category · t · lengthMs · dueMs
//       THE MIC OPENING. The player's bus is recorded from NOW until the window's end — dueMs (how far ahead of the
//       window's own start the message left) + lengthMs. Early is right: the crop finds the attack. Then:
//         <bank>/raw/<id>.wav    the whole recording, kept for a re-crop
//         <bank>/<name>.wav      THE SAMPLE — cropped to the attack, mono, the engine's sample rate
//         <bank>/index.json      a row for it; a name taken twice REPLACES its row and its file — the latest take wins
//       and the sample is in a buffer, ready to be played.
//       THE MODES (§71, 2026-10-05): bankOn(dir, crop, source, record) — the buffers are FILLED at start from `source` (the bank itself,
//       or the BACKUP bank the players recorded in rehearsal); captures are WRITTEN to `dir`; with record = false an opening changes
//       nothing. THE SAFETY NET: a capture with no attack above the floor leaves the buffer as it was (the backup, or the earlier take)
//       and says so — the analysis that decides this must be made foolproof before the concert (the piece's NITS).
//   /le/play  name · id · lane · t · dueMs
//       THE RETURN. The sample is played to the master at UNITY, dueMs from now ON THE ENGINE'S CLOCK — it lands where
//       the score's brick is, with no clock shared between the score and the engine.
//
// THE CROP'S RULE (~le.cropFind — on the recording's samples, in the language, so the engine is whole without a score server):
//   the level is read in steps of one millisecond (the loudest sample of each);
//   THE ATTACK   the first sample above  attackDb (-30) under the recording's peak  AND above  floorDb (-50 dBFS) —
//                silence is not an attack — stepped back preMs (5) of pre-roll;
//   THE END      where the level falls under  endDb (-45) below the peak  and stays there holdMs (50), or the recording's end;
//   the fades    fadeInMs (2) · fadeOutMs (10).
//   Each is a DEFAULT, overridden by the piece (bankOn's cropOpts; a session's LE_CROP) — the composer's ear tunes them.
//   A recording whose peak is under floorDb has no attack in it: it is REPORTED, and nothing is saved under the name.
//
// THE INDEX'S SCHEMA is the engine's; the file is the piece's (docs/SEAMS.md):
//   { "schema": 1, "samples": [ { id · name · player · lane · category · scoreTime · lengthMs · peakDb · file · raw ·
//                                 openingId · windowMs · attackMs · captured } ] }
//   file · raw are relative to the bank's folder, with forward slashes. attackMs is where in the raw recording the attack
//   was found — how early the window opened before the sound.
//
// A NAME IS A FILE NAME: ~le.safeName keeps letters, digits, - and _ and drops the rest, so nothing a message carries
// can write outside the bank's folder.
(
~le[\cropDefaults] = (attackDb: -30, floorDb: -50, preMs: 5, endDb: -45, holdMs: 50, fadeInMs: 2, fadeOutMs: 10);

~le[\safeName] = { |self, name|
	(name ? "").asString.select({ |c| c.isAlphaNum or: { "-_".includes(c) } }).keep(64)
};

~le[\nowIso] = { |self|
	var t = Date.localtime, z = { |n| n.asInteger.asString.padLeft(2, "0") };
	t.year.asString ++ "-" ++ z.(t.month) ++ "-" ++ z.(t.day) ++ "T" ++ z.(t.hour) ++ ":" ++ z.(t.minute) ++ ":" ++ z.(t.second)
};

// a FloatArray as a mono 24-bit WAV, written by the language
~le[\wavWrite] = { |self, path, data, sr|
	var f = SoundFile.new.headerFormat_("WAV").sampleFormat_("int24").numChannels_(1).sampleRate_(sr.asInteger), ok;
	ok = f.openWrite(path);
	if(ok) { f.writeData(data); f.close };
	ok
};

// ---- the crop ---------------------------------------------------------------------------------------------------------
// where the attack and the end are, in samples: (start, end, attack, peak) — or nil when there is nothing to crop
~le[\cropFind] = { |self, data, sr, opts|
	var o = self[\cropDefaults].copy, hop, n, env, peak, thrOn, thrOff, a, at, start, end, hold, low, k, found;
	if(opts.notNil) { o.putAll(opts) };
	hop = (sr / 1000).round.asInteger.max(1);
	n = data.size div: hop;
	env = Array.fill(n, { |b| var m = 0.0, i0 = b * hop; hop.do({ |j| m = max(m, data[i0 + j].abs) }); m });
	peak = if(n > 0) { env.maxItem } { 0 };
	if(peak < o[\floorDb].dbamp) { nil } {
		thrOn = max(peak * o[\attackDb].dbamp, o[\floorDb].dbamp);
		a = env.detectIndex({ |v| v >= thrOn });
		at = a * hop;
		while { data[at].abs < thrOn } { at = at + 1 };   // the sample, inside that millisecond
		start = (at - (o[\preMs] * sr / 1000).round.asInteger).max(0);
		thrOff = peak * o[\endDb].dbamp;
		hold = o[\holdMs].asInteger.max(1);
		low = 0; k = a;
		while { found.isNil and: { k < n } } {
			if(env[k] < thrOff) { low = low + 1; if(low >= hold) { found = k - hold + 1 } } { low = 0 };
			k = k + 1;
		};
		end = if(found.notNil) { found * hop } { data.size };
		(start: start, end: end, attack: at, peak: peak)
	}
};

// the cropped samples themselves, faded in and out
~le[\cropTake] = { |self, data, sr, c, opts|
	var o = self[\cropDefaults].copy, out, n, nIn, nOut;
	if(opts.notNil) { o.putAll(opts) };
	out = data.copyRange(c[\start], c[\end] - 1);
	n = out.size;
	nIn = (o[\fadeInMs] * sr / 1000).round.asInteger.min(n div: 2);
	nOut = (o[\fadeOutMs] * sr / 1000).round.asInteger.min(n div: 2);
	nIn.do({ |i| out[i] = out[i] * (i / nIn) });
	nOut.do({ |i| out[n - 1 - i] = out[n - 1 - i] * (i / nOut) });
	out
};

// ---- the index --------------------------------------------------------------------------------------------------------
// (a JSON file read by the language comes back all strings: the numbers of the schema are made numbers again here)
~le[\indexRead] = { |self|
	var path = self[\bankDir] +/+ "index.json", doc, rows = List.new, numbers = [\scoreTime, \lengthMs, \peakDb, \windowMs, \attackMs];
	self[\indexBroken] = false;
	if(File.exists(path)) {
		try { doc = path.parseJSONFile } { doc = nil };
		if(doc.isNil or: { doc["samples"].isNil }) {
			self[\indexBroken] = true;
			self.say("LE_ERROR", "the bank's index could not be read and will NOT be written over: " ++ path);
		} {
			doc["samples"].do({ |d|
				var row = ();
				d.keysValuesDo({ |k, v|
					var key = k.asSymbol;
					row[key] = case { key == \lane } { v.asInteger } { numbers.includes(key) } { v.asFloat } { true } { v };
				});
				rows.add(row);
			});
		};
	};
	self[\indexRows] = rows;
	rows
};

// the rows of ANY folder's index, read without touching the write bank's state — the source the buffers are filled from (§71)
~le[\indexRowsOf] = { |self, dir|
	var path = dir.asString +/+ "index.json", doc, rows = List.new, numbers = [\scoreTime, \lengthMs, \peakDb, \windowMs, \attackMs];
	if(File.exists(path)) {
		try { doc = path.parseJSONFile } { doc = nil };
		if(doc.notNil and: { doc["samples"].notNil }) {
			doc["samples"].do({ |d|
				var row = ();
				d.keysValuesDo({ |k, v| var key = k.asSymbol; row[key] = case { key == \lane } { v.asInteger } { numbers.includes(key) } { v.asFloat } { true } { v } });
				rows.add(row);
			});
		};
	};
	rows
};

~le[\indexWrite] = { |self|
	var path = self[\bankDir] +/+ "index.json", f, ok = false;
	if(self[\indexBroken] != true) {
		f = File(path, "w");
		if(f.isOpen) {
			f.write("{\n \"schema\": 1,\n \"_what\": \"THE SAMPLE INDEX — a row per sample in this folder, written by the engine after each capture (electronics/sc/bank.scd). GENERATED: do not hand-edit while the engine is up.\",\n \"samples\": [\n  "
				++ self[\indexRows].collect({ |r| self.json(r) }).join(",\n  ") ++ "\n ]\n}\n");
			f.close;
			ok = true;
		};
	};
	ok
};

// ---- the bank ---------------------------------------------------------------------------------------------------------
~le[\bankOn] = { |self, dir, cropOpts, source, record|
	var s = self[\server];
	self[\bankDir] = dir.asString;                      // where captures are WRITTEN — files and index
	self[\sourceDir] = (source ? dir).asString;         // where the buffers are FILLED FROM at start — the bank itself, or the backup (§71)
	self[\record] = (record ? true);                    // false: an opening records nothing; the buffers keep what the files gave them
	File.mkdir(self[\bankDir]);
	File.mkdir(self[\bankDir] +/+ "raw");
	self[\cropOpts] = cropOpts;
	self[\samples] = IdentityDictionary.new;
	self.indexRead;                                      // the WRITE bank's rows — a capture's row joins them
	self.indexRowsOf(self[\sourceDir]).do({ |row|
		var p = self[\sourceDir] +/+ row[\file].asString;
		if(File.exists(p)) { self[\samples][row[\name].asSymbol] = (row: row, buf: Buffer.read(s, p), from: \loaded) };
	});
	self[\samples].size
};

~le[\bankHear] = { |self|
	self.hear(\open, { |le, d| le.captureOpen(d) });
	self.hear(\play, { |le, d| le.samplePlay(d) });
	self
};

// ---- the capture: /le/open --------------------------------------------------------------------------------------------
~le[\captureOpen] = { |self, d|
	var s = self[\server], sr = s.sampleRate, who = (d[\player] ? '?').asSymbol, p = self[\players][who];
	var name = self.safeName(d[\name]), id = self.safeName(d[\id]);
	var winMs = (d[\lengthMs] ? 500).asFloat.clip(20, 30000), lead = ((d[\dueMs] ? 0).asFloat / 1000).clip(0, 5);
	var total = lead + (winMs / 1000), buf;
	case
	{ self[\bankDir].isNil } { self.say("LE_INFO", "open · " ++ who ++ " — the engine was started with no bank folder: nothing is recorded") }
	{ p.isNil } { self.say("LE_INFO", "open · " ++ who ++ " — the engine has no such player: nothing is recorded") }
	{ name.size == 0 } { self.say("LE_INFO", "open · " ++ who ++ " — the opening has no name: nothing is recorded") }
	{ self[\record] == false } { self.say("LE_INFO", "open · " ++ who ++ " · " ++ name ++ " — recording is OFF: the buffer keeps what it holds" ++ if(self[\samples][name.asSymbol].notNil) { "" } { " (nothing yet)" }) }
	{ true } {
		if(id.size == 0) { id = name };
		self.say("LE_INFO", "open · " ++ who ++ " · " ++ name ++ " · " ++ winMs.round(1).asInteger ++ " ms");
		// the recorder starts in the same breath as the buffer is made: no round trip between the message and the recording
		buf = Buffer.alloc(s, (total * sr).ceil.asInteger, 1, { |b|
			Synth.basicNew(\leCapture, s).newMsg(self[\grpFx], [\in, p[\bus].index, \buf, b.bufnum], \addToTail)
		});
		SystemClock.sched(total + 0.25, {
			buf.loadToFloatArray(action: { |data|
				self.captureDone(d, who, name, id, winMs, data);
				buf.free;
			});
			nil
		});
	};
	self
};

~le[\captureDone] = { |self, d, who, name, id, winMs, data|
	var s = self[\server], sr = s.sampleRate, dir = self[\bankDir], rawRel = "raw/" ++ id ++ ".wav", rel = name ++ ".wav";
	var rawMs = (data.size / sr * 1000).round(1).asInteger, rawPeak = if(data.size > 0) { data.abs.maxItem } { 0 };
	var c, out, row, old, lenMs, atMs;
	self.wavWrite(dir +/+ rawRel, data, sr);
	self.say("LE_INFO", "captured · " ++ name ++ " · raw · " ++ rawMs ++ " ms · peak " ++ self.db(rawPeak) ++ " dB");
	c = self.cropFind(data, sr, self[\cropOpts]);
	if(c.isNil) {
		old = self[\samples][name.asSymbol];
		self.say("LE_INFO", "nothing to crop · " ++ name ++ " — no attack in the window; the sample was not saved"
			++ if(old.notNil) { " · THE BUFFER KEEPS ITS " ++ if(old[\from] == \loaded) { "LOADED" } { "EARLIER" } ++ " TAKE (the safety net, §71)" } { " · the buffer is empty" });
		self.say("LE_RESULT", self.json((msg: "captured", name: name, player: who, openingId: id, cropped: false,
			rawMs: rawMs, rawPeakDb: self.db(rawPeak), raw: rawRel, kept: old.notNil)));
	} {
		out = self.cropTake(data, sr, c, self[\cropOpts]);
		self.wavWrite(dir +/+ rel, out, sr);
		// §74 (2026-10-05): a sample file was once written with NO ROW (bfl-impulse-1, 08:29:23) and the window said nothing — whatever throws
		// between the file and the index now says so, in the window and in the result the page gets.
		try {
			lenMs = (out.size / sr * 1000).round(0.1);
			atMs = (c[\attack] / sr * 1000).round(0.1);
			old = self[\samples][name.asSymbol];
			row = (id: "smp_" ++ self.nowIso.select(_.isDecDigit), name: name, player: who.asString, lane: (d[\lane] ? -1).asInteger,
				category: (d[\category] ? "").asString, scoreTime: (d[\t] ? 0).asFloat.round(0.001), lengthMs: lenMs,
				peakDb: self.db(c[\peak]), file: rel, raw: rawRel, openingId: id, windowMs: winMs, attackMs: atMs, captured: self.nowIso);
			self[\indexRows] = self[\indexRows].reject({ |r| r[\name].asString == name });
			self[\indexRows].add(row);
			if(self.indexWrite.not) { self.say("LE_INFO", "the index was NOT written — the sample is saved as " ++ rel) };
			Buffer.read(s, dir +/+ rel, action: { |b|
				self[\samples][name.asSymbol] = (row: row, buf: b, from: \captured);
				if(old.notNil) { SystemClock.sched(10, { old[\buf].free; nil }) };
			});
			self.say("LE_INFO", "cropped · " ++ name ++ " · " ++ lenMs.round(1).asInteger ++ " ms of " ++ rawMs
				++ " · the attack at " ++ atMs.round(1).asInteger ++ " ms · peak " ++ self.db(c[\peak]) ++ " dB"
				++ if(old.notNil) { " · REPLACES the earlier take" } { "" });
			self.say("LE_RESULT", self.json(row.copy.putAll((msg: "captured", cropped: true, rawMs: rawMs, replaced: old.notNil))));
		} { |err|
			self.say("LE_ERROR", "the row of " ++ name ++ " was NOT made — the sample is saved as " ++ rel ++ " · " ++ err.errorString);
			self.say("LE_RESULT", self.json((msg: "captured", name: name, player: who, openingId: id, cropped: true, rowError: err.errorString, file: rel, raw: rawRel)));
		};
	};
	self
};

// ---- the return: /le/play ---------------------------------------------------------------------------------------------
~le[\samplePlay] = { |self, d|
	var s = self[\server], name = self.safeName(d[\name]), due = ((d[\dueMs] ? 0).asFloat / 1000).clip(0, 5);
	var smp = if(self[\samples].notNil) { self[\samples][name.asSymbol] };
	if(smp.isNil) {
		self.say("LE_INFO", "play · " ++ name ++ " — no such sample in the bank");
	} {
		s.makeBundle(if(due > 0.005) { due }, {
			Synth(\leSample, [\out, self[\busMaster].index, \buf, smp[\buf].bufnum], self[\grpFx], \addToTail);
		});
		self.say("LE_INFO", "play · " ++ name ++ " · in " ++ (due * 1000).round(1).asInteger ++ " ms · "
			++ smp[\row][\lengthMs].round(1).asInteger ++ " ms long");
		self.say("LE_RESULT", self.json((msg: "play", name: name, id: (d[\id] ? "").asString, dueMs: (due * 1000).round(0.1),
			lengthMs: smp[\row][\lengthMs], peakDb: smp[\row][\peakDb])));
	};
	self
};
)
