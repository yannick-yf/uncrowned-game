class_name CastLooks
extends RefCounted

## **Who wears what** (group L, 2026-09-30): every kind of person the demo shows, told
## apart at a glance — the king's guards in heavy armour, the watch, the works' guards
## and archers, the ironworks' workers, the villagers, Bram and Wren. The player alone
## stays as his brother drew him.
##
## A look is a sheet: his traveller dressed by `tools/draw_cast_looks.gd`, the same size
## and layout as the one his frames read from, so a figure wears a look by handing its
## sheet to his shader. The recipes and the table of who wears which are
## `content/looks.json`; this reads them for the window and for the tool, so the two never
## disagree about a name or about the room kept round his frames.
##
## Presentation only: nothing in `core/` reads a look, and a clone without the sheets
## draws everybody as his traveller, as before.

const FILE: String = "res://content/looks.json"
const DIR: String = "res://view3d/cast/"

static var _table: Dictionary = {}


static func _read() -> Dictionary:
	if _table.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
		_table = parsed as Dictionary if parsed is Dictionary else {"looks": {}}
	return _table


## Every look and its recipe, by name.
static func looks() -> Dictionary:
	return _read().get("looks", {}) as Dictionary


static func names() -> Array[StringName]:
	var out: Array[StringName] = []
	for name: String in looks().keys():
		out.append(StringName(name))
	return out


static func sheet_path(look: StringName) -> String:
	return DIR + String(look) + ".png"


## How much taller than a man this look is drawn: the king's guards stand a fifth over
## everybody, which is half of what makes them look unbeatable.
static func scale_of(look: StringName) -> float:
	return float((looks().get(String(look), {}) as Dictionary).get("scale", 1.0))


## The room kept above and beside each of his frames for what stands out of a man —
## a plume, a bow. Never below: his feet stand on the frame's bottom edge.
static func room_px() -> int:
	return int(_read().get("room_px", 8))


static func with_room(region: Rect2i, room: int) -> Rect2i:
	return Rect2i(region.position - Vector2i(room, room), region.size + Vector2i(room * 2, room))


# ------------------------------------------------------------------- who wears what ---

## A person of the cast: named ones by name, strangers by their trade — and by where
## they stand, where a place dresses its own (the works' watchmen are the works' guards).
## Anybody else is a villager, the same one every time.
static func of_person(id: StringName, trade: StringName, place: StringName) -> StringName:
	var table: Dictionary = _read()
	var people: Dictionary = table.get("people", {}) as Dictionary
	if people.has(String(id)):
		return StringName(String(people[String(id)]))
	var here: Dictionary = (table.get("strangers_by_place", {}) as Dictionary).get(String(place), {}) as Dictionary
	if trade != &"" and here.has(String(trade)):
		return StringName(String(here[String(trade)]))
	var strangers: Dictionary = table.get("strangers", {}) as Dictionary
	if trade != &"" and strangers.has(String(trade)):
		return StringName(String(strangers[String(trade)]))
	return crowd(hash(String(id)))


## A fighter nobody names, by kind: `&""` for a kind that is not a person (a wolf).
static func of_fighter(kind: StringName) -> StringName:
	var fighters: Dictionary = _read().get("fighters", {}) as Dictionary
	return StringName(String(fighters.get(String(kind), "")))


## The king's escort before his gate.
static func escort() -> StringName:
	return StringName(String(_read().get("escort", "")))


## One of the villagers, by a number that stays the same for the same walker.
static func crowd(index: int) -> StringName:
	return _one_of(_read().get("crowd", []) as Array, index)


## One of the ironworks' workers, likewise.
static func worker(index: int) -> StringName:
	return _one_of(_read().get("workers", []) as Array, index)


## Whether the people who walk to work in this place are its workers or villagers.
static func works_at(place: StringName) -> bool:
	return (_read().get("workers_at", []) as Array).has(String(place))


static func _one_of(pool: Array, index: int) -> StringName:
	if pool.is_empty():
		return &""
	return StringName(String(pool[posmod(index, pool.size())]))


# ------------------------------------------------------------------- the window ---

## A copy of his frames that draws from a look's sheet. His own frames are widened by
## the room the tool kept round them — the margin shrinks by as much, so each frame is
## exactly as large as before and his feet stand where they stood — and ours, which have
## no margin, are left as they are.
static func frames_for(base: SpriteFrames, sheet: Texture2D) -> SpriteFrames:
	# Built afresh rather than duplicated: a duplicate shares its frames' textures with the
	# one it came from, and re-pointing them would dress the player too.
	var room: int = room_px()
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for named: StringName in base.get_animation_names():
		frames.add_animation(named)
		frames.set_animation_loop(named, base.get_animation_loop(named))
		frames.set_animation_speed(named, base.get_animation_speed(named))
		for i: int in base.get_frame_count(named):
			var his := base.get_frame_texture(named, i) as AtlasTexture
			if his == null:
				continue
			var slice := AtlasTexture.new()
			slice.atlas = sheet
			slice.filter_clip = his.filter_clip
			slice.region = his.region
			slice.margin = his.margin
			if his.margin.size != Vector2.ZERO:
				slice.region = Rect2(with_room(Rect2i(his.region), room))
				slice.margin = Rect2(his.margin.position - Vector2(room, room),
					his.margin.size - Vector2(room * 2, room))
			frames.add_frame(named, slice, base.get_frame_duration(named, i))
	return frames
