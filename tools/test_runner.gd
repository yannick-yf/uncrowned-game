extends SceneTree

## The feedback loop.
##
##   godot --headless --path . -s tools/test_runner.gd
##
## Discovers every test/*.gd that extends TestCase, runs every method named test_*
## on a fresh instance, and exits non-zero if anything failed. Takes milliseconds,
## which is the only reason it gets run after every change.

const TEST_DIR: String = "res://test"


func _initialize() -> void:
	var started_usec: int = Time.get_ticks_usec()
	var suites: int = 0
	var ran: int = 0
	var failed: int = 0
	var assertions: int = 0
	var report := PackedStringArray()

	for file_name: String in _test_files():
		var script: GDScript = load("%s/%s" % [TEST_DIR, file_name]) as GDScript
		if script == null:
			report.append("  %s could not be loaded" % file_name)
			failed += 1
			continue

		var methods: Array[String] = _test_methods(script)
		if methods.is_empty():
			continue

		var probe: Variant = script.new()
		if not (probe is TestCase):
			continue

		suites += 1
		print("%s" % file_name)
		for method: String in methods:
			var test_case: TestCase = script.new() as TestCase
			test_case.before_each()
			test_case.call(method)
			test_case.after_each()
			assertions += test_case.assertion_count()
			ran += 1
			if test_case.failure_count() == 0:
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
	print("%d suites, %d tests, %d assertions, %d failed — %.1f ms" % [
		suites, ran, assertions, failed, elapsed_ms
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
