extends TestCase

## The player's purse — `docs/PLAYER_MODEL.md` §6, task J1.
##
## One integer, moved only through the event log, and it cannot go below zero. That is
## the whole of the task, and these are the only three things that can go wrong with
## it: that the number starts where it should, that nothing writes it except an event,
## and that a run replayed from its log lands on the same number.
##
## **No prices, no market, no items** (§5, §6). Nothing here spends gold on anything;
## it exists so the fight has somewhere to put a dead man's gold.


func _spend(sim: Sim, amount: int, why: String) -> void:
	sim.submit(&"move_purse", {"amount": amount, "why": why})
	sim.advance(2)


func test_a_new_player_has_nothing() -> void:
	var player := Game.build().store(&"player") as PlayerState
	assert_eq(player.gold, PlayerState.EMPTY, "you woke in a clearing with no purse")


func test_nothing_writes_the_purse_except_an_event_in_the_log() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_spend(sim, 40, "a body in the road")
	assert_eq(player.gold, 40, "found on him")
	_spend(sim, -15, "the ferryman")
	assert_eq(player.gold, 25, "and paid out again")

	var replayed: Sim = Game.replay(sim)
	assert_eq((replayed.store(&"player") as PlayerState).fingerprint(), player.fingerprint(),
		"the same purse, rebuilt from the log alone")
	assert_eq((replayed.store(&"player") as PlayerState).gold, 25,
		"a run that earns and spends and then replays lands on the same number")


func test_a_purse_cannot_go_below_zero() -> void:
	var sim: Sim = Game.build()
	var player := sim.store(&"player") as PlayerState
	_spend(sim, 10, "a quest paid")
	_spend(sim, -30, "more than you have")
	assert_eq(player.gold, PlayerState.EMPTY, "empty, and no emptier")
	# And at the store, where the arithmetic is, so the rule does not depend on
	# anybody remembering to clamp at the call site.
	assert_eq(player.move_gold(-5), 0, "an empty purse gives up nothing")
	assert_eq(player.gold, PlayerState.EMPTY)


func test_what_actually_moved_is_what_the_log_says() -> void:
	# Taking more than is there takes what is there. The event has to record the real
	# amount, or a journal reading it would say you paid a price you never paid.
	var sim: Sim = Game.build()
	_spend(sim, 10, "a quest paid")
	_spend(sim, -30, "more than you have")
	var moves: Array[Dictionary] = []
	for event: SimEvent in sim.events.all():
		if event.type == &"purse_moved":
			moves.append(event.data)
	assert_eq(moves.size(), 2, "two moves, both in the log")
	assert_eq(int(moves[1]["asked"]), -30, "you asked for thirty")
	assert_eq(int(moves[1]["by"]), -10, "and ten is what left the purse")
	assert_eq(int(moves[1]["to"]), 0, "leaving it empty")


func test_a_move_that_changes_nothing_is_still_visible_in_the_log() -> void:
	# A body with nothing on it, or a purse already empty. Neither is an error; both
	# are things somebody will one day need to see in a journal.
	var sim: Sim = Game.build()
	_spend(sim, -5, "an empty purse")
	var kinds: Array[StringName] = []
	for event: SimEvent in sim.events.all():
		kinds.append(event.type)
	assert_true(kinds.has(&"purse_unmoved"), "the world said nothing happened")
	assert_false(kinds.has(&"purse_moved"), "and did not pretend otherwise")
