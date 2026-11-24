// An explosion of mine gas: a white flash, a fireball of flames which burns out
// to smoke, and a shockwave ring.
//
// Draw it as a textured rectangle (any white texture) whose modulate color
// carries the parameters: r = the progress (0 at the blast, 1 when it is over),
// g = a seed, a = 1.

shader_type canvas_item;

#include "res://scenes/effects/noise.gdshaderinc"

void fragment() {
    float p = clamp(COLOR.r, 0.0, 1.0);
    float seed = COLOR.g * 53.0;
    vec2 uv = UV * 2.0 - 1.0;
    float r = length(uv);

    // The shockwave: a thin bright ring which races outwards and fades.
    float ring_radius = sqrt(p) * 1.0;
    float ring = smoothstep(0.07, 0.0, abs(r - ring_radius)) * (1.0 - p) * 0.8;

    // The fireball grows quickly and burns out; the flames lick outwards.
    float grow = sqrt(clamp(p * 5.0, 0.0, 1.0));
    float radius = 0.72 * grow * (1.0 - 0.35 * p);
    float angle = atan(uv.y, uv.x);
    float flames = fbm(vec2(angle * 2.5 + seed, r * 3.0 - TIME * 3.0)) - 0.5;
    float body = fbm(uv * 3.0 + vec2(seed, -TIME * 1.5));
    float ball = smoothstep(radius, radius * 0.35, r + flames * 0.45 * grow);

    // Hot in the middle and early, cooler at the edge and later.
    float heat = clamp((1.0 - r / max(radius, 0.001)) * 1.4 + body * 0.6 - p * 1.6, 0.0, 1.0);
    vec3 fire = mix(vec3(0.85, 0.12, 0.04), vec3(1.0, 0.58, 0.1), smoothstep(0.1, 0.5, heat));
    fire = mix(fire, vec3(1.0, 0.95, 0.65), smoothstep(0.55, 0.95, heat));

    // The smoke: dark puffs which remain when the fire burns out.
    float smoke_amount = smoothstep(0.25, 0.7, p) * (1.0 - smoothstep(0.75, 1.0, p));
    vec3 smoke = vec3(0.18, 0.15, 0.17) + 0.1 * body;
    vec3 color = mix(fire, smoke, smoothstep(0.35, 0.8, p) * (1.0 - heat));
    float alpha = ball * (1.0 - smoothstep(0.7, 1.0, p));
    alpha = max(alpha, ball * smoke_amount * 0.8);

    // The flash at the very start.
    float flash = (1.0 - smoothstep(0.0, 0.08, p)) * smoothstep(0.9, 0.0, r);
    color = mix(color, vec3(1.0), flash);
    alpha = max(alpha, flash);

    color = mix(color, vec3(1.0, 0.92, 0.7), ring);
    alpha = max(alpha, ring);
    COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}
