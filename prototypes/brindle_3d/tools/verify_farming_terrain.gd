extends SceneTree
## Independent, read-only checks for the local farming earthworks and water query.
## Run headlessly; no complete world, facade generation or asset rebuild is needed.
const TERRAIN_HELPER = preload("res://scripts/farming_terrain.gd")
const ENVELOPE := Rect2(-300.0,-80.0,280.0,260.0)
const SOURCE_FILES: Array[String] = ["height","water_level","terrain_paint","water_flow"]
var checks: int = 0
var failures: int = 0
var grid_size: int = 0
var extent: float = 768.0
var started_ms: int = 0
var mill_in := Vector3.INF
var mill_out := Vector3.INF
var wheel_axis := Vector3.INF

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL ",label)

func finish() -> void:
	print("FARMING_TERRAIN_CHECK ","PASS" if failures == 0 else "FAIL"," checks=",checks," failures=",failures," elapsed_ms=",Time.get_ticks_msec()-started_ms)
	quit(0 if failures == 0 else 1)

func run() -> void:
	started_ms = Time.get_ticks_msec()
	var plan_path: String = "res://planning/farming-town.json"
	var meta_path: String = "res://assets/landscape/landscape.json"
	check(FileAccess.file_exists(plan_path),"Farming plan exists")
	check(FileAccess.file_exists(meta_path),"Base terrain metadata exists")
	if failures > 0:
		finish();return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	check(parsed is Dictionary and parsed.has("terrain"),"Farming terrain plan is valid JSON")
	check(meta is Dictionary and int(meta.get("grid_size",0))>1,"Base grid metadata is valid")
	if failures > 0:
		finish();return
	var layout: Dictionary = parsed
	grid_size = int(meta.grid_size)
	extent = float(meta.extent_m)
	var original: Array[PackedFloat32Array] = []
	var hashes: Array[String] = []
	for name: String in SOURCE_FILES:
		var path: String = "res://assets/landscape/"+name+".f32"
		check(FileAccess.file_exists(path),"Base data exists: "+name)
		if not FileAccess.file_exists(path):
			finish();return
		var data: PackedFloat32Array = FileAccess.get_file_as_bytes(path).to_float32_array()
		var channels: int = 3 if name in ["terrain_paint","water_flow"] else 1
		check(data.size()==grid_size*grid_size*channels,"Expected grid shape: "+name)
		original.append(data)
		hashes.append(FileAccess.get_sha256(path))
	if failures > 0:
		finish();return
	var plan_before: String = JSON.stringify(layout)
	var first: Array[PackedFloat32Array] = copies(original)
	var second: Array[PackedFloat32Array] = copies(original)
	TERRAIN_HELPER.apply(first[0],first[1],first[2],first[3],grid_size,layout)
	TERRAIN_HELPER.apply(second[0],second[1],second[2],second[3],grid_size,layout)
	for channel: int in 4:
		var finite: bool = true
		for value: float in first[channel]:
			if not is_finite(value):
				finite=false;break
		check(finite,"Finite generated values: "+SOURCE_FILES[channel])
		check(first[channel]==second[channel],"Deterministic generated values: "+SOURCE_FILES[channel])
	_check_scope_and_existing_water(original,first)
	var cached: Dictionary = TERRAIN_HELPER.prepare_query(layout)
	check(JSON.stringify(layout)==plan_before,"Applying and preparing queries leaves the authored plan unchanged")
	_read_mill_markers(layout)
	_check_flow_continuity(layout,first[0],first[1])
	_check_mill_water(cached)
	_check_query_cache(cached)
	for i: int in SOURCE_FILES.size():
		check(hashes[i]==FileAccess.get_sha256("res://assets/landscape/"+SOURCE_FILES[i]+".f32"),"Base file remains unchanged: "+SOURCE_FILES[i])
	finish()

func copies(source: Array[PackedFloat32Array]) -> Array[PackedFloat32Array]:
	var result: Array[PackedFloat32Array] = []
	for values: PackedFloat32Array in source:
		result.append(values.duplicate())
	return result

func _check_scope_and_existing_water(before: Array[PackedFloat32Array], after: Array[PackedFloat32Array]) -> void:
	var changed: int = 0
	var outside: int = 0
	var protected_changes: int = 0
	var step: float = extent/float(grid_size-1)
	for z: int in grid_size:
		for x: int in grid_size:
			var i: int = z*grid_size+x
			var different: bool = before[0][i]!=after[0][i] or before[1][i]!=after[1][i]
			for channel: int in [2,3]:
				for component: int in 3:
					different = different or before[channel][i*3+component]!=after[channel][i*3+component]
			if not different:
				continue
			changed += 1
			if not ENVELOPE.has_point(Vector2(x*step-extent*.5,z*step-extent*.5)):
				outside += 1
			if before[1][i]>-9000.0 and before[1][i]>before[0][i]+.02:
				protected_changes += 1
	check(changed>0,"Farming terrain actually changes the local data")
	check(outside==0,"No data changes outside the farming envelope: "+str(outside))
	check(protected_changes==0,"Existing wet cells retain their bed, level, paint and flow: "+str(protected_changes))
	print("FARMING_TERRAIN_SCOPE changed_cells=",changed," outside=",outside," existing_water_changes=",protected_changes)

func _read_mill_markers(layout: Dictionary) -> void:
	var mill: Dictionary = {}
	for item: Dictionary in layout.get("buildings",[]):
		if str(item.id)=="MoulinDesPres":
			mill=item;break
	check(not mill.is_empty() and mill.has("scene"),"Mill prefab placement is available for hydraulic checks")
	if mill.is_empty() or not mill.has("scene"):
		return
	var packed: PackedScene = load(str(mill.scene))
	check(packed!=null,"Mill prefab loads without the full world")
	if packed==null:
		return
	var instance: Node3D = packed.instantiate()
	var transform := Transform3D(Basis(Vector3.UP,deg_to_rad(float(mill.get("yaw",0.0)))),Vector3(mill.xz[0],mill.altitude,mill.xz[1]))
	var present: bool = instance.has_node("WaterIn") and instance.has_node("WaterOut") and instance.has_node("WheelAxis")
	check(present,"Mill contains actual inlet, outlet and wheel markers")
	if present:
		mill_in=transform*(instance.get_node("WaterIn") as Node3D).position
		mill_out=transform*(instance.get_node("WaterOut") as Node3D).position
		wheel_axis=transform*(instance.get_node("WheelAxis") as Node3D).position
	instance.free()

func _within_prefab_trough(point: Vector3) -> bool:
	if not mill_in.is_finite() or not mill_out.is_finite():
		return false
	var start := Vector2(mill_in.x,mill_in.z)
	var finish := Vector2(mill_out.x,mill_out.z)
	var delta: Vector2 = finish-start
	if delta.length_squared()<.01:
		return false
	var at := Vector2(point.x,point.z)
	var fraction: float = (at-start).dot(delta)/delta.length_squared()
	return fraction>=-.0001 and fraction<=1.0001 and at.distance_to(start+delta*fraction)<.08

func _check_flow_continuity(layout: Dictionary, height: PackedFloat32Array, water: PackedFloat32Array) -> void:
	var courses: Array = layout.terrain.get("watercourses",[])
	check(courses.size()>=3,"Main stream, mill bypass and irrigation channel are present")
	for course: Dictionary in courses:
		var samples: PackedVector3Array = TERRAIN_HELPER.course_samples(course)
		check(samples.size()>2,"Sampled hydraulic profile: "+str(course.id))
		var rises: int = 0
		var dry_points: Array[Vector2] = []
		var examined: int = 0
		for i: int in samples.size():
			var point: Vector3 = samples[i]
			if i>0 and point.y>samples[i-1].y+.0001:
				rises += 1
			# Only the actual 1.68 m prefabricated trough is exempt from the 2 m
			# grid test. Its visible surface and markers are checked separately.
			if str(course.id)=="BiefDuMoulin" and _within_prefab_trough(point):
				continue
			examined += 1
			if _sample(water,point.x,point.z)-_sample(height,point.x,point.z)<.02:
				dry_points.append(Vector2(point.x,point.z))
		check(rises==0,"Water profile never rises downstream: "+str(course.id))
		check(examined>0 and dry_points.is_empty(),"Rendered grid has continuous wet channel centres: "+str(course.id)+" dry="+str(dry_points.slice(0,4)))
		print("FARMING_TERRAIN_FLOW ",course.id," checked=",examined," dry=",dry_points.size())

func _check_mill_water(cached: Dictionary) -> void:
	if not mill_in.is_finite() or not mill_out.is_finite() or not wheel_axis.is_finite():
		check(false,"Mill markers are finite");return
	for point: Vector3 in [mill_in,wheel_axis,mill_out]:
		var level: float = TERRAIN_HELPER.water_at_world(point.x,point.z,cached,-9999.0)
		check(absf(level-30.48)<.001,"Precise mill surface is 30.48 m at "+str(Vector2(point.x,point.z)))
	check(absf(mill_in.y-30.48)<.035 and absf(mill_out.y-30.48)<.035,"Visible prefab inlet and outlet match the planned water level")
	var immersion: float = TERRAIN_HELPER.water_at_world(wheel_axis.x,wheel_axis.z,cached,-9999.0)-(wheel_axis.y-2.05)
	check(immersion>.05 and immersion<.35,"Undershot wheel intersects the current by 5–35 cm")

func _check_query_cache(cached: Dictionary) -> void:
	var points: Array[Vector2] = [Vector2(mill_in.x,mill_in.z),Vector2(wheel_axis.x,wheel_axis.z),Vector2(mill_out.x,mill_out.z),Vector2(-209,34),Vector2(180,250),Vector2(-190,-230)]
	for x: int in range(-252,-79,9):
		for z: int in range(-47,155,9):
			points.append(Vector2(x,z))
	var discrepancies: Array[Vector2] = []
	for point: Vector2 in points:
		if not point.is_finite():
			continue
		var quick: float = TERRAIN_HELPER.water_at_world(point.x,point.y,cached,17.0)
		var complete: float = _reference_query(point,cached,17.0)
		if absf(quick-complete)>.00001:
			discrepancies.append(point)
	check(discrepancies.is_empty(),"Cached queries agree with a complete segment scan: "+str(discrepancies.slice(0,4)))
	for point: Vector2 in [Vector2(180,250),Vector2(-190,-230),Vector2(260,40)]:
		check(TERRAIN_HELPER.water_at_world(point.x,point.y,cached,17.125)==17.125,"Other sectors retain their original water sample: "+str(point))
	print("FARMING_TERRAIN_QUERY compared=",points.size()," differences=",discrepancies.size())

func _reference_query(point: Vector2, cached: Dictionary, fallback: float) -> float:
	# Deliberately avoids every spatial-bin and bounding-box shortcut.
	for area: Dictionary in cached.terrain.get("dry_areas",[]):
		var offset: Vector2 = point-Vector2(area.xz[0],area.xz[1])
		var angle: float = deg_to_rad(float(area.get("yaw",0.0)))
		var local := Vector2(cos(angle)*offset.x-sin(angle)*offset.y,sin(angle)*offset.x+cos(angle)*offset.y)
		var half := Vector2(area.size[0],area.size[1])*.5
		var inside: bool = absf(local.x)<=half.x and absf(local.y)<=half.y
		if str(area.get("outline","Rectangle")).to_lower()=="ellipse":
			inside=(local/half).length_squared()<=1.0
		if inside:
			var slope: Array = area.get("slope",[0.0,0.0])
			return float(area.altitude)+local.dot(Vector2(slope[0],slope[1]))-.10
	var closest: float = INF
	var result: float = fallback
	for course: Dictionary in cached.terrain.get("watercourses",[]):
		var samples: PackedVector3Array = course.samples_xyz
		var widths: PackedFloat32Array = course.query_widths
		for i: int in samples.size()-1:
			var start := Vector2(samples[i].x,samples[i].z)
			var delta := Vector2(samples[i+1].x,samples[i+1].z)-start
			if delta.length_squared()<.000001:
				continue
			var fraction: float = clampf((point-start).dot(delta)/delta.length_squared(),0.0,1.0)
			var width: float = lerpf(widths[i],widths[i+1],fraction)
			var ratio: float = point.distance_to(start+delta*fraction)/width
			if ratio<=1.0 and ratio<closest:
				closest=ratio
				result=lerpf(samples[i].y,samples[i+1].y,fraction)
	return result

func _sample(data: PackedFloat32Array, x: float, z: float) -> float:
	var step: float = extent/float(grid_size-1)
	var gx: float = clampf((x+extent*.5)/step,0.0,grid_size-1.0)
	var gz: float = clampf((z+extent*.5)/step,0.0,grid_size-1.0)
	var ix: int = mini(floori(gx),grid_size-2)
	var iz: int = mini(floori(gz),grid_size-2)
	return lerpf(lerpf(data[iz*grid_size+ix],data[iz*grid_size+ix+1],gx-ix),lerpf(data[(iz+1)*grid_size+ix],data[(iz+1)*grid_size+ix+1],gx-ix),gz-iz)
