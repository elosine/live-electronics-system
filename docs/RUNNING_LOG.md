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
