shader_type spatial;
render_mode cull_disabled;
// Metre-scaled detail supplies close-up texture without dense modeled straw or bricks.
uniform vec4 tint : source_color=vec4(.5,.4,.2,1.);
uniform int surface_kind=0;
uniform float roughness=.95;
varying vec3 p;
varying vec3 n;
float hash(vec3 a) { return fract(sin(dot(a,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 a) {
 vec3 i=floor(a),f=fract(a);f=f*f*(3.-2.*f);
 return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+1.),f.x),f.y),f.z);
}
void vertex(){p=VERTEX;n=NORMAL;}
void fragment(){
 float broad=noise(p*2.1),fine=noise(p*25.);
 vec3 base=tint.rgb*COLOR.rgb*(.9+.15*broad+.06*fine);
 float relief=0.;
 if(surface_kind==0){
  float grain=noise(p*vec3(24.,1.4,24.));base*=.88+.22*grain;
 } else if(surface_kind==1){
  vec2 uv=abs(n.x)>abs(n.z)?p.zy:p.xy;
  float row=floor(uv.y/.29);vec2 cell=fract(vec2(uv.x/.55+mod(row,2.)*.5,uv.y/.29));
  vec2 fw=fwidth(cell)*1.4;
  float joints=(1.-smoothstep(.025,.025+fw.x,cell.x))+(1.-smoothstep(.045,.045+fw.y,cell.y));
  base*=1.-clamp(joints,0.,1.)*.18;relief=clamp(joints,0.,1.);
 } else if(surface_kind==2){
  float strands=noise(p*vec3(3.,8.,54.));
  float courses=sin(p.y*27.+noise(p*2.)*.6)*.5+.5;
  base*=.86+.2*strands+.09*courses;relief=strands;
 } else if(surface_kind==5){
  float furrow=sin(p.x*8.3+noise(p*.3)*.35)*.5+.5;
  base*=.76+.30*furrow+.13*noise(p*8.);relief=furrow;
 } else if(surface_kind==6){
  base*=.86+.23*smoothstep(.05,4.5,p.y)+.08*broad;
 } else if(surface_kind==9){
  base*=.92+.08*sin(p.x*120.)*sin(p.y*120.);
 }
 ALBEDO=base;
 ROUGHNESS=roughness;
 if(surface_kind==1 || surface_kind==2 || surface_kind==5){
  NORMAL=normalize(NORMAL+vec3(dFdx(relief),dFdy(relief),0.)*.05);
 }
}
