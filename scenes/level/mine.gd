class_name Mine
extends RefCounted

## The mine of a level and everything that happens in it: the blocks, the
## dwarves, the water, the gas pockets, the dragons and their fire, the moles,
## and the evil miner of Queen Treacher who races the dwarves to the treasure.
##
## The mine draws nothing and reads no input, so that the tests can play a
## level headless and fast (see tests/godot/test_levels.gd): the level scene
## sets where each dwarf wants to go ([method set_target]), tells when its
## player jumped ([method jump]), calls [method step] and draws the mine with
## [MineView].
##
## Everything is measured in cells: x grows to the right and y downwards; the
## cell (x, y) covers [x, x + 1] x [y, y + 1]. A dwarf stands with its feet at
## [member Dwarf.pos].

enum Cell { AIR, DIRT, ROCK, BEDROCK, GAS, SPRING, SEALED, GATE, PLATE }

enum State { PLAYING, WON, FLOODED, LOST }

## At most this many dwarves dig together.
const MAX_DWARVES := 4

## The mine is this many cells wide; the outer columns are the walls.
const WIDTH := 11

## The levels in [LevelCatalog] count their caves, gas pockets and water for a
## mine of 22 inner columns; a narrower mine gets this share of them.
const AREA_SCALE := (WIDTH - 2) / 22.0

## The rows of the sky above the grass.
const SKY_ROWS := 3

## How many rows the screen shows: the mine fills the width of the 1920 x 1080
## screen, below the bar of 88 pixels at the top (see [MineView]).
const VIEW_ROWS := WIDTH * (1080.0 - 88.0) / 1920.0

## How many hits each kind of block takes.
const HITS := {Cell.DIRT: 3, Cell.ROCK: 4, Cell.GAS: 1, Cell.SPRING: 3}

## A pickaxe swung to the side reaches this far beyond the dwarf, in cells.
const SIDE_REACH := 0.35

## The kinds of the boosters, which the players buy with their gems after a
## level (see [Shop]) and which start by themselves when they help (see
## [MineBoosters]).
const BOOSTERS := ["gold_pick", "helmet", "boots", "pump"]

## The pump starts by itself when the mine is this full of water, and pumps
## again whenever the mine fills up this far.
const PUMP_AT := 0.6

## The slot of the evil miner of Queen Treacher (see [member rival]); the slots
## 0 to 3 are the players'.
const RIVAL := 4

## The gravity, in cells per second squared.
const GRAVITY := 34.0

## How fast a dwarf walks, in cells per second.
const WALK_SPEED := 6.5

## How high a dwarf hops when its player jumps while it walks, in cells (see
## [method _hops]).
const HOP := 1.25

## How high a dwarf bobs when its player jumps while it stands still, in cells:
## barely, so that it stays on its block (see [method _hops]).
const BOB := 0.2

## How high a dwarf hops with the spring boots, in cells.
const HOP_BOOTS := 2.3

const DWARF_HALF_WIDTH := 0.3
const DWARF_HEIGHT := 0.9

## How long a dwarf is dizzy from the fire or an explosion, in seconds.
const STUN_TIME := 2.5

## How long the gas of an opened pocket floats before it catches fire from the
## lamps of the dwarves, in seconds.
const FUSE_TIME := 2.4

## A gas pocket opened by an explosion catches fire this soon, for a chain.
const CHAIN_FUSE_TIME := 0.25

## A dwarf above the screen for this long is let down on a rope to its friends.
const ROPE_AFTER := 2.5

## The dragon circles this long before it spits, so that the dwarves see where.
const DRAGON_WARNING := 1.8

## How fast the fire falls, in cells per second.
const FIRE_SPEED := 9.0

## How often the water flows, per second.
const WATER_RATE := 20.0


class Dwarf:
    extends RefCounted

    var index := 0
    ## The middle of the feet, in cells.
    var pos := Vector2.ZERO
    var vel := Vector2.ZERO
    ## Where the player wants the dwarf, in cells.
    var target_x := 0.0
    var on_ground := false
    ## 1 to the right, -1 to the left.
    var facing := 1
    ## The dwarf is dizzy for this many more seconds.
    var stun := 0.0
    ## The head of the dwarf is under water: dwarves are heavy, so they wade
    ## along the bottom, slower, and still swing their pickaxes.
    var swimming := false
    ## The pickaxe swings for this many more seconds (for drawing).
    var swing := 0.0
    ## Where the pickaxe swung last: (1, 0), (-1, 0) or (0, 1).
    var swing_dir := Vector2i(0, 1)
    var above_screen := 0.0
    ## The dwarf sees stars (knocked out by a pickaxe) for so many more seconds.
    var stars := 0.0
    var gems := 0
    var hits := 0


class Dragon:
    extends RefCounted

    ## The dragon flies in at x and spits on the column.
    var x := 0.0
    var column := 0
    ## How far along its flight: < DRAGON_WARNING circles, then spits, then leaves.
    var time := 0.0
    var spat := false
    var from_left := true


class Fire:
    extends RefCounted

    var pos := Vector2.ZERO


var level: Dictionary
var height := 0
var cells := PackedByteArray()
## How many hits each block still takes; a low jump hits less than a whole hit.
var hits_left := PackedFloat32Array()
var water := PackedFloat32Array()
## What is inside the blocks, by the index of the cell: "gem" or a booster.
var items := {}
## Gems and boosters lying in the caves, by the index of their cell.
var loose := {}
## The clouds of gas of the opened pockets, by the index of their cell: the
## seconds left until they explode.
var fuses := {}
var dwarves: Array[Dwarf] = []
## The evil miner of Queen Treacher, or null (before he arrives, and in the
## levels without him, see [MineRival]). He is not one of [member dwarves]: the
## screen does not follow him, he presses no plates and takes no gems.
var rival: Dwarf = null
## How the evil miner arrives, paces himself and fights (see [MineRival]).
var rivalry := MineRival.new()
## The moles (see [MineMoles]).
var moles := MineMoles.new()
## The boosters which the players brought along, by kind: how many.
var charges := {}
## The boosters which started in this level, by kind (true): a booster helps
## the players' dwarves for the rest of the level.
var active := {}
var dragons: Array[Dragon] = []
var fires: Array[Fire] = []
var chest := Vector2i.ZERO
var gems := 0
var gems_total := 0
var state := State.PLAYING
var time := 0.0
## The top row of the screen (can be fractional).
var view_top := 0.0
## The deepest row reached by any dwarf.
var deepest := 0.0
var water_total := 0.0
## What happened since the view looked last: dictionaries with "type" and "pos"
## (in cells), and more by the type; see [method take_events].
var events: Array[Dictionary] = []
## The gates and their plates (see [MinePuzzles]).
var puzzles := MinePuzzles.new()
## The springs of the walls, the indices of their cells.
var springs: Array[int] = []
## The water flows from the left to the right in the next step (see [MineWater]).
var water_left_to_right := true
## The dice of the dragons, and when the next one comes (see [MineDragons]).
var rng := RandomNumberGenerator.new()
var next_dragon := INF

## Where the last dwarf left the mine, for the next to come; (-1, -1) before.
var _left_at := Vector2(-1, -1)
var _water_clock := 0.0


## Make the mine of the level, with the dwarves of the first slots (e.g., for
## the bots), and the boosters which the players brought (by kind, how many);
## the players' dwarves come and go with [method add_dwarf] and [method
## remove_dwarf].
func _init(a_level: Dictionary, initial_dwarves := 0, a_charges := {}) -> void:
    level = a_level
    charges = a_charges.duplicate()
    _generate()
    rng.seed = int(level.get("seed", 0)) * 7 + 3
    MineDragons.schedule(self)
    moles.start(self)
    for slot in range(clampi(initial_dwarves, 0, MAX_DWARVES)):
        add_dwarf(slot)
    events.clear()


## The dwarf of the slot (or the evil miner, [constant RIVAL]), or null if it is
## not in the mine.
func dwarf_of(slot: int) -> Dwarf:
    if slot == RIVAL:
        return rival
    for each in dwarves:
        if each.index == slot:
            return each
    return null


## A dwarf comes to dig in the slot (0 to 3, by the color of its tunic): at
## the start, on the grass; later, it is let down on a rope to the deepest
## dwarf, or to where the last one left.
func add_dwarf(slot: int) -> Dwarf:
    var existing := dwarf_of(slot)
    if existing != null:
        return existing
    var dwarf := Dwarf.new()
    dwarf.index = slot
    var deepest := _deepest_dwarf()
    if deepest != null:
        dwarf.pos = deepest.pos
        events.append({"type": "rope", "pos": dwarf.pos, "dwarf": slot})
    elif _left_at.x >= 0.0:
        dwarf.pos = _left_at
        events.append({"type": "rope", "pos": dwarf.pos, "dwarf": slot})
    else:
        dwarf.pos = Vector2(2.5 + (WIDTH - 5.0) * (slot + 0.5) / MAX_DWARVES, SKY_ROWS)
    dwarf.target_x = dwarf.pos.x
    dwarves.append(dwarf)
    events.append({"type": "joined", "pos": dwarf.pos, "dwarf": slot})
    rivalry.dwarf_came(self)
    return dwarf


## The dwarf of the slot leaves the mine (its player left the picture).
func remove_dwarf(slot: int) -> void:
    var dwarf := dwarf_of(slot)
    if dwarf == null:
        return
    dwarves.erase(dwarf)
    if dwarves.is_empty():
        _left_at = dwarf.pos
    events.append({"type": "left", "pos": dwarf.pos, "dwarf": slot})


func _deepest_dwarf() -> Dwarf:
    var deepest: Dwarf = null
    for each in dwarves:
        if deepest == null or each.pos.y > deepest.pos.y:
            deepest = each
    return deepest


## The index of the cell (x, y).
func index(x: int, y: int) -> int:
    return y * WIDTH + x


## The kind of the cell; outside of the mine, bedrock.
func cell(x: int, y: int) -> int:
    if x < 0 or x >= WIDTH or y < 0 or y >= height:
        return Cell.BEDROCK
    return cells[index(x, y)]


## Whether the cell stops the dwarves, the water and the fire.
func is_solid(x: int, y: int) -> bool:
    if y < 0 and x >= 0 and x < WIDTH:
        return false
    return cell(x, y) != Cell.AIR


## Whether a pickaxe breaks the cell.
func is_breakable(x: int, y: int) -> bool:
    return HITS.has(cell(x, y))


## The water in the cell, in [0, 1].
func water_at(x: int, y: int) -> float:
    if x < 0 or x >= WIDTH or y < 0 or y >= height:
        return 0.0
    return water[index(x, y)]


## How damaged the block is, in [0, 1): 0 untouched.
func damage(x: int, y: int) -> float:
    var kind := cell(x, y)
    if not HITS.has(kind):
        return 0.0
    var full := int(HITS[kind])
    return float(full - hits_left[index(x, y)]) / float(full)


## Let the dwarf of the player head for x (in cells).
func set_target(player: int, x: float) -> void:
    var dwarf := dwarf_of(player)
    if dwarf == null:
        return
    # NOTE (mristin):
    # A little into the walls, so that the dwarves can lean against them and
    # seal the springs.
    dwarf.target_x = clampf(x, 0.5, WIDTH - 0.5)


## The player jumped: the dwarf swings its pickaxe and hops. A low jump
## (strength below 1) hits the block less.
func jump(player: int, strength := 1.0) -> void:
    var dwarf := dwarf_of(player)
    if state != State.PLAYING or dwarf == null:
        return
    if dwarf.stun > 0.0:
        return
    if dwarf.swimming:
        events.append({"type": "blub", "pos": dwarf.pos, "dwarf": dwarf.index})

    dwarf.swing = 0.35
    dwarf.swing_dir = Vector2i(0, 1)
    if not _strike(dwarf, 0):
        var target := _hit_target(dwarf)
        if target.x >= 0:
            if target.y <= int(floor(dwarf.pos.y - DWARF_HEIGHT * 0.5)):
                dwarf.swing_dir = Vector2i(signi(target.x - int(floor(dwarf.pos.x))), 0)
            dwarf.hits += 1
            hit_block(target, strength * MineBoosters.power(self, dwarf, target), dwarf)
        else:
            events.append({"type": "swing", "pos": dwarf.pos, "dwarf": dwarf.index})

    if dwarf.on_ground:
        var hop := BOB
        if _hops(dwarf):
            hop = HOP_BOOTS if MineBoosters.boots(self, dwarf) else HOP
        dwarf.vel.y = -sqrt(2.0 * GRAVITY * hop)
        dwarf.on_ground = false


## Whether the jump of the dwarf is a hop: while it walks (over a hole, say) or
## leans against a block beside its feet, to climb onto it. A dwarf which
## stands still only bobs, so that it keeps digging the block under its feet.
func _hops(dwarf: Dwarf) -> bool:
    var dx := dwarf.target_x - dwarf.pos.x
    if absf(dx) > 0.3:
        return true
    if absf(dx) < 0.05:
        return false
    var side := signf(dx)
    var x := int(floor(dwarf.pos.x + side * (DWARF_HALF_WIDTH + 0.05)))
    return x != int(floor(dwarf.pos.x)) and is_solid(x, int(floor(dwarf.pos.y - 0.5)))


## The player swung an arm out to the side (-1 left, 1 right): the dwarf swings
## its pickaxe at the block beside it, without a hop. A low swing (strength
## below 1) hits the block less.
func swing_side(player: int, side: int, strength := 1.0) -> void:
    var dwarf := dwarf_of(player)
    if state != State.PLAYING or dwarf == null or side == 0:
        return
    if dwarf.stun > 0.0:
        return
    if dwarf.swimming:
        events.append({"type": "blub", "pos": dwarf.pos, "dwarf": dwarf.index})

    dwarf.swing = 0.35
    dwarf.facing = signi(side)
    dwarf.swing_dir = Vector2i(signi(side), 0)
    if _strike(dwarf, signi(side)):
        return
    var target := _side_target(dwarf, signi(side))
    if target.x >= 0:
        dwarf.hits += 1
        hit_block(target, strength * MineBoosters.power(self, dwarf, target), dwarf)
    else:
        events.append({"type": "swing", "pos": dwarf.pos, "dwarf": dwarf.index})


## The pickaxe of the dwarf swung down (side 0) or to the side (-1 or 1): it
## hits the evil miner or a mole if one is in its way, before any block. Return
## whether it hit one.
func _strike(dwarf: Dwarf, side: int) -> bool:
    if dwarf == rival:
        return false
    var body := dwarf.pos - Vector2(0, DWARF_HEIGHT * 0.5)
    var point := body + (Vector2(side * 0.8, 0.0) if side != 0 else Vector2(0.0, 0.9))
    return rivalry.strike(self, dwarf, point, body, side) or moles.strike(self, dwarf, point, body)


## Take what happened since the last call, and forget it.
func take_events() -> Array[Dictionary]:
    var result := events
    events = []
    return result


## How full of water the mine is, in [0, 1]; at 1, it is flooded.
func flood_level() -> float:
    var flood := float(level.get("flood", 60.0)) * AREA_SCALE
    return clampf(water_total / flood, 0.0, 1.0) if flood > 0.0 else 0.0


## How far down the dwarves came, in [0, 1].
func progress() -> float:
    return clampf((deepest - SKY_ROWS) / float(chest.y - SKY_ROWS), 0.0, 1.0)


## The stars the dwarves earned: one for the treasure, two for half of the
## gems, and three for 80 % of them.
func stars() -> int:
    if state != State.WON:
        return 0
    var share := float(gems) / float(maxi(1, gems_total))
    if share >= 0.8:
        return 3
    if share >= 0.5:
        return 2
    return 1


## Advance the mine by dt seconds.
func step(dt: float) -> void:
    if state != State.PLAYING:
        return
    time += dt

    if flood_level() >= PUMP_AT:
        if MineBoosters.has(self, "pump"):
            MineBoosters.pump(self, Vector2(WIDTH / 2.0, view_top + 2.0))
        else:
            MineBoosters.use(self, "pump")

    for dwarf in dwarves:
        move_dwarf(dwarf, dt)
    rivalry.update(self, dt)
    moles.update(self, dt)

    puzzles.update(self, dt)
    _burn_fuses(dt)
    MineDragons.fly(self, dt)
    MineDragons.fall(self, dt)

    _water_clock += dt
    var water_step := 1.0 / WATER_RATE
    while _water_clock >= water_step:
        _water_clock -= water_step
        MineWater.flow(self, water_step)

    _follow_view(dt)
    _lower_ropes(dt)
    _check_end()


# --- The generation ------------------------------------------------------------


## The count of the level (e.g., "gems").
## A count of the level, for the area of this mine (see [constant AREA_SCALE]).
func _scaled(field: String) -> int:
    return int(round(float(level.get(field, 0)) * AREA_SCALE))


func _generate() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = int(level.get("seed", 0))

    var depth := int(level.get("depth", 0))
    # NOTE (mristin):
    # The sky, the earth, the treasure chamber (3 rows of air and its floor) and
    # the bedrock at the bottom.
    height = SKY_ROWS + depth + 5
    cells.resize(WIDTH * height)
    hits_left.resize(WIDTH * height)
    water.resize(WIDTH * height)
    water.fill(0.0)

    var rock: Array = level.get("rock", [0.2, 0.5])
    var top := SKY_ROWS
    var bottom := SKY_ROWS + depth
    for y in range(height):
        for x in range(WIDTH):
            var kind := Cell.AIR
            if x == 0 or x == WIDTH - 1 or y == height - 1:
                kind = Cell.BEDROCK if y >= top else Cell.AIR
            elif y >= top and y < bottom:
                var t := float(y - top) / float(maxi(1, depth - 1))
                var p_rock := lerpf(float(rock[0]), float(rock[1]), t)
                kind = Cell.ROCK if rng.randf() < p_rock and y > top else Cell.DIRT
            elif y == height - 2:
                kind = Cell.ROCK
            cells[index(x, y)] = kind

    # NOTE (mristin):
    # The bands of hard rock across the mine, every so many rows, and the clumps
    # of rock. There is nothing which a pickaxe does not break: the dwarves only
    # dig down, so anything unbreakable below a dwarf would trap it.
    var bands := int(level.get("bands", 0))
    if bands > 0:
        var y := top + bands
        while y < bottom - 4:
            for x in range(1, WIDTH - 1):
                cells[index(x, y)] = Cell.ROCK
            y += bands + rng.randi_range(-2, 2)

    var interior := (WIDTH - 2) * depth
    var clumps := int(round(float(level.get("clumps", 0.0)) * interior / 100.0 / 3.0))
    for b in range(clumps):
        var bw := rng.randi_range(2, 4)
        var bh := rng.randi_range(1, 2)
        var bx := rng.randi_range(1, WIDTH - 1 - bw)
        var by := rng.randi_range(top + 3, bottom - 2 - bh)
        for yy in range(by, by + bh):
            for xx in range(bx, bx + bw):
                cells[index(xx, yy)] = Cell.ROCK

    # NOTE (mristin):
    # The caves, where the dwarves drop down a few rows at once.
    for c in range(_scaled("caves")):
        var cw := rng.randi_range(2, 5)
        var ch := rng.randi_range(1, 3)
        var cx := rng.randi_range(1, WIDTH - 1 - cw)
        var cy := rng.randi_range(top + 4, bottom - 3 - ch)
        for yy in range(cy, cy + ch):
            for xx in range(cx, cx + cw):
                cells[index(xx, yy)] = Cell.AIR
        # A cave has a floor to stand on.
        for xx in range(cx, cx + cw):
            if cells[index(xx, cy + ch)] == Cell.AIR:
                cells[index(xx, cy + ch)] = Cell.DIRT

    # NOTE (mristin):
    # The treasure chamber: three rows of air, the chest in the middle of its
    # floor.
    var chamber_x := rng.randi_range(2, WIDTH - 7)
    for yy in range(bottom, bottom + 3):
        for xx in range(chamber_x, chamber_x + 5):
            cells[index(xx, yy)] = Cell.AIR
    for xx in range(1, WIDTH - 1):
        cells[index(xx, bottom + 3)] = Cell.BEDROCK
    chest = Vector2i(chamber_x + 2, bottom + 2)

    puzzles.carve(self, rng, top, depth)

    # NOTE (mristin):
    # The gas pockets, sometimes two or three together.
    var pockets := _scaled("gas")
    var placed := 0
    while placed < pockets:
        var ex := rng.randi_range(1, WIDTH - 2)
        var ey := rng.randi_range(top + 3, bottom - 3)
        var group := rng.randi_range(1, 3)
        for g in range(group):
            var gx := clampi(ex + g, 1, WIDTH - 2)
            if _is_earth(gx, ey):
                cells[index(gx, ey)] = Cell.GAS
                placed += 1

    # NOTE (mristin):
    # The gems, spread over the whole depth: each gem lies in its own band of
    # rows, so that the dwarves find gems all the way down.
    var gem_count := int(level.get("gems", 0))
    for g in range(gem_count):
        var band_top := top + 1 + int(float(g) / gem_count * (depth - 2))
        var band_bottom := top + 1 + int(float(g + 1) / gem_count * (depth - 2))
        for attempt in range(40):
            var gx := rng.randi_range(1, WIDTH - 2)
            var gy := rng.randi_range(band_top, maxi(band_top, band_bottom - 1))
            var i := index(gx, gy)
            if _is_earth(gx, gy) and not items.has(i):
                items[i] = "gem"
                gems_total += 1
                break
            if cells[i] == Cell.AIR and not loose.has(i) and is_solid(gx, gy + 1):
                loose[i] = "gem"
                gems_total += 1
                break

    for spring in level.get("springs", []):
        var sx := 0 if spring["side"] == "left" else WIDTH - 1
        var sy := top + int(float(spring["at"]) * depth)
        sy = clampi(sy, top + 2, bottom - 2)
        cells[index(sx, sy)] = Cell.SPRING
        springs.append(index(sx, sy))
        var inner := 1 if sx == 0 else WIDTH - 2
        if cells[index(inner, sy)] == Cell.AIR:
            cells[index(inner, sy)] = Cell.DIRT

    for y in range(height):
        for x in range(WIDTH):
            var kind := cells[index(x, y)]
            hits_left[index(x, y)] = int(HITS.get(kind, 0))


func _is_earth(x: int, y: int) -> bool:
    var kind := cell(x, y)
    return kind == Cell.DIRT or kind == Cell.ROCK


# --- The dwarves ---------------------------------------------------------------


## The block which the pickaxe of the dwarf hits: the one below its feet, or
## (-1, -1) if none.
##
## A jump only hits down (an arm swung out hits sideways, see [method
## swing_side]). The only exception is an open spring in the wall right beside
## the dwarf: the dwarf hammers it shut, so that the players can stop the water
## with nothing but their jumps.
func _hit_target(dwarf: Dwarf) -> Vector2i:
    var cx := int(floor(dwarf.pos.x))
    var body := int(floor(dwarf.pos.y - DWARF_HEIGHT * 0.5))
    for side in [-1, 1]:
        var wall: int = cx + side
        if (wall == 0 or wall == WIDTH - 1) and cell(wall, body) == Cell.SPRING:
            if cell(cx, body) == Cell.AIR:
                return Vector2i(wall, body)

    if not dwarf.on_ground:
        return Vector2i(-1, -1)

    var below := int(floor(dwarf.pos.y + 0.05))
    if is_breakable(cx, below):
        return Vector2i(cx, below)
    # NOTE (mristin):
    # The dwarf stands on the edge of a block, with its middle over the air.
    for x in [
        int(floor(dwarf.pos.x - DWARF_HALF_WIDTH + 0.02)),
        int(floor(dwarf.pos.x + DWARF_HALF_WIDTH - 0.02))
    ]:
        if is_breakable(x, below):
            return Vector2i(x, below)
    return Vector2i(-1, -1)


## The block beside the dwarf (on the side, -1 or 1) which its pickaxe reaches,
## from its feet up to its head, or (-1, -1) if none.
func _side_target(dwarf: Dwarf, side: int) -> Vector2i:
    var x := int(floor(dwarf.pos.x + side * (DWARF_HALF_WIDTH + SIDE_REACH)))
    if x == int(floor(dwarf.pos.x)):
        return Vector2i(-1, -1)
    var rows := _rows_of(dwarf.pos.y)
    for y in range(rows.y, rows.x - 1, -1):
        if is_breakable(x, y):
            return Vector2i(x, y)
    return Vector2i(-1, -1)


## Hit the block of the target with the strength (in hits; by the dwarf, or by
## null for the fire).
func hit_block(target: Vector2i, strength: float, dwarf: Dwarf) -> void:
    var i := index(target.x, target.y)
    var kind := cells[i]
    if kind == Cell.GAS:
        _release(i, FUSE_TIME)
        return
    var left := maxf(0.0, hits_left[i] - strength)
    hits_left[i] = left
    if left > 0.01:
        (
            events
            . append(
                {
                    "type": "hit",
                    "pos": Vector2(target) + Vector2(0.5, 0.5),
                    "kind": kind,
                    "dwarf": dwarf.index if dwarf != null else -1,
                }
            )
        )
        return
    _break(target, dwarf)


func _break(target: Vector2i, dwarf: Dwarf) -> void:
    var i := index(target.x, target.y)
    var kind := cells[i]
    var center := Vector2(target) + Vector2(0.5, 0.5)
    if kind == Cell.SPRING:
        cells[i] = Cell.SEALED
        hits_left[i] = 0
        events.append({"type": "sealed", "pos": center})
        return
    cells[i] = Cell.AIR
    hits_left[i] = 0
    fuses.erase(i)
    events.append({"type": "break", "pos": center, "kind": kind})
    if items.has(i):
        if dwarf != null and dwarf == rival:
            # NOTE (mristin):
            # The evil miner takes no gems: they fall out for the dwarves.
            loose[i] = items[i]
        else:
            _collect(str(items[i]), center, dwarf)
        items.erase(i)


## The dwarf (or, from an explosion, the nearest dwarf) takes the gem.
func _collect(kind: String, at: Vector2, dwarf: Dwarf) -> void:
    if dwarf == null:
        var best := INF
        for each in dwarves:
            var distance := each.pos.distance_to(at)
            if distance < best:
                best = distance
                dwarf = each
    if kind == "gem":
        gems += 1
        if dwarf != null:
            dwarf.gems += 1
        events.append({"type": "gem", "pos": at, "dwarf": dwarf.index if dwarf != null else -1})


## Move the dwarf (or the evil miner) for dt seconds: walk towards its target,
## fall, and gather the loose gems.
func move_dwarf(dwarf: Dwarf, dt: float) -> void:
    dwarf.stars = maxf(0.0, dwarf.stars - dt)
    dwarf.swing = maxf(0.0, dwarf.swing - dt)
    dwarf.stun = maxf(0.0, dwarf.stun - dt)

    var head := Vector2i(int(floor(dwarf.pos.x)), int(floor(dwarf.pos.y - DWARF_HEIGHT * 0.8)))
    var was_swimming := dwarf.swimming
    dwarf.swimming = water_at(head.x, head.y) > 0.5
    if dwarf.swimming and not was_swimming:
        events.append({"type": "splash", "pos": dwarf.pos})

    # NOTE (mristin):
    # Sideways: towards where the player stands, unless the dwarf is dizzy.
    var vx := 0.0
    if dwarf.stun <= 0.0:
        var speed := WALK_SPEED * (0.55 if dwarf.swimming else 1.0)
        vx = clampf((dwarf.target_x - dwarf.pos.x) * 8.0, -speed, speed)
        if absf(dwarf.target_x - dwarf.pos.x) > 0.05:
            dwarf.facing = 1 if dwarf.target_x > dwarf.pos.x else -1
    vx += dwarf.vel.x
    dwarf.vel.x = move_toward(dwarf.vel.x, 0.0, 12.0 * dt)
    _move_x(dwarf, vx * dt)

    # NOTE (mristin):
    # Up and down: the dwarf falls, slowly in the water.
    dwarf.vel.y = minf(dwarf.vel.y + GRAVITY * dt, 4.0 if dwarf.swimming else 16.0)
    _move_y(dwarf, dwarf.vel.y * dt)

    if dwarf == rival:
        return
    if dwarf.pos.y > deepest:
        deepest = dwarf.pos.y

    var key := index(int(floor(dwarf.pos.x)), int(floor(dwarf.pos.y - 0.5)))
    if loose.has(key):
        _collect(str(loose[key]), dwarf.pos - Vector2(0, 0.5), dwarf)
        loose.erase(key)


func _rows_of(y: float) -> Vector2i:
    return Vector2i(int(floor(y - DWARF_HEIGHT + 0.01)), int(floor(y - 0.01)))


func _move_x(dwarf: Dwarf, dx: float) -> void:
    if dx == 0.0:
        return
    var rows := _rows_of(dwarf.pos.y)
    var x := dwarf.pos.x + dx
    if dx > 0.0:
        var edge := int(floor(x + DWARF_HALF_WIDTH))
        for row in range(rows.x, rows.y + 1):
            if is_solid(edge, row):
                x = edge - DWARF_HALF_WIDTH - 0.001
                break
    else:
        var edge := int(floor(x - DWARF_HALF_WIDTH))
        for row in range(rows.x, rows.y + 1):
            if is_solid(edge, row):
                x = edge + 1 + DWARF_HALF_WIDTH + 0.001
                break
    dwarf.pos.x = x


func _move_y(dwarf: Dwarf, dy: float) -> void:
    var y := dwarf.pos.y + dy
    var left := int(floor(dwarf.pos.x - DWARF_HALF_WIDTH + 0.01))
    var right := int(floor(dwarf.pos.x + DWARF_HALF_WIDTH - 0.01))
    dwarf.on_ground = false
    if dy >= 0.0:
        var row := int(floor(y))
        for x in range(left, right + 1):
            if is_solid(x, row):
                y = float(row)
                dwarf.vel.y = 0.0
                dwarf.on_ground = true
                break
    else:
        var row := int(floor(y - DWARF_HEIGHT))
        for x in range(left, right + 1):
            if is_solid(x, row):
                y = float(row + 1) + DWARF_HEIGHT
                dwarf.vel.y = 0.0
                break
    dwarf.pos.y = y


# --- The gas -------------------------------------------------------------------


## Open the gas pocket of the cell: the block is gone, and its gas floats there
## until it explodes after the fuse (in seconds).
func _release(i: int, fuse: float) -> void:
    if cells[i] == Cell.GAS:
        cells[i] = Cell.AIR
        hits_left[i] = 0
        events.append({"type": "gas", "pos": Vector2(i % WIDTH, i / WIDTH) + Vector2(0.5, 0.5)})
    if fuses.has(i):
        fuses[i] = minf(float(fuses[i]), fuse)
    else:
        fuses[i] = fuse


## Set the gas of the cell on fire at once (e.g., the dragons' fire).
func ignite(i: int) -> void:
    if fuses.has(i):
        fuses[i] = minf(float(fuses[i]), 0.05)


func _burn_fuses(dt: float) -> void:
    if fuses.is_empty():
        return
    var exploding: Array[int] = []
    for i in fuses.keys():
        fuses[i] = float(fuses[i]) - dt
        if float(fuses[i]) <= 0.0:
            exploding.append(i)
    for i in exploding:
        fuses.erase(i)
        _explode(Vector2i(i % WIDTH, i / WIDTH))


## Blow up the gas of the cell: the blocks around it break, the gas pockets in
## reach open and blow up right after, and the dwarves nearby get dizzy.
func _explode(at: Vector2i) -> void:
    var center := Vector2(at) + Vector2(0.5, 0.5)
    cells[index(at.x, at.y)] = Cell.AIR
    hits_left[index(at.x, at.y)] = 0
    events.append({"type": "explosion", "pos": center})
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            if absi(dx) + absi(dy) > 2 and (absi(dx) == 2 or absi(dy) == 2):
                continue
            var x := at.x + dx
            var y := at.y + dy
            if x <= 0 or x >= WIDTH - 1 or y < SKY_ROWS or y >= height - 1:
                continue
            var kind := cell(x, y)
            if kind == Cell.GAS or fuses.has(index(x, y)):
                _release(index(x, y), CHAIN_FUSE_TIME)
            elif kind == Cell.DIRT or kind == Cell.ROCK:
                cells[index(x, y)] = Cell.AIR
                hits_left[index(x, y)] = 0
                var i := index(x, y)
                if items.has(i):
                    _collect(str(items[i]), Vector2(x + 0.5, y + 0.5), null)
                    items.erase(i)
    for dwarf in _bodies():
        var offset := dwarf.pos - Vector2(0, 0.45) - center
        if offset.length() < 2.3:
            if MineBoosters.shielded(self, dwarf):
                events.append({"type": "shielded", "pos": dwarf.pos, "dwarf": dwarf.index})
                continue
            dwarf.stun = STUN_TIME
            dwarf.vel = Vector2(signf(offset.x) * 6.0 if offset.x != 0.0 else 0.0, -8.0)
            events.append({"type": "dizzy", "pos": dwarf.pos, "dwarf": dwarf.index})


# --- The water -----------------------------------------------------------------

# --- The view and the end ------------------------------------------------------


func _follow_view(dt: float) -> void:
    if dwarves.is_empty():
        return
    var sum := 0.0
    var lowest := -INF
    for dwarf in dwarves:
        sum += dwarf.pos.y
        lowest = maxf(lowest, dwarf.pos.y)
    var target := sum / dwarves.size() - VIEW_ROWS * 0.5
    target = maxf(target, lowest - VIEW_ROWS + 3.0)
    target = clampf(target, 0.0, float(height) - VIEW_ROWS)
    view_top += (target - view_top) * (1.0 - exp(-dt / 0.5))


## A dwarf left above the top of the screen is let down on a rope to the
## deepest dwarf, so that the friends stay together.
func _lower_ropes(dt: float) -> void:
    var deepest_dwarf := _deepest_dwarf()
    for dwarf in dwarves:
        if dwarf.pos.y < view_top + 0.6:
            dwarf.above_screen += dt
        else:
            dwarf.above_screen = 0.0
        if dwarf.above_screen >= ROPE_AFTER and dwarf != deepest_dwarf:
            dwarf.above_screen = 0.0
            dwarf.pos = deepest_dwarf.pos
            dwarf.vel = Vector2.ZERO
            dwarf.target_x = dwarf.pos.x
            events.append({"type": "rope", "pos": dwarf.pos, "dwarf": dwarf.index})


func _check_end() -> void:
    for dwarf in dwarves:
        if (
            absf(dwarf.pos.x - (chest.x + 0.5)) < 0.9
            and dwarf.pos.y > chest.y
            and dwarf.pos.y <= chest.y + 1.01
        ):
            state = State.WON
            events.append({"type": "won", "pos": Vector2(chest) + Vector2(0.5, 0.5)})
            return
    # NOTE (mristin):
    # The evil miner takes the treasure only if no dwarf is in the treasure
    # hall: dwarves who arrive with him drive him off.
    for dwarf in dwarves:
        if dwarf.pos.y > chest.y - 2.5:
            return
    if (
        rival != null
        and absf(rival.pos.x - (chest.x + 0.5)) < 0.9
        and rival.pos.y > chest.y
        and rival.pos.y <= chest.y + 1.01
    ):
        state = State.LOST
        events.append({"type": "lost", "pos": Vector2(chest) + Vector2(0.5, 0.5)})
        return
    if level.get("flood", 0.0) > 0.0 and water_total >= float(level["flood"]) * AREA_SCALE:
        state = State.FLOODED
        events.append({"type": "flooded", "pos": Vector2(WIDTH / 2.0, view_top)})


## The players' dwarves and the evil miner: whom the fire and the explosions
## reach.
func _bodies() -> Array[Dwarf]:
    var result: Array[Dwarf] = dwarves.duplicate()
    if rival != null:
        result.append(rival)
    return result
