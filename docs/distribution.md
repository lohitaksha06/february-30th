# Distribution — where this game actually gets played

> **The short answer: itch.io, free, forever.**
>
> There is no upfront cost, no fee, and no gatekeeping. You upload a build, write
> a page, and it is downloadable by anyone in the world that same hour.

---

## 1. Two storefronts, one build

**itch.io and Google Play, shipping together.**

| | **itch.io** | **Google Play** | Steam | App Store |
| --- | --- | --- | --- | --- |
| Upfront cost | **$0** | **$25 once** (already paid) | $100/game | $99/**year** |
| Cut | **0–100%, your choice** | 15% above $1M/yr, else 0% | 30% | 30% |
| Approval | **None. Instant.** | 14-day closed test | ~30 days | Days–weeks |
| Who it reaches | PC indie horror players | **Phone players** | Everyone | iPhone players |
| Console | No | No | Yes | No |

Each covers a population the others don't:

- **itch.io** — where horror and experimental indie games actually get found.
  Free reviews, devlogs, HTML5-in-browser play, and a permanent monthly jam.
- **Google Play** — the only way this reaches a phone. A free demo here is the
  download driver for the paid version.

Together they cost **$0 ongoing** and cover desktop and mobile. Steam and the App
Store are Phase 3, only if the game earns something.

---

## 2. Why itch.io first anyway

Even with Play in the plan, **itch is the release that teaches you how to ship.**

Its Open Revenue Sharing model lets you set itch's cut anywhere from **0% to
100%** — you drag a slider. Set it to 0% and they keep nothing. There is no
listing fee, no approval queue, and no content review.

Two real costs, both tiny at this scale:

- **Processor fee ~$0.30 + 2.9%** per sale. On $5 that's about 45 cents. itch's own
  docs recommend a **$2 minimum price** so the flat fee doesn't dominate a sale.
- **Payouts need a tax interview** plus a PayPal or Payoneer account, and revenue
  has a **7-day hold**. Irrelevant until you're earning.

Steam is the wrong first release for a beginner: **$100 before you can do
anything**, a 30% cut, and a review process. Its only advantage is a broader
audience — which is worthless before the game has players.

---

## 3. The plan

### Phase 1 — the demo (free, everywhere)

**When:** as soon as the prologue plays end to end.

| Target | Why |
| --- | --- |
| **itch.io, $0** | The canonical home. Downloads, reviews, devlogs, comments. |
| **itch.io HTML5** | Play in-browser, no download. Instant share link. |
| **GitHub Pages** | Same web build, free, from the repo you already have. |
| **Google Play internal test** | Start the 14-day closed-test clock early. |
| **GitHub repo** | Source, docs, and the whole design bible. Public. |

The demo is **the prologue plus one hour of Act I**, ending at the first ghoul —
a complete, self-contained horror experience that shows a stranger the game's
whole personality in fifteen minutes.

The HTML5 build also means **playtesting on a phone** before the native build
exists. Not a compromise — for a fifteen-minute horror piece, that is how most
people first encounter it.

### Phase 2 — the full game

**When:** two acts complete. **45–60 minutes.**

| Platform | Price |
| --- | --- |
| **itch.io** (Win / Linux) | **$4–6**, or pay-what-you-want at $0 minimum |
| **Google Play** (Android) | **$4–6**, or Play's "Free" with an unlock, per `tech-stack.md` §8 |

Free demo on both. Full write-up, screenshots, trailer, and the devlog posts
that led here.

### Phase 3 — the audience

itch.io is the floor, not the ceiling. What actually gets a game like this in
front of people:

| Where | What |
| --- | --- |
| **itch.io jams** | **[itch.io/jams](https://itch.io/jams) has a permanent jam every month.** One build, one paragraph. Cheapest visibility that exists. |
| **r/indiegaming, r/horrorgaming** | Post the demo. These communities want exactly this and are ruthless about authenticity — post the *design*, lead with the calendar cosmology. |
| **Newgrounds** | Free hosting, exact audience, long history of weird horror being discovered here. |
| **Bluesky / Mastodon** | Devlogs and the "day that doesn't exist" hook. Genuinely shareable. |
| **YouTube / TikTok** | Short clips of the ghoul audio and the death. This game has three viral moments and no budget for trailers. |
| **Play store page** | The demo listing is the download driver. Write the description for a stranger scrolling, not for a player already hooked. |
| **Game Jolt** | Free alternative storefront, smaller horror audience. Secondary. |

### Phase 4 — everything else

- **Direct download from the repo's Releases tab.** Always available, even if
  itch goes down.
- **Portfolio / résumé.** A shipped 3D horror game on two storefronts with a
  public repo is a stronger portfolio piece than almost anything else.
- **Godot showcase / community.** Friendly to published Godot games, and a real
  audience.
- **Steam and App Store — only if it earns.** Both need money up front. Revisit
  honestly when the itch and Play numbers justify it.

---



---

## 4. The thing worth understanding

**You are not trying to make a lot of money from this.** And that is worth saying
plainly, because it changes every decision.

The realistic outcomes, honestly:

- Most itch horror games made by one or two people earn **$200–2,000** in the
  first year.
- A good one might do considerably better.
- **What is nearly guaranteed is a finished, playable, published game on two
  storefronts with a public repo and a real audience.** That is worth more than
  the revenue — for a portfolio, for skills, and for the next project.

The plan above is designed for that outcome, which is why the demo is free, the
price is modest, and the design docs are public. **Anyone can read the plot,
argue with the cosmology, and go play it.** That is the strongest thing you can
put in front of a stranger.

Steam's $100 and 30% are not a barrier in absolute terms — but they buy a *store*
rather than a *community*, and for a $5 game with a niche premise, the community
is worth more than the storefront.

---

## 5. Publishing checklist

### itch.io

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
- [ ] HTML5 build, free, no download, **"Mobile Friendly" ticked** (required for
      it to launch fullscreen on phones)
- [ ] GitHub repo public, docs included
- [ ] One honest devlog post: *what this is, what it is about, why February 30th*
- [ ] Post the demo to r/indiegaming and r/horrorgaming
- [ ] Enter the current itch.io jam — one paragraph, one build, done

### Google Play

- [ ] Signing key generated and **backed up somewhere you will find it** — lose
      this and you can never update the app again
- [ ] Store listing: icon, feature graphic, screenshots, short + full description
- [ ] **IARC questionnaire answered honestly.** Horror featuring the death of a
      child — expect a content descriptor, not a rejection. See
      `tech-stack.md` §8.5.
- [ ] Privacy policy URL — **required for Play**, even with no tracking or ads.
      A one-page GitHub Pages file is enough.
- [ ] Content rating questionnaire + target audience set to 13+
- [ ] `.aab` uploaded to **internal testing** first (instant, no tester minimum)
- [ ] Then closed testing: **12 testers, 14 days**. Start this the day the demo
      is ready — it is the whole schedule.
- [ ] Production, staged rollout at 10% → 50% → 100% (catches a crash before
      the whole Play audience hits it)

---

## 6. Legal bits, handled early

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
- [`tech-stack.md`](tech-stack.md) — §8 has the mobile input map and Play release
- [`pipeline.md`](pipeline.md) — why every asset is provably original
- [`scope.md`](scope.md) — why this is 45 minutes and not five acts