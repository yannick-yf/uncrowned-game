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

const TILE: int = Art.TILE
const FIGURE: float = 16.0
## Interpolating across a respawn or a zone change would streak the player over
## the whole map for a frame.
const TELEPORT_TILES: float = 2.0
## How near something hunting you has to be before the HUD mentions it.
const CLOSE_ENOUGH_TO_FEAR: float = 7.0
## How long a thing that just happened stays on screen: two seconds, then the
## world stops mentioning it and never brings it up again.
const MOMENT_STEPS: int = Sim.STEPS_PER_REAL_SECOND * 2
## How many of the most recent entries fit on the page. The journal is a record,
## not a feed: the oldest thing you did is rarely the thing you are trying to
## understand.
const JOURNAL_ROWS: int = 9

var _journal_open: bool = false
## The log length the page was built from. A journal held open would otherwise walk
## every event in the run sixty times a second to print the same page.
var _journal_at: int = -1
## Deaths already answered for, so one death triggers one reload.
var _deaths_seen: int = 0

## Somewhere you cannot enter should still say what it is.
var _sim: Sim = null
var _world: WorldState = null
var _cast: Cast = null
var _wild: Wildlife = null
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
var _real_seconds: float = 0.0
var _render_from: Vector2 = Vector2.ZERO
var _render_to: Vector2 = Vector2.ZERO

var _mine: Allegiance = null
@onready var _info: Label = $HUD/Info
@onready var _box: ColorRect = $HUD/DialogueBox
@onready var _speaker: Label = $HUD/DialogueBox/Speaker
@onready var _line: Label = $HUD/DialogueBox/Line
@onready var _choices: Label = $HUD/DialogueBox/Choices
@onready var _prompt: Label = $HUD/Prompt
@onready var _journal_box: ColorRect = $HUD/JournalBox
@onready var _journal_title: Label = $HUD/JournalBox/Title
@onready var _journal_body: Label = $HUD/JournalBox/Body


## Wiring, not logic: one call into core/, then cache what is read every frame.
func _ready() -> void:
	_art = Art.new()
	_seconds_per_step = Game.seconds_per_step()
	_debug_available = OS.has_feature("debug")
	# A run in progress is on disk as its event log, so starting the game is
	# replaying it. If that fails or there is nothing there, a new run.
	_sim = SaveFile.read()
	if _sim == null:
		_sim = Game.build()
	_world = _sim.store(&"world") as WorldState
	_cast = _sim.store(&"cast") as Cast
	_wild = _sim.store(&"wildlife") as Wildlife
	_ticked = _sim.store(&"worldtick") as WorldTick
	_mine = _sim.store(&"allegiance") as Allegiance
	_standing = _sim.store(&"standing") as Standing
	_road = _sim.store(&"travellers") as Travellers
	_book = _sim.store(&"phrasebook") as Phrasebook
	var stand: String = OS.get_environment("UNCROWNED_AT")
	if OS.has_feature("debug") and stand.contains(","):
		var parts: PackedStringArray = stand.split(",")
		_world.player_pos = Vector2(float(parts[0]) + 0.5, float(parts[1]) + 0.5)
	_render_from = _world.player_pos
	_render_to = _world.player_pos


## Render a frame to a file and quit, for looking at the game without playing it.
##
## **The tool the last night needed and did not have.** "Zero script errors over 300
## frames" says nothing about whether the sea is the right colour, and the ocean
## shipped covered in shoreline tiles because nobody looked. This makes looking cheap:
##
##   UNCROWNED_SHOT=/tmp/a.png UNCROWNED_AT=241,150 godot --path . --quit-after 40
##
## Debug builds only, like the day-skip, and listed in CLAUDE.md for the same reason.
func _screenshot_if_asked() -> void:
	if not OS.has_feature("debug"):
		return
	var path: String = OS.get_environment("UNCROWNED_SHOT")
	if path.is_empty():
		return
	_shot_frames += 1
	# A few frames in, so the camera has settled and the first draw is behind us.
	if _shot_frames != 12:
		return
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(path)
	print("wrote %s" % path)
	get_tree().quit()


var _shot_frames: int = 0


func _process(delta: float) -> void:
	_real_seconds += delta
	_screenshot_if_asked()
	_read_input()

	_accumulator += delta
	while _accumulator >= _seconds_per_step:
		_accumulator -= _seconds_per_step
		_render_from = _world.player_pos
		_sim.advance(1)
		_render_to = _world.player_pos

	position = (get_viewport_rect().size * 0.5 - _camera_at(delta) * float(TILE)).round()
	queue_redraw()
	_draw_hud()
	_draw_journal()


# ------------------------------------------------------------------- input ---

func _read_input() -> void:
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

	var dir: Vector2i = _read_direction()
	if dir != _held_dir:
		_held_dir = dir
		_sim.submit(&"move_intent", {"x": dir.x, "y": dir.y})

	if _debug_available and Input.is_action_just_pressed(&"debug_skip_day"):
		_skip_a_day()

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


## Rebuild the run from the last rest. Every reference has to be re-taken, because
## replay builds a whole new world rather than rewinding this one.
func _reload() -> void:
	var loaded: Sim = SaveFile.read()
	if loaded == null:
		return
	_sim = loaded
	_world = _sim.store(&"world") as WorldState
	_cast = _sim.store(&"cast") as Cast
	_wild = _sim.store(&"wildlife") as Wildlife
	_ticked = _sim.store(&"worldtick") as WorldTick
	_standing = _sim.store(&"standing") as Standing
	_road = _sim.store(&"travellers") as Travellers
	_book = _sim.store(&"phrasebook") as Phrasebook
	_mine = _sim.store(&"allegiance") as Allegiance
	_deaths_seen = _world.deaths
	_journal_at = -1
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
func _camera_at(delta: float) -> Vector2:
	var looking: Vector2 = Vector2(_world.player_dir)
	if looking.length() > 0.01:
		looking = looking.normalized()
	var want: Vector2 = _draw_position() + looking * CAMERA_LOOKAHEAD
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
	var crowd: int = _crowd_size()
	var tent: int = 0
	var folk: int = 0
	for prop: Dictionary in region.props:
		var kind: StringName = prop["kind"] as StringName
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

	for beast: Beast in _wild.beasts:
		_draw_beast(beast)

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
	var ground: Array = Art.ground_tile(terrain, x, y)
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
		if kind == &"kiln":
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
	draw_texture_rect_region(
		_art.atlas(entry[0] as StringName),
		Rect2(dest.round(), Vector2(source.size)),
		Rect2(source), Color(1.0, 1.0, 1.0, 0.45) if covers else Color.WHITE)


func _draw_beast(beast: Beast) -> void:
	var sheet: Texture2D = _art.beast_sheet_for(beast.kind)
	if sheet == null:
		return
	var top_left: Vector2 = beast.pos * float(TILE) - Vector2(FIGURE, FIGURE) * 0.5
	draw_texture_rect_region(
		sheet,
		Rect2(top_left.round(), Vector2(FIGURE, FIGURE)),
		Art.tile_rect(Art.column_for(beast.facing), 0),
	)


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
func _draw_travellers(min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	if _road == null:
		return
	for walker: Traveller in _road.walkers:
		var at: Vector2i = walker.tile()
		if at.x < min_x or at.x > max_x or at.y < min_y or at.y > max_y:
			continue
		var sheet: Texture2D = _art.townsfolk_sheet(walker.id)
		if sheet == null:
			continue
		var column: int = Art.column_for(Vector2i(walker.heading, 0))
		var top_left: Vector2 = walker.pos * float(TILE) - Vector2(FIGURE, FIGURE) * 0.5
		draw_texture_rect_region(
			sheet, Rect2(top_left.round(), Vector2(FIGURE, FIGURE)), Art.tile_rect(column, 0))


## The escort, drawn because it has to be *seen* to drop. Ten bodies in two ranks
## in front of the gate; five after the Muster empties.
func _draw_escort() -> void:
	for i: int in _ticked.kings_escort():
		var rank: int = i / 5
		var file: int = i % 5
		var at: Vector2 = _world.king_pos + Vector2(float(file) - 2.0, 2.0 + float(rank) * 1.2)
		_draw_actor(at, &"guard", Art.FACE_DOWN)


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

	var rows: Array[String] = []
	var done: String = _just_happened()
	if done != "":
		rows.append(done)
	var mood: String = _atmosphere()
	if mood != "":
		rows.append(mood)

	# Only what can actually reach you. A wolf that has seen you from the treeline
	# while you stand in a camp it cannot enter is not a warning, it is a lie.
	var hunted: int = 0
	for beast: Beast in _wild.beasts:
		if beast.hunting and beast.pos.distance_to(_world.player_pos) <= CLOSE_ENOUGH_TO_FEAR:
			hunted += 1
	if hunted > 0:
		rows.append(Text.of(&"beast.one") if hunted == 1 else Text.of(&"beast.many", [hunted]))

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
	var rows: Array[Dictionary] = Journal.entries(_sim.events)
	var lines: Array[String] = []
	var from: int = maxi(rows.size() - JOURNAL_ROWS, 0)
	for i: int in range(from, rows.size()):
		var row: Dictionary = rows[i]
		lines.append("%s   %s" % [_clock(int(row["tick"])), _journal_line(row)])
		var because: String = _journal_because(row)
		if because != "":
			lines.append("                  %s" % because)
	if lines.is_empty():
		lines.append(Text.of(&"journal.empty"))

	# §15's second page. A predicate over ten numbers is invisible, and without this
	# "push the world until he cannot hold it" is guesswork. State and attribution
	# only: it says the treasury is empty and that you emptied it, and never that
	# you should rob the bank next.
	lines.append("")
	lines.append(Text.of(&"journal.holds"))
	for row: Dictionary in EndRules.what_holds_him_up(_ticked, _world, _sim.facts):
		lines.append("· %-30s %5d%s" % [
			Text.of(row["name_key"] as StringName), int(round(float(row["value"]))),
			Text.of(&"journal.yours") if float(row["yours"]) > 0.0 else "",
		])
	# What became of the wood, once she has told the player it is happening. Her
	# last word is "if you can, save us", and without this that is a request the
	# player can satisfy and never find out about.
	if OpeningRules.knows_about_the_wood(_sim.facts):
		var wood: Dictionary = OpeningRules.wood_row(_ticked)
		lines.append("")
		lines.append(Text.of(&"journal.wood"))
		if bool(wood.get("gone", false)):
			lines.append(Text.of(&"journal.wood.gone"))
		elif bool(wood.get("falling", false)):
			lines.append(Text.of(&"journal.wood.falling", [int(wood.get("paces", 0))]))
		else:
			lines.append(Text.of(&"journal.wood.holding", [int(wood.get("paces", 0))]))

	# What you are, and what it has bought. Joining is worn (§8's appearance
	# register), so the one screen that joins acts to consequences should say it.
	lines.append("")
	lines.append(Text.of(&"journal.side"))
	if _mine.side == FactionRules.NEUTRAL:
		lines.append(Text.of(&"journal.side.none"))
	else:
		lines.append(Text.of(&"journal.side.row",
			[Text.of(_mine.rank_key()), int(round(_mine.served))]))

	# And who holds what, which is the map answering back. Only the two borders can
	# move, so only the two borders are worth a line.
	lines.append("")
	lines.append(Text.of(&"journal.ground"))
	for zone: StringName in FactionRules.CONTESTED:
		var held: StringName = _mine.holder(zone)
		lines.append(Text.of(&"journal.ground.row", [
			Text.of(StringName("place.short.%s" % zone)),
			Text.of(StringName("ground.%s" % (held if held != FactionRules.NEUTRAL else &"none"))),
		]))

	if _world.reign_ended != &"":
		lines.append("")
		lines.append(Text.of(&"journal.deposed",
			[Text.of(StringName("end.%s" % _world.reign_ended))]))
		# And whether the thing she asked for happened. This is the one place the
		# five endings stop being five ways to win: a reign ended while the wood was
		# still being cleared reads differently from one ended after it stopped.
		if OpeningRules.knows_about_the_wood(_sim.facts):
			lines.append(Text.of(&"journal.wood.gone" if _ticked.held_ground <= 0.0
				else (&"journal.wood.lost" if _ticked.steel_output > 0.0
					else &"journal.wood.saved")))

	# Everybody with a name, where they stand, and how far off. A playtest tool:
	# eighteen more people arrive over Phase 6 and "walk about until you find him"
	# is not a way to review a character. Gated on a debug build and written down in
	# CLAUDE.md, like the day-skip — a debug tool nobody recorded is one that ships.
	if _debug_available:
		lines.append("")
		lines.append(Text.of(&"journal.who"))
		for npc: Npc in _cast.named():
			var delta: Vector2 = npc.centre() - _world.player_pos
			var compass: String = ("%s%s" % [
				"N" if delta.y < -1.0 else ("S" if delta.y > 1.0 else ""),
				"W" if delta.x < -1.0 else ("E" if delta.x > 1.0 else "")])
			lines.append("· " + Text.of(&"journal.who.row", [
				npc.display_name,
				Text.of(StringName("place.short.%s" % _world.region().zone_at(npc.tile))),
				int(delta.length()), compass]))

	var known: Array[Dictionary] = Journal.knowledge(_sim.facts, _cast)
	if not known.is_empty():
		lines.append("")
		lines.append(Text.of(&"journal.known"))
		for row: Dictionary in known:
			var held: String = Text.of(&"journal.holding") \
				if _world.holds(StringName(row["fact"])) else ""
			lines.append("· %s%s" % [row["line"], held])
			# Whether a fact would survive the death of the person who gave it to
			# you. Invariant 6 made visible, because it is the player's problem as
			# much as the designer's.
			lines.append("      %s%s" % [
				Text.of(&"journal.told_by", [", ".join(row["from"] as PackedStringArray)]),
				"" if bool(row["safe"]) else Text.of(&"journal.only_source")])
	_journal_title.text = Text.of(&"journal.title", [_clock(_sim.tick)])
	_journal_body.text = "\n".join(lines)


## The journal's rows arrive as facts — a kind, a town, a count — and become a
## sentence here. Core stopped writing prose when the game learnt a second language.
func _journal_line(row: Dictionary) -> String:
	var town: String = _short_place(row.get("town", &"") as StringName)
	match row["kind"] as StringName:
		Journal.DEED:
			return Text.of(_deed_key(row["deed"] as StringName),
				[town, _seen(int(row["seen"]))])
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
	return &"journal.unseen"


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
