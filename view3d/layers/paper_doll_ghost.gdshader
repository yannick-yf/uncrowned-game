shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, blend_mix;
// The player's ghost (O21), from the same layers: the shape of him through a crown or a
// wall, at a third of himself.
#include "res://view3d/layers/paper_doll.gdshaderinc"

uniform float ghost_alpha : hint_range(0.0, 1.0) = 0.32;

void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * scale.x, INV_VIEW_MATRIX[1] * scale.y, INV_VIEW_MATRIX[2] * scale.z, MODEL_MATRIX[3]);
}

void fragment() {
	vec4 c = doll(UV);
	if (doll_background(c)) { discard; }
	ALBEDO = c.rgb;
	ALPHA = c.a * ghost_alpha;
}
