// A cloud of mine gas: green, swirling and bubbling, which glows orange and
// flickers just before it catches fire.
//
// Draw it as a textured rectangle (any white texture) whose modulate color
// carries the parameters: r = a seed, g = how much gas (0 to 1), b = how close
// the gas is to exploding (0 to 1), a = 1.

shader_type canvas_item;

#include "res://scenes/effects/noise.gdshaderinc"

void fragment() {
    vec4 info = COLOR;
    float seed = info.r * 97.0;
    float amount = info.g;
    float danger = info.b;
    vec2 uv = UV * 2.0 - 1.0;
    float t = TIME * 0.55 + seed;

    // NOTE (mristin):
    // A domain-warped fractal noise swirls the gas; it rises slowly.
    vec2 warp = vec2(fbm(uv * 1.7 + vec2(t, seed)), fbm(uv * 1.7 + vec2(seed, -t)));
    float n = fbm(uv * 2.2 + warp * 1.6 + vec2(0.0, TIME * 0.35));
    float edge = length(uv * vec2(1.0, 1.15)) + (n - 0.5) * 0.7;
    float mask = smoothstep(1.0, 0.35, edge);

    // Bubbles which rise through the gas.
    float bubbles = 0.0;
    for (int k = 0; k < 4; k++) {
        float fk = float(k);
        vec2 center = vec2(
            (hash21(vec2(seed, fk)) - 0.5) * 1.1,
            1.0 - fract(TIME * (0.25 + 0.1 * fk) + hash21(vec2(fk, seed))) * 2.0
        );
        float radius = 0.07 + 0.05 * hash21(vec2(fk + 3.0, seed));
        float d = length(uv - center);
        bubbles += smoothstep(radius, radius * 0.6, d) - 0.6 * smoothstep(radius * 0.6, radius * 0.2, d);
    }

    // A soft glow in the middle, so that the gas looks luminous, not murky.
    float glow = smoothstep(0.9, 0.0, length(uv)) * 0.5;
    vec3 dark = vec3(0.36, 0.82, 0.18);
    vec3 light = vec3(0.86, 1.0, 0.38);
    vec3 color = mix(dark, light, clamp(smoothstep(0.3, 0.75, n) + glow, 0.0, 1.0));
    color += vec3(0.7, 0.9, 0.4) * clamp(bubbles, 0.0, 1.0) * 0.7;

    // Close to exploding, the gas glows orange and flickers.
    float flicker = 0.5 + 0.5 * sin(TIME * (18.0 + 30.0 * danger) + seed);
    color = mix(color, vec3(1.0, 0.55, 0.12), danger * danger * (0.4 + 0.6 * flicker));

    float alpha = mask * (0.3 + 0.5 * n + glow * 0.4) * amount;
    alpha += clamp(bubbles, 0.0, 1.0) * mask * 0.45 * amount;
    COLOR = vec4(color, clamp(alpha, 0.0, 0.85));
}
