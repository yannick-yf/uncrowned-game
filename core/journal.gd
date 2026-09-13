class_name Journal
extends RefCounted

## What happened, and why — the only place in the game allowed to answer the second.
##
## §15 calls this the most important screen in the game and §8 makes it the third
## feedback register: IMMEDIATE is the act confirmed as you do it, AMBIENT is the
## world quietly changing its mind, and NARRATED is this. Most systemic games ship
## the first two, which is why their players never feel their choices mattered.
##
## **Push the ambient, pull the attribution.** Nothing in the world ever tells the
## player they caused something — Maddox not knowing it was you is the whole
## pleasure of it. So the causal chain lives here, behind a key, and is never
## announced.
##
## It is read from the event log and nothing else. That is what the external/derived
## split was paid for, and it is why a run replayed from its log tells the same
## story word for word.
##
## **This file does not write sentences.** It returns what happened as data — a
## kind, the town, how many saw it, how many days — and the window makes the words.
## It used to build English prose here, which put presentation inside the simulation
## and would have made the game untranslatable (2026-09-12).

const GRAIN_IS_NEWS: float = 60.0

const DEED: StringName = &"deed"
const UNSEEN: StringName = &"unseen"
const ARRIVAL: StringName = &"arrival"
const FRAUD: StringName = &"fraud"
const ARMY: StringName = &"army"
const GRAIN: StringName = &"grain"
const ESCORT: StringName = &"escort"
const HARDSHIP: StringName = &"hardship"
const FLIP: StringName = &"flip"


## One chronological list. Every row carries facts, never phrasing.
static func entries(events: EventLog, _facts: FactBase = null) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var last_deed: Dictionary = {}
	var fraud_told: StringName = &""
	var army_has_fallen: bool = false
	var grain_reported: Dictionary = {}
	var hardship_reported: Dictionary = {}

	for event: SimEvent in events.all():
		var tick: int = _tick_of(event)
		match event.type:
			&"deed_witnessed":
				var deed: StringName = StringName(event.data.get("about", ""))
				var where: StringName = StringName(event.data.get("town", ""))
				last_deed[deed] = where
				rows.append({
					"tick": tick, "kind": DEED, "deed": deed, "town": where,
					"seen": (event.data.get("witnesses", []) as Array).size(),
					"spends_the_telling": deed == DeedRules.DEED_WARNING,
				})
			&"theft_unseen", &"act_unseen", &"deed_unseen":
				rows.append({
					"tick": tick, "kind": UNSEEN,
					"deed": StringName(event.data.get("about", DeedRules.DEED_THEFT)),
					"town": StringName(event.data.get("town", "")),
				})
			&"rumour_arrived":
				var about: StringName = StringName(event.data.get("about", ""))
				var town: StringName = StringName(event.data.get("town", ""))
				if not last_deed.has(about) or last_deed[about] == town:
					continue
				rows.append({
					"tick": tick, "kind": ARRIVAL, "deed": about, "town": town,
					"origin": last_deed[about] as StringName,
					"days": float(event.data.get("days", 0.0)),
					"carried": bool(event.data.get("carried", false)),
				})
			&"fraud_exposed":
				fraud_told = &"muster"
				rows.append({"tick": tick, "kind": FRAUD, "town": fraud_told,
					"spends_the_telling": true})
			&"army_fell":
				if army_has_fallen:
					continue
				army_has_fallen = true
				rows.append({"tick": tick, "kind": ARMY, "told_at": fraud_told})
			&"grain_moved":
				var to: float = float(event.data.get("to", 0.0))
				var at: StringName = StringName(event.data.get("town", ""))
				if to < GRAIN_IS_NEWS or grain_reported.has(at):
					continue
				grain_reported[at] = true
				rows.append({"tick": tick, "kind": GRAIN, "town": at,
					"after_the_army": army_has_fallen})
			&"place_decided":
				# A place the player decided. Once per change; a decision that kept a
				# place where it was is a stamp, not news.
				if not bool(event.data.get("changed", false)):
					continue
				rows.append({"tick": tick, "kind": FLIP,
					"town": StringName(event.data.get("zone", "")),
					"to": StringName(event.data.get("to", "")), "by_player": true})
			&"ground_changed_hands":
				# The band moved it. The row says it turned, and nothing about you.
				rows.append({"tick": tick, "kind": FLIP,
					"town": StringName(event.data.get("zone", "")),
					"to": StringName(event.data.get("to", "")), "by_player": false})
			&"hardship_moved":
				# Who an act cost, once per town per cause. The only place in the game
				# that joins the two (§8): the town shows it and the person there says
				# it, and neither of them says why.
				if float(event.data.get("amount", 0.0)) <= 0.0:
					continue
				var cause: StringName = StringName(event.data.get("about", ""))
				var place: StringName = StringName(event.data.get("town", ""))
				var key: String = "%s|%s" % [place, cause]
				if hardship_reported.has(key):
					continue
				hardship_reported[key] = true
				rows.append({"tick": tick, "kind": HARDSHIP, "town": place, "deed": cause})
			&"escort_changed":
				rows.append({"tick": tick, "kind": ESCORT,
					"from": int(event.data.get("from", 0)),
					"to": int(event.data.get("to", 0)),
					"after_the_army": army_has_fallen})
	return rows


## What you know, and who you had it from. §15's other half: progression here is
## knowledge, so this is where it is visible. `line` is a description authored in
## content and therefore already in the player's language.
static func knowledge(facts: FactBase, cast: Cast) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if facts == null:
		return rows
	for fact: StringName in facts.facts():
		var described: String = String(cast.fact_descriptions.get(fact, "")) if cast != null else ""
		if described == "":
			continue
		var told_by := PackedStringArray()
		for source: StringName in facts.sources_of(fact):
			var npc: Npc = cast.get_npc(source) if cast != null else null
			told_by.append(npc.display_name if npc != null else String(source))
		rows.append({
			"fact": String(fact),
			"line": described,
			"from": told_by,
			"safe": facts.is_redundant(fact),
		})
	return rows


## Events are stamped with the step, because two key presses inside the same in-game
## minute must replay in order. A journal is read in in-game time, so it converts.
static func _tick_of(event: SimEvent) -> int:
	return event.step / Sim.STEPS_PER_WORLD_TICK
