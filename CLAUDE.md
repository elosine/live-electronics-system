# live-electronics-system — the shared live-electronics engine

**What this is:** ONE live-electronics engine, with its notation and graphics, built once and dropped into THREE pieces — the
Decibel piece · the Switch~ piece · the composer's improvisation with live electronics (his words: `septet_LGMF_2026`
COMPOSITION_NOTES LG-346 · LG-348 … LG-351). **Not a piece** — it has no score of its own. It is a **MODULE SET with named
SEAMS** that lives INSIDE each piece's folder (a git submodule): its files live once on disk and are seen from every piece;
a piece records the engine commit it uses. Planned 2026-10-03 with the composer in piece #6's lab journal — **`#6 §805 … §814`**
(`septet_LGMF_2026/docs/RUNNING_LOG.md`); the plan is `docs/PLAN.md` here.

**The lineage:** the custom-composition-system pieces #1 … #6 (`composition-system/INDEX.md`). The engine is a PORT of the
experimental work in `live-electronics-engine` — the sandbox, which stays alive for experiments — into the stack the pieces
share: the composer score · the notation engine · the Reaper rack (pieces #4 … #6). The three pieces themselves are a NORMAL
PORT of that stack (the new-piece protocol, `composition-system/protocol/NEW_PIECE_PROTOCOL.md`); the engine is added to each.

**The three seams** — where the engine plugs into a piece's stack (`docs/SEAMS.md`, filled at part 3):
- **the composer score** — a mixin file + one script tag (the way piece #6's `texture_row.js` · `harmony_sel.js` · `vibes_pitch.js` went in, without touching the drawer)
- **the sound path** — the processing sits DOWNSTREAM of the sample (an effect in Reaper switched by a message from the score, or the sandbox's own process fed the audio — which is part 4's design); the composer score's part is a TRIGGER that sends its message at its time
- **the notation** — a new graphic = a rules row + a drawn or animated kind + its edge class (the piece's `check_rules` · `check_screen_edges` hold that shape)

**The boundary:** the engine holds the GENERIC machinery (routing · the effects · the trigger kinds · the glyph kinds); the
piece's SAVE holds the uses (which note · which effect · which glyph · when). The piece's save stays the ground truth; the
piece's extractor emits the trigger events like any other.

**THE RULE THE ENGINE'S CODE OBEYS — ADDITIVE:** new files, registry rows, one hook line each. Every line a stack file must
change is listed in `docs/SEAMS.md` and applied once per piece at the take (`docs/TAKE.md`, part 8). If the engine had to
rewrite stack files, "take the engine" would be a patch, not a drop-in — and the engine would belong inside the first piece
instead (the option set aside, `#6 §806`).

**How it is built and taken** (`#6 §807 · §808`): built in the FIRST piece, where he hears it, landing here as it is built;
each piece pulls at ITS moment, never automatically, and records the commit; a piece's lock pins it; parallel work on the
pieces is the normal case. A change made for one piece reaches another when that piece pulls — the additive rule, the shield
and the batteries run in the piece that takes a change cover it.

**State (keep this line current):** **► 2026-10-06 (RUNNING_LOG §49 · §50, Opus, in the Decibel piece): THE COMPUTER PLAYERS — A PERFORMER, the first object that DECIDES. `sc/performer.scd`: a performer is in a STATE for a container of time and decides sound by sound from what it HEARS — far (its own pace, a clock) · approaching (a beat after its target's onset) · closePass (just after, or a BET before the predicted onset; never with) · breakRejoin (silence, then in as a cluster breaks up) · change (a weighted coin between two); `/le/performer  id · state · [from · to] · t · dueMs · lengthMs · [offsetMs · wholeMs] · pal · [target · targetFrom · seed · mark · silenceMs · ear · dials · pass · zone]` · `/le/performerstop`; a sound has a generation and an answer stops at a depth; a listener with nothing to answer plays unprompted; a cluster is defined. The rules are functions with the TIME HANDED IN (`perfTake` · `perfHear` · `perfStep`); `perfRun` is a 10 ms clock that hands each sound to the server 30 ms ahead. TWO EARS through one door (`perfNote`): `sim` — a score tells each simulated note (`/le/onset … sim 1`) · `mic` — the onset probe; the performers hear each other. `score/le_performer.js`, a MIXIN on `LEObjects`: the brick `elecPerformer` (its label, its panel, its message, a start inside it, a stop) and THE SIMULATED EAR on the transport's tick. Proven OFFLINE — `sc/performer_test.scd` (new, 17 checks, no server) — and the brick under a stub window and SEEN in the Decibel piece's running page. NOT CLAIMED: a performer through a living engine (`perfRun` · `perfSound` parsed, never run); the `mic` ear for a concert (the probe hears a rise out of silence only — NITS); the composer's ear.** *(Before it:)* **► 2026-10-06 (RUNNING_LOG §47 · §48, Opus, in the Decibel piece): A GENERATED VOICE — THE SINE, and the fourth composer-score object. `sc/sine.scd` · `\leSine` (`sc/synths.scd`): a sine with a level line and a pitch line in cents, `/le/sine  id · lane · t · dueMs · midi · lengthMs · [level · levelCurve · gliss · pass]` (the lines as `ms:value` pairs, as `/le/play`'s `env`) · `/le/sinestop`; heard with or without a bank; ITS LEVEL IS EXACT — a mark of the ladder becomes the sine's peak by formula, `markDb + 0.691 − K(f)`, no measurement. `score/le_sine.js`, a MIXIN on `LEObjects`: the brick `elecSine` — a pitch with its cents, a length, a gliss kind, a level flat · hairpin · FOLLOWING A DRAWN CURVE read through the host's reader handed in at attach (`opts.curveAt`); a playhead that starts inside a sine starts it for what is left; a stop reaches the engine (the host's `stopPlay` wrapped; a restart or a jump by the message's `pass`, each sine known by its own node). Proven OFFLINE — `sc/sine_test.scd` (new: a 50-cent glide on its line within 0.02 cents; held at ff it reads −33.6 LUFS against −33.54) · `tools/sine_page_test.js` (new, 33 checks) — and the brick SEEN in the Decibel piece's running page. NOT CLAIMED: a sine through a living engine (`sinePlay` · `sineLetGo` parsed, never run); the composer's ear.** *(Before it:)* **► 2026-10-06 (RUNNING_LOG §46, Fable, in the Decibel piece): THE ICY STAGE LOOPS — `icLoop` (`sc/process.scd`: 1 = the read point wraps at the source's end and reads it again from the start, for a drone from a held sound; 0 = it holds at the end, as before — the engine's default; the Decibel row defaults to 1 with `from` 0); the row's option and hints in `score/le_process.js`. Proven headless (`sc/process_test.scd`: the looper still reading a second in, the holder's tail dead at 671 ms; fifteen renders). NOT CLAIMED: the composer's ear; the seam of a wrap.** *(Before it:)* **► 2026-10-06 (RUNNING_LOG §42 … §45, Opus, in the Decibel piece): THE LEVEL IS IN — part 13 whole. `sc/level.scd`: a sample's LOUDNESS (BS.1770 in the language — `loudDb` · `loudIntDb` · `played` on every row, at capture and at render; `measureBank` for a bank as it stands), THE LADDER of marks (`LE_LEVEL`; `markDb` · `gainFor`), THE DYNAMIC a return is played at (`dyn` · `env` on `/le/play` → `\leSample`'s envelope, joined in decibels). THE DRIVE (`srcDrive` on `/le/process`, a plan row's eleventh field; a dial as a line). THE BUS (`\leMaster`: switched filters · a soft-knee RMS compressor · a linked look-ahead limiter that cannot overshoot · the clip; `LE_MASTER` · `/le/master`; `\leLoudness` — momentary LUFS and true peak). THE HOUSE (`\leIn`'s chain · `LE_VENUE` · `sc/calibrate.scd` · the room and the bleed guard in `bank.scd` · `/le/tone`). The page: a return brick's Dynamic and Drive (`score/le_objects.js`), a stage's Drive and a dial as a line (`score/le_process.js`). Proven OFFLINE — `sc/level_test.scd` · `sc/bus_test.scd` (new) · `sc/process_test.scd` · `tools/page_test.js` (new). NOT CLAIMED: the composer's ear; ANY of it through a living engine — `session.scd`'s start and `selftest.scd`'s rewritten A · B are parsed, not run.** *(Before it:)* **► 2026-10-06 (RUNNING_LOG §40, Opus, in the Decibel piece): THE COMPOSER'S PETALS OF RESONANCE ARE IN THE CHAIN, TWICE — `petalsOrig` (his SynthDef UGen for UGen, the microphone replaced by the chain's signal) and `petals` (the same instrument by a cleaned path: one bank of 26 Ringz, the wobble and each partial's ring drawn per render) — and THE FEEDBACK HAS `fbOwn`: 0 the loop as it was (it takes off only where two strings share a harmonic) · 1 EVERY STRING SINGS, a chord on the six strings. A preset marked `deal: false` is left out of a pattern brick's pool; a brick's tag may be 48 characters. Proven headless (`sc/process_test.scd`, thirteen renders). NOT CLAIMED: the composer's ear; a render of the new stages through a living engine.** *(Before it:)* **► 2026-10-05 (RUNNING_LOG §39, Fable, in the Decibel piece): A FIFTH STANCE IN THE ROLLS — `far` after (between lazy and unison; `sc/bank.scd` `arRoll` · `chainRoll`; a share of 0 by default, so a piece that says nothing hears no change); `roll_test.scd` PASS.** *(Before it:)* **► 2026-10-05 (RUNNING_LOG §38, Fable, in the Decibel piece): A PATTERN BRICK DEALS A PRESET PER IMPACT — `score/le_objects.js` `elec.fx` (`dealVariants` · `fxPool` · `raw`): every onset of a composed rhythm its own variant `<sample>~<key>-<env>`, round robin through the piece's presets, seeded; the plan a row per onset at the onset's time; the boxes offer raw samples only. Proven under a stub window (17 checks). NOT CLAIMED: the composer's ear.** *(Before it:)* **► 2026-10-05 (RUNNING_LOG §36 · §37, Fable, in the Decibel piece): TWO GRANULAR VOICES IN THE CHAIN — `cloud` (GrainBuf: long asynchronous grains from one moment of the chain's signal, held) and `icy`, THE COMPOSER'S OWN FREEZE of 2015 … 2016 (`github.com/elosine/freeze`: Warp1 over the same buffer, a crawling read point, 0.6 … 0.8 s windows, 17 … 40 grains, his ten grain windows in `sc/grainEnv/`, loaded into buffers 1 … 10 by every offline render; ungated — the mix alone decides the attack); the resonator bank's four pitches are controls (`resF1 … resF4`). Proven headless (`sc/process_test.scd`, ten renders). NOT CLAIMED: the composer's ear on the hundred presets a piece now draws from them.** *(Before it:)* **► 2026-10-05 (RUNNING_LOG §35, Opus, in the Decibel piece): THE PLAN IS IN — a return brick may ask for a VARIANT of its sample (`elec.variants`: one effect of the chain under an envelope, from the piece's presets file — `<sample>~<key>-<env>`); the page tells the engine every variant its bricks will ask for (`/le/plan`, in parts that share a stamp) and the engine renders a sample's variants RIGHT AFTER ITS CAPTURE, the soonest-needed first, two at a time (`sc/process.scd` `planTake` · `planRender` · `planNext`; `/le/planrender`; `durX` in `/le/process`); a variant asked for too early falls back to its earlier render or to the sample, raw (`sc/bank.scd` `sampleFor`). Proven headless (`sc/process_test.scd`) and under a stub window. NOT CLAIMED: a plan through a living engine; the composer's ear. NEXT: by the piece's need.** *(Before it:)* **► 2026-10-05 (RUNNING_LOG §26, Opus, in the Decibel piece): THE PROCESSING IS IN — the sandbox's chain ported whole (`sc/process.scd`, `\leProcess`: resonators · drive · the ring modulators · shift · comb · filter · string · diffusion · smear · gate · freeze · three reverbs · tape · noise), rendered OFFLINE (NRT) from a banked sample's file into a NEW banked sample `<root>~<n>`, ended by a SHAPE (an envelope: the processed timbre with a struck shape) or by its TAIL; and a THIRD composer-score object, the PROCESS BRICK (`score/le_process.js`, a mixin on `LEObjects` — its catalogue of eighteen effects, its panel, Render). `*` now means every CAPTURED sample. Proven headless: `sc/process_test.scd`. NOT CLAIMED: the composer's ear; a render through a living engine. NEXT: the granular voices and his pedals of resonance, by the piece's need.** *(Before it:)* **► 2026-10-05 (RUNNING_LOG §17 … §24, Fable, in the Decibel piece): THE RETURN HAS FOUR BEHAVIOURS — `ar` · `chain` · `arChain` ROLLED by the engine (the dice its own, the dials a piece's), and `pattern` COMPOSED in the brick's panel (§24: two rows of boxes pick the samples, a small seeded generator of this module's own, one message carries the onsets, the engine plays each on time; §25: the Strikes drawer's whole menu — accel · round robin and containers — by the HOST's calculators handed in at attach, the samples dealt onto a run's onsets, a level per onset). The bank knows `*` (every sample, §21); the behaviours are proven headless by `sc/roll_test.scd` (§22). NOT CLAIMED: the composer's ear. NEXT: what the Decibel piece's music reaches next.** *(Before it:)* **► 2026-10-04 (RUNNING_LOG §14, Opus): THE ENGINE DOES ITS FIRST WHOLE THING — 4.3 · 4.3b · 4.4 · the index · part 11's first two objects BUILT AND PROVEN in the Decibel piece: a brick in a score opens a microphone, the window is recorded, cropped to its attack, saved under its name and indexed (`sc/bank.scd`), and a second brick returns it at unity where it is placed (`score/le_objects.js` — zones with a model of their own). The self-test is SEVEN tests. A player's own sound no longer goes to the master (`LE_PASS` · `LE_ECHO` are route checks). The runner knows a server's OWNER: an ownerless server is cleared before a start, a living engine never touched. `docs/SEAMS.md` is whole for all of it. NOT CLAIMED: the composer's ear. NEXT: the next object, when the Decibel piece's music reaches it.** *(Before it:)* **► 2026-10-04 (RUNNING_LOG §5 … §7, Opus): THE FIRST CODE IS HERE, AND THE SEAT IS MADE — the engine sits in the Decibel piece as a git subtree at `electronics/`, WHOLE (docs and code); while a piece is the place of work its docs are edited THERE and this repo's stand-alone clone is a mirror (`docs/TAKE.md`). Part 4, the sound path: SuperCollider real-time on UDP 57210 — `sc/` · `tools/sc.js`; its self-test passes (the pass-through sample-exact · the safety · the latency probe). NOT PROVEN: the crossing itself — ReaRoute is not on his machine (his hand). NEXT: 4.1 (e) in the Decibel piece once it is; then 4.2 the message.** **► LATER THE SAME DAY (RUNNING_LOG §8): 4.1 DONE — the crossing proven there: unity, two DAW blocks of latency; `docs/SEAMS.md` has the three facts a piece's DAW job needs. NEXT: 4.2 the message, a talk.** **► LATER STILL (RUNNING_LOG §11): 4.2 BUILT — the message route: the LANGUAGE hears a piece's score on UDP 57211 (`sc/boot.scd` the ear · the onset probe), `tools/osc.js` · `tools/relay.js` · `score/le_msg.js`; a message is `/le/<kind>` + NAME, VALUE pairs; proven in the Decibel piece to the edge of Web MIDI. NEXT: 4.3 the capture and 4.3b the crop, a talk.** **► AND (RUNNING_LOG §12 · §13): 4.2 DONE — the lead measured, 114.2 ms; 4.3 · 4.3b · 4.4 · the index LAID OUT as one build (`docs/PLAN.md` part 4). NEXT: that build, in the Decibel piece.** *(Before it:)* **► 2026-10-04 (RUNNING_LOG §4, Fable): THE SEAT REFINED at his word — a git SUBTREE at `electronics/` inside each piece, not a submodule; he never touches it, the AI pushes here at every wrap. Part 5 re-read: the first sound is a note CAPTURED and RETURNED; the filter third. The first code will be built in the Decibel piece by its running order (its journal §2, steps 6 … 10). HERE nothing in hand.** *(Before it:)* **► 2026-10-04 (RUNNING_LOG §3): 9.1 — THE DECIBEL PIECE'S REPO EXISTS, `decibel_TENOR_2026` (public; the new-piece protocol's container 2 done, no code there yet; its record is in THAT repo). HERE nothing is in hand until the first take — which needs that piece's copy-forward (its container 3) and parts 3 · 4 laid out.** *(Before it:)* **► HIS PICK 2026-10-03 (`#6 §815`): PART 9's FIRST RUN — the Decibel piece's repo, by the new-piece protocol, begun in a new session from piece #6's checkpoint #5 (its record lives in THAT piece's repo, not here). HERE: nothing in hand until the first take — parts 3 the seams · 4 the sound path · 5 the first sound · 8 the take, each laid out when he reaches it; before part 4 is put to him, read the sandbox `live-electronics-engine`'s CLAUDE.md.** *(Before it:)* **► PART 1 DONE 2026-10-03 (Fable, `#6 §814`): the repo made, public, pushing after every
commit; the kit in; `docs/PLAN.md` written — twelve parts, part 1 laid out, 2 … 12 top line only. NEXT: the part he names
(the order and the timing are HIS — never framed by a date); structurally, 9's first run (the Decibel piece's repo by the
protocol) comes before 5 the first sound. Journal §2's first block is the cold-start block.**

## READ FIRST — how to work here

**`docs/AI_METHODOLOGY.md`** is the composer's standing instruction on scoping, decisions,
and confidence (inherited unchanged from piece #4 by way of #5 and #6). It governs everything below
and outranks the working-preference docs where they conflict. In short: fix what blocks the
work and flag the rest to `docs/NITS.md` · don't make the composer decide minutiae ·
prefer one robust build over a fragile one · **a confidence claim must be verified in the
running app** · no clear evidence means no diagnosis.

The composer's own rule for a port (said of piece #5's, 2026-09-03; it holds here):
*"I don't want to get too bogged down in technical details of porting and code and such,
but I want to do a good, solid job and not leave out things now that might bite later ...
leaving everything we can for when the time comes."* Keep the conversation at the
conceptual level; consult the code yourself. **In this repo that rule is the plan's own rule:** the parts are
containers; a sub-part is added the moment it is needed and not before (`docs/PLAN.md` header).

**How he reads (his user-level CLAUDE.md, 2026-08-24):** succinct
language, clear spatial division between chunks, short lines, one idea per chunk, bullets
first. A one-line TL;DR leads any reply over two paragraphs. One step at a time.

**He keeps his own time** (his word 2026-10-03, `#6 §806`): no schedule keeping, no deadline watching, no ordering by date
from the AI. The AI gives the parts, the dependencies and what is efficient; the order and the pace are his.

**A NEW NOTATION BEGINS WITH A DEVICE SHEET** (`docs/PLANNING_METHOD.md` § THE DEVICE SHEET): the engraving rules are the
piece's `notation/registry/rules.json`, read through its generated `docs/ENGRAVING_RULES.md`; the engine ADDS rows, it
never edits a code number. Parts 7 and 12 are made of device sheets.

## Orient from docs, not from scanning

- **What the pieces share — the index, read at every session start:** `composition-system/INDEX.md`
- **ANY WORK ON THE SOUND PATH — READ THIS FIRST:** the piece's `docs/DYNAMICS_LAW.md` (piece #6's is the current copy) — the two
  kinds of note, the fader on the curve channels; the engine's processing sits DOWNSTREAM of that sample and must not undo it
- **What now / what next:** `docs/PLANNER.md` — the **NOW ►** line
- **Living plan:** `docs/PLAN.md` — stable IDs; the twelve parts; the rule in its header
- **Session state, decisions:** `docs/PROJECT_JOURNAL.md` — §2 Resume Here first
- **The lab journal:** `docs/RUNNING_LOG.md` — append-only, written as the work happens; **a bare `§N` here is THIS repo's; piece #6's is `#6 §N`**
- **Where the engine plugs in · how a piece takes it:** `docs/SEAMS.md` · `docs/TAKE.md`
- **Building a plan item / analyzing an issue for the plan:** `docs/PLANNING_METHOD.md` — three phases, fixed formats
- **Deferred, real but not now:** `docs/NITS.md`
- **Working preferences & routines:** `docs/HOW_WE_WORK.md` · `docs/SESSION_PROTOCOL.md` · `docs/SESSION_HYGIENE.md` (clear between chunks; the docs are the handoff)
- **No sketch pad here, by design (his to reverse):** a musical idea about the electronics is an LG note in the PIECE that has it —
  the brief for this engine is `septet_LGMF_2026` LG-340 … LG-345 (the device) · LG-346 (the order) · LG-348 … LG-351 (the plan's talk).
  A process note about the ENGINE itself goes in this repo's RUNNING_LOG, verbatim, the AI's reading marked.

Do NOT scan or analyze the codebase unprompted. Name the question first, then read only
what answers it. High bar for subagents / background processes.

**After `/clear` + `/postclear` (his standing rule, 2026-09-11):** play back, then **STOP
and ask**. No edits, no builds, no tool calls beyond the resume reads. Start only on his
word. At `/session-start`: orient, agree the agenda, then work.

## Standing practice: the lab journal (composer, 2026-09-03 — not optional, never asked for)

> *"I'd like to keep a running journal like lab notes, so I can look back on decisions or
> comments, theory, philosophy, etcetera, or how we actually made something, if I wanted
> to write a paper later about this — and I would expect the AI agent to do this
> automatically as a habit."*

The rules, adopted from `live-electronics-engine` (its CLAUDE.md and `docs/journal/README.md`):

- **When:** at the end of any exchange that produced a decision, a result, a rejection, a
  measurement, a theoretical or philosophical point, or a question worth remembering.
  Not at session end — by then the reasoning has blurred.
- **What each entry carries:** what prompted it, in the composer's words, quoted not
  paraphrased · what was tried, in order · the numbers · what was rejected and why (dead
  ends at the same weight as successes) · what was decided, and why that rather than the
  alternative · corrections as NEW entries, never edits.

**EXTENDED TO THE COMPOSING ITSELF (composer, 2026-09-18):** *"could you remember to take
journal notes during the comp process and remind somehow future agents to do the same, lab notes so if I want to come back
and write a paper on how I wrote this piece."* The engine is built WHILE a piece is composed, so the two logs run together:
what settles the ENGINE (a mechanism, an effect's design, a seam) goes here; what settles the PIECE goes in the piece's log,
and each cites the other (`#6 §N` here; this repo's name and `§N` there). **The test: could someone write the paper "how
this engine was made" from this log alone?** Future agents: this is not optional and he will not ask for it.

- **Append-only.** The journal is the record of how the thinking went; it is never tidied.
  Current state lives in the plan, the journal §2 and the READMEs, which are rewritten freely.

*The morph-notes practice of pieces #5 · #6 is NOT carried: the morph tool is a composing tool of the pieces, not of the
engine. Checked heading by heading against `septet_LGMF_2026/CLAUDE.md` at the first commit (`#6 §814`).*

## THE RHYTHM — next steps · model · clear (standing, composer 2026-08-23; carried whole)

*(It was in piece #4's CLAUDE.md and the copy-forward to piece #5 dropped it, so it loaded
in no septet session for a week and the advice came only sometimes — his own verdict,
2026-09-10: "This was happening for a while, but then is inconsistent." It is carried here
from the first commit, deliberately.)*

**REFINED by him, 2026-09-18 (guidelines, not hard rules — his user-level CLAUDE.md, "The shape of a working reply"):**
*"the next model clear dialog is good, but lets keep that more focused and local, only when we are moving on to something
that needs a model change or clear"* — and *"no more things left to do, or left pending or even whats next unless I
specifically ask."* So **in the CHAT:** model / clear advice only at a real switch point, one or two lines; no next-steps
list unless he asks; replies are a goal heading, a short ✓ trail, the one thing in hand with a brief why per step, and ONE
compact notes section at the bottom for the honest side-matter. **And (2026-09-18):**
*"avoid unnessary extra work unless asked for, so like verifications and such unless we write these into a plan as necessary
verifications and qc"* — no probe, no cross-check, no QC pass that he did not ask for or that the plan does not name as a
required step; if something looks worth checking, ONE line offering it, and he decides. This does not relax
`AI_METHODOLOGY`'s rule that a confidence CLAIM must be verified in the running app — unverified simply means unclaimed.
**In the DOCS nothing changes:** journal §2's NEXT STEPS · MODEL · CLEAR table is still kept current — it is the handoff,
and it is what makes the chat free to stay on one thing. The paragraph below is the 2026-08-23 original; read it through this.

At every juncture — a chunk wrap, a milestone, a mode change (execution ↔ conversation),
or when asked "where are we" — the AI **states the next 2–4 logical steps, each with a
recommended model and whether to clear before it**, and **says out loud when a good clear
or switch point has arrived** ("this is a good time to clear", "switch to Opus for this").
Not when asked — as a habit, like the lab journal. The rule for the recommendation is in
`docs/SESSION_HYGIENE.md` § Model strategy (Fable = judgment / verdicts / design;
Opus = executing a written plan; clear at milestones and mode changes; the cold-execution
test before any clear).

**The running thread lives in `docs/PROJECT_JOURNAL.md` §2 → "NEXT STEPS · MODEL · CLEAR".**
Keep it current as steps complete — it is the first thing a model reads after a clear, and
it must say what is next, with what model, right now.

**Fable's allotment is separate and is the one he watches** (composer, 2026-09-10). So the
routing advice is also credit advice, and these bind every Fable turn:
- **Fewest round trips.** Batch independent reads and tool calls into one response; no
  exploratory reads; name the question before opening anything.
- **No screenshots unless the screenshot IS the proof he asked for.** `read_page` otherwise.
- **Never spawn a subagent on Fable.** If one is ever justified, pass `model: "sonnet"`.
- **Wrap on Opus.** `/checkpoint` and `/session-end` are mechanical work at the long,
  expensive end of a session: switch to Opus, wrap, `/clear`, switch to Fable, `/postclear`.
- **A `Resume reads:` list names what the NEXT STEP needs, not what the last session wrote.**
  Every line on it is re-read in every turn of the session that follows.

## Apps

- **The engine has no app of its own.** It runs inside a piece's composer score (`node score/server.js` there) and notation
  app, and sounds through the piece's Reaper rack. It is exercised and verified IN A PIECE — on that piece's throwaway
  server (`score-5401` in piece #6's `.claude/launch.json`), never his port.
- **`.claude/launch.json`:** none here until a part needs one.
- **The sandbox** `live-electronics-engine` has its own apps and its own record — the source of part 2's port; read-only here.

⚠ **Standing warnings, inherited and still true:** the AI never holds his port and never saves from its own browser pane
(piece #5's principle 9) · the in-app browser has no Web MIDI, so every MIDI path is verified on his Chrome · loopMIDI ports are
machine-global and the pieces' racks may be live — the engine never binds a piece's `LG…` ports or piece #5's.

**Checks this repo owns:** `node tools/sc.js run sc/selftest.scd` (in a piece: `node electronics/tools/sc.js run electronics/sc/selftest.scd`) — SEVEN tests (A … E the route and the messages · F the crop · G the first object end to end), no hardware, no sound, exit 0 · `node tools/osc.js selftest` — the OSC encoder · `"C:/Program Files/SuperCollider-3.14.1/sclang.exe" sc/process_test.scd` (in a piece: `… electronics/sc/process_test.scd`) — THE PROCESSING, headless: four offline renders through the real chain on a scratch bank, no server, no sound; it ends `PROCESS_TEST PASS`, and a living engine beside it is untouched · each further part brings its battery when it is built; THE SHIELD (`tools/layout_shield.js` of the · **THE LEVEL, offline and safe beside a living engine (part 13):** `… sclang.exe" sc/level_test.scd` — the measure, the ladder, the envelope, the bus's dials, a session's start from its environment, A PARSE OF EVERY FILE THAT BOOTS A SERVER, the guard; it ends `LEVEL_TEST PASS` · `… sclang.exe" sc/bus_test.scd` — the engine's own SynthDefs in NRT, the files measured: the master (unity to the sample, the ceiling, the glue, the filters), the meter, `\leSample`'s envelope, `\leIn`; it ends `BUS_TEST PASS` · `node tools/page_test.js` — the composer-score module under a stub window; `PAGE_TEST PASS`. · **THE SINE, offline and safe beside a living engine:** `… sclang.exe" sc/sine_test.scd` — the figures, `\leSine` in NRT measured (the glide, the level, the K shelf, the stop); `SINE_TEST PASS` · `node tools/sine_page_test.js` — the sine brick under a stub window; `SINE_PAGE_TEST PASS`. · **THE PERFORMERS, offline and safe beside a living engine:** `… sclang.exe" sc/performer_test.scd` — the rules with the time handed in, a scripted stream of onsets: the message, far apart, approaching, the close pass and its bets, the depth, the break, a change, a new pass; `PERFORMER_TEST PASS`. **A test that forks is run under a time limit** — a routine that throws never reaches its exit.
piece) runs in the piece that takes a change, before and after.

## Reference repos (read-only context)

- **The sandbox** `C:\Users\jwloy\GitHub\live-electronics-engine` — the source of part 2's port: the experimental live-electronics
  work; its CLAUDE.md and `docs/journal/README.md` are where the lab-journal rules came from. **Never edit it** — it stays alive
  for experiments; the port TAKES from it.
- **The pieces #1 … #6** — by `composition-system/INDEX.md`. Piece #6 `septet_LGMF_2026` is the current stack and the plan's
  record (`#6 §805 … §814`); piece #2 `composition_for_two_pianos_and_two_percussion` holds the CELLS LG-341 names
  (`docs/CELL_ARCHITECTURE_ADR.md` · `CELL_CODE_MAP.md`). **Piece #5 has the composer's own uncommitted files — never stage,
  move or edit anything there.**

Consult only when a specific named question requires it. Never edit them.

## Git

- Commit at the natural wrap of an approved chunk; reference plan IDs (`N.m`) in messages.
- Stage **explicit paths only, never `git add -A`**.
- **Push after every commit** — his word, 2026-10-03: *"live-electronics-system (if available), public, push after every commit"*
  (`#6 §813`). Do not ask.
- **PUBLIC repo:** nothing personal lands here — no call screenshots, no account details, no licensed fonts.
- **THE SEAT IS A SUBTREE (RUNNING_LOG §4 · §7; `docs/TAKE.md`):** in a piece this repo IS the folder `electronics/`; the piece's session commits there as always and the AI runs `git subtree push --prefix=electronics engine main` at every wrap, then pulls the stand-alone clone. Read "submodule" below and above as history.
- **A commit here reaches a piece only when the piece pulls** (`git subtree pull`). A piece pulls at ITS moment, never
  automatically; a piece's lock pins the commit it was submitted with (`docs/TAKE.md`).
