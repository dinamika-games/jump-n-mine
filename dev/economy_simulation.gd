extends SceneTree
## Simulate the purse of an expedition through the fifteen levels, to check the
## prices of [Economy]: the players must not be able to buy everything after the
## first few levels.
##
## Bots play every level (one dwarf, jumping every 1.6 s, and the evil miner)
## to see how many gems a level gives; children who look for the gems find
## more, so we also try "keen" players (twice the bots' gems) and "perfect"
## players (all the gems). Each kind of player spends greedily after each level:
## "house" builds the cheapest stage it can, "boosters" first buys one of each
## booster and uses them all up in the next level.
##
##     $GODOT --headless --audio-driver Dummy --path . --script dev/economy_simulation.gd

const DT := 1.0 / 30.0


func _initialize() -> void:
    _run.call_deferred()


func _bot_gems(level: Dictionary) -> Array[int]:
    var mine := Mine.new(level, 1)
    var bots: Array[MineBot] = [MineBot.new(mine, 0), MineBot.new(mine, Mine.RIVAL)]
    while mine.state == Mine.State.PLAYING and mine.time < 40.0 * 60.0:
        for bot in bots:
            bot.act(DT)
        mine.step(DT)
        mine.take_events()
    return [mine.gems, mine.gems_total]


func _run() -> void:
    var found: Array[Array] = []
    for level in LevelCatalog.LEVELS:
        found.append(_bot_gems(level))
    print("Gems per level (bot / all): ", found)
    print("The whole house: %d gems for %d improvements" % [Economy.house_total(), Economy.house_count()])

    for player in ["bot", "keen", "perfect"]:
        for strategy in ["house", "boosters"]:
            var purse := 0
            var built := {}
            var line := "%-8s %-9s" % [player, strategy]
            for i in range(found.size()):
                var gems: int = found[i][0]
                if player == "keen":
                    gems = mini(found[i][1], gems * 2)
                elif player == "perfect":
                    gems = found[i][1]
                purse += gems
                if strategy == "boosters":
                    for kind in Mine.BOOSTERS:
                        if purse >= int(Economy.BOOSTER_PRICES[kind]):
                            purse -= int(Economy.BOOSTER_PRICES[kind])
                purse = Economy.build_greedily(purse, built)
                if i + 1 in [1, 3, 5, 10, 15]:
                    var count := 0
                    for part in built:
                        count += int(built[part])
                    line += "  L%d: %d built, %d left" % [i + 1, count, purse]
            print(line)
    quit()

