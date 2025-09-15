# res://systems/game_defs.gd
extends Resource
class_name GameDefs

enum STAT { HEALTH, ANGER, ENVY, LOYALTY, PIETY, FORTUNE }

enum BeliefState { UNALIGNED, SEEKER, BELIEVER, APOSTATE }

enum BIOME { DESERT, PLAINS, MOUNTAIN, FOREST }

const STAT_COUNT: int = 6
const NPC_CAPACITY: int = 20

const STAT_INDICES := {          # allow string lookup
	"health": STAT.HEALTH,
	"fortune": STAT.FORTUNE,
	"piety": STAT.PIETY,
	"loyalty": STAT.LOYALTY,
	"anger": STAT.ANGER,
	"envy": STAT.ENVY,
}

# Optional: faster StringName map (if you use &"fortune")
const STAT_INDEX_SN := {
	&"health": STAT.HEALTH,
	&"fortune": STAT.FORTUNE,
	&"piety": STAT.PIETY,
	&"loyalty": STAT.LOYALTY,
	&"anger": STAT.ANGER,
	&"envy": STAT.ENVY,
}

static func stat_index(name: Variant) -> int:
	# Accept String or StringName
	if name is StringName:
		return int(STAT_INDEX_SN.get(name, -1))
	return int(STAT_INDICES.get(String(name), -1))

static func stat_name(index: int) -> StringName:
	var names := [&"health", &"fortune", &"piety", &"loyalty", &"anger", &"envy",]
	return names[index] if index >= 0 and index < names.size() else &""
