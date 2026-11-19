extends SceneTree
## Let bots play every level, one jump every 1.6 s each, and check that the
## level can be finished (the puzzles, too), that one dwarf takes about 15
## minutes (between 11 and 20), and that more dwarves, who cooperate on the
## twin gates, are not slower.
##
## The tests test_levels_world_<n>.gd play the levels of one world each, so
## that they run in parallel; run this script itself to play all of them.
## Pass "-- --only=<id part>" to play only some levels, and "-- --players=2" to
## play with more dwarves.

const DT := 1.0 / 30.0
const MAX_TIME := 40.0 * 60.0

## The world to play, -1 for all.
var world := -1

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


## Play the level with bots; return the mine at the end.
static func play(level: Dictionary, players: int) -> Mine:
    var mine := Mine.new(level, players)
    var bots: Array[MineBot] = []
    for i in range(players):
        bots.append(MineBot.new(mine, i))
    while mine.state == Mine.State.PLAYING and mine.time < MAX_TIME:
        for bot in bots:
            bot.act(DT)
        mine.step(DT)
        mine.take_events()
    return mine


func _run() -> void:
    var only := ""
    var player_counts: Array[int] = [1, 3]
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--only="):
            only = arg.trim_prefix("--only=")
        elif arg.begins_with("--players="):
            player_counts = [int(arg.trim_prefix("--players="))]

    for level in LevelCatalog.LEVELS:
        if only != "" and not str(level["id"]).contains(only):
            continue
        if world >= 0 and int(level["world"]) != world:
            continue
        var minutes := {}
        for players in player_counts:
            var started := Time.get_ticks_msec()
            var mine := play(level, players)
            var hits := 0
            for dwarf in mine.dwarves:
                hits += dwarf.hits
            minutes[players] = mine.time / 60.0
            print(
                (
                    (
                        "%s, %d dwarves: %s after %.1f min, %d/%d gems, %d stars, %d hits, "
                        + "flood %.0f %%, deepest %.0f %% (%.1f s)"
                    )
                    % [
                        level["id"],
                        players,
                        Mine.State.keys()[mine.state],
                        mine.time / 60.0,
                        mine.gems,
                        mine.gems_total,
                        mine.stars(),
                        hits,
                        mine.flood_level() * 100.0,
                        mine.progress() * 100.0,
                        (Time.get_ticks_msec() - started) / 1000.0,
                    ]
                )
            )
            _check(
                mine.state == Mine.State.WON,
                "%s: %d dwarves find the treasure" % [level["id"], players]
            )
        if minutes.has(1):
            _check(
                minutes[1] >= 11.0 and minutes[1] <= 20.0,
                "%s: one dwarf takes about 15 minutes, got %.1f" % [level["id"], minutes[1]]
            )
            for players in minutes:
                _check(
                    minutes[players] <= minutes[1] * 1.1,
                    (
                        "%s: %d dwarves are not slower than one, got %.1f min"
                        % [level["id"], players, minutes[players]]
                    )
                )

    print("RESULT: ", "OK" if _failures.is_empty() else "FAILED")
    quit(0 if _failures.is_empty() else 1)
