extends TestCase

## **The demo's opening, played end to end** (O20, 2026-09-29). `tools/opening_run.gd`
## plays it through the simulation with hands on the keys — creation, the fairy, a rest
## at her fire, the path, Bram's hail, the three drills, out of his sight and back, the
## wolves before the bridge, the works' gate — and replays and reloads it at the end.
## A stage that stops names itself. The table it prints is the one to read after a
## change to any of it: walking, fighting and reading time, and the damage against 100
## and against 30 HP.

const SLOW: bool = true


func test_the_opening_plays_from_the_graves_to_the_works() -> void:
	var run := OpeningRun.new()
	var ok: bool = run.play()
	print(run.summary())
	assert_true(ok, "the opening plays through: %s" % run.stopped)
	var reached: Array[String] = []
	for stage: Dictionary in run.stages:
		reached.append(String(stage["name"]))
	for name: String in ["the fairy", "a rest at her fire", "the path and the hail", "the sword", "the bow",
			"the magic", "out of his sight and back", "the works' gate", "replay and save"]:
		assert_true(reached.has(name), "it reaches %s" % name)
	assert_eq(run.sim.events.of_type(&"hailed").size(), 1, "Bram called once in all of it")
	for owed: String in run.owed:
		debt(owed)
	if Places.baked():
		assert_true(run.owed.is_empty(), "on his map nothing is owed")
