##
## test_runner.gd — Custom minimal test runner (Phase 0).
## Runs tests defined in tests/unit/ and reports results to console.
##
## GUT addon is preferred for full test coverage (Phase 3+).
## To install GUT: download from https://github.com/bitwes/Gut
## and extract into addons/gut/.
##
extends Node


var _passed = 0
var _failed = 0
var _results = []


func _ready() -> void:
	_print_separator()
	print("TRPG Map Editor — Test Suite")
	_print_separator()

	_run_all_tests()

	print("")
	_print_separator()
	print("RESULTS: %d passed, %d failed, %d total" % [_passed, _failed, _passed + _failed])

	if _failed > 0:
		print("FAILURES:")
		for msg in _results:
			if msg.begins_with("FAIL"):
				print("  ", msg)

	_print_separator()

	if _failed == 0:
		_print_green("ALL TESTS PASSED")
	else:
		push_error("%d TEST(S) FAILED" % _failed)

	# Auto-quit after running (useful for CI)
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0 if _failed == 0 else 1)


# ---------- Test registration ----------

func _run_all_tests() -> void:
	var test_classes = [
		"res://tests/unit/test_map_data.gd",
		"res://tests/unit/test_grid_utils.gd",
		"res://tests/unit/test_undo_redo.gd",
		"res://tests/unit/test_floor_manager.gd",
	]
	for path in test_classes:
		var TestClass = load(path)
		if TestClass == null:
			push_error("[TestRunner] Could not load %s" % path)
			continue
		var instance = TestClass.new()
		instance.run_tests(self)


# ---------- Test API (mirrors GUT for compatibility) ----------

func assert_eq(actual, expected, message = "") -> bool:
	if actual == expected:
		_passed += 1
		return true
	_failed += 1
	var msg = "FAIL: %s — expected %s, got %s" % [_format_val(message), _format_val(expected), _format_val(actual)]
	_results.append(msg)
	push_error(msg)
	return false


func assert_true(condition, message = "") -> bool:
	return assert_eq(condition, true, message)


func assert_false(condition, message = "") -> bool:
	return assert_eq(condition, false, message)


func assert_not_null(value, message = "") -> bool:
	if value != null:
		_passed += 1
		return true
	_failed += 1
	var msg = "FAIL: %s — expected non-null" % _format_val(message)
	_results.append(msg)
	push_error(msg)
	return false


func assert_null(value, message = "") -> bool:
	return assert_eq(value, null, message)


# ---------- Helpers ----------

func _format_val(v, default = "") -> String:
	if v is String and not v.is_empty():
		return v
	if v is String:
		return default
	return str(v)


func _print_green(text) -> void:
	print("\033[32m%s\033[0m" % text)


func _print_separator() -> void:
	var out = ""
	for _i in range(60):
		out += "="
	print(out)
