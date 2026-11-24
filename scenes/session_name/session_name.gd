extends CardMenu

## Name a new expedition: the name starts as the date and the time, so that
## jumping on OK is enough; the keys of the keyboard (or the keys on the
## screen, with the mouse) change it, and the first key replaces it.

const KEYS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-: "

var session_name := ""
var _untouched := true
var _keys := GridContainer.new()


func _ready() -> void:
    super()
    title = "A new expedition"
    hint = "Jump on OK, or type a name first."
    session_name = get_node("/root/Session").default_session_name()
    set_cards(
        [
            {"id": "ok", "title": "OK", "icon": "ok", "color": Color("#4a7a3a")},
            {"id": "back", "title": "Back", "icon": "back"},
        ]
    )
    chosen.connect(_on_chosen)

    _keys.columns = 13
    _keys.position = Vector2(560, 850)
    for key in KEYS:
        var button := Button.new()
        button.text = "Space" if key == " " else key
        button.custom_minimum_size = Vector2(56, 44)
        button.focus_mode = Control.FOCUS_NONE
        button.pressed.connect(_type.bind(key))
        _keys.add_child(button)
    var erase := Button.new()
    erase.text = "<-"
    erase.custom_minimum_size = Vector2(56, 44)
    erase.focus_mode = Control.FOCUS_NONE
    erase.pressed.connect(_erase)
    _keys.add_child(erase)
    add_child(_keys)


func _process(delta: float) -> void:
    super(delta)
    subtitle = session_name + ("|" if fmod(Time.get_ticks_msec() / 500.0, 2.0) < 1.0 else " ")


func _type(key: String) -> void:
    if _untouched:
        session_name = ""
        _untouched = false
    if session_name.length() < 24:
        session_name += key


func _erase() -> void:
    _untouched = false
    session_name = session_name.left(-1)


func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_BACKSPACE:
            _erase()
            get_viewport().set_input_as_handled()
            return
        if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
            _on_chosen("ok")
            get_viewport().set_input_as_handled()
            return
        if event.keycode == KEY_ESCAPE:
            _on_chosen("back")
            get_viewport().set_input_as_handled()
            return
        var character := String.chr(event.unicode) if event.unicode > 0 else ""
        if character != "" and (character.to_upper() in KEYS or character.is_valid_identifier()):
            _type(character)
            get_viewport().set_input_as_handled()
            return
    super(event)


func _on_chosen(id: String) -> void:
    if id == "ok":
        get_node("/root/Session").start_session(session_name)
        Flow.play(get_tree())
    else:
        Flow.go(
            get_tree(),
            Flow.SESSIONS if not get_node("/root/Session").sessions().is_empty() else Flow.INTRO
        )
