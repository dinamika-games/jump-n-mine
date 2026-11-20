class_name MineWater
extends RefCounted

## The water of the [Mine]: the open springs pour it in, it falls and spreads
## through the open cells, and it seeps away slowly in some levels.


static func flow(mine: Mine, dt: float) -> void:
    for i in mine.springs:
        if mine.cells[i] != Mine.Cell.SPRING:
            continue
        var sx := i % Mine.WIDTH
        var sy := i / Mine.WIDTH
        var inner := 1 if sx == 0 else Mine.WIDTH - 2
        var j := mine.index(inner, sy)
        if mine.cells[j] != Mine.Cell.AIR:
            continue
        var rate := 0.12
        for spring in mine.level.get("springs", []):
            if (spring["side"] == "left") == (sx == 0):
                rate = float(spring["rate"]) * Mine.AREA_SCALE
        var added := minf(rate * dt, 1.0 - mine.water[j])
        if added > 0.0:
            mine.water[j] += added
            mine.water_total += added

    if mine.water_total <= 0.0001:
        mine.water_total = 0.0
        return

    # NOTE (mristin):
    # The water seeps away slowly through the cracks of the mine.
    var drain := float(mine.level.get("drain", 0.0)) * Mine.AREA_SCALE * dt
    if drain > 0.0 and mine.water_total > 0.0:
        var keep := maxf(0.0, (mine.water_total - drain) / mine.water_total)
        for k in range(mine.water.size()):
            if mine.water[k] > 0.0:
                mine.water[k] *= keep
        mine.water_total *= keep

    # NOTE (mristin):
    # From the bottom up: the water falls into the cell below as far as it
    # fits, and then evens out with its neighbors on the sides. We alternate
    # the direction of the rows, so that the water does not lean to one side.
    var total := 0.0
    var step_x := 1 if mine.water_left_to_right else -1
    mine.water_left_to_right = not mine.water_left_to_right
    for y in range(mine.height - 2, -1, -1):
        var x := 1 if step_x > 0 else Mine.WIDTH - 2
        for n in range(Mine.WIDTH - 2):
            var i := mine.index(x, y)
            var w := mine.water[i]
            if w > 0.0:
                if mine.cells[i] != Mine.Cell.AIR:
                    mine.water[i] = 0.0
                    w = 0.0
                else:
                    var below := i + Mine.WIDTH
                    if mine.cells[below] == Mine.Cell.AIR and mine.water[below] < 1.0:
                        var moved := minf(w, 1.0 - mine.water[below])
                        mine.water[below] += moved
                        w -= moved
                    if w > 0.001:
                        var left := i - 1
                        var right := i + 1
                        var open_left := mine.cells[left] == Mine.Cell.AIR and mine.water[left] < w
                        var open_right := (
                            mine.cells[right] == Mine.Cell.AIR and mine.water[right] < w
                        )
                        if open_left and open_right:
                            var avg := (w + mine.water[left] + mine.water[right]) / 3.0
                            mine.water[left] = avg
                            mine.water[right] = avg
                            w = avg
                        elif open_left:
                            var avg := (w + mine.water[left]) / 2.0
                            mine.water[left] = avg
                            w = avg
                        elif open_right:
                            var avg := (w + mine.water[right]) / 2.0
                            mine.water[right] = avg
                            w = avg
                    if w < 0.002:
                        w = 0.0
                    mine.water[i] = w
            x += step_x
    for k in range(mine.water.size()):
        total += mine.water[k]
    mine.water_total = total
