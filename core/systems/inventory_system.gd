class_name InventorySystem
extends SimSystem

## **What the player comes by, and what he puts on** (group E).
##
## Everything here is an event, like every other act, so a save carries what was found,
## taken and worn, and a replay rebuilds the same bag:
##
## - `character_made` — the start kit: a cloth tunic, cloth trousers, walking boots, and
##   no weapon. The first sword lies by the graves (Yannick, 2026-10-01).
## - `pick_up` — something lying where it can be picked up (`content/places.json`'s
##   `finds`), from beside it, once.
## - a fact that grants an item (`from_fact`) — Wren's bow, which a line of hers has given
##   since T5 as `you:the_bow`.
## - `duel_down` — what a beaten fighter leaves: what you saw on him.
## - `equip`, `unequip` — the inventory screen's two acts. **Not in a fight**: a fight is
##   turns, and changing armour mid-blow would make protection a move.
##
## Each gain derives `item_gained`, which the window says aloud.

## A find picked up, so it is not there to pick up again and the world stops drawing it.
const FOUND: String = "found:%s"
## How close the player must stand to pick something up, in tiles from its centre.
const REACH: float = 1.6


func steps() -> bool:
	return false


func ticks() -> bool:
	return false


func system_name() -> StringName:
	return &"inventory"


func on_event(sim: Sim, event: SimEvent) -> void:
	var inventory := sim.store(&"inventory") as Inventory
	if inventory == null:
		return
	match event.type:
		&"character_made":
			inventory.made = true
			for item: StringName in ItemRules.start_kit():
				_give(sim, inventory, item, &"start")
		&"equip":
			_equip(sim, inventory, StringName(String(event.data.get("item", ""))))
		&"unequip":
			_unequip(sim, inventory, StringName(String(event.data.get("slot", ""))))
		&"pick_up":
			_pick_up(sim, inventory, StringName(String(event.data.get("find", ""))))
		&"duel_down":
			_loot(sim, inventory, StringName(String(event.data.get("who", ""))))
		&"duel_began":
			_ready_the_bow(sim, inventory, String(event.data.get("drill", "")))
		&"duel_ended":
			for item: StringName in inventory.wear_what_waited():
				sim.derive(&"equipped", {"item": String(item), "slot": String(ItemRules.slot_of(item))})
	_granted(sim, inventory)


func _give(sim: Sim, inventory: Inventory, item: StringName, from: StringName, wear: bool = true) -> void:
	if inventory.gain(item, wear):
		sim.derive(&"item_gained", {"item": String(item), "from": String(from),
			"worn": inventory.in_slot(ItemRules.slot_of(item)) == item})


func _fighting(sim: Sim) -> bool:
	var duel := sim.store(&"duel") as Duel
	return duel != null and duel.on()


func _equip(sim: Sim, inventory: Inventory, item: StringName) -> void:
	if _fighting(sim):
		sim.derive(&"equip_refused", {"item": String(item), "why": "fight"})
	elif not inventory.equip(item):
		sim.derive(&"equip_refused", {"item": String(item), "why": "not_owned"})
	else:
		sim.derive(&"equipped", {"item": String(item), "slot": String(ItemRules.slot_of(item))})


func _unequip(sim: Sim, inventory: Inventory, slot: StringName) -> void:
	if _fighting(sim):
		sim.derive(&"equip_refused", {"slot": String(slot), "why": "fight"})
	elif inventory.unequip(slot):
		sim.derive(&"unequipped", {"slot": String(slot)})


## **From beside it, once.** Too far, already taken, or nothing by that name: nothing.
func _pick_up(sim: Sim, inventory: Inventory, id: StringName) -> void:
	var world := sim.store(&"world") as WorldState
	if world == null or sim.facts.has(StringName(FOUND % id)):
		return
	for find: Dictionary in Places.shared().finds():
		if find["id"] != id:
			continue
		var at: Vector2i = world.region().resolve(find["anchor"] as Dictionary)
		if world.player_pos.distance_to(Vector2(at) + Vector2(0.5, 0.5)) > REACH:
			sim.derive(&"pick_up_refused", {"find": String(id), "why": "far"})
			return
		sim.facts.add_source(StringName(FOUND % id), &"witnessed")
		_give(sim, inventory, find["item"] as StringName, &"find")
		return


## **What you saw on him** (`content/items.json`'s `loot`). A king's guard leaves the piece
## of his seat, so the three of them leave the set.
func _loot(sim: Sim, inventory: Inventory, who: StringName) -> void:
	if who == Duel.NOBODY or who == DuelRules.PLAYER:
		return
	var duel := sim.store(&"duel") as Duel
	if duel != null and duel.drill != Duel.NOBODY:
		return
	var kind: StringName = DuelRules.kind_of(who)
	var seat: int = 1
	var parts: PackedStringArray = String(who).split("#")
	if parts.size() > 1:
		seat = int(parts[1])
	var left: Array[StringName] = ItemRules.loot_of(kind, seat)
	if left.is_empty():
		# A stranger of the cast is read by his trade: `gatekeeper@1` is a gatekeeper.
		kind = DuelRules.trade_of(who)
		left = ItemRules.loot_of(kind, seat)
	# Into the bag while the fight goes on, on once it is over (`wear_what_waited`).
	for item: StringName in left:
		_give(sim, inventory, item, kind, not _fighting(sim))


## **The bow lesson puts your bow in its place** (the review of group E): a player who took
## Wren's bow off before trying again could never shoot in it, and nothing said why.
func _ready_the_bow(sim: Sim, inventory: Inventory, drill: String) -> void:
	if drill != String(DuelRules.BOW) or inventory.in_slot(ItemRules.BOW) != &"":
		return
	for item: StringName in inventory.owned:
		if ItemRules.slot_of(item) == ItemRules.BOW:
			inventory.equip(item)
			sim.derive(&"equipped", {"item": String(item), "slot": String(ItemRules.BOW)})
			return


## An item a fact grants — Wren's bow — arrives the moment the fact is written.
func _granted(sim: Sim, inventory: Inventory) -> void:
	for item: StringName in ItemRules.items():
		var fact: StringName = ItemRules.fact_of(item)
		if fact != &"" and not inventory.has(item) and sim.facts.has(fact):
			_give(sim, inventory, item, &"given")
