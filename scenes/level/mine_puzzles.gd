class_name MinePuzzles
extends RefCounted

## The puzzles of the mine: a hall with an iron gate as its floor, across the
## whole mine, and stone plates on which the dwarves stand to open it. The
## dwarves can only step and jump, so the plates are pressed by standing on
## them.
##
## * A "timer" gate opens while a dwarf stands on its plate, and stays open for
##   [constant TIMER] seconds after: the dwarf runs off the plate and drops
##   through.
## * A "twin" gate opens for good once enough plates are pressed at the same
##   time. How many are enough follows the dwarves who dig right now, on the
##   fly: one dwarf alone needs one plate, two or more dwarves need two (each
##   of them on a plate), so that the friends work together, but a player who
##   is alone is never stuck. When a player leaves, the gate asks for fewer.
##
## The hall is three rows high and as wide as the mine, so that the dwarves dig
## into it from anywhere above; next to each plate, the floor is stone, so that
## a dwarf on a plate stands safe while the gate opens.

## How long a timer gate stays open after its plate was left, in seconds.
const TIMER := 4.5

## How many plates a twin gate has.
const TWIN_PLATES := 2


class Puzzle:
    extends RefCounted

    ## "timer" or "twin".
    var kind := "timer"
    ## The row of the gate (the floor of the hall).
    var row := 0
    var plates: Array[Vector2i] = []
    var gate: Array[Vector2i] = []
    var open := false
    ## A twin gate stays open for good once it opened.
    var latched := false
    ## A timer gate closes when this runs out, in seconds.
    var timer := 0.0
    ## Which plates are pressed now.
    var pressed: Array[bool] = []
    ## How many plates must be pressed together now.
    var needed := 1


var puzzles: Array[Puzzle] = []


## Carve the halls of the puzzles of the level into the mine (see
## [code]puzzles[/code] in [LevelCatalog]).
func carve(mine: Mine, rng: RandomNumberGenerator, top: int, depth: int) -> void:
    for spec in mine.level.get("puzzles", []):
        var puzzle := Puzzle.new()
        puzzle.kind = str(spec["kind"])
        var row := top + int(float(spec["at"]) * depth)
        row = clampi(row, top + 6, top + depth - 6)
        puzzle.row = row
        for y in range(row - 3, row):
            for x in range(1, Mine.WIDTH - 1):
                mine.cells[mine.index(x, y)] = Mine.Cell.AIR
                mine.items.erase(mine.index(x, y))
        var plate_xs: Array[int] = []
        if puzzle.kind == "twin":
            plate_xs = [rng.randi_range(2, 6), rng.randi_range(Mine.WIDTH - 7, Mine.WIDTH - 3)]
        else:
            plate_xs = [
                (
                    rng.randi_range(2, 4)
                    if rng.randf() < 0.5
                    else rng.randi_range(Mine.WIDTH - 5, Mine.WIDTH - 3)
                )
            ]
        for x in range(1, Mine.WIDTH - 1):
            var near := false
            for px in plate_xs:
                if absi(x - px) <= 1:
                    near = true
            var i := mine.index(x, row)
            mine.items.erase(i)
            if x in plate_xs:
                mine.cells[i] = Mine.Cell.PLATE
                puzzle.plates.append(Vector2i(x, row))
                puzzle.pressed.append(false)
            elif near:
                mine.cells[i] = Mine.Cell.BEDROCK
            else:
                mine.cells[i] = Mine.Cell.GATE
                puzzle.gate.append(Vector2i(x, row))
        # NOTE (mristin):
        # A gem waits in the hall, as a little reward for getting there.
        var gx := rng.randi_range(4, Mine.WIDTH - 5)
        if not gx in plate_xs:
            mine.loose[mine.index(gx, row - 1)] = "gem"
            mine.gems_total += 1
        puzzles.append(puzzle)


## The puzzle whose gate or plate is the cell, or null.
func puzzle_at(cell: Vector2i) -> Puzzle:
    for puzzle in puzzles:
        if cell.y == puzzle.row and (cell in puzzle.gate or cell in puzzle.plates):
            return puzzle
    return null


## Press the plates under the dwarves, and open and close the gates.
func update(mine: Mine, dt: float) -> void:
    for puzzle in puzzles:
        var count := 0
        for k in range(puzzle.plates.size()):
            var plate := puzzle.plates[k]
            var on := false
            for dwarf in mine.dwarves:
                if (
                    dwarf.on_ground
                    and int(round(dwarf.pos.y)) == plate.y
                    and absf(dwarf.pos.x - (plate.x + 0.5)) < 0.5 + Mine.DWARF_HALF_WIDTH - 0.05
                ):
                    on = true
            if on and not puzzle.pressed[k]:
                mine.events.append({"type": "plate", "pos": Vector2(plate) + Vector2(0.5, 0.0)})
            puzzle.pressed[k] = on
            if on:
                count += 1

        # NOTE (mristin):
        # How many plates are needed follows the dwarves who dig now.
        puzzle.needed = clampi(mine.dwarves.size(), 1, puzzle.plates.size())

        if puzzle.kind == "twin":
            if not puzzle.latched and count >= puzzle.needed:
                puzzle.latched = true
                _set_open(mine, puzzle, true)
        else:
            if count > 0:
                puzzle.timer = TIMER
                if not puzzle.open:
                    _set_open(mine, puzzle, true)
            elif puzzle.open:
                puzzle.timer -= dt
                if puzzle.timer <= 0.0 and not _occupied(mine, puzzle):
                    _set_open(mine, puzzle, false)


## Whether a dwarf is in the gate (then it must not close on the dwarf).
func _occupied(mine: Mine, puzzle: Puzzle) -> bool:
    for dwarf in mine.dwarves:
        for cell in puzzle.gate:
            if (
                absf(dwarf.pos.x - (cell.x + 0.5)) < 0.5 + Mine.DWARF_HALF_WIDTH
                and dwarf.pos.y > cell.y
                and dwarf.pos.y - Mine.DWARF_HEIGHT < cell.y + 1
            ):
                return true
    return false


func _set_open(mine: Mine, puzzle: Puzzle, open: bool) -> void:
    puzzle.open = open
    for cell in puzzle.gate:
        mine.cells[mine.index(cell.x, cell.y)] = Mine.Cell.AIR if open else Mine.Cell.GATE
    var middle := Vector2(Mine.WIDTH / 2.0, puzzle.row + 0.5)
    mine.events.append({"type": "gate_open" if open else "gate_closed", "pos": middle})
