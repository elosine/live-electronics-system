// icylab.scd — ICY LIVE: his freeze on a LOADED SAMPLE, in real time, every knob live (the Switch~ piece's lab, 2026-11-07 —
// switch_2026 RUNNING_LOG §46 … §48; the engine's own log carries the mechanism). Loaded by boot.scd after process.scd; it
// makes no sound until a message asks.
//
// TWO VOICES, switchable, on the same sample:
//   \leIcyWarp   HIS \icy (github.com/elosine/freeze, freeze.scd) per channel: two Warp1 over the L and R buffers, ONE read head
//                (as his \icy_s ran two buffers). His argument names: envbuf · pitchshift · winsz · overlaps · rand · startpos ·
//                endpos · resettrig; `rate` is the read head's speed as a FRACTION of real time (his \rate control mapped between
//                ratemin and ratemax — here given directly: 1/30 = thirty times slower).
//   \leIcyGrain  the same read head, the grains made by GrainBuf — so that each grain may have its OWN length (rand, leaned by
//                skew), its own start near the head (scatter), its own window (an assorted set) and its own place (a pan per
//                grain). Static duration = rand 0. The source's own field is kept at panspread 0 (the L buffer's grains sit at
//                -width, the R buffer's at +width); panspread throws each grain further out. A grain's pan is a POSITION, so a
//                quad (his wish: VBAP) replaces the two-channel pan without touching the knobs.
// Both scale the sum by 1/sqrt(overlaps) (the engine's rule for the icy stage: K overlapping windows sum to K × their mean).
//
//   /le/icy  do list                           the samples loaded, the windows, the voice playing
//   /le/icy  do load  dir <folder>             every .wav / .aif in the folder into L and R buffers (a mono file into both)
//   /le/icy  do start sample <name> [voice warp|grain] [knobs …]
//   /le/icy  do set   [voice …] knob value …   on the playing synth — any argument above; also  slower N  (= rate 1/N) ·
//                                              envbuf <name|hann> · envset A|B|none (grain: A = expodec · gauss · hanning, B = all ten)
//   /le/icy  do stop
//   Every answer is one LE_RESULT line  { msg: "icy", … }.
//
// WHERE IT PLAYS: into busMaster in grpFx — through the engine's bus and out (ReaRoute → the rack's ELEC RETURN; the PA live).
(
~le[\icyLab] = ~le[\icyLab] ? (samples: IdentityDictionary.new, envs: nil, envNames: nil, synth: nil, voice: \grain, sample: nil, dir: nil);

~le[\icyLabDefs] = { |self|
	SynthDef(\leIcyWarp, { |out = 0, bufL = 0, bufR = 0, envbuf = -1, pitchshift = 1, winsz = 0.8, overlaps = 40, resettrig = 0,
		startpos = 0, endpos = 1, rand = 0.1, rate = 0.0333, amp = 1, gate = 1|
		var env, ix, l, r;
		env = EnvGen.kr(Env.asr(0.02, 1, 0.15), gate, doneAction: 2);
		ix = Phasor.kr(resettrig, ((1.0 / ControlRate.ir) / (BufFrames.kr(bufL) / SampleRate.ir)) * rate, startpos, endpos);
		l = Warp1.ar(1, bufL, ix, pitchshift, winsz, envbuf, overlaps, rand);
		r = Warp1.ar(1, bufR, ix, pitchshift, winsz, envbuf, overlaps, rand);
		Out.ar(out, [l, r] * (env * amp * overlaps.max(1).sqrt.reciprocal));
	}).add;

	SynthDef(\leIcyGrain, { |out = 0, bufL = 0, bufR = 0, pitchshift = 1, winsz = 0.6, overlaps = 17, resettrig = 0,
		startpos = 0, endpos = 1, rand = 0.2, skew = 0, scatter = 0, rate = 0.0333, panspread = 0, width = 1, envn = 1, amp = 1, gate = 1|
		var envbufs = \envbufs.kr(Array.fill(10, -1));
		var env, bufDur, ix, dens, trig, q, dur, pos, eb, pan, l, r;
		env = EnvGen.kr(Env.asr(0.02, 1, 0.15), gate, doneAction: 2);
		bufDur = BufDur.kr(bufL);
		ix = Phasor.kr(resettrig, ((1.0 / ControlRate.ir) / bufDur) * rate, startpos, endpos);
		dens = overlaps / winsz.max(0.01);                                   // a new grain every winsz / overlaps seconds
		trig = Impulse.ar(dens);
		q = TRand.ar(0, 1, trig);
		q = q ** (2 ** (skew.clip(-1, 1) * -2));                              // the weighting: skew -1 leans short, +1 leans long
		dur = winsz * (1 + ((2 * q - 1) * rand.clip(0, 1)));                 // rand 0 = every grain winsz long (the static branch)
		pos = (ix + (TRand.ar(scatter.neg, scatter, trig) / bufDur)).wrap(0, 1);   // scatter: seconds of the source, either side of the head
		eb = Select.ar(TIRand.ar(0, (envn - 1).max(0), trig), K2A.ar(envbufs));    // one window per grain, drawn from the set
		pan = TRand.ar(panspread.neg, panspread, trig);
		l = GrainBuf.ar(2, trig, dur, bufL, pitchshift, pos, 2, (pan - width).clip(-1, 1), eb, 512);
		r = GrainBuf.ar(2, trig, dur, bufR, pitchshift, pos, 2, (pan + width).clip(-1, 1), eb, 512);
		Out.ar(out, (l + r) * (env * amp * overlaps.max(1).sqrt.reciprocal));
	}).add;
	self
};

// his ten grain windows (sc/grainEnv/gEnv_*.aif) into buffers, once; by name in file order
~le[\icyLabEnvs] = { |self|
	var lab = self[\icyLab], s = self[\server];
	if(lab[\envs].isNil) {
		var paths = (self[\dir] +/+ "grainEnv" +/+ "gEnv_*.aif").pathMatch.sort;
		lab[\envNames] = paths.collect({ |p| PathName(p).fileNameWithoutExtension.copyToEnd(5) });
		lab[\envs] = paths.collect({ |p| Buffer.read(s, p) });
		s.sync;
	};
	lab
};

~le[\icyLabEnvBuf] = { |self, name|
	var lab = self.icyLabEnvs, i;
	name = name.asString;
	if((name == "hann") or: { name == "" } or: { name == "-1" }) { -1 } {
		i = lab[\envNames].indexOf(name);
		if(i.isNil) { i = lab[\envNames].detectIndex({ |n| n.toLower == name.toLower }) };
		if(i.isNil) { -1 } { lab[\envs][i].bufnum }
	}
};

~le[\icyLabEnvSet] = { |self, set|
	var lab = self.icyLabEnvs, names;
	names = switch(set.asString.toUpper,
		"A", { ["expodec", "gauss", "hanning"] },
		"B", { lab[\envNames] },
		{ nil });
	if(names.isNil) { nil } { names.collect({ |n| self.icyLabEnvBuf(n) }) }
};

// the samples: every .wav / .aif in a folder, L and R into two buffers (a mono file into both); named by the file
~le[\icyLabLoad] = { |self, dir|
	var lab = self[\icyLab], s = self[\server], n = 0;
	dir = dir.asString;
	lab[\dir] = dir;
	(dir +/+ "*").pathMatch.select({ |p| ["wav", "aif", "aiff", "flac"].any({ |x| x == PathName(p).extension.toLower }) }).sort.do({ |p|   // by content (never includes: identity)
		var name = PathName(p).fileNameWithoutExtension.asSymbol, chans = 1, dur = 0;
		SoundFile.use(p, { |f| chans = f.numChannels; dur = f.duration });
		lab[\samples][name] = (
			path: p, dur: dur, chans: chans,
			bufL: Buffer.readChannel(s, p, channels: [0]),
			bufR: Buffer.readChannel(s, p, channels: [if(chans > 1) { 1 } { 0 }]));
		n = n + 1;
	});
	s.sync;
	self.icyLabEnvs;
	n
};

// a knob from a message: his names, plus the conveniences
~le[\icyLabArgs] = { |self, d|
	var args = List.new, lab = self[\icyLab];
	var num = { |v| v.asString.asFloat };
	[\pitchshift, \winsz, \overlaps, \rand, \startpos, \endpos, \resettrig, \rate, \amp, \skew, \scatter, \panspread, \width].do({ |k|
		if(d[k].notNil) { args.addAll([k, num.(d[k])]) };
	});
	if(d[\slower].notNil) { args.addAll([\rate, 1.0 / num.(d[\slower]).max(0.001)]) };
	if(d[\envbuf].notNil) { args.addAll([\envbuf, self.icyLabEnvBuf(d[\envbuf])]) };
	args.asArray
};

~le[\icyLabEnvSetApply] = { |self, synth, d|
	var set, one;
	if(d[\envset].notNil) {
		set = self.icyLabEnvSet(d[\envset]);
		if(set.notNil) {
			synth.setn(\envbufs, set.extend(10, -1)); synth.set(\envn, set.size);
		} {
			one = self.icyLabEnvBuf(d[\envbuf] ? "expodec");
			synth.setn(\envbufs, [one].extend(10, -1)); synth.set(\envn, 1);
		};
	} {
		if(d[\envbuf].notNil) { synth.setn(\envbufs, [self.icyLabEnvBuf(d[\envbuf])].extend(10, -1)); synth.set(\envn, 1) };
	};
};

~le[\icyLabDo] = { |self, d|
	var lab = self[\icyLab], what = (d[\do] ? "list").asString, s = self[\server], smp, def, args, said;
	case
	{ what == "load" } {
		var n = self.icyLabLoad(d[\dir] ? lab[\dir] ? "");
		self.say("LE_RESULT", self.json((msg: "icy", did: "load", dir: lab[\dir], samples: lab[\samples].keys.asArray.collect(_.asString).sort, n: n)));
	}
	{ what == "list" } {
		self.say("LE_RESULT", self.json((msg: "icy", did: "list", dir: lab[\dir] ? "", samples: lab[\samples].keys.asArray.collect(_.asString).sort,
			windows: (self.icyLabEnvs[\envNames] ? []), playing: lab[\sample].notNil, voice: lab[\voice].asString, sample: (lab[\sample] ? "").asString)));
	}
	{ what == "stop" } {
		if(lab[\synth].notNil) { lab[\synth].set(\gate, 0); lab[\synth] = nil };
		lab[\sample] = nil;
		self.say("LE_RESULT", self.json((msg: "icy", did: "stop")));
	}
	{ what == "start" } {
		if(d[\voice].notNil) { lab[\voice] = d[\voice].asSymbol };
		smp = lab[\samples][(d[\sample] ? lab[\sample] ? "").asSymbol];
		if(smp.isNil) {
			self.say("LE_ERROR", "icy — no sample named " ++ (d[\sample] ? "") ++ " is loaded (do load dir <folder> first)");
		} {
			if(lab[\synth].notNil) { lab[\synth].set(\gate, 0) };
			def = if(lab[\voice] == \warp) { \leIcyWarp } { \leIcyGrain };
			args = [\out, self[\busMaster].index, \bufL, smp[\bufL].bufnum, \bufR, smp[\bufR].bufnum] ++ self.icyLabArgs(d);
			lab[\synth] = Synth(def, args, self[\grpFx]);
			if(def == \leIcyGrain) { self.icyLabEnvSetApply(lab[\synth], d) };
			lab[\sample] = (d[\sample] ? lab[\sample]).asSymbol;
			self.say("LE_RESULT", self.json((msg: "icy", did: "start", sample: lab[\sample].asString, voice: lab[\voice].asString,
				dur: smp[\dur], node: lab[\synth].nodeID, args: args[6..].collect(_.asString).join(" "))));
		};
	}
	{ what == "set" } {
		if(lab[\synth].isNil) {
			self.say("LE_ERROR", "icy — nothing is playing to set");
		} {
			if(d[\voice].notNil and: { d[\voice].asSymbol != lab[\voice] }) {
				d[\do] = "start"; self.icyLabDo(d);   // a change of voice is a new synth on the same sample
			} {
				args = self.icyLabArgs(d);
				if(args.size > 0) { lab[\synth].set(*args) };
				if(lab[\voice] == \grain) { self.icyLabEnvSetApply(lab[\synth], d) };
				self.say("LE_RESULT", self.json((msg: "icy", did: "set", args: args.collect(_.asString).join(" "))));
			};
		};
	}
	{ true } { self.say("LE_ERROR", "icy — do list · load · start · set · stop (not " ++ what ++ ")") };
	self
};

~le[\icyLabHear] = { |self|
	self.hear(\icy, { |le, d| le.icyLabDo(d) });
	self
};
)
