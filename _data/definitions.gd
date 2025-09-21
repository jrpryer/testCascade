# res://systems/game_defs.gd
extends Resource
class_name GameDefs

enum STAT { HEALTH, ANGER, ENVY, LOYALTY, PIETY, FORTUNE }
#enum ACTION {APRAYER, BLESS, CURSE, DROUGHT, FSUMMON, HEAL, HEAT, HSUMMON, IPRAYER, KILL, KIDNAP, MARRY, PLAGUE, PROPHECY, RAIN, RENAME}
enum COMMUNITY_ROLE { APOSTLE, PRIEST, BUILDER, WORKER, UNBELIEVER }
enum BIOME { DESERT, PLAINS, MOUNTAIN, FOREST }

const STAT_COUNT: int = 6
const NPC_CAPACITY: int = 20

const BIOME_RESOURCE := {
	BIOME.DESERT:   &"oasis",
	BIOME.PLAINS:   &"fertile_soil",
	BIOME.MOUNTAIN: &"ore_caves",
	BIOME.FOREST:   &"hunting_grounds",
}

#const ACTION_INDEX_SN := {
#	 &"aprayer":  ACTION.APRAYER,
#	 &"bless":    ACTION.BLESS,
#	 &"curse":    ACTION.CURSE,
#	 &"drought":  ACTION.DROUGHT,
#	 &"fsummon":  ACTION.FSUMMON,
#	 &"heal":     ACTION.HEAL,
#	 &"heat":     ACTION.HEAT,
#	 &"hsummon":  ACTION.HSUMMON,
#	 &"iprayer":  ACTION.IPRAYER,
#	 &"kill":     ACTION.KILL,
#	 &"kidnap":   ACTION.KIDNAP,
#	 &"marry":    ACTION.MARRY,
#	 &"plague":   ACTION.PLAGUE,
#	 &"prophecy": ACTION.PROPHECY,
#	 &"rain":     ACTION.RAIN,
#	 &"rename":   ACTION.RENAME,
# }

const ACTION_TO_STAT := {
	&"famine":        &"anger",
	&"eclipse_omen":  &"piety",
	&"blood_tax":     &"loyalty",
	&"stranger_arrives": &"fortune",
	}

#const STAT_INDICES := {          # allow string lookup
#	"health": STAT.HEALTH,
#	"fortune": STAT.FORTUNE,
#	"piety": STAT.PIETY,
#	"loyalty": STAT.LOYALTY,
#	"anger": STAT.ANGER,
#	"envy": STAT.ENVY,
#}

# Faster StringName map lookup
const STAT_INDEX_SN := {
	&"health": STAT.HEALTH,
	&"fortune": STAT.FORTUNE,
	&"piety": STAT.PIETY,
	&"loyalty": STAT.LOYALTY,
	&"anger": STAT.ANGER,
	&"envy": STAT.ENVY,
}

const ROLE_INDEX_SN := {
	&"apostle" : COMMUNITY_ROLE.APOSTLE,
	&"priest" : COMMUNITY_ROLE.PRIEST,
	&"worker" : COMMUNITY_ROLE.WORKER ,
	&"builder" : COMMUNITY_ROLE.BUILDER,
	&"unbeliever" : COMMUNITY_ROLE.UNBELIEVER
}

static func stat_index(name: Variant) -> int:
	return int(STAT_INDEX_SN.get(name, -1))

static func stat_name(index: int) -> StringName:
	var names := [&"health", &"fortune", &"piety", &"loyalty", &"anger", &"envy",]
	return names[index] if index >= 0 and index < names.size() else &""
#
#static func action_index(name: StringName) -> int:
#	return int(ACTION_INDEX_SN.get(name, -1))	
#
#static func action_name(index: int) -> StringName:
#	var names := [&"aprayer", &"bless", &"curse", &"drought", &"fsummon", &"heal", &"heat", &"hsummon", &"iprayer", &"kill", &"kidnap", &"marry", &"plague", &"prophecy", &"rain", &"rename"]
#	return names[index] if index >= 0 and index < names.size() else &""
