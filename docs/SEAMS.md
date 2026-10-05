# SEAMS — where the engine plugs into a piece's stack

> **Filled as each seam is made** (`docs/PLAN.md` parts 3 · 4 · 7). The sound path's audio half was written at 4.1, 2026-10-04.
>
> **The rule (CLAUDE.md, `#6 §806`):** the engine's code is ADDITIVE — new files, registry rows, one hook line each. **Every line a
> stack file must change is listed HERE**, so a piece applies the list once at the take (`docs/TAKE.md`). A change not on this
> list is a fault.

## The three seams

| Seam | What the engine adds | What the piece's stack must provide | Where it was proven |
|---|---|---|---|
| **The composer score** | a mixin file per object family (part 11) | one `<script>` tag in `composer.html`; the hook the mixin attaches to | ‹part 3› |
| **The sound path** | the engine itself — SuperCollider, real-time: `sc/` · `tools/sc.js` (part 4) | **audio:** one send per player to an engine input; ONE FLAT RETURN TRACK — below · **message:** ‹4.2› | the engine's half: `selftest.scd`, 2026-10-04 · the crossing: ‹the Decibel piece's 6.1, when ReaRoute is on the machine› |
| **The notation** | a rules row + a drawn or animated kind + its edge class per glyph (parts 7 · 12) | `notation/registry/rules.json` · `page_rules.json` · the render's kind table · the extractor's event emit | ‹part 7› |

## The sound path — the audio half (4.1)

**The shape.** The engine is ONE SuperCollider server (UDP 57210). The simulation and the concert differ in one place, the device:

| | the players reach the engine by | the engine reaches the room by |
|---|---|---|
| **live** (`\live`) | microphones → the interface → the engine's hardware inputs | the engine's master → the interface → the PA. No DAW. |
| **simulated** (`\sim`) | the piece's sampled players in its Reaper rack → ReaRoute → the same inputs | the engine's master → ReaRoute → ONE FLAT TRACK in the rack |

**What the machine must have (once per machine, his hand):** ReaRoute — an option of Reaper's installer ("ReaRoute ASIO driver") — and
Reaper's audio system on ASIO. `node electronics/tools/sc.js devices` says whether SuperCollider sees it.

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
| `… sc.js run electronics/sc/session.scd LE_PLAYERS=name:0,…` | the engine up and listening |

The line protocol every script speaks is at the top of `tools/sc.js`; the namespace and its one trap at the top of `sc/boot.scd`.

## The lines a stack file must change, per piece

*(none yet — the audio half changes no stack file. The message route (4.2) and the composer score's hook (part 3) will add the
first; one table per stack file, each line with the commit that proved it.)*
