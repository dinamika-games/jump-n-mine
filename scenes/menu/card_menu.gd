class_name CardMenu
extends Control

## A menu of big cards in a row, played with the body like the game: step left
## or right to point at a card (each head in the camera picture has its own
## helmet over the cards), and jump to press it. The mouse and the keys (Left,
## Right, Enter or Space, and Escape for "back") work, too.
##
## A card is a dictionary with "id", "title", and optionally "subtitle",
## "icon" (see [method _draw_icon]), "color" and "disabled".

signal chosen(id: String)

## A head must point at a card this long before its jump presses it, so that a
## player who jumps while stepping over does not press the wrong card.
const SETTLE := 0.3

## The heads are followed from this to this fraction of the camera picture.
const HEAD_RANGE := Vector2(0.15, 0.85)

## The shade over the title painting behind the menus, and the tint of the dim
## camera picture over it.
const _BACKDROP_SHADE := Color(0.06, 0.03, 0.1, 0.45)
const _BACKDROP_PICTURE_TINT := Color(1, 1, 1, 0.22)

var title := ""
var subtitle := ""
var hint := "Step left or right to choose, and jump to press!"
## Draw the cave and the camera picture behind the cards (off for an overlay).
var background := true
var cards: Array[Dictionary] = []
## Where the cards start, as a fraction of the height of the screen.
var cards_top := 0.36
## How high the cards are, in pixels; low cards show only their titles.
var card_height := 420.0

## The card under the mouse or chosen with the keys, -1 for none.
var _focused := -1
## Per head id: "card" and "since" (seconds).
var _pointing := {}
var _pressed := -1
var _pressed_time := 0.0
var _time := 0.0
var _font: Font = ThemeDB.fallback_font


func _init() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
    var vision := get_node_or_null("/root/Vision")
    if vision != null:
        vision.head_jumped.connect(_on_head_jumped)


## Show the cards (see the class for their fields).
func set_cards(new_cards: Array[Dictionary]) -> void:
    cards = new_cards
    _focused = clampi(_focused, -1, cards.size() - 1)
    if _focused < 0 and not cards.is_empty():
        _focused = _first_enabled()
    queue_redraw()


## Press the card of the id, as if a player did (e.g., in the tests).
func press(id: String) -> void:
    for i in range(cards.size()):
        if cards[i]["id"] == id:
            _press(i)
            return
    push_error("There is no card %s in %s." % [id, cards.map(func(c): return c["id"])])


func _first_enabled() -> int:
    for i in range(cards.size()):
        if not cards[i].get("disabled", false):
            return i
    return -1


func _card_rect(i: int) -> Rect2:
    var n := maxi(1, cards.size())
    var margin := 60.0
    var gap := 30.0
    var width := minf(380.0, (size.x - 2 * margin - gap * (n - 1)) / n)
    var total := width * n + gap * (n - 1)
    var x := (size.x - total) / 2.0 + i * (width + gap)
    var grow := 1.0
    if i == _pressed:
        grow = 1.0 + 0.08 * maxf(0.0, 1.0 - _pressed_time * 4.0)
    var rect := Rect2(x, size.y * cards_top, width, card_height)
    return rect.grow(rect.size.x * (grow - 1.0) * 0.5)


func _card_at(point: Vector2) -> int:
    for i in range(cards.size()):
        if _card_rect(i).has_point(point):
            return i
    return -1


## The card a head points at, by where it stands in the picture.
func _card_of_head(position: Vector2) -> int:
    if cards.is_empty():
        return -1
    var x := clampf((position.x - HEAD_RANGE.x) / (HEAD_RANGE.y - HEAD_RANGE.x), 0.0, 0.999)
    return int(x * cards.size())


func _process(delta: float) -> void:
    _time += delta
    _pressed_time += delta
    var vision := get_node_or_null("/root/Vision")
    if vision != null:
        var seen := {}
        for id in vision.heads:
            seen[id] = true
            var card := _card_of_head(vision.heads[id]["position"])
            var pointing: Dictionary = _pointing.get(id, {"card": -1, "since": 0.0})
            if pointing["card"] != card:
                pointing = {"card": card, "since": 0.0}
                if card >= 0 and visible:
                    get_node("/root/Sounds").play("select")
            else:
                pointing["since"] = float(pointing["since"]) + delta
            _pointing[id] = pointing
        for id in _pointing.keys():
            if not seen.has(id):
                _pointing.erase(id)
    queue_redraw()


func _on_head_jumped(id: int, _strength: float) -> void:
    if not visible or not is_visible_in_tree():
        return
    var pointing: Dictionary = _pointing.get(id, {})
    if pointing.is_empty() or float(pointing["since"]) < SETTLE:
        return
    _press(int(pointing["card"]))


func _press(i: int) -> void:
    if i < 0 or i >= cards.size() or cards[i].get("disabled", false):
        return
    _pressed = i
    _pressed_time = 0.0
    get_node("/root/Sounds").play("click")
    chosen.emit(str(cards[i]["id"]))


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var i := _card_at(event.position)
        if i >= 0 and i != _focused:
            _focused = i
    elif (
        event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
    ):
        var i := _card_at(event.position)
        if i >= 0:
            _focused = i
            _press(i)
            accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
    if not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_LEFT, KEY_A:
            _move_focus(-1)
        KEY_RIGHT, KEY_D:
            _move_focus(1)
        KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
            _press(_focused)
        KEY_ESCAPE, KEY_BACKSPACE:
            for i in range(cards.size()):
                if cards[i]["id"] == "back":
                    _press(i)
                    break
        _:
            return
    get_viewport().set_input_as_handled()


func _move_focus(step: int) -> void:
    if cards.is_empty():
        return
    var i := _focused
    for attempt in range(cards.size()):
        i = posmod(i + step, cards.size())
        if not cards[i].get("disabled", false):
            _focused = i
            get_node("/root/Sounds").play("select")
            return


func _draw() -> void:
    if background:
        draw_backdrop(self, size)
    else:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.03, 0.06, 0.72))

    _text(title, Vector2(size.x / 2.0, 150.0), 84, Color("#ffe2a0"), true)
    if subtitle != "":
        _text(subtitle, Vector2(size.x / 2.0, 235.0), 36, Color("#f4e6d0"), false)

    var pointed := {}
    for id in _pointing:
        pointed[int(_pointing[id]["card"])] = true

    for i in range(cards.size()):
        _draw_card(i, i == _focused or pointed.has(i))

    _draw_heads()

    _text(hint, Vector2(size.x / 2.0, size.y - 60.0), 32, Color("#f4e6d0"), false)
    var vision := get_node_or_null("/root/Vision")
    if vision != null and vision.status() != "":
        _text(vision.status(), Vector2(size.x / 2.0, size.y - 22.0), 22, Color("#c8b8a8"), false)


## The cave behind the menus, with the camera picture dimly over it, mirrored.
static func draw_backdrop(canvas: CanvasItem, area: Vector2) -> void:
    # NOTE (mristin):
    # The title painting, darkened, so that the cards stand out.
    canvas.draw_texture_rect(Art.picture("title.png"), Rect2(Vector2.ZERO, area), false)
    canvas.draw_rect(Rect2(Vector2.ZERO, area), _BACKDROP_SHADE)
    var vision := canvas.get_node_or_null("/root/Vision")
    if vision == null:
        return
    var texture: Texture2D = vision.preview()
    if texture == null:
        return
    # NOTE (mristin):
    # The camera picture, dim and mirrored, so that the players see themselves
    # behind the cards, each with a miner's helmet in the color of her helmet
    # marker over the cards.
    var ratio := texture.get_size().x / maxf(1.0, texture.get_size().y)
    var picture := Rect2((area.x - area.y * ratio) / 2.0, 0, area.y * ratio, area.y)
    canvas.draw_set_transform(Vector2(area.x, 0), 0.0, Vector2(-1, 1))
    canvas.draw_texture_rect(
        texture,
        Rect2(area.x - picture.end.x, 0, picture.size.x, picture.size.y),
        false,
        _BACKDROP_PICTURE_TINT
    )
    canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    # NOTE (mristin):
    # The faces are painted again over the helmets, with all that lies under
    # them: the title painting, the shade and the camera picture.
    var layers := [
        {"texture": Art.picture("title.png"), "rect": Rect2(Vector2.ZERO, area)},
        {"color": _BACKDROP_SHADE},
        {"texture": texture, "rect": picture, "flip": true, "color": _BACKDROP_PICTURE_TINT},
    ]
    var face := func(outline: PackedVector2Array) -> void: Art.camera_face(canvas, outline, layers)
    var order: Array[int] = vision.ids_from_left()
    var time := Time.get_ticks_msec() / 1000.0
    for rank in range(order.size()):
        var head: Dictionary = vision.heads[order[rank]]
        var position: Vector2 = head["position"]
        var size: float = head["size"] * picture.size.y
        var top := picture.position + position * picture.size - Vector2(0, size * 0.5)
        var line: float = head.get("jump_line", NAN)
        if not is_nan(line):
            var center_x := picture.position.x + position.x * picture.size.x
            Art.jump_line(
                canvas,
                picture.position.y + line * picture.size.y,
                maxf(0.0, center_x - size * 1.4),
                minf(area.x, center_x + size * 1.4),
                bool(head.get("jumping", false)),
                10.0
            )
        Art.miner_hat(canvas, top, size, rank, time + rank, head.get("roll", 0.0), face)


func _draw_card(i: int, focused: bool) -> void:
    var card := cards[i]
    var rect := _card_rect(i)
    var disabled: bool = card.get("disabled", false)
    var color: Color = card.get("color", Color("#5a3d6e"))
    if disabled:
        color = Color("#3a3440")
    var lift := -12.0 if focused and not disabled else 0.0
    rect.position.y += lift
    # The shadow, rounded like the card.
    Art._rounded(
        self, Rect2(rect.position + Vector2(0, 10), rect.size).grow(4.0), 26.0, Color(0, 0, 0, 0.35)
    )
    Art._rounded(
        self, rect.grow(4.0), 26.0, Color("#ffe2a0") if focused and not disabled else Art.OUTLINE
    )
    Art._rounded(self, rect, 22.0, color)
    var text_color := Color("#8a8090") if disabled else Color.WHITE
    if rect.size.y < 300.0:
        # NOTE (mristin):
        # A low card has only its title, on a lighter band inside the card.
        Art._rounded(self, rect.grow(-10.0), 16.0, color.lightened(0.12))
        _text_wrapped(
            str(card["title"]),
            Rect2(
                rect.position.x + 12,
                rect.position.y + rect.size.y * 0.3,
                rect.size.x - 24,
                rect.size.y * 0.5
            ),
            40,
            text_color
        )
        return
    Art._rounded(
        self,
        Rect2(rect.position + Vector2(10, 10), Vector2(rect.size.x - 20, 200)),
        16.0,
        color.lightened(0.12)
    )
    _draw_icon(
        str(card.get("icon", "")), rect.position + Vector2(rect.size.x / 2.0, 115.0), disabled
    )
    _text_wrapped(
        str(card["title"]),
        Rect2(rect.position.x + 12, rect.position.y + 230, rect.size.x - 24, 100),
        38,
        text_color
    )
    if card.has("subtitle"):
        _text_wrapped(
            str(card["subtitle"]),
            Rect2(rect.position.x + 12, rect.position.y + 330, rect.size.x - 24, 80),
            26,
            text_color.darkened(0.1)
        )


func _draw_heads() -> void:
    var vision := get_node_or_null("/root/Vision")
    if vision == null:
        return
    var order: Array[int] = vision.ids_from_left()
    for rank in range(order.size()):
        var id := order[rank]
        if not _pointing.has(id):
            continue
        var card := int(_pointing[id]["card"])
        if card < 0 or card >= cards.size():
            continue
        var rect := _card_rect(card)
        var count := 0
        for other in order.slice(0, rank):
            if _pointing.has(other) and int(_pointing[other]["card"]) == card:
                count += 1
        var center := Vector2(rect.get_center().x + (count - 0.0) * 70.0, rect.position.y - 70.0)
        var rise: float = vision.heads[id].get("rise", 0.0)
        center.y -= clampf(rise, 0.0, 1.5) * 30.0
        var settle := clampf(float(_pointing[id]["since"]) / SETTLE, 0.0, 1.0)
        draw_circle(center, 34.0, Art.OUTLINE)
        draw_circle(center, 30.0, Dwarves.color(rank))
        draw_arc(center + Vector2(0, 6), 26.0, PI, TAU, 16, Art.STEEL, 18.0)
        draw_circle(center + Vector2(0, -16), 6.0, Color("#ffe65a"))
        if settle >= 1.0:
            _text("Jump!", center + Vector2(0, -52), 28, Color("#ffe2a0"), true)


## Draw an icon of the menus: "play", "new", "continue", "expedition",
## "dwarves:<n>", "world:<i>", "level:<i>", "lock", "trash", "back", "keep",
## "question", "quit", "again", "next", "levels", "ok".
func _draw_icon(icon: String, center: Vector2, disabled: bool) -> void:
    var parts := icon.split(":")
    var kind := parts[0]
    var argument := int(parts[1]) if parts.size() > 1 else 0
    var dim := Color(1, 1, 1, 0.35) if disabled else Color.WHITE
    match kind:
        "play", "continue", "next":
            Art.dwarf(
                self,
                center + Vector2(-30, 70),
                140.0,
                0,
                {
                    "facing": 1,
                    "time": _time,
                    "swing": fmod(_time, 1.2) / 1.2 if kind == "play" else 0.0
                }
            )
            if kind == "next":
                _arrow(center + Vector2(70, 0), 1, dim)
        "new":
            Art.dwarf(self, center + Vector2(0, 70), 140.0, 1, {"facing": 1, "time": _time})
            _text("+", center + Vector2(80, -30), 90, Color("#ffe2a0"), true)
        "expedition":
            Art.gem(self, center + Vector2(-50, 10), 30.0, 0)
            Art.gem(self, center + Vector2(0, -20), 36.0, 1)
            Art.gem(self, center + Vector2(50, 10), 30.0, 2)
        "dwarves":
            for k in range(argument):
                var x := (k - (argument - 1) / 2.0) * 62.0
                Art.dwarf(self, center + Vector2(x, 75), 110.0, k, {"facing": 1, "time": _time + k})
        "world":
            var world: Dictionary = LevelCatalog.WORLDS[argument]
            var r := Rect2(center - Vector2(110, 80), Vector2(220, 160))
            draw_rect(r, world["cave"])
            for k in range(3):
                Art.block(
                    self,
                    Rect2(r.position + Vector2(k * 73, 87), Vector2(73, 73)),
                    argument,
                    Vector2i(k, argument),
                    0.0,
                    k == 1
                )
            if argument == 1:
                draw_rect(
                    Rect2(r.position + Vector2(0, 60), Vector2(220, 27)),
                    Color(0.25, 0.55, 0.95, 0.7)
                )
            if argument == 2:
                Art.dragon(self, center + Vector2(0, -35), 110.0, 1, _time, 0.5)
            if argument == 0:
                Art.dwarf(self, center + Vector2(0, 7), 80.0, 0, {"time": _time})
        "level":
            Art.block(
                self,
                Rect2(center - Vector2(60, 60), Vector2(120, 120)),
                int(LevelCatalog.LEVELS[argument]["world"]),
                Vector2i(argument, 1),
                float(argument % 4) / 4.0,
                false
            )
            _text(str(argument + 1), center + Vector2(0, 18), 64, Color.WHITE, true)
        "lock":
            draw_arc(center + Vector2(0, -20), 34.0, PI, TAU, 16, dim, 12.0)
            draw_rect(Rect2(center + Vector2(-48, -20), Vector2(96, 76)), Color("#8a8090"))
        "trash":
            draw_rect(Rect2(center + Vector2(-45, -40), Vector2(90, 100)), Color("#c8c0d0"))
            draw_rect(Rect2(center + Vector2(-58, -58), Vector2(116, 14)), Color("#c8c0d0"))
            for k in [-20, 0, 20]:
                draw_line(center + Vector2(k, -25), center + Vector2(k, 45), Color("#5a5060"), 6.0)
        "back":
            _arrow(center, -1, dim)
        "keep":
            draw_polyline(
                PackedVector2Array(
                    [center + Vector2(-50, 0), center + Vector2(-10, 40), center + Vector2(55, -45)]
                ),
                Color("#7cf04f"),
                18.0
            )
        "ok":
            draw_polyline(
                PackedVector2Array(
                    [center + Vector2(-50, 0), center + Vector2(-10, 40), center + Vector2(55, -45)]
                ),
                Color("#7cf04f"),
                18.0
            )
        "question":
            _text("?", center + Vector2(0, 40), 140, Color("#ffe2a0"), true)
        "quit":
            draw_line(center + Vector2(-45, -45), center + Vector2(45, 45), Color("#ff7060"), 18.0)
            draw_line(center + Vector2(45, -45), center + Vector2(-45, 45), Color("#ff7060"), 18.0)
        "again":
            draw_arc(center, 50.0, 0.3, TAU - 0.3, 24, Color("#ffe2a0"), 14.0)
            _arrow(center + Vector2(50, -15), 1, Color("#ffe2a0"), 0.5)
        "levels":
            for k in range(3):
                Art.block(
                    self,
                    Rect2(center + Vector2(-90 + k * 60, -30), Vector2(60, 60)),
                    0,
                    Vector2i(k, 9),
                    0.0,
                    false
                )
        "stars":
            for k in range(3):
                Art.score_star(self, center + Vector2((k - 1) * 70, 0), 30.0, k < argument)


func _arrow(center: Vector2, direction: int, color: Color, scale_by := 1.0) -> void:
    var s := 60.0 * scale_by
    draw_colored_polygon(
        PackedVector2Array(
            [
                center + Vector2(direction * s, 0),
                center + Vector2(-direction * s * 0.2, -s * 0.8),
                center + Vector2(-direction * s * 0.2, s * 0.8)
            ]
        ),
        color
    )
    draw_line(center - Vector2(direction * s, 0), center, color, s * 0.5)


func _text(text: String, center: Vector2, font_size: int, color: Color, outline: bool) -> void:
    var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
    var at := Vector2(center.x - width / 2.0, center.y)
    if outline:
        draw_string_outline(
            _font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, Art.OUTLINE
        )
    draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _text_wrapped(text: String, rect: Rect2, font_size: int, color: Color) -> void:
    var size_now := font_size
    while size_now > 16:
        var lines := _font.get_multiline_string_size(
            text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size_now
        )
        if lines.y <= rect.size.y:
            break
        size_now -= 2
    draw_multiline_string(
        _font,
        rect.position + Vector2(0, size_now),
        text,
        HORIZONTAL_ALIGNMENT_CENTER,
        rect.size.x,
        size_now,
        -1,
        color
    )
