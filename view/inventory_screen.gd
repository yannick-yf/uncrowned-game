class_name InventoryScreen
extends Node2D

## **What you carry, and what you wear** (group E, `docs/CREATION_AND_GEAR.md` §4). Tab.
##
## The player in the middle, drawn by the game's own layers (`PaperDoll`, the canvas
## shader), so a helmet put on here is the helmet the world shows. On the left of him the
## six slots and what is in them, with what they add up to — the protection taken off
## every blow, the weight, what he strikes with; on the right what is in his bag, with the
## numbers of the one under the cursor. Enter puts on or takes off.
##
## **Every change is an event**, like every act in the game: `equip` and `unequip`,
## submitted and answered on the spot, so a save carries what he wore. The world waits
## while the screen is open, as it waits for the pause menu. Not during a fight: Tab
## does nothing then, and the HUD says why.

const SLOTS: Rect2 = Rect2(16.0, 52.0, 208.0, 256.0)
const DOLL: Rect2 = Rect2(232.0, 52.0, 176.0, 256.0)
const BAG: Rect2 = Rect2(416.0, 52.0, 208.0, 256.0)
const ROW_STEP: float = 20.0
## Where a slot's item is written, from the panel's left edge: past the longest slot name.
const NAME_AT: float = 80.0
const TURN_SECONDS: float = 1.6
const WAYS: Array[StringName] = [&"down", &"left", &"up", &"right"]

var _sim: Sim = null
var _column: int = 0
var _slot_at: int = 0
var _bag_at: int = 0
var _doll: AnimatedSprite2D = null
var _turned: float = 0.0
var _way: int = 0


func begin(sim: Sim) -> void:
	_sim = sim


func _ready() -> void:
	_build_doll()


func _bag() -> Inventory:
	return _sim.store(&"inventory") as Inventory if _sim != null else null


## What is in the bag and not on him, in the order he came by it.
func carried() -> Array[StringName]:
	var out: Array[StringName] = []
	var bag: Inventory = _bag()
	if bag == null:
		return out
	for item: StringName in bag.owned:
		if bag.in_slot(ItemRules.slot_of(item)) != item:
			out.append(item)
	return out


# ------------------------------------------------------------------- the figure ---

func _build_doll() -> void:
	if not PaperDoll.ready() or not ResourceLoader.exists(World3d.HIS_FRAMES):
		return
	var his: SpriteFrames = load(World3d.HIS_FRAMES) as SpriteFrames
	if his == null:
		return
	_doll = AnimatedSprite2D.new()
	_doll.sprite_frames = CastLooks.frames_for(his, PaperDoll.sheet(&"body"))
	_doll.centered = true
	_doll.offset = Vector2(0.0, -float(_doll.sprite_frames.get_frame_texture(&"idle_down", 0).get_height()) * 0.5)
	_doll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_doll.position = Vector2(DOLL.get_center().x, DOLL.end.y - 34.0)
	_doll.material = PaperDoll.material(PaperDoll.CANVAS_SHADER, _slots())
	add_child(_doll)
	_doll.play(&"walk_down")


func _slots() -> Dictionary:
	var looks: Dictionary = AppearanceRules.default_appearance()
	var held: Appearance = _sim.store(&"appearance") as Appearance if _sim != null else null
	if held != null:
		looks = held.chosen()
	var bag: Inventory = _bag()
	return PaperDoll.slots_for(looks, bag.equipped if bag != null and bag.made else null)


func _dress() -> void:
	if _doll != null:
		PaperDoll.apply(_doll.material as ShaderMaterial, _slots())


# ------------------------------------------------------------------- input ---

func _process(delta: float) -> void:
	_turned += delta
	if _turned >= TURN_SECONDS and _doll != null:
		_turned = 0.0
		_way = (_way + 1) % WAYS.size()
		_doll.play(StringName("walk_" + String(WAYS[_way])))
	queue_redraw()


## **The keys, read by the world's window and not by this node** — so the Tab that opened
## the screen is not read again, on the same frame, as the Tab that closes it. True when
## the player has closed it.
func read_input() -> bool:
	if Input.is_action_just_pressed(&"inventory") or Input.is_action_just_pressed(&"back"):
		Sound.cue(&"cancel")
		return true
	if Input.is_action_just_pressed(&"move_left") or Input.is_action_just_pressed(&"move_right"):
		_column = 1 - _column
		Sound.cue(&"move")
	if Input.is_action_just_pressed(&"move_down"):
		_move(1)
	if Input.is_action_just_pressed(&"move_up"):
		_move(-1)
	if Input.is_action_just_pressed(&"interact"):
		act()
	return false


func _move(by: int) -> void:
	if _column == 0:
		_slot_at = posmod(_slot_at + by, ItemRules.SLOTS.size())
	else:
		var count: int = carried().size()
		if count == 0:
			return
		_bag_at = posmod(_bag_at + by, count)
	Sound.cue(&"move")


## **Enter: what is under the cursor goes on, or comes off** — one event, answered at once.
## Public, so the suite can press it. False when there was nothing to do.
func act() -> bool:
	var bag: Inventory = _bag()
	if bag == null:
		return false
	if _column == 0:
		var slot: StringName = ItemRules.SLOTS[_slot_at]
		if bag.in_slot(slot) == &"":
			Sound.cue(&"refused")
			return false
		_sim.submit(&"unequip", {"slot": String(slot)})
	else:
		var item: StringName = under_cursor()
		if item == &"":
			Sound.cue(&"refused")
			return false
		_sim.submit(&"equip", {"item": String(item)})
	_sim.advance(1)
	Sound.cue(&"accept")
	_bag_at = clampi(_bag_at, 0, maxi(carried().size() - 1, 0))
	_dress()
	return true


## Where the cursor is, for the suite and for a photograph: the column (0 worn, 1 bag)
## and the row.
func point(column: int, row: int) -> void:
	_column = clampi(column, 0, 1)
	if _column == 0:
		_slot_at = clampi(row, 0, ItemRules.SLOTS.size() - 1)
	else:
		_bag_at = maxi(row, 0)


## The bag's item under the cursor, or nothing when the cursor is on the slots.
func under_cursor() -> StringName:
	var items: Array[StringName] = carried()
	if _column != 1 or items.is_empty():
		return &""
	return items[mini(_bag_at, items.size() - 1)]


# ------------------------------------------------------------------- drawing ---

## The bag shows this many rows, and scrolls past them: ten things today, more weapons
## to come (Yannick, 2026-10-01).
const BAG_ROWS: int = 8
const BAG_STEP: float = 17.0


func _draw() -> void:
	var screen: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.02, 0.02, 0.03, 0.82), true)
	Ui.write_over(self, Vector2(0.0, 34.0), Text.of(&"inventory.title"), Ui.LARGE, Ui.INK,
		HORIZONTAL_ALIGNMENT_CENTER, screen.x)
	Ui.panel(self, SLOTS)
	Ui.panel(self, DOLL, Color(0.10, 0.10, 0.11, 0.92))
	Ui.panel(self, BAG)
	_draw_ground()
	_draw_worn()
	_draw_bag()
	Ui.write_over(self, Vector2(0.0, SLOTS.end.y + 24.0), Text.of(&"inventory.help"), Ui.NOTE, Ui.FAINT,
		HORIZONTAL_ALIGNMENT_CENTER, screen.x)


func _draw_ground() -> void:
	var feet := Vector2(DOLL.get_center().x, DOLL.end.y - 34.0)
	var points := PackedVector2Array()
	for i: int in 24:
		var a: float = TAU * float(i) / 24.0
		points.append(feet + Vector2(cos(a) * 34.0, sin(a) * 34.0 * 0.28))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.35))


func _draw_worn() -> void:
	var bag: Inventory = _bag()
	Ui.write_over(self, Vector2(SLOTS.position.x, SLOTS.position.y + 16.0), Text.of(&"inventory.worn"),
		Ui.BODY, Ui.SAGE, HORIZONTAL_ALIGNMENT_CENTER, SLOTS.size.x)
	for i: int in ItemRules.SLOTS.size():
		var slot: StringName = ItemRules.SLOTS[i]
		var y: float = SLOTS.position.y + 40.0 + float(i) * ROW_STEP
		var lit: bool = _column == 0 and i == _slot_at
		if lit:
			Ui.caret(self, Vector2(SLOTS.position.x + 8.0, y - 4.0), 6.0)
		Ui.write_over(self, Vector2(SLOTS.position.x + 18.0, y), Text.of(StringName("slot.%s" % slot)),
			Ui.ROW, Ui.GOLD if lit else Ui.DIM)
		var item: StringName = bag.in_slot(slot) if bag != null else &""
		var name: String = Text.of(StringName("item.%s" % item)) if item != &"" else Text.of(&"inventory.nothing")
		Ui.write_over(self, Vector2(SLOTS.position.x + NAME_AT, y), name, Ui.NOTE,
			(Ui.GOLD if lit else Ui.INK) if item != &"" else Ui.FAINT)
	var top: float = SLOTS.position.y + 40.0 + float(ItemRules.SLOTS.size()) * ROW_STEP + 8.0
	draw_line(Vector2(SLOTS.position.x + 10.0, top - 8.0), Vector2(SLOTS.end.x - 10.0, top - 8.0),
		Color(0.75, 0.70, 0.55, 0.28), 1.0)
	var lines: Array[String] = totals()
	for i: int in lines.size():
		Ui.write_over(self, Vector2(SLOTS.position.x + 12.0, top + 8.0 + float(i) * 15.0), lines[i],
			Ui.NOTE, Ui.INK if i == 0 else Ui.DIM)


## **What it adds up to**: the protection taken off every blow, whether he is weighed
## down, and what he strikes with. Public, so the suite can measure every line.
func totals() -> Array[String]:
	var lines: Array[String] = []
	var bag: Inventory = _bag()
	if bag == null:
		return lines
	lines.append(Text.of(&"inventory.protection", [bag.protection()]))
	var heavy: bool = ItemRules.heavy_pieces(bag.equipped) >= ItemRules.HEAVY_FROM
	lines.append(Text.of(&"inventory.heavy") if heavy else Text.of(&"inventory.light"))
	var weapon: StringName = bag.weapon_in_hand()
	var held: StringName = bag.in_slot(ItemRules.WEAPON)
	var with: String = Text.of(&"inventory.fists")
	if held != &"":
		with = Text.of(StringName("item.%s" % held))
	elif weapon != DuelRules.FISTS:
		# A run never made at creation (the suite's, a scene opened alone) holds the
		# sword it always had without carrying it.
		with = Text.of(&"item.short_sword")
	lines.append(Text.of(&"inventory.strikes", [with, DuelRules.damage_with(weapon)]))
	return lines


func _draw_bag() -> void:
	Ui.write_over(self, Vector2(BAG.position.x, BAG.position.y + 16.0), Text.of(&"inventory.bag"),
		Ui.BODY, Ui.SAGE, HORIZONTAL_ALIGNMENT_CENTER, BAG.size.x)
	var items: Array[StringName] = carried()
	if items.is_empty():
		Ui.write_over(self, Vector2(BAG.position.x, BAG.position.y + 44.0), Text.of(&"inventory.empty_bag"),
			Ui.NOTE, Ui.FAINT, HORIZONTAL_ALIGNMENT_CENTER, BAG.size.x)
		return
	var first: int = clampi(_bag_at - (BAG_ROWS - 1), 0, maxi(items.size() - BAG_ROWS, 0))
	for i: int in range(first, mini(first + BAG_ROWS, items.size())):
		var y: float = BAG.position.y + 40.0 + float(i - first) * BAG_STEP
		var lit: bool = _column == 1 and i == _bag_at
		if lit:
			Ui.caret(self, Vector2(BAG.position.x + 8.0, y - 4.0), 6.0)
		Ui.write_over(self, Vector2(BAG.position.x + 18.0, y), Text.of(StringName("item.%s" % items[i])),
			Ui.ROW, Ui.GOLD if lit else Ui.INK)
	if first > 0:
		_arrow(Vector2(BAG.end.x - 14.0, BAG.position.y + 30.0), -1.0)
	if first + BAG_ROWS < items.size():
		_arrow(Vector2(BAG.end.x - 14.0, BAG.position.y + 40.0 + float(BAG_ROWS) * BAG_STEP - 10.0), 1.0)
	var item: StringName = under_cursor()
	if item == &"":
		return
	var told: Array[String] = about(item)
	draw_line(Vector2(BAG.position.x + 10.0, BAG.end.y - 46.0), Vector2(BAG.end.x - 10.0, BAG.end.y - 46.0),
		Color(0.75, 0.70, 0.55, 0.28), 1.0)
	for i: int in told.size():
		Ui.write_over(self, Vector2(BAG.position.x + 12.0, BAG.end.y - 30.0 + float(i) * 14.0), told[i],
			Ui.NOTE, Ui.DIM)


## A small triangle saying there is more of the bag above (-1) or below (1).
func _arrow(at: Vector2, way: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-4.0, -2.0 * way), at + Vector2(4.0, -2.0 * way), at + Vector2(0.0, 3.0 * way),
	]), Ui.DIM)


## **An item's numbers, in the screen's words**: what it protects or strikes for and
## whether it is heavy, then what it would take the place of.
func about(item: StringName) -> Array[String]:
	var out: Array[String] = [describe(item)]
	var bag: Inventory = _bag()
	var worn: StringName = bag.in_slot(ItemRules.slot_of(item)) if bag != null else &""
	if worn != &"" and worn != item:
		out.append(Text.of(&"inventory.replaces", [Text.of(StringName("item.%s" % worn))]))
	return out


static func describe(item: StringName) -> String:
	var weapon: StringName = ItemRules.weapon_of(item)
	var parts: Array[String] = []
	if weapon == DuelRules.BOW:
		parts.append(Text.of(&"inventory.item_ranged",
			[DuelRules.damage_with(weapon), DuelRules.bow_min_tiles(), DuelRules.reach_with(weapon)]))
	elif weapon != &"":
		parts.append(Text.of(&"inventory.item_weapon", [DuelRules.damage_with(weapon)]))
	else:
		var protects: int = ItemRules.protection_of(item)
		parts.append(Text.of(&"inventory.item_protection", [protects]) if protects > 0 else Text.of(&"inventory.item_none"))
	if ItemRules.is_heavy(item):
		parts.append(Text.of(&"inventory.item_heavy"))
	return ", ".join(parts)
