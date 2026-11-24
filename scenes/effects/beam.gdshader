// A dim beam of light from the lamp on a player's helmet, in the camera
// picture, down to her dwarf in the mine: soft at the edges, with dust which
// drifts along it and sparkles now and then.
//
// Draw it as a quad whose UV.x runs from the lamp (0) to the dwarf (1) and
// whose UV.y runs across it (0 to 1); the modulate color carries the color of
// the dwarf (rgb) and the strength of the beam (a).

shader_type canvas_item;
render_mode blend_add;

#include "res://scenes/effects/noise.gdshaderinc"

void fragment() {
    vec4 info = COLOR;
    float along = UV.x;
    float across = abs(UV.y * 2.0 - 1.0);

    // NOTE (mristin):
    // A soft core which fades towards the edges, brighter at the lamp and
    // dimmer down at the dwarf, faded in at both ends.
    float core = exp(-across * across * 5.0) * smoothstep(1.0, 0.75, across);
    float fade = mix(1.0, 0.55, along) * smoothstep(0.0, 0.06, along) * smoothstep(1.0, 0.92, along);

    // Dust which drifts down the beam, and the beam breathes a little.
    float dust = fbm(vec2(along * 7.0 - TIME * 0.9, UV.y * 3.0 + TIME * 0.15));
    float breath = 0.85 + 0.15 * sin(TIME * 2.3 + info.r * 11.0);

    // Motes of dust which catch the light.
    float motes = smoothstep(0.86, 0.97, value_noise(vec2(along * 46.0 - TIME * 4.0, UV.y * 9.0 + info.g * 13.0)));

    float alpha = info.a * fade * (core * (0.55 + 0.6 * dust) * breath + motes * core * 0.8);
    vec3 color = mix(info.rgb, vec3(1.0, 0.94, 0.78), 0.45);
    // NOTE (mristin):
    // The additive blending multiplies the color with the alpha already.
    COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}
