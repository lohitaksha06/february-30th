# Act 1 — The Cavern (playtest guide)

From the prologue title card, press **N** to descend. (Prologue unchanged:
**R** still replays it.)

## The run (about 8–10 minutes)

1. **Land.** Cold floor, Wren holding your sleeve. Objective, top-left:
   *follow the white butterflies · run only when seen*.
2. **Walk, don't run.** Wren's first talk beats explain the rules as you
   move: the lost ones hear running; the white butterflies fly the true
   path on a loop — follow them, not Wren.
3. **Hollow rocks** (white pebble line at the mouth): crouch (**C**) inside
   and ghosts can't see you. *Hidden — stay small* shows in the prompt.
   Break line of sight first; a ghost that watched you go in still knows.
4. **Ghost grounds** (two, mid and deep cavern): tall dark figures, pale
   squeezed faces, no eyes, one arm dragging. Patrol → suspicious (heard
   you) → **chase** (saw you): the eerie loop starts — detuned shimmer,
   heartbeat, low beating drone (`art-source/audio/synth_chase.py`) — and
   the prompt says *IT SEES YOU — RUN*.
5. **Breath bar** (bottom-left): ~3.5 s of sprint from full, then you drop
   to a walk until it recovers past a third. Sprint (4.2 m/s) outruns a
   chase (3.6 m/s) but not forever — plan the hollows.
6. **Caught** = white flash + sting + checkpoint respawn, never death.
   3 s of grace after. Checkpoints at both ghost grounds.
7. **The white door** at the far end: walk in → *THE 30TH IS WAITING*,
   to be continued. **E** walks it again.

## Controls (new vs prologue)

| Action | Key |
|---|---|
| Crouch / hide (hold) | C — the most important key in this act |
| Sprint (hold, drains breath) | Shift |
| Everything else | Same as prologue (WASD, mouse, F torch, E) |

Torch note: light adds noise (`+4 m`). In a chase it doesn't matter; while
sneaking past a patrol, keep it off.

## Verified how

`game/tests/test_act1.tscn` plays the level headless: boots, chases on
sight, starts the music, catches on touch, respawns at the checkpoint,
re-chases, gives up on a hidden player, ends at the door. 8/8 CHECKs pass,
twice in a row. Run it: `godot --headless res://tests/test_act1.tscn`.

One honest footnote from testing: teleporting exactly inside a capsule
parks the rider on the ghost's head, out of catch range — physics
stalemate, test-only artifact (real play collides at ~0.6 m and catches).
The test offsets by 0.8 m and notes it.

## Deliberate deviation

`docs/worlds.md` + `tech-stack.md` say **no stamina bar** (sprint limited
by geometry). This act adds one anyway, per your call: chases here are
longer than the docs' alleys assume, and a visible breath bar teaches
*run only when seen* in one chase. Prologue is untouched (stamina off).
