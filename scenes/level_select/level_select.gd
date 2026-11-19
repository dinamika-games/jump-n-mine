extends CardMenu

## The three worlds, and the five levels of each. Finishing a level opens the
## next one; the levels not open yet show a lock.


func _ready() -> void:
    super()
    chosen.connect(_on_chosen)
    _show()


func _show() -> void:
    var cards_now: Array[Dictionary] = []
    if Flow.world < 0:
        title = "Choose the mine"
        subtitle = (
            "%s: %d stars"
            % [get_node("/root/Session").session_name, get_node("/root/Session").total_stars()]
        )
        for w in range(LevelCatalog.WORLDS.size()):
            var world: Dictionary = LevelCatalog.WORLDS[w]
            var first := w * LevelCatalog.LEVELS_PER_WORLD
            var stars := 0
            for level in LevelCatalog.levels_of(w):
                stars += get_node("/root/Session").stars_of(level["id"])
            (
                cards_now
                . append(
                    {
                        "id": "world:%d" % w,
                        "title": world["name"],
                        "subtitle": "%d / %d stars" % [stars, 3 * LevelCatalog.LEVELS_PER_WORLD],
                        "icon": "world:%d" % w,
                        "color": Color(world["rock"]).darkened(0.35),
                        "disabled": not get_node("/root/Session").is_unlocked(first),
                    }
                )
            )
        cards_now.append({"id": "back", "title": "Back", "icon": "back"})
    else:
        var world: Dictionary = LevelCatalog.WORLDS[Flow.world]
        title = world["name"]
        subtitle = world["story"]
        for level in LevelCatalog.levels_of(Flow.world):
            var index := LevelCatalog.index_of(level["id"])
            var open: bool = get_node("/root/Session").is_unlocked(index)
            var stars: int = get_node("/root/Session").stars_of(level["id"])
            (
                cards_now
                . append(
                    {
                        "id": "level:%d" % index,
                        "title": level["name"],
                        "subtitle":
                        ("%d / 3 stars" % stars if stars > 0 else "New!") if open else "Locked",
                        "icon": "level:%d" % index if open else "lock",
                        "color": Color(world["rock"]).darkened(0.3),
                        "disabled": not open,
                    }
                )
            )
        cards_now.append({"id": "back", "title": "Back", "icon": "back"})
    set_cards(cards_now)


func _on_chosen(id: String) -> void:
    if id.begins_with("world:"):
        Flow.world = int(id.trim_prefix("world:"))
        _show()
    elif id.begins_with("level:"):
        Flow.play_level(get_tree(), int(id.trim_prefix("level:")))
    elif id == "back":
        if Flow.world >= 0:
            Flow.world = -1
            _show()
        else:
            Flow.go(get_tree(), Flow.INTRO)
