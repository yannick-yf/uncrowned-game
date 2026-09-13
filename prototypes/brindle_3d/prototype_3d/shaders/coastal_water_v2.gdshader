shader_type spatial;
render_mode cull_disabled;
uniform vec4 deep_color : source_color = vec4(0.028, 0.14, 0.225, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.085, 0.32, 0.40, 1.0);
uniform vec4 foam_color : source_color = vec4(0.80, 0.88, 0.76, 1.0);
uniform vec2 flow_a = vec2(0.035, 0.022);
uniform vec2 flow_b = vec2(-0.024, 0.031);
uniform float wave_height : hint_range(0.0, 0.1) = 0.045;
uniform float wave_speed : hint_range(0.0, 3.0) = 0.7;
uniform float pattern_scale : hint_range(0.1, 4.0) = 1.0;
uniform float shoreline_z = 15.0;
uniform vec4 shore_rocks[7];
varying vec3 world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.0),f.x),f.y);
}
void vertex() {
	world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float t=TIME*wave_speed;
	float x=world.x*0.65+t, z=world.z*0.70-t;
	VERTEX.y+=sin(x)*cos(z)*wave_height;
	NORMAL=normalize(vec3(-cos(x)*cos(z)*0.65*wave_height,1.0,sin(x)*sin(z)*0.70*wave_height));
}
void fragment() {
	float t=TIME*wave_speed;
	vec2 a=world.xz*pattern_scale+flow_a*t*8.0;
	vec2 b=world.xz*pattern_scale+flow_b*t*8.0;
	float pattern=noise(a*1.8)*0.55+noise(b*3.1)*0.45;
	float shore=shoreline_z+sin(world.x*0.33)*0.5;
	float depth=smoothstep(shore-0.4,shore+11.0,world.z);
	vec3 col=mix(shallow_color.rgb,deep_color.rgb,depth);
	col*=0.90+pattern*0.23;
	float lines=sin(a.y*12.0+noise(a*3.0)*5.0+sin(b.x*3.0));
	float sparkle=smoothstep(0.94,1.0,lines)*smoothstep(0.65,0.88,noise(b*2.4))*0.07;
	float surf_z=shore+sin(t*1.2)*0.19+noise(vec2(world.x*3.0,t))*0.13;
	float surf=(1.0-smoothstep(0.07,0.30,abs(world.z-surf_z)))*(0.35+noise(a*4.0)*0.65);
	float retreat=(1.0-smoothstep(0.025,0.09,abs(world.z-surf_z-0.5)))*noise(b*4.0)*0.28;
	float rock_foam=0.0;
	for (int i=0; i<7; i++) {
		float edge=length((world.xz-shore_rocks[i].xy)*vec2(1.0,1.1))-shore_rocks[i].z;
		rock_foam=max(rock_foam,(1.0-smoothstep(0.02,0.17,abs(edge+sin(t*1.5)*0.07)))*0.78);
	}
	ALBEDO=mix(col,foam_color.rgb,max(rock_foam,max(sparkle,max(surf,retreat))));
	ROUGHNESS=0.36;
	SPECULAR=0.5;
}
