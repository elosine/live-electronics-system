// boot.scd — the engine's boot: the namespace ~le, the server, the groups, the buses (the engine plan's 4.1 b).
//
// A session file loads this, then boots:
//     (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "boot.scd").load;
//     ~le.bootEngine(\sim, { |le| … the patch … });
//
// THE MODES — the simulation and the concert differ in ONE place, the device:
//   \sim     a piece's Reaper rack feeds the engine over ReaRoute ASIO (16 in · 16 out). Reaper must be running.
//   \live    the interface named in the environment variable LE_DEVICE (the microphones in, the PA out).
//   \remote  a WINDOWS device (LE_DEVICE_IN · LE_DEVICE_OUT; the Windows default by MME when unset), 2 in · 2 out — so a remote
//            desktop session hears the engine with the DAW (which is then on WASAPI, and ReaRoute is gone): listening from afar
//            (the Decibel piece's RUNNING_LOG §209; the engine's §55). The microphones are not there: an opening captures nothing.
//   \quiet   no hardware in the path — every bus private, nothing sounds. The engine's own self-test (selftest.scd).
//
// THE SIGNAL, in the order the groups run:
//   grpIn      leIn — one per player: a hardware input onto the player's OWN bus (the "microphone"; amp = the preamp)
//   grpFx      whatever hears a player — the pass-through now; the capture, the playback, the effects later
//   grpMaster  leMaster — the master bus to the hardware output. THIS IS THE OUTPUT, live and simulated: a mastering bus
//              (high-pass · low-pass · the glue · a look-ahead limiter · the clip — synths.scd; § the bus, below)
//   grpMeter   the meters, last, so they read what was actually sent — the peaks, and the loudness meter (loudOn)
//
// THE SERVER listens on UDP 57210, not SuperCollider's usual 57110: an IDE he has open is never touched.
// THE LANGUAGE listens for a piece's MESSAGES on UDP 57211 (§ the ear, below; the engine plan's 4.2).
//
// HOW ~le IS WRITTEN: its functions take the namespace as their first argument and are called  ~le.name(args) ;
// its DATA is read with brackets,  ~le[\server] . (An Event calls a function stored under a key when the key is used
// as a method name — so a key must never share a name with a real method: no `halt`, `free`, `add`, `play`, `stop`.)
// A file run from the command line ends with a bare `)` — never `);` (the sandbox's rule: sclang runs nothing otherwise).
(
~le = ~le ? ();
~le[\dir] = PathName(thisProcess.nowExecutingPath).pathOnly;
~le[\port] = 57210;
~le[\msgPort] = 57211;

// ---- the line protocol (tools/sc.js reads these lines) ----------------------------------------------------------------
~le[\say] = { |self, tag, text| (tag ++ " " ++ text).postln; self };

~le[\json] = { |self, ev|
	var one;
	one = { |v|
		case
		{ v.isNil } { "null" }
		{ v.isString } { v.quote }
		{ v.isKindOf(Symbol) } { v.asString.quote }
		{ v.isKindOf(Boolean) } { v.asString }
		{ v.isNumber } { if(v.isNaN or: { v.abs == inf }) { "null" } { v.asString } }
		{ v.isKindOf(SequenceableCollection) } { "[" ++ v.collect({ |x| one.(x) }).join(", ") ++ "]" }
		{ true } { v.asString.quote }
	};
	"{" ++ ev.keys.asArray.sort.collect({ |k| k.asString.quote ++ ": " ++ one.(ev[k]) }).join(", ") ++ "}"
};

~le[\db] = { |self, amp| if(amp > 0) { amp.ampdb.round(0.1) } { -150 } };

// leave the process: the server first, then sclang, with an exit code tools/sc.js reports
~le[\leave] = { |self, code = 0|
	var s = self[\server];
	if((self[\indexDirty] == true) and: { self[\indexWrite].notNil }) { if(self.indexWrite) { self[\indexDirty] = false } };   // §228: a pending index write is flushed before the process ends
	if(s.notNil and: { s.serverRunning }) { s.quit };
	SystemClock.sched(0.8, { code.exit; nil });
	self
};

// ---- the bus: the master's dials (the engine plan's part 13; the Decibel piece's 11.6) --------------------------------
// The engine's own defaults are NEUTRAL — no filter, no glue; the limiter at −1 dB with 5 ms of look-ahead, always. A piece
// gives its dials at the START (LE_MASTER, session.scd — the names below) and may move them while the engine runs:
//     /le/master  hpfHz 30  glueOn 0  ceilingDb -1 …      (0 for a filter = off)
// lookaheadMs alone is taken when the master is made: it is how late the bus runs, and samplePlay (bank.scd) plays that much
// early (~le[\masterDelay]).
~le[\masterDefaults] = (hpfHz: 0, lpfHz: 0, glueOn: 0, glueThr: -18, glueRatio: 2, glueKnee: 6, glueAtkMs: 30, glueRelMs: 250, glueGainDb: 0,
	ceilingDb: -1, lookaheadMs: 5, limRelMs: 100);
~le[\masterOf] = { |self|
	var o = self[\masterDefaults].copy;
	if(self[\masterOpts].notNil) { o.putAll(self[\masterOpts]) };
	o
};
~le[\masterArgs] = { |self|
	var o = self.masterOf, lp = (o[\lpfHz] > 0) and: { o[\lpfHz] < 20000 };
	[\hpfOn, if(o[\hpfHz] > 0) { 1 } { 0 }, \hpfFreq, o[\hpfHz].max(10), \lpfOn, if(lp) { 1 } { 0 }, \lpfFreq, if(lp) { o[\lpfHz] } { 20000 },
		\glueOn, if(o[\glueOn] > 0) { 1 } { 0 }, \glueThr, o[\glueThr], \glueRatio, o[\glueRatio].max(1), \glueKnee, o[\glueKnee].max(0),
		\glueAtk, (o[\glueAtkMs] / 1000).max(0.001), \glueRel, (o[\glueRelMs] / 1000).max(0.001), \glueGain, o[\glueGainDb],
		\ceilDb, o[\ceilingDb].min(0), \limRel, (o[\limRelMs] / 1000).max(0.005)]
};
~le[\masterSaid] = { |self|
	var o = self.masterOf, lp = (o[\lpfHz] > 0) and: { o[\lpfHz] < 20000 };
	"high-pass " ++ if(o[\hpfHz] > 0) { o[\hpfHz].asString ++ " Hz" } { "off" } ++ " · low-pass " ++ if(lp) { o[\lpfHz].asString ++ " Hz" } { "off" }
	++ " · the glue " ++ if(o[\glueOn] > 0) { "ON (" ++ o[\glueThr] ++ " dB, " ++ o[\glueRatio] ++ ":1, a " ++ o[\glueKnee] ++ " dB knee)" } { "off" }
	++ " · the ceiling " ++ o[\ceilingDb] ++ " dB, " ++ ((self[\masterDelay] ? 0) * 1000).round(0.1) ++ " ms of look-ahead"
};
// /le/master — the dials moved while the engine runs (a listening session's on and off); what it does not know is left out
~le[\masterSet] = { |self, d|
	var took = List.new;
	if(self[\masterOpts].isNil) { self[\masterOpts] = () };
	d.keysValuesDo({ |k, v|
		if(self[\masterDefaults][k].notNil) { self[\masterOpts][k] = v.asString.asFloat; took.add(k) };
	});
	if(self[\master].notNil and: { took.size > 0 }) { self[\master].set(*self.masterArgs) };
	self.say("LE_INFO", "the bus · " ++ if(took.size > 0) { self.masterSaid } { "nothing it knows in that message" }
		++ if(took.includes(\lookaheadMs)) { " — THE LOOK-AHEAD is taken at the start: it changes with the next one" } { "" });
	self
};

// ---- the loudness meter on what was sent: momentary LUFS and true peak, the loudest since they were last read ---------
~le[\loudOn] = { |self|
	if(self[\loudSynth].isNil) {
		self[\loudNow] = (lufs: -120, tp: 0);
		self[\loudMax] = (lufs: -120, tp: 0);
		OSCdef(\leLoud, { |msg|
			var l = msg[3], p = msg[4];
			if(l.isNumber and: { l.isNaN.not }) {
				self[\loudNow][\lufs] = max(self[\loudNow][\lufs], l); self[\loudMax][\lufs] = max(self[\loudMax][\lufs], l);
			};
			if(p.isNumber and: { p.isNaN.not }) {
				self[\loudNow][\tp] = max(self[\loudNow][\tp], p); self[\loudMax][\tp] = max(self[\loudMax][\tp], p);
			};
		}, '/le/loud', self[\server].addr);
		self[\loudSynth] = Synth(\leLoudness, [\in, self[\busOut].index], self[\grpMeter]);
	};
	self
};
// " · −21.3 LUFS · −2.0 dBTP" — or nothing, when nothing sounded
~le[\loudSaid] = { |self, which|
	var x = self[which];
	if(x.isNil or: { x[\lufs] < -70 }) { "" } { " · " ++ x[\lufs].round(0.1) ++ " LUFS · " ++ self.db(x[\tp]) ++ " dBTP" }
};

// ---- the boot --------------------------------------------------------------------------------------------------------
~le[\bootEngine] = { |self, mode = \sim, onReady|
	var s, o, dev, asio;
	self[\mode] = mode;
	s = Server(\le, NetAddr("127.0.0.1", self[\port]));
	Server.default = s;
	self[\server] = s;
	o = s.options;
	o.numOutputBusChannels = 16;
	o.numInputBusChannels = 16;
	o.numAudioBusChannels = 1024;
	o.numBuffers = 16384;      // every sample AND every render holds a buffer: a bank of 949 reached the default 1024 mid-pass and the
	                           // captures stopped — "No more buffer numbers" (the Decibel piece's RUNNING_LOG §195 · SWEEP_LIST #8, 2026-10-06)
	o.memSize = 262144;        // 256 MB: the buffers and the delay lines to come
	o.blockSize = 64;
	asio = ServerOptions.devices.select({ |d| d.contains("ASIO") });
	dev = case
	{ mode == \sim } { asio.detect({ |d| d.toLower.contains("rearoute") }) }
	{ mode == \live } { "LE_DEVICE".getenv }
	{ mode == \remote } {
		o.numInputBusChannels = 2; o.numOutputBusChannels = 2;
		o.inDevice = "LE_DEVICE_IN".getenv ? "MME : Microsoft Sound Mapper - Input";
		o.outDevice = "LE_DEVICE_OUT".getenv ? "MME : Microsoft Sound Mapper - Output";
		o.outDevice
	}
	{ mode == \quiet } { o.numInputBusChannels = 0; o.numOutputBusChannels = 2; "" };
	if(dev.isNil) {
		if(mode == \sim) {
			self.say("LE_ERROR", "ReaRoute is not installed: SuperCollider sees no ReaRoute ASIO device. The ASIO devices it sees: "
				++ if(asio.isEmpty) { "none" } { asio.join(" | ") });
		} {
			self.say("LE_ERROR", "no device: set LE_DEVICE to the interface's name as `sc.js devices` prints it");
		};
		self.leave(2);
	} {
		if((dev.size > 0) and: { mode != \remote }) { o.device = dev };   // remote: in and out set apart above (their MME names differ)
		self[\device] = dev;
		s.waitForBoot({
			self[\sr] = s.sampleRate;
			self[\grpIn] = Group.head(s);
			self[\grpFx] = Group.after(self[\grpIn]);
			self[\grpMaster] = Group.after(self[\grpFx]);
			self[\grpMeter] = Group.after(self[\grpMaster]);
			self[\busMaster] = Bus.audio(s, 2);
			self[\busOut] = if(mode == \quiet) { Bus.audio(s, 2) } { Bus(\audio, 0, 2, s) };
			self[\players] = ();
			self[\meterIds] = ();
			self[\peaks] = ();
			(self[\dir] +/+ "synths.scd").load;
			s.sync;
			OSCdef(\leMeter, { |msg|
				var id = msg[2].asInteger, peak = 0;
				msg[3..].pairsDo({ |pk, rms| peak = max(peak, pk) });
				self[\peaks][id] = max(self[\peaks][id] ? 0, peak);
			}, '/le/meter', s.addr);
			self[\masterDelay] = (self.masterOf[\lookaheadMs] / 1000).clip(0.001, 0.02); self[\master] = Synth(\leMaster, [\in, self[\busMaster].index, \out, self[\busOut].index, \lookahead, self[\masterDelay]] ++ self.masterArgs, self[\grpMaster]);
			s.sync;
			onReady.value(self);
		}, 100, {
			self.say("LE_ERROR", "the server did not boot on " ++ if(dev.size > 0) { dev } { "the default device" }
				++ " — is the device there, and free? (in \\sim: is Reaper running, on ASIO?)");
			self.leave(3);
		});
	};
	self
};

// ---- the house (the engine plan's part 13; the Decibel piece's 11.7): a VENUE's numbers for each microphone ----------
// ~le[\venue] = (bcl: (trimDb: "-2.5", hpfHz: "90", eq1: "250/-3/1", eq2: "3000/2/0.7"), …) — as LE_VENUE gives them (takeSpecs):
// an eq is  hz/dB/Q . micArgs turns a player's into \leIn's arguments; a player the venue does not name is flat.
~le[\micArgs] = { |self, name|
	var v = if(self[\venue].notNil) { self[\venue][name] }, args = List.new;
	var num = { |x| x.asString.asFloat };
	if(v.notNil) {
		if(v[\trimDb].notNil) { args.addAll([\amp, num.(v[\trimDb]).clip(-40, 40).dbamp]) };
		if(v[\hpfHz].notNil and: { num.(v[\hpfHz]) > 0 }) { args.addAll([\hpfOn, 1, \hpfFreq, num.(v[\hpfHz])]) };
		[[\eq1, \eq1On, \eq1Freq, \eq1Db, \eq1Rq], [\eq2, \eq2On, \eq2Freq, \eq2Db, \eq2Rq]].do({ |k|
			var e = if(v[k[0]].notNil) { v[k[0]].asString.split($/).collect({ |x| x.asString.asFloat }) };
			if(e.notNil and: { e.size >= 2 } and: { e[1] != 0 }) { args.addAll([k[1], 1, k[2], e[0], k[3], e[1], k[4], (e[2] ? 1).max(0.1).reciprocal]) };
		});
	};
	args.asArray
};
~le[\micSaid] = { |self|
	var v = self[\venue] ? ();
	(self[\venueName] ? "a venue").asString ++ " — " ++ v.keys.asArray.sort.collect({ |k|
		var o = v[k];
		k.asString ++ ": trim " ++ (o[\trimDb] ? 0) ++ " dB" ++ if(o[\hpfHz].notNil) { " · high-pass " ++ o[\hpfHz] ++ " Hz" } { "" }
			++ [\eq1, \eq2].select({ |e| o[e].notNil }).collect({ |e| " · eq " ++ o[e] }).join
	}).join(" | ")
};
// what a session is started with, read from the environment in one place (session.scd · calibrate.scd): the ladder (LE_LEVEL), the
// bus (LE_MASTER — needed BEFORE the boot: the master is made in it), the venue (LE_VENUE:  name=<n>;bcl:trimDb=-2.5:hpfHz=90:eq1=250/-3/1,bfl:…),
// and whether a bled capture is refused (LE_REFUSE_BLEED, a concert)
~le[\takeSpecs] = { |self|
	var pairs = { |text, into| text.split($,).do({ |kv| var b = kv.split($=); if(b.size == 2) { into[b[0].asSymbol] = b[1].asFloat } }); into };
	var lv = "LE_LEVEL".getenv, ms = "LE_MASTER".getenv, vn = "LE_VENUE".getenv, parts;
	if(lv.notNil and: { lv.size > 0 }) { self[\levelOpts] = pairs.(lv, ()) };
	if(ms.notNil and: { ms.size > 0 }) { self[\masterOpts] = pairs.(ms, ()) };
	if(vn.notNil and: { vn.size > 0 }) {
		parts = vn.split($;);
		self[\venueName] = if(parts.size > 1) { parts[0].asString.replace("name=", "") } { "a venue" };
		self[\venue] = ();
		parts.last.asString.split($,).do({ |p|
			var b = p.asString.split($:), o = ();
			b.drop(1).do({ |kv| var x = kv.asString.split($=); if(x.size == 2) { o[x[0].asSymbol] = x[1].asString } });
			if(b[0].asString.size > 0) { self[\venue][b[0].asSymbol] = o };
		});
	};
	self[\refuseBleed] = ("LE_REFUSE_BLEED".getenv ? "0").asFloat > 0;
	self
};
// /le/tone — the line-up tone a house asks for: a sine on both outputs, PAST the bus (as it is, untouched by the glue or the limiter)
~le[\toneOut] = { |self, d|
	var dur = (d[\seconds] ? 10).asString.asFloat.clip(1, 120), db = (d[\db] ? -18).asString.asFloat.clip(-60, -6), hz = (d[\hz] ? 1000).asString.asFloat.clip(20, 16000);
	Synth(\leTone, [\out, self[\busOut].index, \freq, hz, \db, db, \dur, dur], self[\grpMeter], \addToHead);
	self.say("LE_INFO", "tone · " ++ hz.round(1).asInteger ++ " Hz at " ++ db ++ " dBFS on both outputs for " ++ dur ++ " s — past the bus, as it is: the house's line-up");
	self
};

// ---- the players, the pass-through, the meters -----------------------------------------------------------------------
// a player = one microphone = one hardware input channel (0-based) onto the player's own mono bus
~le[\addPlayer] = { |self, name, inCh = 0, amp = 1|
	var s = self[\server], bus = Bus.audio(s, 1), syn;
	if(self[\mode] != \quiet) {
		syn = Synth(\leIn, [\in, s.options.numOutputBusChannels + inCh, \out, bus.index, \amp, amp] ++ self.micArgs(name), self[\grpIn]);
	};
	self[\players][name] = (bus: bus, mic: syn, ch: inCh);
	self[\players][name]
};

// the player's bus to the master, untouched — at once (delay 0), or `delay` seconds later (leEcho, a listening aid)
~le[\passThrough] = { |self, name, amp = 1, delay = 0|
	var p = self[\players][name];
	p[\pass] = if(delay > 0) {
		Synth(\leEcho, [\in, p[\bus].index, \out, self[\busMaster].index, \amp, amp, \time, delay], self[\grpFx])
	} {
		Synth(\lePass, [\in, p[\bus].index, \out, self[\busMaster].index, \amp, amp], self[\grpFx])
	};
	p
};

// a peak meter on a bus, read back by name
~le[\meterOn] = { |self, name, bus, chans = 1|
	var id = self[\meterIds].size;
	self[\meterIds][name] = id;
	Synth(if(chans == 2) { \leMeter2 } { \leMeter1 }, [\in, bus.index, \id, id], self[\grpMeter]);
	id
};
~le[\peakDb] = { |self, name| self.db(self[\peaks][self[\meterIds][name]] ? 0) };
~le[\resetPeaks] = { |self| self[\peaks] = (); if(self[\loudNow].notNil) { self[\loudNow] = (lufs: -120, tp: 0) }; self };

// ---- the ear: a piece's messages (the engine plan's 4.2) -------------------------------------------------------------
// The LANGUAGE listens on UDP 57211 — PINNED, because sclang's own port moves when another sclang is open. A message is
//     /le/<kind>  name value  name value …
// and it says what each value is, so a field can be added without breaking a reader. hear(kind, func) hands func the
// pairs as an Event:  func.(le, data, time, addr)  — `time` is when the language received it, on the clock the onset
// probe below reports on. /le/hello is answered to its sender with /le/hello.reply, carrying back whatever it brought:
// the handshake a piece's tools use to ask "is the engine there?" without starting or stopping anything.
~le[\openEar] = { |self|
	var port = self[\msgPort];
	if(self[\earPort].isNil) {
		if(thisProcess.openUDPPort(port)) {
			self[\earPort] = port;
			self.hear(\hello, { |le, data, time, addr|
				addr.sendMsg('/le/hello.reply', \engine, 1, \mode, le[\mode], \players,
					le[\players].keys.asArray.sort.collect(_.asString).join(","), *data.asKeyValuePairs);
			});
		} {
			self.say("LE_ERROR", "the engine's message port, UDP " ++ port ++ ", is taken — is another engine running?");
		};
	};
	self[\earPort].notNil
};

~le[\hear] = { |self, kind, func|
	OSCdef(("leHear_" ++ kind).asSymbol, { |msg, time, addr|
		var data = ();
		msg[1..].pairsDo({ |k, v| data[k.asSymbol] = v });
		func.value(self, data, time, addr);
	}, ("/le/" ++ kind).asSymbol, recvPort: self[\earPort]);
	self
};

// ---- the onset probe: WHEN a player's sound arrives, told to the language (4.2 e) ------------------------------------
// One per player, on the player's own bus: a rise out of silence above `thresh` (0.001 = -60 dB) is reported ONCE, to
// the function stored at ~le[\onHeard] as  (name, time, amp). With a message's arrival time (above) it gives the LEAD:
// how long before its own sound a message came. Good to about one block of the audio device — the server answers per block.
~le[\onsetOn] = { |self, name, thresh = 0.001|
	var p = self[\players][name], id;
	if(self[\onsetNames].isNil) {
		self[\onsetNames] = ();
		OSCdef(\leHeard, { |msg, time|
			var who = self[\onsetNames][msg[2].asInteger];
			if(who.notNil and: { self[\onHeard].notNil }) { self[\onHeard].value(who, time, msg[3]) };
		}, '/le/heard', self[\server].addr);
	};
	id = self[\onsetNames].size;
	self[\onsetNames][id] = name;
	p[\onset] = Synth(\leOnset, [\in, p[\bus].index, \id, id, \thresh, thresh], self[\grpMeter]);
	p
};

// ---- the bank: the capture, the crop, the index, the sample player (the engine plan's 4.3 … 4.4) — its own file ----
(~le[\dir] +/+ "bank.scd").load;
// ---- the level: a sample's loudness, the ladder of marks, the dynamic a return is played at (the engine plan's part 13) — its own file ----
(~le[\dir] +/+ "level.scd").load;
// ---- the generated voices: a sine with a level line and a pitch line, on the players' ladder (the Decibel piece's 12.1) — its own file ----
(~le[\dir] +/+ "sine.scd").load;
// ---- the tracker: a sine that is a WINDOW on a player — armed for its span, in with them, following them, out with them (the Decibel piece's 16.1) — its own file ----
(~le[\dir] +/+ "track.scd").load;
// ---- the computer players: a performer in a state, who hears the players' onsets and plays by the state's rule (the Decibel piece's 14.4) — its own file ----
(~le[\dir] +/+ "performer.scd").load;
// ---- the processing: a banked sample through the chain, offline, banked again (the engine plan's part 6) — its own file ----
(~le[\dir] +/+ "process.scd").load;
// ---- the petals live: a player's microphone straight into the petals of resonance, for a return at its own mic opening (the Decibel piece's 10.14) — its own file ----
(~le[\dir] +/+ "petals_live.scd").load;
)
