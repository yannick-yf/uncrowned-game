shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;

uniform float ground_level = 0.0;
varying float ground_fade;

void vertex() {
	float phase = float(INSTANCE_ID) * 2.39996;
	float sway = sin(TIME * 1.35 + phase);
	// Flutter rotates the folded blade; bounded drift gives it a light pendulum.
	float bend = sin(TIME * 2.2 + phase) * 0.34;
	mat2 turn = mat2(vec2(cos(bend),sin(bend)),vec2(-sin(bend),cos(bend)));
	VERTEX.xy = turn * VERTEX.xy;
	NORMAL.xy = turn * NORMAL.xy;
	VERTEX += vec3(sway * .16, sin(TIME * 2.5 + phase) * .035, cos(TIME * 1.1 + phase) * .11);
	float height = (MODEL_MATRIX * vec4(VERTEX,1.0)).y - ground_level;
	ground_fade = smoothstep(.06,.45,height);
}

void fragment() {
	float vein = 1.0-smoothstep(.018,.045,abs(UV.x-.5));
	ALBEDO = COLOR.rgb * mix(.96,1.09,vein);
	ROUGHNESS = .94;
	SPECULAR = .12;
	ALPHA = COLOR.a * ground_fade * .84;
}
