extends SceneTree

## Standalone asset validation, for when you want the whole report rather than a
## pass or fail:
##
##   godot --headless --path . -s tools/validate_assets.gd
##   godot --headless --path . -s tools/validate_assets.gd -- --no-cache
##
## --no-cache decodes every file rather than trusting modification times. CI should
## always pass it; a person checking their own change almost never needs to.
##
## The same check runs inside the test suite (test/test_assets.gd), which is what
## actually guards the rule.

func _initialize() -> void:
	var use_cache: bool = not OS.get_cmdline_user_args().has("--no-cache")
	var started_usec: int = Time.get_ticks_usec()
	var report: AssetValidator.Report = AssetValidator.validate(40, use_cache)
	var elapsed_ms: float = float(Time.get_ticks_usec() - started_usec) / 1000.0

	print("palette      %d colours" % report.palette_size)
	print("scanned      %d images (%d contact sheets skipped, %d from cache)" % [
		report.scanned, report.previews_skipped, report.cache_hits,
	])
	print("tree         %s" % ("re-walked" if report.tree_rewalked else "unchanged since last run"))
	print("tile sources %d checked against the 16 px grid" % report.tile_sources)
	for note: String in report.exceptions_used:
		print("  exception  %s" % note)
	for line: String in report.unreadable:
		print("  UNREADABLE %s" % line)
	for line: String in report.off_grid:
		print("  OFF-GRID   %s" % line)
	for line: String in report.off_palette:
		print("  OFF-PAL    %s" % line)
	print("%s — %d problems, %.0f ms" % [
		"ok" if report.ok() else "FAILED", report.failure_count(), elapsed_ms,
	])
	quit(0 if report.ok() else 1)
