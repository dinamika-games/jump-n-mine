extends SceneTree
## Draw the miner's helmets over the heads of a photo, as the game draws them
## over the camera picture, to review where they sit:
##
##   $GODOT --audio-driver Dummy --path . --windowed --resolution 1920x1080 \
##       --script dev/pictures/hat_preview.gd -- <photo> <heads> <output>
##
## The heads are "x1,y1,x2,y2[,roll];..." in pixels of the mirrored photo (as
## YOLOX gives them, see tests/JumpNMine.Tests), with the tilt of the head in
## radians, clockwise in the mirrored photo (as HeadVision gives it).


class Painter:
    extends Node2D

    var texture: Texture2D
    var heads: Array[Rect2] = []
    var rolls: Array[float] = []

    func _draw() -> void:
        var rect := Rect2(Vector2(320, 60), texture.get_size() * 2.0)
        draw_set_transform(Vector2(rect.position.x * 2 + rect.size.x, 0), 0.0, Vector2(-1, 1))
        draw_texture_rect(texture, rect, false)
        draw_set_transform(Vector2.ZERO)
        var layers := [{"texture": texture, "rect": rect, "flip": true}]
        for k in range(heads.size()):
            var head := heads[k]
            var size := maxf(head.size.x, head.size.y) * 2.0
            var center := rect.position + head.get_center() * 2.0
            Art.miner_hat(
                self,
                center - Vector2(0, size * 0.5),
                size,
                k,
                0.0,
                rolls[k],
                func(outline: PackedVector2Array) -> void: Art.camera_face(self, outline, layers)
            )


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var args := OS.get_cmdline_user_args()
    var painter := Painter.new()
    painter.texture = ImageTexture.create_from_image(Image.load_from_file(args[0]))
    for spec in args[1].split(";"):
        var v := spec.split(",")
        painter.heads.append(
            Rect2(float(v[0]), float(v[1]), float(v[2]) - float(v[0]), float(v[3]) - float(v[1]))
        )
        painter.rolls.append(float(v[4]) if v.size() > 4 else 0.0)
    root.add_child(painter)
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(args[2])
    quit()
