# The Prologue — Script

> **Twelve minutes. No enemies. No jumpscares. Everything after this depends on it.**

---

## Design intent

This prologue is doing four jobs and it has no monsters in it at all:

1. **Teach that you live in a small, ordinary house.** Four rooms. Everything
   within thirty seconds' walk of everything else. This is the last safe place in
   the game and the player must feel that before it is taken.
2. **Establish the real birthday** — the cake, the candles, the correct number —
   so the 30th has something to be a *alternative* to.
3. **Let the player choose to be a good kid.** You go and look at the cake. You go
   back to bed. You check the cupboard **after** midnight even though you are
   scared. Every choice in this prologue is a tiny act of politeness, and that is
   the protagonist's whole character established without a word of exposition.
4. **Make the fall feel earned.** You push *them* in. You choose to hide them from
   your mother. The game never absolves you and never accuses you.

---

## CAST — the small house

| Room | Purpose |
| --- | --- |
| **Your bedroom** | Bed, window, wardrobe. The cupboard is here. |
| **Hallway** | Three doors. Your mother's door is closed. |
| **Living room** | The cake. The table. One chair pulled out. |
| **Kitchen** | Cold. Lights off. Plates still in the dishwasher. |

It is a **small house.** Four rooms, one floor. This is deliberate and it is a
performance decision as much as a story one — see `tech-stack.md` §7.

---

## THE SCRIPT

### BEAT 0 — Character select

Black screen. A name field, unused.

```
        ┌─────────┐    ┌─────────┐
        │  BOY    │    │  GIRL   │
        └─────────┘    └─────────┘
```

One stylised child, near-silhouette, in a room with slightly too much light.
Pick. Fade to black. Fade up.

> You are not told what this means. It becomes obvious in about four minutes.

---

### BEAT 1 — 11:48 PM

You wake up. First-person, lying down. The camera is at pillow height.

**The room is lit by a streetlight through the window** — cold blue, and it is
the only light source in the game for the first three minutes. It shifts
slightly as if a car is passing outside. It never fully goes away.

A digital clock on the nightstand reads **11:48**.

Sitting up takes one keypress. The player does this within two seconds of
starting. Everyone does.

**No music. No ambience yet.** Room tone only — a house at night. A fridge
somewhere. Something settling.

---

### BEAT 2 — the living room

You walk out. The hallway is short enough to cross in four seconds.

The **living room** light is off. You switch it on — or the flashlight comes out,
whichever the player reaches for first.

**The cake is on the table.**

- One cake
- **Eleven candles**, unlit
- A name on it, in icing, spelt right
- One chair pulled out from the table
- One plate. One fork. One glass.
- It is nobody's birthday but yours

The music box motif starts here — the real one, in tune, at full tempo, playing
your birthday song. It is the only genuinely warm sound in the game.

The player is given about **thirty seconds** with no objective. They will
photograph it. They will walk around the room. Let them.

**Nothing happens.** This is the calm.

---

### BEAT 3 — back to bed

The clock reads **11:52**.

You go back. Under the covers. The camera returns to pillow height and the
streetlight is doing its slow shift across the ceiling.

This beat exists so the player **chooses** to be here for midnight instead of
being placed here.

---

### BEAT 4 — 11:59

The clock changes.

The music box **stops mid-bar.**

**Total silence for four seconds.** Not a scare — a gap. The player learns what
the game sounds like when it isn't playing.

Then, from the wardrobe:

*shff. shff. shff.*

Rustling. Something being moved by someone who does not have much room.

Then — **three knocks. A pause. Three knocks.**

That is the whole sound design of the inciting incident. Do not add anything to
it. It is the best sound in the game's budget and it costs about 200 bytes.

The HUD clock is visible if the player turns their head: **11:59**.

---

### BEAT 5 — the choice, and the wait

You can get up now. The player will not, immediately. They will wait.

**Ninety seconds of doing nothing.** The rustling continues, small and patient.

Add exactly one thing in this window, and only if the player turns to look at
the wardrobe directly: **the wardrobe door is not flush.** There is a gap of
about a centimetre, and it is moving very slightly, as if something on the other
side is breathing.

When the clock hits **12:00**, the music box comes back — **one semitone flat,
and slower.** It is now the 30th's theme. It never plays in tune again for the
rest of the game.

---

### BEAT 6 — the wardrobe opens

You get up. Cross the room. Open the door.

**They are sitting on the floor with their back against the wall, knees up.**
Small, even in a small room. They do not stand up. They do not threaten.

**They have your face.**

- Your cowlick
- The gap where your front right tooth used to be
- The same pyjamas you are wearing, except yours are buttoned and **theirs are
  inside out**
- A party hat two sizes too small
- A jacket with the sleeves cut at two different lengths

The fridge is still going in the kitchen. The streetlight is still moving.

They look up and say:

> *"It's my birthday too."*
>
> *"It's the thirtieth."*

---

### BEAT 7 — the dialogue box

The player gets a dialogue box with **choice options.** This is the only time in
the game it is used in this form, and that is deliberate — the rest of the game
is conversation, not menus.

Every option converges on the same beat. The point is to show the player trying
to be kind to something they do not understand.

| Prompt | Options | What all of them say |
| --- | --- | --- |
| **"There's no thirtieth."** | *"What do you mean?"* · *"Are you in my cupboard?"* · *"Are you OK?"* | they explain it the way a child explains something adult and slightly wrong |
| **"What do you mean?"** | *"It's my birthday."* · *"Don't you know the date?"* · *[say nothing]* | they say the date again, softer |
| **"Are you in my cupboard?"** | *"I live in here."* · *"It's warm in here."* · *"You have a bed."* | they look at the bed. they do not want it |
| **"Are you OK?"** | *[offer help]* · *"Do you want me to get mum?"* | this one has a sting — see below |

**On "Do you want me to get mum?":**

> *"No."*
>
> *"Please don't get her."*

Then, immediately:

> *"Please don't."*

**That is the first thing the game tells you about your mother**, and it is
delivered by a child in a cupboard. Do not explain it.

### The player forgets their birthday

At some point in this conversation the protagonist **stops having a birthday.**
It happens by omission. If the player asked about the cake, they remember. If they
did not, they do not.

The HUD birthday readout quietly disappears at some point during Beat 7 and the
player may not notice for minutes.

This is the theme stated once, plainly, and then never again.

---

### BEAT 8 — the door

**Your mother unlocks the door.**

The sound is a key in a lock, downstairs, and it is the most ordinary sound in
the game. Your mother does not appear. She never appears.

She calls up:

> *"Is everything alright? I thought I heard something."*

**Now you have about four seconds.**

You do not have time to explain a child in a wardrobe. You do not have time to
think. You do not have time to be sure.

The player has **one input**: reach out and **push them in.**

It is the worst available option and it is the only one. **There is no correct
choice here because there is no good one.** The game does not score it and does
not comment.

> *"Please don't,"* they say, one more time.

---

### BEAT 9 — the fall

You push. The wardrobe door swings.

**And behind it there is no back.** No wall, no shelving, no depth. The door opens
onto a hallway that goes much further back than a cupboard is wide.

The camera **does not cut away.** It goes in with them. Both of you fall, and the
door is at the end of the fall, getting smaller, and it closes.

The music box is playing. **It is one semitone flat.**

### Final shot of the prologue

Black. The music box, alone, for eight bars.

Then the title card, and the sound of a **crowd of children cheering, slightly
out of time** — the bad cheer, for the first time, very quietly, underneath the
title.

---

## Prologue technical notes

- **~12 minutes**, no fail states, no combat, nothing chasing the player
- **Four rooms, one floor** — see `tech-stack.md` §7 for why this is also the
  performance strategy
- **Two light sources total:** the streetlight (a single animated directional
  light) and the flashlight
- **The entire prologue is under 300 KB** of assets
- **The streetlight never turns off.** It is the last warm-neutral thing in the
  game and it is gone in Act I
- **Everything after Beat 9 must honour the framing.** No monster in this game
  is ever scary on its own — every one of them was forgotten. That is the promise
  the prologue makes, and the game spends the next five hours cashing.

---

## Related

- [`plot.md`](plot.md) — the full plot
- [`worlds.md`](worlds.md) — the five acts
- [`story.md`](story.md) — canon and cast
- [`distribution.md`](distribution.md) — where this gets published
- [`tech-stack.md`](tech-stack.md) — why it runs on anything