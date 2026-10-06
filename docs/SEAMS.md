# SEAMS — where the engine plugs into a piece's stack

> **Filled as each seam is made** (`docs/PLAN.md` parts 3 · 4 · 7 · 11). The sound path's audio half was written at 4.1, 2026-10-04; its message half, and the first lines a stack file must change, at 4.2 the same day; **the bank and the first two composer-score objects at 4.3 … 4.4 · part 11, the same day (RUNNING_LOG §14).**
>
> **The rule (CLAUDE.md, `#6 §806`):** the engine's code is ADDITIVE — new files, registry rows, one hook line each. **Every line a
> stack file must change is listed HERE**, so a piece applies the list once at the take (`docs/TAKE.md`). A change not on this
> list is a fault.

## The three seams

| Seam | What the engine adds | What the piece's stack must provide | Where it was proven |
|---|---|---|---|
| **The composer score** | a mixin file per object family (part 11): **`score/le_msg.js`** the page's voice · **`score/le_objects.js`** the mic opening and the return · **`score/le_process.js`** the process brick and its catalogue of effects | three `<script>` tags in `composer.html`; two lines — `LEObjects.attach(…)` and `LEObjects.tick(…)` | the voice: the Decibel piece's 6.2, 2026-10-04 (RUNNING_LOG §11) · **the first two objects: its 6.3 … 6.5, the same day (RUNNING_LOG §14)** |
| **The sound path** | the engine itself — SuperCollider, real-time: `sc/` · `tools/sc.js` · the message: `tools/osc.js` · `tools/relay.js` (part 4) · **the bank: `sc/bank.scd`** · **the processing: `sc/process.scd`**, offline (part 6) | **audio:** one send per player to an engine input; ONE FLAT RETURN TRACK — below · **message:** three lines in its score server; a `message` block in its route table — below · **the bank:** a folder, given at the engine's start — below | the engine's half: `selftest.scd`, 2026-10-04 · **the crossing: the Decibel piece's 6.1, 2026-10-04 — unity; two DAW blocks** (RUNNING_LOG §8) · **the message: its 6.2, the same day — to the edge of Web MIDI** (RUNNING_LOG §11) · **the bank: its 6.3 … 6.5 — a rack note captured, cropped, indexed, returned at unity** (RUNNING_LOG §14) |
| **The notation** | a rules row + a drawn or animated kind + its edge class per glyph (parts 7 · 12) | `notation/registry/rules.json` · `page_rules.json` · the render's kind table · the extractor's event emit | ‹part 7› |

## The sound path — the audio half (4.1)

**The shape.** The engine is ONE SuperCollider server (UDP 57210). The simulation and the concert differ in one place, the device:

| | the players reach the engine by | the engine reaches the room by |
|---|---|---|
| **live** (`\live`) | microphones → the interface → the engine's hardware inputs | the engine's master → the interface → the PA. No DAW. |
| **simulated** (`\sim`) | the piece's sampled players in its Reaper rack → ReaRoute → the same inputs | the engine's master → ReaRoute → ONE FLAT TRACK in the rack |

**THE ENGINE RETURNS WHAT IT MAKES** (since 4.4): a sample played back, later an effect — never a player's own sound by itself.
The player is already heard in the room (in the simulation: in the rack), and a straight copy two DAW blocks behind only colours
it. A pass-through exists as a ROUTE CHECK alone (`LE_PASS` · `LE_ECHO`, below).

**What the machine must have (once per machine, his hand):** ReaRoute — an option of Reaper's installer ("ReaRoute ASIO driver") — and
Reaper's audio system on ASIO. `node electronics/tools/sc.js devices` says whether SuperCollider sees it.
**ASIO is the studio setting.** A remote-desktop session that needs Reaper on WASAPI (so the remote side hears it) has no ReaRoute
channels: there the rack plays and the engine cannot be fed. MIDI is untouched by the choice.

**What a piece's rack must provide — the whole list:**

1. **Per player, one hardware send** from the player's instrument track to one ReaRoute channel: **mono · post-fader · unity**.
   *Post-fader because a rack's faders are its loudness calibration: the engine then hears each player at the level the composer
   does, and a sample played back at unity is as loud as the note was.* The channel number is the player's engine input, counted
   from 1 as Reaper names it; the engine counts from 0.
2. **One return track** — the loudspeaker: input = the ReaRoute pair the engine's master leaves on (1/2), monitoring ON, record mode
   NONE, **0 dB, NO effects**. What is heard from it is the engine's master exactly as it leaves for the PA. A piece never
   processes it.
3. **For the latency measure only, and only while it runs:** a send from the return track to one more ReaRoute channel (3), taken
   down afterwards.

**Three facts a piece's DAW job needs (proven 2026-10-04, RUNNING_LOG §8):**
- **Reaper lists ReaRoute's channels at hardware index 512 … 527**, not among the device's own — a job that scans 0 … n−1 never
  finds them. A send's `I_DSTCHAN` and a track's `I_RECINPUT` take 512 + the channel directly.
- **The round trip costs two of the DAW's blocks** — one per crossing (23.22 ms at 512 samples, 44100 Hz). It is the simulation's
  number, not the concert's.
- **A track's own meter may read before its fader.** A check compares against the DAW's master with the engine off.

**What a piece's stack files change: NOTHING.** The route is data in the rack plus three files of the piece's own: a table of
which track is which player, a job for its DAW control, a tool that runs the checks. The Decibel piece's are the model:
`bank/elec_route.json` · `reaper/bridge/jobs/elec_route.lua` · `tools/elec.js`.

**What the engine gives a piece:**

| | |
|---|---|
| `node electronics/tools/sc.js devices` | what SuperCollider can open; whether ReaRoute is there |
| `… sc.js run electronics/sc/selftest.scd` | the engine's own test — no hardware, no sound; exit 0 = all SEVEN pass |
| `… sc.js run electronics/sc/check_route.scd LE_IN=0 LE_SECONDS=10` | one player passed through; reports the loudest in and out |
| `… sc.js run electronics/sc/latency.scd LE_OUT=0 LE_IN=2` | the round trip, in ms |
| `… sc.js run electronics/sc/session.scd LE_PLAYERS=name:0,… LE_BANK=<folder> [LE_CROP=…]` | THE ENGINE, up and listening: the players' microphones, the bank, the messages. `LE_ECHO=1` / `LE_PASS=1` are route checks (each player returned a second later / straight); `LE_SECONDS=n` a tool's bounded run; `LE_MODE=quiet` no hardware |

**While an engine is up** (his own window): a file that boots a server is REFUSED by `tools/sc.js`, and a piece must not list the
audio devices (it loads ReaRoute beside the live client). The runner removes only the server its own run started (RUNNING_LOG §9).

**AN ENGINE IS A SERVER WITH ITS LANGUAGE** (RUNNING_LOG §14). On Windows the language starts its server through a `cmd /c` wrapper,
and a window closed by its X took the language and LEFT THE SERVER — holding the port and the audio device, reachable by nothing,
and every later start refused. Two things since: **(1)** a piece's start tool ends its engine on `SIGHUP` (the window's close),
`SIGINT`, `SIGTERM`, `SIGBREAK` — the Decibel piece's `tools/elec.js start` is the model; **(2)** `tools/sc.js` looks up each
server's OWNER (the sclang above the wrapper): a server whose owner is gone is removed before a start (`sweepOrphans`), and only a
server with a LIVING owner counts as "the engine is up". A living engine is never touched.

The line protocol every script speaks is at the top of `tools/sc.js`; the namespace and its one trap at the top of `sc/boot.scd`.

## The sound path — the message half (4.2)

**The shape.** A piece's score tells the engine what is about to happen by ONE road, the same in concert and in simulation:

| | the page is | the note is | the road |
|---|---|---|---|
| **live** | a browser on a player's tablet | the player's own | the page → the piece's score server (HTTP `POST /api/elec`) → OSC over UDP → the engine's LANGUAGE port |
| **simulated** | the composer's own browser | the page's MIDI to the sampled player in the rack | the same |

The one thing that may differ is the engine's ADDRESS, a field of the piece's route table. (When the score server runs on the
engine's own laptop even that is the same, `127.0.0.1`: then the only difference is where the browser is.)

**The engine's side.** The language listens on **UDP 57211** — PINNED (`sc/boot.scd`, `~le.openEar`), beside the server's 57210;
sclang's own port moves when another sclang is open, so it cannot be the address. A message is `/le/<kind>` followed by NAME, VALUE
pairs — it says what each value is, so a field can be added without breaking a reader:

```
/le/open   player bcl  lane 1  id zn-2  name bcl-A  category attack  t 4.9  lengthMs 500  dueMs 89.3
/le/play   name bcl-A  id zn-3  lane 1  t 8  dueMs 85.9
```

A patch registers a kind with `~le.hear(kind, { |le, data, time, addr| … })` and gets the pairs as an Event, and the time the
language received them. `/le/hello` is answered to its sender with `/le/hello.reply` — "is the engine there?", asked without
starting or stopping anything.

**The kinds so far:**

| kind | fields | what the engine does |
|---|---|---|
| `hello` | anything | answers `/le/hello.reply` to the sender, with its mode and players |
| `open` | player · lane · id · name · category · `t` the score's seconds · `lengthMs` the window · `dueMs` how far ahead of the window's start the message left | THE MIC OPENING — the bank, below |
| `play` | name · id · lane · t · `dueMs` | THE RETURN — the bank, below |
| `process` | source · out · effect · `args` "name:value,…" (the chain's own controls) · `end` shape or tail · atkMs · durMs · relMs · curve (shape) · floorDb · capMs (tail) · gainDb · match · id | THE PROCESSING — a banked sample through the chain, OFFLINE, banked again as `out`; its row carries the id back as `openingId` (`sc/process.scd`) |
| `sine` | id · lane · t · dueMs · `midi` (the pitch with its cents: 57.12) · `lengthMs` · `level` a mark or a line `ms:mark,…` · `levelCurve` · `gliss` a line `ms:cents,…` · `pass` | A GENERATED VOICE — a sine at a dynamic of the ladder, exact by formula, where the brick is (`sc/sine.scd`). A new `pass` lets go of the sines of the pass before |
| `sinestop` | — | every sine sounding lets go in 50 ms (a score that stops) |
| `onset` | player · lane · id · t · dueMs | A ROUTE CHECK (4.2's proof): shown as one line; when that player's sound then arrives, a second line with the ms between them. No page sends it any more |

**Why the timing need not be exact.** A message is sent AHEAD of what it announces (a composer page schedules about 100 ms
ahead; a mic opening opens before its notated moment and runs long), and a capture is cropped to the attack afterwards. So a
message need only be EARLY. No clock is shared between the browser and the engine: a return says how far ahead it left (`dueMs`)
and the engine schedules it on its own clock that much later.

**Rejected** (the Decibel piece's RUNNING_LOG §57 · §58): a MIDI port as the trigger — it rides the notes' own clock, but a
loopback MIDI port has no concert counterpart, and a MIDI message holds two numbers and no names · a WebSocket — a dependency the
pieces' stacks refuse, for a speed sparse messages do not need (an HTTP POST on localhost is under a millisecond).

**What the engine gives a piece:**

| | |
|---|---|
| `node electronics/tools/osc.js selftest` | the OSC encoder against bytes written out by hand |
| `node electronics/tools/osc.js send /le/hello` | one message to the engine; prints its answer (safe beside a live engine) |
| `electronics/tools/relay.js` | the score server's handler: `require(…)({ configFile })` → `(req, res)`. `POST { kind, data }` → `/le/<kind>`; `GET` → what the page needs; the address comes ONLY from the piece's table, never from a request |
| `electronics/score/le_msg.js` | the page's voice: `LE.send(kind, data)` · `LE.hello()` · `LE.playerOf(port)` |
| `… sc.js run electronics/sc/session.scd … LE_SECONDS=20` | a bounded run for a piece's proof; `LE_MODE=quiet` for the messages alone, no hardware |
| `electronics/sc/selftest.scd` — D · E | the ear and the onset probe, proven with no hardware |

**Proven** (the Decibel piece's 6.2, 2026-10-04 — RUNNING_LOG §11): `/le/hello` answered through the score server in 0.71 ms and
from the page in 0.5 ms · a real note on the engine's ReaRoute input paired with its message. **The score's lead over its own sound,
measured on the composer's Chrome the same day: 114.2 ms** — the message left 92.8 ms ahead of the note's own start, and the sound
reached the engine 21.4 ms after that start (one note; RUNNING_LOG §12).

## The sound path — the bank (4.3 · 4.3b · 4.4 · the index)

**The shape.** `sc/bank.scd`, loaded by `boot.scd`. A session calls `~le.bankOn(folder, cropOpts)` then `~le.bankHear`
(`session.scd` does, when it is given `LE_BANK`).

| step | what happens | what is left |
|---|---|---|
| `/le/open` | the player's bus is recorded FROM THE MESSAGE to the window's end (`dueMs` + `lengthMs`) — the recorder starts in the same breath as its buffer is made, no round trip | `<bank>/raw/<id>.wav` — the whole recording, kept for a re-crop |
| the crop | in the LANGUAGE, on the recording's samples (the engine is whole without a piece's server) | `<bank>/<name>.wav` — mono, 24-bit, the engine's sample rate |
| the index | a row written after each crop; a name taken twice REPLACES its row and its file — the latest take wins | `<bank>/index.json` |
| the buffer | the sample is loaded at once; every sample of the index at the session's start | — |
| `/le/play` | `leSample` to the master at UNITY, `dueMs` from the message's arrival, on the engine's clock (a time-stamped bundle) | the sound |

**The crop's rule** — each number a DEFAULT of the engine's, overridden by the piece (`LE_CROP=attackDb=-30,endDb=-45,…` at the
engine's start); **the composer's ear tunes them:**

| | default | |
|---|---|---|
| `attackDb` | −30 | THE ATTACK: the first sample above this, under the recording's peak … |
| `floorDb` | −50 | … AND above this, in dBFS — silence is not an attack. A recording whose peak is under it is REPORTED (`nothing to crop`), and nothing is saved under the name |
| `preMs` | 5 | the sample starts this long before the attack |
| `endDb` · `holdMs` | −45 · 50 | THE END: where the level falls under `endDb` below the peak and stays there `holdMs` — or the recording's end |
| `fadeInMs` · `fadeOutMs` | 2 · 10 | |

The level is read in steps of one millisecond (the loudest sample of each); the attack is then found to the sample inside its step.

**The index's schema** (the engine's; the FILE is the piece's):

```
{ "schema": 1, "samples": [ { "id", "name", "player", "lane", "category", "scoreTime", "lengthMs", "peakDb",
                              "file", "raw", "openingId", "windowMs", "attackMs", "captured" } ] }
```

`file` · `raw` are relative to the bank's folder, forward slashes. **`attackMs`** is where in the raw recording the attack was found —
how early the window opened before the sound; kept for the composer and for the paper. A JSON file read by the language comes
back all strings: `~le.indexRead` makes the schema's numbers numbers again. An index that cannot be read is NEVER written over.

**A name is a file name:** `~le.safeName` (and the page's twin) keeps letters, digits, `-` and `_` and drops the rest — nothing a
message carries can write outside the bank's folder. **The folder itself never comes from a message** (the relay's rule for the
address, again): it is given at the engine's start.

**What the engine says** (each one `LE_INFO` line; a tool reads the `LE_RESULT` twin):
`open · bcl · bcl-A · 500 ms` → `captured · bcl-A · raw · 589 ms · peak -41.2 dB` → `cropped · bcl-A · 2476 ms of 4000 · the attack at
575 ms · peak -41.2 dB` (or `nothing to crop · bcl-A — …`) · `play · bcl-A · in 86 ms · 2476 ms long` (or `play · x — no such sample
in the bank`). `LE_RESULT` carries `"msg": "captured"` with the index's row, or `"msg": "play"`.

**What a piece's stack must provide — the whole list:** (1) a folder for its samples, and in its route table where it is and any
crop number it overrides · (2) its start tool passes them (`LE_BANK` · `LE_CROP`) · (3) `raw/` in its `.gitignore`; the cropped
samples and the index are the piece's to commit · (4) its score server already serves the folder to the page, if the folder sits
under a served path (the Decibel piece: `bank/samples/` under `/bank/`). **No line of a stack file changes.**

**Proven** (RUNNING_LOG §14): `selftest.scd` F — a synthetic attack found 0.16 ms from where it was put · G — a window opened by
message on a private bus: recorded (0.500 s for 100 + 400 ms), cropped, indexed, loaded, returned at the captured peak to 0.0 dB ·
**in the Decibel piece's rack: a bass clarinet note, 2476 ms kept of a 4000 ms window, the attack found 575 ms in, captured at
−41.2 dB and back on the return track at −41.22 dB.**

## The composer score — the objects (part 11: the first two)

**The shape.** `score/le_objects.js`. The two objects are **ZONES WITH A MODEL OF THEIR OWN** — the stack's composer tests an object's
TYPE by name in some 250 places and has no registry, while a zone already draws on a lane, selects, moves, resizes, duplicates,
saves, undoes and has a panel, and its MODEL is tested in a handful of places. The file adds only what the model means.

| | `midiModel` | `zoneFunction` | carries | the key (the piece's) | played through |
|---|---|---|---|---|---|
| **the mic opening** | `elecOpen` | `elec` | `elec: { name, category, player }` | over the selected note: 100 ms before it, 500 ms long; or at the playhead | `/le/open` |
| **the return** | `elecPlay` | `elec` | `elec: { name }` | at the playhead: the selected opening's sample, else the nearest opening's before it | `/le/play` |

- **`zoneFunction: 'elec'`, not the stack's `midiPreview`** — a zone of that function is offered the MIDI models' panel rows and
  their mute / solo; these have their own section instead.
- **The label** says what the brick is: `◉ bcl-A` · `▶ bcl-A`, and what is missing: `— no microphone on this lane` · `— not captured yet`.
- **The panel section** (appended under the zone's own rows): the opening's name · category · window in ms · player (read from
  the lane) · what the bank holds of it; the return's sample, picked from the index. A rename of an opening carries its returns.
- **A return is as long as its sample** — read from the index at the page's load, at a gesture, and a moment after each opening
  the page has played through.
- **The tick is the file's own, beside the MIDI playback and not inside it:** in concert the page is on a tablet and has no MIDI.
  Each brick's message leaves once, ahead of its start by the look-ahead (0.1 s), with `dueMs`. An opening the playhead STARTS
  INSIDE still opens, for what is left of its window. A brick on a silenced part sends nothing.
- **`renderZone` and `showPropertyPanel` are WRAPPED** — the way the stack's own mixins go in; no line of theirs is changed.
- **A lane is one of the engine's players by the MIDI port of its instrument**, which the piece's route table lists per player.

**Proven** (the Decibel piece's 6.3 … 6.5, RUNNING_LOG §14): the keys by the browser's real input; the panel, the rename and its
undo; a save's round trip; the page's own playback — `open` 89.3 ms and `play` 85.9 ms ahead — shown by the engine and returned
through the rack; the notation's extractor unmoved by the two models.

## The composer score — the third object: the process brick (parts 6 · 11.3)

**The shape.** `score/le_process.js` — a MIXIN on `LEObjects` (it adds methods to that object and is loaded after it), so a
page without it still opens a score that has these bricks. A zone like the other two:

| | `midiModel` | carries | the key (the piece's) | played through |
|---|---|---|---|---|
| **the process brick** | `elecProcess` | `elec: { source, out, label, effect, args, end, atkMs, durMs, relMs, curve, floorDb, capMs, gainDb, match, rendered }` | at the playhead: its source the selected brick's sample, else the nearest return or stage before it | `/le/play` of `out`, once rendered |

- **A stage of a chain:** `source` is a banked sample, `out` the name the result is banked under — `<root>~<n>`, the root being the
  sample the chain began from. The next brick's source is this brick's out.
- **The catalogue** (`LEObjects.EFFECTS`) is the chain's stages by name, each with its few dials under the engine's OWN control
  names: `args` is `{ controlName: value }` and is what the message carries. The engine has no menu; the panel's JSON box may set
  any control of `\leProcess`, so two stages at once is a brick too.
- **Render** (the panel) sends `/le/process` with an id and reads the bank's index until a row of that name carries the id
  (`openingId`); then the brick is as long as its sample. Nothing else comes back — the index is the answer, as for a capture.
- **The label** says what it is and what is missing: `⟳ a pitch · bfl-impulse-1~1 = comb ← bfl-impulse-1` · `— not rendered` ·
  `— changed: render again` · `— its source is newer: render again`.
- **`*` and a pattern's "every sample" leave processed samples out** — a render must not change what a piece already plays.

**Proven** (the Decibel piece's 10.1, RUNNING_LOG §26): the engine's half by `sc/process_test.scd` (four offline renders, no
hardware); the page's half under a stub window with the piece's workshop score. NOT yet by a browser's real input or a living engine.

## The composer score — the processed return: a brick's variants and the plan (parts 6 · 11.2)

**The shape.** Nothing new on the page: a field on the return brick, a file of the piece's, two message kinds. A return may ask
for a TRANSFORMATION of its sample instead of the sample — one effect of the chain under an envelope — and the engine makes it
from whatever was just captured.

| | where | what |
|---|---|---|
| **the variant** | the return brick: `elec.variants = { '<sample>': '<key>-<env>' }` | one per sample the brick plays; the brick then asks for `<sample>~<key>-<env>` (`bfl-impulse-1~crush4-perc`) |
| **the presets** | THE PIECE's file, fetched at `opts.presetsUrl` (`/bank/presets.json` by default) | `{ classes: { <class>: { durX } }, envelopes: { <env>: { atkMs?, capMs? } }, presets: [{ key, name, effect, args, class, durX?, match?, capMs? }] }` — `args` whole, under the chain's own control names; a value may be a range `[lo, hi]`, drawn at each send. `<env>` is one of the engine's endings (`perc` · `expodec` · `gauss` · `tri` · … · `tail`) |
| **the plan** | `/le/plan  stamp · part · of · rows · [render]` | every variant the score's bricks ask for, once, with the score time of its first use: `base;suffix;effect;end;atkMs;durX;match;t;capMs;args`, `\|` between rows. In parts of six that share a stamp; in force when the last part is in |
| **render them all** | `/le/planrender`, or `render 1` on a plan (the panel's button sends the latter) | every planned variant whose sample is in the bank, again |

- **The engine renders a sample's variants right after its capture**, the soonest-needed first, two at a time, offline; each is a
  processed sample — a file, a row with `planned: 1`, a buffer.
- **Asked for before it is ready, a variant falls back** — the earlier render if a buffer holds one, else the sample, raw — and
  the engine's window says `late · …`. The page does not know and does not wait.
- **The page sends the plan** at a pass's first frame, a second after any change to the score, and with the button. An empty
  plan clears the engine's.
- **`markDirty` is WRAPPED** (with `renderZone` and `showPropertyPanel`: three now) — no line of the host's is changed.
- **A piece with no presets file** has no rows in the panel and every return is raw: the file is the switch.
- **A variant's row is left out of the pickers** (the return's Sample · a pattern's boxes · the process brick's Source), and `*`
  plays the captured samples only.

**Proven** (the Decibel piece's 10.8, RUNNING_LOG §35): the engine's half by `sc/process_test.scd` (a plan in two parts, out of
order; a queue two wide; lengths by `durX`; the fallback); the page's half under a stub window with the piece's score. NOT yet
through a living engine or by a browser's eye.

## The composer score — the fourth object: the sine brick, a GENERATED voice

**The shape.** `score/le_sine.js` — a MIXIN on `LEObjects`, as the process brick's file is; it adds its own row to `MODELS`. The
engine's half is `sc/sine.scd` and `\leSine` (`sc/synths.scd`), heard with or without a bank. A zone like the other three:

| | `midiModel` | carries | the key (the piece's) | played through |
|---|---|---|---|---|
| **the sine brick** | `elecSine` | `elec: { midi, gliss: { kind, from, to, points? }, level: { mode, mark, to?, curveRef? }, label }` | over the selected note: its lane, its span, its pitch; or at the playhead, four seconds | `/le/sine` |

- **Its length is the sine's; its lane says whose staff it is on** — the player who holds a long tone against it.
- **The pitch carries its cents** (`57.12`); the panel takes a name (`A3 +12`) or a number.
- **The gliss is a line of CENTS** against the pitch — `none · to` (unison) `· from · through · around · line` — sent as `ms:cents` pairs.
- **The level is a dynamic of the ladder** — `flat` · `hairpin` · `curve`. The engine turns a mark into the sine's exact peak:
  `markDb + 0.691 − K(f)`, K the K-weighting's gain at the sine's frequency. No sine is ever measured.
- **A level that FOLLOWS A DRAWN CURVE is read through the HOST's reader, handed in:** `opts.curveAt(ref, { layer, startTime,
  endTime }, n)` → n heights 0 … 1 over the span, or null where nothing is drawn. `ref` is the piece's (the first piece: its three
  reference curves `A · B · C`, or `lane`). Read AT THE FIRE, eight points — a curve redrawn between two passes is heard at the
  next. Height 0 … 1 = ppp … fff. The module leans on no file of the piece's; without a reader the level is the flat mark.
- **A playhead that STARTS INSIDE the brick starts it for what is left** — its lines taken up where they stand, a curve read again.
- **A stop reaches the engine:** the host's `stopPlay` is WRAPPED (once, at the attach) to send `/le/sinestop`. A restart or a jump
  of the playhead needs no message of its own: every `/le/sine` carries the pass's number, and a new one lets the old sines go.
- **The label** says what it is: `∿ A3 +12c ↗ −28c → 0 · 6.0 s · mf` · `… · curve A ▁▃▅▆█▆▅▃` · `… · curve A — none drawn: p`.

**Proven** (the Decibel piece's 12.1 … 12.3, RUNNING_LOG §47 · §48): the engine's half by `sc/sine_test.scd` (offline renders, measured);
the page's half by `tools/sine_page_test.js` under a stub window (33 checks). NOT yet by a browser's real input or a living engine.

## The level — a sample's loudness, a return's dynamic, the drive, the bus, the house (part 13)

*(Built in the Decibel piece, 2026-10-06 — its PLAN 1.4; this repo's RUNNING_LOG §42 … §45. NO line of a piece's stack files changes for any of it: the page's part is in the two modules already tagged, the engine's in files `boot.scd` loads.)*

**What a piece GIVES at the engine's start** (its tool flattens its own route table; `sc/boot.scd` `takeSpecs` reads them):

| the variable | what it is | absent |
|---|---|---|
| `LE_LEVEL` | the ladder — `reference=<the LUFS of fff>,stepDb=4,liftCapDb=20,floorDb=-60,driveRef=-20,bleedDb=12` | the engine's defaults (`sc/level.scd` `levelDefaults`) |
| `LE_MASTER` | the bus — `hpfHz=30,lpfHz=0,glueOn=1,glueThr=-18,glueRatio=2,glueKnee=6,glueAtkMs=30,glueRelMs=250,glueGainDb=0,ceilingDb=-1,lookaheadMs=5,limRelMs=100` | NEUTRAL: no filter, no glue; the ceiling −1 dB, 5 ms of look-ahead |
| `LE_VENUE` | a hall — `name=<n>;bcl:trimDb=-2.5:hpfHz=90:eq1=250/-3/1,bfl:…` (an eq is hz/dB/Q) | every microphone flat |
| `LE_REFUSE_BLEED` | `1`: a capture that barely stands over its room is refused — a concert | flagged in its row, kept |

**What a page MAY add to `/le/play`** (`score/le_objects.js` `dynFields`; an engine that predates them ignores them): `dyn` — `played` · `mark:mf` · `rel:+1[:floor:p][:ceil:f]` · `env` — `ms:level,…` (ms may be `end`, the sample's own length; a level is a mark, `=` the brick's own dynamic, or `+n` / `-n` steps from it) · `envCurve`.

**What a page MAY add to `/le/process`:** `srcDrive` — `played` · `normalized` · `+12`. **To a plan row:** an eleventh field, the drive (absent = `normalized`). **In `args`:** a dial as a line, `name:value@ms,value@ms`.

**Two more messages:** `/le/master  name value …` — the bus's dials while it runs (the names of `LE_MASTER`; `lookaheadMs` only at the start) · `/le/tone  seconds · db · hz` — a line-up tone past the bus.

**What the INDEX gains** (a row; all optional — a page must not need them): `loudDb` · `loudIntDb` (LUFS: the loudest 400 ms · the whole sample) · `played` (the name on the ladder) · `drive` (how a render was driven) · `floorDb` · `overDb` · `bleed` (a capture in a room).

**What a piece's score SAVE gains** (the uses — the piece's): `zone.elec.dyn` on a return brick · `zone.elec.variants[name]` as `{ v, drive }` beside the plain string · `zone.elec.drive` on a process brick · a dial's value as a line string.

**A variant's NAME:** `<sample>~<key>-<env>` — and `…_dN` · `_dP` · `_d12` · `_dm6` when the BRICK says the drive. A piece that keeps its plan's renders out of git by `*~*-*.wav` still matches them.

**The bus runs LATE by its look-ahead, and `samplePlay` plays that much EARLY:** a return still lands where its brick is; a piece's DAW job changes nothing; a measured round trip through the master grows by the look-ahead.

**The batteries a piece runs after taking a change here** — all offline, safe beside a living engine: `sc/level_test.scd` · `sc/bus_test.scd` · `sc/process_test.scd` · `sc/roll_test.scd` · `tools/page_test.js`.

## The lines a stack file must change, per piece

*(The message route, 4.2 — the Decibel piece's 6.2 commit of 2026-10-04. The objects, part 11 — its 6.3 … 6.6 commit, the same day.)* *(The process brick — the Decibel piece's 10.1 commit of 2026-10-05: one more tag, one more key.)* *(The processed return — its 10.8 commit of the same day: NO line; a presets file where the page fetches it, `/bank/presets.json`.)* *(The sine brick — the Decibel piece's 12.2 · 12.3 commit of 2026-10-06: one more tag, one more key, one reader in the attach line.)*

**The piece's score server (`score/server.js`) — three lines:**

| # | the line | where |
|---|---|---|
| 1 | `const elecRelay = require('../electronics/tools/relay.js')({ configFile: path.join(__dirname, '..', 'bank', 'elec_route.json') });` | with the requires |
| 2 | `if (url === '/api/elec') return elecRelay(req, res);` | the first of the API routes |
| 3 | `if (url.startsWith('/electronics/')) { base = path.join(__dirname, '..', 'electronics', 'score'); rel = url.slice('/electronics'.length); }` | in the static block, beside `/bank/` |
| 2c | `if (url === '/api/candidates') { … }` — GET the kept settings · POST one more (the piece's `tools/candidates.js` writes `bank/candidates.json` and renders `docs/CANDIDATES.md`) | after row 2 — THE SHELF (2026-10-05, the Decibel piece's §113); the panel's Shelf menu and "keep → shelf" button are the module's (`opts.shelfUrl`, '/api/candidates' by default) |

**The piece's composer page (`score/public/composer.html`) — six lines:**

| # | the line | where |
|---|---|---|
| 1 | `<script src="/electronics/le_msg.js"></script>` | after the last panel's script tag |
| 2 | `<script src="/electronics/le_objects.js"></script>` | after it |
| 2b | `<script src="/electronics/le_process.js"></script>` | after it — the process brick (2026-10-05); its key is `process` in line 3's `keys` |
| 2c | `<script src="/electronics/le_sine.js"></script>` | after it — the sine brick (2026-10-06); its key is `sine` in line 3's `keys`, its curve reader `curveAt` there too |
| 3 | `if (window.LEObjects) LEObjects.attach(Composer, { keys: { open: 'm', play: 'r', process: 'e', sine: 's' }, lanes: META_LAYER, indexUrl: '/bank/samples/index.json', accel: window.AccelCalc, containers: window.TimeContainers, curveAt: (ref, z, n) => …, portOf: (l) => (Composer.trackInstrument(l) \|\| {}).port, laneLabel: (l) => (TRACKS[l] \|\| {}).short \|\| ('lane ' + l) });` | just BEFORE `Composer.init()` is called — so a loaded score's first drawing has the bricks' labels. The keys, the lanes and the index's address are the PIECE's. `curveAt` (2026-10-06) is the sine brick's level from a drawn curve: the piece's own curve readers behind one function — n heights 0 … 1 over a span, or null |
| 4 | `if (window.LEObjects) LEObjects.tick(this, timeSec);` | in `applyScroll`, the last of the playback ticks |

*(4.2's test hook — `LE.noteOn(…)` in `tickCurvePlayback` — is OUT: the mic opening is the message.)*

**The piece's route table (the Decibel piece: `bank/elec_route.json`) — two blocks:**

```
"message": { "host": "127.0.0.1", "port": 57211 }
"bank":    { "dir": "bank/samples", "crop": {} }
```

The `message` block is read at every request — a change needs no restart of the score server. The `bank` block is read by the
piece's start tool and given to the engine at ITS start — a change needs the engine started again.

**Three facts of the take:** a score server started BEFORE its three lines existed has no route — restart it once · a page served
by such a server gets no `le_msg.js`, `window.LE` is undefined and nothing is sent: nothing breaks · **the objects need no line of
the server beyond those three** — a page reload brings them.
