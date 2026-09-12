class_name Art
extends RefCounted

## Where the pictures are, and nothing else.
##
## view/ only. core/ must never learn that a furnace has a sprite — the simulation
## knows a landmark of kind "kiln" stands at a tile, and this decides what that
## looks like. Everything here comes from the one approved pack (SPECS §13).

const PACK: String = "res://assets/NinjaAdventure/Ninja Adventure - Asset Pack"
const TILE: int = 16

const FACE_DOWN: int = 0
const FACE_UP: int = 1
const FACE_LEFT: int = 2
const FACE_RIGHT: int = 3

## Casting. Cosmetic and swappable — no rule depends on any of it.
##
## Deliberately no child sprites, ever: the pack ships Child/, EggBoy/, EggGirl/
## and LionBoy/, and CLAUDE.md invariant 10 puts them permanently out of scope.
## Bell is an apprentice and an adult; she is cast as one.
const CASTING: Dictionary = {
	&"player": "Villager",
	&"king": "Noble",
	&"guard": "Knight",
	&"maddox": "OldMan",
	&"tovin": "Inspector",
	&"bell": "Woman",
	&"ossa": "OldWoman",
	&"garrick": "Villager2",
	&"wren": "Villager5",
	&"halgrave": "OldMan3",
	&"sena": "Woman",
	&"ivo": "Monk",
	&"cadan": "Noble",
	&"nessa": "Princess",
	&"pell": "OldMan2",
	&"ryse": "KnightGold",
	&"odile": "Inspector",
	&"kell": "Villager4",
	&"til": "ManGreen",
	&"mira": "Woman",
	&"corvin": "Sultan2",
	&"peyre": "Monk",
	&"anselm": "Monk2",
	&"hesper": "OldWoman",
	&"aurel": "Knight",
	&"arthur": "Sultan",
	&"dray": "KnightGold",
	# Strangers are cast by trade, not by name — there is only one trader sheet
	# however many traders the map ends up holding.
	&"trader": "ManGreen",
	&"watchman": "Knight",
}

## What lives in the wild. Monster sheets are 4x4 — the same four directions as a
## character, with fewer frames.
const BEASTS: Dictionary = {
	&"bear": "Bear",
	&"spider": "SpiderRed",
	&"bat": "BlueBat",
}

## Faces for the crowd. Never the same one twice in a row, and none of them is
## anybody: §6 keeps townsfolk out of the cast precisely so they cannot acquire a
## name by being drawn often enough.
const TOWNSFOLK: Array[String] = [
	"Villager3", "Villager4", "Villager5", "Villager6", "Woman", "OldMan2",
	"OldWoman", "ManGreen", "Monk", "Villager2",
]

var _atlases: Dictionary = {}
var _sheets: Dictionary = {}

## Terrain -> [atlas, tile column, tile row]. Anything absent is drawn as a flat
## colour by the caller, which is what the mountains and the town walls get.
var terrain_tiles: Dictionary = {}
## Landmark kind -> [atlas, source rect]. Sizes are the sprite's own, not the
## footprint's: a four-tile building that is five tiles tall should look it.
var props: Dictionary = {}


func _init() -> void:
	_load(&"floor", "Backgrounds/Tilesets/TilesetFloor.png")
	_load(&"floorb", "Backgrounds/Tilesets/TilesetFloorB.png")
	_load(&"house", "Backgrounds/Tilesets/TilesetHouse.png")
	_load(&"water", "Backgrounds/Tilesets/TilesetWater.png")
	_load(&"nature", "Backgrounds/Tilesets/TilesetNature.png")
	_load(&"camp", "Backgrounds/Tilesets/tileset_camp.png")
	_load(&"ruin", "Backgrounds/Tilesets/TilesetVillageAbandoned.png")
	_load(&"field", "Backgrounds/Tilesets/TilesetField.png")
	_load(&"boat", "Backgrounds/Vehicles/Boat.png")

	terrain_tiles = {
		Region.Terrain.WILD: [&"floor", 11, 12],
		Region.Terrain.FOREST: [&"floor", 11, 12],
		Region.Terrain.ROAD: [&"floor", 11, 19],
		Region.Terrain.RUINS: [&"floor", 11, 19],
		Region.Terrain.TOWN: [&"floor", 11, 19],
		Region.Terrain.CAMP: [&"floor", 11, 19],
		# A building's footprint is packed earth, not a grey block. It is normally
		# hidden under the sprite standing on it — but a struck tent leaves its
		# ground behind, and bare ground is what should be there.
		Region.Terrain.WALL: [&"floor", 11, 19],
		Region.Terrain.CASTLE: [&"floorb", 1, 1],
		Region.Terrain.SEA: [&"water", 11, 0],
		Region.Terrain.WATER: [&"water", 11, 0],
		Region.Terrain.FORD: [&"water", 0, 5],
		Region.Terrain.SAND: [&"water", 0, 5],
		Region.Terrain.MARSH: [&"water", 0, 6],
		Region.Terrain.FARMLAND: [&"field", 1, 4],
		# The thesis, on the ground. Cleared land reads as the road's world — the
		# same beaten dirt the road and the towns are drawn on — because that is
		# exactly what it has become. The fairies' clearing keeps the wood's own
		# floor. The thicket keeps it too and is buried under trees by `scatter_at`.
		Region.Terrain.CLEARED: [&"floor", 11, 19],
		Region.Terrain.CLEARING: [&"floor", 11, 12],
		Region.Terrain.THICKET: [&"floor", 11, 12],
	}

	props = {
		&"house_0": [&"house", Rect2i(0, 0, 64, 48)],
		&"house_1": [&"house", Rect2i(64, 0, 64, 48)],
		&"house_2": [&"house", Rect2i(128, 0, 64, 48)],
		&"house_big": [&"house", Rect2i(64, 0, 64, 48)],
		&"kiln": [&"house", Rect2i(464, 64, 48, 64)],
		&"tent": [&"camp", Rect2i(96, 0, 48, 48)],
		&"tent_b": [&"camp", Rect2i(144, 0, 48, 48)],
		&"ruin_house": [&"ruin", Rect2i(192, 97, 64, 80)],
		&"overgrowth": [&"ruin", Rect2i(0, 144, 64, 48)],
		&"tower": [&"ruin", Rect2i(192, 97, 64, 80)],
		&"boat": [&"boat", Rect2i(0, 0, 80, 32)],
		&"counting_house": [&"house", Rect2i(400, 224, 64, 80)],
		&"stall": [&"house", Rect2i(240, 64, 64, 80)],
		&"granary": [&"house", Rect2i(0, 224, 48, 64)],
		&"muster_rolls": [&"camp", Rect2i(96, 48, 32, 32)],
		# A book, not a barrel. The first version reused the muster-rolls art without
		# looking at it, so the five documents lay on the ground as pots and the
		# player walked up to some crockery and was told they had taken a ledger.
		&"papers": [&"camp", Rect2i(114, 122, 16, 16)],
		&"campfire": [&"camp", Rect2i(192, 80, 32, 32)],
	}


func _load(id: StringName, path: String) -> void:
	_atlases[id] = load("%s/%s" % [PACK, path]) as Texture2D


func atlas(id: StringName) -> Texture2D:
	return _atlases.get(id, null) as Texture2D


func beast_sheet_for(kind: StringName) -> Texture2D:
	var id := StringName("beast:%s" % kind)
	if _sheets.has(id):
		return _sheets[id] as Texture2D
	_sheets[id] = load("%s/Actor/Monster/%s/SpriteSheet.png" % [PACK, String(BEASTS.get(kind, "Bear"))]) as Texture2D
	return _sheets[id] as Texture2D


## Whether anything at all knows how to draw this kind of prop. Landmarks come
## from the props table; the crowd comes from its own faces.
func can_draw(kind: StringName) -> bool:
	return props.has(kind) or kind == &"townsfolk"


## One of the crowd, picked by index so the same spot always holds the same face.
func townsfolk_sheet(index: int) -> Texture2D:
	var folder: String = TOWNSFOLK[absi(index) % TOWNSFOLK.size()]
	var id := StringName("folk:%s" % folder)
	if not _sheets.has(id):
		_sheets[id] = load("%s/Actor/Character/%s/SpriteSheet.png" % [PACK, folder]) as Texture2D
	return _sheets[id] as Texture2D


func sheet_for(role: StringName) -> Texture2D:
	if _sheets.has(role):
		return _sheets[role] as Texture2D
	# A generic's id is "trade@n". Everyone of a trade wears the same face.
	var key: StringName = role
	var at: int = String(role).find("@")
	if at > 0:
		key = StringName(String(role).substr(0, at))
	var folder: String = String(CASTING.get(key, "Villager"))
	_sheets[role] = load("%s/Actor/Character/%s/SpriteSheet.png" % [PACK, folder]) as Texture2D
	return _sheets[role] as Texture2D


static func tile_rect(column: int, row: int) -> Rect2:
	return Rect2(column * TILE, row * TILE, TILE, TILE)


static func column_for(facing: Vector2i) -> int:
	if facing.y < 0:
		return FACE_UP
	if facing.x < 0:
		return FACE_LEFT
	if facing.x > 0:
		return FACE_RIGHT
	return FACE_DOWN


## Scatter — trees, bushes, boulders — is decided per tile rather than stored, so
## a wood can be dense without the world holding a hundred thousand objects.
##
## Deliberately *not* solid. A forest you cannot walk through is a maze, and the
## Thornwood's cost is meant to be time and blood, not navigation.
static func scatter_hash(x: int, y: int) -> int:
	var h: int = (x * 73856093) ^ (y * 19349663)
	return absi(h) % 1000


## The flat colour a terrain falls back to when it has no atlas tile.
##
## **Keyed, not indexed.** It was a `PackedColorArray` in the window, read by terrain
## ordinal — so adding `CLEARING` to `core/` in one commit left the table one short
## and the first frame drawn in the clearing would have read off the end of it. No
## test drew anything, so nothing caught it. A dictionary cannot go out of bounds,
## and `colour_for` answers for a terrain nobody has coloured yet.
const TERRAIN_COLOURS: Dictionary = {
	Region.Terrain.WILD: Color(0.29, 0.38, 0.23),
	Region.Terrain.ROAD: Color(0.55, 0.47, 0.33),
	Region.Terrain.RUINS: Color(0.35, 0.29, 0.27),
	Region.Terrain.CASTLE: Color(0.29, 0.27, 0.36),
	Region.Terrain.SEA: Color(0.11, 0.17, 0.28),
	Region.Terrain.MOUNTAIN: Color(0.22, 0.21, 0.24),
	Region.Terrain.TOWN: Color(0.45, 0.40, 0.29),
	Region.Terrain.WALL: Color(0.42, 0.39, 0.36),
	Region.Terrain.CAMP: Color(0.38, 0.31, 0.24),
	Region.Terrain.WATER: Color(0.16, 0.31, 0.45),
	Region.Terrain.FORD: Color(0.36, 0.44, 0.47),
	Region.Terrain.FOREST: Color(0.15, 0.25, 0.16),
	Region.Terrain.MARSH: Color(0.27, 0.31, 0.26),
	Region.Terrain.FARMLAND: Color(0.47, 0.45, 0.24),
	Region.Terrain.SAND: Color(0.68, 0.62, 0.44),
	Region.Terrain.CLEARED: Color(0.31, 0.40, 0.24),
	Region.Terrain.CLEARING: Color(0.20, 0.30, 0.19),
	Region.Terrain.THICKET: Color(0.09, 0.16, 0.10),
}

## Magenta, deliberately. A terrain nobody has drawn should be impossible to miss.
const NO_COLOUR: Color = Color(1.0, 0.0, 1.0)


func colour_for(terrain: int) -> Color:
	return TERRAIN_COLOURS.get(terrain, NO_COLOUR) as Color


## [atlas, source rect] for whatever grows on this tile, or an empty array.
func scatter_at(terrain: int, x: int, y: int) -> Array:
	var roll: int = scatter_hash(x, y)
	match terrain:
		Region.Terrain.FOREST:
			# Thinned from 42% of tiles to 26%. A wood you cannot see an animal
			# through is not atmospheric, it is unfair — you cannot avoid what you
			# cannot see, and the trees are drawn two tiles tall over one-tile
			# ground, so they overlap far more than the number suggests.
			if roll < 200:
				return [&"nature", Rect2i(32, 0, 32, 32)]
			if roll < 260:
				return [&"nature", Rect2i(0, 0, 32, 32)]
		Region.Terrain.THICKET:
			# Nearly every tile. The thicket is impassable, and the only honest way
			# to say so without a wall is to make it read as solid wood.
			if roll < 248:
				return [&"nature", Rect2i(32, 0, 32, 32)]
			return [&"nature", Rect2i(0, 0, 32, 32)]
		Region.Terrain.CLEARING:
			# Open ground. A little scrub at the margins and nothing in the middle,
			# so it reads as a room rather than a thinner wood.
			if roll < 26:
				return [&"nature", Rect2i(96, 0, 32, 32)]
		Region.Terrain.CLEARED:
			# What is left standing after the axes: a few dead trees, drawn grey by
			# the window, and otherwise bare.
			if roll < 34:
				return [&"nature", Rect2i(0, 0, 32, 32)]
		Region.Terrain.WILD:
			if roll < 22:
				return [&"nature", Rect2i(96, 0, 32, 32)]
		Region.Terrain.MOUNTAIN:
			if roll < 170:
				return [&"nature", Rect2i(258, 84, 60, 44)]
		Region.Terrain.RUINS:
			if roll < 90:
				return [&"nature", Rect2i(64, 0, 32, 32)]
		Region.Terrain.MARSH:
			if roll < 60:
				return [&"nature", Rect2i(96, 0, 32, 32)]
	return []
