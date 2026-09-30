# Art Direction — How the Models Get Made

> Status: draft v1, for review.
>
> This is the answer to *"how will you make the models?"*

---

## 1. The key idea: cheap and wrong

The brief is *Bad Parenting* — disturbing graphics, but **not heavy**. That is
not a contradiction, and it is the whole design.

`Bad Parenting` and the games in its lineage are frightening because they
**deliberately under-build**. PS1-era limits, low-res textures, wrong proportions,
held frames, analog post. Nobody in those games spent polygons on anything. The
uncanny valley was reached by *removing* fidelity, not by adding it.

So our rule, and it is the rule the entire art pipeline serves:

> **The horror is not in the model. The horror is in the error.**
>
> Every distracting triangle we spend on a character is a triangle we did not
> spend on a proportion that is 4% wrong. The second one is free and it is what
> the player actually remembers.

If you ever find yourself adding detail to make something more convincing, stop.
Make one thing *wrong* instead. It is cheaper and it is scarier.

---

## 2. Toolchain

Nothing here is bought. All of it is free and scriptable.

| Stage | Tool | Why |
| --- | --- | --- |
| Modelling | **Blender 4.x**, scripted in Python (`bpy`) | Free. Models are built by *code*, not by hand — so they are reproducible, diffable, and regenerable |
| Textures | **Aseprite** (scriptable) + Python for generation | Free. Low-res pixel work is its home turf |
| Audio | **Python** (`numpy`, custom DSP) | Free. Most of our horror audio is synthesis, not samples |
| Export | `bpy` → **glTF 2.0 / `.glb`** | Small, GPU-friendly, loads natively in Godot and Three.js |
| Validation | Python | Enforces the budgets in §6 so a bad asset fails CI, not review |

**Everything is generated from source.** The `.py` files are the source of truth;
the `.blend` and the `.glb` are build artefacts. See `pipeline.md`.

> **Prerequisite:** Blender is not currently installed on this machine. It is a
> ~300 MB free download and is a one-time setup step. I can write the full
> pipeline before it is installed, and it will run headless
> (`blender --background --python build.py`) the moment it is.

---

## 3. Modelling rules

### Hard budgets — enforced by `tools/validate_assets.py`, fails CI

| Class | Triangle budget | Vertices |
| --- | --- | --- |
| Child / the Boy | **≤ 800** | ≤ 450 |
| Adult (Party Guest) | **≤ 400** | ≤ 250 |
| Hero prop (cupboard, cake, car) | **≤ 600** | ≤ 350 |
| Common prop (chair, mug, coat) | **≤ 120** | ≤ 80 |
| Level shell (per room) | **≤ 3,000** | ≤ 2,000 |

### Absolute prohibitions

- **No subdivision surface.** Ever. Not for anything.
- **No sculpt detail, no high-poly retopo, no bake chains.** The pipeline has
  no step where polygons multiply.
- **No normal maps, no roughness maps, no PBR.** Albedo only. Lighting is
  vertex/diffuse. This is not laziness — it is what makes the 1998-CD-ROM read.
- **No realistic human faces.** Ever. At 800 triangles you cannot build one, and
  you must not try. Our faces are texture on a wrong head, which is both cheaper
  and far more effective.

### The 800-triangle child

That is genuinely enough. It is roughly *Half-Life 2-era* character density. A
humanoid at 800 tris is about 60–70 for each limb segment, 100 for the head,
and the rest distributed. The result reads as *intentionally crude*, which is the
target.

---

## 4. The seven tricks — this is the actual art direction

These are cheap, and they are doing all the work. Ranked by value per triangle.

### 4.1 Wrong proportions — *the single highest-value trick in the project*

Take a correct child and make **one** dimension off by 3–8%. One. Not all of
them.

- left arm 6% longer than the right
- head 4% too large for the body
- the jaw 3% wider on one side
- feet 8% too small

The player cannot articulate what is wrong. They will not say "his left arm is
6% too long." They will say the room made them uncomfortable and they will not
be able to say why, and **that is the entire effect**. It costs zero triangles
and is achieved by scaling a bone.

This is scripted, not hand-done, so it is applied consistently:

```python
# art-source/blender/src/wrongness.py  (illustrative)
WRONGS = {
    "arm_l":   1.06,   # +6%
    "head":    1.04,   # +4%
    "foot_l":  0.92,   # -8%
    "jaw":     1.03,
}

def apply_wrongness(rig, seed):
    """Scale named bones by a few percent. Never the whole body."""
    rng = random.Random(seed)          # deterministic per character
    for bone, delta in WRONGS.items():
        if rng.random() < 0.65:         # only ~2/3 of the errors per character
            f = 1.0 + delta * rng.uniform(0.7, 1.3)
            rig.bones[bone].scale *= f
```

Seeded, so a given character is *always* wrong in exactly the same way. A crowd
of 200 has 200 distinct, consistent silhouettes from one mesh.

### 4.2 Vertex snapping (PS1 jitter) — 8 lines of shader

Quantise the final clip-space position to a coarse grid. The mesh appears to
"shimmer" as it moves. Free. Instantly reads as a cursed old game.

```glsl
// game/shaders/ps1_snap.gdshader
vec4 ps1_snap(vec4 clip_pos, float grid) {
    vec2 g = vec2(grid);
    vec2 res = u_viewport_size;
    return vec4(
        round(clip_pos.xy / clip_pos.w * res / g) * g / res * clip_pos.w,
        clip_pos.zw
    );
}
```

Paired with **affine texture warping** (skipping perspective correction). A face
texture on a head turned slightly sideways, warping badly, is deeply unsettling
and costs one line.

### 4.3 Palette-locked, dithered textures

A **16-colour palette** shared across the entire game, applied per material
family. Dithered, not smoothly blended.

This is the single strongest "period" signal and it is free. It is the
difference between "a modern game in a dark room" and "a game that came off a
CD-ROM in 1998 and should not have been preserved." That second feeling is
exactly the `Bad Parenting` register.

### 4.4 Misaligned faces

Do not model a face. Take one correct face texture and:

- shift the UVs by 3–6 px
- place the eyes 2 px apart vertically
- reuse a **different child's face on a correct head**, or vice versa

Wrong-by-a-hair. Skin crawl, at zero cost. Faces are 64×64 — 16 KB each.

### 4.5 Held frames

During a scare, **freeze the animation for 300–800 ms.** A frame that stops is
far more frightening than a monster that moves, and it *reduces* work.

### 4.6 Low internal resolution

Render at **320×180** and upscale with nearest-neighbour.

This is the single largest performance lever available, and it is also an art
direction decision. It gives the crunchy, unscalable, *found-footage* look. It
costs about 5% of the fragments of a native-resolution build.

### 4.7 Fake shadows, no shadow maps

A single 128×128 alpha blob under each actor, plus one baked darkening multiply
in the wall textures. **No real-time shadow maps** except one optional 512px
cascade for the flashlight, which is togglable off in the low settings profile.

---

## 5. The doppelgänger problem, and how it is solved

The design needs **200 Party Guests** in Act I and **twelve Waiting Children**
in Act III, and Act V has **four hundred children, all with your face.**

This is the constraint that dictates the whole art pipeline. Here is the
solution:

> **One base child mesh. One skeleton. Everything else is a parameter.**

| Vary by | Method | Cost |
| --- | --- | --- |
| Face | swap 1 of 6 face textures (64×64) | 16 KB |
| Build | mirror the mesh on X | **0 bytes** |
| Height / limbs | seeded bone scale, §4.1 | **0 bytes** |
| Clothing | material colour parameter + 2 overlay meshes | ~0 bytes |
| Name tag | texture tint | 0 bytes |

**Per additional child: zero geometry, 16 KB of texture, one draw call.**

So a hall of 400 children is *one mesh instanced 400 times with six textures
swapped across it.* This is how you get that crowd inside a 50 MB build. Without
this, Act V does not exist.

The Party Guests use a separate 400-tri adult mesh on the same principle.

---

## 6. Performance budget

Hard targets. Exceeding these is a bug.

| Metric | Target | Hard cap |
| --- | --- | --- |
| Install size | **< 50 MB** | 80 MB |
| VRAM | < 24 MB | 32 MB |
| Draw calls (typical scene) | < 250 | 400 |
| Triangles on screen | < 50,000 | 80,000 |
| Real-time shadow maps | **0** | 1 (flashlight only) |
| Dynamic lights per scene | 1 | 2 |
| Internal render resolution | 320×180 → upscale | — |
| Audio payload | < 8 MB | 12 MB |
| **Target GPU** | **GTX 1050 / Intel Iris Xe (2017 integrated)** | — |

The target GPU is deliberately *well below* this machine's RTX 3050.
"Runs smoothly for users" means the user base, not the developer laptop — so we
design for a 2017 integrated graphics card and it will be effortless everywhere
else.

---

## 7. Lighting

- 1 hemisphere light (ambient)
- 1 directional light (the sun/moon — usually very dim, or none at all)
- 1 flashlight spot, player-controlled
- Everything else is **baked into the texture** as a multiply

Indoor levels use **no directional light at all** — just the hemisphere and the
flashlight, which means the flashlight is the only thing that reveals the room
and the only thing that hides it.

---

## 8. The look reference

| Borrow from | Not from |
| --- | --- |
| PS1-era texture warping and vertex jitter | — |
| Analog horror: VHS tracking, scanlines, head-switching noise | — |
| Mandela Catalogue / Local 58: stills, low framerate, wrong faces | — |
| Lunar sandbox, Room 6, the PS1 dread tradition | — |
| Domestic settings rendered *accurately* | — |
| 16-colour dithered palettes | Modern PBR |
| | **Realistic human faces** |
| | **Gore, blood, dismemberment** |
| | High-poly detail |
| | Smooth 60fps framerate (30 is the target) |

**The last row matters as much as the first.** This game's horror register is
*uncanny and administrative*. It is not body horror. A realistic screaming face
would break the entire thing. The scare in Act V is a party with four hundred
children in it, not a monster — keep it that way.

---

## 9. Where the fear budget actually goes

Roughly:

- **70% audio**
- **20% camera work and editing** (framing, held frames, cut timing)
- **10% models**

This is not a joke and it is not laziness. It is how the reference games work.
A 50 MB model of a perfect face will not frighten anyone. A door that makes the
wrong noise will.

So the asset budget is deliberately skewed away from geometry, and
`docs/tech-stack.md` allocates the real time to audio.

---

## 10. Audio design (because it is the real content)

- **The music box motif.** A 24-note celesta line played **one semitone flat**,
  looping, **slowing 2% per loop**. It plays in *every* act. By Act V the player
  hears it before they see anything. This single cue will do more work than all
  the geometry combined. It costs about 40 KB.
- **The knock.** Filtered noise burst into a 1.5 s hallway convolution tail,
  pitched down 12 semitones. Generated in Python, not sampled.
- **Static voices.** A pitched noise source ring-modulated by a 40 Hz LFO, then
  granular-stuttered. Sounds exactly like corrupted speech. **No text-to-speech
  is used anywhere in this game.**
- **Bedroom ambience.** Real room tone, minus one band. The absence is the part
  that registers.
- **No music stings on jumpscares.** Every scare uses a *removal* of sound.
  Silence is the cheapest and most effective effect available.

---

## 11. What to build first

In order, because each one de-risks the next:

1. **One child, 800 tris, in Blender, with `wrongness.py` applied.** Walk around
   it in a grey box. If this character is not unsettling, nothing else matters
   and the pipeline gets fixed here, cheaply.
2. **The PS1 + VHS shader chain** on that one character. This is the look, and
   it is viewable in ~20 lines before any of it is in the engine.
3. **The music box motif.** Because it is the theme and it is 40 KB.
4. **One Act I room** with the Guests. This proves the 200-instanced-figure
   trick.
5. Everything else.

Steps 1 and 2 can be prototyped in the browser (`prototype/`) before Blender or
Godot are installed, so the visual target can be locked and screenshotted early.

---

## 12. Open questions

1. **Does §4.1 read as unsettling, or merely as a modelling error?** This is the
   only genuinely risky claim in this document and it must be validated on the
   one child mesh before anything else is built.
2. **Palette count.** 16 is the proposal. 8 is more aggressive and more
   period-correct; 32 is safer for readability in dark levels. Needs an A/B on an
   actual Act I screenshot.
3. **Is 320×180 too low?** It is the right call for the register, but confirm
   against a real screenshot before it is locked in.
