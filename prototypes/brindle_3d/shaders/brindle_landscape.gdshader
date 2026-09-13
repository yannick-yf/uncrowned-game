shader_type spatial;
uniform sampler2D ground_noise : filter_linear_mipmap, repeat_enable;
uniform sampler2D painted_rock : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 grass_dark : source_color = vec4(0.20,0.29,0.15,1);
uniform vec4 grass_light : source_color = vec4(0.36,0.43,0.21,1);
uniform vec4 rock_tint : source_color = vec4(0.572549,0.584314,0.603922,1);
uniform vec4 sand_tint : source_color = vec4(0.73,0.65,0.47,1);
uniform bool procedural_blend = false;
uniform bool brindle_mask_enabled = false;
uniform sampler2D brindle_ground_mask : filter_linear, repeat_disable;
uniform vec4 brindle_bounds = vec4(102.,193.,145.,120.);
uniform vec4 meadow_dark : source_color = vec4(.215,.29,.15,1);
uniform vec4 meadow_light : source_color = vec4(.34,.415,.22,1);
uniform vec4 dry_meadow : source_color = vec4(.38,.405,.25,1);
uniform vec4 soil_dark : source_color = vec4(.285,.235,.17,1);
uniform vec4 soil_light : source_color = vec4(.425,.355,.255,1);
uniform bool scorch_enabled = false;
uniform sampler2D scorch_mask : filter_linear, repeat_disable;
uniform vec4 charred_soil : source_color = vec4(.15,.128,.098,1.);
uniform vec4 ground_ash : source_color = vec4(.35,.335,.305,1.);
varying vec3 world;
varying vec3 world_normal;
float noise(vec2 p) { return texture(ground_noise,p*0.021).r; }
void vertex() {
    world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);
}
void fragment() {
    vec2 p=world.xz;
    float grain=noise(p*18.0);
    float patches=noise(p*.65)*.58+noise(p*2.9)*.27+noise(p*8.0)*.15;
    vec3 grass=mix(grass_dark.rgb,grass_light.rgb,smoothstep(.22,.80,patches))*(.94+grain*.12);
    vec3 weights=pow(abs(world_normal),vec3(4));
    weights/=max(.001,weights.x+weights.y+weights.z);
    vec3 stone=texture(painted_rock,world.yz*.17).rgb*weights.x+texture(painted_rock,world.xz*.17).rgb*weights.y+texture(painted_rock,world.xy*.17).rgb*weights.z;
    stone=mix(rock_tint.rgb*(.82+grain*.22),stone,.68);
    stone*=.92+noise(p*.7)*.12;
    vec3 sand=sand_tint.rgb*(.89+grain*.14);
    vec3 bank=vec3(.34,.30,.20)*(.9+grain*.2);
    vec3 col=mix(grass,bank,COLOR.b*.75);
    col=mix(col,sand,COLOR.g);
    if (procedural_blend) {
        float incline=length(world_normal.xz)/max(.001,abs(world_normal.y));
        float stone_weight=max(smoothstep(.45,1.05,incline),smoothstep(92.,155.,world.y)*.88);
        col=mix(grass,stone,stone_weight);
    } else {
        col=mix(col,stone,COLOR.r);
    }
    if (brindle_mask_enabled) {
        vec2 uv=(world.xz-brindle_bounds.xy)/brindle_bounds.zw;
        vec3 ground_mask=texture(brindle_ground_mask,clamp(uv,vec2(0),vec2(1))).rgb;
        float fade=smoothstep(0.,.10,uv.x)*smoothstep(0.,.10,uv.y)*(1.-smoothstep(.9,1.,uv.x))*(1.-smoothstep(.9,1.,uv.y));
        float broad=noise(p*.13)*.7+noise(p*.53)*.3;
        vec3 meadow=mix(meadow_dark.rgb,meadow_light.rgb,smoothstep(.18,.8,broad));
        meadow=mix(meadow,dry_meadow.rgb,ground_mask.g*.35);
        meadow*=.96+noise(p*3.2)*.08;
        meadow*=1.-ground_mask.b*.17;
        vec3 earth=mix(soil_dark.rgb,soil_light.rgb,noise(p*1.6)*.55+noise(p*.22)*.45);
        earth*=.93+noise(p*8.)*.12;
        float worn=ground_mask.r*(.88+noise(p*5.)*.12);
        vec3 local_ground=mix(meadow,earth,smoothstep(.05,.93,worn));
        col=mix(col,local_ground,fade*(1.-COLOR.r*.6)*(1.-COLOR.g));
    }
    if (scorch_enabled) {
        vec2 uv=(world.xz-brindle_bounds.xy)/brindle_bounds.zw;
        vec3 fire=texture(scorch_mask,clamp(uv,vec2(0),vec2(1))).rgb;
        float inside=step(0.,uv.x)*step(0.,uv.y)*step(uv.x,1.)*step(uv.y,1.);
        vec3 dried=mix(col,soil_dark.rgb,fire.b*.48*inside);
        vec3 burned=mix(charred_soil.rgb,ground_ash.rgb,fire.g*.7);
        burned*=.83+grain*.34;
        col=mix(dried,burned,smoothstep(.03,.88,fire.r)*inside);
    }
    ALBEDO=col;
    ROUGHNESS=.96;
}
