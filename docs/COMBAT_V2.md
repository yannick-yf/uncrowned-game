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

Proposed, not settled — §7 holds the numbers.

Everyone in the fight acts once per round, in a fixed order. On their turn a
combatant may **move** up to a number of tiles and take **one action**:

| Action | What it does |
|---|---|
| **Strike** | A target on an adjacent tile takes fixed damage |
| **Guard** | Halves what you take until your next turn |
| **Wait** | Ends the turn. Sometimes the right move |

Movement is the game's own 8-way movement on the world grid, so diagonals count and a
tile is 2 m. Reach is one tile; a bow or a spear is a later reach, not a later system.

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

1. **The numbers.** Tiles moved per turn, the player's hit points, a wolf's hit
   points, what a strike takes, what guard saves. All of it is one small table, and it
   is the whole of balance — the first design's rule that *balance is editing one
   file* should survive.
2. **Move and act, or move or act?** Both are defensible. Move-and-act plays faster;
   move-or-act makes position a real cost.
3. **What ends a fight when nobody wins.** The player walks away, or everyone has
   fled. Does it end at a distance, after a number of rounds, or when no enemy can
   reach you?
4. **Where the fled go**, and whether they return.
5. **The tutorial fight.** Against what, and what it must teach in how many turns.

## 8. The one thing that may need drawing

**His traveller has no attack facing north or south.**

The first design ran a fight along the world's east-west axis for exactly this reason:
the camera never turns, his brother drew idle and walk in four directions, and the
eight frames we added under Yannick's exception are **left and right only**. On a grid,
two fighters can stand north and south of each other, and there is no frame for that.

Three answers, and it is a question about a picture, so it is Yannick's:

- **Accept it.** A fighter striking north is drawn striking left or right. Cheapest,
  and it will look wrong to anyone who notices.
- **Draw four more frames** — attack and guard, up and down — under the same exception
  that produced the eight, and delete them the day his brother draws his own.
- **Keep fights on one axis**, by placing combatants east and west when a fight starts.
  Free, but it throws away half of what a grid is for.

Nothing else in this design depends on the answer, so the task list can be written
before it is settled — but the fight cannot be *built* before it is.
