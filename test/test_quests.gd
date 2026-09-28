extends TestCase

## Quests as predicates over the fact base.
##
## **Invariant 5 is the whole design here**, not a thing checked afterwards:
## *"quests are reactions to fact patterns, not scripts. A quest that can only start
## one way is a bug."* Because a quest is keyed on facts, and §7 requires every fact
## to have more than one source, **every quest has more than one way in for free** —
## and the test below proves it by counting the people who could open each one.


func _facts() -> FactBase:
	return FactBase.new()


func _knows(facts: FactBase, of: Array) -> void:
	for fact: Variant in of:
		facts.add_source(fact as StringName, &"test")


# --------------------------------------------------------------- the shape ---

func test_the_demo_has_one_quest_and_it_is_the_works() -> void:
	# **C3, 2026-09-28.** `SIMULATION_KEEP_OR_DROP.md`: the fact-pattern *mechanism* is
	# right and fits one quest per place; the eight quests of the old game go. The one
	# left is the fairy's, and the Cinderworks is where it is answered.
	assert_eq(QuestRules.all().size(), 1, "one quest: %s" % str(QuestRules.all()))
	assert_eq(QuestRules.all()[0]["id"], &"the_wood_is_going")


func test_a_quest_opens_because_you_learned_something() -> void:
	var facts: FactBase = _facts()
	var quest: Dictionary = QuestRules.find(&"the_wood_is_going")
	assert_false(QuestRules.is_open(quest, facts), "she has not asked you yet")
	_knows(facts, [OpeningRules.FACT_LAST_WORD])
	assert_true(QuestRules.is_open(quest, facts), "and now she has")


func test_either_act_at_the_works_answers_it() -> void:
	# `done_any`, and these are the two acts the quest actually ends on — put the fires
	# out with Tom, or light them again with Sena. **Both answer her question**, one of
	# them the way she did not want: a quest that only closes on the answer she hoped
	# for would be a quest that stays open for half the players who finish the demo.
	for act: StringName in [DeedRules.DEED_DOUSE, DeedRules.DEED_RELIGHT]:
		var facts: FactBase = _facts()
		_knows(facts, [OpeningRules.FACT_LAST_WORD])
		assert_eq(QuestRules.progress(QuestRules.find(&"the_wood_is_going"), facts), [0, 1])
		_knows(facts, [act])
		assert_true(QuestRules.is_done(QuestRules.find(&"the_wood_is_going"), facts),
			"%s settles it" % act)
		assert_false(QuestRules.is_open(QuestRules.find(&"the_wood_is_going"), facts),
			"so it is no longer a question")


# ----------------------------------------------------------- invariant 5 ---

func test_no_quest_can_only_start_one_way() -> void:
	# The invariant, counted rather than asserted. For every fact a quest needs, at
	# least two different people in the cast can teach it — or it is a fact the
	# player is given by the world rather than by a person, which cannot be closed
	# off by killing anybody.
	var cast: Cast = Cast.shared()
	var teachers: Dictionary = {}
	for id: StringName in cast.npcs.keys():
		for option: DialogueOption in cast.get_npc(id).options:
			if option.teaches == &"":
				continue
			if not teachers.has(option.teaches):
				teachers[option.teaches] = []
			(teachers[option.teaches] as Array).append(id)

	for quest: Dictionary in QuestRules.all():
		for fact: Variant in (quest["needs"] as Array):
			var name: StringName = fact as StringName
			# Two kinds of fact are exempt, and both because **no death can take them
			# away** — which is what the invariant is actually protecting.
			#
			# `met:` is produced by walking up to somebody, and the opening's seven
			# are given in the first minute by a fairy who cannot be killed and does
			# not leave until she has finished. Asked of `OpeningRules` rather than by
			# matching a `you:` prefix, so that if she gains or loses a line the
			# exemption follows her instead of going stale.
			if String(name).begins_with("met:"):
				continue
			if OpeningRules.WHAT_SHE_TELLS_YOU.has(name):
				# The exemption rests on her being there to say it, so that is checked.
				assert_not_null(cast.get_npc(OpeningRules.FAIRY),
					"%s needs '%s', which the fairy gives in the first minute" % [quest["id"], name])
				continue
			var who: Array = teachers.get(name, []) as Array
			assert_true(who.size() >= 2,
				"%s needs '%s', which only %s can teach" % [quest["id"], name, str(who)])


func test_every_quest_can_actually_be_finished() -> void:
	# A predicate nobody can satisfy is a dead end dressed as content. Every fact a
	# quest wants has to be reachable: taught by somebody, met by walking up to them,
	# or performed as a deed.
	var cast: Cast = Cast.shared()
	var reachable: Dictionary = {}
	for id: StringName in cast.npcs.keys():
		reachable[StringName("met:%s" % id)] = true
		for option: DialogueOption in cast.get_npc(id).options:
			if option.teaches != &"":
				reachable[option.teaches] = true
	for deed: StringName in DeedRules.all_deeds():
		reachable[deed] = true
	# And the quest's own acts, which a kiln offers once you are in with either side —
	# asked of `SiteRules` itself, so the day it offers something else this follows.
	var brought := FactBase.new()
	brought.add_source(SiteRules.BROUGHT_THROUGH, &"test")
	var vouched := FactBase.new()
	vouched.add_source(SiteRules.VOUCHED_FOR, &"test")
	for facts: FactBase in [brought, vouched]:
		reachable[SiteRules.quest_deed_at(&"kiln", facts)] = true
	for fact: StringName in OpeningRules.WHAT_SHE_TELLS_YOU:
		reachable[fact] = true

	for quest: Dictionary in QuestRules.all():
		var wanted: Array = (quest.get("done", []) as Array) + (quest.get("done_any", []) as Array)
		assert_false(wanted.is_empty(), "%s can be finished at all" % quest["id"])
		for fact: Variant in wanted + (quest["needs"] as Array):
			assert_true(reachable.has(fact as StringName),
				"%s wants '%s', which nothing in the world produces" % [quest["id"], fact])


func test_every_quest_has_a_name_and_a_note_in_both_languages() -> void:
	for language: String in ["en", "fr"]:
		var known: Array[String] = Text.keys_for(language)
		for quest: Dictionary in QuestRules.all():
			assert_true(known.has(String(QuestRules.name_key(quest))),
				"%s: %s" % [language, QuestRules.name_key(quest)])
			assert_true(known.has(String(QuestRules.note_key(quest))),
				"%s: %s" % [language, QuestRules.note_key(quest)])


func test_quests_need_no_store_and_survive_a_reload() -> void:
	# The reason there is no quest store: the state *is* the fact base, so a reloaded
	# save has exactly the quests its facts imply and there is nothing to migrate.
	var sim: Sim = Game.build()
	var world := sim.store(&"world") as WorldState
	sim.submit(&"talk", {"npc": "fairy"})
	sim.advance(2)
	for _line: int in 9:
		if world.options.is_empty():
			break
		sim.submit(&"choose_intent", {"intent": String(world.options[0].intent)})
		sim.advance(2)
	var before: int = QuestRules.open_ones(sim.facts).size()
	assert_eq(before, 1, "her question is open")
	var replayed: Sim = Game.replay(sim)
	assert_eq(QuestRules.open_ones(replayed.facts).size(), before,
		"the same facts, so the same questions")
