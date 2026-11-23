class_name Level
extends Node2D

## Play a level of [LevelCatalog]: the players step left and right to walk
## their dwarves and jump to swing the pickaxes, until a dwarf finds the
## treasure at the bottom, or the evil miner of Queen Treacher takes the
## treasure first, and they start again. The dwarves
## take the boosters bought in the shop along, and keep the gems they gathered.
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
## play, to watch a level, and with [code]-- --record[/code] to record the
## players (see [Recorder]).

## The keys of the players: left, right and jump.
const KEYS := [
    [KEY_LEFT, KEY_RIGHT, KEY_UP],
    [KEY_A, KEY_D, KEY_W],
    [KEY_J, KEY_L, KEY_I],
    [KEY_KP_4, KEY_KP_6, KEY_KP_8],
]

## A dwarf stands in the middle of a block and walks to the next one only once
## its head is this far (in cells) beyond the edge of the block, so that it
## stays on the block it digs while its player sways and jumps. In recordings
## of players who dug on one spot, the head swayed about 2 % of the width of
## the picture over a second (half a cell), and as far during a jump.
const BLOCK_MARGIN := 0.5

## The head must stay beyond the edge of the block this long (in seconds) before
## the dwarf steps to the next block, so that a glitch of the tracking (in a
## recording, the head jumped by more than a block for a frame) does not move it.
const STEP_HOLD := 0.1

## A dwarf waits this long for its head to come back, in seconds.
const WAIT_FOR_HEAD := 4.0

## Show the cards at the end this long after the treasure is found or lost.
const END_DELAY := 2.0

## The menu at the end of a level takes a jump only after the players stopped
## digging this long (in seconds, see [member CardMenu.calm]), so that the next
## level does not start by itself before they can choose the shop. In
## recordings, the players jump about once a second while they dig.
const END_CALM := 1.5

var level: Dictionary
var mine: Mine
var view: MineView
var hud: Hud
var overlay: CameraOverlay
## The head of each slot: its id, or -1.
var head_of_slot: Array[int] = [-1, -1, -1, -1]
var bots: Array[MineBot] = []
## The bot of the evil miner, or null in the levels without him.
var rival_bot: MineBot = null

## How long the dwarf of each slot waits for its head already, in seconds.
var _waiting: Array[float] = [0.0, 0.0, 0.0, 0.0]
## The last head of each slot, so that a head which comes back gets its dwarf.
var _last_head: Array[int] = [-1, -1, -1, -1]
## How long the head of each slot is beyond the edge of its dwarf's block already,
## in seconds (see [constant STEP_HOLD]).
var _beyond: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _tips_shown := {}
var _end_in := -1.0
var _menu: CardMenu = null
var _layer := CanvasLayer.new()
var _recorder: Recorder = null
## Whether the gems of the level went into the purse already.
var _banked := false


func _ready() -> void:
    level = LevelCatalog.LEVELS[Flow.level_index]
    mine = Mine.new(level, 0, get_node("/root/Session").purse.boosters)
    if bool(level.get("rival", false)):
        rival_bot = MineBot.new(mine, Mine.RIVAL)
    view = MineView.new(mine, int(level["world"]))
    add_child(view)
    add_child(_layer)
    overlay = CameraOverlay.new()
    overlay.span = Vector2(0.5, Mine.WIDTH - 0.5) * MineView.CELL
    overlay.anchor_y = MineView.TOP + (get_viewport_rect().size.y - MineView.TOP) * 0.28
    overlay.target_of_head = _beam_target
    _layer.add_child(overlay)
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
    get_node("/root/Vision").head_swung.connect(_on_head_swung)
    if "--record" in OS.get_cmdline_user_args():
        _recorder = Recorder.new(str(level["id"]))
        get_node("/root/Vision").head_moved.connect(_on_head_moved)
        get_node("/root/Vision").head_arms.connect(_recorder.arms)
    hud.tip(_first_tip(), 7.0)


## Where the beam of light of a head goes (see [CameraOverlay]): to the middle
## of its dwarf, a block wide.
func _beam_target(_id: int, slot: int) -> Variant:
    var dwarf := mine.dwarf_of(slot)
    if dwarf == null:
        return null
    var at := view.to_screen(dwarf.pos - Vector2(0, Mine.DWARF_HEIGHT * 0.5))
    return Vector3(at.x, at.y, MineView.CELL * 1.1)


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
    if rival_bot != null:
        rival_bot.act(delta)
    mine.step(delta)
    var events := mine.take_events()
    if _recorder != null:
        for slot in range(Mine.MAX_DWARVES):
            var dwarf := mine.dwarf_of(slot)
            if dwarf != null:
                _recorder.dwarf(slot, head_of_slot[slot], dwarf)
        for event in events:
            _recorder.event(event)
    view.show_events(events)
    _sound(events)

    overlay.slot_of_head.clear()
    for slot in range(head_of_slot.size()):
        if head_of_slot[slot] >= 0:
            overlay.slot_of_head[head_of_slot[slot]] = slot

    _loops()

    if mine.state != Mine.State.PLAYING and _end_in < 0.0 and _menu == null:
        _end_in = END_DELAY
        if mine.state == Mine.State.WON:
            get_node("/root/Session").finish_level(level["id"], mine.stars())
        _bank()
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


## Put the gems which the dwarves gathered into the purse, once: at the end of
## the level, or when the players leave it.
func _bank() -> void:
    if _banked:
        return
    _banked = true
    get_node("/root/Session").purse.add_gems(mine.gems)


func _exit_tree() -> void:
    _bank()
    if _recorder != null:
        _recorder.close()
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
        dwarf.target_x = floorf(_head_x(id)) + 0.5


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
    var t: float = get_node("/root/Vision").across(position)
    return 0.5 + t * (Mine.WIDTH - 1.0)


## Step the dwarf of the slot towards its head, block by block: it stands in
## the middle of a block and steps to the next one once the head was beyond the
## edge of its block (see [constant BLOCK_MARGIN]) for [constant STEP_HOLD], and
## the dwarf arrived at its block (or the step goes back towards where the dwarf
## stands, e.g., when a block stopped it). The walls count as blocks, too, so
## that a dwarf can lean against them.
func _step_towards_head(slot: int, dwarf: Mine.Dwarf, x: float, delta: float) -> void:
    var column := floorf(dwarf.target_x)
    var side := 0
    if x < column - BLOCK_MARGIN:
        side = -1
    elif x > column + 1.0 + BLOCK_MARGIN:
        side = 1
    if side == 0:
        _beyond[slot] = 0.0
        return
    _beyond[slot] += delta
    if _beyond[slot] < STEP_HOLD:
        return
    var target := clampf(column + side, 0.0, Mine.WIDTH - 1.0) + 0.5
    var arrived := absf(dwarf.pos.x - dwarf.target_x) < 0.15
    if arrived or absf(target - dwarf.pos.x) < absf(dwarf.target_x - dwarf.pos.x):
        mine.set_target(slot, target)


func _steer(delta: float) -> void:
    if mine.state != Mine.State.PLAYING:
        return
    var heads: Dictionary = get_node("/root/Vision").heads
    for slot in range(Mine.MAX_DWARVES):
        var dwarf := mine.dwarf_of(slot)
        var head := head_of_slot[slot]
        if head >= 0:
            if heads.has(head) and dwarf != null:
                _step_towards_head(slot, dwarf, _head_x(head), delta)
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


func _on_head_moved(id: int, _position: Vector2) -> void:
    _recorder.head(id, get_node("/root/Vision").heads[id])


func _on_head_jumped(id: int, strength: float) -> void:
    if _recorder != null:
        _recorder.jump(id, strength)
    var slot := head_of_slot.find(id)
    if slot >= 0:
        mine.jump(slot, strength)


func _on_head_swung(id: int, side: int) -> void:
    if _recorder != null:
        _recorder.swing(id, side)
    var slot := head_of_slot.find(id)
    if slot >= 0:
        mine.swing_side(slot, side)


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
            "won", "lost", "mole", "rival":
                get_node("/root/Sounds").play(type)
            "gas", "joined", "mole_dig", "mole_gone":
                pass
            "booster":
                get_node("/root/Session").purse.use_booster(str(event["kind"]))
                get_node("/root/Sounds").play("booster")
            "mole_cry":
                get_node("/root/Sounds").play("sniff")
            "knockout":
                get_node("/root/Sounds").play("bonk")
            "bonked":
                get_node("/root/Sounds").play("bonk", 0.8)
                get_node("/root/Sounds").play("dizzy")
            "pried":
                get_node("/root/Sounds").play("hit_hard", 0.7)
            "plate":
                get_node("/root/Sounds").play("click")
            "gate_open":
                get_node("/root/Sounds").play("booster")
            "gate_closed", "dry":
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
        "splash": "Water! It slows you down. Jump next to the spring to seal it.",
        "dry": "The spring ran dry!",
        "booster": "A booster from the shop helps you!",
        "mole": "A mole! It digs for you. Don't hit it!",
        "mole_cry": "Oh no, the mole cries! Moles are friends.",
        "rival": "Queen Treacher's evil miner! Be faster, and bonk him!",
        "bonked": "The evil miner hit you! Hit him back with your pickaxe!",
        "pried": "The evil miner broke a bar of the gate!",
        "rope": "A rope lets the dwarf down to the friends.",
    }
    if tips.has(type) and not _tips_shown.has(type):
        _tips_shown[type] = true
        hud.tip(tips[type])


func _show_end() -> void:
    _menu = CardMenu.new()
    _menu.background = false
    _menu.calm = END_CALM
    _menu.hint = "Stop digging, step left or right to choose, and jump to press!"
    var cards: Array[Dictionary] = []
    var purse := "+%d gems, %d in the purse" % [mine.gems, get_node("/root/Session").purse.gems]
    if mine.state == Mine.State.WON:
        _menu.title = "Treasure found!"
        _menu.subtitle = (
            "%d of %d gems, %d stars. %s" % [mine.gems, mine.gems_total, mine.stars(), purse]
        )
        if Flow.level_index + 1 < LevelCatalog.LEVELS.size():
            cards.append(
                {"id": "next", "title": "Next level", "icon": "next", "color": Color("#b8452f")}
            )
        cards.append({"id": "again", "title": "Again", "icon": "again", "color": Color("#3d5a8a")})
    else:
        _menu.title = "The evil miner was faster!"
        _menu.subtitle = "Queen Treacher's miner grabbed the treasure. %s" % purse
        cards.append(
            {"id": "again", "title": "Try again", "icon": "again", "color": Color("#b8452f")}
        )
    cards.append({"id": "shop", "title": "Shop", "icon": "shop", "color": Color("#8a6a1e")})
    cards.append({"id": "levels", "title": "Levels", "icon": "levels", "color": Color("#5a3d6e")})
    _menu.set_cards(cards)
    _menu.chosen.connect(_on_menu)
    _layer.add_child(_menu)
    overlay.visible = false
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
    overlay.visible = false
    set_physics_process(false)
    get_node("/root/Sounds").stop_loops()


func _on_menu(id: String) -> void:
    match id:
        "resume":
            _menu.queue_free()
            _menu = null
            overlay.visible = true
            set_physics_process(true)
        "next":
            Flow.play_level(get_tree(), Flow.level_index + 1)
        "again":
            Flow.play_level(get_tree(), Flow.level_index)
        "levels":
            Flow.world = int(level["world"])
            Flow.go(get_tree(), Flow.LEVEL_SELECT)
        "shop":
            Flow.world = int(level["world"])
            var next := Flow.level_index
            if mine.state == Mine.State.WON and next + 1 < LevelCatalog.LEVELS.size():
                next += 1
            Flow.open_shop(get_tree(), next)
