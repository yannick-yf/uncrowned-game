shader_type spatial;
render_mode unshaded, cull_disabled;
// Le fond neutre de la planche source est découpé au rendu. Le PNG original
// reste intact ; les contours sombres et la palette du personnage sont conservés.
uniform sampler2D sprite_sheet : source_color, filter_nearest, repeat_disable;

void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * scale.x, INV_VIEW_MATRIX[1] * scale.y, INV_VIEW_MATRIX[2] * scale.z, MODEL_MATRIX[3]);
}

void fragment() {
	vec4 ink = texture(sprite_sheet, UV);
	float high = max(ink.r, max(ink.g, ink.b));
	float low = min(ink.r, min(ink.g, ink.b));
	if (ink.a < 0.5 || (high > 0.35 && (high - low) / max(high, 0.001) < 0.22)) { discard; }
	ALBEDO = ink.rgb;
	ALPHA = ink.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
