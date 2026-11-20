class_name Art
extends RefCounted

## The pictures of the game: the painted sprites of assets/pictures/ (cut by
## dev/pictures/cut_sprites.py), drawn at the size the game needs.
##
## Every function draws on the canvas item at a position in pixels, so that the
## menus and the level share them.

const OUTLINE := Color("#1a1016")
const GEM_COLORS := [Color("#3ee6f0"), Color("#f04fd0"), Color("#7cf04f"), Color("#ffd23e")]
const STEEL := Color("#b9c3cf")
const GOLD := Color("#ffcf3a")

const _PICTURES := "res://assets/pictures/"

## The worlds by their index into [constant LevelCatalog.WORLDS].
const _WORLDS := ["copper_hills", "sunken_halls", "dragon_deeps"]

## The colors of the dwarves' tunics, by their slot.
const _DWARF_COLORS := ["red", "blue", "green", "yellow"]

## In a dwarf picture, the dwarf is this tall (as a share of the picture), with
## its feet at this point (as shares of the picture).
const _DWARF_TALL := 244.0 / 362.0
const _DWARF_FEET := Vector2(0.54, 328.0 / 362.0)


## The picture of the path under assets/pictures/ (Godot caches the loaded
## pictures, so that this is cheap).
static func picture(path: String) -> Texture2D:
    return load(_PICTURES + path)


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


## A miner's helmet with its lamp, for a head in the camera picture: the
## middle of the top of the head box of YOLOX, and its size (in pixels); the
## brim has the color of the player's dwarf.
static func miner_hat(
    canvas: CanvasItem, top: Vector2, width: float, brim: Color, time: float
) -> void:
    var w := width * 0.95
    # NOTE (mristin):
    # The head boxes of YOLOX reach about a quarter of their height above the
    # hair; the brim sits on the crown of the head.
    var dome := top + Vector2(0, width * 0.42)
    # The light of the lamp, a soft cone forwards (towards the camera: up).
    var lamp := dome + Vector2(0, -w * 0.3)
    var flicker := 0.85 + 0.15 * sin(time * 7.0)
    canvas.draw_circle(lamp, w * 0.45, Color(1.0, 0.95, 0.6, 0.12 * flicker))
    canvas.draw_circle(lamp, w * 0.26, Color(1.0, 0.95, 0.6, 0.18 * flicker))
    # The dome.
    var points := PackedVector2Array()
    for k in range(17):
        var a := PI + PI * k / 16.0
        points.append(dome + Vector2(cos(a) * w * 0.42, sin(a) * w * 0.4))
    var outline := points.duplicate()
    canvas.draw_colored_polygon(points, STEEL)
    outline.append(outline[0])
    canvas.draw_polyline(outline, OUTLINE, maxf(2.0, w * 0.03))
    canvas.draw_line(
        dome + Vector2(-w * 0.2, -w * 0.3),
        dome + Vector2(-w * 0.05, -w * 0.36),
        Color(1, 1, 1, 0.7),
        maxf(2.0, w * 0.03)
    )
    # The brim, in the color of the dwarf.
    var brim_rect := Rect2(dome + Vector2(-w * 0.55, -w * 0.02), Vector2(w * 1.1, w * 0.12))
    _rounded(canvas, brim_rect.grow(maxf(1.5, w * 0.02)), w * 0.06, OUTLINE)
    _rounded(canvas, brim_rect, w * 0.05, brim)
    # The lamp.
    canvas.draw_circle(lamp, w * 0.11, OUTLINE)
    canvas.draw_circle(lamp, w * 0.09, Color("#ffe65a"))
    canvas.draw_circle(lamp, w * 0.045, Color.WHITE)


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


## An iron gate in the floor, closed: bars over the dark.
static func gate(canvas: CanvasItem, rect: Rect2) -> void:
    canvas.draw_rect(rect, Color("#1c1820"))
    var iron := Color("#6d7480")
    var bar := rect.size.x / 5.0
    for k in range(5):
        var x := rect.position.x + (k + 0.5) * bar
        canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), OUTLINE, bar * 0.55)
        canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), iron, bar * 0.35)
        canvas.draw_line(
            Vector2(x - bar * 0.08, rect.position.y),
            Vector2(x - bar * 0.08, rect.end.y),
            iron.lightened(0.4),
            2.0
        )
    for y in [rect.position.y + rect.size.y * 0.2, rect.end.y - rect.size.y * 0.2]:
        canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), OUTLINE, 9.0)
        canvas.draw_line(
            Vector2(rect.position.x, y), Vector2(rect.end.x, y), iron.darkened(0.1), 5.0
        )


## A stone plate in the floor which a dwarf presses by standing on it; it
## glows when it is pressed.
static func plate(canvas: CanvasItem, rect: Rect2, pressed: bool, time: float) -> void:
    bedrock(canvas, rect)
    var top := Rect2(
        rect.position + Vector2(6, 4 + (6 if pressed else 0)), Vector2(rect.size.x - 12, 18)
    )
    _rounded(canvas, top.grow(2.0), 6.0, OUTLINE)
    _rounded(canvas, top, 5.0, Color("#b9b2a5"))
    var glow := (
        Color(0.5, 1.0, 0.4) if pressed else Color(1.0, 0.85, 0.3, 0.55 + 0.35 * sin(time * 4.0))
    )
    canvas.draw_circle(top.get_center(), 6.0, glow)
    if pressed:
        canvas.draw_circle(top.get_center(), 14.0, Color(0.5, 1.0, 0.4, 0.3))


## A spring in the wall, pouring water, or sealed with a plug.
static func spring(canvas: CanvasItem, rect: Rect2, sealed: bool, damage: float) -> void:
    canvas.draw_texture_rect(
        picture("blocks/spring_sealed.png" if sealed else "blocks/spring_open.png"), rect, false
    )
    cracks(canvas, rect, damage)


## A gem, of the color by the index, as big as the size (its half height).
static func gem(canvas: CanvasItem, center: Vector2, size: float, color_index: int) -> void:
    _centered(canvas, picture("items/gem_%d.png" % (absi(color_index) % 4)), center, size * 2.2)


## The badge of a booster (see [constant Mine.BOOSTERS]), as big as the radius.
static func booster(canvas: CanvasItem, center: Vector2, size: float, kind: String) -> void:
    _centered(canvas, picture("items/booster_%s.png" % kind), center, size * 2.0)


## The dwarf of the slot (0 to 3, by the color of its tunic) standing at the
## feet, as tall as the height (in pixels).
##
## The state: "facing" (1 or -1), "swing" (in [0, 1], 1 at the start of a
## swing), "stun" (dizzy), "time" (for the animation), "walking", "boosters"
## (the kinds on the dwarf) and "under_water".
static func dwarf(
    canvas: CanvasItem, feet: Vector2, height: float, slot: int, state: Dictionary
) -> void:
    var time := float(state.get("time", 0.0))
    var boosters: Array = state.get("boosters", [])
    var swing := float(state.get("swing", 0.0))
    var pose := "idle"
    if bool(state.get("stun", false)):
        pose = "dizzy"
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
    elif bool(state.get("walking", false)):
        pose = "walk_a" if fmod(time * 6.0, 2.0) < 1.0 else "walk_b"
    var texture := picture("dwarves/%s/%s.png" % [_DWARF_COLORS[clampi(slot, 0, 3)], pose])
    var size := Vector2.ONE * height / _DWARF_TALL
    var facing := int(state.get("facing", 1))
    var origin := feet - Vector2(_DWARF_FEET.x * size.x * facing, _DWARF_FEET.y * size.y)
    canvas.draw_set_transform(origin, 0.0, Vector2(facing, 1))
    canvas.draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
    canvas.draw_set_transform(Vector2.ZERO)


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
