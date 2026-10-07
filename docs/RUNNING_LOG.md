# RUNNING LOG — the lab journal of live-electronics-system

> **Why this exists** (composer, 2026-09-03, said at the opening of piece #5 and standing
> since): *"I'd like to keep a running journal like lab notes, so I can look back on
> decisions or comments, theory, philosophy, etcetera, or how we actually made something —
> if I wanted to write a paper later about this. And I would expect the AI agent to do this
> automatically as a habit."*
>
> Rules (from `live-electronics-engine`, piece #5's D4, carried here): written **as the work
> happens**, at the end of any exchange that produced a decision, a result, a rejection, a
> measurement, or a theoretical point — never at session end. Each entry: what prompted
> it, in the composer's words; what was tried, in order; the numbers; what was rejected
> and why; what was decided and why that rather than the alternative. **Append-only;
> corrections are new entries.** Entries are numbered §N and never renumbered.
> Current state lives in `PROJECT_JOURNAL.md` §2 and `PLAN.md`; this is the trail.
>
> **The engine is built while a piece is composed, so two logs run together:** what settles the ENGINE goes here; what settles
> the PIECE goes in the piece's log; each cites the other. The test: could someone write the paper "how this engine was made"
> from this log alone?
>
> **A `§N` in this file is THIS repo's.** Another repo's lab journal is cited as `#N §M`
> (`#6 §805` = `septet_LGMF_2026/docs/RUNNING_LOG.md` §805).

---

# 2026-10-03 — session 1 (Fable, in piece #6's session; the repo made from there)

## §1. The project opens — part 1 of the plan built: the repo, the kit, the plan

**Where it was planned:** not here — in piece #6's lab journal, at the `/postclear` after that repo's checkpoint #4, in place of
the go for the Decibel piece's set-up. The composer's opening words (`#6` LG-348, verbatim there):

> *"Okay, let's have a pre-conversation first. I want to develop a clear set of objectives and a clear plan or route to getting
> to the object objectives. So there are three pieces on the slate right now. The decibel piece, the switch, ensemble switch
> piece, and the live electronics with improviser piece. All three will share a live electronics engine. And that'll be it in
> itself a sort of port from the experimental work I was doing in the live electronics. So that needs to be developed. …"*

**The talk, in order (`#6 §805 … §813`):** his brief → the ONE decision put to him, where the engine lives (A its own repo · B inside
the first piece) → his probe: the components slot INTO the composer score and the notation, "does it still make sense to have
a standalone part?" → the picture corrected: a MODULE SET with named SEAMS, additive, the piece's save the ground truth → his
statement of the process (built in the first piece, landing in the engine as built, the others take it, parallel work) →
the one precision: the files live ONCE on disk (a submodule; a junction and a copy-back rejected) → **A decided** → the eight
objectives agreed → his orientation question (the protocol written, not yet run; two plans live) → the route's ten parts agreed →
his scenarios checked (the growing collection · the graphics and live analysis · the composer-score paradigms · the mastering
chain · the playback route · OSC) → parts 11 and 12 added, the flexibility a RULE → his three words for the repo:
*"live-electronics-system (if available), public, push after every commit"* → part 1 laid out → his *"go here"*.

**What was built (part 1, this commit):**
- `LICENSE` (MIT) · `.gitattributes` carried byte-exact from piece #6 @ `06ce0ac`; a `.gitignore` written for a public repo.
- The method docs carried whole with one provenance line each (the protocol's 2.4): `AI_METHODOLOGY` · `SESSION_HYGIENE` ·
  `PLANNING_METHOD` · `HOW_WE_WORK` · `SESSION_PROTOCOL` · the `checkpoint` and `postclear` commands.
- The record docs from the home's skeletons (`composition-system/skeletons/`), filled for an ENGINE: `CLAUDE.md` · `README.md` ·
  `docs/PROJECT_JOURNAL.md` · `docs/PLAN.md` · `docs/PLANNER.md` · this file · `docs/NITS.md`.
- `docs/SEAMS.md` · `docs/TAKE.md` — each saying what it will hold (parts 3 and 8).
- **CLAUDE.md checked heading by heading against piece #6's** (principle 19): READ FIRST ✓ (+ his "he keeps his own time" of
  `#6 §806`) · Orient from docs ✓ (the sketch pad's line replaced by where the brief lives) · the lab journal ✓ (the composing
  extension kept, re-read for an engine built during composing) · **the morph notes — NOT carried** (the pieces' tool) · THE RHYTHM ✓
  whole · Apps ✓ (none of its own) · Reference repos ✓ · Git ✓ (his push rule) · Checks ✓ (none yet).
- **Not carried, by design, his to reverse:** `COMPOSITION_NOTES` (a musical idea about the electronics is an LG note in the piece
  that has it — the brief is `#6` LG-340 … LG-351) · `PERFORMANCE_NOTES` · `SWEEP_LIST` · `PROTOCOL_DEVIATIONS` (the protocol's
  runs are the pieces'; a deviation of THIS start is a line here) · `MORPH_NOTES`.
- **The home:** one entry in `composition-system/INDEX.md` under the module manifest (the engine its first member) and one line
  in its `LOG.md`. **The planning repo's lists: not touched** — only at his word.
- **Deviations of this start from the protocol's § 2, noted here (no register):** 2.1 the profile does not apply (an engine has no
  score type; its kind of start is "a port from a sandbox into a module set") · 2.3 the names: no ports, no Reaper guard, no piece
  chain — the repo's name alone · 2.5 the record docs cut to seven (above) · 2.6 the planning repo untouched.

**Nothing of code.** The pieces untouched. Next: the part he names.

## §2. His pick after part 1: part 9's first run — the Decibel piece's repo

**What prompted it:** after part 1, his *"What are next steps then?"* — then, on Opus, *"checkpoint here, then start the Decibel repo after clear"* (`#6 §815`).

**The structural shape he was given** (six steps, NOT an order in time — the order is his, `#6 §806`): a checkpoint of piece #6's repo · part 9's first run, the Decibel piece's repo by the new-piece protocol (a normal port: copy-forward · both layers · the scrolling score — his words, `#6` LG-348) · one read of the sandbox `live-electronics-engine`, independent of the port (what it is built on decides the sound seam) · parts 3 and 4 laid out, needing that read · part 5 the first sound — the trigger in the Decibel composer score and one filter heard on a live note; the FIRST TAKE, so part 8's recipe is written and proven there; needing the Decibel repo and parts 3 · 4 · then composing: parts 6 and 11 grow by need, 7 and 12 when notating comes, the other two set-ups whenever he wants them.

**Decided:** his pick — the checkpoint, then the Decibel repo. That run's record and its deviations register live in the Decibel piece's repo. **Here nothing is in hand** until the first take.

**Why the engine waits on a piece:** it has no app of its own; it is built where he hears it. The first code lands here from inside the first piece's folder (the submodule), at part 5.

# 2026-10-04 — written from piece #6's chat (Opus)

## §3. 9.1 — the Decibel piece's repo exists

**What prompted it:** his go for the Decibel repo in piece #6's chat, 2026-10-04 — the profile confirmed (*"yes … But yes, normal port"*), the repo's three answers (*"all a"*: `decibel_TENOR_2026` · public · push after every commit) (`#6 §816 … §818`).

**What exists:** `decibel_TENOR_2026` — the new-piece protocol's container 2 done: the kit only, no code. Its CLAUDE.md, its journal (D4) and its PLAN § 0 name this engine: taken as a git submodule by `docs/TAKE.md`, at parts 5 · 8, not at set-up.

**Written here:** PLAN part 9 `doing`, sub-part **9.1** added (the plan's rule: a sub-part at the moment it is needed).

**What it means for the engine:** nothing is in hand here yet. The first take needs the Decibel piece's copy-forward (its container 3 — the composer score must exist there) and parts 3 · 4 laid out here.

# 2026-10-04 — written from piece #6's chat (Fable)

## §4. The engine's seat in a piece REFINED at his word: a git SUBTREE at `electronics/`, not a submodule · part 5 re-read · THE SORTING

**What prompted it:** his brief for the Decibel piece (`decibel_TENOR_2026/docs/RUNNING_LOG.md` §2; `#6 §819`): *"I would expect AI to try to organize where everything goes as we're building it and how it sits in the system to try to organize that architecture as we go along. Or if we, you know, we need to have a conversation at any point about that. But I kind of want that to be done in the back end as much as possible. So I know we took a decision to keep the live electronics in a separate repo, but I don't want to have to fuss with that too much. I don't want that to become an extra administrative burden. So if we need to rethink that decision, I'm open to that."*

**The call (the AI's, at his word; his to reverse — the Decibel journal's D7):** the decision of `#6 §806` STANDS — one engine, this repo, built in the first piece where he hears it. Its one precision (`#6 §807`, a submodule, "the files live once on disk") is REPLACED: the engine's code lives inside each piece as ORDINARY FILES in `electronics/`, and this repo is kept in step by `git subtree push --prefix=electronics` at every wrap of a piece's session — the AI's step, never his; a piece takes the engine by `git subtree add` / `pull`.

**Why a subtree and not the submodule:** a submodule needs two commits per change (inside it, then the pointer in the piece) and a push of the inner repo BEFORE the outer, by every cold session — exactly the burden he named, moved onto the AI, where a missed step breaks a clone. With a subtree a session commits as always; a clone of the piece is whole; a missed `subtree push` costs nothing — the next one carries everything. Rejected: everything in the first piece and a split later (this repo would hold no code for weeks; the subtree gives it the history as it happens).

**What changes in this plan:** part 8 (the take) is written as a subtree recipe, `docs/TAKE.md` at its first use. **Part 5 RE-READ by his brief:** the first sound is a note CAPTURED at a mic opening and RETURNED beside the live note — the filter (the pedals of resonance) is the third object, not the first. **Part 11's first two members** named: the mic opening (a window on a brick: time · length · instrument · a CATEGORY) and the return (a banked sample placed near the live note by an algorithm). **Part 6's first effect:** the pedals of resonance — a folder `SynthDef_petalsOfResonance` exists under `C:\Users\jwloy\GitHub` (the spelling there "petals", his to confirm; a SuperCollider name — part 2's read of the sandbox says what it is built on).

**THE SORTING:** the boundary test is a standing practice in the Decibel piece's CLAUDE.md — does the code know THIS piece → the piece; does it work for any piece → `electronics/`. The AI places; he is told in one line. Every piece's CLAUDE.md carries it.

**Q2 answered in principle:** the pieces take the engine by subtree; proven at the first push. Where the first code is built: the Decibel piece's running order (its journal §2), steps 6 … 10.

## §5. Q1 ANSWERED — what the sandbox is built on; the sound seam's shape; the first object named in the Decibel piece (2026-10-04, Fable, in the Decibel piece's chat)

**What prompted it:** the Decibel piece's running order step 6 (its journal §2) — *"ONE READ of the sandbox … what it is built on
decides the sound seam."* His words, the brief for the first object, are in that piece's RUNNING_LOG §47 — the piece's; here the
engine's part.

**The read of `live-electronics-engine` (its CLAUDE.md · README · `docs/plan/next-session.md` · folder listings · two greps):**

- **Two layers.** SuperCollider 3.14.1 (sc3-plugins, Sediment): `synths/*.scd` — roads-cloud · grain-articulate · grain-spectral ·
  string-grain · elotonic-drum · feature-chain · process-chain · gesture-voice; `lib/grain-envelopes.scd`; rendered OFFLINE (NRT).
  And the browser, Web Audio: the playhead engine (freeze · backward · slow · loop), `perform.html`, five labs, `tools/serve.py` on
  8732 with store/list endpoints for his kept settings.
- **No live input path.** `SoundIn` appears nowhere in `synths/ lib/ tests/`; `getUserMedia` nowhere in `engine/`. The sandbox
  processes recordings. A live window's capture and its plain playback are NEW code for the engine, not a port.
- **His pedals of resonance is SC** (`SynthDef_petalsOfResonance.scd`: `input = SoundIn.ar(ibs)`; thirteen resonators × two banks) —
  a live-input SynthDef. He said it is for phase 2, not the first object.

**What it decides for the plan (the AI's reading, put to him; his word pending):**

- **Part 4, the sound path: SuperCollider REAL-TIME, fed by a piece's Reaper rack.** His rig is SC; his phase-2 processing is in
  this sandbox's lineage; his rule — *"should actually use the actual pipeline"* — means the simulation and the concert differ in
  ONE place, the input device (ReaRoute from Reaper here · a mic through the interface live). The Web Audio layer is not the live
  path.
- **The audio route's first candidate: ReaRoute ASIO** (SC's device; 16 channels each way; Reaper stays the mixer). Unverified on
  his machine — a check at the build.
- **Part 3, the message seam:** a loopMIDI port (`DECElec`) read by `MIDIIn`, or OSC through the piece's score server. Undecided;
  the AI leans OSC for the data it carries.
- **Part 2, the port from the sandbox, for the first object: almost nothing** — the SC boot and chain conventions. The clouds, the
  freeze, the labs follow with phase 2.
- **NEW for the plan — the sample index:** one JSON per piece, a row per banked sample (id · name · player · time · length ·
  category · file · the opening that made it); the schema, writer and reader are the engine's; the file and the samples the piece's.
  Where it sits in the twelve parts (part 4? part 11? its own?) — to be laid out with him.

**The first object's shape, in his words (piece §47):** an opening brick → the simulated input (MIDI → the sampled instrument in
Reaper) → recorded by SC to a buffer and a file → a second brick a few seconds later plays it back through the buffer player.

## §6. Part 4's output stage settled in principle: SuperCollider's master bus IS the output, live; a piece's Reaper only stands in for the players and the loudspeaker in simulation (2026-10-04, Fable; his question in the Decibel piece's §48)

Live: the engine's mastering chain (ported from the sandbox at part 2) → the interface; no DAW in the chain. Simulation: the
engine's output returns to the piece's DAW on one flat track (ReaRoute, Windows — the device forces the return) so the player
tracks and the electronics meet at one pair of speakers. The master is the engine's in both. A piece's return track carries no
processing — a rule for `docs/SEAMS.md` at part 3.

## §7. 4.1 BUILT as far as the machine allows — the seat by subtree, the SuperCollider code, its self-test; ReaRoute is not on the machine (2026-10-04, Opus, in the Decibel piece's chat)

**What prompted it:** his word in the Decibel piece — *"commit the rack too, then /checkpoint then build as much as possible independently no clear"* (that piece's RUNNING_LOG §50 · §51 has the piece's side: the rack's route job, its tool, the numbers from its rack).

**THE MACHINE, read first (4.1 a):**
- **ReaRoute is NOT installed.** `HKLM\SOFTWARE\ASIO` holds one driver, `UMC ASIO Driver` (his Behringer UMC 1820); Reaper's `Plugins` folder holds no ReaRoute file. It is an option of Reaper's installer — his hand.
- **Reaper runs on WASAPI** (`GetAudioDeviceInfo`: MODE WASAPI · OUT 01-02 · 44100 Hz · block 512; two hardware outs, two ins). ReaRoute's channels are offered when Reaper's audio system is ASIO (the set-up every source gives; not yet seen on this machine) — a second hand step, and `reaper.ini` shows the UMC ASIO driver was his setting before.
- **SuperCollider 3.14.1 runs headless from the command line and its build has ASIO:** `ServerOptions.devices` lists `ASIO : UMC ASIO Driver` beside MME · DirectSound · WASAPI · WDM-KS. So ReaRoute will be offered to it as an ASIO device the moment it exists. It lists NO WASAPI loopback device.
- **Rejected, a route with no install:** a WASAPI loopback (not offered by this build; it would capture his whole mix, not one player; and the engine's own output would feed it) · the engine on the UMC's ASIO beside Reaper (the interface has no internal loop — a cable would be needed). ReaRoute stays: it ships with Reaper, is sample-synced to it, and gives sixteen channels each way — one per microphone.

**THE SEAT, made and proven (D7 of the piece; this log's §4):** `git subtree add --prefix=electronics <this repo> main` in the Decibel piece, WITHOUT `--squash`. What was learned making it: a `git subtree push` can only fast-forward this repo's `main` if the piece's `electronics/` CONTAINS `main` — so the engine arrives in a piece WHOLE, its plan, journal and kit beside its code (`electronics/docs/…`, `electronics/CLAUDE.md`). Consequence, and the rule from now: **while a piece is the place of work, the engine's docs are edited in that piece's `electronics/docs/`** and reach this repo by the same push as the code; the stand-alone clone on his disk is a MIRROR, pulled after each push. A session that does edit the mirror directly is merged by `git subtree pull` before the next push. Without `--squash` because the engine's commits then ARE ancestors in the piece and a push needs no bookkeeping; the cost is this repo's few commits appearing in the piece's log. `docs/TAKE.md` now holds the recipe.

**THE CODE (all of it generic — it knows no piece):**
- `tools/sc.js` — finds sclang (the sandbox's rule: under Program Files, not always on PATH), runs a `.scd` headless, reads a LINE PROTOCOL (`LE_READY` · `LE_RESULT {json}` · `LE_ERROR` · `LE_INFO`), exit codes 0 · 2 no device · 3 no boot · 4 timeout. **The engine's server is on UDP 57210, never 57110** — an IDE he has open is never touched; a scsynth left on 57210 by a cut run is swept, and only that one.
- `sc/boot.scd` — the namespace `~le`; the modes `\sim` (ReaRoute) · `\live` (the interface in `LE_DEVICE`) · `\quiet` (no hardware in the path); four groups in order — in (a player's microphone onto the player's own bus) · fx · master · meter; `\sim` REFUSES with a plain line when ReaRoute is absent rather than fall back to a microphone.
- `sc/synths.scd` — `leIn` · `lePass` (dual mono, unity) · `leMaster` · `leMeter1/2` · `leLatency`.
- `sc/selftest.scd` · `check_route.scd` · `latency.scd` · `session.scd` · `devices.scd`.

**THE MASTER — where the "mastering bus" actually was.** His words (piece §48): *"I know we established a like a mastering bus built in SuperCollider for sound out."* The sandbox's SuperCollider has none (one `Limiter.ar(….tanh, 0.95)` closing `process-chain.scd`). The bus is in its BROWSER engine — `engine/playhead-engine.js`, its journal §113-114: voices → master → dry → high-pass 30 Hz (Q 0.71) → glue compressor (−18 dB · knee 6 · 2:1 · 30 / 250 ms) → safety (−1 dB · knee 0 · 20:1 · 2 / 100 ms) → out, with a reverb send and a tape-delay send joining before the safety. **`leMaster` is that chain TRANSLATED**, the high-pass and the glue switchable and OFF by default, the safety always on, then a hard clip at full scale. Off because 6.1's result is a note *untouched*, and because the translation carries the sandbox's NUMBERS, not its sound: Web Audio's compressor has a soft knee and its own make-up gain, `Compander` has neither. His ear decides at the processing. The two sends are not ported.
- **Rejected for the safety: `Limiter.ar`** — a true ceiling, but its look-ahead is added as latency to everything the engine sends. A `Compander` with the sandbox's numbers adds none.

**THE NUMBERS — `selftest.scd`, `\quiet`, 44100 Hz, block 64 (all three pass, exit 0):**
- **A · the pass-through is untouched:** a 220 Hz tone at −20 dBFS on a player's bus → in −20.0 dB · out −20.0 dB · **the largest difference between a sample in and the sample out: 0.0** (exactly equal).
- **B · the safety:** the same tone at +6 dBFS → out **0.0 dBFS at the onset** (the clip caught it) · **−0.1 dBFS settled**. The static curve predicts −0.65; it is −0.1 because a follower with a 2 ms attack and no look-ahead reads under a wave's crest (≈ 0.93 of it at 220 Hz). So the −1 dB is where the squeeze STARTS; the ceiling is the clip. The test's first threshold (< −0.3 dB) was the AI's guess and failed; it now asserts what the safety promises — never over full scale, and more than 5 dB under what came in.
- **C · the latency probe measures a delay it is given:** 512 samples + one block (64) = 13.061 ms expected · **13.061 ms measured** (nine clicks, the median).
- `\sim` today: `LE_ERROR ReaRoute is not installed …`, exit 2 — the check of 4.1 (a), automated.

**A trap in sclang, kept for the next builder:** an Event calls a function stored under a key when the key is used as a method name — but only if no real method has that name. `~le.halt(2)` would have run `Object:halt`. The namespace's functions are named clear of real methods (`leave`, not `halt`; no `free` · `add` · `play` · `stop`) and its data is read with brackets. Written at the top of `boot.scd`.

**NOT PROVEN — each needs ReaRoute on the machine:** the `\sim` boot · `check_route.scd` and `latency.scd` against a rack · whether Reaper lists ReaRoute's channels among `GetOutputChannelName` / `GetInputChannelName` (the piece's job finds them by name and refuses if it cannot).

## §8. 4.1 DONE — the crossing proven in the Decibel piece: unity, and two DAW blocks of latency (2026-10-04, Opus, in the Decibel piece's chat)

**What prompted it:** his two hand steps done there (Reaper 7.82 · ASIO · ReaRoute). The piece's side and every number: its RUNNING_LOG §54.

**For the engine:**
- **The `\sim` boot holds:** device `ASIO : ReaRoute ASIO (x64)`, 44100 Hz (Reaper's), the engine's block 64, sixteen in and out.
- **Where a DAW job finds ReaRoute — the one thing §7 could not know:** Reaper lists its sixteen channels at HARDWARE INDEX 512 … 527
  (ReWire's place), not among the device's own 0 … n−1. `GetNumAudioOutputs` does not count them; `GetOutputChannelName(512)` is
  "ReaRoute 1". A send's `I_DSTCHAN` and a track's `I_RECINPUT` take 512 directly (their low ten bits). Written into `docs/SEAMS.md`.
- **Unity, exactly:** one player passed through — heard −42.6 dB, sent −42.6 dB, back on the piece's return track −42.63 dB.
  **Reaper's mono fold of a stereo track is the half-sum**, so `lePass`'s dual mono at unity returns a note at the level it is heard at.
- **THE LATENCY: 23.22 ms = 1024 samples = two of Reaper's blocks of 512** (`latency.scd`, nine clicks, the median). One block per
  ReaRoute crossing; the engine's own 64 adds nothing measurable beside it. A property of the simulation, set by the DAW's block.
- **A warning for every piece's check:** a Reaper track's own meter (`Track_GetPeakInfo`) read BEFORE the fader on that rack — the
  first verdict compared against it and reported a 15 dB loss that did not exist. The reference is the DAW's master with the engine
  off, and the engine's own meters.
- `session.scd` run as the launcher runs it: booted, heard a note, reported it, stopped; no process left.

**4.1's sub-steps (a) … (f) are done.** Not claimed: the composer's ear. Next: 4.2, the message — a talk first.

## §9. A FAULT OF THE RUNNER, found by its damage — it swept every server on the port; and the first listening aid, `leEcho` (2026-10-04, Opus, in the Decibel piece's chat)

**What prompted it:** the composer, of the pass-through: *"I just don't hear the return. And plus I want it to be explicit anyways."* The
piece's RUNNING_LOG §55 has the order of the readings.

**The fault:** `tools/sc.js` ended every run with `sweep()` — *remove any scsynth on UDP 57210* — meant for a server orphaned by a run
cut short. But a run that boots NO server (`devices.scd`, behind the piece's look-only probe) swept too, and took down the engine he had
started in his own window. The meter reading taken next (the return track at −154 dB) measured that, not his complaint.

**The fix — three rules of the runner now:**
- **`sweep(pid)` removes only a scsynth whose PARENT is the sclang this run started.** Nobody else's.
- **A file that boots a server is refused while an engine is up** (`engineUp()`; `opts.boots === false` marks `devices.scd`).
- **A piece does not list the audio devices beside a live engine** — PortAudio's ASIO listing loads every driver, ReaRoute among them.

**`leEcho` — a player's bus to the master, `time` seconds LATER** (`DelayN`, to 4 s; dual mono, unity), chosen by `passThrough`'s third
argument and `session.scd`'s `LE_ECHO`. Why it exists: a pass-through returns two DAW blocks behind the note (§8) and the ear takes
the two for one sound; a return must be HEARD to be judged. It is an aid for the route, not an effect of the engine's brief — the
capture and the playback (4.3 · 4.4) replace it.

**Proven** (the piece's §55): with `LE_ECHO=1` the engine's out trails its in; the piece's return track carries −42.62 dB; the piece's
`meters` command leaves the engine up; `selftest.scd` still passes.

## §10. 4.1 HEARD — the composer's ear closes it (2026-10-04, Opus, in the Decibel piece's chat)

His words there (its RUNNING_LOG §56): *"I hear it now, let's go on to 6.2"* — a note, and the same note one second later out of the
engine (`leEcho`, the listening aid of §9). 4.1 is closed by the meters and by the ear. The notes toward 4.2, the message, are in the
piece's §56: a MIDI port carries the trigger on the notes' own clock but almost no data; OSC carries any data but no clock; a third shape
sends the data ahead and the trigger by MIDI. Not decided — the talk is next.

## §11. 4.2 BUILT — the message route: the engine's ear on UDP 57211, the OSC encoder, the relay, the page's voice; proven in the Decibel piece to the edge of Web MIDI (2026-10-04, Opus, in the Decibel piece's chat)

**What prompted it** (the piece's RUNNING_LOG §57 … §60; his brief is its sketch pad's DEC-8): *"we're going to need to talk in terms of
the actual performance engine and then how we simulate it … let's make sure there's correspondence at least"* and *"Browser runs on the
iPad … and the live electronics runs on a separate laptop."* So the message from a score to the engine is a NETWORK message, in concert
and in simulation alike (the piece's D10). His word to the layout: *"a, write it"*; to the build: *"build here no clear"*.

**What was built — all of it generic, so all of it here:**

- **The ear** (`sc/boot.scd`): `~le[\msgPort] = 57211` · `~le.openEar` opens that UDP port on the LANGUAGE (pinned: sclang's own port
  moves when another sclang is open) and answers `/le/hello` with `/le/hello.reply` · `~le.hear(kind, func)` registers `/le/<kind>` and
  hands `func` the message's NAME, VALUE pairs as an Event, with the time the language received them.
- **The onset probe** (`sc/synths.scd` `leOnset` · `boot.scd` `~le.onsetOn`): a rise out of silence above −60 dB on a player's bus,
  told ONCE to the language (`/le/heard`). With a message's arrival time it gives the LEAD — how long before its own sound a message
  came. Good to about one block of the audio device.
- **The session** (`sc/session.scd`): shows `/le/onset` as one line; when that player's sound then arrives, a second line with the ms
  between them, and one `LE_RESULT` line for a tool. New: `LE_SECONDS` (a bounded run) and `LE_MODE=quiet` (no hardware).
- **The OSC encoder** (`tools/osc.js`): encode · decode · `send` over node's own `dgram`, about a hundred lines, no dependency. Its
  self-test compares against bytes written out by hand from the OSC 1.0 specification.
- **The relay** (`tools/relay.js`): what a piece's score server mounts at `/api/elec` — a page's `{ kind, data }` becomes `/le/<kind>`
  with its pairs. The address comes ONLY from the piece's route table, never from a request. An onset is answered at once (UDP gives no
  receipt, and a score must not wait on one); a `hello` waits 400 ms for the engine's answer.
- **The page's voice** (`score/le_msg.js`): `LE.send(kind, data)` — it never throws and never waits · `LE.hello()` · `LE.noteOn(…)`,
  THE TEST HOOK: a note the page plays on a player's MIDI port becomes `/le/onset`, while the piece's table says `testOnsets`.

**The message's form, and why:** `/le/onset  player bcl  lane 1  id wc-2  t 5.0  dueMs 98.6` — NAME, VALUE pairs, not positions. A
positional message breaks every reader when a field is added; the capture (4.3) will add a length and a category, the playback a
sample's name. The pairs cost a few bytes and buy that.

**The numbers** (the piece's `probes/elec_message.json`; its §60):
- `selftest.scd`: D the ear — every field back, the hello answered · E the onset probe — a tone started 100 ms after its message is
  reported 118.0 ms after it (the server on the machine's default device; 90 … 250 passes).
- `/le/hello` and back: 0.71 ms through the piece's score server · 0.5 ms asked from the page.
- The composer page's own playback, through its one hook line: the engine shows `onset · bcl · lane 1 · brick wc-2 · at 5.0 s · due in
  99.0 ms` — the page schedules a note up to 100 ms ahead, and the message leaves at that moment.
- A real note on the ReaRoute input, paired with a message sent before it: `heard · bcl · its sound arrived 536.6 ms after its message`
  (that lead is PowerShell starting — the tool's own note, not a score's).

**NOT MEASURED, and why:** the score's lead over ITS OWN sound. The proof drove the composer page in the desktop app's browser pane,
which has no Web MIDI: the hook fired and the message arrived, but the note went to a stub and made no sound. The measure needs the
composer's Chrome on a score server that has the route. His engine window writes it down when it happens (the piece's `tools/elec.js
start` appends each pairing to `probes/elec_message_log.jsonl`). Expected, NOT claimed: the 0 … 100 ms the page schedules ahead, plus
the sampler and one DAW block.

**Rejected:** a MIDI port as the trigger — no concert counterpart · a WebSocket — a dependency, for a speed the messages do not need ·
a shared clock — the crop (4.3b) finds the attack, so a message need only be early · positional OSC arguments — above.

**Two faults met in the build** (the machine's, kept for the next builder): a doubled backslash typed into a shell heredoc reached
the file as ONE, so a splice script wrote `~le[msgPort]` for `~le[\msgPort]` and sclang stopped at the parse with no `LE_` line at all
(the runner's only sign was its timeout, exit 4) — **a file that carries backslashes is written by the file tool, never through the
shell** · a shell command over about 8 KB fails with a false "matching quote" error.

**Open, noted for the performance module (not now — his word, DEC-8):** in concert there are several tablets, each with its own
clock and playhead — WHICH page sends a message, and how a duplicate from a second page is ignored, is that module's question. The
message's `id` is there so the engine can tell.

`docs/SEAMS.md` has the message half and the first rows of "the lines a stack file must change"; `docs/TAKE.md` step 2 names them.

## §12. 4.2 DONE — the lead measured on the composer's Chrome: 114.2 ms (2026-10-04, Opus, in the Decibel piece's chat)

The one box left open in §11. The composer played a bass clarinet note from his composer page (his Chrome, Web MIDI; his score server
restarted so that it had the route; his own engine window). The engine's two lines, and the pairing kept by the piece's tool: the
message left **92.8 ms** ahead of the note's own start; the note's sound reached the engine **114.2 ms** after the message — so **21.4 ms**
from the note's start to its sound at the engine's input (the sampler, the DAW's block, the probe). One note; the piece's
`probes/elec_message_log.jsonl`. A message is at the engine about a tenth of a second before the sound it announces, with no clock shared.

**A note on method** (the piece's §61): the measure cost the composer four hand steps for one number, after the route had been proven
without him. A check that needs the composer's hands is offered, not assumed.

**Next here:** 4.3 the capture · 4.3b the crop · 4.4 the playback · the index — proposed to him in the piece as ONE build, the first
object end to end (the piece's §61). Not decided.

## §13. 4.3 · 4.3b · 4.4 · the index LAID OUT — the engine's half of the first object (2026-10-04, Fable, in the Decibel piece's chat)

His word there: *"a, write it"* (its RUNNING_LOG §61 · §62). The four are built as ONE in the piece (its 6.3 … 6.6); `docs/PLAN.md` part 4
has the generic forms. **The engine's own decisions in it, each a default the composer's ear may move:**
- **The capture runs from the message to the window's end** — `dueMs/1000 + length` seconds. Nothing is scheduled and no clock is shared:
  the message is early (§12: about 100 ms), and early is right.
- **The crop is done by the engine itself, in the language, on the recording's samples** — so the engine is whole without a piece's
  server (his aim: *"eventually, ideally, it would be a standalone"*). The rule: the attack is the first rise above −30 dB below the
  recording's peak AND above −50 dBFS, with 5 ms of pre-roll; the end is where the level stays below −45 dB below the peak for 50 ms, or
  the window's end; fades of 2 ms in, 10 ms out. A window with no attack is reported, not saved.
- **The index's place — ANSWERED:** the file sits in the PIECE's bank (the samples are the piece's); its SCHEMA is the engine's.
- **The bank's folder is given to the engine at its start (`LE_BANK`), never in a message** — the same rule as the relay's address (§11).
- **The playback is scheduled on the engine's clock `dueMs` after its message** — the lead compensates itself; a sample lands where its
  brick is to within the network's jitter. At UNITY.
- **The composer-score objects (part 11) are ZONES WITH A NEW MODEL in a piece's score, not a new object type** — the reason is the
  pieces' shared composer page, which has no registry of types (the piece's §62).
**Rejected:** the crop in Node · a capture scheduled to the brick's exact start. **Not built yet** — the build is the piece's next step.

## §14. 4.3 · 4.3b · 4.4 · THE INDEX · THE FIRST TWO OBJECTS — BUILT AND PROVEN: a note captured, cropped, banked, returned; and a fault of the runner closed (2026-10-04, Opus, in the Decibel piece's chat)

*(The piece's side of the same build — its hooks, its tool, its demo score, the composer's questions about the engine — is its
RUNNING_LOG §64. This entry is what is the ENGINE's: machinery any of the three pieces takes as it is.)*

**His word there:** *"ok, window closed — go ahead with the build"*, then *"and please move thru the whole build independently"*.

**WHAT WAS BUILT, in the order it was proven.**

1. **`sc/synths.scd` — two synths.** `leCapture`: `RecordBuf` of a player's bus into a buffer, once, freeing itself when the buffer is
   full. `leSample`: `PlayBuf` of a buffer to the master, dual mono, unity, freeing itself at its end.
2. **`sc/bank.scd` — the bank, a file of its own, loaded by `boot.scd`.** `bankOn(dir, cropOpts)` · `bankHear` (the kinds `open` · `play`) ·
   `captureOpen` · `captureDone` · `cropFind` · `cropTake` · `indexRead` · `indexWrite` · `samplePlay` · `safeName` · `wavWrite` · `nowIso`.
   - **The recorder starts in the same breath as its buffer:** `Buffer.alloc`'s completion message IS the recorder's `/s_new` — no
     round trip between the message's arrival and the first recorded sample. (A `sync` first would have cost one hardware block.)
   - **The recording comes back to the language through `loadToFloatArray`** (the server writes a temp file, the language reads it);
     the raw and the cropped files are then written BY THE LANGUAGE (`SoundFile`, WAV, 24-bit, mono) — one read from the server, the
     crop on the numbers themselves, no second pass through the server.
   - **The crop reads the level in steps of one millisecond** (the loudest sample of each), finds the first step over the threshold,
     then the first SAMPLE over it inside that step. The end needs `holdMs` consecutive low steps — a low note's zero crossings dip a
     1 ms step by a few dB and must not end the sample.
   - **The index is rewritten whole at each capture** from the rows in memory; read at `bankOn`. sclang's JSON reader returns every
     value as a string: the schema's numbers are converted back by name. **An index that fails to parse is never written over** — the
     sample is still saved, and the engine says so.
   - **The return is a time-stamped bundle** (`makeBundle(dueMs/1000, …)`): the server starts the sample `dueMs` after the language
     received the message, to the sample, whatever the language is doing.
   - **A name is a file name** — `safeName` keeps letters, digits, `-`, `_`. The bank's folder is never taken from a message.
3. **`sc/session.scd`.** `LE_BANK` · `LE_CROP` (`key=value,…`). **A player's own sound no longer goes to the master.** Until now the
   session passed every player straight through (4.1's proof), then one second late (the listening aid of §9). With a sample to
   return, a straight copy of the player two DAW blocks behind is not "the electronics" — it is a comb on the live sound; in concert
   it would be the dry microphone in the PA. So: nothing passes unless asked — `LE_PASS=1` (straight) and `LE_ECHO=n` (n seconds
   late) remain as ROUTE CHECKS. *The AI's call; the piece's plan said only "the listening aid is retired".*
4. **`sc/selftest.scd` — two more tests, seven in all.**
   - **F · the crop.** A 0.6 s array: noise at −80 dB; at 0.200 s a 220 Hz tone, 1 ms to rise, a 60 ms time constant.
     **Found 0.16 ms from where it was put**; the sample starts at 195.1 ms (5 ms of pre-roll), ends at 512.8 ms (the −45 dB point of
     that decay is 511 ms); silence alone is refused.
   - **G · the first object, end to end, no hardware.** `/le/open` (dueMs 100, lengthMs 400) to the ear; a 440 Hz burst put on the
     player's private bus 200 ms later. **Raw 0.500 s · the attack found at 188.8 ms · 147.5 ms kept · peak −20.1 dB · one row in the
     index, read back by the language's own parser · `/le/play` → −20.1 dB at the master: unity to the tenth of a dB.**
   - All seven passed at the FIRST run of the new code.
5. **`score/le_objects.js` — the mic opening and the return** (part 11's first two). Zones with a model of their own; the reasons and
   the shape are `docs/SEAMS.md` § the composer score. Three decisions made at the build:
   - **`zoneFunction: 'elec'`, not `midiPreview`** (the piece's plan had copied the trill's call). A `midiPreview` zone is offered the
     MIDI models' rows in the panel — a model picker without these two in it, a player list from piece #2 — and takes part in the
     zones' mute / solo. With a function of its own the host's panel shows the zone's four plain rows, and this file's section.
   - **The tick is the file's own, called beside the MIDI playback** (the piece's plan put the message inside the zones' MIDI tick).
     That tick returns at once on a page with no Web MIDI — and in concert the page is a player's tablet: no MIDI is the NORMAL case.
     The correspondence rule (the piece's D10) decided it.
   - **An opening the playhead starts inside still opens**, for the rest of its window. The window begins 100 ms before its note; a
     composer who parks the playhead on the note and presses play is inside it.
   `score/le_msg.js` lost its test hook (`LE.noteOn`); `LE.playerOf` stays — the objects read a lane's player with it.

**IN THE DECIBEL PIECE'S RACK** (its `tools/elec.js object`; the numbers are in its `probes/elec_object.json`): a bass clarinet note
(D3, 1.5 s) played into the rack by a tool, a 4000 ms window opened by message just before it → **raw 4000 ms, peak −41.2 dB → the
attack found 575 ms in (the tool's own start-up) → 2476 ms kept (the note and its release) → on the return track −41.22 dB: unity.**
Then the piece's composer page, in a throwaway copy: its own playback sent `open` 89.3 ms ahead and `play` 85.9 ms ahead; the engine
showed both and the sample came back through the rack.

**A FAULT OF THE RUNNER, FOUND BY THE BUILD'S FIRST RUN.** The composer had closed his engine's window; the runner still refused —
"the engine is already running". **What was there:** one `scsynth` on 57210, its parent a `cmd /c "…scsynth.exe …"` wrapper, the
wrapper's parent (the sclang) GONE. On Windows sclang starts its server through `cmd`; closing the console window ended node and
sclang and left the wrapper and the server — holding the port and ReaRoute, with no language to speak to it. Every start after
that would have been refused, his own `start` included. *And the runner's own sweep had been comparing a server's PARENT with the
sclang's pid since §9 — the parent is the wrapper, so it never matched; it had been a no-op, hidden because a run that ends
normally quits its own server.* **Closed three ways:**
- `tools/sc.js` reads each server's OWNER — one step above the `cmd` wrapper — and whether that owner is a living `sclang`.
- **`engineUp()` is true only for a server whose owner lives.** `sweepOrphans()` removes one whose owner is gone, before a start.
  *This does not loosen §9's rule (a probe once took his engine down): a living engine is still never touched. An ownerless server
  is no one's engine.*
- A piece's start tool ends its engine on the window's close (`SIGHUP`), `SIGINT`, `SIGTERM`, `SIGBREAK`.
**Proven:** the leftover was seen as `ownerAlive: false` and removed by the next run · an engine started in a console window of
its own and closed as the X closes it: no SuperCollider process left · `SIGTERM`: the same.

**NOT CLAIMED.** His ear — on the return (does it read as the note's attack?) and on every number of the crop. The crop on a soft
or a slow attack (a −30 dB threshold under the peak lands late on one that takes 50 ms to rise — the pre-roll is 5 ms). More than
one player at once. The concert's device (`\live`).

**For the paper.** The first object is a small closed loop that already has the shape of the whole instrument: the SCORE knows
WHEN and WHO (a brick on a player's staff), the ENGINE knows WHAT (the sound it heard, reduced to its attack), and the only thing
that passes between them is a name and a lead time — no audio, no clock. The same two messages serve the concert unchanged; what
the simulation replaces is the microphone and the loudspeaker, nothing else.

## §15. THE MODES, THE SAFETY NET, A GRACEFUL LEAVE — from the Decibel piece's step 8 (2026-10-05, Fable; the piece's RUNNING_LOG §71 has his words and the measurements)

**What is the engine's here:** `bankOn(dir, crop, source, record)` — the buffers FILLED from `source` at start (the bank itself, or a backup bank with the same
names), captures WRITTEN to `dir`, `record = false` makes an opening change nothing (`LE_SOURCE` · `LE_RECORD`; `indexRowsOf` reads any folder's index).
THE SAFETY NET: a capture with no attack above the floor leaves the buffer as it was — loaded or earlier — and says so (`kept` in its result); its analysis is
to be made foolproof before a concert (the piece's NITS). `/le/leave`: the language quits its server (the device closed properly) and exits — a tool's
run ends on it, the kill a fallback. `tools/crop_report.js`: a page per crop — the raw envelope, the kept region, the attack, the sample, both playable.
**What the piece's is:** the mode word and the folders (`bank/elec_route.json`), the kinds tested, the impulses' names.

**Measured in the piece (seven kinds through its rack, the defaults):** the impulses keep 0.7 … 1.0 s — the end rule (−45 dB of peak, 50 ms) runs into the
instrument's room; a swelling multiphonic's "attack" is found at the swell (1.3 s in); a 2 s flute tone keeps 2989 ms (the release).

**A rule, learned the hard way:** an engine on ReaRoute ended with `taskkill` left ReaRoute's client side wedged — every later boot came up and hung at its
first `s.sync`; Reaper's `Audio_Quit/Init` did not free it; only a Reaper restart does. Hence `/le/leave`. And a note sender killed mid-note leaves a stuck
note in the sampler — a sender finishes on its own now.

## §16. THE ROW-MAKING REPORTS ITS OWN FAILURE — from the Decibel piece's step 8 (2026-10-05, Fable; the piece's RUNNING_LOG §74 has the facts)

In the piece a capture once ended with the cropped file on disk and NO ROW in the index (`bfl-impulse-1`, 08:29:23; a 265 ms raw,
peak −36.9 dB, a first take), and the window said nothing a reader could use. Read, not solved: `captureDone` (`sc/bank.scd`) writes
the file, builds the row, adds it, writes the index; the rows are a `List`; `indexRead` runs only at the bank's load; the next
capture's index write carried every row in memory — so the row never got in, and whatever threw between the file and the add was
lost. **Done:** the row-making sits in a `try`; on an error the engine says `LE_ERROR the row of <name> was NOT made — the sample is
saved as <file> · <error>` and sends a `captured` result with `rowError`, `file`, `raw` — the page sees it. The cause is still to be
read from the window the next time it happens. No change to the capture, the crop or the index format. Not tested (the piece's D13).

## §17. THE FIRST BEHAVIOUR OF A RETURN — `ar`, anticipation-reaction, rolled live; a player's several ports (2026-10-05, Fable; from the Decibel piece's step 9 — its RUNNING_LOG §75 … §78 and DEC-9 … 9c have his words)

The engine is now ONE MORE PERFORMER with a bank and behaviours (the piece's D14). The first behaviour, `ar`: a `/le/play` with
`behaviour ar` points at the brick's CENTRE (`t`, `dueMs` — the live note); the engine rolls a stance — just-before · just-after ·
lazily-after · near-unison — and an offset inside that stance's range, drawn skewed to the fast edge (`u^skew`); a just-before
can MISS (late, or far too early). Rolled HERE at every playback, never in the page (the piece's D15): the score stays still,
the simulation runs the same dice. `arDefaults` in `sc/bank.scd`; a piece overrides them with `LE_AR` (session.scd), flat names
`before · after · lazy · unison · afterLo/Hi · beforeLo/Hi · lazyLo/Hi · unisonLo/Hi · skew · missRate · missLateShare ·
missLateLo/Hi · missEarlyLo/Hi`. Each roll is one line in the window and in the result (`stance`, `offsetMs`). The page
(`score/le_objects.js`): `elec.behaviour` on a return — the panel's Behaviour select, the region ±`arRegionMs`, the message at
the region's start. A player may own several MIDI ports (`players[].ports`; `le_msg.js` `playerOf`, `tools/relay.js`): one
microphone, two lanes. Not tested (the piece's D13); the roll's arithmetic is five lines. Taken from the piece's #2 lineage:
the bands' floors (80 / 100 ms), a separation, three-body's accuracy as the tight share and its air shot as the miss.

## §18. THE SECOND BEHAVIOUR — `chain`: the samples follow the live note one after another, the order rolled (2026-10-05, Fable; the Decibel piece's RUNNING_LOG §80 … §82, DEC-10 · 10b)

`/le/play … behaviour chain names a,b`: `chainRoll` scrambles the order (I), then link by link takes as reference the previous
link's rolled time (H = 1) or the live note (H = 0; between, a coin), rolls a follower's stance from G (after · lazy · unison; no
before) and a distance from ar's B draw; the error accumulates down the chain. Each link is scheduled from the message's `dueMs`
(the live note), said in one window line, and listed in the result. Defaults `chainDefaults`; a piece overrides with `LE_CHAIN`
(`after · lazy · unison · before · follow · shuffle`). The page: `elec.names` on a return brick, the brick from the live note
forward 0.5 s per sample, a "Samples, in order" field. Not tested (the piece's D13).

## §19. THE INDEX LOST EVERY FIRST TAKE'S ROW — `reject` then `add` on a full Array (2026-10-05, Fable; the piece's RUNNING_LOG §84)

In the piece a first take of any name wrote its file and never its row; a re-take always did. `captureDone` rejected the old row
by name and then called `add` without taking the result: after `reject` the collection is exactly full unless a row was removed,
and `add` on a full Array returns a new one. Fixed by making the rows a List (`.asList`) before the add. The `try` of §16 stays —
it names a real exception when one comes.

## §20. THE THIRD BEHAVIOUR — `arChain`: one sample around the live note, the rest chained after it; the bands at the composer's ear (2026-10-05, Fable; the Decibel piece's §87, DEC-11)

`chainRoll(names, arFirst)`: with `arFirst` the first link is the ar roll against the live note (before · after · lazy · unison ·
a miss), the rest follow the previous link as the chain does. `/le/play … behaviour arChain names a,b,c`, `t` · `dueMs` at the
live note; the page sends it from the region's start, 400 ms ahead. The bands are the piece's dials (LE_AR), not the engine's
defaults: this piece widened its after band ×1.5 and pushed the rest out — the defaults stay for the next piece's ear.

## §21. `*` IN A CHAIN — every sample the bank holds at playback (2026-10-05, Fable; the Decibel piece's §89, DEC-12)

A name `*` in `/le/play … names` is replaced, at the moment of the roll, by every sample in the bank (sorted, then shuffled by
I when I says so): the composer's "every live input triggers all the samples from all the instruments recorded so far" — the
bank grows while the piece is composed, so the list is resolved by the engine, never written into the score. The page labels
the brick `ALL n samples` by its index; the length drawn is the index's count × a link.

## §22. THE ROLLS, HEADLESS — `sc/roll_test.scd`: the behaviours' arithmetic proven without a server (2026-10-05, Fable; the Decibel piece's §91)

`bank.scd` loads into a bare sclang (`~le = ()` and a `say` stub are all it needs), the piece's dials go in as the engine
receives them, and `chainRoll` · `arRoll` print their links: three per three names, every time; the stances and distances as
the dials say. The file carries the Decibel piece's dials of 2026-10-05 inline — edit them to a piece's own. Run:
`sclang.exe sc/roll_test.scd` (no server boots; the engine beside it is untouched). It answered the composer's "are three
samples played?" without his hands: yes; what he heard as one was a near-unison by design.

## §23. `chainNames` — the star before the scrub (2026-10-05, Fable; the Decibel piece's §94)

`safeName` scrubs a message's name to a file name, and `"*"` is not one: §21's check for it came after the scrub and never saw
it — an empty chain. The names a chain plays are resolved in one function now, `chainNames(names)`: the star is looked for in the
raw list and becomes every sample the bank holds; the rest is scrubbed as before. Found by CONTENT: an Array's includes() is identity in SuperCollider and never matches a String. `roll_test.scd` proves the four cases headless.

## §24. BEHAVIOUR `pattern` — a composed rhythm on a return brick, no dice (2026-10-05, Fable; the Decibel piece's §97, DEC-15)

The fourth behaviour of the return, and the first that is NOT rolled: the page composes, the engine obeys. `sc/bank.scd`:
`patternOnsets(pattern)` turns the message's `pattern "name:atMs,…"` into onsets (names through `safeName`, times clipped at 0,
nameless pairs dropped); `samplePlay`'s `behaviour pattern` branch schedules each from `dueMs` in a bundle, one window line per
onset, the result carrying the count and the pattern. `score/le_objects.js`: the fifth Behaviour option; the samples picked by two
rows of boxes derived from the bank's index (the players × the tags after their prefix; no pick = the whole bank at playback);
the dials `elec.rhythm` (shape even · front · back · centre · edges · accel · rit · random · span · gap · jitter · order · seed);
Generate → `elec.pattern = [{ name, atMs }]` from the brick's start; `fire` sends ONE `/le/play` with the pattern.

**The generator is this module's own** (`rhythm(n, cfg)`, ~20 lines, mulberry32-seeded): the Decibel stack's Strikes drawer has a
richer one, and it was NOT lifted — the engine's page module may lean on no file of a piece's stack (the boundary, objective 6);
what it needs, it carries. Proven headless both sides: `sc/roll_test.scd` (the parse, four cases) and the module under a stub
window (six generates, one reproducible). The sound in the running app is the composer's, as he composes.

## §25. THE PATTERN BRICK'S FULL MENU — the host's calculators handed in, the samples dealt, a level per onset (2026-10-05, Fable; the Decibel piece's §98)

The composer wanted the Strikes drawer's whole rhythm part on the pattern brick — above all the accelerating run (first gap → last
gap) with its round robin. The run and the containers are pure modules of the piece's stack (`accel_calc.js` · `time_containers.js`);
**this module does not load them — the host hands them in at attach** (`opts.accel` · `opts.containers`), and a page without
them simply has no such shapes. That is the boundary kept the cheap way: the engine is given what it may use, never reaches for it.

`score/le_objects.js`: SHAPES (unison · even · front-loaded · back-loaded · centre · edges · random — its own; accel · round
robin · containers — the host's) · `runOnsets()` builds the drawer's spec from the brick's dials · `deal()` ports the drawer's
U13 dealing for samples (round robin by laps under a re-attack rule PER SAMPLE, or free dealing leaning to the longest wait) ·
`generate()` adds reverse · rotate · an order seed apart from the rhythm's · a level in dB per onset from the run's ramp.
`sc/bank.scd`: a message onset is `name:atMs` or `name:atMs:db` — `patternOnsets` reads the third field (clipped at +12 dB),
`samplePlay` gives `\leSample` its `amp`. Proven headless both sides (`sc/roll_test.scd`; the module under a stub window with
the two calculators required as node modules — eleven generates). The sound is the composer's to hear.

## §26. THE PROCESSING — the sandbox's chain ported, rendered OFFLINE, and a third object, the process brick (2026-10-05, Opus; the Decibel piece's §103, its PLAN 1.3 · 10.1; parts 2 · 6 · 11)

**What prompted it:** the Decibel piece's step 10 — the composer's notes there (its DEC-16 · 16b · 16c): each banked sample
transformed through a CHAIN of processes, "I am sitting in a room" style, each stage kept, a brick per stage; an ENVELOPE at
the render's end so a processed timbre can keep a struck shape; the effects to start from: the sandbox's, already built.

**What is the engine's (this log) and what the piece's (its §103):** the chain, the render, the brick's machinery and the
catalogue of effects are here; which effect at which stage, the dials, the workshop score and the rendered samples are the piece's.

**The port (part 2).** `sc/process.scd` — the sandbox's `\processChain` (`live-electronics-engine/synths/process-chain.scd`)
whole, as `\leProcess`: every stage, its order, its control names. Five changes, each because the result is a BANKED SAMPLE
and not a running layer: (1) MONO — the `space` stage (width · swirl) is out, the stereo reverbs are summed: the bank is mono;
(2) EVERY stage has a mix — the filter got one (`filtMix`) and the reverb's default is 0: in the sandbox both were always in
the path, right for a layer, wrong when a brick is ONE stage; (3) the spectral block is BYPASSED when smear · gate · freeze are
off — an FFT in the path delays the sound a frame and softens every attack; (4) FREEZE engages at `freezeAtMs` and its phases
are re-drawn at every frame (`PV_Diffuser`, hop 0.25): a short sample is followed by silence, and frozen magnitudes on
silence's phases are a buzz at the frame rate, not a held spectrum; (5) no tanh and no limiter at the end — the render is
floating point and the language sets the level — a DC blocker instead. Added: `rate` (the synth's own — a tape's speed) and
`rev` (read backwards). The sc3-plugins stages are looked up BY NAME as the synth is built: one not installed is left out and
named once; the file still loads.

**The render is OFFLINE (NRT) — decided at the build, against the lay-out's "real time on the running server".** Why: it is the
sandbox's own road for this chain on this machine (`build/audition/*.scd` — `Score.recordNRT`); a second scsynth with no device
and no port cannot glitch a performance or disturb ReaRoute; it is faster than real time (four renders in under 2 s); and it
is provable with no hardware beside a living engine — a real-time render could not have been tested while the composer's
engine was up. What it costs: the source is read from its FILE, not its buffer — every sample of the bank is a file already.
The language then finds the result's START (the first sample `floorDb` under the peak — a comb's or an FFT's delay is not kept
as silence at the head), ENDS it, sets its level, writes it with the bank's own writer, adds its row and loads its buffer.

**How a render ends (the composer's addition):** `shape` — an envelope AFTER the effect: attack · the level held · a release
on a curve (an `Env`'s formula; −4 = a struck sound's), the whole exactly `durMs` long; a release as long as the rest is a
pure struck shape. The processed TIMBRE and the ATTACK's shape are decoupled. `tail` — the effect rings out: the sample ends
at the last sample `floorDb` (−60) under its own peak, or is faded at `capMs` past the source when it never falls (a freeze,
a long feedback). LEVEL: `match` 1 sets the result's peak to the source's — a chain neither fades away nor runs hot — then
`gainDb`; held under full scale.

**A NAME MAY CARRY `~`:** a processed sample is `<root>~<n>` (`safeName` here, `safe` in the page). And `*` — "every sample
the bank holds" (§21) — now means every CAPTURED sample: a processed one is played by its own brick or by name; a render does
not change what a piece's "everything" plays (`chainNames`; the page's `picked()` the same for a pattern with no pick).

**The object (part 11.3).** `score/le_process.js` — a MIXIN on `LEObjects`, one more tag: `midiModel` `elecProcess`, a zone
like the other two. `elec: { source, out, label, effect, args, end, …, rendered }`; its panel — Source · Name · Label · Effect ·
the effect's dials · Ends by · Level · Render · ▶ hear it · ▶ its source · the whole setting as a JSON box; the CATALOGUE
(`EFFECTS`): eighteen entries, each the few dials that matter under the chain's own control names — a brick's `args` are
`{ controlName: value }`, which is what the message carries, so the engine needs no menu and the box can set ANY control.
Render sends `/le/process` with an id; the engine's row carries it back as `openingId`; the page reads the index until it is
there (no new return road — the bank's index is the answer, as for a capture). A rendered brick is played exactly as a plain
return. The label says when a brick is `not rendered`, `changed` since its render, or older than its source.
`le_objects.js` gained only the hooks: the model's row, the key, the label, the panel, the redraw, the tick, `~` in a name.

**What was tried, and what the proof found.** `sc/process_test.scd` — bare sclang, no server, a scratch bank in the temp
folder, a made-up 300 ms burst, four renders through the real chain. Two faults, both found by it:
- every render was made and none could be banked: `_SFWrite` "wrong type" — a whole-array multiply (`take * g`) hands back
  something the file writer refuses; the level is now set in place, sample by sample, and the array stays a `FloatArray`;
- a reverb's TAIL never ended: measured on the raw render — a steady −66.6 dBFS from 2 s on, a DC of −4.7e−4. `PlayBuf` at its
  buffer's end HOLDS the last value; the test's source ends off zero (a real capture ends on a fade, so this would have shown
  only on a `shape` with no release). The player is now shut at its end (`Done`), and a `LeakDC` at about 8 Hz closes the chain.
  With both, the reverb's tail is 1649 ms; Greyhole at feedback 0.8 is still above −60 dB at its cap, and is faded — correct.

Then: PASS — the envelope exact (600.0 ms asked and made), the peaks matched to 0.0 dB, a render of a render, an sc3-plugins
stage, the freeze still −10.7 dB under its peak a second after its source had ended, `*` leaving the processed out; the
messages given as Symbols, as OSC delivers a string. The page module under a stub window with the piece's workshop score and
its real index: the message of each stage, the panel built, a dial and the effect changed through their own handlers, a
render known by its id, the label's states, the tick, the key. A living engine beside both was untouched (its hello answered
before and after).

**Not claimed:** the composer's ear on any of it; the round trip through a living engine (his first Render — the engine must
be started after this build); the default dials, which are the sandbox's or the AI's guess. **Open by design:** the two
granular voices and his pedals of resonance (parts 2 · 6, by need) · a stereo bank and the `space` stage · a cascade (a stage
re-rendered re-rendering those made from it — the label already says which are stale).

## §27. A BRICK'S `yOffset` IS THE HOST'S FRACTION OF THE LANE — the process model's 2 drew it a lane too low (2026-10-05, Fable; the Decibel piece's §105, its SWEEP_LIST #5)

- **What:** `score/le_objects.js` `MODELS.elecProcess.yOffset` was 2 (§26's build). The first host, the Decibel composer page, places a zone at `top + (laneHeight − brickHeight) · yOffset` — a fraction, 0 the top of the lane, 1 the bottom. The opening is 0, the return 1; 2 fell a whole lane below, and the composer saw one purple brick and no orange ones. **Fixed: 0.5** — the three bricks stack top · middle · bottom.
- **For a second host:** the unit of a model's `yOffset` is the host's, not this module's. A host that places zones by rows or pixels maps the three values at its attach line (a seam to name in SEAMS.md when the second host comes; not added now — one host).
- **Proven once:** the module parses (`node --check`). The composer's eye on it: pending (the piece's §105).

## §28. NINE STAGES INTO THE CHAIN — Buffer Override written from its algorithm; the pedals, a cabinet, a true crusher, Chebyshev, two shredders (2026-10-05, Fable; the Decibel piece's §106 · DEC-17 · PLAN 10.5)

- **What:** `sc/process.scd` `\leProcess` gains nine stages, each a mix at 0 like every stage, so no brick made before this renders differently: `override` right after the noise bed; after `drive`: `overdrive` · `fuzz` · `octave` · `cab` · `crush` · `cheby` · `squiz` · `waveloss`. `score/le_process.js` `EFFECTS` gains their nine rows, in the chain's order. Nothing in them knows a piece.
- **Buffer Override, the algorithm (the original is Destroy FX's, GPL — nothing copied):** the input into a 4.5 s LocalBuf ring (`Phasor` · `BufWr`); a forced buffer every `ovrBuf` ms (`Impulse.ar`), its ring position latched; a mini-buffer of `ovrBuf / ovrDiv`, read 0 → length by a `Phasor` reset at each forced buffer: the FIRST mini-buffer repeats until the next forced buffer. A repeat every 1/f s is a tone at f. Smoothing `ovrSmooth` (0 … 0.5 of the mini-buffer): the head fades in under the tail (two `BufRd`, equal-power), and the repeat is shortened by the fade — the original's way. Two safeguards: the tail reader is silent during the first pass (the mini-buffer is still being written — it would read ring contents 4.5 s old), and both readers sit one sample behind the write head (no dependence on the server's order of the write and the reads). Rejected: a triangular-window two-reader loop — a comb, not the sound. Not yet: the LFOs, buffer interrupt, the MIDI pitch.
- **The pedals:** overdrive = the band above 720 Hz driven, the band below at 0.35 of it, tanh, a tone lowpass · fuzz = gain, a BIAS, a hard clip (one side first), the bias taken out at 40 Hz, a tone · octave = `abs` (rectified, its offset out at 30 Hz) blended by `ocOctave`, a hard clip · cab = a highpass, a +3 dB thump at 1.4 × it, a presence peak at 2.5 kHz, two lowpasses (steep) · crush = `Latch` at a rate, rounded to 2^(1 − bits) — own code, no Decimator · cheby = T2 … T5 as polynomials, the even ones WITHOUT their constant (a constant under silence would make a tail that never ends — §26's lesson) · squiz · waveloss through `opt` (left out and named where not installed).
- **The test (`process_test.scd`):** two cases added — `t-src~5` override (120 ms / 24 = 200 Hz) under a shape · `t-src~6` fuzz into the cabinet in ONE render (two mixes by the args). **PASS**, every check ok; "the chain is whole" — every stage installed on this machine.
- **Not claimed:** the sound; the dials (provisional, the composer's ear next — his method: build → hear → knobs → the library). A seam to remember: the dial ranges live twice (the page's rows · the stage's clips) — kept equal by hand.

## §29. `none` — the catalogue's first row is a pass-through (2026-10-05, Fable; the Decibel piece's §107)

- **What:** `score/le_process.js` `EFFECTS` gains `none` (no dials) at the top. Picking it clears a brick's dials; a render of it sends no args, so the chain passes the source (every mix at 0) under the END stage, peak matched. The composer's ask was a reset; the row is also a use — the plain sample re-shaped. The engine's code is untouched.

## §30. The process brick's dials: a slider each, log-scaled where the range is wide, and a hint table (2026-10-05, Fable; the Decibel piece's §108)

- **What:** `score/le_process.js` — `slider()` beside `num()` in the panel: live while dragged (no rebuild), one commit at release; a log scale when `max / min ≥ 50`, else linear; rounded to the dial's step. `HINTS` by control name — [what it does, the usual range]; `hintOf(d)` composes it with the dial's full range and puts it on the label, the slider and the box. The END stage's boxes carry hints of their own.
- **For a second host:** nothing here is the host's — the panel helpers (`el · rowEl · note · commit`) come in from LEObjects as before.
- **Proven:** parses; the arithmetic checked in node at the ends and the middle of six dial shapes. Not seen in a browser.

## §31. `feedback` — a loop of six unity-resonance strings, the amp's clipping, a colour and a path; the bloom set as a TIME (2026-10-05, Fable; the Decibel piece's §110)

- **What:** `sc/process.scd` gains the stage `feedback` after `cab` — the chain's only `LocalIn`/`LocalOut` pair. The excitation (the sample + the return) into six `CombC` strings at 1/f (1.5 s), each scaled by `1 − 10^(−3d/1.5)` so its resonance sits at unity and the loop gain is independent of the strings; the amp `tanh(x·drive)/drive` (unity small-signal, a ceiling 1/drive); a lowpass colour (+ a highpass at 120 Hz) that steers the winning harmonic; `DelayC` as the path; the loop gain per round trip from the BLOOM TIME: `(60 · (path + 64/sr) / bloom) dB`, held `fbHold` s then × 0.25 over 0.6 s. Climb = the colour up to 4× and the path −40 % over the hold; wobble = the path ±20 % on `LFNoise1.kr(1.5)`. No strings (all 0) = the excitation itself in the loop. `score/le_process.js`: the row with fourteen dials and their hints.
- **Why a time:** a feedback's loop gain is barely above 1 and a dial on it is unplayable; the time to grow 60 dB is what a hand can set.
- **Proven:** `process_test.scd`, the seventh case — the tone at 0.0 dB under the peak from 0.5 to 1.0 s with the source over at 0.35 s; 3825 ms long under a 4 s cap; PASS.
- **Not claimed:** the sound; the dials. Later, at his word: the strings as a chord box (a note name, not Hz), the sustained level as a dial.

## §32. Eight endings (Env.perc, the Roads grain envelopes), presets on a catalogue row, a RANGE as a dial's value (2026-10-05, Fable; the Decibel piece's §111)

- **The endings (`sc/process.scd` `processRender` · `processDone`):** `end` is one of shape · tail · perc · gauss · quasi · tri · expodec · rexpodec (an unknown word = tail; compared by content). Every non-tail mode takes `durMs` frames from the found start and draws its curve sample by sample: shape as before; perc = Env.perc's two curve −4 segments (atkMs up, the rest down); gauss = exp(−½((pos−0.5)/0.15)²); quasi = Gaussian quarters over a flat middle; tri; expodec = exp(−6.9078·pos); rexpodec = its mirror. The mode is switched as a Symbol.
- **Presets (`score/le_process.js`):** a catalogue row may carry `presets: [{ name, args, end? }]`; the panel shows a Preset menu for it; a pick merges the preset's args onto the effect's defaults. The feedback has six.
- **A range (`score/le_process.js`):** a dial's value may be `[lo, hi]`; `drawArgs` draws it at every render (uniform, to the dial's step) and the message carries the number; the panel offers ⚄ (to a range) and = (back to one value); the JSON box reads and writes it. The engine sees numbers only.
- **The page's `ENDS` table** carries each ending's label and standard length; the engine's list must match it (two lists, kept equal by hand — as the dial ranges are).
- **Proven:** `process_test.scd`, an eighth case — `none` under `perc` 700 ms: 700.0 ms, the last tenth at −inf dB; PASS. The page module parses.

## §33. The process brick: ⚄ all · ⚄ usual — every dial of an effect rolled at once (2026-10-05, Fable; the Decibel piece's §112)

- **What:** `score/le_process.js` `rollDial(d, usual)` — a dial drawn across its range or within its hint's usual range, log-uniform where the slider is log, an option dial picking an option, rounded to the step; the panel's two buttons roll every dial but the `…Mix` ones and any range dial. Page only; the engine untouched.

## §34. The process brick: a Shelf menu and a keep button over a host route; a dial row that no longer wraps (2026-10-05, Fable; the Decibel piece's §113)

- **What:** `score/le_process.js` — `loadShelf()` (GET `opts.shelfUrl`, '/api/candidates' by default; falling back to the static `opts.shelfFile`, '/bank/candidates.json') and `keep(zone, remark)` (POST the brick's setting · heardOn · out · label · effect · render · remark); the panel's Shelf menu (a kept setting applied whole by `processApply`) and the "keep → shelf" button. The data and the route are the HOST's (the Decibel piece: `bank/candidates.json` · `tools/candidates.js` · `score/server.js` `/api/candidates`); SEAMS.md row 2c names the route. The slider shrinks (`flex: 1 1 60px`) and a dial's row is `nowrap`, so the ⚄ button stays on its line.
- **Proven:** parses. Not seen in a browser.

## §35. THE PLAN — a score's variants rendered after the capture, the soonest-needed first; a fallback when one is late; a return brick's `variants` (2026-10-05, Opus; the Decibel piece's §116 · its PLAN 10.8; parts 6 · 11)

- **What prompted it:** the Decibel piece's principle that a sample never comes back as itself (its DEC-21 · 22): every return plays a TRANSFORMATION of its sample — one effect of the chain under a short envelope — and in concert there is no time to render by hand. The piece's talk settled the shape (its §114); this is the machinery, which knows no piece.
- **The engine (`sc/process.scd`):** `/le/process` takes **`durX`** — the envelope's length as a multiple of the source's own (÷ the tape's `rate` when the args change it) · **`/le/plan`** `stamp · part · of · rows · [render]` — the variants a score will ask for, a row each: `base;suffix;effect;end;atkMs;durX;match;t;capMs;args`, `|` between rows, `t` the score time of its first use. A plan comes in PARTS that share a stamp and REPLACES the one before it only when the last part is in — each part is its own HTTP request and its own datagram, so their order is nobody's promise (the first design, "the first part resets", would have lost rows) · **`planRender(base)`** — called at the end of `captureDone` (`sc/bank.scd`): the sample's planned variants into a QUEUE ordered by `t`; at most `planWidth` (2) renders at once, each one's end starting the next (`planNext`, called from the render's callback) · **`/le/planrender`** (and `render 1` on a plan) — every planned variant whose sample's file is in the bank. A variant is a processed sample like any other: `<base>~<suffix>.wav`, a row (`kind: "processed"`, **`planned: 1`**), a buffer.
- **A capture ALWAYS renders its variants again** — not only the missing ones. With the buffers filled from a backup bank at the start (the `concert` mode), "missing" would never be true and the night's own sound would never be transformed.
- **The fallback (`sc/bank.scd` `sampleFor`)**, used wherever a name becomes a buffer (a plain return, `ar`, a chain's links, a pattern's onsets): a name with `~` that has no buffer plays its BASE (the part before the first `~`), raw; a variant whose buffer still holds an EARLIER take's render (it was queued again and has not landed: `planStale`) plays that. Each is said — `LE_INFO late · …`. A score never waits on a render and a return is never silent for one.
- **The page (`score/le_objects.js`):** a return brick's `elec.variants` `{ '<sample>': '<key>-<env>' }`; `vname` (what a brick asks for), `planRows` (every variant once, with its first use), `sendPlan` (parts of six, a stamp; a dial given as a range `[lo, hi]` drawn at the send) at a pass's first frame, a second after a change (`markDirty` wrapped) and with the panel's button; the panel's rows — a preset · an envelope · ▶ — from the PIECE's presets file (`opts.presetsUrl`, `/bank/presets.json` by default: `{ classes: { name: { durX } }, envelopes: { name: { atkMs?, capMs? } }, presets: [{ key, name, effect, args, class, durX?, match?, capMs? }] }`). A page with no such file shows no rows and every return is raw. Rows with `planned` are left out of the pickers (`choosable()`); `captured()` is what `*` plays.
- **Proven, once each side:** `sc/process_test.scd` — PROCESS_TEST PASS with the plan's cases (three variants in two parts, the second first · a queue two wide · lengths 350.0 · 612.5 · 700.0 ms for durX 1.0 · 1.75 · 1.0 at half speed · the row · the fallback) · the page module under a stub window with the piece's score, 20 checks.
- **Not claimed:** a plan through a living engine · the composer's ear · how many renders a machine carries beside a performance (the width is the dial) · a browser's eye on the panel.
- **For a piece that takes this:** nothing to add to a stack file. A presets file where the page can fetch it; the rest is the score's.

## §36. The granular freeze — the cloud, the first granular voice of part 6 (2026-10-05, Fable; the Decibel piece's §120)

- **What prompted it:** the composer heard the spectral freeze REPEAT (a flutter) and asked for *"longer windows … more overlap … a sustained freeze rather than a repeated type of effect"*; of A (tune the spectral freeze) and B (a granular freeze after the sandbox's `\roadsCloudBuf`) he chose B.
- **What:** `sc/process.scd` — the stage `cloud` after the spectral block: the chain's signal written into a 4 s LocalBuf while the source plays (a Phasor whose rate is `1 - Done.kr(play)`: the writing stops with the source, so the moment is never overwritten); from `gfAtMs` on, `GrainBuf` grains of `gfDur` ms at `gfDens`/s on `Dust` (asynchronous — no period to hear), beginning at the moment ± `gfSpread` ms, each at `2 ** (±gfPitch / 12)`; the level × 1/√(density × length) — the sandbox's measured compensation (roads-cloud.scd), density a texture control. The dry sound until the first grains (half a grain after the moment). `score/le_process.js`: the row `cloud`, six dials, hints.
- **Why a buffer the chain writes, not the source buffer:** the grains are of whatever the stages before it made — a chain is a chain.
- **Proven:** `sc/process_test.scd` PASS — the cloud holds a second past its 350 ms source (−12.6 dB under its peak at 0.6 … 1.1 s) and is cut at the tail's cap. Not heard.
- **Not yet:** the cloud's envelopes across its length (the sandbox's density/length curves) · the spectral freeze's own tuning (window · hop · the re-draw rate) · stereo.

## §37. `icy` — the composer's own freeze of 2015 … 2016 (Warp1) ported as a stage; his ten grain windows in the engine (2026-10-05, Fable; the Decibel piece's §122)

- **What prompted it:** the cloud (§36) held a snapshot; he wanted a STRETCH — *"the classic time stretching algorithms, like … the amazing slow downer"* — and pointed at his repo `github.com/elosine/freeze`: `\icy` · `\icy_live` · `\icy_s`, all Warp1 with a crawling pointer, 0.6 … 0.8 s windows, 17 … 40 overlaps, a window-offset random of 0.1 … 0.2, and ten grain envelopes of his own.
- **What:** `sc/process.scd` — the stage `icy` after the cloud, reading the same LocalBuf the cloud writes: `Warp1.ar(1, buf, ptr, 2 ** (icPitch/12), icWin, envBuf, icOverlaps, icRand, 2)`, the pointer `icFromMs + Sweep.kr(on, icSpeed)` clipped to the material written so far, normalised to the buffer; `icEnv` 0 = Warp1's Hann, 1 … 10 = `sc/grainEnv/gEnv_*.aif` in name order, which `processRender` now reads into buffers 1 … 10 of every offline score (`pathMatch`, so a missing folder costs nothing but the Hann). Level × 1/√overlaps. `score/le_process.js`: the row, seven dials, hints, four presets (his three versions · held).
- **Proven:** `sc/process_test.scd` PASS (ten renders) — the stretch sounding a second past a 0.35 s source, cut at the cap. Not heard.
- **Not yet:** his `\icy_live`'s duration envelope (linen with `rel` on curve −6) — the piece's endings do that job here · stereo (his `\icy_s` ran two buffers) · the speed map of `Freezer.scd` read exactly.

- **§37 b (the same day; the piece's §124):** the icy stage no longer gates the dry sound until its first window — Warp1 runs from the start, swelling in as the material is written (no gap after the attack); the mix alone decides the attack: 1 = the stretch only, the peak-match lifting the sustain · 0.5 = both · 0 = the sample. `process_test.scd` PASS (the sustain −5.5 dB under the peak, was −11.9).

- **§37 c (the same day; the piece's §125):** the resonator bank's four pitches are controls (`resF1 … resF4`; the row has the dials) — so a piece can draw them per variant (the Decibel piece's DEC-23). `process_test.scd` PASS.

- **§37 d (the same day; the piece's §129):** a return brick honours `elec.label` — a tag shown first on its label (`score/le_objects.js` `decorate`); a piece's tool may number an audition with it.

## §38. A pattern brick deals a preset per impact — the composed rhythm meets the plan (2026-10-05, Fable; the Decibel piece's §131 · DEC-28)

**What prompted it (the composer, in the Decibel piece):** *"I guess you can do a round robin of impulses, but each one will be processed differently"* — and the brick's two rows of boxes were to offer *"just the raw ones, not the processed ones"*.

**What is the engine's here (`score/le_objects.js`):**
- `raw(r)` — a RAW sample of the index: not `kind processed`, not `planned`, no `~` in its name. The pattern brick's Players · Impulses boxes and `picked()` use it: no render of any kind joins a composed rhythm's deal (before: the boxes listed a piece's workshop renders as if they were impulses).
- `elec.fx = { mode 'none' | 'each', env, cls, seed }` and **`dealVariants(n, fx)`**: n variants `<key>-<env>` for n onsets — the piece's presets (`opts.presetsUrl`; `fxPool`: all, or one class) shuffled once by the seed (mulberry32, `seed * 7919 + 3`) and dealt round robin, none twice until all are used, past the pool round again; the envelope the one asked for, or the file's `mix` as exact shares of n (largest remainders), shuffled (`seed * 104729 + 17`). The rule is the Decibel piece's `tools/deal_variants.js`, carried in: the tool deals a score's returns, the module deals one brick's onsets.
- `generate()` writes `pattern[i].variant`; `fire()` names each onset `<sample>~<key>-<env>`; **`planRows()` carries a pattern's variants at the ONSET'S time** (`startTime + atMs`), not the brick's — the engine's soonest-first queue then spreads a long run's renders through the pass. A brick without `fx` (saved before) plays as it did.
- The panel: an **Effects** row (mode · envelope · class · seed · redeal) and a note of the pool; the label `· a preset each`; the readout `name~preset-env ms`.
- NOT changed: `sc/bank.scd` (its pattern branch already resolved a `~` name through `sampleFor`) · the seams.

**Proven once, headless:** the module under a stub window with that piece's real index (310 rows) and its 49 presets — 17 checks pass (the raw 25 only · 25 distinct presets for 25 onsets · reproducible by seed · the plan's rows timed by onset · the message per onset · a class narrows the pool and a 25th onset over 24 comes round again · the mix's shares · mode none plans nothing). NOT heard.

## §39. A fifth stance in the rolls — FAR after (2026-10-05, Fable; the Decibel piece's §135 · DEC-30)

**What prompted it (the composer, in the Decibel piece):** *"get rid of unison and create a tier after lazily after … make lazily after 300 to 500, and then after that, 500 to 750. But then keep that longest one similarly 10% … like the unison was."*

**What is the engine's:** `sc/bank.scd` — the stances of a return were before · after · lazy · unison (+ the miss); now **far** sits between lazy and unison: `arDefaults` `far: 0, farLo: 500, farHi: 750`, `chainDefaults` `far: 0`, a fourth `case` and a `switch` arm in `arRoll` and in `chainRoll` (`o[\far] ? 0` — a piece's dials that predate the tier roll as before). The engine's own defaults give far a share of 0: a piece that says nothing hears no change; the Decibel piece sets far 0.15 (ar) · 0.10 (chain) and unison 0 in its `bank/elec_route.json`, flattened by its `tools/elec.js` to `LE_AR` · `LE_CHAIN` as before (one word added to its list of ranges). `roll_test.scd` carries that piece's current dials and a case that forces every link far and checks the band — `PASS`. NOT heard.

## §40. The composer's petals of resonance, twice; the feedback made to sing a chord (2026-10-06, Opus; the Decibel piece's §150 · §151 · DEC-32)

**What prompted it** — the composer, in the Decibel piece: *"One is a port of my pedals of resonance code. Can you look at the code and then do some cleanup especially the signal path and just taking out unnecessary things but keep the original and then can you produce a sample file that has side by side my original and then your cleanup … Then I want a similar type of thing with the feedback device … look in my harmonies, the cord shapes …"* ("petals", the flower — his word the same day.)

**In the chain (`sc/process.scd`), after the resonator bank — two stages, each a mix at 0 like the rest:**
- **`petalsOrig` (controls `po…`)** — `github.com/elosine/SynthDef_petalsOfResonance` @ `e87a5d4`, UGen for UGen and in his order: two banks of 13 partials over one fundamental, `fund × (firstPartial + spread × n)`, bank B `bank2MidiOffset` semitones up, each partial's pitch wobbling ± 0.5 semitone on a slow sine; 26 `DynKlank`s of one partial each at −40 dB, shuffled, mixed, limited, faded after `ringL2`. ONE line changed: `SoundIn.ar(ibs)` is the chain's signal. Left out: `masteramp` (the render sets the level) · `obs` · `doneAction: 2` (it would end the chain). No clips on its dials.
- **`petals` (controls `pt…`)** — the same instrument, the path cleaned: one bank of 26 `Ringz`, summed · no shuffle · each partial's wobble rate and start phase drawn per render (`Rand`) · each partial's ring drawn once per render between the two ring dials · no limiter, no fade (the render's ending does it) · the input envelope kept as his.

**Two facts measured for it (a headless probe: sclang and two offline renders):**
1. `rrand(a, b)` on two CONTROLS is a server-side binary operator: **a new random value at every control block.** In his SynthDef the ring time of every resonator therefore flickers between `ringL1` and `ringL2` 750 times a second (48 kHz, blocks of 64), and the 26 decay together at one effective time — not 26 rings. `rrand(0.07, 0.013)` on two NUMBERS is the language's: drawn once, when the SynthDef is built.
2. **A `Rand` in an NRT render differs from render to render** — the offline server is seeded by the clock. Per-render draws need no seed control.

**The feedback: `fbOwn`, "each string sings".** Fifty-four chords (two to six strings, the piece's chord shapes) were rendered through the stage as built (§31): none bloomed — 1.3 … 3.4 s of ring-down, 16 … 44 dB under the peak after one second. The stage's strings are combs at unity on their harmonics, summed × 0.5: one string alone has a loop gain of 0.5. The loop takes off only where two strings share a harmonic (the open guitar's two E's) and the path's phase agrees. `fbOwn` 1 makes the loop's result without the loop: each string a comb that barely decays (100 s), at the level of the loop's string; the bloom a gain of 60 dB in `fbBloom` s from the level the sound gave that string, up to a ceiling that is one amp per string (`fbDrive / 4` into the tanh); tone · climb · hold as before, then 1.5 s of ring-down; `wobble` a slow pitch drift per string; `path` unused. `fbOwn` 0, the default, is the stage as it was (the test's case 7 unchanged: 3824.9 ms, 0.0 dB). Rejected: more loop gain per string (which harmonic wins is the phase's luck, and one mode wins through a shared amp) · a tuned loop per string (a `LocalIn`'s block delay, 1.33 ms, bars any fundamental above 750 Hz) · octave doublings (they re-voice the chord).

**The page (`score/`):** `le_process.js` — two rows (`petals` · `petalsOrig`, eight dials each, hints), the option `fbOwn` on the feedback row · `le_objects.js` — a preset marked `deal: false` is left out of a pattern brick's pool (`fxPool`): a piece may keep audition sets beside the presets it deals · a brick's own tag may be 48 characters (was 24).

**The proof:** `sc/process_test.scd` — PROCESS_TEST PASS, three cases added: `~11` · `~12` the two petals ring past their source and die before the cap (1843 ms · 1657 ms for a ring of 1 … 2 s) · `~13` a chord that shares no harmonic (E4 · F#4 · A4) holds at its peak a second in, each pitch in it within 2.3 dB (a Goertzel on each), then dies (2949 ms). Thirteen renders now.

**SEAMS:** unchanged — no line of a piece's stack.

**NOT CLAIMED:** the composer's ear on either; a render of the new stages through a living engine.

## §41. The cleaned petals lose the fade-in (2026-10-06, Opus; the Decibel piece's §152)

**What prompted it** — the composer, on the offer made at §40's wrap: *"Go ahead and drop 20ms fade from cleaned petals"*.

**The change, one line of the `petals` stage (`sc/process.scd`):** the input envelope `Env.perc(0.02, inputLen, 1, -1)` becomes `Env([1, 0], [inputLen], -1)` — no rise; the same fall, on his curve, over `inputLen`. His 20 ms rise was the microphone's gate (a window opening on a live input); on a banked impulse, cropped to its attack, it shaved the first 20 ms of the very thing that excites the bank. `petalsOrig` keeps it, as his. So a pair now differs in four ways: the attack · the ring · the wobble · the ending.

**The proof:** `sc/process_test.scd` — PROCESS_TEST PASS (case `~12`, the cleaned path: 2089 ms; before the change 1657 ms on the same source — the bank is struck harder and falls under −60 dB later; the lengths also move with each render's draws).

**NOT CLAIMED:** the composer's ear.

## §42. The level, first half — a sample's loudness, the ladder of marks, the dynamic a return is played at (2026-10-06, Opus; the Decibel piece's §154 … §161 · D17 · its PLAN 1.4, 11.1 … 11.3)

**What prompted it** — the composer, in the Decibel piece (its DEC-33): the electronics scored *"like live performers on a scale from ppp to fff"*, with the player's agency kept — *"played back as played or re leveled as my composer intention"*. This engine had no loudness scale: a sample came back as loud as the microphone caught it, and its only figure was a peak.

**A new file, `sc/level.scd`** (loaded by `boot.scd` after `bank.scd`; pure language — no server in any of it):
- **The measure.** `loudOf(data, sr)` → `loudDb` (the loudest 400 ms) · `loudIntDb` (the whole sample), in LUFS (ITU-R BS.1770), on the sample AS IT WILL SOUND (`\leSample` is dual mono at unity: twice one channel's mean square). The K-weighting is applied in the FREQUENCY domain: a 400 ms window through the language's FFT, the power spectrum weighted by |H|² of the standard's two filters, whose coefficients are computed for the file's own sample rate in double precision (at 48 kHz they are the standard's table); the transform's scale is read off a unit impulse. A window every 100 ms through the first 2 s, then side by side. A 7.5 s sample: 130 ms of the language's time. Written into a row at a capture (`bank.scd` `captureDone`) and at a render (`process.scd` `processDone`), with `played` — the name on the ladder nearest it; `measureBank` fills the rows a bank already has, in the background, eight a second, the index written once.
- **The ladder.** `levelDefaults` — `reference` (the LUFS of fff) · `stepDb` 4 · `liftCapDb` 20 · `floorDb` −60 · `driveRef` · `bleedDb`; a piece overrides them at the start (`LE_LEVEL`, `session.scd`). `markDb` · `playedMark` · `gainFor(row, dyn)`: `played` (0 dB — the default) · `mark:mf` · `rel:+1[:floor:p][:ceil:f]`; a lift is held at the cap, nothing is raised from under the floor, a row with no figure is played as captured and the window says so.
- **The dynamic in time.** `/le/play` may carry `dyn` · `env` · `envCurve`; `levelFor` turns them into `\leSample`'s envelope — eight levels in dB of gain over seven times, padded with the last. An `env` point is `ms:level`; ms may be `end` (the sample's own length); a level is a mark, `=` (the brick's own dynamic) or `+n` / `-n` steps from it. `\leSample` (`synths.scd`) multiplies by `EnvGen.kr(Env(envDb, envDt, envCurve)).dbamp` — the levels joined in decibels; all at 0 dB, exactly 1. In `samplePlay` each sample of a plain return, a roll, a chain and a pattern takes the brick's dynamic from its OWN start against its OWN loudness, and is scheduled earlier by `masterDelay` (the bus's look-ahead — 0 until the bus is rebuilt).

**The page (`score/le_objects.js`)** — a return brick's `elec.dyn = { mode, mark, rel, floor, ceil, shape }` (absent = as played): `dynFields` (what it adds to `/le/play`; nothing when the brick has none) · `dynLabel` (`mf` · `mp→ff` · `▲|p` · `mf~`) · `dynPanel` (Level: as played · a mark · relative; Shape: none · hairpin · step · line; what the bank says was played) · the bank's line says the loudness.

**Proofs, headless:** `sc/level_test.scd` — LEVEL_TEST PASS (the 48 kHz table · the reference tone −17.0 LUFS at two rates and from a file · a short burst · the ladder · every form of `gainFor` · three envelopes · `\leSample` built with its controls · the index's round trip) · a second implementation in the time domain agrees within 0.05 dB on four of the piece's files · **`tools/page_test.js`** — the page module under a stub window, a new battery (17 checks) · `sc/roll_test.scd` and `sc/process_test.scd` still pass.

**Measured in passing:** thirteen renders of the processing's own test, all at one peak, spread over 15 dB of loudness (−14.6 … −29.9 LUFS) — what "a render's peak is set to its source's" means to an ear.

**NOT CLAIMED:** the composer's ear · any of it through a living engine.

## §43. The drive — a gain on the source, before the chain; a dial as a line in time (2026-10-06, Opus; the Decibel piece's §162 · its PLAN 1.4, 11.4)

**What prompted it** — the Decibel piece's D17: level is two things, the DRIVE into an effect and the DYNAMIC out of it, and the composer's word that some impulses came back quiet, *"and their processed versions with them"*: a quiet take was a quiet excitation, and the non-linear stages answered less.

**In `sc/process.scd`:**
- `\leProcess` has `srcAmp` (1): the source's gain, before every stage.
- `/le/process` takes `srcDrive` — `played` (0 dB) · `normalized` (the source brought to `driveRef`, LE_LEVEL; −20 LUFS — measured on the samples in hand by `level.scd`) · `+12` / `-6`. Held so that the driven source's own peak stays a decibel under full scale. A render asked for by a brick of its own defaults to `played`; a PLAN's variant to `normalized`. The row keeps what was done (`drive: "normalized +13.2 dB"`); nothing is written when the source went in as it is.
- a plan row has an eleventh field, the drive; `planNext` hands it on.
- `processArgs` reads A DIAL AS A LINE — `name:value@ms,value@ms` — and returns its breakpoints; `processRender` writes them into the offline score as `/n_set` steps every 50 ms along the line.

**In `score/le_objects.js` · `score/le_process.js`:** `driveWord` · `driveOf` · `driveTag` · `vsuffix` · `isLine`; a variant may be `{ v, drive }`, and a drive of the brick's own gives the variant a name of its own (`…_dN` · `_dP` · `_d12` · `_dm6`); the plan's rows carry the drive (the brick's, else the preset's, else `normalized`); a drive menu per sample in "Processed as"; on the process brick `elec.drive`, a Drive row, and a dial's third form — a line (`∿` / `=`).

**The proof** (`sc/process_test.scd`, PROCESS_TEST PASS): the feedback from a source and from a copy of it 20 dB down, `normalized`: −9.9 and −9.9 LUFS · a linear stage `played`: 20 dB apart · a boost of 12: 12 dB · a line on the output level ends a reverb's tail at 274 ms instead of 1649. **Measured:** the feedback `played` — −10.0 and −13.0 LUFS: three decibels for twenty; a saturating loop is set by its ceiling, not its excitation. `tools/page_test.js` covers the page's part.

**NOT CLAIMED:** the composer's ear.

## §44. The bus — the master rebuilt as a mastering bus, live; a loudness and true-peak meter; a second offline battery (2026-10-06, Opus; the Decibel piece's §164 · its PLAN 1.4, 11.6)

**What prompted it** — the composer's "A" in the Decibel piece (its §156): the bus is SuperCollider's, not a plug-in chain in the DAW. Until now `\leMaster` was a switchable high-pass, a `Compander` glue and a `Compander` safety with no look-ahead — the sandbox's NUMBERS without its soft knee, and a "−1 dB" that was only where the squeeze began.

**`sc/synths.scd` `\leMaster`, in order:** a high-pass and a low-pass, each switched (off = not in the path) · THE GLUE, a feed-forward compressor written out — the mean square of both channels over 30 ms, a gain computer in decibels with a soft knee, attack and release on the gain, make-up; under its knee, exactly unity · THE LIMITER, look-ahead, both channels as one, written out — the louder channel's peak over a window 1.2 … 2.4 look-aheads long (two `RunningMax`, reset in turn), held (`Amplitude`, instant attack), the gain under the ceiling averaged over 0.8 of a look-ahead (`RunningSum`), the sound one look-ahead late (`DelayN`); it cannot overshoot, and under the ceiling its gain is exactly 1 · the clip. `Limiter.ar` was not used: it cannot be linked across channels and it delays twice its `dur`.
**`\leLoudness`** — `~le.loudGraph`: the K-weighting as two `SOS` at the server's rate (`level.scd` `kCoefs`), 400 ms of mean square → LUFS; true peak from the samples and three in-between phases (8-tap windowed sinc, `tpTaps`); the loudest of each half second to `/le/loud`.
**`sc/boot.scd` § the bus** — `masterDefaults` (NEUTRAL: no filter, no glue; ceiling −1, look-ahead 5 ms) · `masterOf` · `masterArgs` · `masterSaid` · `masterSet` (`/le/master`: the dials moved while it runs; `lookaheadMs` only at the start) · `loudOn` · `loudSaid`; the master is made with the piece's dials and `masterDelay` is set — `bank.scd` `samplePlay` plays that much early. **`sc/session.scd`** — `LE_MASTER` read before the boot; the meter on; its figures on the two-second line; `/le/leave` says the session's loudest.
**Also in the file, for the next entry:** `\leIn` has a trim, a high-pass and two bands of EQ, each switched (flat = the input, sample for sample), and `\leTone` (a line-up tone).

**The proof — `sc/bus_test.scd`, new:** the engine's SynthDefs in NRT, the files measured; safe beside a living engine. BUS_TEST PASS — unity to the sample, 220 samples late at 44.1 kHz; +6 dB tones at 60 · 220 · 1000 Hz and a struck burst all leave at −1.0 dB, onset and settled; the glue 0.0 · −10.51 · −15.38 on its three cases; the filters; the meter −16.98 LUFS on the reference tone and −5.93 dBTP on a −6.02 inter-sample peak whose samples read −9.03; `\leSample`'s envelope 0 → −12 dB joined in decibels; `\leIn` flat, trimmed, high-passed, one band of EQ.
`sc/level_test.scd` now also checks the bus's dials and PARSES every file that boots a server.

**NOT RUN:** `sc/selftest.scd` — its tests A and B rewritten for the delayed, limited bus — and `session.scd`'s new lines: the composer's engine was up, and they boot the engine's own server. Parsed, not executed.

## §45. The house — a venue's input chains, a calibration, a guard against bleed, a line-up tone (2026-10-06, Opus; the Decibel piece's §165 · its PLAN 1.4, 11.7)

**What prompted it** — the last item of the level: an engine that has only ever heard a sampler through a DAW's sends must take any hall's microphones.

- **`\leIn`** (`sc/synths.scd`) — amp (the trim) · a high-pass · two `BPeakEQ` bands, each switched; flat, it is the input sample for sample.
- **A venue** — `~le[\venue]`, per player `trimDb` · `hpfHz` · `eq1` · `eq2` (hz/dB/Q), from `LE_VENUE` (`name=<n>;bcl:trimDb=-2.5:hpfHz=90:eq1=250/-3/1,bfl:…`); `micArgs` turns it into `\leIn`'s arguments at `addPlayer`. **`takeSpecs`** (`sc/boot.scd`) reads `LE_LEVEL` · `LE_MASTER` · `LE_VENUE` · `LE_REFUSE_BLEED` in one place, for `session.scd` and `calibrate.scd` alike.
- **`sc/calibrate.scd`** — each player in turn, one reference dynamic on cue; the loudest 400 ms of a few seconds, read through the venue's chain; one `LE_RESULT` a player with the trim that puts the reading on the ladder's mark. It writes nothing: the piece's tool writes the venue's file.
- **The room** (`sc/bank.scd` `bleedOf`) — the first 60 ms of a capture's recording, where a window is known to be early: its loudest sample is the ROOM. `cropFind` takes it (`roomAmp`): an attack must stand 6 dB over it, or a hall's murmur 20 dB under the note is taken for the attack (the crop's own threshold is 30 under the peak). A capture whose peak stands under `bleedDb` over the room is flagged in its row; with `refuseBleed` (a concert) it is refused and the buffer keeps what it had. A silent room changes nothing.
- **`/le/tone`** (`toneOut`, `\leTone`) — a sine on both outputs, past the bus.

**Proof:** `sc/level_test.scd` — the guard's three cases; the crop with and without the room (0.0 ms against 200.1 for an attack at 200); a venue's numbers as arguments; a session's start from its environment · `sc/bus_test.scd` — `\leIn` flat, trimmed, high-passed, one band. **NOT RUN:** `calibrate.scd` (parsed) and `/le/tone` — each needs an engine of its own or sounds; a capture in a real room.

## §46. The icy stage LOOPS — `icLoop`: the read point wraps at the source's end (2026-10-06, Fable, in the Decibel piece; its §169 · §171, its PLAN 10.13)

**What prompted it** — the composer's rule for his piece (its COMPOSITION_NOTES DEC-34b): *"for this piece will read from beginning to end of source and loop"* — a held sound (a multiphonic, a bowed cymbal) stretched into a DRONE by his freeze `icy`, the source read in order from its start and, at its end, again. Until now the read point HELD at the end of what was written (`.min(icWr)`), as his 2015 freezes did.

**What changed.** `sc/process.scd`, the icy stage: `icPos` = where the point would be (`from` + the sweep at `icSpeed`); `icLp` = `icLoop.clip(0, 1)`; the pointer = `icPos.min(icWr)` × (1 − icLp) + (`icPos % icWr.max(1e-4)`) × icLp — ARITHMETIC, not `Select`, because the bound `icWr` (`gfW` / SampleRate, the write head) is audio rate while the rest is control rate, and `Select.kr` over mixed rates does not compile. `icLoop = 0` is the stage's default: the engine serves three pieces and the other two hear no change. The bound is the material written so far, so a wrap can only happen once the source is over (while it is still being written, `icPos` < `icWr` at any pace below 1). `score/le_process.js`: the icy row's option `at the end` (loops to the start · holds at the end), the Decibel row's default 1 and its `from` default 0 (the piece's call, in the module's row — the engine's own default stays 0 in the stage); two hints. The header's option list says it.

**The proof — `sc/process_test.scd`, PASS:** two renders of the 0.35 s burst at half speed, cap 1500 — looping (~14) and holding (~15). 1.0 … 1.4 s in, the looper is −14.0 dB under its peak (still reading the burst, a wrap every 0.7 s); the holder's render ENDED at 671 ms — its tail fell under −60 dB on the source's silent end — while the looper ran to the cap (1804 ms). The tally is fifteen rows. The first run failed on the test's own tally (thirteen) and on a −999 detail for the holder (shorter than the measured window): both fixed, re-run, PASS.

**Not measured, said as such:** a grain whose window straddles the wrap reads silence beyond the write head — a possible bump at the seam; the piece's audition has a brick for the ear (its 10.13, A11), and a crossfade at the wrap is the piece's item (f) if it is heard. **THE SORTING:** the option is the engine's; which pieces loop by default, and the presets, are each piece's.

## §47. A GENERATED VOICE — the sine: `\leSine`, `sc/sine.scd`, `/le/sine` · `/le/sinestop` (2026-10-06, Opus, in the Decibel piece; its §177, its PLAN 1.5 · 12.1)

**What prompted it** — the Decibel piece's composer (its DEC-35 · 35b): *"the next effect I want to build is simple sine wave generators, they will have a pitch and aduration and may have crescend/decres; the musician will pitch bend against and beat with sine tone"* — and, rejecting the piece's beating tool as the vehicle: *"these will be simple generated electronics using sc in the composer score"*. The first thing the engine MAKES rather than catches.

**What was built.** `sc/synths.scd` `\leSine`: a sine to the master, dual mono, `dur` seconds; a level line (`envDb` 8 · `envDt` 7 · `envCurve` — `\leSample`'s envelope shape, here the dB of its PEAK) and a pitch line in cents (`glissCents` 8 · `glissDt` 7, straight in cents, audio rate); a 10 ms rise and 30 ms fall; `gate`. `sc/sine.scd`, loaded by `boot.scd` after `level.scd`; `session.scd` wires `sineHear` whether or not there is a bank.

**The message** — `/le/sine  id · lane · t · dueMs · midi · lengthMs · [level · levelCurve · gliss]`: `midi` carries its cents (57.12); `level` is one mark or a line of `ms:mark` pairs; `gliss` a line of `ms:cents` pairs; `end` = the length; eight points each at the most. The same breakpoint form as `/le/play`'s `env` — one convention. `/le/sinestop`: every sine lets go in 50 ms (twice, 0.2 s apart — one sent ahead of its start has not begun at the first).

**Why its own file and not the bank's:** the bank's kinds are wired only when a session has a bank; a generated voice needs none.

**The level is exact.** A mark is a loudness on the ladder (`markDb`); BS.1770 reads a sine of peak A on both channels as −0.691 + 20·log10(A) + K(f), K the K-weighting's gain at the sine's frequency (`kGainDb`, from `kCoefs` · `kGain2`). So no sine is ever measured: its peak is `markDb + 0.691 − K(f)`. Computed at 44.1 kHz: K = −0.21 dB at 220 Hz · +0.70 at 1 kHz · +3.20 at 2093 Hz · +3.99 at 4186 Hz. One ladder for the samples and the generated voices. A mark may be a number (ppp 0 … fff 7, fractions; below 0 on down) so a drawn curve needs no rounding to names.

**Proven offline** — `sc/sine_test.scd` (new; NRT on `bus_test.scd`'s frame), SINE_TEST PASS, ten checks: the figures · a 3 s glide of 50 cents on the line within 0.02 cents (zero crossings) · the ramp half way in decibels · held at ff it reads −33.6 LUFS by `loudOf` (ff −33.54), its peak the formula's to 0.01 dB · C7 at mf reads −41.7 (mf −41.54) · the stop. `sc/level_test.scd` PASS — `session.scd` parses with its line.

**Rejected:** eight fixed values with seven fixed times in the message (the piece's plan as first written) — the engine already speaks `ms:value`; a control-rate frequency (it steps once a block; a glide is audio rate); a per-channel loudness formula (the plan's slip: the sine sounds on both channels, as a sample does).

**NOT claimed:** a sine through a living engine; the composer's ear. **THE SORTING:** the voice, the message and the formula are the engine's; which pitches, which lines, which player it is for are the piece's.

## §48. The sine brick — the fourth composer-score object; a level that follows a drawn curve; how a stop reaches a generated voice (2026-10-06, Opus, in the Decibel piece; its §178, its PLAN 1.5 · 12.2 · 12.3)

**What prompted it** — the Decibel piece's composer: *"maybe crescendos are generated like trills, I draw a curve on a curve lane and attach the sine to that curve"* (its DEC-35b).

**What was built.** `score/le_sine.js` — a mixin on `LEObjects`, loaded after it; it adds its own row to `MODELS` (`elecSine`). The brick: `elec: { midi, gliss: { kind, from, to, points? }, level: { mode, mark, to?, curveRef? }, label }`. Its message, `/le/sine`, carries the pitch with its cents, the length, the level as one mark or `ms:mark` pairs, the gliss as `ms:cents` pairs, and `pass`. `score/le_objects.js`: five hand-off lines (the key `keys.sine` · the label · the panel · the fire · the tick's "inside"), `_passN`.

**The curve seam.** A brick's level may FOLLOW A DRAWN CURVE. The reader is the HOST's and is HANDED IN on the attach line — `opts.curveAt(ref, { layer, startTime, endTime }, n)` → n heights 0 … 1, or null — the same way the pattern brick was handed the stack's two calculators (§25). What `ref` names is the piece's. The module reads it at the FIRE (so a redrawn curve is heard at the next pass) and at each drawing of the label (an eight-step sparkline). Height 0 … 1 = marks 0 … 7; the engine's formula does the rest (§47).

**The stop — three cases, one rule: no message may have to arrive before another.** (1) The score stops: the host's `stopPlay` is wrapped at the attach → `/le/sinestop`. (2) It is started again, or (3) its playhead jumps: nothing is sent; each `/le/sine` carries the pass's number, and `sc/sine.scd` `sinePlay` lets go of the sines of the pass before on the first of a new one. Each sine is remembered by its own node until its length is over (`~le[\sines]`, `sineLetGo(keep)`): a sounding one closes its gate (50 ms), one sent ahead and not begun is freed 2 ms after it begins. An audition carries no pass and lets nothing go. **Rejected:** a group swept twice 0.2 s apart (it silences a sine begun between the sweeps); a stop message at a jump (two posts in one frame are not ordered).

**A playhead that starts inside a sine starts it** for what is left — the lines re-based (`from(points, f0)`), a curve read again over the remainder. A long tone would otherwise sound only when its first frame is crossed.

**Proven** — `tools/sine_page_test.js` (new; the stub window of `page_test.js`), SINE_PAGE_TEST PASS, 33 checks; `tools/page_test.js` PASS after the host file's change; `sc/sine_test.scd` PASS after the stop's rework. **NOT claimed:** a browser's real input; `sinePlay` · `sineLetGo` through a living server (parsed, never run); the composer's ear. **THE SORTING:** the brick, the message, the pass and the stop are the engine's; the key, the curve reader and what its `ref` names are each piece's.

## §49. THE COMPUTER PLAYERS — a performer in a state, who hears onsets and decides sound by sound (`sc/performer.scd`); proven with no server (2026-10-06, Opus, in the Decibel piece — its RUNNING_LOG §183 … §189; its PLAN 1.6 · 14.4)

**What prompted it (the piece's DEC-36c, his words):** *"let's design an algorithm for the electronics to follow. And let's consider them just three players. Drawing on the available impulses plus effects. So they'll be processed impulses."* — in a section where every player, human or computer, runs one orbit of four states (far apart · approaching · close pass · break-and-rejoin), the change between two states a container of its own.

**What is new in the engine:** until now every object was a BRICK — one message, one sound (or one composed rhythm), at a time the score names. A PERFORMER is the first object that is in a STATE for a stretch of time and makes its own decisions from what it HEARS. It is the engine plan's "placement algorithm" (part 11) grown into a player: the piece's D14, "the electronics is its own performer", taken literally.

**The mechanism (`sc/performer.scd`):**
- **One message starts a container:** `/le/performer id · state · [from · to] · t · dueMs · lengthMs · [offsetMs · wholeMs] · pal · [target · targetFrom · seed · mark · silenceMs · ear · dials · pass · zone]`. A performer is kept by its id across containers — its memory of who played when, its place in its palette, its dice. The first message of a new `pass` ends the pass before (the sine's way); `/le/performerstop` ends all.
- **The rules are functions of (performer, time) — the time is HANDED IN.** `perfHear(p, who, at, gen)` is what it does on an onset; `perfStep(p, t, dt, hz)` is its clockwork (the container's turn · its own pace · the unprompted sound · the break's watch · what is due) and answers the sounds due inside `hz`. Nothing in them asks a clock or a server: they are proven in a bare sclang with virtual time (`sc/performer_test.scd`).
- **`perfRun`:** one Routine on SystemClock, 10 ms a step, for all performers; a sound is handed to the server 30 ms ahead as a timed bundle (`\leSample` at the performer's mark, level.scd's `levelFor`; earlier by the master's look-ahead) — the 10 ms step does not quantise the sound. It rests when nobody has had a container for 3 s. An error in a step is said (`LE_ERROR performer · …`) and the clock goes on.
- **A performer hears three kinds of onset through ONE door, `perfNote(who, at, gen)`:** a SIMULATED player's note told by a score ahead of its sound (`/le/onset player · dueMs · sim 1` — session.scd passes it on and does not print it) · a player's own sound at its microphone (the onset probe, `le[\onHeard]` → `perfMicOnset`) · another performer's sound (the clock tells the others as it plays it). Which of the first two is the ear travels in the message (`ear sim | mic`) — never both, or a simulated note would be heard twice.
- **Each performer has its own dice** (a Lehmer generator seeded from the message): the same seed and the same things heard give the same decisions — which is what lets the test assert them.
- **The dials are the piece's, in the message** (`dials k=v,…` over `perfDefaults`), as the palette is: no environment variable, no restart for a number.

**Three design points a later piece should know (the piece's §189 has the reasoning):** a sound has a GENERATION and an answer stops at a depth (or two performers answer each other for ever) · a listener with nothing to answer plays UNPROMPTED after a wait (or an ensemble of listeners is silent) · a CLUSTER is `count` onsets of two players or more inside `windowMs`, BROKEN when nothing follows for `breakGapMs`.

**Proven:** `sc/performer_test.scd` — PERFORMER_TEST PASS, 17 checks (the piece's §189 lists the numbers). **NOT CLAIMED:** `perfRun` and `perfSound` on a server (parsed, never run) · the `mic` ear with real sound — `\leOnset` reports a rise out of silence and holds 250 ms, so an attack over a ringing sound is not heard: a detector of attacks (a fast envelope against a slow one) is the next thing the concert's road needs (NITS).

## §50. The performer's brick — the fifth composer-score object; the simulated ear (`score/le_performer.js`) (2026-10-06, Opus, in the Decibel piece — its RUNNING_LOG §190 · §191)

**What it is:** a MIXIN on `LEObjects`, as `le_process.js` and `le_sine.js` are — the model `elecPerformer`: a computer player is in a STATE for the length of the brick. `zone.elec = { id, state, from?, to?, target?, targetFrom?, pal: [names], mark, seed, silenceMs?, ear?, dials?, label? }`. One tag in a piece's page; four lines in `le_objects.js` (the label · the panel · the fire · a playhead that starts inside it, as the sine's). No key of its own yet: the first piece makes its bricks with a builder; the panel edits one.

**The message:** `performerMessage(zone, at0, dueMs)` → `/le/performer` — the brick's state, what is left of its length, its palette as one comma-joined string (464 characters for 18 names: well inside a datagram), its target, its seed and mark, `silenceMs` for a break, `ear`, the `dials` as `k=v,…` (27 in the first piece), the pass's number, its zone and lane. A playhead that starts inside sends `offsetMs` and `wholeMs`, so a change knows its place and a break its silence. The host's `stopPlay` is wrapped once more (the sine wraps it too; each wrap calls the one before) → `/le/performerstop`, said only where the score has a performer.

**THE SIMULATED EAR:** `L.tick` is wrapped — the same window of time the bricks are fired in — and, while a performer's brick is near (from half a second before the first to the end of the last), every NOTE on a player's lane whose start falls in the window is told to the engine: `/le/onset player · lane · id · t · dueMs · sim 1`. The player is the lane's by the piece's route table (`playerOf`, as a mic opening finds its microphone; a player who owns two lanes is one player). Nothing is sent where every brick says `ear: 'mic'`. **Why here and not in the piece:** a score that simulates its players is every piece's case, and the engine's `sim` ear needs exactly this and nothing else; the piece gives no line for it.
**This is the route check of 4.2 come back as a feature:** `/le/onset` was the first message the engine ever heard (a note's onset, to measure the lead), and was taken out of the page when the mic opening became a brick. session.scd still shows a tool's `/le/onset`; one marked `sim` goes to the performers and is not printed.

**Proven:** in the piece — under a stub window (`tools/three_body_check.js`: the label, the message, the tick, inside, the stop) and SEEN in its running page on the throwaway server (the bricks drawn, the panel built, five seconds played: six performer messages, twelve onsets for twelve notes, a stop). The engine's own page tests still pass (`tools/page_test.js` · `tools/sine_page_test.js`). **NOT CLAIMED:** the messages through a living engine.


## §51. THE FIRST FAULTS UNDER REAL LOAD — the buffer pool (1024) full mid-pass; the language held by `loudOf` so a recording began inside its note; both from the engine's own window (2026-10-06, Fable, in the Decibel piece — its RUNNING_LOG §194 · §195 · SWEEP_LIST #8)

**What prompted it:** a pass of 68 mic openings 1.4 s apart in the Decibel piece, with three variants a sample rendered right after each capture — the first time the engine captured, rendered and banked at that rate. 20 banked; 10 refused; nothing after 44 s. The composer pasted the engine's window.

**Fault 1 — THE BUFFER POOL.** `STOPPED: … ERROR: No more buffer numbers -- free some buffers before allocating more.` at the 72nd allocation of the pass. Every sample and every render holds a buffer from the engine's start (the bank: 949); a capture allocates its recording buffer and, on banking, the sample's; each render its own. The server's `numBuffers` was the DEFAULT, 1024. Once full, an opening still says `open` and the recording buffer's alloc fails — nothing is recorded, silently but for the first error. **Fix:** `boot.scd` `o.numBuffers = 16384`. A buffer number is a slot, not memory. **NITS:** a bank beyond that wants buffers loaded on demand.

**Fault 2 — THE LANGUAGE HELD.** In each of the ten refused windows, a render's banking lines (`processed · …`) stand between the window's `open` and its `captured`; in the twenty good ones, never. The recording of an opening starts in the buffer's completion message (no round trip, `bank.scd` `captureOpen`), so a recording that begins inside the note means `/le/open` was HANDLED late — the OSC responder runs in the language, one thread. What held it: **`loudOf` (`level.scd`) — BS.1770 computed sample by sample in sclang**: one 400 ms window is 17,640 samples through two biquads, ~20 … 50 ms; a 1.7 s render is ~20 windows, ~0.5 … 1 s of language time; three renders a capture every 1.4 s is more measuring than real time. The index write (a thousand rows serialized after every capture and render) and the drive's second measure of the source at every render start, on top. The room rule (`bleedOf`, 11.7 c) then did exactly its job: the window's first 60 ms held the note at its peak, no attack stood over it, nothing was saved.
**Fix, the figures unchanged:** `loudOf` yields 2 ms between windows when it runs inside a Routine (`thisThread.isKindOf(Routine)` — called from the main thread, as `measureBank` does at start, it runs as before) · `captureDone` is forked on SystemClock in `captureOpen` · `processDone` is forked in the NRT completion (`processRender`) · the drive reads `loudDb` from the source's row when it has one (the same file, the same measure). A message now waits at most one window. **Not solved:** the saturation — the backlog grows under a dense pass and a variant asked for early plays its earlier render or raw (by design, §35). **For the concert** (the live design renders DURING the performance): the measure on the SERVER — a K-weighted analysis synth with `SendReply`, its figures checked against `loudOf`'s across the bank before the ladder trusts it — or `~le[\planWidth]` 1. Rejected now: the server measure (a day, and the ladder's reference would be re-measured) · deferring renders while a window is "due" (the engine does not know the next window; a piece's page tells it ~200 ms ahead) · a faster filter in the language (sclang has no vectorized IIR).

**Proven:** `sc/level_test.scd` PASS (it parses every file that boots a server; the measure's figures) · `sc/process_test.scd` PASS (fifteen renders through the forked banking). **NOT CLAIMED:** a living engine through a pass — the Decibel piece's retake pass is the first run.

**Also in that window, for the record:** the performers' FIRST RUN ON A SERVER — e1 · e2 · e3 through far apart, approaching (beats after their targets), close pass (bets hit and missed), break and rejoin (`REJOINS — a cluster broke up`), far apart; `performers · stopped — 3 ended`; no error. Two small things (NITS): the input meter line drifts under its floor after a long silence (`bcl in -498.5 dB`) · a performer's bet never expires (`MISS — perc played 7937 ms after the prediction`, across a break's silence).

**Why this is the engine's and not the piece's:** the pool, the thread, the measure and the banking are the machinery every piece runs; the piece's part was the pass that found them (its §194: the raw windows on disk read against the index) and its answer meanwhile (no plan during a capture pass; the renders after it by its deal tool).

## §52. THE LOOP AROUND THE PETALS · THE STRINGS AS RINGING PARTIALS · THE DEF BY FILE (2026-10-07, Fable, in the Decibel piece — its RUNNING_LOG §201 · §203; DEC-40)

**What prompted it (the piece's DEC-40):** his feedback chords, heard, were *"a distorted overtone series"*; what he wants is the petals' behaviour — an impulse makes it ring — with *"slightly more gritty guitar feedback"*. The piece's §201 named three routes; his word: *"let's hear A first, and then, if necessary, we'll move to C and B"* — A heard (seven stacks, the piece's §202), then: *"Okay, those are all pretty good. Let's actually go on to C and B."* Two things in the chain, both ENGINE (they work for any piece), and a fault of the renderer met on the way.

**(c) THE LOOP AROUND THE PETALS — `petalsOrig` gains three dials (`process.scd`, the stage; `le_process.js`, the row and the hints):** `poBloom` (s; 0 = NO LOOP, his SynthDef exactly as it was) · `poDrive` (the amp: tanh at poDrive, unity for small signals, a ceiling of 1/poDrive) · `poHold` (s from the start; then the loop is broken — × 0.25 over 0.6 s, as the feedback stage's — and the bank rings down on its own; his fade is moved to max(ringHi, hold + 3) while the loop is on). The bank's mix (× −40 dB, as his) goes through the amp and back into the bank's input one block later. **The gain from the bloom, derived then measured:** a resonator driven at its resonance grows by about sr/2 per second per unit of input (Ringz: a steady gain of T·sr/13.8, reached over T/6.9 s); the bank at −40 dB lifts at g × 0.005 × sr nepers a second, less its own decay 6.9/T — so g = (6.9/bloom + 6.9/T) / (0.005 sr), T the middle of the two rings; the same number as the pole of a unity resonator in a loop, (g − 1)/τ with τ = T/6.9: g_steady = 1 + T/bloom. MEASURED (process_test.scd ~16: the bank of ~11, ring 1 … 2 s, bloom 1 s, hold 2 s, drive 6): held at −2.2 dB under its peak through 1.5 … 2 s (the bare ~11 has fallen 40 dB by then), the loop broken at 2 s, −21 dB at 3.5 … 4 s, over at 5.1 s; RMS per 500 ms −16 −17 −17 −17 −17 −22 −32 −41 −51 −62 — a flat hold at the amp's ceiling, then the ring.

**(b) THE STRINGS AS RINGING PARTIALS — the feedback gains `fbRes` (0 a string is a COMB at 1/f, every harmonic of its pitch, as it was · 1 ONE RINGING PARTIAL, a Ringz at f) and `fbRing` (the string's ring, s; 1.5 as the comb's was — the comb's decay was a fixed 1.5 and is this dial now).** Both loops (the one loop and "every string sings") take the switch. **The Ringz at unity:** its gain at resonance is 1 / (2 (1 − R)), R = exp(−6.9078 / (ring × sr)) (a0 0.5, the zeros at ±1), so × 2 (1 − R). **The one loop's gain for a partial — wrong twice, then measured right:** (1) under the comb's formula (60 dB over the round trip per bloom second, +1.1 dB at bloom 0.5) the partial FELL — a resonator integrates over its ring, and the strings are summed × 0.5: measured −11 dB at 0.9 … 1.4 s. The pole: (g − 1)/τ → g = 1 + ring/bloom, and twice that for the × 0.5. (2) With that gain the chord sang TO THE CAP (5.3 s): the break (× 0.25 of a gain of 8) left the loop at unity → the partial's break goes to an ABSOLUTE 0.5 (a quarter of unity after the × 0.5) over 0.6 s. MEASURED (~17: E4 · F#4 · A4, the chord of ~13 that never bloomed as combs): at the peak by 0.3 s, held 0.0 dB through 0.9 … 1.4 s, over at 4.1 s; **the winner takes all — E4 at 0 dB, F#4 −39.6, A4 −48.4: a shared amp lets the strongest partial win, as a guitar's feedback picks one note.** (~18, every string sings as partials: all three at 0.0 dB — a chord of clipped partials.) **The two loops share ONE LocalIn/LocalOut pair** (two channels, read once before the petals; the feedback's `LocalIn.ar(1)` became `loopIn[0]`).

**THE DEF BY FILE — a fault of the renderer, met at the first run of the test: every render failed** (`ERROR: makeSynthMsgWithTags: buffer overflow` · `/d_recv failed` · `SynthDef leProcess not found` — the whole battery, the old cases too). `leProcess` is **72,547 bytes, 159 controls** (`def_size.scd`): the score's `['/d_recv', self.processDef.asBytes]` outgrew the language's OSC message buffer (64 KB) with the twelve Ringz and their Selects. **Fixed:** the def is written ONCE per engine run to `<bank>/raw/leProcess.scsyndef` (`writeDefFile`) and the score loads it (`['/d_load', defPath]`) — the real-time server already got it that way (`SynthDef:send` falls back to a file past its own limit). Any further growth of the chain is free of the OSC limit now. **The battery:** `process_test.scd` has three new cases (~16 · ~17 · ~18) and counts eighteen rows; PASS at the third run.

**For another piece:** a preset with `poBloom` > 0 is the guitar's physics on the petals (a swell to the amp's ceiling, the grit of the tanh, the hold, the ring); `fbRes` 1 in the one loop is a single feeding-back note, with each string singing a chord of clipped partials. The dials' ranges are the page's row; the first numbers are this piece's auditions (its §203).
