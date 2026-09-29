class_name HailRules
extends RefCounted

## **Where Bram calls from** (O14, 2026-09-29). Walk into the ground round the ruined
## village and the man who teaches the sword sees you, calls out, and comes over to
## talk — Yannick's « dresseur Pokémon ». These are the rules without the world: who
## sees you, who still calls, and the walk he takes. The system that runs it (O16) asks.
##
## A hail row is `{who, point, at, radius}`: the person, the named point their ground is
## centred on, that point resolved on this world, and how far they see (the table's
## unless the row says). `Places.hails()` hands rows in that shape; `row()` builds one.

const TABLE_PATH: String = "res://content/hail.json"
const HAILED: String = "hailed:%s"
const MET: String = "met:%s"

static var _table: Dictionary = {}


static func _read() -> Dictionary:
	if _table.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE_PATH))
		_table = parsed as Dictionary if parsed is Dictionary else {}
	return _table


static func radius_tiles() -> float:
	return float(_read().get("radius_tiles", 0.0))


## Steps the '!' stands before he moves.
static func spotted_steps() -> int:
	return int(round(float(_read().get("spotted_seconds", 0.0)) * float(Sim.STEPS_PER_REAL_SECOND)))


## Steps he has to reach you before the walk is given up.
static func budget_steps() -> int:
	return int(round(float(_read().get("budget_seconds", 0.0)) * float(Sim.STEPS_PER_REAL_SECOND)))


## A row for somebody calling from a named point, resolved on this world.
static func row(who: StringName, point: StringName, radius: float = 0.0) -> Dictionary:
	return {"who": who, "point": point, "at": Places.shared().point(point), "radius": radius}


static func radius_of(hail: Dictionary) -> float:
	var own: float = float(hail.get("radius", 0.0))
	return own if own > 0.0 else radius_tiles()


## Whether a tile is inside the ground they watch. A zone that resolved nowhere sees
## nobody, rather than everybody within reach of (-1, -1).
static func in_sight(hail: Dictionary, tile: Vector2i) -> bool:
	var at: Vector2i = hail.get("at", Region.NOWHERE) as Vector2i
	if at == Region.NOWHERE:
		return false
	return Vector2(tile).distance_to(Vector2(at)) <= radius_of(hail)


## Whether they still call out: never twice, never to somebody they have already
## spoken to, and never once they are dead. Facts, so a replay calls exactly when the
## run did.
static func calls_out(who: StringName, facts: FactBase) -> bool:
	if facts == null:
		return false
	if facts.has(StringName(HAILED % who)) or facts.has(StringName(MET % who)):
		return false
	return not facts.has(StringName(OpeningRules.KILLED % who))


## The walk from where they stand to beside the player: the shortest way on open
## ground, cut at the first tile that touches the player's. Empty when there is no way.
static func approach(region: Region, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var walk: Array[Vector2i] = Navigation.path(region, from, to)
	for i: int in walk.size():
		if maxi(absi(walk[i].x - to.x), absi(walk[i].y - to.y)) <= 1:
			return walk.slice(0, i + 1)
	return walk
