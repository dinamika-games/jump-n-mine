class_name Flow
extends RefCounted

## The way through the screens (see DESIGN.md, "The screens"):
## the intro, the story (the first time), the expeditions, naming a new one, how
## to play (the first time), the worlds and the levels, the level, and the shop
## and the house.

const INTRO := "res://scenes/intro/intro.tscn"
const SESSIONS := "res://scenes/sessions/sessions.tscn"
const SESSION_NAME := "res://scenes/session_name/session_name.tscn"
const INSTRUCTION := "res://scenes/instruction/instruction.tscn"
const LEVEL_SELECT := "res://scenes/level_select/level_select.tscn"
const LEVEL := "res://scenes/level/level.tscn"
const SHOP := "res://scenes/shop/shop.tscn"
const HOUSE := "res://scenes/house/house.tscn"
const STORY := "res://scenes/story/story.tscn"

## The level which the level scene plays, the index into [constant LevelCatalog.LEVELS].
static var level_index := 0

## The world which the level select opens, -1 for the worlds.
static var world := -1

## The level which the players go on with from the shop and the house (an index
## into [constant LevelCatalog.LEVELS]), or -1 to go back to the levels.
static var after_shop := -1


## Show the screen.
static func go(tree: SceneTree, scene: String) -> void:
    tree.change_scene_to_file.call_deferred(scene)


## Go on from Play: the story the first time, choose the expedition (once each
## start), then how to play the first time, and the levels.
static func play(tree: SceneTree) -> void:
    var session := tree.root.get_node("/root/Session")
    if not session.has_seen_story():
        go(tree, STORY)
    elif not session.chosen_this_run:
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


## Open the shop; from there the players go on with the level of the index, or
## back to the levels for -1.
static func open_shop(tree: SceneTree, next_level: int) -> void:
    after_shop = next_level
    go(tree, SHOP)


## Leave the shop or the house: to the level the players go on with, or to the
## levels.
static func leave_shop(tree: SceneTree) -> void:
    if after_shop >= 0:
        play_level(tree, after_shop)
    else:
        go(tree, LEVEL_SELECT)
