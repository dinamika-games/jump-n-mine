class_name Art
extends RefCounted

## The pictures of the game: the painted sprites of assets/pictures/ (cut by
## dev/pictures/cut_sprites/), drawn at the size the game needs.
##
## Every function draws on the canvas item at a position in pixels, so that the
## menus and the level share them.

const OUTLINE := Color("#1a1016")
const GEM_COLORS := [Color("#3ee6f0"), Color("#f04fd0"), Color("#7cf04f"), Color("#ffd23e")]
const STEEL := Color("#b9c3cf")
const GOLD := Color("#ffcf3a")

const _PICTURES := "res://assets/pictures/"

## The frames of the water pouring from a spring (assets/pictures/water/), and
## how many per second.
const POUR_FRAMES := 6
const POUR_FPS := 10.0

## The water leaves the pipe in the top left corner of a frame of the pouring
## water, this far down (as a fraction of its height); it falls about straight
## down from the [constant POUR_STRETCH] of its height, and splashes from the
## [constant POUR_SPLASH] down.
const POUR_MOUTH := 0.075
const POUR_STRETCH := 0.5
const POUR_SPLASH := 0.62

## A frame of the pouring water is this tall when the water falls freely, in
## blocks; it is as wide as its picture is.
const POUR_HEIGHT := 1.6

## The height of the crystal of a plate, waiting and pressed, as a part of the tile.
const _PLATE_CRYSTAL := [0.098, 0.119]

## The worlds by their index into [constant LevelCatalog.WORLDS].
const _WORLDS := ["copper_hills", "sunken_halls", "dragon_deeps"]

## The colors of the dwarves' tunics, by their slot.
const _DWARF_COLORS := ["red", "blue", "green", "yellow"]

## The slot of the evil miner (see [constant Mine.RIVAL]): until his own
## pictures are painted (assets/pictures/dwarves/evil/), he is a red dwarf in
## the shadows.
const _EVIL := 4
const _EVIL_SHADE := Color(0.42, 0.34, 0.5)

## In a picture of the mole (assets/pictures/mole/, 400 x 300), the body is
## this long, and the feet stand on this line.
const _MOLE_BODY := 340.0
const _MOLE_FEET := 270.0

## In a dwarf picture, the dwarf is this tall (as a share of the picture), with
## its feet at this point (as shares of the picture).
const _DWARF_TALL := 244.0 / 362.0
const _DWARF_FEET := Vector2(0.54, 328.0 / 362.0)

## The helmet is this wide (in head sizes), and the bottom of its brim lies
## this far below the center of the head box (in head sizes).
const _HAT_WIDTH := 1.3
const _HAT_BRIM := 0.02

## The face which covers the brim, as an ellipse in head sizes: its center
## below the center of the head box, and its half width and half height. Its
## top is the hairline.
const _FACE_CENTER := 0.22
const _FACE_RADII := Vector2(0.3, 0.32)

## The brim casts a shadow this far down the forehead (in head sizes), this dark.
const _SHADOW_DEPTH := 0.12
const _SHADOW_ALPHA := 0.45

## The loaded pictures, by their path. We must keep them: a picture which is
## freed right after a draw call is drawn white, since the frame is rendered
## later.
static var _pictures := {}


## The picture of the path under assets/pictures/ (loaded once).
static func picture(path: String) -> Texture2D:
    if not _pictures.has(path):
        _pictures[path] = load(_PICTURES + path)
    return _pictures[path]


## Forget the loaded pictures (when the game quits, so that none is left in use).
static func forget_pictures() -> void:
    _pictures.clear()


## A number in [0, 1) which depends only on the integers, for the details which
## must stay the same from frame to frame.
static func hash01(a: int, b: int, c := 0) -> float:
    var h := (a * 73856093) ^ (b * 19349663) ^ (c * 83492791)
    h = (h ^ (h >> 13)) * 1274126177
    h = h ^ (h >> 16)
    return float(h & 0xFFFF) / 65536.0


## A block of earth or rock of the world (its index), of the cell (which picks
## one of the two paintings), with its cracks from the damage in [0, 1).
static func block(
    canvas: CanvasItem, rect: Rect2, world: int, cell: Vector2i, damage: float, hard: bool
) -> void:
    var variant := 1 + int(hash01(cell.x, cell.y, 7) * 2.0)
    var kind := "rock" if hard else "earth"
    canvas.draw_texture_rect(
        picture("blocks/%s/%s_%d.png" % [_world(world), kind, variant]), rect, false
    )
    cracks(canvas, rect, damage)


## The top block of earth with its grass.
static func grass(canvas: CanvasItem, rect: Rect2, world: int, damage: float) -> void:
    canvas.draw_texture_rect(picture("blocks/%s/grass.png" % _world(world)), rect, false)
    cracks(canvas, rect, damage)


## The cracks of a block: more, the more it is damaged.
static func cracks(canvas: CanvasItem, rect: Rect2, damage: float) -> void:
    if damage <= 0.0:
        return
    var stage := clampi(int(ceil(damage * 3.0 - 0.01)), 1, 3)
    canvas.draw_texture_rect(picture("blocks/crack_%d.png" % stage), rect, false)


## The bedrock of the walls and the floor.
static func bedrock(canvas: CanvasItem, rect: Rect2) -> void:
    canvas.draw_texture_rect(picture("blocks/bedrock.png"), rect, false)


## The sky of the world, as wide as the rectangle.
static func sky(canvas: CanvasItem, rect: Rect2, world: int) -> void:
    canvas.draw_texture_rect(picture("blocks/%s/sky.png" % _world(world)), rect, false)


## The far wall of the cave of the world, repeated over the rectangle, shifted
## by the offset (for the parallax).
static func cave(canvas: CanvasItem, rect: Rect2, world: int, offset: Vector2) -> void:
    var texture := picture("blocks/%s/cave.png" % _world(world))
    var tile := texture.get_size()
    var start := rect.position - Vector2(fposmod(offset.x, tile.x), fposmod(offset.y, tile.y))
    var y := start.y
    while y < rect.end.y:
        var x := start.x
        while x < rect.end.x:
            canvas.draw_texture_rect(texture, Rect2(Vector2(x, y), tile), false)
            x += tile.x
        y += tile.y


## A block of earth with a pocket of gas glowing in it, for the menus (the
## level draws the gas with a shader, see scenes/effects/gas.gdshader).
static func gas_pocket(canvas: CanvasItem, rect: Rect2, world: int, time: float) -> void:
    block(canvas, rect, world, Vector2i(1, 1), 0.0, false)
    var center := rect.get_center()
    var s := rect.size.x
    for k in range(6):
        var angle := k * TAU / 6.0 + time * 0.8
        var r := s * (0.12 + 0.1 * sin(time * 2.0 + k))
        var at := center + Vector2.from_angle(angle) * s * 0.16
        canvas.draw_circle(at, r, Color(0.45, 0.95, 0.2, 0.55))
    canvas.draw_circle(center, s * 0.18, Color(0.8, 1.0, 0.35, 0.8))


## A miner's helmet with its glowing lamp, for a head in the camera picture:
## the middle of the top of the head box of YOLOX, its size (in pixels) and the
## tilt of the head (radians, clockwise); the brim has the color of the dwarf of
## the slot (white for -1).
##
## The helmet sits over the hair, and the forehead covers the middle of the
## brim, so that the head wears it: [param face] paints the face again over the
## helmet, given the outline of the face (see [method camera_face]); without
## it, the helmet lies over the head.
static func miner_hat(
    canvas: CanvasItem,
    top: Vector2,
    size: float,
    slot: int,
    time: float,
    roll: float = 0.0,
    face: Callable = Callable()
) -> void:
    var color: String = "white" if slot < 0 or slot > 3 else _DWARF_COLORS[slot]
    var texture := picture("helmets/%s.png" % color)
    var width := size * _HAT_WIDTH
    # NOTE (mristin):
    # We place the helmet relative to the center of the head box, and turn it
    # with the head around there. The bottom of the brim lies at 76 % of the
    # picture.
    var center := top + Vector2(0, size * 0.5)
    var brim := Vector2(0, size * _HAT_BRIM)
    var rect := Rect2(brim - Vector2(width * 0.5, width * 0.76), Vector2(width, width))
    var flicker := 0.92 + 0.08 * sin(time * 7.0)
    canvas.draw_set_transform(center, roll, Vector2.ONE)
    canvas.draw_texture_rect(texture, rect, false, Color(flicker, flicker, flicker, 1.0))
    canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if face.is_valid():
        face.call(_face_outline(center, size, roll))
        _brim_shadow(canvas, center, size, roll)


## Paint the camera picture again inside the outline of a face, over its
## helmet, as the picture shows it: the layers are drawn from the bottom up,
## each a Dictionary with a "color" (the modulation) and optionally a
## "texture" drawn into a "rect" (in pixels), mirrored if "flip".
static func camera_face(canvas: CanvasItem, outline: PackedVector2Array, layers: Array) -> void:
    for layer: Dictionary in layers:
        var color: Color = layer.get("color", Color.WHITE)
        var texture: Texture2D = layer.get("texture", null)
        if texture == null:
            canvas.draw_colored_polygon(outline, color)
            continue
        var rect: Rect2 = layer["rect"]
        var flip: bool = layer.get("flip", false)
        var uvs := PackedVector2Array()
        for point in outline:
            var uv := (point - rect.position) / rect.size
            if flip:
                uv.x = 1.0 - uv.x
            uvs.append(uv)
        canvas.draw_colored_polygon(outline, color, uvs, texture)


## The shadow of the brim on the forehead, under a helmet: dark at the brim,
## fading out down the forehead.
static func _brim_shadow(canvas: CanvasItem, center: Vector2, size: float, roll: float) -> void:
    # NOTE (mristin):
    # A head of a pixel or two has no forehead to shade.
    if size < 4.0:
        return
    var top := _FACE_CENTER - _FACE_RADII.y
    var bottom := _HAT_BRIM + _SHADOW_DEPTH
    var points := PackedVector2Array()
    var colors := PackedColorArray()
    # NOTE (mristin):
    # The arc of the face above the bottom of the shadow, from its left to its
    # right; the straight line back closes it. The arc starts and ends exactly
    # where it crosses the bottom, since points flattened onto the bottom would
    # lie on the closing line, and Godot could not triangulate the polygon.
    var cut := asin(clampf((bottom - _FACE_CENTER) / _FACE_RADII.y, -1.0, 0.0))
    var first := PI - cut
    var last := TAU + cut
    for k in range(17):
        var angle := lerpf(first, last, float(k) / 16.0)
        var local := Vector2(cos(angle) * _FACE_RADII.x, _FACE_CENTER + sin(angle) * _FACE_RADII.y)
        points.append(center + (local * size).rotated(roll))
        var shade := clampf((bottom - local.y) / (bottom - top), 0.0, 1.0)
        colors.append(Color(0, 0, 0, _SHADOW_ALPHA * shade))
    canvas.draw_polygon(points, colors)


## Where the lamp of a helmet (see [method miner_hat]) shines: it sits at 48 %
## of the width and 34 % of the height of the helmet picture.
static func hat_lamp(top: Vector2, size: float, roll: float = 0.0) -> Vector2:
    var width := size * _HAT_WIDTH
    var center := top + Vector2(0, size * 0.5)
    var brim := Vector2(0, size * _HAT_BRIM)
    var local := brim + Vector2((0.48 - 0.5) * width, (0.34 - 0.76) * width)
    return center + local.rotated(roll)


## The outline of the face in a head (see [method miner_hat]).
static func _face_outline(center: Vector2, size: float, roll: float) -> PackedVector2Array:
    var outline := PackedVector2Array()
    for k in range(32):
        var angle := k * TAU / 32.0
        var local := Vector2(cos(angle) * _FACE_RADII.x, _FACE_CENTER + sin(angle) * _FACE_RADII.y)
        outline.append(center + (local * size).rotated(roll))
    return outline


## The line which a player's head must rise above for a jump, in the camera
## picture: light blue and dashed with an arrow up, gold while she jumps. It
## spans the part of the picture around her head (from left to right, in
## pixels); thick, so that it shows on the overlay.
static func jump_line(
    canvas: CanvasItem, y: float, left: float, right: float, jumping: bool, thickness: float
) -> void:
    var color := Color("#ffcf3a") if jumping else Color("#8fd8ff")
    var dash := thickness * 3.0
    var arrow := thickness * 3.0
    var x := left
    while x < right - arrow * 1.2:
        var end := minf(x + dash, right - arrow * 1.2)
        canvas.draw_line(Vector2(x, y), Vector2(end, y), OUTLINE, thickness * 1.8)
        canvas.draw_line(Vector2(x, y), Vector2(end, y), color, thickness)
        x += dash * 1.7
    var tip := PackedVector2Array(
        [
            Vector2(right - arrow * 1.1, y + arrow * 0.3),
            Vector2(right, y + arrow * 0.3),
            Vector2(right - arrow * 0.55, y - arrow * 0.8),
        ]
    )
    canvas.draw_colored_polygon(tip, color)
    tip.append(tip[0])
    canvas.draw_polyline(tip, OUTLINE, maxf(1.5, thickness * 0.4))


## An iron gate in the floor, closed: bars over the dark. The tiles of a row
## meet in the middle of a bar, so that the row repeats seamlessly.
static func gate(canvas: CanvasItem, rect: Rect2) -> void:
    canvas.draw_rect(rect, Color("#1c1820"))
    canvas.draw_texture_rect(picture("blocks/gate.png"), rect, false)


## A stone plate in the floor which a dwarf presses by standing on it; its
## crystal glows when it is pressed, and pulses while it waits.
static func plate(canvas: CanvasItem, rect: Rect2, pressed: bool, time: float) -> void:
    var tile := "blocks/plate_pressed.png" if pressed else "blocks/plate_waiting.png"
    canvas.draw_texture_rect(picture(tile), rect, false)
    var crystal := rect.position + rect.size * Vector2(0.5, _PLATE_CRYSTAL[int(pressed)])
    var glow := (
        Color(0.5, 1.0, 0.4, 0.3)
        if pressed
        else Color(1.0, 0.85, 0.3, 0.15 + 0.15 * sin(time * 4.0))
    )
    canvas.draw_circle(crystal, rect.size.x * 0.1, glow)


## A spring in the wall: its pipe (the water is drawn by [method pour]), or
## sealed with a plug.
static func spring(canvas: CanvasItem, rect: Rect2, sealed: bool, damage: float) -> void:
    canvas.draw_texture_rect(
        picture("blocks/spring_sealed.png" if sealed else "blocks/spring_empty.png"), rect, false
    )
    cracks(canvas, rect, damage)


## The water pouring from the mouth of a spring, to the side (1 to the right,
## -1 to the left), down to the floor or the surface of the water at the row
## landing (in pixels), with blocks of the size (in pixels), at the time. A
## long fall stretches the falling part of the stream, and a short one shrinks
## the whole stream.
static func pour(
    canvas: CanvasItem, mouth: Vector2, landing: float, block: float, side: int, time: float
) -> void:
    var frame := picture("water/pour_%d.png" % (int(time * POUR_FPS) % POUR_FRAMES + 1))
    var natural := POUR_HEIGHT * block
    var aspect := float(frame.get_width()) / frame.get_height()
    var top := mouth.y - POUR_MOUTH * natural
    var height := landing - top
    if height < block * 0.3:
        return
    canvas.draw_set_transform(Vector2(mouth.x, top), 0.0, Vector2(side, 1))
    var source := Vector2(frame.get_width(), frame.get_height())
    if height <= natural:
        var k := height / natural
        var width := natural * aspect * maxf(k, 0.6)
        canvas.draw_texture_rect(frame, Rect2(0, 0, width, height), false)
    else:
        var width := natural * aspect
        var head := POUR_STRETCH * natural
        var tail := (1.0 - POUR_SPLASH) * natural
        canvas.draw_texture_rect_region(
            frame, Rect2(0, 0, width, head), Rect2(0, 0, source.x, POUR_STRETCH * source.y)
        )
        canvas.draw_texture_rect_region(
            frame,
            Rect2(0, head, width, height - head - tail),
            Rect2(0, POUR_STRETCH * source.y, source.x, (POUR_SPLASH - POUR_STRETCH) * source.y)
        )
        canvas.draw_texture_rect_region(
            frame,
            Rect2(0, height - tail, width, tail),
            Rect2(0, POUR_SPLASH * source.y, source.x, (1.0 - POUR_SPLASH) * source.y)
        )
    canvas.draw_set_transform(Vector2.ZERO)


## A gem, of the color by the index, as big as the size (its half height).
static func gem(canvas: CanvasItem, center: Vector2, size: float, color_index: int) -> void:
    _centered(canvas, picture("items/gem_%d.png" % (absi(color_index) % 4)), center, size * 2.2)


## The badge of a booster (see [constant Mine.BOOSTERS]), as big as the radius.
static func booster(canvas: CanvasItem, center: Vector2, size: float, kind: String) -> void:
    _centered(canvas, picture("items/booster_%s.png" % kind), center, size * 2.0)


## The dwarf of the slot (0 to 3, by the color of its tunic, and 4 for the
## evil miner) standing at the feet, as tall as the height (in pixels).
##
## The state: "facing" (1 or -1), "swing" (in [0, 1], 1 at the start of a
## swing), "sideways" (the swing strikes the block beside the dwarf, not the
## one below), "stun" (dizzy), "time" (for the animation), "walking",
## "boosters" (the kinds on the dwarf) and "under_water".
static func dwarf(
    canvas: CanvasItem, feet: Vector2, height: float, slot: int, state: Dictionary
) -> void:
    var time := float(state.get("time", 0.0))
    var boosters: Array = state.get("boosters", [])
    var swing := float(state.get("swing", 0.0))
    var pose := "idle"
    if bool(state.get("stun", false)):
        pose = "dizzy"
    elif swing > 0.0 and bool(state.get("sideways", false)):
        if swing > 0.75:
            pose = "side_back"
        elif swing > 0.3:
            pose = "side_hit"
        else:
            pose = "side_recoil"
    elif swing > 0.0:
        if swing > 0.7:
            pose = "raised"
        elif swing > 0.4:
            pose = "swing"
        else:
            pose = "hit_down" if swing > 0.2 else "hit_down_b"
    elif bool(state.get("under_water", false)):
        pose = "under_water"
    elif "helmet" in boosters:
        pose = "fire_helmet"
    elif "boots" in boosters:
        pose = "spring_boots"
    elif "gold_pick" in boosters:
        pose = "golden_pickaxe"
    var walking := bool(state.get("walking", false)) and swing <= 0.0
    if walking and pose == "idle":
        # NOTE (mristin):
        # A walk cycle of six frames, ten frames a second.
        pose = "walk_%d" % (1 + int(fmod(time * 10.0, 6.0)))
    var shade := Color.WHITE
    var path := "dwarves/%s/%s.png" % [_DWARF_COLORS[clampi(slot, 0, 3)], pose]
    if slot == _EVIL:
        if ResourceLoader.exists(_PICTURES + "dwarves/evil/%s.png" % pose):
            path = "dwarves/evil/%s.png" % pose
        else:
            shade = _EVIL_SHADE
    var texture := picture(path)
    var size := Vector2.ONE * height / _DWARF_TALL
    var facing := int(state.get("facing", 1))
    canvas.draw_set_transform(feet, 0.0, Vector2(facing, 1))
    canvas.draw_texture_rect(texture, Rect2(-_DWARF_FEET * size, size), false, shade)
    canvas.draw_set_transform(Vector2.ZERO)
    if slot == _EVIL and shade != Color.WHITE:
        # NOTE (mristin):
        # The badge of Queen Treacher on his chest: a black crown on purple.
        var badge := feet + Vector2(0.0, -height * 0.42)
        canvas.draw_circle(badge, height * 0.09, OUTLINE)
        canvas.draw_circle(badge, height * 0.075, Color("#6a2a8a"))
        _crown(canvas, badge, height * 0.06, Color("#141018"))
    if float(state.get("stars", 0.0)) > 0.0:
        dizzy_stars(canvas, feet + Vector2(0, -height * 1.02), height * 0.42, time)


## A little crown, as wide as twice the size, with its middle at the center.
static func _crown(canvas: CanvasItem, center: Vector2, size: float, color: Color) -> void:
    var s := size
    (
        canvas
        . draw_colored_polygon(
            PackedVector2Array(
                [
                    center + Vector2(-s, s * 0.6),
                    center + Vector2(-s, -s * 0.5),
                    center + Vector2(-s * 0.5, s * 0.05),
                    center + Vector2(0, -s * 0.8),
                    center + Vector2(s * 0.5, s * 0.05),
                    center + Vector2(s, -s * 0.5),
                    center + Vector2(s, s * 0.6),
                ]
            ),
            color
        )
    )


## Stars circling over a knocked out head, with their middle at the center.
static func dizzy_stars(canvas: CanvasItem, center: Vector2, width: float, time: float) -> void:
    for k in range(5):
        var angle := time * 4.0 + k * TAU / 5.0
        var at := center + Vector2(cos(angle) * width * 0.5, sin(angle) * width * 0.16)
        var size := width * (0.1 + 0.03 * sin(angle))
        _star(canvas, at, size * 1.25, OUTLINE)
        _star(canvas, at, size, Color("#ffe066"))


## A mole with its middle at the center, as long as the size, looking to the
## facing (1 right, -1 left), in the phase of [MineMoles.Mole] ("dig", "peek",
## "back", "cry" or "flee") for the time (in seconds) of the phase: it digs (and
## runs) with two frames, looks back and sniffs while it peeks, and cries. Its
## feet stand at a little more than half of the size below the center. Without
## its pictures, it is drawn in code.
static func mole(
    canvas: CanvasItem, center: Vector2, size: float, facing: int, phase: String, time: float
) -> void:
    var pose := ""
    match phase:
        "dig", "back":
            pose = "dig_%d" % (1 + int(fmod(time * 6.0, 2.0)))
        "flee":
            pose = "dig_%d" % (1 + int(fmod(time * 10.0, 2.0)))
        "peek":
            pose = "peek_1" if time < MineMoles.PEEK * 0.5 else "peek_2"
        "cry":
            pose = "cry_%d" % (1 + int(fmod(time * 2.2, 2.0)))
    if pose != "" and ResourceLoader.exists(_PICTURES + "mole/%s.png" % pose):
        var tile := Vector2(400.0, 300.0) * size / _MOLE_BODY
        var feet := center + Vector2(0, size * 0.59)
        canvas.draw_set_transform(feet, 0.0, Vector2(facing, 1))
        canvas.draw_texture_rect(
            picture("mole/%s.png" % pose),
            Rect2(Vector2(-tile.x * 0.5, -tile.y * _MOLE_FEET / 300.0), tile),
            false
        )
        canvas.draw_set_transform(Vector2.ZERO)
        return
    var crying := phase == "cry"
    var bob := sin(time * (14.0 if crying else 6.0)) * size * 0.03
    var c := center + Vector2(0, bob)
    var f := float(facing)
    if phase == "peek" and fmod(time, 1.2) < 0.6:
        f = -f
    var fur := Color("#5b4636")
    # The body, the belly and the paws.
    _ellipse(canvas, c, Vector2(size * 0.5, size * 0.36) + Vector2.ONE * 3.0, OUTLINE, 0.0)
    _ellipse(canvas, c, Vector2(size * 0.5, size * 0.36), fur, 0.0)
    _ellipse(
        canvas,
        c + Vector2(f * size * 0.08, size * 0.12),
        Vector2(size * 0.3, size * 0.18),
        fur.lightened(0.25),
        0.0
    )
    for k in [-1, 1]:
        var paw := c + Vector2(f * size * (0.32 + 0.05 * k), size * 0.26)
        canvas.draw_circle(paw, size * 0.1, OUTLINE)
        canvas.draw_circle(paw, size * 0.08, Color("#f2a7b0"))
    # The snout and the nose.
    var snout := c + Vector2(f * size * 0.5, -size * 0.04)
    canvas.draw_circle(snout, size * 0.13, OUTLINE)
    canvas.draw_circle(snout, size * 0.11, fur.lightened(0.15))
    canvas.draw_circle(snout + Vector2(f * size * 0.1, -size * 0.02), size * 0.08, Color("#ff7f9a"))
    # The eyes: tiny dots, or shut tight and crying.
    var eye := c + Vector2(f * size * 0.28, -size * 0.17)
    if crying:
        canvas.draw_line(
            eye - Vector2(size * 0.06, 0),
            eye + Vector2(size * 0.06, 0),
            OUTLINE,
            maxf(2.0, size * 0.035)
        )
        canvas.draw_arc(
            snout + Vector2(-f * size * 0.1, size * 0.12), size * 0.07, 0.0, PI, 8, OUTLINE, 3.0
        )
        for k in range(3):
            var t := fmod(time * 1.6 + k / 3.0, 1.0)
            var tear := eye + Vector2(-f * size * (0.05 + 0.25 * t), size * (0.05 + 0.6 * t * t))
            canvas.draw_circle(tear, size * 0.055, Color(0.55, 0.8, 1.0, 1.0 - t))
    else:
        canvas.draw_circle(eye, size * 0.045, OUTLINE)
        canvas.draw_circle(eye + Vector2(size * 0.012, -size * 0.012), size * 0.015, Color.WHITE)


## A dragon flying with its middle at the center, as wide as the size, its
## mouth glowing by the glow in [0, 1]; a glow above 1 means that it spits.
static func dragon(
    canvas: CanvasItem, center: Vector2, size: float, facing: int, time: float, glow: float
) -> void:
    var frame := 1 if fmod(time * 5.0, 2.0) < 1.0 else 2
    if glow > 1.0:
        frame = 4
    elif glow > 0.4:
        frame = 3
    var texture := picture("dragon/frame_%d.png" % frame)
    var tile := texture.get_size() * size / texture.get_size().x
    canvas.draw_set_transform(
        center - Vector2(tile.x * 0.5 * facing, tile.y * 0.5), 0.0, Vector2(facing, 1)
    )
    canvas.draw_texture_rect(texture, Rect2(Vector2.ZERO, tile), false)
    canvas.draw_set_transform(Vector2.ZERO)


## A ball of fire, falling, with its core at the center.
static func fire(canvas: CanvasItem, center: Vector2, size: float, time: float) -> void:
    var texture := picture("dragon/fire_%d.png" % (1 + int(fmod(time * 12.0, 3.0))))
    var tile := texture.get_size() * size * 2.6 / texture.get_size().y
    canvas.draw_texture_rect(
        texture, Rect2(center - Vector2(tile.x * 0.5, tile.y * 0.78), tile), false
    )


## The treasure chest, standing on its bottom middle, glowing.
static func chest(canvas: CanvasItem, bottom: Vector2, size: float, time: float) -> void:
    var glow := 0.5 + 0.5 * sin(time * 3.0)
    canvas.draw_circle(
        bottom + Vector2(0, -size * 0.4), size * (0.8 + glow * 0.1), Color(1.0, 0.85, 0.3, 0.2)
    )
    var texture := picture("items/chest.png")
    var tile := texture.get_size() * size / texture.get_size().x
    canvas.draw_texture_rect(texture, Rect2(bottom - Vector2(tile.x * 0.5, tile.y), tile), false)


## A star of the score, filled or empty.
static func score_star(canvas: CanvasItem, center: Vector2, size: float, filled: bool) -> void:
    _centered(
        canvas,
        picture("items/star_filled.png" if filled else "items/star_empty.png"),
        center,
        size * 2.4
    )


static func _centered(
    canvas: CanvasItem, texture: Texture2D, center: Vector2, longest: float
) -> void:
    var tile := texture.get_size() * longest / maxf(texture.get_size().x, texture.get_size().y)
    canvas.draw_texture_rect(texture, Rect2(center - tile * 0.5, tile), false)


static func _world(world: int) -> String:
    return _WORLDS[clampi(world, 0, _WORLDS.size() - 1)]


static func _star(canvas: CanvasItem, center: Vector2, size: float, color: Color) -> void:
    var points := PackedVector2Array()
    for k in range(10):
        var r := size if k % 2 == 0 else size * 0.45
        points.append(center + Vector2.from_angle(-PI / 2.0 + k * TAU / 10.0) * r)
    canvas.draw_colored_polygon(points, color)


static func _ellipse(
    canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color, width: float
) -> void:
    var points := PackedVector2Array()
    for k in range(24):
        var a := TAU * k / 24.0
        points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
    if width <= 0.0:
        canvas.draw_colored_polygon(points, color)
    else:
        points.append(points[0])
        canvas.draw_polyline(points, color, width)


static func _rounded(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
    var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
    canvas.draw_rect(
        Rect2(rect.position + Vector2(r, 0), Vector2(rect.size.x - 2 * r, rect.size.y)), color
    )
    canvas.draw_rect(
        Rect2(rect.position + Vector2(0, r), Vector2(rect.size.x, rect.size.y - 2 * r)), color
    )
    for corner in [
        rect.position + Vector2(r, r),
        Vector2(rect.end.x - r, rect.position.y + r),
        Vector2(rect.position.x + r, rect.end.y - r),
        rect.end - Vector2(r, r),
    ]:
        canvas.draw_circle(corner, r, color)


static func _rounded_outline(
    canvas: CanvasItem, rect: Rect2, radius: float, color: Color, width: float
) -> void:
    var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
    canvas.draw_line(
        rect.position + Vector2(r, 0), Vector2(rect.end.x - r, rect.position.y), color, width
    )
    canvas.draw_line(
        Vector2(rect.position.x + r, rect.end.y), rect.end - Vector2(r, 0), color, width
    )
    canvas.draw_line(
        rect.position + Vector2(0, r), Vector2(rect.position.x, rect.end.y - r), color, width
    )
    canvas.draw_line(
        Vector2(rect.end.x, rect.position.y + r), rect.end - Vector2(0, r), color, width
    )
    canvas.draw_arc(rect.position + Vector2(r, r), r, PI, PI * 1.5, 6, color, width)
    canvas.draw_arc(Vector2(rect.end.x - r, rect.position.y + r), r, PI * 1.5, TAU, 6, color, width)
    canvas.draw_arc(rect.end - Vector2(r, r), r, 0, PI * 0.5, 6, color, width)
    canvas.draw_arc(Vector2(rect.position.x + r, rect.end.y - r), r, PI * 0.5, PI, 6, color, width)
