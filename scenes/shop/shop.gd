extends CardMenu

## The shop: the players buy boosters with the gems in the purse of the
## expedition, for the next levels (see [Economy]); the boosters start by
## themselves in a level when they help. From here, they go to the house, or on
## with the next level (see [member Flow.after_shop]).


func _ready() -> void:
    super()
    chosen.connect(_on_chosen)
    _show()


func _show() -> void:
    var session := get_node("/root/Session")
    title = "The shop"
    subtitle = (
        "%d gems in the purse. The boosters start by themselves when they help!"
        % session.purse.gems
    )
    var cards_now: Array[Dictionary] = []
    for kind in Mine.BOOSTERS:
        var info: Array = Economy.BOOSTER_INFO[kind]
        var have: int = session.purse.boosters_of(kind)
        var price := int(Economy.BOOSTER_PRICES[kind])
        var note := "%d gems, you have %d" % [price, have]
        if have >= Economy.MAX_CARRY:
            note = "You have %d, the most" % have
        elif session.purse.gems < price:
            note = "%d gems: not enough" % price
        (
            cards_now
            . append(
                {
                    "id": "buy:%s" % kind,
                    "title": info[0],
                    "subtitle": "%s. %s" % [note, info[1]],
                    "icon": "booster:%s" % kind,
                    "color": Color("#8a6a1e"),
                    "disabled": not session.purse.can_buy_booster(kind),
                }
            )
        )
    (
        cards_now
        . append(
            {
                "id": "house",
                "title": "The house",
                "subtitle": "%d of %d built" % [session.purse.house_built(), Economy.house_count()],
                "icon": "house",
                "color": Color("#3d5a8a"),
            }
        )
    )
    var go := "Back"
    if Flow.after_shop >= 0:
        go = "Play " + str(LevelCatalog.LEVELS[Flow.after_shop]["name"])
    cards_now.append({"id": "back", "title": go, "icon": "next", "color": Color("#4a7a3a")})
    set_cards(cards_now)


func _on_chosen(id: String) -> void:
    if id.begins_with("buy:"):
        if get_node("/root/Session").purse.buy_booster(id.trim_prefix("buy:")):
            get_node("/root/Sounds").play("buy")
        _show()
    elif id == "house":
        Flow.go(get_tree(), Flow.HOUSE)
    elif id == "back":
        Flow.leave_shop(get_tree())
