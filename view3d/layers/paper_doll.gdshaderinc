// **The player, stacked** (group A, `docs/CREATION_AND_GEAR.md` §3).
//
// Every layer is a sheet in the same layout, so one UV reads them all. They are stacked in
// `PaperDoll.ORDER`; each may be recoloured exactly as the looks' recipes recolour — his
// value kept and scaled, a new hue, a saturation scaled and floored, and the floor his own
// shader needs for a bright colour to survive — and a head gear may hide the hair and the
// beard under it with a mask. His art's alpha is all or nothing, so a layer either covers
// what is under it or does not.
//
// The same function draws the player in the world, his ghost, and the creation and
// inventory screens: the preview is the game's own drawing.

// One sampler and one recolouring per slot of `PaperDoll.ORDER`, written out rather than
// in arrays: an array of samplers indexed in a loop is not allowed everywhere Godot runs.
// A recolouring is x = hue in turns, y = saturation scale, z = saturation floor, w = value
// scale; w = 0 means the slot shows his own pixels.
uniform sampler2D doll_l0 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r0 = vec4(0.0);
uniform sampler2D doll_l1 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r1 = vec4(0.0);
uniform sampler2D doll_l2 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r2 = vec4(0.0);
uniform sampler2D doll_l3 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r3 = vec4(0.0);
uniform sampler2D doll_l4 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r4 = vec4(0.0);
uniform sampler2D doll_l5 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r5 = vec4(0.0);
uniform sampler2D doll_l6 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r6 = vec4(0.0);
uniform sampler2D doll_l7 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r7 = vec4(0.0);
uniform sampler2D doll_l8 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r8 = vec4(0.0);
uniform sampler2D doll_l9 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r9 = vec4(0.0);
uniform sampler2D doll_l10 : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform vec4 doll_r10 = vec4(0.0);
// Where the head gear lets no hair show: its alpha.
uniform sampler2D doll_head_mask : hint_default_transparent, filter_nearest, repeat_disable;
uniform float doll_has_mask = 0.0;

vec3 doll_hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 doll_rgb(vec3 c) {
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

// `draw_cast_looks.gd`'s `_moved` and `safe`, on the GPU.
vec3 doll_moved(vec3 c, vec4 r) {
	vec3 hsv = doll_hsv(c);
	float s = min(max(hsv.y * r.y, r.z), 1.0);
	float v = min(hsv.z * r.w, 1.0);
	if (v > 0.35 && s < 0.24) {
		s = 0.24;
	}
	return doll_rgb(vec3(r.x, s, v));
}

// **The recolouring is done on the colours as they are painted** (A7). A 3D shader reads
// a `source_color` texture already converted to linear light, and the recipes' numbers —
// hue, saturation, value — are numbers about the painted colours, the ones the tool and
// the 2D screens work in. Moved in linear light, a brown skin came out yellow in the world
// while the creation screen showed it brown. So the world's two shaders define
// `DOLL_LINEAR`, and a recoloured pixel goes back to sRGB, is moved, and comes back.
vec3 doll_srgb(vec3 c) {
	vec3 lo = c * 12.92;
	vec3 hi = 1.055 * pow(max(c, vec3(0.0)), vec3(1.0 / 2.4)) - 0.055;
	return mix(lo, hi, step(vec3(0.0031308), c));
}

vec3 doll_linear(vec3 c) {
	vec3 lo = c / 12.92;
	vec3 hi = pow((max(c, vec3(0.0)) + 0.055) / 1.055, vec3(2.4));
	return mix(lo, hi, step(vec3(0.04045), c));
}

// One slot laid over what is under it. `hidden` is the head gear's mask, for the hair
// and the beard.
vec4 doll_over(vec4 under, sampler2D layer, vec4 r, vec2 uv, bool hidden) {
	vec4 c = texture(layer, uv);
	if (c.a < 0.5 || hidden) {
		return under;
	}
	vec3 rgb = c.rgb;
	if (r.w > 0.0) {
#ifdef DOLL_LINEAR
		rgb = doll_linear(doll_moved(doll_srgb(c.rgb), r));
#else
		rgb = doll_moved(c.rgb, r);
#endif
	}
	return vec4(rgb, 1.0);
}

vec4 doll(vec2 uv) {
	bool masked = doll_has_mask > 0.5 && texture(doll_head_mask, uv).a > 0.5;
	vec4 c = vec4(0.0);
	c = doll_over(c, doll_l0, doll_r0, uv, false);
	c = doll_over(c, doll_l1, doll_r1, uv, false);
	c = doll_over(c, doll_l2, doll_r2, uv, false);
	c = doll_over(c, doll_l3, doll_r3, uv, false);
	c = doll_over(c, doll_l4, doll_r4, uv, false);
	c = doll_over(c, doll_l5, doll_r5, uv, false);
	c = doll_over(c, doll_l6, doll_r6, uv, masked);
	c = doll_over(c, doll_l7, doll_r7, uv, masked);
	c = doll_over(c, doll_l8, doll_r8, uv, false);
	c = doll_over(c, doll_l9, doll_r9, uv, false);
	c = doll_over(c, doll_l10, doll_r10, uv, false);
	return c;
}

// His own shader's rule for what is background, kept so the doll and his figure agree.
bool doll_background(vec4 c) {
	float high = max(c.r, max(c.g, c.b));
	float low = min(c.r, min(c.g, c.b));
	return c.a < 0.5 || (high > 0.35 && (high - low) / max(high, 0.001) < 0.22);
}
