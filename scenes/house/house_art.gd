class_name HouseArt
extends RefCounted

## Draw the dwarves' house with the stages of its parts (see [constant
## Economy.HOUSE_PARTS]): a little shack at first, which grows with every
## improvement into a palace with a tower, a garden, a fence, the mine entrance
## and the village square. The house is drawn in code (no painted pictures), on
## a stage of 1200 x 520 which is scaled into the rectangle.

const W := 1200.0
const H := 520.0
const GROUND := 440.0

const _WOOD := Color("#8a5a32")
const _WOOD_DARK := Color("#5e3a1e")
const _STONE := Color("#9a958c")
const _STONE_DARK := Color("#6e6a63")
const _GOLD := Color("#ffcf3a")
const _GLASS := Color("#9fd4ff")
const _OUTLINE := Color("#1a1016")

## Where the stage lies on the canvas, and how much it is scaled (for the
## pictures which set their own transform, see [method _square]).
static var _origin := Vector2.ZERO
static var _scale := 1.0


## Draw the house into the rectangle, with the stages of the parts by their id
## (0 to 5 each), at the time (for the smoke, the water and the glow).
static func draw(canvas: CanvasItem, rect: Rect2, stages: Dictionary, time: float) -> void:
    var k := minf(rect.size.x / W, rect.size.y / H)
    var origin := rect.position + (rect.size - Vector2(W, H) * k) * 0.5
    _origin = origin
    _scale = k
    canvas.draw_set_transform(origin, 0.0, Vector2(k, k))
    var s := func(id: String) -> int: return int(stages.get(id, 0))

    # The sky and the hills.
    Art._rounded(canvas, Rect2(0, 0, W, H).grow(6.0), 30.0, _OUTLINE)
    Art._rounded(canvas, Rect2(0, 0, W, H), 26.0, Color("#9fd2f0"))
    canvas.draw_circle(Vector2(1080, 80), 42.0, Color("#fff2b0"))
    _ellipse(canvas, Vector2(300, GROUND + 30), Vector2(420, 120), Color("#79b85a"))
    _ellipse(canvas, Vector2(950, GROUND + 40), Vector2(480, 110), Color("#6aa84e"))
    Art._rounded(canvas, Rect2(0, GROUND, W, H - GROUND), 26.0, Color("#5c9c45"))
    canvas.draw_rect(Rect2(0, GROUND, W, 30), Color("#5c9c45"))

    _mine_entrance(canvas, s.call("mine"), time)
    _tower(canvas, s.call("tower"), time)
    _chimney(canvas, s.call("chimney"), time)
    _roof(canvas, s.call("roof"))
    _walls(canvas, s.call("walls"))
    _windows(canvas, s.call("windows"))
    _door(canvas, s.call("door"))
    _garden(canvas, s.call("garden"), time)
    _square(canvas, s.call("square"), time)
    _fence(canvas, s.call("fence"))

    canvas.draw_set_transform(Vector2.ZERO)


## A filled ellipse, cut to the stage, so that the hills stay in the picture.
static func _ellipse(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for k in range(32):
        var a := TAU * k / 32.0
        points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
    var stage := PackedVector2Array([Vector2.ZERO, Vector2(W, 0), Vector2(W, H), Vector2(0, H)])
    for part in Geometry2D.intersect_polygons(points, stage):
        canvas.draw_colored_polygon(part, color)


static func _box(canvas: CanvasItem, rect: Rect2, color: Color, outline := 4.0) -> void:
    canvas.draw_rect(rect.grow(outline * 0.5), _OUTLINE)
    canvas.draw_rect(rect, color)


static func _poly(canvas: CanvasItem, points: Array, color: Color) -> void:
    var packed := PackedVector2Array(points)
    canvas.draw_colored_polygon(packed, color)
    packed.append(packed[0])
    canvas.draw_polyline(packed, _OUTLINE, 4.0)


## The mine entrance in the hill on the left: a dark hole, then timber props,
## rails, a cart full of gems, lanterns and a gate studded with gems.
static func _mine_entrance(canvas: CanvasItem, stage: int, time: float) -> void:
    _ellipse(canvas, Vector2(150, GROUND), Vector2(170, 150), Color("#8a6a4a"))
    _ellipse(canvas, Vector2(150, GROUND), Vector2(150, 132), Color("#9a7a56"))
    var hole := Rect2(100, GROUND - 120, 100, 120)
    _ellipse(canvas, Vector2(150, GROUND - 70), Vector2(52, 60), Color("#1b1218"))
    canvas.draw_rect(Rect2(98, GROUND - 70, 104, 70), Color("#1b1218"))
    if stage >= 1:
        _box(canvas, Rect2(hole.position.x - 8, hole.position.y + 10, 16, 110), _WOOD)
        _box(canvas, Rect2(hole.end.x - 8, hole.position.y + 10, 16, 110), _WOOD)
        _box(canvas, Rect2(hole.position.x - 16, hole.position.y + 4, 132, 16), _WOOD_DARK)
    if stage >= 2:
        for x in [120.0, 180.0]:
            canvas.draw_line(Vector2(x, GROUND), Vector2(x + 140, GROUND + 60), _STONE_DARK, 6.0)
        for k in range(5):
            var t := k / 4.0
            canvas.draw_line(
                Vector2(116 + 140 * t, GROUND + 60 * t),
                Vector2(186 + 140 * t, GROUND + 60 * t),
                _WOOD_DARK,
                5.0
            )
    if stage >= 3:
        var cart := Rect2(220, GROUND + 4, 90, 44)
        _poly(
            canvas,
            [cart.position, cart.position + Vector2(90, 0), cart.end, cart.end - Vector2(90, 0)],
            Color("#6d7480")
        )
        canvas.draw_circle(cart.position + Vector2(20, 48), 11.0, _OUTLINE)
        canvas.draw_circle(cart.position + Vector2(70, 48), 11.0, _OUTLINE)
        for g in range(4):
            Art.gem(canvas, cart.position + Vector2(18 + g * 18, -6 - (g % 2) * 8), 12.0, g)
    if stage >= 4:
        for x in [80.0, 220.0]:
            canvas.draw_line(Vector2(x, GROUND - 130), Vector2(x, GROUND - 100), _OUTLINE, 4.0)
            var glow := 0.6 + 0.2 * sin(time * 5.0 + x)
            canvas.draw_circle(Vector2(x, GROUND - 92), 24.0, Color(1, 0.85, 0.4, 0.25 * glow))
            _box(canvas, Rect2(x - 9, GROUND - 104, 18, 22), Color(1, 0.85, 0.4, glow))
    if stage >= 5:
        canvas.draw_arc(Vector2(150, GROUND - 70), 70.0, PI, TAU, 24, _OUTLINE, 18.0)
        canvas.draw_arc(Vector2(150, GROUND - 70), 70.0, PI, TAU, 24, _GOLD, 12.0)
        for g in range(7):
            var a := PI + g * PI / 6.0
            Art.gem(canvas, Vector2(150, GROUND - 70) + Vector2.from_angle(a) * 70.0, 11.0, g)


## The house itself: a shack of grey planks, then logs, a timber frame, stone,
## carved stone, and marble with gold.
static func _walls(canvas: CanvasItem, stage: int) -> void:
    var walls := Rect2(420, 260, 360, GROUND - 260)
    var colors := [
        Color("#8c8378"),
        Color("#9a6438"),
        Color("#efe2c4"),
        _STONE,
        Color("#c9bfa8"),
        Color("#f4f0ea"),
    ]
    _box(canvas, walls, colors[stage])
    match stage:
        0:
            for x in range(int(walls.position.x) + 30, int(walls.end.x), 45):
                canvas.draw_line(
                    Vector2(x, walls.position.y), Vector2(x, walls.end.y), Color("#6e665c"), 3.0
                )
            canvas.draw_line(
                walls.position + Vector2(40, 60), walls.position + Vector2(110, 52), _WOOD_DARK, 6.0
            )
        1:
            for y in range(int(walls.position.y) + 22, int(walls.end.y), 26):
                canvas.draw_line(
                    Vector2(walls.position.x, y), Vector2(walls.end.x, y), _WOOD_DARK, 4.0
                )
        2:
            for x in [walls.position.x + 8, walls.get_center().x, walls.end.x - 8]:
                canvas.draw_line(
                    Vector2(x, walls.position.y), Vector2(x, walls.end.y), _WOOD_DARK, 14.0
                )
            canvas.draw_line(
                Vector2(walls.position.x, walls.position.y + 8),
                Vector2(walls.end.x, walls.position.y + 8),
                _WOOD_DARK,
                14.0
            )
            canvas.draw_line(walls.position, walls.position + Vector2(90, 90), _WOOD_DARK, 10.0)
            canvas.draw_line(
                Vector2(walls.end.x, walls.position.y),
                Vector2(walls.end.x - 90, walls.position.y + 90),
                _WOOD_DARK,
                10.0
            )
        3, 4:
            var row := 0
            for y in range(int(walls.position.y), int(walls.end.y), 30):
                var shift := 30 if row % 2 == 1 else 0
                canvas.draw_line(
                    Vector2(walls.position.x, y), Vector2(walls.end.x, y), _STONE_DARK, 3.0
                )
                for x in range(int(walls.position.x) + shift, int(walls.end.x), 60):
                    canvas.draw_line(
                        Vector2(x, y), Vector2(x, minf(y + 30, walls.end.y)), _STONE_DARK, 3.0
                    )
                row += 1
            if stage == 4:
                for x in [walls.position.x + 20, walls.end.x - 20]:
                    _box(
                        canvas, Rect2(x - 14, walls.position.y, 28, walls.size.y), Color("#ddd4bf")
                    )
        5:
            for x in [walls.position.x + 20, walls.end.x - 20]:
                _box(canvas, Rect2(x - 16, walls.position.y, 32, walls.size.y), Color("#ffffff"))
                canvas.draw_rect(Rect2(x - 20, walls.position.y, 40, 12), _GOLD)
                canvas.draw_rect(Rect2(x - 20, walls.end.y - 12, 40, 12), _GOLD)
            canvas.draw_rect(Rect2(walls.position.x, walls.position.y, walls.size.x, 10), _GOLD)


## The roof: planks with holes, straw, wooden shingles, red tiles, slate with a
## dormer, and gold.
static func _roof(canvas: CanvasItem, stage: int) -> void:
    var left := Vector2(392, 268)
    var right := Vector2(808, 268)
    var apex := Vector2(600, 120)
    var colors := [
        Color("#7a7268"),
        Color("#e2c068"),
        Color("#9a6a3c"),
        Color("#c0503a"),
        Color("#4e5a6e"),
        _GOLD
    ]
    _poly(canvas, [left, apex, right], colors[stage])
    var lines := 5
    for k in range(1, lines):
        var t := float(k) / lines
        var a := apex.lerp(left, t)
        var b := apex.lerp(right, t)
        var color: Color = colors[stage].darkened(0.25)
        canvas.draw_line(a, b, color, 4.0 if stage != 1 else 2.0)
        if stage == 1:
            for j in range(12):
                var at := a.lerp(b, j / 11.0)
                canvas.draw_line(at, at + Vector2(0, 14), color, 2.0)
        elif stage in [2, 3, 4]:
            for j in range(1, 8):
                var at := a.lerp(b, j / 8.0)
                canvas.draw_line(at, at + Vector2(0, (right.y - apex.y) / lines), color, 3.0)
    if stage == 0:
        _poly(
            canvas,
            [Vector2(500, 210), Vector2(560, 200), Vector2(555, 240), Vector2(505, 236)],
            Color("#5a5048")
        )
    if stage >= 4:
        # A dormer, and on the golden roof its shine.
        _poly(
            canvas,
            [Vector2(640, 230), Vector2(675, 196), Vector2(710, 230)],
            colors[stage].darkened(0.1)
        )
        _box(canvas, Rect2(648, 230, 54, 34), Color("#efe2c4"))
        _box(canvas, Rect2(662, 236, 26, 24), _GLASS)
    if stage == 5:
        canvas.draw_line(apex + Vector2(-60, 60), apex + Vector2(-20, 20), Color(1, 1, 1, 0.7), 6.0)
        Art._star(canvas, apex + Vector2(0, -16), 18.0, _GOLD)


## The door: a dark hole with a curtain, planks, oak, iron bands, an arched
## gate, and gems.
static func _door(canvas: CanvasItem, stage: int) -> void:
    var door := Rect2(565, 340, 70, 100)
    if stage >= 4:
        door = Rect2(555, 320, 90, 120)
    var colors := [
        Color("#6a4a7a"),
        _WOOD,
        Color("#6e4424"),
        Color("#6e4424"),
        Color("#5a3a22"),
        Color("#5a3a22")
    ]
    if stage >= 4:
        Art._ellipse(
            canvas,
            Vector2(door.get_center().x, door.position.y + 2),
            Vector2(door.size.x * 0.5 + 2, 32),
            _OUTLINE,
            0.0
        )
        Art._ellipse(
            canvas,
            Vector2(door.get_center().x, door.position.y + 2),
            Vector2(door.size.x * 0.5 - 2, 28),
            colors[stage],
            0.0
        )
    _box(canvas, door, colors[stage])
    match stage:
        0:
            for k in range(4):
                var x := door.position.x + 10 + k * 17
                canvas.draw_line(
                    Vector2(x, door.position.y),
                    Vector2(x + 4 * sin(k), door.end.y),
                    Color("#4e345a"),
                    3.0
                )
        1, 2:
            for k in range(1, 4):
                var x := door.position.x + k * door.size.x / 4.0
                canvas.draw_line(
                    Vector2(x, door.position.y), Vector2(x, door.end.y), _WOOD_DARK, 3.0
                )
    if stage >= 2:
        canvas.draw_circle(
            door.position + Vector2(door.size.x - 14, door.size.y * 0.55), 6.0, _GOLD
        )
    if stage >= 3:
        for y in [door.position.y + 22, door.end.y - 24]:
            canvas.draw_rect(Rect2(door.position.x, y, door.size.x, 10), Color("#4a4f58"))
    if stage >= 5:
        for g in range(5):
            Art.gem(canvas, door.position + Vector2(18 + (g % 3) * 27, 50 + (g / 3) * 34), 9.0, g)


## The windows beside the door: holes, shutters, glass, flower boxes, stained
## glass, and a rose window in the gable.
static func _windows(canvas: CanvasItem, stage: int) -> void:
    for x in [450.0, 680.0]:
        var window := Rect2(x, 300, 70, 70)
        if stage == 0:
            _box(canvas, window, Color("#1b1218"))
            continue
        if stage >= 3:
            var box := Rect2(window.position.x - 8, window.end.y, window.size.x + 16, 16)
            _box(canvas, box, _WOOD)
            for f in range(5):
                var at := Vector2(box.position.x + 10 + f * 15, box.position.y - 4)
                canvas.draw_circle(
                    at, 7.0, [Color("#ff6a8a"), Color("#ffd23e"), Color("#ffffff")][f % 3]
                )
        if stage == 1:
            _box(canvas, window, Color("#1b1218"))
            _box(canvas, Rect2(window.position - Vector2(30, 0), Vector2(30, 70)), Color("#4a7a3a"))
            _box(canvas, Rect2(window.end.x, window.position.y, 30, 70), Color("#4a7a3a"))
            continue
        if stage >= 4:
            _box(canvas, window, _GLASS)
            var quarters := [Color("#ff6a6a"), Color("#6aa0ff"), Color("#ffd23e"), Color("#7cf04f")]
            for q in range(4):
                canvas.draw_rect(
                    Rect2(window.position + Vector2((q % 2) * 35, (q / 2) * 35), Vector2(35, 35)),
                    Color(quarters[q], 0.8)
                )
        else:
            _box(canvas, window, _GLASS)
            canvas.draw_line(
                Vector2(window.position.x, window.position.y + 20),
                Vector2(window.end.x, window.position.y + 6),
                Color(1, 1, 1, 0.6),
                4.0
            )
        canvas.draw_line(
            Vector2(window.get_center().x, window.position.y),
            Vector2(window.get_center().x, window.end.y),
            _WOOD_DARK,
            5.0
        )
        canvas.draw_line(
            Vector2(window.position.x, window.get_center().y),
            Vector2(window.end.x, window.get_center().y),
            _WOOD_DARK,
            5.0
        )
    if stage >= 5:
        var rose := Vector2(600, 214)
        canvas.draw_circle(rose, 34.0, _OUTLINE)
        for k in range(8):
            var a := k * TAU / 8.0
            canvas.draw_colored_polygon(
                PackedVector2Array(
                    [
                        rose,
                        rose + Vector2.from_angle(a) * 30.0,
                        rose + Vector2.from_angle(a + TAU / 8.0) * 30.0
                    ]
                ),
                Art.GEM_COLORS[k % 4]
            )
        canvas.draw_circle(rose, 8.0, _GOLD)


## The chimney on the right of the roof: none, a clay pipe, bricks, stone with
## smoke, two of them, and the chimney of a forge with sparks.
static func _chimney(canvas: CanvasItem, stage: int, time: float) -> void:
    if stage == 0:
        return
    var xs := [700.0]
    if stage >= 4:
        xs = [480.0, 700.0]
    for x in xs:
        var width := 22.0 if stage == 1 else 46.0
        var top := 150.0 if stage >= 3 else 170.0
        var rect := Rect2(x, top, width, 120)
        var color: Color = [
            Color("#c07a4a"), Color("#c07a4a"), Color("#a84a32"), _STONE, _STONE, Color("#3a3036")
        ][stage]
        _box(canvas, rect, color)
        if stage == 2:
            for y in range(int(top) + 14, int(top) + 120, 16):
                canvas.draw_line(Vector2(x, y), Vector2(x + width, y), color.darkened(0.3), 2.0)
        if stage >= 2:
            _box(canvas, Rect2(x - 6, top - 10, width + 12, 14), color.darkened(0.2))
        if stage >= 3:
            for k in range(4):
                var t := fmod(time * 0.4 + k * 0.25, 1.0)
                var at := Vector2(x + width * 0.5 + sin(t * 6.0 + k) * 14.0, top - 20 - t * 110)
                canvas.draw_circle(at, 12.0 + t * 20.0, Color(0.85, 0.85, 0.9, 0.55 * (1.0 - t)))
        if stage >= 5:
            for k in range(6):
                var t := fmod(time * 0.9 + k / 6.0, 1.0)
                canvas.draw_circle(
                    Vector2(x + width * 0.5 + sin(k * 2.3) * 30.0 * t, top - 10 - t * 80),
                    4.0,
                    Color(1.0, 0.7, 0.2, 1.0 - t)
                )


## The tower right of the house: a lookout post on stilts, a stone tower, its
## flag, a clock, and a glowing crystal spire.
static func _tower(canvas: CanvasItem, stage: int, time: float) -> void:
    if stage == 0:
        return
    var x := 800.0
    if stage == 1:
        for leg in [x + 10, x + 80]:
            _box(canvas, Rect2(leg, 230, 12, GROUND - 230), _WOOD)
        _box(canvas, Rect2(x - 4, 220, 110, 16), _WOOD_DARK)
        _poly(
            canvas,
            [Vector2(x - 4, 220), Vector2(x + 51, 170), Vector2(x + 106, 220)],
            Color("#e2c068")
        )
        return
    var top := 150.0 if stage < 4 else 100.0
    var tower := Rect2(x, top, 110, GROUND - top)
    _box(canvas, tower, _STONE)
    for y in range(int(top) + 30, int(GROUND), 30):
        canvas.draw_line(Vector2(x, y), Vector2(x + 110, y), _STONE_DARK, 3.0)
    for k in range(4):
        _box(canvas, Rect2(x + k * 30 - 5, top - 22, 22, 24), _STONE)
    _box(canvas, Rect2(x + 40, top + 50, 30, 46), Color("#1b1218"))
    if stage >= 3:
        canvas.draw_line(Vector2(x + 55, top - 22), Vector2(x + 55, top - 110), _OUTLINE, 5.0)
        var wave := sin(time * 4.0) * 6.0
        _poly(
            canvas,
            [
                Vector2(x + 57, top - 108),
                Vector2(x + 117, top - 92 + wave),
                Vector2(x + 57, top - 74)
            ],
            Color("#b8452f")
        )
        Art._star(canvas, Vector2(x + 80, top - 92), 10.0, _GOLD)
    if stage >= 4:
        var clock := Vector2(x + 55, top + 130)
        canvas.draw_circle(clock, 30.0, _OUTLINE)
        canvas.draw_circle(clock, 26.0, Color("#fff8e0"))
        canvas.draw_line(
            clock, clock + Vector2.from_angle(time * 0.5 - PI / 2) * 18.0, _OUTLINE, 4.0
        )
        canvas.draw_line(
            clock, clock + Vector2.from_angle(time * 0.05 - PI / 2) * 12.0, _OUTLINE, 5.0
        )
    if stage >= 5:
        var glow := 0.6 + 0.3 * sin(time * 3.0)
        canvas.draw_circle(Vector2(x + 25, top - 70), 40.0, Color(0.6, 0.9, 1.0, 0.25 * glow))
        _poly(
            canvas,
            [Vector2(x + 8, top - 22), Vector2(x + 25, top - 120), Vector2(x + 42, top - 22)],
            Color(0.6, 0.95, 1.0, 0.9)
        )


## The garden left of the door: flowers, vegetable beds, mushrooms, a pond and
## a fountain (each new stage adds to the garden).
static func _garden(canvas: CanvasItem, stage: int, time: float) -> void:
    if stage >= 1:
        for k in range(7):
            var at := Vector2(300 + k * 16, GROUND - 6 - (k % 2) * 8)
            canvas.draw_line(at, at + Vector2(0, 14), Color("#3a7a2a"), 3.0)
            canvas.draw_circle(
                at, 7.0, [Color("#ff6a8a"), Color("#ffd23e"), Color("#b07aff")][k % 3]
            )
    if stage >= 2:
        _box(canvas, Rect2(296, GROUND + 14, 110, 26), Color("#6e4a2a"))
        for k in range(5):
            var at := Vector2(306 + k * 22, GROUND + 14)
            canvas.draw_circle(at, 7.0, Color("#ff8a2a") if k % 2 == 0 else Color("#4aa83a"))
    if stage >= 3:
        for k in range(3):
            var at := Vector2(1000 + k * 26, GROUND + 50 + (k % 2) * 6)
            canvas.draw_rect(Rect2(at - Vector2(4, 0), Vector2(8, 14)), Color("#f4e6d0"))
            Art._ellipse(canvas, at, Vector2(14, 9), Color("#d0402a"), 0.0)
            canvas.draw_circle(at + Vector2(-4, -3), 2.5, Color.WHITE)
    if stage >= 4:
        Art._ellipse(canvas, Vector2(880, GROUND + 52), Vector2(70, 18), _OUTLINE, 0.0)
        Art._ellipse(canvas, Vector2(880, GROUND + 52), Vector2(66, 15), Color("#4a9ee8"), 0.0)
        canvas.draw_line(
            Vector2(850 + sin(time) * 10, GROUND + 48),
            Vector2(880 + sin(time) * 10, GROUND + 48),
            Color(1, 1, 1, 0.6),
            3.0
        )
    if stage >= 5:
        var base := Vector2(880, GROUND + 46)
        _box(canvas, Rect2(base - Vector2(10, 46), Vector2(20, 46)), _STONE)
        for k in range(6):
            var t := fmod(time * 1.2 + k / 6.0, 1.0)
            var side := 1.0 if k % 2 == 0 else -1.0
            canvas.draw_circle(
                base + Vector2(side * 40 * t, -50 + 160 * (t - 0.4) * (t - 0.4) - 25),
                5.0,
                Color(0.6, 0.85, 1.0, 1.0 - t)
            )


## The fence along the front: sticks, pickets, a stone wall, iron, and a hedge
## with arches.
static func _fence(canvas: CanvasItem, stage: int) -> void:
    if stage == 0:
        return
    var y := GROUND + 70
    var from := 400.0
    var to := 800.0
    match stage:
        1:
            for x in range(int(from), int(to), 34):
                canvas.draw_line(Vector2(x, y), Vector2(x + 3, y - 40), _WOOD_DARK, 5.0)
            canvas.draw_line(Vector2(from, y - 24), Vector2(to, y - 20), _WOOD_DARK, 4.0)
        2:
            canvas.draw_line(Vector2(from, y - 26), Vector2(to, y - 26), _OUTLINE, 10.0)
            canvas.draw_line(Vector2(from, y - 26), Vector2(to, y - 26), Color.WHITE, 6.0)
            for x in range(int(from), int(to), 30):
                _poly(
                    canvas,
                    [
                        Vector2(x, y),
                        Vector2(x, y - 40),
                        Vector2(x + 8, y - 50),
                        Vector2(x + 16, y - 40),
                        Vector2(x + 16, y)
                    ],
                    Color.WHITE
                )
        3:
            for x in range(int(from), int(to), 40):
                _box(canvas, Rect2(x, y - 34, 40, 34), _STONE)
        4:
            canvas.draw_line(Vector2(from, y - 36), Vector2(to, y - 36), _OUTLINE, 6.0)
            for x in range(int(from), int(to), 22):
                canvas.draw_line(Vector2(x, y), Vector2(x, y - 48), _OUTLINE, 5.0)
                canvas.draw_colored_polygon(
                    PackedVector2Array(
                        [Vector2(x - 6, y - 46), Vector2(x, y - 58), Vector2(x + 6, y - 46)]
                    ),
                    _GOLD
                )
        5:
            for x in range(int(from), int(to), 60):
                Art._ellipse(canvas, Vector2(x + 30, y - 22), Vector2(34, 26), _OUTLINE, 0.0)
                Art._ellipse(
                    canvas, Vector2(x + 30, y - 22), Vector2(31, 23), Color("#3f8a3a"), 0.0
                )
                canvas.draw_circle(Vector2(x + 20, y - 30), 4.0, Color("#ff6a8a"))
            for x in [470.0, 730.0]:
                canvas.draw_arc(Vector2(x, y - 30), 50.0, PI, TAU, 16, _OUTLINE, 18.0)
                canvas.draw_arc(Vector2(x, y - 30), 50.0, PI, TAU, 16, Color("#3f8a3a"), 13.0)


## The village square on the right: a bench, a market stall, a well, a
## bandstand and a golden statue of the miners (each new stage adds to it).
static func _square(canvas: CanvasItem, stage: int, time: float) -> void:
    if stage >= 1:
        _box(canvas, Rect2(1030, GROUND + 10, 80, 12), _WOOD)
        for x in [1036.0, 1096.0]:
            _box(canvas, Rect2(x, GROUND + 22, 8, 18), _WOOD_DARK)
    if stage >= 2:
        _box(canvas, Rect2(1040, GROUND - 70, 120, 70), _WOOD)
        for k in range(4):
            _poly(
                canvas,
                [
                    Vector2(1030 + k * 35, GROUND - 70),
                    Vector2(1030 + k * 35 + 35, GROUND - 70),
                    Vector2(1030 + k * 35 + 35, GROUND - 100),
                    Vector2(1030 + k * 35, GROUND - 100)
                ],
                Color("#e8e0d0") if k % 2 == 0 else Color("#b8452f")
            )
        for k in range(3):
            Art.gem(canvas, Vector2(1066 + k * 34, GROUND - 46), 12.0, k)
    if stage >= 3:
        _box(canvas, Rect2(910, GROUND - 40, 60, 40), _STONE)
        canvas.draw_line(Vector2(914, GROUND - 40), Vector2(914, GROUND - 100), _WOOD_DARK, 6.0)
        canvas.draw_line(Vector2(966, GROUND - 40), Vector2(966, GROUND - 100), _WOOD_DARK, 6.0)
        _poly(
            canvas,
            [Vector2(900, GROUND - 96), Vector2(940, GROUND - 124), Vector2(980, GROUND - 96)],
            Color("#c0503a")
        )
    if stage >= 4:
        var bandstand := Rect2(1040, GROUND - 230, 120, 120)
        _poly(
            canvas,
            [
                Vector2(1030, bandstand.position.y),
                Vector2(1100, bandstand.position.y - 40),
                Vector2(1170, bandstand.position.y)
            ],
            Color("#4a7a3a")
        )
        for x in [1044.0, 1150.0]:
            _box(canvas, Rect2(x, bandstand.position.y, 8, 120), Color.WHITE)
        for k in range(3):
            var t := fmod(time * 0.5 + k / 3.0, 1.0)
            var at := Vector2(1080 + k * 20 + sin(t * 6.0) * 8, bandstand.position.y + 70 - t * 60)
            canvas.draw_circle(at, 5.0, Color(_OUTLINE, 1.0 - t))
            canvas.draw_line(at, at + Vector2(4, -16), Color(_OUTLINE, 1.0 - t), 2.0)
    if stage >= 5:
        _box(canvas, Rect2(1120, GROUND + 6, 60, 34), _STONE)
        canvas.draw_circle(Vector2(1150, GROUND - 30), 44.0, Color(1, 0.85, 0.3, 0.15))
        # NOTE (mristin):
        # The dwarf sets its own transform and resets it after: we draw it in
        # the pixels of the canvas, and set the transform of the stage again.
        Art.dwarf(
            canvas,
            _origin + Vector2(1150, GROUND + 8) * _scale,
            70.0 * _scale,
            3,
            {"facing": -1, "time": 0.0}
        )
        canvas.draw_set_transform(_origin, 0.0, Vector2(_scale, _scale))
