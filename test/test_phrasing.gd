extends TestCase

## Steps 1 to 3 of the dialogue plan: the whole path built, tested, and with the
## model slot **empty**.
##
## The point of building it this way round is that the game today runs entirely on
## hand-written lines with this switched off, and turning a model on later is
## replacing one function rather than opening up the dialogue system.
##
## The shape that keeps everything true: the window asks whoever chooses words, and
## then **submits the answer as an ordinary external event**. So it is logged, it is
## in the save file, it replays instead of being asked again, and it can be deleted
## entirely without the game noticing.


func _world() -> Sim:
	var sim: Sim = Game.build()
	Text.set_locale("en")
	return sim


func _talk_to(sim: Sim, who: StringName) -> void:
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(who).centre()
	sim.submit(&"talk", {"npc": String(who)})
	sim.advance(2)


func _packet_key(sim: Sim, who: StringName, intent: StringName) -> String:
	var world := sim.store(&"world") as WorldState
	var cast := sim.store(&"cast") as Cast
	var option: DialogueOption = DialogueRules.find(cast.get_npc(who), intent)
	var packet: String = Context.build(who, world, cast,
		sim.store(&"standing") as Standing, sim.store(&"worldtick") as WorldTick,
		sim.facts, Relations.shared(), option)
	return Phrasebook.key_for(packet, intent)


# ------------------------------------------------------------------ step 1 ---

func test_the_packet_says_how_the_person_talks() -> void:
	# Without this a packet says "a foreman", which is not enough to put words in
	# anybody's mouth.
	var sim: Sim = _world()
	var cast := sim.store(&"cast") as Cast
	var voices := Voices.shared()
	for npc: Npc in cast.named():
		assert_true(voices.of(npc).length() > 0, "%s has no voice note" % npc.id)
	assert_true(Context.build(&"halgrave", sim.store(&"world") as WorldState, cast,
		sim.store(&"standing") as Standing, sim.store(&"worldtick") as WorldTick,
		sim.facts, Relations.shared()).contains("VOICE:"), "and the packet carries it")


func _packet(sim: Sim, who: StringName, intent: StringName) -> String:
	var cast := sim.store(&"cast") as Cast
	return Context.build(who, sim.store(&"world") as WorldState, cast,
		sim.store(&"standing") as Standing, sim.store(&"worldtick") as WorldTick,
		sim.facts, Relations.shared(), DialogueRules.find(cast.get_npc(who), intent))


func test_the_packet_asks_for_facts_and_not_for_the_finished_sentence() -> void:
	# The change that decides whether any of this is worth having. A packet ending in
	# the whole written reply is a brief to *rephrase*, and rephrasing a sentence that
	# is already written buys nothing. Facts are the brief that pays: one fact set
	# serves every world the question can be asked in, and the written reply serves
	# one. See `content/answers.json`.
	var sim: Sim = _world()
	var packet: String = _packet(sim, &"halgrave", &"ask_cost")
	assert_true(packet.contains("ASKED:"), "the question is in the brief")
	assert_true(packet.contains("MUST BE TRUE: the works has killed 381 men in 11 years"),
		"and the facts the answer has to contain")
	assert_false(packet.contains("MUST SAY:"), "and never the finished sentence")


func test_an_answer_with_no_facts_declared_is_not_written_at_all() -> void:
	# The gate that makes this safe to turn on one line at a time. No facts, no
	# generation, and the hand-written reply is what the player hears — so every
	# option nobody has briefed is exactly as it was.
	var sim: Sim = _world()
	var answers := Answers.shared()
	assert_true(answers.may_be_written(&"halgrave", &"ask_cost"), "this one is briefed")
	assert_false(answers.may_be_written(&"tovin", &"ask_muster"), "this one is not")
	assert_true(_packet(sim, &"tovin", &"ask_muster").contains("MUST SAY:"),
		"so the packet shows the written line and nothing may replace it")


func test_every_brief_belongs_to_a_question_that_exists() -> void:
	# A brief keyed to a renamed intent is a silent no-op: the option never generates
	# and nothing says so. Same failure the `causes:` keys had.
	var sim: Sim = _world()
	var cast := sim.store(&"cast") as Cast
	for key: StringName in Answers.shared().everything():
		var parts: PackedStringArray = String(key).split(".", false)
		assert_eq(parts.size(), 2, "%s is not npc.intent" % key)
		var npc: Npc = cast.get_npc(StringName(parts[0]))
		assert_true(npc != null, "%s names somebody who exists" % key)
		if npc != null:
			assert_true(DialogueRules.find(npc, StringName(parts[1])) != null,
				"%s names a question they can be asked" % key)


# ------------------------------------------------------------------ step 3 ---

func test_the_door_refuses_an_invented_person() -> void:
	# The rule the whole design rests on. Facts here are mechanical: a line naming
	# somebody who does not exist sends the player off to find nothing, and after
	# that they stop trusting anybody, which ends a game about trusting people.
	var sim: Sim = _world()
	var known: PackedStringArray = ProseRules.known_names(sim.store(&"cast") as Cast)
	assert_true(ProseRules.accepts("I send the number to the king every spring.", known),
		"a plain true line is fine")
	assert_false(ProseRules.accepts(
		"Ask Dorian at the mill, he keeps the second book.", known),
		"and an invented man is not")


func test_the_door_refuses_the_house_style_being_broken() -> void:
	var known: PackedStringArray = ProseRules.known_names(Cast.shared())
	var bad: Array[String] = [
		"He signs it, which is a thing he does — every spring, without fail.",
		("This is an extraordinarily consequential administrative responsibility "
			+ "which necessitates considerable institutional circumspection."),
		("I sign every prison sentence over four months in this region and I have "
			+ "done so for forty years without once reading one of them properly."),
	]
	for line: String in bad:
		assert_false(ProseRules.accepts(line, known), "rejected: %s" % line)


func test_a_refused_line_leaves_the_written_one_standing() -> void:
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	_talk_to(sim, &"halgrave")
	var authored: String = world.current_line

	sim.submit(&"phrased", {
		"key": "anything", "for": "halgrave",
		"line": "Ask Dorian at the mill. He has the other book."})
	sim.advance(2)
	assert_eq(world.current_line, authored, "he says what he was written to say")
	assert_false((sim.store(&"phrasebook") as Phrasebook).remembers("anything"),
		"and nothing was remembered")


# ------------------------------------------------------------------ step 2 ---

func test_nothing_chooses_words_today() -> void:
	# The default asks nothing, so the game ships with every line hand-written and
	# this whole path inert. That is what makes it safe to build now.
	var phraser := Phraser.new()
	assert_false(phraser.ready(), "no model is attached")
	assert_eq(phraser.phrase("any packet", null, "en"), "", "and it offers no words")


func test_a_given_line_is_spoken_and_remembered() -> void:
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	var book := sim.store(&"phrasebook") as Phrasebook
	_talk_to(sim, &"halgrave")

	var key: String = _packet_key(sim, &"halgrave", &"")
	sim.submit(&"phrased", {
		"key": key, "for": "halgrave",
		"line": "Careful. The slag is hot all day."})
	sim.advance(2)
	assert_eq(world.current_line, "Careful. The slag is hot all day.", "he says it")
	assert_eq(book.recall(key), "Careful. The slag is hot all day.", "and it is written down")


func test_the_same_situation_gets_the_same_words() -> void:
	# §18's proof for this phase. The key is the packet fingerprint, so identical
	# state is identical words, which is why §9 refused retrieval: a drifting packet
	# is a drifting key and a cache that never hits.
	var sim: Sim = _world()
	var first: String = _packet_key(sim, &"halgrave", &"ask_cost")
	var second: String = _packet_key(sim, &"halgrave", &"ask_cost")
	assert_eq(second, first, "same world, same key")

	var other: String = _packet_key(sim, &"halgrave", &"ask_works")
	assert_ne(other, first, "a different question is a different key")


func test_words_survive_being_saved_and_reloaded() -> void:
	# The reason the window submits rather than the system generating. The line is
	# in the log, so it is in the save file, so a reload says the same thing and no
	# model is ever asked twice for the same moment.
	SaveFile.discard()
	var sim: Sim = _world()
	_talk_to(sim, &"halgrave")
	var key: String = _packet_key(sim, &"halgrave", &"")
	sim.submit(&"phrased", {"key": key, "for": "halgrave", "line": "The slag is hot."})
	sim.advance(2)

	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"phrasebook") as Phrasebook).recall(key), "The slag is hot.",
		"rebuilt from the log alone, with no model anywhere")
	SaveFile.discard()


func test_a_late_line_is_kept_but_not_put_in_the_wrong_mouth() -> void:
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	_talk_to(sim, &"halgrave")
	sim.submit(&"end_talk")
	sim.advance(2)
	_talk_to(sim, &"sena")
	var hers: String = world.current_line

	sim.submit(&"phrased", {"key": "late", "for": "halgrave", "line": "The slag is hot."})
	sim.advance(2)
	assert_eq(world.current_line, hers, "Sena does not say Halgrave's line")
	assert_eq((sim.store(&"phrasebook") as Phrasebook).recall("late"), "The slag is hot.",
		"but it is kept for the next time he is asked")


# ------------------------------------------------- the figures, step 3 again ---

func test_the_door_refuses_a_line_that_drops_the_number() -> void:
	# The only half of "it must state the facts" that is checkable without a person
	# reading it, and it is checkable because content writes numbers as digits. An
	# answer that leaves the figure out has dodged the question.
	var known: PackedStringArray = ProseRules.known_names(Cast.shared())
	var must := PackedStringArray(["the works has killed 381 men in 11 years"])
	assert_true(ProseRules.accepts("381 men in 11 years. I send the count up every spring.",
		known, must), "the figures are there")
	assert_false(ProseRules.accepts("A great many men, over the years.", known, must),
		"and this one dodged it")


func test_the_door_refuses_a_figure_nobody_gave_it() -> void:
	# Worse than dropping one. A figure is why a player believes the rest of the line,
	# so an invented figure spends trust the game cannot earn back.
	var known: PackedStringArray = ProseRules.known_names(Cast.shared())
	var must := PackedStringArray(["the works has killed 381 men in 11 years"])
	assert_false(ProseRules.accepts("381 men in 11 years, and 9 more last week.", known, must),
		"9 came from nowhere")


func test_the_figures_survive_the_line_being_written_in_french() -> void:
	Text.set_locale("fr")
	Cast.forget()
	var known: PackedStringArray = ProseRules.known_names(Cast.shared())
	var must := PackedStringArray(["the works has killed 381 men in 11 years"])
	assert_true(ProseRules.accepts("381 hommes en 11 ans. J'envoie le compte chaque printemps.",
		known, must), "381 is 381 in either language, which is why this check works at all")
	Text.set_locale("en")
	Cast.forget()


func test_a_brief_and_the_fact_it_teaches_agree_on_their_figures() -> void:
	# The bug that cost an hour and was blamed on a model twice.
	#
	# `cinderworks:death_toll` read "près de 400 hommes" while the brief for the
	# question that teaches it said 381. Both end up in the same packet — one under
	# YOU KNOW or HOLDS, one under MUST BE TRUE — so a model reading it wrote 400 and
	# looked like it was inventing figures. It was reading ours. A description and the
	# answer that hands it over are two statements about one thing, and two statements
	# about one thing have to agree.
	var cast: Cast = Cast.shared()
	var answers := Answers.shared()
	for key: StringName in answers.everything():
		var parts: PackedStringArray = String(key).split(".", false)
		if parts.size() != 2:
			continue
		var npc: Npc = cast.get_npc(StringName(parts[0]))
		if npc == null:
			continue
		var option: DialogueOption = DialogueRules.find(npc, StringName(parts[1]))
		if option == null or option.teaches == &"":
			continue
		var described: String = String(cast.fact_descriptions.get(option.teaches, ""))
		if described.is_empty():
			continue
		var brief: PackedStringArray = ProseRules.numbers_in(
			" ".join(answers.must_be_true(npc.id, option.intent)))
		for number: String in ProseRules.numbers_in(described):
			assert_true(brief.has(number),
				"%s teaches %s, whose description says %s and whose brief never does"
					% [key, option.teaches, number])


# ----------------------------------------------------------- the opener ---

func test_an_opener_may_not_state_a_fact() -> void:
	# The whole point of splitting the job. A model that never states a fact cannot
	# state one backwards, and stating one backwards is the failure nothing catches.
	var known: PackedStringArray = ProseRules.known_names(Cast.shared())
	assert_true(ProseRules.opener_accepted("Je sais ce que vous avez pris.", known),
		"a reaction that gives nothing away is fine")
	assert_false(ProseRules.opener_accepted("381 hommes en 11 ans, et je le sais.", known),
		"an opener carrying a figure is doing the written line's job")


func test_an_opener_is_one_short_sentence() -> void:
	var known: PackedStringArray = ProseRules.known_names(Cast.shared())
	assert_false(ProseRules.opener_accepted(
		"Je sais ce que vous avez pris. Vous aurez quand meme votre reponse.", known),
		"two sentences is a speech, not an opener")
	assert_false(ProseRules.opener_accepted(
		("Je sais parfaitement ce que vous avez pris sur cet etal hier, devant tout le "
			+ "monde, et je ne l'ai pas oublie."), known), "and this is a paragraph")


func test_nothing_to_react_to_means_no_opener() -> void:
	# A character with no reason to react says the written line and nothing else,
	# which is what the game already does today.
	var known: PackedStringArray = ProseRules.known_names(Cast.shared())
	assert_true(ProseRules.opener_accepted(ProseRules.NO_OPENER, known), "silence is allowed")
	assert_eq(ProseRules.joined(ProseRules.NO_OPENER, "381 en 11 ans."), "381 en 11 ans.",
		"and joins to exactly the line that was written")


func test_the_join_is_the_written_line_with_a_reaction_in_front() -> void:
	assert_eq(ProseRules.joined("Vous, vous payez d'avance.", "C'est la seule chose que je vends."),
		"Vous, vous payez d'avance. C'est la seule chose que je vends.",
		"the facts are untouched, and a model never saw them")
