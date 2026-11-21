class_name Economy
extends RefCounted

## What the gems buy (see DESIGN.md, "The gems, the shop and the house"): the
## boosters for the next levels, and the improvements of the dwarves' house.
##
## The dwarves keep the gems which they gathered in a level, whether they found
## the treasure or not. The prices are checked by tests/godot/test_economy.gd
## (with all the gems of the first levels, the players buy only a little of the
## house) and simulated by dev/economy_simulation.gd, which lets bots play every
## level and spends their gems greedily.

## The price of a booster, in gems.
const BOOSTER_PRICES := {"gold_pick": 10, "helmet": 8, "boots": 6, "pump": 12}

## The players take at most this many of each booster into a level.
const MAX_CARRY := 3

## The names of the boosters and what they do, for the shop.
const BOOSTER_INFO := {
    "gold_pick": ["Golden pickaxe", "Double hits on the rock, 20 s"],
    "helmet": ["Fire helmet", "No dizziness from fire, 30 s"],
    "boots": ["Spring boots", "Hop up two blocks, 25 s"],
    "pump": ["Pump", "Pumps out the water"],
}

## The price of each of the five stages of a part of the house, before the
## part's factor ([constant HOUSE_PARTS]).
const STAGE_PRICES := [5, 12, 24, 40, 64]

## The parts of the dwarves' house, each with five stages built one after the
## other (in any order of the parts, like the palace of Civilization III): its
## "id", its "name", a "factor" of its prices, and the names of the "stages".
const HOUSE_PARTS: Array[Dictionary] = [
    {
        "id": "walls",
        "name": "Walls",
        "factor": 1.0,
        "stages": ["Log walls", "Timber frame", "Stone walls", "Carved stone", "Marble and gold"],
    },
    {
        "id": "roof",
        "name": "Roof",
        "factor": 1.0,
        "stages": ["Straw roof", "Wooden shingles", "Red tiles", "Slate and dormer", "Golden roof"],
    },
    {
        "id": "door",
        "name": "Door",
        "factor": 0.8,
        "stages": ["Plank door", "Oak door", "Iron-bound door", "Arched gate", "Gem-studded gate"],
    },
    {
        "id": "windows",
        "name": "Windows",
        "factor": 0.8,
        "stages": ["Shutters", "Glass windows", "Flower boxes", "Stained glass", "Rose window"],
    },
    {
        "id": "chimney",
        "name": "Chimney",
        "factor": 0.8,
        "stages": ["Clay pipe", "Brick chimney", "Stone chimney", "Twin chimneys", "Forge chimney"],
    },
    {
        "id": "tower",
        "name": "Tower",
        "factor": 1.3,
        "stages":
        ["Lookout post", "Stone tower", "Tower with a flag", "Clock tower", "Crystal spire"],
    },
    {
        "id": "garden",
        "name": "Garden",
        "factor": 0.9,
        "stages": ["Flowers", "Vegetable beds", "Mushroom patch", "Pond", "Fountain"],
    },
    {
        "id": "fence",
        "name": "Fence",
        "factor": 0.7,
        "stages": ["Stick fence", "Picket fence", "Stone wall", "Iron fence", "Hedge with arches"],
    },
    {
        "id": "mine",
        "name": "Mine entrance",
        "factor": 1.1,
        "stages": ["Timber props", "Rails", "Mine cart", "Lanterns", "Gem-studded gate"],
    },
    {
        "id": "square",
        "name": "Village square",
        "factor": 1.2,
        "stages": ["Bench", "Market stall", "Well", "Bandstand", "Statue of the miners"],
    },
]


## The price of the stage (0 to 4) of the part (its index in [constant
## HOUSE_PARTS]), in gems.
static func house_price(part: int, stage: int) -> int:
    var factor := float(HOUSE_PARTS[part]["factor"])
    return int(round(STAGE_PRICES[stage] * factor))


## The price of the whole house, in gems.
static func house_total() -> int:
    var total := 0
    for part in range(HOUSE_PARTS.size()):
        for stage in range(STAGE_PRICES.size()):
            total += house_price(part, stage)
    return total


## How many improvements the house has in all.
static func house_count() -> int:
    return HOUSE_PARTS.size() * STAGE_PRICES.size()


## Build the cheapest stages of the house which the purse affords, one after the
## other, into the built stages (by the index of the part); return the gems
## left. The simulation and the tests spend like this.
static func build_greedily(purse: int, built: Dictionary) -> int:
    while true:
        var best := -1
        var best_price := 1 << 30
        for part in range(HOUSE_PARTS.size()):
            var stage := int(built.get(part, 0))
            if stage >= STAGE_PRICES.size():
                continue
            var price := house_price(part, stage)
            if price < best_price:
                best_price = price
                best = part
        if best < 0 or best_price > purse:
            return purse
        purse -= best_price
        built[best] = int(built.get(best, 0)) + 1
    return purse
