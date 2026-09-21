class_name Sound
extends Node

## What the game sounds like: one track for where you are, one layer for what the
## ground is, and the small noises a menu makes.
##
## **One of these, created on first use and parented to the tree's root**, because it
## is the one thing in the game that has to outlive the screen — walking out of
## Harrowgate must not restart the music, and neither must opening the pause menu.
##
## It was an autoload for an hour and could not stay one. The suite runs as
## `godot -s tools/test_runner.gd`, which replaces the main loop, and an autoload
## never loads in that mode — so every `view/` file that mentioned `Sound` failed to
## parse and thirty tests went red at once. The static façade below is the fix and is
## better anyway: `_live()` returns null when there is no tree to speak into, so a
## headless test asking for a noise silently gets none.
##
## **`view/` only, like `Art`.** `core/` knows the player is standing in Saltmarch; it
## must never learn that Saltmarch sounds like water. Everything here is a table from
## something the simulation already says to a file in the approved pack (§13) — and
## the pack that drew the tiles wrote the music, which is the same argument as the
## font: one pack, never a mix.
##
## Nothing here is loaded until it is asked for. Forty-one tracks is thirty megabytes
## and the game needs one of them at a time.

const PACK: String = "res://assets/NinjaAdventure/Ninja Adventure - Asset Pack/Audio"

## **Music is off for now (Yannick, 2026-09-14):** *remove the music as well.* The tracks
## are the 2D pack's, and the 2D game's layers come off one by one while his brother's
## world is tested (MIGRATION_3D §9, decision 8). The tables below stand, the ambience
## and the cues still play, and one word turns the score back on.
const MUSIC: bool = false

## Where you are, and what it sounds like.
##
## The pack's titles do half the work: there is a track called *Clearing* and a track
## called *Dark Forest*, and the opening happens in one and then the other. What is
## chosen rather than given is which of them is the king's world — **the road, the
## capital and the castle share nothing with the wood**, because §4's whole argument
## is that they are two places and the map should say so without a caption.
const MUSIC_AT: Dictionary = {
	&"brindle": "26 - Lost Village.ogg",
	&"cinderworks": "28 - Tension.ogg",
	&"harrowgate": "36 - Village.ogg",
	&"wide_acres": "31 - Sunny.ogg",
	&"muster": "17 - Fight.ogg",
	&"saltmarch": "18 - Aquatic.ogg",
	&"cairnwell": "32 - Manor.ogg",
	&"blackcairn": "10 - Dark Castle.ogg",
}

## And what the ground sounds like when you are not in any of them. The wound the
## works has cut gets a lament — it is the one piece of ground in Erileo that is
## nothing but a loss, and it should be audible before it is explained.
const MUSIC_ON: Dictionary = {
	Region.Terrain.FOREST: "37 - Dark Forest.ogg",
	Region.Terrain.THICKET: "37 - Dark Forest.ogg",
	Region.Terrain.CLEARING: "11 - Clearing.ogg",
	Region.Terrain.CLEARED: "29 - Lament.ogg",
}

const MUSIC_ROAD: String = "23 - Road.ogg"
const MUSIC_TITLE: String = "38 - Intro.ogg"
## Character creation: you are deciding who woke up in the clearing with no memory of
## having been anybody. *Dream* rather than a fanfare.
const MUSIC_CREATION: String = "22 - Dream.ogg"

## Under the music, quieter, on its own loop. Three of them, because the map has three
## kinds of ground that make a noise: the wood, running water, and the sea.
const AMBIENT_ON: Dictionary = {
	Region.Terrain.WILD: "Wind.wav",
	Region.Terrain.FOREST: "Wind.wav",
	Region.Terrain.THICKET: "Wind.wav",
	Region.Terrain.CLEARING: "Wind.wav",
	Region.Terrain.CLEARED: "Wind2.wav",
	Region.Terrain.WATER: "River.wav",
	Region.Terrain.FORD: "River.wav",
	Region.Terrain.MARSH: "River.wav",
	Region.Terrain.SEA: "Wave.wav",
	Region.Terrain.SAND: "Wave.wav",
}

## The one-shots, by what happened rather than by what they are: a caller says
## `cue(&"refused")` and never learns which wav that is.
const CUES: Dictionary = {
	&"move": "Sounds/Menu/Move1.wav",
	&"accept": "Sounds/Menu/Accept.wav",
	&"cancel": "Sounds/Menu/Cancel.wav",
	&"refused": "Sounds/Menu/Cancel2.wav",
	&"spoke": "Sounds/Voice/Voice3.wav",
	&"took": "Sounds/Bonus/Coin.wav",
	&"learnt": "Jingles/Secret1.wav",
	&"rested": "Jingles/Success1.wav",
	&"died": "Jingles/GameOver.wav",
	&"seen": "Sounds/Alert/Alert.wav",
	# **The fight** (H2, 2026-09-21): a clean hit, a hit that fells somebody, a blow on a
	# raised guard, a blow that finds nobody, and the two ways it ends. Chosen by their
	# measured attack and length — the sharpest, fullest hit in the pack for a hit; the
	# dull short one for a guard; the shortest, quietest for a whiff — and **not yet
	# heard by anybody**, because the machine this was built on has no speakers. If a
	# whiff sounds like a jump, this is the row.
	&"hit": "Sounds/Hit & Impact/Hit7.wav",
	&"felled": "Sounds/Hit & Impact/Hit2.wav",
	&"blocked": "Sounds/Hit & Impact/Impact.wav",
	&"whiff": "Sounds/Jump & Bounce/Jump.wav",
	&"fight_won": "Jingles/Success2.wav",
	&"fight_lost": "Jingles/GameOver2.wav",
}

## Loud enough to be there and quiet enough to be talked over. The music sits well
## under the cues on purpose: this game is read, and a score that competes with the
## dialogue box is a score somebody turns off.
const MUSIC_DB: float = -14.0
const AMBIENT_DB: float = -22.0
const CUE_DB: float = -6.0
## How long a track takes to give way to the next one. Long enough that walking over a
## boundary is a change of weather rather than a cut.
const FADE: float = 1.4
## And the least time a track is allowed to hold the floor, so that standing on the
## line between the wood and the road does not turn the score into a stutter.
const DWELL: float = 6.0

## Where the player's choice is kept — the same file the language lives in, because
## they are the same kind of thing and §16 will grow one options screen for both.
const SETTINGS: String = "user://settings.cfg"

static var _instance: Sound = null
## Mute is static and read from disk on first ask, so a menu can label its own row
## before anything has made a noise — and so it survives a screen being freed.
static var _muted: bool = false
static var _asked_settings: bool = false

var _music: Array[AudioStreamPlayer] = []
var _at: int = 0
var _ambient: AudioStreamPlayer = null
var _cue: AudioStreamPlayer = null

var _playing: String = ""
var _ambience: String = ""
var _held_since: float = -DWELL
var _cache: Dictionary = {}


## Put the one Sound in the tree, under something that lives as long as the game does.
## Called by `screens.gd` before the first screen exists, and idempotent so the play
## screen can call it too and still have music when it is opened on its own.
##
## Explicit rather than lazy, and that is not a style preference: creating it on first
## use meant creating it inside `Screens._ready()`, which is inside the engine's own
## `root.add_child`, and Godot refuses to add a child to a node that is busy adding
## children. The node came back half-built and the first track crashed on an empty
## array of players.
static func install(host: Node) -> void:
	if _instance != null and is_instance_valid(_instance):
		return
	_instance = Sound.new()
	_instance.name = "Sound"
	host.add_child(_instance)


## The living one, or null when there is nowhere to play. Null is the ordinary answer
## in a test and in any tool script: the whole façade below no-ops on it.
static func _live() -> Sound:
	return _instance if _instance != null and is_instance_valid(_instance) else null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in 2:
		var player := AudioStreamPlayer.new()
		player.volume_db = -80.0
		add_child(player)
		_music.append(player)
	_ambient = AudioStreamPlayer.new()
	_ambient.volume_db = AMBIENT_DB
	_ambient.finished.connect(_loop_ambient)
	add_child(_ambient)
	_cue = AudioStreamPlayer.new()
	_cue.volume_db = CUE_DB
	add_child(_cue)
	_apply_mute()


# ------------------------------------------------------------------ the mix ---

static func muted() -> bool:
	if not _asked_settings:
		_asked_settings = true
		var file := ConfigFile.new()
		if file.load(SETTINGS) == OK:
			_muted = bool(file.get_value("player", "muted", false))
	return _muted


static func set_muted(quiet: bool) -> void:
	_muted = quiet
	_asked_settings = true
	var file := ConfigFile.new()
	file.load(SETTINGS)
	file.set_value("player", "muted", _muted)
	file.save(SETTINGS)
	var it: Sound = _live()
	if it != null:
		it._apply_mute()


func _apply_mute() -> void:
	# The music keeps running while it is muted rather than stopping, so unmuting
	# picks the place up where it was instead of restarting the track.
	var quiet: bool = muted()
	for player: AudioStreamPlayer in _music:
		player.volume_db = -80.0 if (quiet or player != _music[_at]) else MUSIC_DB
	_ambient.volume_db = -80.0 if quiet else AMBIENT_DB
	_cue.volume_db = -80.0 if quiet else CUE_DB


# ------------------------------------------------------------------- music ---

## The track for a place, chosen from what the simulation already says about where the
## player is standing. `zone` is `&""` outside a settlement.
static func track_for(zone: StringName, terrain: int) -> String:
	if MUSIC_AT.has(zone):
		return String(MUSIC_AT[zone])
	if MUSIC_ON.has(terrain):
		return String(MUSIC_ON[terrain])
	return MUSIC_ROAD


## Play a track, crossfading out of whatever is playing. Asking for the track that is
## already playing does nothing, which is what lets the caller ask every frame.
static func play_music(track: String) -> void:
	var it: Sound = _live()
	if it != null:
		it._start(track)


## Play a track and give up the dwell, for a screen that wants its own music and must
## not have the request refused because the last one was recent.
static func play_music_now(track: String) -> void:
	var it: Sound = _live()
	if it != null:
		it._held_since = -DWELL
		it._start(track)


static func play_ambient(terrain: int) -> void:
	var it: Sound = _live()
	if it != null:
		it._under(terrain)


## One noise, now. Unknown names are ignored rather than raised: a cue is the least
## important thing on the screen and must never be the thing that stops a frame.
static func cue(what: StringName) -> void:
	var it: Sound = _live()
	if it != null:
		it._say(what)


static func now_playing() -> String:
	var it: Sound = _live()
	return it._playing if it != null else ""


func _start(track: String) -> void:
	if not MUSIC or track == _playing or track.is_empty():
		return
	var now: float = float(Time.get_ticks_msec()) * 0.001
	# A place is not allowed to be left before it has been arrived in. Without this,
	# walking the boundary between the wood and the road is a stutter rather than a
	# journey.
	if _playing != "" and now - _held_since < DWELL:
		return
	var stream: AudioStream = _stream("Musics/%s" % track)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_held_since = now
	_playing = track
	var going: AudioStreamPlayer = _music[_at]
	_at = 1 - _at
	var coming: AudioStreamPlayer = _music[_at]
	coming.stream = stream
	coming.volume_db = -80.0
	coming.play()
	if muted():
		return
	var fade: Tween = create_tween().set_parallel(true)
	fade.tween_property(coming, "volume_db", MUSIC_DB, FADE)
	fade.tween_property(going, "volume_db", -80.0, FADE)


# ----------------------------------------------------------------- ambience ---

func _under(terrain: int) -> void:
	var wanted: String = String(AMBIENT_ON.get(terrain, ""))
	if wanted == _ambience:
		return
	_ambience = wanted
	if wanted.is_empty():
		_ambient.stop()
		return
	_ambient.stream = _stream("Sounds/Ambient/%s" % wanted)
	_ambient.play()


func _loop_ambient() -> void:
	if not _ambience.is_empty():
		_ambient.play()


# --------------------------------------------------------------------- cues ---

func _say(what: StringName) -> void:
	if muted() or not CUES.has(what):
		return
	var stream: AudioStream = _stream(String(CUES[what]))
	if stream == null:
		return
	_cue.stream = stream
	_cue.play()


func _stream(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path] as AudioStream
	var full: String = "%s/%s" % [PACK, path]
	var stream: AudioStream = load(full) as AudioStream if ResourceLoader.exists(full) else null
	_cache[path] = stream
	if stream == null:
		push_error("no sound at %s" % full)
	return stream
