# FEBRUARY 30th

A first-person sad-horror game about the day after your birthday.

You are eleven years old. Tonight is **February 29th** — the rarest birthday there
is. Your mother has never got it right before. This year she finally did.

At 00:00 you wake to knocking from your bedroom cupboard.

There is a child in there. They have your face, your hair, the tooth you lost in
January. They are wearing clothes that are almost yours, but wrong: a party hat two
sizes too small, a shirt buttoned inside-out, a jacket with the sleeves cut at
two different lengths.

They say tonight is their birthday. They say it is the **30th**.

There is no 30th of February. There is no 30th of anything.

Your mother unlocks the door downstairs. You have about four seconds, and the only
option available to you is to push them further in to hide them.

You fall in together.

---

## The pitch in one line

> **You spend the whole game walking toward someone you have just lost, knowing
> the only thing you can give them will kill them. You rescue them anyway. They
> die. You go home.**

---

## What kind of game this is

**Sad horror, with something chasing you.** Every monster in this game is a
disappointed child. Nothing can be killed — the only verbs are **run, hide, and
be kind**, and being kind is the most expensive one.

- **Choose** boy or girl at the start. The child in the cupboard has *your* face.
- **A twelve-minute prologue** with no enemies in it. A small house, a cake with
  eleven candles, and a wardrobe door that does not sit flush.
- **Ghouls hunt you by sound.** Running is loud. Walking is quiet. Closed doors
  are free.
- **Your companion is taken from you in Act II**, and it is your fault — you were
  running from a ghoul. That turns the game from a descent into a rescue.
- **One ending.** They die. You escape.

Runs on **anything** — target hardware is a 2017 integrated graphics card, and
**an Adreno 610 phone**. Under 50 MB.

**Two storefronts, one build:** free on **itch.io**, and your own app on **Google
Play**. Both ship together, because designing the touch controls in from the start
is free and bolting them onto a finished game is a rewrite.

---

## Contents

| Doc | What it covers |
| --- | --- |
| [`docs/scope.md`](docs/scope.md) | **Read this one first.** What we cut, why, and what to build in order |
| [`docs/plot.md`](docs/plot.md) | **The plot.** Why Feb 30th exists, Wren, your mother, the death |
| [`docs/prologue.md`](docs/prologue.md) | **The opening twelve minutes**, beat by beat |
| [`docs/story.md`](docs/story.md) | Canon rules, cast, continuity bible, tone rules |
| [`docs/worlds.md`](docs/worlds.md) | Five acts — layouts, chase mechanics, scares |
| [`docs/art-direction.md`](docs/art-direction.md) | **How the models get made.** Pipeline, budgets, the tricks |
| [`docs/tech-stack.md`](docs/tech-stack.md) | Engine, perf budgets, **§8 the mobile input map** |
| [`docs/distribution.md`](docs/distribution.md) | **Where this gets published** — itch.io **and** Google Play, one build |
| [`docs/pipeline.md`](docs/pipeline.md) | Reproducible asset build — `game/assets` is generated, not committed |
| [`docs/project-structure.md`](docs/project-structure.md) | Folder layout and module boundaries |

---

## Scope — the short version

The full design is **five acts and 4–6 hours, which is 38–56 weeks of work for
two beginners.** The shipped game should be:

| | |
| --- | --- |
| **Length** | **45–60 minutes** |
| **Levels** | 3 — the house, the 30th, the kitchen |
| **Acts** | 2 — the fall, and the party |
| **New systems** | 4 — dialogue, chase, "is this my birthday", the death |
| **Geometry** | ~6,000 triangles |

The five acts are not deleted — they are in `docs/` and become the next game.
**Build the prologue first.** Twelve minutes, four rooms, no enemies. Finishing
that one thing proves the project works.

Full reasoning: [`docs/scope.md`](docs/scope.md)

## Status

**Part 1 playable.** Open `game/project.godot` in Godot 4.7 and press F5 —
bedroom wake-up → wardrobe → Wren → fall → title. See
[`docs/part1-playtest.md`](docs/part1-playtest.md) for the run and itch.io export.

## Licence

TBD. All original work — every asset is generated from Python, so there is no
third-party licensing to untangle.