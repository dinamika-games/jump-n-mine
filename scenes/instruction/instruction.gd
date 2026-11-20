extends CardMenu

## How to play: on the left, a child in front of the camera, with the miner's
## helmet and the jump line as the game draws them over the camera picture; on
## the right, her dwarf in a little mine, doing what she does, one move after
## the other, with one short line each.

## The scenes of the animation: the line, and how long it shows.
const STEPS := [
    ["Step left and right: your dwarf walks with you.", 4.0],
    ["Jump! Your dwarf swings the pickaxe at the block below.", 5.0],
    ["Dig a step, then hop onto the next block to move sideways.", 5.0],
    ["Three or four hits break a block. Grab the gems!", 4.0],
    ["Green gas explodes: step away! Hammer the springs shut.", 5.0],
    ["Dragons spit fire from above: step aside! Find the treasure.", 5.0],
]

## The two panels: the player in front of the camera, and her dwarf.
const YOU := Rect2(150, 370, 640, 430)
const DWARF := Rect2(1130, 370, 640, 430)

## The size of a block in the little mine.
const CELL := 104.0

var _clock := 0.0
var _warning := EffectLayer.new("res://scenes/effects/warning.gdshader")


func _ready() -> void:
    super()
    title = "How to play"
    hint = "Jump on the card to start!"
    cards_top = 0.8
    card_height = 130.0
    set_cards(
        [
            {"id": "go", "title": "Let's dig!", "color": Color("#b8452f")},
            {"id": "back", "title": "Back", "color": Color("#5a3d6e")},
        ]
    )
    chosen.connect(_on_chosen)
    _warning.paint = _paint_warning
    add_child(_warning)


func _process(delta: float) -> void:
    super(delta)
    _clock += delta


func _step() -> Array:
    var total := 0.0
    for step in STEPS:
        total += float(step[1])
    var t := fmod(_clock, total)
    for i in range(STEPS.size()):
        if t < float(STEPS[i][1]):
            return [i, t / float(STEPS[i][1])]
        t -= float(STEPS[i][1])
    return [0, 0.0]


func _draw() -> void:
    super()
    var at := _step()
    var step: int = at[0]
    var t: float = at[1]
    subtitle = ""

    # The line of the step, on a band, with a dot for each step under it.
    var band := Rect2(size.x / 2.0 - 760.0, 196.0, 1520.0, 76.0)
    Art._rounded(self, band.grow(3.0), 20.0, Art.OUTLINE)
    Art._rounded(self, band, 18.0, Color(0.12, 0.08, 0.16, 0.85))
    _text(
        STEPS[step][0], Vector2(size.x / 2.0, band.position.y + 52.0), 40, Color("#ffe2a0"), false
    )
    for k in range(STEPS.size()):
        var dot := Vector2(size.x / 2.0 + (k - (STEPS.size() - 1) / 2.0) * 34.0, band.end.y + 16.0)
        draw_circle(dot, 9.0, Art.OUTLINE)
        draw_circle(dot, 7.0, Color("#ffe2a0") if k == step else Color("#5a4a60"))

    # What the player does: the jumps and the steps of the animation.
    var jump := 0.0
    var lean := 0.0
    if step == 0:
        lean = sin(t * TAU)
    elif step == 5:
        # Step aside from the dragon's fire.
        lean = -clampf((t - 0.15) * 5.0, 0.0, 1.0)
    elif step == 2:
        lean = clampf(t * 3.0, 0.0, 1.0) * 0.6
        jump = maxf(0.0, sin(clampf((t - 0.35) * 2.5, 0.0, 1.0) * PI))
    else:
        jump = maxf(0.0, sin(t * TAU * 3.0))

    _draw_you(lean, jump)
    _draw_arrow(Vector2((YOU.end.x + DWARF.position.x) / 2.0, YOU.get_center().y))
    _draw_mine(step, t, lean, jump)


## The panel of the player in front of the camera.
func _draw_you(lean: float, jump: float) -> void:
    _panel(YOU, "You")
    # A room behind the player, as the camera sees it.
    var wall := YOU.grow(-14.0)
    draw_rect(wall, Color("#4a3b52"))
    draw_rect(Rect2(wall.position.x, wall.end.y - 90.0, wall.size.x, 90.0), Color("#6b5240"))
    draw_rect(Rect2(wall.position.x + 40.0, wall.position.y + 40.0, 150.0, 110.0), Color("#7fb6d6"))
    draw_rect(
        Rect2(wall.position.x + 40.0, wall.position.y + 40.0, 150.0, 110.0), Art.OUTLINE, false, 6.0
    )

    var scale_by := 1.0
    var feet := Vector2(YOU.get_center().x + lean * 150.0, YOU.end.y - 36.0 - jump * 45.0)
    var head_r := 33.0 * scale_by
    var standing_head := Vector2(feet.x, YOU.end.y - 36.0 - 250.0)
    var head := feet + Vector2(0, -250.0)

    # The jump line, as the game draws it over the camera picture.
    var line_y := standing_head.y - head_r * 1.4
    Art.jump_line(self, line_y, feet.x - 150.0, feet.x + 150.0, jump > 0.5, 8.0)

    _child(feet, head, head_r, jump)
    Art.miner_hat(self, head - Vector2(0, head_r * 1.35), head_r * 2.7, 0, _clock)


## A child, seen from the front: arms up while she jumps.
func _child(feet: Vector2, head: Vector2, r: float, jump: float) -> void:
    var skin := Color("#f2c29b")
    var shirt := Color("#e04848")
    var pants := Color("#34507a")
    var hip := feet + Vector2(0, -108)
    var shoulder := head + Vector2(0, r + 30)
    var spread := 18.0 + jump * 22.0
    for side in [-1.0, 1.0]:
        var knee := hip + Vector2(side * (spread + 4.0), 62.0 - jump * 12.0)
        var foot := feet + Vector2(side * (spread + 8.0), 0)
        draw_line(hip + Vector2(side * 14.0, 0), knee, Art.OUTLINE, 30.0)
        draw_line(knee, foot, Art.OUTLINE, 30.0)
        draw_line(hip + Vector2(side * 14.0, 0), knee, pants, 24.0)
        draw_line(knee, foot, pants, 24.0)
        Art._rounded(
            self, Rect2(foot + Vector2(-18 + side * 6.0, -6), Vector2(36, 16)), 7.0, Art.OUTLINE
        )
        # The arms: down at the sides, up in a jump.
        var hand := shoulder + Vector2(side * (52.0 + jump * 18.0), 95.0 - jump * 190.0)
        var elbow := shoulder + Vector2(side * 46.0, 48.0 - jump * 100.0)
        draw_line(shoulder + Vector2(side * 30.0, 6), elbow, Art.OUTLINE, 24.0)
        draw_line(elbow, hand, Art.OUTLINE, 24.0)
        draw_line(shoulder + Vector2(side * 30.0, 6), elbow, shirt, 18.0)
        draw_line(elbow, hand, skin, 16.0)
        draw_circle(hand, 12.0, Art.OUTLINE)
        draw_circle(hand, 9.0, skin)
    var torso := Rect2(shoulder + Vector2(-42, -6), Vector2(84, hip.y - shoulder.y + 14))
    Art._rounded(self, torso.grow(3.0), 22.0, Art.OUTLINE)
    Art._rounded(self, torso, 20.0, shirt)
    draw_rect(Rect2(head + Vector2(-12, r - 6), Vector2(24, 26)), skin)
    draw_circle(head, r + 3.0, Art.OUTLINE)
    draw_circle(head, r, skin)
    # The hair, the eyes and a smile.
    draw_arc(head + Vector2(0, -4), r * 0.95, PI * 1.05, PI * 1.95, 16, Color("#7a4a2a"), r * 0.45)
    for side in [-1.0, 1.0]:
        draw_circle(head + Vector2(side * r * 0.36, r * 0.05), r * 0.11, Art.OUTLINE)
    draw_arc(head + Vector2(0, r * 0.25), r * 0.38, PI * 0.15, PI * 0.85, 10, Art.OUTLINE, 4.0)


## The panel of the dwarf in its little mine.
func _draw_mine(step: int, t: float, lean: float, jump: float) -> void:
    _panel(DWARF, "Your dwarf")
    var inner := DWARF.grow(-14.0)
    var cave: Texture2D = Art.picture("blocks/copper_hills/cave.png")
    draw_texture_rect_region(cave, inner, Rect2(Vector2(40, 60), inner.size * 0.9))
    var origin := inner.position + Vector2((inner.size.x - 5 * CELL) / 2.0, inner.size.y - 2 * CELL)

    var damage := 0.0
    if step == 1 or step == 3:
        damage = clampf(floor(t * 3.0) / 3.0, 0.0, 0.67)
    for x in range(5):
        for y in range(2):
            var rect := Rect2(origin + Vector2(x * CELL, y * CELL), Vector2(CELL, CELL))
            if step == 3 and x == 2 and y == 0 and t > 0.75:
                Art.gem(self, rect.get_center() - Vector2(0, (t - 0.75) * 400.0), 30.0, 1)
            elif step == 4 and x == 3 and y == 0:
                Art.gas_pocket(self, rect, 0, _clock)
            elif step == 4 and x == 0 and y == 0:
                Art.spring(self, rect, false, 0.0)
            else:
                Art.block(
                    self, rect, 0, Vector2i(x, y + 3), damage if x == 2 and y == 0 else 0.0, y == 1
                )

    var dwarf_x := origin.x + 2.5 * CELL + lean * CELL * 1.2
    var feet_y := origin.y - jump * CELL * 0.35
    if step == 2:
        # NOTE (mristin):
        # A step of one block: the dwarf walks against it, jumps and hops on.
        var side := Rect2(origin + Vector2(3 * CELL, -CELL), Vector2(CELL, CELL))
        Art.block(self, side, 0, Vector2i(3, 1), 0.0, true)
        var hop := clampf((t - 0.35) * 2.5, 0.0, 1.0)
        dwarf_x = origin.x + (2.62 + hop) * CELL
        feet_y = origin.y - hop * CELL - sin(hop * PI) * CELL * 0.45
    var swing := 1.0 - fmod(t * 3.0, 1.0) if step == 1 or step == 3 else 0.0
    (
        Art
        . dwarf(
            self,
            Vector2(dwarf_x, feet_y),
            CELL * 1.05,
            0,
            {
                "facing": -1 if step == 0 and cos(t * TAU) < 0.0 else 1,
                "time": _clock,
                "swing": swing,
                "walking": step == 0,
            }
        )
    )
    if step == 5:
        _draw_dragon(inner, origin, t)


## The dragon flies above the mine, a red glow shows where its fire will fall,
## the dwarf steps aside, and the fire falls where the dwarf stood.
func _draw_dragon(inner: Rect2, origin: Vector2, t: float) -> void:
    var column := origin.x + 2.5 * CELL
    # NOTE (mristin):
    # The dragon faces left; its mouth is over the column.
    var dragon := Vector2(column + 60.0, inner.position.y + 68.0)
    var spitting := 2.0 if t > 0.45 and t < 0.6 else clampf((t - 0.2) * 4.0, 0.0, 1.0)
    Art.dragon(self, dragon, 160.0, -1, _clock, spitting)
    if t > 0.45:
        var fall := clampf((t - 0.45) / 0.3, 0.0, 1.0)
        var y := lerpf(inner.position.y + 120.0, origin.y - 10.0, fall)
        if fall < 1.0:
            Art.fire(self, Vector2(column, y), 26.0, _clock)
        else:
            draw_circle(Vector2(column, origin.y - 10.0), 26.0, Color(1.0, 0.6, 0.2, 0.5))
    Art.chest(self, origin + Vector2(4.5 * CELL, 0), CELL * 0.9, _clock)


## The warning where the dragon's fire will fall, until it spits (see
## scenes/effects/warning.gdshader).
func _paint_warning(canvas: CanvasItem) -> void:
    var at := _step()
    if at[0] != 5 or float(at[1]) > 0.45:
        return
    var inner := DWARF.grow(-14.0)
    var origin := inner.position + Vector2((inner.size.x - 5 * CELL) / 2.0, inner.size.y - 2 * CELL)
    var column := origin.x + 2.5 * CELL
    var rect := Rect2(
        column - CELL * 0.75,
        inner.position.y + 110.0,
        CELL * 1.5,
        origin.y - inner.position.y - 80.0
    )
    var ground := (origin.y - rect.position.y) / rect.size.y
    var strength := clampf(float(at[1]) / 0.45, 0.2, 1.0)
    canvas.draw_texture_rect(_warning.white(), rect, false, Color(strength, 0.3, ground, 1.0))


func _panel(rect: Rect2, label: String) -> void:
    Art._rounded(
        self, Rect2(rect.position + Vector2(0, 10), rect.size).grow(6.0), 28.0, Color(0, 0, 0, 0.35)
    )
    Art._rounded(self, rect.grow(6.0), 28.0, Art.OUTLINE)
    Art._rounded(self, rect, 24.0, Color("#5a3d6e"))
    # The name of the panel, above it.
    var tag := Rect2(rect.position + Vector2(24, -64), Vector2(240, 50))
    Art._rounded(self, tag.grow(3.0), 16.0, Art.OUTLINE)
    Art._rounded(self, tag, 14.0, Color("#b8452f"))
    _text(label, tag.get_center() + Vector2(0, 13), 34, Color.WHITE, false)


func _draw_arrow(center: Vector2) -> void:
    var points := PackedVector2Array(
        [
            center + Vector2(-90, -24),
            center + Vector2(20, -24),
            center + Vector2(20, -60),
            center + Vector2(95, 0),
            center + Vector2(20, 60),
            center + Vector2(20, 24),
            center + Vector2(-90, 24),
        ]
    )
    var outline := points.duplicate()
    outline.append(outline[0])
    draw_colored_polygon(points, Color("#ffe2a0"))
    draw_polyline(outline, Art.OUTLINE, 6.0)


func _on_chosen(id: String) -> void:
    if id == "go":
        get_node("/root/Session").saw_instruction()
        Flow.play(get_tree())
    else:
        Flow.go(get_tree(), Flow.INTRO)
