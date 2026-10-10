shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, blend_mix;
// The player's ghost (O21), from the same layers: the shape of him through a crown or a
// wall. **Only where he is hidden, and as a silhouette** (D15, the audit's 12): it was drawn
// in his own colours at a third of himself everywhere, over himself too, so seen through
// the well's roof he looked like a bug in the roof. Now the scene's depth says which of his
// pixels something stands in front of, and only those are drawn: a cool flat fill, a gold
// edge one texel wide — a game's "you are here, behind this".
// The world reads its textures in linear light; the recolouring is done in sRGB.
#define DOLL_LINEAR
#include "res://view3d/layers/paper_doll.gdshaderinc"

uniform float ghost_alpha : hint_range(0.0, 1.0) = 0.32;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec3 fill_colour : source_color = vec3(0.30, 0.34, 0.44);
uniform vec3 edge_colour : source_color = vec3(1.0, 0.847, 0.443);
uniform vec2 texel = vec2(0.0035, 0.0035);

void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * scale.x, INV_VIEW_MATRIX[1] * scale.y, INV_VIEW_MATRIX[2] * scale.z, MODEL_MATRIX[3]);
}

void fragment() {
	vec4 c = doll(UV);
	if (doll_background(c)) { discard; }
	// Reversed depth: a larger value is nearer the lens. Something nearer than this pixel of
	// him, by more than a hand, hides it; anything else, and he is seen as himself.
	float scene = texture(depth_texture, SCREEN_UV).r;
	if (scene <= FRAGCOORD.z + 0.00002) { discard; }
	bool edge = doll_background(doll(UV + vec2(texel.x, 0.0))) || doll_background(doll(UV - vec2(texel.x, 0.0)))
		|| doll_background(doll(UV + vec2(0.0, texel.y))) || doll_background(doll(UV - vec2(0.0, texel.y)));
	ALBEDO = edge ? edge_colour : fill_colour;
	ALPHA = edge ? min(ghost_alpha * 2.8, 0.95) : ghost_alpha * 1.6;
}
