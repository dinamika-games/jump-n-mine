class_name MineBot
extends RefCounted

## A bot which plays a dwarf in the [Mine] like a player: it can only step
## (set where its dwarf goes) and jump (swing the pickaxe down, and hop), and
## it jumps no more often than a child (every [member jump_period] seconds).
##
## The tests let bots play every level (tests/godot/level_playthrough.gd), and
## the level plays one for each dwarf with --bots (to watch the levels).
##
## The bot plans with Dijkstra over the places where its dwarf can stand in the
## next rows: a place is the block the dwarf stands on. From a place, the dwarf
## digs the block below (and falls to the next floor), walks to the side (and
## falls, if there is no floor), or hops onto a step of one block. The cost is
## in jumps. The bot digs to the gems on the way, hammers the open springs shut
## when the water rises, and else goes as deep as it can.

enum Move { START, DIG, WALK, HOP }

## How many rows below the dwarf the bot plans.
const WINDOW := 22

## The cost of walking one block, and of one jump.
const WALK := 1
const JUMP := 10

## The bot digs to a gem which costs at most this much (about eight blocks).
const GEM_REACH := 8 * 35

## When the water rises, the bot goes to a spring at most this far.
const SPRING_REACH := 14 * 35

## A row deeper is worth more than any detour within the window.
const DEPTH_REWARD := 100000

## The bot keeps to its goal unless another is better by this much.
const GOAL_STICKINESS := 120

var mine: Mine
var player := 0
var jump_period := 1.6

var _since_jump := 0.0
## The places of the plan (each the block to stand on), and how to get there.
var _path: Array[Vector2i] = []
var _moves: Array[int] = []
var _planned_from := Vector2i(-1, -1)
var _replan := 0.0
var _goal := Vector2i(-1, -1)
var _place := Vector2i(-1, -1)


func _init(a_mine: Mine, a_player: int, a_jump_period := 1.6) -> void:
    mine = a_mine
    player = a_player
    jump_period = a_jump_period
    # NOTE (mristin):
    # The players do not jump all at the same time.
    _since_jump = a_player * 0.37


## Step and jump for the next dt seconds; call it before [method Mine.step].
func act(dt: float) -> void:
    _since_jump += dt
    _replan -= dt
    var dwarf: Mine.Dwarf = mine.dwarf_of(player)
    if dwarf == null:
        return
    if not dwarf.on_ground:
        return
    var here := _place_of(dwarf)
    if _solve_puzzle(here):
        return
    if here != _planned_from or _replan <= 0.0 or _path.is_empty():
        _plan(here)
        _planned_from = here
        _replan = 2.0

    if _path.size() < 2:
        _hammer_spring(dwarf, here)
        return

    var next := _path[1]
    var middle := here.x + 0.5
    match _moves[1]:
        Move.DIG:
            mine.set_target(player, middle)
            if absf(dwarf.pos.x - middle) < 0.2:
                _jump()
        Move.WALK:
            mine.set_target(player, next.x + 0.5)
        Move.HOP:
            # Hop onto the step: walk against it and jump.
            mine.set_target(player, next.x + 0.5)
            var side := signi(next.x - here.x)
            var face := float(here.x + 1) if side > 0 else float(here.x)
            if absf(face - (dwarf.pos.x + side * Mine.DWARF_HALF_WIDTH)) < 0.1:
                _jump()


## On the floor of a puzzle hall: stand on a plate until the gate opens, then
## drop through the gate. Return whether the bot is busy with a puzzle.
func _solve_puzzle(here: Vector2i) -> bool:
    var puzzle: MinePuzzles.Puzzle = null
    for each in mine.puzzles.puzzles:
        if each.row == here.y:
            puzzle = each
    if puzzle == null:
        return false
    if puzzle.open:
        var best := puzzle.gate[0]
        for cell in puzzle.gate:
            if absi(cell.x - here.x) < absi(best.x - here.x):
                best = cell
        mine.set_target(player, best.x + 0.5)
        return true
    # NOTE (mristin):
    # Each dwarf takes its own plate, by its rank among the dwarves here.
    var rank := 0
    for other in mine.dwarves:
        if other.index < player:
            rank += 1
    var plate := puzzle.plates[rank % puzzle.plates.size()]
    mine.set_target(player, plate.x + 0.5)
    return true


## Beside an open spring, hammer it shut.
func _hammer_spring(dwarf: Mine.Dwarf, here: Vector2i) -> void:
    for side in [-1, 1]:
        if mine.cell(here.x + side, here.y - 1) == Mine.Cell.SPRING:
            mine.set_target(player, here.x + 0.5)
            _jump()
            return
    mine.set_target(player, dwarf.pos.x)


func _jump() -> void:
    if _since_jump >= jump_period:
        _since_jump = 0.0
        mine.jump(player)
        _replan = 0.0


## The block the dwarf stands on; it changes sideways only once the dwarf is
## well over the next block, so that a dwarf on the border does not flip the
## plan.
func _place_of(dwarf: Mine.Dwarf) -> Vector2i:
    var place := Vector2i(int(floor(dwarf.pos.x)), int(round(dwarf.pos.y)))
    if place.y == _place.y and place.x != _place.x:
        if absf(dwarf.pos.x - (place.x + 0.5)) > 0.3:
            return _place
    if not mine.is_solid(place.x, place.y):
        # NOTE (mristin):
        # The dwarf stands on the edge of the next block, over a hole.
        for x in [
            int(floor(dwarf.pos.x - Mine.DWARF_HALF_WIDTH + 0.02)),
            int(floor(dwarf.pos.x + Mine.DWARF_HALF_WIDTH - 0.02))
        ]:
            if mine.is_solid(x, place.y):
                place.x = x
    _place = place
    return place


## The first solid block from the row y down in the column x: where a dwarf
## falling there lands.
func _floor_below(x: int, y: int) -> int:
    var f := y
    while f < mine.height - 1 and not mine.is_solid(x, f):
        f += 1
    return f


func _plan(start: Vector2i) -> void:
    _path.clear()
    _moves.clear()
    var top := start.y - 2
    var bottom := mini(start.y + WINDOW, mine.height - 1)
    var rows := bottom - top + 1
    var count := Mine.WIDTH * rows
    var dist := PackedInt32Array()
    dist.resize(count)
    dist.fill(1 << 30)
    var previous := PackedInt32Array()
    previous.resize(count)
    previous.fill(-1)
    var how := PackedInt32Array()
    how.resize(count)
    how.fill(Move.START)

    var start_key := (start.y - top) * Mine.WIDTH + start.x
    dist[start_key] = 0
    var heap: Array[int] = [start_key]
    var best_key := -1
    var best_score := 1 << 30
    var gem_key := -1
    var gem_cost := GEM_REACH
    var spring_key := -1
    var spring_cost := SPRING_REACH
    var flood := mine.flood_level()

    while not heap.is_empty():
        var packed := _pop(heap)
        var key := packed & 0xFFFF
        var d := packed >> 16
        if d > dist[key]:
            continue
        var x := key % Mine.WIDTH
        var y := top + key / Mine.WIDTH

        # NOTE (mristin):
        # A gem in the block underfoot is taken by digging it, and a loose gem
        # by standing at it.
        var below := mine.index(x, y)
        var body := mine.index(x, y - 1)
        var gem: bool = mine.items.get(below, "") == "gem" or mine.loose.get(body, "") == "gem"
        if gem and d < gem_cost:
            gem_cost = d
            gem_key = key
        if flood > 0.3 and d < spring_cost:
            for side in [-1, 1]:
                if mine.cell(x + side, y - 1) == Mine.Cell.SPRING:
                    spring_cost = d
                    spring_key = key

        var score := d - DEPTH_REWARD * (y - start.y)
        if Vector2i(x, y) == _goal:
            score -= GOAL_STICKINESS
        if y >= mine.chest.y + 1:
            score -= 100000000 - absi(x - mine.chest.x) * JUMP
        if key != start_key and score < best_score:
            best_score = score
            best_key = key

        # The next places: x, y and (the move | its cost << 4).
        var nexts: Array[Vector3i] = []
        if mine.is_breakable(x, y):
            var hits := 1 if mine.cell(x, y) == Mine.Cell.GAS else mine.hits_left[below]
            nexts.append(Vector3i(x, _floor_below(x, y + 1), Move.DIG | (hits * JUMP) << 4))
        for side in [-1, 1]:
            var nx: int = x + side
            if nx <= 0 or nx >= Mine.WIDTH - 1:
                continue
            if not mine.is_solid(nx, y - 1):
                nexts.append(Vector3i(nx, _floor_below(nx, y), Move.WALK | WALK << 4))
            elif not mine.is_solid(nx, y - 2) and not mine.is_solid(x, y - 2):
                nexts.append(Vector3i(nx, y - 1, Move.HOP | JUMP << 4))
        for n in nexts:
            if n.y < top or n.y > bottom:
                continue
            var nkey := (n.y - top) * Mine.WIDTH + n.x
            var nd: int = d + (n.z >> 4)
            if nd < dist[nkey]:
                dist[nkey] = nd
                previous[nkey] = key
                how[nkey] = n.z & 0xF
                _push(heap, (nd << 16) | nkey)

    if spring_key >= 0:
        best_key = spring_key
    elif gem_key == start_key:
        # The gem lies in the block underfoot: dig it.
        _path = [start, start + Vector2i(0, 1)]
        _moves = [Move.START, Move.DIG]
        return
    elif gem_key >= 0:
        best_key = gem_key
    if best_key < 0:
        return
    _goal = Vector2i(best_key % Mine.WIDTH, top + best_key / Mine.WIDTH)
    var key := best_key
    while key >= 0:
        _path.push_front(Vector2i(key % Mine.WIDTH, top + key / Mine.WIDTH))
        _moves.push_front(how[key])
        key = previous[key]


static func _push(heap: Array[int], value: int) -> void:
    heap.append(value)
    var i := heap.size() - 1
    while i > 0:
        var parent := (i - 1) / 2
        if heap[parent] <= heap[i]:
            break
        var swap := heap[parent]
        heap[parent] = heap[i]
        heap[i] = swap
        i = parent


static func _pop(heap: Array[int]) -> int:
    var result := heap[0]
    var last: int = heap.pop_back()
    if heap.is_empty():
        return result
    heap[0] = last
    var i := 0
    var n := heap.size()
    while true:
        var left := 2 * i + 1
        var right := left + 1
        var smallest := i
        if left < n and heap[left] < heap[smallest]:
            smallest = left
        if right < n and heap[right] < heap[smallest]:
            smallest = right
        if smallest == i:
            break
        var swap := heap[smallest]
        heap[smallest] = heap[i]
        heap[i] = swap
        i = smallest
    return result
