# The Asset Pipeline

> Status: draft v1, for review.

---

## The rule

**`game/assets/` is a build output. It is git-ignored.**

The source of every model, texture, and sound is Python under `art-source/`.
A `.glb` is to this project what a `.o` file is to a C project.

```bash
git clone https://github.com/lohitaksha06/february-30th
cd february-30th
python -m tools.bootstrap      # install Blender + Godot (free)
python -m tools.build_all      # every model, texture, and sound in the game
```

Nothing is hand-committed. Nothing can be lost. Everything is diffable.

---

## Why this matters

| Benefit | Detail |
| --- | --- |
| **The repo stays small** | A few MB of `.py` instead of a few hundred MB of binaries |
| **Every change is reviewable** | "The Guests' arms got longer" is a readable commit in `wrongness.py`, not an opaque 40 MB `.blend` |
| **Budgets are enforceable** | `validate_assets.py` runs in CI. A 900-triangle child fails the build, automatically, forever |
| **Reproducible** | CI rebuilds from scratch and proves the game is intact |
| **No asset drift** | A binary that "somebody tweaked in Blender at 2am" cannot exist, because the `.blend` is not the source |

---

## Stage 1 — Models

```bash
blender --background --python art-source/blender/src/build_all.py
```

| Script | Produces | Budget |
| --- | --- | --- |
| `build_child.py` | the 800-tri child mesh + shared rig | 800 tri |
| `build_adult.py` | the 400-tri Party Guest | 400 tri |
| `build_props.py` | cake, cupboard, chairs, coats, cars | ≤ 600 tri |
| `build_level_shells.py` | room shells, one per act | ≤ 3,000 tri/room |
| `wrongness.py` | the seeded proportion errors | 0 extra tri |
| `export.py` | glTF 2.0 → `game/assets/models/` | — |

**All headless. No Blender GUI required.** The whole 3D library is built by CI on
every push.

### `wrongness.py` in one paragraph

Every character mesh is generated from one base, then given **one or two
dimensions that are 3–8% wrong**, seeded per character so each one is
*consistently, repeatably* wrong. It is the highest value-per-triangle technique
in the game and it costs zero polygons. See `art-direction.md` §4.1.

---

## Stage 2 — Textures

```bash
python art-source/textures/build.py
```

| Output | Size | Count |
| --- | --- | --- |
| Faces | 64×64 | 6 (one per doppelgänger variant) |
| Characters | 128×128 | ~20 |
| Props | 128×128 | ~80 |
| Hero props | 256×256 | ~12 |
| Blob shadows | 128×128 | 1 |

**All 16-colour, palette-locked, dithered.** No PBR maps, ever. Total target
under 24 MB of VRAM.

Sources are `.aseprite` files (hand-painted) plus Python generators for
everything repetitive — the calendar pages, the coat name tags, the dither
patterns.

---

## Stage 3 — Audio

```bash
python art-source/audio/build.py
```

**Almost everything is synthesised, not sampled.** This keeps the payload under
8 MB and, more importantly, keeps the horror in *our* hands rather than in a
licence.

| Cue | Method | Size |
| --- | --- | --- |
| **The music box motif** | celesta, 24 notes, 1 semitone flat, −2% tempo/loop | ~40 KB |
| The knock | filtered noise → 1.5 s hallway convolution, −12 semitones | ~60 KB |
| Static voices | ring-modulated noise + 40 Hz LFO + granular stutter | ~30 KB |
| Ambience | real room tone, one band removed | ~2 MB |
| Foley | synthesised cloth, paper, wood | ~1 MB |

**No text-to-speech anywhere in this game.** All voices are corrupted noise
design. See `art-direction.md` §10.

---

## Stage 4 — Validate

```bash
python tools/validate_assets.py
```

Hard-fails on:

- any mesh over its triangle budget
- any texture over its size budget
- any asset with no matching entry in the palette
- any `.png` over 256×256
- total VRAM over 32 MB
- total install payload over 80 MB

**This runs in CI on every push.** The budgets are not a guideline; a breach
breaks the build.

---

## Stage 5 — Package

```bash
python tools/package.py --target windows
```

Produces a distributable. Target: **under 50 MB**, no engine runtime, no
install step — the player downloads one folder and double-clicks it.

---

## CI

`.github/workflows/assets.yml` on every push:

1. install Blender + Godot (cached)
2. `build_all` — regenerate every asset from source
3. `validate_assets` — **fail the build on any budget breach**
4. run the unit tests
5. upload the asset bundle as a build artefact

A pull request that quietly doubles the triangle count does not merge. That is
the entire point of generating assets instead of committing them.
