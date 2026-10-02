# Scope — and why your friend is right

> **Your friend is right, and the current five-act plan is the wrong shape for two
> people.** This document is what to cut, and what to keep.

---

## 1. The honest assessment

The design so far is a *good* design. It is also roughly **two to three years of
solo work**, and you are a beginner. Those two facts have to be held at the same
time.

Here is what the current plan actually costs, in the crudest possible units:

| Work | Estimate |
| --- | --- |
| Prologue (12 min) | 2–4 weeks |
| Act I as written (four mechanics, ~1500-tri crowd) | 6–10 weeks |
| Act II (a driving act with vehicles) | 6–8 weeks |
| Act III (12-children identification minigame) | 5–7 weeks |
| Act IV (a real puzzle with a real solution) | 5–7 weeks |
| Act V (a cathedral room + 400-instanced crowd + death scene) | 8–12 weeks |
| Polish, audio pass, packaging, publishing | 6–8 weeks |
| **Total** | **~38–56 weeks** |

That is a real 3D game with real content. It is also the single most common way
first-time projects die: not because the idea was bad, but because the plan
assumed the person had already made one.

**The failure mode here is not a bad game. It is no game.** An unreleased game is
worth zero, and the design skill you build by *finishing* one is worth more than
the difference between a 5-act game and a 2-act game.

---

## 2. The reframe

There is a version of this that is small, finishable, and **not a compromise** —
because a short game is not a lesser form of the thing, it is the thing. Games like
*Oxenfree*, *Gone Home*, *To the Moon*, and most of the good short horror on itch
run 60–90 minutes. Nobody has ever felt shortchanged by one.

So the rule for this project:

> **Cut from the ends, never from the middle.**
>
> The prologue and the death are the two best things in the design and they are
> untouchable. Everything else is negotiable.

### What becomes FEBRUARY 30th

| | |
| --- | --- |
| Prologue | **Keep, unchanged.** 12 minutes |
| Act I | **Keep, reduced.** One mechanic. ~20 minutes |
| Act V | **Keep, reduced.** The party and the death. ~15 minutes |
| **Total** | **~45–60 minutes** |
| Levels | **3** — bedroom, house, cupboard-world |
| Acts | **2** — the fall, and the party |
| New systems | **4** — dialogue, chase, "is this my birthday", the death |
| Characters | **3** — you, your companion, your mother (off-screen) |

### What gets cut and where it lives

| Cut | Why | Where it goes |
| --- | --- | --- |
| **Act II — The Long Way** (the highway) | Vehicles are the most expensive thing in 3D. A drivable car, road geometry, and traffic are a month of work on their own. | A **single bus window** in Act I. One shot, no driving, ten minutes of my time. The mother can say her one line through it. |
| **Act III — Lost and Found** | A 12-children identification minigame is a whole second game. | Gone. |
| **Act IV — The After** | The puzzle is good but it is *exposition*, and the exposition has to be in dialogue now. | Compressed into **two dialogue beats** on the walk through Act I. |
| **Act V — The 30th room** | The cathedral of calendar pages is 8k triangles and it is beautiful and it is *not* what makes this game good. | The party happens in **your kitchen**. Your mother's kitchen. It is the last safe room and that is why it is the saddest one. |

That last cut is the one worth arguing about, and I will argue for it: **the
party happening in the room where the party was supposed to happen** — the
same table, the same cake, eleven candles, a second hat — is better than a
cathedral. In the cathedral you are a visitor. In the kitchen it is *yours*, and
the game has been telling you it is yours since the first scene. It is also about
2,000 triangles instead of 8,000, and it connects the ending to the opening
directly, which makes the whole thing feel like one story instead of two.

---

## 3. Act I, rebuilt

This is the act that does all the work now.

```
   BEDROOM ──────────► the house ──────────► the 30th ──────► the kitchen
   (prologue)          Act I, 20 min        Act I, 20 min     Act II, 15 min
```

### Act I-a — the house

Your street, but *small*. Not a cul-de-sac of six houses — **your house and its
neighbours, seen from the pavement**, then back in through a door that should not
open onto this.

- **The Guests** — motionless adults. Cone-of-vision, the one stealth rule.
- **The Unacknowledged** — ghosts who ask *"Is this my birthday?"* Say yes and
  they rest. Say no and you lose a memory.
- **The photograph** — your companion in it, beside another child with your face.
- **The woman in the cardigan**, not facing the street. Your mother. Most players
  miss her.
- **One bus.** A window, a route number, your mother's line.

That is four systems, and three of them are ones you already need elsewhere.

### Act I-b — the 30th

The overturned world. The cupboards and the rooms, inside out and impossible.

- **Ghouls.** Two. They hunt by sound.
- **The coat** — name tag, one letter wrong.
- **The truth**, in two dialogue beats, on the way.

### Act II — the kitchen

The party. Fifteen minutes. The candles. The misspelled name. They get what they
wanted, and then they die, and you escape.

---

## 4. What actually makes this hard (the real risk list)

Not scope. **Four technical things**, and you should know them all before you start.

| Risk | Why it will bite | Mitigation |
| --- | --- | --- |
| **Godot skill** | Neither of you has shipped anything. You will be fighting the editor, not the design. | Build the prologue first. Twelve minutes, four rooms, no enemies. If you can't finish that, nothing else matters. |
| **Character animation** | The worst thing to build and the thing you cannot avoid. Procedural walking for two actors beats hand-animated anything. | Procedural animation from day one. See §6. |
| **The chase** | Two agents chasing one is genuinely hard. Pathfinding, navigation mesh, and getting stuck on corners. | **One ghoul, on a navmesh, in Act I-b.** No second one. Make it work properly before adding a second. |
| **Audio** | It carries 70% of the fear and it is the thing you will be most tempted to skip. | The prologue's sound design is four sounds: room tone, the music box, the knock, the door lock. Get those right and you have 80% of what makes this game work. |

**The prologue is the whole project, scaled down.** If you build the prologue and
it is good, the game exists. Everything after is elaboration.

---

## 5. What to build, in order

| # | Milestone | Why this one |
| --- | --- | --- |
| **1** | **Prologue** — 4 rooms, 2 actors, dialogue, no enemies | The whole game, scaled down. Finishing this proves you can finish something. |
| 2 | The 800-tri child with the wrongness pass | Validate the art direction before anything depends on it |
| 3 | PS1 + VHS shader chain | The look. ~20 lines of shader. |
| 4 | Act I-a — house, Guests, Unacknowledged | Four systems, three reusable |
| 5 | **One ghoul** on a navmesh | The riskiest technical thing in the project |
| 6 | Act I-b — the 30th, the coat, the dialogue | The rest of the game |
| 7 | Act II — the kitchen, the party, the death | The ending |
| 8 | Publish the demo, get 100 players | See `distribution.md` |

**Do not skip milestone 1.** Everything else is optional. That is the single most
important sentence in this document.

---

## 6. The shortcuts that are not compromises

Because cutting scope is painful, here is what you *don't* have to give up.

**Animation — procedural, always.** A character that swings its arms based on
distance travelled, leans into turns, and bobs with its own height looks fine at
30 fps, in the dark, with a VHS filter. Nobody has ever said "that walk cycle is
poorly animated" in a game that looks like this. This single decision saves
**months** and is the reason the original 5-act plan was affordable at all.

**Audio — synthesise it.** The knock, the music box, the bad cheer, the static
voices are all Python DSP. No sample library, no licensing, no recording studio.
It is also, as it turns out, the correct *sound* — the reference games are built
on degraded synthetic audio anyway.

**Crowds — instance it.** 200 guests is one mesh drawn 200 times. This was
already the plan and it costs nothing.

**The look — cheat the resolution.** 320×180 is not a limitation, it is the art
direction. It is also 95% of your performance budget.

**One texture atlas, one material.** Fewer draw calls than you think you need.

---

## 7. Two beginners, honestly

The one genuine advantage you have: **there are two of you.**

| Split | Who |
| --- | --- |
| Code | Whoever is faster in GDScript |
| Art, models, textures | Whoever is faster in Blender or Aseprite |
| Audio | Whoever can tolerate fiddling with DSP |
| Writing | Whoever is willing to be the one who says no |

But **not two of you on the same thing at the same time.** Merge conflicts in
GDScript and in `.tscn` scenes are miserable, and Godot scene files are large and
merge-hostile. Pick one file per person per week.

And if you are not going to work on it together, do not pretend you will. One
person with a finished 45-minute game beats two people with an unfinished
five-act one, every time.

---

## 8. The realistic version

| | Five acts (current) | **One night (recommended)** |
| --- | --- | --- |
| Length | 4–6 hours | **45–60 min** |
| Levels | 5 | **3** |
| Acts | 5 | **2** |
| New systems | 12+ | **4** |
| Level geometry | ~40,000 tris | **~6,000 tris** |
| Weeks of work | 38–56 | **12–18** |
| Probability of finishing | low | **high** |

**Recommendation: build the one-night version. Keep the five acts as `docs/` and
pull Act III's coat scene, or Act IV's reconstruction puzzle, into the next game.**

There is a version of the future where you have shipped this and the player who
finished it asks for more. That is the best outcome available and you get there
by finishing, not by planning.

---

## Related

- [`prologue.md`](prologue.md) — the twelve minutes to build first
- [`plot.md`](plot.md) — the full plot; the cut version is a subset of it
- [`tech-stack.md`](tech-stack.md) — the perf budget for a 6,000-triangle game
- [`distribution.md`](distribution.md) — publishing when it exists
- [`art-direction.md`](art-direction.md) — the model pipeline