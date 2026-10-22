# Worlds 2–4 — the 30th, in three parts

The white door at the end of Act 1 no longer shows a card. It opens into a
chain of three worlds that ends at your own birthday table on the evening of the
29th.

```
prologue (bedroom)
   └─ fall → title → [N]
        └─ cavern.tscn            Act 1
             └─ world2_mushrooms.tscn   glowing cave   (crawlers)
                  └─ world3_blood.tscn   red cave       (three lost souls)
                       └─ world4_street.tscn  foggy street (two)
                            └─ goodbye at your door
                                 └─ ending.tscn   the party, two plates
```

Everything is still code-built. No imported models, no shadow maps, no
textures. The VHS overlay, 320×180 render and procedural audio carry the
look.

## World 2 — the bright cave

**File:** `game/src/world/mushroom_cave.gd` · **Scene:** `world2_mushrooms.tscn`

The pretty one. Silksong-adjacent, but wrong underneath:

- 64 glowing mushroom clusters, five cap colours. Only **three** real
  `OmniLight3D`s; the rest of the glow is emission, which costs nothing.
- A trail of **rainbow pebbles** down the centre of the path. It is the only
  honest thing in the level.
- Three hollows to crouch in: fat stems, a low cap shelf, and a glowing rim so
  the safe spot is readable in the dark.
- **Crawlers** (`src/world/crawler.gd`): `Ghost` subclass. Low, wide, four
  wrong-length legs, a face with no eyes. Faster than a ghost (4.0 m/s),
  narrower sight (10 m), sounds the same.
- Wren's line: *"Caps are listening. Don't touch them."*

## World 3 — the red cave

**File:** `game/src/world/blood_cave.gd` · **Scene:** `world3_blood.tscn`

Narrower, hotter, no directional light at all.

**This is not a gore level.** `docs/art-direction.md` §8 bans body horror, so
there are no bodies, no dismemberment and nothing to clean up. The "blood" is
stained rock, still pools, and thin red drips from the ceiling. The horror is
that the cave is where uncounted days went to stop existing.

- 22 still pools with a darker rim, unshaded, so they read as depth rather
  than paint.
- Stalactites and three hollows cut into the walls.
- **Three lost souls** patrol overlapping ground. This is the hardest cave:
  more enemies, less light, tighter path.
- Wren: *"It's warm in here. Like a mouth."*

## World 4 — the street

**File:** `game/src/world/fog_street.gd` · **Scene:** `world4_street.tscn`

Your street, fogged until it forgets itself. Eight houses, three streetlights,
one warm window, a bicycle left in the road, and your front door at the end.

- Two lost souls walk the middle of the road. Hide behind the hedge, the bins,
  or the bus shelter.
- The exit is **your own door**, and it needs **E**. No arch, no card.
- Wren stops at the threshold. The goodbye is a dialogue-box choice:

  > **WREN:** This is as far as I go. The door only knows one of us.
  >
  > **YOU:** *Come with me.* / *I'll stay.*

  Both answers converge. She asks you to leave the cupboard open, then tells
  you that spending the day with you was the best birthday they ever had. At
  the party you understand it was a lie.

## The party

**File:** `game/src/world/ending.gd` · **Scene:** `ending.tscn`

No enemies, no stamina, no chase. You came up through the cupboard that
morning. By 6:40 PM it is the 29th, your birthday, and Mum has set the table.
She got everything right.

- Warm dining room: one lamp over the table, dusk through the window, candle
  light on the cake. No shadows.
- **Two plates. Two hats.** Mum does not know why she set the second place. The
  chair opposite you is empty.
- Eleven candles. **E** at the cake opens the last choice: *Blow out the
  candles.* / *Leave them burning.* Both converge.
- The realization: at the door Wren said spending the day with you was the best
  birthday they ever had. It was a lie — a kind one, said so you would go home
  and have yours. *Most people get to enjoy their life. Wren didn't get to enjoy
  theirs.*
- You don't feel like celebrating. You sit down anyway. Mum pretends not to
  notice.
- End card: **FEBRUARY 29th — for Wren**, then **E** replays the prologue.

## How the chain works

New worlds share one director, `src/world/journey.gd`. It reads all level and
story data from the geometry script attached to its `Geometry` child:

| Property | Meaning |
| --- | --- |
| `spawn` / `exit_pos` / `exit_radius` | where you start, where the world ends |
| `hide_spots` / `hide_radius` | crouch-to-hide zones |
| `checkpoints` | respawn points, in order |
| `patrols` | patrol loops, assigned to enemies by index |
| `beats` | position + radius + subtitle lines, fired once |
| `objective` / `intro` | HUD text |
| `next_scene` / `is_final` | chain wiring |
| `exit_requires_interact` | caves auto-exit; the street door needs E |
| `music_pitch` | same motif, different room (0.85 / 0.55 / 0.95) |

This is why the story coordinates and the level coordinates cannot drift
apart. Adding a beat means editing the geometry script that owns the ground
it happens on.

Shared pieces:

- `src/world/cave_base.gd` — `rock`, `floor_slab`, `corridor`, `exit_arch`,
  `atmosphere`, `hide_marker`.
- `src/ui/journey_hud.gd` — objective, subtitle queue, breath bar, VHS, flash,
  fade, end card.
- `src/ui/dialogue_box.gd` — the choice box from Beat 7, reused for the
  goodbye.
- `Ghost` tunables (`chase_speed`, `view_dist`, `catch_dist`, `lose_time`, …)
  so each world's monsters feel different without new AI.

Caught behaviour is unchanged from Act 1: flash, sting, short freeze, fade,
respawn at the last checkpoint, 3 s of grace. There is no death screen.

## Controls

| Action | Key |
| --- | --- |
| Move / look | WASD / mouse |
| Crouch (hide) | **C** |
| Sprint (drains breath) | **Shift** |
| Flashlight (makes noise) | **F** |
| Interact / advance dialogue / choose | **E**, **Enter**, **Space**, click |
| Dialogue cursor | **W/S** or arrows |
| At the title | **N** to descend |

## Tests

```powershell
cd game
godot --headless --import
godot --headless res://tests/test_worlds.tscn      # 35 checks, all three worlds + ending
godot --headless res://tests/test_act1.tscn        # 8 checks
godot --headless res://tests/test_dialogue.tscn    # 12 checks
```

`test_worlds` asserts per cave: boot, enemy count/type, hide, chase trigger,
chase music, catch, checkpoint respawn, and exit → `LEAVING`. For the street it
asserts final-world data, Wren, both enemies, and that the door starts the
finale dialogue. For the ending it asserts the party boots, Mum is present, the cake choice
opens, and the card and title appear without the stamina bar. Scene changes are
disabled under test so the test scene itself is not replaced.

## Known limits (honest)

- Wren follows through walls. She is a ghost; it reads as intentional, but it
  is not pathfinding.
- No save system. The chain is one sitting, which suits a 30-minute horror
  short.
- Caves use three to four dynamic lights each. If a 2017 iGPU complains,
  cut the mushroom lights first; emission carries the look.
- The street goodbye is the only branching choice after Beat 7. Everything
  else is conversation, per `docs/prologue.md`.
