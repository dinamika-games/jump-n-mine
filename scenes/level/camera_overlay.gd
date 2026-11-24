class_name CameraOverlay
extends Control

## The camera picture, dim, over the mine or behind the menu cards, so that the
## players see themselves and what they play at once: a miner's helmet on every
## player and a dim beam of light from the lamp on her helmet to what she
## points at (her dwarf in the mine, the card in a menu), so that she sees
## which is hers.
##
## The picture is zoomed so that the part of it where the heads point (see
## [constant Vision.HEAD_RANGE]) spans [member span] on the screen: the lamp of
## each player lies right above what she points at. Up and down, it follows the
## heads slowly, so that they stay at [member anchor_y].
##
## The user of the overlay tells the color of each head ([member slot_of_head])
## and where its beam goes ([member target_of_head]). The overlay draws the
## beams and the helmets; it draws the picture under them itself if
## [member show_picture], or the user draws it with [method draw_picture], e.g.,
## behind its own drawings.

## How much of the camera picture shows.
const PICTURE_ALPHA := 0.3

## How strong the beams of light are.
const BEAM_STRENGTH := 0.55

## The beam is this wide at the lamp, in helmet sizes.
const BEAM_WIDTH_AT_LAMP := 0.25

## The zoomed picture shows the heads far larger than this; the helmets are
## drawn this large at most (in pixels), on the top of the heads.
const MAX_HAT := 190.0

## The time constant (s) with which the picture follows the heads up and down.
const FOLLOW_TAU := 1.5

## Where on the screen (x, in pixels) a head at the start and at the end of
## [constant Vision.HEAD_RANGE] points.
var span := Vector2(0.0, 1920.0)

## Where on the screen (y, in pixels) the heads stay.
var anchor_y := 300.0

## The slot of each head (see [method Dwarves.color]), by the id of the head;
## a head without one gets a white helmet and no beam.
var slot_of_head := {}

## Where the beam of a head goes: called with the id of the head and its slot,
## returns the point on the screen and the width of the beam there (as a
## Vector3: x, y and the width), or null for no beam.
var target_of_head: Callable

## Whether the overlay draws the picture under the helmets.
var show_picture := true

var _time := 0.0
## The height of the heads in the picture (as a share of it), smoothed.
var _head_y := 0.4
var _beams := EffectLayer.new("res://scenes/effects/beam.gdshader")
var _hats := Control.new()


func _init() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _beams.paint = _paint_beams
    add_child(_beams)
    _hats.set_anchors_preset(Control.PRESET_FULL_RECT)
    _hats.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hats.draw.connect(_draw_hats)
    add_child(_hats)


func _process(delta: float) -> void:
    _time += delta
    var vision := get_node_or_null("/root/Vision")
    if vision != null and not vision.heads.is_empty():
        var sum := 0.0
        for id in vision.heads:
            sum += float(vision.heads[id]["position"].y)
        var mean: float = sum / vision.heads.size()
        _head_y += (mean - _head_y) * (1.0 - exp(-delta / FOLLOW_TAU))
    queue_redraw()
    _hats.queue_redraw()


## Where the camera picture lies on the screen, or an empty rectangle if there
## is none.
func picture_rect() -> Rect2:
    var vision := get_node_or_null("/root/Vision")
    if vision == null:
        return Rect2()
    var texture: Texture2D = vision.preview()
    if texture == null or texture.get_width() <= 0:
        return Rect2()
    var range_x: Vector2 = vision.HEAD_RANGE
    var width := (span.y - span.x) / (range_x.y - range_x.x)
    var left := span.x - range_x.x * width
    var height := width * texture.get_height() / texture.get_width()
    return Rect2(left, anchor_y - _head_y * height, width, height)


## Draw the camera picture, dim and mirrored, on the canvas (e.g., behind the
## drawings of the user, see [member show_picture]).
func draw_picture(canvas: CanvasItem) -> void:
    var vision := get_node_or_null("/root/Vision")
    var rect := picture_rect()
    if vision == null or rect.size == Vector2.ZERO:
        return
    # NOTE (mristin):
    # The picture is mirrored, so that the players move in it as in a mirror.
    canvas.draw_set_transform(Vector2(rect.position.x * 2 + rect.size.x, 0), 0.0, Vector2(-1, 1))
    canvas.draw_texture_rect(vision.preview(), rect, false, Color(1, 1, 1, PICTURE_ALPHA))
    canvas.draw_set_transform(Vector2.ZERO)


func _draw() -> void:
    if show_picture:
        draw_picture(self)


## Where the helmet of the head goes on the screen: the top of its box and its
## size, as [method Art.miner_hat] takes them, with its brim on the forehead of
## the head in the picture.
func _head_on_screen(head: Dictionary, rect: Rect2) -> Array:
    var position: Vector2 = head["position"]
    var size: float = head["size"] * rect.size.y
    var top := rect.position + position * rect.size - Vector2(0, size * 0.5)
    var hat := minf(size, MAX_HAT)
    return [top + Vector2(0, size * 0.3 - hat * 0.52), hat]


func _paint_beams(canvas: EffectLayer) -> void:
    var vision := get_node_or_null("/root/Vision")
    var rect := picture_rect()
    if vision == null or rect.size == Vector2.ZERO or not target_of_head.is_valid():
        return
    for id in vision.heads:
        var slot := int(slot_of_head.get(id, -1))
        if slot < 0:
            continue
        var target: Variant = target_of_head.call(id, slot)
        if target == null:
            continue
        var head: Dictionary = vision.heads[id]
        var placed := _head_on_screen(head, rect)
        var lamp := Art.hat_lamp(placed[0], placed[1], head.get("roll", 0.0))
        var end := Vector2(target.x, target.y)
        var direction := end - lamp
        if direction.length() < 1.0:
            continue
        var across := direction.normalized().orthogonal()
        var near := across * float(placed[1]) * BEAM_WIDTH_AT_LAMP * 0.5
        var far := across * float(target.z) * 0.5
        var color := Dwarves.color(slot)
        color.a = BEAM_STRENGTH
        (
            canvas
            . draw_polygon(
                PackedVector2Array([lamp - near, lamp + near, end + far, end - far]),
                PackedColorArray([color, color, color, color]),
                PackedVector2Array([Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)]),
                canvas.white(),
            )
        )


func _draw_hats() -> void:
    var vision := get_node_or_null("/root/Vision")
    var rect := picture_rect()
    if vision == null or rect.size == Vector2.ZERO:
        return
    # NOTE (mristin):
    # A miner's helmet on every player, with the brim in her color. The
    # picture is dim, so the helmets lie over the heads.
    for id in vision.heads:
        var head: Dictionary = vision.heads[id]
        var placed := _head_on_screen(head, rect)
        var slot := int(slot_of_head.get(id, -1))
        Art.miner_hat(_hats, placed[0], placed[1], slot, _time + id, head.get("roll", 0.0))
