class_name Dwarves
extends RefCounted

## The dwarves of the players: they have no names, only the colors of their
## tunics, by their slot (0 to 3); a player who comes gets the first free
## slot.

## The most dwarves which dig together.
const MAX := 4

const COLORS := [Color("#e04848"), Color("#3f8ee8"), Color("#3fbf5a"), Color("#f2b630")]


## The color of the dwarf of the player.
static func color(player: int) -> Color:
    return COLORS[clampi(player, 0, MAX - 1)]
