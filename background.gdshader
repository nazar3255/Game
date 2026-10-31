shader_type canvas_item;

uniform float brightness : hint_range(-1.0, 1.0) = 0.0;
uniform float contrast : hint_range(0.0, 3.0) = 1.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Яскравість
    color.rgb += brightness;

    // Контраст
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;

    // Насиченість
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(gray), color.rgb, saturation);

    COLOR = color;
}