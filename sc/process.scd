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
//                A DIAL AS A LINE (the Decibel piece's 11.4):  fbDrive:2@0,8@6000  — value@ms breakpoints from the render's start;
//                the dial starts at the first value and is stepped along the line every 50 ms (the chain's own lag smooths it).
//       srcDrive THE DRIVE (11.4): how hard the SOURCE hits the chain — a gain on the source, before every stage:
//                  played       as the sample is (0 dB) — the default of a render asked for by a brick of its own
//                  normalized   brought to the piece's driveRef (LE_LEVEL; −20 LUFS) whatever was captured — one excitation, the
//                               effect always speaks; the default of a PLAN's variant
//                  +12 · -6     that many dB
//                held so that the driven source's own peak stays a decibel under full scale. What comes OUT is not touched by it:
//                `match` sets the result's peak as before, and a return's DYNAMIC (level.scd) is applied when it is played.
//       end      HOW THE RESULT ENDS —
//                  shape   an ENVELOPE after the effect: atkMs up · the level held · relMs down on `curve` (-4 = percussive),
//                          the whole exactly durMs long. relMs as long as the rest = a pure struck shape. The processed TIMBRE
//                          with an ATTACK's shape: the two are decoupled.
//                  tail    the effect rings out: the sample ends where it falls floorDb (-60) under its own peak, or at capMs
//                          (8000) past the source's end if it never does (a freeze) — then faded.
//                  perc · gauss · quasi · tri · expodec · rexpodec   (§111) FIXED CURVES over durMs: SuperCollider's Env.perc (atkMs
//                          up and the rest down, both on curve -4) · Roads's grain envelopes — a bell (sigma 0.15 of the length) ·
//                          Gaussian sides over a flat middle · a triangle · an exponential fall to -60 dB · its mirror, a rise then a cut.
//       match    1 (default): the result's PEAK is set to the source's, so a chain neither fades away nor runs hot · 0: as rendered
//       gainDb   then this, on top
//       id       comes back in the row as openingId — how the page knows THIS render is done
//   The answer is the bank's: <bank>/<out>.wav · a row in index.json (kind "processed", with source · effect · args · end) ·
//   the sample in a buffer, playable at once by /le/play. One LE_RESULT line; an LE_ERROR when nothing was made.
//       durX     (2026-10-05, the Decibel piece's DEC-22) instead of durMs: the envelope's length as a MULTIPLE OF THE SOURCE'S OWN
//                length — and of the length the effect makes of it when the args change `rate` (a tape at half speed is twice as long).
//
// THE PLAN (the Decibel piece's 10.8 · DEC-21 · 22 — "every return a transformation"): a score may ask for VARIANTS of the samples it
// captures, <base>~<suffix> (bfl-impulse-1~crush4-perc): one effect under a short envelope. The score is a PLAN; the engine renders
// each sample's variants RIGHT AFTER ITS CAPTURE, the soonest-needed first — the same in concert and in simulation.
//   /le/plan        stamp · part · of · rows · [render]
//       rows     the variants, "|" between them, each  base;suffix;effect;end;atkMs;durX;match;t;capMs;args[;drive]  (t = the score time
//                of its first use; args as /le/process takes them; drive as srcDrive above — absent = normalized). A plan comes in PARTS that share a stamp; it REPLACES the plan
//                before it when the last part is in, in whatever order they arrive. An empty plan clears it. render 1: then every
//                planned variant whose sample is in the bank is rendered (as /le/planrender).
//   /le/planrender  every planned variant whose sample is in the bank, rendered again — the simulation's button.
//   After a capture (bank.scd captureDone) the sample's planned variants are queued, ordered by t; at most planWidth (2) renders
//   run at once and each one's end starts the next. A variant is a processed sample like any other — a file, a row (planned: 1),
//   a buffer. Played before its render is in, a variant falls back (bank.scd sampleFor): the EARLIER render if a buffer holds one
//   (the take before, or the backup's), else its base RAW — said in the window each time, as "late".
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
//   ADDED the same day (DEC-18 · DEC-19 · §110): `feedback` after `cab` — the slap held to the amp, six strings in a loop (LocalIn/Out).
//   ADDED the same day (§120): the GRANULAR FREEZE after the spectral block — the cloud: long overlapping grains from one moment (GrainBuf
//   on a buffer the chain writes), the first of the granular voices (the engine plan's 10.2; after the sandbox's \roadsCloudBuf).
//   ADDED the same day (§122): `icy` — HIS OWN FREEZE of 2015 … 2016 (github.com/elosine/freeze): Warp1 over that buffer, a crawling read
//   point, 0.6 … 0.8 s windows, 17 … 40 overlaps, his ten grain windows (grainEnv/). The render loads them into buffers 1 … 10.
//   ADDED 2026-10-06 (the Decibel piece's DEC-32 · PLAN 10.3 · RUNNING_LOG §151; the engine's §40): HIS PETALS OF RESONANCE
//   (github.com/elosine/SynthDef_petalsOfResonance), twice, after the resonator bank — `petalsOrig` (po…), his SynthDef UGen for UGen
//   with the microphone replaced by the chain's signal, and `petals` (pt…), the same instrument by a cleaned signal path.
//   AND `fbOwn` on the feedback: 0 (default) the loop as it was · 1 every string sings — a CHORD on the six strings (the loop only
//   takes off where two strings share a harmonic; measured on 54 chords, none bloomed).
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
			rlo = 0.5, rlomid = 0.5, rhimid = 0.5, rhi = 0.5, resMix = 0, resDcy = 0.6, resF1 = 110, resF2 = 440, resF3 = 1600, resF4 = 5200,
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
			fbMix = 0, fbS1 = 82.41, fbS2 = 110, fbS3 = 146.83, fbS4 = 196, fbS5 = 246.94, fbS6 = 329.63,
			fbBloom = 1, fbHold = 2, fbDrive = 6, fbTone = 2500, fbPath = 8, fbClimb = 0, fbWobble = 0, fbOwn = 0,
			gfMix = 0, gfAtMs = 80, gfDur = 200, gfDens = 40, gfSpread = 20, gfPitch = 0,
			icMix = 0, icSpeed = 0.03, icFromMs = 60, icWin = 0.6, icOverlaps = 17, icRand = 0.2, icPitch = 0, icEnv = 4,
			poMix = 0, poFund = 200, poFirst = 2, poSpread = 0.33, poOffset = 0.25, poRingLo = 7.75, poRingHi = 9.5, poInLen = 1,
			ptMix = 0, ptFund = 200, ptFirst = 2, ptSpread = 0.33, ptOffset = 0.25, ptRingLo = 7.75, ptRingHi = 9.5, ptInLen = 1,
			amp = 1, lag = 0.04, srcAmp = 1|
			var sig, play, dry, pre, soft, bank, shaped, filtered, chainA, chainF, specA, specF, frz, wet, back;
			var gfBufL, gfW, gfOn, gfD, gfTrig, gfOv, gfPos, gfRate, gfCloud;
			var icOn, icWr, icPtr, icEnvBuf, icSig;
			var ovrBufL, ovrFrames, wr, ovrTrig, startPos, miniSamps, fadeSamps, period, ph, firstRep, gA, rdA, rdB, ovr;
			var od, fz, oc, cabSig, cr, chx, chx2, ch;
			var fbRt, fbProg, fbGain, fbIn, fbExc, fbStr, fbNone, fbAmp, fbToneNow, fbCol, fbPathNow;
			var fbRise, fbKnee, fbCount, fbOwnSig;
			var poTuneA, poTuneB, poPa, poPb, poIn, poRes, poOut;
			var ptIn, ptBase, ptTuned, ptLo, ptHi, ptRings, pt;
			var mix ={ |a, b, m| XFade2.ar(a, b, (m.lag(lag) * 2 - 1).clip(-1, 1)) };
			// a stage whose class is not installed is left out: `otherwise` stands in its place
			var opt = { |name, f, otherwise|
				var c = name.asClass;
				if(c.isNil) { if(missing.includes(name).not) { missing.add(name) }; otherwise } { f.value(c) }
			};

			back = rev > 0;
			play = PlayBuf.ar(1, buf, rate.abs.clip(0.05, 8) * BufRateScale.kr(buf) * (1 - (2 * back)), 1, back * (BufFrames.kr(buf) - 2), 0);
			// a player that has reached its buffer's end HOLDS the last value: a source that does not end on zero would leave a
			// steady offset under everything, and a tail would never reach silence (measured, process_test.scd) — so it is shut
			sig = play * (1 - Done.kr(play)) * srcAmp;   // srcAmp: THE DRIVE (11.4) — the source's gain, before every stage
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

			// --- resonator bank: four ringing bands — their pitches controls since §125 (the Decibel piece's DEC-23: drawn per variant) -----
			bank = Ringz.ar(sig, [resF1, resF2, resF3, resF4].collect({ |f| f.lag(lag).clip(20, 12000) }), resDcy.lag(lag).clip(0.02, 3.0)) * [rlo.lag(lag), rlomid.lag(lag), rhimid.lag(lag), rhi.lag(lag)];
			sig = mix.(sig, bank.sum * 0.2, resMix);
			// --- THE PETALS OF RESONANCE — HIS ORIGINAL (github.com/elosine/SynthDef_petalsOfResonance @ e87a5d4, SynthDef_petalsOfResonance.scd;
			//     the Decibel piece's DEC-32 · PLAN 10.3 · RUNNING_LOG §151), kept UGEN FOR UGEN and in his order: two banks of 13 partials over
			//     one fundamental — fund × (firstPartial + spread × n) — bank B bank2MidiOffset semitones up, every partial's pitch wobbling
			//     ± 0.5 semitone on a slow sine of its own; 26 DynKlanks of ONE partial each, at -40 dB, shuffled, mixed, limited, faded out
			//     after ringL2. ONE LINE IS CHANGED: the microphone, SoundIn.ar(ibs), is the chain's signal. LEFT OUT: masteramp (the render
			//     sets the level) · obs · doneAction: 2 (it would end the whole chain — his fade is kept). His 26 lines of each kind are
			//     written as loops; no clip on a dial, as his (the page's row bounds them).
			//     WHAT HIS CODE DOES, kept on purpose — the cleaned path below differs exactly here:
			//       · SinOsc.kr(rrand(0.07, 0.013)): the LANGUAGE's rrand, on two numbers — the 26 wobble rates are drawn ONCE, when this
			//         SynthDef is built (once per engine start), and are the same in every render; all 26 wobbles start at phase 0.
			//       · rrand(ringL1, ringL2): on two CONTROLS it is the SERVER's rrand — a new value at EVERY CONTROL BLOCK (measured, §151).
			//         Every resonator's ring time flickers between the two 750 times a second, so all 26 ring down together at ONE
			//         effective time (7 … 15 s → about 10.5 s) — not 26 different rings.
			poTuneA = { |partialNum|
				var freq, freqMidi, tuner, freqTunedMidi;
				freq = poFund * (poFirst + (poSpread * partialNum));
				freqMidi = freq.cpsmidi;
				tuner = SinOsc.kr(rrand(0.07, 0.013), 0, 0.5);
				freqTunedMidi = freqMidi + tuner;
				freqTunedMidi.midicps
			};
			poTuneB = { |partialNum|
				var freq, freqMidi, tuner, freqTunedMidi;
				freq = poFund * (poFirst + (poSpread * partialNum));
				freqMidi = freq.cpsmidi;
				tuner = SinOsc.kr(rrand(0.07, 0.013), 0, 0.5);
				freqTunedMidi = freqMidi + tuner + poOffset;
				freqTunedMidi.midicps
			};
			poPa = 13.collect({ |i| poTuneA.value(i) });
			poPb = 13.collect({ |i| poTuneB.value(i) });
			poIn = sig * 1.0 * EnvGen.ar(Env.perc(0.02, poInLen, 1.0, -1), 1);
			poRes = (poPa ++ poPb).collect({ |p| DynKlank.ar(`[[p], nil, [rrand(poRingLo, poRingHi)]], poIn) });
			poOut = Mix.ar((poRes * -40.dbamp).scramble);
			poOut = Limiter.ar(poOut, 0.98, 0.01) * EnvGen.ar(Env.linen(0.01, poRingHi, 0.3), 1);
			sig = mix.(sig, poOut, poMix);
			// --- THE PETALS OF RESONANCE — THE CLEANED PATH (DEC-32): the same instrument and the same dials, the signal path tidied —
			//       · ONE bank of 26 Ringz, summed (a DynKlank of one partial IS a Ringz); no shuffle (it does nothing to a mono mix)
			//       · each partial's wobble rate (0.013 … 0.07 Hz) and its START PHASE drawn PER RENDER (Rand — an offline render is seeded
			//         by the clock, measured §151): his 2025 note, "a new set … for every synth instance"
			//       · each partial's RING drawn ONCE per render between ring lo and ring hi — 26 different rings, as rrand(ringL1, ringL2)
			//         reads: the chord thins out partial by partial instead of sinking as one
			//       · no limiter, no fade: the render is floating point and its ending is the engine's (tail: to -60 dB, or the cap)
			//       · NO FADE-IN on the input (his word 2026-10-06, the Decibel piece's §152): his 20 ms rise was the microphone's gate, and
			//         it softened the first 20 ms of what excites the bank — here the sound enters as it is. The fall over inputLen (his
			//         curve, -1) is kept: how long the bank listens.
			ptIn = sig * EnvGen.ar(Env([1, 0], [ptInLen.clip(0.02, 20)], -1), 1);
			ptBase = 13.collect({ |n| (ptFund.clip(20, 400) * (ptFirst.clip(1, 8) + (ptSpread.clip(0.05, 3) * n))).cpsmidi });
			ptTuned = (ptBase ++ (ptBase + ptOffset.clip(0, 12))).collect({ |m| (m + SinOsc.kr(Rand(0.013, 0.07), Rand(0, 2pi), 0.5)).midicps.clip(20, 18000) });
			ptLo = ptRingLo.clip(0.1, 30); ptHi = ptRingHi.clip(0.1, 30);
			ptRings = ptTuned.collect({ ptLo + ((ptHi - ptLo) * Rand(0, 1)) });
			pt = Ringz.ar(ptIn, ptTuned, ptRings).sum * -40.dbamp;
			sig = mix.(sig, pt, ptMix);
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
			// --- feedback (DEC-18 · DEC-19): the slap held to the amp — a LOOP of six strings, the amp's clipping, a speaker's colour
			//     and the path to the amp; the strings the impulse excites most win and BLOOM, limited by the clipping, sing for fbHold s,
			//     then the loop is broken and they ring down. fbBloom is the TIME to grow 60 dB: the loop gain is set from it and the
			//     round trip (a real feedback's gain is barely above 1 — set as a gain it is unplayable). Each string is a comb at 1/f with
			//     its resonance brought to unity, so the loop gain IS the bloom. No strings (all six at 0) = the material's own spectrum.
			fbRt = (fbPath.clip(1, 50) / 1000) + (64 / SampleRate.ir);
			fbProg = (Sweep.kr(0, 1) / fbHold.clip(0.01, 20)).clip(0, 1);
			fbGain = (60 * fbRt / fbBloom.clip(0.05, 10)).dbamp * EnvGen.kr(Env([1, 1, 0.25], [fbHold.clip(0, 20), 0.6], \lin));
			fbIn = LocalIn.ar(1);
			fbExc = sig + fbIn;
			fbStr = [fbS1, fbS2, fbS3, fbS4, fbS5, fbS6].collect({ |f|
				var on = f > 0, d = 1 / f.max(20);
				CombC.ar(fbExc * on, 0.05, d, 1.5) * (1 - 10.pow(-3 * d / 1.5)) * on   // the string: it rings 1.5 s; its resonance at unity gain
			}).sum * 0.5;
			fbNone = (fbS1 + fbS2 + fbS3 + fbS4 + fbS5 + fbS6) <= 0;
			fbStr = Select.ar(fbNone, [fbStr, fbExc]);
			fbAmp = (fbStr * fbDrive.clip(1, 40)).tanh / fbDrive.clip(1, 40);   // the amp: unity for small signals, a ceiling for large — what the bloom meets
			fbToneNow = (fbTone.clip(500, 8000) * (1 + (fbClimb.clip(0, 1) * 3 * fbProg))).clip(200, 16000);   // the climb: the colour rises over the hold
			fbCol = HPF.ar(LPF.ar(fbAmp, fbToneNow), 120);
			fbPathNow = (fbPath.clip(1, 50) / 1000) * (1 - (0.4 * fbClimb.clip(0, 1) * fbProg)) * (1 + (0.2 * fbWobble.clip(0, 1) * LFNoise1.kr(1.5)));
			LocalOut.ar(DelayC.ar(fbCol, 0.06, fbPathNow.clip(0.0005, 0.06)) * fbGain);
			// --- EVERY STRING SINGS (fbOwn 1 — the Decibel piece's DEC-32 · RUNNING_LOG §151; the engine's §40). MEASURED there: in the
			//     loop above a string alone has a loop gain of 0.5 — it can only ring down. The loop takes off where TWO strings share a
			//     harmonic (the open guitar's two E's) AND the path's phase agrees; on a chord whose notes share nothing (a cluster, any
			//     chord with no octave in it) nothing blooms: 54 chords rendered, none held. So, for a CHORD, the loop's RESULT is made
			//     without its lottery, under the same dials:
			//       · each string is a comb that barely decays — it keeps what the sound gave it: which of its harmonics, and how much
			//       · the BLOOM is the gain a loop would have given it: 60 dB in fbBloom s, from that level — so the strings the sound
			//         excites most arrive first, and a string it barely touched arrives late, or not before the hold ends
			//       · the CEILING is the amp, one per string (the chord stays a chord: no string is clipped by another): a singing string
			//         sits fbDrive / 4 into the tanh — drive 4 is mild, 12 is hard
			//       · tone · climb · hold as above; then the strings ring down 1.5 s. wobble: each string drifts in pitch by itself (± 5
			//         cents at 1), so a chord's beating moves. path does nothing here — there is no loop.
			//     With no string at all (all six at 0) it is the loop above, whatever fbOwn says.
			fbRise = (60 * Sweep.kr(0, 1) / fbBloom.clip(0.05, 10)).min(120).dbamp;
			fbKnee = (fbDrive.clip(1, 40) / 4).clip(0.5, 10);
			fbCount = [fbS1, fbS2, fbS3, fbS4, fbS5, fbS6].collect({ |f| f > 0 }).sum.max(1);
			fbOwnSig = [fbS1, fbS2, fbS3, fbS4, fbS5, fbS6].collect({ |f|
				var on = f > 0, d = (1 / f.max(20)) * (1 + (0.003 * fbWobble.clip(0, 1) * LFNoise1.kr(0.7)));
				var str = CombC.ar(sig * on, 0.06, d.clip(0.0004, 0.06), 100) * (1 - 10.pow(-3 * d / 1.5));   // at the level of the loop's string (above): the bloom starts where the loop's would
				var lvl = Amplitude.ar(str, 0.01, 0.3);
				var g = fbRise.min(fbKnee / (lvl * fbDrive.clip(1, 40)).max(0.000001));
				(str * g * fbDrive.clip(1, 40)).tanh / fbDrive.clip(1, 40) * on
			}).sum / fbCount.sqrt;
			fbOwnSig = HPF.ar(LPF.ar(fbOwnSig, fbToneNow), 120) * EnvGen.kr(Env([1, 1, 0.001, 0.00001], [fbHold.clip(0.01, 20), 1.5, 0.5], \exp));
			fbCol = Select.ar((fbOwn > 0.5) * (1 - fbNone), [fbCol, fbOwnSig]);
			sig = mix.(sig, fbCol * 2, fbMix);
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
			// --- granular freeze — THE CLOUD (the first granular voice, 10.2; the Decibel piece's §120, 2026-10-05): the signal so far is
			//     written into a buffer while the source plays (then the writing stops — the moment is never overwritten); from gfAtMs on,
			//     long overlapping Hann grains (gfDur ms, gfDens a second, asynchronous — Dust) begin at that moment ± gfSpread ms, each at
			//     a random pitch within ± gfPitch semitones. The sound is HELD by many offset readings of one place, not by a held
			//     snapshot re-synthesised — so nothing repeats at a frame rate. After the sandbox's \roadsCloudBuf (roads-cloud.scd):
			//     the level compensated by 1/sqrt(overlap), so density is texture, not loudness. Until the first grains, the dry sound.
			gfBufL = LocalBuf(SampleRate.ir * 4).clear;
			gfW = Phasor.ar(0, 1 - Done.kr(play), 0, BufFrames.ir(gfBufL));
			BufWr.ar(sig, gfBufL, gfW, 0);
			gfD = gfDur.clip(20, 2000) / 1000;
			gfOn = (gfMix > 0) * (Sweep.kr(0, 1) >= ((gfAtMs.clip(0, 3000) / 1000) + (gfD * 0.5)));   // the first grains need written material
			gfTrig = Dust.ar(gfDens.clip(1, 400)) * gfOn;
			gfOv = (gfDens.clip(1, 400) * gfD).max(1);
			gfPos = (((gfAtMs.clip(0, 3000) + TRand.ar(gfSpread.clip(0, 500).neg, gfSpread.clip(0, 500), gfTrig)) / 1000 * SampleRate.ir) / BufFrames.ir(gfBufL)).clip(0, 1);
			gfRate = 2 ** (TRand.ar(gfPitch.clip(0, 24).neg, gfPitch.clip(0, 24), gfTrig) / 12);
			gfCloud = GrainBuf.ar(1, gfTrig, gfD, gfBufL, gfRate, gfPos, 2, 0, -1, 512) * gfOv.sqrt.reciprocal;
			sig = mix.(sig, gfCloud, gfMix * Lag.kr(gfOn, 0.05));
			// --- icy — HIS FREEZE (github.com/elosine/freeze, 2015 … 2016: \icy · \icy_live · \icy_s; the Decibel piece's §122): Warp1 over
			//     the same buffer the cloud writes — LONG windows (0.6 … 0.8 s), MANY overlapping grains (17 … 40), each window's place
			//     randomised a little, and the read point CRAWLING from icFromMs at icSpeed of real time (0 = held there; 0.03 = thirty times
			//     slower); the grain window one of his ten (grainEnv/, read into buffers 1 … 10 by the render; expodec his favourite) or
			//     Warp1's own Hann (0). A STRETCH, not a snapshot: the sound moves. It ends where the material does. Level by 1/sqrt(overlaps).
			//     §124 (his ear: "an attack, then a gap, then the frozen sustain"; "quiet"): the stretch runs FROM THE START, its windows
			//     filling as the material is written — it swells in under the attack, no gap; the mix is the whole story: 1 = the stretch
			//     alone (the attack suppressed, the peak-match then lifts the sustain to the source's peak) · 0.5 = attack and sustain
			//     together · 0 = the sample as it is. The read point waits at icFromMs until the sound reaches it, then crawls.
			icWr = gfW / SampleRate.ir;   // seconds of material written so far: the read point never runs ahead of it
			icOn = Sweep.kr(0, 1) >= (icFromMs.clip(0, 3000) / 1000);
			icPtr = ((icFromMs.clip(0, 3000) / 1000) + Sweep.kr(icOn, icSpeed.clip(0, 4))).min(icWr) / (BufFrames.ir(gfBufL) / SampleRate.ir);
			icEnvBuf = Select.kr(icEnv.clip(0, 10), [-1] ++ (1..10));
			icSig = Warp1.ar(1, gfBufL, icPtr, 2 ** (icPitch.clip(-24, 24) / 12), icWin.clip(0.05, 2), icEnvBuf, icOverlaps.clip(1, 64), icRand.clip(0, 1), 2)
				* icOverlaps.clip(1, 64).sqrt.reciprocal;
			sig = mix.(sig, icSig, icMix);
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
// A dial may be a LINE,  name:value@ms,value@ms  (11.4): its first value is the dial's start; the breakpoints come back in `lines`.
~le[\processArgs] = { |self, text|
	var names = self.processDef.allControlNames.collect({ |c| c.name }), args = List.new, unknown = List.new, lines = List.new, cur;
	var point = { |t| var p = t.asString.stripWhiteSpace.split($@); [p[0].asString.asFloat, if(p.size > 1) { p[1].asString.asFloat.max(0) } { 0 }] };
	(text ? "").asString.split($,).do({ |kv|
		var b = kv.asString.stripWhiteSpace.split($:), k, first;
		if(b.size == 2) {
			k = b[0].asString.stripWhiteSpace.asSymbol;
			cur = nil;
			if(names.includes(k) and: { (k != \buf) and: { k != \out } and: { k != \srcAmp } }) {
				if(b[1].asString.includes($@)) {
					first = point.(b[1]);
					cur = (key: k, pts: List[first]);
					lines.add(cur);
					args.add(k); args.add(first[0]);
				} { args.add(k); args.add(b[1].asString.asFloat) };
			} { unknown.add(k) };
		} {
			// a line's further breakpoints: "fbDrive:2@0,8@6000" arrives here as "fbDrive:2@0" and then "8@6000"
			if((b.size == 1) and: { cur.notNil } and: { b[0].asString.includes($@) }) { cur[\pts].add(point.(b[0])) };
		};
	});
	(args: args.asArray, unknown: unknown.asArray, lines: lines.asArray)
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
	var endMode, srcPath, sf, sr, srcData, srcPeak, parsed, args, argsText, rate = 1, total, lead = 0.02, oscPath, nrtPath, opts, score, envPaths;
	var lineText = IdentityDictionary.new, steps = List.new, driveMode, driveDb = 0, driveHeld = false, srcLoud;
	var endModes = ["shape", "tail", "perc", "gauss", "quasi", "tri", "expodec", "rexpodec"];
	var durX = (d[\durX] ? 0).asString.asFloat;
	lim.keysValuesDo({ |k, r| if(d[k].notNil) { o[k] = d[k].asString.asFloat.clip(r[0], r[1]) } });
	if(d[\planned].notNil) { o[\planned] = 1 };   // a variant of the plan: its row says so
	endMode = (d[\end] ? o[\end]).asString;
	if(endModes.detect({ |m| m == endMode }).isNil) { endMode = "tail" };   // compared by content (§94)
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
			parsed[\lines].do({ |ln| lineText[ln[\key]] = ln[\pts].collect({ |p| p[0].asString ++ "@" ++ p[1].round(1).asInteger }).join(",") });
			argsText = args.clump(2).collect({ |p| p[0].asString ++ ":" ++ (lineText[p[0]] ? p[1]) }).join(",");
			// THE DRIVE (11.4): a gain on the source before the chain — measured HERE, on the samples in hand (a row may have no figure yet)
			driveMode = (d[\srcDrive] ? if(d[\planned].notNil) { "normalized" } { "played" }).asString.stripWhiteSpace;
			if(driveMode == "normalized") {
				srcLoud = if(self[\loudOf].notNil) { try { self.loudOf(srcData, sr) } { nil } };
				driveDb = if(srcLoud.notNil and: { srcLoud[\loudDb] > -100 }) { self.levelOf[\driveRef] - srcLoud[\loudDb] } { 0 };
			} {
				if(driveMode != "played") { driveDb = driveMode.asFloat.clip(-60, 40) };
			};
			if((srcPeak > 0) and: { (srcPeak.ampdb + driveDb) > -1 }) { driveDb = -1 - srcPeak.ampdb; driveHeld = true };
			// said in the window and kept in the row — unless the source went in as it is, which is nothing to say
				o[\driveText] = if((driveMode == "played") and: { driveDb == 0 }) { nil } { driveMode ++ " " ++ if(driveDb >= 0) { "+" } { "" } ++ driveDb.round(0.1) ++ " dB" ++ if(driveHeld) { " (held under full scale)" } { "" } };
			args.clump(2).do({ |p| if(p[0] == \rate) { rate = p[1].abs.clip(0.05, 8) } });
			// durX: the envelope's length as a multiple of the source's own — of what the effect makes of it, when the tape's speed changes it
			if(durX > 0) { o[\durMs] = (srcData.size / sr / rate * 1000 * durX).clip(lim[\durMs][0], lim[\durMs][1]) };
			// shape: the object's length and room for the head · tail: the source, then the cap
			total = if(endMode != "tail") { (o[\durMs] / 1000) + 0.5 } { (srcData.size / sr / rate) + (o[\capMs] / 1000) };
			File.mkdir(dir +/+ "raw");
			oscPath = dir +/+ "raw" +/+ out ++ ".osc";
			nrtPath = dir +/+ "raw" +/+ out ++ ".nrt.wav";
			if(File.exists(nrtPath)) { File.delete(nrtPath) };   // a render that fails must not be mistaken for the one before it
			opts = ServerOptions.new.numOutputBusChannels_(1).memSize_(131072).numWireBufs_(256);
			// his ten grain windows (grainEnv/gEnv_*.aif, §122) into buffers 1 … 10, in name order — the icy stage picks one by number
			envPaths = (self[\dir] +/+ "grainEnv" +/+ "gEnv_*.aif").pathMatch.sort;
			// a dial as a line: stepped along its breakpoints every 50 ms, from the render's start (the chain's lag smooths the steps)
			parsed[\lines].do({ |ln|
				var pts = ln[\pts].asArray.sort({ |a, b| a[1] < b[1] });
				(pts.size - 1).do({ |i|
					var p = pts[i], q = pts[i + 1], t = p[1] + 50, span = (q[1] - p[1]).max(1);
					while { t < q[1] } { steps.add([lead + (t / 1000), ['/n_set', 1000, ln[\key], p[0] + ((q[0] - p[0]) * ((t - p[1]) / span))]]); t = t + 50 };
					steps.add([lead + (q[1] / 1000), ['/n_set', 1000, ln[\key], q[0]]]);
				});
			});
			steps = steps.select({ |x| (x[0] > lead) and: { x[0] < (lead + total) } }).sort({ |a, b| a[0] < b[0] });
			score = Score([
				[0.0, ['/d_recv', self.processDef.asBytes]],
				[0.0, ['/b_allocRead', 0, srcPath, 0, 0]]
			] ++ envPaths.collect({ |p, i| [0.0, ['/b_allocRead', i + 1, p, 0, 0]] }) ++ [
				[lead, ['/s_new', \leProcess, 1000, 0, 0, \buf, 0, \out, 0, \srcAmp, driveDb.dbamp] ++ args]
			] ++ steps.asArray ++ [
				[lead + total, ['/c_set', 0, 0]]
			]);
			self[\processBusy].add(out.asSymbol);
			self.say("LE_INFO", "process · " ++ out ++ " ← " ++ src ++ " · " ++ effect ++ " · " ++ endMode ++ " · rendering " ++ total.round(0.01) ++ " s offline"
					++ if(o[\driveText].notNil) { " · driven " ++ o[\driveText] } { "" }
					++ if(parsed[\lines].size > 0) { " · " ++ parsed[\lines].size ++ " dial" ++ if(parsed[\lines].size > 1) { "s" } { "" } ++ " on a line" } { "" }
				++ if(parsed[\unknown].size > 0) { " · NOT in the chain, left out: " ++ parsed[\unknown].join(", ") } { "" });
			score.recordNRT(oscPath, nrtPath, nil, sr, "WAV", "float", opts, "", nil, { |code|
				self[\processBusy].remove(out.asSymbol);
				try { self.processDone(o, src, out, id, effect, argsText, endMode, sr, srcPeak, nrtPath, oscPath, code) } { |err|
					self.say("LE_ERROR", "process · " ++ out ++ " — the render was made and could not be banked · " ++ err.errorString);
					self.say("LE_RESULT", self.json((msg: "processed", name: out, source: src, openingId: id, failed: true)));
				};
				if(self[\planNext].notNil) { self.planNext };   // a render has ended: the plan's queue may start its next
			});
		};
	};
	self
};

// the rendered file -> the sample: its start found, its end made (shape | tail), its level set, written, indexed, loaded
~le[\processDone] = { |self, o, src, out, id, effect, argsText, endMode, sr, srcPeak, nrtPath, oscPath, code|
	var s = self[\server], dir = self[\bankDir], rel = out ++ ".wav", sf = SoundFile.new;
	var data, peak, thr, head, last, start, stop, n, take, nA, nR, c, g, outPeak, fadeMs, capped = false, held = false, srcRow, row, old, lenMs, mode, loud;
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
		if(endMode != "tail") {
			n = (o[\durMs] / 1000 * sr).round.asInteger.max(1);
			take = data.copyRange(start, (start + n - 1).min(data.size - 1));
			if(take.size < n) { take = take ++ FloatArray.newClear(n - take.size) };
			if(endMode == "shape") {
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
				// the fixed curves (§111): perc — Env.perc, atkMs up and the rest down, both on curve -4 · gauss — a bell, sigma 0.15 of the
				// length · quasi — Gaussian sides (a quarter each) over a flat middle · tri — a triangle · expodec — an exponential fall to
				// -60 dB at the end · rexpodec — its mirror, a rise to full then a cut. The mode as a Symbol: switch compares by identity.
				mode = endMode.asSymbol;
				nA = (o[\atkMs] / 1000 * sr).round.asInteger.clip(1, n);
				n.do({ |i|
					var pos = i / n, lvl;
					lvl = switch(mode,
						\perc, { if(i < nA) { (1 - exp(i / nA * -4)) / (1 - exp(-4)) } { var p = (i - nA) / (n - nA).max(1); 1 - ((1 - exp(p * -4)) / (1 - exp(-4))) } },
						\gauss, { exp(-0.5 * (((pos - 0.5) / 0.15) ** 2)) },
						\quasi, { if(pos < 0.25) { exp(-0.5 * (((0.25 - pos) / 0.0833) ** 2)) } { if(pos > 0.75) { exp(-0.5 * (((pos - 0.75) / 0.0833) ** 2)) } { 1 } } },
						\tri, { if(pos < 0.5) { 2 * pos } { 2 * (1 - pos) } },
						\expodec, { exp(pos * -6.9078) },
						\rexpodec, { exp((1 - pos) * -6.9078) },
						{ 1 });
					take[i] = take[i] * lvl;
				});
			};
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
			loud = if(self[\loudOf].notNil) { try { self.loudOf(take, sr) } { nil } };   // 11.1: how loud the render is (level.scd)
			if(self[\indexRows].isNil) { self[\indexRows] = List.new };
			srcRow = self[\indexRows].detect({ |r| r[\name].asString == src });
			row = (id: "prc_" ++ self.nowIso.select({ |ch| ch.isDecDigit }), name: out,
				player: if(srcRow.notNil) { (srcRow[\player] ? "").asString } { "" }, lane: if(srcRow.notNil) { (srcRow[\lane] ? -1).asInteger } { -1 },
				category: "processed", scoreTime: 0, lengthMs: lenMs, peakDb: self.db(outPeak), file: rel, raw: "raw/" ++ out ++ ".nrt.wav",
				openingId: id, windowMs: 0, attackMs: (head / sr * 1000).round(0.1), captured: self.nowIso,
				kind: "processed", source: src, effect: effect, args: argsText, end: endMode);
			if(loud.notNil) { self.loudInto(row, loud) };
			if(o[\driveText].notNil) { row[\drive] = o[\driveText] };
			if(o[\planned].notNil) { row[\planned] = 1 };   // a variant of the plan (below): a page keeps it out of its pickers
			self[\indexRows] = self[\indexRows].reject({ |r| r[\name].asString == out }).asList;   // a List: add() in place (bank.scd, §84)
			self[\indexRows].add(row);
			if(self.indexWrite.not) { self.say("LE_INFO", "the index was NOT written — the sample is saved as " ++ rel) };
			old = if(self[\samples].notNil) { self[\samples][out.asSymbol] };
			if(s.notNil and: { s.serverRunning }) {
				Buffer.read(s, dir +/+ rel, action: { |b|
					if(self[\samples].isNil) { self[\samples] = IdentityDictionary.new };
					self[\samples][out.asSymbol] = (row: row, buf: b, from: \processed);
					if(self[\planStale].notNil) { self[\planStale].remove(out.asSymbol) };   // this take's render is in the buffer now
					if(old.notNil and: { old[\buf].notNil }) { SystemClock.sched(10, { old[\buf].free; nil }) };
				});
			} {
				if(self[\planStale].notNil) { self[\planStale].remove(out.asSymbol) };
			};
			self.say("LE_INFO", "processed · " ++ out ++ " ← " ++ src ++ " · " ++ effect ++ " · " ++ endMode ++ " · " ++ lenMs.round(1).asInteger ++ " ms · peak " ++ self.db(outPeak) ++ " dB"
				++ if(loud.notNil) { " · loud " ++ loud[\loudDb] ++ " LUFS" } { "" }
				++ if(capped) { " · STILL SOUNDING at the cap: faded" } { "" } ++ if(held) { " · held under full scale" } { "" }
				++ if(old.notNil) { " · REPLACES the earlier render" } { "" });
			self.say("LE_RESULT", self.json(row.copy.putAll((msg: "processed", capped: capped, held: held, replaced: old.notNil))));
		};
	};
	self
};

// ---- THE PLAN: the variants a score will ask for, rendered as soon as their sample is captured (the header has the messages) --------
~le[\planWidth] = 2;   // how many renders may run at once: each is a second scsynth, beside a performance

// /le/plan — one PART of a plan. The parts share a stamp and may arrive in any order (each is its own HTTP request and its own
// datagram); the plan in force changes only when the last one is in.
~le[\planTake] = { |self, d|
	var stamp = (d[\stamp] ? "").asString, part = (d[\part] ? 1).asInteger.max(1), of = (d[\of] ? 1).asInteger.max(1);
	var rows = List.new, all, render;
	(d[\rows] ? "").asString.split($|).do({ |line|
		var f = line.asString.split($;);
		if(f.size >= 10) {
			rows.add((base: self.safeName(f[0]), suffix: self.safeName(f[1]), effect: f[2].asString, end: f[3].asString,
				atkMs: f[4].asString.asFloat, durX: f[5].asString.asFloat, match: f[6].asString.asInteger, t: f[7].asString.asFloat,
				capMs: f[8].asString.asFloat, args: f[9].asString, drive: if(f.size > 10) { f[10].asString.stripWhiteSpace } { "" }));
		};
	});
	if(self[\planIn].isNil or: { self[\planIn][\stamp] != stamp }) { self[\planIn] = (stamp: stamp, parts: IdentityDictionary.new, render: false) };
	self[\planIn][\parts][part] = rows;
	if((d[\render] ? 0).asInteger > 0) { self[\planIn][\render] = true };
	if(self[\planIn][\parts].size >= of) {
		all = List.new;
		of.do({ |i| all.addAll(self[\planIn][\parts][i + 1] ? []) });
		render = self[\planIn][\render];
		self[\planIn] = nil;
		self[\plan] = all.reject({ |r| (r[\base].size == 0) or: { r[\suffix].size == 0 } }).asArray.sort({ |a, b| a[\t] <= b[\t] });   // soonest-needed first
		self.say("LE_INFO", "plan · " ++ self[\plan].size ++ " variants of " ++ self[\plan].collect({ |r| r[\base] }).asSet.size ++ " samples"
			++ if(self[\plan].size == 0) { " — every return plays its sample as it is" } { "" });
		if(render) { self.planRenderAll };
	};
	self
};

// a variant into the queue (once: a second asking replaces the first). If a buffer already holds this name it is an EARLIER take's
// render from now until the new one lands — sampleFor (bank.scd) says so when it is played.
~le[\planAdd] = { |self, r|
	var out = r[\base] ++ "~" ++ r[\suffix];
	if(self[\planQueue].isNil) { self[\planQueue] = List.new };
	if(self[\planStale].isNil) { self[\planStale] = IdentitySet.new };
	self[\planQueue] = self[\planQueue].reject({ |q| q[\out] == out }).asList;
	self[\planQueue].add((out: out, row: r));
	if(self[\samples].notNil and: { self[\samples][out.asSymbol].notNil }) { self[\planStale].add(out.asSymbol) };
	out
};

// the next renders, the soonest-needed first, while a slot is free; called when a variant is queued and when any render ends
~le[\planNext] = { |self|
	var q, r, m;
	if(self[\planQueue].notNil and: { self[\planQueue].size > 0 }) {
		self[\planQueue] = self[\planQueue].asArray.sort({ |a, b| a[\row][\t] <= b[\row][\t] }).asList;
		while { (self[\planQueue].size > 0) and: { self[\processBusy].size < self[\planWidth] } } {
			q = self[\planQueue].removeAt(0);
			r = q[\row];
			m = (source: r[\base], out: q[\out], effect: r[\effect], args: r[\args], end: r[\end], atkMs: r[\atkMs], durX: r[\durX],
				match: r[\match], id: "plan", planned: 1);
			if(r[\capMs] > 0) { m[\capMs] = r[\capMs] };
			if(r[\drive].notNil and: { r[\drive].size > 0 }) { m[\srcDrive] = r[\drive] };   // absent: a plan's variant is driven normalized (processRender)
			self.processRender(m);
		};
	};
	self
};

// a sample has just been captured: its planned variants, from THIS take (bank.scd captureDone calls it)
~le[\planRender] = { |self, base|
	var b = (base ? "").asString, rows = (self[\plan] ? []).select({ |r| r[\base] == b });
	if(rows.size > 0) {
		rows.do({ |r| self.planAdd(r) });
		self.say("LE_INFO", "plan · " ++ b ++ " — " ++ rows.size ++ if(rows.size == 1) { " variant" } { " variants" } ++ " to render: " ++ rows.collect({ |r| r[\suffix] }).join(" · "));
		self.planNext;
	};
	rows.size
};

// /le/planrender — every planned variant whose sample is in the bank, again: the simulation's button, and a way to hear a changed
// preset without a pass through the openings
~le[\planRenderAll] = { |self|
	var rows = (self[\plan] ? []), have = rows.select({ |r| self.processFile(r[\base]).notNil }), wait = rows.size - have.size;
	have.do({ |r| self.planAdd(r) });
	self.say("LE_INFO", "plan · render all — " ++ have.size ++ " of " ++ rows.size ++ " planned variants queued"
		++ if(wait > 0) { " · " ++ wait ++ " wait for their sample's capture" } { "" });
	self.planNext;
	have.size
};
)
