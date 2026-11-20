class_name Hud
extends Control

## The bar at the top of the level (the name of the level, the gems, how deep
## the dwarves came and how full of water the mine is), the tips, and the
## camera picture in the corner with a dot on every head.

var mine: Mine
var level: Dictionary
## The dwarf of each head in the camera, by the id of the head.
var dwarf_of_head := {}

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

    _draw_camera()

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


func _draw_camera() -> void:
    var vision := get_node_or_null("/root/Vision")
    if vision == null:
        return
    var area := get_viewport_rect().size
    var rect := Rect2(area.x - 380, area.y - 290, 360, 270)
    var texture: Texture2D = vision.preview()
    if texture == null:
        if vision.status() != "":
            var lines: String = vision.status()
            draw_rect(Rect2(area.x - 620, area.y - 60, 600, 44), Color(0.1, 0.06, 0.08, 0.7))
            _text(lines, Vector2(area.x - 610, area.y - 28), 22, Color("#f4e6d0"))
        return
    draw_rect(rect.grow(4), Art.OUTLINE)
    draw_set_transform(Vector2(rect.position.x * 2 + rect.size.x, 0), 0.0, Vector2(-1, 1))
    draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.9))
    draw_set_transform(Vector2.ZERO)
    # NOTE (mristin):
    # A miner's helmet on every player, with the brim in the color of her dwarf.
    for id in vision.heads:
        var head: Dictionary = vision.heads[id]
        var position: Vector2 = head["position"]
        var size: float = head["size"] * rect.size.y
        var top := rect.position + position * rect.size - Vector2(0, size * 0.5)
        var slot := int(dwarf_of_head.get(id, -1))
        var brim := Dwarves.color(slot) if slot >= 0 else Color(0.85, 0.85, 0.85)
        var line: float = head.get("jump_line", NAN)
        if not is_nan(line):
            var center_x := rect.position.x + position.x * rect.size.x
            Art.jump_line(
                self,
                rect.position.y + line * rect.size.y,
                maxf(rect.position.x + 4.0, center_x - size * 1.4),
                minf(rect.end.x - 4.0, center_x + size * 1.4),
                bool(head.get("jumping", false)),
                maxf(4.0, rect.size.y * 0.018)
            )
        Art.miner_hat(self, top, size, slot, _time + id)
        _draw_jump_meter(head, top + Vector2(size * 0.75, size * 0.2), size, brim)


## A bar beside the head which fills as the head rises, and flashes when a jump
## counts, so that the players see how high they must jump.
func _draw_jump_meter(head: Dictionary, at: Vector2, size: float, color: Color) -> void:
    var vision := get_node("/root/Vision")
    var rise: float = head.get("rise", 0.0)
    var share := clampf(rise / vision.JUMP_HEIGHT, 0.0, 1.0)
    var since := Time.get_ticks_msec() / 1000.0 - float(head.get("jumped", -10.0))
    var bar := Rect2(at, Vector2(maxf(8.0, size * 0.12), size * 0.9))
    draw_rect(bar.grow(2.0), Art.OUTLINE)
    draw_rect(bar, Color(0.2, 0.15, 0.2, 0.8))
    # A tick where a low jump (a weaker hit) begins.
    var low: float = vision.LOW_JUMP_HEIGHT / vision.JUMP_HEIGHT
    var tick_y := bar.end.y - bar.size.y * low
    draw_line(
        Vector2(bar.position.x - 4.0, tick_y), Vector2(bar.end.x + 4.0, tick_y), Art.OUTLINE, 3.0
    )
    var fill := bar.size.y * share
    var fill_color := color if since > 0.4 else Color("#ffe65a")
    draw_rect(Rect2(bar.position.x, bar.end.y - fill, bar.size.x, fill), fill_color)
    if since <= 0.4:
        draw_rect(bar.grow(5.0), Color(1.0, 0.9, 0.4, 0.5 * (1.0 - since / 0.4)), false, 4.0)


func _text(text: String, at: Vector2, font_size: int, color: Color) -> void:
    draw_string_outline(
        _font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color(0, 0, 0, color.a)
    )
    draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
