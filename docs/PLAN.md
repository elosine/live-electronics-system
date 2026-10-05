# PLAN — live-electronics-system

> **Rules:** IDs are stable — never renumber, only append. Status: `todo` / `doing` / `done` / `deferred` / `dropped`.
> Every part keeps a one-line ***why***.
>
> **THE RULE OF THIS PLAN (his word 2026-10-03, `#6 §811 · §812`):** the parts are CONTAINERS with stable numbers. A sub-part is
> added under its part THE MOMENT IT IS NEEDED, with its own stable ID (`4.1`, `11.2` …), through `docs/PLANNING_METHOD.md`
> — a notation by a DEVICE SHEET, a build with THE SHIELD run in the piece that takes it. **Nothing is detailed before it is
> needed** — his own rule for a port: *"leaving everything we can for when the time comes."* A part he has not yet discussed
> carries one line: *to be laid out when we discuss it.*
>
> **The order and the timing of the parts are HIS** (`#6 §806`). The numbers are for reference only. The structural
> dependencies below are not an order.
>
> **Where this plan was made:** piece #6's lab journal, `septet_LGMF_2026/docs/RUNNING_LOG.md` §805 … §814, with his words in
> that repo's `docs/COMPOSITION_NOTES.md` LG-348 … LG-351. The brief for the engine's contents: LG-340 … LG-346 there.

## The objectives (agreed 2026-10-03, `#6 §808 · §809`)

1. **Three pieces**, each a repo set up by the new-piece protocol — the universal layer and a NORMAL PORT of the scrolling-score
   stack: the Decibel piece · the Switch~ piece · the improviser piece.
2. **One engine**, in its own repo (this one), ported from the sandbox's basic machinery, dropping into each piece ADDITIVELY
   at three seams: the composer score · the sound path · the notation.
3. **The composer-score side first:** a trigger object in the regular composer score routes a live instrument's MIDI note into
   an effect, so he hears the sampled note processed as it would be live.
4. **The effects, his brief:** the momentary-input class — the gate that opens the mic for an instant, then delay · loop +
   granular · freeze · Greyhole (LG-340) — and the saved impulses replayed by piece #2's cells (LG-341); with them, the
   mechanism of coordinating split-second input.
5. **The notation side, when notating comes:** new graphics in the regular notation score linked to the triggers — the GC
   carrying a capture glyph, the glyph vocabulary (shape or colour × the window's length), the collection on screen
   (LG-342 … LG-345).
6. **The piece's save stays the ground truth:** the engine holds the generic machinery, the piece holds the uses — which note,
   which effect, which glyph, when.
7. **The Decibel piece** built around the full ensemble as announced; re-orchestration his if it is scaled back.
8. **The improviser piece** may take only some of the objects.

**Not objectives, set aside** (`#6 §808`): the different score paradigm (LG-339, "something else") · the whole stack moved into
one shared repo · his flags 4.9 · 5.10 of the protocol (the instrument knowledge base).

## The structural dependencies (not an order)

1 before anything lands · the first run of 9 before 5 (the engine is built inside the first piece, where he hears it) ·
3 and 4 before 5 · 8 before the second and third runs of 9 · 7 when notating comes.

---

## 1. The engine repo — `done` 2026-10-03 (Fable, `#6 §814`)

***Why:*** the plan needs a file and the engine a home; one source for three pieces.

**Result when done:** `C:\Users\jwloy\GitHub\live-electronics-system` = `github.com/elosine/live-electronics-system`, public,
pushing after every commit, its kit in place and this plan written into its PLAN — so `/session-start` runs here and finds the
state line, the twelve parts and the rule. No code yet.

- **1.1 The repo made** ☑ — MIT LICENSE and `.gitattributes` carried from piece #6 · a `.gitignore` for a public repo · the first
  commit looked at before the first push (the home's lesson, `#6 §804`) · `gh repo create --public` · the push rule in CLAUDE.md § Git.
- **1.2 The kit** ☑ — the method docs carried whole from piece #6 @ `06ce0ac` with one provenance line each (AI_METHODOLOGY ·
  SESSION_HYGIENE · PLANNING_METHOD · HOW_WE_WORK · SESSION_PROTOCOL · the checkpoint and postclear commands — the protocol's 2.4);
  the record docs from the home's skeletons, filled for an ENGINE: CLAUDE.md (checked heading by heading against piece #6's) ·
  README · PROJECT_JOURNAL · PLAN · PLANNER · RUNNING_LOG · NITS. **Not for an engine, by design (his to reverse):**
  PERFORMANCE_NOTES · SWEEP_LIST · COMPOSITION_NOTES (a musical idea about the electronics is an LG note in the piece that has it) ·
  PROTOCOL_DEVIATIONS (the protocol's runs are the pieces'; a deviation of the ENGINE's start is a RUNNING_LOG line here) ·
  MORPH_NOTES (the morph tool is the pieces').
- **1.3 The plan written** ☑ — this file: the objectives, the rule, the dependencies, the twelve parts, part 1 laid out, 2 … 12 top line only.
- **1.4 The home** ☑ — one entry in `composition-system/INDEX.md` (the engine, the module manifest's first member, 9.11) · one line
  in its `LOG.md`. The planning repo's lists: only at his word — not touched.
- **1.5 Two files that parts 3 and 8 fill** ☑ — `docs/SEAMS.md` · `docs/TAKE.md`, each saying what it will hold.

## 2. The port from the sandbox — `todo`

***Why:*** the engine's first contents are the experimental work that already exists.
`live-electronics-engine` surveyed; the BASIC MACHINERY taken into the engine (the signal chain · the mastering chain with its
limiters and master bus · the analysis · whatever else is machinery, not experiment); what stays an experiment stays there.
*To be laid out when we discuss it.* **One line from the first run (2026-10-04, RUNNING_LOG §5):** the sandbox has NO live-input
path — it processes recordings; so for the FIRST OBJECT (the Decibel piece's 6.1 … 6.6) only the SC boot and the mastering chain
(`synths/process-chain.scd`, if it is one) port; the clouds, the freeze, the labs and his pedals of resonance come with the processing
phase.

## 3. The seams — `todo`

***Why:*** additive or it is a patch (CLAUDE.md).
The three plug points in a piece's stack named and, where missing, made: the composer score's script tag and hook · the
message route to the sound (OSC or MIDI from the composer score) · the registry rows for a notation kind. Written in
`docs/SEAMS.md`; applied once per piece at the take. *To be laid out when we discuss it.* **Known already (2026-10-04, RUNNING_LOG §5 · §6):** the sound-path seam's first lines are
one SEND from a player's DAW track to the engine's input and ONE FLAT RETURN TRACK (0 dB, no effects — the loudspeaker); the message
route is decided in the Decibel piece's 6.2 (a loopMIDI port read by `MIDIIn`, or OSC through the piece's score server).

## 4. The sound path — `doing` (the shape decided 2026-10-04 in the Decibel piece — RUNNING_LOG §5 · §6; his words in that piece's RUNNING_LOG §47 · §48)

***Why:*** he must hear the sampled note processed as it would be live — *"should actually use the actual pipeline."*

**The shape (his word 2026-10-04):** the sound process is **SuperCollider, REAL-TIME**. Live: the mics → the interface → SC's input
buses; SC's master bus (the mastering chain, from part 2) → the interface → the PA; no DAW in the chain. In a piece's simulation: the
sampled players in the piece's Reaper rack → ReaRoute → SC's input buses — the same code from there on; SC's output → ReaRoute → ONE
FLAT RETURN TRACK in Reaper (the loudspeaker; 0 dB, no effects), so the players and the electronics meet at one pair of monitors.
The simulation and the concert differ in ONE place: the input device. The sandbox's Web Audio layer is NOT the live path.

- **4.1 The audio route DAW → SC → DAW — `done` 2026-10-04 (RUNNING_LOG §8): the crossing PROVEN in the Decibel piece — unity (heard −42.6 · sent −42.6 · back −42.63 dB), the round trip two DAW blocks (23.22 ms at 512). (a) … (f) ☑; **HEARD by him the same day (RUNNING_LOG §10).** *(As it stood before ReaRoute was on the machine:)* BUILT 2026-10-04 (RUNNING_LOG §7), the crossing UNPROVEN. (a) ☐ HIS: ReaRoute installed, Reaper on ASIO · (b) ☑ `sc/boot.scd` · (c) ☐ the piece's job written and parse-checked, not run · (d) ☑ `sc/synths.scd`; the master = the sandbox's browser chain translated, its colouring stages off · (e) ☐ the engine's half ☑ (`selftest.scd`: sample-exact pass-through, the safety, the probe to the sample); the crossing and the latency ☐ · (f) ☑ `docs/SEAMS.md` the audio half; `docs/TAKE.md` step 1. (First run: the Decibel piece's 6.1, `decibel_TENOR_2026/docs/PLAN.md` 1.1).
  *Result when done:* one note from a piece's composer score heard direct and again after passing through SC untouched, on the flat
  return; the round-trip latency measured. The generic sub-steps: (a) the bridge driver present — ReaRoute ASIO on Windows (Reaper's
  installer option); a virtual cable the fallback · (b) SC's boot file — device, the DAW's sample rate, 16 in / 16 out; the boot
  convention from the sandbox · (c) in the DAW: one send per player track to an engine input channel; the flat return track — made by
  the piece's own tooling (the Decibel piece: its bridge) · (d) the pass-through patch + the mastering chain · (e) verified in the
  piece's running app; the latency the number · (f) `docs/SEAMS.md`'s sound-path row filled from what was proven. The code lives
  in the piece's `electronics/` (its journal D7) and comes here by `git subtree push`.
- **4.2 The trigger's message — a piece's score → the engine, OSC over UDP through the piece's score server — `todo` (LAID OUT
  2026-10-04 in the Decibel piece, its 6.2 — `decibel_TENOR_2026/docs/PLAN.md` 1.1; its RUNNING_LOG §57 · §58 · §59).** *Result when
  done:* a brick's onset in a piece's composer score is seen in the engine as one line, with its data, before its sound arrives; the
  lead measured. *The shape (the piece's D10 — concert and simulation on ONE road):* the browser (an iPad in concert; the composer's
  in simulation) → the piece's score server (an HTTP POST) → OSC over UDP → the engine's LANGUAGE port, pinned (57211) beside the
  server's 57210. The one difference between concert and simulation is the engine's address. Not a MIDI port (no concert
  counterpart) · not a WebSocket (a dependency the pieces' stacks refuse) · no shared clock (the capture is cropped to the attack, so
  the message need only be early). The generic sub-steps: (a) the engine's ear — `sc/`: the pinned port and one `OSCdef` for
  `/le/hello` · `/le/onset` (lane · id · score time · send time), each printed as `LE_INFO`, stamped with SC's clock · (b) the OSC
  encoder — `tools/osc.js`, dependency-free Node, sent by `dgram` · (c) the piece's server: one route in, one sender out to the address
  in its route table · (d) the first composer-score mixin — `score/le_msg.js`: `LE.send(kind, data)`; the piece adds one `<script>` tag
  and one hook line where its playback emits a note · (e) verified in the piece's running app; the lead over the note's own sound
  (which the engine hears through 4.1) the number · (f) `docs/SEAMS.md`: the message half of the sound-path row, the composer-score
  row's first entry, and the first rows of "the lines a stack file must change"; `docs/TAKE.md`.
- **4.3 the capture to a bank · 4.3b the crop (the recording trimmed to the attack, reliably — the composer's word, DEC-8) · 4.4 the
  playback from the bank · the sample index** — their first runs are the Decibel piece's 6.3 · 6.3b · 6.4 · 6.5; *each to be laid
  out when we discuss it.* Where the index sits (here, or part 11) is open.

## 5. The first sound — `todo`

***Why:*** the lineage's "first sound" step — one thing heard end to end before anything else is built.
The trigger object in the composer score (the first member of 11) and the first effect — a filter, his example — heard on a
live instrument's note, in the first piece's composer score. *To be laid out when we discuss it.*
**RE-READ by his brief for the Decibel piece, 2026-10-04 (RUNNING_LOG §4; `#6 §819`):** the first sound is a note CAPTURED at a
MIC OPENING and RETURNED beside the live note (11's first two members: the mic opening · the return); the filter — the pedals of
resonance, 6's first — comes third. Laid out in the Decibel piece's running order, steps 8 … 10.

## 6. The effects of his brief — `todo`, open-ended

***Why:*** the engine is his whole live-electronics setup, growing (LG-351).
The momentary gate that opens the mic for an instant; delay · loop + granular · freeze · Greyhole (LG-340); the saved impulses
replayed by piece #2's cells (LG-341); the mechanism of coordinating split-second input. New effects, shapes and analysis are
added here as sub-parts by compositional need. *To be laid out when we discuss it.*

## 7. The notation kinds — `todo`

***Why:*** a trigger a performer cannot read is not a notation.
The GC carrying a capture glyph · the glyph vocabulary (shape or colour × the window's length; Braxton's Language Music a
candidate, LG-343) · the collection on screen (LG-345) — each by a DEVICE SHEET; the piece's extractor emitting the trigger
events; the film and the print carrying them. 12's kinds are drawn here. *To be laid out when notating comes.*

**His staff system, 2026-10-04 (the Decibel sketch pad DEC-4; its D8):** NO electronics lane or staff — every electronic sound
derives from a player's own input and is drawn on THAT player's staff with a SIGN OF ORIGIN: a sign just before the note with its GC
(section 1) · a STACK of signs across the staves read as an electronic chord, the real notes placed after it (section 3) · a held
electronic chord of freezes as a duration-line kind on each contributing player's staff (section 2). Whether section 3's stacks show
in the parts or only in the conductor's and the presentation score: his, open. The data for 7's device sheets. For 11: an electronics
object lives on the player's lane but is routed to the electronics, not the instrument's port.

## 8. The take — `todo`

***Why:*** three pieces take one engine; the recipe must run cold.
How a piece pulls the engine: the submodule checkout inside the piece · the commit recorded · the seams applied (3) · the
batteries and THE SHIELD run in the piece · a piece's lock pins the commit. Written in `docs/TAKE.md` so a cold model runs it.
*To be laid out when we discuss it.*

**REFINED 2026-10-04 (RUNNING_LOG §4; the Decibel journal's D7):** the take is a git SUBTREE, not a submodule — the engine's code
sits in each piece as ordinary files in `electronics/`; `git subtree add` / `pull` to take, `git subtree push --prefix=electronics`
at every wrap to land here; the AI's steps, never his. Proven at the first push.

## 9. The three set-ups — `doing`

***Why:*** the pieces are where the engine is heard and used.
The new-piece protocol's runs — the Decibel piece · the Switch~ piece · the improviser piece — each a NORMAL PORT of the
scrolling-score stack, each taking the engine by 8. The protocol is `composition-system/protocol/NEW_PIECE_PROTOCOL.md`; its
record and deviations live in each piece's repo, not here. *Each run laid out there, at his word.*

- **9.1 The Decibel piece** — `doing`. `decibel_TENOR_2026` (`C:\Users\jwloy\GitHub\decibel_TENOR_2026` ·
  `github.com/elosine/decibel_TENOR_2026`, public) made 2026-10-04: the protocol's container 2 done — a normal port (copy-forward
  from piece #6 · both layers · the scrolling score), the kit in, no code yet. Next THERE: container 3, the copy-forward. The engine
  is taken there at parts 5 · 8 — its CLAUDE.md, journal D4 and PLAN § 0 say so. (`#6 §816 … §818`)

## 10. The engine's record — `todo`, continuous

***Why:*** the lab journal's rule, for the engine.
This repo's RUNNING_LOG and device sheets; what the engine teaches goes to the protocol's v2 (the home's 10.3) and to the home's
INDEX (the module manifest, 9.11 — the engine its first member). *Kept as the work happens; no laying out needed.*

## 11. The composer-score objects for the electronics — `todo`

***Why:*** the live instruments have bricks, meta shapes and curves; the electronics need their own family (LG-351).
Objects that live on a lane, interact with the MIDI, are saved in the score and read by the extractor. The trigger of 5 is the
first member; the rest by compositional need, one at a time, each through the planning method. *To be laid out when we discuss it.*

## 12. The live graphics — `todo`

***Why:*** the animations go with the sounds, and live analysis may feed the score at performance time (LG-351).
New in kind: the scrolling score has animated objects (the GC · the pie · the meter · the ball) but no RUNTIME INPUT; 12 gives
the performance score one. 7's kinds are its drawn form; a device sheet for each. *To be laid out when we discuss it.*
