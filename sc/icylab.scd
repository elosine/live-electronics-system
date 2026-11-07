// icylab.scd — ICY LIVE: his freeze on a LOADED SAMPLE, in real time, every knob live (the Switch~ piece's lab, 2026-11-07 —
// switch_2026 RUNNING_LOG §46 … §48; the engine's own log carries the mechanism). Loaded by boot.scd after process.scd; it
// makes no sound until a message asks.
//
// TWO VOICES, switchable, on the same sample:
//   \leIcyWarp   HIS \icy (github.com/elosine/freeze, freeze.scd) per channel: two Warp1 over the L and R buffers, ONE read head
//                (as his \icy_s ran two buffers). His argument names: grainEnvelope · pitch · grainLength · overlaps · lengthVary · readFrom ·
//                readTo · rewind; `slowerBy` is the read head's speed as a FACTOR (his \rate control mapped between ratemin and
//                ratemax — here the factor itself: 30 = thirty times slower).
//   \leIcyGrain  the same read head, the grains made by GrainBuf (the legible names are his, 2026-11-07: grainLength · overlaps · grainEnvelope · lengthVary · lengthLean · scatter · envelopeSet · slowerBy · pitch · readFrom · readTo · rewind · panSpread · stereoWidth · level) — so that each grain may have its OWN length (lengthVary, leaned by
//                lengthLean), its own start near the head (scatter), its own window (an assorted set) and its own place (a pan per
//                grain). Static duration = lengthVary 0. The source's own field is kept at panSpread 0 (the L buffer's grains sit at
//                -stereoWidth, the R buffer's at +stereoWidth); panSpread throws each grain further out. A grain's pan is a POSITION, so a
//                quad (his wish: VBAP) replaces the two-channel pan without touching the knobs.
// Both scale the sum by 1/sqrt(overlaps) (the engine's rule for the icy stage: K overlapping windows sum to K × their mean).
//
//   /le/icy  do list                           the samples loaded, the windows, the voice playing
//   /le/icy  do load  dir <folder>             every .wav / .aif in the folder into L and R buffers (a mono file into both)
//   /le/icy  do start sample <name> [voice warp|grain] [knobs …]
//   /le/icy  do set   [voice …] knob value …   on the playing synth — any argument above; slowerBy N = the head N times slower ·
//                                              grainEnvelope <name|hann> · envelopeSet A|B|none (grain: A = expodec · gauss · hanning, B = all ten)
//   /le/icy  do stop
//   Every answer is one LE_RESULT line  { msg: "icy", … }.
//
// WHERE IT PLAYS: into busMaster in grpFx — through the engine's bus and out (ReaRoute → the rack's ELEC RETURN; the PA live).
(
~le[\icyLab] = ~le[\icyLab] ? (samples: IdentityDictionary.new, envs: nil, envNames: nil, synth: nil, voice: \grain, sample: nil, dir: nil);

~le[\icyLabDefs] = { |self|
	if(self[\icyStretchDefs].notNil) { self.icyStretchDefs };
	SynthDef(\leIcyWarp, { |out = 0, bufL = 0, bufR = 0, grainEnvelope = -1, pitch = 1, grainLength = 0.8, overlaps = 40, rewind = 0,
		readFrom = 0, readTo = 1, lengthVary = 0.1, slowerBy = 30, level = 1, gate = 1|
		var env, ix, l, r;
		env = EnvGen.kr(Env.asr(0.02, 1, 0.15), gate, doneAction: 2);
		ix = Phasor.kr(rewind, ((1.0 / ControlRate.ir) / (BufFrames.kr(bufL) / SampleRate.ir)) / slowerBy.max(0.001), readFrom, readTo);
		l = Warp1.ar(1, bufL, ix, pitch, grainLength, grainEnvelope, overlaps, lengthVary);
		r = Warp1.ar(1, bufR, ix, pitch, grainLength, grainEnvelope, overlaps, lengthVary);
		Out.ar(out, [l, r] * (env * level * overlaps.max(1).sqrt.reciprocal));
	}).add;

	SynthDef(\leIcyGrain, { |out = 0, bufL = 0, bufR = 0, pitch = 1, grainLength = 0.6, overlaps = 17, rewind = 0,
		readFrom = 0, readTo = 1, lengthVary = 0.2, lengthLean = 0, scatter = 0, slowerBy = 30, panSpread = 0, stereoWidth = 1, envn = 1, level = 1, gate = 1|
		var envbufs = \envbufs.kr(Array.fill(10, -1));
		var env, bufDur, ix, dens, trig, q, dur, pos, eb, pan, l, r;
		env = EnvGen.kr(Env.asr(0.02, 1, 0.15), gate, doneAction: 2);
		bufDur = BufDur.kr(bufL);
		ix = Phasor.kr(rewind, ((1.0 / ControlRate.ir) / bufDur) / slowerBy.max(0.001), readFrom, readTo);
		dens = overlaps / grainLength.max(0.01);                                   // a new grain every grainLength / overlaps seconds
		trig = Impulse.ar(dens);
		q = TRand.ar(0, 1, trig);
		q = q ** (2 ** (lengthLean.clip(-1, 1) * -2));                              // the weighting: lengthLean -1 leans short, +1 leans long
		dur = grainLength * (1 + ((2 * q - 1) * lengthVary.clip(0, 1)));                 // lengthVary 0 = every grain grainLength long (the static branch)
		pos = (ix + (TRand.ar(scatter.neg, scatter, trig) / bufDur)).wrap(0, 1);   // scatter: seconds of the source, either side of the head
		eb = Select.ar(TIRand.ar(0, (envn - 1).max(0), trig), K2A.ar(envbufs));    // one window per grain, drawn from the set
		pan = TRand.ar(panSpread.neg, panSpread, trig);
		l = GrainBuf.ar(2, trig, dur, bufL, pitch, pos, 2, (pan - stereoWidth).clip(-1, 1), eb, 512);
		r = GrainBuf.ar(2, trig, dur, bufR, pitch, pos, 2, (pan + stereoWidth).clip(-1, 1), eb, 512);
		Out.ar(out, (l + r) * (env * level * overlaps.max(1).sqrt.reciprocal));
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
	[\pitch, \grainLength, \overlaps, \lengthVary, \lengthLean, \scatter, \slowerBy, \readFrom, \readTo, \rewind, \panSpread, \stereoWidth, \level].do({ |k|
		if(d[k].notNil) { args.addAll([k, num.(d[k])]) };
	});
	if(d[\grainEnvelope].notNil) { args.addAll([\grainEnvelope, self.icyLabEnvBuf(d[\grainEnvelope])]) };
	args.asArray
};

~le[\icyLabEnvSetApply] = { |self, synth, d|
	var set, one;
	if(d[\envelopeSet].notNil) {
		set = self.icyLabEnvSet(d[\envelopeSet]);
		if(set.notNil) {
			synth.setn(\envbufs, set.extend(10, -1)); synth.set(\envn, set.size);
		} {
			one = self.icyLabEnvBuf(d[\grainEnvelope] ? "expodec");
			synth.setn(\envbufs, [one].extend(10, -1)); synth.set(\envn, 1);
		};
	} {
		if(d[\grainEnvelope].notNil) { synth.setn(\envbufs, [self.icyLabEnvBuf(d[\grainEnvelope])].extend(10, -1)); synth.set(\envn, 1) };
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
			if(lab[\voice] == \stretch) { self.icyStretchStart((d[\sample] ? lab[\sample]).asSymbol, d) } {
			if(lab[\synth].notNil) { lab[\synth].set(\gate, 0) };
			def = if(lab[\voice] == \warp) { \leIcyWarp } { \leIcyGrain };
			args = [\out, self[\busMaster].index, \bufL, smp[\bufL].bufnum, \bufR, smp[\bufR].bufnum] ++ self.icyLabArgs(d);
			lab[\synth] = Synth(def, args, self[\grpFx]);
			if(def == \leIcyGrain) { self.icyLabEnvSetApply(lab[\synth], d) };
			lab[\sample] = (d[\sample] ? lab[\sample]).asSymbol;
			self.say("LE_RESULT", self.json((msg: "icy", did: "start", sample: lab[\sample].asString, voice: lab[\voice].asString,
				dur: smp[\dur], node: lab[\synth].nodeID, args: args[6..].collect(_.asString).join(" "))));
			};
		};
	}
	{ what == "set" } {
		if(lab[\synth].isNil) {
			self.say("LE_ERROR", "icy — nothing is playing to set");
		} {
			if(d[\voice].notNil and: { d[\voice].asSymbol != lab[\voice] }) {
				d[\do] = "start"; self.icyLabDo(d);   // a change of voice is a new synth on the same sample
			} {
			if((lab[\voice] == \stretch) and: { d[\windowSeconds].notNil } and: { self.icyStretchSize(d[\windowSeconds]) != self.icyStretchSize(lab[\windowSeconds]) }) {
				d[\do] = "start"; self.icyLabDo(d);   // another window size: new frames, a new synth
			} {
				args = self.icyLabArgs(d);
				if(args.size > 0) { lab[\synth].set(*args) };
				if(lab[\voice] == \grain) { self.icyLabEnvSetApply(lab[\synth], d) };
				self.say("LE_RESULT", self.json((msg: "icy", did: "set", args: args.collect(_.asString).join(" "))));
			};
			};
		};
	}
	{ true } { self.say("LE_ERROR", "icy — do list · load · start · set · stop (not " ++ what ++ ")") };
	self
};


// ---- THE STRETCH VOICE — PaulStretch in the engine (2026-11-07; the Switch~ piece's §55, the engine's §73) ---------------
//   \leIcyStretch   the sample's SPECTRAL FRAMES (PV_RecordBuf — analysed once per window size, on demand, in real time: a
//                   one-second sample takes a second) played at 1/slowerBy (PV_PlayBuf, fractional frames interpolated) with
//                   FRESH RANDOM PHASES every frame (PV_Diffuser, its trigger held high) through a Hann IFFT: the magnitudes
//                   kept, the phases thrown away — so no two frames are copies of one waveform: nothing beats, nothing pulses,
//                   the timbre sits still and moves only as the window moves. Two chains for stereo. Its knobs, by design:
//                   windowSeconds · slowerBy · readFrom · level. windowSeconds -> the nearest analysed size:
//                   0.37 · 0.74 · 1.49 · 2.97 s at 44.1 kHz (16384 … 131072 samples). Level: ×2, measured against the grain voice (the test's F).
~le[\icyStretchSizes] = [16384, 32768, 65536, 131072];
~le[\icyStretchHop] = 0.125;   // an eighth: eight windows overlap, the swell between frames eight times finer than the window

~le[\icyStretchDefs] = { |self|
	SynthDef(\leIcyStretch, { |out = 0, fftL = 0, fftR = 0, recL = 0, recR = 0, slowerBy = 30, readFrom = 0, nFrames = 1, level = 1, gate = 1|
		var env = EnvGen.kr(Env.asr(0.05, 1, 0.3), gate, doneAction: 2);
		var rate = 1 / slowerBy.max(0.001), off = readFrom.clip(0, 0.999) * nFrames;
		var l = IFFT(PV_Diffuser(PV_PlayBuf(fftL, recL, rate, off, 1), 1), 0);
		var r = IFFT(PV_Diffuser(PV_PlayBuf(fftR, recR, rate, off, 1), 1), 0);
		Out.ar(out, [l, r] * (env * level * 5));   // measured 12 dB under the grain voice at x0.5, 8 under at x2 (icylab_test F); x5 brings it level
	}).add;
	// the analysis: the sample played once through an FFT into its record buffer; the synth ends with the sample
	SynthDef(\leIcyAnalyse, { |buf = 0, fft = 0, rec = 0, hop = 0.25, out = 0|
		var sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf), doneAction: 2);
		var chain = PV_RecordBuf(FFT(fft, sig, hop, 0), rec, 0, 1, 0, hop, 0);
		Out.ar(out, IFFT(chain, 0) * 0.0);   // the chain must be drawn to run; nothing is heard
	}).add;
	self
};

~le[\icyStretchSize] = { |self, seconds|
	var sr = self[\server].sampleRate ? 44100, want = (seconds ? 1.49).asFloat * sr;
	self[\icyStretchSizes].minItem({ |n| (n - want).abs })
};

// the frames of one sample at one size — made now if absent (a real-time pass of the sample's length); done.value(pv) when in
~le[\icyStretchFrames] = { |self, name, size, done|
	var lab = self[\icyLab], s = self[\server], smp = lab[\samples][name], key = (name.asString ++ "@" ++ size).asSymbol, pv, hop;
	lab[\pv] = lab[\pv] ? IdentityDictionary.new;
	lab[\fft] = lab[\fft] ? IdentityDictionary.new;
	pv = lab[\pv][key];
	if(pv.notNil) { done.value(pv) } {
		fork {
			hop = self[\icyStretchHop];
			if(lab[\fft][size].isNil) { lab[\fft][size] = [Buffer.alloc(s, size), Buffer.alloc(s, size)] };
			pv = (size: size, frames: ((smp[\dur] * s.sampleRate) / (size * hop)).ceil.asInteger.max(1),
				recL: Buffer.alloc(s, smp[\dur].calcPVRecSize(size, hop, s.sampleRate)),
				recR: Buffer.alloc(s, smp[\dur].calcPVRecSize(size, hop, s.sampleRate)));
			s.sync;
			Synth(\leIcyAnalyse, [\buf, smp[\bufL].bufnum, \fft, lab[\fft][size][0].bufnum, \rec, pv[\recL].bufnum, \hop, hop, \out, self[\busMaster].index], self[\grpFx]);
			Synth(\leIcyAnalyse, [\buf, smp[\bufR].bufnum, \fft, lab[\fft][size][1].bufnum, \rec, pv[\recR].bufnum, \hop, hop, \out, self[\busMaster].index], self[\grpFx]);
			(smp[\dur] + (size * 2 / s.sampleRate) + 0.1).wait;
			lab[\pv][key] = pv;
			done.value(pv);
		};
	};
};

~le[\icyStretchStart] = { |self, name, d|
	var lab = self[\icyLab], size = self.icyStretchSize(d[\windowSeconds] ? lab[\windowSeconds] ? 1.49);
	var num = { |v, dflt| if(v.isNil) { dflt } { v.asString.asFloat } };
	lab[\windowSeconds] = (d[\windowSeconds] ? lab[\windowSeconds] ? 1.49).asString.asFloat;
	self.icyStretchFrames(name, size, { |pv|
		if(lab[\synth].notNil) { lab[\synth].set(\gate, 0) };
		lab[\synth] = Synth(\leIcyStretch, [\out, self[\busMaster].index, \fftL, lab[\fft][size][0].bufnum, \fftR, lab[\fft][size][1].bufnum,
			\recL, pv[\recL].bufnum, \recR, pv[\recR].bufnum, \nFrames, pv[\frames],
			\slowerBy, num.(d[\slowerBy], 30), \readFrom, num.(d[\readFrom], 0), \level, num.(d[\level], 1)], self[\grpFx]);
		lab[\sample] = name; lab[\voice] = \stretch;
		self.say("LE_RESULT", self.json((msg: "icy", did: "start", sample: name.asString, voice: "stretch", windowSeconds: (size / self[\server].sampleRate).round(0.01),
			frames: pv[\frames], node: lab[\synth].nodeID)));
	});
};

~le[\icyLabHear] = { |self|
	self.hear(\icy, { |le, d| le.icyLabDo(d) });
	self
};
)
