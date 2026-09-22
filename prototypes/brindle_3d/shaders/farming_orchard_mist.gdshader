shader_type fog;

uniform float density : hint_range(0.0, 0.1) = 0.0055;
uniform float amount : hint_range(0.0, 1.0) = 1.0;

void fog() {
	// Soft edges and a clear floor preserve the paths underneath the canopy.
	vec3 box = abs(UVW * 2.0 - 1.0);
	float border = 1.0 - smoothstep(0.48, 1.0, max(box.x, box.z));
	float height = smoothstep(0.015, 0.2, UVW.y) * (1.0 - smoothstep(0.60, 1.0, UVW.y));
	float drift = 0.88 + 0.12 * sin(WORLD_POSITION.x * 0.24 + WORLD_POSITION.z * 0.19 + TIME * 0.035);
	DENSITY = density * amount * border * height * drift;
	ALBEDO = vec3(0.95, 0.97, 1.0);
}
