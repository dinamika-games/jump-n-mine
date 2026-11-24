class_name MineMoles
extends RefCounted

## The moles of the mine: friends of the dwarves. Every so often (see
## [code]moles[/code] in [LevelCatalog]), a mole comes out of the earth a few
## rows below a dwarf, digs a short tunnel through the earth, to the sides and
## down but never up, since moles cannot fly (and lets the gems in it fall out,
## since a mole takes no gems), looks around, and goes back the way it came. A
## mole hit by a pickaxe cries, runs away, and the next one waits longer.

## How fast a mole digs and goes back, in cells per second.
const SPEED := 1.6
const BACK_SPEED := 2.4

## A mole looks around this long before it goes back, and cries this long when a
## pickaxe hit it, in seconds.
const PEEK := 1.6
const CRY := 1.8

## After a mole was hit, the next one comes this much later, in seconds.
const SHY := 30.0


class Mole:
    extends RefCounted

    ## The cells of its tunnel, from where it came out of the earth.
    var path: Array[Vector2i] = []
    ## How far along its tunnel it is, in cells.
    var along := 0.0
    ## "dig", "peek", "back", "cry" or "flee".
    var phase := "dig"
    ## How long it is in its phase, in seconds.
    var time := 0.0
    ## The middle of the mole, in cells.
    var pos := Vector2.ZERO
    var facing := 1


var all: Array[Mole] = []

var _rng := RandomNumberGenerator.new()
var _next := INF


## Seed the moles of the mine (from the seed of its level), and wait for the first.
func start(mine: Mine) -> void:
    _rng.seed = int(mine.level.get("seed", 0)) * 13 + 5
    _schedule(mine, 0.0)


## The pickaxe of the dwarf struck at the point (in cells, the body of the dwarf
## at the body): a mole there cries. Return whether it hit one.
func strike(mine: Mine, dwarf: Mine.Dwarf, point: Vector2, body: Vector2) -> bool:
    for mole in all:
        if not mole.phase in ["dig", "peek", "back"]:
            continue
        if mole.pos.distance_to(point) < 0.75 or mole.pos.distance_to(body) < 0.6:
            mole.phase = "cry"
            mole.time = 0.0
            mine.events.append({"type": "mole_cry", "pos": mole.pos, "dwarf": dwarf.index})
            _schedule(mine, SHY)
            return true
    return false


## Let the moles come, dig, look around, go back, and cry.
func update(mine: Mine, dt: float) -> void:
    if mine.time >= _next:
        _schedule(mine, 0.0)
        if all.size() < 2:
            _spawn(mine)
    var gone: Array[Mole] = []
    for mole in all:
        mole.time += dt
        var last := float(mole.path.size() - 1)
        match mole.phase:
            "dig":
                var before := int(floor(mole.along + 0.5))
                mole.along = minf(last, mole.along + SPEED * dt)
                var now := int(floor(mole.along + 0.5))
                if now != before:
                    if (
                        not _may_dig(mine, mole.path[now])
                        or not mine.is_solid(mole.path[now].x, mole.path[now].y + 1)
                    ):
                        # NOTE (mristin):
                        # Something changed ahead (e.g., a gate, or a dwarf
                        # dug away the floor): go back.
                        mole.along = float(before)
                        mole.phase = "back"
                        mole.time = 0.0
                    else:
                        _dig(mine, mole.path[now])
                if mole.along >= last:
                    mole.phase = "peek"
                    mole.time = 0.0
            "peek":
                if mole.time >= PEEK:
                    mole.phase = "back"
                    mole.time = 0.0
            "back", "flee":
                var speed := BACK_SPEED * (2.0 if mole.phase == "flee" else 1.0)
                mole.along = maxf(0.0, mole.along - speed * dt)
                if mole.along <= 0.0:
                    gone.append(mole)
                    mine.events.append({"type": "mole_gone", "pos": mole.pos})
            "cry":
                if mole.time >= CRY:
                    mole.phase = "flee"
                    mole.time = 0.0
        var k := clampi(int(floor(mole.along)), 0, mole.path.size() - 1)
        var k2 := mini(k + 1, mole.path.size() - 1)
        var from := Vector2(mole.path[k]) + Vector2(0.5, 0.5)
        var to := Vector2(mole.path[k2]) + Vector2(0.5, 0.5)
        var before_x := mole.pos.x
        mole.pos = from.lerp(to, mole.along - float(k))
        if absf(mole.pos.x - before_x) > 0.001:
            mole.facing = 1 if mole.pos.x > before_x else -1
    for mole in gone:
        all.erase(mole)


func _schedule(mine: Mine, delay: float) -> void:
    var interval: Array = mine.level.get("moles", [])
    if interval.is_empty():
        _next = INF
        return
    _next = mine.time + delay + _rng.randf_range(float(interval[0]), float(interval[1]))


## Whether a mole may dig through the cell: earth or air inside the mine, away
## from the walls (and their springs), the halls of the puzzles and the
## treasure chamber.
func _may_dig(mine: Mine, at: Vector2i) -> bool:
    if at.x < 2 or at.x > Mine.WIDTH - 3 or at.y <= Mine.SKY_ROWS or at.y >= mine.chest.y - 3:
        return false
    for puzzle in mine.puzzles.puzzles:
        if at.y >= puzzle.row - 4 and at.y <= puzzle.row + 1:
            return false
    var kind := mine.cell(at.x, at.y)
    return kind == Mine.Cell.DIRT or kind == Mine.Cell.AIR


## Whether a mole may step into the cell from its tunnel: moles cannot fly, so
## the cell needs earth or a block under it to stand on (its own tunnel is no
## floor).
func _may_step(mine: Mine, at: Vector2i, path: Array[Vector2i]) -> bool:
    if at in path:
        return false
    return _has_floor(mine, at, path)


func _has_floor(mine: Mine, at: Vector2i, path: Array[Vector2i]) -> bool:
    var below := at + Vector2i(0, 1)
    return mine.is_solid(below.x, below.y) and not below in path


## A mole comes out of the earth one or two rows below a dwarf (where the
## players see it), with a short tunnel ahead.
func _spawn(mine: Mine) -> void:
    if mine.dwarves.is_empty():
        return
    var dwarf: Mine.Dwarf = mine.dwarves[_rng.randi_range(0, mine.dwarves.size() - 1)]
    for attempt in range(20):
        var start := Vector2i(
            _rng.randi_range(2, Mine.WIDTH - 3), int(floor(dwarf.pos.y)) + _rng.randi_range(1, 2)
        )
        if not _may_dig(mine, start) or mine.cell(start.x, start.y) != Mine.Cell.DIRT:
            continue
        var path: Array[Vector2i] = [start]
        if not _has_floor(mine, start, path):
            continue
        var direction := 1 if _rng.randf() < 0.5 else -1
        var length := _rng.randi_range(3, 5)
        for k in range(12):
            if path.size() >= length:
                break
            var last: Vector2i = path[-1]
            var down := last + Vector2i(0, 1)
            var next := last + Vector2i(direction, 0)
            if _rng.randf() < 0.25 and _may_dig(mine, down) and _may_step(mine, down, path):
                next = down
            if not _may_dig(mine, next) or not _may_step(mine, next, path):
                # NOTE (mristin):
                # A mole turns around at most once; else it digs down, or stops.
                if (
                    k == 0
                    and _may_dig(mine, last - Vector2i(direction, 0))
                    and _may_step(mine, last - Vector2i(direction, 0), path)
                ):
                    direction = -direction
                    continue
                if _may_dig(mine, down) and _may_step(mine, down, path):
                    path.append(down)
                    continue
                break
            path.append(next)
        if path.size() < 3:
            continue
        var mole := Mole.new()
        mole.path = path
        mole.pos = Vector2(start) + Vector2(0.5, 0.5)
        mole.facing = direction
        all.append(mole)
        _dig(mine, start)
        mine.events.append({"type": "mole", "pos": mole.pos})
        return


## The mole digs through the cell: the earth is gone, and a gem in it falls out
## for the dwarves.
func _dig(mine: Mine, at: Vector2i) -> void:
    var i := mine.index(at.x, at.y)
    if mine.cells[i] != Mine.Cell.DIRT:
        return
    mine.cells[i] = Mine.Cell.AIR
    mine.hits_left[i] = 0
    if mine.items.has(i):
        mine.loose[i] = mine.items[i]
        mine.items.erase(i)
    mine.events.append({"type": "mole_dig", "pos": Vector2(at) + Vector2(0.5, 0.5)})
