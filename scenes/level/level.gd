class_name Level
extends Node2D

## Play a level of [LevelCatalog]: the players step left and right to walk
## their dwarves and jump to swing the pickaxes, until a dwarf finds the
## treasure at the bottom, or the water floods the mine and they start again.
##
## The players come and go at will: a head which appears
## in the camera picture gets a dwarf of a free color (a slot), let down into
## the mine on a rope, and a dwarf whose head left the picture waits for
## [constant WAIT_FOR_HEAD] seconds and then leaves. A head which comes back in
## time (the tracker gives it its old id) takes its dwarf back.
##
## The keys work, too (see [constant KEYS]): the first key of a player brings
## its dwarf. Without a camera, the first dwarf is there from the start. Start
## the game with [code]-- --bots[/code] (or [code]--bots=3[/code]) to let bots
## play, to watch a level.

## The keys of the players: left, right and jump.
const KEYS := [
    [KEY_LEFT, KEY_RIGHT, KEY_UP],
    [KEY_A, KEY_D, KEY_W],
    [KEY_J, KEY_L, KEY_I],
    [KEY_KP_4, KEY_KP_6, KEY_KP_8],
]

## The heads are followed from this to this fraction of the camera picture.
const HEAD_RANGE := Vector2(0.12, 0.88)

## A dwarf waits this long for its head to come back, in seconds.
const WAIT_FOR_HEAD := 4.0

## Show the cards at the end this long after the treasure or the flood.
const END_DELAY := 2.0

var level: Dictionary
var mine: Mine
var view: MineView
var hud: Hud
## The head of each slot: its id, or -1.
var head_of_slot: Array[int] = [-1, -1, -1, -1]
var bots: Array[MineBot] = []

## How long the dwarf of each slot waits for its head already, in seconds.
var _waiting: Array[float] = [0.0, 0.0, 0.0, 0.0]
## The last head of each slot, so that a head which comes back gets its dwarf.
var _last_head: Array[int] = [-1, -1, -1, -1]
var _tips_shown := {}
var _end_in := -1.0
var _menu: CardMenu = null
var _layer := CanvasLayer.new()


func _ready() -> void:
    level = LevelCatalog.LEVELS[Flow.level_index]
    mine = Mine.new(level, 0)
    view = MineView.new(mine, int(level["world"]))
    add_child(view)
    add_child(_layer)
    hud = Hud.new(mine, level)
    _layer.add_child(hud)

    var bot_count := 0
    for arg in OS.get_cmdline_user_args():
        if arg == "--bots":
            bot_count = 1
        elif arg.begins_with("--bots="):
            bot_count = clampi(int(arg.trim_prefix("--bots=")), 1, Mine.MAX_DWARVES)
    for slot in range(bot_count):
        mine.add_dwarf(slot)
        bots.append(MineBot.new(mine, slot))
    if bot_count == 0 and not get_node("/root/Vision").has_camera():
        mine.add_dwarf(0)
    mine.take_events()

    get_node("/root/Vision").head_jumped.connect(_on_head_jumped)
    hud.tip(_first_tip(), 7.0)


func _first_tip() -> String:
    if mine.dwarves.is_empty():
        return "Step in front of the camera to get your dwarf!"
    if Flow.level_index == 0:
        return "Jump to swing your pickaxe! Dig down to the treasure."
    return world_name() + ": " + str(level["name"])


func world_name() -> String:
    return LevelCatalog.WORLDS[int(level["world"])]["name"]


func _physics_process(delta: float) -> void:
    _bind_heads(delta)
    _steer(delta)
    for bot in bots:
        bot.act(delta)
    mine.step(delta)
    var events := mine.take_events()
    view.show_events(events)
    _sound(events)

    hud.dwarf_of_head.clear()
    for slot in range(head_of_slot.size()):
        if head_of_slot[slot] >= 0:
            hud.dwarf_of_head[head_of_slot[slot]] = slot

    _loops()

    if mine.state != Mine.State.PLAYING and _end_in < 0.0 and _menu == null:
        _end_in = END_DELAY
        if mine.state == Mine.State.WON:
            get_node("/root/Session").finish_level(level["id"], mine.stars())
    if _end_in >= 0.0:
        _end_in -= delta
        if _end_in < 0.0:
            _show_end()


## Keep the water pouring from the open springs, and the gas hissing.
func _loops() -> void:
    var sounds := get_node("/root/Sounds")
    var playing := mine.state == Mine.State.PLAYING and is_physics_processing()
    var pouring := false
    for i in mine.springs:
        var inner := 1 if i % Mine.WIDTH == 0 else Mine.WIDTH - 2
        if mine.cells[i] == Mine.Cell.SPRING and mine.cell(inner, i / Mine.WIDTH) == Mine.Cell.AIR:
            pouring = true
    sounds.loop("water_pour", playing and pouring)
    sounds.loop("fuse", playing and not mine.fuses.is_empty())


func _exit_tree() -> void:
    get_node("/root/Sounds").stop_loops()


## Give the new heads their dwarves, and let the dwarves whose heads are gone
## wait, and then leave.
func _bind_heads(delta: float) -> void:
    var heads: Dictionary = get_node("/root/Vision").heads
    for slot in range(head_of_slot.size()):
        var head := head_of_slot[slot]
        if head < 0:
            continue
        if heads.has(head):
            _waiting[slot] = 0.0
            continue
        _waiting[slot] += delta
        if _waiting[slot] >= WAIT_FOR_HEAD:
            head_of_slot[slot] = -1
            _waiting[slot] = 0.0
            mine.remove_dwarf(slot)

    for id in get_node("/root/Vision").ids_from_left():
        if head_of_slot.has(id):
            continue
        var slot := _last_head.find(id)
        if slot < 0 or (head_of_slot[slot] >= 0 and heads.has(head_of_slot[slot])):
            slot = _free_slot()
        if slot < 0:
            continue
        head_of_slot[slot] = id
        _last_head[slot] = id
        _waiting[slot] = 0.0
        var dwarf := mine.add_dwarf(slot)
        dwarf.target_x = _head_x(id)


## A slot whose dwarf is not in the mine (and played by no bot), or -1.
func _free_slot() -> int:
    for slot in range(Mine.MAX_DWARVES):
        if slot < bots.size():
            continue
        if mine.dwarf_of(slot) == null and head_of_slot[slot] < 0:
            return slot
    # NOTE (mristin):
    # Else a dwarf whose head is gone and which waits for it.
    for slot in range(Mine.MAX_DWARVES):
        if slot >= bots.size() and head_of_slot[slot] >= 0 and _waiting[slot] > 0.0:
            return slot
    return -1


## Where in the mine (in cells) the head stands.
func _head_x(id: int) -> float:
    var position: Vector2 = get_node("/root/Vision").heads[id]["position"]
    var t := clampf((position.x - HEAD_RANGE.x) / (HEAD_RANGE.y - HEAD_RANGE.x), 0.0, 1.0)
    return 0.5 + t * (Mine.WIDTH - 1.0)


func _steer(_delta: float) -> void:
    if mine.state != Mine.State.PLAYING:
        return
    var heads: Dictionary = get_node("/root/Vision").heads
    for slot in range(Mine.MAX_DWARVES):
        var dwarf := mine.dwarf_of(slot)
        var head := head_of_slot[slot]
        if head >= 0:
            if heads.has(head) and dwarf != null:
                mine.set_target(slot, _head_x(head))
            continue
        if slot < bots.size():
            continue
        var keys: Array = KEYS[slot]
        var direction := 0.0
        if Input.is_physical_key_pressed(keys[0]):
            direction -= 1.0
        if Input.is_physical_key_pressed(keys[1]):
            direction += 1.0
        if direction == 0.0:
            if dwarf != null and absf(dwarf.target_x - dwarf.pos.x) > 0.6:
                mine.set_target(slot, dwarf.pos.x)
            continue
        if dwarf == null:
            dwarf = mine.add_dwarf(slot)
        mine.set_target(slot, dwarf.pos.x + direction * 1.0)


func _on_head_jumped(id: int) -> void:
    var slot := head_of_slot.find(id)
    if slot >= 0:
        mine.jump(slot)


func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    if _menu != null:
        return
    if event.keycode == KEY_ESCAPE:
        _show_pause()
        get_viewport().set_input_as_handled()
        return
    for slot in range(KEYS.size()):
        var jump_key: bool = event.physical_keycode == KEYS[slot][2]
        if jump_key or (slot == 0 and event.physical_keycode == KEY_SPACE):
            if slot < bots.size() or head_of_slot[slot] >= 0:
                return
            if mine.dwarf_of(slot) == null:
                mine.add_dwarf(slot)
            else:
                mine.jump(slot)
            get_viewport().set_input_as_handled()
            return


func _sound(events: Array[Dictionary]) -> void:
    for event in events:
        var type := str(event["type"])
        match type:
            "hit":
                get_node("/root/Sounds").play(
                    "hit_hard" if int(event.get("kind", 0)) == Mine.Cell.ROCK else "hit_soft",
                    randf_range(0.9, 1.1)
                )
            "singed":
                get_node("/root/Sounds").play("dizzy")
            "pump":
                get_node("/root/Sounds").play("booster")
            "won", "flooded":
                get_node("/root/Sounds").play(type)
            "gas", "joined":
                pass
            "plate":
                get_node("/root/Sounds").play("click")
            "gate_open":
                get_node("/root/Sounds").play("booster")
            "gate_closed":
                get_node("/root/Sounds").play("sealed")
            "left":
                get_node("/root/Sounds").play("rope", 0.8)
            _:
                get_node("/root/Sounds").play(type, randf_range(0.95, 1.05))
        _tip_for(type)


## Explain a thing the first time it happens in the level.
func _tip_for(type: String) -> void:
    var tips := {
        "gas": "Gas! Step away before it explodes!",
        "dragon": "A dragon! Step away from the red glow!",
        "plate": "Stand on the stone plates to open the iron gate!",
        "gate_open": "The gate is open! Quick, drop through!",
        "splash": "Water! Hit the blue spring in the wall to seal it.",
        "booster": "A booster! It helps you for a while.",
        "rope": "A rope lets the dwarf down to the friends.",
    }
    if tips.has(type) and not _tips_shown.has(type):
        _tips_shown[type] = true
        hud.tip(tips[type])
    if not _tips_shown.has("water") and mine.flood_level() > 0.5:
        _tips_shown["water"] = true
        hud.tip("The mine is filling with water! Seal the springs!")


func _show_end() -> void:
    _menu = CardMenu.new()
    _menu.background = false
    var cards: Array[Dictionary] = []
    if mine.state == Mine.State.WON:
        _menu.title = "Treasure found!"
        _menu.subtitle = "%d of %d gems, %d stars" % [mine.gems, mine.gems_total, mine.stars()]
        if Flow.level_index + 1 < LevelCatalog.LEVELS.size():
            cards.append(
                {"id": "next", "title": "Next level", "icon": "next", "color": Color("#b8452f")}
            )
        cards.append({"id": "again", "title": "Again", "icon": "again", "color": Color("#3d5a8a")})
    else:
        _menu.title = "The mine is flooded!"
        _menu.subtitle = "The dwarves climbed out, wet but happy. Let's try again!"
        cards.append(
            {"id": "again", "title": "Try again", "icon": "again", "color": Color("#b8452f")}
        )
    cards.append({"id": "levels", "title": "Levels", "icon": "levels", "color": Color("#5a3d6e")})
    _menu.set_cards(cards)
    _menu.chosen.connect(_on_menu)
    _layer.add_child(_menu)
    if mine.state == Mine.State.WON:
        var stars := StarsBanner.new(mine.stars())
        _menu.add_child(stars)


func _show_pause() -> void:
    get_tree().paused = false
    _menu = CardMenu.new()
    _menu.background = false
    _menu.title = "A break"
    _menu.subtitle = str(level["name"])
    (
        _menu
        . set_cards(
            [
                {"id": "resume", "title": "Go on", "icon": "play", "color": Color("#4a7a3a")},
                {"id": "again", "title": "Start again", "icon": "again", "color": Color("#3d5a8a")},
                {"id": "levels", "title": "Levels", "icon": "levels", "color": Color("#5a3d6e")},
            ]
        )
    )
    _menu.chosen.connect(_on_menu)
    _layer.add_child(_menu)
    set_physics_process(false)
    get_node("/root/Sounds").stop_loops()


func _on_menu(id: String) -> void:
    match id:
        "resume":
            _menu.queue_free()
            _menu = null
            set_physics_process(true)
        "next":
            Flow.play_level(get_tree(), Flow.level_index + 1)
        "again":
            Flow.play_level(get_tree(), Flow.level_index)
        "levels":
            Flow.world = int(level["world"])
            Flow.go(get_tree(), Flow.LEVEL_SELECT)
