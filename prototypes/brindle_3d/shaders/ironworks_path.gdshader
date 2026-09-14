shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform sampler2D ground_noise : filter_linear_mipmap, repeat_enable;
varying vec3 world;
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; }
void fragment() {
    float broad=texture(ground_noise,world.xz*.034).r;
    float grain=texture(ground_noise,world.xz*.65).r;
    ALBEDO=mix(vec3(.070,.057,.042),vec3(.14,.112,.082),broad)*(.90+grain*.18);
    ALPHA=smoothstep(.0,.72,COLOR.a-(grain-.5)*.36)*.86;
    ROUGHNESS=.98;
}
