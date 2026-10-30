
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

// ==========================================
// COLOR GRADING
// ==========================================

uniform float saturation : hint_range(0.0, 1.0) = 0.68;
uniform float contrast : hint_range(0.5, 2.0) = 1.12;
uniform float brightness : hint_range(0.5, 1.5) = 0.88;

uniform vec4 shadow_color : source_color = vec4(0.48, 0.58, 0.48, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.85, 0.79, 0.63, 1.0);


// ==========================================
// PROCEDURAL FOG
// ==========================================

uniform float fog_strength : hint_range(0.0, 0.3) = 0.065;
uniform float fog_scale : hint_range(0.5, 10.0) = 2.2;
uniform float fog_speed : hint_range(0.0, 0.5) = 0.018;

// НОВИЙ ПАРАМЕТР — СИЛА РУХУ ТУМАНУ
uniform float fog_motion_strength : hint_range(0.0, 3.0) = 1.0;

uniform float fog_detail : hint_range(0.0, 1.0) = 0.35;
uniform float fog_softness : hint_range(0.1, 2.0) = 1.2;

uniform float fog_world_scale : hint_range(0.0, 0.02) = 0.0035;

uniform vec4 fog_color : source_color = vec4(0.35, 0.42, 0.34, 1.0);

uniform vec2 camera_world_position = vec2(0.0);


// ==========================================
// VIGNETTE
// ==========================================

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.38;
uniform float vignette_radius : hint_range(0.1, 1.5) = 0.85;
uniform vec2 vignette_center = vec2(0.5, 0.5);


// ==========================================
// FILM GRAIN
// ==========================================

uniform float grain_strength : hint_range(0.0, 0.2) = 0.025;


// ==========================================
// FLICKER
// ==========================================

uniform float flicker_strength : hint_range(0.0, 0.2) = 0.015;


// ==========================================
// COLOR SHIFT
// ==========================================

uniform float color_shift : hint_range(0.0, 0.2) = 0.025;


// ==========================================
// HASH FUNCTIONS
// ==========================================

float hash(vec2 p) {
    return fract(
        sin(dot(p, vec2(127.1, 311.7))) * 43758.5453
    );
}

vec2 gradient_hash(vec2 p) {
    float angle = hash(p) * 6.2831853;

    return vec2(cos(angle), sin(angle));
}


// ==========================================
// PERLIN-STYLE GRADIENT NOISE
// ==========================================

float gradient_noise(vec2 p) {

    vec2 cell = floor(p);
    vec2 local = fract(p);

    vec2 fade = local * local * local *
        (local * (local * 6.0 - 15.0) + 10.0);

    vec2 g00 = gradient_hash(cell);
    vec2 g10 = gradient_hash(cell + vec2(1.0, 0.0));
    vec2 g01 = gradient_hash(cell + vec2(0.0, 1.0));
    vec2 g11 = gradient_hash(cell + vec2(1.0, 1.0));

    float n00 = dot(g00, local);
    float n10 = dot(g10, local - vec2(1.0, 0.0));
    float n01 = dot(g01, local - vec2(0.0, 1.0));
    float n11 = dot(g11, local - vec2(1.0, 1.0));

    float nx0 = mix(n00, n10, fade.x);
    float nx1 = mix(n01, n11, fade.x);

    return clamp(
        mix(nx0, nx1, fade.y) * 1.4 + 0.5,
        0.0,
        1.0
    );
}


// ==========================================
// FRACTAL BROWNIAN MOTION
// ==========================================

float fbm(vec2 p) {

    float value = 0.0;
    float amplitude = 0.5;
    float total = 0.0;

    mat2 rotation = mat2(
        vec2(0.8, -0.6),
        vec2(0.6, 0.8)
    );

    for (int i = 0; i < 5; i++) {

        value += gradient_noise(p) * amplitude;
        total += amplitude;

        p = rotation * p * 2.0 + vec2(3.7, 1.9);
        amplitude *= 0.5;
    }

    return value / total;
}


// ==========================================
// DOMAIN WARPING
// ==========================================

float calculate_fog(vec2 uv) {

    vec2 screen_size = vec2(textureSize(screen_texture, 0));
    float aspect = screen_size.x / screen_size.y;

    vec2 p = uv * vec2(aspect, 1.0) * fog_scale;

    // Прив'язка до координат світу
    p += camera_world_position * fog_world_scale;

    // Рух туману з урахуванням нового параметра
    vec2 movement = vec2(
        TIME * fog_speed * fog_motion_strength,
        TIME * fog_speed * 0.35 * fog_motion_strength
    );

    // Викривлення форми
    float warp_x = fbm(p * 0.65 + movement);

    float warp_y = fbm(
        p * 0.65 + movement + vec2(12.4, 5.7)
    );

    vec2 warped_p = p + (vec2(warp_x, warp_y) - 0.5) * 1.8;

    // Великі форми
    float large_noise = fbm(warped_p * 0.7);

    // Дрібні деталі
    float detail_noise = fbm(
        warped_p * 1.8 + vec2(4.2, 8.1)
    );

    // Поєднання шумів
    float noise_value = mix(
        large_noise,
        detail_noise,
        fog_detail
    );

    float density = clamp(
        (noise_value - 0.12) * 1.25,
        0.0,
        1.0
    );

    density = pow(density, fog_softness);

    return density;
}


// ==========================================
// FRAGMENT
// ==========================================

void fragment() {

    vec2 uv = SCREEN_UV;

    vec2 screen_size = vec2(textureSize(screen_texture, 0));
    float aspect = screen_size.x / screen_size.y;

    vec3 color = texture(screen_texture, uv).rgb;


    // COLOR GRADING

    float gray = dot(color, vec3(0.299, 0.587, 0.114));

    color = mix(vec3(gray), color, saturation);

    float lum = dot(color, vec3(0.299, 0.587, 0.114));

    color = mix(
        color * shadow_color.rgb,
        color * highlight_color.rgb,
        smoothstep(0.15, 0.85, lum)
    );

    color = (color - 0.5) * contrast + 0.5;
    color *= brightness;


    // COLOR SHIFT

    color.g += color_shift * (1.0 - lum);
    color.b -= color_shift * 0.4 * (1.0 - lum);


    // PROCEDURAL FOG

    float fog = calculate_fog(uv);

    color = mix(
        color,
        fog_color.rgb,
        fog * fog_strength
    );


    // VIGNETTE

    vec2 vignette_uv = uv - vignette_center;

    vignette_uv.x *= aspect;

    float vignette_distance = length(vignette_uv);

    float vignette = smoothstep(
        vignette_radius * 0.55,
        vignette_radius,
        vignette_distance
    );

    color *= 1.0 - vignette * vignette_strength;


    // FILM GRAIN

    float grain = hash(
        floor(uv * vec2(900.0, 900.0)) +
        floor(TIME * 12.0)
    );

    color += (grain - 0.5) * grain_strength;


    // FLICKER

    float flicker = hash(
        vec2(floor(TIME * 8.0), 1.0)
    );

    color *= 1.0 - flicker * flicker_strength;


    // FINAL COLOR

    COLOR = vec4(color, 1.0);
}
