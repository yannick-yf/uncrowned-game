class_name TestCase
extends RefCounted

## Base class for every file in test/.
##
## One instance per test method: the runner constructs a fresh case, calls
## before_each(), the test_* method, then after_each(). Assertions record failures
## rather than halting, so one broken expectation does not hide the next.

var _failures: PackedStringArray = PackedStringArray()
var _assertions: int = 0


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func failures() -> PackedStringArray:
	return _failures


func failure_count() -> int:
	return _failures.size()


func assertion_count() -> int:
	return _assertions


func fail(message: String) -> void:
	_failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	_assertions += 1
	if not condition:
		fail("expected true%s" % _suffix(message))


func assert_false(condition: bool, message: String = "") -> void:
	_assertions += 1
	if condition:
		fail("expected false%s" % _suffix(message))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	_assertions += 1
	if actual != expected:
		fail("expected %s, got %s%s" % [_show(expected), _show(actual), _suffix(message)])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	_assertions += 1
	if actual == unexpected:
		fail("expected anything but %s%s" % [_show(unexpected), _suffix(message)])


func assert_null(value: Variant, message: String = "") -> void:
	_assertions += 1
	if value != null:
		fail("expected null, got %s%s" % [_show(value), _suffix(message)])


func assert_not_null(value: Variant, message: String = "") -> void:
	_assertions += 1
	if value == null:
		fail("expected non-null%s" % _suffix(message))


func _show(value: Variant) -> String:
	if value is String or value is StringName:
		return "\"%s\"" % String(value)
	return str(value)


func _suffix(message: String) -> String:
	return "" if message.is_empty() else " — %s" % message
