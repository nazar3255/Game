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
// PSYCHEDELIC EFFECTS
// ==========================================

// Головний перемикач
uniform bool psychedelic_enabled = false;

// Загальна сила ефекту
uniform float psychedelic_intensity : hint_range(0.0, 1.0) = 1.0;

// Хвиляста дисторсія
uniform float wave_strength : hint_range(0.0, 0.08) = 0.018;
uniform float wave_frequency : hint_range(1.0, 30.0) = 12.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.2;

// Додаткове органічне викривлення
uniform float organic_distortion : hint_range(0.0, 0.05) = 0.012;
uniform float distortion_scale : hint_range(1.0, 15.0) = 4.0;

// Скручування зображення
uniform float swirl_strength : hint_range(0.0, 3.0) = 0.45;

// Колірна дисперсія
uniform float dispersion_strength : hint_range(0.0, 0.03) = 0.006;

// Насиченість психоделічного режиму
uniform float psychedelic_saturation : hint_range(0.0, 2.0) = 1.45;

// Інтенсивність кольорових переливів
uniform float psychedelic_colors : hint_range(0.0, 1.0) = 0.25;

// Швидкість зміни кольорів
uniform float color_cycle_speed : hint_range(0.0, 3.0) = 0.35;


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
// PSYCHEDELIC DISTORTION
// ==========================================

vec2 calculate_psychedelic_uv(vec2 uv) {

    vec2 screen_size = vec2(textureSize(screen_texture, 0));
    float aspect = screen_size.x / screen_size.y;

    vec2 centered = uv - vec2(0.5);

    // Корекція пропорцій екрана
    centered.x *= aspect;

    float radius = length(centered);
    float angle = atan(centered.y, centered.x);

    // Хвилі, що проходять через зображення
    float wave = sin(
        radius * wave_frequency -
        TIME * wave_speed +
        sin(angle * 3.0 + TIME * 0.5)
    );

    float secondary_wave = sin(
        angle * 5.0 -
        radius * 8.0 +
        TIME * wave_speed * 0.7
    );

    // Органічне викривлення за допомогою шуму
    vec2 noise_position = uv * distortion_scale;

    noise_position += vec2(
        TIME * 0.12,
        TIME * 0.08
    );

    float noise_x = fbm(noise_position);
    float noise_y = fbm(
        noise_position + vec2(7.3, 3.8)
    );

    vec2 organic_offset = vec2(
        noise_x - 0.5,
        noise_y - 0.5
    );

    // Основний рух хвиль
    vec2 wave_offset = normalize(centered + vec2(0.0001)) *
        wave * wave_strength;

    // Додаткові хвилясті коливання
    wave_offset += vec2(
        secondary_wave,
        wave
    ) * wave_strength * 0.35;

    // Органічне викривлення
    vec2 final_offset = wave_offset +
        organic_offset * organic_distortion;

    // Скручування зображення
    float swirl = sin(
        radius * 5.0 - TIME * wave_speed * 0.5
    ) * swirl_strength * radius;

    float rotation_angle = swirl * 0.35;

    mat2 rotation = mat2(
        vec2(cos(rotation_angle), -sin(rotation_angle)),
        vec2(sin(rotation_angle), cos(rotation_angle))
    );

    centered = rotation * centered;

    vec2 distorted_uv = centered / vec2(aspect, 1.0) + vec2(0.5);

    distorted_uv += final_offset / vec2(aspect, 1.0);

    return distorted_uv;
}


// ==========================================
// FRAGMENT
// ==========================================

void fragment() {

    vec2 uv = SCREEN_UV;

    float intensity = 0.0;

    if (psychedelic_enabled) {
        intensity = psychedelic_intensity;
    }

    // ======================================
    // PSYCHEDELIC UV
    // ======================================

    vec2 distorted_uv = uv;

    if (intensity > 0.0) {

        vec2 psychedelic_uv = calculate_psychedelic_uv(uv);

        distorted_uv = mix(
            uv,
            psychedelic_uv,
            intensity
        );
    }

    // Захист від виходу за межі текстури
    distorted_uv = clamp(
        distorted_uv,
        vec2(0.001),
        vec2(0.999)
    );


    // ======================================
    // CHROMATIC DISPERSION
    // ======================================

    vec3 color;

    if (intensity > 0.0) {

        vec2 center = uv - vec2(0.5);

        float aspect = float(textureSize(screen_texture, 0).x) /
                       float(textureSize(screen_texture, 0).y);

        center.x *= aspect;

        vec2 dispersion_direction = normalize(
            center + vec2(0.0001)
        );

        dispersion_direction.x /= aspect;

        float dispersion = dispersion_strength * intensity;

        vec2 offset = dispersion_direction * dispersion;

        // Червоний канал
        float red = texture(
            screen_texture,
            clamp(distorted_uv + offset, vec2(0.001), vec2(0.999))
        ).r;

        // Зелений канал
        float green = texture(
            screen_texture,
            distorted_uv
        ).g;

        // Синій канал
        float blue = texture(
            screen_texture,
            clamp(distorted_uv - offset, vec2(0.001), vec2(0.999))
        ).b;

        color = vec3(red, green, blue);

    } else {

        color = texture(screen_texture, uv).rgb;
    }


    // ======================================
    // COLOR GRADING
    // ======================================

    float gray = dot(color, vec3(0.299, 0.587, 0.114));

    float current_saturation = mix(
        saturation,
        psychedelic_saturation,
        intensity
    );

    color = mix(vec3(gray), color, current_saturation);

    float lum = dot(color, vec3(0.299, 0.587, 0.114));

    color = mix(
        color * shadow_color.rgb,
        color * highlight_color.rgb,
        smoothstep(0.15, 0.85, lum)
    );

    color = (color - 0.5) * contrast + 0.5;
    color *= brightness;


    // ======================================
    // COLOR SHIFT
    // ======================================

    color.g += color_shift * (1.0 - lum);
    color.b -= color_shift * 0.4 * (1.0 - lum);


    // ======================================
    // PSYCHEDELIC COLOR CYCLE
    // ======================================

    if (intensity > 0.0) {

        float color_time = TIME * color_cycle_speed;

        vec3 psychedelic_tint = vec3(
            0.5 + 0.5 * sin(color_time + uv.x * 4.0),
            0.5 + 0.5 * sin(color_time + uv.y * 4.0 + 2.1),
            0.5 + 0.5 * sin(color_time + (uv.x + uv.y) * 3.0 + 4.2)
        );

        vec3 tinted_color = color *
            (0.65 + psychedelic_tint * 0.7);

        color = mix(
            color,
            tinted_color,
            psychedelic_colors * intensity
        );
    }


    // ======================================
    // VIGNETTE
    // ======================================

    vec2 screen_size = vec2(textureSize(screen_texture, 0));
    float aspect = screen_size.x / screen_size.y;

    vec2 vignette_uv = uv - vignette_center;

    vignette_uv.x *= aspect;

    float vignette_distance = length(vignette_uv);

    float vignette = smoothstep(
        vignette_radius * 0.55,
        vignette_radius,
        vignette_distance
    );

    color *= 1.0 - vignette * vignette_strength;


    // ======================================
    // FILM GRAIN
    // ======================================

    float grain = hash(
        floor(uv * vec2(900.0, 900.0)) +
        floor(TIME * 12.0)
    );

    color += (grain - 0.5) * grain_strength;


    // ======================================
    // FLICKER
    // ======================================

    float flicker = hash(
        vec2(floor(TIME * 8.0), 1.0)
    );

    color *= 1.0 - flicker * flicker_strength;


    // ======================================
    // FINAL COLOR
    // ======================================

    COLOR = vec4(color, 1.0);
}