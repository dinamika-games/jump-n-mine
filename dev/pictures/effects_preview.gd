extends SceneTree
## Show the gas and the explosions in a little mine, and then the water (a deep
## pool with a dwarf wading in it, a shallow puddle, and a spring pouring into
## them), and take screenshots, to review the shaders:
##
##   $GODOT --audio-driver Dummy --path . --windowed --resolution 1920x1080 \
##       --script dev/pictures/effects_preview.gd -- <folder>


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var folder := OS.get_cmdline_user_args()[0]
    var level: Dictionary = LevelCatalog.LEVELS[3].duplicate(true)
    var mine := Mine.new(level, 1)
    var view := MineView.new(mine, 0)
    root.add_child(view)
    var y := Mine.SKY_ROWS + 3
    for x in range(3, 21, 4):
        mine.cells[mine.index(x, y)] = Mine.Cell.GAS
    mine._release(mine.index(7, y), 2.4)
    mine._release(mine.index(11, y), 0.6)
    mine._release(mine.index(15, y), 0.05)
    for k in range(int(0.3 * 60)):
        mine.step(1.0 / 60.0)
        view.show_events(mine.take_events())
        await process_frame
    root.get_texture().get_image().save_png(folder.path_join("effects_1.png"))
    for k in range(int(0.35 * 60)):
        mine.step(1.0 / 60.0)
        view.show_events(mine.take_events())
        await process_frame
    root.get_texture().get_image().save_png(folder.path_join("effects_2.png"))
    view.queue_free()
    await _water(folder)
    quit()


## A deep pool on the left, with a dwarf wading in it, a shallow puddle on the
## right, and a spring pouring into them; two screenshots half a second apart,
## to see the waves move.
func _water(folder: String) -> void:
    var level: Dictionary = LevelCatalog.LEVELS[5].duplicate(true)
    level["rival"] = false
    level["moles"] = []
    level["springs"] = []
    level["drain"] = 0.0
    var mine := Mine.new(level, 1)
    var top := Mine.SKY_ROWS + 3
    var middle := Mine.WIDTH / 2
    for y in range(top, top + 4):
        for x in range(1, Mine.WIDTH - 1):
            mine.cells[mine.index(x, y)] = Mine.Cell.AIR
    var walls: Array[Vector2i] = []
    for x in range(1, Mine.WIDTH - 1):
        walls.append(Vector2i(x, top + 4))
    for y in range(top + 1, top + 4):
        walls.append(Vector2i(middle, y))
    for at in walls:
        mine.cells[mine.index(at.x, at.y)] = Mine.Cell.ROCK
        mine.hits_left[mine.index(at.x, at.y)] = Mine.HITS[Mine.Cell.ROCK]
    for y in range(top + 1, top + 4):
        for x in range(1, middle):
            mine.water[mine.index(x, y)] = 1.0
    for x in range(middle + 1, Mine.WIDTH - 1):
        mine.water[mine.index(x, top + 3)] = 0.35
    var spring := mine.index(0, top)
    mine.cells[spring] = Mine.Cell.SPRING
    mine.springs.append(spring)
    mine.spring_water[spring] = 100.0
    mine.hits_left[spring] = Mine.HITS[Mine.Cell.SPRING]
    var dwarf: Mine.Dwarf = mine.dwarves[0]
    dwarf.pos = Vector2(2.5, top + 4)
    dwarf.vel = Vector2.ZERO
    dwarf.target_x = dwarf.pos.x
    mine.view_top = top - 0.6
    var view := MineView.new(mine, 1)
    root.add_child(view)
    for shot in range(1, 3):
        for k in range(int(0.5 * 60)):
            mine.step(1.0 / 60.0)
            mine.view_top = top - 0.6
            view.show_events(mine.take_events())
            await process_frame
        root.get_texture().get_image().save_png(folder.path_join("water_%d.png" % shot))
