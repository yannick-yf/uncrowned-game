extends TestCase

## Phase 6g — the relationship web and §9's context assembler.
##
## A pure function over fixed, ordered sources. **No model anywhere**, and it is
## worth building without one: the packet is what a hand-written line is choosing
## between, it is what a dialogue cache would be keyed on, and it is the thing to
## *read* before deciding whether a model should ever see it.
##
## §9's reason for rejecting retrieval is the test below about determinism. The
## packet is hashed; vector recall drifts between runs, hardware and index builds;
## a drifting packet is a drifting hash, a cache miss, and a broken determinism
## guarantee at exactly the layer that needs one.


func _world() -> Sim:
	return Game.build()


func _packet(sim: Sim, who: StringName) -> String:
	return Context.build(who, sim.store(&"world") as WorldState,
		sim.store(&"cast") as Cast, sim.store(&"standing") as Standing,
		sim.store(&"worldtick") as WorldTick, sim.facts, Relations.shared())


# ------------------------------------------------------------------- the web ---

func test_every_edge_names_two_people_who_exist() -> void:
	# An id typed into a content file and never compared against anything is the
	# mistake that has now been made twice — once with a deed, once with a cause.
	var cast := Cast.shared()
	var web := Relations.shared()
	var edges: int = 0
	for who: StringName in web.everybody():
		assert_not_null(cast.get_npc(who), "'%s' has relations and does not exist" % who)
		for edge: Dictionary in web.of(who):
			edges += 1
			assert_not_null(cast.get_npc(edge["to"] as StringName),
				"%s %s '%s', who does not exist" % [who, edge["kind"], edge["to"]])
			assert_true(String(edge["kind"]).length() > 0, "%s's edge has no name" % who)
	assert_true(edges >= 30, "the web is worth walking: %d edges" % edges)


func test_nobody_important_stands_alone() -> void:
	# Somebody with no edges has nothing the assembler can say about them beyond
	# their own sheet, which is the thin packet problem in miniature.
	var cast := Cast.shared()
	var web := Relations.shared()
	var alone: Array[String] = []
	for npc: Npc in cast.named():
		if web.of(npc.id).is_empty():
			alone.append(String(npc.id))
	assert_true(alone.size() <= 4,
		"%d named people have no relations at all: %s" % [alone.size(), str(alone)])


func test_two_hops_reaches_further_than_one() -> void:
	var web := Relations.shared()
	assert_true(web.near(&"sena", 2).size() > web.near(&"sena", 1).size(),
		"the interesting things are two hops out — Sena works for Halgrave, who buys from Wren")


# ---------------------------------------------------------------- the packet ---

func test_the_same_world_renders_the_same_packet() -> void:
	# The whole of why §9 refused retrieval. This is the determinism guarantee a
	# dialogue cache is built on.
	var first: Sim = _world()
	var second: Sim = _world()
	for who: StringName in [&"maddox", &"sena", &"arthur", &"hesper"]:
		assert_eq(_packet(second, who), _packet(first, who), "%s renders identically" % who)
		assert_eq(Context.fingerprint(_packet(second, who)),
			Context.fingerprint(_packet(first, who)), "and hashes identically")


func test_the_packet_changes_when_the_world_does() -> void:
	# A packet that does not move is a cache that never misses and a conversation
	# that never notices anything.
	var sim: Sim = _world()
	var before: String = _packet(sim, &"maddox")

	var world := sim.store(&"world") as WorldState
	world.player_pos = Vector2(146.5, 172.0)
	sim.submit(&"steal")
	sim.advance(4)
	assert_ne(_packet(sim, &"maddox"), before, "he watched you do it and the packet says so")


func test_a_packet_names_only_things_that_exist() -> void:
	# It is assembled from ids rather than written, so this cannot fail today — it
	# is here for the day something starts generating one.
	var sim: Sim = _world()
	var cast := sim.store(&"cast") as Cast
	for npc: Npc in cast.named():
		for line: String in _packet(sim, npc.id).split("\n"):
			if not line.begins_with("KNOWS: "):
				continue
			# "<from> <kind> <to>" — the ends are people, the middle is the relation.
			var parts: PackedStringArray = line.substr(7).split(" ")
			assert_eq(parts.size(), 3, "an edge line is three words: %s" % line)
			for at: int in [0, 2]:
				assert_not_null(cast.get_npc(StringName(parts[at])),
					"%s's packet names '%s', who is nobody" % [npc.id, parts[at]])


func test_a_packet_stays_a_packet_however_long_the_run() -> void:
	# Each source has a fixed slice, because the one that grows without bound is
	# the conversation history and a packet that grows is a context window that
	# eventually does not fit.
	var sim: Sim = _world()
	var world := sim.store(&"world") as WorldState
	world.player_pos = (sim.store(&"cast") as Cast).get_npc(&"maddox").centre()
	for _round: int in 8:
		sim.submit(&"talk", {"npc": "maddox"})
		sim.advance(2)
		if world.options.is_empty():
			break
		sim.submit(&"choose_intent", {"intent": String(world.options[0].intent)})
		sim.advance(2)
		sim.submit(&"end_talk")
		sim.advance(2)
	var asked: int = 0
	for line: String in _packet(sim, &"maddox").split("\n"):
		if line.begins_with("ALREADY ASKED: "):
			asked += 1
	assert_true(asked <= Context.MAX_HISTORY, "the history is clipped: %d lines" % asked)


func test_the_packet_is_rich_enough_to_be_worth_reading() -> void:
	# The question Phase 6 was building toward. A thin packet means no model on
	# earth would write a good line from it; a rich one means the decision about
	# where a model runs is worth having.
	var sim: Sim = _world()
	for who: StringName in [&"sena", &"arthur", &"nessa", &"anselm"]:
		var lines: int = _packet(sim, who).split("\n").size()
		assert_true(lines >= 8, "%s's packet is %d lines — too thin to write from" % [who, lines])
