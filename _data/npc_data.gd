extends Resource
class_name NPCData

@export var id: int = -1  # assign via IdGen.next_npc_id()
@export var display_name: StringName = &""
@export var role: GameDefs.COMMUNITY_ROLE
@export var goal: StringName = &""
@export var chunk_id: int = 0
@export var stats: PackedFloat32Array = PackedFloat32Array()

# Store only event IDs (64-bit safe)
const MEM_CAP: int = 100
@export var memories: PackedInt64Array = PackedInt64Array()

func ensure_sizes() -> void:
	if stats.size() != GameDefs.STAT_COUNT:
		stats.resize(GameDefs.STAT_COUNT)

# --- Memory: IDs only -------------------------------------------------------

func remember_event(ev_id: int) -> void:
	# append and cap
	memories.append(ev_id)
	if memories.size() > MEM_CAP:
		memories.remove_at(0)

func get_memory_ids(limit: int = -1) -> PackedInt64Array:
	# return most-recent-first up to limit
	var out := PackedInt64Array()
	var count: int = memories.size()
	var take: int = count
	if limit > 0 and limit < count:
		take = limit
	for i in range(count - 1, count - take - 1, -1):
		out.append(memories[i])
	return out

func get_memories_ordered(limit: int = -1) -> Array[MemoryNote]:
	# resolve IDs via EventLog and wrap as MemoryNote (friendly formatting later)
	var ids := get_memory_ids(limit)
	var out: Array[MemoryNote] = []
	for k in range(ids.size()):
		var ev := EventLog.get_event(int(ids[k]))
		if ev != null:
			out.append(MemoryNote.from_event(ev))
	return out

# --- Stats convenience -------------------------------------------------------

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
