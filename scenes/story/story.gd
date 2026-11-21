extends CardMenu

## The story of the game, frame by frame: Queen Treacher wants to crush the
## miners, who fight for better lives for everybody and share the treasures of
## the earth with all the people; she sends her evil miners to find the
## treasures first, to buy weapons and start a war which would silence the
## people. Jump on Next (or wait) for the next frame, or Skip.
##
## The frames are the pictures assets/pictures/intro/frame_<n>.png, painted
## with an image generator from dev/pictures/prompts/intro.md; until they are
## there, the sketches frame_<n>.svg show.

## The captions of the frames.
const FRAMES := [
    (
        "Deep in the mountains, the miner dwarves dig for the treasures of the earth,"
        + " and share them with all the people."
    ),
    (
        "The people want better lives: fair work, warm bread and a school for every "
        + "child. The miners stand with them."
    ),
    (
        "But in her cold castle, Queen Treacher frowns. She wants to crush the miners and"
        + " silence the people."
    ),
    (
        "Her plan: grab the treasures, buy weapons and start a war, so that nobody asks "
        + "for a better life any more."
    ),
    (
        "She sends out her evil miners, with her black crown on their chests, to dig up "
        + "the treasures first."
    ),
    (
        "Now it is up to you! Jump to swing your pickaxe, be faster than Treacher's "
        + "miners, and bring the treasure to the people!"
    ),
]

## A frame shows this long before the next one comes by itself, in seconds.
const FRAME_TIME := 11.0

var _frame := 0
var _shown := 0.0
var _pictures: Array[Texture2D] = []


func _init() -> void:
    super()
    cards_top = 0.86
    card_height = 120.0
    hint = ""


func _ready() -> void:
    super()
    for k in range(FRAMES.size()):
        var base := "res://assets/pictures/intro/frame_%d" % (k + 1)
        var path := base + ".png" if ResourceLoader.exists(base + ".png") else base + ".svg"
        _pictures.append(load(path) if ResourceLoader.exists(path) else null)
    chosen.connect(_on_chosen)
    _show()


func _show() -> void:
    _shown = 0.0
    var last := _frame >= FRAMES.size() - 1
    set_cards(
        [
            {"id": "next", "title": "Let's dig!" if last else "Next", "color": Color("#b8452f")},
            {"id": "skip", "title": "Skip", "color": Color("#5a3d6e")},
        ]
    )


func _process(delta: float) -> void:
    super(delta)
    _shown += delta
    if _shown >= FRAME_TIME:
        _on_chosen("next")


func _on_chosen(id: String) -> void:
    if id == "next" and _frame < FRAMES.size() - 1:
        _frame += 1
        _show()
        return
    get_node("/root/Session").saw_story()
    Flow.play(get_tree())


func _draw_behind_cards() -> void:
    var area := size
    draw_rect(Rect2(Vector2.ZERO, area), Color("#120c14"))
    var picture: Texture2D = _pictures[_frame] if _frame < _pictures.size() else null
    if picture != null:
        # NOTE (mristin):
        # The picture covers the screen, and comes in slowly (Ken Burns).
        var zoom := 1.0 + 0.04 * _shown / FRAME_TIME
        var rect := Rect2(Vector2.ZERO, area).grow(area.x * (zoom - 1.0) * 0.5)
        var fade := clampf(_shown * 2.0, 0.0, 1.0)
        draw_texture_rect(picture, rect, false, Color(1, 1, 1, fade))
    var band := Rect2(0, area.y * 0.66, area.x, area.y * 0.34)
    draw_rect(band, Color(0.05, 0.03, 0.06, 0.78))
    _text_wrapped(
        FRAMES[_frame], Rect2(160, band.position.y + 24, area.x - 320, 150), 46, Color("#fff2d8")
    )
    for k in range(FRAMES.size()):
        var dot := Vector2(
            area.x / 2.0 + (k - (FRAMES.size() - 1) / 2.0) * 30.0, band.position.y + 12
        )
        draw_circle(dot, 8.0, Color("#ffe2a0") if k == _frame else Color(1, 1, 1, 0.3))
