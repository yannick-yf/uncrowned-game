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
## **One face each.** Twenty-nine roles shared eighteen sheets, so Bell, Sena and Mira
## were the same woman in three towns, and the bank and the estate were run by the same
## man in a hat. Told apart by the name over their head and nothing else, which for a
## game about walking up to twenty-five specific people is the whole problem.
##
## The pack ships 94 character sheets and most of them are ninjas, robots and demons.
## What is left after the ones that cannot stand in a kingdom is about thirty human
## faces, which is exactly enough — so the table is now one-to-one and a test says so.
## The next person to join the cast needs a face nobody has, and there are three spare.
##
## Deliberately no child sprites, ever: the pack ships Child/, EggBoy/, EggGirl/ and
## LionBoy/, and CLAUDE.md invariant 10 puts them permanently out of scope. Bell is an
## apprentice and an adult; she is cast as one.
const CASTING: Dictionary = {
	&"player": "Villager",
	&"guard": "Knight",
	# Harrowgate, and the road through it.
	&"maddox": "OldMan",
	&"tovin": "Inspector",
	&"bell": "Villager4",
	&"ossa": "OldWoman",
	&"garrick": "Villager2",
	&"wren": "Villager5",
	# **Bram's is a placeholder and reads as one** (F2, 2026-09-19). Every `Villager`
	# sheet in the pack is already somebody, so the sparring partner is cast as a man
	# who trains with a weapon instead — which is what he is, and wrong for a burnt
	# village, and visible as wrong. It costs nothing: the art rule has kept the 2D pack
	# out of the 3D world since 2026-09-14, so this table only dresses the procedural
	# map, and M3b replaces every row of it with his brother's faces.
	&"bram": "Samurai",
	# The Cinderworks.
	&"harry": "OldMan3",
	&"sena": "Villager3",
	# Tom's is a placeholder for the same reason Bram's is, below: every `Villager` sheet
	# in the pack is already somebody. M3b replaces the whole table with his brother's.
	&"tom": "SamuraiBlue",
	&"ivo": "Master",
	# The Wide Acres.
	&"cadan": "Sultan",
	&"nessa": "Princess",
	&"pell": "OldMan2",
	# The Muster, and the man who walked out of it.
	&"ryse": "KnightGold",
	&"odile": "FighterWhite",
	&"kell": "Villager6",
	# Saltmarch.
	&"til": "ManGreen",
	&"mira": "Woman",
	# Cairnwell.
	&"corvin": "Noble",
	&"peyre": "Monk",
	&"anselm": "Monk2",
	# Blackcairn.
	&"hesper": "Village6",
	&"aurel": "FighterRed",
	&"arthur": "Sultan2",
	&"dray": "RedGladiator",
	# Strangers are cast by trade, not by name — there is only one trader sheet
	# however many traders the map ends up holding.
	&"trader": "Hunter",
	&"watchman": "GladiatorBlue",
}


## Faces for the crowd. Never the same one twice in a row, and none of them is
## anybody: §6 keeps townsfolk out of the cast precisely so they cannot acquire a name
## by being drawn often enough.
##
## They are **men who walked out of the Muster** — that is what the crowd in Harrowgate
## is and why the bread price moves — so they are cast as armed men standing about,
## not as villagers. Faces are shared with the cast on purpose here: the alternative is
## thirty more sheets that do not exist, and a crowd is meant to be a crowd. Nobody in
## it stands in the same town as the named person they resemble.
const TOWNSFOLK: Array[String] = [
	"Samurai", "SamuraiBlue", "GladiatorBlue", "FighterRed", "Hunter",
	"Villager2", "Villager5", "ManGreen", "Knight", "Villager",
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
		# A bailey is packed earth, not snow. It was `floorb` — the pale blob set —
		# which is what made Blackcairn a white rectangle.
		Region.Terrain.CASTLE: [&"floor", 11, 19],
		# A wall you can see. (11,20) on the house sheet is the one tile in the pack
		# that runs seamlessly in both directions, checked by tiling it rather than
		# by looking at the sheet.
		Region.Terrain.RAMPART: [&"house", 11, 20],
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

	# Every rect here was found by measuring the sheet rather than by guessing at it.
	# The pack packs its buildings edge to edge with no transparent gutter, so the
	# seams are the columns of black outline between them — which is how `granary`
	# came to be a stone statue standing in a wheat field for two nights, and why
	# nobody noticed until somebody looked at a screenshot of the Wide Acres.
	props = {
		# Houses. Three roofs, and the difference between them is what stops two towns
		# being the same town (§6: every place has its own face).
		&"house_0": [&"house", Rect2i(0, 0, 64, 48)],
		&"house_1": [&"house", Rect2i(64, 0, 62, 48)],
		&"house_2": [&"house", Rect2i(128, 0, 64, 48)],
		# Trade. A shop with a sign over it and a workshop with its front open are the
		# two buildings that say "town" rather than "village" without a word of text.
		&"shop": [&"house", Rect2i(256, 0, 48, 48)],
		&"workshop": [&"house", Rect2i(304, 0, 64, 48)],
		# Stone. Saltmarch builds in it because timber rots in a marsh, and a castle
		# is made of nothing else.
		&"stone_house": [&"house", Rect2i(368, 0, 48, 48)],
		&"tower": [&"house", Rect2i(368, 0, 48, 48)],
		# Two storeys over an arch: an inn on the road, and the same shape either side
		# of a castle gate.
		&"inn": [&"house", Rect2i(416, 0, 48, 48)],
		&"gatehouse": [&"house", Rect2i(416, 0, 48, 48)],
		# The two biggest things in Erileo, and they belong to the two powers that are
		# not the crown's army: the bank's hall in Cairnwell, and the king's keep.
		&"counting_house": [&"house", Rect2i(400, 224, 64, 80)],
		&"keep": [&"house", Rect2i(464, 0, 64, 63)],
		# A barn. What the Wide Acres keeps the grain in — §3's second power base, and
		# for two nights it was drawn as a statue.
		&"granary": [&"house", Rect2i(400, 176, 64, 48)],
		&"house_big": [&"house", Rect2i(64, 0, 62, 48)],
		&"kiln": [&"house", Rect2i(464, 64, 48, 64)],
		&"stall": [&"house", Rect2i(240, 64, 64, 80)],
		&"tent": [&"camp", Rect2i(96, 0, 48, 48)],
		&"tent_b": [&"camp", Rect2i(144, 0, 48, 48)],
		&"ruin_house": [&"ruin", Rect2i(192, 97, 64, 80)],
		&"overgrowth": [&"ruin", Rect2i(0, 144, 64, 48)],
		&"boat": [&"boat", Rect2i(0, 0, 80, 32)],
		&"muster_rolls": [&"camp", Rect2i(96, 48, 32, 32)],
		# A book, not a barrel. The first version reused the muster-rolls art without
		# looking at it, so the five documents lay on the ground as pots and the
		# player walked up to some crockery and was told they had taken a ledger.
		&"papers": [&"camp", Rect2i(114, 122, 16, 16)],
		&"campfire": [&"camp", Rect2i(192, 80, 32, 32)],
		# Scenery: what a place has lying about, which is most of what tells you what
		# the place does for a living.
		&"well": [&"camp", Rect2i(160, 48, 32, 32)],
		&"crates": [&"camp", Rect2i(0, 16, 48, 32)],
		&"barrels": [&"camp", Rect2i(0, 0, 48, 16)],
		&"logs": [&"camp", Rect2i(16, 88, 32, 32)],
		&"fence": [&"camp", Rect2i(0, 118, 48, 16)],
		# The works' yard is his `soubassement_2m` since 2026-09-21 (G2), a stone module
		# the 2D pack has no picture of. The pack's fence stands for it in the flat look
		# at the bake only, so that look does not show an invisible wall; the 3D window
		# draws his own piece and never reads this row.
		&"soubassement_2m": [&"camp", Rect2i(0, 118, 48, 16)],
		&"produce": [&"house", Rect2i(240, 208, 64, 32)],
		&"oven": [&"house", Rect2i(464, 176, 32, 48)],
	}

func _load(id: StringName, path: String) -> void:
	_atlases[id] = load("%s/%s" % [PACK, path]) as Texture2D


func atlas(id: StringName) -> Texture2D:
	return _atlases.get(id, null) as Texture2D


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


## Travellers are traffic, not people (§9, §13): a pack horse on the road, never a
## face — a face is how furniture turns into a character by being looked at often
## enough. The pack's horse seen from the side is two frames of 23 × 16 facing left;
## walking the other way is the same frame flipped by the window.
const TRAFFIC_FRAME: Vector2i = Vector2i(23, 16)


func traffic_sheet() -> Texture2D:
	var id := StringName("traffic:horse")
	if not _sheets.has(id):
		_sheets[id] = load("%s/Actor/Animal/Horse/SpriteSheetBrownSide.png" % PACK) as Texture2D
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
## `chance` is **out of 1000**, matching `scatter_hash`, and is the odds of any detail
## at all; one of them is then picked evenly. The first draft wrote these as if the
## hash returned 0–255, so every surface got a quarter of the detail it was asked for
## and the grass still looked flat. Kept moderate even so: detail that appears half
## the time stops being detail and becomes a checkerboard.
##
## **A detail tile is a variant of the surface, never an edge of it.** That is not a
## style note, it is the bug that shipped twice — the sea drawn with shoreline tiles
## and the marsh drawn with a pond's top-left corner. Anything here must tile with
## itself in every direction.
const GROUND: Dictionary = {
	Region.Terrain.WILD: {
		"sheet": &"floor", "base": Vector2i(11, 12), "chance": 300,
		"detail": [Vector2i(12, 12), Vector2i(13, 12), Vector2i(14, 12), Vector2i(15, 12)],
	},
	Region.Terrain.CLEARING: {
		"sheet": &"floor", "base": Vector2i(11, 12), "chance": 380,
		"detail": [Vector2i(12, 12), Vector2i(14, 12), Vector2i(15, 12)],
	},
	Region.Terrain.FOREST: {
		"sheet": &"floor", "base": Vector2i(11, 12), "chance": 220,
		"detail": [Vector2i(13, 12), Vector2i(14, 12)],
	},
	Region.Terrain.THICKET: {
		"sheet": &"floor", "base": Vector2i(11, 12), "chance": 120,
		"detail": [Vector2i(13, 12)],
	},
	# The road, the towns and the camp are all beaten ground, and beaten ground has
	# stones and ruts in it.
	Region.Terrain.ROAD: {
		"sheet": &"floor", "base": Vector2i(11, 19), "chance": 260,
		"detail": [Vector2i(12, 19), Vector2i(13, 19), Vector2i(14, 19), Vector2i(15, 19)],
	},
	Region.Terrain.TOWN: {
		"sheet": &"floor", "base": Vector2i(11, 19), "chance": 200,
		"detail": [Vector2i(13, 19), Vector2i(15, 19)],
	},
	Region.Terrain.CAMP: {
		"sheet": &"floor", "base": Vector2i(11, 19), "chance": 280,
		"detail": [Vector2i(12, 19), Vector2i(14, 19)],
	},
	# Ground the works has taken. The darker, rougher dirt, with the twig and the
	# stone that are literally the stumps left behind.
	# The bailey: swept earth, worn where people walk, and no weeds — somebody keeps
	# this ground. Paving it with the capital's stone was tried and rejected: that
	# tile family is the pale pink one, and it turned the castle into a ballroom.
	Region.Terrain.CASTLE: {
		"sheet": &"floor", "base": Vector2i(11, 19), "chance": 120,
		"detail": [Vector2i(13, 19), Vector2i(15, 19)],
	},
	Region.Terrain.CLEARED: {
		"sheet": &"floor", "base": Vector2i(11, 18), "chance": 420,
		"detail": [Vector2i(12, 18), Vector2i(14, 18), Vector2i(15, 18)],
	},
	# Brindle. Grass coming back through it, which is the village reclaiming itself.
	Region.Terrain.RUINS: {
		"sheet": &"floor", "base": Vector2i(11, 20), "chance": 520,
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
		"sheet": &"water", "base": Vector2i(1, 7), "chance": 140,
		"detail": [Vector2i(11, 1), Vector2i(11, 2), Vector2i(11, 4)],
	},
	Region.Terrain.WATER: {
		"sheet": &"water", "base": Vector2i(1, 7), "chance": 190,
		"detail": [Vector2i(11, 1), Vector2i(11, 2)],
	},
	# A marsh is shallow water with things growing in it, so it is that water with
	# the lily turned right up. It used to be a pond's top-left corner.
	Region.Terrain.MARSH: {
		"sheet": &"water", "base": Vector2i(1, 7), "chance": 520,
		"detail": [Vector2i(11, 3), Vector2i(11, 3), Vector2i(11, 1)],
	},
	Region.Terrain.FORD: {
		"sheet": &"water", "base": Vector2i(1, 7), "chance": 340,
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


## What each settlement's ground is made of.
##
## **Every town was the same beaten dirt**, which is why they all looked like the same
## town with different buildings on it. A place reads as itself from its floor before
## it reads as itself from anything else — a quay is planks, a capital is paved, a
## works is ash and cinder. Falls through to the ordinary town dirt for anywhere not
## named here.
const TOWN_GROUND: Dictionary = {
	# Planks over the marsh. Saltmarch is a port built on ground that is not ground.
	&"saltmarch": {
		"sheet": &"floor", "base": Vector2i(16, 18), "chance": 340,
		"detail": [Vector2i(17, 18), Vector2i(18, 18), Vector2i(19, 18)],
	},
	# The capital is paved, and swept. It is the only place in Erileo where the
	# ground itself says somebody is paying for it.
	&"cairnwell": {
		"sheet": &"floor", "base": Vector2i(11, 5), "chance": 120,
		"detail": [Vector2i(12, 5), Vector2i(13, 5)],
	},
	# Ash and cinder, the same ground the wound outside is made of, because the works
	# does not stop at its own wall.
	&"cinderworks": {
		"sheet": &"floor", "base": Vector2i(11, 18), "chance": 380,
		"detail": [Vector2i(12, 18), Vector2i(14, 18), Vector2i(15, 18)],
	},
	# A market town's ground: grass trodden into dirt by everybody walking over it.
	# Not paved — Harrowgate is a place things pass through, and the only place in
	# Erileo that pays to pave itself is the capital.
	# Beaten earth with every rut and stone the sheet has, because a market town is
	# the road widened out. Row 20 was tried and is an autotile edge family, not a
	# scatter family: used as detail it drew green stripes down the whole town.
	&"harrowgate": {
		"sheet": &"floor", "base": Vector2i(11, 19), "chance": 360,
		"detail": [Vector2i(12, 19), Vector2i(13, 19), Vector2i(14, 19), Vector2i(15, 19)],
	},
	# Trodden mud between the tents, which is what a camp turns its ground into.
	&"muster": {
		"sheet": &"floor", "base": Vector2i(11, 18), "chance": 300,
		"detail": [Vector2i(12, 18), Vector2i(13, 19)],
	},
}


## Which tile of a terrain's surface this square is, base or detail.
##
## Hashed off the position, so it is the same every frame and every run — ground that
## shimmers as you walk is worse than ground that is flat.
static func ground_tile(terrain: int, x: int, y: int, zone: StringName = &"") -> Array:
	var entry: Dictionary = GROUND.get(terrain, {}) as Dictionary
	if zone != &"" and TOWN_GROUND.has(zone) \
			and (terrain == Region.Terrain.TOWN or terrain == Region.Terrain.CAMP):
		entry = TOWN_GROUND[zone] as Dictionary
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
	# Added after the map screen drew Blackcairn in magenta — which is the sentinel
	# working exactly as intended: a terrain nobody has coloured is impossible to
	# miss, and `RAMPART` went into the enum without one.
	Region.Terrain.RAMPART: Color(0.42, 0.44, 0.40),
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
