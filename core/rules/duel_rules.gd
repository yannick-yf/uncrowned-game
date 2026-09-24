class_name DuelRules
extends RefCounted

## The rules of a fight, second design (K1, K2 — `docs/COMBAT_V2.md`).
##
## **Built beside the first design, which is still on disk and still runs.**
## `CombatRules`, `Fight` and `CombatSystem` are the real-time fighting game Yannick
## played and replaced; nothing here touches them, and the cut-over that deletes them
## is K6. Until then two fights exist and only one of them is wired to the player.
##
## **There are no dice.** Not a seeded roll, not a coin, nothing: damage is fixed, the
## order of play is fixed, and whoever started the fight acts first. Determinism here
## comes from there being nothing random, which is stronger than seeding — it removes
## every question about saving and re-rolling, and it makes a fight a puzzle of
## position and order rather than a gamble.
##
## **Tiles, not millimetres.** A fight happens on the world grid the rest of the game
## walks on, so a position is a `Vector2i` and a distance is 8-way — the Chebyshev
## distance, because the game's movement is 8-way and a diagonal is one step like any
## other. A tile is `BakeRules.METRES_PER_TILE`, read from there rather than written
## here: a fight that disagreed with the map about how big a tile is would be wrong in
## a way no test of the fight alone could see.
##
## **No Godot physics, ever**, for the same reason the first design had none: the save
## is the event log, so a fight that asked an `Area3D` whether a blow landed would
## break every save in the game, silently. A blow lands when two integers are one
## apart.
##
## Everything a fight can be balanced with is in `content/duel.json` and in no other
## file — the one rule worth keeping from the first design. The whole of tuning is
## editing one row of one table.

const PATH: String = "res://content/duel.json"

## The player, as a fighter id. NPCs use their cast id.
const PLAYER: StringName = &"player"

const STRIKE: StringName = &"strike"
const WAIT: StringName = &"wait"

## The eight neighbours, in a fixed order, so every search in this file breaks its
## ties the same way on every machine and in every replay.
const AROUND: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]

static var _table: Dictionary = {}
static var _fighters: Dictionary = {}


static func table() -> Dictionary:
	if _table.is_empty():
		_read()
	return _table


static func fighters() -> Dictionary:
	if _fighters.is_empty():
		_read()
	return _fighters


static func _read() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not (parsed is Dictionary):
		return
	var root: Dictionary = parsed as Dictionary
	_table = (root.get("table", {}) as Dictionary).duplicate()
	_fighters = (root.get("fighters", {}) as Dictionary).duplicate(true)


## **A test seam, and it is only that.** K2's check is that *editing the table alone*
## changes the outcome of a scripted fight, and the honest way to check it is to edit
## the table and play the same fight again. A suite that uses this calls `forget()` in
## `after_each`, because the table is static and a leaked override would quietly
## rebalance every fight that ran after it.
static func override(rows: Dictionary) -> void:
	if _table.is_empty():
		_read()
	for key: String in rows.keys():
		_table[key] = rows[key]


## Back to the file. Called by any suite that overrode a row.
static func forget() -> void:
	_table = {}
	_fighters = {}


static func number(key: String, fallback: int = 0) -> int:
	return int(table().get(key, fallback))


# ------------------------------------------------------------------ the table ---

static func tiles_per_turn() -> int:
	return number("tiles_per_turn", 4)


static func reach_tiles() -> int:
	return number("reach_tiles", 1)


static func strike_damage() -> int:
	return number("strike_damage", 5)


static func player_hp() -> int:
	return number("player_hp", 100)


static func leaves_at_tiles() -> int:
	return number("leaves_at_tiles", 3)


## How far off somebody is set down when a fight begins and they were not already
## beside you. In the table with everything else, because it decides whether the first
## turn is spent closing.
static func stand_off_tiles() -> int:
	return maxi(number("stand_off_tiles", 3), 1)


static func leaves_after_rounds() -> int:
	return maxi(number("leaves_after_rounds", 2), 1)


static func follows_tiles() -> int:
	return number("follows_tiles", 8)


static func flees_at_hp() -> int:
	return number("flees_at_hp", 5)


static func steps_per_tile() -> int:
	return maxi(number("steps_per_tile", 10), 1)


static func act_steps() -> int:
	return maxi(number("act_steps", 30), 1)


static func strike_at_step() -> int:
	return clampi(number("strike_at_step", 18), 0, act_steps())


static func hurt_steps() -> int:
	return number("hurt_steps", 20)


static func pause_steps() -> int:
	return maxi(number("pause_steps", 8), 0)


static func beat_steps() -> int:
	return maxi(number("beat_steps", 100), 0)


static func _about(who: StringName) -> Dictionary:
	var all: Dictionary = fighters()
	if all.has(String(who)):
		return all[String(who)] as Dictionary
	return all.get("_default", {}) as Dictionary


## How much health somebody brings to a fight. The player brings the table's own
## number rather than `WorldState`'s ten pips, because the two are different things:
## the pips are how much of the world you can take before you wake at the last fire,
## and this is how long a fight lasts. See `docs/COMBAT_V2.md` §7.
static func hp_of(who: StringName) -> int:
	if who == PLAYER:
		return player_hp()
	return int(_about(who).get("hp", 10))


## Whether they stop when you go down. A sparring partner does.
static func spares(who: StringName) -> bool:
	return bool(_about(who).get("spares", false))


static func is_down(hp: int) -> bool:
	return hp <= 0


# ------------------------------------------------------------------ the grid ---

## **8-way distance**, which is the only distance this fight knows. Moving diagonally
## costs what moving straight costs, because that is how the player walks.
static func apart(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Reach is one tile, diagonals included.
static func in_reach(a: Vector2i, b: Vector2i) -> bool:
	return a != b and apart(a, b) <= reach_tiles()


## A tile is two metres, read from the bake so the fight and the map cannot disagree.
static func metres_of(tiles: int) -> float:
	return float(tiles) * BakeRules.METRES_PER_TILE


## And the same in millimetres, which is the unit the window's blows already speak. A
## conversion and not a number of the fight's: it is here so that nothing in the fight
## itself has to write a figure down.
static func millimetres_of(tiles: int) -> int:
	return int(metres_of(tiles) * 1000.0)


## Where a fighter may stand at the end of its move, and what each tile costs it.
##
## A breadth-first walk of at most `cap` steps of 8-way movement, refusing his water,
## his rock and everybody else's tile. A diagonal is refused when both of the tiles it
## cuts between are shut, so nobody squeezes through the corner of two walls — the
## same rule `MovementRules` enforces by resolving each axis separately.
##
## Returns tile -> the number of tiles it took to get there, the starting tile at 0.
static func reachable(from: Vector2i, region: Region, cap: int, taken: Dictionary = {}) -> Dictionary:
	var cost: Dictionary = {from: 0}
	if cap <= 0 or region == null:
		return cost
	var edge: Array[Vector2i] = [from]
	for depth: int in cap:
		var next: Array[Vector2i] = []
		for tile: Vector2i in edge:
			for step: Vector2i in AROUND:
				var to: Vector2i = tile + step
				if cost.has(to) or taken.has(to):
					continue
				if not region.is_passable(to):
					continue
				if step.x != 0 and step.y != 0 \
						and not region.is_passable(Vector2i(to.x, tile.y)) \
						and not region.is_passable(Vector2i(tile.x, to.y)):
					continue
				cost[to] = depth + 1
				next.append(to)
		edge = next
		if edge.is_empty():
			break
	return cost


## The way from one tile to another inside a `reachable` field, as the tiles walked,
## the destination last and the starting tile left out.
##
## Walked backwards from the destination, always onto a neighbour one cheaper, taking
## the first in `AROUND`'s fixed order — so the same two tiles give the same path in
## every replay, on every machine.
static func path_to(from: Vector2i, to: Vector2i, cost: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not cost.has(to) or to == from:
		return out
	var at: Vector2i = to
	var guard: int = int(cost[to]) + 1
	while at != from and guard > 0:
		guard -= 1
		out.push_front(at)
		var want: int = int(cost[at]) - 1
		var stepped: bool = false
		for step: Vector2i in AROUND:
			var back: Vector2i = at + step
			if cost.has(back) and int(cost[back]) == want:
				at = back
				stepped = true
				break
		if not stepped:
			break
	return out


## Which way somebody standing on `from` is looking at `to`: one of the eight, and
## `Vector2i(0, 1)` when they are on the same tile.
static func facing_from(from: Vector2i, to: Vector2i) -> Vector2i:
	var away: Vector2i = to - from
	if away == Vector2i.ZERO:
		return Vector2i(0, 1)
	return Vector2i(signi(away.x), signi(away.y))


## Where an opponent is set down when a fight begins and they are not already beside
## you. Ours, not the design's: a fight begins because somebody is in front of you, and
## a debug photograph taken in a town where the man is three hundred tiles away would
## otherwise be a picture of nothing. The direction is the one they were already in, so
## nobody is spun round, and the search out from there is in `AROUND`'s fixed order.
static func stand_off(mine: Vector2i, theirs: Vector2i, region: Region, apart_tiles: int) -> Vector2i:
	var way: Vector2i = facing_from(mine, theirs)
	var wanted: Vector2i = mine + way * apart_tiles
	if region != null and region.is_passable(wanted) and wanted != mine:
		return wanted
	for ring: int in range(1, 6):
		for step: Vector2i in AROUND:
			var candidate: Vector2i = wanted + step * ring
			if candidate != mine and region != null and region.is_passable(candidate):
				return candidate
	return wanted


# ------------------------------------------------- what somebody does on a turn ---

## **One rule, and it is the whole of a monster's mind** (`docs/COMBAT_V2.md` §6: a
## monster needs hit points, a damage number, a reach, and one rule for its turn).
##
## Returns `{"to": Vector2i, "action": StringName, "target": StringName}`.
##
## Three branches, in order:
##
## 1. **Wounded, so it runs.** At or below `flees_at_hp` it spends its turn getting as far
##    from the nearest enemy as it can and does not strike. Yannick's own example: attack
##    the Cinderworks' people and they run and hide somewhere.
## 2. **It can reach somebody, so it strikes.** The tile it moves to is the cheapest one
##    from which a foe is in reach, ties broken by the fixed order below.
## 3. **It cannot, so it closes** — as near as it can get, and waits. It will not follow
##    past `follows_tiles` from where the fight began, which is the rule that makes
##    walking out of a fight possible at all: both sides move four tiles a turn, so a
##    chaser who never gives up can never be outrun.
static func decide(
	me: DuelFighter,
	foes: Array[DuelFighter],
	region: Region,
	began_at: Vector2i,
	taken: Dictionary = {},
) -> Dictionary:
	var standing: Dictionary = {"to": me.at, "action": WAIT, "target": &""}
	if foes.is_empty():
		return standing
	var cost: Dictionary = reachable(me.at, region, tiles_per_turn(), taken)
	var tiles: Array[Vector2i] = _ordered(cost)

	if me.hp <= flees_at_hp():
		var away: Vector2i = me.at
		var best_gap: int = _nearest(me.at, foes)
		for tile: Vector2i in tiles:
			var gap: int = _nearest(tile, foes)
			if gap > best_gap:
				best_gap = gap
				away = tile
		return {"to": away, "action": WAIT, "target": &""}

	var strike_from: Vector2i = me.at
	var victim: StringName = &""
	var found: bool = false
	for tile: Vector2i in tiles:
		for foe: DuelFighter in foes:
			if in_reach(tile, foe.at):
				strike_from = tile
				victim = foe.who
				found = true
				break
		if found:
			break
	if found:
		return {"to": strike_from, "action": STRIKE, "target": victim}

	var closer: Vector2i = me.at
	var best: int = _nearest(me.at, foes)
	for tile: Vector2i in tiles:
		if apart(tile, began_at) > follows_tiles():
			continue
		var gap: int = _nearest(tile, foes)
		if gap < best:
			best = gap
			closer = tile
	return {"to": closer, "action": WAIT, "target": &""}


## The tiles of a reachable field, cheapest first and then north to south and west to
## east — a fixed order, so every search above breaks its ties the same way twice.
static func _ordered(cost: Dictionary) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for key: Variant in cost.keys():
		tiles.append(key as Vector2i)
	tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var ca: int = int(cost[a])
		var cb: int = int(cost[b])
		if ca != cb:
			return ca < cb
		if a.y != b.y:
			return a.y < b.y
		return a.x < b.x)
	return tiles


static func _nearest(tile: Vector2i, foes: Array[DuelFighter]) -> int:
	var best: int = 1 << 20
	for foe: DuelFighter in foes:
		best = mini(best, apart(tile, foe.at))
	return best


## **Out of reach**, which is the first half of leaving. Asked at the end of a round
## rather than at the end of a turn, because stepping four tiles back is not leaving
## when the man in front of you has his own turn to close it again.
static func out_of_reach(me: DuelFighter, foes: Array[DuelFighter]) -> bool:
	if foes.is_empty():
		return false
	return _nearest(me.at, foes) > leaves_at_tiles()


## **And staying there is the other half** (`docs/COMBAT_V2.md` §7), which is the same
## rule for the player as for anybody: §3 took the boundary away so the player can walk
## out, and a fight that only ended at 0 would otherwise follow them across the map.
## Symmetry is the whole reason it needs no extra rule.
static func has_left(me: DuelFighter, foes: Array[DuelFighter]) -> bool:
	return out_of_reach(me, foes) and me.away_rounds >= leaves_after_rounds()


# ------------------------------------------------- the shape of a blow, for the view ---
#
# Pure, and here rather than in the window, for the reason the first design had the
# same functions: *when* a blow reads as coming is the fight's business, it has to be
# the same in both windows, and it can then be tested without drawing anything.

## Which of the drawn poses somebody is in, or `&""` for none of them — standing or
## walking, as the rest of the game draws people.
##
## `hurt` wins over everything: a fighter struck in the middle of their own blow is
## shown taking it. A blow does not move them (Yannick, 2026-09-24) — the recoil is a
## drawing and nothing else.
static func pose_of(hurt_left: int, acting: StringName, into: int) -> StringName:
	if hurt_left > 0:
		return &"hurt"
	if acting != STRIKE:
		return &""
	if into < strike_at_step():
		return &"ready"
	return &"attack"


## How far through its wind-up a blow is: 0.0 on the step it starts, 1.0 on the step it
## lands, and **−1.0 when nothing is winding up**, so the window can tell "no telegraph"
## from "a telegraph just begun" without a second question.
static func telegraph_at(acting: StringName, into: int) -> float:
	if acting != STRIKE or into >= strike_at_step():
		return -1.0
	return float(into) / float(maxi(strike_at_step() - 1, 1))


## **The shape of a blow**, −1 fully drawn back and +1 fully thrust forward, as a
## fraction of whatever the window thinks that is worth in tiles. The gather, then the
## release, then the arm coming back.
static func lunge_at(acting: StringName, into: int) -> float:
	if acting != STRIKE:
		return 0.0
	var wind: int = strike_at_step()
	if into < wind:
		return -float(into + 1) / float(maxi(wind, 1))
	var since: int = into - wind
	var recovery: int = maxi(act_steps() - wind, 1)
	return maxf(1.0 - float(since) / float(recovery), 0.0)


## And how low they are carried, the same fraction. A blow is a gather and a release:
## they sink through the wind-up and come up as it goes out, which is the part of a
## blow a person actually reads. Purely up and down, so his pixels are never stretched.
static func dip_at(acting: StringName, into: int) -> float:
	if acting != STRIKE:
		return 0.0
	if into < strike_at_step():
		return float(into + 1) / float(maxi(strike_at_step(), 1))
	return -0.4
