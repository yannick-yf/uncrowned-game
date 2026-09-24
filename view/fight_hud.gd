class_name FightHud
extends Control

## What a fight looks like on the flat of the screen (H1, H2, H5 — 2026-09-21): both
## fighters' health as pips, the opponent named, what a blow just cost hanging over the
## one who took it, a word for a guard and a word for a miss, the beat's banner, and
## the keys. It comes up with the lens and goes with it.
##
## **Fed, never asking.** `main.gd` hands it a reading once a frame — `present()` —
## built from the same stores that screen draws from, and this draws nothing it was not
## handed. That is the shape `World3d.sync()` has and for the same reason: one reader
## applies the rules, and the picture cannot disagree with the simulation because it
## never consulted it.
##
## `--headless` never calls `_draw`, so what a test can check is the reading's effect on
## this node: up or not, which name, how many pips, what the banner says.

## Health is ten small integers, so it is ten pips and not a bar: a blow takes two of
## them and the two can be counted from the sofa. A pip lost in the last half second
## stays lit in ember before it goes dark, which is how a hit reads on the bar.
const PIP: Vector2 = Vector2(13.0, 6.0)
const PIP_GAP: float = 2.0
## **Above this, health is a bar and not pips** (K4). Ten small integers count from the
## sofa; a hundred of them is 1,500 pixels on a 640-wide screen. The second design's
## table gives the player a hundred (`content/duel.json`, a development value Yannick
## named as one), so the same widget has to draw both without lying about either — the
## bar keeps the pips' footprint and their two colours and only stops being countable.
const MAX_PIPS: int = 12
const MARGIN: float = 10.0
const TOP: float = 10.0
const GHOST_SECONDS: float = 0.55
## A number hung over the one who took the blow rises and fades in under a second.
const FLOAT_SECONDS: float = 0.85
const FLOAT_RISE: float = 24.0
const BANNER_IN_SECONDS: float = 0.25

## Gold is yours and ember is his, here and on the ground — `World3d`'s marks use the
## same two, so what the bars say and what the arena says read as one voice.
const MINE: Color = Color(1.0, 0.847, 0.443)
const HIS: Color = Color(1.0, 0.42, 0.28)

var _reading: Dictionary = {}
var _alpha: float = 0.0
var _now: float = 0.0
## The health each side is drawn with, and when it last dropped, for the ghost pips.
var _shown: Dictionary = {&"mine": -1, &"his": -1}
var _drops: Dictionary = {}
var _floats: Array[Dictionary] = []
var _banner: String = ""
var _banner_at: float = -1.0


func _init() -> void:
	name = "FightHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


## Once a frame. `reading` carries: `lens` (0..1, the eased framing), `on`, `my_hp`,
## `my_max`, `his_hp`, `his_max`, `his_name`, `felled`, `his_down`, `settling`,
## `outcome`, and `blows` — the fight's events since the last frame, each with a screen
## point `at` to hang a word on, or (-1, -1) for none.
func present(reading: Dictionary, delta: float) -> void:
	_now += delta
	_alpha = clampf(float(reading.get("lens", 0.0)), 0.0, 1.0)
	var on: bool = bool(reading.get("on", false))
	visible = _alpha > 0.002
	if not on and _alpha <= 0.002:
		# Gone with the fight: the next one starts with nothing left over.
		_shown = {&"mine": -1, &"his": -1}
		_drops = {}
		_floats = []
		_banner = ""
		_banner_at = -1.0
		_reading = {}
		queue_redraw()
		return
	if on:
		_reading = reading
		_take_health(&"mine", 0 if bool(reading.get("felled", false)) else int(reading.get("my_hp", 0)))
		_take_health(&"his", int(reading.get("his_hp", 0)))
		for row: Variant in reading.get("blows", []) as Array:
			_take_blow(row as Dictionary)
		# **The banner is read off the state, not off an event.** The outcome is set on
		# the frame the fight is decided and stands for the beat, so a frame that missed
		# the event — the first one drawn, a photograph — still says who is down.
		var outcome: String = String(reading.get("outcome", ""))
		if outcome != "" and _banner == "":
			_banner = Text.of(&"fight.down", [String(reading.get("his_name", ""))]) if outcome == "won" \
				else Text.of(&"fight.you_down")
			_banner_at = _now
	for i: int in range(_floats.size() - 1, -1, -1):
		if _now - float(_floats[i]["born"]) > FLOAT_SECONDS:
			_floats.remove_at(i)
	queue_redraw()


func _take_health(side: StringName, hp: int) -> void:
	var was: int = int(_shown[side])
	if was < 0:
		_shown[side] = hp
		return
	if hp < was:
		_drops[side] = {"from": was, "at": _now}
	_shown[side] = hp


func _take_blow(blow: Dictionary) -> void:
	var kind: String = String(blow.get("type", ""))
	var by_me: bool = String(blow.get("by", "")) == "player"
	var at: Vector2 = blow.get("at", Vector2(-1.0, -1.0)) as Vector2
	if kind == "blow_landed":
		var damage: int = int(blow.get("damage", 0))
		var guarded: bool = bool(blow.get("guarded", false))
		var text: String = "-%d" % damage
		if guarded:
			text = "%s  %s" % [text, Text.of(&"fight.blocked")]
		# The number is the colour of the one who *threw* it: gold when you hit him,
		# ember when he hits you, so a glance at the colour says whose turn that was.
		var colour: Color = (MINE if by_me else HIS) if not guarded else Color(0.694, 0.851, 0.804)
		_floats.append({"text": text, "at": _place(at, not by_me), "born": _now,
			"colour": colour, "size": Ui.HEADING if (damage >= 2 and not guarded) else Ui.ROW})
	elif kind == "blow_missed":
		_floats.append({"text": Text.of(&"fight.miss"), "at": _place(at, by_me), "born": _now,
			"colour": Ui.DIM, "size": Ui.NOTE})


## A screen point to hang a word on, or the bar's corner when the window gave none.
func _place(at: Vector2, mine: bool) -> Vector2:
	if at.x >= 0.0 and at.y >= 0.0:
		return at
	# The game's canvas is 640 wide; headless, out of any tree, there is no viewport to ask.
	var width: float = get_viewport_rect().size.x if is_inside_tree() else 640.0
	return Vector2(MARGIN + 70.0, TOP + 34.0) if mine else Vector2(width - MARGIN - 70.0, TOP + 34.0)


func _draw() -> void:
	if _alpha <= 0.002 or _reading.is_empty():
		return
	var size: Vector2 = get_viewport_rect().size
	var his_name: String = String(_reading.get("his_name", ""))
	_draw_bar(&"mine", int(_reading.get("my_max", 10)), Text.of(&"fight.you"), MINE, false, size)
	_draw_bar(&"his", int(_reading.get("his_max", 10)), his_name, HIS, true, size)

	for row: Dictionary in _floats:
		var age: float = (_now - float(row["born"])) / FLOAT_SECONDS
		var colour: Color = row["colour"] as Color
		colour.a = _alpha * (1.0 - age * age)
		var at: Vector2 = (row["at"] as Vector2) + Vector2(0.0, -FLOAT_RISE * age)
		var text: String = String(row["text"])
		var text_size: int = int(row["size"])
		Ui.write_over(self, at - Vector2(Ui.width_of(text, text_size) * 0.5, 0.0), text, text_size, colour)

	var settling: bool = int(_reading.get("settling", 0)) > 0
	if _banner != "" and _banner_at >= 0.0:
		var came: float = clampf((_now - _banner_at) / BANNER_IN_SECONDS, 0.0, 1.0)
		var colour: Color = Ui.INK
		colour.a = _alpha * came
		# Under the ring and over the keys' line, so it crosses nobody's face.
		var width: float = Ui.width_of(_banner, Ui.LARGE)
		var at := Vector2((size.x - width) * 0.5, size.y * 0.80 + (1.0 - came) * 6.0)
		Ui.write_over(self, at, _banner, Ui.LARGE, colour)
	elif not settling:
		# **Whose turn it is** (K4). A turn-based fight that does not say so is a fight
		# the player stands in wondering why nothing is happening, and the keys are not
		# the first design's: there is no guard to press.
		var turn_based: bool = bool(_reading.get("turn_based", false))
		if turn_based:
			var whose: String = Text.of(&"duel.your_turn") if bool(_reading.get("my_turn", false)) \
				else Text.of(&"duel.his_turn", [his_name])
			var tone: Color = MINE if bool(_reading.get("my_turn", false)) else HIS
			tone.a = _alpha
			Ui.write_over(self, Vector2((size.x - Ui.width_of(whose, Ui.ROW)) * 0.5, size.y - 30.0),
				whose, Ui.ROW, tone)
		var keys: String = Text.of(&"duel.keys") if turn_based else Text.of(&"fight.keys")
		var colour: Color = Ui.DIM
		colour.a = _alpha * 0.9
		Ui.write_over(self, Vector2((size.x - Ui.width_of(keys, Ui.NOTE)) * 0.5, size.y - 12.0),
			keys, Ui.NOTE, colour)


## Ten pips and a name. The remaining health is anchored at the outer edge of the
## screen and the loss appears on the inner side, so both bars drain toward the middle
## — the genre's convention, kept because it is the one every player already reads.
func _draw_bar(side: StringName, max_hp: int, label: String, colour: Color, right: bool, size: Vector2) -> void:
	var hp: int = int(_shown[side])
	var drop: Dictionary = _drops.get(side, {}) as Dictionary
	var ghost_to: int = hp
	if not drop.is_empty():
		if _now - float(drop["at"]) < GHOST_SECONDS:
			ghost_to = int(drop["from"])
		else:
			_drops.erase(side)
	var lit: Color = Ui.INK
	lit.a = _alpha
	var ghost: Color = Ui.EMBER
	ghost.a = _alpha
	var gone := Color(0.08, 0.08, 0.10, 0.72 * _alpha)
	var edge := Color(colour.r, colour.g, colour.b, 0.55 * _alpha)
	if max_hp > MAX_PIPS:
		_draw_long_bar(hp, ghost_to, max_hp, label, lit, ghost, gone, edge, right, size)
		return
	for i: int in max_hp:
		var x: float = MARGIN + float(i) * (PIP.x + PIP_GAP)
		if right:
			x = size.x - MARGIN - PIP.x - float(i) * (PIP.x + PIP_GAP)
		var rect := Rect2(Vector2(x, TOP), PIP)
		var fill: Color = lit if i < hp else (ghost if i < ghost_to else gone)
		draw_rect(rect, fill, true)
		draw_rect(rect, edge, false, 1.0)
	var name_colour: Color = colour
	name_colour.a = _alpha
	var width: float = float(max_hp) * (PIP.x + PIP_GAP) - PIP_GAP
	var name_x: float = MARGIN if not right else size.x - MARGIN - Ui.width_of(label, Ui.ROW)
	Ui.write_over(self, Vector2(name_x, TOP + PIP.y + 13.0), label, Ui.ROW, name_colour)
	if right:
		return
	# A hairline under the player's pips only, so the two sides are told apart at a glance.
	draw_rect(Rect2(Vector2(MARGIN, TOP + PIP.y + 2.0), Vector2(width, 1.0)), edge, true)


## **A hundred points, drawn as one bar** (K4). The same footprint ten pips have, the
## same three tones — lit, the ember of what just went, and dark — and it drains toward
## the middle of the screen as the pips do. It is not countable, which is the honest
## thing to say about a hundred of anything: the number beside it is what a player
## reads, and the length is what they feel.
func _draw_long_bar(
	hp: int,
	ghost_to: int,
	max_hp: int,
	label: String,
	lit: Color,
	ghost: Color,
	gone: Color,
	edge: Color,
	right: bool,
	size: Vector2,
) -> void:
	var width: float = float(MAX_PIPS) * (PIP.x + PIP_GAP) - PIP_GAP
	var left: float = MARGIN if not right else size.x - MARGIN - width
	var share: float = clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	var was: float = clampf(float(ghost_to) / float(maxi(max_hp, 1)), 0.0, 1.0)
	draw_rect(Rect2(Vector2(left, TOP), Vector2(width, PIP.y)), gone, true)
	# Both bars drain toward the middle, so the remaining health is anchored at the
	# outer edge and the loss appears on the inner side — the pips' rule, kept.
	var lit_x: float = left if not right else left + width * (1.0 - share)
	var ghost_x: float = left if not right else left + width * (1.0 - was)
	draw_rect(Rect2(Vector2(ghost_x, TOP), Vector2(width * was, PIP.y)), ghost, true)
	draw_rect(Rect2(Vector2(lit_x, TOP), Vector2(width * share, PIP.y)), lit, true)
	draw_rect(Rect2(Vector2(left, TOP), Vector2(width, PIP.y)), edge, false, 1.0)
	var reading: String = "%s  %d" % [label, maxi(hp, 0)]
	var name_colour: Color = Color(edge.r, edge.g, edge.b, _alpha)
	var name_x: float = MARGIN if not right else size.x - MARGIN - Ui.width_of(reading, Ui.ROW)
	Ui.write_over(self, Vector2(name_x, TOP + PIP.y + 13.0), reading, Ui.ROW, name_colour)
	if not right:
		draw_rect(Rect2(Vector2(MARGIN, TOP + PIP.y + 2.0), Vector2(width, 1.0)), edge, true)


# ------------------------------------------------------------- for the suite ---

func is_up() -> bool:
	return visible and not _reading.is_empty()


func pips_shown(side: StringName) -> int:
	return maxi(int(_shown.get(side, 0)), 0)


func opponent_named() -> String:
	return String(_reading.get("his_name", ""))


func banner() -> String:
	return _banner


func floats_shown() -> int:
	return _floats.size()
