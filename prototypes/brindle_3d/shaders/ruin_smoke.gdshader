shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 smoke_color : source_color = vec4(.57,.56,.53,1.);
varying vec3 puff_position;
void vertex() {
    puff_position=MODEL_MATRIX[3].xyz;
    vec3 scale=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
    MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*scale.x,INV_VIEW_MATRIX[1]*scale.y,INV_VIEW_MATRIX[2]*scale.z,MODEL_MATRIX[3]);
}
void fragment() {
    vec2 q=UV*2.-1.;
    float swirl=sin(q.x*7.+puff_position.y*2.+TIME*.36)*sin(q.y*6.-puff_position.x*.7)*.10;
    float radius=length(q*vec2(.92,1.05))+swirl;
    float soft=1.-smoothstep(.16,.94,radius);
    float wisps=.78+.22*sin(UV.y*9.+UV.x*5.+puff_position.y);
    ALBEDO=smoke_color.rgb;
    ALPHA=soft*soft*wisps*COLOR.a;
}
