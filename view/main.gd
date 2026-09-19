extends Node2D

## The window. It reads the simulation and draws it.
##
## Everything that decides anything lives in core/. This file does three things:
## turn key state into submitted events, drive the clock by calling Sim.advance(),
## and draw what the world currently is. It never writes to core/ and it holds no
## game state — the interpolation cache below is render-only, and throwing it away
## would cost one frame of smoothing and nothing else.
##
## _process() here is not game logic. It is the crank.
##
## It is handed its run by `screens.gd` and does not choose one. The fallback in
## `_ready` is for opening this scene on its own, which is worth keeping: a
## screenshot of the world should not have to walk a menu first.

## What this screen asks the game to do next. Only `&"title"` is ever emitted —
## everything else a player can do from here is done inside the world.
signal chose(what: StringName, carrying: Variant)

const TILE: int = Art.TILE
const FIGURE: float = 16.0
## Interpolating across a respawn or a zone change would streak the player over
## the whole map for a frame.
const TELEPORT_TILES: float = 2.0
## How long a thing that just happened stays on screen: two seconds, then the
## world stops mentioning it and never brings it up again.
const MOMENT_STEPS: int = Sim.STEPS_PER_REAL_SECOND * 2
## How many of the most recent entries fit on the page. The journal is a record,
## not a feed: the oldest thing you did is rarely the thing you are trying to
## understand.
const JOURNAL_ROWS: int = 9
## Room under the pause menu's rows for the two lines saying what leaving costs.
const PAUSE_NOTE_ROOM: float = 32.0

var _journal_open: bool = false
## Which page of the journal is showing. Kept between openings: a player who was
## reading the quests wants the quests again.
var _journal_page: int = 0
## The log length the page was built from. A journal held open would otherwise walk
## every event in the run sixty times a second to print the same page.
var _journal_at: int = -1
## Deaths already answered for, so one death triggers one reload.
var _deaths_seen: int = 0

## Somewhere you cannot enter should still say what it is.
var _sim: Sim = null
var _world: WorldState = null
var _cast: Cast = null
var _ticked: WorldTick = null
var _standing: Standing = null
var _road: Travellers = null
var _book: Phrasebook = null
## Whatever chooses words, if anything does. The default asks nothing, so the game
## ships today running entirely on authored lines with this path switched off.
var _phraser: Phraser = Phraser.new()
var _art: Art = null

var _accumulator: float = 0.0
var _seconds_per_step: float = 1.0 / 60.0
var _debug_available: bool = false
var _skipped_days: int = 0
var _held_dir: Vector2i = Vector2i.ZERO
var _fight: Fight = null
## **How far into the fight's framing we are**, 0 at rest and 1 squared up. Eased once,
## here, and read by two things that must not disagree: the 3D lens, which drops and
## tightens by it, and the darkened edge of the screen, which comes up by it. Two
## easings of the same idea in two files drift, and the drift is visible.
var _fight_lens: float = 0.0
## The screen's darkened edge — Yannick's, 2026-09-19: *« en termes de DA ça calibre
## bien ce qu'est un combat »*. It costs no art and no geometry and it works on empty
## ground, which the ring of onlookers in `docs/COMBAT.md` §6 cannot. **It is only a
## picture**: the wall that stops the player leaving is `CombatRules.inside_arena`, in
## the simulation, because a boundary drawn here is a boundary a replay would not have.
var _ring: ColorRect = null
## Set only by `UNCROWNED_FIGHT`, cleared on the first frame the 3D window exists.
var _snap_lens: bool = false
## What the fight's keys were last frame, so one event is sent per **change** and not
## sixty a second. `_held_dir` does the same job for walking, and for the same reason.
var _held_fight: Dictionary = {}
var _real_seconds: float = 0.0
var _render_from: Vector2 = Vector2.ZERO
var _render_to: Vector2 = Vector2.ZERO

var _mine: Allegiance = null
var _map_open: bool = false
## The menu over a stopped world, or null while it is running. Stopping the world is
## the point: the simulation only advances from `_process`, so not calling it is a
## complete pause with nothing to remember to re-enable.
var _paused: Menu = null
## The last thing the world made a noise about, so one event makes one noise. Steps
## rather than booleans: the simulation already stamps when each of these happened.
var _sounded_take: int = -1
var _sounded_theft: int = -1
var _sounded_line: String = ""
## The region, painted once into an image, because 56,000 `draw_rect` calls a frame
## is not a map screen, it is a slideshow.
var _map_image: Texture2D = null
## **The 3D window** (MIGRATION_3D §6, M2a), or null on the 2D map. The baked world is
## seen in three dimensions — his ground, the pixel figures stood up on it — and this
## node reads the same stores this screen does and places things. Everything else
## here — the clock, the input, the HUD, the dialogue, the journal, the map, the
## pause — is unchanged and shared: this screen is the bridge between the simulation
## and whichever window is open. `UNCROWNED_VIEW=2d` keeps the flat view on the baked
## world, for the map and for looking at the bake itself.
var _three_d: World3d = null
@onready var _hud: CanvasLayer = $HUD
@onready var _info: Label = $HUD/Info
@onready var _box: ColorRect = $HUD/DialogueBox
@onready var _speaker: Label = $HUD/DialogueBox/Speaker
@onready var _line: Label = $HUD/DialogueBox/Line
@onready var _choices: Label = $HUD/DialogueBox/Choices
@onready var _prompt: Label = $HUD/Prompt
@onready var _journal_box: ColorRect = $HUD/JournalBox
@onready var _journal_title: Label = $HUD/JournalBox/Title
@onready var _journal_body: Label = $HUD/JournalBox/Body


## The run to play, handed over by `screens.gd` before this enters the tree.
##
## Plain assignment only: this is called before `_ready`, so no `@onready` member
## exists yet and nothing here may touch the HUD.
func begin(carrying: Variant) -> void:
	_sim = carrying as Sim


## Wiring, not logic: one call into core/, then cache what is read every frame.
func _ready() -> void:
	# Ignored when `screens.gd` has already done it, which is every run but a debug
	# one that opens this scene by itself.
	Sound.install(self)
	_art = Art.new()
	_seconds_per_step = Game.seconds_per_step()
	_debug_available = OS.has_feature("debug")
	# Nobody handed us a run, so this scene was opened on its own. A run in progress
	# is on disk as its event log, so starting the game is replaying it; if that
	# fails or there is nothing there, a new run.
	if _sim == null:
		_sim = SaveFile.read()
	if _sim == null:
		_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	_fight = _sim.store(&"fight") as Fight
	_cast = _sim.store(&"cast") as Cast
	_ticked = _sim.store(&"worldtick") as WorldTick
	_mine = _sim.store(&"allegiance") as Allegiance
	_standing = _sim.store(&"standing") as Standing
	_road = _sim.store(&"travellers") as Travellers
	_book = _sim.store(&"phrasebook") as Phrasebook
	# Which of this screen's own overlays to open before the first frame, for the
	# screenshot tool. `screens.gd` routes all three of these here, so there is one
	# variable naming every screen in the game rather than one per overlay.
	if _debug_available:
		match OS.get_environment("UNCROWNED_SCREEN"):
			"map":
				_map_open = true
			"journal":
				_journal_open = true
			"pause":
				_pause_menu()
	var stand: String = OS.get_environment("UNCROWNED_AT")
	if OS.has_feature("debug") and stand.contains(","):
		var parts: PackedStringArray = stand.split(",")
		_world.player_pos = Vector2(float(parts[0]) + 0.5, float(parts[1]) + 0.5)
	# One of the four places, freed for this frame, so §13's free-state ground and its
	# sign can be looked at without playing to them. The same debug gate as the tile
	# above, and listed with it in CLAUDE.md.
	var freed: String = OS.get_environment("UNCROWNED_FREE")
	if OS.has_feature("debug") and freed != "" and _mine != null:
		# Comma-separated, so two places freed at once photograph a crisis at the wall.
		for zone: String in freed.split(","):
			_mine.decide(StringName(zone.strip_edges()), FactionRules.OPPOSITION, _sim.tick)
	# **`UNCROWNED_FIGHT=bram`** — squared up against somebody for the frame `shot.sh`
	# takes, with the lens already dropped and the screen already darkened. The same
	# gate and the same reason as the two above: `--headless` never draws, so the only
	# way to see whether a fight *reads* is to photograph one, and twelve frames is not
	# long enough for a camera that takes a second to move.
	var squaring_up: String = OS.get_environment("UNCROWNED_FIGHT")
	if OS.has_feature("debug") and squaring_up != "":
		# `bram` squares up; `bram:40` squares up and runs forty steps first, so a
		# wind-up or a blow can be photographed rather than only a stand-off.
		var parts: PackedStringArray = squaring_up.strip_edges().split(":")
		_sim.submit(&"fight_began", {"opponent": parts[0]})
		_sim.advance(1)
		if parts.size() > 1 and parts[1].is_valid_int():
			_sim.advance(maxi(parts[1].to_int(), 0))
		_fight_lens = 1.0
		_snap_lens = true
		_draw_ring()

	# **`UNCROWNED_TOWN=cinderworks:9/7`** — a place's two numbers, set for the frame
	# `shot.sh` takes, so an outcome can be looked at before there is a quest to play to
	# it. `place:allegiance/richesse`, comma-separated for more than one. The same debug
	# gate as the two above, and listed with them in CLAUDE.md.
	var towns_set: String = OS.get_environment("UNCROWNED_TOWN")
	var towns_store := _sim.store(&"towns") as TownState
	var changed: bool = false
	if OS.has_feature("debug") and towns_set != "" and towns_store != null:
		for row: String in towns_set.split(","):
			var halves: PackedStringArray = row.strip_edges().split(":")
			if halves.size() != 2:
				continue
			var pair: PackedStringArray = halves[1].split("/")
			var place := StringName(halves[0].strip_edges())
			towns_store.set_value(place, TownRules.ALLEGIANCE, int(pair[0]))
			if pair.size() > 1:
				towns_store.set_value(place, TownRules.RICHESSE, int(pair[1]))
			changed = true
	if changed:
		# **And let the world answer.** Writing the two numbers is not the picture: how
		# many people walk to work is matched when a place *moves*, and a value set
		# straight into the store moves nothing. Six photographs of the three states were
		# taken before this existed and every one of them showed a full shift standing in
		# front of cold furnaces — a picture of the debug tool rather than of the game.
		# An hour is what the population is matched on.
		_sim.advance(Sim.STEPS_PER_WORLD_TICK * 61)
	_render_from = _world.player_pos
	_render_to = _world.player_pos
	if Places.baked() and OS.get_environment("UNCROWNED_VIEW") != "2d":
		var landscape: Dictionary = RegionBake.read_landscape()
		if landscape.is_empty():
			push_error("the baked world is on but his landscape is not at %s; showing it flat" % RegionBake.LANDSCAPE)
		else:
			_three_d = World3d.new()
			_three_d.name = "World3d"
			add_child(_three_d)
			_three_d.build(_world.region(), landscape, _art, _sim)


## What the 3D window needs to place things this frame, read from the same stores this
## screen draws from. Built here so the rules the 2D drawing applies — tents from
## army strength, the crowd from the deserters, the free-state kits, the castle's
## reading — are applied once, by one reader.
func _frame(eye: Vector2) -> Dictionary:
	var tents: int = _tents_standing()
	if _is_free(&"muster"):
		tents = maxi(1, tents / 2)
	return {
		"player": _draw_position(),
		"facing": _world.player_facing,
		"camera": eye,
		"fight_lens": _fight_lens,
		# Where the man in front of you is standing *this frame*. He is an NPC, and an
		# NPC is drawn at his anchor in `content/places.json` — which is where he was
		# before the two of you squared up, and is not where he is now. Handed over
		# rather than looked up, like the towns above: the window is given the reading.
		"fight": {} if _fight == null or not _fight.on() else {
			"who": String(_fight.opponent),
			"at": _fight.at_tiles(_fight.opponent_at_mm),
			"facing": Vector2i(-_fight.toward, 0),
			# What each of them is doing this frame, so the window can *show* it. His
			# brother has drawn no blow and no guard — eight animations, idle and walk
			# in four directions — so the only thing that can read as a wind-up is the
			# figure he already made, moved.
			"toward": _fight.toward,
			"his_move": String(_fight.opponent_move),
			"his_frame": _fight.opponent_frame,
			"my_move": String(_fight.player_move),
			"my_frame": _fight.player_frame,
			"my_stun": _fight.player_stun,
			"his_stun": _fight.opponent_stun,
			"guarding": _fight.pressing_guard and _fight.player_move == &"",
		},
		"tents": tents,
		"crowd": _crowd_size(),
		"free": {
			&"wide_acres": _is_free(&"wide_acres"), &"cairnwell": _is_free(&"cairnwell"),
			&"cinderworks": _is_free(&"cinderworks"), &"muster": _is_free(&"muster"),
		},
		# Where each place stands, in its two numbers (M1). One reader, as with the
		# free-state kits above: the window is handed the reading and never asks the
		# store what it means.
		"towns": _town_rows(),
		"shuttered": CastleRules.wealth(_ticked) == CastleRules.SHUTTERED,
		"escort": _ticked.kings_escort(),
		"extra_guards": CastleRules.extra_guards(CastleRules.instability(_mine, _sim.tick)),
		# §8's immediate register: who would see the act in front of you, when there
		# is one — the same rule `_draw_witnesses` applies to the 2D marks.
		"witnesses": CrimeRules.witnesses_to(_cast, _world.current_zone, _world.player_pos)
			if _can_steal() or _can_give_back() or _can_warn() else [],
		"now": _real_seconds,
	}


## Every place that carries the two numbers, and what they read as.
func _town_rows() -> Dictionary:
	var out: Dictionary = {}
	var towns := _sim.store(&"towns") as TownState
	if towns == null:
		return out
	for id: StringName in towns.ids():
		out[id] = {
			"allegiance": towns.allegiance_of(id),
			"richesse": towns.richesse_of(id),
			"look": String(towns.look_of(id)),
		}
	return out


## **M — the map of Erileo.**
##
## Asked for as a debug tool and worth having as a real one: a game whose whole
## argument is *the road against the forest* should let you see the shape of the
## argument. Every tile in its terrain colour, the eight places named, and where you
## are standing.
##
## Painted once into a texture and kept, because a 280 × 200 region is 56,000 tiles
## and drawing that many rectangles every frame is a slideshow rather than a map.
func _map_texture() -> Texture2D:
	if _map_image != null:
		return _map_image
	var region: Region = _world.region()
	var image := Image.create(region.width, region.height, false, Image.FORMAT_RGBA8)
	for x: int in region.width:
		for y: int in region.height:
			image.set_pixel(x, y, _art.colour_for(region.terrain_at(Vector2i(x, y))))
	_map_image = ImageTexture.create_from_image(image)
	return _map_image


func _draw_map() -> void:
	var region: Region = _world.region()
	var screen: Vector2 = get_viewport_rect().size
	var scale: float = minf((screen.x - 48.0) / float(region.width),
		(screen.y - 64.0) / float(region.height))
	var size := Vector2(float(region.width), float(region.height)) * scale
	var at: Vector2 = -position + (screen - size) * 0.5

	draw_rect(Rect2(-position, screen), Color(0.05, 0.05, 0.07, 0.86), true)
	draw_texture_rect(_map_texture(), Rect2(at, size), false)
	draw_rect(Rect2(at, size), Color(0.75, 0.70, 0.55, 0.9), false, 1.0)

	# The eight places, and the one you are standing in.
	for zone: StringName in Region.ZONE_ORDER:
		var site: Vector2i = Region.zone_sites()[zone] as Vector2i
		var dot: Vector2 = at + Vector2(site) * scale
		draw_circle(dot, 2.5, Color(0.96, 0.93, 0.86, 1.0))
		Ui.write_over(self, dot + Vector2(4.0, 3.0),
			Text.of(StringName("place.short.%s" % zone)), Ui.NOTE,
			Color(0.96, 0.93, 0.86, 0.92))

	# The fairies' clearing, which is not a zone and is where you woke up.
	draw_circle(at + Vector2(Region.CLEARING) * scale, 2.0, Color(0.78, 0.96, 0.80, 1.0))

	Ui.write_over(self, at + Vector2(0.0, -8.0), Text.of(&"map.title"), Ui.HEADING,
		Ui.INK)
	Ui.write_over(self, at + Vector2(0.0, -8.0), Text.of(&"map.close"), Ui.NOTE,
		Ui.DIM, HORIZONTAL_ALIGNMENT_RIGHT, size.x)

	var you: Vector2 = at + _world.player_pos * scale
	draw_circle(you, 3.5, Color(0.15, 0.12, 0.10, 1.0))
	draw_circle(you, 2.5, Color(1.0, 0.42, 0.28, 1.0))


func _process(delta: float) -> void:
	_real_seconds += delta
	if _paused != null:
		_read_pause()
		# Leaving for the title frees this screen inside that call. It is out of the
		# tree but not yet deleted, so the rest of the frame would run on a window
		# that is no longer anybody's.
		if not is_inside_tree():
			return
	else:
		_read_input()
		_accumulator += delta
		while _accumulator >= _seconds_per_step:
			_accumulator -= _seconds_per_step
			_render_from = _world.player_pos
			_sim.advance(1)
			_render_to = _world.player_pos
		_draw_hud()
		_draw_journal()
		_listen()

	# The HUD is a CanvasLayer and therefore draws *over* everything this node draws,
	# including the map and the pause panel. Anything that takes the whole screen
	# takes the HUD with it.
	_hud.visible = _paused == null and not _map_open
	# The journal is itself inside the HUD, so only the two readouts drawn over the
	# world step aside for it.
	_info.visible = not _journal_open
	_prompt.visible = not _journal_open
	# Placed even while paused, so the first frame of a run that opens paused is not
	# a view of the top-left corner of the map.
	# Eased before the frame is built, so the lens and the ring see the same number on
	# the same frame.
	var squared_up: float = 1.0 if (_fight != null and _fight.on()) else 0.0
	_fight_lens = lerpf(_fight_lens, squared_up, 1.0 - exp(-FIGHT_LENS_SETTLES * delta))
	if absf(_fight_lens - squared_up) < 0.002:
		_fight_lens = squared_up
	_draw_ring()

	var eye: Vector2 = _camera_at(delta)
	if _three_d != null:
		# The 3D lens does the following; this canvas stays put, so the overlays
		# drawn at `-position` — the map, the pause — land on the screen.
		position = Vector2.ZERO
		if _snap_lens:
			_snap_lens = false
			_three_d.snap_framing(_fight_lens)
		_three_d.sync(_frame(eye), delta)
	else:
		position = (get_viewport_rect().size * 0.5 - eye * float(TILE)).round()
	queue_redraw()


# ------------------------------------------------------------------- sound ---

## What the world sounds like from where the player is standing, and one noise for
## each thing that just happened.
##
## Asked every frame and answered by a table: `Sound` refuses a track that is already
## playing, so this is a lookup rather than a decision. The one thing decided here is
## that **a theft nobody saw and a theft somebody saw are different sounds** — the
## world tells you it noticed before the journal explains what that cost (§8's
## immediate register).
func _listen() -> void:
	var region: Region = _world.region()
	var here: Vector2i = _world.player_tile()
	var ground: int = region.terrain_at(here)
	Sound.play_music(Sound.track_for(region.zone_at(here), ground))
	Sound.play_ambient(ground)

	if _world.last_taken_step > _sounded_take:
		_sounded_take = _world.last_taken_step
		Sound.cue(&"learnt")
	if _world.last_theft_step > _sounded_theft:
		_sounded_theft = _world.last_theft_step
		Sound.cue(&"took" if _world.last_theft_seen == 0 else &"seen")
	if _world.in_dialogue() and _world.current_line != _sounded_line:
		_sounded_line = _world.current_line
		Sound.cue(&"spoke")
	elif not _world.in_dialogue():
		_sounded_line = ""


# ------------------------------------------------------------------- input ---

## **Escape, with the world stopped.** Everything else on this screen is something
## the player does *in* the world; this is the one thing they do to the run.
##
## It is deliberately not a save menu. §19 settled that you save by resting at a fire,
## and a second way to save would make the fire a formality — so this says plainly
## that leaving costs whatever has happened since the last one.
func _read_pause() -> void:
	if Input.is_action_just_pressed(&"move_down") and _paused.move(1):
		Sound.cue(&"move")
	if Input.is_action_just_pressed(&"move_up") and _paused.move(-1):
		Sound.cue(&"move")
	if Input.is_action_just_pressed(&"back"):
		Sound.cue(&"cancel")
		_paused = null
		return
	if not Input.is_action_just_pressed(&"interact"):
		return
	Sound.cue(&"accept")
	match _paused.chosen():
		&"resume":
			_paused = null
		&"language":
			Text.cycle()
			_cast = Cast.shared()
			_sim.add_store(&"cast", _cast)
			_journal_at = -1
			_pause_menu()
		&"sound":
			Sound.set_muted(not Sound.muted())
			_pause_menu()
		&"title":
			chose.emit(&"title", null)
		&"quit":
			chose.emit(&"quit", null)


func _pause_menu() -> void:
	var was: StringName = _paused.chosen() if _paused != null else &""
	_paused = Menu.new([
		{"id": &"resume", "key": &"pause.resume"},
		{"id": &"language", "key": &"title.language", "args": [Text.locale().to_upper()]},
		{"id": &"sound", "key": &"title.sound",
			"args": [Text.of(&"sound.off" if Sound.muted() else &"sound.on")]},
		{"id": &"title", "key": &"pause.title_screen"},
		{"id": &"quit", "key": &"pause.quit"},
	])
	_paused.point_at(was)


func _read_input() -> void:
	# **A fight takes the keyboard before anything else.** It runs at sixty steps a
	# second with the world's clock held, and nothing else may be open while it does:
	# a dialogue box would read the player's blows as menu choices, and walking would
	# go out as `move_intent` instead of along the fight's own line.
	if _fight != null and _fight.on():
		# Escape still opens the pause menu, because a player must always be able to
		# stop. **It is not a way out of the fight** — Yannick, 2026-09-19: no fleeing
		# in the demo. Closing the menu puts you back in front of him.
		if Input.is_action_just_pressed(&"back"):
			_pause_menu()
			return
		_read_fight_input()
		return
	if not _held_fight.is_empty():
		_held_fight = {}

	if _world.in_dialogue():
		if _held_dir != Vector2i.ZERO:
			_held_dir = Vector2i.ZERO
			_sim.submit(&"move_intent", {"x": 0, "y": 0})
		for index: int in _world.options.size():
			if Input.is_action_just_pressed(StringName("option_%d" % (index + 1))):
				_sim.submit(&"choose_intent", {"intent": String(_world.options[index].intent)})
		if Input.is_action_just_pressed(StringName("option_%d" % _exit_slot())) \
				or Input.is_action_just_pressed(&"interact") \
				or Input.is_action_just_pressed(&"back"):
			_sim.submit(&"end_talk")
		return

	# Escape backs out of whatever is open, one layer at a time, and stops the world
	# when there is nothing left to close. One key that always means "out of this"
	# beats a key per screen that the player has to remember.
	if Input.is_action_just_pressed(&"back"):
		if _map_open:
			_map_open = false
		elif _journal_open:
			_journal_open = false
			_draw_journal()
		else:
			_pause_menu()
		return

	# Left and right turn the journal's pages while it is open, so they cannot also
	# be walking. Reading a page while walking into a bear was never a feature.
	var dir: Vector2i = Vector2i.ZERO if _journal_open else _read_direction()
	if dir != _held_dir:
		_held_dir = dir
		_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})

	if _debug_available and Input.is_action_just_pressed(&"debug_skip_day"):
		_skip_a_day()

	# **G: nothing can take a point off you.** For walking the demo without dying to it.
	# Submitted rather than set, so a run played through it replays through it — see
	# `WorldState.hurt`. Same gate as the day-skip, and listed with it in CLAUDE.md.
	if _debug_available and Input.is_action_just_pressed(&"debug_unkillable"):
		_sim.submit(&"unkillable", {"on": not _world.unkillable})

	if Input.is_action_just_pressed(&"interact"):
		var npc: Npc = _nearby_npc()
		if npc != null:
			_sim.submit(&"talk", {"npc": String(npc.id)})
		elif _can_give_back():
			_sim.submit(&"give_back")
		elif _can_steal():
			_sim.submit(&"steal")
		elif _can_rest():
			_rest()
		elif _papers_in_reach() or _site_in_reach() != "" or _watched_site() != "":
			_sim.submit(&"act")

	# A second key, because the two kinds of act are different kinds of thing and
	# were fighting over one. E is what is in front of you; F is what you carry in
	# your head. Splitting them is also what keeps §8's availability rule true —
	# telling a town must not queue behind a stall that happens to be nearer.
	# Death sends you back to the fire, and the run is rewound with you: the world
	# has to forget what you did between the last rest and dying, or death would
	# cost position and nothing else.
	if _world.deaths > _deaths_seen:
		_deaths_seen = _world.deaths
		Sound.cue(&"died")
		if SaveFile.exists():
			_reload()
			return

	if Input.is_action_just_pressed(&"language"):
		# The cast is written in a language too, so the sheets are reloaded with the
		# HUD. Safe mid-run: sheets are immutable content and standing is keyed on
		# ids, which do not change with the words.
		Text.cycle()
		_cast = Cast.shared()
		_sim.add_store(&"cast", _cast)
		_journal_at = -1

	_find_words()

	if Input.is_action_just_pressed(&"map_screen"):
		_map_open = not _map_open
	if _journal_open:
		if Input.is_action_just_pressed(&"move_right"):
			_turn_page(1)
		if Input.is_action_just_pressed(&"move_left"):
			_turn_page(-1)
	if Input.is_action_just_pressed(&"journal"):
		_journal_open = not _journal_open
		_draw_journal()

	if Input.is_action_just_pressed(&"speak_out"):
		if _can_warn():
			_sim.submit(&"tell_town")
		elif _can_expose():
			_sim.submit(&"expose_fraud")


## The slot that leaves the conversation. One function, used by both the keybind
## and the line the dialogue box prints, because the first version computed it in
## two places: the box offered "4. (say nothing and go)" and nothing was bound to
## 4, so the only way out was a key the game never mentioned.
func _exit_slot() -> int:
	return mini(_world.options.size() + 1, DialogueRules.MAX_OPTIONS)


## Development only. Every remaining consequence in §8 happens *later* — a rumour
## arriving three days after a theft, grain rising a week after the desertions —
## and none of them can be judged by hand without being able to skip forward.
##
## It advances through the ordinary tick path, so a skipped day is identical to a
## waited one: the same drift, the same events, the same replay. Which also means
## a day skipped standing in the Thornwood is a day of being eaten. That is
## correct, and worth knowing before pressing it there.
##
## Gated on a debug build, so it cannot reach anyone who is playing rather than
## making this.
func _skip_a_day() -> void:
	var before: int = _sim.tick
	_sim.advance_world_ticks(Game.TICKS_PER_IN_GAME_DAY)
	_skipped_days += 1
	print("[debug] skipped a day: tick %d -> %d (%s)" % [
		before, _sim.tick, _clock(_sim.tick)])


## The fight's keys: **K** strikes, **O** guards, **I** steps back, and left and right
## walk the line.
##
## One event per change of what is held, which is `CombatSystem`'s contract and the
## reason a saved fight is a handful of rows rather than a recording of the keyboard.
##
func _read_fight_input() -> void:
	var walk: int = 0
	if Input.is_action_pressed(&"move_right"):
		walk += 1
	if Input.is_action_pressed(&"move_left"):
		walk -= 1
	# **Right is east and left is west, always** — and that was a bug until Yannick played
	# it. The fight's own line counts millimetres *towards the opponent*, so pressing
	# right moved the player left whenever the opponent stood west of them. The comment
	# above used to promise F3 would fix it by reading the player's side instead of
	# assuming it, and F3 never did. `Fight.toward` is which way along the world the line
	# runs, so multiplying by it turns a key back into a direction on the screen.
	walk *= _fight.toward
	var want: Dictionary = {
		"attack": Input.is_action_pressed(&"strike"),
		"guard": Input.is_action_pressed(&"guard"),
		# **Pressed, not held.** The other two are states the fight reads every frame;
		# a backstep is one decision, and the simulation spends it on use. Sending the
		# edge keeps that true however long the key is down.
		"evade": Input.is_action_just_pressed(&"evade"),
		"walk": walk,
	}
	# The edge has to go out even when nothing else changed, or a backstep pressed on a
	# frame where the player was already holding nothing would never reach the fight.
	if want == _held_fight and not bool(want["evade"]):
		return
	_held_fight = want
	_sim.submit(&"fight_input", want)


func _read_direction() -> Vector2i:
	var dir := Vector2i.ZERO
	if Input.is_action_pressed(&"move_right"):
		dir.x += 1
	if Input.is_action_pressed(&"move_left"):
		dir.x -= 1
	if Input.is_action_pressed(&"move_down"):
		dir.y += 1
	if Input.is_action_pressed(&"move_up"):
		dir.y -= 1
	return dir


func _nearby_npc() -> Npc:
	var who: Npc = _cast.nearest_to(_world.current_zone, _world.player_pos, Game.TALK_REACH)
	# Somebody who has left is not somebody to prompt about. The simulation refuses
	# the conversation anyway; this is so the window does not offer it.
	if who != null and OpeningRules.is_gone(who.id, _sim.facts):
		return null
	return who


## The stall within reach that still has something on it, or NOWHERE.
func _stall_in_reach() -> Vector2i:
	var at: Vector2i = _world.region().nearest_stall(_world.player_tile(), CrimeRules.STALL_REACH)
	if at == Region.NOWHERE or _world.stall_is_bare(at, _sim.tick):
		return Region.NOWHERE
	return at


func _can_steal() -> bool:
	return _stall_in_reach() != Region.NOWHERE


## Asking the rules layer a question. Reading a pure predicate is not mutating.
func _can_expose() -> bool:
	if _world.current_zone != WorldState.OVERWORLD:
		return false
	var in_muster: bool = _world.region().is_in_muster(_world.player_tile())
	return ArmyRules.can_expose(in_muster, _world.fraud_told_to, _sim.facts)


## Telling a town what is coming. The witnesses are the audience, not the risk.
func _can_warn() -> bool:
	return TellingRules.can_warn(
		_world.region().zone_at(_world.player_tile()),
		_world.fraud_told_to,
		CrimeRules.witnesses_to(_cast, _world.current_zone, _world.player_pos),
		_sim.facts)


## The prompt for whatever can be done to the landmark you are beside, or "".
func _site_in_reach() -> String:
	var site: Dictionary = _world.region().nearest_site(_world.player_tile(), SiteRules.REACH)
	if site.is_empty() or _world.spent_sites.has(site["at"] as Vector2i):
		return ""
	# The quest's act, where the quest has one to offer (Q4).
	var quest: StringName = SiteRules.quest_deed_at(site["kind"] as StringName, _sim.facts)
	if quest != &"":
		return "" if _sim.facts.has(quest) else Text.of(SiteRules.quest_label_key(quest))
	return Text.of(SiteRules.label_key(site["kind"] as StringName))


## Why there is no prompt at a site the watch is standing over. A place must never
## simply fall silent — an absent prompt is indistinguishable from a bug.
func _watched_site() -> String:
	var site: Dictionary = _world.region().nearest_site(_world.player_tile(), SiteRules.REACH)
	if site.is_empty() or _world.spent_sites.has(site["at"] as Vector2i):
		return ""
	if WatchRules.guarded_by(_cast, _world.current_zone, _world.player_pos,
			_ticked.alertness_in(_world.region().zone_at(_world.player_tile()))) == &"":
		return ""
	return Text.of(&"prompt.watched")


func _can_rest() -> bool:
	return _world.region().nearest_campfire(
		_world.player_tile(), RecoveryRules.FIRE_REACH) != Region.NOWHERE


## Sitting down: the world moves eight hours while you do not, and then the run is
## written to disk. Advancing and saving are here rather than in a system because
## both are about the *run* — and a system that wrote a file could not be replayed.
func _rest() -> void:
	_sim.submit(&"rest")
	_sim.advance(Sim.STEPS_PER_WORLD_TICK * RecoveryRules.REST_TICKS)
	SaveFile.write(_sim)
	_deaths_seen = _world.deaths
	Sound.cue(&"rested")


## Rebuild the run from the last rest. Every reference has to be re-taken, because
## replay builds a whole new world rather than rewinding this one.
func _reload() -> void:
	var loaded: Sim = SaveFile.read()
	if loaded == null:
		return
	_sim = loaded
	_world = _sim.store(&"world") as WorldState
	_fight = _sim.store(&"fight") as Fight
	_cast = _sim.store(&"cast") as Cast
	_ticked = _sim.store(&"worldtick") as WorldTick
	_standing = _sim.store(&"standing") as Standing
	_road = _sim.store(&"travellers") as Travellers
	_book = _sim.store(&"phrasebook") as Phrasebook
	_mine = _sim.store(&"allegiance") as Allegiance
	_deaths_seen = _world.deaths
	_journal_at = -1
	# A rebuilt run has its own step numbers, and the old marks would silence the
	# first few things that happen in it.
	_sounded_take = -1
	_sounded_theft = -1
	_sounded_line = ""
	_render_from = _world.player_pos
	_render_to = _world.player_pos


## Papers on the ground you have not picked up yet.
func _papers_in_reach() -> bool:
	var papers: Dictionary = _world.region().nearest_document(
		_world.player_tile(), DocumentRules.REACH)
	return not papers.is_empty() and not _world.holds(papers["fact"] as StringName)


## A document you are carrying and have not yet read out where people could hear.
func _can_read_out() -> bool:
	return TellingRules.tellable_document(
		_world.region().zone_at(_world.player_tile()),
		CrimeRules.witnesses_to(_cast, _world.current_zone, _world.player_pos),
		_world, _sim.facts) != &""


func _can_give_back() -> bool:
	return _world.can_give_back(
		_world.region().nearest_stall(_world.player_tile(), CrimeRules.STALL_REACH))


# ----------------------------------------------------------------- drawing ---

## How far ahead of the player the camera sits, in tiles, and how fast it catches up.
##
## Lookahead shows you where you are going rather than where you have been, which
## matters on a map whose whole point is choosing a route. Kept small: more than a
## tile or two and the player stops being the thing you are looking at.
const CAMERA_LOOKAHEAD: float = 1.6
## How fast the fight's framing comes on and goes off. Slow enough to read as a camera
## move and not a cut — which is the whole of the decision in `SPECS.md` §10.
const FIGHT_LENS_SETTLES: float = 3.2
## The darkened edge. No aspect correction on purpose: the shape follows the screen's,
## so the *borders* close in rather than a circle being laid over the world. `0.42` is
## where it starts and `1.02` is past the corners, so the corners never go fully black.
const RING_SHADER: String = """
shader_type canvas_item;
render_mode unshaded;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float d = smoothstep(0.42, 1.02, length(p));
	COLOR = vec4(0.0, 0.0, 0.0, d * strength * 0.88);
}
"""
## Per second, as a share of the remaining distance. Fast enough that it never feels
## like dragging something, slow enough that changing your mind is visible.
const CAMERA_CATCHES_UP: float = 7.0

var _camera: Vector2 = Vector2.ZERO
var _camera_placed: bool = false


## Where the camera is, as opposed to where the player is.
##
## Eased toward the player plus a lead in the direction they are facing. Snapped
## rather than eased when the player has moved further than they could have walked —
## a death puts them back at a fire, and a camera that *travels* there sweeps the
## whole map and tells everybody where the fairies are.
## **The arena, as a picture.** Built the first time a fight needs it and kept after —
## one `ColorRect` and six lines of shader, which is the whole cost of the thing.
##
## It goes in front of the HUD's own children rather than over them, so the dialogue box
## and the readouts stay legible; and it lives inside the HUD's `CanvasLayer`, so the map
## and the pause panel take it with them when they take the screen.
##
## **`--headless` never draws**, so no test in this project can see this. It was checked
## with `tools/shot.sh`, which is why that tool exists.
func _draw_ring() -> void:
	if _ring == null:
		if _fight_lens <= 0.002:
			return
		_ring = ColorRect.new()
		_ring.name = "Arena"
		_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ring.set_anchors_preset(Control.PRESET_FULL_RECT)
		var shader := Shader.new()
		shader.code = RING_SHADER
		var paint := ShaderMaterial.new()
		paint.shader = shader
		_ring.material = paint
		_hud.add_child(_ring)
		_hud.move_child(_ring, 0)
	_ring.visible = _fight_lens > 0.002
	if _ring.visible:
		(_ring.material as ShaderMaterial).set_shader_parameter("strength", _fight_lens)


func _camera_at(delta: float) -> Vector2:
	var looking: Vector2 = Vector2(_world.player_dir)
	if looking.length() > 0.01:
		looking = looking.normalized()
	var want: Vector2 = _draw_position() + looking * CAMERA_LOOKAHEAD
	# A fight is framed on the arena and not on the player, so backing into the wall
	# does not drag the picture with you. The lookahead goes too — during a fight the
	# held direction is a step along the fight's line, not a way you are heading.
	if _fight != null and _fight.on():
		want = _fight.centre_tiles()
	if not _camera_placed or _camera.distance_to(want) > TELEPORT_TILES:
		_camera = want
		_camera_placed = true
		return _camera
	# Frame-rate independent easing: the same catch-up at 30 fps and at 144.
	_camera = _camera.lerp(want, 1.0 - exp(-CAMERA_CATCHES_UP * delta))
	return _camera


func _draw_position() -> Vector2:
	if _render_from.distance_to(_render_to) > TELEPORT_TILES:
		return _render_to
	var t: float = clampf(_accumulator / _seconds_per_step, 0.0, 1.0)
	return _render_from.lerp(_render_to, t)


func _draw() -> void:
	if _world == null:
		return
	if _three_d != null:
		# The world is the 3D window's; this canvas draws only what lies over it.
		if _map_open:
			_draw_map()
		if _paused != null:
			_draw_paused()
		return
	var region: Region = _world.region()
	var centre: Vector2 = _draw_position()
	# What to draw is decided by where the **camera** is, not where the player is.
	# The two parted company when the camera gained a lead: culling from the player
	# leaves a strip of unpainted ground on the side you are walking toward, and the
	# lead is exactly the size of that strip.
	var eye: Vector2 = _camera if _camera_placed else centre
	var half: Vector2 = get_viewport_rect().size * 0.5 / float(TILE)
	var min_x: int = maxi(floori(eye.x - half.x) - 2, 0)
	var max_x: int = mini(ceili(eye.x + half.x) + 2, region.width - 1)
	var min_y: int = maxi(floori(eye.y - half.y) - 3, 0)
	var max_y: int = mini(ceili(eye.y + half.y) + 2, region.height - 1)

	# Ground first, then everything that stands on it, so a tree drawn at the top
	# of one tile overlaps the tile behind it rather than being clipped by it.
	for x: int in range(min_x, max_x + 1):
		for y: int in range(min_y, max_y + 1):
			_draw_ground(region, x, y)

	# **Canopy.** Everything growing *behind* the player is drawn now; everything in
	# front of them waits until after they are drawn, so walking south through the
	# Thornwood puts you under the branches rather than in front of them. The row the
	# player is standing on is the canopy proper and is drawn faded, because a wood
	# that swallows you is not atmospheric, it is a lost player.
	var on_foot: Vector2i = _world.player_tile()
	for x: int in range(min_x, max_x + 1):
		for y: int in range(min_y, mini(on_foot.y, max_y + 1)):
			_draw_scatter(region, x, y)

	# The Muster's tents are drawn from army strength, so a camp that has been
	# emptying while you were elsewhere looks emptied. This is the visible half of
	# §8's fifth consequence: the world moved without you.
	var tents_standing: int = _tents_standing()
	# §13's free-state ground: a freed place is its own kit with things missing. The
	# Muster strikes half its rows; the Wide Acres loses its fences (below).
	if _is_free(&"muster"):
		tents_standing = maxi(1, tents_standing / 2)
	var crowd: int = _crowd_size()
	var tent: int = 0
	var folk: int = 0
	for prop: Dictionary in region.props:
		var kind: StringName = prop["kind"] as StringName
		if kind == &"fence" and _is_free(&"wide_acres"):
			continue
		if kind == &"tent" or kind == &"tent_b":
			tent += 1
			if tent > tents_standing:
				continue
		elif kind == &"townsfolk":
			folk += 1
			if folk > crowd:
				continue
			_draw_townsfolk(prop["at"] as Vector2i, folk)
			continue
		_draw_prop(prop, min_x, max_x, min_y, max_y)

	for npc: Npc in _cast.in_zone(_world.current_zone):
		if OpeningRules.is_gone(npc.id, _sim.facts):
			continue
		if npc.id == OpeningRules.FAIRY:
			_draw_fairy(npc.centre())
			continue
		_draw_actor(npc.centre(), npc.id, Art.FACE_DOWN)

	_draw_travellers(min_x, max_x, min_y, max_y)

	if _world.current_zone == WorldState.OVERWORLD:
		_draw_escort()
		# Arthur is a person in the cast now and the NPC loop draws him where he
		# stands, which is the tile `king_pos` already named. Drawing him twice put
		# a second king half a pixel behind the first.

	_draw_actor(centre, &"player", Art.column_for(_world.player_facing))

	# The other half of the canopy, over the player.
	for x: int in range(min_x, max_x + 1):
		for y: int in range(maxi(on_foot.y, min_y), max_y + 1):
			var over: bool = y <= on_foot.y + 1 and absi(x - on_foot.x) <= 1
			_draw_scatter(region, x, y, Color(1.0, 1.0, 1.0, 0.55) if over else Color.WHITE)

	_draw_particles(min_x, max_x, min_y, max_y)
	_draw_witnesses()
	if _map_open:
		_draw_map()
	if _paused != null:
		_draw_paused()


## Over the stopped world, in screen coordinates — `-position` undoes the camera, the
## same way the map screen does.
func _draw_paused() -> void:
	var screen: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(-position, screen), Color(0.04, 0.04, 0.05, 0.72), true)
	# Sized from the rows it holds rather than from a number typed once. Adding the
	# sound row to a box measured for four put "quit the game" through the middle of
	# the sentence explaining what quitting costs.
	var body: float = float(_paused.rows.size()) * Menu.SPACING
	var box := Rect2(-position + Vector2(screen.x * 0.5 - 130.0, 96.0),
		Vector2(260.0, 78.0 + body + PAUSE_NOTE_ROOM))
	Ui.panel(self, box)
	Ui.write(self, box.position + Vector2(0.0, 30.0), Text.of(&"pause.heading"),
		Ui.HEADING, Ui.GOLD, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	_paused.draw_on(self, box.position.x + 42.0, box.position.y + 58.0)
	draw_multiline_string(Ui.font(),
		box.position + Vector2(16.0, box.size.y - PAUSE_NOTE_ROOM + 12.0),
		Text.of(&"pause.note"), HORIZONTAL_ALIGNMENT_CENTER, box.size.x - 32.0,
		Ui.NOTE, 2, Ui.DIM)


## How many of the Muster's tents are still up. Struck in proportion to the army
## that pitched them, never all of them: a camp with nobody in it is a ruin, and
## the Muster is not one yet.
func _tents_standing() -> int:
	var total: int = 0
	for prop: Dictionary in _world.region().props:
		var kind: StringName = prop["kind"] as StringName
		if kind == &"tent" or kind == &"tent_b":
			total += 1
	var share: float = clampf(_ticked.army_strength, 0.0, 100.0) / 100.0
	return clampi(ceili(float(total) * share), 1, total)


## How many people are standing about in Harrowgate: nobody extra while the army
## is whole, the full crowd once it has emptied out. The bread price explained by
## bodies rather than by a number, which is §8's ambient register.
func _crowd_size() -> int:
	var lost: float = clampf(100.0 - _ticked.army_strength, 0.0, 100.0)
	var total: int = 0
	for prop: Dictionary in _world.region().props:
		if (prop["kind"] as StringName) == &"townsfolk":
			total += 1
	return clampi(roundi(float(total) * lost / 60.0), 0, total)


func _draw_townsfolk(at: Vector2i, index: int) -> void:
	var sheet: Texture2D = _art.townsfolk_sheet(index)
	if sheet == null:
		return
	# Facing decided by where they stand, so a crowd is not a rank of clones all
	# looking the same way.
	var facing: int = Art.scatter_hash(at.x, at.y) % 4
	var top_left: Vector2 = (Vector2(at) + Vector2(0.5, 0.5)) * float(TILE) \
		- Vector2(FIGURE, FIGURE) * 0.5
	draw_texture_rect_region(
		sheet, Rect2(top_left.round(), Vector2(FIGURE, FIGURE)), Art.tile_rect(facing, 0))


func _draw_ground(region: Region, x: int, y: int) -> void:
	var dest := Rect2(float(x * TILE), float(y * TILE), float(TILE), float(TILE))
	var terrain: int = region.terrain_at(Vector2i(x, y))

	# **Shorelines.** Water that touches anything else is drawn as its own bank, so a
	# coast is a coast rather than a straight line between two colours. The bank is
	# chosen by what it is meeting: sand against a beach, grass against a field.
	if Art.is_water(terrain):
		var here := Vector2i(x, y)
		var around: Array = [
			Art.is_water(region.terrain_at(here + Vector2i(0, -1))),
			Art.is_water(region.terrain_at(here + Vector2i(1, 0))),
			Art.is_water(region.terrain_at(here + Vector2i(0, 1))),
			Art.is_water(region.terrain_at(here + Vector2i(-1, 0))),
			Art.is_water(region.terrain_at(here + Vector2i(1, -1))),
			Art.is_water(region.terrain_at(here + Vector2i(-1, -1))),
			Art.is_water(region.terrain_at(here + Vector2i(1, 1))),
			Art.is_water(region.terrain_at(here + Vector2i(-1, 1))),
		]
		var bank: Vector2i = Art.BANK_GRASS
		for step: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			if region.terrain_at(here + step) == Region.Terrain.SAND:
				bank = Art.BANK_SAND
		var edge: Vector2i = Art.water_edge(bank, around)
		if edge.x >= 0:
			draw_texture_rect_region(
				_art.atlas(&"water"), dest, Art.tile_rect(edge.x, edge.y))
			return

	# The surface, base or detail, hashed off the position so it never shimmers.
	# Towns are asked which town they are, so a quay is planks and a capital is paved.
	var ground: Array = Art.ground_tile(terrain, x, y,
		region.zone_at(Vector2i(x, y)) if terrain == Region.Terrain.TOWN
			or terrain == Region.Terrain.CAMP else &"")
	if not ground.is_empty():
		var cell: Vector2i = ground[1] as Vector2i
		draw_texture_rect_region(
			_art.atlas(ground[0] as StringName), dest, Art.tile_rect(cell.x, cell.y))
		return

	var entry: Array = _art.terrain_tiles.get(terrain, []) as Array
	if entry.is_empty():
		draw_rect(dest, _art.colour_for(terrain), true)
		return

	var column: int = entry[1] as int
	var row: int = entry[2] as int
	# **No column-shift animation here, and a note about why**, because it looks like
	# an obvious thing to add and it is wrong.
	#
	# `TilesetWater.png` is a sheet of **autotile blobs**, not animation frames: each
	# patch of water is a 3×3 of interior plus shoreline, and the tile beside an
	# interior tile is its *edge*, not its next frame. Nudging the column by one to
	# animate it walked the whole sea onto shoreline tiles, which is why the ocean
	# came out covered in tan blobs. Shipped for one night, found by looking at it.
	#
	# Water is animated properly below — by its shoreline, which `_water_frame`
	# picks from the blob — and anything wanting a moving surface needs a sheet that
	# actually has frames.
	# Break up the flat fills so ground does not read as graph paper.
	if terrain == Region.Terrain.WILD or terrain == Region.Terrain.FOREST:
		if Art.scatter_hash(x + 7, y + 3) < 90:
			column = 15
	elif terrain == Region.Terrain.FARMLAND:
		# Crop rows, which is what tells a field from a lawn at a glance.
		row = 4 if (y / 2) % 2 == 0 else 1
	draw_texture_rect_region(
		_art.atlas(entry[0] as StringName), dest, Art.tile_rect(column, row))


func _draw_scatter(region: Region, x: int, y: int, tint: Color = Color.WHITE) -> void:
	var entry: Array = _art.scatter_at(region.terrain_at(Vector2i(x, y)), x, y)
	if entry.is_empty():
		return
	var source: Rect2i = entry[1] as Rect2i
	# Anchored by the foot, not the corner, so a tree stands on its tile.
	var at := Vector2(
		float(x * TILE) + float(TILE) * 0.5 - float(source.size.x) * 0.5,
		float((y + 1) * TILE) - float(source.size.y),
	)
	draw_texture_rect_region(
		_art.atlas(entry[0] as StringName),
		Rect2(at.round(), Vector2(source.size)),
		Rect2(source), tint)


## Embers over the kilns, and smoke off the fires.
##
## Drawn rather than spawned: there is no particle node anywhere in this game, and
## adding one would mean a scene tree the window does not otherwise need. A few dozen
## sine waves cost nothing and stop at the edge of the screen.
##
## Deliberately only two places — the furnaces, because the Cinderworks running is the
## thing the whole map is about, and the campfires, because a fire you can save at
## should look like one from across a field.
func _draw_particles(min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	var now: float = _real_seconds
	for prop: Dictionary in _world.region().props:
		var kind: StringName = prop["kind"] as StringName
		var embers: int = 0
		var colour := Color.WHITE
		# A freed Cinderworks is cold: the same kilns, no embers (§13).
		if kind == &"kiln" and not _is_free(&"cinderworks"):
			embers = 5
			colour = Color(1.0, 0.62, 0.28, 0.75)
		elif kind == &"campfire":
			embers = 3
			colour = Color(1.0, 0.74, 0.40, 0.70)
		if embers == 0:
			continue
		var at: Vector2i = prop["at"] as Vector2i
		if at.x < min_x - 2 or at.x > max_x + 2 or at.y < min_y - 2 or at.y > max_y + 2:
			continue
		var base := Vector2(float(at.x) + 0.5, float(at.y)) * float(TILE)
		for i: int in embers:
			# Each ember has its own period and its own drift, so the group never
			# pulses together — which is the thing that reads as fake.
			var life: float = fposmod(now * (0.34 + float(i) * 0.07) + float(i) * 0.41, 1.0)
			var rise: float = life * 22.0
			var sway: float = sin((now + float(i) * 2.1) * 1.7) * (2.0 + life * 4.0)
			var fade: float = colour.a * (1.0 - life) * (1.0 - life)
			draw_circle(base + Vector2(sway, -rise), 1.0 + (1.0 - life), Color(
				colour.r, colour.g, colour.b, fade))


func _draw_prop(prop: Dictionary, min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	var at: Vector2i = prop["at"] as Vector2i
	var size: Vector2i = prop.get("size", Vector2i(4, 3)) as Vector2i
	if at.x > max_x or at.y > max_y or at.x + size.x < min_x or at.y + size.y < min_y:
		return
	var entry: Array = _art.props.get(prop["kind"] as StringName, []) as Array
	if entry.is_empty():
		return
	var source: Rect2i = entry[1] as Rect2i
	# Footed on the bottom of its footprint and centred across it, so a tall
	# building overhangs the tiles behind rather than floating above them.
	var dest := Vector2(
		float(at.x * TILE) + float(size.x * TILE) * 0.5 - float(source.size.x) * 0.5,
		float((at.y + size.y) * TILE) - float(source.size.y),
	)
	# **Occlusion fade.** A building the player is standing behind goes part
	# transparent, so walking behind the counting house does not mean disappearing
	# for four seconds. Judged on the drawn rectangle rather than the footprint,
	# because what hides the player is the part that overhangs — a tall roof covers
	# tiles nobody is standing on.
	var covers: bool = Rect2(dest, Vector2(source.size)).grow(-2.0).has_point(
		_draw_position() * float(TILE))
	var tint: Color = Color(1.0, 1.0, 1.0, 0.45) if covers else Color.WHITE
	# A shuttered counting house: the same building, unlit, once the bank is the
	# creditor's rather than the crown's (§13's free variant).
	if (prop["kind"] as StringName) == &"counting_house" and _is_free(&"cairnwell"):
		tint = tint.darkened(0.4)
	# And the castle's wealth reading (§4): shuttered works and an unfinished wall,
	# drawn as the keep, the towers and the gate gone dark.
	var kind: StringName = prop["kind"] as StringName
	if (kind == &"keep" or kind == &"tower" or kind == &"gatehouse") \
			and CastleRules.wealth(_ticked) == CastleRules.SHUTTERED:
		tint = tint.darkened(0.35)
	draw_texture_rect_region(
		_art.atlas(entry[0] as StringName),
		Rect2(dest.round(), Vector2(source.size)),
		Rect2(source), tint)


## The fairy, who is **light and movement and not a body**.
##
## There is no fairy in the asset pack, §13 forbids mixing packs, and a twinkling
## humanoid would undo the plain register the whole cast was rewritten for — so she
## is drawn rather than sprited. She still has to be *visible*: something the eye can
## find and follow, not a voice from nowhere.
##
## Three soft discs and a few motes that drift on their own clock. Deliberately
## dimmer and slower than anything else on screen, because she is dying.
func _draw_fairy(at: Vector2) -> void:
	var centre: Vector2 = at * float(TILE)
	var now: float = float(Time.get_ticks_msec()) * 0.001
	# The glow: three discs, the outermost barely there. Breathing slowly.
	var breath: float = 0.82 + 0.18 * sin(now * 1.1)
	for ring: int in 3:
		var radius: float = (14.0 - float(ring) * 4.0) * breath
		var alpha: float = 0.07 + float(ring) * 0.09
		draw_circle(centre, radius, Color(0.78, 0.94, 0.80, alpha))
	# And the motes, on their own periods so the pattern never repeats cleanly.
	for mote: int in 5:
		var phase: float = now * (0.5 + float(mote) * 0.13) + float(mote) * 1.7
		var sway: Vector2 = Vector2(cos(phase) * 9.0, sin(phase * 0.7) * 6.0 - 3.0)
		draw_circle(centre + sway, 1.2, Color(0.90, 1.0, 0.88, 0.55))


func _draw_actor(at: Vector2, role: StringName, column: int) -> void:
	var sheet: Texture2D = _art.sheet_for(role)
	if sheet == null:
		return
	var top_left: Vector2 = at * float(TILE) - Vector2(FIGURE, FIGURE) * 0.5
	draw_texture_rect_region(
		sheet,
		Rect2(top_left.round(), Vector2(FIGURE, FIGURE)),
		Art.tile_rect(column, 0),
	)


## §8's IMMEDIATE register, before the act rather than after it.
##
## Whoever can see you is marked while there is an act in front of you that they
## would see you do. No count and no number: *who* is the part that matters, because
## Maddox seeing you is not the same event as a stranger seeing you, and the sight
## radius is learnt by walking until the marks go out rather than by being told a
## figure.
##
## The same marks serve both signs. Over a stall they mean "who would see this"; with
## something to tell they mean "who would hear it" — which is the whole of why
## telling is the mirror of theft rather than a separate mechanic wearing its coat.
##
## Shown only with a stall in reach. A permanent readout of who can see you is
## surveillance furniture; this is the answer to a question the player is asking at
## exactly that moment.
func _draw_witnesses() -> void:
	if not (_can_steal() or _can_give_back() or _can_warn()):
		return
	for id: String in CrimeRules.witnesses_to(_cast, _world.current_zone, _world.player_pos):
		var npc: Npc = _cast.get_npc(StringName(id))
		if npc == null:
			continue
		var head: Vector2 = (npc.centre() * float(TILE) - Vector2(0.0, float(FIGURE) * 0.5 + 4.0)).round()
		draw_circle(head, 2.6, Color(0.08, 0.07, 0.10, 0.85))
		draw_circle(head, 1.5, Color(0.93, 0.88, 0.68, 0.95))


## People on the King's Road. Drawn from the crowd's faces, because that is what
## they are: nobody, and never the same one twice.
##
## They are simulated for the whole map whether or not you are looking, which is
## the point — a carrier who stops existing when you turn away cannot deliver
## anything. Only the drawing is culled.
##
## **Drawn as traffic, not as people** (2026-09-13, §13): a pack horse walking the
## road, never a face from any sheet the cast or the crowd uses. The side sheet faces
## left; a walker heading the other way is the same frame drawn with a negative width.
func _draw_travellers(min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	if _road == null:
		return
	var sheet: Texture2D = _art.traffic_sheet()
	if sheet == null:
		return
	var line: Array[Vector2i] = _world.region().road_waypoints()
	var size := Vector2(Art.TRAFFIC_FRAME)
	for walker: Traveller in _road.walkers:
		var at: Vector2i = walker.tile()
		if at.x < min_x or at.x > max_x or at.y < min_y or at.y > max_y:
			continue
		# Which way it is actually going, read off the next waypoint rather than off
		# the leg index, which says nothing about east or west.
		var facing_right: bool = false
		if not line.is_empty():
			var target: int = clampi(walker.leg + walker.heading, 0, line.size() - 1)
			facing_right = float(line[target].x) + 0.5 > walker.pos.x
		# Two frames, alternated by where it stands, so a walking animal walks.
		var frame: int = absi(int(floorf(walker.pos.x + walker.pos.y))) % 2
		var src := Rect2(float(frame * Art.TRAFFIC_FRAME.x), 0.0, size.x, size.y)
		var rect := Rect2((walker.pos * float(TILE) - size * 0.5).round(), size)
		if facing_right:
			rect.position.x += size.x
			rect.size.x = -size.x
		draw_texture_rect_region(sheet, rect, src)



## The escort, drawn because it has to be *seen* to drop. Ten bodies in two ranks
## in front of the gate; five after the Muster empties.
func _draw_escort() -> void:
	for i: int in _ticked.kings_escort():
		var rank: int = i / 5
		var file: int = i % 5
		var at: Vector2 = _world.king_pos + Vector2(float(file) - 2.0, 2.0 + float(rank) * 1.2)
		_draw_actor(at, &"guard", Art.FACE_DOWN)
	# §4's instability reading, on the wall: more guards than the escort accounts for,
	# posted either side of the gate. Drawn from the reading, never stored, and never
	# fought — the escort is the number the endings read; this is what the wall looks
	# like from the road when places have been changing hands.
	var unrest: StringName = CastleRules.instability(_mine, _sim.tick)
	var posts: Array[Vector2] = [Vector2(-5.0, 9.0), Vector2(3.0, 9.0), Vector2(-8.0, 9.0), Vector2(11.0, 9.0)]
	for i: int in CastleRules.extra_guards(unrest):
		_draw_actor(_world.king_pos + posts[i], &"guard", Art.FACE_DOWN)


# --------------------------------------------------------------------- hud ---

## Somewhere you cannot enter should still say what it is. The Muster is a camp on
## the road, not a town, and looking identical to Harrowgate's gate while refusing
## to open is the kind of thing a player reasonably reads as broken.
## A line the player may speak, with its trait bracket in their language.
func _option_label(option: DialogueOption) -> String:
	var key: StringName = option.tag_key()
	if key == &"":
		return option.text
	return Text.of(&"option.tagged", [Text.of(key), option.text])


## Ask whoever chooses words whether they have any for what is on screen now.
##
## Runs beside the simulation rather than inside it. Anything it gets back is
## submitted as an ordinary event, so the words end up in the log, in the save file
## and in a replay, exactly like a keypress. Nothing here can break a run: if the
## phraser is absent, slow or wrong, the authored line stays on screen.
func _find_words() -> void:
	if not _world.in_dialogue() or not _phraser.ready():
		return
	var npc: Npc = _cast.get_npc(_world.talking_to)
	if npc == null:
		return
	var option: DialogueOption = DialogueRules.find(npc, _world.last_intent)
	# No facts declared for this answer, so nothing may replace it. The gate that
	# lets generation be turned on one line at a time instead of all at once: an
	# option nobody has briefed is exactly as it was before any of this existed.
	if not Answers.shared().may_be_written(npc.id, _world.last_intent):
		return
	var packet: String = Context.build(npc.id, _world, _cast, _standing, _ticked,
		_sim.facts, Relations.shared(), option)
	var key: String = Phrasebook.key_for(packet, _world.last_intent)
	_book.asked += 1
	if _book.remembers(key):
		_book.served += 1
		_world.current_line = _book.recall(key)
		return
	var line: String = _phraser.phrase(packet, option, Text.locale())
	if line != "":
		_sim.submit(&"phrased", {
			"key": key, "line": line, "for": String(npc.id)})


## The clock, in the player's language.
func _clock(tick: int) -> String:
	return Text.of(&"clock.day", Game.in_game_clock_parts(tick))


func _place_name() -> String:
	var zone: StringName = _world.region().zone_at(_world.player_tile())
	if Region.is_place(zone):
		return Text.of(StringName("place.%s" % zone))
	match _world.region().terrain_at(_world.player_tile()):
		Region.Terrain.ROAD:
			return Text.of(&"place.road")
		Region.Terrain.FORD:
			return Text.of(&"place.ford")
		Region.Terrain.FOREST:
			return Text.of(&"place.forest")
		Region.Terrain.MARSH:
			return Text.of(&"place.marsh")
		Region.Terrain.FARMLAND:
			return Text.of(&"place.farmland")
		Region.Terrain.SAND:
			return Text.of(&"place.coast")
	return Text.of(&"place.wild")


## §8's AMBIENT register: how the place you are standing in regards you.
##
## Per place and never global, so walking out of Harrowgate and into Cairnwell
## changes the word — which teaches that reputation has an address without a line
## of explanation. Shown from the first minute, including at neutral, because a
## baseline is what makes the change legible; a readout that only appears once
## something has gone wrong gives the player nothing to compare it against.
##
## It says how you are regarded. It never says why, and it never moves at the
## moment of the act — it moves when the story gets here, which may be days after
## you left. Push the ambient, pull the attribution.
func _regard() -> String:
	if _standing == null:
		return ""
	var zone: StringName = _world.region().zone_at(_world.player_tile())
	if zone == &"":
		return ""
	return Text.of(&"hud.regard", [Text.of(StringName("regard.%s" % StandingRules.word_for(_standing.in_town(zone))))])


func _draw_hud() -> void:
	var walked: int = int(_real_seconds)
	var where: String = _place_name()
	var lines: Array[String] = [
		Text.of(&"hud.line", [where, _regard(), _world.player_hp, WorldState.MAX_HP, _world.deaths]),
		Text.of(&"hud.escort", [_ticked.kings_escort()]),
	]
	if _world.current_zone == WorldState.OVERWORLD:
		lines.append(Text.of(&"hud.to_blackcairn", [int(round(_world.tiles_to_blackcairn()))]))
	lines.append(Text.of(&"hud.clock",
		[_clock(_sim.tick), walked / 60, "%02d" % (walked % 60)]))
	lines.append(Text.of(&"hud.language", [Text.locale().to_upper()]))
	if _debug_available:
		lines.append("[T] skip a day%s" % ("   ·   %d skipped" % _skipped_days if _skipped_days > 0 else ""))
		if _world.unkillable:
			lines.append("[G] INVULNÉRABLE")
	_info.text = "\n".join(lines)

	_box.visible = _world.in_dialogue()
	if _world.in_dialogue():
		_speaker.text = _world.speaker_name
		_line.text = _world.current_line
		var rows: Array[String] = []
		for index: int in _world.options.size():
			rows.append("%d. %s" % [index + 1, _option_label(_world.options[index])])
		rows.append(Text.of(&"prompt.exit", [_exit_slot()]))
		_choices.text = "\n".join(rows)
		_prompt.text = ""
		return

	# Nothing to press while a fight is on, and "E, talk to Bram" over the top of a man
	# swinging at you reads as a bug.
	if _fight != null and _fight.on():
		_prompt.text = ""
		return

	var rows: Array[String] = []
	var done: String = _just_happened()
	if done != "":
		rows.append(done)
	var mood: String = _atmosphere()
	if mood != "":
		rows.append(mood)
	var sign: String = _sign()
	if sign != "":
		rows.append(sign)

	var npc: Npc = _nearby_npc()
	if _can_rest():
		rows.append(Text.of(&"prompt.rest"))
	elif _papers_in_reach():
		rows.append(Text.of(&"prompt.papers"))
	elif npc != null:
		rows.append(Text.of(&"prompt.talk", [npc.display_name, npc.role.to_lower()]))
	elif _can_give_back():
		rows.append(Text.of(&"prompt.put_back"))
	elif _can_steal():
		# Who is watching is drawn over their heads, not counted here. The prompt
		# never says what it will cost: the world shows, the journal explains (§8).
		rows.append(Text.of(&"prompt.take"))
	elif _world.region().nearest_stall(_world.player_tile(), CrimeRules.STALL_REACH) != Region.NOWHERE:
		rows.append(Text.of(&"prompt.picked_clean"))
	elif _site_in_reach() != "":
		rows.append(_site_in_reach())
	elif _watched_site() != "":
		rows.append(_watched_site())

	# Its own row, never an `elif`. What you know is available wherever you are
	# standing, and burying it behind whatever happens to be nearer would make the
	# act that raises a town harder to reach than the act that lowers one.
	if _can_read_out():
		rows.append(Text.of(&"prompt.read_out"))
	elif _can_warn() or _can_expose():
		rows.append(Text.of(&"prompt.say"))
	_prompt.text = "\n".join(rows)


## §8's IMMEDIATE register: the act, confirmed at the moment it happens, and
## nothing else.
##
## It says what you did and who looked up. It does not say what it will cost,
## because the cost has not happened yet and will not happen here — that is the
## ambient register's business, three days' walk away, and the player is meant to
## be the one who joins them up. Push the ambient, pull the attribution.
func _just_happened() -> String:
	# Papers first: picking one up is the quieter act and the one that was silent.
	# Taking a document told the player nothing at all — no line, no name, nothing
	# to say what they now had (found in play, 2026-09-12).
	if _world.last_taken_step >= 0 and _sim.step - _world.last_taken_step <= MOMENT_STEPS:
		return Text.of(&"moment.took_papers",
			[Text.of(StringName("doc.%s" % _world.last_taken))])
	if _world.last_theft_step < 0:
		return ""
	if _sim.step - _world.last_theft_step > MOMENT_STEPS:
		return ""
	if _world.last_theft_seen == 0:
		return Text.of(&"moment.took.none")
	if _world.last_theft_seen == 1:
		return Text.of(&"moment.took.one")
	return Text.of(&"moment.took.many", [_world.last_theft_seen])


## §8's NARRATED register, and the only screen allowed to join an act to its
## consequence.
##
## The world never says "your actions caused this". It changes its mind quietly and
## the player comes here to find out why — which is why this is behind a key rather
## than a notification. Push the ambient, pull the attribution.
func _draw_journal() -> void:
	_journal_box.visible = _journal_open
	if not _journal_open:
		_journal_at = -1
		return
	if _journal_at == _sim.events.size():
		return
	_journal_at = _sim.events.size()
	var pages: Array[Dictionary] = _journal_pages()
	_journal_page = posmod(_journal_page, pages.size())
	var page: Dictionary = pages[_journal_page]
	_journal_title.text = "%s      %s" % [
		Text.of(&"journal.title", [_clock(_sim.tick)]),
		Text.of(&"journal.paging", [Text.of(page["name"] as StringName),
			_journal_page + 1, pages.size()]),
	]
	_journal_body.text = "\n".join(page["lines"] as Array[String])


## Turn to the next page, and make the next frame rebuild it.
func _turn_page(by: int) -> void:
	_journal_page += by
	_journal_at = -1


## §8's NARRATED register, **as pages rather than as one scroll**.
##
## It was one list and it had outgrown the box long before anybody noticed: the
## quests, the two factions and the debug roll of everybody's position ran off the
## bottom, where a Label draws the lines that fit and says nothing about the rest.
## Widening the font made it visible, which is the only reason it was found.
##
## Two things come out of that. A page per question the player might be asking, so a
## new section is a row here rather than a squeeze. And **every page is cut to the box
## rather than trusted to fit** — silently losing the end of a page is the bug; losing
## the oldest blocks and saying how many is a page.
func _journal_pages() -> Array[Dictionary]:
	var pages: Array[Dictionary] = [
		{"name": &"journal.doings", "blocks": _page_doings()},
		{"name": &"journal.holds", "blocks": _page_the_king()},
		{"name": &"journal.kingdom", "blocks": _page_kingdom()},
		{"name": &"journal.quests", "blocks": _page_quests()},
		{"name": &"journal.side", "blocks": _page_you()},
	]
	var known: Array[Array] = _page_known()
	if not known.is_empty():
		pages.append({"name": &"journal.known", "blocks": known})
	# Everybody with a name, where they stand, and how far off, nearest first. A
	# playtest tool: eighteen more people arrive over Phase 6 and "walk about until
	# you find him" is not a way to review a character. Gated on a debug build and
	# written down in CLAUDE.md, like the day-skip — a debug tool nobody recorded is
	# one that ships.
	if _debug_available:
		pages.append({"name": &"journal.who", "blocks": _page_who()})
	for page: Dictionary in pages:
		page["lines"] = _last_that_fit(page["blocks"] as Array[Array])
	return pages


## How many lines of the box a string takes once it has wrapped.
func _rows_for(line: String, width: float, size: int) -> int:
	return maxi(1, ceili(Ui.width_of(line, size) / width))


## As much of the end of a page as the box will hold, and a line saying what was left
## out. Blocks rather than lines, because an entry and the reason underneath it are
## one thing and half of one is worse than neither.
##
## The end rather than the start: on every page here the last block is the one being
## looked for — the newest deed, the nearest person, the most recent thing learnt.
func _last_that_fit(blocks: Array[Array]) -> Array[String]:
	var size: int = _journal_body.get_theme_font_size(&"font_size")
	var width: float = _journal_body.size.x
	# One line held back for the count, so saying "and 4 more" cannot itself overflow.
	var room: int = floori(_journal_body.size.y / Ui.font().get_height(size)) - 1
	var kept: Array[Array] = []
	var used: int = 0
	for at: int in range(blocks.size() - 1, -1, -1):
		var cost: int = 0
		for line: String in blocks[at]:
			cost += _rows_for(line, width, size)
		if used + cost > room:
			break
		used += cost
		kept.push_front(blocks[at])
	var out: Array[String] = []
	if kept.size() < blocks.size():
		out.append(Text.of(&"journal.more", [blocks.size() - kept.size()]))
	for block: Array in kept:
		out.append_array(block)
	return out


## What you did, oldest first, with why it mattered under each line.
func _page_doings() -> Array[Array]:
	var blocks: Array[Array] = []
	for row: Dictionary in Journal.entries(_sim.events):
		var block: Array[String] = [
			"%s   %s" % [_clock(int(row["tick"])), _journal_line(row)]]
		var because: String = _journal_because(row)
		if because != "":
			block.append("                  %s" % because)
		blocks.append(block)
	if blocks.is_empty():
		blocks.append([Text.of(&"journal.empty")] as Array[String])
	return blocks


## §15's second page. A predicate over ten numbers is invisible, and without this
## "push the world until he cannot hold it" is guesswork. State and attribution only:
## it says the treasury is empty and that you emptied it, and never that you should
## rob the bank next.
func _page_the_king() -> Array[Array]:
	var blocks: Array[Array] = []
	for row: Dictionary in EndRules.what_holds_him_up(_ticked, _world, _sim.facts):
		blocks.append(["- %-30s %5d%s" % [
			Text.of(row["name_key"] as StringName), int(round(float(row["value"]))),
			Text.of(&"journal.yours") if float(row["yours"]) > 0.0 else "",
		]] as Array[String])
	# What became of the wood, once she has told the player it is happening. Her last
	# word is "if you can, save us", and without this that is a request the player can
	# satisfy and never find out about.
	if OpeningRules.knows_about_the_wood(_sim.facts):
		var wood: Dictionary = OpeningRules.wood_row(_ticked)
		var said: StringName = &"journal.wood.holding"
		if bool(wood.get("gone", false)):
			said = &"journal.wood.gone"
		elif bool(wood.get("falling", false)):
			said = &"journal.wood.falling"
		blocks.append(["", Text.of(&"journal.wood"),
			Text.of(said, [int(wood.get("paces", 0))])] as Array[String])
	if _world.reign_ended != &"":
		var block: Array[String] = ["", Text.of(&"journal.deposed",
			[Text.of(StringName("end.%s" % _world.reign_ended))])]
		# And whether the thing she asked for happened. This is the one place the five
		# endings stop being five ways to win: a reign ended while the wood was still
		# being cleared reads differently from one ended after it stopped.
		if OpeningRules.knows_about_the_wood(_sim.facts):
			block.append(Text.of(&"journal.wood.gone" if _ticked.held_ground <= 0.0
				else (&"journal.wood.lost" if _ticked.steel_output > 0.0
					else &"journal.wood.saved")))
		# §3's throne reading. If the throne is the player's, the ending shows one thing
		# of what they do with it: the towns they changed, the morning after, in words.
		if _world.reign_reading != &"":
			block.append(Text.of(StringName("journal.throne.%s" % _world.reign_reading)))
			if _world.reign_reading == EndRules.CROWNED:
				for town: StringName in Region.ZONE_ORDER:
					var lot: float = _ticked.hardship_in(town)
					if absf(lot - WorldTick.NEUTRAL) < 0.5:
						continue
					block.append(Text.of(&"journal.throne.worse" if lot > WorldTick.NEUTRAL
						else &"journal.throne.better", [_short_place(town)]))
		blocks.append(block)
	return blocks


## §15's kingdom page (2026-09-13). The thesis says the ending is a reading of what
## the kingdom became; this is where the player reads it before the end. Pulled, like
## every page, and it never scores: words for the places, the people and the castle,
## with whose doing it was beside each — never a number, never advice.
func _page_kingdom() -> Array[Array]:
	var places: Array[String] = [Text.of(&"journal.kingdom.places")]
	var people: Array[String] = ["", Text.of(&"journal.kingdom.hardship")]
	var castle: Array[String] = ["", Text.of(&"journal.kingdom.castle")]
	for row: Dictionary in Journal.kingdom(_mine, _ticked, _sim.tick):
		match row["kind"] as StringName:
			&"place":
				var who: String = ""
				if int(row["tick"]) >= 0:
					who = Text.of(&"journal.kingdom.by_you" if bool(row["by_player"])
						else &"journal.kingdom.turned", [_clock(int(row["tick"]))])
				places.append(Text.of(&"journal.kingdom.place", [
					_short_place(row["town"] as StringName),
					Text.of(&"journal.kingdom.free" if bool(row["free"]) else &"journal.kingdom.crown"),
					who]))
			&"hardship":
				people.append(Text.of(&"journal.kingdom.worse" if bool(row["worse"])
					else &"journal.kingdom.better", [_short_place(row["town"] as StringName)]))
			&"castle":
				castle.append(Text.of(StringName("journal.kingdom.wealth.%s" % row["wealth"])))
				castle.append(Text.of(StringName("journal.kingdom.unrest.%s" % row["unrest"])))
	if people.size() == 2:
		people.append(Text.of(&"journal.kingdom.same"))
	return [places, people, castle] as Array[Array]



## What you are looking for. A pure view over the fact base — nothing is stored, so
## there is nothing that can disagree with what you actually know. Answered questions
## first, so that a page too full to hold them all keeps the open ones.
func _page_quests() -> Array[Array]:
	var blocks: Array[Array] = []
	for quest: Dictionary in QuestRules.done_ones(_sim.facts):
		blocks.append([Text.of(&"journal.quests.done",
			[Text.of(QuestRules.name_key(quest))])] as Array[String])
	for quest: Dictionary in QuestRules.open_ones(_sim.facts):
		var step: Array = QuestRules.progress(quest, _sim.facts)
		blocks.append([
			Text.of(&"journal.quests.row",
				[Text.of(QuestRules.name_key(quest)), int(step[0]), int(step[1])]),
			"     %s" % Text.of(QuestRules.note_key(quest)),
		] as Array[String])
	if blocks.is_empty():
		blocks.append([Text.of(&"journal.quests.none")] as Array[String])
	return blocks


## What you are, and what it has bought. Joining is worn (§8's appearance register),
## so the one screen that joins acts to consequences should say it — and under that,
## who holds what, which is the map answering back. Only the two borders can move, so
## only the two borders are worth a line.
func _page_you() -> Array[Array]:
	var first: Array[String] = [Text.of(&"journal.side.none")]
	if _mine.side != FactionRules.NEUTRAL:
		first = [Text.of(&"journal.side.row",
			[Text.of(_mine.rank_key_with(_standing))])]
	var ground: Array[String] = ["", Text.of(&"journal.ground")]
	for zone: StringName in FactionRules.CONTESTED:
		var held: StringName = _mine.holder(zone)
		ground.append(Text.of(&"journal.ground.row", [
			Text.of(StringName("place.short.%s" % zone)),
			Text.of(StringName("ground.%s" % (held if held != FactionRules.NEUTRAL else &"none"))),
		]))
	return [first, ground] as Array[Array]


## What you know, and — invariant 6 made visible — whether it would survive the death
## of the person who told you. That is the player's problem as much as the designer's.
func _page_known() -> Array[Array]:
	var blocks: Array[Array] = []
	for row: Dictionary in Journal.knowledge(_sim.facts, _cast):
		var held: String = Text.of(&"journal.holding") \
			if _world.holds(StringName(row["fact"])) else ""
		blocks.append([
			"- %s%s" % [row["line"], held],
			"      %s%s" % [
				Text.of(&"journal.told_by", [", ".join(row["from"] as PackedStringArray)]),
				"" if bool(row["safe"]) else Text.of(&"journal.only_source")],
		] as Array[String])
	return blocks


func _page_who() -> Array[Array]:
	var people: Array[Npc] = _cast.named().duplicate()
	# Farthest first, so the cut takes the far end and leaves the people you could
	# actually walk to.
	people.sort_custom(func(a: Npc, b: Npc) -> bool:
		return a.centre().distance_to(_world.player_pos) \
			> b.centre().distance_to(_world.player_pos))
	var blocks: Array[Array] = []
	for npc: Npc in people:
		var delta: Vector2 = npc.centre() - _world.player_pos
		var compass: String = ("%s%s" % [
			"N" if delta.y < -1.0 else ("S" if delta.y > 1.0 else ""),
			"W" if delta.x < -1.0 else ("E" if delta.x > 1.0 else "")])
		blocks.append(["- " + Text.of(&"journal.who.row", [
			npc.display_name,
			Text.of(StringName("place.short.%s" % _world.region().zone_at(npc.tile))),
			int(delta.length()), compass])] as Array[String])
	return blocks


## The journal's rows arrive as facts — a kind, a town, a count — and become a
## sentence here. Core stopped writing prose when the game learnt a second language.
func _journal_line(row: Dictionary) -> String:
	var town: String = _short_place(row.get("town", &"") as StringName)
	match row["kind"] as StringName:
		Journal.DEED:
			var key: StringName = _deed_key(row["deed"] as StringName)
			if key == &"":
				# The spoken levers and the second direction have no line of their own:
				# what people heard, said to you, is the line.
				var heard: String = Text.of(StringName("deed.heard.%s" % String(row["deed"])))
				return Text.of(&"journal.deed.generic",
					[heard.substr(0, 1).to_upper() + heard.substr(1), _seen(int(row["seen"]))])
			return Text.of(key, [town, _seen(int(row["seen"]))])
		Journal.HARDSHIP:
			return Text.of(&"journal.hardship", [town])
		Journal.FLIP:
			return Text.of(&"journal.flip.free" if PlaceRules.is_free(row["to"] as StringName)
				else &"journal.flip.crown", [town])
		Journal.UNSEEN:
			return Text.of(&"journal.unseen", [town])
		Journal.ARRIVAL:
			return Text.of(&"journal.arrival", [town])
		Journal.FRAUD:
			return Text.of(&"journal.fraud")
		Journal.ARMY:
			return Text.of(&"journal.army")
		Journal.GRAIN:
			return Text.of(&"journal.grain", [town])
		Journal.ESCORT:
			return Text.of(&"journal.escort", [int(row["to"]), int(row["from"])])
	return ""


## The half that is allowed to say *why*, and the only text in the game that is.
func _journal_because(row: Dictionary) -> String:
	match row["kind"] as StringName:
		Journal.DEED, Journal.FRAUD:
			return Text.of(&"journal.spent") if bool(row.get("spends_the_telling", false)) else ""
		Journal.ARRIVAL:
			var key: StringName = &"journal.because.carried" if bool(row["carried"]) \
				else &"journal.because.spread"
			return Text.of(key, [
				_elapsed(float(row["days"])),
				Text.of(_phrase_key(row["deed"] as StringName)),
				_short_place(row["origin"] as StringName)])
		Journal.ARMY:
			return Text.of(&"journal.because.army",
				[_short_place(row["told_at"] as StringName)]) if row["told_at"] != &"" else ""
		Journal.GRAIN:
			return Text.of(&"journal.because.grain") if bool(row["after_the_army"]) else ""
		Journal.ESCORT:
			return Text.of(&"journal.because.escort") if bool(row["after_the_army"]) else ""
		Journal.HARDSHIP:
			return Text.of(&"journal.because.hardship",
				[Text.of(StringName("deed.heard.%s" % String(row["deed"])))])
		Journal.FLIP:
			return Text.of(&"journal.because.you_decided" if bool(row["by_player"])
				else &"journal.because.turned")
	return ""


func _short_place(zone: StringName) -> String:
	return Text.of(StringName("place.short.%s" % zone)) if Region.is_place(zone) else ""


func _seen(count: int) -> String:
	return Text.of(&"journal.seen.one" if count == 1 else &"journal.seen.many", [count])


func _elapsed(days: float) -> String:
	if days < 1.0:
		return Text.of(&"journal.elapsed.hours")
	var whole: int = int(round(days))
	return Text.of(&"journal.elapsed.day") if whole <= 1 \
		else Text.of(&"journal.elapsed.days", [whole])


func _deed_key(deed: StringName) -> StringName:
	match deed:
		DeedRules.DEED_THEFT: return &"journal.deed.theft"
		DeedRules.DEED_RESTITUTION: return &"journal.deed.restitution"
		DeedRules.DEED_WARNING: return &"journal.deed.warning"
		DeedRules.DEED_SABOTAGE: return &"journal.deed.sabotage"
		DeedRules.DEED_BURN_STORES: return &"journal.deed.burn"
		DeedRules.DEED_ROB_BANK: return &"journal.deed.rob"
		DeedRules.DEED_WRECK_ROLLS: return &"journal.deed.rolls"
	return &""


func _phrase_key(deed: StringName) -> StringName:
	match deed:
		DeedRules.DEED_THEFT: return &"journal.phrase.theft"
		DeedRules.DEED_WARNING: return &"journal.phrase.warning"
	return &"journal.phrase.other"


## What a place looks like, which is not the same as what to do about it.
##
## The line below reads as scenery if you know nothing and as confirmation if
## Ossa has already told you, and it is the same line either way — the world
## shows, people explain. It must never become an instruction: the moment the
## camp tells the player to expose the fraud, the fact stops being something
## found from a person who was there, which is the thread §6 hangs on.
##
## Authored here rather than in content/ because it is one line. The second or
## third of these earns a file.
func _atmosphere() -> String:
	if _world.current_zone != WorldState.OVERWORLD:
		return ""
	if not _world.region().is_in_muster(_world.player_tile()):
		return ""
	if _world.pay_fraud_exposed:
		return Text.of(&"muster.struck")
	# Told somewhere else. The camp has to stop advertising a thing that can no
	# longer be done here — a world that describes an opportunity the player no
	# longer has is worse than one that says nothing, and an absent prompt on its
	# own is indistinguishable from a bug. It never says why: speaking it aloud
	# anywhere is what reached Odile, and this is what that looks like from here.
	if _world.fraud_told_to != &"":
		return Text.of(&"muster.shut")
	return Text.of(&"muster.queue")


## The entrance sign, in the place's own words (§15). Propaganda: a claim the player
## can doubt and later find false. Which one shows is the rules layer's verdict; the
## words are content, French first.
func _sign() -> String:
	if _world.current_zone != WorldState.OVERWORLD or _mine == null:
		return ""
	var here: StringName = _world.region().zone_at(_world.player_tile())
	var key: StringName = PlaceRules.sign_key_for(here, _mine.holder(here), _mine.was_decided(here))
	return Text.of(key) if key != &"" else ""


func _is_free(zone: StringName) -> bool:
	return _mine != null and PlaceRules.is_free(_mine.holder(zone))
