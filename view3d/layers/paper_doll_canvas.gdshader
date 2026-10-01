shader_type canvas_item;
// The player on a screen — the creation's preview, the inventory's (group A): the game's
// own drawing, not an imitation of it.
#include "res://view3d/layers/paper_doll.gdshaderinc"

void fragment() {
	vec4 c = doll(UV);
	if (doll_background(c)) { discard; }
	COLOR = c;
}
