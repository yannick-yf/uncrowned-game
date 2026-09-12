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


## The tiles a terrain is *actually* made of: one base, and the detail tiles that
## belong with it.
##
## **Why this exists.** Every terrain used to be a single tile repeated, with one
## hard-coded exception that swapped grass for one variant a third of the time. The
## result reads as a flat fill, which is the whole of "the grass looks bad": real
## ground in this pack has four or five variants per surface — tufts, twigs, stones,
## ripples — sitting in the sheet unused.
##
## `chance` is out of 256 and is the odds of *any* detail, then one of them is picked
## evenly. Kept low: detail that appears half the time stops being detail and becomes
## a checkerboard, which is the failure the one hard-coded variant already had.
##
## **A detail tile is a variant of the surface, never an edge of it.** That is not a
## style note, it is the bug that shipped twice — the sea drawn with shoreline tiles
## and the marsh drawn with a pond's top-left corner. Anything here must tile with
## itself in every direction.
const GROUND: Dictionary = {
	Region.Terrain.WILD: {
		"sheet": &"floor", "base": Vector2i(11, 12), "chance": 96,
		"detail": [Vector2i(12, 12), Vector2i(13, 12), Vector2i(14, 12), Vector2i(15, 12)],
	},
	Region.Terrain.CLEARING: {
		"sheet": &"floor", "base": Vector2i(11, 12), "chance": 130,
		"detail": [Vector2i(12, 12), Vector2i(14, 12), Vector2i(15, 12)],
	},
	Region.Terrain.FOREST: {
		"sheet": &"floor", "base": Vector2i(11, 12), "chance": 70,
		"detail": [Vector2i(13, 12), Vector2i(14, 12)],
	},
	Region.Terrain.THICKET: {
		"sheet": &"floor", "base": Vector2i(11, 12), "chance": 40,
		"detail": [Vector2i(13, 12)],
	},
	# The road, the towns and the camp are all beaten ground, and beaten ground has
	# stones and ruts in it.
	Region.Terrain.ROAD: {
		"sheet": &"floor", "base": Vector2i(11, 19), "chance": 74,
		"detail": [Vector2i(12, 19), Vector2i(13, 19), Vector2i(14, 19), Vector2i(15, 19)],
	},
	Region.Terrain.TOWN: {
		"sheet": &"floor", "base": Vector2i(11, 19), "chance": 60,
		"detail": [Vector2i(13, 19), Vector2i(15, 19)],
	},
	Region.Terrain.CAMP: {
		"sheet": &"floor", "base": Vector2i(11, 19), "chance": 80,
		"detail": [Vector2i(12, 19), Vector2i(14, 19)],
	},
	# Ground the works has taken. The darker, rougher dirt, with the twig and the
	# stone that are literally the stumps left behind.
	Region.Terrain.CLEARED: {
		"sheet": &"floor", "base": Vector2i(11, 18), "chance": 120,
		"detail": [Vector2i(12, 18), Vector2i(14, 18), Vector2i(15, 18)],
	},
	# Brindle. Grass coming back through it, which is the village reclaiming itself.
	Region.Terrain.RUINS: {
		"sheet": &"floor", "base": Vector2i(11, 20), "chance": 150,
		"detail": [Vector2i(12, 20), Vector2i(13, 20), Vector2i(14, 20), Vector2i(15, 20)],
	},
	# **Water, and the one thing that has to be right about it.**
	#
	# The sheet holds two blues. `(11,0)` is a flat greyish `(121,184,206)` standing
	# on its own; everything else — every bank, every blob interior, and all four
	# detail tiles — is a brighter `(113,221,238)`. Drawing the sea in the first and
	# its details in the second is what made the ocean read as pale squares.
	#
	# `(1,7)` is the plain tile of the *bright* family, so the sea, its ripples, its
	# stones and its shoreline are finally one colour. Found by asking the sheet which
	# of its 476 tiles are a single flat colour, rather than by picking one that
	# looked about right.
	Region.Terrain.SEA: {
		"sheet": &"water", "base": Vector2i(1, 7), "chance": 40,
		"detail": [Vector2i(11, 1), Vector2i(11, 2), Vector2i(11, 4)],
	},
	Region.Terrain.WATER: {
		"sheet": &"water", "base": Vector2i(1, 7), "chance": 54,
		"detail": [Vector2i(11, 1), Vector2i(11, 2)],
	},
	# A marsh is shallow water with things growing in it, so it is that water with
	# the lily turned right up. It used to be a pond's top-left corner.
	Region.Terrain.MARSH: {
		"sheet": &"water", "base": Vector2i(1, 7), "chance": 150,
		"detail": [Vector2i(11, 3), Vector2i(11, 3), Vector2i(11, 1)],
	},
	Region.Terrain.FORD: {
		"sheet": &"water", "base": Vector2i(1, 7), "chance": 96,
		"detail": [Vector2i(11, 1), Vector2i(11, 2)],
	},
	# Beach. No detail: the only tiles near it on this sheet are *water* details, and
	# scattering those put three cyan puddles in the middle of the sand.
	Region.Terrain.SAND: {
		"sheet": &"water", "base": Vector2i(0, 5), "chance": 0, "detail": [],
	},
}


# ------------------------------------------------------------- shorelines ---

## Where each blob starts. The water sheet carries the same shape twice: once with
## sand banks and once with grass banks, so water can meet a beach or a field and
## look like it meant to.
const BANK_SAND: Vector2i = Vector2i(4, 0)
const BANK_GRASS: Vector2i = Vector2i(4, 6)

## Offsets inside a 4×4 blob, read off the sheet rather than guessed:
##
## ```
##   outer TL   top      top      outer TR
##   left       inner SE inner SW right
##   left       inner NE inner NW right
##   outer BL   bottom   bottom   outer BR
## ```
##
## The middle four are **inner** corners — the sheet draws a small island across
## their junction, so each one is the quadrant of water that has land diagonally
## behind it. Getting those backwards is the difference between a bay and a
## chequerboard, which is why they are named here rather than indexed.
const EDGE_TOP_LEFT: Vector2i = Vector2i(0, 0)
const EDGE_TOP: Vector2i = Vector2i(1, 0)
const EDGE_TOP_RIGHT: Vector2i = Vector2i(3, 0)
const EDGE_LEFT: Vector2i = Vector2i(0, 1)
const EDGE_RIGHT: Vector2i = Vector2i(3, 1)
const EDGE_BOTTOM_LEFT: Vector2i = Vector2i(0, 3)
const EDGE_BOTTOM: Vector2i = Vector2i(1, 3)
const EDGE_BOTTOM_RIGHT: Vector2i = Vector2i(3, 3)
const INNER_SE: Vector2i = Vector2i(1, 1)
const INNER_SW: Vector2i = Vector2i(2, 1)
const INNER_NE: Vector2i = Vector2i(1, 2)
const INNER_NW: Vector2i = Vector2i(2, 2)


## Which shoreline tile a piece of water is, given what is around it.
##
## `around` is eight booleans — **is that neighbour also water** — in the order
## N, E, S, W, NE, NW, SE, SW. Returns the cell to draw, or `Vector2i(-1, -1)` for
## open water with nothing to bank against.
##
## This is the single thing that most separates the map from the games it is aiming
## at. Everything in it was painted in rectangles: a coast was a straight line
## between blue and yellow, because every tile of a terrain was the same tile. A
## shoreline is what a map looks like when it was drawn rather than filled in.
static func water_edge(bank: Vector2i, around: Array) -> Vector2i:
	var n: bool = around[0]
	var e: bool = around[1]
	var s: bool = around[2]
	var w: bool = around[3]
	if not n and not w:
		return bank + EDGE_TOP_LEFT
	if not n and not e:
		return bank + EDGE_TOP_RIGHT
	if not s and not w:
		return bank + EDGE_BOTTOM_LEFT
	if not s and not e:
		return bank + EDGE_BOTTOM_RIGHT
	if not n:
		return bank + EDGE_TOP
	if not s:
		return bank + EDGE_BOTTOM
	if not w:
		return bank + EDGE_LEFT
	if not e:
		return bank + EDGE_RIGHT
	# Every side is water, so only a diagonal can still be land.
	if not around[5]:
		return bank + INNER_NW
	if not around[4]:
		return bank + INNER_NE
	if not around[7]:
		return bank + INNER_SW
	if not around[6]:
		return bank + INNER_SE
	return Vector2i(-1, -1)


static func is_water(terrain: int) -> bool:
	return terrain == Region.Terrain.SEA or terrain == Region.Terrain.WATER \
		or terrain == Region.Terrain.FORD or terrain == Region.Terrain.MARSH


## Which tile of a terrain's surface this square is, base or detail.
##
## Hashed off the position, so it is the same every frame and every run — ground that
## shimmers as you walk is worse than ground that is flat.
static func ground_tile(terrain: int, x: int, y: int) -> Array:
	var entry: Dictionary = GROUND.get(terrain, {}) as Dictionary
	if entry.is_empty():
		return []
	var detail: Array = entry["detail"] as Array
	var roll: int = scatter_hash(x * 3 + 11, y * 5 + 7)
	if detail.is_empty() or roll >= int(entry["chance"]):
		return [entry["sheet"], entry["base"] as Vector2i]
	return [entry["sheet"], detail[scatter_hash(x + 31, y + 17) % detail.size()] as Vector2i]


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
		# Nothing grows out of open water. The marsh used to scatter the same bush
		# the grassland does, so Saltmarch had trees standing in the sea.
	return []
