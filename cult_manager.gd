extends Node
class_name CultManager

signal state_changed(change_type: String, affected_npcs: Array)

@export var cult_data: CultData
@export var cascade_system: CascadeSystem

const STAT_INDICES := GameDefs.STAT_INDICES
const CLUSTER_AFFINITY_THRESHOLD: float = 70.0

#var n: int = cult_data.relationship_matrix.size()

func _ready() -> void:
	assert(cult_data != null)
	assert(cascade_system != null)

func process_action(ev: GameEvent) -> void:
	match ev.action:
		"bless":
			_apply_stat_delta(ev.target_npc, &"fortune", +absf(ev.strength))
		"curse":
			_apply_stat_delta(ev.target_npc, &"fortune", -absf(ev.strength))
		"stat_cascade":
			spread_stat(ev)
		"belief_cascade":
			spread_belief(ev)
		_:
			push_warning("Unhandled action: %s" % ev.action)
	_update_cached_queries()
	emit_signal("state_changed", ev.action, [ev.source_npc, ev.target_npc])

func _remember(npc_id: int, ev: GameEvent, before: float, after: float, label: String) -> void:
	if npc_id < 0 or npc_id >= cult_data.npcs.size(): return
	var note := MemoryNote.from_event(ev, npc_id, before, after, label)
	cult_data.npcs[npc_id].remember(note)

func spread_stat(ev: GameEvent) -> void:
	# Hard types on all locals
	var stat_idx: int = int(GameDefs.stat_index(ev.stat))
	if stat_idx < 0: return
	#var count: int = cult_data.stats_matrix.size()
	var count: int = cult_data.npcs.size()
	var src: int = int(ev.source_npc)
	var strength: float = float(ev.strength)
	var decay: float = clamp(float(ev.decay_rate), 0.0, 1.0)

	# Source
	var before_src: float = float(cult_data.npcs[src].stats[stat_idx])
	var after_src: float = clamp(before_src + strength, 0.0, 100.0)
	cult_data.npcs[src].stats[stat_idx] = after_src
	_remember(src, ev, before_src, after_src, "origin")

	# Recipients
	for tgt in range(count):
		if tgt == src: continue
		var aff01: float = clamp(float(cult_data.relationship_matrix[src][tgt]) * 0.01, 0.0, 1.0)
		if aff01 <= 0.0: continue
		var delta: float = strength * aff01 * (1.0 - decay)   # <- explicitly float
		if absf(delta) < 0.0001: continue
		
		var before: float = float(cult_data.npcs[tgt].stats[stat_idx])
		var after: float = clamp(before + delta, 0.0, 100.0)
		cult_data.npcs[tgt].stats[stat_idx] = after
		_remember(tgt, ev, before, after, "received")
	
	emit_signal("state_changed", "stat_cascade", [src])


func spread_belief(ev: GameEvent) -> void:
	# Sketch: increase neighbors toward BELIEVER if influence is strong
	var start := ev.source_npc
	if start < 0: return
	for i in cult_data.relationship_matrix.size():
		if i == start: continue
		var w := cult_data.relationship_matrix[start][i]
		if w > 70.0:
			cult_data.belief_states[i] = max(cult_data.belief_states[i], GameDefs.BeliefState.SEEKER)

func _apply_stat_delta(npc_id: int, stat_name: String, delta: float) -> void:
	if npc_id < 0: return
	var idx : int = int(STAT_INDICES.get(stat_name, -1))
	if idx == -1: return
	cult_data.npcs[npc_id].stats[idx] += delta

# Cached queries -------------------------------------------------------------

func _update_cached_queries() -> void:
	_build_social_clusters()
	# believers_by_family etc. could be added here when family ids exist.

func _build_social_clusters() -> void:
	cult_data.social_clusters.clear()
	var m: Array[PackedFloat32Array] = cult_data.relationship_matrix
	var n: int = m.size()
	var assigned: PackedInt32Array = PackedInt32Array()
	assigned.resize(n)

	for i in range(n):
		if assigned[i] == 1:
			continue
		var cluster: Array[int] = []
		var queue: Array[int] = [i]
		assigned[i] = 1
		while not queue.is_empty():
			var u: int = queue.pop_back()
			cluster.append(u)
			for v in range(n):
				if v == u or assigned[v] == 1:
					continue
				var uv: float = float(m[u][v])
				var vu: float = float(m[v][u])
				if uv > CLUSTER_AFFINITY_THRESHOLD and vu > CLUSTER_AFFINITY_THRESHOLD:
					assigned[v] = 1
					queue.append(v)
		if cluster.size() > 1:
			cult_data.social_clusters.append(cluster)

#func _build_social_clusters() -> void:
	#cult_data.social_clusters.clear()
	#var n := cult_data.relationship_matrix.size()
	#var assigned := PackedInt32Array()
	#assigned.resize(n)
	#for i in range(n):
		#if assigned[i] == 1: continue
		#var cluster := [i]
		#assigned[i] = 1
		#for j in range(n):
			#if i == j or assigned[j] == 1: continue
			#if cult_data.relationship_matrix[i][j] > CLUSTER_AFFINITY_THRESHOLD and cult_data.relationship_matrix[j][i] > CLUSTER_AFFINITY_THRESHOLD:
				#cluster.append(j); assigned[j] = 1
		#if cluster.size() > 1:
			#cult_data.social_clusters.append(cluster)
