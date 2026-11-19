extends CardMenu

## The expeditions: Continue the last one, start a New expedition, or go on
## with one of the other recent ones. Delete removes an expedition for good,
## in three steps, so that nobody deletes one by chance: Delete, then the card
## of the expedition, then Delete again (or Keep).

enum Mode { CHOOSE, DELETE, CONFIRM }

## How many other recent expeditions the screen offers.
const RECENT := 2

var _mode := Mode.CHOOSE
var _to_delete := ""


func _ready() -> void:
    super()
    title = "Your expeditions"
    chosen.connect(_on_chosen)
    _show()


func _describe(session: Dictionary) -> String:
    return "%d stars" % int(session["stars"])


func _show() -> void:
    var all: Array[Dictionary] = get_node("/root/Session").sessions()
    var cards_now: Array[Dictionary] = []
    match _mode:
        Mode.CHOOSE:
            subtitle = "Go on digging, or start a new expedition."
            var last: String = get_node("/root/Session").last_id()
            var shown := 0
            for session in all:
                if session["id"] == last:
                    (
                        cards_now
                        . append(
                            {
                                "id": "go:" + session["id"],
                                "title": "Continue",
                                "subtitle": "%s\n%s" % [session["name"], _describe(session)],
                                "icon": "continue",
                                "color": Color("#b8452f"),
                            }
                        )
                    )
            cards_now.append(
                {"id": "new", "title": "New expedition", "icon": "new", "color": Color("#4a7a3a")}
            )
            for session in all:
                if session["id"] == last or shown >= RECENT:
                    continue
                shown += 1
                (
                    cards_now
                    . append(
                        {
                            "id": "go:" + session["id"],
                            "title": session["name"],
                            "subtitle": _describe(session),
                            "icon": "expedition",
                            "color": Color("#3d5a8a"),
                        }
                    )
                )
            if not all.is_empty():
                cards_now.append(
                    {
                        "id": "delete",
                        "title": "Delete...",
                        "icon": "trash",
                        "color": Color("#5a3d6e")
                    }
                )
            cards_now.append({"id": "back", "title": "Back", "icon": "back"})
        Mode.DELETE:
            subtitle = "Which expedition shall we delete?"
            for session in all.slice(0, 4):
                (
                    cards_now
                    . append(
                        {
                            "id": "pick:" + session["id"],
                            "title": session["name"],
                            "subtitle": _describe(session),
                            "icon": "expedition",
                            "color": Color("#7a3a3a"),
                        }
                    )
                )
            cards_now.append({"id": "back", "title": "Back", "icon": "back"})
        Mode.CONFIRM:
            var data: Variant = get_node("/root/Session").read(_to_delete)
            var name: String = data.get("name", _to_delete) if data != null else _to_delete
            subtitle = 'Delete "%s" for good?' % name
            cards_now = [
                {"id": "confirm", "title": "Delete", "icon": "trash", "color": Color("#b83a2f")},
                {"id": "back", "title": "Keep", "icon": "keep", "color": Color("#4a7a3a")},
            ]
    set_cards(cards_now)


func _on_chosen(id: String) -> void:
    if id.begins_with("go:"):
        get_node("/root/Session").choose_session(id.trim_prefix("go:"))
        Flow.play(get_tree())
    elif id == "new":
        Flow.go(get_tree(), Flow.SESSION_NAME)
    elif id == "delete":
        _mode = Mode.DELETE
        _show()
    elif id.begins_with("pick:"):
        _to_delete = id.trim_prefix("pick:")
        _mode = Mode.CONFIRM
        _show()
    elif id == "confirm":
        get_node("/root/Session").delete_session(_to_delete)
        _mode = Mode.CHOOSE
        _show()
    elif id == "back":
        if _mode == Mode.CHOOSE:
            Flow.go(get_tree(), Flow.INTRO)
        else:
            _mode = Mode.CHOOSE
            _show()
