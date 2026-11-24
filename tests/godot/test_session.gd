extends SceneTree
## Check the expeditions: starting, saving, listing, choosing and deleting
## them, the stars and which levels are open, the purse of gems, the boosters
## and the house, and the saves of the format 1.

var _failures: Array[String] = []


func _check(condition: bool, message: String) -> void:
    if not condition:
        print("FAIL ", message)
        _failures.append(message)


func _initialize() -> void:
    _run.call_deferred()


func _run() -> void:
    var session := root.get_node("/root/Session")
    session.use_settings("user://test_session.cfg")
    var saves: String = session.saves_dir()
    if DirAccess.dir_exists_absolute(saves):
        for file in DirAccess.get_files_at(saves):
            DirAccess.remove_absolute(saves.path_join(file))

    _check(session.sessions().is_empty(), "there are no expeditions at first")
    _check(session.is_unlocked(0), "the first level is open")
    _check(not session.is_unlocked(1), "the second level is locked")

    session.start_session("Gold diggers")
    var first: String = session.session_id
    _check(FileAccess.file_exists(saves.path_join(first + ".json")), "the expedition is saved")
    _check(
        not FileAccess.file_exists(saves.path_join(first + ".json.tmp")),
        "no temporary file is left"
    )

    session.finish_level(LevelCatalog.LEVELS[0]["id"], 2)
    session.finish_level(LevelCatalog.LEVELS[0]["id"], 1)
    _check(session.stars_of(LevelCatalog.LEVELS[0]["id"]) == 2, "the best stars are kept")
    _check(session.is_unlocked(1), "finishing a level opens the next")
    _check(session.next_level_index() == 1, "the next level to play is the second")

    session.start_session("")
    _check(session.session_name != "", "an empty name becomes the date and the time")
    _check(session.total_stars() == 0, "a new expedition has no stars")

    var listed: Array[Dictionary] = session.sessions()
    _check(listed.size() == 2, "both expeditions are listed, got %d" % listed.size())

    _check(session.choose_session(first), "the first expedition can be chosen again")
    _check(session.session_name == "Gold diggers", "it keeps its name")
    _check(session.stars_of(LevelCatalog.LEVELS[0]["id"]) == 2, "it keeps its stars")
    _check(session.last_id() == first, "it is remembered as the last")

    _check(session.delete_session(first), "the expedition can be deleted")
    _check(session.session_id == "", "deleting the current expedition leaves none chosen")
    _check(session.sessions().size() == 1, "one expedition is left")
    _check(session.last_id() == "", "the deleted expedition is not the last any more")
    _check(not session.delete_session(first), "an expedition is deleted only once")

    session.start_session("Purse")
    var purse: String = session.session_id
    _check(session.purse.gems == 0, "a new expedition has no gems")
    _check(not session.purse.buy_booster("pump"), "without gems, nothing can be bought")
    session.purse.add_gems(40)
    _check(session.purse.buy_booster("pump"), "a pump can be bought with gems")
    _check(session.purse.gems == 40 - Economy.BOOSTER_PRICES["pump"], "the pump costs its price")
    session.purse.add_gems(100)
    for k in range(Economy.MAX_CARRY + 1):
        session.purse.buy_booster("boots")
    _check(
        session.purse.boosters_of("boots") == Economy.MAX_CARRY, "the players carry at most 3 boots"
    )
    session.purse.use_booster("boots")
    _check(session.purse.boosters_of("boots") == Economy.MAX_CARRY - 1, "a booster is used up")
    var before: int = session.purse.gems
    _check(session.purse.build(0), "the first stage of the walls can be built")
    _check(session.purse.stage_of(0) == 1, "the walls have their first stage")
    _check(session.purse.gems == before - Economy.house_price(0, 0), "a stage costs its price")
    _check(session.choose_session(purse), "the expedition is read back")
    _check(session.purse.gems == before - Economy.house_price(0, 0), "the purse is saved")
    _check(
        session.purse.stage_of(0) == 1 and session.purse.house_built() == 1, "the house is saved"
    )
    _check(session.purse.boosters_of("pump") == 1, "the boosters are saved")
    _check(session.purse.gems_earned == 140, "all the gems gathered are counted")

    # NOTE (mristin):
    # A save of the format 1 (before the gems) is read with an empty purse.
    var old := FileAccess.open(saves.path_join("20200101-000000.json"), FileAccess.WRITE)
    (
        old
        . store_string(
            (
                JSON
                . stringify(
                    {
                        "format": 1,
                        "id": "20200101-000000",
                        "name": "Old",
                        "progress": {"stars": {"01_first_swing": 3}, "instruction_seen": true},
                    }
                )
            )
        )
    )
    old.close()
    _check(session.choose_session("20200101-000000"), "a save of the format 1 is read")
    _check(session.stars_of("01_first_swing") == 3, "it keeps its stars")
    _check(
        session.purse.gems == 0 and session.purse.house_built() == 0,
        "it starts with an empty purse"
    )
    session.delete_session("20200101-000000")
    session.delete_session(purse)

    var broken := FileAccess.open(saves.path_join("broken.json"), FileAccess.WRITE)
    broken.store_string("{not json")
    broken.close()
    _check(session.sessions().size() == 1, "a broken save is skipped")

    print("RESULT: ", "OK" if _failures.is_empty() else "FAILED")
    quit(0 if _failures.is_empty() else 1)
