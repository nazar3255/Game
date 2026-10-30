
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// GENERAL
uniform float intensity : hint_range(0.0, 1.0) = 1.0;

// COLOR
uniform vec4 tint_color : source_color = vec4(1.0, 0.9, 0.75, 1.0);
uniform float saturation : hint_range(0.0, 1.0) = 1.0;
uniform float contrast : hint_range(0.0, 3.0) = 1.1;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

// DISTORTION
uniform float distortion : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic : hint_range(0.0, 1.0) = 0.0;

// BLOOM
uniform float bloom_strength : hint_range(0.0, 2.0) = 0.0;
uniform float bloom_threshold : hint_range(0.0, 2.0) = 0.7;
uniform float bloom_radius : hint_range(1.0, 30.0) = 8.0;

// BLUR - ONLY THE SCENE
uniform float blur_strength : hint_range(0.0, 1.0) = 0.0;
uniform float blur_radius : hint_range(1.0, 10.0) = 2.0;

// BOKEH - LIGHT HALO
uniform float bokeh_strength : hint_range(0.0, 3.0) = 0.0;
uniform float bokeh_threshold : hint_range(0.0, 2.0) = 0.65;
uniform float bokeh_radius : hint_range(1.0, 40.0) = 15.0;
uniform vec4 bokeh_color : source_color = vec4(1.0, 0.85, 0.55, 1.0);
uniform float bokeh_highlights : hint_range(0.0, 2.0) = 1.0;
uniform float bokeh_shadows : hint_range(0.0, 1.0) = 0.0;

// ATMOSPHERE
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.0;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.0;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.0;


// BLUR THE ORIGINAL SCENE
vec3 calculate_blur(vec2 uv) {
    vec2 px = 1.0 / vec2(textureSize(screen_texture, 0));
    px *= blur_radius;

    vec3 result = texture(screen_texture, uv).rgb * 0.4;

    result += texture(screen_texture, uv + vec2(px.x, 0.0)).rgb * 0.1;
    result += texture(screen_texture, uv - vec2(px.x, 0.0)).rgb * 0.1;
    result += texture(screen_texture, uv + vec2(0.0, px.y)).rgb * 0.1;
    result += texture(screen_texture, uv - vec2(0.0, px.y)).rgb * 0.1;

    result += texture(screen_texture, uv + px).rgb * 0.05;
    result += texture(screen_texture, uv - px).rgb * 0.05;
    result += texture(screen_texture, uv + vec2(px.x, -px.y)).rgb * 0.05;
    result += texture(screen_texture, uv + vec2(-px.x, px.y)).rgb * 0.05;

    return result;
}


// GET SCENE WITH OPTIONAL BLUR
vec3 get_scene(vec2 uv) {
    vec3 sharp_scene = texture(screen_texture, uv).rgb;
    vec3 blurred_scene = calculate_blur(uv);

    return mix(sharp_scene, blurred_scene, blur_strength);
}


// EXTRACT BRIGHT AREAS FOR BLOOM
vec3 extract_bright(vec2 uv) {
    vec3 col = texture(screen_texture, uv).rgb;

    float lum = dot(col, vec3(0.299, 0.587, 0.114));

    float mask = smoothstep(
        bloom_threshold,
        bloom_threshold + 0.3,
        lum
    );

    return col * mask;
}


// BLOOM
vec3 calculate_bloom(vec2 uv) {
    vec2 px = 1.0 / vec2(textureSize(screen_texture, 0));
    px *= bloom_radius;

    vec3 result = vec3(0.0);

    result += extract_bright(uv) * 0.2;
    result += extract_bright(uv + vec2(px.x, 0.0)) * 0.1;
    result += extract_bright(uv - vec2(px.x, 0.0)) * 0.1;
    result += extract_bright(uv + vec2(0.0, px.y)) * 0.1;
    result += extract_bright(uv - vec2(0.0, px.y)) * 0.1;

    result += extract_bright(uv + px) * 0.1;
    result += extract_bright(uv - px) * 0.1;
    result += extract_bright(uv + vec2(px.x, -px.y)) * 0.1;
    result += extract_bright(uv + vec2(-px.x, px.y)) * 0.1;

    return result;
}


// EXTRACT BRIGHT AREAS FOR BOKEH
vec3 extract_bokeh(vec2 uv) {
    vec3 col = texture(screen_texture, uv).rgb;

    float lum = dot(col, vec3(0.299, 0.587, 0.114));

    // Виділення світлих ділянок
    float highlights = smoothstep(
        bokeh_threshold,
        bokeh_threshold + 0.2,
        lum
    );

    // Виділення тіней
    float shadows = 1.0 - smoothstep(0.0, 0.5, lum);

    // Об'єднання масок
    float mask = clamp(
        highlights * bokeh_highlights + shadows * bokeh_shadows,
        0.0,
        1.0
    );

    return col * mask;
}


// BOKEH LIGHT HALO

vec3 calculate_bokeh(vec2 uv) {
    vec2 px = 1.0 / vec2(textureSize(screen_texture, 0));
    px *= bokeh_radius;

    vec3 glow = vec3(0.0);

    // Center
    glow += extract_bokeh(uv) * 0.20;

    // First ring
    glow += extract_bokeh(uv + vec2(px.x, 0.0)) * 0.12;
    glow += extract_bokeh(uv - vec2(px.x, 0.0)) * 0.12;
    glow += extract_bokeh(uv + vec2(0.0, px.y)) * 0.12;
    glow += extract_bokeh(uv - vec2(0.0, px.y)) * 0.12;

    // Diagonal samples
    glow += extract_bokeh(uv + px) * 0.08;
    glow += extract_bokeh(uv - px) * 0.08;
    glow += extract_bokeh(uv + vec2(px.x, -px.y)) * 0.08;
    glow += extract_bokeh(uv + vec2(-px.x, px.y)) * 0.08;

    // Outer ring
    glow += extract_bokeh(uv + vec2(px.x * 2.0, 0.0)) * 0.04;
    glow += extract_bokeh(uv - vec2(px.x * 2.0, 0.0)) * 0.04;
    glow += extract_bokeh(uv + vec2(0.0, px.y * 2.0)) * 0.04;
    glow += extract_bokeh(uv - vec2(0.0, px.y * 2.0)) * 0.04;

    // Additional intermediate samples
    glow += extract_bokeh(uv + px * 0.5) * 0.04;
    glow += extract_bokeh(uv - px * 0.5) * 0.04;
    glow += extract_bokeh(uv + vec2(px.x * 0.5, -px.y * 0.5)) * 0.04;
    glow += extract_bokeh(uv + vec2(-px.x * 0.5, px.y * 0.5)) * 0.04;

    return glow;
}



// RANDOM NOISE
float random_noise(vec2 uv) {
    return fract(
        sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453
    );
}


// MAIN
void fragment() {
    vec2 uv = SCREEN_UV;

    // Original scene
    vec3 original = texture(screen_texture, uv).rgb;

    // Distortion
    float wave = sin(uv.y * 35.0 + TIME * 2.0)
        * distortion * 0.003;

    vec2 distorted_uv = uv + vec2(wave, 0.0);

    // Scene with blur applied BEFORE other effects
    vec3 color = get_scene(distorted_uv);

    // Brightness
    color *= brightness;

    // Contrast
    color = (color - 0.5) * contrast + 0.5;

    // Saturation
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(gray), color, saturation);

    // Tint
    color *= tint_color.rgb;

    // Chromatic aberration
    vec2 chroma_offset = vec2(chromatic * 0.003, 0.0);

    float red = get_scene(distorted_uv + chroma_offset).r;
    float blue = get_scene(distorted_uv - chroma_offset).b;

    color.r = mix(color.r, red, chromatic);
    color.b = mix(color.b, blue, chromatic);

    // Bloom overlay
    color += calculate_bloom(distorted_uv) * bloom_strength;

    // Bokeh overlay - adds light, does not replace the scene
    vec3 bokeh = calculate_bokeh(distorted_uv);
    color += bokeh * bokeh_color.rgb * bokeh_strength;

    // Vignette
    float vignette = distance(uv, vec2(0.5));
    color *= 1.0 - vignette * vignette_strength;

    // Grain
    float noise = random_noise(uv * (TIME + 1.0));
    color += (noise - 0.5) * grain_strength;

    // Scanlines
    float scanline = sin(uv.y * 900.0) * 0.5 + 0.5;
    color *= 1.0 - scanline * scanline_strength * 0.15;

    // Flicker
    float flicker = 1.0
        - random_noise(vec2(TIME, 0.0)) * flicker_strength * 0.1;
    color *= flicker;

    // Global intensity
    color = mix(original, color, intensity);

    COLOR = vec4(color, 1.0);
}
