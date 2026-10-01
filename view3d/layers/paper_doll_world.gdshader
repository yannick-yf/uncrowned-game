shader_type spatial;
render_mode unshaded, cull_disabled;
// The player in the world (group A): his brother's billboard trick and his rule for what
// is background, drawn from the stacked layers — and the fight's flash and tint, which
// `view/world3d.gd` used to swap in a second material for.
#include "res://view3d/layers/paper_doll.gdshaderinc"

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec3 flash_colour : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);

void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * scale.x, INV_VIEW_MATRIX[1] * scale.y, INV_VIEW_MATRIX[2] * scale.z, MODEL_MATRIX[3]);
}

void fragment() {
	vec4 c = doll(UV);
	if (doll_background(c)) { discard; }
	ALBEDO = mix(c.rgb * tint, flash_colour, flash);
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
