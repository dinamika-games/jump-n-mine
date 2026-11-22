class_name MineBoosters
extends RefCounted

## The boosters which the players bought in the shop and brought into the mine
## ([member Mine.charges]): each starts by itself when it helps, and then helps
## all the players' dwarves for the rest of the level ([member Mine.active]):
## the golden pickaxe on the hard rock, the fire helmet when the fire or an
## explosion would make a dwarf dizzy, the spring boots before a step of two
## blocks, and the pump when the mine is filling up ([constant Mine.PUMP_AT]),
## and whenever it fills up again. A booster bought in the shop thus lasts a
## level. The evil miner never has them.


## Whether the booster of the kind (see [constant Mine.BOOSTERS]) helps the
## players' dwarves now.
static func has(mine: Mine, kind: String) -> bool:
    return bool(mine.active.get(kind, false))


## Start a booster of the kind for the rest of the level, if the players have
## one left; return whether it started.
static func use(mine: Mine, kind: String) -> bool:
    if int(mine.charges.get(kind, 0)) <= 0:
        return false
    mine.charges[kind] = int(mine.charges[kind]) - 1
    var at := Vector2(Mine.WIDTH / 2.0, mine.view_top + 2.0)
    for dwarf in mine.dwarves:
        if dwarf.pos.y >= mine.deepest - 0.01:
            at = dwarf.pos - Vector2(0, 1.2)
    mine.events.append({"type": "booster", "pos": at, "kind": kind})
    mine.active[kind] = true
    if kind == "pump":
        pump(mine, at)
    return true


## How hard the pickaxe of the dwarf hits the target: twice with the golden
## pickaxe, which starts on the rock.
static func power(mine: Mine, dwarf: Mine.Dwarf, target: Vector2i) -> float:
    if dwarf == mine.rival:
        return 1.0
    var rock := mine.cell(target.x, target.y) == Mine.Cell.ROCK
    if not has(mine, "gold_pick") and rock:
        use(mine, "gold_pick")
    return 2.0 if has(mine, "gold_pick") else 1.0


## Whether the dwarf hops with the spring boots: they start before a step of two
## blocks, which a dwarf cannot climb otherwise.
static func boots(mine: Mine, dwarf: Mine.Dwarf) -> bool:
    if dwarf == mine.rival:
        return false
    if has(mine, "boots"):
        return true
    var dx := dwarf.target_x - dwarf.pos.x
    if absf(dx) < 0.05:
        return false
    var x := int(floor(dwarf.pos.x + signf(dx) * (Mine.DWARF_HALF_WIDTH + 0.05)))
    var here := int(floor(dwarf.pos.x))
    var row := int(floor(dwarf.pos.y - 0.5))
    if x == here or not mine.is_solid(x, row) or not mine.is_solid(x, row - 1):
        return false
    if mine.is_solid(x, row - 2) or mine.is_solid(here, row - 2):
        return false
    return use(mine, "boots")


## Whether the fire helmet keeps the dwarf from getting dizzy (it starts when
## the fire or an explosion would make a dwarf dizzy).
static func shielded(mine: Mine, dwarf: Mine.Dwarf) -> bool:
    if dwarf == mine.rival:
        return false
    return has(mine, "helmet") or use(mine, "helmet")


## The pump: 70 % of the water in the mine disappears at once.
static func pump(mine: Mine, at: Vector2) -> void:
    var removed := mine.water_total * 0.7
    for k in range(mine.water.size()):
        mine.water[k] *= 0.3
    mine.water_total -= removed
    mine.events.append({"type": "pump", "pos": at})
