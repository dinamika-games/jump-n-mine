class_name MineView
extends Node2D

## Draw the [Mine]: the sky and the grass, the cave, the blocks with their
## cracks, the water, the gems and the boosters, the dwarves, the dragons and
## their fire, and the chips and sparks of what happens.

## How long an explosion shows, in seconds.
const BLAST_TIME := 1.3

## The size of a cell on the screen, in pixels.
const CELL := 80.0

## The mine starts below the bar at the top of the screen.
const TOP := 88.0

var mine: Mine
var world: Dictionary
## The index of the world in [constant LevelCatalog.WORLDS].
var world_index := 0

var _time := 0.0
var _particles: Array[Dictionary] = []
## The explosions which still show: "pos" (in cells), "time" (since the blast)
## and "seed".
var _blasts: Array[Dictionary] = []
var _warning_layer := EffectLayer.new("res://scenes/effects/warning.gdshader")
var _gas_layer := EffectLayer.new("res://scenes/effects/gas.gdshader")
var _blast_layer := EffectLayer.new("res://scenes/effects/explosion.gdshader")
var _shake := 0.0
var _font: Font = ThemeDB.fallback_font


func _init(a_mine: Mine, a_world_index: int) -> void:
    mine = a_mine
    world_index = a_world_index
    world = LevelCatalog.WORLDS[a_world_index]
    _warning_layer.paint = _paint_warnings
    add_child(_warning_layer)
    _gas_layer.paint = _paint_gas
    add_child(_gas_layer)
    _blast_layer.paint = _paint_blasts
    add_child(_blast_layer)


## Show what happened (the events of [method Mine.take_events]).
func show_events(events: Array[Dictionary]) -> void:
    for event in events:
        var at: Vector2 = event["pos"]
        match str(event["type"]):
            "hit":
                var hard := int(event.get("kind", 0)) == Mine.Cell.ROCK
                _chips(at, world["rock"] if hard else world["dirt"], 6)
            "break":
                var kind := int(event.get("kind", 0))
                var color: Color = world["dirt"]
                if kind == Mine.Cell.ROCK:
                    color = world["rock"]
                _chips(at, color, 16)
            "gem":
                _sparkles(at, Color("#bff8ff"), 14)
                _float_text(at, "+1", Color("#7ff0ff"))
            "booster":
                _sparkles(at, Color("#fff6b0"), 18)
                _float_text(at, _booster_name(str(event["kind"])), Color("#ffe27a"))
            "pump":
                _sparkles(at, Color("#8fd0ff"), 18)
                _float_text(at, "Pump!", Color("#8fd0ff"))
            "explosion":
                _shake = 0.5
                _blasts.append({"pos": at, "time": 0.0, "seed": randf()})
                for k in range(30):
                    (
                        _particles
                        . append(
                            {
                                "pos": at,
                                "vel": Vector2.from_angle(randf() * TAU) * randf_range(3.0, 9.0),
                                "color":
                                [Color("#ffd400"), Color("#ff6a1a"), Color("#5a4a44")][k % 3],
                                "life": randf_range(0.4, 0.9),
                                "size": randf_range(8.0, 18.0),
                                "gravity": 4.0,
                            }
                        )
                    )
            "fire_hit", "spit":
                _sparkles(at, Color("#ff9a3a"), 10)
            "fizzle":
                _sparkles(at, Color("#e0f0ff"), 10)
            "splash":
                _sparkles(at, Color("#8fd0ff"), 10)
            "sealed":
                _sparkles(at, Color("#cfe8ff"), 12)
                _float_text(at, "Sealed!", Color("#cfe8ff"))
            "singed", "dizzy":
                _chips(at - Vector2(0, 0.5), Color("#3a3036"), 8)
            "rope":
                _float_text(at - Vector2(0, 1.2), "Rope!", Color("#f4e6d0"))
            "won":
                _sparkles(at, Color("#ffe27a"), 40)


func _booster_name(kind: String) -> String:
    match kind:
        "gold_pick":
            return "Golden pickaxe!"
        "helmet":
            return "Fire helmet!"
        "boots":
            return "Spring boots!"
    return "Booster!"


func _chips(at: Vector2, color: Color, count: int) -> void:
    for k in range(count):
        (
            _particles
            . append(
                {
                    "pos": at,
                    "vel": Vector2(randf_range(-3.0, 3.0), randf_range(-6.0, -1.0)),
                    "color": color.darkened(randf_range(0.0, 0.3)),
                    "life": randf_range(0.4, 0.8),
                    "size": randf_range(5.0, 11.0),
                    "gravity": 20.0,
                }
            )
        )


func _sparkles(at: Vector2, color: Color, count: int) -> void:
    for k in range(count):
        (
            _particles
            . append(
                {
                    "pos": at,
                    "vel": Vector2.from_angle(randf() * TAU) * randf_range(1.0, 4.0),
                    "color": color,
                    "life": randf_range(0.4, 1.0),
                    "size": randf_range(3.0, 7.0),
                    "gravity": 0.0,
                }
            )
        )


func _float_text(at: Vector2, text: String, color: Color) -> void:
    (
        _particles
        . append(
            {
                "pos": at,
                "vel": Vector2(0, -1.2),
                "color": color,
                "life": 1.4,
                "size": 0.0,
                "gravity": 0.0,
                "text": text,
            }
        )
    )


func _process(delta: float) -> void:
    _time += delta
    _shake = maxf(0.0, _shake - delta)
    var amount := _shake * 18.0
    position = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
    for blast in _blasts:
        blast["time"] = float(blast["time"]) + delta
    _blasts = _blasts.filter(func(b: Dictionary) -> bool: return float(b["time"]) < BLAST_TIME)
    for p in _particles:
        p["life"] = float(p["life"]) - delta
        p["vel"] = Vector2(p["vel"]) + Vector2(0, float(p["gravity"]) * delta)
        p["pos"] = Vector2(p["pos"]) + Vector2(p["vel"]) * delta
    _particles = _particles.filter(func(p: Dictionary) -> bool: return float(p["life"]) > 0.0)
    queue_redraw()


## The position on the screen of a point of the mine (in cells).
func to_screen(point: Vector2) -> Vector2:
    return Vector2(point.x * CELL, TOP + (point.y - mine.view_top) * CELL)


func _draw() -> void:
    var area := get_viewport_rect().size
    var first := int(floor(mine.view_top)) - 1
    var last := int(ceil(mine.view_top + Mine.VIEW_ROWS)) + 1

    # NOTE (mristin):
    # The far wall of the cave moves at half the speed of the blocks, so that
    # it looks far away.
    Art.cave(
        self, Rect2(Vector2(0, TOP), area), world_index, Vector2(0, mine.view_top * CELL * 0.5)
    )
    draw_rect(Rect2(Vector2(0, TOP), area), Color(0, 0, 0, 0.25))
    _draw_sky(first)

    for y in range(maxi(0, first), mini(mine.height, last + 1)):
        for x in range(Mine.WIDTH):
            _draw_cell(x, y)

    _draw_puzzles(first, last)
    _draw_water(first, last)
    _draw_items(first, last)
    _draw_chest()
    for dwarf in mine.dwarves:
        _draw_dwarf(dwarf)
    for fire in mine.fires:
        Art.fire(self, to_screen(fire.pos), 26.0, _time)
    for dragon in mine.dragons:
        var glow := clampf(
            (dragon.time - Mine.DRAGON_WARNING * 0.5) / (Mine.DRAGON_WARNING * 0.5), 0.0, 1.0
        )
        if dragon.spat:
            glow = 2.0 if dragon.time < Mine.DRAGON_WARNING + 0.4 else 0.0
        var facing := 1 if dragon.from_left else -1
        Art.dragon(
            self, Vector2(dragon.x * CELL - facing * 70.0, TOP + 80.0), 240.0, facing, _time, glow
        )
    _draw_particles()


func _draw_sky(first: int) -> void:
    if first > Mine.SKY_ROWS:
        return
    var bottom := to_screen(Vector2(0, Mine.SKY_ROWS)).y
    if bottom <= TOP:
        return
    # The sky ends at the grass; its top may be above the screen.
    var height := Mine.WIDTH * CELL * 400.0 / 1920.0
    Art.sky(self, Rect2(0, bottom - height, Mine.WIDTH * CELL, height), world_index)
    if bottom - height > TOP:
        draw_rect(Rect2(0, TOP, Mine.WIDTH * CELL, bottom - height - TOP + 1), world["sky_top"])


func _draw_cell(x: int, y: int) -> void:
    var rect := Rect2(to_screen(Vector2(x, y)), Vector2(CELL, CELL))
    var kind := mine.cell(x, y)
    var damage := mine.damage(x, y)
    match kind:
        Mine.Cell.AIR:
            return
        Mine.Cell.DIRT, Mine.Cell.ROCK:
            if y == Mine.SKY_ROWS:
                Art.grass(self, rect, world_index, damage)
            else:
                Art.block(self, rect, world_index, Vector2i(x, y), damage, kind == Mine.Cell.ROCK)
        Mine.Cell.BEDROCK:
            Art.bedrock(self, rect)
        Mine.Cell.GAS:
            # The block itself; its gas glows through it (see _paint_gas).
            Art.block(self, rect, world_index, Vector2i(x, y), 0.0, false)
        Mine.Cell.SPRING:
            Art.spring(self, rect, false, damage)
        Mine.Cell.SEALED:
            Art.spring(self, rect, true, 0.0)
        Mine.Cell.GATE:
            Art.gate(self, rect)
        Mine.Cell.PLATE:
            Art.plate(self, rect, _pressed(Vector2i(x, y)), _time)
    var i := mine.index(x, y)
    if mine.items.has(i):
        var item := str(mine.items[i])
        var center := rect.get_center()
        if item == "gem":
            # The gems show through the block, so that the dwarves dig for them.
            Art.gem(self, center, 16.0 + sin(_time * 3.0 + x) * 1.5, x + y)
        else:
            draw_circle(center, 26.0, Color(1, 0.95, 0.5, 0.25 + 0.15 * sin(_time * 4.0)))
            Art.booster(self, center, 20.0, item)


func _draw_water(first: int, last: int) -> void:
    if mine.water_total <= 0.0:
        return
    var water_color := Color(0.2, 0.5, 0.95, 0.55)
    for y in range(maxi(0, first), mini(mine.height, last + 1)):
        for x in range(1, Mine.WIDTH - 1):
            var w := mine.water_at(x, y)
            if w <= 0.02:
                continue
            var rect := Rect2(to_screen(Vector2(x, y)), Vector2(CELL, CELL))
            var full := mine.water_at(x, y - 1) > 0.02
            var h := CELL if full else CELL * clampf(w, 0.08, 1.0)
            var top := rect.end.y - h
            draw_rect(Rect2(rect.position.x, top, CELL, h), water_color)
            if not full:
                var wave := sin(_time * 3.0 + x * 0.9) * 3.0
                draw_line(
                    Vector2(rect.position.x, top + wave),
                    Vector2(rect.end.x, top - wave),
                    Color(0.75, 0.9, 1.0, 0.8),
                    3.0
                )
    for i in mine.springs:
        if mine.cells[i] != Mine.Cell.SPRING:
            continue
        var sx := i % Mine.WIDTH
        var sy := i / Mine.WIDTH
        var inner := 1 if sx == 0 else Mine.WIDTH - 2
        if mine.cell(inner, sy) != Mine.Cell.AIR:
            continue
        # The water pours out of the open spring.
        var from := to_screen(Vector2(sx + (1.0 if sx == 0 else 0.0), sy + 0.4))
        var direction := 1.0 if sx == 0 else -1.0
        var points := PackedVector2Array()
        for k in range(8):
            var t := k / 7.0
            points.append(from + Vector2(direction * t * 40.0, t * t * 70.0))
        draw_polyline(points, Color(0.6, 0.85, 1.0, 0.9), 12.0)


func _draw_items(first: int, last: int) -> void:
    for i in mine.loose:
        var x: int = i % Mine.WIDTH
        var y: int = i / Mine.WIDTH
        if y < first or y > last:
            continue
        var center := to_screen(Vector2(x + 0.5, y + 0.6 + sin(_time * 2.0 + x) * 0.05))
        var item := str(mine.loose[i])
        if item == "gem":
            Art.gem(self, center, 20.0, x * 3 + y)
        else:
            Art.booster(self, center, 24.0, item)


func _draw_chest() -> void:
    Art.chest(self, to_screen(Vector2(mine.chest.x + 0.5, mine.chest.y + 1.0)), CELL * 1.1, _time)


## Draw the warnings of the dragons' fire: a column of heat down to where the
## fire will fall, stronger until the dragon spits (see
## scenes/effects/warning.gdshader).
func _paint_warnings(canvas: CanvasItem) -> void:
    var white := _warning_layer.white()
    for dragon in mine.dragons:
        if dragon.spat:
            continue
        var x := dragon.column
        var bottom := int(floor(mine.view_top))
        while bottom < mine.height and not mine.is_solid(x, bottom):
            bottom += 1
        var top := to_screen(Vector2(x - 0.25, mine.view_top))
        var end := to_screen(Vector2(x + 1.25, bottom + 0.35))
        var rect := Rect2(top, end - top)
        var ground := (to_screen(Vector2(x, bottom)).y - top.y) / maxf(1.0, rect.size.y)
        var strength := clampf(dragon.time / Mine.DRAGON_WARNING, 0.15, 1.0)
        canvas.draw_texture_rect(
            white, rect, false, Color(strength, Art.hash01(x, 7, 3), ground, 1.0)
        )


func _draw_dwarf(dwarf: Mine.Dwarf) -> void:
    var feet := to_screen(dwarf.pos)
    var boosters: Array = []
    for kind in dwarf.boosters:
        if float(dwarf.boosters[kind]) > 0.0:
            boosters.append(kind)
    var walking := absf(dwarf.target_x - dwarf.pos.x) > 0.1 and dwarf.on_ground
    (
        Art
        . dwarf(
            self,
            feet,
            CELL * 1.05,
            dwarf.index,
            {
                "facing": dwarf.facing,
                "swing": dwarf.swing / 0.35,
                "sideways": dwarf.swing_dir.y == 0,
                "stun": dwarf.stun > 0.0,
                "time": _time + dwarf.index,
                "walking": walking,
                "boosters": boosters,
                "under_water": dwarf.swimming,
            }
        )
    )


func _draw_particles() -> void:
    for p in _particles:
        var at := to_screen(p["pos"])
        var alpha := clampf(float(p["life"]) * 2.0, 0.0, 1.0)
        var color: Color = p["color"]
        color.a = alpha
        if p.has("text"):
            var text: String = p["text"]
            var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x
            draw_string_outline(
                _font,
                at - Vector2(width / 2.0, 0),
                text,
                HORIZONTAL_ALIGNMENT_LEFT,
                -1,
                40,
                10,
                Color(0, 0, 0, alpha)
            )
            draw_string(
                _font, at - Vector2(width / 2.0, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40, color
            )
        else:
            draw_rect(Rect2(at - Vector2.ONE * p["size"] * 0.5, Vector2.ONE * p["size"]), color)


## Draw the gas: in the pockets, glowing through their blocks, and the clouds
## of the opened pockets, which grow and flicker before they explode.
func _paint_gas(canvas: CanvasItem) -> void:
    var white := _gas_layer.white()
    var first := int(floor(mine.view_top)) - 2
    var last := int(ceil(mine.view_top + Mine.VIEW_ROWS)) + 2
    for y in range(maxi(0, first), mini(mine.height, last)):
        for x in range(Mine.WIDTH):
            if mine.cell(x, y) == Mine.Cell.GAS:
                var rect := Rect2(to_screen(Vector2(x, y)), Vector2(CELL, CELL)).grow(4.0)
                var seed := Art.hash01(x, y, 5)
                canvas.draw_texture_rect(white, rect, false, Color(seed, 1.0, 0.0, 1.0))
    for i in mine.fuses:
        var left := float(mine.fuses[i])
        var cell := Vector2(i % Mine.WIDTH, i / Mine.WIDTH)
        var released := clampf((Mine.FUSE_TIME - left) * 3.0, 0.2, 1.0)
        var danger := clampf(1.0 - left / Mine.FUSE_TIME, 0.0, 1.0)
        var size := CELL * (1.2 + 1.4 * released)
        var center := to_screen(cell + Vector2(0.5, 0.5 - 0.3 * released))
        var rect := Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size)
        canvas.draw_texture_rect(
            white, rect, false, Color(Art.hash01(int(cell.x), int(cell.y), 9), 1.0, danger, 1.0)
        )


## Draw the explosions.
func _paint_blasts(canvas: CanvasItem) -> void:
    var white := _blast_layer.white()
    for blast in _blasts:
        var size := CELL * 5.6
        var center := to_screen(blast["pos"])
        var rect := Rect2(center - Vector2.ONE * size * 0.5, Vector2.ONE * size)
        var progress := float(blast["time"]) / BLAST_TIME
        canvas.draw_texture_rect(
            white, rect, false, Color(progress, float(blast["seed"]), 0.0, 1.0)
        )


## Whether the plate of the cell is pressed now.
func _pressed(cell: Vector2i) -> bool:
    var puzzle := mine.puzzles.puzzle_at(cell)
    if puzzle == null:
        return false
    var k := puzzle.plates.find(cell)
    return k >= 0 and puzzle.pressed[k]


## Over each closed gate, a lamp for each plate which must be pressed now (lit
## when pressed), so that the players see how many of them it takes; under an
## open timer gate, how long it stays open.
func _draw_puzzles(first: int, last: int) -> void:
    for puzzle in mine.puzzles.puzzles:
        if puzzle.row < first or puzzle.row > last:
            continue
        var center := to_screen(Vector2(Mine.WIDTH / 2.0, puzzle.row - 2.4))
        if puzzle.open:
            if puzzle.kind == "timer":
                var share := clampf(puzzle.timer / MinePuzzles.TIMER, 0.0, 1.0)
                var bar := Rect2(center - Vector2(150, 8), Vector2(300, 16))
                draw_rect(bar.grow(3.0), Art.OUTLINE)
                draw_rect(
                    Rect2(bar.position, Vector2(bar.size.x * share, bar.size.y)), Color("#7cf04f")
                )
            continue
        var pressed := 0
        for on in puzzle.pressed:
            if on:
                pressed += 1
        for k in range(puzzle.needed):
            var at := center + Vector2((k - (puzzle.needed - 1) / 2.0) * 70.0, 0)
            var lit := k < pressed
            draw_circle(at, 26.0, Art.OUTLINE)
            draw_circle(at, 22.0, Color("#7cf04f") if lit else Color("#4a4048"))
            if lit:
                draw_circle(at, 34.0, Color(0.5, 1.0, 0.4, 0.25))
        # A plate under each lamp glows the way to it.
        for plate in puzzle.plates:
            var top := to_screen(Vector2(plate.x + 0.5, plate.y - 0.15))
            var pulse := 0.25 + 0.2 * sin(_time * 3.0 + plate.x)
            draw_line(top, top - Vector2(0, CELL * 0.9), Color(1.0, 0.9, 0.4, pulse), 6.0)
