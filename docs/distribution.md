# Distribution — where this game actually gets played

> **The short answer: itch.io, free, forever.**
>
> There is no upfront cost, no fee, and no gatekeeping. You upload a build, write
> a page, and it is downloadable by anyone in the world that same hour.

---

## 1. Why itch.io and not Steam

| | **itch.io** | Steam |
| --- | --- | --- |
| **Upfront cost** | **$0** | **$100 per game**, recoupable after $1,000 in sales |
| **Revenue share** | **0–100%, your choice** | 30%, after the recoupable fee |
| **Hosting fee** | **Free** | N/A |
| **Approval** | **None. Instant.** | Review process, ~30 days, content guidelines |
| **Discoverability** | Good — an *indie horror* tag page with real traffic | Excellent, but only if you can pay the tax to be visible |
| **Audience fit** | **Exact.** This is where horror and experimental indie games are found and talked about | Broader, but flooded |
| **Pricing** | Free / pay-what-you-want / named price | Fixed |
| **Payment setup** | Free account, tax interview when you have earnings | $100 before you can do anything |

**itch.io's model is literally called Open Revenue Sharing** — you drag a slider
from 0% to 100% and choose what share they get. Set it to **0%** and they keep
nothing. It is one of the few genuinely generous terms in the industry, and they
exist because they want to be the place where small games live.

There is also no minimum, no approval queue, and no content review. A $0 game
with a slightly unsettling premise about a child and a cupboard is not going to
be a problem there. It is exactly the sort of thing that page is full of.

---

## 2. The plan

### Phase 1 — the demo (free, itch.io + GitHub Pages)

**When:** as soon as the prologue plays end to end.

| Target | Why |
| --- | --- |
| **itch.io, $0** | The canonical home. Full download, reviews, devlogs, comments. |
| **itch.io HTML5 build** | Play in-browser, no download at all. Instant share link. |
| **GitHub Pages** | Web build, hosted free from the repo you already have. A link you can put anywhere. |
| **GitHub repo** | Source, docs, and the whole design bible. Public. |

The demo is **the prologue plus one hour of Act I**, and it ends at the first
ghoul. That is a complete, self-contained horror experience that shows a stranger
the game's whole personality in fifteen minutes.

> The HTML5 build also means **you can playtest on a phone.** Not a compromise —
> for a fifteen-minute horror piece, that is how most of your audience will first
> encounter it.

### Phase 2 — the full game (paid, itch.io)

**When:** five acts complete. **4–6 hours.**

- Named price or pay-what-you-want. For a first commercial release, **$4–6 USD**
  is the honest band, or pay-what-you-want at a $0 minimum.
- Free demo on the same page, full game behind a link.
- Full write-up, screenshots, a trailer, and the devlog posts that came with it.

### Phase 3 — the audience

itch.io is the floor, not the ceiling. The thing that actually gets a game like
this in front of people:

| Where | What |
| --- | --- |
| **r/indiegaming, r/horrorgaming, r/horror** | Post the demo. These communities want exactly this and are ruthless about authenticity. Post the *design* — the calendar cosmology got people talking in our own notes, so lead with that. |
| **Newgrounds** | Free hosting, an audience of exactly the right age and sensibility, and a long history of horror and weird games being discovered there. |
| **Bluesky / Mastodon** | Devlogs, screenshots, the "day that doesn't exist" hook. The theme is genuinely shareable. |
| **YouTube / TikTok** | Short clips of the ghoul audio and the Act V death scene. This game has three viral moments and no budget to make trailers. |
| **Free Game Jams** | **[itch.io/jams](https://itch.io/jams) has a permanent jam every month.** Entering takes one build and one paragraph. It is the cheapest visibility available and it is how a huge share of itch games got their first players. |
| **Game Jolt** | Free alternative storefront with a smaller horror audience. Secondary. |

### Phase 4 — everything else

- **Direct download from the repo's Releases tab.** Always available, forever,
  even if itch goes down.
- **Portfolio / résumé.** A finished 3D horror game with a public repo is a
  stronger portfolio piece than almost anything else you could put there.
- **Godot showcase / community.** Godot's own community is friendly to published
  Godot games and it is a real audience.

---

## 3. The thing worth understanding

**You are not trying to make a lot of money from this.** And that is worth
saying plainly, because it changes every decision.

The realistic outcomes, honestly:

- Most itch horror games made by one person earn **$200–2,000** in the first year.
- A good one might do considerably better.
- **What is nearly guaranteed is a finished, playable, published game with a
  public repo and an audience.** That is worth more than the revenue, for a
  portfolio, for skills, and for the next project.

The plan above is designed for that outcome, which is why the demo is free,
the price is modest, and the design docs are public. **Anyone can read the
plot, argue with the cosmology, and go play it.** That is the strongest thing you
can put in front of a stranger.

Steam's $100 and 30% are not a barrier in absolute terms — but they buy a *store*
rather than a *community*, and for a $5 game with a niche premise, the community
is worth more than the storefront.

---

## 4. Publishing checklist

When the demo is ready:

- [ ] itch.io account, free
- [ ] Game page: title, cover image, screenshots, trailer (30–45 seconds)
- [ ] Tags, most important first: `horror`, `psychological horror`, `indie`,
      `atmospheric`, `story rich`, `first person`, `short`
- [ ] **Content warning** in the description. This game is about a forgotten
      child and one death. Say so, plainly and without drama. Players who are
      eleven are not the audience; do not pretend otherwise, and do not pretend
      it is harmless.
- [ ] Price: **$0** for the demo
- [ ] Linux + Windows builds, ~50 MB, zipped
- [ ] HTML5 build, free, no download
- [ ] GitHub repo public, docs included
- [ ] One honest devlog post: *what this is, what it is about, why February 30th*
- [ ] Post the demo to r/indiegaming and r/horrorgaming
- [ ] Enter the current itch.io jam — one paragraph, one build, done

---

## 5. Legal bits, handled early

Cheap to do now, painful later.

- **Everything is original work.** No scraped assets, no copyrighted characters,
  no ripped models. The whole pipeline generates assets from Python
  (`pipeline.md`), which means this is structurally guaranteed.
- **Fonts must be free** — SIL Open Font License or a comparable licence.
- **Audio is synthesised**, not sampled, specifically so there is no sample
  licensing question. See `art-direction.md` §10.
- **Write a content rating.** It is a PG/12 for theme, not for gore. State it
  yourself rather than letting a platform decide for you.
- **Your name on the page** — you own this, put your name on it.
- **A licence for the repo.** MIT for the code and docs; state clearly that the
  art and story are yours.

---

## Related

- [`plot.md`](plot.md) — the full plot
- [`prologue.md`](prologue.md) — the opening 12 minutes
- [`tech-stack.md`](tech-stack.md) — the builds we are uploading
- [`pipeline.md`](pipeline.md) — why every asset is provably original