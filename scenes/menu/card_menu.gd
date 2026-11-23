class_name CardMenu
extends Control

## A menu of big cards in a row, played with the body like the game: step left
## or right to point at a card (each player wears a helmet in the camera
## picture behind the cards, and its lamp shines on her card, see
## [CameraOverlay]), and jump to press it. The mouse and the keys (Left,
## Right, Enter or Space, and Escape for "back") work, too.
##
## A card is a dictionary with "id", "title", and optionally "subtitle",
## "icon" (see [method _draw_icon]), "color" and "disabled".

signal chosen(id: String)

## A head must point at a card this long before its jump presses it, so that a
## player who jumps while stepping over does not press the wrong card.
const SETTLE := 0.3

## A head points at the next card only once it is this far (in cards) beyond
## the edge of its card, for [constant STEP_HOLD] seconds, so that a jump or a
## sway near the edge does not move it to the next card (and makes it wait for
## [constant SETTLE] again).
const CARD_MARGIN := 0.25
const STEP_HOLD := 0.1

## The size of the painted icons on the cards (see assets/pictures/icons/).
const ICON_SIZE := 150.0

## The shade over the title painting behind the menus.
const _BACKDROP_SHADE := Color(0.06, 0.03, 0.1, 0.45)

## A jump presses a card only once the menu showed this long (in seconds), and
## only if the same head did not jump for this long before: the menu at the end
## of a level sets it, since the players are still digging when it comes up,
## and their next jump would otherwise press the card under them.
var calm := 0.0

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
## Per head id: "card", "since" (seconds) and "beyond" (how long the head is
## beyond the edge of its card, see [constant CARD_MARGIN]).
var _pointing := {}
var _pressed := -1
var _pressed_time := 0.0
var _time := 0.0
## Per head id: when (in [member _time]) it jumped the last time.
var _last_jump := {}
var _font: Font = ThemeDB.fallback_font
var _overlay := CameraOverlay.new()


func _init() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    _overlay.show_picture = false
    _overlay.target_of_head = _beam_target
    add_child(_overlay)


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


## Where a head stands across the cards, in cards (0 at the left edge of the
## first card).
func _cards_across(position: Vector2) -> float:
    return float(get_node("/root/Vision").across(position)) * cards.size()


## Where the beam of light of a head goes (see [CameraOverlay]): onto the card
## it points at.
func _beam_target(id: int, _slot: int) -> Variant:
    var card := int(_pointing.get(id, {}).get("card", -1))
    if card < 0 or card >= cards.size():
        return null
    var rect := _card_rect(card)
    return Vector3(rect.get_center().x, rect.position.y + rect.size.y * 0.35, rect.size.x * 0.8)


func _process(delta: float) -> void:
    _time += delta
    _pressed_time += delta
    var vision := get_node_or_null("/root/Vision")
    if vision != null:
        var seen := {}
        for id in vision.heads:
            seen[id] = true
            if cards.is_empty():
                continue
            var x := _cards_across(vision.heads[id]["position"])
            var pointing: Dictionary = _pointing.get(id, {})
            if pointing.is_empty() or int(pointing["card"]) >= cards.size():
                pointing = {
                    "card": clampi(int(x), 0, cards.size() - 1), "since": 0.0, "beyond": 0.0
                }
                if visible:
                    get_node("/root/Sounds").play("select")
            else:
                var card := int(pointing["card"])
                pointing["since"] = float(pointing["since"]) + delta
                if x < card - CARD_MARGIN or x > card + 1.0 + CARD_MARGIN:
                    pointing["beyond"] = float(pointing["beyond"]) + delta
                else:
                    pointing["beyond"] = 0.0
                if float(pointing["beyond"]) >= STEP_HOLD:
                    pointing = {
                        "card": clampi(int(x), 0, cards.size() - 1), "since": 0.0, "beyond": 0.0
                    }
                    if visible:
                        get_node("/root/Sounds").play("select")
            _pointing[id] = pointing
        for id in _pointing.keys():
            if not seen.has(id):
                _pointing.erase(id)

        # NOTE (mristin):
        # The players wear the colors of their helmet markers, from the left.
        _overlay.slot_of_head.clear()
        var order: Array[int] = vision.ids_from_left()
        for rank in range(order.size()):
            _overlay.slot_of_head[order[rank]] = rank
        if not cards.is_empty():
            _overlay.span = Vector2(_card_rect(0).position.x, _card_rect(cards.size() - 1).end.x)
        _overlay.anchor_y = size.y * cards_top * 0.62
    queue_redraw()


func _on_head_jumped(id: int, _strength: float) -> void:
    if not visible or not is_visible_in_tree():
        return
    var since_jump := _time - float(_last_jump.get(id, -INF))
    _last_jump[id] = _time
    if _time < calm or since_jump < calm:
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
    _overlay.draw_picture(self)
    _draw_behind_cards()

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


## Draw what a menu shows above its cards (e.g., the house), over the
## backdrop and under the cards.
func _draw_behind_cards() -> void:
    pass


## The cave behind the menus (the camera picture lies over it, see
## [CameraOverlay]).
static func draw_backdrop(canvas: CanvasItem, area: Vector2) -> void:
    # NOTE (mristin):
    # The title painting, darkened, so that the cards stand out.
    canvas.draw_texture_rect(Art.picture("title.png"), Rect2(Vector2.ZERO, area), false)
    canvas.draw_rect(Rect2(Vector2.ZERO, area), _BACKDROP_SHADE)


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
        # A low card has only its title, on a lighter band inside the card, and
        # its icon (if any) over the title.
        Art._rounded(self, rect.grow(-10.0), 16.0, color.lightened(0.12))
        if card.has("icon"):
            var box := Rect2(rect.position + Vector2(18, 16), Vector2(rect.size.x - 36, 100))
            _draw_icon(str(card["icon"]), box.get_center(), disabled, box.size)
            _text_wrapped(
                str(card["title"]),
                Rect2(rect.position.x + 12, rect.position.y + 122, rect.size.x - 24, 80),
                30,
                text_color
            )
            return
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


## "Jump!" over the cards which a head points at long enough to press them.
func _draw_heads() -> void:
    var shown := {}
    for id in _pointing:
        var card := int(_pointing[id]["card"])
        if card < 0 or card >= cards.size() or shown.has(card):
            continue
        if float(_pointing[id]["since"]) >= SETTLE:
            shown[card] = true
            var rect := _card_rect(card)
            _text(
                "Jump!",
                Vector2(rect.get_center().x, rect.position.y - 30.0),
                40,
                Color("#ffe2a0"),
                true
            )


## Draw an icon of the menus: "play", "new", "continue", "expedition",
## "dwarves:<n>", "world:<i>", "level:<i>", "lock", "trash", "back", "keep",
## "question", "quit", "again", "next", "levels", "ok", "booster:<kind>", "shop",
## "house", "house_stage:<part>:<stage>" (the painted piece of the stage of the
## part of the house, see [method HouseArt.stage_picture], as big as fits into
## the box), "story".
func _draw_icon(
    icon: String, center: Vector2, disabled: bool, box := Vector2(ICON_SIZE, ICON_SIZE)
) -> void:
    var parts := icon.split(":")
    var kind := parts[0]
    var argument := int(parts[1]) if parts.size() > 1 else 0
    var word := parts[1] if parts.size() > 1 else ""
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
                _painted_icon("next", center + Vector2(75, 10), ICON_SIZE * 0.6, dim)
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
        "lock", "trash", "back", "keep", "ok", "question", "quit", "again":
            _painted_icon("ok" if kind == "keep" else kind, center, ICON_SIZE, dim)
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
        "booster":
            draw_circle(center, 78.0, Color(1, 0.95, 0.5, 0.2 + 0.1 * sin(_time * 4.0)))
            Art.booster(self, center, 66.0, word)
        "shop":
            Art.booster(self, center + Vector2(-55, 10), 40.0, "gold_pick")
            Art.gem(self, center + Vector2(10, -20), 34.0, 1)
            Art.booster(self, center + Vector2(65, 15), 40.0, "helmet")
        "house":
            var session := get_node_or_null("/root/Session")
            HouseArt.draw(
                self,
                Rect2(center - Vector2(130, 70), Vector2(260, 150)),
                session.purse.house if session != null else {},
                _time
            )
        "house_stage":
            var path := HouseArt.stage_picture(argument, int(parts[2]) if parts.size() > 2 else 0)
            if path != "":
                var picture := Art.picture(path)
                var size := Vector2(picture.get_width(), picture.get_height())
                size *= minf(box.x / size.x, box.y / size.y)
                draw_texture_rect(picture, Rect2(center - size / 2.0, size), false, dim)
        "story":
            Art.dwarf(self, center + Vector2(-50, 70), 120.0, 0, {"facing": 1, "time": _time})
            Art.dwarf(
                self, center + Vector2(50, 70), 120.0, Mine.RIVAL, {"facing": -1, "time": _time}
            )
        "stars":
            for k in range(3):
                Art.score_star(self, center + Vector2((k - 1) * 70, 0), 30.0, k < argument)


## Draw the painted icon of the name (see assets/pictures/icons/), as big as the
## size, tinted by the color.
func _painted_icon(name: String, center: Vector2, size: float, color: Color) -> void:
    var rect := Rect2(center - Vector2(size, size) / 2.0, Vector2(size, size))
    draw_texture_rect(Art.picture("icons/%s.png" % name), rect, false, color)


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
