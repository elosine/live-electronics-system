// boot.scd — the engine's boot: the namespace ~le, the server, the groups, the buses (the engine plan's 4.1 b).
//
// A session file loads this, then boots:
//     (PathName(thisProcess.nowExecutingPath).pathOnly +/+ "boot.scd").load;
//     ~le.bootEngine(\sim, { |le| … the patch … });
//
// THE MODES — the simulation and the concert differ in ONE place, the device:
//   \sim     a piece's Reaper rack feeds the engine over ReaRoute ASIO (16 in · 16 out). Reaper must be running.
//   \live    the interface named in the environment variable LE_DEVICE (the microphones in, the PA out).
//   \quiet   no hardware in the path — every bus private, nothing sounds. The engine's own self-test (selftest.scd).
//
// THE SIGNAL, in the order the groups run:
//   grpIn      leIn — one per player: a hardware input onto the player's OWN bus (the "microphone"; amp = the preamp)
//   grpFx      whatever hears a player — the pass-through now; the capture, the playback, the effects later
//   grpMaster  leMaster — the master bus to the hardware output. THIS IS THE OUTPUT, live and simulated.
//   grpMeter   the meters, last, so they read what was actually sent
//
// THE SERVER listens on UDP 57210, not SuperCollider's usual 57110: an IDE he has open is never touched.
//
// HOW ~le IS WRITTEN: its functions take the namespace as their first argument and are called  ~le.name(args) ;
// its DATA is read with brackets,  ~le[\server] . (An Event calls a function stored under a key when the key is used
// as a method name — so a key must never share a name with a real method: no `halt`, `free`, `add`, `play`, `stop`.)
// A file run from the command line ends with a bare `)` — never `);` (the sandbox's rule: sclang runs nothing otherwise).
(
~le = ~le ? ();
~le[\dir] = PathName(thisProcess.nowExecutingPath).pathOnly;
~le[\port] = 57210;

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
	if(s.notNil and: { s.serverRunning }) { s.quit };
	SystemClock.sched(0.8, { code.exit; nil });
	self
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
	o.memSize = 262144;        // 256 MB: the buffers and the delay lines to come
	o.blockSize = 64;
	asio = ServerOptions.devices.select({ |d| d.contains("ASIO") });
	dev = case
	{ mode == \sim } { asio.detect({ |d| d.toLower.contains("rearoute") }) }
	{ mode == \live } { "LE_DEVICE".getenv }
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
		if(dev.size > 0) { o.device = dev };
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
			self[\master] = Synth(\leMaster, [\in, self[\busMaster].index, \out, self[\busOut].index], self[\grpMaster]);
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

// ---- the players, the pass-through, the meters -----------------------------------------------------------------------
// a player = one microphone = one hardware input channel (0-based) onto the player's own mono bus
~le[\addPlayer] = { |self, name, inCh = 0, amp = 1|
	var s = self[\server], bus = Bus.audio(s, 1), syn;
	if(self[\mode] != \quiet) {
		syn = Synth(\leIn, [\in, s.options.numOutputBusChannels + inCh, \out, bus.index, \amp, amp], self[\grpIn]);
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
~le[\resetPeaks] = { |self| self[\peaks] = (); self };
)
