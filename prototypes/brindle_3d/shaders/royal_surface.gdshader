shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(.6,.55,.45,1.);
uniform int surface_kind = 1;
varying vec3 p;
varying vec3 n;
float hash(vec2 q){return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 q){vec2 i=floor(q),f=fract(q);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){p=VERTEX;n=NORMAL;}
void fragment(){
 vec2 uv=abs(n.x)>.6?p.zy:(abs(n.y)>.65?p.xz:p.xy);
 float grain=noise(uv*22.);
 vec3 col=tint.rgb*COLOR.rgb*(.93+.13*grain);
 if(surface_kind==1){
   float row=floor(uv.y/.46);vec2 grid=vec2(uv.x/.94+mod(row,2.)*.5,uv.y/.46);
   vec2 edge=min(fract(grid),1.-fract(grid));float joint=smoothstep(.006,.033,min(edge.x,edge.y));
   col*=mix(.65,.90+.18*hash(floor(grid)),joint);
 }else if(surface_kind==2){
   vec2 tile=vec2(uv.x/.34+mod(floor(uv.y/.30),2.)*.5,uv.y/.30);
   vec2 edge=min(fract(tile),1.-fract(tile));col*=mix(.64,.88+.19*hash(floor(tile)),smoothstep(.008,.06,min(edge.x,edge.y)));
 }else if(surface_kind==0){col*=.82+.27*noise(uv*vec2(28.,1.2));}
 ALBEDO=col;ROUGHNESS=surface_kind==3?.61:.95;
}
