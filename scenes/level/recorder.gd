class_name Recorder
extends RefCounted

## Record how the players move and what their dwarves do in a level, so that we
## can tune the steering and the jumps (start the game with
## [code]-- --record[/code]).
##
## The recording is a CSV file in [code]user://recordings/[/code], one line per
## record: the time in seconds since the level started, the kind, and its
## fields:
## [br]- [code]head[/code]: the head id, x and y (fractions of the camera
##   picture), its size, its rise and whether it is jumping,
## [br]- [code]jump[/code]: the head id and the strength,
## [br]- [code]swing[/code]: the head id and the side (-1 or 1),
## [br]- [code]arms[/code]: the head id, the left wrist across the body and above
##   its shoulder, and the right one, in head sizes (nan where unknown, see
##   SwingGauge.cs),
## [br]- [code]dwarf[/code]: the slot, its head id (or -1), x, y and target x (in
##   cells) and whether it stands on the ground, once per physics frame,
## [br]- [code]event[/code]: the type of the mine event, x and y (in cells) and
##   the slot of the dwarf (or -1).
##
## Only these numbers are recorded, never the camera pictures.

const HEADER := "t,kind,id,a,b,c,d,e"

var path := ""

var _file: FileAccess
var _start_msec := 0


func _init(level_id: String) -> void:
    DirAccess.make_dir_recursive_absolute("user://recordings")
    var stamp := Time.get_datetime_string_from_system().replace(":", "-")
    path = "user://recordings/%s_%s.csv" % [stamp, level_id]
    _file = FileAccess.open(path, FileAccess.WRITE)
    if _file == null:
        push_error("Could not record to %s: %s" % [path, FileAccess.get_open_error()])
        return
    _file.store_line(HEADER)
    _start_msec = Time.get_ticks_msec()
    print("Recording to %s." % ProjectSettings.globalize_path(path))


func head(id: int, info: Dictionary) -> void:
    var position: Vector2 = info["position"]
    _line(
        "head",
        id,
        [position.x, position.y, info["size"], info["rise"], 1 if info["jumping"] else 0]
    )


func jump(id: int, strength: float) -> void:
    _line("jump", id, [strength])


func swing(id: int, side: int) -> void:
    _line("swing", id, [side])


func arms(id: int, a: Vector4) -> void:
    _line("arms", id, [a.x, a.y, a.z, a.w])


func dwarf(slot: int, head_id: int, d: Mine.Dwarf) -> void:
    _line("dwarf", slot, [head_id, d.pos.x, d.pos.y, d.target_x, 1 if d.on_ground else 0])


func event(e: Dictionary) -> void:
    var pos: Vector2 = e.get("pos", Vector2(NAN, NAN))
    _line("event", int(e.get("dwarf", -1)), [e["type"], pos.x, pos.y])


func close() -> void:
    if _file != null:
        _file.close()
        _file = null


func _line(kind: String, id: int, fields: Array) -> void:
    if _file == null:
        return
    var t := (Time.get_ticks_msec() - _start_msec) / 1000.0
    var parts := PackedStringArray(["%.3f" % t, kind, str(id)])
    for field in fields:
        parts.append(("%.4f" % field) if field is float else str(field))
    _file.store_line(",".join(parts))
