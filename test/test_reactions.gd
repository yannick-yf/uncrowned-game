extends TestCase

## What somebody says in front of an answer, because of where you stand with them.
##
## **This is what replaced the model** (2026-09-12). Generated dialogue was tested and
## dropped: the door can check figures, names, register and formatting, and none of
## that catches a line that says the opposite of what it was told. Shrinking the job
## to one fact-free sentence removed that failure by construction and the model still
## got the sign backwards 5 times in 6, refusing to help people who liked it.
##
## But the thing being generated was measured and it is real: lines diverge 50%
## between worlds where the player has acted and 74% where they have not, and all of
## that divergence is the opening sentence. So it is written by hand, where every one
## of them can be read before it ships — which is the whole argument, and it is worth
## noticing that the argument is not "models are bad" but "this is small".


func _world() -> Sim:
	var sim: Sim = Game.build()
	Text.set_locale("en")
	return sim


## **The town's opinion, not the person's** (J5, `docs/PLAYER_MODEL.md` §5). A
## reaction used to be read off what this one person thought of you; since the player
## model it is read off what the place you are both standing in thinks. The line
## written for each band is unchanged, and so is every claim below — only where the
## band comes from has moved.
func _talk_to(sim: Sim, who: StringName, regard: float) -> void:
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(who).centre()
	var here: StringName = world.region().zone_at(world.player_tile())
	var player := sim.store(&"player") as PlayerState
	if not player.has_standing(here):
		fail("%s stands in %s, which carries no standing" % [who, here])
	player.standing[here] = regard
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)


func _ask_first(sim: Sim) -> String:
	var world := sim.store(&"world") as WorldState
	if world.options.is_empty():
		return ""
	sim.submit(&"choose_intent", {"intent": String(world.options[0].intent)})
	sim.advance(2)
	return world.current_line


# ----------------------------------------------------------------- content ---

func test_every_reaction_obeys_the_rule_for_an_opener() -> void:
	# The same check the model's output had to pass, turned on the hand-written
	# version. If the rules were right for a machine they are right for me.
	for language: String in ["en", "fr"]:
		Text.set_locale(language)
		Cast.forget()
		var cast: Cast = Cast.shared()
		var known: PackedStringArray = ProseRules.known_names(cast)
		var counted: int = 0
		for band: StringName in cast.reactions.keys():
			counted += 1
			for fault: String in ProseRules.opener_faults(
					String(cast.reactions[band]), known):
				assert_true(false, "%s shared '%s': %s" % [language, band, fault])
		for npc: Npc in cast.named():
			for band: StringName in npc.reactions.keys():
				counted += 1
				for fault: String in ProseRules.opener_faults(
						String(npc.reactions[band]), known):
					assert_true(false, "%s %s/%s: %s" % [language, npc.id, band, fault])
		assert_true(counted >= 20, "%s carries %d reactions" % [language, counted])
	Text.set_locale("en")
	Cast.forget()


func test_the_two_languages_carry_the_same_reactions() -> void:
	# A band written in one language and missing in the other is a French player
	# hearing a stock line where an English one hears a character.
	var here: Dictionary = {}
	for language: String in ["en", "fr"]:
		var cast: Cast = Cast.load_from(Cast.path_for(language))
		var keys := PackedStringArray()
		for band: StringName in cast.reactions.keys():
			keys.append("shared.%s" % band)
		for id: StringName in cast.npcs.keys():
			for band: StringName in cast.get_npc(id).reactions.keys():
				keys.append("%s.%s" % [id, band])
		keys.sort()
		here[language] = ", ".join(keys)
	assert_eq(String(here["fr"]), String(here["en"]), "both languages, the same set")
	assert_true(String(here["fr"]).length() > 0, "and there is something in the set")


func test_nobody_is_given_a_reaction_at_a_standing_that_cannot_talk() -> void:
	# Below `hated` the whole conversation is refused, so a line written for it is a
	# line nobody will ever read — and it would read as though the refusal had a
	# voice, which it does not.
	for language: String in ["en", "fr"]:
		var cast: Cast = Cast.load_from(Cast.path_for(language))
		assert_false(cast.reactions.has(&"hated"), "%s: no shared line for hated" % language)
		for id: StringName in cast.npcs.keys():
			assert_false(cast.get_npc(id).reactions.has(&"hated"),
				"%s: %s has one for hated" % [language, id])


# ------------------------------------------------------------- in the game ---

func test_the_joined_line_still_fits_the_box() -> void:
	# The one real risk in joining two written things: French runs longer than
	# English and the longest reply is already 37 words. Checked against every
	# combination that can actually occur rather than against the worst case, because
	# the worst case pairs a long reply with an opener that person never says.
	for language: String in ["en", "fr"]:
		Text.set_locale(language)
		Cast.forget()
		var cast: Cast = Cast.shared()
		var known: PackedStringArray = ProseRules.known_names(cast)
		for npc: Npc in cast.named():
			for band: StringName in StandingRules.scale():
				var reaction: String = cast.reaction_for(npc, band)
				if reaction.is_empty():
					continue
				for option: DialogueOption in npc.options:
					var joined: String = ProseRules.joined(reaction, option.reply)
					for fault: String in ProseRules.faults(joined, known):
						assert_true(false, "%s %s/%s/%s: %s"
							% [language, npc.id, option.intent, band, fault])
		assert_true(true, "%s: every reaction against every answer fits" % language)
	Text.set_locale("en")
	Cast.forget()


func test_a_stranger_hears_exactly_what_the_game_always_said() -> void:
	# The guarantee that makes this safe to add at all. Neutral standing has no
	# reaction, so every line the game shipped with is untouched.
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	_talk_to(sim, &"harry", 0.0)
	assert_false(world.options.is_empty(), "he has something to be asked")
	var asked: StringName = world.options[0].intent
	var written: String = DialogueRules.find(cast.get_npc(&"harry"), asked).reply
	assert_eq(_ask_first(sim), written, "word for word what was written")


func test_a_man_in_a_town_that_has_turned_on_you_answers_differently() -> void:
	var written: Sim = _world()
	_talk_to(written, &"harry", 0.0)
	var plain: String = _ask_first(written)

	var sour: Sim = _world()
	_talk_to(sour, &"harry", -45.0)
	var cold: String = _ask_first(sour)

	assert_ne(cold, plain, "the same question, and it does not open the same way")
	assert_true(cold.ends_with(plain), "but the facts under it are untouched")


func test_the_reaction_is_said_once_and_not_every_time() -> void:
	# A man who says "you will have the number anyway" to all three questions is a
	# machine with a stuck key. The relationship needs acknowledging once.
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var reaction: String = cast.reaction_for(cast.get_npc(&"maddox"), &"unwelcome")
	assert_false(reaction.is_empty(), "he has one")

	_talk_to(sim, &"maddox", -45.0)
	assert_true(_ask_first(sim).begins_with(reaction), "the first answer carries it")
	for _round: int in 2:
		if world.options.is_empty():
			break
		sim.submit(&"choose_intent", {"intent": String(world.options[0].intent)})
		sim.advance(2)
		assert_false(world.current_line.begins_with(reaction), "and the next ones do not")


func test_walking_away_and_coming_back_acknowledges_it_again() -> void:
	# The thread is the conversation, not the relationship. Leaving and returning is
	# a new exchange, and he has not stopped knowing what you did.
	var sim: Sim = _world()
	var cast := sim.store(&"cast") as Cast
	var reaction: String = cast.reaction_for(cast.get_npc(&"maddox"), &"unwelcome")
	_talk_to(sim, &"maddox", -45.0)
	assert_true(_ask_first(sim).begins_with(reaction), "said once")
	sim.submit(&"end_talk")
	sim.advance(2)
	sim.submit(&"talk", {"npc": "maddox"})
	sim.advance(2)
	assert_true(_ask_first(sim).begins_with(reaction), "and said again next time")
