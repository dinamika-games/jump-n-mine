class_name MineRival
extends RefCounted

## The evil miner of Queen Treacher, who races the dwarves to the treasure (see
## [code]rival[/code] in [LevelCatalog]); the dwarf himself is
## [member Mine.rival], played by a [MineBot] for the slot [constant
## Mine.RIVAL], which reads [member period] and [member waits].
##
## He arrives a moment after the first dwarf, on the grass on the other side.
## His pace adapts to the players: he digs down a little slower than they did
## over the last [constant WINDOW] seconds; close behind them, he does not stop,
## but digs on slowly and steadily, and waits only once he caught up with them,
## pacing left and right.
## When they stop digging, he digs on like the tortoise and overtakes them. A
## dwarf who hits him knocks him out; he knocks out a dwarf beside him now and
## then. He presses no plates, but pries a bar out of a closed gate.

## The evil miner arrives this long after the first dwarf, in seconds.
const ARRIVES := 3.0

## How long the evil miner lies knocked out after a dwarf hit him, in seconds.
const KNOCKOUT_TIME := 5.0

## How long a dwarf hit by the evil miner sees stars, in seconds.
const BONK_TIME := 1.5

## The evil miner hits a dwarf beside him at most this often, in seconds.
const HIT_EVERY := 8.0

## The evil miner pries a bar out of a closed gate in this many seconds.
const PRY_TIME := 4.0

## Over the last [constant WINDOW] seconds, he digs down at [constant PACE] of
## the speed of the players, but never jumps less often than every [constant
## TORTOISE_PERIOD] seconds (the tortoise), nor more often than every
## [constant FASTEST].
const WINDOW := 25
const PACE := 0.8
const TORTOISE_PERIOD := 4.0
const FASTEST := 1.6

## Closer than [constant LAG] rows behind the players' deepest dwarf, he digs
## on slowly and steadily, a jump every [constant STEADY_PERIOD] seconds, and
## closer than [constant CAUGHT_UP] rows, he waits (he also falls down the
## shafts which the dwarves dug), unless the players stopped: their deepest
## dwarf came less than [constant STOPPED_ROWS] deeper in the last [constant
## STOPPED_WINDOW] seconds. Then he digs on like the tortoise, and overtakes
## them.
const LAG := 4.0
const STEADY_PERIOD := 3.0
const CAUGHT_UP := 0.5
const STOPPED_ROWS := 1.0
const STOPPED_WINDOW := 12

## How often he jumps now, in seconds.
var period := 2.4
## He waits close behind the players (see [constant LAG]).
var waits := false

## When he arrives, INF before the first dwarf came.
var _arrive_at := INF
var _hit_in := 0.0
var _pry := 0.0
## Once a second, how deep the players' deepest dwarf and he are.
var _frontier: Array[float] = []
var _depths: Array[float] = []
var _clock := 0.0
## The players stopped digging (see [constant STOPPED_WINDOW]).
var _stopped := false


## A dwarf came into the mine: the first brings the evil miner, if the level has
## him.
func dwarf_came(mine: Mine) -> void:
    if _arrive_at == INF and bool(mine.level.get("rival", false)):
        _arrive_at = mine.time + ARRIVES


## The pickaxe of the dwarf struck at the point (in cells; the body of the dwarf
## at the body), down (side 0) or to the side: if the evil miner is there, he is
## knocked out. Return whether he was hit.
func strike(mine: Mine, dwarf: Mine.Dwarf, point: Vector2, body: Vector2, side: int) -> bool:
    var rival := mine.rival
    if rival == null or rival.stars > 0.0:
        return false
    var other := rival.pos - Vector2(0, Mine.DWARF_HEIGHT * 0.5)
    var offset := other - body
    var near := other.distance_to(point) < 0.75
    if side == 0:
        near = near or (absf(offset.x) < 1.0 and absf(offset.y) < 0.7)
    else:
        near = (
            near or (signf(offset.x) == side and absf(offset.x) < 1.25 and absf(offset.y) < 0.7)
        )
    if not near:
        return false
    rival.stun = KNOCKOUT_TIME
    rival.stars = KNOCKOUT_TIME
    rival.swing = 0.0
    var away := signf(offset.x) if offset.x != 0.0 else float(dwarf.facing)
    rival.vel = Vector2(away * 4.0, -6.0)
    mine.events.append({"type": "knockout", "pos": rival.pos, "dwarf": dwarf.index})
    return true


## Bring the evil miner when his time came, let him move, hit a dwarf beside
## him now and then, pry the bars out of the closed gates, and pace him.
func update(mine: Mine, dt: float) -> void:
    if mine.rival == null:
        if mine.time >= _arrive_at:
            _arrive(mine)
        return
    var rival := mine.rival
    mine.move_dwarf(rival, dt)
    _pace(mine, dt)
    waits = rival.pos.y >= _frontier_now(mine) - CAUGHT_UP and not _stopped

    _hit_in = maxf(0.0, _hit_in - dt)
    if rival.stun <= 0.0 and _hit_in <= 0.0 and not waits:
        for dwarf in mine.dwarves:
            var offset := dwarf.pos - rival.pos
            if absf(offset.x) < 1.0 and absf(offset.y) < 0.6 and dwarf.stun <= 0.0:
                var side := 1 if offset.x >= 0.0 else -1
                rival.swing = 0.35
                rival.swing_dir = Vector2i(side, 0)
                rival.facing = side
                dwarf.stun = BONK_TIME
                dwarf.stars = BONK_TIME
                dwarf.vel = Vector2(side * 5.0, -6.0)
                _hit_in = HIT_EVERY
                mine.events.append({"type": "bonked", "pos": dwarf.pos, "dwarf": dwarf.index})
                break

    # NOTE (mristin):
    # He presses no plates: he pries a bar out of a closed gate under his feet,
    # and leaves the hole for the dwarves, too.
    var below := Vector2i(int(floor(rival.pos.x)), int(floor(rival.pos.y + 0.05)))
    var puzzle := mine.puzzles.puzzle_at(below)
    if rival.on_ground and rival.stun <= 0.0 and puzzle != null and below in puzzle.gate:
        _pry += dt
        if _pry >= PRY_TIME:
            _pry = 0.0
            puzzle.gate.erase(below)
            mine.cells[mine.index(below.x, below.y)] = Mine.Cell.AIR
            mine.events.append({"type": "pried", "pos": Vector2(below) + Vector2(0.5, 0.5)})
    else:
        _pry = 0.0


## Let him arrive on the grass, on the other side than the deepest dwarf.
func _arrive(mine: Mine) -> void:
    var rival := Mine.Dwarf.new()
    rival.index = Mine.RIVAL
    var left := true
    for dwarf in mine.dwarves:
        if dwarf.pos.y >= mine.deepest - 0.01:
            left = dwarf.pos.x > Mine.WIDTH / 2.0
    rival.pos = Vector2(1.5 if left else Mine.WIDTH - 1.5, Mine.SKY_ROWS)
    rival.target_x = rival.pos.x
    mine.rival = rival
    mine.events.append({"type": "rival", "pos": rival.pos, "dwarf": Mine.RIVAL})


## How deep the players' deepest dwarf is now (or was, if they all left).
func _frontier_now(mine: Mine) -> float:
    var frontier := mine.deepest
    for dwarf in mine.dwarves:
        frontier = maxf(frontier, dwarf.pos.y)
    return frontier


## Once a second, compare how fast he dug down over the last [constant WINDOW]
## seconds with the players' deepest dwarf, and let him jump less or more often.
func _pace(mine: Mine, dt: float) -> void:
    _clock += dt
    if _clock < 1.0:
        return
    _clock -= 1.0
    var frontier := _frontier_now(mine)
    _frontier.append(frontier)
    _depths.append(mine.rival.pos.y)
    while _frontier.size() > WINDOW + 1:
        _frontier.pop_front()
        _depths.pop_front()
    _stopped = (
        _frontier.size() > STOPPED_WINDOW
        and _frontier[-1] - _frontier[-1 - STOPPED_WINDOW] < STOPPED_ROWS
    )
    if _stopped:
        period = TORTOISE_PERIOD
        return
    if mine.rival.pos.y >= frontier - LAG:
        period = STEADY_PERIOD
        return
    if _frontier.size() < 6:
        return
    var span := float(_frontier.size() - 1)
    var players := (_frontier[-1] - _frontier[0]) / span
    var his := (_depths[-1] - _depths[0]) / span
    if his > players * PACE:
        period *= 1.12
    else:
        period /= 1.06
    period = clampf(period, FASTEST, TORTOISE_PERIOD)
