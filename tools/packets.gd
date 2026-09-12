extends SceneTree

## Dump many context packets at once.
##
## `tools/packet.gd` prints one, which is right for reading a single person. This
## prints the whole grid — every named person, every question they can be asked,
## under several different worlds — because the question the dialogue experiment
## asks is not "is this packet good" but "is the packet **always** enough to write
## from". One good packet proves nothing; the thin ones are the answer.
##
##   godot --headless --path . -s tools/packets.gd -- fr
##   godot --headless --path . -s tools/packets.gd -- en halgrave,mira,pell

const SITUATIONS: Array[StringName] = [&"plain", &"welcome", &"unwelcome", &"hungry"]

## What a player who has been playing for an hour has found out.
const LEARNED: Array[StringName] = [
	&"cinderworks:death_toll", &"muster:pay_fraud", &"thornwood:kell",
]


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var locale: String = args[0] if args.size() > 0 else "fr"
	var only: PackedStringArray = args[1].split(",", false) if args.size() > 1 else PackedStringArray()
	Text.set_locale(locale)

	for situation: StringName in SITUATIONS:
		var sim: Sim = Game.build()
		Text.set_locale(locale)
		var world := sim.store(&"world") as WorldState
		var cast := sim.store(&"cast") as Cast
		var standing := sim.store(&"standing") as Standing
		var ticked := sim.store(&"worldtick") as WorldTick

		for npc: Npc in cast.named():
			if only.size() > 0 and not only.has(String(npc.id)):
				continue
			_set_up(situation, npc, world, standing, ticked, sim.facts)

		for npc: Npc in cast.named():
			if only.size() > 0 and not only.has(String(npc.id)):
				continue
			for option: DialogueOption in npc.options:
				var packet: String = Context.build(npc.id, world, cast, standing,
					ticked, sim.facts, Relations.shared(), option)
				print("=== %s | %s | %s | %s" % [npc.id, option.intent, situation,
					Context.fingerprint(packet)])
				print(packet)
				print("--- WROTE")
				print(option.reply)
				print("")
	quit()


## The worlds. Each one is a state the player can actually walk into, not a stress
## test: somebody who has never met you, somebody who likes you, somebody who saw
## you take something, and a town where bread has doubled.
func _set_up(situation: StringName, npc: Npc, world: WorldState, standing: Standing,
		ticked: WorldTick, facts: FactBase) -> void:
	var town: StringName = world.region().zone_at(npc.tile)
	match situation:
		&"welcome":
			facts.add_source(StringName("met:%s" % npc.id), &"setup")
			# Somebody who has got this far has learned things. A packet where the
			# player knows nothing is a packet where every answer is written for
			# somebody who just walked in off the road, which was the whole gap.
			for fact: StringName in LEARNED:
				facts.add_source(fact, &"setup")
			standing.shift_person(npc.id, 45.0)
			standing.shift_town(town, 25.0)
		&"unwelcome":
			facts.add_source(StringName("met:%s" % npc.id), &"setup")
			facts.add_source(DeedRules.DEED_THEFT, &"setup")
			for fact: StringName in LEARNED:
				facts.add_source(fact, &"setup")
			standing.shift_person(npc.id, -45.0)
			standing.shift_town(town, -30.0)
			ticked.rouse(town, 25.0)
		&"hungry":
			facts.add_source(StringName("met:%s" % npc.id), &"setup")
			ticked.grain_price[town] = 88.0
			ticked.push_sentiment(town, -30.0)
			ticked.army_strength = 62.0
