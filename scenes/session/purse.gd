class_name Purse
extends RefCounted

## The purse of an expedition (see [Economy]): the gems which the dwarves
## gathered, the boosters bought with them for the next levels, and the stages
## of the dwarves' house. It calls back to save the expedition whenever it
## changes.

## The gems in the purse, and all the gems the expedition ever gathered.
var gems := 0
var gems_earned := 0

## The boosters bought for the next levels, by kind: how many.
var boosters := {}

## The stage of each part of the house (see [constant Economy.HOUSE_PARTS]), by
## its id: how many of its stages are built.
var house := {}

var _save: Callable


func _init(save: Callable) -> void:
    _save = save
    read_from({})


## Take the purse from the progress of a save (empty for a save of the format 1).
func read_from(data: Dictionary) -> void:
    gems = maxi(0, int(data.get("gems", 0)))
    gems_earned = maxi(gems, int(data.get("gems_earned", gems)))
    boosters = {}
    var saved_boosters: Dictionary = data.get("boosters", {})
    for kind in Mine.BOOSTERS:
        boosters[kind] = clampi(int(saved_boosters.get(kind, 0)), 0, Economy.MAX_CARRY)
    house = {}
    var saved_house: Dictionary = data.get("house", {})
    for part in Economy.HOUSE_PARTS:
        house[part["id"]] = clampi(
            int(saved_house.get(part["id"], 0)), 0, Economy.STAGE_PRICES.size()
        )


## Put the gems which the dwarves gathered in a level into the purse, and save.
func add_gems(count: int) -> void:
    if count <= 0:
        return
    gems += count
    gems_earned += count
    _save.call()


## How many boosters of the kind the players bought for the next levels.
func boosters_of(kind: String) -> int:
    return int(boosters.get(kind, 0))


## Whether the players can buy a booster of the kind now.
func can_buy_booster(kind: String) -> bool:
    return boosters_of(kind) < Economy.MAX_CARRY and gems >= int(Economy.BOOSTER_PRICES[kind])


## Buy a booster of the kind with the gems, and save; return whether it was
## bought.
func buy_booster(kind: String) -> bool:
    if not can_buy_booster(kind):
        return false
    gems -= int(Economy.BOOSTER_PRICES[kind])
    boosters[kind] = boosters_of(kind) + 1
    _save.call()
    return true


## A booster of the kind was used up in a level; save.
func use_booster(kind: String) -> void:
    if boosters_of(kind) <= 0:
        return
    boosters[kind] = boosters_of(kind) - 1
    _save.call()


## How many stages of the part of the house (its index in [constant
## Economy.HOUSE_PARTS]) are built.
func stage_of(part: int) -> int:
    return int(house.get(Economy.HOUSE_PARTS[part]["id"], 0))


## How many improvements of the house are built in all.
func house_built() -> int:
    var total := 0
    for part in range(Economy.HOUSE_PARTS.size()):
        total += stage_of(part)
    return total


## The price of the next stage of the part, or -1 if it is finished.
func next_house_price(part: int) -> int:
    var stage := stage_of(part)
    if stage >= Economy.STAGE_PRICES.size():
        return -1
    return Economy.house_price(part, stage)


## Build the next stage of the part with the gems, and save; return whether it
## was built.
func build(part: int) -> bool:
    var price := next_house_price(part)
    if price < 0 or gems < price:
        return false
    gems -= price
    house[Economy.HOUSE_PARTS[part]["id"]] = stage_of(part) + 1
    _save.call()
    return true
