extends SceneTree
## Take a screenshot of a screen, e.g., to review it:
##
##   $GODOT --path . --windowed --resolution 1920x1080 --script dev/pictures/screenshot.gd -- \
##       res://scenes/intro/intro.tscn shot.png 3 [--level=3] [--bots=2] [--no-camera]
##
## The arguments: the scene, the picture to write and how many seconds to wait;
## --level sets the level, and --bots lets bots play its dwarves (see Level).


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var args := OS.get_cmdline_user_args()
    var scene := args[0]
    var output := args[1]
    var seconds := float(args[2]) if args.size() > 2 else 2.0
    for arg in args:
        if arg.begins_with("--level="):
            Flow.level_index = int(arg.trim_prefix("--level=")) - 1
        if arg.begins_with("--world="):
            Flow.world = int(arg.trim_prefix("--world="))
    change_scene_to_file(scene)
    await create_timer(seconds).timeout
    var image := root.get_texture().get_image()
    image.save_png(output)
    print("Wrote ", output)
    quit()
