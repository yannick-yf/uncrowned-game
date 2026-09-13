extends SceneTree

## The feedback loop.
##
##   godot --headless --path . -s tools/test_runner.gd
##
## Discovers every test/*.gd that extends TestCase, runs every method named test_*
## on a fresh instance, and exits non-zero if anything failed.
##
## **A test that records no assertions is a failure, not a pass.** GDScript
## runtime errors do not unwind: they print, abandon the function and return
## quietly, so a crashed test records no failures and looks exactly like a clean
## one. Requiring at least one assertion catches the common case — a crash before
## the first assert, which is what a renamed field produces.
##
## The residual hole, stated rather than hidden: a test that crashes *after* an
## assertion still reads as a pass. Nothing in the engine reports a script error
## back to the script that caused it. Run with tools/run_tests.sh, which fails on
## any SCRIPT ERROR in the output, when that matters — CI always should.

const TEST_DIR: String = "res://test"


func _initialize() -> void:
	# English, whatever the machine or the player's saved setting says. Content
	# tests assert on the words themselves — that Maddox blames the soldiers and
	# never the player — so a suite that reads a preference is a suite that passes
	# or fails depending on which language somebody last pressed L in. Found exactly
	# that way (2026-09-12). test_language.gd exercises both on purpose.
	Text.set_locale("en")

	var started_usec: int = Time.get_ticks_usec()
	var suites: int = 0
	var ran: int = 0
	var failed: int = 0
	var assertions: int = 0
	var report := PackedStringArray()
	var timings: Array[Array] = []
	var only_fast: bool = OS.get_cmdline_user_args().has("--fast")
	var skipped_suites: int = 0

	var owed: int = 0
	for file_name: String in _test_files():
		var script: GDScript = load("%s/%s" % [TEST_DIR, file_name]) as GDScript
		if script == null:
			report.append("  %s could not be loaded" % file_name)
			failed += 1
			continue

		var methods: Array[String] = _test_methods(script)
		if methods.is_empty():
			continue

		# A suite declaring `const SLOW := true` walks the map or reads the asset
		# pack. Skipped by --fast, which is what gets run after every change.
		if only_fast and bool(script.get_script_constant_map().get("SLOW", false)):
			skipped_suites += 1
			continue

		var probe: Variant = script.new()
		if not (probe is TestCase):
			continue

		suites += 1
		print("%s" % file_name)
		for method: String in methods:
			var test_case: TestCase = script.new() as TestCase
			var began: int = Time.get_ticks_usec()
			test_case.before_each()
			test_case.call(method)
			test_case.after_each()
			timings.append([float(Time.get_ticks_usec() - began) / 1000.0, method])
			assertions += test_case.assertion_count()
			ran += 1

			# A GDScript runtime error does not unwind — it prints, abandons the
			# function, and returns as if nothing happened. A test killed that way
			# records no failure and used to be reported as passing, which is the
			# worst possible reading. A test that asserts nothing is therefore a
			# failure: either it crashed on its way to the first assertion, or it
			# never tested anything.
			if test_case.debts().size() > 0 and test_case.failure_count() == 0:
				# Owed by the map, not broken in the code (TestCase.debt). Printed so it is
				# read, counted apart so the suite can be green while the brief is open.
				owed += test_case.debts().size()
				print("  DEBT  %s" % method)
				for message: String in test_case.debts():
					print("          owed by the map: %s" % message)
			elif test_case.assertion_count() == 0:
				failed += 1
				print("  DEAD  %s — recorded no assertions; look for a SCRIPT ERROR above" % method)
			elif test_case.failure_count() == 0:
				print("  ok    %s" % method)
			else:
				failed += 1
				print("  FAIL  %s" % method)
				for message: String in test_case.failures():
					print("          %s" % message)

	var elapsed_ms: float = float(Time.get_ticks_usec() - started_usec) / 1000.0
	print("")
	for line: String in report:
		print(line)
	timings.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	if timings.size() > 0 and float(timings[0][0]) > 200.0:
		print("slowest:")
		for i: int in mini(5, timings.size()):
			print("  %7.1f ms  %s" % [float(timings[i][0]), String(timings[i][1])])
	print("%d suites, %d tests, %d assertions, %d failed%s — %.1f ms%s" % [
		suites, ran, assertions, failed,
		", %d owed by the map" % owed if owed > 0 else "", elapsed_ms,
		"  (--fast: %d slow suites skipped)" % skipped_suites if only_fast else "",
	])
	quit(1 if failed > 0 else 0)


func _test_files() -> Array[String]:
	var out: Array[String] = []
	for file_name: String in DirAccess.get_files_at(TEST_DIR):
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			out.append(file_name)
	out.sort()
	return out


func _test_methods(script: GDScript) -> Array[String]:
	var out: Array[String] = []
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method.get("name", "") as String
		if method_name.begins_with("test_"):
			out.append(method_name)
	out.sort()
	return out
