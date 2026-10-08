// synths.scd — the engine's basic machinery (the engine plan's 4.1 d). Loaded by boot.scd once the server is up.
//
// leIn       one player's microphone: a hardware input onto the player's own bus — THE INPUT CHAIN (the engine plan's part 13;
//            the Decibel piece's 11.7 a): amp, the trim (the preamp) · a high-pass (hpfOn · hpfFreq) · two bands of corrective EQ
//            (eq1On · eq1Freq · eq1Db · eq1Rq, eq2…). Every stage is switched: all off and amp 1, the bus holds the input sample
//            for sample. The numbers are a VENUE's — a piece gives them at the start (LE_VENUE, session.scd).
// lePass     a player's bus to the master, untouched — dual mono at unity.
// leEcho     a player's bus to the master, LATER: the same sound `time` seconds behind. A LISTENING AID — a pass-through
//            returns two DAW blocks after the note and is not heard as a second sound; one second behind, it is.
// leMaster   THE OUTPUT: the master bus to the hardware — A MASTERING BUS, LIVE (part 13; the Decibel piece's 11.6), in this order:
//              high-pass     hpfOn · hpfFreq (30)                       switched; off = not in the path
//              low-pass      lpfOn · lpfFreq                            switched; off = not in the path
//              the glue      a feed-forward COMPRESSOR: an RMS detector over 30 ms on both channels together, a gain computer
//                            in decibels with a SOFT KNEE (glueThr −18 · glueRatio 2 · glueKnee 6), the gain moved by
//                            glueAtk 0.03 · glueRel 0.25, glueGain on top; switched by glueOn. Under its knee it multiplies by
//                            exactly 1.
//              the limiter   LOOK-AHEAD, both channels as one: the louder channel's peak over the next `lookahead` (5 ms) sets
//                            ONE gain for both, smoothed over 4 ms and released over limRel (0.1 s). It cannot overshoot: every
//                            gain it averages is small enough for the sample it meets (the window it looks over is longer than
//                            the smoothing, and the delay lies between them). Under the ceiling (ceilDb, −1) its gain is exactly 1.
//                            IT DELAYS THE BUS BY `lookahead` — the engine plays its samples that much EARLY (bank.scd samplePlay,
//                            ~le[\masterDelay]) so a return still lands where its brick is. `lookahead` is taken when the synth
//                            is made; the rest are dials, moved while it runs (boot.scd masterSet · /le/master).
//              the clip      at full scale, last, that nothing passes.
//            The ceiling is a SAMPLE's peak; the decibel above it is room for what lies between the samples.
//            With every switch off a signal under the ceiling leaves exactly as it arrived, `lookahead` later (bus_test.scd).
//            The numbers are the sandbox's ensemble bus (live-electronics-engine/engine/playhead-engine.js) as a START — the
//            composer's ear moves them; the sandbox's reverb and tape sends are not ported, they came with the effects.
// leLoudness THE METER on what was sent: momentary loudness (BS.1770's K-weighting in two second-order sections, 400 ms) and
//            TRUE PEAK (the samples and three points between each pair, by an 8-tap windowed sinc) — the loudest of each half
//            second to '/le/loud' (boot.scd loudOn). ~le.loudGraph is the reading itself, shared with bus_test.scd.
// leTone     a sine on both channels for `dur` seconds, then gone: the line-up tone a house asks for (boot.scd toneOut).
// leMeter1/2 a bus's peak, twenty times a second, to '/le/meter'.
// leLatency  a click out and a listener in: the seconds between them, to '/le/latency' (latency.scd).
// leOnset    a rise out of silence on a bus, told ONCE to '/le/heard' — when a player's sound arrives (boot.scd § the onset probe).
// leCapture  a player's bus into a buffer, ONCE, from the moment it starts until the buffer is full; then it frees itself (bank.scd).
// leSample   a buffer to the master, ONCE, dual mono; then it frees itself (bank.scd). At UNITY — as loud as it was captured —
//            unless it is given a DYNAMIC: envDb (8 levels, dB of gain) over envDt (7 times, s) on envCurve — a flat level, a
//            hairpin, a step, a line (level.scd levelFor makes them from a brick's marks). The levels are joined IN DECIBELS:
//            curve 0 is an even hairpin to the ear. All at 0 dB it multiplies by exactly 1.
// leSine     A GENERATED VOICE (sine.scd; first built in the Decibel piece, 2026-10-06): a sine to the master, dual mono, for
//            `dur` seconds, then it frees itself. Its LEVEL is a line — envDb (8 levels, dB of its PEAK) over envDt (7 times, s)
//            on envCurve, joined in decibels as leSample's is; its PITCH is `freq` moved by a line of CENTS — glissCents (8)
//            over glissDt (7), straight in cents (an even glide to the ear), at audio rate. A 10 ms rise and a 30 ms fall
//            stand under both, so it never clicks. sine.scd makes the lines from a brick's marks (sineSpec).
// lePetalsLive  A PLAYER'S MICROPHONE INTO THE PETALS OF RESONANCE, LIVE (petals_live.scd; first built in the Decibel piece, 2026-10-07):
//            the player's bus through a window, the composer's bank of 26 resonators ringing on, to the master, dual mono; it frees
//            itself. Its level is leSample's envelope, set when the return's message comes; silent until then.
(
SynthDef(\leIn, { |in = 0, out = 0, amp = 1, hpfOn = 0, hpfFreq = 90, eq1On = 0, eq1Freq = 250, eq1Db = 0, eq1Rq = 1, eq2On = 0, eq2Freq = 3000, eq2Db = 0, eq2Rq = 1|
	var sig = In.ar(in, 1) * amp, x;
	x = HPF.ar(sig, hpfFreq.clip(10, 2000)); sig = (x * hpfOn) + (sig * (1 - hpfOn));
	x = BPeakEQ.ar(sig, eq1Freq.clip(20, 18000), eq1Rq.clip(0.1, 10), eq1Db.clip(-24, 24)); sig = (x * eq1On) + (sig * (1 - eq1On));
	x = BPeakEQ.ar(sig, eq2Freq.clip(20, 18000), eq2Rq.clip(0.1, 10), eq2Db.clip(-24, 24)); sig = (x * eq2On) + (sig * (1 - eq2On));
	Out.ar(out, sig);
}).add;

SynthDef(\lePass, { |in = 0, out = 0, amp = 1|
	var sig = In.ar(in, 1) * amp;
	Out.ar(out, [sig, sig]);
}).add;

SynthDef(\leEcho, { |in = 0, out = 0, amp = 1, time = 1|
	var sig = DelayN.ar(In.ar(in, 1), 4, time) * amp;
	Out.ar(out, [sig, sig]);
}).add;

SynthDef(\leMaster, { |in = 0, out = 0, amp = 1, hpfOn = 0, hpfFreq = 30, lpfOn = 0, lpfFreq = 20000,
		glueOn = 0, glueThr = -18, glueRatio = 2, glueKnee = 6, glueAtk = 0.03, glueRel = 0.25, glueGain = 0, ceilDb = -1, limRel = 0.1|
	var la = \lookahead.ir(0.005);
	var sig, x, nRms, pw, over, t, gr, m, h, s, gt, nBox, g;
	sig = In.ar(in, 2) * amp;
	x = HPF.ar(sig, hpfFreq.clip(10, 1000)); sig = (x * hpfOn) + (sig * (1 - hpfOn));
	x = LPF.ar(sig, lpfFreq.clip(200, 20000)); sig = (x * lpfOn) + (sig * (1 - lpfOn));
	// the glue: how far the bus's RMS stands over the threshold, bent by the knee, times (1/ratio − 1) = the decibels to take off
	nRms = (0.03 * SampleRate.ir).round.max(1);
	pw = RunningSum.ar((sig[0].squared + sig[1].squared) * 0.5, nRms) / nRms;
	over = (pw.max(1e-10).log10 * 10) - glueThr;
	t = (over + (glueKnee * 0.5)).clip(0, glueKnee);
	gr = (((t * t) / (glueKnee * 2).max(0.001)) + (over - (glueKnee * 0.5)).max(0)) * (glueRatio.max(1).reciprocal - 1);
	gr = LagUD.ar(gr, glueRel, glueAtk);   // falling = more is taken off = the attack; rising = the release
	x = sig * (gr + glueGain).dbamp;
	sig = (x * glueOn) + (sig * (1 - glueOn));
	// the limiter: the louder channel's peak over a window 1.2 … 2.4 look-aheads long (two detectors, reset in turn), held and
	// released; the gain that keeps it under the ceiling, averaged over 0.8 of a look-ahead; the sound itself one look-ahead late
	m = max(sig[0].abs, sig[1].abs);
	h = max(RunningMax.ar(m, Impulse.ar((2.4 * la).reciprocal)), RunningMax.ar(m, Impulse.ar((2.4 * la).reciprocal, 0.5)));
	s = Amplitude.ar(h, 0, limRel);
	gt = (ceilDb.dbamp / s.max(1e-9)).min(1);
	nBox = (0.8 * la * SampleRate.ir).round.max(1);
	g = RunningSum.ar(gt, nBox) / nBox;
	Out.ar(out, (DelayN.ar(sig, 0.05, la) * g).clip2(1));
}).add;

// the three in-between phases of a four-times reading of a signal's peak: 8 taps each, a windowed sinc, summing to 1
~le[\tpTaps] = { |self|
	[0.25, 0.5, 0.75].collect({ |p|
		var h = Array.fill(8, { |j|
			var x = (3 + p) - j, sinc = if(x.abs < 1e-9) { 1 } { sin(pi * x) / (pi * x) };
			sinc * 0.5 * (1 + cos(pi * x / 4))
		});
		h / h.sum
	})
};

// THE READING: two channels in -> [momentary loudness in LUFS, true peak as an amplitude], both at audio rate.
// The K-weighting's coefficients are level.scd's, made for THIS server's rate when the SynthDef is built.
~le[\loudGraph] = { |self, sig|
	var co = self.kCoefs(self[\sr] ? 48000), sh = co[\shelf], hp = co[\hp], taps = self.tpTaps, n = (0.4 * SampleRate.ir).round;
	var k = sig.collect({ |ch| SOS.ar(SOS.ar(ch, sh[0], sh[1], sh[2], sh[3].neg, sh[4].neg), hp[0], hp[1], hp[2], hp[3].neg, hp[4].neg) });
	var ms = RunningSum.ar(k[0].squared + k[1].squared, n) / n;
	var tp = sig.collect({ |ch|
		var d = [ch], best;
		7.do({ d = d.add(Delay1.ar(d.last)) });
		best = d[3].abs;
		taps.do({ |h| best = max(best, h.collect({ |c, j| d[j] * c }).sum.abs) });
		best
	});
	[(ms.max(1e-12).log10 * 10) - 0.691, max(tp[0], tp[1])]
};

SynthDef(\leLoudness, { |in = 0, id = 0|
	var g = ~le.loudGraph(In.ar(in, 2)), tr = Impulse.kr(2), rst = Delay1.kr(tr);
	SendReply.kr(tr, '/le/loud', [RunningMax.kr(A2K.kr(g[0]), rst), A2K.kr(RunningMax.ar(g[1], T2A.ar(rst)))], id);
}).add;

SynthDef(\leTone, { |out = 0, freq = 1000, db = -18, dur = 10|
	var sig = SinOsc.ar(freq) * db.dbamp * EnvGen.kr(Env.linen(0.02, (dur - 0.04).max(0.01), 0.02), doneAction: 2);
	Out.ar(out, [sig, sig]);
}).add;

SynthDef(\leMeter1, { |in = 0, id = 0|
	SendPeakRMS.kr(In.ar(in, 1), 20, 3, '/le/meter', id);
}).add;

SynthDef(\leMeter2, { |in = 0, id = 0|
	SendPeakRMS.kr(In.ar(in, 2), 20, 3, '/le/meter', id);
}).add;

SynthDef(\leLatency, { |out = 0, in = 0, amp = 0.1, thresh = 0.02, period = 0.5|
	var click = Impulse.ar(period.reciprocal);
	var t = Sweep.ar(click, 1);
	var back = InFeedback.ar(in, 1);
	var first = Trig1.ar(back.abs > thresh, period * 0.8);
	Out.ar(out, click * amp);
	SendReply.ar(first, '/le/latency', t);
}).add;

SynthDef(\leOnset, { |in = 0, id = 0, thresh = 0.001, hold = 0.25|
	var amp = Amplitude.ar(In.ar(in, 1), 0.001, 0.05);
	SendReply.ar(Trig1.ar(amp > thresh, hold), '/le/heard', amp, id);
}).add;

// InFeedback (2026-10-08, the Decibel piece's SWEEP_LIST #10): a bus not yet written in this cycle is read as it stood a cycle ago
// (64 samples) instead of as silence — the recording no longer depends on where in the tree the recorder sits
SynthDef(\leCapture, { |in = 0, buf = 0|
	RecordBuf.ar(InFeedback.ar(in, 1), buf, loop: 0, doneAction: 2);
}).add;

SynthDef(\leSample, { |out = 0, buf = 0, amp = 1|
	var db = \envDb.ir(0 ! 8), dt = \envDt.ir(0.01 ! 7), cv = \envCurve.ir(0);
	var lvl = EnvGen.kr(Env(db, dt, cv)).dbamp;
	var sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf), doneAction: 2) * amp * lvl;
	Out.ar(out, [sig, sig]);
}).add;

SynthDef(\leSine, { |out = 0, freq = 220, dur = 4, amp = 1, gate = 1|
	var db = \envDb.ir(-60 ! 8), dt = \envDt.ir(0.01 ! 7), cv = \envCurve.ir(0);
	var gc = \glissCents.ir(0 ! 8), gt = \glissDt.ir(0.01 ! 7);
	var lvl = EnvGen.kr(Env(db, dt, cv)).dbamp;
	var cents = EnvGen.ar(Env(gc, gt, 0));
	var guard = EnvGen.kr(Env([0, 1, 1, 0], [0.01, (dur - 0.04).max(0.01), 0.03], \sin), doneAction: 2);
	var let = EnvGen.kr(Env.asr(0, 1, 0.05), gate, doneAction: 2);   // gate 0 = it lets go in 50 ms (sine.scd sineStop)
	var sig = SinOsc.ar(freq * (cents / 100).midiratio) * amp * lvl * guard * let;
	Out.ar(out, [sig, sig]);
}).add;

// lePetalsLive — a player's microphone into the petals of resonance, in real time (petals_live.scd has the SynthDef and its story)
if(~le[\petalsLiveDef].notNil) { ~le.petalsLiveDef.add };

// leSineTrack · leTrackSim · leTrackProbe — a sine that is a window on a player: its ear, the level a score tells it, the sound check's probe (track.scd has the SynthDefs and their story)
if(~le[\trackDefs].notNil) { ~le.trackDefs.do({ |def| def.add }) };
)
