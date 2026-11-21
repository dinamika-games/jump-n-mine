extends SceneTree
## Check the rules of the mine: three hits break the earth and four the rock,
## a jump only hits down and an arm swung out hits the block beside, a dwarf
## hops onto a step of one block, the gas pockets blow up their neighbors, the
## springs flood the mine unless they are hammered shut, the fire makes a dwarf
## dizzy unless it wears the helmet, and the treasure ends the level; the moles
## dig and cry when hit, the evil miner digs on when the players stop and sees
## stars when hit, and the boosters bought in the shop start when they help.

const DT := 1.0 / 60.0

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


## A small level of only earth, without any surprises.
func _plain(changes := {}) -> Dictionary:
    var level := {
        "id": "test",
        "name": "Test",
        "world": 0,
        "seed": 1,
        "depth": 12,
        "rock": [0.0, 0.0],
        "bands": 0,
        "clumps": 0.0,
        "caves": 0,
        "gems": 0,
        "gas": 0,
        "boosters": {},
        "springs": [],
        "flood": 20.0,
        "drain": 0.0,
        "dragons": [],
        "dragons_from": 1.0,
    }
    level.merge(changes, true)
    return level


func _wait(mine: Mine, seconds: float) -> void:
    var t := 0.0
    while t < seconds:
        mine.step(DT)
        t += DT


## Put the dwarf standing on the block (x, y).
func _stand(mine: Mine, x: int, y: int) -> Mine.Dwarf:
    var dwarf: Mine.Dwarf = mine.dwarves[0]
    for yy in range(Mine.SKY_ROWS, y):
        mine.cells[mine.index(x, yy)] = Mine.Cell.AIR
    dwarf.pos = Vector2(x + 0.5, y)
    dwarf.target_x = dwarf.pos.x
    _wait(mine, 0.5)
    return dwarf


func _check_hits() -> void:
    var mine := Mine.new(_plain(), 1)
    var dwarf := _stand(mine, 5, Mine.SKY_ROWS)
    for k in range(2):
        mine.jump(0)
        _wait(mine, 1.0)
    _check(mine.cell(5, Mine.SKY_ROWS) == Mine.Cell.DIRT, "two hits do not break the earth")
    _check(mine.damage(5, Mine.SKY_ROWS) > 0.5, "the earth is cracked after two hits")
    mine.jump(0)
    _wait(mine, 1.0)
    _check(mine.cell(5, Mine.SKY_ROWS) == Mine.Cell.AIR, "three hits break the earth")
    _check(dwarf.pos.y > Mine.SKY_ROWS + 0.9, "the dwarf falls into the hole")

    mine.cells[mine.index(5, Mine.SKY_ROWS + 1)] = Mine.Cell.ROCK
    mine.hits_left[mine.index(5, Mine.SKY_ROWS + 1)] = 4
    for k in range(3):
        mine.jump(0)
        _wait(mine, 1.0)
    _check(mine.cell(5, Mine.SKY_ROWS + 1) == Mine.Cell.ROCK, "three hits do not break the rock")
    mine.jump(0)
    _wait(mine, 1.0)
    _check(mine.cell(5, Mine.SKY_ROWS + 1) == Mine.Cell.AIR, "four hits break the rock")


func _check_weak_hits() -> void:
    var mine := Mine.new(_plain(), 1)
    _stand(mine, 5, Mine.SKY_ROWS)
    for k in range(5):
        mine.jump(0, 0.5)
        _wait(mine, 1.0)
    _check(mine.cell(5, Mine.SKY_ROWS) == Mine.Cell.DIRT, "five low jumps do not break the earth")
    _check(mine.damage(5, Mine.SKY_ROWS) > 0.8, "low jumps crack the earth, too")
    mine.jump(0, 0.5)
    _wait(mine, 1.0)
    _check(mine.cell(5, Mine.SKY_ROWS) == Mine.Cell.AIR, "six low jumps break the earth")


func _check_side() -> void:
    var mine := Mine.new(_plain(), 1)
    var y := Mine.SKY_ROWS + 3
    var dwarf := _stand(mine, 5, y)
    mine.cells[mine.index(6, y - 1)] = Mine.Cell.DIRT
    mine.hits_left[mine.index(6, y - 1)] = 3
    mine.cells[mine.index(6, y - 2)] = Mine.Cell.AIR
    mine.set_target(0, 8.0)
    _wait(mine, 0.5)
    _check(dwarf.pos.x < 6.0, "the dwarf does not walk through a block")
    mine.jump(0)
    _wait(mine, 0.8)
    _check(mine.hits_left[mine.index(6, y - 1)] == 3, "leaning against a block does not hit it")
    _check(mine.hits_left[mine.index(5, y)] == 2, "the pickaxe hits the block below")
    _check(dwarf.pos.x > 6.0 and dwarf.pos.y <= y - 0.99, "the jump hops the dwarf onto the step")


func _check_side_swing() -> void:
    var mine := Mine.new(_plain(), 1)
    var y := Mine.SKY_ROWS + 3
    var dwarf := _stand(mine, 5, y)
    for yy in range(Mine.SKY_ROWS, y):
        mine.cells[mine.index(6, yy)] = Mine.Cell.AIR
        mine.cells[mine.index(4, yy)] = Mine.Cell.AIR
    mine.cells[mine.index(6, y - 1)] = Mine.Cell.ROCK
    mine.hits_left[mine.index(6, y - 1)] = 4
    mine.set_target(0, 8.0)
    _wait(mine, 0.5)
    for k in range(3):
        mine.swing_side(0, 1)
        _wait(mine, 0.5)
    _check(mine.cell(6, y - 1) == Mine.Cell.ROCK, "three swings to the side do not break the rock")
    _check(mine.damage(6, y - 1) > 0.5, "swings to the side crack the block beside the dwarf")
    _check(
        mine.hits_left[mine.index(5, y)] == 3, "a swing to the side does not hit the block below"
    )
    _check(dwarf.pos.y > y - 0.01, "a swing to the side does not hop")
    mine.swing_side(0, 1)
    _wait(mine, 1.0)
    _check(mine.cell(6, y - 1) == Mine.Cell.AIR, "four swings to the side break the rock")
    _check(dwarf.pos.x > 6.0, "the dwarf walks through the opening")

    var cracked := mine.hits_left.duplicate()
    mine.set_target(0, 6.5)
    _wait(mine, 1.0)
    mine.swing_side(0, -1)
    _wait(mine, 0.5)
    _check(mine.hits_left == cracked, "a swing into the open air hits nothing")


func _check_explosion() -> void:
    var mine := Mine.new(_plain(), 1)
    var y := Mine.SKY_ROWS + 6
    var dwarf := _stand(mine, 1, Mine.SKY_ROWS + 2)
    mine.cells[mine.index(6, y)] = Mine.Cell.GAS
    mine.hits_left[mine.index(6, y)] = 1
    mine.cells[mine.index(7, y)] = Mine.Cell.ROCK
    mine.cells[mine.index(8, y)] = Mine.Cell.GAS
    mine.hits_left[mine.index(8, y)] = 1
    mine.items[mine.index(6, y + 1)] = "gem"
    mine._release(mine.index(6, y), 0.1)
    _wait(mine, 1.0)
    _check(mine.cell(6, y) == Mine.Cell.AIR, "the gas blows up")
    _check(mine.cell(7, y) == Mine.Cell.AIR, "the explosion breaks the rock")
    _check(mine.cell(6, y + 2) == Mine.Cell.AIR, "the explosion reaches two blocks down")
    _check(mine.cell(8, y) == Mine.Cell.AIR, "the explosion sets off the next gas pocket")
    _check(mine.gems == 1, "the gem in a blown up block is collected")
    _check(dwarf.stun == 0.0, "a dwarf far away is not dizzy")


func _check_springs() -> void:
    var level := _plain({"springs": [{"at": 0.5, "side": "left", "rate": 2.0}], "flood": 6.0})
    var mine := Mine.new(level, 1)
    var spring: int = mine.springs[0]
    var y: int = spring / Mine.WIDTH
    _wait(mine, 3.0)
    _check(mine.water_total == 0.0, "a closed spring pours no water")
    for yy in range(y - 1, y + 3):
        for x in range(1, 4):
            mine.cells[mine.index(x, yy)] = Mine.Cell.AIR
    _wait(mine, 1.0)
    _check(mine.water_total > 0.5, "an open spring pours water")
    _check(mine.water_at(2, y + 2) > 0.0, "the water flows down and sideways")
    _wait(mine, 10.0)
    _check(mine.state == Mine.State.FLOODED, "the mine floods")

    mine = Mine.new(level, 1)
    for yy in range(y - 1, y + 3):
        for x in range(1, 4):
            mine.cells[mine.index(x, yy)] = Mine.Cell.AIR
    var dwarf: Mine.Dwarf = mine.dwarves[0]
    dwarf.pos = Vector2(1.5, y + 2)
    _wait(mine, 0.3)
    dwarf.pos = Vector2(1.5, y + 1)
    mine.cells[mine.index(1, y + 1)] = Mine.Cell.ROCK
    dwarf.vel = Vector2.ZERO
    mine.set_target(0, 1.5)
    _wait(mine, 0.3)
    for k in range(3):
        mine.jump(0)
        _wait(mine, 0.6)
    _check(mine.cells[spring] == Mine.Cell.SEALED, "three jumps beside the spring hammer it shut")
    var water := mine.water_total
    _wait(mine, 2.0)
    _check(mine.water_total <= water + 0.001, "a sealed spring pours no more water")


func _check_fire() -> void:
    var mine := Mine.new(_plain({"dragons": [1.0, 1.0], "dragons_from": 0.0}), 1)
    var dwarf: Mine.Dwarf = mine.dwarves[0]
    var stunned := false
    for k in range(int(6.0 / DT)):
        mine.step(DT)
        stunned = stunned or dwarf.stun > 0.0
    _check(stunned, "the fire of the dragon makes a dwarf who stands still dizzy")
    mine = Mine.new(_plain({"dragons": [1.0, 1.0], "dragons_from": 0.0}), 1)
    dwarf = mine.dwarves[0]
    mine.active["helmet"] = 100.0
    var shielded := false
    for k in range(int(6.0 / DT)):
        mine.step(DT)
        shielded = shielded or dwarf.stun > 0.0
    _check(not shielded, "the fire helmet keeps the dwarf from getting dizzy")

    mine = Mine.new(_plain({"dragons": [1.0, 1.0], "dragons_from": 0.0}), 1, {"helmet": 1})
    dwarf = mine.dwarves[0]
    shielded = false
    for k in range(int(6.0 / DT)):
        mine.step(DT)
        shielded = shielded or dwarf.stun > 0.0
    _check(not shielded, "a fire helmet from the shop starts when the fire comes")
    _check(int(mine.charges["helmet"]) == 0, "the fire helmet from the shop is used up")


func _check_boosters() -> void:
    var mine := Mine.new(_plain(), 1, {"gold_pick": 1, "pump": 1})
    _stand(mine, 5, Mine.SKY_ROWS + 2)
    mine.jump(0)
    _wait(mine, 0.6)
    _check(not MineBoosters.has(mine, "gold_pick"), "the golden pickaxe waits for the rock")
    var y := Mine.SKY_ROWS + 3
    mine.cells[mine.index(5, y)] = Mine.Cell.ROCK
    mine.hits_left[mine.index(5, y)] = 4
    _stand(mine, 5, y)
    mine.jump(0)
    _wait(mine, 0.6)
    _check(MineBoosters.has(mine, "gold_pick"), "the golden pickaxe starts on the rock")
    _check(mine.hits_left[mine.index(5, y)] == 2, "the golden pickaxe hits twice")

    mine.water_total = 0.0
    for k in range(mine.water.size()):
        mine.water[k] = 0.0
    var flood := float(mine.level["flood"]) * Mine.AREA_SCALE
    mine.water[mine.index(5, mine.height - 2)] = 0.0
    mine.water_total = flood * (Mine.PUMP_AT + 0.05)
    mine.step(DT)
    _check(mine.flood_level() < Mine.PUMP_AT, "the pump from the shop starts when the water rises")
    _check(int(mine.charges["pump"]) == 0, "the pump is used up")


func _check_moles() -> void:
    var mine := Mine.new(_plain({"depth": 30, "moles": [1.0, 1.0]}), 1)
    _stand(mine, 5, Mine.SKY_ROWS + 4)
    var dug := false
    var came := false
    for k in range(int(4.0 / DT)):
        mine.step(DT)
        for event in mine.take_events():
            came = came or event["type"] == "mole"
            dug = dug or event["type"] == "mole_dig"
    _check(came and dug, "a mole comes and digs a tunnel")
    _check(mine.gems == 0, "the mole takes no gems")

    mine = Mine.new(_plain({"depth": 30, "moles": [1.0, 1.0]}), 1)
    var dwarf := _stand(mine, 5, Mine.SKY_ROWS + 4)
    _wait(mine, 1.2)
    _check(mine.moles.all.size() == 1, "a mole is out")
    if mine.moles.all.is_empty():
        return
    var mole: MineMoles.Mole = mine.moles.all[0]
    # NOTE (mristin):
    # Put the dwarf beside the mole, and swing at it.
    var cell := Vector2i(int(floor(mole.pos.x)), int(floor(mole.pos.y)))
    var side := 1 if cell.x < Mine.WIDTH / 2 else -1
    var stand := cell - Vector2i(side, 0)
    mine.cells[mine.index(stand.x, stand.y)] = Mine.Cell.AIR
    mine.cells[mine.index(stand.x, stand.y + 1)] = Mine.Cell.DIRT
    dwarf.pos = Vector2(stand.x + 0.5, stand.y + 1)
    dwarf.vel = Vector2.ZERO
    dwarf.target_x = dwarf.pos.x
    mine.step(DT)
    mine.take_events()
    mine.swing_side(0, side)
    _check(mole.phase == "cry", "a mole hit by the pickaxe cries")
    _wait(mine, MineMoles.CRY + 4.0)
    _check(not mole in mine.moles.all, "the crying mole runs away")


func _check_rival() -> void:
    var level := _plain({"rival": true})
    var mine := Mine.new(level, 1)
    var rival_bot := MineBot.new(mine, Mine.RIVAL)
    _wait(mine, MineRival.ARRIVES + 0.5)
    _check(mine.rival != null, "the evil miner arrives")
    var t := 0.0
    while mine.state == Mine.State.PLAYING and t < 600.0:
        rival_bot.act(DT)
        mine.step(DT)
        t += DT
    _check(mine.state == Mine.State.LOST, "the evil miner takes the treasure when the players stop")
    _check(mine.stars() == 0, "no stars when the evil miner was faster")

    mine = Mine.new(level, 1)
    _wait(mine, MineRival.ARRIVES + 0.5)
    var dwarf := _stand(mine, 5, Mine.SKY_ROWS)
    mine.rival.pos = Vector2(6.5, Mine.SKY_ROWS)
    mine.rival.vel = Vector2.ZERO
    mine.rival.target_x = 6.5
    mine.swing_side(0, 1)
    _check(mine.rival.stars > 0.0, "the evil miner sees stars when a dwarf hits him")
    _check(mine.rival.stun > 0.0, "the evil miner lies knocked out")

    mine = Mine.new(level, 1)
    _wait(mine, MineRival.ARRIVES + 0.5)
    dwarf = _stand(mine, 5, Mine.SKY_ROWS)
    # NOTE (mristin):
    # As if the players stopped digging, so that he does not only wait.
    mine.rivalry._stopped = true
    mine.rivalry._clock = -10.0
    mine.rival.pos = Vector2(5.9, Mine.SKY_ROWS)
    mine.rival.vel = Vector2.ZERO
    mine.rival.target_x = 5.9
    _wait(mine, 0.2)
    _check(dwarf.stars > 0.0 and dwarf.stun > 0.0, "the evil miner knocks out a dwarf beside him")


func _check_treasure() -> void:
    var mine := Mine.new(_plain(), 1)
    var dwarf: Mine.Dwarf = mine.dwarves[0]
    dwarf.pos = Vector2(mine.chest.x + 0.5, mine.chest.y + 1.0)
    mine.step(DT)
    _check(mine.state == Mine.State.WON, "the treasure ends the level")
    _check(mine.stars() >= 1, "finding the treasure gives a star at least")


## Put the dwarf of the slot standing on the cell (x, y), and let it settle.
func _put(mine: Mine, slot: int, x: int, y: int) -> void:
    var dwarf := mine.dwarf_of(slot)
    if dwarf == null:
        dwarf = mine.add_dwarf(slot)
    dwarf.pos = Vector2(x + 0.5, y)
    dwarf.vel = Vector2.ZERO
    dwarf.target_x = dwarf.pos.x


func _check_puzzles() -> void:
    var twin_level := _plain({"puzzles": [{"kind": "twin", "at": 0.5}]})

    # NOTE (mristin):
    # Alone, one plate opens the twin gate.
    var mine := Mine.new(twin_level, 1)
    var puzzle: MinePuzzles.Puzzle = mine.puzzles.puzzles[0]
    _check(puzzle.plates.size() == 2, "a twin gate has two plates")
    _check(mine.cell(puzzle.gate[0].x, puzzle.row) == Mine.Cell.GATE, "the gate is closed at first")
    _put(mine, 0, puzzle.plates[0].x, puzzle.row)
    _wait(mine, 0.3)
    _check(puzzle.open, "alone, one plate opens the twin gate")

    # NOTE (mristin):
    # Two dwarves need both plates; once open, the gate stays open.
    mine = Mine.new(twin_level, 2)
    puzzle = mine.puzzles.puzzles[0]
    _put(mine, 0, puzzle.plates[0].x, puzzle.row)
    _put(mine, 1, 12, puzzle.row - 3)
    _wait(mine, 0.3)
    _check(puzzle.needed == 2, "with two dwarves, the twin gate needs two plates")
    _check(not puzzle.open, "with two dwarves, one plate does not open the twin gate")
    _put(mine, 1, puzzle.plates[1].x, puzzle.row)
    _wait(mine, 0.3)
    _check(puzzle.open, "two dwarves on the two plates open the twin gate")
    _put(mine, 0, 12, puzzle.row - 3)
    _put(mine, 1, 13, puzzle.row - 3)
    _wait(mine, 0.3)
    _check(puzzle.open, "the twin gate stays open")

    # NOTE (mristin):
    # A friend who leaves makes the gate ask for fewer plates, on the fly.
    mine = Mine.new(twin_level, 2)
    puzzle = mine.puzzles.puzzles[0]
    _put(mine, 0, puzzle.plates[0].x, puzzle.row)
    _put(mine, 1, 12, puzzle.row - 3)
    _wait(mine, 0.3)
    _check(not puzzle.open, "the gate waits for the second dwarf")
    mine.remove_dwarf(1)
    _wait(mine, 0.3)
    _check(puzzle.open, "when the friend leaves, the dwarf alone opens the gate")

    var timer_level := _plain({"puzzles": [{"kind": "timer", "at": 0.5}]})
    mine = Mine.new(timer_level, 1)
    puzzle = mine.puzzles.puzzles[0]
    _put(mine, 0, puzzle.plates[0].x, puzzle.row)
    _wait(mine, 0.3)
    _check(puzzle.open, "the plate opens the timer gate")
    var side := 1 if puzzle.plates[0].x < Mine.WIDTH / 2 else -1
    _put(mine, 0, puzzle.plates[0].x + side, puzzle.row)
    _wait(mine, MinePuzzles.TIMER - 1.0)
    _check(puzzle.open, "the timer gate stays open for a while")
    _wait(mine, 1.5)
    _check(not puzzle.open, "the timer gate closes again")
    mine.dwarf_of(0).pos = Vector2(puzzle.plates[0].x + 0.5, puzzle.row)
    _wait(mine, 0.3)
    mine.set_target(0, puzzle.gate[puzzle.gate.size() / 2].x + 0.5)
    _wait(mine, 4.0)
    _check(
        mine.dwarf_of(0).pos.y > puzzle.row + 0.5, "the dwarf runs off the plate and drops through"
    )


func _check_generation() -> void:
    for level in LevelCatalog.LEVELS:
        for players in [1, 4]:
            var mine := Mine.new(level, players)
            var again := Mine.new(level, players)
            _check(mine.cells == again.cells, "%s is the same every time" % level["id"])
            _check(mine.gems_total >= int(level["gems"]) * 0.8, "%s has its gems" % level["id"])
            _check(
                mine.springs.size() == level["springs"].size(), "%s has its springs" % level["id"]
            )
            for dwarf in mine.dwarves:
                _check(
                    not mine.is_solid(int(dwarf.pos.x), int(dwarf.pos.y) - 1),
                    "%s: the dwarves start in the open" % level["id"]
                )


func _run() -> void:
    _check_hits()
    _check_weak_hits()
    _check_side()
    _check_side_swing()
    _check_explosion()
    _check_springs()
    _check_fire()
    _check_treasure()
    _check_boosters()
    _check_moles()
    _check_rival()
    _check_puzzles()
    _check_generation()
    print("RESULT: ", "OK" if _failures.is_empty() else "FAILED")
    quit(0 if _failures.is_empty() else 1)
