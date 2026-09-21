class_name YardRules
extends RefCounted

## **A yard composed from his pieces, not computed from two corners** (G2–G4,
## 2026-09-21). The brief describes a yard the way a person would walk it: *runs* of one
## of his modules from here to there, laid end marker to end marker as his own note
## says ("dupliquer pour prolonger"); one *gate*, his `portail_cour`, whose 2.6 m passage
## is the only way in; and single *pieces* — a sign at the gate. Everything is in his
## metres, the brief's coordinates, and this turns it into placements: piece, position,
## yaw, and what it is for. Nothing here touches a region; the bake stands the result.
##
## Two things a run does on its own. It **stops at his water**: a run that says
## `until: water` is laid module by module until the next one would stand in the river,
## and ends on the bank — the previous yard planted ten fence pieces in the river and
## Yannick read them as invisible walls. And it **drops a module where one of his own
## walls already stands**, so a run laid through his `MuretMinerai` keeps his wall as
## the wall rather than doubling it.

## Placement roles. A run's module and a single piece both stop a walker on the tiles
## their shapes cover; the gate's origin is its passage and stops nobody.
const ROLE_RUN: StringName = &"run"
const ROLE_GATE: StringName = &"gate"
const ROLE_PIECE: StringName = &"piece"

## A module's axis is tested against his obstacles a little short of its ends, so two
## walls that merely touch end to end are not read as one standing on the other.
const AXIS_INSET_M: float = 0.05


## The placements of one yard. `wet(Vector2) -> bool` says whether a point of his
## ground is under his water; `his_obstacles` are his collision polygons in world
## metres, as the build tool extracts them. The result is `{"pieces": [...],
## "report": [...]}`; a run that could not be laid as written says so in the report.
static func compose(yard: Dictionary, catalog: Dictionary, wet: Callable,
		his_obstacles: Array) -> Dictionary:
	var pieces: Array[Dictionary] = []
	var report: Array[String] = []
	var place: String = String(yard.get("place", "?"))
	for raw: Variant in (yard.get("runs", []) as Array):
		var run: Dictionary = raw as Dictionary
		var id: String = String(run.get("id", "run"))
		var asset: Dictionary = CatalogRules.entry(catalog, String(run.get("piece", "")))
		if asset.is_empty():
			report.append("YARD %s run %s: no piece '%s' in his catalogue" % [place, id, run.get("piece", "")])
			continue
		var laid: Array[Dictionary] = lay_run(run, asset, wet, his_obstacles)
		var kept: int = 0
		var dropped: int = 0
		for module: Dictionary in laid:
			if module.has("dropped"):
				dropped += 1
			else:
				kept += 1
				pieces.append(module)
		var ending: String = ""
		if not laid.is_empty() and laid[laid.size() - 1].has("stopped_at_water"):
			ending = ", stopped at his water"
		report.append("yard  %-12s run %-10s %d × %s%s%s" % [place, id, kept, String(asset["id"]),
			", %d left to his own walls" % dropped if dropped > 0 else "", ending])
	if yard.has("gate"):
		var gate: Dictionary = yard["gate"] as Dictionary
		var asset: Dictionary = CatalogRules.entry(catalog, String(gate.get("piece", "")))
		if asset.is_empty():
			report.append("YARD %s: no gate piece '%s' in his catalogue" % [place, gate.get("piece", "")])
		else:
			pieces.append(_placement(asset, _xz(gate["xz"]), float(gate.get("yaw", 0.0)), ROLE_GATE, "gate"))
	for raw: Variant in (yard.get("pieces", []) as Array):
		var single: Dictionary = raw as Dictionary
		var asset: Dictionary = CatalogRules.entry(catalog, String(single.get("piece", "")))
		if asset.is_empty():
			report.append("YARD %s: no piece '%s' in his catalogue" % [place, single.get("piece", "")])
			continue
		pieces.append(_placement(asset, _xz(single["xz"]), float(single.get("yaw", 0.0)), ROLE_PIECE,
			String(single.get("id", String(asset["id"])))))
	return {"pieces": pieces, "report": report}


## One run as modules. Each module is `from` plus a whole number of pitches, so the run
## starts exactly where the brief says — at a wall's face, a gatepost, a corner — and
## whatever does not fit is left at the `to` end. A module marked `dropped` stood where
## one of his own obstacles already stands; the last one may be marked `stopped_at_water`.
static func lay_run(run: Dictionary, asset: Dictionary, wet: Callable, his_obstacles: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var from: Vector2 = _xz(run["from_xz"])
	var to: Vector2 = _xz(run["to_xz"])
	if from == to:
		return out
	var direction: Vector2 = (to - from).normalized()
	var pitch: float = float(run.get("pitch_m", CatalogRules.MODULE_PITCH_M))
	var yaw: float = CatalogRules.yaw_along(direction)
	var until_water: bool = String(run.get("until", "")) == "water"
	var id: String = String(run.get("id", "run"))
	for centre: Vector2 in CatalogRules.modules_along(from, to, pitch):
		var far_end: Vector2 = centre + direction * pitch * 0.5
		if bool(wet.call(far_end)) or bool(wet.call(centre)):
			if not out.is_empty():
				out[out.size() - 1]["stopped_at_water"] = true
			break
		var module: Dictionary = _placement(asset, centre, yaw, ROLE_RUN, id)
		var a: Vector2 = centre - direction * (pitch * 0.5 - AXIS_INSET_M)
		var b: Vector2 = centre + direction * (pitch * 0.5 - AXIS_INSET_M)
		if CatalogRules.segment_crosses(a, b, his_obstacles):
			module["dropped"] = true
		out.append(module)
	if until_water and not out.is_empty() and not out[out.size() - 1].has("stopped_at_water"):
		# The run was asked to reach the water and ran out of `to` first: say so rather
		# than end in open ground quietly.
		out[out.size() - 1]["short_of_water"] = true
	return out


static func _placement(asset: Dictionary, xz: Vector2, yaw: float, role: StringName, id: String) -> Dictionary:
	var size: Vector3 = CatalogRules.size_m(asset)
	return {
		"piece": String(asset["id"]),
		"scene": CatalogRules.scene_of(asset),
		"xz": xz,
		"yaw": yaw,
		"role": role,
		"id": id,
		"size_m": [size.x, size.y, size.z],
		"lift": CatalogRules.lift_m(asset),
	}


static func _xz(value: Variant) -> Vector2:
	if value is Vector2:
		return value as Vector2
	var pair: Array = value as Array
	return Vector2(float(pair[0]), float(pair[1]))
