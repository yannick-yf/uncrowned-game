shader_type spatial;
render_mode cull_disabled;
// Brindle's coastal palette and noise, adapted to connected inland water.
uniform vec4 deep_color : source_color = vec4(.028,.14,.225,1);
uniform vec4 shallow_color : source_color = vec4(.085,.32,.40,1);
uniform vec4 foam_color : source_color = vec4(.80,.88,.76,1);
uniform float wave_height = .025;
uniform float wave_speed = .7;
varying vec3 world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);
}
void vertex() {
    world=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
    float t=TIME*wave_speed;
    VERTEX.y+=sin(world.x*.65+t)*cos(world.z*.70-t)*wave_height;
}
void fragment() {
    float t=TIME*wave_speed;
    vec2 flow=COLOR.gb*2.-1.;
    vec2 a=world.xz-flow*t*(.35+COLOR.a*1.6);
    vec2 b=world.xz*.7+vec2(-.024,.031)*t*8.;
    float pattern=noise(a*1.8)*.55+noise(b*3.1)*.45;
    vec3 col=mix(shallow_color.rgb,deep_color.rgb,smoothstep(.02,1.,COLOR.r));
    col*=.90+pattern*.23;
    float lines=sin(a.y*8.+noise(a*3.)*5.+sin(b.x*3.));
    float sparkle=smoothstep(.94,1.,lines)*smoothstep(.65,.88,noise(b*2.4))*.09;
    // Quiet river margins have occasional broken foam, not a continuous pale rim.
    float edge=(1.-smoothstep(.0,.045,COLOR.r))*smoothstep(.55,.83,noise(a*.8))*.19;
    ALBEDO=mix(col,foam_color.rgb,max(edge,sparkle));
    ROUGHNESS=.34;
    SPECULAR=.5;
}
