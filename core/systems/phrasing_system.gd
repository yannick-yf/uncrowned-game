class_name PhrasingSystem
extends SimSystem

## Where a generated line enters the world, if one ever does.
##
## **The model is not here and never will be.** A model is not deterministic, and
## `core/` has to replay exactly, so nothing inside the simulation may ask one
## anything. Instead the window asks, and then **submits the words it was given as
## an ordinary external event**. That is the one shape that keeps everything true:
##
## - it is logged, so a save contains the words and a reload says the same thing
## - it is replayed rather than recomputed, so the model is never called twice
## - it can be removed entirely and the game still works, because every line has an
##   authored version behind it
##
## The line is checked here rather than where it was produced. Whoever generated it
## may be careless or absent; the rule that a line may only mention people who exist
## has to hold at the door, not on trust.

func on_event(sim: Sim, event: SimEvent) -> void:
	if event.type != &"phrased":
		return
	var world := sim.store(&"world") as WorldState
	var book := sim.store(&"phrasebook") as Phrasebook
	var cast := sim.store(&"cast") as Cast
	if world == null or book == null:
		return

	var key: String = String(event.data.get("key", ""))
	var line: String = String(event.data.get("line", ""))
	if key.is_empty() or line.is_empty():
		return

	# The door. A line that breaks the house rules, invents a person, drops a figure
	# it was given or invents one it was not, is dropped and the authored line stands.
	var must: PackedStringArray = _must_be_true(world, cast)
	var faults: PackedStringArray = ProseRules.faults(
		line, ProseRules.known_names(cast), must)
	if not faults.is_empty():
		sim.derive(&"phrase_refused", {"key": key, "why": ", ".join(faults)})
		return

	book.remember(key, line)
	# Only speak it if this is still the conversation it was written for. A line
	# arriving late is remembered for next time and not put in anybody's mouth now.
	if world.in_dialogue() and String(event.data.get("for", "")) == String(world.talking_to):
		world.current_line = line


## What this line was supposed to contain. Read here rather than trusted from the
## event: whoever generated the line also chose what to tell the model it must say,
## and a door that takes the brief from the same place as the answer is not a door.
func _must_be_true(world: WorldState, cast: Cast) -> PackedStringArray:
	if world.talking_to == &"" or world.last_intent == &"":
		return PackedStringArray()
	var npc: Npc = cast.get_npc(world.talking_to)
	if npc == null:
		return PackedStringArray()
	return Answers.shared().must_be_true(npc.id, world.last_intent)


func system_name() -> StringName:
	return &"phrasing"
