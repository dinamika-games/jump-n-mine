extends CanvasLayer

## Escape twice quits the game (the autoload QuitGuard): the first Escape does
## what it does on the screen (back in the menus, the break in a level) and
## shows that a second one quits; a second Escape within
## [constant WINDOW] seconds quits.

## The second Escape must come within this many seconds.
const WINDOW := 2.0

var _last_escape := -INF
var _label := Label.new()


func _ready() -> void:
    layer = 100
    process_mode = Node.PROCESS_MODE_ALWAYS
    _label.text = "Press Esc again to quit"
    _label.add_theme_font_size_override("font_size", 40)
    _label.add_theme_color_override("font_color", Color("#ffe2a0"))
    _label.add_theme_color_override("font_outline_color", Color("#1a1016"))
    _label.add_theme_constant_override("outline_size", 12)
    _label.set_anchors_preset(Control.PRESET_CENTER_TOP)
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.position = Vector2(-300, 110)
    _label.size = Vector2(600, 60)
    _label.visible = false
    add_child(_label)


func _input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if event.keycode != KEY_ESCAPE:
        return
    var now := Time.get_ticks_msec() / 1000.0
    if now - _last_escape <= WINDOW:
        get_viewport().set_input_as_handled()
        get_tree().quit()
        return
    _last_escape = now
    _label.visible = true


func _process(_delta: float) -> void:
    if _label.visible and Time.get_ticks_msec() / 1000.0 - _last_escape > WINDOW:
        _label.visible = false
