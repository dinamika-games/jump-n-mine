extends Node

## Find the camera, follow the heads of the players and count their jumps (the
## autoload Vision, see [HeadVision] for the vision itself).
##
## Without a camera (or with [code]-- --no-camera[/code], and in the headless
## tests), the players play with the keyboard.

signal head_appeared(id: int, position: Vector2)
signal head_moved(id: int, position: Vector2)
signal head_lost(id: int)
signal head_jumped(id: int, strength: float)
## The player of the head swung a fist to the side: -1 to the left of the
## mirrored picture, 1 to the right.
signal head_swung(id: int, side: int)

## Where the wrists of the player are, for the recordings: the left wrist across
## the body and above its shoulder, then the right one, in head sizes (NaN where
## unknown).
signal head_arms(id: int, arms: Vector4)

## The heads are followed from this to this fraction of the camera picture, in
## the mine and in the menus: a player reaches the walls of the mine (or the
## outer cards) in the middle of the room, where she still sees the screen and
## a short step moves her dwarf, and her fists stay in the picture when she
## punches towards the wall (a fist which leaves it still counts, see
## SwingGauge.cs). In a recording, the punches reached about 30 % of the
## picture beyond the head, and those of a player at the edge of the picture
## were cut off.
const HEAD_RANGE := Vector2(0.3, 0.7)

## Give up waiting for the camera server after this many seconds.
const _CAMERA_SERVER_TIMEOUT := 7.0

## Wait this long after the first feed shows up, so that the others can follow.
const _GRACE_AFTER_FIRST_FEED := 1.0

## The format index of a feed which lists no formats, see [method _find_format].
const _ANY_FORMAT := -2

## The heads in the picture, by their id: "position" (normalized to the mirrored
## picture, [0, 1]), "size" (in the heights of the picture), "rise" (how far
## above standing, in head sizes), "jump_line" (the height which the head must
## rise above for a jump, normalized to the picture; NAN before it is known),
## "jumping" (whether the player is in a jump now), "roll" (the tilt of the head,
## in radians, clockwise in the mirrored picture) and "jumped" (the time of the
## last jump, in seconds, or -1). HeadVision smooths them all with 1€ filters.
var heads := {}

## Why there is no camera, for the players; empty while it runs or is searched.
var camera_problem := ""

## Whether we still look for the camera.
var searching := false

## A picture to show instead of the camera picture, for the screenshots (see
## dev/pictures/overlay_preview.gd).
var preview_override: Texture2D = null

@onready var service: Node = $HeadVision


func _ready() -> void:
    service.HeadAppeared.connect(_on_appeared)
    service.HeadMoved.connect(_on_moved)
    service.HeadLost.connect(_on_lost)
    service.HeadJumped.connect(_on_jumped)
    service.HeadSwung.connect(func(id: int, side: int) -> void: head_swung.emit(id, side))
    service.HeadArms.connect(func(id: int, arms: Vector4) -> void: head_arms.emit(id, arms))

    if "--no-camera" in OS.get_cmdline_user_args():
        camera_problem = "The camera is switched off. Play with the keyboard."
        return
    if DisplayServer.get_name() == "headless":
        camera_problem = "There is no camera in the headless mode."
        return
    _find_camera()


## Whether the camera runs.
func has_camera() -> bool:
    return service.IsStarted


## The camera picture, not mirrored (draw it with flip_h), or null.
func preview() -> Texture2D:
    return preview_override if preview_override != null else service.GetPreview()


## What to tell the players about the camera: empty while all is well.
func status() -> String:
    if camera_problem != "":
        return camera_problem
    if searching:
        return "Looking for the camera..."
    return service.Status


## Where the head at the position (in the mirrored picture) stands across the
## room, from 0 (left) to 1 (right; see [constant HEAD_RANGE]).
func across(position: Vector2) -> float:
    return clampf((position.x - HEAD_RANGE.x) / (HEAD_RANGE.y - HEAD_RANGE.x), 0.0, 1.0)


## The ids of the heads in the picture, from the left to the right.
func ids_from_left() -> Array[int]:
    var ids: Array[int] = []
    for id in heads:
        ids.append(int(id))
    ids.sort_custom(
        func(a: int, b: int) -> bool: return heads[a]["position"].x < heads[b]["position"].x
    )
    return ids


func _on_appeared(id: int, position: Vector2, size: float) -> void:
    heads[id] = _new_head(position, size)
    head_appeared.emit(id, position)


func _on_moved(
    id: int,
    position: Vector2,
    size: float,
    rise: float,
    jump_line: float,
    jumping: bool,
    roll: float
) -> void:
    if not heads.has(id):
        heads[id] = _new_head(position, size)
        head_appeared.emit(id, position)
    var head: Dictionary = heads[id]
    head["position"] = position
    head["size"] = size
    head["rise"] = rise
    head["jump_line"] = jump_line
    head["jumping"] = jumping
    head["roll"] = roll
    head_moved.emit(id, position)


static func _new_head(position: Vector2, size: float) -> Dictionary:
    return {
        "position": position,
        "size": size,
        "rise": 0.0,
        "jump_line": NAN,
        "jumping": false,
        "roll": 0.0,
        "jumped": -1.0,
    }


func _on_lost(id: int) -> void:
    heads.erase(id)
    head_lost.emit(id)


func _on_jumped(id: int, strength: float) -> void:
    if heads.has(id):
        heads[id]["jumped"] = Time.get_ticks_msec() / 1000.0
    head_jumped.emit(id, strength)


func _find_camera() -> void:
    searching = true
    CameraServer.monitoring_feeds = true
    var extension_problem := CameraExtension.start()

    # NOTE (mristin):
    # The camera server enumerates the feeds asynchronously, so we poll instead
    # of always waiting for the whole timeout.
    var waited := 0.0
    var first_feed_at := -1.0
    while waited < _CAMERA_SERVER_TIMEOUT:
        if CameraServer.get_feed_count() > 0:
            if first_feed_at < 0.0:
                first_feed_at = waited
            elif waited - first_feed_at >= _GRACE_AFTER_FIRST_FEED:
                break
        await get_tree().create_timer(0.25).timeout
        waited += 0.25

    searching = false
    print("The camera server reports %d feed(s)." % CameraServer.get_feed_count())

    var wanted := -1
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--camera="):
            wanted = int(arg.trim_prefix("--camera="))

    var compatible := 0
    for i in range(CameraServer.get_feed_count()):
        var feed := CameraServer.get_feed(i)
        var format_index := _find_format(feed)
        if format_index == -1:
            print(
                (
                    "Skipping the feed %s with the formats: %s"
                    % [feed.get_name(), CameraExtension.get_formats(feed)]
                )
            )
            continue
        if wanted >= 0 and compatible != wanted:
            compatible += 1
            continue
        print("Starting the camera %s (format %d)." % [feed.get_name(), format_index])
        if format_index != _ANY_FORMAT:
            CameraExtension.set_format(feed, format_index)
        feed.feed_is_active = true
        service.Start(feed)
        return

    if CameraServer.get_feed_count() == 0:
        camera_problem = "There is no camera. Play with the keyboard."
        if extension_problem != "":
            camera_problem = extension_problem + " Play with the keyboard."
    else:
        camera_problem = "No camera supports 640x480. Play with the keyboard."


## Find the 640x480 YUYV format of a feed, or return -1 if there is none.
##
## Godot lists the formats only on Linux, and the camera extension on Windows.
## On macOS, the feed lists no formats and runs at the resolution of the system;
## we return [constant _ANY_FORMAT] then.
static func _find_format(feed: CameraFeed) -> int:
    var formats := CameraExtension.get_formats(feed)
    if formats.is_empty():
        return _ANY_FORMAT

    for format_index in range(formats.size()):
        var format := formats[format_index] as Dictionary
        var width := format.get("width", 0) as int
        var height := format.get("height", 0) as int
        var pixel_format := format.get("format", "") as String

        # NOTE (mristin):
        # V4L2 on Linux calls the format YUYV, Media Foundation on Windows YUY2.
        if (
            width == 640
            and height == 480
            and (pixel_format.begins_with("YUYV") or pixel_format.begins_with("YUY2"))
        ):
            return format_index

    return -1
