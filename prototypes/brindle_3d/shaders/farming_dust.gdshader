shader_type spatial;
render_mode cull_disabled, depth_draw_never;

uniform float ground_level = 0.0;
varying float ground_fade;

void vertex() {
	vec3 particle_scale=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*particle_scale.x,INV_VIEW_MATRIX[1]*particle_scale.y,INV_VIEW_MATRIX[2]*particle_scale.z,MODEL_MATRIX[3]);
	float phase=float(INSTANCE_ID)*2.39996;
	VERTEX.xy += vec2(sin(TIME*.43+phase),cos(TIME*.37+phase))*.10;
	ground_fade=smoothstep(.06,.42,MODEL_MATRIX[3].y-ground_level);
}

void fragment() {
	float radius=length(UV*2.0-1.0);
	float softness=1.0-smoothstep(.08,.95,radius);
	ALBEDO=COLOR.rgb;
	ROUGHNESS=1.0;
	SPECULAR=0.0;
	EMISSION=COLOR.rgb*.025;
	ALPHA=softness*softness*COLOR.a*ground_fade*.18;
}
