// Shared by the continuous coast terrain and its detached rock pieces.
// painted must be a linear-colour, world-space triplanar sample of painted_cliff.
// All scales below are metres; there are no additional texture reads or UV seams.
float coastal_hash(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float coastal_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(coastal_hash(i), coastal_hash(i + vec3(1, 0, 0)), f.x),
			mix(coastal_hash(i + vec3(0, 1, 0)), coastal_hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(coastal_hash(i + vec3(0, 0, 1)), coastal_hash(i + vec3(1, 0, 1)), f.x),
			mix(coastal_hash(i + vec3(0, 1, 1)), coastal_hash(i + vec3(1)), f.x), f.y), f.z);
}

vec3 coastal_granite(vec3 world, vec3 world_normal, vec3 painted) {
	// The coast reads as weathered granite masses, not tiled pale limestone flakes.
	float broad = coastal_noise(world * 0.055);
	float mineral = coastal_noise(world * vec3(0.16, 0.13, 0.17));
	float weathering = smoothstep(0.18, 0.82, broad * 0.64 + mineral * 0.36);
	vec3 granite = mix(vec3(0.082, 0.093, 0.096), vec3(0.155, 0.139, 0.115), weathering);
	// The existing paint contributes restrained close-up joints only. Large-scale
	// mineral colour remains continuous across terrain and detached rock pieces.
	float footprint = max(length(dFdx(world)), length(dFdy(world)));
	float detail = 1.0 - smoothstep(0.18, 0.80, footprint);
	float luminance = dot(painted, vec3(0.2126, 0.7152, 0.0722));
	granite *= mix(1.0, clamp(luminance / 0.25, 0.32, 1.75), 0.72 * detail);
	float joints = 1.0 - smoothstep(0.075, 0.19, luminance);
	float cliff = 1.0 - abs(normalize(world_normal).y);
	granite *= 1.0 - joints * (0.12 + cliff * 0.12) * detail;
	return granite;
}

// A small derivative bump gives the reused painted fractures light response.
// View-space derivatives avoid tangent seams on steep heightfield triangles.
vec3 coastal_relief_normal(vec3 position, vec3 normal, float height) {
	vec3 dx = dFdx(position);
	vec3 dy = dFdy(position);
	vec3 r1 = cross(dy, normal);
	vec3 r2 = cross(normal, dx);
	float determinant = dot(dx, r1);
	vec3 gradient = sign(determinant) * (dFdx(height) * r1 + dFdy(height) * r2);
	return normalize(abs(determinant) * normal - gradient);
}
