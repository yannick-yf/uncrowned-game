# Combat — what the research found, and one decision for Yannick

Date: 2026-09-18, overnight. Six research agents, 553,000 tokens, no errors.
Written for Yannick. F group of [DEMO_TASKS.md](DEMO_TASKS.md).

**Read §1 first.** It is a contradiction with `SPECS.md` that only Yannick can settle,
and nothing visual is built until he does.

---

## 1. The decision: `SPECS.md` §10 against the in-place arena

> ### ✅ Ruled 2026-09-19: **in place, no cut.**
>
> Yannick chose option 1 below. `SPECS.md` §10 has been rewritten to match — the
> paragraph it replaced is quoted there, because the reversal is the point. `CLAUDE.md`'s
> standing exception now records the king's on-contact death as the remaining breach,
> and no longer warns against assuming the screen's shape: the shape is decided.
>
> Two more rulings came with it, in answer to *"how do I even reach a fight?"* —
> the first person the player can fight is **a neutral sparring partner near the start
> of the game**, put there so the fight can be played and tuned long before the quest
> exists; and **a fight begins from a dialogue option**, not from contact and not from
> an act at a site.
>
> What follows is the argument as it was put, kept unedited.


**What the spec says**, `docs/SPECS.md:2699-2703`:

> **Where it happens.** Never in the overworld. Any fight transitions to a dedicated
> combat screen, in the manner of *Pokémon* or a classic *Final Fantasy*.
> **The combat screen.** Side-on 2D.

**What Yannick said on 2026-09-18**, twice: first that the fight would be *« un combat
de style Street Fighter, un micro temps de chargement vers une arène »*, then, at the end
of the day, that his fear is *« de passer d'un format open world 3D à un système de
combat 2D »*, that we should *« trouver une solution élégante qui permet peut-être
d'avoir une arène de combat 3D »*, and that solving it is my job.

**That is a direction to explore, not a ruling that §10 is wrong.** `CLAUDE.md`: *if the
code and the spec disagree, one of them is wrong and Yannick decides which — do not
silently pick.* So this document recommends, and waits.

### What the research says, and it is one-sided

**The break he fears is the seam, not the camera.** Every game that removed the jar
removed the *cut*, and kept the camera move:

- Final Fantasy XII ran combat on the field map with no battle screen — Hiroyuki Ito:
  *"so players could seamlessly move from battle to exploration"*.
- Chrono Trigger, 1995: *"contact with enemies on a field map initiates a battle that
  occurs directly on the map rather than on a separate battle screen"* — and the camera
  still pans and the party still runs into formation.
- Yakuza 3's *"Seamless Battle is a streaming data-based loading-free system"* — and its
  battle camera drops and orbits every single time.
- Pokémon Legends: Arceus: *"you'll enter battle seamlessly, rather than switching into a
  battle-specific screen"* — and the camera repositions hard.

**We have nothing to load.** The fight would happen in the same baked region, with the
same simulation and the same sprites. So the entire cost of the transition is a camera
interpolation of about half a second.

### And one hard constraint I verified in our own code

**His traveller sprite has exactly eight animations**: `idle` and `walk` × `up`, `left`,
`right`, `down` — checked in `traveler_walk_frames.tres`. And `view/world3d.gd:610-617`
maps a direction to one of those four **by world axis**, not by camera:

```gdscript
if facing.y < 0: return "up"
if facing.x < 0: return "left"
```

`AZIMUTH_DEGREES` is `0.0` and the file says why: *"Fixed, because the camera's tilt and
azimuth are; billboards are lifted along it so their feet stay on the ground."*

**So the camera cannot orbit.** Turn it ninety degrees and a fighter facing world-east is
still drawn with the frame drawn to be seen from the south: every punch would read as a
character facing you being hit from nowhere. Doom needed eight drawn rotations for this;
Octopath Traveler II has a whole sprite pipeline for it. Asking his brother for eight
camera-relative facings, on top of the twenty-five faces he already owes, is not a small
ask — it is the largest art request in the project.

*(Two of the six agents disagreed on exactly this. The one that said "animate the
azimuth" was wrong, and the sprite file is why.)*

### The recommendation

**Fight in place, and never cut. Change two numbers, not three.**

| Camera value | Exploration | Fight |
|---|---|---|
| **Azimuth** | 0° | **0° — never touched** |
| Tilt | 48° | ~25–30°, nearly side-on |
| Ortho size | 24 m | the framing where his sprite lands on whole pixels |

Because the azimuth never turns, **the fight line is the world's east–west axis**, and
the two profiles it needs are exactly the `left` and `right` frames he has already drawn.
No new art. No orbit. No load.

**And the boundary can be people.** Yakuza's arena *"of bystanders forms once combat is
initiated"* — no geometry, no fog gate, no art, because the onlookers are the traveller
sprite every NPC already uses. For a game whose currency is standing, **who watched you
fight the king's man is a fact the simulation can keep.**

### The three ways this can go

1. **In place, as above.** Elegant, cheap, no new art — and it needs §10 rewritten.
2. **A separate 3D arena scene**, loaded. Keeps §10's "dedicated screen" and loses the
   seamlessness; still needs a place built for it, which is art nobody has.
3. **§10 as written — a 2D side-on screen.** The cheapest to reason about and the thing
   Yannick said he fears.

**I recommend 1, and I have not built its camera.**

---

## 2. What the research settled, and none of it is in doubt

These hold whichever way §1 goes, which is why F1 could be built tonight.

### The simulation is already a fighting game's clock

`core/sim.gd:42-43`: 60 steps a second, a world tick every 15. **One sim step is one
frame**, so every number in the fighting-game literature — quoted at 60fps for thirty
years — can be used unmodified. Combat is the first system in this codebase that runs on
the **step** rather than the tick, and `SimSystem.steps()` already exists for it.

### No Godot physics. None.

Snopek, who wrote rollback for Godot: *"The built-in physics engine in Godot is NOT
deterministic"* — which is why he replaced it rather than fixed it. A hit is an **integer
interval overlap** computed by a pure function, exactly the shape `MovementRules.step`
already has. This is the single change that would silently break every save, so it is a
rule and not a preference.

### Fixed-point arithmetic is not needed

Bruce Dawson's rule: same binary, same processor, and the only float hazards are an
altered FPU control word and uninitialised state. The hard cases are all *cross-build*.
This project's saves are already world-tagged and Godot-version-bound, so cross-platform
bit-equality was never a property being preserved. **Integers anyway**, because frame data
is integers by nature — but not because floats would have broken.

### The log gets input edges and nothing else

`MovementSystem`'s existing rule, applied: *"intent arrives as an event and is remembered
in the world store rather than re-sent every tick."* So the log holds `fight_began`, one
event per **change** of the input, and `fight_ended`. Positions, health, hitboxes and the
opponent's choices are all recomputed. GGPO draws the same line.

### The opponent's attacks must be *slow*

This is the finding that most changes the design, and it is counter to both of Yannick's
references. Measured human reaction is ~265 ms ≈ **16 frames**. A Street Fighter jab is 4
frames — it exists to be *guessed*, in a two-player game. Against one scripted opponent
the player must be able to *learn the tell and react*, which puts every one of the king's
attacks in the **18–28 frame** band with a visible anticipation.

**Street Fighter's feel, at a quarter of Street Fighter's speed.**

### What already exists and would be foolish to rebuild

`WorldState.hurt()` is documented as *"one path for everything that can hurt you — the
king today, a fight in Phase 4"*; the invulnerability window, death and the respawn at the
last fire are all one shared path already. `ContactRules` is the template for a pure
combat rule: a radius, a damage, seconds converted to steps.

---

## 3. What F1 is, and what it is not

**F1 is the fight with no screen**: two fighters, their health, what each is doing this
frame, an attack that lands or misses, a guard, and a result. It runs inside
`Sim.advance()` and is checked by replaying the same inputs.

It is deliberately **independent of §1's decision**. Whatever the fight looks like, these
are its rules.

### The shape

| Piece | What it is |
|---|---|
| `content/moves.json` | The frame data. Startup, active, recovery, damage, stun, reach — **integers, in steps** |
| `core/rules/combat_rules.gd` | Pure. Does this hitbox reach that hurtbox, what does a hit cost, when may a fighter act again |
| `core/fight.gd` | The store. Two fighters, their health, their position on the line, the move each is in and how far through it |
| `core/systems/combat_system.gd` | The only thing that writes it, on the step, from events |

### The world clock stops

`SPECS.md:1566-1569` already rules it: *"Combat runs beside the sim, and the world clock
stops during a fight. A fight is not advanced by world ticks and does not advance them."*
And `Sim.advance()` increments the tick unconditionally today.

Thirty real seconds of fighting is 1,800 steps — **two in-game hours** of grain drift,
rumours travelling and armies moving. So this is not optional. F1 adds a hold the sim
consults before it ticks, and nothing else about `advance()` changes.

---

## 4. Two things F1 does not fix, both recorded rather than forgotten

**The `dead` ending is structurally unreachable.** `EndRules.DEAD` is
`king_health <= 0`, but `_satisfied` also needs `handprint_of(...) >= 25.0`, and
`handprint_of` returns **0.0** for `king_health` (`core/rules/end_rules.gd:83-85`). So
killing the king would change nothing. `test_endings.gd` skips it on purpose and asserts
he has 1,000 HP. **Combat will have to change that rule**, and it is not F1's business.

**A fight is a dexterity gate, and this game's currency is not dexterity.** Four of the
five endings need no fighting and the fifth is killing him. If the fight demands
fighting-game execution it becomes the one wall in a game about power, knowledge and
access — and invariant 4 protects against progression checks, not against reflexes.
**The mitigation is that the king's frame data should read the player's power facts**, so
that preparation, not reflexes, is what makes him beatable. That is a design conversation,
and it belongs with Yannick.

---

## 5. What F1 delivered, and what playing it found

**Built and green on both worlds** (2026-09-19): `content/moves.json`,
`core/rules/combat_rules.gd`, `core/fight.gd`, `core/systems/combat_system.gd`,
`Sim.ticks_held`, and fourteen tests in `test/test_combat.gd` — **in the fast suite**,
because a fight costs nothing to simulate and is the thing that will be retuned most.

The fight is winnable, it ends, and it replays to the same millimetre on the same frame.

### The two bugs the tests did not catch, and playing it did

Both were found by writing a throwaway script that *plays* the fight with a competent
player and printing the result. Neither would have been found by a test, because both
tests and bugs came from the same head.

**1. The opponent never closed.** One blow's knockback put him past both reaches, and he
had no reason to walk. He stood there for ever and the fight never ended. **A fighter who
does not walk is a target, not an opponent.**

**2. The player locked him out of the fight entirely.** The player's blow leaves +2
frames of advantage — which is good design — and the opponent's swing needs 24 free
frames to start. A player who simply kept hitting never gave him 24, so he died without
raising his arm: five blows landed, nothing taken. **This is the genre's oldest bug, the
infinite**, and the fix is that being hit does not make him forget he was already
waiting.

After both: **five blows landed, two taken, eight health of ten left, nobody dead.** That
is a fight.

> The lesson worth keeping: the tests were green while the fight was broken, because a
> test asserts what you thought of. The five-line script that plays it found both in one
> run. **Every combat change gets played, not only tested.**

### And one bug in our own clock, caught by a test

`_end` cleared `Sim.ticks_held` in the middle of a step, while `on_step` sets it at the
top of the same step and the tick fires at the bottom — so the world ticked on the frame
the last blow landed. One writer now, once a step. The test checks the clock on **every
frame** of the fight rather than at the end, which is what caught it: frame 262.

### What is still open, in order

- **§1 is still Yannick's to settle.** No camera is built. Nothing above assumes one.
- **The fight may be too easy or too hard and nobody can tell yet**, because nobody has
  played it with their hands. The frame data is five rows of one JSON file, which is the
  point: tuning it is editing a row, not editing code.
- **§4's two open questions stand**, unchanged: the `dead` ending is unreachable, and a
  fight is a dexterity gate in a game whose currency is not dexterity.

---

## 6. And then I looked at it

§1 recommends a tilt of 25–30° with the azimuth untouched. That is a claim about a
picture, and this project has one rule about claims about pictures: *a night was spent
shipping things that drew wrong without erroring.* So the camera was tilted for one
frame — `UNCROWNED_LENS=tilt,size`, debug-gated, listed in `CLAUDE.md` — and the frames
were looked at.

**The framing works.** At 27° and 10 m the traveller is large, legible and lit, and
because the azimuth never moved he is drawn with the frames his brother has already made.
Nothing about it needs new art. At 22° it is better still for the figure and worse for
everything else.

**But the camera was the smaller half of the question.** Two frames say so:

- **In the works' quarter, the roofs swallow the fight.** Lower the camera and his
  buildings stand between it and the fighters. At 22° the player is behind a roof.
- **On open ground, nothing frames the fight at all.** Clean, readable, and completely
  empty: two figures on a field.

**Both are the same problem and it has one answer, already in §1.** Yakuza's ring of
bystanders: the fight needs open ground *and* a boundary, and the boundary is people. It
costs no geometry and no new art, because an onlooker is the traveller sprite every NPC
in this game already is. And for a game whose currency is standing, **who watched you
fight the king's man is a fact the simulation can keep.**

So the recommendation stands and gains a condition: **a fight happens on open ground,
ringed by whoever was near enough to watch.** Where the works' quarter has no such ground,
that is a thing to ask his brother for — a yard — and it is a far smaller ask than eight
facings.

---

## 7. F2 — the way in, and why F1 was not playable

**Built 2026-09-19**, the same day Yannick walked to the works looking for a fight and
found neither an opponent nor a way to start one. Three things were missing, and none of
them was the arithmetic:

| Missing | Now |
|---|---|
| Nothing submitted `fight_began` | `DialogueOption.fights` names an opponent; `DialogueSystem` **derives** the event and closes the conversation on the same step |
| No key was bound to a blow | **K** strikes, **O** guards, as *physical* keycodes so the pair sits in the same place on AZERTY and QWERTY. Left and right walk the line |
| Nobody to fight before the quest | **Bram**, survivor of Brindle, at the village crossroads — 30 tiles from where a new run wakes |

**A fight is something you say.** Not something you walk into: walking into somebody is
the king's on-contact death, which is the project's oldest debt and not the design. The
option goes through the closed set of intents (invariant 9), so the log holds the line
the player chose and replay recomputes the fight from it — which is why `fight_began` is
*derived* and not submitted. Submitting it would start two fights on a replayed log.

**He is repeatable on purpose.** The fight will be retuned many times, and a sparring
partner you can only fight once is no use after Tuesday.

**What F2 deliberately did not settle.** Bram's blows are real and so are his: losing to
him respawns the player at the clearing, because they have not rested yet. Whether
sparring should stop short of that is **F4's** question, which is where winning and
losing are handled, not F2's.

---

## 8. F3 — the lens drops, and the screen closes in

**Built 2026-09-19.** §6 found that the camera was the smaller half of the question and
that the *place* was the problem: in a built-up quarter the roofs swallow the fight, and
on open ground nothing frames it. The answer §6 proposed — Yakuza's ring of bystanders —
has a weakness this document should have said plainly: **it needs people**, and it fails
worst exactly where the second problem bites, on empty ground.

**Yannick's answer is better and it is now the baseline.** As the lens drops, the borders
of the screen darken. It needs nobody, costs no art and no geometry, works in a wood or
on a moor, and — his argument, and the strongest one — it generalises to whatever the
open world grows later, where a ring of townspeople never would. The onlookers survive as
a layer on top, where there really are people, which is also the more honest fiction.

### What is built

| | |
|---|---|
| **The lens** | 48° → 27°, tighter (`FIGHT_SIZE_M = 7`), eased over about a second. **The azimuth is never touched** |
| **The ring** | one `ColorRect` and six lines of shader, inside the HUD's layer so the map and the pause panel take it with them |
| **One eased number** | `view/main.gd` owns `_fight_lens`; the lens and the ring both read it, because two easings of one idea drift visibly |
| **The ground** | `Fight.origin_tiles` and `toward` turn the fight's line of millimetres into world tiles. The player's position is written from it every step |
| **The wall** | `CombatRules.inside_arena` — two tiles either side of the middle, four tiles across, which fits the frame with room |
| **One hand** | `MovementSystem` stands down while a fight is on, exactly as it does mid conversation |

**The wall is in the simulation and the darkness is in the window.** That split is the
whole of invariant 1 applied to this feature, and it is easy to get backwards: the
obvious build draws a dark ring and stops the player at its edge, which puts a rule in
the camera. A save here is the event log, so a boundary the window enforced is a boundary
a replay would not have.

### Two things it turned up

- **The opponent was drawn at his anchor.** An NPC stands where `content/places.json`
  puts him, which is where he was *before* squaring up — so he would have stood still on
  screen while the fight moved him. The frame now carries where he is this step.
- **`Escape` had stopped working during a fight**, because the fight's input branch
  returned before the key was read. A player must always be able to pause. It opens the
  pause menu, and that is not fleeing: **there is no fleeing in the demo** (Yannick,
  2026-09-19), so `fight_left` stays an outcome that nothing in the game produces.

---

## 9. F4 — one result, handed back, once

**Built 2026-09-19.** A fight now ends properly in both directions and says so to
whoever asked for it.

### Losing is not always dying, and that is data

`content/moves.json` gains an `opponents` block: what each one is worth, and whether he
**spares** you. Bram does — *« je m'arrête quand tu tombes »* is in his own dialogue, and
a sparring partner who sends you back to the fairies' clearing twelve seconds into the
game is not a sparring partner. Anyone not listed takes `_default`, which does not spare.

So: lose to Bram and you are left standing in the village on one health, no death on the
counter. Lose to the foreman and the checkpoint rule takes over exactly as it always has.
**Down is recorded before the damage is softened**, so losing to a man who spares you is
still losing.

### The result

`fight_ended` now carries `asked_by` — the dialogue intent that started it. Nothing in
the demo listens yet, because Bram's fight has no consequence beyond the bruises, but the
quest's fights (F6) turn on exactly this: a result nobody can be handed is a result that
gets applied by whoever notices, twice. It is derived **once**, because `_end` puts the
fight down before anything else and cannot run again — and that is a test, not a comment.

### Two things this cleaned up

**The loss was being inferred.** The first build read it back out of `WorldState`: full
health, a death on the counter, and still in hitstun. Each of those is true for other
reasons, and none of them held once an opponent could spare you. `Fight.player_felled` is
set by the blow that did it.

**A blow costs what the file says.** `WorldState.hurt` gave half a second of grace after
every wound. That is *contact's* rule — standing inside the king drains ten health in
three frames — and a fight's blows are already discrete, already cannot land twice, and
are already spaced by frame data. **Measured before and after, honestly: it was eating
none of Bram's blows**, whose swings are seventy-four frames apart against a
thirty-frame window. The first draft of this section claimed it had eaten a whole swing;
that was a bad measurement, which counted a killing blow as zero because death resets
health to full. The window is now contact's alone — a trap closed before F5 and F6 bring
a faster opponent, not a bug that was biting.

---

## 10. F5 — two blows, three answers, and four numbers that lied

**Built 2026-09-19.** F1 left him with one blow and the player with two buttons, which is
a drill. F5 makes it a fight.

| | |
|---|---|
| **His jab** | 18/3/12, reach 1300, 1 damage. −2 on hit, −6 on block: it neither locks you out nor is free |
| **His choice** | by distance, not by a coin or a timer. Inside 1550 mm he answers short; beyond it he must wind up the heavy one |
| **His heavy blow** | reach 1500 → **2000**, so he holds ground the player's 1300 cannot reach from |
| **His decision delay** | its own number (10), no longer the move's own startup |
| **Your backstep** | `I`. 4 startup, 10 of travel at twice walking speed, **invulnerable for exactly those ten**, 8 of recovery. One press, one step |

**The relationship is the design:** the guard answers the jab, the jab answers the
backstep, the backstep answers the swing. It works because human reaction is ~16 frames
(§2): react to the heavy blow and you are invulnerable on frame 20, before it lands on 24;
react to the short one and it lands on 18, two frames before you are safe.

### Four numbers that looked right and were not

Every one of these was found by *playing* the fight with a scripted opponent and counting,
and none of them would have failed a test written from the design.

1. **The heavy blow was thrown zero times.** He waited 24 frames and then wound up for 24
   more; the player crossed 1080 mm in the wait — the whole band in which he would have
   swung. Separating the delay from the startup is what let the move exist.
2. **Its reach was too short.** The band between the jab's threshold and his own was
   200 mm and both fighters crossed it in five frames.
3. **The jab was thrown zero times as well**, at reach 1100. He stands at the edge of his
   swing and the player at the edge of theirs, and the band sat below both of them.
4. **The backstep was not a dodge.** Travel alone had moved the player 360 mm when the
   heavy blow landed — nowhere near out of a blow reaching two metres. The dodging player
   lost at 1 health having landed nothing, while the frame data looked correct. A test
   asserting *"in time for the heavy one"* was passing on the arithmetic of when travel
   **begins**; the played fight is what said it meant nothing.

> The pattern across F1 and F5 is now hard to miss: **a test asserts what you thought of,
> and a played fight finds what you did not.** Both are cheap here — a fight is integers
> and no window — so both get run.

### Easier, on Yannick's call

He played it and asked for it easier (2026-09-19). Heavy blow: 24 → 28 frames of wind-up,
3 → 2 damage. Decision delay: 10 → 16. The jab stays at 18, the floor of §2's readable
band and the only thing keeping the backstep honest.

| Reaction | Guarding | Backstepping |
|---|---|---|
| 16 frames | won, 9 of 10 | won, 10 of 10 |
| 22 frames | won, 9 of 10 | won, 10 of 10 |
| 28 frames | won, 8 of 10 | won, 8 of 10 |
| 34 frames | won, 8 of 10 | won, 8 of 10 |

No losing case at any speed, where a 22-frame dodger used to lose at 1 health. Two other
numbers had to follow, and **both were caught by tests rather than by eye**: his reach
(2000 → 2200), because the band a heavy blow lives in must be wider than the ground the
player covers while he thinks; and the starting distance (2400 → 2800), because they must
begin outside the longest reach in the game. And the backstep's invulnerable frames grew
from 10 to 14, because slowing the heavy blow had silently broken the dodge — its last two
active frames were landing after the window shut.

---

## 11. Nobody has drawn a blow

**Asked by Yannick and checked rather than remembered, 2026-09-19.**
`prototypes/brindle_3d/prototype_3d/assets/traveler_walk_frames.tres` holds **eight**
animations: `idle` and `walk` × `up`, `down`, `left`, `right`. One sheet,
`traveler_walk_v2.png`. There is **no attack, no guard and no flinch**, anywhere in his
workshop.

So until F5 a strike, a guard and a backstep all looked like a person standing still, and
the 28 frames of wind-up this entire fight is built to be *read* were invisible. That is
most of why it felt hard with hands on it, and no amount of tuning the frame data fixes
it: the numbers were never the problem, the tell was missing.

**What is there now, and what it is not.** The figure he already drew is *moved*: drawn
back through the wind-up, further the closer the blow is to landing; thrust forward on the
frames it is out; eased back through the recovery; leaning away behind a guard.
`CombatRules.lunge_at` decides the timing — pure and tested, so *when* a blow reads as
coming is the fight's business and not the camera's — and the window decides how far
(0.3 tiles, about sixty centimetres).

It reads in motion and barely at all in a still, which is exactly what a displacement is.
**It is a placeholder and it prints a `DEBT` line in every run**, alongside the map's, so
it is counted and not forgotten. `test_his_brother_has_not_drawn_a_blow` fails the day the
sheet grows a ninth animation, so that nobody ships the placeholder over real work.

**What would replace it is three frames**: an attack, a guard, a flinch — `left` and
`right` only, because the camera never turns. It is in `docs/POUR_SLOSINIO.md` §8.

