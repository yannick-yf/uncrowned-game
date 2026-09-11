class_name Art
extends RefCounted

## Where the pictures are, and nothing else.
##
## view/ only. core/ must never learn that a Villager has a sprite sheet — the
## simulation knows an NPC stands at a tile, and this decides what that looks
## like. Everything here comes from the one approved pack (SPECS §13).

const PACK: String = "res://assets/NinjaAdventure/Ninja Adventure - Asset Pack"
const TILE: int = 16

## Atlas coordinates in TilesetFloor, picked for being flat and unambiguous.
const GRASS: Vector2i = Vector2i(11, 12)
const GRASS_TUFT: Vector2i = Vector2i(15, 12)
const EARTH: Vector2i = Vector2i(11, 19)

## Sprite-sheet columns are directions; rows are animation frames.
const FACE_DOWN: int = 0
const FACE_UP: int = 1
const FACE_LEFT: int = 2
const FACE_RIGHT: int = 3

## 4x3-tile houses, verified by eye against the atlas.
const HOUSES: Array[Rect2i] = [
	Rect2i(0, 0, 64, 48),
	Rect2i(64, 0, 64, 48),
	Rect2i(128, 0, 64, 48),
]

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
}

var floor_atlas: Texture2D = null
var house_atlas: Texture2D = null
var _sheets: Dictionary = {}


func _init() -> void:
	floor_atlas = load("%s/Backgrounds/Tilesets/TilesetFloor.png" % PACK) as Texture2D
	house_atlas = load("%s/Backgrounds/Tilesets/TilesetHouse.png" % PACK) as Texture2D


func sheet_for(role: StringName) -> Texture2D:
	if _sheets.has(role):
		return _sheets[role] as Texture2D
	var folder: String = String(CASTING.get(role, "Villager"))
	var texture: Texture2D = load("%s/Actor/Character/%s/SpriteSheet.png" % [PACK, folder]) as Texture2D
	_sheets[role] = texture
	return texture


static func tile_rect(cell: Vector2i) -> Rect2:
	return Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)


static func column_for(facing: Vector2i) -> int:
	if facing.y < 0:
		return FACE_UP
	if facing.x < 0:
		return FACE_LEFT
	if facing.x > 0:
		return FACE_RIGHT
	return FACE_DOWN
