class_name LevelCatalog
extends RefCounted

## The three worlds and the fifteen levels of the game (see DESIGN.md, "The
## levels").
##
## A level is plain data, from which [Mine] generates the mine with the seed of
## the level, so that a level is the same every time it is played. The test
## tests/godot/test_levels.gd lets a bot play each level and checks that it can
## be finished and how long it takes.
##
## The fields of a level:
## [br]- [code]id[/code], [code]name[/code], [code]world[/code] (the index into
##   [constant WORLDS]) and [code]seed[/code],
## [br]- [code]depth[/code]: how many rows of earth lie between the grass and the
##   treasure chamber,
## [br]- [code]rock[/code]: the share of the hard rock (4 hits) among the blocks at
##   the top and at the bottom, the rest is soft earth (3 hits),
## [br]- [code]bands[/code]: a band of hard rock across the mine every so many
##   rows; 0 for none,
## [br]- [code]clumps[/code]: clumps of hard rock per 100 blocks,
## [br]- [code]caves[/code]: open caves, where the dwarves drop down,
## [br]- [code]gems[/code]: the gems in the blocks,
## [br]- [code]gas[/code]: the pockets of gas, which explode once opened,
## [br]- [code]moles[/code]: how many seconds lie between two moles (from, to), or
##   an empty array for none,
## [br]- [code]rival[/code]: whether the evil miner of Queen Treacher races the
##   dwarves to the treasure,
## [br]- [code]springs[/code]: the springs in the walls, each with the depth as a
##   fraction of the mine, the side ("left" or "right") and how many cells of
##   water it pours per second,
## [br]- [code]drain[/code]: how many cells of water seep away per second,
## [br]- [code]puzzles[/code]: the halls with an iron gate and its plates (see
##   [MinePuzzles]), each with its "kind" ("timer" or "twin") and where it is
##   ("at", as a fraction of the depth),
## [br]- [code]dragons[/code]: how many seconds lie between two dragons (from,
##   to), or an empty array for none, and [code]dragons_from[/code], the depth as
##   a fraction of the mine from which they come.

const WORLDS: Array[Dictionary] = [
    {
        "id": "copper_hills",
        "name": "The Copper Hills",
        "story": "Dig down to the old copper chests of the dwarves.",
        "sky_top": Color("#7ec8f0"),
        "sky_bottom": Color("#d8f0ff"),
        "grass": Color("#5cb84a"),
        "cave": Color("#241a33"),
        "cave_far": Color("#31243f"),
        "dirt": Color("#d99a52"),
        "rock": Color("#a8653a"),
    },
    {
        "id": "sunken_halls",
        "name": "The Sunken Halls",
        "story": "The old halls lie deep under the lake. Keep the water out!",
        "sky_top": Color("#8fb4d9"),
        "sky_bottom": Color("#e2ecf5"),
        "grass": Color("#4fa36b"),
        "cave": Color("#121c2b"),
        "cave_far": Color("#1b2a3d"),
        "dirt": Color("#cdb38a"),
        "rock": Color("#9a8466"),
    },
    {
        "id": "dragon_deeps",
        "name": "The Dragon Deeps",
        "story": "Dragons guard the heart of the mountain. Mind the fire!",
        "sky_top": Color("#e8916b"),
        "sky_bottom": Color("#f8d9a8"),
        "grass": Color("#8a9a3c"),
        "cave": Color("#1f0f14"),
        "cave_far": Color("#2e161d"),
        "dirt": Color("#d4a57a"),
        "rock": Color("#a3705a"),
    },
]

const LEVELS: Array[Dictionary] = [
    # The Copper Hills: digging, gems, boosters and the first gas pockets.
    {
        "id": "01_first_swing",
        "name": "The First Swing",
        "world": 0,
        "seed": 1101,
        "depth": 68,
        "rock": [0.05, 0.3],
        "bands": 0,
        "clumps": 2.0,
        "caves": 10,
        "gems": 22,
        "gas": 0,
        "moles": [20.0, 40.0],
        "rival": false,
        "springs": [],
        "drain": 0.0,
        "dragons": [],
        "dragons_from": 1.0,
        "puzzles": [],
    },
    {
        "id": "02_copper_veins",
        "name": "Copper Veins",
        "world": 0,
        "seed": 1202,
        "depth": 72,
        "rock": [0.15, 0.45],
        "bands": 0,
        "clumps": 4.0,
        "caves": 9,
        "gems": 21,
        "gas": 0,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs": [],
        "drain": 0.0,
        "dragons": [],
        "dragons_from": 1.0,
        "puzzles": [],
    },
    {
        "id": "03_mushroom_grotto",
        "name": "The Mushroom Grotto",
        "world": 0,
        "seed": 1303,
        "depth": 74,
        "rock": [0.2, 0.5],
        "bands": 14,
        "clumps": 4.0,
        "caves": 13,
        "gems": 23,
        "gas": 0,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs": [],
        "drain": 0.0,
        "dragons": [],
        "dragons_from": 1.0,
        "puzzles": [{"kind": "timer", "at": 0.5}],
    },
    {
        "id": "04_barrels_of_thunder",
        "name": "Barrels of Thunder",
        "world": 0,
        "seed": 1404,
        "depth": 68,
        "rock": [0.25, 0.6],
        "bands": 12,
        "clumps": 5.0,
        "caves": 8,
        "gems": 19,
        "gas": 17,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs": [],
        "drain": 0.0,
        "dragons": [],
        "dragons_from": 1.0,
        "puzzles": [{"kind": "timer", "at": 0.4}],
    },
    {
        "id": "05_dripping_gallery",
        "name": "The Dripping Gallery",
        "world": 0,
        "seed": 1505,
        "depth": 70,
        "rock": [0.25, 0.6],
        "bands": 12,
        "clumps": 5.0,
        "caves": 9,
        "gems": 22,
        "gas": 11,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs":
        [
            {"at": 0.45, "side": "left", "rate": 0.12},
            {"at": 0.95, "side": "right", "rate": 0.12},
        ],
        "drain": 0.04,
        "dragons": [],
        "dragons_from": 1.0,
        "puzzles": [{"kind": "twin", "at": 0.6}],
    },
    # The Sunken Halls: water from the left and the right.
    {
        "id": "06_well_of_whispers",
        "name": "The Well of Whispers",
        "world": 1,
        "seed": 2106,
        "depth": 68,
        "rock": [0.3, 0.6],
        "bands": 12,
        "clumps": 5.0,
        "caves": 9,
        "gems": 22,
        "gas": 9,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs":
        [
            {"at": 0.3, "side": "right", "rate": 0.12},
            {"at": 0.55, "side": "left", "rate": 0.12},
            {"at": 0.65, "side": "left", "rate": 0.12},
        ],
        "drain": 0.05,
        "dragons": [],
        "dragons_from": 1.0,
        "puzzles": [{"kind": "timer", "at": 0.3}, {"kind": "twin", "at": 0.7}],
    },
    {
        "id": "07_flooded_stairs",
        "name": "The Flooded Stairs",
        "world": 1,
        "seed": 2207,
        "depth": 70,
        "rock": [0.3, 0.65],
        "bands": 10,
        "clumps": 5.0,
        "caves": 9,
        "gems": 22,
        "gas": 9,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs":
        [
            {"at": 0.2, "side": "left", "rate": 0.14},
            {"at": 0.37, "side": "right", "rate": 0.14},
            {"at": 0.5, "side": "right", "rate": 0.14},
            {"at": 0.67, "side": "left", "rate": 0.14},
            {"at": 0.8, "side": "left", "rate": 0.14},
            {"at": 0.97, "side": "right", "rate": 0.14},
        ],
        "drain": 0.06,
        "dragons": [],
        "dragons_from": 1.0,
        "puzzles": [{"kind": "twin", "at": 0.5}],
    },
    {
        "id": "08_pump_room",
        "name": "The Pump Room",
        "world": 1,
        "seed": 2308,
        "depth": 74,
        "rock": [0.35, 0.65],
        "bands": 12,
        "clumps": 6.0,
        "caves": 11,
        "gems": 26,
        "gas": 12,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs":
        [
            {"at": 0.25, "side": "right", "rate": 0.16},
            {"at": 0.42, "side": "left", "rate": 0.16},
            {"at": 0.45, "side": "left", "rate": 0.16},
            {"at": 0.62, "side": "right", "rate": 0.16},
            {"at": 0.7, "side": "right", "rate": 0.16},
            {"at": 0.87, "side": "left", "rate": 0.16},
        ],
        "drain": 0.06,
        "dragons": [],
        "dragons_from": 1.0,
        "puzzles": [{"kind": "timer", "at": 0.3}, {"kind": "twin", "at": 0.75}],
    },
    {
        "id": "09_crystal_lake",
        "name": "The Crystal Lake",
        "world": 1,
        "seed": 2409,
        "depth": 69,
        "rock": [0.35, 0.7],
        "bands": 11,
        "clumps": 6.0,
        "caves": 13,
        "gems": 28,
        "gas": 10,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs":
        [
            {"at": 0.15, "side": "left", "rate": 0.14},
            {"at": 0.28, "side": "right", "rate": 0.14},
            {"at": 0.35, "side": "right", "rate": 0.14},
            {"at": 0.47, "side": "left", "rate": 0.14},
            {"at": 0.55, "side": "left", "rate": 0.14},
            {"at": 0.68, "side": "right", "rate": 0.14},
            {"at": 0.8, "side": "right", "rate": 0.14},
        ],
        "drain": 0.07,
        "dragons": [],
        "dragons_from": 1.0,
        "puzzles": [{"kind": "twin", "at": 0.4}, {"kind": "timer", "at": 0.8}],
    },
    {
        "id": "10_waterfall_mine",
        "name": "The Waterfall Mine",
        "world": 1,
        "seed": 2510,
        "depth": 69,
        "rock": [0.4, 0.7],
        "bands": 10,
        "clumps": 6.0,
        "caves": 10,
        "gems": 26,
        "gas": 13,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs":
        [
            {"at": 0.2, "side": "right", "rate": 0.16},
            {"at": 0.33, "side": "left", "rate": 0.16},
            {"at": 0.4, "side": "left", "rate": 0.16},
            {"at": 0.53, "side": "right", "rate": 0.16},
            {"at": 0.6, "side": "right", "rate": 0.16},
            {"at": 0.85, "side": "left", "rate": 0.16},
        ],
        "drain": 0.07,
        "dragons": [40.0, 60.0],
        "dragons_from": 0.6,
        "puzzles": [{"kind": "twin", "at": 0.5}],
    },
    # The Dragon Deeps: dragons spit fire from above, and everything together.
    {
        "id": "11_smoke_in_the_shaft",
        "name": "Smoke in the Shaft",
        "world": 2,
        "seed": 3111,
        "depth": 69,
        "rock": [0.35, 0.7],
        "bands": 12,
        "clumps": 5.0,
        "caves": 9,
        "gems": 24,
        "gas": 12,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs": [],
        "drain": 0.0,
        "dragons": [20.0, 32.0],
        "dragons_from": 0.0,
        "puzzles": [{"kind": "timer", "at": 0.35}, {"kind": "twin", "at": 0.7}],
    },
    {
        "id": "12_ember_seam",
        "name": "The Ember Seam",
        "world": 2,
        "seed": 3212,
        "depth": 68,
        "rock": [0.4, 0.75],
        "bands": 11,
        "clumps": 6.0,
        "caves": 10,
        "gems": 24,
        "gas": 13,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs":
        [
            {"at": 0.0, "side": "right", "rate": 0.12},
            {"at": 0.5, "side": "left", "rate": 0.12},
        ],
        "drain": 0.06,
        "dragons": [18.0, 28.0],
        "dragons_from": 0.0,
        "puzzles": [{"kind": "twin", "at": 0.5}],
    },
    {
        "id": "13_thunder_halls",
        "name": "The Thunder Halls",
        "world": 2,
        "seed": 3313,
        "depth": 64,
        "rock": [0.4, 0.75],
        "bands": 11,
        "clumps": 6.0,
        "caves": 9,
        "gems": 24,
        "gas": 24,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs":
        [
            {"at": 0.4, "side": "right", "rate": 0.12},
            {"at": 0.9, "side": "left", "rate": 0.12},
        ],
        "drain": 0.06,
        "dragons": [16.0, 26.0],
        "dragons_from": 0.0,
        "puzzles": [{"kind": "twin", "at": 0.3}, {"kind": "timer", "at": 0.65}],
    },
    {
        "id": "14_dragons_larder",
        "name": "The Dragons' Larder",
        "world": 2,
        "seed": 3414,
        "depth": 68,
        "rock": [0.45, 0.8],
        "bands": 10,
        "clumps": 7.0,
        "caves": 10,
        "gems": 28,
        "gas": 15,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs":
        [
            {"at": 0.3, "side": "left", "rate": 0.14},
            {"at": 0.55, "side": "right", "rate": 0.14},
            {"at": 0.7, "side": "right", "rate": 0.14},
            {"at": 0.95, "side": "left", "rate": 0.14},
        ],
        "drain": 0.07,
        "dragons": [14.0, 22.0],
        "dragons_from": 0.0,
        "puzzles":
        [{"kind": "timer", "at": 0.25}, {"kind": "twin", "at": 0.55}, {"kind": "twin", "at": 0.85}],
    },
    {
        "id": "15_heart_of_the_mountain",
        "name": "The Heart of the Mountain",
        "world": 2,
        "seed": 3515,
        "depth": 68,
        "rock": [0.45, 0.85],
        "bands": 10,
        "clumps": 7.0,
        "caves": 10,
        "gems": 31,
        "gas": 18,
        "moles": [20.0, 40.0],
        "rival": true,
        "springs":
        [
            {"at": 0.2, "side": "right", "rate": 0.14},
            {"at": 0.37, "side": "left", "rate": 0.14},
            {"at": 0.45, "side": "left", "rate": 0.14},
            {"at": 0.75, "side": "right", "rate": 0.14},
        ],
        "drain": 0.07,
        "dragons": [14.0, 22.0],
        "dragons_from": 0.0,
        "puzzles":
        [{"kind": "twin", "at": 0.3}, {"kind": "timer", "at": 0.55}, {"kind": "twin", "at": 0.8}],
    },
]

## How many levels each world has.
const LEVELS_PER_WORLD := 5


## The level of the id, or an empty dictionary.
static func find(id: String) -> Dictionary:
    for level in LEVELS:
        if level["id"] == id:
            return level
    return {}


## The index of the level of the id in [constant LEVELS], or -1.
static func index_of(id: String) -> int:
    for i in range(LEVELS.size()):
        if LEVELS[i]["id"] == id:
            return i
    return -1


## The levels of the world.
static func levels_of(world: int) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for level in LEVELS:
        if int(level["world"]) == world:
            result.append(level)
    return result
