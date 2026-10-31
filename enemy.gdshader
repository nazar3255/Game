shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	vec3 flash_color = vec3(1.0);

	tex.rgb = mix(tex.rgb, flash_color, flash_intensity);

	COLOR = tex * COLOR;
}