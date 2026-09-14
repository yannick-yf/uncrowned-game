shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform sampler2D ground_noise : filter_linear_mipmap, repeat_enable;
uniform sampler2D ironworks_ground_mask : filter_linear, repeat_disable;
varying vec3 world;
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz; }
void fragment() {
    float broad=texture(ground_noise,world.xz*.024).r;
    float grain=texture(ground_noise,world.xz*.5).r;
    ALBEDO=mix(vec3(.26,.21,.13),vec3(.41,.34,.22),broad)*(.92+grain*.15);
    vec2 town_uv=(world.xz-vec2(182.,-13.))/vec2(104.,108.);
    float inside=step(0.,town_uv.x)*step(0.,town_uv.y)*step(town_uv.x,1.)*step(town_uv.y,1.);
    float town=texture(ironworks_ground_mask,clamp(town_uv,vec2(0.),vec2(1.))).r*inside;
    ALBEDO=mix(ALBEDO,mix(vec3(.070,.057,.042),vec3(.14,.112,.082),broad)*(.90+grain*.18),town);
    ALPHA=smoothstep(.0,.65,COLOR.a-(grain-.5)*.32)*.95;
    ROUGHNESS=.98;
}
