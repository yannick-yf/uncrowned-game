shader_type spatial;
render_mode cull_disabled;
uniform vec4 coal_color : source_color = vec4(0.28, 0.06, 0.015, 1.0);
uniform float glow_strength : hint_range(0.0, 3.0) = 1.25;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
    float grain = sin(local_position.x * 28.0 + local_position.z * 19.0);
    float pulse = 0.86 + 0.14 * sin(TIME * 1.7 + local_position.x * 3.0);
    ALBEDO = coal_color.rgb * COLOR.rgb;
    EMISSION = vec3(1.0, 0.19, 0.025) * max(0.15, grain * 0.45 + 0.4) * pulse * glow_strength;
    ROUGHNESS = 1.0;
}
