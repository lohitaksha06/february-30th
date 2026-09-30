# World Map — Five Acts

> Status: draft v1, for review.

Each act is a **neighbourhood**, not a dungeon. Every one is somebody's real
worst birthday night, rebuilt accurately by a calendar that has no concept of
a bad outcome — it only knows it has to *render the day somewhere*.

That accuracy is the horror. Do not make these places look broken. Make them
look **right**, and then make one detail wrong.

---

## Act structure at a glance

```
                    ┌─────────────────────────────────┐
   BEDROOM          │  I   — 29TH STREET       0:00    │  "the party that ended"
   (prologue)  ───► │      find 3 party favours        │  tutorial
                    └──────────────┬──────────────────┘
                                   ▼
                    ┌─────────────────────────────────┐
                    │  II  — THE LONG WAY      0:40    │  "the drive that never arrived"
                    │      cross 3 carriageways        │  vehicle stealth
                    └──────────────┬──────────────────┘
                                   ▼
                    ┌─────────────────────────────────┐
                    │  III — LOST AND FOUND     1:30    │  "the kid nobody picked up"
                    │      identify the real child     │  social deduction
                    └──────────────┬──────────────────┘
                                   ▼
                    ┌─────────────────────────────────┐
                    │  IV  — THE AFTER         2:20    │  "the adults who forgot"
                    │      reconstruct the day        │  pure puzzle / reveal
                    └──────────────┬──────────────────┘
                                   ▼
                    ┌─────────────────────────────────┐
                    │  V   — THE 30TH          3:10    │  "the party, at full size"
                    │      the offer. 3 endings.       │  conversation, no gameplay
                    └─────────────────────────────────┘
```

Total target: **4–6 hours.** No procedural generation, no replay value, no
difficulty modes. It is a short story that happens to be playable.

---

## ACT I — 29TH STREET

**Purpose.** Tutorial. Establish the rules, the look, the Boy, and the one
truth the whole game rests on: *being noticed is the only danger.*

**Premise.** Your street. Every mailbox has your house number on it. The party
is over and nobody is going to acknowledge that it ever happened.

### Layout

A cul-de-sac of **six houses**, all identical, all numbered 29. The street is a
loop — walk far enough in any direction and you arrive back at your own gate,
and the party hats on the letterboxes have moved.

```
              ┌──────┐  ┌──────┐  ┌──────┐
              │  29  │  │  29  │  │  29  │      ← PARTY GUESTS
              └──────┘  └──────┘  └──────┘        (facing the street)
                  ╲        │        ╱
                   ╲       │       ╱
                    ┌─────┴─────┐
                    │    29     │  ← YOUR HOUSE (Boy is here)
                    └─────┬─────┘
                          ║
                     ┌────╨────┐
                     │ cul-de- │
                     │   sac   │  ← street loops back on itself
                     └─────────┘
```

### The Guests

**30 to 200 figures.** Adults, motionless, standing in gardens and on pavements,
all facing the same direction: the street.

They do not move. They do not turn. They do not pursue.

If you enter a Guest's **cone of vision** (a 70° fan, ~14 m) and remain there,
the **frost meter** fills. Leave the cone and it drains. Fill it and the act
resets to the gate.

**Design note:** the Guests are not enemies, and the game never says they are.
The player should be unsure whether they are being caught or *recognised*.

### Objective

Collect **three party favours** and give them to the Boy in the house:

1. A paper party hat (hat brim too small for any head)
2. A candle, still lit, in a puddle of melted wax
3. A balloon, deflating *upward*

### The scare

On taking the third favour, the game holds a frame for 600 ms. Cut to a wide
angle of the street. **Every Guest has turned to face the other way.** No
animation. They simply now face elsewhere. The music box motif drops 3 semitones.

### Exit

The hallway cupboard in your own house. Its door is nine feet tall and already
open.

### Teaches
move · crouch · sprint (noisy) · flashlight · interact · the frost rule · the Boy

---

## ACT II — THE LONG WAY

**Purpose.** Break comfort. Take the safe, familiar first act and stretch it into
something with no landmarks and no way to navigate. Introduce the *repeating
passage* — the game's first real "wrongness" structure.

**Premise.** The drive to a party that got cancelled. The 30th's roads do not
go anywhere; they go *forever*, and the exit ramp is on the map but the map is
wrong.

### Layout

A **2 km loop of two-lane highway**, no streetlights, rendered in four
interchange loops so the player builds a mental map and then watches it lie.

```
     ╭──────────╮         ╭──────────╮
     │  LOOP A  │◄───────►│  LOOP B  │      oncoming: 1 car / 20 s
     ╰────┬─────╯         ╰────┬─────╯
          │                    │
          ▼                    ▼
     ╭──────────╮         ╌──────────┐
     │  LOOP C  │         │  LOOP D  │      exit ramp: moves
     ╰──────────╯         └──────────┘
```

### Mechanic — Duck / Hide / Count

Headlights sweep the carriageway. You have three states:

- **Exposed** — in the road, in the light. Dead on arrival.
- **Below the line** — crouched behind the crash barrier or in a ditch. Safe.
- **Hidden** — inside a vehicle (boot, footwell, under the seat). Safe, and you
  can *count*: each hiding place is safe for exactly **three** passes, then the
  driver opens the door.

The count is the mechanic. The player must commit to a vehicle and then leave it
before they are found out.

### The Parties of the Road

Every car is full. Windows fogged from the inside. Everyone is facing forward.

**There is one passenger too many in the back seat.** No light, no movement, no
explanation. It is never explained. It is in every car.

### Objective

Cross **three carriageways** and reach the exit ramp. A physical map in the
inventory is the only guide, and its exit marker relocates when you look at it
directly.

### The scare

A scripted sequence. You are in the back of a car. The driver is your mother.
She does not look at you. She says *"we'll be there soon."* The radio plays
tomorrow's news, **backwards** — and one word comes through clearly, forward:
your name.

### Exit
An interchange ramp that folds back on itself and lands in a school car park.

### Teaches
the world can repeat · time pressure from something harmless · the Boy is
watching, not chasing

---

## ACT III — LOST AND FOUND

**Purpose.** The most interactive act. Turns the player from an observer into
someone making judgements about children. This is where the game is at its most
uncomfortable, and it gets there entirely through paperwork.

**Premise.** Every unclaimed thing in the 30th is here. A cloakroom of coats
nobody collected.

### Layout

**Act III-a — The corridor.** A school hallway, lockers on both sides. Every
locker is open. Every one is empty. Doors close behind you and do not reopen.

**Act III-b — The hall.** A large hall of **coat racks**, extending past the
fog. Twelve **Waiting Children** standing among them, all with your face, all
waiting to be collected by an adult who is not coming.

```
   ┌──────────────────────────────────────────────┐
   │  ▓  coat  coat  coat  coat  coat  coat  ▓    │
   │  ▓      coat  coat  coat  coat  coat     ▓   │
   │  ▓  coat  coat  coat  coat  coat  coat  ▓    │
   │        ┌───┐  ┌───┐  ┌───┐  ┌───┐            │
   │        │ 1 │  │ 2 │  │ 3 │  │ 4 │   children  │
   │        └───┘  └───┘  └───┘  └───┘            │
   │           all twelve have your face          │
   └──────────────────────────────────────────────┘
```

### Mechanic — Identify

Exactly **one** of the twelve belongs to this world and will help you. The other
eleven are the Boy, wearing other children's details.

You verify each child using the evidence you are carrying:

| Evidence | Found in | Checks |
| --- | --- | --- |
| A photograph | Act I | Who the child is standing next to |
| A bracelet | Act II | The bead count, the clasp |
| A birthday hat | Act II | The name written inside |
| A scar | Act III-a | Which knee, which side |

**Failure is not death.** Choosing wrong triggers a scream and resets the hall.
The sound is the same every time. The game does not explain what happens to the
child you chose. It does not show you. It just resets, and the room is quiet
again.

### The reveal

The coat that fits you is **your coat.** The name tag reads your name, spelled
correctly except for **one letter**. The Boy wants you to wear it. It fits.

Wearing it is optional. The game never asks you to.

### Exit
The Lost and Found bin at the back of the hall. It is the size of a bedroom.

### Teaches
look carefully at detail · the game rewards attention and punishes speed ·
the Boy is a collection, not a person

---

## ACT IV — THE AFTER

**Purpose.** The only act with no threat. Pure reconstruction. This is where the
game explains its own cosmology and earns the ending.

**Premise.** The adults' world. A waiting room that is never called.

### Layout

Six rooms in a non-euclidean loop, each holding one piece of a child's day:

1. **The Card** — a birthday card with the age scratched out and rewritten
2. **The Photo** — a print with one person cropped out by hand
3. **The Chart** — a growth chart with measurements that stop on a date
4. **The Ticket** — a cinema stub, unused, dated the 29th
5. **The Letter** — a note in an adult's handwriting that never got sent
6. **The Chair** — a small chair in an adult-sized waiting room

### Mechanic — Reconstruct

Order the six items into a timeline. This is a real puzzle with a real solution,
not a walking-simulator cutscene. Wrong ordering is allowed and simply shows
what the wrong version of the day looks like, which are all worse.

### The reveal

Solve it correctly and the answer is: **it is not one child's day.** Every item
belongs to a different child, and none of them know each other. The Boy is not
a person with a history. He is a **pile of other people's kids**, assembled by a
calendar that could only think of one shape to pour them into.

The game does not dramatise this. It puts the six items in a row on a table and
lets the player see the sizes do not match.

### The scare

On completing the puzzle, the room resolves into your own living room. The Boy
is at your table with your mother. Both of them say *happy birthday* — to
somebody who is not in the room yet.

Nothing else happens. The light does not change. The mother does not look
disturbed. That is the scare.

### Exit
A gurney that unrolls down a corridor, which turns a corner and is a page of a
calendar.

### Teaches
the cosmology · that the Boy is not a villain · that refusal is allowed

---

## ACT V — THE 30TH

**Purpose.** The ending. **No stealth. No chase. No mechanic.** It is a
conversation in a very large room, and then a choice.

### Layout

A cathedral-scale space built of **printed calendar pages**. Every wall is a
month. January through December, wrapping indefinitely. February is red.

The 30th is printed. It is still wet. You can see it being printed by a machine
you cannot find.

At the far end, the party — at full scale, and it is enormous, and it is for
you. There are four hundred children in it.

**Every one of them has your face.**

### The conversation

The Boy explains himself completely and makes the offer (see `story.md` §4). He
is calm, reasonable, and eleven years old.

The player can respond. The dialogue is short and the branches converge — the
player is choosing *how* to hear him, not *what* he says. Four lines, three
endings, one prompt.

### Lifelines

How many of the four objects the player carries changes the length and warmth of
the conversation, and unlocks the fourth ending line. It never changes the
choice.

### Endings

**A — Wear the coat.** You take his place. The cycle continues.
**B — Blow out the candles.** You erase the 30th, and your own 29th with it.
**C — Stay.** You take his hand and both of you go home.

### Final image

The credits roll over the opening shot from Act I — bedroom, cupboard, knocking.
The boy on the floor has your pyjamas. The camera does not open the door.

---

## World rules for every act

These apply to all five and should be enforced in code review, not just in prose:

1. **No combat.** There is no weapon and no damage. Every "fail" is a retry.
2. **No procedural generation.** Every act is hand-placed. This is a story.
3. **Every scare has a fair tell** — sound or visual, ≥ 700 ms of warning.
4. **Every world loops.** No act contains a straight line you walk down once.
5. **The Boy is never alone and never more than three steps from camera.**
6. **The music box motif plays in every act.** It loops at 1 semitone flat and
   slows 2% per loop. By Act V the player hears it before they see anything.
