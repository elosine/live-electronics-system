# PROJECT PLANNER — live-electronics-system

> **What this is:** the working view of the ENGINE as an outline — the twelve parts of `docs/PLAN.md`, what each holds, the
> one in hand. Rewritten freely; the lab journal is the append-only record.

**NOW ►** 2026-10-05 — **THE PLAN BUILT (parts 6.2 · 11.2 b; RUNNING_LOG §35)** — in the Decibel piece: a return brick's variants (`elec.variants`), the score's plan to the engine (`/le/plan`), a sample's variants rendered right after its capture, the soonest-needed first, a fallback when one is late; proven headless and under a stub window, NOT heard. *(Before it:)* **THE PROCESSING BUILT (parts 2 · 6.1 · 11.3; RUNNING_LOG §26)** — in the Decibel piece: the sandbox's chain ported (`sc/process.scd`), rendered OFFLINE from a banked sample into a new one (`/le/process`; ended by a `shape` or a `tail`), and a third object, the process brick (`score/le_process.js`); proven headless (`sc/process_test.scd`). NOT CLAIMED: his ear; a render through a living engine. NEXT: the granular voices and the pedals of resonance, by the piece's need. *(Before it:)* 2026-10-04 — **PART 4: 4.1 THE AUDIO ROUTE DONE** (RUNNING_LOG §8) — proven in the Decibel piece: unity, two DAW blocks of latency. ► NEXT: 4.2 the message (a talk: a loopMIDI port or OSC), as that piece reaches its 6.2. *(Before it:)* **PART 4, THE SOUND PATH: 4.1 BUILT, THE CROSSING UNPROVEN** (RUNNING_LOG §5 … §7) — the engine is SuperCollider real-time (`sc/` · `tools/sc.js`), seated in the Decibel piece at `electronics/`; its self-test passes. ReaRoute is not on his machine and his Reaper is on WASAPI — his two hand steps; then the Decibel piece's `node tools/elec.js probe → route → check → latency` closes 4.1 (e). After it: 4.2 the message. *(Before it:)* 2026-10-03 — **► HIS PICK 2026-10-03 (`#6 §815`): PART 9's FIRST RUN — the Decibel piece's repo, by the new-piece protocol, begun in a new session from piece #6's checkpoint #5 (its record lives in THAT piece's repo, not here). HERE: nothing in hand until the first take — parts 3 the seams · 4 the sound path · 5 the first sound · 8 the take, each laid out when he reaches it; before part 4 is put to him, read the sandbox `live-electronics-engine`'s CLAUDE.md.** *(Before it:)* **► PART 1 DONE (Fable, `#6 §814`): the repo made, public, pushing after every commit; the kit in; the plan
written (twelve parts; part 1 laid out, 2 … 12 top line only). NEXT: the part he names — the order his. Structurally: 9's first
run (the Decibel piece's repo, by the protocol) before 5 the first sound; 3 and 4 before 5. Journal §2's first block is the
cold-start block.**

---

## The engine, as an outline

- **The repo** (1) — done.
- **The contents** — 2 the port from the sandbox · 6 the effects (open-ended) · 11 the composer-score objects · 12 the live graphics.
- **The plumbing** — 3 the seams · 4 the sound path · 8 the take.
- **The proofs** — 5 the first sound.
- **The score** — 7 the notation kinds.
- **The pieces** — 9 the three set-ups (by the protocol, in their own repos).
- **The record** — 10, continuous.

---

## Open, his

- Which part first. (The order and the timing are his — `#6 §806`.)
- What `live-electronics-engine` is built on — read before part 4's design is put to him (`#6 §806`, "not read").
