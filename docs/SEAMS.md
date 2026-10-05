# SEAMS — where the engine plugs into a piece's stack

> **Filled as each seam is made** (`docs/PLAN.md` parts 3 · 4 · 7). The sound path's audio half was written at 4.1, 2026-10-04; its message half, and the first lines a stack file must change, at 4.2 the same day.
>
> **The rule (CLAUDE.md, `#6 §806`):** the engine's code is ADDITIVE — new files, registry rows, one hook line each. **Every line a
> stack file must change is listed HERE**, so a piece applies the list once at the take (`docs/TAKE.md`). A change not on this
> list is a fault.

## The three seams

| Seam | What the engine adds | What the piece's stack must provide | Where it was proven |
|---|---|---|---|
| **The composer score** | a mixin file per object family (part 11) | one `<script>` tag in `composer.html`; the hook the mixin attaches to | **the first file: `score/le_msg.js`, the page's voice** — the Decibel piece's 6.2, 2026-10-04 (RUNNING_LOG §11); the object families: ‹part 11› |
| **The sound path** | the engine itself — SuperCollider, real-time: `sc/` · `tools/sc.js` · the message: `tools/osc.js` · `tools/relay.js` (part 4) | **audio:** one send per player to an engine input; ONE FLAT RETURN TRACK — below · **message:** three lines in its score server; a `message` block in its route table — below | the engine's half: `selftest.scd`, 2026-10-04 · **the crossing: the Decibel piece's 6.1, 2026-10-04 — unity; two DAW blocks** (RUNNING_LOG §8) · **the message: its 6.2, the same day — to the edge of Web MIDI** (RUNNING_LOG §11) |
| **The notation** | a rules row + a drawn or animated kind + its edge class per glyph (parts 7 · 12) | `notation/registry/rules.json` · `page_rules.json` · the render's kind table · the extractor's event emit | ‹part 7› |

## The sound path — the audio half (4.1)

**The shape.** The engine is ONE SuperCollider server (UDP 57210). The simulation and the concert differ in one place, the device:

| | the players reach the engine by | the engine reaches the room by |
|---|---|---|
| **live** (`\live`) | microphones → the interface → the engine's hardware inputs | the engine's master → the interface → the PA. No DAW. |
| **simulated** (`\sim`) | the piece's sampled players in its Reaper rack → ReaRoute → the same inputs | the engine's master → ReaRoute → ONE FLAT TRACK in the rack |

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
| `… sc.js run electronics/sc/selftest.scd` | the engine's own test — no hardware, no sound; exit 0 = all pass |
| `… sc.js run electronics/sc/check_route.scd LE_IN=0 LE_SECONDS=10` | one player passed through; reports the loudest in and out |
| `… sc.js run electronics/sc/latency.scd LE_OUT=0 LE_IN=2` | the round trip, in ms |
| `… sc.js run electronics/sc/session.scd LE_PLAYERS=name:0,… [LE_ECHO=1]` | the engine up and listening; `LE_ECHO` returns each player that many seconds LATER — a listening aid (a straight pass-through is two DAW blocks behind and is not heard as a second sound) |

**While an engine is up** (his own window): a file that boots a server is REFUSED by `tools/sc.js`, and a piece must not list the
audio devices (it loads ReaRoute beside the live client). The runner removes only the server its own run started (RUNNING_LOG §9).

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
/le/onset  player bcl  lane 1  id wc-2  t 5.0  dueMs 98.6
```

A patch registers a kind with `~le.hear(kind, { |le, data, time, addr| … })` and gets the pairs as an Event, and the time the
language received them. `/le/hello` is answered to its sender with `/le/hello.reply` — "is the engine there?", asked without
starting or stopping anything.

**The kinds so far:** `hello` · `onset` (player · lane · id · `t` the score's seconds · `dueMs` how far ahead of the note's own
start the message left). `sc/session.scd` shows an onset as ONE LINE and, when that player's sound then arrives on its input (the
onset probe, `~le.onsetOn`), a second line with the milliseconds between them.

**Why the timing need not be exact.** A message is sent AHEAD of what it announces (a composer page schedules its notes about
100 ms ahead; a mic opening will open before its notated moment and run long), and a capture is cropped to the attack afterwards
(4.3b). So a message need only be EARLY. No clock is shared between the browser and the engine.

**Rejected** (the Decibel piece's RUNNING_LOG §57 · §58): a MIDI port as the trigger — it rides the notes' own clock, but a
loopback MIDI port has no concert counterpart, and a MIDI message holds two numbers and no names · a WebSocket — a dependency the
pieces' stacks refuse, for a speed sparse messages do not need (an HTTP POST on localhost is under a millisecond).

**What a piece's stack must provide — the whole list:** (1) in its route table, a `message` block and, per player, the name the
page will send · (2) three lines in its score server · (3) one tag and one hook line in its composer page. All are written out
under "The lines a stack file must change", below.

**What the engine gives a piece:**

| | |
|---|---|
| `node electronics/tools/osc.js selftest` | the OSC encoder against bytes written out by hand |
| `node electronics/tools/osc.js send /le/hello` | one message to the engine; prints its answer (safe beside a live engine) |
| `electronics/tools/relay.js` | the score server's handler: `require(…)({ configFile })` → `(req, res)`. `POST { kind, data }` → `/le/<kind>`; `GET` → what the page needs; the address comes ONLY from the piece's table, never from a request |
| `electronics/score/le_msg.js` | the page's voice: `LE.send(kind, data)` · `LE.hello()` · `LE.noteOn(…)`, the test hook |
| `… sc.js run electronics/sc/session.scd … LE_SECONDS=20` | a bounded run for a piece's proof; `LE_MODE=quiet` for the messages alone, no hardware |
| `electronics/sc/selftest.scd` — D · E | the ear and the onset probe, proven with no hardware |

**Proven** (the Decibel piece's 6.2, 2026-10-04 — RUNNING_LOG §11): `/le/hello` answered through the score server in 0.71 ms and
from the page in 0.5 ms · the composer page's OWN playback, through its hook, shown by the engine as
`onset · bcl · lane 1 · brick wc-2 · at 5.0 s · due in 99.0 ms` · a real note on the engine's ReaRoute input paired with its
message. **NOT YET MEASURED: the score's lead over its own sound** — that needs Web MIDI, which only the composer's own browser has.

## The lines a stack file must change, per piece

*(First entries: the message route, 4.2 — proven in the Decibel piece's 6.2 commit of 2026-10-04, its RUNNING_LOG §60.)*

**The piece's score server (`score/server.js`) — three lines:**

| # | the line | where |
|---|---|---|
| 1 | `const elecRelay = require('../electronics/tools/relay.js')({ configFile: path.join(__dirname, '..', 'bank', 'elec_route.json') });` | with the requires |
| 2 | `if (url === '/api/elec') return elecRelay(req, res);` | the first of the API routes |
| 3 | `if (url.startsWith('/electronics/')) { base = path.join(__dirname, '..', 'electronics', 'score'); rel = url.slice('/electronics'.length); }` | in the static block, beside `/bank/` |

**The piece's composer page (`score/public/composer.html`) — two lines:**

| # | the line | where |
|---|---|---|
| 1 | `<script src="/electronics/le_msg.js"></script>` | after the last panel's script tag |
| 2 | `if (window.LE) LE.noteOn(inst.port, wc.layer, wc.id, wc.startSeconds, onAt);` | in `tickCurvePlayback`, right after the note-on is handed to Web MIDI. **THE TEST HOOK** — it goes when the mic opening is a brick of its own (4.3) |

**The piece's route table (the Decibel piece: `bank/elec_route.json`) — one block:**

```
"message": { "host": "127.0.0.1", "port": 57211, "testOnsets": true }
```

`testOnsets` is the test hook's switch: while true, a note the page plays on a player's MIDI port also tells the engine its onset.
The table is read at every request — a change needs no restart.

**Two facts of the take:** a score server started BEFORE its three lines existed has no route — restart it once · a page served
by such a server gets no `le_msg.js`, `window.LE` is undefined and the hook is skipped: nothing breaks, nothing is sent.
