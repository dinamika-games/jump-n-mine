class_name Hud
extends Control

## The bar at the top of the level (the name of the level, the gems, how deep
## the dwarves and the evil miner came and how full of water the mine is), the
## boosters which the dwarves brought along, and the tips. The camera
## picture lies over the mine (see [CameraOverlay]).

var mine: Mine
var level: Dictionary

var _tip := ""
var _tip_left := 0.0
var _time := 0.0
var _font: Font = ThemeDB.fallback_font


func _init(a_mine: Mine, a_level: Dictionary) -> void:
    mine = a_mine
    level = a_level
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE


## Show a tip in the middle of the screen for a few seconds.
func tip(text: String, seconds := 6.0) -> void:
    _tip = text
    _tip_left = seconds


func _process(delta: float) -> void:
    _time += delta
    _tip_left = maxf(0.0, _tip_left - delta)
    queue_redraw()


func _draw() -> void:
    var width := get_viewport_rect().size.x
    draw_rect(Rect2(0, 0, width, MineView.TOP), Color("#1a1016"))
    draw_rect(Rect2(0, MineView.TOP - 4, width, 4), Color("#3a2a30"))
    _text(level["name"], Vector2(24, 58), 40, Color("#ffe2a0"))

    # The gems.
    Art.gem(self, Vector2(620, 44), 22.0, 0)
    _text("%d / %d" % [mine.gems, mine.gems_total], Vector2(655, 58), 40, Color.WHITE)

    # How deep the dwarves came, down to the treasure.
    var bar := Rect2(860, 28, 460, 32)
    draw_rect(bar.grow(3), Art.OUTLINE)
    draw_rect(bar, Color("#3a2a30"))
    draw_rect(
        Rect2(bar.position, Vector2(bar.size.x * mine.progress(), bar.size.y)), Color("#d99a52")
    )
    Art.chest(self, bar.end + Vector2(30, 6), 44.0, _time)
    if mine.rival != null:
        var share := clampf(
            (mine.rival.pos.y - Mine.SKY_ROWS) / float(mine.chest.y - Mine.SKY_ROWS), 0.0, 1.0
        )
        Art.dwarf(
            self,
            Vector2(bar.position.x + bar.size.x * share, bar.end.y + 4),
            46.0,
            Mine.RIVAL,
            {"facing": -1}
        )
    Art.dwarf(
        self, Vector2(bar.position.x + bar.size.x * mine.progress(), bar.end.y + 4), 46.0, 0, {}
    )

    # How full of water the mine is.
    if not level.get("springs", []).is_empty():
        var flood := mine.flood_level()
        var meter := Rect2(1450, 28, 300, 32)
        draw_rect(meter.grow(3), Art.OUTLINE)
        draw_rect(meter, Color("#1a2a3a"))
        var blink := flood > 0.75 and fmod(_time * 3.0, 1.0) < 0.5
        draw_rect(
            Rect2(meter.position, Vector2(meter.size.x * flood, meter.size.y)),
            Color("#ff5a4a") if blink else Color("#3f8ee8")
        )
        draw_circle(Vector2(1420, 44), 14.0, Color("#3f8ee8"))
        draw_colored_polygon(
            PackedVector2Array([Vector2(1406, 40), Vector2(1434, 40), Vector2(1420, 18)]),
            Color("#3f8ee8")
        )

    _draw_boosters()

    # NOTE (mristin):
    # Why there is no camera picture, if there is none (see [CameraOverlay]).
    var vision := get_node_or_null("/root/Vision")
    if vision != null and vision.preview() == null and vision.status() != "":
        var area := get_viewport_rect().size
        draw_rect(Rect2(area.x - 620, area.y - 60, 600, 44), Color(0.1, 0.06, 0.08, 0.7))
        _text(vision.status(), Vector2(area.x - 610, area.y - 28), 22, Color("#f4e6d0"))

    if _tip_left > 0.0:
        var alpha := clampf(_tip_left, 0.0, 1.0)
        var size_now := 46
        var text_width := _font.get_string_size(_tip, HORIZONTAL_ALIGNMENT_LEFT, -1, size_now).x
        var box := Rect2((width - text_width) / 2.0 - 30, 150, text_width + 60, 80)
        draw_rect(box, Color(0.1, 0.06, 0.08, 0.8 * alpha))
        _text(
            _tip,
            Vector2(box.position.x + 30, box.position.y + 56),
            size_now,
            Color(1, 0.9, 0.6, alpha)
        )


func _text(text: String, at: Vector2, font_size: int, color: Color) -> void:
    draw_string_outline(
        _font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color(0, 0, 0, color.a)
    )
    draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## The boosters which the dwarves brought along, in the bottom left corner: how
## many are left of each, and a bar for the one which helps now.
func _draw_boosters() -> void:
    var area := get_viewport_rect().size
    var x := 24.0
    for kind in Mine.BOOSTERS:
        var left := int(mine.charges.get(kind, 0))
        var on := MineBoosters.has(mine, kind)
        if left <= 0 and not on:
            continue
        var center := Vector2(x + 34, area.y - 52)
        draw_circle(center, 38.0, Color(0.1, 0.06, 0.08, 0.75))
        if on:
            draw_circle(center, 38.0, Color(1, 0.9, 0.4, 0.3 + 0.15 * sin(_time * 6.0)))
        Art.booster(self, center, 28.0, kind)
        _text("%d" % left, center + Vector2(24, 34), 30, Color.WHITE)
        if on:
            var share := float(mine.active[kind]) / float(Mine.BOOSTER_TIME.get(kind, 20.0))
            draw_rect(Rect2(center + Vector2(-34, 44), Vector2(68 * share, 6)), Color("#ffe27a"))
        x += 96.0
