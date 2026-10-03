class_name WildSystem
extends SimSystem

## **Being seen by a pack is how a fight in the wood begins** (W2, R2).
##
## The only system that starts a duel without anybody saying a word. `DialogueSystem`
## begins one because the player chose a line and `ActSystem` because somebody stood in
## the way; this one begins one because a pack saw the player — in the cone in front of it
## (`DuelRules.sight_of`), or by being walked into — which is the whole difference between
## a road and a wood. Since R2 (2026-10-01) it also walks the packs about their ground and
## turns them, so the cone moves and a player can come up behind them unseen.
##
## **Nothing here gates anything** (`PLAYER_MODEL.md` §8, and invariant 4). A pack does
## not close a road and is not asked whether a quest is finished: it stands on its ground,
## and a player who wants that road fights or goes round. The demo's funnel is made of
## *where the wolves are* and of nothing else, which is why **W4 can take it out by
## editing one content file**.
##
## **Generic** (Yannick, 2026-10-01: *« on doit pouvoir l'activer sur un nouveau type
## d'ennemi sans réécrire la logique »*): a pack is any kind in `content/places.json`'s
## `wild` block, and how it sees and wanders is its row in `content/duel.json`. The towns'
## people are never in it.

## A pack takes one decision, or one tile of its walk, every PACE steps: 0.8 s, an amble
## beside the player's 2.5 tiles a second on his brother's map.
const PACE: int = 48
## How long a pack stands looking before it moves on, in paces: from REST_MIN to REST_MIN +
## REST_SPREAD - 1, so between about three and ten seconds.
const REST_MIN: int = 4
const REST_SPREAD: int = 9
## How many steps a tile of margin buys: the player walks a tile in ten steps at the most
## (six tiles a second, the 2D map's pace) and a pack one in PACE, so six is safely fewer
## than the two of them closing it.
const QUIET_STEPS_A_TILE: int = 6
## The eight ways a pack can look.
const WAYS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1)]


func steps() -> bool:
	return true


func ticks() -> bool:
	return false


func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type == &"ambush":
		_ambush(sim, event)
		return
	if event.type != &"duel_ended":
		return
	var wild := sim.store(&"wild") as Wild
	if wild == null or wild.fighting < 0:
		return
	# **Won means gone, and anything else means they are still there.** Walking away from
	# a pack leaves it on the road, which is the answer to "what happens if I run" that
	# costs no code: the road is still the dangerous one tomorrow.
	if String(event.data.get("how", "")) == "won":
		wild.cleared[wild.fighting] = true
	wild.fighting = -1


func on_step(sim: Sim, step: int) -> void:
	var wild := sim.store(&"wild") as Wild
	var world := sim.store(&"world") as WorldState
	var duel := sim.store(&"duel") as Duel
	if wild == null or world == null or duel == null:
		return
	# One fight at a time, and no ambush during somebody else's. **Nor a second one from
	# the pack just beaten** (the review of O13–O16): its `duel_ended` reaches this system a
	# step after the fight stops, and on that step it was still standing and set on the
	# player again, so every pack was fought twice. `fighting` is cleared by that event.
	if duel.on() or duel.settling > 0 or wild.fighting >= 0:
		return
	var region: Region = world.region()
	if region == null:
		return
	if step % PACE == 0:
		_wander(sim, wild, region)
	# Nor on a player somebody is calling over and holding still (O16), nor in the middle
	# of a conversation.
	var hail := sim.store(&"hail") as Hail
	if (hail != null and hail.holds_player()) or world.in_dialogue():
		return
	var here: Vector2i = world.player_tile()
	# Far from every pack, look again only when one could have come into sight: never
	# changes what is seen, only how often it is asked. A jump — a reload, a test setting
	# him down — asks at once.
	if step < wild.quiet_until and maxi(absi(here.x - wild.quiet_from.x), absi(here.y - wild.quiet_from.y)) <= 1:
		return
	var margin: int = 1 << 20
	for which: int in Wild.packs().size():
		if wild.cleared.has(which):
			continue
		if seen_by(wild, region, which, here):
			begin(sim, wild, region, which, wild.kind_of(which))
			return
		var lead: Vector2i = wild.now_at(region, which)
		var reach: int = int(DuelRules.sight_of(wild.kind_of(which))["tiles"]) + 4
		margin = mini(margin, maxi(absi(here.x - lead.x), absi(here.y - lead.y)) - reach)
	wild.quiet_from = here
	wild.quiet_until = step + clampi(margin * QUIET_STEPS_A_TILE, 0, PACE * 2)


## **Whether a pack sees the player**: in its cone, or walked into — on a tile one of its
## animals stands on. Beside one, from behind or the side, it does not: that is where a
## blade is brought to it unseen (R3). Public, so the window and the suite ask the very
## question the simulation does.
static func seen_by(wild: Wild, region: Region, which: int, here: Vector2i) -> bool:
	# **Never in the towns** (`docs/COMBAT_V2.md` §6, the review of R): a pack at a town's
	# edge does not see into it.
	if in_a_town(region, here):
		return false
	var kind: StringName = wild.kind_of(which)
	var sight: Dictionary = DuelRules.sight_of(kind)
	var lead: Vector2i = wild.now_at(region, which)
	# Asked every step, of every pack: one subtraction answers it for any pack further than
	# it sees and than its animals stand from its leader.
	if absi(here.x - lead.x) > int(sight["tiles"]) + 3 or absi(here.y - lead.y) > int(sight["tiles"]) + 3:
		return false
	if DuelRules.sees(lead, wild.looks(which), here, sight):
		return true
	for animal: Vector2i in wild.members(region, which):
		if animal == here:
			return true
	return false


## **The surprise attack** (R3, 2026-10-01): **K** outside a fight, from where no pack sees
## the player — an arrow at an animal two to six tiles off, or a blade at one beside him.
## The window asks `ambush_target` what K would do and submits it; this asks again, so a
## stale or forged key press attacks nothing, and the fight begins with the blow.
func _ambush(sim: Sim, event: SimEvent) -> void:
	var wild := sim.store(&"wild") as Wild
	var world := sim.store(&"world") as WorldState
	var duel := sim.store(&"duel") as Duel
	if wild == null or world == null or duel == null:
		return
	if duel.on() or duel.settling > 0 or wild.fighting >= 0:
		return
	# Not in the middle of a conversation, nor while somebody holds him to talk (the review
	# of R): the window does not offer it then, and the simulation does not take it.
	var hail := sim.store(&"hail") as Hail
	if world.in_dialogue() or (hail != null and hail.holds_player()):
		sim.derive(&"ambush_refused", {"pack": int(event.data.get("pack", -1)), "why": "busy"})
		return
	var region: Region = world.region()
	# **The animal he chose, with the weapon that reaches it** (N4) — or, asked by pack
	# alone, the best of them.
	var aim: Dictionary = {}
	for one: Dictionary in ambush_targets(wild, region, world.player_tile(), sim.store(&"inventory") as Inventory):
		if int(one["pack"]) != int(event.data.get("pack", -1)):
			continue
		if not event.data.has("animal") or int(one["animal"]) == int(event.data["animal"]):
			aim = one
			break
	if aim.is_empty():
		sim.derive(&"ambush_refused", {"pack": int(event.data.get("pack", -1))})
		return
	var which: int = int(aim["pack"])
	begin(sim, wild, region, which, DuelRules.PLAYER,
		{"seat": String(aim["seat"]), "weapon": String(aim["weapon"])})


## **What K would attack, outside a fight**, or nothing: an animal beside the player, struck
## with what he holds — his sword, or his fists — or else, with a bow on his back, the
## nearest animal in the bow's band. Never one whose pack sees him: that is already a fight.
## Pure, so the window's prompt and the simulation's answer are the same question.
static func ambush_target(wild: Wild, region: Region, here: Vector2i, inventory: Inventory) -> Dictionary:
	var all: Array[Dictionary] = ambush_targets(wild, region, here, inventory)
	return all[0] if not all.is_empty() else {}


## **Every animal K could surprise from here** (N4): each with the weapon that reaches it —
## his blade beside him, else his bow in its band — where it stands and what the blow would
## cost it, doubled. A blade's first, then the nearest arrow's, then by pack and animal, so
## the choice is always offered in the same order.
static func ambush_targets(wild: Wild, region: Region, here: Vector2i, inventory: Inventory) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if wild == null or region == null:
		return out
	var close: StringName = inventory.weapon_in_hand() if inventory != null else DuelRules.SWORD
	var bow: bool = inventory != null and inventory.has_bow()
	for which: int in Wild.packs().size():
		if wild.cleared.has(which) or seen_by(wild, region, which, here):
			continue
		var animals: Array[Vector2i] = wild.members(region, which)
		for one: int in animals.size():
			var weapon: StringName = &""
			if DuelRules.reaches(close, here, animals[one]):
				weapon = close
			elif bow and DuelRules.reaches(DuelRules.BOW, here, animals[one]):
				weapon = DuelRules.BOW
			if weapon == &"":
				continue
			var kind: StringName = wild.kind_of(which)
			out.append({"pack": which, "animal": one, "weapon": weapon, "kind": kind, "at": animals[one],
				"seat": kind if one == 0 else StringName("%s#%d" % [kind, one + 1]),
				"rank": DuelRules.apart(here, animals[one]) if weapon == DuelRules.BOW else -1,
				"damage": DuelRules.damage_with(weapon) * DuelRules.SURPRISE_TIMES})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["rank"]) != int(b["rank"]):
			return int(a["rank"]) < int(b["rank"])
		if int(a["pack"]) != int(b["pack"]):
			return int(a["pack"]) < int(b["pack"])
		return int(a["animal"]) < int(b["animal"]))
	return out


## **The fight a pack begins**, with every animal where it stands — not set down beside the
## player, since R2: a wolf that saw you from five tiles has five tiles to run. Derived
## rather than submitted, for `DialogueSystem`'s reason: the player's event was the step
## they took, and the fight is the world's answer to it. A replay recomputes it.
static func begin(sim: Sim, wild: Wild, region: Region, which: int, by: StringName,
		opening: Dictionary = {}) -> void:
	wild.fighting = which
	var pack: Array[String] = []
	var places: Array = []
	for animal: Vector2i in wild.members(region, which):
		pack.append(String(wild.kind_of(which)))
		places.append([animal.x, animal.y])
	var began: Dictionary = {"opponents": pack, "by": String(by), "asked_by": "the_wood",
		"places": places}
	if not opening.is_empty():
		began["opening"] = opening
	else:
		sim.derive(&"pack_spotted", {"pack": which})
	sim.derive(&"duel_began", began)


## **Each pack, one pace**: resting and looking about, or one tile along its walk to a spot
## of its own ground. The choices are the simulation's dice in the deterministic sense —
## a hash of the run's seed, the pack and the pace — so a replay walks them again, and no
## other system's draws are moved by them.
func _wander(sim: Sim, wild: Wild, region: Region) -> void:
	for which: int in Wild.packs().size():
		if wild.cleared.has(which):
			continue
		var roams: int = DuelRules.roams_of(wild.kind_of(which))
		if roams <= 0:
			continue
		var home: Vector2i = wild.at(region, which)
		var here: Vector2i = wild.now_at(region, which)
		var pace: int = sim.step / PACE
		if not wild.rest.has(which):
			wild.spot[which] = here
			wild.facing[which] = wild.looks(which)
			wild.goal[which] = here
			wild.rest[which] = REST_MIN + dice(sim, which, pace, 1) % REST_SPREAD
			continue
		if int(wild.rest[which]) > 0:
			wild.rest[which] = int(wild.rest[which]) - 1
			if int(wild.rest[which]) == 0:
				wild.goal[which] = _new_goal(sim, region, which, home, roams, pace)
			continue
		var goal: Vector2i = wild.goal[which] as Vector2i
		if here == goal:
			# Arrived: stand, and look one way or another.
			wild.facing[which] = WAYS[dice(sim, which, pace, 2) % WAYS.size()]
			wild.rest[which] = REST_MIN + dice(sim, which, pace, 3) % REST_SPREAD
			continue
		var next: Vector2i = _step_toward(region, here, goal)
		if next == here:
			wild.goal[which] = here
			continue
		wild.facing[which] = next - here
		wild.spot[which] = next


## A free tile of its ground, within `roams` of its anchor, out of every town, or where it
## is.
static func _new_goal(sim: Sim, region: Region, which: int, home: Vector2i, roams: int, pace: int) -> Vector2i:
	for attempt: int in 8:
		var span: int = roams * 2 + 1
		var tile: Vector2i = home + Vector2i(dice(sim, which, pace, 10 + attempt * 2) % span - roams,
			dice(sim, which, pace, 11 + attempt * 2) % span - roams)
		if walkable(region, tile):
			return tile
	return home


## **Ground a pack may stand on**: walkable, and in no town — the junction's pack stood a
## row south of the Muster and wandered into it a quarter of the time (the review of R).
static func walkable(region: Region, tile: Vector2i) -> bool:
	return region.is_passable(tile) and not in_a_town(region, tile)


static func in_a_town(region: Region, tile: Vector2i) -> bool:
	return region.zone_at(tile) != &""


## **Whether a pack's ground reaches here**: as far as it wanders and sees, and a little
## more for the animals round its leader — so nobody lies down to sleep where a pack will
## find him (the review of R: the save was written in the middle of the fight that woke
## him). Never in a town, where no pack sees.
static func threatens(wild: Wild, region: Region, tile: Vector2i) -> bool:
	if wild == null or region == null or in_a_town(region, tile):
		return false
	for which: int in Wild.packs().size():
		if wild.cleared.has(which):
			continue
		var kind: StringName = wild.kind_of(which)
		var reach: int = DuelRules.roams_of(kind) + int(DuelRules.sight_of(kind)["tiles"]) + 2
		var home: Vector2i = wild.at(region, which)
		if maxi(absi(tile.x - home.x), absi(tile.y - home.y)) <= reach:
			return true
	return false


## One tile toward `goal`, diagonals included, on ground that can be walked; where it is
## when nothing nearer can be.
static func _step_toward(region: Region, here: Vector2i, goal: Vector2i) -> Vector2i:
	var way := Vector2i(signi(goal.x - here.x), signi(goal.y - here.y))
	for step: Vector2i in [way, Vector2i(way.x, 0), Vector2i(0, way.y)]:
		if step != Vector2i.ZERO and walkable(region, here + step):
			return here + step
	return here


## **The pack's dice**: a number from the run's seed, the pack, the pace and what it is for.
## Not `sim.rng`, on purpose — a pack that drew from it every half-second would move every
## other draw in the game, and a replay of an old save would wander into new weather.
static func dice(sim: Sim, which: int, pace: int, salt: int) -> int:
	return DiceRules.mixed([sim.rng_seed, which, pace, salt])
