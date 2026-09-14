shader_type spatial;
render_mode cull_disabled;
// Local stone, rough timber and forged iron; local coordinates survive placement.
uniform vec4 tint : source_color = vec4(.3,.34,.36,1.0);
uniform int surface_kind = 1;
uniform float roughness = .92;
uniform float metalness = 0.0;
uniform float variation = .17;
varying vec3 local_pos;
varying vec3 local_normal;
float hash(vec3 p) { p=fract(p*.1031);p+=dot(p,p.yzx+33.33);return fract((p.x+p.y)*p.z); }
float noise(vec3 p) {
 vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
 mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+1.0),f.x),f.y),f.z);
}
void vertex() { local_pos=VERTEX;local_normal=NORMAL; }
void fragment() {
 vec3 p=local_pos;
 float grain=noise(p*8.0)*.65+noise(p*31.0)*.35;
 if (surface_kind==0) {
   vec3 stretch=abs(local_normal.y)>.65?vec3(1.1,16,28):vec3(26,1.0,26);
   grain=noise(p*stretch)*.8+noise(p*62.0)*.2;
 } else if (surface_kind==2) {
   grain=noise(p*vec3(3,32,8))*.7+noise(p*55.0)*.3;
 }
 ALBEDO=tint.rgb*COLOR.rgb*(1.0+(grain-.5)*variation*2.0);
 ROUGHNESS=roughness;
 METALLIC=metalness;
}
