extends RefCounted
## Local farming-valley earthworks, applied to in-memory terrain after native stamps.
## No files, scene nodes, random values or global resources are changed here.
const EXTENT_M: float = 768.0
const DRY_SENTINEL: float = -9000.0
const QUERY_CELL_M: float = 8.0

static func apply(height: PackedFloat32Array, water: PackedFloat32Array, paint: PackedFloat32Array, flow: PackedFloat32Array, n: int, layout: Dictionary) -> void:
	if n < 2 or height.size() != n*n or water.size() != n*n:
		return
	var terrain: Dictionary = layout.get("terrain", layout)
	var step: float = EXTENT_M / float(n-1)
	# Existing rivers, lake and sea are protected before any new terrace is graded.
	# This also recognises zero-valued dry cells and the newer -9999 sentinel.
	var existing_wet := PackedByteArray()
	existing_wet.resize(n*n)
	for i: int in n*n:
		existing_wet[i] = 1 if water[i] > DRY_SENTINEL and water[i] > height[i]+.02 else 0
	for pad: Dictionary in terrain.get("pads", []):
		_grade_pad(height, existing_wet, n, step, pad)
	for course: Dictionary in terrain.get("watercourses", []):
		_carve_course(height, water, paint, flow, existing_wet, n, step, course)
	# Only explicit new mill footprints can reclaim a new water apron. Natural
	# river cells that were already wet before this operation remain protected.
	for area: Dictionary in terrain.get("dry_areas", []):
		_grade_pad(height, existing_wet, n, step, area, water, 2)
	# Broad river-valley blends must not leave neighbouring houses unseated.
	# Foundation pads preserve all genuinely wet cells, including the new stream.
	for pad: Dictionary in terrain.get("foundation_pads", []):
		_grade_pad(height, existing_wet, n, step, pad, water, 1)
	for bridge: Dictionary in terrain.get("bridges", []):
		_grade_bridge(height, water, existing_wet, n, step, bridge)

static func course_samples(course: Dictionary) -> PackedVector3Array:
	## Input is [X,Z,water-Y]; returned samples are world-space Vector3(X,Y,Z).
	## Plan bends use restrained Bezier handles; water-Y is interpolated linearly.
	## In particular, a spline must never create an uphill hump in the water surface.
	var points: Array = course.get("points_xzy", [])
	var result := PackedVector3Array()
	if points.size() < 2:
		return result
	var previous_level: float = float(points[0][2])
	for i: int in points.size()-1:
		var before: Vector2 = _xz(points[maxi(0,i-1)])
		var start: Vector2 = _xz(points[i])
		var finish: Vector2 = _xz(points[i+1])
		var after: Vector2 = _xz(points[mini(points.size()-1,i+2)])
		var length: float = start.distance_to(finish)
		if length < .001:
			previous_level = minf(previous_level,float(points[i+1][2]))
			continue
		# A long neighbouring segment cannot pull a short bend far off its corridor.
		var out_handle: Vector2 = ((finish-before)/6.0).limit_length(length*.30)
		var in_handle: Vector2 = ((after-start)/6.0).limit_length(length*.30)
		if not bool(course.get("smooth",true)):
			out_handle=(finish-start)/3.0
			in_handle=out_handle
		var high: float = minf(previous_level,float(points[i][2]))
		var low: float = minf(high,float(points[i+1][2]))
		var subdivisions: int = maxi(3,ceili(length/1.25))
		for j: int in subdivisions:
			var t: float = float(j)/float(subdivisions)
			var s: float = 1.0-t
			var at: Vector2 = s*s*s*start + 3*s*s*t*(start+out_handle) + 3*s*t*t*(finish-in_handle) + t*t*t*finish
			result.append(Vector3(at.x,lerpf(high,low,t),at.y))
		previous_level = low
	var end: Vector2 = _xz(points.back())
	result.append(Vector3(end.x,previous_level,end.y))
	return result

static func prepare_query(layout: Dictionary) -> Dictionary:
	## Call once after reading/rebuilding a plan and keep the returned dictionary.
	## The source plan is not mutated. Cached curves, widths and eight-metre bins
	## avoid spline generation or a scan through every segment during gameplay.
	var cached: Dictionary=layout.duplicate(true)
	var terrain: Dictionary=cached.get("terrain",cached)
	var grid: Dictionary={}
	var bounds:=Rect2()
	var has_bounds: bool=false
	for course: Dictionary in terrain.get("watercourses",[]):
		var samples: PackedVector3Array=course_samples(course)
		var widths: PackedFloat32Array=_sample_widths(course,samples)
		course["samples_xyz"]=samples
		course["query_widths"]=widths
		var course_bounds:=Rect2()
		var has_course_bounds: bool=false
		for i: int in samples.size()-1:
			var a:=Vector2(samples[i].x,samples[i].z)
			var end:=Vector2(samples[i+1].x,samples[i+1].z)
			var delta: Vector2=end-a
			if delta.length_squared()<.000001:
				continue
			var segment_bounds: Rect2=Rect2(a,Vector2.ZERO).expand(end).grow(maxf(widths[i],widths[i+1])+.001)
			var segment: Dictionary={"a":a,"delta":delta,"inverse_length2":1.0/delta.length_squared(),"y0":samples[i].y,"y1":samples[i+1].y,"w0":widths[i],"w1":widths[i+1],"bounds":segment_bounds}
			var begin: Vector2i=_query_cell(segment_bounds.position)
			var finish: Vector2i=_query_cell(segment_bounds.end)
			for iz: int in range(begin.y,finish.y+1):
				for ix: int in range(begin.x,finish.x+1):
					var key:=Vector2i(ix,iz)
					if not grid.has(key):
						grid[key]=[]
					grid[key].append(segment)
			course_bounds=course_bounds.merge(segment_bounds) if has_course_bounds else segment_bounds
			has_course_bounds=true
		course["query_bounds"]=course_bounds
		if has_course_bounds:
			bounds=bounds.merge(course_bounds) if has_bounds else course_bounds
			has_bounds=true
	var dry_queries: Array[Dictionary]=[]
	for area: Dictionary in terrain.get("dry_areas",[]):
		var center: Vector2=_xz(area["xz"])
		var half: Vector2=_xz(area["size"])*.5
		if half.x<=0 or half.y<=0:
			continue
		var angle: float=deg_to_rad(float(area.get("yaw",0.0)))
		var c: float=cos(angle)
		var s: float=sin(angle)
		var reach:=Vector2(absf(c)*half.x+absf(s)*half.y,absf(s)*half.x+absf(c)*half.y)
		var area_bounds: Rect2=Rect2(center-reach,reach*2.0).grow(.001)
		dry_queries.append({"center":center,"half":half,"c":c,"s":s,"bounds":area_bounds,"ellipse":str(area.get("outline","Rectangle")).to_lower()=="ellipse","altitude":float(area["altitude"]),"slope":_xz(area.get("slope",[0.0,0.0]))})
		bounds=bounds.merge(area_bounds) if has_bounds else area_bounds
		has_bounds=true
	terrain["_water_query_grid"]=grid
	terrain["_water_query_bounds"]=bounds
	terrain["_water_query_dry"]=dry_queries
	return cached

static func _query_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x/QUERY_CELL_M),floori(point.y/QUERY_CELL_M))

static func water_at_world(x: float, z: float, layout: Dictionary, fallback: float) -> float:
	## The coarse grid cannot resolve a 1.68 m trough. Cached authored geometry
	## supplies its real surface level; unrelated sectors return immediately.
	var terrain: Dictionary=layout.get("terrain",layout)
	if not terrain.has("_water_query_bounds"):
		var prepared: Dictionary=prepare_query(layout)
		terrain=prepared.get("terrain",prepared)
	var point:=Vector2(x,z)
	var bounds: Rect2=terrain["_water_query_bounds"]
	if not bounds.has_point(point):
		return fallback
	for area: Dictionary in terrain["_water_query_dry"]:
		if not (area.bounds as Rect2).has_point(point):
			continue
		var offset: Vector2=point-area.center
		var local:=Vector2(float(area.c)*offset.x-float(area.s)*offset.y,float(area.s)*offset.x+float(area.c)*offset.y)
		var half: Vector2=area.half
		var inside: bool=absf(local.x)<=half.x and absf(local.y)<=half.y
		if bool(area.ellipse):
			inside=(local/half).length_squared()<=1.0
		if inside:
			return float(area.altitude)+local.dot(area.slope)-.10
	var best_ratio2: float=INF
	var result: float=fallback
	for segment: Dictionary in terrain["_water_query_grid"].get(_query_cell(point),[]):
		if not (segment.bounds as Rect2).has_point(point):
			continue
		var delta: Vector2=segment.delta
		var t: float=clampf((point-segment.a).dot(delta)*float(segment.inverse_length2),0.0,1.0)
		var half: float=maxf(.05,lerpf(float(segment.w0),float(segment.w1),t))
		var ratio2: float=point.distance_squared_to(segment.a+delta*t)/(half*half)
		if ratio2<=1.0 and ratio2<best_ratio2:
			best_ratio2=ratio2
			result=lerpf(float(segment.y0),float(segment.y1),t)
	return result

static func _sample_widths(course: Dictionary, samples: PackedVector3Array) -> PackedFloat32Array:
	# Optional per-control-point widths keep the prefabricated straight trough
	# narrow, while its natural approach and outfall can span the coarser grid.
	var authored: Array=course.get("half_widths",[])
	var points: Array=course.get("points_xzy",[])
	var result:=PackedFloat32Array()
	if authored.size()==points.size() and points.size()>=2:
		for i: int in points.size()-1:
			var length: float=_xz(points[i]).distance_to(_xz(points[i+1]))
			if length<.001:
				continue
			var subdivisions: int=maxi(3,ceili(length/1.25))
			for j: int in subdivisions:
				result.append(maxf(.25,lerpf(float(authored[i]),float(authored[i+1]),float(j)/subdivisions)))
		result.append(maxf(.25,float(authored.back())))
		if result.size()==samples.size():
			return result
	var widths: Variant=course.get("half_width",2.2)
	var first: float=float(widths[0]) if widths is Array else float(widths)
	var last: float=float(widths[1]) if widths is Array and widths.size()>1 else first
	var total: float=0.0
	for i: int in samples.size()-1:
		total+=Vector2(samples[i].x,samples[i].z).distance_to(Vector2(samples[i+1].x,samples[i+1].z))
	result.resize(samples.size())
	var elapsed: float=0.0
	for i: int in samples.size():
		if i>0:
			elapsed+=Vector2(samples[i-1].x,samples[i-1].z).distance_to(Vector2(samples[i].x,samples[i].z))
		result[i]=maxf(.25,lerpf(first,last,elapsed/maxf(.001,total)))
	return result

static func _xz(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

static func _cells(bounds: Rect2, n: int, step: float) -> Rect2i:
	var begin := Vector2i(maxi(0,floori((bounds.position.x+EXTENT_M*.5)/step)),maxi(0,floori((bounds.position.y+EXTENT_M*.5)/step)))
	var finish := Vector2i(mini(n-1,ceili((bounds.end.x+EXTENT_M*.5)/step)),mini(n-1,ceili((bounds.end.y+EXTENT_M*.5)/step)))
	return Rect2i(begin,Vector2i(maxi(0,finish.x-begin.x+1),maxi(0,finish.y-begin.y+1)))

static func _grade_pad(height: PackedFloat32Array, protected: PackedByteArray, n: int, step: float, pad: Dictionary, water_guard: PackedFloat32Array=PackedFloat32Array(), water_mode: int=0) -> void:
	# water_mode: 0 = initial terrace; 1 = dry foundation; 2 = explicit mill apron.
	var center: Vector2 = _xz(pad["xz"])
	var size: Vector2 = _xz(pad["size"])
	if size.x <= 0 or size.y <= 0:
		return
	var blend: float = maxf(.01,float(pad.get("blend",4.0)))
	var angle: float = deg_to_rad(float(pad.get("yaw",0.0)))
	var c: float = cos(angle)
	var s: float = sin(angle)
	var half: Vector2 = size*.5
	var ellipse: bool = str(pad.get("outline","Rectangle")).to_lower() == "ellipse"
	var enlarged: Vector2 = half*(1.0+blend/minf(half.x,half.y)) if ellipse else half+Vector2.ONE*blend
	var reach := Vector2(absf(c)*enlarged.x+absf(s)*enlarged.y,absf(s)*enlarged.x+absf(c)*enlarged.y)
	var cells: Rect2i = _cells(Rect2(center-reach,reach*2),n,step)
	var slope: Vector2 = _xz(pad.get("slope",[0.0,0.0]))
	var altitude: float = float(pad["altitude"])
	for iz: int in range(cells.position.y,cells.end.y):
		for ix: int in range(cells.position.x,cells.end.x):
			var index: int = iz*n+ix
			if protected[index] != 0:
				continue
			var offset := Vector2(ix*step-EXTENT_M*.5,iz*step-EXTENT_M*.5)-center
			var local := Vector2(c*offset.x-s*offset.y,s*offset.x+c*offset.y)
			var edge: float = maxf(absf(local.x)-half.x,absf(local.y)-half.y)
			if ellipse:
				edge=((local/half).length()-1.0)*minf(half.x,half.y)
			if edge >= blend:
				continue
			if water_mode > 0:
				var wet: bool=water_guard[index]>DRY_SENTINEL and water_guard[index]>height[index]+.02
				if wet and (water_mode == 1 or edge > 0.0):
					continue
			var target: float = altitude+local.dot(slope)
			height[index] = lerpf(height[index],target,1.0-smoothstep(0.0,blend,edge))
			if water_mode > 0:
				if water_mode == 2 and edge <= 0.0:
					# A finite, sub-floor dry value avoids poisoning bilinear samples
					# and the clipped water mesh beside a narrow prefabricated trough.
					water_guard[index]=height[index]-.10
				else:
					# An extrapolated water value under a previously dry river bank
					# must not become a new puddle when its foundation is lowered.
					water_guard[index]=minf(water_guard[index],height[index]-.05)

static func _carve_course(height: PackedFloat32Array, water: PackedFloat32Array, paint: PackedFloat32Array, flow: PackedFloat32Array, protected: PackedByteArray, n: int, step: float, course: Dictionary) -> void:
	var samples: PackedVector3Array = course_samples(course)
	if samples.size() < 2:
		return
	var widths: PackedFloat32Array=_sample_widths(course,samples)
	var widest: float=.25
	for width: float in widths:
		widest=maxf(widest,width)
	var depth: float = maxf(.05,float(course.get("depth",.8)))
	var blend: float = maxf(step*2.0,float(course.get("blend",18.0)))
	var speed: float = clampf(float(course.get("speed",.56)),.02,1.0)
	var bounds := Rect2(Vector2(samples[0].x,samples[0].z),Vector2.ZERO)
	var segments: Array[Dictionary] = []
	var total: float = 0.0
	for j: int in samples.size()-1:
		var a := Vector2(samples[j].x,samples[j].z)
		var b := Vector2(samples[j+1].x,samples[j+1].z)
		bounds=bounds.expand(b)
		var delta: Vector2=b-a
		var length: float=delta.length()
		if length < .001:
			continue
		segments.append({"a":a,"delta":delta,"length":length,"length2":length*length,"start":total,"y0":samples[j].y,"y1":samples[j+1].y,"w0":widths[j],"w1":widths[j+1]})
		total+=length
	if total < .001:
		return
	var cells: Rect2i = _cells(bounds.grow(widest+blend),n,step)
	var water_apron: float = minf(blend,maxf(2.5,step*1.5))
	var has_paint: bool = paint.size() == n*n*3
	var has_flow: bool = flow.size() == n*n*3
	for iz: int in range(cells.position.y,cells.end.y):
		for ix: int in range(cells.position.x,cells.end.x):
			var index: int=iz*n+ix
			# Preserve the existing river exactly at the confluence. New terraces,
			# channel carving and bridge approaches cannot raise its bed or water.
			if protected[index] != 0:
				continue
			var point := Vector2(ix*step-EXTENT_M*.5,iz*step-EXTENT_M*.5)
			var distance2: float=INF
			var level: float=0.0
			var half: float=widest
			var direction:=Vector2.ZERO
			for segment: Dictionary in segments:
				var delta: Vector2=segment.delta
				var t: float=clampf((point-segment.a).dot(delta)/float(segment.length2),0.0,1.0)
				var d2: float=point.distance_squared_to(segment.a+delta*t)
				if d2 < distance2:
					distance2=d2
					level=lerpf(float(segment.y0),float(segment.y1),t)
					half=lerpf(float(segment.w0),float(segment.w1),t)
					direction=delta/float(segment.length)
			var distance: float=sqrt(distance2)
			var edge: float=distance-half
			if edge >= blend:
				continue
			var previously_wet: bool=water[index]>DRY_SENTINEL and water[index]>height[index]+.02
			# Treat all new channels as one connected excavation. A later branch's
			# bank must never dam the main stream or overwrite its water apron.
			if previously_wet and edge>0.0:
				continue
			if edge <= 0.0:
				var section: float=pow(maxf(0.0,1.0-pow(distance/half,2.0)),.8)
				var bed: float=level-depth*section
				height[index]=minf(height[index],bed) if previously_wet else bed
			else:
				# A broad bank lowers the surrounding rise gradually, rather than
				# cutting a narrow tube. Near water, a low berm contains the stream
				# when the existing plain happens to be below its planned level.
				var bank: float=level+.14*edge+.003*edge*edge
				var weight: float=1.0-smoothstep(0.0,blend,edge)
				var graded: float=lerpf(height[index],minf(height[index],bank),weight)
				var containment_end: float=maxf(water_apron+.01,minf(blend,water_apron+2.0))
				var containment: float=1.0-smoothstep(water_apron,containment_end,edge)
				var dry_shelf: float=level+minf(.8,.25*edge)
				height[index]=lerpf(graded,maxf(graded,dry_shelf),containment)
			if edge <= water_apron:
				water[index]=minf(water[index],level) if previously_wet else level
				if has_flow:
					flow[index*3]=direction.x
					flow[index*3+1]=direction.y
					flow[index*3+2]=speed
			elif not previously_wet:
				# An earlier dry apron is only an interpolation aid; lowering its
				# terrain farther from the new course must not uncover false water.
				water[index]=minf(water[index],height[index]-.05)
			if has_paint:
				var bank_tint: float=(1.0-smoothstep(0.0,5.0,absf(edge)))*smoothstep(.025,.55,height[index]-level)
				paint[index*3+2]=maxf(paint[index*3+2],bank_tint)

static func _grade_bridge(height: PackedFloat32Array, water: PackedFloat32Array, protected: PackedByteArray, n: int, step: float, bridge: Dictionary) -> void:
	var center: Vector2=_xz(bridge["xz"])
	var angle: float=deg_to_rad(float(bridge.get("yaw",0.0)))
	var c: float=cos(angle)
	var s: float=sin(angle)
	var half_length: float=float(bridge["length_m"])*.5
	var half_width: float=float(bridge["width_m"])*.5
	var approach: float=maxf(2.0,float(bridge.get("approach_m",20.0)))
	var side_blend: float=maxf(1.0,float(bridge.get("side_blend_m",3.5)))
	var local_reach:=Vector2(half_width+side_blend,half_length+approach)
	var reach:=Vector2(absf(c)*local_reach.x+absf(s)*local_reach.y,absf(s)*local_reach.x+absf(c)*local_reach.y)
	var cells: Rect2i=_cells(Rect2(center-reach,reach*2),n,step)
	var deck: float=float(bridge["altitude"])
	for iz: int in range(cells.position.y,cells.end.y):
		for ix: int in range(cells.position.x,cells.end.x):
			var index: int=iz*n+ix
			if protected[index] != 0 or (water[index] > DRY_SENTINEL and water[index] > height[index]+.02):
				continue
			var offset:=Vector2(ix*step-EXTENT_M*.5,iz*step-EXTENT_M*.5)-center
			var local:=Vector2(c*offset.x-s*offset.y,s*offset.x+c*offset.y)
			var end_distance: float=absf(local.y)-half_length
			# Match the workshop bridges' buried abutments: overlap the end of
			# the saved deck, not just its mathematical endpoint. The wet channel
			# and the centre of the span remain excluded, so this cannot form a dam.
			if end_distance < -2.3 or end_distance >= approach or absf(local.x) >= half_width+side_blend:
				continue
			var weight: float=(1.0-smoothstep(half_width+.85,half_width+side_blend,absf(local.x)))*(1.0-smoothstep(3.0,approach,end_distance))*smoothstep(-2.3,-1.6,end_distance)
			height[index]=lerpf(height[index],deck,weight)
