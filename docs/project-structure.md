# Project Structure

> Status: draft v1, for review.

---

## The one idea that shapes the layout

**`game/assets/` is generated, not committed.**

The real source of every model, texture, and sound is Python under `art-source/`.
A `.glb` is a build artefact, like a `.o` file. This is what makes the repo tiny,
every asset diffable, and the whole game reproducible from a clone.

```
git clone  →  python -m tools.build_all  →  the entire game exists
```

---

## Layout

```
february 30th/
├── README.md
├── .gitignore
│
├── docs/                          ← you are here
│   ├── story.md                   canon, cast, endings, tone rules
│   ├── worlds.md                  five acts: layouts, mechanics, scares
│   ├── art-direction.md           how the models get made
│   ├── tech-stack.md              engine, budgets, platforms
│   ├── pipeline.md                the reproducible asset build
│   └── project-structure.md       this file
│
├── game/                          ← Godot 4 project, the shipping build
│   ├── project.godot
│   │
│   ├── assets/                    ⚠️ GENERATED — git-ignored
│   │   ├── models/                .glb
│   │   ├── textures/              .png
│   │   ├── audio/                 .ogg
│   │   └── fonts/
│   │
│   ├── src/                       ← all handwritten code lives here
│   │   ├── core/
│   │   │   ├── time/              the 29/30 clock — the spine of the game
│   │   │   ├── state/             save, inventory, flags
│   │   │   ├── input/
│   │   │   └── audio/             bus routing, the music box director
│   │   ├── world/                 act streaming, doors, transitions
│   │   ├── actors/                player, the boy, the guests, the children
│   │   ├── interaction/           verb system: look / enter / open / give
│   │   └── ui/                    HUD, subtitles, menus
│   │
│   ├── scenes/
│   │   ├── acts/
│   │   │   ├── act1_29th_street/
│   │   │   ├── act2_the_long_way/
│   │   │   ├── act3_lost_and_found/
│   │   │   ├── act4_the_after/
│   │   │   └── act5_the_30th/
│   │   ├── actors/
│   │   ├── props/
│   │   └── ui/
│   │
│   └── shaders/
│       ├── ps1_snap.gdshader      vertex snapping + affine warping
│       ├── vhs.gdshader           tracking noise, scanlines, chroma
│       ├── palette_lock.gdshader  16-colour dither
│       └── blob_shadow.gdshader
│
├── art-source/                    ← THE SOURCE OF TRUTH for assets
│   ├── blender/
│   │   ├── rig/                   shared child + adult rigs
│   │   └── src/
│   │       ├── build_child.py     the 800-tri child
│   │       ├── build_adult.py     the 400-tri party guest
│   │       ├── build_props.py
│   │       ├── build_level_shells.py
│   │       ├── wrongness.py       §4.1 of the art direction — the good bit
│   │       └── export.py          → glTF
│   ├── textures/
│   │   ├── src/                   .aseprite sources
│   │   ├── palette/               the shared 16-colour LUTs
│   │   └── build.py
│   └── audio/
│       ├── src/                   generators
│       │   ├── motif.py           the music box — 40 KB, does the most work
│       │   ├── knock.py
│       │   ├── static_voice.py
│       │   └── ambience.py
│       └── build.py
│
├── tools/
│   ├── build_all.py               one command, whole asset library
│   ├── validate_assets.py         enforces the triangle/VRAM budgets — CI
│   ├── package.py                 produce a distributable build
│   └── bootstrap.py               install Blender + Godot
│
├── prototype/                     ← Three.js look-dev, RUNS HERE NOW
│   ├── index.html
│   ├── src/
│   │   ├── main.js
│   │   ├── shaders/               port of ps1 + vhs, for look approval
│   │   └── wrongness.js           the proportion-error pass, in JS
│   └── package.json
│
└── .github/workflows/
    ├── assets.yml                 rebuild every asset, fail on budget breach
    ├── test.yml
    └── release.yml                package + upload
```

---

## Module boundaries

Four rules, so this does not become spaghetti:

1. **`src/core` never imports from `actors`, `world`, or `ui`.** It is the
   bottom of the graph. The clock, save, and input know nothing about actors.
2. **Actors never know which act they are in.** The Boy behaves identically in
   every act. Acts configure him; they do not special-case him.
3. **All time flows through `core/time`.** There is exactly one clock object in
   the game and the 29/30 confusion is a property of it, not scattered
   `Time.t` calls.
4. **`art-source` and `src` never import each other.** Assets are data. Code is
   code. The only thing that crosses the line is a filename.

---

## Why `prototype/` is in the repo

It is temporary and it is not the game. It exists for one reason:

**Godot and Blender are not installed, so the art direction is currently
unverifiable.** `prototype/` is a ~200-line Three.js harness that applies the
PS1 snap, VHS, and palette-lock shaders plus the wrongness pass to a test mesh
— in a browser I *can* run and screenshot right now.

It lets us lock the look with real screenshots **before** anyone installs a
300 MB toolchain. When the look is approved, it gets deleted and the shaders
port to `.gdshader`.

---

## Suggested build order

| # | Milestone | Depends on |
| --- | --- | --- |
| 0 | ✅ Design docs | — |
| 1 | `prototype/` look-dev harness | design approval |
| 2 | Install Blender + Godot (`tools/bootstrap.py`) | look approved |
| 3 | `art-source/blender/wrongness.py` + one child | 1, 2 |
| 4 | Validate §4.1 — is one wrong child actually unsettling? | 3 |
| 5 | `ps1_snap` + `vhs` shaders in Godot | 4 |
| 6 | Audio pipeline + the music box motif | 1 |
| 7 | Grey-box Act I with instanced Guests | 3, 4, 5 |
| 8 | Act I art pass | 7 |
| 9 | Acts II–V | 8, and everything learned |
| 10 | Package, CI, store page | 9 |

**Milestone 4 is the kill-switch.** If one 800-triangle child with a 6% arm
error is *not* unsettling, the art direction is wrong and we find out for the
cost of one mesh — not one hundred.
