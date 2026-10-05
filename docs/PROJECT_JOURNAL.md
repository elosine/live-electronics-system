# PROJECT JOURNAL — live-electronics-system (the shared live-electronics engine)

> One file. Seven sections. Everything important lives here.
> §2 is read at every session start — keep it ~40 lines; trim old sessions to one line each.
> The lab journal (`RUNNING_LOG.md`) is the raw trail underneath; this is the curated state.

---

## §1 Quick-Start

- **What this is:** ONE live-electronics engine, with its notation and graphics, for THREE pieces (the Decibel piece · the Switch~
  piece · his improvisation with live electronics). Not a piece. A module set with named seams, taken by each piece as a git submodule.
- **Lineage:** the custom-composition-system pieces #1 … #6 (`composition-system/INDEX.md`). A port of `live-electronics-engine`
  (the sandbox) into the stack of pieces #4 … #6 (the composer score · the notation engine · the Reaper rack).
- **The kind of start:** a port from a sandbox into a module set — not a piece's profile; the new-piece protocol's universal layer
  applied to the repo (its 2.2 for the name, the visibility, the push rule), its containers 3 … 8 not.
- **The stack:** none of its own — the engine runs inside a piece's apps. Code arrives with part 2.
- **The plan:** `docs/PLAN.md` — twelve parts and the rule (the parts are containers; sub-parts at need). Made in piece #6's lab
  journal, `septet_LGMF_2026/docs/RUNNING_LOG.md` §805 … §814; his words there, COMPOSITION_NOTES LG-348 … LG-351.
- **Reference repos** (read-only): the sandbox `live-electronics-engine` · the pieces by `composition-system/INDEX.md` · piece #2's
  cells. Consult per named question only.

### Where the record of the start lives

- `#6 §805 … §814` (the pre-conversation, the twelve parts, part 1's build) · this repo's RUNNING_LOG §1.

---

## §2 Resume Here

**FIRST — HIS STANDING RULE (2026-09-11):** after `/clear` + `/postclear`:
play back, then **STOP and ask**. No edits, no builds, no tool calls beyond the resume
reads. Start only on his word. *(At `/session-start`: orient, agree the agenda, then work.)*

### THE REPO OPENS ON THIS (2026-10-03, Fable) — PART 1 DONE; the next part is HIS to name

- **UPDATE 6 · 2026-10-04 (RUNNING_LOG §11, Opus) — 4.2 BUILT: THE MESSAGE ROUTE**, in the Decibel piece (its 6.2). A piece's score
  page → its score server (`POST /api/elec`) → OSC over UDP → the engine's LANGUAGE on **UDP 57211** (pinned; the server stays 57210) —
  the same road in concert and in simulation (the piece's D10). New here: `sc/boot.scd` the ear (`openEar` · `hear`) and the onset
  probe (`onsetOn`) · `sc/session.scd` shows `/le/onset` and times the player's sound against it · `tools/osc.js` · `tools/relay.js` ·
  `score/le_msg.js` (the first file of the composer-score seam). A message is `/le/<kind>` + NAME, VALUE pairs. `selftest.scd` passes
  with two new cases (D · E). `docs/SEAMS.md` lists the five lines a piece's stack changes. **PROVEN to the edge of Web MIDI; NOT
  MEASURED: the score's lead over its own sound (the composer's Chrome).** **► NEXT: 4.3 the capture to a bank and 4.3b the crop —
  a talk first, in the Decibel piece (its 6.3 · 6.3b).**
- **UPDATE 5 · 2026-10-04 (RUNNING_LOG §8, Opus) — 4.1 DONE: THE CROSSING PROVEN** in the Decibel piece (ReaRoute installed, Reaper on
  ASIO): unity through the engine; the round trip two DAW blocks (23.22 ms at 512); ReaRoute's channels sit at hardware index 512 …
  527 in Reaper (`docs/SEAMS.md` has the three facts a piece's job needs). **HEARD by him the same day (RUNNING_LOG §10)**; the runner's fault that killed his engine found and fixed (§9). **► NEXT: 4.2, the message
  — a talk first, in the Decibel piece (its 6.2; its RUNNING_LOG §56 has the notes toward it).**
- **UPDATE 4 · 2026-10-04 (RUNNING_LOG §7, Opus) — THE SEAT MADE, 4.1 BUILT, THE CROSSING UNPROVEN.** **Where you are reading this:**
  if the path is `…/decibel_TENOR_2026/electronics/docs/`, you are in the place of work — edit HERE; if it is the stand-alone clone,
  it is a MIRROR (`docs/TAKE.md`: pull before reading, never edit while a piece is at work). The code: `sc/` (boot · synths ·
  selftest · check_route · latency · session · devices) and `tools/sc.js`; the server on UDP 57210. `selftest.scd` passes — the
  pass-through sample-exact, the safety under full scale, the latency probe to the sample. **ReaRoute is NOT on his machine and his
  Reaper is on WASAPI** — two hand steps of his; until then the `\sim` boot refuses (exit 2) and 4.1 (e) is open. The master is the
  sandbox's BROWSER chain translated (high-pass and glue OFF until he has heard them). **► NEXT: when ReaRoute is there, the Decibel
  piece runs `node tools/elec.js probe → route → check → latency`; a fault in the crossing is fixed here. Then 4.2, the message
  (a talk first: a loopMIDI port or OSC).**

- **UPDATE 3 · 2026-10-04 (RUNNING_LOG §5 · §6) — Q1 ANSWERED; PART 4 IN HAND.** The sandbox read: SuperCollider 3.14.1 (offline
  renders) + a Web Audio layer (labs); NO live-input path anywhere; his pedals of resonance is an SC SynthDef on `SoundIn`. His word:
  the sound process is SC REAL-TIME, fed by a piece's Reaper over ReaRoute; SC's master IS the output live; in simulation the DAW is only
  the players and ONE FLAT RETURN TRACK. Part 4 `doing`, **4.1 the audio route laid out** (PLAN.md); parts 2 · 3 each carry one line.
  The first run is the Decibel piece's running order 6.1 … 6.6 (its PLAN.md 1.1) — the build is THERE, on Opus; the code comes here by
  `git subtree push` once `electronics/` exists. The pedals and the recent engine's processing: his phase 2.

- **UPDATE 2 · 2026-10-04 (RUNNING_LOG §4; `#6 §819`) — THE SEAT REFINED at his word: a git SUBTREE at `electronics/` inside each
  piece, not a submodule — he never touches it; the AI pushes at every wrap. Part 5 re-read: the first sound is a note CAPTURED and
  RETURNED; the filter third. Part 11's first two members named (the mic opening · the return). The Decibel piece's running order
  (its journal §2, steps 6 … 10) is where the engine's first code will be built. Q2 answered in principle.
- **UPDATE 2026-10-04 (RUNNING_LOG §3; `#6 §816 … §818`) — 9.1: THE DECIBEL PIECE'S REPO EXISTS,** `decibel_TENOR_2026` (public;
  the protocol's container 2 done — the kit only, no code). Next THERE: container 3, the copy-forward. Here nothing is in hand:
  the first take needs that copy-forward and parts 3 · 4 laid out.
- **UPDATE 2026-10-03 (`#6 §815`) — HIS PICK: PART 9's FIRST RUN**, the Decibel piece's repo by the new-piece protocol, begun in a
  new session from piece #6's checkpoint #5 (`septet_LGMF_2026/docs/PROJECT_JOURNAL.md` §2, the block CHECKPOINT #5 AFTER THE CLOSE).
  That run's record lives in the Decibel piece's repo. Here nothing is in hand until the first take (parts 3 · 4 · 5 · 8).
  The route's structural shape he was given (not an order): the Decibel repo · one read of the sandbox · parts 3 and 4 laid out ·
  part 5 the first sound, where part 8's recipe is written and proven · then parts 6 and 11 by need, 7 and 12 when notating comes.

- **The task:** the shared live-electronics engine — `docs/PLAN.md`, twelve parts.
- **Where it stands · the deliverable:** part 1 done — this repo, public, pushing after every commit; the kit in; the plan
  written. Parts 2 … 12 top line only. No code.
- **► THE NEXT CONCRETE STEP:** the part HE names (the order and the timing are his, `#6 §806`); lay it out under the planning
  method — the goal ("N. Title. Result when done: …"), his word, the sub-steps into PLAN at once. Structurally first: 9's first
  run (the Decibel piece's repo by the protocol — in ITS repo, not here) before 5; 3 and 4 before 5. Before part 4 is put to him:
  read `live-electronics-engine`'s CLAUDE.md — what it is built on decides the sound seam's shape.
- **`Resume reads:`** `docs/PLAN.md` (whole — it is short) · for part 9, `composition-system/protocol/NEW_PIECE_PROTOCOL.md`
  § 2 · for part 2 or 4, the sandbox's CLAUDE.md. Nothing else beyond §2.
- **Pending him:** which part first · the planning repo's lists (a line for this repo; a line for the Decibel piece) — at his word only.
- **Deliberately uncommitted — none.** Nothing of the pieces touched.

### THE SESSIONS BEFORE THIS ONE — one line each; the lab journal has them whole

- *(none — the repo opened 2026-10-03; the talk that made it is piece #6's §805 … §814)*

**NEXT STEPS · MODEL · CLEAR** *(the running thread — THE RHYTHM, CLAUDE.md. Keep current.)*

| # | Step | Model | Clear first? |
|---|---|---|---|
| **►** | **4.2 — the message: a talk** (a loopMIDI port read by `MIDIIn`, or OSC through the piece's score server to UDP 57210), in the Decibel piece at its 6.2. 4.1 is done (RUNNING_LOG §8) | Fable (the talk) · Opus (the build) | — |
| — | 4.3 the capture → 4.4 the playback → the sample index — as the Decibel piece reaches 6.3 … 6.5 | Fable (each talk) · Opus (the builds) | — |
| 9.1 | part 9's first run — the Decibel piece: its repo `decibel_TENOR_2026` MADE 2026-10-04 (container 2). Next there: container 3, the copy-forward (in ITS repo and chat) | Opus | — |

**Open questions:** Q1 — ANSWERED 2026-10-04 (RUNNING_LOG §5): SuperCollider + a Web Audio lab layer, no live-input path; the seam = SC real-time fed over ReaRoute. **Q3 — where the SAMPLE INDEX sits in the twelve parts** (part 4, part 11, or its own). **Q4 — the message route: a loopMIDI port or OSC** (decided at the Decibel piece's 6.2). Q2 — whether the pieces take the
engine as a git submodule exactly, or by a copy at a tag with the commit recorded (`#6 §807` chose the submodule; proven at part 8).

**Blockers:** none.

**Standing warnings for this repo:** PUBLIC — nothing personal · never edit the sandbox or the pieces · the engine never binds a
piece's loopMIDI ports · verify in a piece on its throwaway server, never his port.

**Checks this repo owns:** `node tools/sc.js run sc/selftest.scd` — the engine's three tests, no hardware, no sound (exit 0).

---

## §3 Principles

*(Lessons never to repeat. Numbered, append-only. **1–23 are inherited** — one line each here; the full text,
dates and lab-journal sections are in `septet_2026/docs/PROJECT_JOURNAL.md` §3 (1–18) and
`septet_LGMF_2026/docs/PROJECT_JOURNAL.md` §3 (19–23). Most bite only once the code is here.
Verified in this repo only when they bite.)*

1. Check Reaper input monitoring before blaming the instrument (#3 P1).
2. When a working reference exists, diff the files; don't iterate guesses (#3 P2).
3. The IR schema is a gate on the file — a new overlay kind enters the schema in the same
   commit or the page is rejected and deleted. Snapshot first (#4).
4. Never `git add -A` — stage explicit paths (#4 D30).
5. Only delete IDs you created in the same breath (#4).
6. MIDI thru must never listen to the loopMIDI output ports (#4).
7. Schedule playback with a ~150 ms lead (#4).
8. Object ids are per save — never delete or replace by id alone (#5).
9. Verify against the composer's running server; never hold his port, never save from the
   AI's pane; a hidden pane never fires `requestAnimationFrame` (#5).
10. When downstream meters freeze at identical values, dump mute / solo / routing first (#5).
11. Learn a plugin's vocabulary by diffing the GUI's change, not by guessing from strings (#5).
12. Measure the layer that reaches the INSTRUMENT, not the layer you built. Print the MIDI (#5).
13. Never queue what cannot be un-queued; Chrome does not implement `MIDIOutput.clear()` (#5).
14. Where a note is started by one piece of routing, it is stopped by the same one (#5).
15. Write the assertion after the number, never before it (#5).
16. Build on a `zz-ai-` copy from the FIRST command, not the second (#5).
17. The notehead's left edge is the moment; the go line marks displacement (#5 D49).
18. A checker that tests one half of a rule is worse than no checker. When a rule names two
    classes, the gate tests both or says in writing which it does not (#5).
19. A copy-forward carries the standing RULES whole, not only the code — check the new CLAUDE.md
    against the source's, heading by heading (#6).
20. Prove the copy whole BEFORE changing it — commit the byte-exact copy, run everything against it,
    then patch; after that every red has one possible cause (#6).
21a. The file, the app's intent and the rack's layout are each necessary; only the RECORDING of the
    rack is the proof. When he says it sounds wrong and the text says it is right, record the rack (#6).
21b. `cmp` proves a file was copied; it cannot prove the LIST was right. Run what you copied (#6).
22. A rule that names a part by ID must be checked against the parts that EXIST — when a palette
    changes, grep the registries for the old instrument names, not just the code (#6).
23. When a measurement and an assertion disagree, find out which is wrong before editing either (#6).

*This repo's own:*

24. **Additive or it is a patch.** A shared module that must rewrite its host's files is not shared — it is three divergent copies
    waiting to happen. Every line a host file must change is listed in `docs/SEAMS.md` (`#6 §806`).

---

## §4 Decisions

*(Append-only: ID, date, decision, why, what was rejected.)*

- **D1 · 2026-10-03 — The engine is a repo of its own**, not a module inside the first piece. Why: three pieces live at once and the
  engine grows during the first; one source, one history, one tag. Rejected: inside the first piece, copy-forwarded to the others
  (divergence) · the whole stack moved into one shared repo (more than a modest enhancement; his to reopen). *(`#6 §806 · §808`)*
- **D2 · 2026-10-03 — The engine's files live ONCE on disk, inside every piece** (a git submodule): built in the first piece where he
  hears it, landing here as built; each piece pulls at its own moment and records the commit; a piece's lock pins it. Rejected: a
  copy back by hand (the step that gets skipped) · a Windows junction (nothing of the engine in the piece's git; one deleted its
  target before). *(`#6 §807`)*
- **D3 · 2026-10-03 — ADDITIVE.** New files, registry rows, one hook line each; the seams listed; the piece's save the ground truth, the
  engine the generic machinery. *(`#6 §806`)*
- **D4 · 2026-10-03 — The plan's rule:** the parts are containers with stable numbers; sub-parts at compositional need; nothing detailed
  before it is needed; the order and the timing his. *(`#6 §811 · §812`)*
- **D5 · 2026-10-03 — `live-electronics-system`, PUBLIC, push after every commit** — his three words. *(`#6 §813`)*
- **D6 · 2026-10-03 — Not carried into an engine's kit:** the sketch pad (a musical idea about the electronics is an LG note in the
  piece that has it) · the performance notes · the sweep list · the deviations register · the morph notes. His to reverse. *(§1)*

---

## §5 Playbooks

*(Mode-specific procedures and gotchas. Piece #6's §5 holds the stack's playbooks; bring one across when its system lands here.)*

---

## §6 Done

- 2026-10-03 — **1** the engine repo made, the kit in, the plan written (`#6 §814` · RUNNING_LOG §1).

---

## §7 Human Notes

*(The composer's own to-dos and reminders. Reviewed at session end.)*

- *(none yet)*
