# NITS — deferred small stuff

> Things worth fixing that are **not** blocking the work (`AI_METHODOLOGY.md` rule 1: fix
> what blocks the work or what will break; record the rest here). One bullet each: what it
> is, what was observed, why it is deferred. Enough context to act on cold. Delete when
> fixed. **Never ask the composer to triage this file.**

## From the start of this repo (2026-10-03, RUNNING_LOG §1)

- *(none yet)*

## HELD FOR THE POSTMORTEM

*(Offers he held — not to be raised again until then.)*

- *(none yet)*

## The performers (2026-10-06, RUNNING_LOG §49 · §50 — first built in the Decibel piece)

- **THE `mic` EAR NEEDS AN ATTACK DETECTOR before a concert.** `\leOnset` reports a rise out of silence (above −60 dB) and holds 250 ms; over a ringing instrument a new attack is not a rise out of silence and is not reported — a performer on `ear: mic` would hear the first note of a phrase and little after. What is wanted: a fast envelope against a slow one on each player's bus (an attack = the fast one over the slow by a ratio, above a floor), a short hold, its own reply (`/le/attack`), started beside the probe; proven offline on a file with an attack over a tail; its threshold a venue number (the sound check). Until then `ear: sim` is the only road that is proven.
- **`perfRun` and `perfSound` have never run on a server** (the first piece's engine was up through the build; only parsed). The clock's 10 ms step and 30 ms hand-over are first guesses: a machine under load may want a longer hand-over.
- **A performer hears a simulated note about 100 ms before it sounds** (the score's look-ahead) and a microphone's about a block after — the two ears differ by that much in what "just after" can be; the rules are written so neither needs the future (an answer is at least 60 ms after its onset).
- **No performer brick is made by a key**, and the panel has no "hear one sound" button.
- **The palette travels whole in every container's message** (a string of names): fine at 18; a palette of hundreds wants its own message, sent once.
