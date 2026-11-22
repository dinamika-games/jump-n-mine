extends SceneTree
## Go through the screens like players: from the intro over the story, a new
## expedition, how to play and the levels into the first level; a second player joins with
## her keys; play a bit with the keys, and back out through the pause.

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _frames(count: int) -> void:
    for i in range(count):
        await process_frame


## Wait for the scene of the file, and return it.
func _expect(path: String) -> Node:
    for i in range(30):
        await process_frame
        if current_scene != null and current_scene.scene_file_path == path:
            await process_frame
            return current_scene
    _check(
        false,
        (
            "expected the screen %s, got %s"
            % [path, current_scene.scene_file_path if current_scene != null else "none"]
        )
    )
    return null


func _run() -> void:
    var session := root.get_node("/root/Session")
    session.use_settings("user://test_screens.cfg")
    # NOTE (mristin):
    # Start as on a new computer, which has not seen the story yet.
    if FileAccess.file_exists(session.settings_path()):
        DirAccess.remove_absolute(session.settings_path())
    var saves: String = session.saves_dir()
    if DirAccess.dir_exists_absolute(saves):
        for file in DirAccess.get_files_at(saves):
            DirAccess.remove_absolute(saves.path_join(file))

    change_scene_to_file(Flow.INTRO)
    var screen: CardMenu = await _expect(Flow.INTRO)
    screen.press("play")

    var story: Story = await _expect(Flow.STORY)
    await _frames(2)
    _check(story.hint != "" and story.cards.is_empty(), "the story has no buttons, only the hint")
    story.skip()

    screen = await _expect(Flow.SESSION_NAME)
    screen.press("ok")

    screen = await _expect(Flow.INSTRUCTION)
    await _frames(10)
    screen.press("go")

    screen = await _expect(Flow.LEVEL_SELECT)
    _check(session.has_seen_instruction, "the expedition remembers how to play")
    _check(screen.cards[0]["disabled"] == false, "the first world is open")
    _check(screen.cards[1]["disabled"] == true, "the second world is locked")
    screen.press("world:0")
    await _frames(2)
    _check(screen.cards.size() == 6, "a world shows five levels and Back")
    _check(screen.cards[1]["disabled"] == true, "the second level is locked")
    screen.press("level:0")

    var level: Level = await _expect(Flow.LEVEL)
    _check(level.mine.dwarves.size() == 1, "without a camera, the first dwarf is there")
    var start: float = level.mine.dwarf_of(0).pos.x

    # NOTE (mristin):
    # A second player joins with her jump key, W.
    var w := InputEventKey.new()
    w.physical_keycode = KEY_W
    w.keycode = KEY_W
    w.pressed = true
    Input.parse_input_event(w)
    await _frames(5)
    _check(level.mine.dwarf_of(1) != null, "the second player joins with her key")

    var key := InputEventKey.new()
    key.physical_keycode = KEY_UP
    key.keycode = KEY_UP
    key.pressed = true
    for i in range(6):
        Input.parse_input_event(key)
        await _frames(40)
    _check(
        level.mine.dwarf_of(0).hits >= 3,
        "Up swings the pickaxe of the first dwarf, got %d hits" % level.mine.dwarf_of(0).hits
    )
    _check(level.mine.dwarf_of(1).hits == 0, "the second dwarf did not swing")
    var right := InputEventKey.new()
    right.physical_keycode = KEY_RIGHT
    right.keycode = KEY_RIGHT
    right.pressed = true
    Input.parse_input_event(right)
    await _frames(30)
    right = right.duplicate()
    right.pressed = false
    Input.parse_input_event(right)
    await _frames(5)
    _check(level.mine.dwarf_of(0).pos.x > start, "the dwarf walks to where its player stands")

    var escape := InputEventKey.new()
    escape.keycode = KEY_ESCAPE
    escape.pressed = true
    Input.parse_input_event(escape)
    await _frames(3)
    _check(level._menu != null, "Escape shows the break")
    level._menu.press("levels")
    screen = await _expect(Flow.LEVEL_SELECT)

    # NOTE (mristin):
    # The shop sells the boosters for the gems, and the house is built with them.
    session.purse.add_gems(30)
    Flow.open_shop(self, -1)
    screen = await _expect(Flow.SHOP)
    screen.press("buy:helmet")
    await _frames(2)
    _check(session.purse.boosters_of("helmet") == 1, "the shop sells a fire helmet")
    screen.press("house")
    screen = await _expect(Flow.HOUSE)
    var gems_before: int = session.purse.gems
    screen.press(screen.cards[0]["id"])
    await _frames(2)
    _check(session.purse.house_built() == 1, "the first stage of the house is built")
    _check(session.purse.gems < gems_before, "the house costs gems")
    screen.press("more")
    await _frames(2)
    screen.press("back")
    screen = await _expect(Flow.SHOP)
    screen.press("back")
    screen = await _expect(Flow.LEVEL_SELECT)

    change_scene_to_file(Flow.SESSIONS)
    screen = await _expect(Flow.SESSIONS)
    _check(screen.cards[0]["title"] == "Continue", "the expedition can be continued")
    screen.press("delete")
    await _frames(2)
    screen.press(screen.cards[0]["id"])
    await _frames(2)
    screen.press("confirm")
    await _frames(2)
    _check(session.sessions().is_empty(), "the expedition was deleted in three steps")

    print("RESULT: ", "OK" if _failures.is_empty() else "FAILED")
    quit(0 if _failures.is_empty() else 1)
