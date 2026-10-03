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
## How far apart the foes' bars stand when there is more than one (O6).
const BAR_ROW: float = 30.0

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
## **The lesson, when the fight is a drill** (O8, T8): its title, the objective with how
## far you are, its steps each with its key, a hint that answers where you stand, and
## what was said as it began. **Every row carries its own tone and size**: the card had
## three colours for four rows, so the first round of every lesson begun by its line
## stopped drawing the HUD at the fourth. Empty in any other fight.
var _card: Array[Dictionary] = []
## How far across the screen the card may run before a row is broken (T8).
const CARD_WIDTH: float = 0.55
## The drill's steps as last worked out: `{text, done, current}`.
var _steps: Array[Dictionary] = []
## The hint's text key, or empty.
var _hint: StringName = &""


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
		_card = []
		_steps = []
		_hint = &""
		_reading = {}
		queue_redraw()
		return
	if on:
		_reading = reading
		_take_health(&"mine", 0 if bool(reading.get("felled", false)) else int(reading.get("my_hp", 0)))
		_take_health(&"his", int(reading.get("his_hp", 0)))
		# **A bar for each foe when there is more than one** (O6), kept by who they are,
		# so the second wolf drains its own bar and not the first one's.
		for row: Dictionary in _foes():
			_take_health(StringName(String(row.get("who", ""))), int(row.get("his_hp", 0)))
		for row: Variant in reading.get("blows", []) as Array:
			_take_blow(row as Dictionary)
		# **The banner is read off the state, not off an event.** The outcome is set on
		# the frame the fight is decided and stands for the beat, so a frame that missed
		# the event — the first one drawn, a photograph — still says who is down.
		_card = _lesson(reading)
		var outcome: String = String(reading.get("outcome", ""))
		var drill: String = String(reading.get("drill", ""))
		if outcome != "" and _banner == "" and drill != "":
			# A drill is passed or not yet — nobody is down in a lesson (O8).
			_banner = Text.of(&"drill.passed") if outcome == "won" else Text.of(&"drill.failed")
			_banner_at = _now
		if outcome != "" and _banner == "":
			# A spar won ends with him yielding, not down: nobody dies in one (O1).
			var his: String = String(reading.get("his_name", ""))
			var beast: String = String(reading.get("his_kind", ""))
			if outcome == "won" and beast != "":
				# A beast with its article, and a pack as a pack (the review of O21).
				_banner = Text.of(&"fight.pack_down", [Text.of(StringName("beast.%s.many" % beast))]) \
					if int(reading.get("foes", 1)) > 1 \
					else Text.of(&"fight.beast_down", [Text.of(StringName("beast.%s.noun" % beast))])
			elif outcome == "won" and String(reading.get("foes_many", "")) != "" and int(reading.get("foes", 1)) > 1:
				# Men of one trade, fallen together, as a band (the review of group V): « Les
				# gardes du roi sont à terre », not « Garde du roi est à terre ».
				_banner = Text.of(&"fight.pack_down", [String(reading["foes_many"])])
			elif outcome == "won":
				_banner = Text.of(&"fight.yielded", [his]) if bool(reading.get("spar", false)) \
					else Text.of(&"fight.down", [his])
			elif outcome == "left":
				# Walking out is the ordinary way out of a spar, and nobody is down.
				_banner = Text.of(&"fight.you_left")
			else:
				_banner = Text.of(&"fight.you_down")
			_banner_at = _now
	for i: int in range(_floats.size() - 1, -1, -1):
		if _now - float(_floats[i]["born"]) > FLOAT_SECONDS:
			_floats.remove_at(i)
	queue_redraw()


## The foes that get a bar of their own: every fighter in the reading when there is
## more than one, and none when there is one — the "his" bar is that one.
func _foes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rows: Array = _reading.get("fighters", []) as Array
	if rows.size() < 2:
		return out
	for row: Variant in rows:
		out.append(row as Dictionary)
	return out


## **The foes whose bars are drawn**: the ones still standing, and everybody through the
## beat that ends the fight (T9). At the works' gate the yard sends a man a round and
## every fallen one kept his empty bar, so the list ran down the screen.
func _standing_foes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var settling: bool = int(_reading.get("settling", 0)) > 0
	for row: Dictionary in _foes():
		if settling or not bool(row.get("his_down", false)):
			out.append(row)
	return out


## The drill's card: what it is, how far you are, its steps, and what to do (O8, T8).
func _lesson(reading: Dictionary) -> Array[Dictionary]:
	var drill: String = String(reading.get("drill", ""))
	var out: Array[Dictionary] = []
	_steps = _steps_of(reading)
	_hint = _hint_of(reading)
	if drill != "":
		out.append({"text": Text.of(StringName("drill.%s.title" % drill)), "tone": MINE, "size": Ui.ROW})
		out.append({"text": Text.of(StringName("drill.%s.goal" % drill),
			[int(reading.get("goal_done", 0)), int(reading.get("goal_of", 0))]), "tone": Ui.INK, "size": Ui.ROW})
		# Each step with its key, ticked when done; the one you are on in ink.
		for step: Dictionary in _steps:
			var mark: String = "[x] " if bool(step["done"]) else "[ ] "
			out.append({"text": mark + String(step["text"]),
				"tone": Ui.INK if bool(step["current"]) else Ui.DIM, "size": Ui.NOTE})
		# On your turn, what to do from where you stand; otherwise the lesson in a line.
		var spell_reach: int = int(reading.get("spell_reach", DuelRules.spell_reach_tiles()))
		var needed: String = _needed_name(reading)
		out.append({"text": Text.of(_hint if _hint != &"" else StringName("drill.%s.instruction" % drill),
			[spell_reach, needed]),
			"tone": MINE if _hint != &"" else Ui.DIM, "size": Ui.NOTE})
	# And what was said as it began, through the first round (the review of O21): the
	# answer to the line that squared you up, which the closing box used to swallow.
	var said: String = String(reading.get("said", ""))
	if said != "":
		out.append({"text": Text.of(&"fight.said", [String(reading.get("said_by", "")), said]),
			"tone": Ui.DIM, "size": Ui.NOTE})
	return out


## **A lesson's steps** (T8, redone for the wheel in N6): where to stand, then the wheel and
## the lesson's action, then the blow at her or him. Each is done when where you stand and
## what you have chosen make it so; the first not done is the one you are on.
const LESSON_ACTION: Dictionary = {"sword": "melee", "bow": "ranged", "magic": "magic"}


func _steps_of(reading: Dictionary) -> Array[Dictionary]:
	var drill: String = String(reading.get("drill", ""))
	if not LESSON_ACTION.has(drill):
		return []
	var apart: int = int(reading.get("nearest_apart", 99))
	var spell_reach: int = int(reading.get("spell_reach", DuelRules.spell_reach_tiles()))
	var placed: bool = false
	match drill:
		"sword":
			placed = apart <= DuelRules.reach_tiles()
		"bow":
			placed = apart >= DuelRules.bow_min_tiles() and apart <= DuelRules.bow_reach_tiles()
		"magic":
			placed = apart <= spell_reach
	var chosen: bool = String(reading.get("turn_mode", "")) == "target" \
		and String(reading.get("chosen_category", "")) == String(LESSON_ACTION[drill])
	var rows: Array[Array] = [[StringName("drill.%s.step.close" % drill), placed or chosen],
		[StringName("drill.%s.step.choose" % drill), chosen], [StringName("drill.%s.step.act" % drill), false]]
	var out: Array[Dictionary] = []
	var current_found: bool = false
	for row: Array in rows:
		var done: bool = bool(row[1])
		var current: bool = not done and not current_found
		current_found = current_found or current
		out.append({"text": Text.of(row[0] as StringName, [spell_reach, _needed_name(reading)]), "done": done, "current": current})
	return out


## The lesson's action, named as the wheel names it: the sword, or his fists without one
## (the review of N: the card said « l'épée » over a disc reading « Poings »).
static func _needed_name(reading: Dictionary) -> String:
	var need: String = String(LESSON_ACTION.get(String(reading.get("drill", "")), "melee"))
	if need == "melee" and String(reading.get("close_weapon", "")) == String(DuelRules.FISTS):
		return Text.of(&"drill.need.fists")
	return Text.of(StringName("drill.need.%s" % need))


## **What to do now** (T8, N6), on your own turn and in a lesson only: on the ground, too far
## or too close, or well placed and K to open the wheel; on the wheel, where the lesson's
## action is; on the target, the wrong action, out of reach, or K.
func _hint_of(reading: Dictionary) -> StringName:
	var drill: String = String(reading.get("drill", ""))
	if not LESSON_ACTION.has(drill) or not bool(reading.get("choosing", false)):
		return &""
	var need: String = String(LESSON_ACTION[drill])
	if drill == "magic" and not bool(reading.get("spell_ready", false)):
		return &"drill.hint.gift_resting"
	if not bool(reading.get("reach_this_turn", true)):
		return &"drill.hint.close_and_wait"
	match String(reading.get("turn_mode", "")):
		"wheel":
			if String(reading.get("wheel_category", "")) != need:
				return StringName("drill.hint.pick.%s" % need)
			return &"drill.hint.confirm" if bool(reading.get("weighed_reaches", true)) else &"drill.hint.nobody_from_here"
		"target":
			if String(reading.get("chosen_category", "")) != need:
				return &"drill.hint.wrong_action"
			if not bool(reading.get("target_in_reach", false)):
				return &"drill.hint.target_out_of_reach"
			return StringName("drill.hint.act.%s" % need)
	var apart: int = int(reading.get("nearest_apart", 99))
	match drill:
		"bow":
			if apart < DuelRules.bow_min_tiles():
				return &"drill.hint.bow_too_close"
			if apart > DuelRules.bow_reach_tiles():
				return &"drill.hint.too_far"
		"magic":
			if apart > int(reading.get("spell_reach", DuelRules.spell_reach_tiles())):
				return &"drill.hint.gift_too_far"
		_:
			if apart > DuelRules.reach_tiles():
				return &"drill.hint.sword_too_far"
	return &"drill.hint.open_wheel"


func _take_health(side: StringName, hp: int) -> void:
	var was: int = int(_shown.get(side, -1))
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
		# A blow for nothing still landed — a lesson's partner stops at one point — and says
		# so, rather than « -0 » (the review of T9).
		var text: String = "-%d" % damage if damage > 0 else Text.of(&"fight.touched")
		if guarded:
			text = "%s  %s" % [text, Text.of(&"fight.blocked")]
		# The number is the colour of the one who *threw* it: gold when you hit him,
		# ember when he hits you, so a glance at the colour says whose turn that was.
		var colour: Color = (MINE if by_me else HIS) if not guarded else Color(0.694, 0.851, 0.804)
		_floats.append({"text": text, "at": _place(at, not by_me), "born": _now,
			"colour": colour, "size": Ui.HEADING if (damage >= 2 and not guarded) else Ui.ROW})
		# **The surprise attack says so** (R3), over the number it doubled.
		if bool(blow.get("surprise", false)):
			_floats.append({"text": Text.of(&"fight.surprise"), "at": _place(at, not by_me) + Vector2(0.0, -18.0),
				"born": _now, "colour": MINE, "size": Ui.ROW})
	elif kind == "blow_missed":
		# A miss by the dice (R4) is said as loudly as a hit, over whoever it missed.
		var dice: bool = bool(blow.get("missed", false))
		_floats.append({"text": Text.of(&"fight.miss"), "at": _place(at, not by_me if dice else by_me), "born": _now,
			"colour": (MINE if by_me else HIS) if dice else Ui.DIM, "size": Ui.ROW if dice else Ui.NOTE})


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
	# **What his armour takes off every blow** (E6), on his name's row at the bar's inner
	# end, so a looted helmet is a number in the fight and not only a picture.
	var armour: String = armour_line()
	if armour != "":
		var tone: Color = Ui.DIM
		tone.a = _alpha
		var bar_end: float = MARGIN + float(MAX_PIPS) * (PIP.x + PIP_GAP) - PIP_GAP
		Ui.write_over(self, Vector2(bar_end - Ui.width_of(armour, Ui.NOTE), TOP + PIP.y + 13.0), armour, Ui.NOTE, tone)
	var foes: Array[Dictionary] = _standing_foes()
	if _foes().is_empty():
		_draw_bar(&"his", int(_reading.get("his_max", 10)), his_name, HIS, true, size)
	for index: int in foes.size():
		var row: Dictionary = foes[index]
		_draw_bar(StringName(String(row.get("who", ""))), int(row.get("his_max", 10)),
			String(row.get("name", "")), HIS, true, size, TOP + float(index) * BAR_ROW)

	for row: Dictionary in _floats:
		var age: float = (_now - float(row["born"])) / FLOAT_SECONDS
		var colour: Color = row["colour"] as Color
		colour.a = _alpha * (1.0 - age * age)
		var at: Vector2 = (row["at"] as Vector2) + Vector2(0.0, -FLOAT_RISE * age)
		var text: String = String(row["text"])
		var text_size: int = int(row["size"])
		Ui.write_over(self, at - Vector2(Ui.width_of(text, text_size) * 0.5, 0.0), text, text_size, colour)

	# The lesson, under the bars on the left, each row in its own tone and size, and a long
	# one broken into rows short of the middle of the screen (T8).
	_card_rect = Rect2()
	if not _card.is_empty():
		var top: float = TOP + PIP.y + 34.0
		var width: float = size.x * CARD_WIDTH
		for row: Dictionary in _card:
			var tone: Color = row["tone"] as Color
			tone.a *= _alpha
			var row_size: int = int(row["size"])
			for line: String in Ui.wrapped(String(row["text"]), row_size, width):
				Ui.write_over(self, Vector2(MARGIN, top), line, row_size, tone)
				top += 16.0 if row_size >= Ui.ROW else 13.0
		_card_rect = Rect2(Vector2.ZERO, Vector2(MARGIN + width, top))
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
		_draw_wheel(size)
		_draw_target_words()
		var refused: String = String(_reading.get("refused", "")) if String(_reading.get("turn_mode", "")) != "wheel" else ""
		if refused != "":
			var told: Color = Ui.EMBER
			told.a = _alpha
			Ui.write_over(self, Vector2((size.x - Ui.width_of(refused, Ui.ROW)) * 0.5, size.y - 46.0), refused, Ui.ROW, told)
		# **Whose turn it is** (K4). A turn-based fight that does not say so is a fight
		# the player stands in wondering why nothing is happening.
		var whose: String = whose_turn()
		var tone: Color = MINE if bool(_reading.get("my_turn", false)) else HIS
		tone.a = _alpha
		Ui.write_over(self, Vector2((size.x - Ui.width_of(whose, Ui.ROW)) * 0.5, size.y - 30.0),
			whose, Ui.ROW, tone)
		var keys: String = keys_line()
		var colour: Color = Ui.DIM
		colour.a = _alpha * 0.9
		Ui.write_over(self, Vector2((size.x - Ui.width_of(keys, Ui.NOTE)) * 0.5, size.y - 12.0),
			keys, Ui.NOTE, colour)


## **The wheel of actions** (N3, 2026-10-03, after Baldur's Gate 3's radial menu): round the
## player, one segment a category clockwise from the top — the blade, the bow, magic, items,
## wait — each a dark disc with its icon, the one he is on ringed in gold, what cannot be
## done greyed; under it, what the segment does, or why it cannot. Drawn in the HUD's own
## panel, gold and ink, with icons drawn here: nothing downloaded.
## Where the lesson's card was drawn, so the target's words keep off it (N6).
var _card_rect: Rect2 = Rect2()
const WHEEL_RADIUS: float = 44.0
const WHEEL_SLOT: float = 14.0
## Where the wheel was last drawn, so the mouse can be told which segment it is over (N5).
var _wheel_centre: Vector2 = Vector2(-1.0, -1.0)
var _wheel_count: int = 0


## **The wheel's segment under a point of the screen**, or -1 (N5).
func wheel_slot_at(point: Vector2) -> int:
	if _wheel_count <= 0 or _wheel_centre.x < 0.0:
		return -1
	for index: int in _wheel_count:
		var place: Vector2 = _wheel_centre + Vector2.from_angle(-PI * 0.5 + TAU * float(index) / float(_wheel_count)) * WHEEL_RADIUS
		if point.distance_to(place) <= WHEEL_SLOT + 4.0:
			return index
	return -1


func _draw_wheel(size: Vector2) -> void:
	if String(_reading.get("turn_mode", "")) != "wheel":
		_wheel_count = 0
		return
	var rows: Array = _reading.get("wheel", []) as Array
	if rows.is_empty():
		return
	var centre: Vector2 = _reading.get("my_screen", Vector2(-1.0, -1.0)) as Vector2
	if centre.x < 0.0:
		centre = size * 0.5
	centre.x = clampf(centre.x, WHEEL_RADIUS + 24.0, size.x - WHEEL_RADIUS - 24.0)
	centre.y = clampf(centre.y, WHEEL_RADIUS + 40.0, size.y - WHEEL_RADIUS - 120.0)
	var at: int = int(_reading.get("wheel_at", 0))
	_wheel_centre = centre
	_wheel_count = rows.size()
	for index: int in rows.size():
		var row: Dictionary = rows[index] as Dictionary
		var angle: float = -PI * 0.5 + TAU * float(index) / float(rows.size())
		var place: Vector2 = centre + Vector2.from_angle(angle) * WHEEL_RADIUS
		var lit: bool = index == at
		var open: bool = bool(row.get("available", false))
		draw_circle(place, WHEEL_SLOT + (2.0 if lit else 0.0), Color(Ui.PANEL, 0.94 * _alpha))
		draw_arc(place, WHEEL_SLOT + (2.0 if lit else 0.0), 0.0, TAU, 28,
			Color(Ui.GOLD if lit else Ui.EDGE, _alpha), 2.0 if lit else 1.0)
		var ink: Color = Ui.GOLD if lit and open else (Ui.INK if open else Ui.FAINT)
		draw_icon(self, String(row.get("icon", "")), place, Color(ink, _alpha))
		# The shortcut's number, 1 to 4, at the disc's shoulder (the review of N).
		if index < 4:
			Ui.write_over(self, place + Vector2(WHEEL_SLOT * 0.55, -WHEEL_SLOT * 0.55), str(index + 1), Ui.NOTE,
				Color(Ui.DIM, _alpha))
	# What the segment he is on does, or why it cannot.
	var chosen: Dictionary = rows[clampi(at, 0, rows.size() - 1)] as Dictionary
	var label: String = String(chosen.get("label", ""))
	var under: String = String(chosen.get("detail", "")) if bool(chosen.get("available", false)) \
		else String(chosen.get("why", ""))
	# A refusal is said in the box, where the eye already is (the review of N).
	var refused: String = String(_reading.get("refused", ""))
	var told: bool = refused != ""
	if told:
		under = refused
	var width: float = maxf(Ui.width_of(label, Ui.ROW), Ui.width_of(under, Ui.NOTE)) + 20.0
	var box := Rect2(Vector2(centre.x - width * 0.5, centre.y + WHEEL_RADIUS + WHEEL_SLOT + 6.0), Vector2(width, 34.0))
	Ui.panel(self, box, Color(Ui.PANEL, 0.94 * _alpha))
	Ui.write_over(self, Vector2(box.position.x, box.position.y + 14.0), label, Ui.ROW,
		Color(Ui.GOLD, _alpha), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	Ui.write_over(self, Vector2(box.position.x, box.position.y + 28.0), under, Ui.NOTE,
		Color(Ui.DIM if bool(chosen.get("available", false)) and not told else Ui.EMBER, _alpha), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)


## **Over the target he is on** (N4): its name, then the chance and the damage — or that the
## action does not reach it.
func _draw_target_words() -> void:
	if String(_reading.get("turn_mode", "")) != "target":
		return
	var rows: Array = _reading.get("targets", []) as Array
	if rows.is_empty():
		return
	var row: Dictionary = rows[clampi(int(_reading.get("target_chosen", 0)), 0, rows.size() - 1)] as Dictionary
	var at: Vector2 = row.get("screen", Vector2(-1.0, -1.0)) as Vector2
	if at.x < 0.0:
		return
	var name: String = String(row.get("name", ""))
	var reach: bool = bool(row.get("in_reach", false))
	var odds: String = Text.of(&"target.chance", [int(row.get("chance", 0)), int(row.get("damage", 0))]) if reach \
		else Text.of(&"target.out_of_reach")
	var width: float = maxf(Ui.width_of(name, Ui.ROW), Ui.width_of(odds, Ui.NOTE)) + 16.0
	var box := Rect2(Vector2(at.x - width * 0.5, at.y - 44.0), Vector2(width, 32.0))
	# Over the lesson's card, it goes under the target's feet instead.
	if _card_rect.has_area() and box.intersects(_card_rect):
		box.position.y = at.y + 62.0
	Ui.panel(self, box, Color(Ui.PANEL, 0.94 * _alpha))
	Ui.write_over(self, Vector2(box.position.x, box.position.y + 13.0), name, Ui.ROW,
		Color(Ui.INK, _alpha), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	Ui.write_over(self, Vector2(box.position.x, box.position.y + 26.0), odds, Ui.NOTE,
		Color(Ui.GOLD if reach else Ui.EMBER, _alpha), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)


## **An action's icon**, drawn in lines a dozen pixels across: a sword, a bow, a spell's
## star, a flask, an hourglass. Static, so the inventory and any other screen can draw them.
static func draw_icon(canvas: CanvasItem, icon: String, at: Vector2, ink: Color) -> void:
	match icon:
		"sword":
			canvas.draw_line(at + Vector2(-5.0, 5.0), at + Vector2(6.0, -6.0), ink, 2.0)
			canvas.draw_line(at + Vector2(-5.0, 0.0), at + Vector2(0.0, 5.0), ink, 2.0)
			canvas.draw_line(at + Vector2(-7.0, 7.0), at + Vector2(-4.0, 4.0), ink, 2.0)
		"bow":
			canvas.draw_arc(at + Vector2(-3.0, 0.0), 8.0, -1.1, 1.1, 12, ink, 2.0)
			canvas.draw_line(at + Vector2(0.6, -7.1), at + Vector2(0.6, 7.1), ink, 1.0)
			canvas.draw_line(at + Vector2(-6.0, 0.0), at + Vector2(7.0, 0.0), ink, 1.0)
		"spell":
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -7), at + Vector2(2, -2), at + Vector2(7, 0),
				at + Vector2(2, 2), at + Vector2(0, 7), at + Vector2(-2, 2), at + Vector2(-7, 0), at + Vector2(-2, -2)]), ink)
		"flask":
			canvas.draw_circle(at + Vector2(0.0, 2.5), 4.5, ink)
			canvas.draw_rect(Rect2(at + Vector2(-1.5, -6.0), Vector2(3.0, 5.0)), ink, true)
		"wait":
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-5, -6), at + Vector2(5, -6), at + Vector2(0, 0)]), ink)
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-5, 6), at + Vector2(5, 6), at + Vector2(0, 0)]), ink)


## Ten pips and a name. The remaining health is anchored at the outer edge of the
## screen and the loss appears on the inner side, so both bars drain toward the middle
## — the genre's convention, kept because it is the one every player already reads.
func _draw_bar(side: StringName, max_hp: int, label: String, colour: Color, right: bool,
		size: Vector2, top: float = TOP) -> void:
	var hp: int = int(_shown.get(side, 0))
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
		_draw_long_bar(hp, ghost_to, max_hp, label, lit, ghost, gone, edge, right, size, top)
		return
	for i: int in max_hp:
		var x: float = MARGIN + float(i) * (PIP.x + PIP_GAP)
		if right:
			x = size.x - MARGIN - PIP.x - float(i) * (PIP.x + PIP_GAP)
		var rect := Rect2(Vector2(x, top), PIP)
		var fill: Color = lit if i < hp else (ghost if i < ghost_to else gone)
		draw_rect(rect, fill, true)
		draw_rect(rect, edge, false, 1.0)
	var name_colour: Color = colour
	name_colour.a = _alpha
	var width: float = float(max_hp) * (PIP.x + PIP_GAP) - PIP_GAP
	var name_x: float = MARGIN if not right else size.x - MARGIN - Ui.width_of(label, Ui.ROW)
	Ui.write_over(self, Vector2(name_x, top + PIP.y + 13.0), label, Ui.ROW, name_colour)
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
	top: float = TOP,
) -> void:
	var width: float = float(MAX_PIPS) * (PIP.x + PIP_GAP) - PIP_GAP
	var left: float = MARGIN if not right else size.x - MARGIN - width
	var share: float = clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	var was: float = clampf(float(ghost_to) / float(maxi(max_hp, 1)), 0.0, 1.0)
	draw_rect(Rect2(Vector2(left, top), Vector2(width, PIP.y)), gone, true)
	# Both bars drain toward the middle, so the remaining health is anchored at the
	# outer edge and the loss appears on the inner side — the pips' rule, kept.
	var lit_x: float = left if not right else left + width * (1.0 - share)
	var ghost_x: float = left if not right else left + width * (1.0 - was)
	draw_rect(Rect2(Vector2(ghost_x, top), Vector2(width * was, PIP.y)), ghost, true)
	draw_rect(Rect2(Vector2(lit_x, top), Vector2(width * share, PIP.y)), lit, true)
	draw_rect(Rect2(Vector2(left, top), Vector2(width, PIP.y)), edge, false, 1.0)
	var reading: String = "%s  %d" % [label, maxi(hp, 0)]
	var name_colour: Color = Color(edge.r, edge.g, edge.b, _alpha)
	var name_x: float = MARGIN if not right else size.x - MARGIN - Ui.width_of(reading, Ui.ROW)
	Ui.write_over(self, Vector2(name_x, top + PIP.y + 13.0), reading, Ui.ROW, name_colour)
	if not right:
		draw_rect(Rect2(Vector2(MARGIN, TOP + PIP.y + 2.0), Vector2(width, 1.0)), edge, true)


# ------------------------------------------------------------- for the suite ---

## The armour's line under the player's bar, or nothing when he wears none.
func armour_line() -> String:
	var armour: int = int(_reading.get("my_armour", 0))
	return Text.of(&"fight.armour", [armour]) if armour > 0 else ""


func is_up() -> bool:
	return visible and not _reading.is_empty()


## How many health bars are drawn: yours, and one per foe (O6).
func bars_shown() -> int:
	if not is_up():
		return 0
	return 1 + (maxi(_standing_foes().size(), 1) if not _foes().is_empty() else 1)


## The keys the fight offers, **for the step of the turn he is at** (N3, N4): where to
## stand, the wheel, the target. T6's line — what K does with what you hold, and what U
## would put in your hands — went with U.
func keys_line() -> String:
	# **The keys of the step he is at** (N3, N4): where to stand, the wheel, the target —
	# and none while it is not his turn (the review of N).
	if String(_reading.get("turn_mode", "")) == "" and not bool(_reading.get("my_turn", true)):
		return ""
	match String(_reading.get("turn_mode", "")):
		"wheel":
			return Text.of(&"duel.keys.wheel")
		"target":
			return Text.of(&"duel.keys.target")
	return Text.of(&"duel.keys.move")


## **Whose turn it is, in words** (K4): yours; a beast's or a man's named by his trade
## from the noun — « Au tour du loup », « Au tour du portier » (the review of T9: it read
## « À Le portier des Forges ») — and anybody else's by name. Named for whoever is acting,
## when several are (O6).
func whose_turn() -> String:
	if bool(_reading.get("my_turn", false)):
		return Text.of(&"duel.your_turn")
	var noun: String = String(_reading.get("acting_noun", _reading.get("his_noun", "")))
	if noun != "":
		return Text.of(&"duel.beast_turn", [noun])
	return Text.of(&"duel.his_turn", [String(_reading.get("acting_name", _reading.get("his_name", "")))])


func float_words() -> PackedStringArray:
	var out := PackedStringArray()
	for row: Dictionary in _floats:
		out.append(String(row["text"]))
	return out


func drill_card() -> PackedStringArray:
	var out := PackedStringArray()
	for row: Dictionary in _card:
		out.append(String(row["text"]))
	return out


## The card as it is drawn, row by row (T8).
func card_rows() -> Array[Dictionary]:
	return _card


func lesson_steps() -> Array[Dictionary]:
	return _steps


func hint_key() -> StringName:
	return _hint


func pips_shown(side: StringName) -> int:
	return maxi(int(_shown.get(side, 0)), 0)


func opponent_named() -> String:
	return String(_reading.get("his_name", ""))


func banner() -> String:
	return _banner


func floats_shown() -> int:
	return _floats.size()
