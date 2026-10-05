// synths.scd — the engine's basic machinery (the engine plan's 4.1 d). Loaded by boot.scd once the server is up.
//
// leIn       one player's microphone: a hardware input onto the player's own bus. amp is the preamp.
// lePass     a player's bus to the master, untouched — dual mono at unity.
// leEcho     a player's bus to the master, LATER: the same sound `time` seconds behind. A LISTENING AID — a pass-through
//            returns two DAW blocks after the note and is not heard as a second sound; one second behind, it is.
// leMaster   THE OUTPUT: the master bus to the hardware. The chain is the sandbox's ensemble bus
//            (live-electronics-engine/engine/playhead-engine.js, its journal §113-114), translated from Web Audio:
//              high-pass 30 Hz                   -> HPF, switched by hpfOn         (default OFF)
//              glue: -18 dB, 2:1, 30 / 250 ms    -> Compander, switched by glueOn  (default OFF)
//              safety: -1 dB, 20:1, 2 / 100 ms   -> Compander, always on           (no look-ahead: it adds NO latency)
//            then a hard clip at full scale that nothing passes. With hpfOn = glueOn = 0 a signal under -1 dBFS
//            leaves exactly as it arrived (selftest.scd proves it to the sample).
//            NOT YET HEARD BY HIM: the high-pass and the glue carry the sandbox's NUMBERS, not its sound — Web Audio's
//            compressor has a soft knee and its own make-up gain; these have neither. His ear decides, at the processing.
//            The sandbox's reverb and tape sends are not ported — they come with the effects.
// leMeter1/2 a bus's peak, twenty times a second, to '/le/meter'.
// leLatency  a click out and a listener in: the seconds between them, to '/le/latency' (latency.scd).
(
SynthDef(\leIn, { |in = 0, out = 0, amp = 1|
	Out.ar(out, In.ar(in, 1) * amp);
}).add;

SynthDef(\lePass, { |in = 0, out = 0, amp = 1|
	var sig = In.ar(in, 1) * amp;
	Out.ar(out, [sig, sig]);
}).add;

SynthDef(\leEcho, { |in = 0, out = 0, amp = 1, time = 1|
	var sig = DelayN.ar(In.ar(in, 1), 4, time) * amp;
	Out.ar(out, [sig, sig]);
}).add;

SynthDef(\leMaster, { |in = 0, out = 0, amp = 1, hpfOn = 0, hpfFreq = 30, glueOn = 0, ceilDb = -1|
	var sig, hp, gl, ctl;
	sig = In.ar(in, 2) * amp;
	hp = HPF.ar(sig, hpfFreq);
	sig = (hp * hpfOn) + (sig * (1 - hpfOn));
	ctl = max(sig[0].abs, sig[1].abs);
	gl = Compander.ar(sig, ctl, -18.dbamp, 1, 0.5, 0.03, 0.25);
	sig = (gl * glueOn) + (sig * (1 - glueOn));
	ctl = max(sig[0].abs, sig[1].abs);
	sig = Compander.ar(sig, ctl, ceilDb.dbamp, 1, 0.05, 0.002, 0.1);
	Out.ar(out, sig.clip2(1));
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
)
