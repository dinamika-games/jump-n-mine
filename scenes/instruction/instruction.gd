extends CardMenu

## How to play: a little mine where a dwarf does what a player in front of the
## camera does, one move after the other, with one short line each.

## The scenes of the animation: the line, and how long it shows.
const STEPS := [
    ["Step left and right: your dwarf walks with you.", 4.0],
    ["Jump! Your dwarf swings the pickaxe at the block below.", 5.0],
    ["Dig a step, then hop onto the next block to move sideways.", 5.0],
    ["Three or four hits break a block. Grab the gems!", 4.0],
    ["Green gas explodes: step away! Hammer the springs shut before the mine floods.", 5.0],
    ["Dragons spit fire from above: step aside! Find the treasure at the bottom.", 5.0],
]

var _clock := 0.0


func _ready() -> void:
    super()
    title = "How to play"
    hint = "Jump on the card to start!"
    cards_top = 0.8
    card_height = 130.0
    set_cards(
        [
            {"id": "go", "title": "Let's dig!", "color": Color("#b8452f")},
            {"id": "back", "title": "Back"},
        ]
    )
    chosen.connect(_on_chosen)


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
    _text(STEPS[step][0], Vector2(size.x / 2.0, 250.0), 40, Color("#f4e6d0"), false)

    # The player in front of the camera, on the left.
    var person := Vector2(480, 760)
    var jump := 0.0
    var lean := 0.0
    if step == 0:
        lean = sin(t * TAU) * 90.0
    elif step >= 1:
        jump = maxf(0.0, sin(t * TAU * 3.0)) * 60.0
        if step == 2:
            lean = 60.0 * clampf(t * 3.0, 0.0, 1.0)
    _person(person + Vector2(lean, -jump))

    # The dwarf in its little mine, on the right.
    var cell := 110.0
    var origin := Vector2(980, 380)
    draw_rect(Rect2(origin, Vector2(cell * 6, cell * 4)), Color("#241a33"))
    var damage := 0.0
    if step == 1 or step == 3:
        damage = clampf(floor(t * 3.0) / 4.0, 0.0, 0.75)
    for x in range(6):
        for y in range(2, 4):
            var rect := Rect2(origin + Vector2(x * cell, y * cell), Vector2(cell, cell))
            if step == 4 and x == 4 and y == 2:
                Art.gas_pocket(self, rect, 0, _clock)
            elif step == 4 and x == 5 and y == 3:
                Art.spring(self, rect, false, 0.0)
            elif step == 3 and x == 2 and y == 2 and t > 0.75:
                Art.gem(self, rect.get_center() - Vector2(0, t * 60.0), 24.0, 1)
            else:
                Art.block(
                    self, rect, 0, Vector2i(x, y), damage if x == 2 and y == 2 else 0.0, false
                )
    var side := Rect2(origin + Vector2(3 * cell, cell), Vector2(cell, cell))
    var dwarf_x := origin.x + 2.5 * cell + (lean / 90.0) * cell * 0.9
    var feet_y := origin.y + 2 * cell - jump * 0.3
    if step == 2:
        # NOTE (mristin):
        # A step of one block: the dwarf walks against it, jumps and hops on.
        Art.block(self, side, 0, Vector2i(3, 1), 0.0, true)
        var hop := clampf((t - 0.4) * 2.5, 0.0, 1.0)
        dwarf_x = origin.x + (2.62 + hop) * cell
        feet_y = origin.y + 2 * cell - hop * cell - sin(hop * PI) * cell * 0.4
    var swing := 1.0 - fmod(t * 3.0, 1.0) if step >= 1 and step != 2 else 0.0
    Art.dwarf(
        self,
        Vector2(dwarf_x, feet_y),
        cell * 0.9,
        0,
        {"facing": 1, "time": _clock, "swing": swing, "swing_down": step != 2, "walking": step == 0}
    )
    if step == 5:
        Art.dragon(self, origin + Vector2(cell * 4.5, cell * 0.5), cell * 1.4, -1, _clock, t)
        Art.fire(self, origin + Vector2(cell * 4.5, cell * (0.8 + t * 1.2)), 22.0, _clock)
        Art.chest(self, origin + Vector2(cell * 0.6, cell * 2), cell * 0.8, _clock)


func _person(feet: Vector2) -> void:
    var color := Color("#f4e6d0")
    var head := feet + Vector2(0, -260)
    draw_circle(head, 34.0, color)
    draw_line(head + Vector2(0, 34), feet + Vector2(0, -110), color, 16.0)
    draw_line(feet + Vector2(0, -110), feet + Vector2(-40, 0), color, 14.0)
    draw_line(feet + Vector2(0, -110), feet + Vector2(40, 0), color, 14.0)
    draw_line(head + Vector2(0, 70), head + Vector2(-60, 140), color, 12.0)
    draw_line(head + Vector2(0, 70), head + Vector2(60, 140), color, 12.0)


func _on_chosen(id: String) -> void:
    if id == "go":
        get_node("/root/Session").saw_instruction()
        Flow.play(get_tree())
    else:
        Flow.go(get_tree(), Flow.INTRO)
