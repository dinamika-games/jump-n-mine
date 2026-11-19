extends SceneTree
## Show the gas and the explosions in a little mine, and take screenshots, to
## review the shaders:
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
    quit()
