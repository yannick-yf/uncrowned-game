class_name DuelRules
extends RefCounted

## The rules of a fight, second design (K1, K2 — `docs/COMBAT_V2.md`).
##
## **The only fight there is.** The first design — `CombatRules`, `Fight` and
## `CombatSystem`, a real-time fighting game — was played, replaced, and deleted in K6
## (2026-09-26). `docs/COMBAT.md` records what it was.
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
## **The fairy's gift** (O10): a blow at range, once every few rounds.
const CAST: StringName = &"cast"

## **What a strike is thrown with** (T5). A strike is a strike; the weapon says how far
## it reaches and what it costs. O9's `AIM` — an arrow announced on a tile and landing a
## turn later — is gone: Yannick played it and ruled « je tire, ça tire ».
const SWORD: StringName = &"sword"
const BOW: StringName = &"bow"
## **Bare hands** (group E, 2026-10-01): what a player strikes with who has nothing in his
## weapon slot. A tile, like the sword, for `fists_damage`.
const FISTS: StringName = &"fists"
## **A surprise attack's blow counts this many times** (R3, Yannick 2026-10-01: « dégâts
## doublés sur la première attaque qui déclenche le combat »).
const SURPRISE_TIMES: int = 2
## **A bow of the player's own**, which Wren gives as the bow drill begins (T5): a fact,
## so shooting is gated by having one and by nothing else (invariant 4).
const THE_BOW: StringName = &"you:the_bow"

## The eight neighbours, in a fixed order, so every search in this file breaks its
## ties the same way on every machine and in every replay.
const AROUND: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]

static var _table: Dictionary = {}
static var _fighters: Dictionary = {}
static var _drills: Dictionary = {}
static var _reinforcements: Dictionary = {}


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
	_drills = (root.get("drills", {}) as Dictionary).duplicate(true)
	_reinforcements = (root.get("reinforcements", {}) as Dictionary).duplicate(true)


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
	_drills = {}
	_reinforcements = {}
	_sights = {}


static func number(key: String, fallback: int = 0) -> int:
	return int(table().get(key, fallback))


# ------------------------------------------------------------------ the table ---

static func tiles_per_turn() -> int:
	return number("tiles_per_turn", 4)


static func reach_tiles() -> int:
	return number("reach_tiles", 1)


static func strike_damage() -> int:
	return number("strike_damage", 5)


## Kept only so that a table still carrying `player_hp` is read rather than ignored;
## nothing seats the player with it any more. It goes with the row.
static func player_hp() -> int:
	return number("player_hp", WorldState.MAX_HP)


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


## **Zero, so nobody flees** (Yannick, 2026-09-24). The row is gone from the table and
## this default is what the absence means. It was five, and against ten points and five
## damage that made everything run after exactly one hit — Bram included, who is the
## tutorial. A wounded man running and hiding is still wanted; it is deferred until
## there is a state between healthy and dead, which fifteen points leaves room for.
static func flees_at_hp() -> int:
	return number("flees_at_hp", 0)


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


## **The kind, with the seat taken off.** A fight may hold three wolves and they have
## to be three *different* fighters — `wolf`, `wolf#2`, `wolf#3` — or striking one of
## them means striking whichever the list hands back first, which is how a player spent
## seventeen blows on a corpse while the second wolf stood untouched (found 2026-09-25).
##
## The convention is Godot's own for node names, and it stays inside the fight: the
## table, the window and the standing all read the kind.
static func kind_of(who: StringName) -> StringName:
	return StringName(String(who).get_slice("#", 0))


## **The trade, with the placing taken off too** (T9): the cast's strangers are
## `gatekeeper@1`, `watchman@2` — one trade, placed several times — and the table speaks
## of the trade.
static func trade_of(who: StringName) -> StringName:
	return StringName(String(kind_of(who)).get_slice("@", 0))


static func _about(who: StringName) -> Dictionary:
	var all: Dictionary = fighters()
	var kind: String = String(kind_of(who))
	if all.has(kind):
		return all[kind] as Dictionary
	var trade: String = String(trade_of(who))
	if all.has(trade):
		return all[trade] as Dictionary
	return all.get("_default", {}) as Dictionary


## **What an enemy of this kind sees** (R2, 2026-10-01): `tiles` ahead of it, in a cone
## of `cone` degrees round the way it faces — Yannick: *« le joueur peut s'approcher par
## derrière ou par les côtés sans être repéré »*. A kind whose row says nothing sees only
## what touches it, which is how every pack behaved before. Any kind of enemy outside the
## towns takes this by a row in `content/duel.json`, with no logic of its own.
static func sight_of(who: StringName) -> Dictionary:
	# Asked every step for every pack (R2): read once a kind, until `forget`.
	if _sights.has(who):
		return _sights[who] as Dictionary
	var row: Dictionary = _about(who).get("sight", {}) as Dictionary
	var sight: Dictionary = {"tiles": float(row.get("tiles", 1.0)), "cone": float(row.get("cone", 360.0))}
	_sights[who] = sight
	return sight


static var _sights: Dictionary = {}


## How far from its own ground an enemy of this kind wanders, in tiles: 0 stands still.
static func roams_of(who: StringName) -> int:
	return int(_about(who).get("roams", 0))


## **Whether something at `from`, facing `facing`, sees `to`** with this sight: near
## enough, and inside the cone. Pure, so the window draws the very cone the rules use.
static func sees(from: Vector2i, facing: Vector2i, to: Vector2i, sight: Dictionary) -> bool:
	var gap := Vector2(to - from)
	if gap.length() > float(sight.get("tiles", 1.0)) + 0.5:
		return false
	if gap == Vector2.ZERO or float(sight.get("cone", 360.0)) >= 360.0 or facing == Vector2i.ZERO:
		return true
	var half: float = deg_to_rad(float(sight.get("cone", 360.0)) * 0.5)
	return absf(Vector2(facing).normalized().angle_to(gap.normalized())) <= half + 0.0001


## **A man and not a beast, though nobody the cast names** (T9): a works guard. Killing
## one is a killing, with its deed.
static func is_person(who: StringName) -> bool:
	return bool(_about(who).get("person", false))


## **Who answers an attack on somebody of this trade** (T9), as its row of
## `content/duel.json`'s `reinforcements`, or empty.
static func reinforcement(trade: StringName) -> Dictionary:
	if _table.is_empty():
		_read()
	return _reinforcements.get(String(trade), {}) as Dictionary


## **A free tile `apart` tiles from somebody, or further** (V1): searched ring by ring from
## `apart` outwards, each ring along its top and bottom rows and then its sides, so the
## same ground and the same fighters give the same tile in every replay — and **one that
## can be walked to from him** (the review of group V), never a tile beyond a wall.
static func free_around(region: Region, centre: Vector2i, apart_tiles: int, taken: Dictionary) -> Vector2i:
	if region == null:
		return centre
	var walk: Dictionary = reachable(centre, region, apart_tiles + 8)
	for ring: int in range(maxi(apart_tiles, 1), apart_tiles + 8):
		for x: int in range(-ring, ring + 1):
			for y: int in [-ring, ring]:
				var candidate := centre + Vector2i(x, y)
				if walk.has(candidate) and not taken.has(candidate):
					return candidate
		for y: int in range(-ring + 1, ring):
			for x: int in [-ring, ring]:
				var candidate := centre + Vector2i(x, y)
				if walk.has(candidate) and not taken.has(candidate):
					return candidate
	return free_near(region, centre, taken)


## **Where somebody is set down to fight you** (the review of group V, 2026-09-30): a
## stride off on the side they are already on, as `stand_off` has it — unless a wall
## stands between, and then the nearest tile that far off that can be walked to from you.
## Tom was set down beyond the yard's wall, two tiles off through it, and waited for ever.
static func set_down(mine: Vector2i, theirs: Vector2i, region: Region, apart_tiles: int, taken: Dictionary) -> Vector2i:
	var wanted: Vector2i = stand_off(mine, theirs, region, apart_tiles)
	if region == null:
		return wanted
	if reachable(mine, region, apart_tiles + walk_back_budget(0)).has(wanted) and not taken.has(wanted):
		return wanted
	return step_back(mine, mine, region, apart_tiles, taken)


## **The free tile nearest a point**, searched ring by ring in `AROUND`'s fixed order, so
## the same ground and the same fighters give the same tile in every replay (T9).
static func free_near(region: Region, point: Vector2i, taken: Dictionary) -> Vector2i:
	if region == null:
		return point
	if region.is_passable(point) and not taken.has(point):
		return point
	for ring: int in range(1, 12):
		for step: Vector2i in AROUND:
			var candidate: Vector2i = point + step * ring
			if region.is_passable(candidate) and not taken.has(candidate):
				return candidate
	return point


## How much health somebody brings to a fight. **The player is not asked** — he brings
## `WorldState.player_hp`, the one bar, which `DuelSystem` reads when it seats him
## (Yannick, 2026-09-24). This answers for everybody else.
static func hp_of(who: StringName) -> int:
	return int(_about(who).get("hp", 15))


## **What is on them when they fall** (K3). Zero for anything that would make a fight
## worth starting for the money — the wood pays nothing, and neither does a man who
## offered to spar with you.
static func purse_of(who: StringName) -> int:
	return int(_about(who).get("purse", 0))


## **A drill of the tutorial** (O8), as its row of `content/duel.json`, or empty.
static func drill(id: StringName) -> Dictionary:
	if _table.is_empty():
		_read()
	return _drills.get(String(id), {}) as Dictionary


static func drill_master(id: StringName) -> StringName:
	return StringName(String(drill(id).get("master", "")))


## How far the master walks off before the first turn — further than one turn can close
## and strike, so the first turn is a move.
static func drill_stand_off(id: StringName) -> int:
	return int(drill(id).get("stand_off", tiles_per_turn() + reach_tiles() + 1))


## What the master's blows cost in a drill.
static func drill_damage(id: StringName) -> int:
	return int(drill(id).get("damage", 1))


static func drill_goal(id: StringName) -> StringName:
	return StringName(String(drill(id).get("goal", "")))


static func drill_count(id: StringName) -> int:
	return int(drill(id).get("count", 1))


## Rounds without reaching the goal before the drill is failed.
static func drill_rounds(id: StringName) -> int:
	return int(drill(id).get("rounds", 1))


## Who acts first in a drill: its `first`, or its master (O9 — Bram teaches the bow and
## Wren shoots it).
static func drill_first(id: StringName) -> StringName:
	var first := StringName(String(drill(id).get("first", "")))
	return first if first != &"" else drill_master(id)


## **What somebody fights with** (O9): `sword` unless their row says otherwise. The
## player's is his turn's to say (T5), from what he holds.
static func weapon_of(who: StringName) -> StringName:
	return StringName(String(_about(who).get("weapon", "sword")))


static func bow_reach_tiles() -> int:
	return number("bow_reach_tiles", 6)


## **Never a neighbouring tile** (T5): the nearest a bow shoots, and half of what answers
## an archer — close on her.
static func bow_min_tiles() -> int:
	return maxi(number("bow_min_tiles", 2), 1)


static func bow_keeps_off_tiles() -> int:
	return number("bow_keeps_off_tiles", 3)


## What an arrow costs, under a sword's blow (T5).
static func bow_damage() -> int:
	return number("bow_damage", 3)


## **Whether a strike thrown with this weapon from `from` reaches `to`** (T5): a sword the
## next tile, diagonals included; a bow its band, never the next tile.
static func reaches(weapon: StringName, from: Vector2i, to: Vector2i) -> bool:
	if from == to:
		return false
	var gap: int = apart(from, to)
	if weapon == BOW:
		return gap >= bow_min_tiles() and gap <= bow_reach_tiles()
	return gap <= reach_tiles()


## **The tiles the player's turn buys** (group E): the table's, a tile less under two heavy
## pieces or more. Nobody else wears what they wear by choice.
static func player_tiles(inventory: Inventory) -> int:
	if inventory == null:
		return tiles_per_turn()
	return ItemRules.tiles_with(inventory.equipped, tiles_per_turn())


static func fists_damage() -> int:
	return number("fists_damage", 2)


## What a strike thrown with this weapon costs.
static func damage_with(weapon: StringName) -> int:
	if weapon == FISTS:
		return fists_damage()
	return bow_damage() if weapon == BOW else strike_damage()


## **What this fighter's strike costs** (V1): an arrow the bow's figure, a blow his own
## `damage` row where he has one — a king's guard strikes for ten — and the table's
## otherwise.
static func damage_of(who: StringName, weapon: StringName) -> int:
	if weapon == BOW:
		return bow_damage()
	if weapon == FISTS:
		return fists_damage()
	return int(_about(who).get("damage", strike_damage()))


## The furthest a weapon reaches, for the ring drawn round whoever holds it and for
## whether somebody has got away.
static func reach_with(weapon: StringName) -> int:
	return bow_reach_tiles() if weapon == BOW else reach_tiles()


static func spell_reach_tiles() -> int:
	return number("spell_reach_tiles", 3)


static func spell_damage() -> int:
	return number("spell_damage", 5)


static func spell_every_rounds() -> int:
	return number("spell_every_rounds", 2)


## Whether somebody who knows the spell can cast it now, at somebody standing there.
static func can_cast(me: DuelFighter, round_now: int, from: Vector2i, target_at: Vector2i) -> bool:
	return round_now >= me.ready_round and apart(from, target_at) <= spell_reach_tiles()




## Whether they are a sparring partner. **Not a mercy of their own since O1** — the
## mercy is the line's (`Duel.spar`): a spar line leaves you on one point, and the same
## man fought for real does not. Read only where a fight starts without a line, so a
## debug tool spars with Bram as the game's own line would.
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


## **Where a drill's master walks to before the first turn** (O8): the nearest tile he
## can walk to that is at least `apart` from the player — and when the ground allows
## none, the furthest he can reach. Searched, not aimed: a straight line away can end
## in a wall, and a tile beside the wall is a tile one turn can close.
##
## Ties go to the lowest cost, then the lowest row, then the lowest column, so the same
## ground gives the same tile on every machine and in every replay.
static func step_back(from: Vector2i, away_from: Vector2i, region: Region, apart_tiles: int,
		taken: Dictionary = {}) -> Vector2i:
	var cost: Dictionary = reachable(from, region, walk_back_budget(apart_tiles), taken)
	var best: Vector2i = from
	var best_far: int = apart(from, away_from)
	var best_cost: int = 0
	var found: bool = best_far >= apart_tiles
	for tile: Vector2i in cost.keys():
		var far: int = apart(tile, away_from)
		var spent: int = int(cost[tile])
		var better: bool = false
		if far >= apart_tiles:
			if not found:
				better = true
			else:
				better = spent < best_cost \
					or (spent == best_cost and (tile.y < best.y or (tile.y == best.y and tile.x < best.x)))
		elif not found:
			better = far > best_far or (far == best_far and spent < best_cost)
		if better:
			best = tile
			best_far = far
			best_cost = spent
			found = found or far >= apart_tiles
	return best


## How far a master may walk to get there: the distance and a little more, for the way
## round whatever stands behind him.
static func walk_back_budget(apart_tiles: int) -> int:
	return apart_tiles + 2


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
	if me.weapon == BOW:
		return _archer(me, foes, tiles)

	if me.hp <= flees_at_hp():
		var away: Vector2i = me.at
		var best_gap: int = _nearest(me.at, foes)
		for tile: Vector2i in tiles:
			var gap: int = _nearest(tile, foes)
			if gap > best_gap:
				best_gap = gap
				away = tile
		return {"to": away, "action": WAIT, "target": &""}

	# **It will not follow you past `follows_tiles` from where the fight began**, and
	# that is one rule over both of the branches below rather than only over the closing
	# one. Written the other way first, it capped the walk and not the chase — and a
	# chase *is* a walk that ends in a blow, so the man simply kept coming through the
	# striking branch and nobody could ever be outrun. Found by walking away from him
	# and reading the trace, which is what `tools/play_duel.gd` is for.
	var near: Array[Vector2i] = []
	for tile: Vector2i in tiles:
		if apart(tile, began_at) <= follows_tiles():
			near.append(tile)
	if near.is_empty():
		near.append(me.at)
	tiles = near

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
		var gap: int = _nearest(tile, foes)
		if gap < best:
			best = gap
			closer = tile
	return {"to": closer, "action": WAIT, "target": &""}


## **One rule for an archer** (O9, T5): stand where the nearest foe is between keeping off
## and her reach — staying put if she already does — and shoot him, the arrow landing on
## this act. When no tile she can walk to is in that band, the one nearest it.
static func _archer(me: DuelFighter, foes: Array[DuelFighter], tiles: Array[Vector2i]) -> Dictionary:
	var target: DuelFighter = foes[0]
	for foe: DuelFighter in foes:
		if apart(me.at, foe.at) < apart(me.at, target.at):
			target = foe
	var low: int = bow_keeps_off_tiles()
	var high: int = bow_reach_tiles()
	var best: Vector2i = me.at
	var best_off: int = 1 << 20
	for tile: Vector2i in tiles:
		var gap: int = apart(tile, target.at)
		var off: int = 0 if (gap >= low and gap <= high) else mini(absi(gap - low), absi(gap - high))
		if off < best_off:
			best_off = off
			best = tile
		if off == 0:
			break
	if not reaches(BOW, best, target.at):
		return {"to": best, "action": WAIT, "target": &""}
	return {"to": best, "action": STRIKE, "target": target.who}


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
	# **Reach-aware since the bow** (O9): an archer keeping off within her reach is
	# fighting, not leaving — and somebody inside an archer's reach has not got away.
	var mine: int = reach_with(me.weapon)
	for foe: DuelFighter in foes:
		var gap: int = apart(me.at, foe.at)
		if gap <= maxi(leaves_at_tiles(), maxi(mine, reach_with(foe.weapon))):
			return false
	return true


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
	# Drawing a bow is the wind-up like any strike: his brother drew no bow, and the cocked
	# arm is the honest nearest thing (O9).
	if acting != STRIKE and acting != CAST:
		return &""
	if into < strike_at_step():
		return &"ready"
	return &"attack"


## How far through its wind-up a blow is: 0.0 on the step it starts, 1.0 on the step it
## lands, and **−1.0 when nothing is winding up**, so the window can tell "no telegraph"
## from "a telegraph just begun" without a second question.
static func telegraph_at(acting: StringName, into: int) -> float:
	if (acting != STRIKE and acting != CAST) or into >= strike_at_step():
		return -1.0
	return float(into) / float(maxi(strike_at_step() - 1, 1))


## **The shape of a blow**, −1 fully drawn back and +1 fully thrust forward, as a
## fraction of whatever the window thinks that is worth in tiles. The gather, then the
## release, then the arm coming back.
static func lunge_at(acting: StringName, into: int) -> float:
	if acting != STRIKE and acting != CAST:
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
	if acting != STRIKE and acting != CAST:
		return 0.0
	if into < strike_at_step():
		return float(into + 1) / float(maxi(strike_at_step(), 1))
	return -0.4
