extends RefCounted
class_name GameEvent

@export var id: int = -1
@export var timestamp_ms: int = 0
@export var action: StringName = &""     # e.g. &"stat_cascade"
#@export var stat: GameDefs.STAT       # Action infers the stat
@export var source_npc: int = -1
@export var target_npc: int = -1
@export var strength: float = 0.0        # intensity / delta
@export var decay_rate: float = 0.0      # [0..1]
@export var metadata: Dictionary = {}
@export var parent_id: int = -1
@export var chain_id: int = -1

static func make(
	_id: int,
	_action: StringName,
	_metadata: Dictionary,
#	_stat: GameDefs.STAT,
	_source_npc: int = -1,
	_target_npc: int = -1,
	_strength: float = 0.0,
	_decay_rate: float = 0.0,
	_parent_id: int = -1,
	_chain_id: int = -1
) -> GameEvent:
	var ev := GameEvent.new()
	ev.id = _id
	ev.timestamp_ms = Time.get_ticks_msec()
#	ev.stat = _stat
	ev.action = _action
	ev.source_npc = _source_npc
	ev.target_npc = _target_npc
	ev.strength = _strength
	ev.decay_rate = _decay_rate
	ev.metadata = _metadata
	ev.parent_id = _parent_id
	ev.chain_id = _chain_id
	return ev

func has_source() -> bool: return source_npc >= 0
func has_target() -> bool: return target_npc >= 0
func has_parent() -> bool: return parent_id >= 0
func has_chain() -> bool:  return chain_id  >= 0
