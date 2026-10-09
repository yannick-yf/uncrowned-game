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
## A bar's height (D5), a little more than a pip's, for the frame round it.
const BAR_HEIGHT: float = 8.0
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
const FLOAT_SECONDS: float = 1.25
const FLOAT_RISE: float = 16.0
## A miss is said in a grey of its own, whoever missed (D10).
const MISS_GREY: Color = Color(0.80, 0.80, 0.78)
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
const CARD_WIDTH: float = 0.46
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
		out.append({"text": Text.of(StringName("drill.%s.title" % drill)), "tone": MINE, "size": Ui.ROW,
			"kind": "title"})
		out.append({"text": Text.of(StringName("drill.%s.goal" % drill),
			[int(reading.get("goal_done", 0)), int(reading.get("goal_of", 0))]), "tone": Ui.INK, "size": Ui.ROW,
			"kind": "goal"})
		# Each step with its key, ticked when done; the one you are on in ink. The text keeps
		# its mark for whoever reads the card as words; the panel draws a box instead (D4).
		for step: Dictionary in _steps:
			var mark: String = "[x] " if bool(step["done"]) else "[ ] "
			out.append({"text": mark + String(step["text"]), "step": String(step["text"]),
				"done": bool(step["done"]), "current": bool(step["current"]),
				"tone": Ui.INK if bool(step["current"]) else Ui.DIM, "size": Ui.NOTE, "kind": "step"})
		# On your turn, what to do from where you stand. Off it, nothing more: the steps say
		# the lesson, and the line that said it again went with the panel (D4, fewer words).
		if _hint != &"":
			var spell_reach: int = int(reading.get("spell_reach", DuelRules.spell_reach_tiles()))
			out.append({"text": Text.of(_hint, [spell_reach, _needed_name(reading)]), "tone": MINE,
				"size": Ui.NOTE, "kind": "hint"})
	# And what was said as it began, through the first round (the review of O21): the
	# answer to the line that squared you up, which the closing box used to swallow.
	var said: String = String(reading.get("said", ""))
	if said != "":
		out.append({"text": Text.of(&"fight.said", [String(reading.get("said_by", "")), said]),
			"tone": Ui.DIM, "size": Ui.NOTE, "kind": "said"})
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
			"colour": colour, "size": Ui.HEADING if (damage > 0 and not guarded) else Ui.ROW})
		# **The surprise attack says so** (R3), over the number it doubled.
		if bool(blow.get("surprise", false)):
			_floats.append({"text": Text.of(&"fight.surprise"), "at": _place(at, not by_me) + Vector2(0.0, -18.0),
				"born": _now, "colour": MINE, "size": Ui.ROW})
	elif kind == "blow_missed":
		# A miss by the dice (R4) is said as loudly as a hit, over whoever it missed.
		var dice: bool = bool(blow.get("missed", false))
		_floats.append({"text": Text.of(&"fight.miss"), "at": _place(at, not by_me if dice else by_me), "born": _now,
			"colour": MISS_GREY if dice else Ui.DIM, "size": Ui.ROW})


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
		Ui.write_over(self, Vector2(bar_end - Ui.width_of(armour, Ui.NOTE), TOP + BAR_HEIGHT + 13.0), armour, Ui.NOTE, tone)
	var foes: Array[Dictionary] = _standing_foes()
	if _foes().is_empty():
		_draw_bar(&"his", int(_reading.get("his_max", 10)), his_name, HIS, true, size)
	for index: int in foes.size():
		var row: Dictionary = foes[index]
		_draw_bar(StringName(String(row.get("who", ""))), int(row.get("his_max", 10)),
			String(row.get("name", "")), HIS, true, size, TOP + float(index) * BAR_ROW)

	# **Words over the fight** (D10, the audit's 3): they were small and dark and sat on the
	# figure. Now they rise from over the head with an eased lift — quick, then settling —
	# hold, and fade in their last third; outlined all round in near-black so they read on
	# grass, rock or a roof; damage at the heading's size.
	for row: Dictionary in _floats:
		var age: float = clampf((_now - float(row["born"])) / FLOAT_SECONDS, 0.0, 1.0)
		var colour: Color = row["colour"] as Color
		colour.a = _alpha * (1.0 if age < 0.66 else 1.0 - (age - 0.66) / 0.34)
		var lift: float = 1.0 - (1.0 - minf(age * 1.6, 1.0)) * (1.0 - minf(age * 1.6, 1.0))
		var at: Vector2 = (row["at"] as Vector2) + Vector2(0.0, -6.0 - FLOAT_RISE * lift)
		var text: String = String(row["text"])
		var text_size: int = int(row["size"])
		var left: Vector2 = (at - Vector2(Ui.width_of(text, text_size) * 0.5, 0.0)).round()
		var ink := Color(0.03, 0.03, 0.04, colour.a * 0.9)
		for step: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1),
				Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(0, 2)]:
			Ui.write(self, left + step, text, text_size, ink)
		Ui.write(self, left, text, text_size, colour)

	# The lesson, under the bars on the left, in a panel (D4).
	_card_rect = Rect2()
	if not _card.is_empty():
		_card_rect = _draw_card(Vector2(MARGIN, TOP + BAR_HEIGHT + 22.0), size.x * CARD_WIDTH)
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


## **The lesson's panel** (D4, the audit's 10): eight rows of small type in four colours,
## written straight onto the grass and the ruins, read badly. Now a panel of the wheel's
## style: the title with the count on its right, a rule, the steps with a box each — ticked
## gold when done, outlined gold for the one he is on, dim for the rest — then the hint in
## gold and what was said in dim, each under its own rule. Returns where it was drawn.
const CARD_PAD: float = 8.0
const CARD_LINE: float = 17.0


func _draw_card(at: Vector2, width: float) -> Rect2:
	var shown: float = _alpha
	_alpha = shown * _card_fade(at, width)
	var box: Rect2 = _draw_card_rows(at, width)
	_alpha = shown
	return box


## **A fighter under the card fades it** (D10): the lesson's panel is opaque, and a lesson
## framed wide can put the one you fight under it. Whoever stands under it — the player or
## a foe, by where the window drew them — brings it down to a third.
func _card_fade(at: Vector2, width: float) -> float:
	var under: Rect2 = Rect2(at, Vector2(width, 150.0)).grow(6.0)
	for point: Variant in _reading.get("screens", []) as Array:
		if under.has_point(point as Vector2):
			return 0.35
	return 1.0


func _draw_card_rows(at: Vector2, width: float) -> Rect2:
	var inner: float = width - CARD_PAD * 2.0
	var rows: Array = []
	var height: float = CARD_PAD
	var title: Dictionary = {}
	var goal: Dictionary = {}
	for row: Dictionary in _card:
		match String(row.get("kind", "")):
			"title":
				title = row
				continue
			"goal":
				goal = row
				continue
	if not title.is_empty():
		height += CARD_LINE + 6.0
	var last_kind: String = "title"
	for row: Dictionary in _card:
		var kind: String = String(row.get("kind", ""))
		if kind == "title" or kind == "goal":
			continue
		var text: String = String(row.get("step", row["text"]))
		var indent: float = 14.0 if kind == "step" else 0.0
		var lines: PackedStringArray = Ui.wrapped(text, int(row["size"]), inner - indent)
		var rule: bool = kind != last_kind and not (kind == "step" and last_kind == "title")
		rows.append({"row": row, "lines": lines, "rule": rule or (kind == "step" and last_kind == "title")})
		height += (6.0 if rule or (kind == "step" and last_kind == "title") else 0.0) + float(lines.size()) * CARD_LINE
		last_kind = kind
	height += CARD_PAD - 4.0
	var box := Rect2(at, Vector2(width, height))
	var fill: Color = Ui.PANEL
	fill.a *= 0.92 * _alpha
	Ui.panel(self, box, fill)
	var y: float = at.y + CARD_PAD + 12.0
	if not title.is_empty():
		var gold: Color = MINE
		gold.a = _alpha
		Ui.write(self, Vector2(at.x + CARD_PAD, y), String(title["text"]), Ui.ROW, gold)
		if not goal.is_empty():
			var ink: Color = Ui.INK
			ink.a = _alpha
			var count: String = String(goal["text"])
			Ui.write(self, Vector2(box.end.x - CARD_PAD - Ui.width_of(count, Ui.ROW), y), count, Ui.ROW, ink)
		y += CARD_LINE + 6.0
	for entry: Dictionary in rows:
		var row: Dictionary = entry["row"] as Dictionary
		var kind: String = String(row.get("kind", ""))
		if bool(entry["rule"]):
			var edge: Color = Ui.EDGE
			edge.a *= _alpha
			draw_line(Vector2(at.x + CARD_PAD, y - 13.0), Vector2(box.end.x - CARD_PAD, y - 13.0), edge, 1.0)
			y += 6.0
		var tone: Color = row["tone"] as Color
		tone.a *= _alpha
		if kind == "step":
			_step_box(Vector2(at.x + CARD_PAD, y - 9.0), bool(row.get("done", false)), bool(row.get("current", false)))
		for line: String in entry["lines"] as PackedStringArray:
			Ui.write(self, Vector2(at.x + CARD_PAD + (14.0 if kind == "step" else 0.0), y), line, int(row["size"]), tone)
			y += CARD_LINE
	return box


## A step's box: a gold tick when done, a gold outline for the one he is on, dim otherwise.
func _step_box(at: Vector2, done: bool, current: bool) -> void:
	var box := Rect2(at, Vector2(9.0, 9.0))
	var gold: Color = MINE
	gold.a = _alpha
	var dim: Color = Ui.FAINT
	dim.a = _alpha
	if done:
		draw_rect(box, gold, true)
		var ink: Color = Ui.NIGHT
		ink.a = _alpha
		draw_polyline(PackedVector2Array([at + Vector2(2.0, 4.5), at + Vector2(4.0, 6.5), at + Vector2(7.5, 2.5)]), ink, 1.5)
	else:
		draw_rect(box, gold if current else dim, false, 1.0)


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


## **A health bar and a name** (D5, the audit's 14): the one style of the game (`Ui.bar`),
## for the player and every foe alike — framed, coloured from green to ember as it empties,
## and the part a blow has just taken pale for a moment. A small health keeps its notches,
## so a wolf's ten can still be counted. The remaining health is anchored at the outer edge
## of the screen and the loss appears on the inner side, so both sides drain toward the
## middle — the genre's convention, kept because it is the one every player already reads.
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
	var most: float = float(maxi(max_hp, 1))
	var width: float = float(MAX_PIPS) * (PIP.x + PIP_GAP) - PIP_GAP
	var left: float = MARGIN if not right else size.x - MARGIN - width
	Ui.bar(self, Rect2(Vector2(left, top), Vector2(width, BAR_HEIGHT)), float(hp) / most,
		float(ghost_to) / most, max_hp if max_hp <= MAX_PIPS else 0, right, _alpha)
	var reading: String = "%s  %d" % [label, maxi(hp, 0)]
	var name_colour: Color = colour
	name_colour.a = _alpha
	var name_x: float = MARGIN if not right else size.x - MARGIN - Ui.width_of(reading, Ui.ROW)
	Ui.write_over(self, Vector2(name_x, top + BAR_HEIGHT + 13.0), reading, Ui.ROW, name_colour)


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
