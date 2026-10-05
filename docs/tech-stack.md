# Tech Stack

> Status: draft v1, for review.

---

## 1. The decision

**Godot 4.4 — 3D, GDScript, shipped as a native desktop build.**

| Criterion | Weight | Why Godot wins |
| --- | --- | --- |
| Build size | Critical | ~50–70 MB. The entire perf strategy assumes a small install |
| Runs on anything | Critical | 2017 integrated graphics is our floor, and it is trivial there |
| No runtime install | Critical | Player downloads one file and double-clicks it. No engine runtime, no launcher, no sign-up |
| Cost | Critical | MIT licence. **Zero royalties, ever** — non-negotiable for a game that earns on sales |
| Stylised low-poly 3D | High | Excellent at exactly what we are doing. Custom spatial shaders are first-class |
| Asset import | High | Native `.glb`, animation retargeting, built-in particle and audio systems |
| Post-processing | High | The PS1/VHS chain is a handful of spatial + canvas shaders |
| Iteration speed | Medium | Good. Not Unity-good, but adequate |
| Console port (later) | Optional | Godot is much harder here than Unity. Explicitly *not* a Day 1 target |

### Why not Unity

It would work. It is the industry default. But it is the wrong call for a game
whose entire premise is *small and fast*: builds are 200 MB+, licensing is
annoying, and the first-run editor install is a real barrier for a game that
people will find through a free itch.io page.

### Why not a web build

Tempting, because it is zero-install and it is what I could build and verify
fastest. Rejected for the shipping game:

- A browser tab cannot go fullscreen without a user gesture, cannot own the
  filesystem, and puts a URL bar at the top of a game about a boy in a cupboard
- 3D horror in a browser is a perf fight we do not need to have when our target
  hardware is a 2017 iGPU
- 30 fps with the render thread fighting the compositor is not the register we
  want

**However** — see §5. The web is used, just not as the product.

---

## 2. Renderer choice

**Two renderers, one project, switchable.**

| Build | Renderer | Target |
| --- | --- | --- |
| Default | **GL Compatibility** | 2017 iGPUs, Intel integrated, old laptops, Steam Deck |
| Optional | **Forward+** | Discrete GPUs, extra light/shadow headroom |

GL Compatibility is the default because it is the widest-hardware option and our
art direction needs almost none of Forward+'s features. The shader chain is
written to compile on both.

---

## 3. Language

**GDScript**, not C#.

- It is the path of least resistance for everything above: scene loading, the
  interaction verb system, the act/level state machine
- No .NET runtime dependency in the shipped build
- The performance-sensitive code is in shaders, not script, so we lose nothing
- C# remains available if a subsystem genuinely needs it

---

## 4. "I don't want it to be heavy"

This is the requirement that decides the whole project, so it gets its own
section. **Five different things get called "heavy," and each has its own
answer.**

### 4.1 Download size

| | |
| --- | --- |
| Target | **< 50 MB** zipped |
| Hard cap | 80 MB |
| Why | 800-tri character · 16-colour 128px textures · 320×180 internal render · synthesised OGG audio |

A Unity game with the same art direction would be 200–400 MB, with no way to
reduce it. Godot gives us 50 MB and zero runtime.

### 4.2 Runtime performance

The full budget is in `art-direction.md` §6. The headline:

- **320×180 internal resolution, upscaled nearest** — ~5% of the fragments of a
  native 1080p build. This one line does more for performance than everything
  else combined.
- **Zero shadow maps.** Blob shadows from a single 128×128 alpha texture.
- **One instanced mesh** for a crowd of 200.
- **One hemisphere light + the flashlight.** Indoors, no directional light at all.
- **30 fps locked** — which is also the art direction.
- **No PBR, no normal maps, albedo only.**
- Draw calls < 250, triangles on screen < 50,000.

**Target hardware: GTX 1050 / Intel Iris Xe (2017 integrated)** — deliberately
below this machine's RTX 3050. Designing under the developer's own GPU is what
makes "smooth for users" true rather than aspirational.

The test: if it holds 60 fps at 1080p on a 2017 iGPU, it runs everywhere —
including on a phone.

### 4.3 Build time and iteration speed

**< 50 MB** means the whole game rebuilds and uploads in under a minute. This is
a design constraint, not a vanity number — a slow build makes you iterate slowly,
and iterating slowly is how projects die.

Assets are generated from Python (`pipeline.md`), so CI rebuilds the entire art
library from source and nothing is ever hand-committed.

### 4.4 The engine itself

Godot is ~100 MB installed and exports to **~50 MB with no runtime dependency.**
The player downloads one folder and double-clicks it. No engine install, no
launcher, no account, no sign-up.

Godot also exports to **Android natively** — same project, one checkbox, and the
`.aab` Play requires is ~60 MB because the arm64 engine runtime is bundled. That
is what makes the two-storefront plan in §8 possible without a second codebase.

This is a distribution decision as much as a technical one — see
[`distribution.md`](distribution.md).

### 4.5 The player's attention

The lightest thing in a horror game is **silence**, and it is the most effective
tool available. Four seconds of nothing in the prologue is worth more than any
model, and it costs nothing.

The fear budget is **70% audio, 20% camera and editing, 10% models** — so the
expensive work is writing and recording rather than triangulating, and the scene
budget stays small.

---

## 5. Why the house is small

The prologue is a **small house: four rooms, one floor.** Story choice *and*
performance strategy:

- Every room within thirty seconds' walk of every other room
- The player learns the whole layout in the first minute
- **The last safe place is small**, which is why losing it hurts
- Transitions are near-instant
- Four rooms is roughly **2,000 triangles** of level shell

A large explorable house would be ~40,000 triangles and a worse story.

---

## 6. Performance strategy

The order of operations matters — each layer is cheaper than the one above it.

| # | Technique | Saving | Cost |
| --- | --- | --- | --- |
| 1 | Render at 320×180, upscale nearest | **~95% of fragments** | 1 line |
| 2 | No shadow maps (blob shadows) | Huge | 1 material |
| 3 | One instanced mesh for the whole crowd | 199 draw calls → 1 | 1 scene setup |
| 4 | Cap at 30 fps | Half the CPU/GPU time | 1 setting |
| 5 | Held frames during scares | Negative (it saves) | Free |
| 6 | 16-colour, ≤128px textures | VRAM + bandwidth | 1 validator |
| 7 | No PBR maps, albedo only | Shader cost, VRAM | 1 material |
| 8 | One hemisphere + one spot light | Massive vs Forward+ | 1 scene setup |
| 9 | `MultiMesh` for Guests and Children | Draw calls | 1 node type |
| 10 | Aggressive object pooling | GC hitches | 1 manager |

**Frame-rate target: 30 fps locked.** Not a compromise — 30 fps and a held frame
are part of the art direction. See `art-direction.md` §4.5.

---

## 7. What I can and cannot verify in this environment

Being straight about this, because it changes how the work should be sequenced.

| Tool | On this machine | Consequence |
| --- | --- | --- |
| Node 22 | **Yes** | I can build and run web prototypes |
| Python 3.13 + `uv` | **Yes** | I can write and run all asset-pipeline scripts |
| **Godot** | **No** | I **cannot compile or run** a Godot build here |
| **Blender** | **No** | I **cannot run** the `bpy` build scripts here |
| **ffmpeg** | **No** | Video capture needs installing |

So the sequencing should be:

1. **Write the design docs** (done — that's what this repo currently is)
2. **Build `prototype/`** — a Three.js look-dev harness in the browser that
   applies the PS1 + VHS shader chain and the wrongness pass to a test mesh.
   *I can run this, screenshot it, and iterate on the look with you before you
   install anything.*
3. **Write the full `bpy` pipeline and Godot project** — I can author all of it
   correctly, but you run it.
4. **You install Godot + Blender** (both free) — I can script that as a
   one-command bootstrap.

Step 2 exists specifically so we are not betting the art direction on something
nobody has looked at yet. It is ~200 lines and it de-risks the entire project.

---

## 8. Platform targets — two storefronts from day one

**Desktop and mobile ship together.** Same project, same release. Not
desktop-now-mobile-later.

The reason is scheduling, not preference: **the input layer is far cheaper to
get right before you write it than after.** A touch scheme bolted onto a finished
game is a rewrite; one designed in from the start is a second native target. The
decision gets made here, while it is still free.

| Platform | Notes | Store |
| --- | --- | --- |
| **Windows** | Primary. x86_64, ~50 MB | itch.io |
| **Linux** | AppImage, ~50 MB | itch.io |
| **Web (HTML5)** | Playable in-browser, no download | itch.io + GitHub Pages |
| **Android** | `.aab`, arm64-v8a | **Google Play** |

**Not day one:** macOS (easy, add later), iOS ($99/yr **and** a review queue that
would stall releases), Steam ($100 upfront — see [`distribution.md`](distribution.md)).

### 8.1 Why mobile is not a port

The core verb of this game is **crouch-walking to stay quiet.** That is a
hold-and-release gesture on a thumb, and it is the single thing that decides
whether the Android build is playable or a slideshow. So the whole input layer is
designed around **two thumbs and no keyboard**, from the first commit.

Four held gestures at once. Here is the whole screen, and the layout is not
negotiable because the geometry is.

```
  +------------------------------------------+
  |                              +------+   |
  |        (look: drag)          | LIGHT|   |   upper right,
  |                              +------+   |   thumb-reachable
  |                                              |
  |                          +-----+             |
  |          +-----+          |SPRNT|             |   right of the right
  |          |INTCT|          +-----+             |   thumb
  |          +-----+                            |
  |  +---+                     +-----+           |
  |  |CRH|                     |SPRNT|           |
  |  +---+    +---------+       +-----+           |
  |          |  MOVE  |                         |
  |          | (stick)|                         |
  |          +---------+                         |
  +------------------------------------------+
```

| Verb | Desktop | Mobile | Position |
| --- | --- | --- | --- |
| Move | WASD | Left-thumb virtual stick | Bottom-left, spawns under the thumb |
| **Crouch** | C or Right Ctrl (hold) | Hold button | **Left**, above the stick |
| **Sprint** | Space or Left Shift (hold) | Hold button | **Right**, under the light |
| **Flashlight** | F (hold) | Hold button | **Upper right** |
| Look | Mouse | Drag anywhere on the right half | Everywhere right of the stick |
| Interact / say the birthday | E | Large tap target | **Centre**, thumb-agnostic |
| Dialogue advance | Space / click | Tap | Anywhere |
| Pause | Esc | System back button | OS-level |

**Four held buttons plus a stick is a lot, and it is still one per thumb.**
Crouch sits on the same thumb as movement, and sprint and light sit on the same
thumb as looking. No finger ever leaves its side. That is what makes it playable
rather than a dexterity puzzle.

The **interact target is deliberately centred and finger-agnostic** — you tap it
with either thumb. Interact is used in conversation and in moments where both
thumbs are busy holding things, so it cannot live on one side.

### 8.2 Sprint is the loudest thing in the game

This is not a speed button and it must not be tuned like one.

**Running is what gets you caught.** Ghouls hunt by sound (`worlds.md`), and
sprint is the loudest state in the game by a wide margin. So:

| State | Speed | Noise | Notes |
| --- | --- | --- | --- |
| Crouch | 0.6 m/s | ~silent | The safe default |
| Walk | 1.8 m/s | quiet | Normal movement |
| **Sprint** | **4.2 m/s** | **very loud** | Twice walk, and it is a *decision* |

**Sprint and crouch are mutually exclusive.** Holding crouch cancels sprint, and
the stick's outer radius past 70% triggers sprint only when crouch is not held.
One thumb sliding outward is sprint; that thumb sliding inward is crouch. It is
the same muscle, so it is learnable in one chase.

**There is no stamina bar.** This is the decision from `worlds.md` and sprint is
where it matters most: sprint is limited by **geometry**, not by a gauge. Alleys
are short enough to sprint safely, open rooms are not, and the level teaches you
which is which through shape alone. A stamina meter would turn sprinting into an
account to watch; geometry makes it a decision about the room you are standing in.

**Sprint has no cooldown and cannot be disabled.** It is always available. It just
costs you silence, and the player is the only one who knows what that costs.

### 8.3 The four rules that make touch work here

Non-negotiable. They are the difference between a playable Android build and a
bad one.

1. **Crouch, sprint and flashlight are hold-to-use, never toggles.** In a chase
   the player wants crouch held continuously, sprint burst-and-released, and the
   flashlight flicked constantly — it trades silence for safety (see `worlds.md`).
   A toggle forces a re-press at exactly the moment a hand is shaking.

2. **The stick spawns under the thumb at rest**, not in a corner. A fixed corner
   means constant reaching during panic.

3. **Look-drag sensitivity drops 40% while crouched**, and rises slightly during
   sprint — you are moving too fast to check details, and the game should say so.

4. **Sprint and being-acquired both get haptic pulses**, and they are different.
   A short tick entering sprint; a longer buzz when a ghoul locks on.

   This matters more than it looks. **Audio carries 70% of this game's fear
   budget** (`art-direction.md` §9), and the primary warning is the bad cheer —
   which a phone playing through a speaker on a train simply destroys. Haptics
   are the second channel for that warning. Without them the mobile build loses
   the single most important piece of information the game can give you.

**No visible buttons in the way.** Crouch, sprint and light are transparent hit
areas that fade in on touch. Only crouch and sprint show an icon at all, because
those two must be findable without looking down.

**Desktop keybinds are rebindable and non-default.** C for crouch rather than
Shift, because Shift is not adjacent to WASD. This is a real ergonomic note: the
three movement states must be reachable **without moving the hand's home
position**, and every keyboard player uses Shift as a modifier by reflex.

### 8.3 The performance difference, and why it is fine

Mobile gets a **harder** budget. It is survivable because of decisions already
made:

| | Desktop | Android |
| --- | --- | --- |
| Internal render res | 320×180 | **320×180** |
| Shadow maps | 0 | 0 |
| Dynamic lights | 2 | **2** |
| Draw calls | < 250 | < 250 |
| Target | GTX 1050 / Iris Xe | **Adreno 610 / Mali-G57** |

An Adreno 610 is roughly a GTX 1050 minus the CPU. Because the art direction
already renders at 320×180 with no shadows and one material, **the same scene runs
on a mid-range 2020 Android phone.** The pixel ratio does the work polycount would
otherwise have to.

The real mobile cost is **battery and thermal** — 30 fps 3D for 45 minutes warms
a phone. Mitigations: the 30 fps cap (already), plus a settings toggle that drops
internal render to 256×144 on devices reporting thermal throttling.

### 8.4 Android build settings

- **arm64-v8a only.** armeabi-v7a is dead as a requirement and doubles the
  bundle for nothing. Godot 4 defaults to 64-bit.
- Export as **`.aab`** (Android App Bundle) — Play requires it.
- Target SDK: current Play requirement. It moves yearly; check before release.
- `min_sdk`: low enough for most 2020 hardware, high enough to avoid supporting
  a decade-old device neither of us has.
- **Landscape only.** A 16:9 locked frame is correct for a fixed internal render
  resolution and sidesteps the layout problem entirely.

### 8.5 Release path — Google Play

Google requires a **closed test with at least 12 testers for 14 days** before
production, for new personal accounts.

| Stage | Who | Notes |
| --- | --- | --- |
| **Internal testing** | You | Instant, no tester minimum. **Ship here first.** |
| **Closed testing** | 12+ people, 14 days | The mandatory gate |
| **Production** | Public | |

This is the real calendar cost: plan for **three weeks**, not three days.

**Content policy, stated plainly:** this is horror featuring the death of a child.
The IARC questionnaire asks directly about death and whether characters are
minors. Answer honestly. The likely result is a **content descriptor** on the
listing ("depictions of death", mild fear) — a commercial label, not a policy
problem. Nothing here gets rejected for being horror; this is well inside normal
for the category.

### 8.6 What mobile changes about the design, honestly

Three consequences, none of them negotiable:

- **Session length.** 45 minutes on a phone, in the dark, with headphones, is a
  long ask. **Cut a short Act I demo as the Play surface** — prologue plus one
  hour, ending at the first ghoul. That is the download driver. Full game $4–6,
  demo free.
- **Aspect and posture.** Held vertically, a 16:9 game is small and the scanlines
  may not resolve. Locked landscape, with an **intentional letterbox** so the
  black bars read as part of the aesthetic.
- **The quiet moments do not survive a commute.** Audio carries 70% of this game
  and it needs stillness. The desktop version is the "real" one; the phone build
  is the accessible door into it.

That last point is worth saying plainly: **the mobile build is how people find
the game, not necessarily how they finish it.**

---

## 9. Save system and progression

- Godot's `user://` with **JSON**, not binary — a save file a human can read and
  a player can find
- One save per act boundary, plus a rolling autosave at each checkpoint
- **The save file is named `feb_29.bak`.** It is not a joke, it is not
  acknowledged in the UI, and the player will notice.
- Flags are a flat dictionary. No object serialisation — if a save can be
  corrupted, it will be, and a JSON file can be fixed by hand.

---

## 10. Testing

| Layer | Tool |
| --- | --- |
| Unit tests | GUT or `gdUnit` for the state machine, clock, and interaction verbs |
| Asset budgets | `tools/validate_assets.py` in **CI** — a 900-triangle child fails the build |
| Perf regression | Godot's built-in profiler, recorded as a baseline per act |
| Playtest | Manual, with a scripted checklist per act |
| CI | GitHub Actions — build assets, run tests, package, upload to itch/Steam |

---

## 11. The repository is the build system

`game/assets/models`, `game/assets/textures`, and `game/assets/audio` are
**build outputs and are git-ignored.** The source is the Python in `art-source/`.

```
git clone  →  python -m tools.build_all  →  every asset in the game
```

Why this matters:

- The repo stays a few MB instead of a few hundred
- Every asset is diffable — a change to the crowd's proportions is a readable
  commit in `wrongness.py`, not an opaque 40 MB `.blend`
- CI can rebuild everything from scratch and prove it
- Nothing can be lost, because nothing hand-made exists

Full detail in [`pipeline.md`](pipeline.md).

---

## 12. Open questions

1. **Godot 4.4 vs waiting for 4.5/5.x.** 4.4 is stable and proven; the
   renderer changes in 4.5 are tempting but risky. Recommend 4.4 and move only
   if a blocker appears.
2. **Do we pay for the Steam fee up front?** Not a tech question, but it gates
   the storefront plan.
3. **Is a 30 fps lock acceptable for accessibility?** Some players dislike it.
   I think it is correct for the art direction, but it is worth a settings
   toggle.
