// process.scd — THE PROCESSING: a banked sample put through THE CHAIN and banked again under a name of its own (the engine plan's
// part 6, by way of part 2's port from the sandbox; first built in the Decibel piece, 2026-10-05 — its PLAN 1.3 · RUNNING_LOG §103).
// Loaded by boot.scd after bank.scd; nothing here runs until a message asks for a render.
//
//   /le/process   source · out · effect · args · end · [atkMs durMs relMs curve] · [floorDb capMs] · gainDb · match · id
//       source   a sample in the bank (its FILE, <bank>/<source>.wav — a render of a render is a file like any other)
//       out      the new sample's name; taken twice, it REPLACES its row and its file — the latest render wins
//       effect   a word for the row and the label; the engine does not read it
//       args     "name:value,name:value" — the chain's OWN control names (below). The page decides them: every stage of the
//                chain is a MIX at 0 until an argument turns it up, so a "stage alone" is its mix at 1 and nothing else.
//       end      HOW THE RESULT ENDS —
//                  shape   an ENVELOPE after the effect: atkMs up · the level held · relMs down on `curve` (-4 = percussive),
//                          the whole exactly durMs long. relMs as long as the rest = a pure struck shape. The processed TIMBRE
//                          with an ATTACK's shape: the two are decoupled.
//                  tail    the effect rings out: the sample ends where it falls floorDb (-60) under its own peak, or at capMs
//                          (8000) past the source's end if it never does (a freeze) — then faded.
//       match    1 (default): the result's PEAK is set to the source's, so a chain neither fades away nor runs hot · 0: as rendered
//       gainDb   then this, on top
//       id       comes back in the row as openingId — how the page knows THIS render is done
//   The answer is the bank's: <bank>/<out>.wav · a row in index.json (kind "processed", with source · effect · args · end) ·
//   the sample in a buffer, playable at once by /le/play. One LE_RESULT line; an LE_ERROR when nothing was made.
//
// THE RENDER IS OFFLINE (NRT): a second scsynth, with no device and no port, plays the source's FILE through the chain into a
// file, faster than real time — the sandbox's own road for this chain (its build/audition/*.scd), so the living engine's sound
// server is never asked to do it, a render cannot glitch a performance, and it is proven with no hardware (process_test.scd).
// The language then finds the result's START (the first sample floorDb under the peak — an FFT's or a comb's delay is not kept
// as silence at the head), ENDS it (shape | tail), sets its level, writes it and indexes it.
//
// THE CHAIN is the sandbox's \processChain (live-electronics-engine/synths/process-chain.scd), stage for stage, in its order —
// what makes harmonics before the filter, what is spectral after it, the reverbs last. FIVE CHANGES, each for a banked sample:
//   1 MONO — the `space` stage (width · swirl) is left out: the bank is mono; the stereo reverbs are summed.
//   2 EVERY stage has a mix, the filter too (`filtMix`): in the sandbox the filter and a little reverb were always in the path.
//   3 The spectral block is BYPASSED when smear · gate · freeze are all off: an FFT in the path delays and softens every attack.
//   4 FREEZE engages at `freezeAtMs` and its phases are re-drawn at every frame (PV_Diffuser): a short sample is followed by
//     silence, and frozen magnitudes on silence's phases are a buzz at the frame rate, not a held spectrum.
//   5 No tanh, no limiter at the end: the render is floating point and the language sets the level. A DC blocker instead, and
//     the player is shut at its buffer's end (it holds its last value otherwise — a tail would never fall silent).
//   Added: `rate` (the synth's own — a tape's speed) and `rev` (1 = read backwards).
//   ADDED 2026-10-05 (the Decibel piece's DEC-17 · RUNNING_LOG §106; the engine's §28) — nine stages, each a mix at 0 like the rest:
//   `override` (after Destroy FX's Buffer Override — from how it works, not its code) right after the noise bed; after `drive` the
//   pedals `overdrive` · `fuzz` · `octave` and a speaker `cab`, then `crush` (a true bit depth) · `cheby` · `squiz` · `waveloss`.
// The sc3-plugins stages are looked up BY NAME when the synth is built: one that is not installed is left out of the graph and
// named once (~le[\processMissing]) — the file still loads.
(
~le[\processDefaults] = (end: "tail", floorDb: -60, capMs: 8000, fadeOutMs: 30, atkMs: 2, durMs: 600, relMs: 600, curve: -4, gainDb: 0, match: 1);
~le[\processBusy] = IdentitySet.new;

// ---- the chain --------------------------------------------------------------------------------------------------------
~le[\processDef] = { |self|
	var missing = List.new;
	if(self[\processDefObj].isNil) {
		self[\processDefObj] = SynthDef(\leProcess, { |out = 0, buf = 0, rate = 1, rev = 0,
			rlo = 0.5, rlomid = 0.5, rhimid = 0.5, rhi = 0.5, resMix = 0, resDcy = 0.6,
			cresFreq = 300, cresDcy = 0.6, cresMix = 0,
			drive = 8, driveType = 0, driveArg = 0.5, shapeMix = 0,
			rmFreq = 300, rmMix = 0, drmFreq = 180, drmMix = 0, fsHz = 120, fsMix = 0,
			combTime = 0.012, combFb = 0.8, combMix = 0,
			cut = 1200, res = 0.5, hpf = 30, filtType = 0, filtDist = 0.4, filtMix = 0,
			stresTime = 0.003, stresRes = 0.9, stresMix = 0,
			diffTime = 0.02, diffGain = 0.6, diffMix = 0,
			freeze = 0, freezeAtMs = 60, smear = 0, gate = 0,
			revTime = 2, revDamp = 0.4, revRoom = 22, revMix = 0,
			ghTime = 0.4, ghDamp = 0.2, ghSize = 1, ghDiff = 0.7, ghFb = 0.7, ghModDepth = 0.1, ghModFreq = 2, ghMix = 0,
			jpT60 = 2, jpDamp = 0.3, jpSize = 1.2, jpEarly = 0.7, jpModDepth = 0.1, jpModFreq = 2, jpLow = 1, jpMid = 1, jpHigh = 1, jpMix = 0,
			noise = 0, noiseCut = 8000,
			ovrMix = 0, ovrBuf = 250, ovrDiv = 8, ovrSmooth = 0.1,
			odMix = 0, odDrive = 4, odTone = 3000,
			fzMix = 0, fzGain = 30, fzBias = 0.3, fzTone = 4000,
			ocMix = 0, ocOctave = 1, ocGain = 20, ocTone = 4000,
			cabMix = 0, cabLow = 100, cabHigh = 4500, cabPres = 3,
			crMix = 0, crBits = 8, crRate = 12000,
			chMix = 0, chDrive = 1, ch2 = 0.5, ch3 = 0.3, ch4 = 0, ch5 = 0.2,
			sqMix = 0, sqRatio = 2, sqChunks = 1,
			wlMix = 0, wlDrop = 20, wlOf = 40, wlMode = 2,
			amp = 1, lag = 0.04|
			var sig, play, dry, pre, soft, bank, shaped, filtered, chainA, chainF, specA, specF, frz, wet, back;
			var ovrBufL, ovrFrames, wr, ovrTrig, startPos, miniSamps, fadeSamps, period, ph, firstRep, gA, rdA, rdB, ovr;
			var od, fz, oc, cabSig, cr, chx, chx2, ch;
			var mix = { |a, b, m| XFade2.ar(a, b, (m.lag(lag) * 2 - 1).clip(-1, 1)) };
			// a stage whose class is not installed is left out: `otherwise` stands in its place
			var opt = { |name, f, otherwise|
				var c = name.asClass;
				if(c.isNil) { if(missing.includes(name).not) { missing.add(name) }; otherwise } { f.value(c) }
			};

			back = rev > 0;
			play = PlayBuf.ar(1, buf, rate.abs.clip(0.05, 8) * BufRateScale.kr(buf) * (1 - (2 * back)), 1, back * (BufFrames.kr(buf) - 2), 0);
			// a player that has reached its buffer's end HOLDS the last value: a source that does not end on zero would leave a
			// steady offset under everything, and a tail would never reach silence (measured, process_test.scd) — so it is shut
			sig = play * (1 - Done.kr(play));
			// the noise bed follows the sample's own envelope: it breathes with the material
			sig = sig + (LPF.ar(PinkNoise.ar(1), noiseCut.lag(lag).clip(200, 16000)) * Amplitude.kr(sig, 0.01, 0.2) * noise.lag(lag) * 3);

			// --- buffer override (DEC-17): the sound is cut into FORCED buffers (ovrBuf ms); of each, only the FIRST mini-buffer
			//     (a 1/ovrDiv of it) is kept and repeated until the next forced buffer begins — a stutter, and a PITCH when the
			//     mini-buffer is short (a repeat every 1/f s sounds at f: ovrDiv / ovrBuf · 1000 Hz). The joins are crossfaded by
			//     ovrSmooth of the mini-buffer, the repeat shortened by the fade, as the original does it. After Destroy FX's Buffer
			//     Override (Sophia Poirier, GPL) — written from how it works, not from its code. The LFOs and the MIDI pitch: later.
			ovrBufL = LocalBuf(SampleRate.ir * 4.5).clear;   // the input, written round and round; a forced buffer is at most 4 s
			ovrFrames = BufFrames.ir(ovrBufL);
			wr = Phasor.ar(0, 1, 0, ovrFrames);
			BufWr.ar(sig, ovrBufL, wr, 1);
			ovrTrig = Impulse.ar(1000 / ovrBuf.lag(lag).clip(10, 4000));   // the forced buffer begins; Impulse fires at its first sample too
			startPos = Latch.ar(wr, ovrTrig);
			miniSamps = (ovrBuf.lag(lag).clip(10, 4000) / 1000 * SampleRate.ir / ovrDiv.lag(lag).clip(1, 256)).max(8);
			fadeSamps = (miniSamps * ovrSmooth.lag(lag).clip(0, 0.5)).max(1);
			period = (miniSamps - fadeSamps).max(4);
			ph = Phasor.ar(ovrTrig, 1, 0, period);
			firstRep = Sweep.ar(ovrTrig, SampleRate.ir) < period;   // the first pass: the mini-buffer is being written — no tail yet to fade from
			gA = (ph / fadeSamps).clip(0, 1).max(firstRep);
			rdA = BufRd.ar(1, ovrBufL, (startPos + ph - 1).wrap(0, ovrFrames), 1, 1);              // the mini-buffer's head, fading in
			rdB = BufRd.ar(1, ovrBufL, (startPos + ph + period - 1).wrap(0, ovrFrames), 1, 1);     // its tail, fading out under the head
			ovr = (rdA * gA.sqrt) + (rdB * (1 - gA).sqrt * (1 - firstRep));
			sig = mix.(sig, ovr, ovrMix);

			// --- resonator bank: four ringing bands -----------------------------------------------------------------
			bank = Ringz.ar(sig, [110, 440, 1600, 5200], resDcy.lag(lag).clip(0.02, 3.0)) * [rlo.lag(lag), rlomid.lag(lag), rhimid.lag(lag), rhi.lag(lag)];
			sig = mix.(sig, bank.sum * 0.2, resMix);
			// --- complex resonator: one ringing partial ---------------------------------------------------------------
			sig = opt.(\ComplexRes, { |c| mix.(sig, c.ar(sig, cresFreq.lag(lag).clip(20, 8000), cresDcy.lag(lag).clip(0.01, 0.99)) * 0.5, cresMix) }, sig);
			// --- drive: six shapers, tamed by a lowpass ----------------------------------------------------------------
			dry = sig; pre = dry * drive.lag(lag).clip(1, 40); soft = pre.tanh;
			shaped = Select.ar(driveType.clip(0, 5), [
				soft,
				opt.(\SineShaper, { |c| c.ar(pre * 0.3, driveArg.lag(lag).clip(0.05, 1.0)) }, soft),
				opt.(\CrossoverDistortion, { |c| c.ar(dry, driveArg.lag(lag).clip(0.01, 1.0), (1 - driveArg.lag(lag)).clip(0.01, 1.0)) }, soft),
				opt.(\OSFold4, { |c| c.ar(pre * 0.2, driveArg.lag(lag).neg.clip(-1, -0.02), driveArg.lag(lag).clip(0.02, 1)) }, soft),
				opt.(\SmoothDecimator, { |c| c.ar(dry, (driveArg.lag(lag).clip(0, 1) * 22000 + 800), (1 - driveArg.lag(lag)).clip(0, 1)) }, soft),
				opt.(\Disintegrator, { |c| c.ar(dry, driveArg.lag(lag).clip(0, 1), 0.0) }, soft)
			]);
			sig = mix.(dry, LPF.ar(shaped, 7000) * 0.8, shapeMix);
			// --- the pedals (DEC-17): overdrive · fuzz · octave fuzz, then a speaker cabinet — each alone, or stacked by the JSON box ---
			od = (HPF.ar(sig, 720) + (LPF.ar(sig, 720) * 0.35)) * odDrive.lag(lag).clip(1, 40);   // the lows driven less, as the Tube Screamer's clipping stage does
			sig = mix.(sig, LPF.ar(od.tanh, odTone.lag(lag).clip(500, 8000)) * 0.5, odMix);
			fz = ((sig * fzGain.lag(lag).clip(2, 200)) + fzBias.lag(lag).clip(-1, 1)).clip(-1, 1);   // a biased hard clip: one side clips first, as a transistor fuzz does
			sig = mix.(sig, LPF.ar(HPF.ar(fz, 40), fzTone.lag(lag).clip(500, 8000)) * 0.5, fzMix);
			oc = (sig * (1 - ocOctave.lag(lag).clip(0, 1))) + (HPF.ar(sig.abs, 30) * ocOctave.lag(lag).clip(0, 1) * 2);   // rectified: the octave above appears
			sig = mix.(sig, LPF.ar((oc * ocGain.lag(lag).clip(2, 200)).clip(-1, 1), ocTone.lag(lag).clip(500, 8000)) * 0.5, ocMix);
			cabSig = HPF.ar(sig, cabLow.lag(lag).clip(40, 300));
			cabSig = BPeakEQ.ar(cabSig, cabLow.lag(lag).clip(40, 300) * 1.4, 1.5, 3);                 // the cabinet's low thump
			cabSig = BPeakEQ.ar(cabSig, 2500, 1.0, cabPres.lag(lag).clip(-12, 12));                    // presence
			cabSig = LPF.ar(LPF.ar(cabSig, cabHigh.lag(lag).clip(2000, 12000)), cabHigh.lag(lag).clip(2000, 12000) * 1.3);   // a speaker's roll-off, steep
			sig = mix.(sig, cabSig, cabMix);
			// --- crush: a TRUE bit depth, and the sample rate (the `drive` stage's "bitcrush" is the rate alone) -------------------------
			cr = Latch.ar(sig, Impulse.ar(crRate.lag(lag).clip(500, 48000))).round(2.pow(1 - crBits.lag(lag).clip(2, 16)));
			sig = mix.(sig, cr, crMix);
			// --- cheby: Chebyshev waveshaping — each polynomial adds exactly its harmonic of a sine; the even ones without their offset
			//     (T2(0) = -1, T4(0) = 1 would leave a constant under silence, and a tail would never end) ------------------------------
			chx = (sig * chDrive.lag(lag).clip(0.1, 4)).clip(-1, 1); chx2 = chx * chx;
			ch = chx + (chx2 * 2 * ch2.lag(lag).clip(0, 1)) + (((chx2 * 4) - 3) * chx * ch3.lag(lag).clip(0, 1))
				+ (chx2 * (chx2 - 1) * 8 * ch4.lag(lag).clip(0, 1)) + ((((chx2 * 16) - 20) * chx2 + 5) * chx * ch5.lag(lag).clip(0, 1));
			sig = mix.(sig, ch * 0.4, chMix);
			// --- squiz · waveloss: two shredders from sc3-plugins (chopped and squeezed up in pitch · wave cycles dropped) ---------------
			sig = opt.(\Squiz, { |c| mix.(sig, c.ar(sig, sqRatio.lag(lag).clip(1, 16), sqChunks.clip(1, 32), 0.1), sqMix) }, sig);
			sig = opt.(\WaveLoss, { |c| mix.(sig, c.ar(sig, wlDrop.clip(0, wlOf.clip(1, 100)), wlOf.clip(1, 100), wlMode.clip(1, 2)), wlMix) }, sig);
			// --- ring modulation · the diode ring · frequency shift ---------------------------------------------------
			sig = mix.(sig, sig * SinOsc.ar(rmFreq.lag(lag).clip(20, 8000)), rmMix);
			sig = opt.(\DiodeRingMod, { |c| mix.(sig, c.ar(sig, SinOsc.ar(drmFreq.lag(lag).clip(10, 6000))), drmMix) }, sig);
			sig = mix.(sig, FreqShift.ar(sig, fsHz.lag(lag).clip(-1200, 1200)), fsMix);
			// --- comb: a delay that rings at a pitch (combFb is its ring, in seconds) ----------------------------------
			sig = mix.(sig, CombC.ar(sig, 0.5, combTime.lag(lag).clip(0.002, 0.5), combFb.lag(lag).clip(0.01, 4.0)) * 0.7, combMix);
			// --- filter: four models, and a high-pass -------------------------------------------------------------------
			filtered = Select.ar(filtType.clip(0, 3), [
				MoogFF.ar(sig, cut.lag(lag).clip(80, 16000), res.lag(lag).clip(0, 3.9)),
				opt.(\MoogLadder, { |c| c.ar(sig, cut.lag(lag).clip(80, 16000), (res.lag(lag) / 4).clip(0, 0.98)) }, sig),
				opt.(\LPF18, { |c| c.ar(sig, cut.lag(lag).clip(80, 16000), (res.lag(lag) / 4).clip(0, 0.98), filtDist.lag(lag).clip(0, 1)) }, sig),
				opt.(\RLPFD, { |c| c.ar(sig, cut.lag(lag).clip(80, 16000), (res.lag(lag) / 4).clip(0, 0.98), filtDist.lag(lag).clip(0, 1)) }, sig)
			]);
			sig = mix.(sig, HPF.ar(filtered, hpf.lag(lag).clip(20, 2000)), filtMix);
			// --- string resonator: a delay short enough to be a pitch -------------------------------------------------
			sig = opt.(\Streson, { |c| mix.(sig, c.ar(sig, stresTime.lag(lag).clip(0.0002, 0.05), stresRes.lag(lag).clip(0, 0.99)) * 0.6, stresMix) }, sig);
			// --- diffusion: three nested allpasses — it spreads what is there, without a tail --------------------------
			sig = opt.(\NestedAllpassC, { |c| mix.(sig, c.ar(sig,
				0.05, diffTime.lag(lag).clip(0.0005, 0.05), diffGain.lag(lag).clip(0, 0.9),
				0.05, (diffTime.lag(lag) * 2.4).clip(0.0005, 0.05), diffGain.lag(lag).clip(0, 0.9),
				0.05, (diffTime.lag(lag) * 0.6).clip(0.0005, 0.05), diffGain.lag(lag).clip(0, 0.9)), diffMix) }, sig);
			// --- spectral: smear · gate — bypassed when both are off (change 3) -----------------------------------------
			chainA = FFT(LocalBuf(2048), sig);
			chainA = PV_MagSmear(chainA, smear.clip(0, 24));
			chainA = PV_MagAbove(chainA, gate.clip(0, 60));
			specA = IFFT(chainA);
			// --- freeze: the spectrum at freezeAtMs, held, its phases re-drawn at every frame (change 4) -----------------
			frz = (freeze > 0) * (Sweep.kr(0, 1) >= (freezeAtMs / 1000));
			chainF = FFT(LocalBuf(2048), sig, 0.25);
			chainF = PV_MagFreeze(chainF, frz);
			chainF = PV_MagSmear(chainF, smear.clip(0, 24));
			chainF = PV_Diffuser(chainF, Impulse.kr(200));
			specF = IFFT(chainF) * 0.5;
			sig = Select.ar((smear + gate) > 0, [sig, specA]);
			sig = XFade2.ar(sig, specF, (Lag.kr(frz, 0.02) * 2 - 1).clip(-1, 1));
			// --- the reverbs, last: they hear the result ----------------------------------------------------------------
			wet = GVerb.ar(sig, revRoom.clip(1, 90), revTime.lag(lag).clip(0.1, 20), revDamp.lag(lag).clip(0, 1), 0.5, 15, 0, 0.7, 0.5).sum * 0.4;
			sig = mix.(sig, wet, revMix);
			sig = opt.(\Greyhole, { |c| mix.(sig, c.ar([sig, sig],
				ghTime.lag(lag).clip(0.01, 4.0), ghDamp.lag(lag).clip(0, 1), ghSize.lag(lag).clip(0.5, 5.0), ghDiff.lag(lag).clip(0, 1),
				ghFb.lag(lag).clip(0, 1), ghModDepth.lag(lag).clip(0, 1), ghModFreq.lag(lag).clip(0, 10)).sum * 0.5, ghMix) }, sig);
			sig = opt.(\JPverb, { |c| mix.(sig, c.ar([sig, sig],
				jpT60.lag(lag).clip(0.1, 20), jpDamp.lag(lag).clip(0, 1), jpSize.lag(lag).clip(0.5, 5.0), jpEarly.lag(lag).clip(0, 1),
				jpModDepth.lag(lag).clip(0, 1), jpModFreq.lag(lag).clip(0, 10),
				jpLow.lag(lag).clip(0, 2), jpMid.lag(lag).clip(0, 2), jpHigh.lag(lag).clip(0, 2)).sum * 0.5, jpMix) }, sig);

			// no offset leaves the chain (a comb multiplies one; a shaper makes one): a blocker at about 8 Hz
			Out.ar(out, LeakDC.ar(sig, 0.999) * amp);
		});
		self[\processMissing] = missing.asArray;
		if(missing.size > 0) { self.say("LE_INFO", "process — these stages are not installed here and are left out of the chain: " ++ missing.join(", ")) };
	};
	self[\processDefObj]
};

// "name:value,name:value" -> the chain's own controls, as [\name, value, …]; a name the chain does not have is left out and named
~le[\processArgs] = { |self, text|
	var names = self.processDef.allControlNames.collect({ |c| c.name }), args = List.new, unknown = List.new;
	(text ? "").asString.split($,).do({ |kv|
		var b = kv.asString.stripWhiteSpace.split($:), k;
		if(b.size == 2) {
			k = b[0].asString.stripWhiteSpace.asSymbol;
			if(names.includes(k) and: { (k != \buf) and: { k != \out } }) { args.add(k); args.add(b[1].asString.asFloat) } { unknown.add(k) };
		};
	});
	(args: args.asArray, unknown: unknown.asArray)
};

// where a sample's FILE is: the bank the engine writes to, else the one its buffers were filled from
~le[\processFile] = { |self, name|
	[self[\bankDir], self[\sourceDir]].reject({ |x| x.isNil }).collect({ |x| x.asString +/+ name ++ ".wav" }).detect({ |p| File.exists(p) })
};

// ---- the render: /le/process ------------------------------------------------------------------------------------------
~le[\processRender] = { |self, d|
	var o = self[\processDefaults].copy, dir = self[\bankDir];
	var src = self.safeName(d[\source]), out = self.safeName(d[\out]), id = self.safeName(d[\id]);
	var effect = (d[\effect] ? "").asString.select({ |c| c.isAlphaNum or: { " -_+".includes(c) } }).keep(40);
	var lim = (floorDb: [-120, -6], capMs: [100, 60000], fadeOutMs: [0, 2000], atkMs: [0, 10000], durMs: [10, 120000], relMs: [0, 120000], curve: [-12, 12], gainDb: [-60, 24], match: [0, 1]);
	var endMode, srcPath, sf, sr, srcData, srcPeak, parsed, args, argsText, rate = 1, total, lead = 0.02, oscPath, nrtPath, opts, score;
	lim.keysValuesDo({ |k, r| if(d[k].notNil) { o[k] = d[k].asString.asFloat.clip(r[0], r[1]) } });
	endMode = if((d[\end] ? o[\end]).asString == "shape") { "shape" } { "tail" };
	case
	{ dir.isNil } { self.say("LE_INFO", "process — the engine was started with no bank folder: nothing is rendered") }
	{ (src.size == 0) or: { out.size == 0 } } { self.say("LE_INFO", "process — a source and a name are needed: nothing is rendered") }
	{ src == out } { self.say("LE_INFO", "process · " ++ out ++ " — a sample cannot be its own source: nothing is rendered") }
	{ self[\processBusy].includes(out.asSymbol) } { self.say("LE_INFO", "process · " ++ out ++ " — already rendering") }
	{ (srcPath = self.processFile(src)).isNil } {
		self.say("LE_ERROR", "process · " ++ out ++ " — its source, " ++ src ++ ", is not in the bank: nothing is rendered");
		self.say("LE_RESULT", self.json((msg: "processed", name: out, source: src, openingId: id, failed: true)));
	}
	{ true } {
		sf = SoundFile.new;
		if(sf.openRead(srcPath).not or: { sf.numChannels != 1 }) {
			if(sf.isOpen) { sf.close };
			self.say("LE_ERROR", "process · " ++ out ++ " — " ++ srcPath ++ " could not be read as a mono sample: nothing is rendered");
		} {
			sr = sf.sampleRate.asInteger;
			srcData = FloatArray.newClear(sf.numFrames);
			sf.readData(srcData);
			sf.close;
			srcPeak = if(srcData.size > 0) { srcData.abs.maxItem } { 0 };
			parsed = self.processArgs(d[\args]);
			args = parsed[\args];
			argsText = args.clump(2).collect({ |p| p[0].asString ++ ":" ++ p[1] }).join(",");
			args.clump(2).do({ |p| if(p[0] == \rate) { rate = p[1].abs.clip(0.05, 8) } });
			// shape: the object's length and room for the head · tail: the source, then the cap
			total = if(endMode == "shape") { (o[\durMs] / 1000) + 0.5 } { (srcData.size / sr / rate) + (o[\capMs] / 1000) };
			File.mkdir(dir +/+ "raw");
			oscPath = dir +/+ "raw" +/+ out ++ ".osc";
			nrtPath = dir +/+ "raw" +/+ out ++ ".nrt.wav";
			if(File.exists(nrtPath)) { File.delete(nrtPath) };   // a render that fails must not be mistaken for the one before it
			opts = ServerOptions.new.numOutputBusChannels_(1).memSize_(131072).numWireBufs_(256);
			score = Score([
				[0.0, ['/d_recv', self.processDef.asBytes]],
				[0.0, ['/b_allocRead', 0, srcPath, 0, 0]],
				[lead, ['/s_new', \leProcess, 1000, 0, 0, \buf, 0, \out, 0] ++ args],
				[lead + total, ['/c_set', 0, 0]]
			]);
			self[\processBusy].add(out.asSymbol);
			self.say("LE_INFO", "process · " ++ out ++ " ← " ++ src ++ " · " ++ effect ++ " · " ++ endMode ++ " · rendering " ++ total.round(0.01) ++ " s offline"
				++ if(parsed[\unknown].size > 0) { " · NOT in the chain, left out: " ++ parsed[\unknown].join(", ") } { "" });
			score.recordNRT(oscPath, nrtPath, nil, sr, "WAV", "float", opts, "", nil, { |code|
				self[\processBusy].remove(out.asSymbol);
				try { self.processDone(o, src, out, id, effect, argsText, endMode, sr, srcPeak, nrtPath, oscPath, code) } { |err|
					self.say("LE_ERROR", "process · " ++ out ++ " — the render was made and could not be banked · " ++ err.errorString);
					self.say("LE_RESULT", self.json((msg: "processed", name: out, source: src, openingId: id, failed: true)));
				};
			});
		};
	};
	self
};

// the rendered file -> the sample: its start found, its end made (shape | tail), its level set, written, indexed, loaded
~le[\processDone] = { |self, o, src, out, id, effect, argsText, endMode, sr, srcPeak, nrtPath, oscPath, code|
	var s = self[\server], dir = self[\bankDir], rel = out ++ ".wav", sf = SoundFile.new;
	var data, peak, thr, head, last, start, stop, n, take, nA, nR, c, g, outPeak, fadeMs, capped = false, held = false, srcRow, row, old, lenMs;
	if(File.exists(nrtPath) and: { sf.openRead(nrtPath) }) {
		data = FloatArray.newClear(sf.numFrames * sf.numChannels);
		sf.readData(data);
		sf.close;
	};
	if(File.exists(oscPath)) { File.delete(oscPath) };
	peak = if(data.notNil and: { data.size > 0 }) { data.abs.maxItem } { 0 };
	if(peak < 1e-6) {
		self.say("LE_ERROR", "process · " ++ out ++ " — the render is silent or was not made (the renderer answered " ++ code ++ "): nothing is saved");
		self.say("LE_RESULT", self.json((msg: "processed", name: out, source: src, openingId: id, failed: true)));
	} {
		thr = peak * o[\floorDb].dbamp;
		head = data.detectIndex({ |x| x.abs >= thr });
		start = (head - (0.002 * sr).asInteger).max(0);
		if(endMode == "shape") {
			n = (o[\durMs] / 1000 * sr).round.asInteger.max(1);
			take = data.copyRange(start, (start + n - 1).min(data.size - 1));
			if(take.size < n) { take = take ++ FloatArray.newClear(n - take.size) };
			nA = (o[\atkMs] / 1000 * sr).round.asInteger.clip(0, n);
			nR = (o[\relMs] / 1000 * sr).round.asInteger.clip(0, n - nA);
			c = o[\curve];
			nA.do({ |i| take[i] = take[i] * (i / nA) });
			// the release, on the curve an Env draws: 0 a straight line, below it a fast fall first (-4 a struck sound's)
			nR.do({ |i|
				var pos = (i + 1) / nR, lvl = if(c.abs < 0.001) { 1 - pos } { 1 - ((1 - exp(pos * c)) / (1 - exp(c))) };
				take[n - nR + i] = take[n - nR + i] * lvl;
			});
		} {
			last = data.size - 1;
			while { (last > head) and: { data[last].abs < thr } } { last = last - 1 };
			capped = (data.size - 1 - last) < (0.05 * sr);   // still sounding at the cap: it is faded, not waited for
			stop = (last + (0.02 * sr).asInteger).min(data.size - 1);
			take = data.copyRange(start, stop);
			n = take.size;
			fadeMs = if(capped) { max(o[\fadeOutMs], 150) } { o[\fadeOutMs] };
			nR = (fadeMs / 1000 * sr).round.asInteger.clip(0, n);
			nR.do({ |i| take[n - 1 - i] = take[n - 1 - i] * (i / nR) });
		};
		outPeak = take.abs.maxItem;
		g = if((o[\match] > 0.5) and: { outPeak > 0 }) { srcPeak / outPeak } { 1 };
		g = g * o[\gainDb].dbamp;
		if((outPeak * g) > 0.98) { g = 0.98 / outPeak; held = true };
		take.size.do({ |i| take[i] = take[i] * g });   // in place: the samples stay a FloatArray, which is what the file writer takes
		outPeak = outPeak * g;
		if(self.wavWrite(dir +/+ rel, take, sr).not) {
			self.say("LE_ERROR", "process · " ++ out ++ " — the sample could not be written: " ++ (dir +/+ rel));
			self.say("LE_RESULT", self.json((msg: "processed", name: out, source: src, openingId: id, failed: true)));
		} {
			lenMs = (take.size / sr * 1000).round(0.1);
			if(self[\indexRows].isNil) { self[\indexRows] = List.new };
			srcRow = self[\indexRows].detect({ |r| r[\name].asString == src });
			row = (id: "prc_" ++ self.nowIso.select({ |ch| ch.isDecDigit }), name: out,
				player: if(srcRow.notNil) { (srcRow[\player] ? "").asString } { "" }, lane: if(srcRow.notNil) { (srcRow[\lane] ? -1).asInteger } { -1 },
				category: "processed", scoreTime: 0, lengthMs: lenMs, peakDb: self.db(outPeak), file: rel, raw: "raw/" ++ out ++ ".nrt.wav",
				openingId: id, windowMs: 0, attackMs: (head / sr * 1000).round(0.1), captured: self.nowIso,
				kind: "processed", source: src, effect: effect, args: argsText, end: endMode);
			self[\indexRows] = self[\indexRows].reject({ |r| r[\name].asString == out }).asList;   // a List: add() in place (bank.scd, §84)
			self[\indexRows].add(row);
			if(self.indexWrite.not) { self.say("LE_INFO", "the index was NOT written — the sample is saved as " ++ rel) };
			old = if(self[\samples].notNil) { self[\samples][out.asSymbol] };
			if(s.notNil and: { s.serverRunning }) {
				Buffer.read(s, dir +/+ rel, action: { |b|
					if(self[\samples].isNil) { self[\samples] = IdentityDictionary.new };
					self[\samples][out.asSymbol] = (row: row, buf: b, from: \processed);
					if(old.notNil and: { old[\buf].notNil }) { SystemClock.sched(10, { old[\buf].free; nil }) };
				});
			};
			self.say("LE_INFO", "processed · " ++ out ++ " ← " ++ src ++ " · " ++ effect ++ " · " ++ endMode ++ " · " ++ lenMs.round(1).asInteger ++ " ms · peak " ++ self.db(outPeak) ++ " dB"
				++ if(capped) { " · STILL SOUNDING at the cap: faded" } { "" } ++ if(held) { " · held under full scale" } { "" }
				++ if(old.notNil) { " · REPLACES the earlier render" } { "" });
			self.say("LE_RESULT", self.json(row.copy.putAll((msg: "processed", capped: capped, held: held, replaced: old.notNil))));
		};
	};
	self
};
)
