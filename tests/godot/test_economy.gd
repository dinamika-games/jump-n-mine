extends SceneTree
## Check the prices of the shop and the house (see [Economy]): even players who
## gather every gem of the first levels build only a little of the house and
## cannot fill their pack with boosters, and a whole perfect expedition does not
## pay for half of the house (dev/economy_simulation.gd simulates the purse with
## bots, too).

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    _check(Economy.house_count() == 50, "the house has fifty improvements")
    var all_gems: Array[int] = []
    for level in LevelCatalog.LEVELS:
        all_gems.append(Mine.new(level, 0).gems_total)

    var purse := 0
    var built := {}
    for i in range(3):
        purse = Economy.build_greedily(purse + all_gems[i], built)
    var count := 0
    for part in built:
        count += int(built[part])
    _check(
        count >= 5 and count <= 12,
        "with all the gems of three levels, 5 to 12 improvements are built, got %d" % count
    )

    var full_pack := 0
    for kind in Mine.BOOSTERS:
        full_pack += int(Economy.BOOSTER_PRICES[kind]) * Economy.MAX_CARRY
    _check(
        full_pack > all_gems[0] + all_gems[1],
        "the gems of two levels do not fill the pack with boosters"
    )
    var one_of_each := 0
    for kind in Mine.BOOSTERS:
        one_of_each += int(Economy.BOOSTER_PRICES[kind])
    var most := 0
    for gems in all_gems:
        most = maxi(most, gems)
    _check(one_of_each > most, "no level pays for one booster of each kind")

    var total := 0
    for gems in all_gems:
        total += gems
    _check(
        total * 2 < Economy.house_total(),
        (
            "a perfect expedition (%d gems) pays for less than half of the house (%d)"
            % [total, Economy.house_total()]
        )
    )

    for part in range(Economy.HOUSE_PARTS.size()):
        _check(
            Economy.HOUSE_PARTS[part]["stages"].size() == Economy.STAGE_PRICES.size(),
            "every part of the house has five stages"
        )
        for stage in range(1, Economy.STAGE_PRICES.size()):
            _check(
                Economy.house_price(part, stage) > Economy.house_price(part, stage - 1),
                "every stage costs more than the one before"
            )

    print("RESULT: ", "OK" if _failures.is_empty() else "FAILED")
    quit(0 if _failures.is_empty() else 1)
