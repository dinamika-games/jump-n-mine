extends Node

## The expeditions (the sessions of the game): an expedition is one playthrough
## with its name and the stars of each level. The players come and go at will,
## so an expedition does not keep who plays.
##
## Every expedition is JSON in [code]user://saves/<id>.json[/code], with a format
## version, so that later versions can convert old saves. A save is written to a
## temporary file first and then renamed, so that a crash never destroys the
## last good save. [code]user://settings.cfg[/code] keeps the last expedition.
##
## Start the game with [code]-- --settings=user://other.cfg[/code] to keep the
## settings in another file and the expeditions in
## [code]user://other_saves/[/code] (the tests do so, to leave yours alone).

## The version of the format of the saves.
const FORMAT := 1

## The longest name of an expedition.
const MAX_SESSION_NAME := 24

var session_id := ""
var session_name := ""
var created := ""

## The stars of the finished levels, by the id of the level.
var stars := {}

## Whether the players saw how to play.
var has_seen_instruction := false

## Whether the players chose the expedition since the game started: Play asks
## once each start.
var chosen_this_run := false

## The settings which the tests chose, see [method use_settings].
var _settings_override := ""


func _ready() -> void:
    var last := last_id()
    if last != "":
        choose_session(last)
        chosen_this_run = false


## The name of a new expedition before the players change it: the date and the
## time.
static func default_session_name() -> String:
    var now := Time.get_datetime_dict_from_system()
    return (
        "%04d-%02d-%02d %02d:%02d"
        % [now["year"], now["month"], now["day"], now["hour"], now["minute"]]
    )


## Keep the settings in the file and the expeditions next to it, and forget the
## current expedition (the tests do so, to leave the players' saves alone).
func use_settings(path: String) -> void:
    _settings_override = path
    session_id = ""
    session_name = ""
    created = ""
    chosen_this_run = false
    _from_data({})


## The file of the settings, by default [code]user://settings.cfg[/code].
func settings_path() -> String:
    if _settings_override != "":
        return _settings_override
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--settings="):
            return arg.trim_prefix("--settings=")
    return "user://settings.cfg"


## The directory of the saves: "saves" next to the settings, or, for other
## settings, "<their name>_saves".
func saves_dir() -> String:
    var settings := settings_path()
    if settings.get_file() == "settings.cfg":
        return settings.get_base_dir().path_join("saves")
    return settings.get_basename() + "_saves"


## Start a new expedition with the name, and save it.
func start_session(new_name: String) -> void:
    _new_session(new_name)
    _from_data({})
    chosen_this_run = true
    _save()


## Give the current data a new expedition: its id, its name and when it was
## created.
func _new_session(new_name: String) -> void:
    var now := Time.get_datetime_dict_from_system()
    var id := (
        "%04d%02d%02d-%02d%02d%02d"
        % [now["year"], now["month"], now["day"], now["hour"], now["minute"], now["second"]]
    )
    # NOTE (mristin):
    # Two expeditions started within a second get different ids.
    var suffix := 1
    session_id = id
    while FileAccess.file_exists(_session_path(session_id)):
        suffix += 1
        session_id = "%s-%d" % [id, suffix]
    session_name = new_name.strip_edges().left(MAX_SESSION_NAME)
    if session_name == "":
        session_name = default_session_name()
    created = Time.get_datetime_string_from_system()


## Go on with the expedition of the id; return whether it was found.
func choose_session(id: String) -> bool:
    var data: Variant = read(id)
    if data == null:
        return false
    session_id = id
    session_name = data.get("name", id)
    created = data.get("created", "")
    _from_data(data)
    chosen_this_run = true
    _remember_last()
    return true


## Delete the saved expedition of the id for good; return whether it was there.
## Deleting the current expedition leaves none chosen.
func delete_session(id: String) -> bool:
    var path := _session_path(id)
    if id == "" or not FileAccess.file_exists(path):
        return false
    DirAccess.remove_absolute(path)
    var settings := ConfigFile.new()
    settings.load(settings_path())
    if settings.get_value("general", "last_session", "") == id:
        settings.set_value("general", "last_session", "")
        settings.save(settings_path())
    if id == session_id:
        session_id = ""
        session_name = ""
        created = ""
        chosen_this_run = false
        _from_data({})
    return true


## The saved expeditions, the most recently played first, each with "id",
## "name", "updated" and "stars" (in all the levels).
func sessions() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not DirAccess.dir_exists_absolute(saves_dir()):
        return result
    for file in DirAccess.get_files_at(saves_dir()):
        if not file.ends_with(".json"):
            continue
        var id := file.get_basename()
        var data: Variant = read(id)
        if data == null:
            continue
        var total := 0
        for level in data.get("progress", {}).get("stars", {}).values():
            total += int(level)
        (
            result
            . append(
                {
                    "id": id,
                    "name": data.get("name", id),
                    "updated": data.get("updated", ""),
                    "stars": total,
                }
            )
        )
    result.sort_custom(
        func(a: Dictionary, b: Dictionary) -> bool:
            return (
                a["updated"] > b["updated"] or (a["updated"] == b["updated"] and a["id"] > b["id"])
            )
    )
    return result


## The id of the expedition played last, if its save still exists, else "".
func last_id() -> String:
    var settings := ConfigFile.new()
    settings.load(settings_path())
    var id: String = settings.get_value("general", "last_session", "")
    if id == "" or read(id) == null:
        return ""
    return id


## Read the save of an expedition; null if it is missing, broken or newer.
func read(id: String) -> Variant:
    var path := _session_path(id)
    if id == "" or not FileAccess.file_exists(path):
        return null
    # NOTE (mristin):
    # We parse with an instance, which does not report a broken save as an
    # error; we skip it quietly.
    var json := JSON.new()
    if json.parse(FileAccess.get_file_as_string(path)) != OK:
        return null
    var data: Variant = json.data
    if not data is Dictionary or int(data.get("format", 0)) > FORMAT:
        return null
    return data


## The expedition as plain data, for its save.
func to_data() -> Dictionary:
    return {
        "format": FORMAT,
        "id": session_id,
        "name": session_name,
        "created": created,
        "updated": Time.get_datetime_string_from_system(),
        "progress":
        {
            "stars": stars,
            "instruction_seen": has_seen_instruction,
        },
    }


func _from_data(data: Dictionary) -> void:
    var progress: Dictionary = data.get("progress", {})
    stars = {}
    var saved_stars: Dictionary = progress.get("stars", {})
    for level in saved_stars:
        stars[level] = int(saved_stars[level])
    has_seen_instruction = bool(progress.get("instruction_seen", false))


## Whether the level (by its index in [constant LevelCatalog.LEVELS]) is open:
## the first is, and each next once the one before it was finished.
func is_unlocked(level_index: int) -> bool:
    if level_index <= 0:
        return true
    if "--all-levels" in OS.get_cmdline_user_args():
        return true
    return stars.has(LevelCatalog.LEVELS[level_index - 1]["id"])


## The stars of the level, 0 if not finished.
func stars_of(level_id: String) -> int:
    return int(stars.get(level_id, 0))


## All the stars of the expedition.
func total_stars() -> int:
    var total := 0
    for each in stars.values():
        total += int(each)
    return total


## Remember that the dwarves finished the level with the stars (keeping the
## best), and save.
func finish_level(level_id: String, won: int) -> void:
    stars[level_id] = maxi(int(stars.get(level_id, 0)), won)
    _save()


## Remember that the players saw how to play, and save.
func saw_instruction() -> void:
    has_seen_instruction = true
    if session_id != "":
        _save()


## The first level which is open and not yet finished, or the last level.
func next_level_index() -> int:
    for i in range(LevelCatalog.LEVELS.size()):
        if is_unlocked(i) and not stars.has(LevelCatalog.LEVELS[i]["id"]):
            return i
    return LevelCatalog.LEVELS.size() - 1


## Save the current expedition; without one (e.g., in the tests), start one.
func _save() -> void:
    if session_id == "":
        _new_session(default_session_name())
    DirAccess.make_dir_recursive_absolute(saves_dir())
    var path := _session_path(session_id)
    var temporary := path + ".tmp"
    var file := FileAccess.open(temporary, FileAccess.WRITE)
    if file == null:
        push_error(
            "Could not save the expedition to %s: %s" % [temporary, FileAccess.get_open_error()]
        )
        return
    file.store_string(JSON.stringify(to_data(), "  "))
    file.close()
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)
    DirAccess.rename_absolute(temporary, path)
    _remember_last()


func _remember_last() -> void:
    var settings := ConfigFile.new()
    settings.load(settings_path())
    settings.set_value("general", "last_session", session_id)
    DirAccess.make_dir_recursive_absolute(settings_path().get_base_dir())
    settings.save(settings_path())


func _session_path(id: String) -> String:
    return saves_dir().path_join("%s.json" % id)
