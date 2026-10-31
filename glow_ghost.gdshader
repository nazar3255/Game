
shader_type canvas_item;

uniform vec4 emission_color : source_color = vec4(0.3, 0.9, 1.0, 1.0);
uniform float emission : hint_range(.0, 10.0) = 2.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    COLOR = tex;

    if (tex.a > 0.1) {
        COLOR.rgb *= emission_color.rgb * emission;
    }
}
