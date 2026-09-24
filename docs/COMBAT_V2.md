# Combat, second design

Settled with Yannick on 2026-09-23, after he played the first one and said it was not
what he wanted. It replaces the fighting-game design recorded in `docs/COMBAT.md`,
which stays as the record of what was built and why it went.

**Status: a draft for Yannick.** §7 holds what is still open. Nothing is built.

Read `docs/PLAYER_MODEL.md` first — this design assumes it.

---

## 1. Why it changes

Not because the first one was broken. It was deterministic, replayable, frame-data
driven and it survived being played. It changes because it was **the wrong game**.

Yannick, 2026-09-23, and it is one idea rather than a list of complaints:

> **You can kill everyone.**

That was a founding idea of the project and the fighting-game design could not carry
it. A real-time duel with startup frames and hitstun is a design for *one prepared
fight against one prepared opponent*. It has no answer for a player who decides,
mid-conversation, to draw on three people in a yard — and no cheap answer for wolves,
either.

A turn-based system does. It is also, in Yannick's words, the simpler way to add
monsters and to write their behaviour.

## 2. What it is

Baldur's Gate's default mode, reduced to what this game needs.

| Decision | Settled |
|---|---|
| **Turn-based** | Yes. Not real-time, not real-time-with-pause |
| **Party** | None. The player fights alone |
| **Dice** | None. **Fixed damage.** A blow that lands takes a known number |
| **Where** | **On the world grid.** No separate screen, no arena, no cut |
| **Who can be killed** | Everyone |

**No dice is a bigger decision than it looks, and it is a good one.** It removes every
question about saving and re-rolling, it makes a fight something the player can reason
about rather than gamble on, and it makes the simulation deterministic *by
construction* rather than by seeding an RNG. A fight becomes a puzzle of position and
order, which is what the grid is for.

## 3. What survives of the first design

More than half, because most of the work was the picture and the picture was right.

| Survives | Why |
|---|---|
| The camera that drops and never turns (F3) | Yannick liked it, and the azimuth rule still holds |
| The darkened ring | **Kept, softened.** It says *you are in a fight*, not *you cannot leave* |
| Both healths on screen, named (H1) | Unchanged |
| The damage numbers, the hit flash, the sparks (H2) | A blow still has to read as a blow |
| The ending with a beat (H5) | Unchanged |
| The eight drawn frames | Attack, guard, flinch, wind-up — still what a fighter does |
| Entering and leaving a fight (F2, F4, F6) | The way in from dialogue and from the world stays |

| Goes | Why |
|---|---|
| `core/rules/combat_rules.gd`'s frame data | Startup, active, recovery, hitstun, blockstun, i-frames, pushbox — all of it is real-time vocabulary |
| `core/fight.gd`'s millimetre line | Positions become tiles on the world grid |
| `core/systems/combat_system.gd` at 60 steps/s | A turn-based fight advances on a decision, not on a clock |
| `content/moves.json`'s frame numbers | Replaced by a much smaller table: reach, damage, and what it costs |
| Most of `test_combat.gd`'s 1,199 lines | They assert frame counts |

**The arena boundary goes.** Yannick left this one to me and the reason is his own
design: he wants NPCs who run and hide when attacked. A boundary you cannot cross
contradicts that, and it contradicts this map's oldest rule — *a wall never closes a
road*. The ring stays as a vignette; nothing stops the player leaving, and nothing
stops an enemy fleeing.

## 4. A turn

Settled 2026-09-24, except the numbers, which §7 holds.

Everyone in the fight acts once per round, in a fixed order. On their turn a combatant
**moves and acts** — both, not one or the other (Yannick, 2026-09-24) — moving up to a
**capped** number of tiles and taking **one action**:

| Action | What it does |
|---|---|
| **Strike** | A target on an adjacent tile takes fixed damage |
| **Wait** | Ends the turn. Sometimes the right move |

**There is no guard** (Yannick, 2026-09-24): Baldur's Gate 3 has no block button, and
neither does this. Defence is position and initiative, not a held button — which is the
point of moving to a grid. Two consequences worth naming, because they are savings: the
guard frames drawn for the first design go unused, and **K5 needs six new frames rather
than eight**.

**A blow does not move you.** The one who takes it plays a recoil — the flinch frame,
which is drawn — and stays on their tile (Yannick, 2026-09-24). No knockback, no
pushbox, no shove. A hit that moved you would make position depend on the enemy's dice,
and there are no dice.

Movement is the game's own 8-way movement on the world grid, so diagonals count and a
tile is 2 m. Reach is one tile; a bow or a spear is a later reach, not a later system.

**The cap on movement is what makes position cost anything.** Moving and acting in the
same turn is the faster game to play, and it would make the grid meaningless if a
fighter could cross it — so the tiles per turn is not a comfort number, it is the whole
of what spacing means here. It belongs in the balance table with everything else.

**Order is deterministic and there is no initiative roll** — there are no dice. Whoever
started the fight acts first, then the others in a fixed order. A player who opens on
somebody gets the first blow, which is the right incentive: attacking from
conversation should be an advantage, and the price should be paid in standing rather
than in mechanics.

**The world clock is held for the duration**, as it already is (`Sim.ticks_held`). A
fight is not an hour of the day.

**Every turn is one event in the log.** Fewer events than the first design, not more —
a fight of twenty turns is twenty events, and the save stays the log.

## 5. Killing, fleeing, and what it costs

This is the half the first design had none of.

**Anybody can be attacked.** From the world or from a conversation. Nothing checks who
they are.

**A killed person is gone**, through the mechanism that already exists:
`OpeningRules.is_gone(who, facts)` — written for the fairy, reused for Tom when the
works reopened, and read from facts rather than kept in step by a flag. A death writes
a fact and the world stops drawing them.

**Wounded NPCs flee.** Below a threshold an NPC spends its turn moving away, and
leaving the fight's reach takes it out of the fight. Yannick's own example: attack the
Cinderworks' people and they run and hide somewhere. What happens to a person who fled
— whether they come back, and where they are found — is §7.

**The price is standing, and only standing.** Killing in a town moves that town's
number, by the rule in `PLAYER_MODEL.md` §3: it counts if it was witnessed. In v1 that
changes what people say to you and nothing else — **no hostile watch, decided
2026-09-23**. A town that hates you talks to you differently; it does not hunt you.

**What the dead leave behind** is the natural source for the player's richesse, and
the two designs meet here: a body has the gold it carried. That is also why killing is
worth designing carefully rather than forbidding — it pays, and it costs about −80 of
a town's regard when it was murder (`PLAYER_MODEL.md` §3). The player weighs one
against the other, which is the whole point of letting them do it.

## 6. Monsters

Yannick, 2026-09-23: **in the forest, never in the towns.** Wolves on the road between
Brindle and the Cinderworks.

This is not decoration. It is the game's own thesis made playable — *the road against
the forest* — and it is what makes the demo's walk a journey rather than a corridor:

> Wake up. The tutorial fight. Walk toward the works, because that is the road that is
> plainly safe. Wolves on the way. Then the quest.

**The funnel is made of wolves, not of walls.** `PLAYER_MODEL.md` §8 settles that the
demo constrains the player without a gate in `core/`; this is how. Other roads are not
closed, they are simply where the wolves are.

A monster needs: hit points, one damage number, a reach, and one rule for what it does
on its turn. That is the whole of it, and it is why turn-based makes monsters cheap.

## 7. Open

### The numbers — first pass, 2026-09-24

All of balance is this table, which is the first design's rule kept.

| | Value | |
|---|---|---|
| **Tiles moved per turn** | **4** | 8 m. Everyone, v1 |
| Player hit points | **100 — a development value** | Deliberately a formality. See below |
| Opponent and monster hit points | 10 | Everyone, v1 |
| Damage of a strike | 5 | Everyone, v1 |
| Guard | — | There is none |

So a strike kills anything in two, and twenty land before the player falls.

**Four tiles, and it was measured rather than argued.** Ten was proposed and checked at
Yannick's request. A tile is 2 m and the fight camera shows 7 m of height — about **six
tiles across the screen** — so ten tiles is 20 m, three screen-widths in one turn:
everybody would reach everybody every turn and position would stop existing, which is
precisely what §4's cap exists to prevent. Baldur's Gate 3 gives 9 m a turn, four to
five tiles here. Settled at **4** on 2026-09-24.

**The player's 100 is a development value and Yannick says so plainly** — *"justement
pour que ça soit une formalité, c'est dans le cadre de mes tests et devs"* (2026-09-24).
It is written here rather than left as a silent default, because a number nobody
remembers choosing is a number that ships.

At 100 against 5 damage a wolf needs twenty blows, so **nothing in the demo can
threaten the player**, and the demo's wolves exist to make the road a journey. The
shipped number is still to settle — **30** gives six blows and is the recommendation —
and the moment it has to be settled is **S4**, when somebody who is not us plays it.

> Worth remembering while it stands: **`G` already makes the player unkillable** and
> says `[G] INVULNÉRABLE` on the HUD, so development never needed the balance bent. It
> is there if the 100 becomes tiresome.

### What ends a fight — settled 2026-09-24

**Somebody reaching 0 hit points**, or a scripted end for the fights that want one
(*"on verra ça plus tard"*). No round limit, no timer.

Two readings that rule needs, and neither is a new decision — they are what it means
once the rest of this design is true:

- **Fleeing takes you out of the fight**, so the general form is *one side has nobody
  left in it* — dead or gone. §5's wounded NPCs already leave this way.
- **It works for the player too.** §3 removed the boundary so the player can walk out,
  and a fight that only ends at 0 would otherwise follow them across the map. Getting
  out of reach and staying there is leaving, for everybody. Symmetry is the whole
  reason it needs no extra rule.

### Still open

1. **Where the fled go**, and whether they return.

## 8. The frames, and the exception grows

**His traveller has no attack facing north or south**, and on a grid two fighters stand
north and south of each other constantly. The first design ran fights along one axis
for exactly that reason.

**Settled 2026-09-24: we draw them.** Yannick was offered the cheap answer — a blow
thrown north drawn side-on, which costs nothing and which the flash, the sparks and the
damage number already half sell — and he refused it. His words: *"Ok pour huit images,
et même plus si nécessaire. On veut un rendu assez propre pour la demo v1."*

So the count is **six new, twelve in all** — it was eight until the guard was cut on
2026-09-24, and the two guard frames already drawn go unused:

| | left | right | **up** | **down** |
|---|---|---|---|---|
| Wind-up | ✅ | ✅ | new | new |
| Attack | ✅ | ✅ | new | new |
| Flinch | ✅ | ✅ | new | new |
| ~~Guard~~ | *unused* | *unused* | — | — |

**Three actions rather than one, and the reason is Yannick's own playtest.** He played the first
version and said the animation was very slight; the cause was that the wind-up had no
drawing at all, and the wind-up is the half of a blow a player reads. Drawing an attack
facing north with a wind-up drawn facing west would break the telegraph in exactly the
facing the new frames exist for. The flinch follows for the same reason: being hit from
the north and recoiling to the left reads as a bug.

**"And more if necessary" is the standing instruction**, and the bar is *clean enough
for demo v1* rather than a count.

Three things keep this honest, and they are the same three that made the first eight an
acceptable exception rather than a breach — `CLAUDE.md`'s art rule holds unchanged:

- **No colour is invented.** His hand is copied to a new place, his outline sampled from
  his own line. The up and down walk frames he drew are the base.
- **His files are never touched.** `tools/draw_fight_frames.gd` reads `prototypes/`, and
  the combined sheet is ours.
- **`test_his_brother_has_not_drawn_a_blow` still fails** the day his own sheet grows an
  attack. On that day the tool, the sixteen frames and this exception are all deleted.

A back view is the hard one to draw and the easiest to get wrong, so **K5's check is a
photograph of a blow struck north**, not a count of files.
