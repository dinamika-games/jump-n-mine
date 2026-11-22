class_name Story
extends CardMenu

## The story of the game, frame by frame: Queen Treacher wants to crush the
## miners, who fight for better lives for everybody and share the treasures of
## the earth with all the people; she sends her evil miners to find the
## treasures first, to buy weapons and start a war which would silence the
## people.
##
## Like the opening of a film, the caption of each frame comes word by word,
## slowly enough for a child of ten to read along, and the next frame follows
## by itself. There are no buttons: a jump (or a key, or a click) skips the
## whole story.
##
## The frames are the pictures assets/pictures/intro/frame_<n>.png, painted
## with an image generator from dev/pictures/prompts/intro.md; until they are
## there, the sketches frame_<n>.svg show.

## The captions of the frames.
const FRAMES: Array[String] = [
    (
        "Deep in the mountains, the miner dwarves dig for the treasures of the earth,"
        + " and share them with all the people."
    ),
    (
        "The people want better lives: fair work, tasty bread and a school for every "
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

## The frames whose picture is shown smaller (by the frame index: the scale),
## at the top of the screen, since what matters lies low in the picture and
## the caption would cover it (the treasure in the last frame); the whole
## picture, darkened, fills the screen behind it.
const FIT := {5: 0.68}

## The seconds between two words of a caption: about 150 words a minute, as
## fast as a child of ten reads.
const WORD_TIME := 0.4

## The extra seconds after a word which ends with a comma (or a colon), and
## after a word which ends a sentence, as a reader pauses there.
const COMMA_PAUSE := 0.3
const SENTENCE_PAUSE := 0.6

## How long a word takes to fade in, in seconds.
const WORD_FADE := 0.3

## The seconds before the first word, while the picture fades in.
const LEAD_TIME := 1.0

## The seconds the whole caption stays before the next frame comes.
const HOLD_TIME := 3.0

## A jump right after the story starts does not skip it, since it is probably
## the jump which pressed Play.
const SKIP_GRACE := 1.0

## Where the band of the caption starts, as a fraction of the height.
const BAND_TOP := 0.7

var _frame := 0
## The seconds since the frame came.
var _shown := 0.0
## The seconds since the story started.
var _running := 0.0
var _done := false
var _pictures: Array[Texture2D] = []

## The words of the caption of the frame, and when each of them comes (in
## seconds since the frame came).
var _words: PackedStringArray = []
var _word_starts: Array[float] = []

## The layout of the caption, computed when it is drawn first: the font size,
## and the position of every word.
var _layout_frame := -1
var _layout_size := 0
var _word_positions: Array[Vector2] = []


func _init() -> void:
    super()
    hint = "Jump to skip the story"


func _ready() -> void:
    super()
    for k in range(FRAMES.size()):
        var base := "res://assets/pictures/intro/frame_%d" % (k + 1)
        var path := base + ".png" if ResourceLoader.exists(base + ".png") else base + ".svg"
        _pictures.append(load(path) if ResourceLoader.exists(path) else null)
    _show()


## Show the frame of the index from its start, or with its caption already
## written (e.g., for the screenshots).
func show_frame(index: int, written := false) -> void:
    _frame = clampi(index, 0, FRAMES.size() - 1)
    _show()
    if written:
        _shown = _caption_time()


## Skip the whole story, and go on to play.
func skip() -> void:
    if _done:
        return
    _done = true
    get_node("/root/Sounds").play("click")
    get_node("/root/Session").saw_story()
    Flow.play(get_tree())


func _show() -> void:
    _shown = 0.0
    _layout_frame = -1
    _words = FRAMES[_frame].split(" ", false)
    _word_starts.clear()
    var at := LEAD_TIME
    for word in _words:
        _word_starts.append(at)
        at += WORD_TIME
        if word.ends_with(".") or word.ends_with("!") or word.ends_with("?"):
            at += SENTENCE_PAUSE
        elif word.ends_with(",") or word.ends_with(":") or word.ends_with(";"):
            at += COMMA_PAUSE


## When the last word of the caption is fully there, in seconds since the
## frame came.
func _caption_time() -> float:
    return (_word_starts[-1] if not _word_starts.is_empty() else 0.0) + WORD_FADE


## How long the frame shows, in seconds.
func _frame_time() -> float:
    return _caption_time() + HOLD_TIME


func _process(delta: float) -> void:
    super(delta)
    _shown += delta
    _running += delta
    if _done or _shown < _frame_time():
        return
    if _frame < FRAMES.size() - 1:
        _frame += 1
        _show()
    else:
        _done = true
        get_node("/root/Session").saw_story()
        Flow.play(get_tree())


func _on_head_jumped(_id: int, _strength: float) -> void:
    if is_visible_in_tree() and _running >= SKIP_GRACE:
        skip()


func _unhandled_key_input(event: InputEvent) -> void:
    if not is_visible_in_tree() or not (event is InputEventKey) or not event.pressed or event.echo:
        return
    match event.keycode:
        KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE, KEY_BACKSPACE:
            skip()
            get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        skip()
        accept_event()


## Lay out the caption of the frame in the rectangle: the lines are centered,
## and the font gets smaller until they fit. The words keep their places
## while they come, so that the text does not jump.
func _lay_out(rect: Rect2) -> void:
    _layout_frame = _frame
    var space_width := 0.0
    var font_size := 52
    while true:
        space_width = _font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
        var lines: Array[Array] = [[]]
        var widths: Array[float] = [0.0]
        for i in range(_words.size()):
            var width := (
                _font.get_string_size(_words[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
            )
            var line_width: float = widths[-1]
            if not lines[-1].is_empty() and line_width + space_width + width > rect.size.x:
                lines.append([])
                widths.append(0.0)
                line_width = 0.0
            var x := line_width + (space_width if not lines[-1].is_empty() else 0.0)
            lines[-1].append([i, x])
            widths[-1] = x + width
        var line_height := font_size * 1.3
        if lines.size() * line_height <= rect.size.y or font_size <= 20:
            _layout_size = font_size
            _word_positions.resize(_words.size())
            for k in range(lines.size()):
                var left := rect.position.x + (rect.size.x - widths[k]) / 2.0
                var baseline := rect.position.y + font_size + k * line_height
                for entry in lines[k]:
                    _word_positions[int(entry[0])] = Vector2(left + float(entry[1]), baseline)
            return
        font_size -= 2


func _draw_behind_cards() -> void:
    var area := size
    draw_rect(Rect2(Vector2.ZERO, area), Color("#120c14"))
    var picture: Texture2D = _pictures[_frame] if _frame < _pictures.size() else null
    if picture != null:
        # NOTE (mristin):
        # The picture covers the screen, and comes in slowly (Ken Burns); it
        # fades in from the dark and out again before the next frame.
        var zoom := 1.0 + 0.04 * _shown / _frame_time()
        var rect := Rect2(Vector2.ZERO, area).grow(area.x * (zoom - 1.0) * 0.5)
        var fade := clampf(minf(_shown * 2.0, (_frame_time() - _shown) * 2.0), 0.0, 1.0)
        if FIT.has(_frame):
            draw_texture_rect(picture, rect, false, Color(0.3, 0.3, 0.3, fade))
            var fitted := area * float(FIT[_frame]) * zoom
            rect = Rect2(Vector2((area.x - fitted.x) / 2.0, area.y * 0.02), fitted)
            draw_rect(rect.grow(6.0), Color(Art.OUTLINE, fade))
        draw_texture_rect(picture, rect, false, Color(1, 1, 1, fade))
    var band := Rect2(0, area.y * BAND_TOP, area.x, area.y * (1.0 - BAND_TOP))
    draw_rect(band, Color(0.05, 0.03, 0.06, 0.78))

    var text_rect := Rect2(160, band.position.y + 40, area.x - 320, band.size.y - 130)
    if _layout_frame != _frame:
        _lay_out(text_rect)
    var color := Color("#fff2d8")
    for i in range(_words.size()):
        var alpha := clampf((_shown - _word_starts[i]) / WORD_FADE, 0.0, 1.0)
        if alpha <= 0.0:
            break
        draw_string(
            _font,
            _word_positions[i],
            _words[i],
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            _layout_size,
            Color(color, alpha)
        )

    for k in range(FRAMES.size()):
        var dot := Vector2(
            area.x / 2.0 + (k - (FRAMES.size() - 1) / 2.0) * 30.0, band.position.y + 16
        )
        draw_circle(dot, 8.0, Color("#ffe2a0") if k == _frame else Color(1, 1, 1, 0.3))
