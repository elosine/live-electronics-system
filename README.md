# live-electronics-system

The shared live-electronics engine of the composer's custom-composition-system lineage: ONE engine, with its notation and
graphics, built once and dropped into three pieces — the Decibel piece · the Switch~ piece · his improvisation with live
electronics. Not a piece. A module set with named seams, seated in each piece as a git subtree at `electronics/` (`docs/TAKE.md`).

It is a port of the experimental work in `live-electronics-engine` (the sandbox) into the stack the pieces share
(the composer score · the notation engine · the Reaper rack). Planned 2026-10-03 in piece #6's lab journal
(`septet_LGMF_2026/docs/RUNNING_LOG.md` §805 … §814).

Orientation for any AI session: `CLAUDE.md`, then `docs/PROJECT_JOURNAL.md` §2.

| | |
|---|---|
| `docs/PLAN.md` | the living plan — twelve parts, stable IDs, the rule in its header |
| `docs/PLANNER.md` | the NOW ► line |
| `docs/PROJECT_JOURNAL.md` | session state, decisions, principles |
| `docs/RUNNING_LOG.md` | the lab journal — append-only, written as the work happens |
| `docs/SEAMS.md` · `docs/TAKE.md` | where the engine plugs into a piece · how a piece takes it |
| `docs/AI_METHODOLOGY.md` | how the AI is to work here (governing) |
| `docs/NITS.md` | deferred small things |

**The code** (from 2026-10-04 — part 4, the sound path):

| | |
|---|---|
| `sc/boot.scd` · `synths.scd` | the SuperCollider engine: the namespace, the server (UDP 57210), the buses, the basic machinery |
| `sc/selftest.scd` | its own test — no hardware, no sound: `node tools/sc.js run sc/selftest.scd` |
| `sc/check_route.scd` · `latency.scd` · `session.scd` · `devices.scd` | the route's proof · the round trip · the engine up and listening · what it can open |
| `tools/sc.js` | finds sclang, runs a file headless, reads the line protocol |

What the pieces share lives in `composition-system` — its `INDEX.md` first.
