class_name StarsBanner
extends Control

## The stars which the dwarves earned, popping up one after the other.

var stars := 0
var _time := 0.0


func _init(won: int) -> void:
    stars = won
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
    _time += delta
    queue_redraw()


func _draw() -> void:
    var center := Vector2(get_viewport_rect().size.x / 2.0, 330.0)
    for k in range(3):
        var t := clampf((_time - 0.3 * k) * 4.0, 0.0, 1.0)
        var size_now := 40.0 * (0.4 + 0.6 * t) if k < stars else 40.0
        Art.score_star(self, center + Vector2((k - 1) * 110.0, 0), size_now, k < stars and t > 0.0)
