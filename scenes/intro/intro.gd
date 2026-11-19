extends CardMenu

## The first screen: the title, and Play, the expeditions, how to play and
## quitting.


func _ready() -> void:
    super()
    title = "Jump 'n' Mine"
    subtitle = "Jump to swing your pickaxe, and dig for the dwarves' treasure!"
    var cards_now: Array[Dictionary] = [
        {"id": "play", "title": "Play", "icon": "play", "color": Color("#b8452f")},
        {"id": "sessions", "title": "Expeditions", "icon": "expedition", "color": Color("#3d5a8a")},
        {
            "id": "instruction",
            "title": "How to play",
            "icon": "question",
            "color": Color("#4a7a3a")
        },
        {"id": "quit", "title": "Quit", "icon": "quit", "color": Color("#5a3d6e")},
    ]
    set_cards(cards_now)
    chosen.connect(_on_chosen)


func _on_chosen(id: String) -> void:
    match id:
        "play":
            Flow.play(get_tree())
        "sessions":
            Flow.go(get_tree(), Flow.SESSIONS)
        "instruction":
            Flow.go(get_tree(), Flow.INSTRUCTION)
        "quit":
            get_tree().quit()
