class_name Flow
extends RefCounted

## The way through the screens (see DESIGN.md, "The screens"):
## the intro, the expeditions, naming a new one, how to play (the first time),
## the worlds and the levels, and the level.

const INTRO := "res://scenes/intro/intro.tscn"
const SESSIONS := "res://scenes/sessions/sessions.tscn"
const SESSION_NAME := "res://scenes/session_name/session_name.tscn"
const INSTRUCTION := "res://scenes/instruction/instruction.tscn"
const LEVEL_SELECT := "res://scenes/level_select/level_select.tscn"
const LEVEL := "res://scenes/level/level.tscn"

## The level which the level scene plays, the index into [constant LevelCatalog.LEVELS].
static var level_index := 0

## The world which the level select opens, -1 for the worlds.
static var world := -1


## Show the screen.
static func go(tree: SceneTree, scene: String) -> void:
    tree.change_scene_to_file.call_deferred(scene)


## Go on from Play: choose the expedition (once each start), then how to play
## the first time, and the levels.
static func play(tree: SceneTree) -> void:
    var session := tree.root.get_node("/root/Session")
    if not session.chosen_this_run:
        if session.sessions().is_empty():
            go(tree, SESSION_NAME)
        else:
            go(tree, SESSIONS)
    elif not session.has_seen_instruction:
        go(tree, INSTRUCTION)
    else:
        world = -1
        go(tree, LEVEL_SELECT)


## Play the level of the index.
static func play_level(tree: SceneTree, index: int) -> void:
    level_index = clampi(index, 0, LevelCatalog.LEVELS.size() - 1)
    go(tree, LEVEL)
