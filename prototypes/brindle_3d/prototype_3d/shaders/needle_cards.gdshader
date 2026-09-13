shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, alpha_to_coverage;
uniform sampler2D needle_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float wind_strength : hint_range(0.0,0.1) = 0.035;
void vertex() {
	vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	VERTEX.x += sin(TIME*1.4+world.x*0.7+world.z*0.6) * wind_strength * (1.0-UV.y);
}
void fragment() {
	vec4 tex=texture(needle_texture,UV);
	ALBEDO=tex.rgb*COLOR.rgb;
	ALPHA=tex.a;
	ALPHA_SCISSOR_THRESHOLD=0.40;
	ALPHA_ANTIALIASING_EDGE=0.30;
	ALPHA_TEXTURE_COORDINATE=UV*vec2(textureSize(needle_texture,0));
	ROUGHNESS=0.92;
	SPECULAR=0.15;
}
