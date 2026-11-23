extends CardMenu

## The dwarves' house: the players build it up with the gems in the purse,
## stage by stage, part by part, like the palace of Civilization III (see
## [constant Economy.HOUSE_PARTS]): fifty improvements in all. The cards show
## the next stages of a few parts at a time, each with its picture; "More"
## shows the next parts.

## How many parts the cards show at a time.
const PER_PAGE := 4

var _page := 0


func _init() -> void:
    super()
    cards_top = 0.735
    card_height = 210.0


func _ready() -> void:
    super()
    chosen.connect(_on_chosen)
    _show()


func _pages() -> int:
    return int(ceil(float(Economy.HOUSE_PARTS.size()) / PER_PAGE))


func _show() -> void:
    var session := get_node("/root/Session")
    title = "The dwarves' house"
    subtitle = (
        "%d gems in the purse, %d of %d built"
        % [session.purse.gems, session.purse.house_built(), Economy.house_count()]
    )
    var cards_now: Array[Dictionary] = []
    var first := _page * PER_PAGE
    for part in range(first, mini(first + PER_PAGE, Economy.HOUSE_PARTS.size())):
        var spec: Dictionary = Economy.HOUSE_PARTS[part]
        var price: int = session.purse.next_house_price(part)
        var stage: int = session.purse.stage_of(part)
        var card := {"id": "build:%d" % part, "color": Color("#8a6a1e")}
        if price < 0:
            card["title"] = "%s: all built!" % spec["name"]
            card["icon"] = "house_stage:%d:%d" % [part, spec["stages"].size() - 1]
            card["disabled"] = true
        else:
            card["title"] = "%s: %d gems" % [spec["stages"][stage], price]
            card["icon"] = "house_stage:%d:%d" % [part, stage]
            card["disabled"] = session.purse.gems < price
        cards_now.append(card)
    if _pages() > 1:
        cards_now.append({"id": "more", "title": "More parts", "color": Color("#3d5a8a")})
    cards_now.append({"id": "back", "title": "Back", "color": Color("#4a7a3a")})
    set_cards(cards_now)


func _on_chosen(id: String) -> void:
    if id.begins_with("build:"):
        if get_node("/root/Session").purse.build(int(id.trim_prefix("build:"))):
            get_node("/root/Sounds").play("won")
        _show()
    elif id == "more":
        _page = (_page + 1) % _pages()
        _show()
    elif id == "back":
        Flow.go(get_tree(), Flow.SHOP)


func _draw_behind_cards() -> void:
    var session := get_node_or_null("/root/Session")
    if session == null:
        return
    HouseArt.draw(self, Rect2(330, 262, 1260, 520), session.purse.house, _time)
