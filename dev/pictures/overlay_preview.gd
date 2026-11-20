extends SceneTree
## Take a screenshot of a level with the camera overlay (see CameraOverlay), with
## a photo in place of the camera picture and made-up heads, to review the
## helmets and the beams of light without a camera:
##
##   $GODOT --audio-driver Dummy --path . --windowed --resolution 1920x1080 \
##       --script dev/pictures/overlay_preview.gd -- shot.png [photo.png] [seconds] --no-camera
##
## Run it on a virtual display (e.g., xvfb-run), so that no window opens.

const _HEADS := {
    0: Vector2(0.3, 0.35),
    1: Vector2(0.72, 0.42),
}


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var args := OS.get_cmdline_user_args()
    var output := args[0]
    var photo := args[1] if args.size() > 1 else "res://tests/JumpNMine.Tests/data/crew_of_six_640x480.png"
    var seconds := float(args[2]) if args.size() > 2 else 3.0

    var image := Image.load_from_file(photo)
    var vision := root.get_node("/root/Vision")
    vision.preview_override = ImageTexture.create_from_image(image)

    Flow.level_index = 0
    change_scene_to_file("res://scenes/level/level.tscn")
    var start := Time.get_ticks_msec() / 1000.0
    while Time.get_ticks_msec() / 1000.0 - start < seconds:
        var t := Time.get_ticks_msec() / 1000.0 - start
        for id in _HEADS:
            var position: Vector2 = _HEADS[id] + Vector2(0.04 * sin(t * 0.7 + id), 0.0)
            vision.heads[id] = {
                "position": position,
                "size": 0.2,
                "rise": 0.1,
                "jump_line": position.y - 0.16,
                "jumping": false,
                "roll": 0.1 * sin(t + id),
                "jumped": -1.0,
            }
        await process_frame
    var shot := root.get_texture().get_image()
    shot.save_png(output)
    print("Wrote ", output)
    quit()
