# The Cinderworks quest — the demo's spine, on paper

Date: 2026-09-18. Settled with Yannick. **No code has been written against it.**
This is A1 of [the demo plan](DEMO_PLAN.md), rewritten in the language of
[the simulation model](SIMULATION_MODEL.md).

One quest, one place, two outcomes, each with something good and something bad in it.

---

## 1. Where the works stands when the player arrives

| Value | | Reads as |
|---|---|---|
| **Allégeance** | 6 | above the threshold — it is still the king's works |
| **Richesse** | 4 | **below** the threshold — it is going badly |

**Loyal and poor.** Some furnaces are cold, people are idle, carts stand unloaded.
**The dispute is visible before anybody says a word**, which is how the player learns
there is one. No quest marker, no summons.

The ±3 rule lands exactly on the thresholds from here, with no special case:

| | Allégeance | Richesse | Reads as |
|---|---|---|---|
| **At the start** | 6 | 4 | loyal, going badly |
| **Tom's outcome** | 3 | 1 | **hostile and dead** |
| **Drissa's outcome** | 9 | 7 | **loyal and working** |

**A known limit, to settle by playing.** On Drissa's path richesse crosses its
threshold and allégeance does not — it goes from loyal to more loyal. Her outcome is
therefore quieter than Tom's, which is arguably right (one is a restoration, the other
a rupture) and is helped by the people who are missing afterwards. If it plays too
quietly, the fix is to start the works at allégeance 4 — banner down, openly
restless — so that both axes turn on both paths.

## 2. The two people

Neither is a villain. Both have a case, and the player is asked to weigh them.

### Tom — the unionist

He lived in the village **before there was a factory**. He works too many hours. He is
well paid and cannot use any of it. The air is filthy.

He has reached the point of wanting to hurt the works and bring it down. He does not
like what the crown does; for him the system itself is wrong, and **the destruction of
nature is not worth the price**. He needs the player to help him end it.

### Drissa — the worker, and she is **Sena** (settled 2026-09-19)

The cast already had her: `sena`, who lost a hand in furnace four six years ago, was paid
eleven days' wages, and was told by the works' own doctor that it was her fault. She
defends the place anyway, and that is a better argument for it than the draft below had.
The name Drissa is retired; everything under it is hers.


She was **brought to the village by force**. She works long hours and is glad of the
money. She thinks that without the resistance of a few, and by working with the
management, things can get better — and that for that to happen the extremists who
want to destroy the works have to be stopped. Their leader is Tom.

**Destruction is not the answer. What would people live on?** Helping her means
fighting Tom, and stopping him or killing him.

**Two people, not three.** Either of them can begin the quest, and each tells the
player about the other, so no single death makes the quest unreachable.

## 3. The production area is closed

The inhabited quarter is open: the player walks in, meets Tom and Drissa, hears both.
**The works itself is not.** A fence with one gate, and a guard on it. The furnaces
are out of reach.

**The quest is the key.** Choosing a side is what gets the player inside — Tom brings
them through a way he knows, Drissa vouches for them.

This is why the player cannot put out a furnace before any of this happens. It is not
gated by a flag: **it is simply unreachable**, which is a wall and a guard rather than
a progression check, and therefore obeys invariant 4 — the way past is force or being
let in, both of which are things the world already models.

## 4. The spine — the same shape on both sides

> **Get in** → **face whoever stands in the way** → **act**

| | With Tom | With Drissa |
|---|---|---|
| **Get in** | he brings you through | she vouches for you |
| **Face** | a foreman, or the gate's guard | **Tom**, come to stop the shift |
| **Act** | put out the furnaces still burning | relight the cold ones |

The fight is not an addition: it is the moment somebody puts themselves physically
between the player and the act.

## 5. What each outcome changes

### Tom's outcome — the works dies

| | |
|---|---|
| **Values** | allégeance 6 → 3, richesse 4 → 1 |
| **Signals** | every furnace cold, no fire, no smoke; **the pollution lifts off the map**; the king's banner down |
| **Routines** | nobody walks to the mine any more. People are at the riverside, in the wood, or **gone** |
| **Absence, not damage** | no carts, no woodpiles, no washing, no fires. **The chimneys stay, cold** — a chimney that vanishes means editing his scene; a cold one is free and reads better |
| **Said** | those who remain say what it cost them: the air is clean and there is no work |

### Drissa's outcome — the works runs, and Tom is gone

| | |
|---|---|
| **Values** | allégeance 6 → 9, richesse 4 → 7 |
| **Signals** | every furnace lit, the works loud; **the pollution stays** |
| **Routines** | the walk to the mine resumes, in numbers. But **Tom and his people are not there** — stopped, or dead |
| **Said** | those who remain know what happened to them, and say so. Management promises the air will get better; **the player cannot verify it, and it does not change** |

**This is where the two paths cost the same kind of thing for opposite reasons.**
Tom's way empties the town because there is no work. Drissa's way empties it because
the ones who resisted are gone. Same signal, same mechanism, no extra art — and
neither outcome is the right answer.

### The hole, left open on purpose

A workers' victory means they stop dying at the furnaces. **Richesse shows the wages
lost and nothing shows the lives saved.** It stays that way: the good is carried by
the routines and the lines — people alive, at the riverside instead of at the fire,
saying so. Not everything that matters has to be a number.

## 6. Combat

**A separate screen.** The quest runs in the world; when the fight starts there is a
short load into an arena, side-on, in the manner of Street Fighter. One opponent, one
person. The system can change later; this is where it starts.

**Combat is entirely ours** (Yannick, 2026-09-18) — none of it is asked of his
brother. **His traveller against a different traveller**: the figure he has already
drawn, which the player already is in the world, so the most-watched part of the demo
has no grey blocks in it.

## 7. What this asks of his brother

Small, and all of it reuses what he has:

1. **A fence and a gate** between the quarter and the production area, with his
   `cloture_2m` pieces, which he already places.
2. **Pollution, visible on the map** — his to design. In the model it is a **signal
   driven by production**, not a value: the works runs and it hangs over the place,
   the works stops and it lifts.
3. Nothing else. The furnaces already go cold, the chimneys stay, and abandonment is
   shown by removing things rather than by drawing ruined ones.

## 8. What this asks of us

The quest's start in conversation · the two people and their lines, French first ·
the closed gate and the two ways through it · the act at the furnaces, which is a row
in the table the game already has · the fight, from nothing · the two outcomes moving
two values · the signals bound to those values · the routines changing with them ·
and what people say afterwards.

## 9. Still open

1. **What ties this to the player's own grievance.** The demo opens on a destroyed
   village and a fairy. Tom lived in the works' village before the factory — he is not
   from Brindle. So why does this dispute belong to *this* player rather than being a
   good sidequest? **It needs an answer, and it is a writing question, not a systems
   one.**
2. **Whether the works starts at allégeance 6 or 4** — see §1. Decided by playing.
3. **What the guard on the gate does if the player simply attacks him**, before
   choosing a side.
4. **Names.** Tom and Drissa are Yannick's, and the rest of the cast's names have been
   ruled to need review.
