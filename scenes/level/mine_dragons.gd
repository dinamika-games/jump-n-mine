class_name MineDragons
extends RefCounted

## The dragons of the mine (see [code]dragons[/code] in [LevelCatalog]): a
## dragon flies in above the mine, circles over a dwarf for [constant
## Mine.DRAGON_WARNING] seconds, and spits; its fire falls straight down,
## stops at the first block (and cracks it), goes out in the water, sets the
## gas on fire, and makes a dwarf (or the evil miner) it hits dizzy, unless the
## fire helmet shields the dwarves.


## When the next dragon comes.
static func schedule(mine: Mine) -> void:
    var interval: Array = mine.level.get("dragons", [])
    if interval.is_empty():
        mine.next_dragon = INF
        return
    mine.next_dragon = (mine.time + mine.rng.randf_range(float(interval[0]), float(interval[1])))


## Let the dragons come, circle, spit and leave.
static func fly(mine: Mine, dt: float) -> void:
    if mine.time >= mine.next_dragon:
        schedule(mine)
        var from := float(mine.level.get("dragons_from", 0.0))
        if mine.progress() >= from and not mine.dwarves.is_empty():
            var dwarf: Mine.Dwarf = mine.dwarves[mine.rng.randi_range(0, mine.dwarves.size() - 1)]
            var dragon := Mine.Dragon.new()
            dragon.column = clampi(int(floor(dwarf.pos.x)), 1, Mine.WIDTH - 2)
            dragon.from_left = mine.rng.randf() < 0.5
            dragon.x = -2.0 if dragon.from_left else Mine.WIDTH + 2.0
            mine.dragons.append(dragon)
            mine.events.append(
                {"type": "dragon", "pos": Vector2(dragon.column + 0.5, mine.view_top)}
            )

    var leaving: Array[Mine.Dragon] = []
    for dragon in mine.dragons:
        dragon.time += dt
        var goal := dragon.column + 0.5
        if dragon.time < Mine.DRAGON_WARNING:
            dragon.x = move_toward(dragon.x, goal, 18.0 * dt)
        elif not dragon.spat:
            dragon.spat = true
            dragon.x = goal
            var fire := Mine.Fire.new()
            fire.pos = Vector2(goal, mine.view_top + 1.0)
            mine.fires.append(fire)
            mine.events.append({"type": "spit", "pos": fire.pos})
        else:
            dragon.x += (12.0 if dragon.from_left else -12.0) * dt
            if dragon.x < -4.0 or dragon.x > Mine.WIDTH + 4.0:
                leaving.append(dragon)
    for dragon in leaving:
        mine.dragons.erase(dragon)


## Let the fire fall.
static func fall(mine: Mine, dt: float) -> void:
    var gone: Array[Mine.Fire] = []
    for fire in mine.fires:
        fire.pos.y += Mine.FIRE_SPEED * dt
        var x := int(floor(fire.pos.x))
        var y := int(floor(fire.pos.y + 0.3))
        if y >= mine.height:
            gone.append(fire)
            continue
        if mine.water_at(x, y) > 0.3:
            gone.append(fire)
            mine.events.append({"type": "fizzle", "pos": fire.pos})
            continue
        if mine.fuses.has(mine.index(x, y)):
            # The fire sets the gas on fire.
            mine.ignite(mine.index(x, y))
            gone.append(fire)
            continue
        var hit_dwarf := false
        var bodies: Array[Mine.Dwarf] = mine.dwarves.duplicate()
        if mine.rival != null:
            bodies.append(mine.rival)
        for dwarf in bodies:
            if (
                absf(dwarf.pos.x - fire.pos.x) < 0.55
                and fire.pos.y > dwarf.pos.y - Mine.DWARF_HEIGHT - 0.2
                and fire.pos.y < dwarf.pos.y
            ):
                hit_dwarf = true
                var event := {"type": "shielded", "pos": dwarf.pos, "dwarf": dwarf.index}
                if not MineBoosters.shielded(mine, dwarf):
                    dwarf.stun = Mine.STUN_TIME
                    event["type"] = "singed"
                mine.events.append(event)
        if hit_dwarf:
            gone.append(fire)
            continue
        if mine.is_solid(x, y):
            gone.append(fire)
            mine.events.append({"type": "fire_hit", "pos": fire.pos})
            if mine.is_breakable(x, y):
                mine.hit_block(Vector2i(x, y), 1, null)
    for fire in gone:
        mine.fires.erase(fire)
