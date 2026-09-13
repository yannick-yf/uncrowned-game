# Uncrowned — v2 intent

> **Historical since 2026-09-13.** `SPECS.md` carries all of this — every passage dated
> 2026-09-13 and marked v2 — so this file is kept for the reasoning and is never
> authoritative, like everything in `docs/history/`.

> **What this is.** The settled design intent for v2, written 2026-09-13 before any
> document was changed. It is the input to the spec rewrite, not a replacement for
> `SPECS.md`. Once §§2–20 carry all of this, this file becomes history.
>
> **Read it before `SPECS.md`.** Several passages in the current spec contradict what
> is below, on purpose — they were correct for v1. §3 of this file names each one and
> says how to amend it.

---

## 1. The thesis

> **The game is not about weakening the king. It is about what the kingdom becomes.
> Breaking it and strengthening it are both real plays, both cost someone, and the
> ending is a reading of the state left behind — including the reading where the
> player is the one on the throne.**

That sentence belongs at the top of `SPECS.md`, above §1's pillars, as the document's
first line. Everything below is it, made mechanical.

---

## 2. What is wrong today, in one observation

Read §8's "Player pushes it by" column as a list of verbs: *burning, redirecting,
sabotage, turning workers, agitation, exposure, robbery, handing over records, taking
sides.* Nine verbs, all damage. `DeedRules.world_effects()` confirms it — **ten deeds,
every single effect negative.** `FactionRules.WORTH` confirms it again: **eleven ways
to serve the opposition, two to serve the crown**, and its own comment says *"there was
nothing pro-crown in the game before this."*

So the game can currently express breaking the kingdom in nine ways and building it up
in none. That is not a missing feature. It is a missing **sign** — and the store
already takes one: `WorldTick.push(quantity, amount)` is signed and clamped 0–100, and
`credit_from()` already carries the player's handprint along a coupling. The second
direction costs **no engine work**. It is rows in a table.

---

## 3. Three passages to amend FIRST

These are not edits to make in passing. Each is a passage a careful reader will believe
and refuse v2 on — correctly, because the document currently says so.

### 3.1 The thirteenth-quantity refusal

`SPECS.md` §8 ("Can the twelve quantities carry these five?") says:

> …adding a thirteenth, fourteenth and fifteenth quantity would be the wrong repair.

and `core/world_tick.gd` repeats it on `held_ground`.

**That refusal was about a different kind of number.** In context it refuses to put
*standing* — what each town, faction and person thinks of the player — into the tick
table, because standing is indexed by town, faction and person, while the twelve are
global readings of how the world is doing.

**Hardship (§4.1) is not standing.** It is a condition of a *place*: the same kind of
thing as grain price and town sentiment, which are already held per town in that same
file.

**Amend it:** state in §8 that the refusal covers standing-shaped numbers only and does
not extend to a reading about a place. Add a §20 decision-log row dated 2026-09-13 with
what was rejected and why, in the log's existing format.

### 3.2 Two models of a place changing hands

`FactionRules` already flips a contested zone when town sentiment crosses a hysteresis
band (`TURNS_TO_OPPOSITION = 30`, `TURNS_TO_CROWN = 70`). v2 adds a different model: one
decisive act sets the state and freezes it.

**Both are kept, written as the two paths §8's existing hard rule already names —
*drift may move the world; only the player may end it*:**

- **Drift path.** The sentiment band, unchanged. It moves ownership and writes no
  handprint.
- **Player path.** A decisive act sets the state directly, writes a handprint, stamps
  the tick it happened on, and holds for **2 in-game days (12 real minutes)**. During
  the hold the band cannot move it back.

### 3.3 `docs/V1.md` reads as the target

It opens *"SPECS.md answers what the game should be; this answers what it currently
is."* True and useful — but a fresh reader treats it as the shape of the game, and v2
changes several of its contents.

**Amend it:** one dated line at the top saying it records what was delivered on
2026-09-13 and is not the v2 target.

---

## 4. The decisions

All settled. They are not open for re-litigation in the rewrite session.

### 4.1 Hardship — a per-town reading, added beside the twelve

What an act costs the people who live in a place, held apart from what it costs the
crown. Raised by the crown's policies **and** by the player's disruptions, from either
direction. It **barely drifts** and moves sharply when acted on, so it always reads as
caused (§8's own warning: a world where everything drifts is a world where nothing
reads as caused).

Why it is the keystone: with one bidirectional axis you get a scoreboard with two ends
and the player picks an end. Hardship is the second axis — the one that makes both ends
cost something and neither correct.

### 4.2 The second direction, for all twelve

Fill the "player builds it by" direction in §8's table. Then the companion hard rule,
written beside the existing *every door that shuts opens another*:

> **Every act that moves the kingdom — in either direction — names who it costs, and
> that cost has a face.**

Not "steel +20": a valley that cannot drink its water, a garrison that goes hungry, a
family an NPC can name. A cost with no face is a scoreboard, and a scoreboard has one
correct way to play.

### 4.3 Four places, deeply — not six thinly

| Place | Supplies | Break it | Strengthen it |
|---|---|---|---|
| The Wide Acres | Food | Burn the stores; return the land to smallholders | Enforce the grants; get the convoys moving |
| The Cinderworks | Steel — and eats the Thornwood | Sabotage; turn the workers; cut the ore | Deliver labour; settle the wage dispute; feed it the forest |
| The Muster | Force | Expose the pay fraud; starve it; turn the captains | Pay it; feed it; hand it the deserters |
| The bank at Cairnwell | Money | Rob it; hand over the records | Restore confidence; bring it the crown's creditors |

These are already the four landmarks `SiteRules` reaches — kiln, granary, counting
house, muster rolls. No new landmark machinery.

**Wood gets no town of its own.** The Thornwood is terrain and the Cinderworks needs
fuel, so felling the forest is a *Cinderworks* consequence. The factory eating the
forest that saved the player's life becomes a mechanic instead of backstory, at the
cost of one belt of tile work rather than a whole zone.

Greyhold and Harrowgate are marked deferred, not cut.

### 4.4 One decisive change per place, two directions

Not two quests per place — **one**, whose outcome can land either way. This keeps
invariant 5 literally true (*a quest that can only start one way is a bug*) and halves
the writing. §3 already lists four ways into the Muster and four into the Cinderworks.

A decisive change is a **deed at a landmark**, not a quest object. There is no quest
store and v2 must not introduce one.

### 4.5 Binary states, with a ceiling

Two states per place: **crown-held** or **free**. A place is never pushed past its
starting state — you restore or you liberate; the Wide Acres never becomes better than
it has ever been. State this explicitly so nobody builds a third state by accident.

### 4.6 Reversible, frozen 2 in-game days

Per §3.2. One constant, defined once. The capital's instability reading (§4.8) uses the
same window.

### 4.7 Rank — derived, never gating

`FactionRules` already has four crown ranks from service (0 / 25 / 60 / 110) and its own
comment says *"the crown's last rank is the castle door."* That is the design. Write it
down in §11 and extend it; do not invent a new one.

- Rank is **derived** from crown standing, exactly as the escort is derived from army
  strength. Nothing stores "you are a Baron"; the title is what the court calls someone
  at that standing.
- It changes how you are greeted, what is offered, what is assumed, and what people
  will tell you.
- **It never gates** (invariant 4). At high standing the gate opens because the guard
  knows your face; at low standing you climb the wall. Same destination, different
  route.
- High crown standing never removes the other endings (invariant 7). A player loyal all
  game can still turn at the end.

The crown's two service acts (`i_gave_it_back`, `i_informed_the_crown`) become a real
list, in step with §4.2.

### 4.8 The capital — one state, two readings

Blackcairn cannot be taken and has one state. It carries two **derived** readings, both
legible from anywhere:

| Reading | Derived from | Shows as |
|---|---|---|
| Wealth | Crown treasury, steel output, grain supply | Scaffolding and new stone, or shuttered works and unfinished walls |
| Instability | How many places have flipped, how recently, and how far apart | Banners down, more guards on the wall, the gate shut in daylight |

Instability derived from **recency** is what makes it political rather than
statistical: four towns flipping in a week is a crisis, the same four over a season is
policy.

§8's rule *a change the player cannot perceive is identical to no change* applies: give
both readings a second channel — what people in the towns say about the capital.

### 4.9 Endings — no sixth one

`EndRules` already reads predicates over quantities, and `WorldTick.handprint` already
records how much of each is the player's doing. Taking the throne is a **reading**, not
a new ending:

| State at the end | Reads as |
|---|---|
| Deposed · high handprint · high crown standing | **The player takes the throne.** |
| Deposed · high handprint · low crown standing | The player made a vacancy someone else filled. |
| Deposed · low handprint | It fell over. Already forbidden — an ending needs a handprint. |

If the player can take the throne, the ending must show one thing of what they do with
it: the hardship figures in the towns they changed, the morning after.

### 4.10 The entrance sign is a voice, not a readout

Each place's entrance carries a sign or a speaker stating the place's status **in its
own words** — a claim the player can doubt and later find false. *"CornTown, proud to
provide food to our lovely king"* is exactly right because it is propaganda.

A status readout would flatten discovery and break §8's *push the ambient, pull the
attribution*. A place the player **strengthened** for the crown boasts differently from
one that was always loyal; a freed one says something careful if the patrols still ride
past.

### 4.11 Three phases of play — a description, never gates

Creation + fairy + tutorial · the organic world · confront the king. Written as the
shape a playthrough tends to take, the same way §3 now says routes are descriptions
rather than machinery. **Phase 3 is available in minute one**; that is Pillar 1 and it
is not negotiable.

### 4.12 The opening is reworked

The current opening points one way: the king destroyed your village, so go and kill
him. If serving the crown is a real play, the first ninety seconds must not close that
door. Do not soften what happened — change what *kind* of thing it was:

- **Policy, not malice.** Brindle was cleared because the Cinderworks needed the
  ground, not because the king hated it. Worse in some ways, and it leaves the door
  open — people in the game already serve a system that did this.
- **The fairy wants something; she does not name an enemy.** If she wants the forest to
  survive, that goal is compatible with very different plays, including making the
  works efficient enough to stop expanding.
- **One credible pro-works voice in the first hour,** who is not a fool. §5's king's
  argument exists; it is simply not audible at the start.

**The test:** after the tutorial, a player who wants to *serve* the crown can say what
their first step would be, without the game having offered it.

---

## 5. Two removals

### 5.1 Monsters — out of the whole map

Not just the forests. `BeastRules` (bears, spiders, bats) goes, and with it
`core/beast.gd`, `core/wildlife.gd`, `core/systems/wildlife_system.gd`,
`core/rules/beast_rules.gd`, `test/test_wildlife.gd`, and the beast entries in
`core/region.gd`, `core/world_state.gd`, `view/art.gd`, `view/main.gd`,
`content/text.*.json`, `test/test_journeys.gd`, `test/test_opening.gd`.

**What it costs, and why it survives:** §4's terrain table calls the wild *"slow,
unwatched, dangerous."* It becomes **slow and unwatched**. The road/wild decision keeps
its teeth because the road is *fast and watched* — the choice moves from "will I
survive it" to "will I be seen." MAP_SPEC's road ratio of 1.41 matters more, not less,
since time is now the only price of the wild.

Amend §4's terrain table and MAP_SPEC §6 accordingly. Add a §20 decision-log row and a
§21 cut-list row.

### 5.2 Road travellers — KEPT

Explicitly not removed, and worth a note in the docs so the question does not come back.

`TravelRules` puts six unnamed walkers on the King's Road at 2.4 tiles/sec. Its own
comment: *"Travellers are the road's postal service. They are furniture, not people —
no name, no home, no routine, no opinion of anybody."* **They are how rumour physically
travels between towns.** Before them a rumour spread as a uniform circle and reached
every town whichever way the player walked, so the road cost nothing and the wild
bought nothing.

Deleting them would take rumour propagation, the point of the Thornwood, and the reason
MAP_SPEC's road ratio exists.

**Add to §9:** travellers are never conversational, never named, never part of the
twenty-five. If they read as fake, that is a presentation problem for §13 — draw them
as traffic (a cart, a pair at a distance, someone leaving a gate), not as characters.

---

## 6. Order of work

§8 carries hardship, the second direction and the freeze window. §3, §4 and §11 all
read off those. Written in the wrong order, §3 gets written against the one-directional
model and is paid for twice.

| # | § | Change |
|---|---|---|
| 1 | §8 | Amend the thirteenth-quantity refusal (§3.1), then add hardship |
| 2 | §8 | The "builds it by" direction for all twelve; the cost-has-a-face rule |
| 3 | §8 | Reconcile the ownership band with the decisive change; define the 2-day freeze once |
| 4 | §3 | Retitle the spine: what each place is and what can be done to it. Columns: supplies · states · break · strengthen |
| 5 | §3 | The Deposed × handprint × crown-standing reading |
| 6 | §11 | The rank ladder, written down and extended; rank never gates |
| 7 | §4 | Two ground states for the four places; the capital's two readings; terrain table minus "dangerous" |
| 8 | §5 | The reworked opening (§4.12) |
| 9 | §9 | Place state and crown standing as conditions content may name; the traveller note |
| 10 | §13 | Two ground states × four places; capital states; how travellers are drawn; the v3 art note (§7) |
| 11 | §15 | The entrance sign as voice; the journal gains the kingdom's state |
| 12 | §2 | The three phases as a curve; the thesis line at the top of the document |
| 13 | §17–18 | Rewrite scope and roadmap for v2; the v1 seven-phase plan becomes finished work |
| 14 | §20–21 | Decision-log rows for every decision above, dated 2026-09-13, each with what was rejected and why. Cut-list row for the beasts |

---

## 7. After v2 — a note to write now, not a task

A real graphics jump means a different asset pack, and that is a wall rather than a
download:

- **One approved pack** (Ninja Adventure, CC0) — §13
- **A 340-colour locked palette** — §13, `content/palette.txt`
- **The asset validator**, invariant 10, enforced by test: off-palette colour or
  off-grid tile source fails the suite
- **One kit per place, one face each** — a new pack must cover all four places plus the
  capital

**v2 changes what the world means; v3 changes what it looks like.** Keep them apart —
an art swap during a systems rewrite makes every visual bug ambiguous between the two.

Add a short §13 note now saying the pack and palette are locked *for v2*, that a v3 art
pass is expected to replace both, and that the validator is what makes such a
replacement safe rather than what blocks it. Licence matters as much as looks: CC0 or a
licence that survives a Steam release, checked before anything is drawn against it.

---

## 8. Do not touch

v2 is a content and coupling change. The following are load-bearing and finished:

- **The `core/` / `view/` split and the event log.** A save is its event log; loading is
  replaying. v2 asks for no snapshot.
- **The twelve quantities as a set.** Hardship is added *beside* them as a per-place
  reading. The twelve are not renamed, renumbered or merged.
- **The handprint rule.** It is what makes taking the throne expressible. Used more,
  changed never.
- **Standing's three indexes** — town, faction, person. Crown standing is a faction and
  already exists. No new structure.
- **Quests as predicates over facts.** No quest store, now or in v2.
- **Determinism.** `sim.rng`, never global randomness. The freeze window is a tick stamp
  in the event log, so a replay lands identically.
- **All twelve invariants**, including no children, static typing, and no progression
  check gating an action.
- **Authoring order: French first, then English.** Every new string — entrance signs,
  the second direction's dialogue, hardship in the journal — is written FR then EN, and
  a test asserts both exist.
