shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform sampler2D ground_noise : filter_linear_mipmap, repeat_enable;
varying vec3 world;
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; }
void fragment() {
    float broad=texture(ground_noise,world.xz*.024).r;
    float grain=texture(ground_noise,world.xz*.5).r;
    ALBEDO=mix(vec3(.26,.21,.13),vec3(.41,.34,.22),broad)*(.92+grain*.15);
    ALPHA=smoothstep(.0,.65,COLOR.a-(grain-.5)*.32)*.95;
    ROUGHNESS=.98;
}
