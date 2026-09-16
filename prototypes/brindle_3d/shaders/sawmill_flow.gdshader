shader_type spatial;
render_mode cull_disabled;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float lines=sin(world.z*18.0-TIME*4.0+sin(world.x*13.0)*.5);
 float fine=sin(world.x*41.0+world.z*6.0-TIME*2.0)*.5+.5;
 ALBEDO=mix(vec3(.045,.19,.24),vec3(.10,.31,.35),.5+lines*.16+fine*.13);
 ROUGHNESS=.28;SPECULAR=.55;
}
