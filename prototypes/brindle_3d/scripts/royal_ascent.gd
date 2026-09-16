@tool
extends RefCounted
## One continuous profile shared by the terrain, parapets and traversal checks.
static func curve(profile: Array) -> Curve3D:
	var result: Curve3D=Curve3D.new();result.bake_interval=.6
	for i: int in profile.size():
		var p: Array=profile[i];var a: Array=profile[maxi(0,i-1)];var b: Array=profile[mini(i+1,profile.size()-1)]
		var tangent: Vector3=Vector3(b[0]-a[0],b[2]-a[2],b[1]-a[1])/6.0
		result.add_point(Vector3(p[0],p[2],p[1]),-tangent,tangent)
	return result

static func grade(heights: PackedFloat32Array,n: int,profile: Array) -> void:
	var pts: PackedVector3Array=curve(profile).get_baked_points()
	var box: Rect2=Rect2(Vector2(pts[0].x,pts[0].z),Vector2.ZERO)
	for p: Vector3 in pts:box=box.expand(Vector2(p.x,p.z))
	box=box.grow(6.0)
	for z: int in range(maxi(0,floori((box.position.y+384)/2)),mini(n,ceili((box.end.y+384)/2))):
		for x: int in range(maxi(0,floori((box.position.x+384)/2)),mini(n,ceili((box.end.x+384)/2))):
			var p: Vector2=Vector2(x*2-384,z*2-384);var best: float=INF;var altitude: float=0
			for i: int in pts.size()-1:
				var a: Vector2=Vector2(pts[i].x,pts[i].z);var b: Vector2=Vector2(pts[i+1].x,pts[i+1].z)
				var t: float=clampf((p-a).dot(b-a)/maxf(.0001,(b-a).length_squared()),0,1)
				var distance: float=p.distance_squared_to(a.lerp(b,t))
				if distance<best:best=distance;altitude=lerpf(pts[i].y,pts[i+1].y,t)
			heights[z*n+x]=lerpf(heights[z*n+x],altitude,1-smoothstep(3.8,6.0,sqrt(best)))
