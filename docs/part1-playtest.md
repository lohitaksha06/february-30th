# Part 1 — Playtest Guide (bedroom → fall)

Playable now in Godot 4.7. Open `game/project.godot`, press **F5**.

## The run (about 5–6 minutes)

1. **Who are you?** Click BOY or GIRL. (Wren copies you.)
2. **Wake.** Black screen, `FEB 29 11:48`. Camera on the pillow, ceiling above.
   Press **E** to sit up.
3. **Explore.** WASD + mouse. **F** = torch (hold). Walk around the bedroom.
   Cake line points you to the living room — optional, have a look.
4. **Knocks.** After ~30s (or ~8s if you walk up to the wardrobe):
   `shff shff` → 3 knocks, pause, 3 knocks. Clock reads **11:59**.
5. **Wardrobe.** Walk close, look at it, press **E**.
   Door swings → **mild jumpscare** (red flash + loud knock + 350ms freeze,
   fair-tell per `docs/worlds.md` rule 6) → **Wren** sitting inside.
6. **Talk.** Press **E** through 3 lines:
   *"It's my birthday too." / "It's the thirtieth." / "Please don't get her."*
7. **Mum.** Lock sound downstairs + *"Is everything alright?"*
   Press **E** within ~6s to **PUSH THEM IN**. (Timeout pushes anyway —
   the game never scores this.)
8. **Fall.** No cut. Camera dives through the wardrobe into a dark shaft
   with floating calendar pages, music box one semitone flat.
   Title card: **FEBRUARY 30th**. Press **R** to replay.

## Controls

| Action | Key |
|---|---|
| Move / look | WASD + mouse (click once to capture) |
| Sit up / open / talk / push | E (or Enter) |
| Torch (hold) | F |
| Crouch (hold) | C |
| Sprint (hold, loud!) | Shift |
| Replay after title | R |

## Analog-horror look (all cheap)

- Internal render **320×180**, nearest-neighbour upscale (`project.godot`)
- **VHS overlay** fullscreen shader: scanlines + grain + vignette +
  drifting tracking bar (`shaders/vhs_overlay.gdshader`)
- Cold-blue streetlight that breathes like passing cars, one directional
  light + torch only, **zero shadow maps**
- Wren: boxy kid, head 4% too big, one arm 6% longer, eyes misaligned —
  `docs/art-direction.md` §4.1, no imports, ~14 boxes

## PC load

2 lights, <60 draw calls in the bedroom, no PBR, no shadows, 30–60fps
on anything. Your machine will not notice.

## Ship to itch.io

1. Install export templates once: Godot → Editor → Manage Export Templates → Download.
2. Project → Export → **itch-windows** / **itch-linux** / **itch-web**
   (presets in `game/export_presets.cfg`, output goes to `build/itch/`).
3. Upload the Windows `.exe` (+ `.pck`) and/or the `web/` folder to itch —
   set "Kind of project: HTML" for the web build so it plays in-browser.

## What's stubbed for Part 2

- Living-room cake close-up + letterbox dialogue portraits
- Touch buttons (look-drag already works; buttons per `tech-stack.md` §8 next)
- The 30th side: street, ghouls, chase by sound
