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

## A full jump rises this many head sizes above standing, and a low one (a
## weaker hit) at least [constant LOW_JUMP_HEIGHT] (see JumpGauge); for the
## jump meters.
const JUMP_HEIGHT := 0.35
const LOW_JUMP_HEIGHT := 0.2

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
## "jumping" (whether the player is in a jump now) and "jumped" (the time of the
## last jump, in seconds, or -1).
var heads := {}

## Why there is no camera, for the players; empty while it runs or is searched.
var camera_problem := ""

## Whether we still look for the camera.
var searching := false

@onready var service: Node = $HeadVision


func _ready() -> void:
    service.HeadAppeared.connect(_on_appeared)
    service.HeadMoved.connect(_on_moved)
    service.HeadLost.connect(_on_lost)
    service.HeadJumped.connect(_on_jumped)

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
    return service.GetPreview()


## What to tell the players about the camera: empty while all is well.
func status() -> String:
    if camera_problem != "":
        return camera_problem
    if searching:
        return "Looking for the camera..."
    return service.Status


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
    id: int, position: Vector2, size: float, rise: float, jump_line: float, jumping: bool
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
    head_moved.emit(id, position)


static func _new_head(position: Vector2, size: float) -> Dictionary:
    return {
        "position": position,
        "size": size,
        "rise": 0.0,
        "jump_line": NAN,
        "jumping": false,
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
