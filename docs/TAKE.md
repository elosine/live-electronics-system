# TAKE — how a piece takes the engine

> **The seat is a git SUBTREE at `electronics/`** (RUNNING_LOG §4; the Decibel piece's D7) — it replaced the submodule of `#6 §807`.
> Step 1 was written and proven at its first use, 2026-10-04 (RUNNING_LOG §7). Steps 2 … 5 are filled as their parts are built.
>
> **What the seat means:** the engine lives in each piece as ORDINARY FILES in `electronics/` — a clone of the piece is whole, a
> session commits as always. It arrives WHOLE: its plan, journal and kit beside its code, because a push can only fast-forward
> this repo's `main` if the piece's folder contains it. **While a piece is the place of work, the engine's docs are edited in that
> piece's `electronics/docs/`.** The stand-alone clone of this repo is a mirror.

## The recipe

1. **The seat — PROVEN 2026-10-04 in `decibel_TENOR_2026`.** In the piece, on a clean tree:
   ```
   git remote add engine https://github.com/elosine/live-electronics-system.git
   git subtree add --prefix=electronics engine main -m "<message>"
   ```
   No `--squash`: the engine's commits become ancestors in the piece, and a push needs no bookkeeping.
   **At every wrap of a piece's session — the AI's step, never his:**
   ```
   git subtree push --prefix=electronics engine main
   git -C <the stand-alone clone> pull --ff-only
   ```
   A wrap that misses it costs nothing — the next carries everything.
   **Before a push, if `main` has moved** (another piece pushed, or a session edited the mirror):
   ```
   git subtree pull --prefix=electronics engine main -m "<message>"
   ```
   **Never** a force-push and never a history rewrite; if a push is refused, pull first.
2. **The seams applied** — `docs/SEAMS.md`'s list for this stack, once. *The audio half is written there (4.1): one send per
   player, one flat return track, three files of the piece's own.* **The message half is written there too (4.2): a `message` block in the piece's route table ·
   three lines in its score server · one tag and one hook line in its composer page — each written out, with where it goes.
   Restart a score server that was running before its three lines existed.** *The rest as parts 3 · 7 are built.*
3. ‹the batteries and THE SHIELD run in the piece — before and after›
4. ‹the commit recorded — where in the piece it is written, and in the piece's journal›
5. ‹at the piece's lock — what the archive's README says›

## The takes made

- **`decibel_TENOR_2026`** — seated 2026-10-04 at this repo's `467dc7e` (its commit `f535210`); the first code built there.
  **First push 2026-10-04: `467dc7e..3ce152c`, a fast-forward; the mirror pulled clean.**
