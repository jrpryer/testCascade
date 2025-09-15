# res://data/npc_data.gd
extends Resource
class_name NPCData

const MEM_CAPACITY := 10

@export var id: int = -1  # assign via IdGen.next_npc_id()
@export var display_name: String = ""
@export var role: StringName = &""
@export var chunk_id: int = 0
@export var stats: PackedFloat32Array = PackedFloat32Array()
@export var memories: Array[MemoryNote] = []   # last N notes

func ensure_sizes() -> void:
	if stats.size() != GameDefs.STAT_COUNT:
		stats.resize(int(GameDefs.STAT_COUNT))

func remember(note: MemoryNote) -> void:
	memories.append(note)
	if memories.size() > MEM_CAPACITY:
		memories.pop_front()

func get_memories_ordered(tail: int = -1) -> Array[MemoryNote]:
	# Returns in chronological order (oldest → newest)
	var count: int = memories.size()
	if tail > 0 and tail < count:
		var out: Array[MemoryNote] = []
		out.resize(tail)
		var start: int = count - tail
		for i in range(tail):
			out[i] = memories[start + i]
		return out
	# full copy so callers can’t mutate our storage
	return memories.duplicate()

func get_stat(stat_name: Variant) -> float:
	var idx: int = GameDefs.stat_index(stat_name)
	return stats[idx] if idx >= 0 else 0.0

func set_stat(stat_name: Variant, value: float) -> void:
	var idx: int = GameDefs.stat_index(stat_name)
	if idx >= 0:
		stats[idx] = value

func add_stat(stat_name: Variant, delta: float) -> void:
	var idx: int = GameDefs.stat_index(stat_name)
	if idx >= 0:
		stats[idx] += delta
