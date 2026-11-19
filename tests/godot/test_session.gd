extends SceneTree
## Check the expeditions: starting, saving, listing, choosing and deleting
## them, the stars and which levels are open.

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

    var broken := FileAccess.open(saves.path_join("broken.json"), FileAccess.WRITE)
    broken.store_string("{not json")
    broken.close()
    _check(session.sessions().size() == 1, "a broken save is skipped")

    print("RESULT: ", "OK" if _failures.is_empty() else "FAILED")
    quit(0 if _failures.is_empty() else 1)
