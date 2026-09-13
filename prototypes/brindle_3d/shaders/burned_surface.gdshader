shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.5,0.4,0.3,1.0);
uniform int surface_kind : hint_range(0,5) = 1;
uniform float texture_strength : hint_range(0.0,1.0) = 0.25;
uniform float moss_amount : hint_range(0.0,1.0) = 0.0;
uniform float wind_strength : hint_range(0.0,0.2) = 0.0;
uniform bool vertex_srgb = false;
uniform bool use_painted_texture = false;
uniform sampler2D painted_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float painted_scale : hint_range(0.05,2.0) = 0.25;
uniform float painted_strength : hint_range(0.0,1.0) = 0.9;
uniform float facet_softness : hint_range(0.0,1.0) = 0.0;

uniform float burn_amount : hint_range(0.0,1.0) = .8;
uniform bool ground_charring = false;
uniform sampler2D scorch_mask : filter_linear, repeat_disable;
uniform vec4 scorch_bounds = vec4(102.,193.,145.,120.);
uniform vec4 charcoal : source_color = vec4(.105,.092,.078,1.);
uniform vec4 ash : source_color = vec4(.32,.315,.295,1.);

varying vec3 world;
varying vec3 world_normal;
float hash(vec3 p) { p=fract(p*0.1031); p+=dot(p,p.yzx+33.33); return fract((p.x+p.y)*p.z); }
float noise(vec3 p) {
	vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
		mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+1.0),f.x),f.y),f.z);
}
void vertex() {
	world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
	float sway = sin(TIME*1.3+world.x*0.63+world.z*0.41);
	VERTEX.x += sway * wind_strength * clamp(VERTEX.y,0.0,1.0);
	VERTEX.z += cos(TIME+world.x*0.4) * wind_strength*0.4*clamp(VERTEX.y,0.0,1.0);
}
void fragment() {
	vec3 p=world;
	float broad=noise(p*1.4);
	float fine=noise(p*23.0);
	float detail=broad*0.55+fine*0.45;
	if (surface_kind==0) {
		vec3 grain_scale=abs(world_normal.y)>0.65 ? vec3(0.65,16.0,15.0) : vec3(16.0,0.8,16.0);
		float grain=noise(p*grain_scale);
		detail=mix(grain, fine, 0.20);
	} else if (surface_kind==2) {
		detail=noise(p*vec3(9.0,3.0,18.0))*0.65+fine*0.35;
	} else if (surface_kind==4) { detail=broad*0.80+fine*0.20; }
	vec3 vertex_tint = vertex_srgb ? pow(COLOR.rgb,vec3(2.2)) : COLOR.rgb;
	if (!vertex_srgb) {
		vertex_tint = mix(vertex_tint, vec3(1.0), facet_softness);
	}
	vec3 col=tint.rgb*vertex_tint*(1.0+(detail-0.5)*texture_strength*2.0);
	if (use_painted_texture) {
		vec3 weights=pow(abs(world_normal),vec3(4.0));
		weights/=max(weights.x+weights.y+weights.z,0.001);
		vec3 painted=texture(painted_texture,p.zy*painted_scale).rgb*weights.x;
		painted+=texture(painted_texture,p.xz*painted_scale).rgb*weights.y;
		painted+=texture(painted_texture,p.xy*painted_scale).rgb*weights.z;
		col=mix(col,painted*vertex_tint,painted_strength);
	}
	float moss=smoothstep(0.46,0.70,noise(p*2.2))*smoothstep(0.25,0.85,world_normal.y)*moss_amount;
	col=mix(col,vec3(0.13,0.19,0.045),moss);
	float coarse=noise(world*1.45)*.7+noise(world*4.2)*.3;
    float streak=noise(world*vec3(7.,.48,7.));
    float soot=smoothstep(.21,.69,coarse*.65+streak*.35);
    float coverage=burn_amount*mix(.55,1.0,soot);
    if(surface_kind==0) coverage=burn_amount*mix(.82,1.,soot);
    if(ground_charring) {
        vec2 uv=(world.xz-scorch_bounds.xy)/scorch_bounds.zw;
        float inside=step(0.,uv.x)*step(0.,uv.y)*step(uv.x,1.)*step(uv.y,1.);
        coverage=texture(scorch_mask,clamp(uv,vec2(0),vec2(1))).r*inside*.98;
    }
    float ash_dust=smoothstep(.48,.76,noise(world*2.9))*max(.12,world_normal.y)*.65;
    vec3 burnt=mix(charcoal.rgb,ash.rgb,ash_dust);
    burnt*=.8+noise(world*27.)*.4;
    col=mix(col,burnt,clamp(coverage,0.,1.));
    ALBEDO=max(col,vec3(.001));
	ROUGHNESS=0.94;
}
