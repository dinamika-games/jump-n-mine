// The warning where a dragon's fire will fall: a shimmering column of heat
// with embers rising, and a hot glowing mark on the ground where the fire will
// land. It grows stronger until the dragon spits.
//
// Draw it as a textured rectangle (any white texture) over the column, from
// the top of the screen down to the ground, whose modulate color carries the
// parameters: r = how strong (0 to 1), g = a seed, b = where the ground is
// (as a fraction of the height of the rectangle), a = 1.

shader_type canvas_item;

#include "res://scenes/effects/noise.gdshaderinc"

void fragment() {
    float strength = COLOR.r;
    float seed = COLOR.g * 71.0;
    float ground = clamp(COLOR.b, 0.05, 1.0);
    vec2 uv = UV;
    float t = TIME;

    // NOTE (mristin):
    // The column wavers like hot air; it is strongest near the ground.
    float waver = (fbm(vec2(uv.y * 4.0 - t * 1.5, seed)) - 0.5) * 0.35;
    float across = abs((uv.x - 0.5) * 2.0 + waver);
    float column = smoothstep(1.0, 0.3, across);
    float down = smoothstep(0.0, ground, uv.y) * step(uv.y, ground + 0.02);
    float flicker = 0.75 + 0.25 * fbm(vec2(uv.x * 3.0 + seed, uv.y * 6.0 - t * 4.0));
    float heat = column * (0.25 + 0.75 * down) * flicker;

    // The embers: little sparks which rise through the column.
    float embers = 0.0;
    for (int k = 0; k < 6; k++) {
        float fk = float(k);
        float x = 0.25 + 0.5 * hash21(vec2(fk, seed));
        float y = ground - fract(t * (0.35 + 0.2 * hash21(vec2(seed, fk))) + hash21(vec2(fk * 3.1, seed))) * ground;
        float d = length((uv - vec2(x + sin(t * 3.0 + fk) * 0.05, y)) * vec2(1.0, 4.0));
        embers += smoothstep(0.06, 0.0, d);
    }

    // The mark on the ground: a hot glowing ellipse which pulses.
    vec2 mark_uv = (uv - vec2(0.5, ground)) * vec2(1.6, 9.0);
    float pulse = 0.8 + 0.2 * sin(t * (8.0 + 10.0 * strength));
    float mark = smoothstep(1.0, 0.0, length(mark_uv)) * pulse;

    vec3 color = mix(vec3(0.9, 0.12, 0.05), vec3(1.0, 0.55, 0.1), heat);
    color = mix(color, vec3(1.0, 0.9, 0.5), clamp(embers + mark * 0.7, 0.0, 1.0));
    float alpha = (heat * 0.75 + embers * 0.95 + mark * 0.9) * strength;
    COLOR = vec4(color, clamp(alpha, 0.0, 0.9));
}
