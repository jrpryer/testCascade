extends Node
class_name CultManager

@export var cult_data: CultData

signal stat_changed(npc_id: int, stat_idx: int, before: float, after: float, ev: GameEvent)

#func _ready() -> void:
	#assert(cult_data != null)

# ---- Tight data surface ----

func get_npc_count() -> int:
	return cult_data.npcs.size()

func get_affinity(a: int, b: int) -> float:
	var n: int = cult_data.relationship_matrix.size()
	if a < 0 or b < 0 or a >= n or b >= n:
		return 0.0
	return float(cult_data.relationship_matrix[a][b])  # 0..100

func add_affinity_delta(a: int, b: int, d: float) -> void:
	var n: int = cult_data.relationship_matrix.size()
	if a < 0 or b < 0 or a >= n or b >= n:
		return
	cult_data.relationship_matrix[a][b] = clamp(cult_data.relationship_matrix[a][b] + d, 0.0, 100.0)

func add_stat(npc_id: int, stat_idx: int, delta: float, ev: GameEvent) -> float:
	if npc_id < 0 or npc_id >= cult_data.npcs.size():
		return 0.0
	if stat_idx < 0 or stat_idx >= GameDefs.STAT_COUNT:
		return 0.0
	var npc: NPCData = cult_data.npcs[npc_id]
	var before: float = float(npc.stats[stat_idx])
	var after: float = clamp(before + delta, 0.0, 100.0)
	npc.stats[stat_idx] = after
	if ev != null:
		cult_data.npcs[npc_id].remember_event(ev.id)
#		npc.remember(MemoryNote.from_event(ev))
	stat_changed.emit(npc_id, stat_idx, before, after, ev)

	# Optional: relationship feedback (tiny, symmetric-ish)
	# Uncomment if you want immediate social drift:
	# if ev.source_npc >= 0 and npc_id != ev.source_npc:
	#     var drift := abs(delta) * 0.1 * (delta >= 0.0 ? 1.0 : -0.3)
	#     add_affinity_delta(npc_id, ev.source_npc, drift)

#	stat_changed.emit(npc_id, stat_idx, before, after, ev)
	return after


	#extends Node
#class_name CultManager
#
#signal state_changed(change_type: GameDefs.ACTION, affected_npcs: Array)
#
#@export var cult_data: CultData
#@export var cascade_system: CascadeManager
#
#const CLUSTER_AFFINITY_THRESHOLD: float = 70.0
## Tune how much relationships change per point of stat delta experienced by tgt.
#const REL_DELTA_PER_POINT: float = 0.25
#
#var action_queue: Array[GameEvent] = []
#
#
#func _ready() -> void:
#	assert(cult_data != null)
#	assert(cascade_system != null)
#
#func queue_action(ev) -> void:
#	action_queue.append(ev)
#
#func process_actions(max_iterations: int = 100) -> void:
#	var i := 0
#	while i < max_iterations and action_queue.size() > 0:
#		var ev: GameEvent = action_queue.pop_front()
#		_execute(ev)
#		i += 1
#
#func _execute(ev: GameEvent) -> void:
##	match ev.action:
##		"BLESS":
##			_apply_stat_delta(ev.target_npc, &"fortune", +absf(ev.strength))
##		"curse":
##			_apply_stat_delta(ev.target_npc, &"fortune", -absf(ev.strength))
##		"kill":
##			_apply_stat_delta(ev.target_npc, &"health", -absf(ev.strength))
##		"stat_cascade":
##			spread_stat(ev)
##		"belief_cascade":
##			spread_belief(ev)
##		_:
##			push_warning("Unhandled action: %s" % ev.action)
#	
#	# Let systems register themselves for post-processing
##	_post_process_event.emit(ev)
##	_update_cached_queries()
#	emit_signal("state_changed", str(ev.action), [ev.source_npc, ev.target_npc]) ##ANSWER only needed for potential UI updates
#
#func _get_relationship_context(src: int, tgt: int, stat: StringName) -> float:
#	var base_rel: float = cult_data.relationship_matrix[src][tgt] * 0.01
#
#	# Relationship value determines disposition type
#	if base_rel > 0.75: return base_rel * 1.2      # Strong bonds amplify
#	elif base_rel < 0.25: return base_rel * 0.3    # Enemies resist influence  
#	elif String(stat) == "anger": return base_rel * 0.7  # Anger spreads easier through weak ties
#	else: return base_rel
#
#	
#func _apply_relationship_delta(a: int, b: int, delta: float) -> void:
#	if a < 0 or b < 0: return
#	if a >= cult_data.npcs.size() or b >= cult_data.npcs.size(): return
#	var before_ab: float = float(cult_data.relationship_matrix[a][b])
#	var after_ab: float = clamp(before_ab + delta, 0.0, 100.0)
#	cult_data.relationship_matrix[a][b] = after_ab
#
#func _apply_stat_delta(npc_id: int, stat: StringName, delta: float) -> void:
#	var idx := int(GameDefs.stat_index(stat))
#	if idx < 0 or npc_id < 0 or npc_id >= cult_data.npcs.size(): return
#	var before := float(cult_data.npcs[npc_id].stats[idx])
#	var after : float = clamp(before + float(delta), 0.0, 100.0)
#	cult_data.npcs[npc_id].stats[idx] = after
#
#
#func spread_stat(ev: GameEvent) -> void:
#	# Hard types on all locals
#	var stat_idx: int = int(GameDefs.stat_index(ev.stat))
#	if stat_idx < 0: return
#	#var count: int = cult_data.stats_matrix.size()
#	var count: int = cult_data.npcs.size()
#	var src: int = int(ev.source_npc)
#	var strength: float = float(ev.strength)
#	var decay: float = clamp(float(ev.decay_rate), 0.0, 1.0)
#
#	# Source
#	var before_src: float = float(cult_data.npcs[src].stats[stat_idx])
#	var after_src: float = clamp(before_src + strength, 0.0, 100.0)
#	cult_data.npcs[src].stats[stat_idx] = after_src
#
#	# Recipients
#	for tgt in range(count):
#		if tgt == src: continue
#		var aff01: float = clamp(_get_relationship_context(src, tgt, ev.stat), 0.0, 1.0)
#		if aff01 <= 0.0: continue
#		var delta: float = strength * aff01 * (1.0 - decay)   # <- explicitly float
#		if absf(delta) < 0.0001: continue
#		
#		var before: float = float(cult_data.npcs[tgt].stats[stat_idx])
#		var after: float = clamp(before + delta, 0.0, 100.0)
#		cult_data.npcs[tgt].stats[stat_idx] = after
#		# After the stat change, update relationships based on experience
#		var rel_delta = abs(delta) * 0.1  # Small relationship changes
#		if delta > 0: rel_delta *= 1.0    # Positive effects help relationships
#		else: rel_delta *= -0.3           # Negative effects hurt less
#
#		_apply_relationship_delta(tgt, src, rel_delta)  # Target's opinion of source changes
#
#
#	emit_signal("state_changed", "stat_cascade", [src])
#
#
#func spread_belief(ev: GameEvent) -> void:
#	var start := ev.source_npc
#	if start < 0: return
#	var piety_idx: int = GameDefs.STAT.PIETY
#	for i in cult_data.relationship_matrix.size():
#		if i == start: continue
#		var w := cult_data.relationship_matrix[start][i]
#		if w > 70.0:
#			# Increase Piety by a small amount, scaled to relationship weight (e.g., 1% of w)
#			var delta: float = w * 0.01
#			var before: float = cult_data.npcs[i].stats[piety_idx]
#			var after: float = clamp(before + delta, 0.0, 100.0)
#			cult_data.npcs[i].stats[piety_idx] = after
#	# Optionally emit an updated signal or update cached queries
#	emit_signal("state_changed", "spread_piety", [start])
#
## Cached queries -------------------------------------------------------------
#	##These rebuild expensive-to-compute social data structures (like social clusters) so they don't need to be 
#	### recalculated every time they're accessed. It's a performance optimization that trades memory for speed.
#	### store results in cult_data.social_clusters. Instead of recalculating "which NPCs form tight social groups" 
#	### every time you need it, you calculate once and cache the result. It's updated when relationships change significantly
#
#func _update_cached_queries() -> void:
#	_build_social_clusters()
#	# believers_by_family etc. could be added here when family ids exist.
#
#func _build_social_clusters() -> void:
#	cult_data.social_clusters.clear()
#	var m: Array[PackedFloat32Array] = cult_data.relationship_matrix
#	var n: int = m.size()
#	var assigned: PackedInt32Array = PackedInt32Array()
#	assigned.resize(n)
#
#	for i in range(n):
#		if assigned[i] == 1:
#			continue
#		var cluster: Array[int] = []
#		var queue: Array[int] = [i]
#		assigned[i] = 1
#		while not queue.is_empty():
#			var u: int = queue.pop_back()
#			cluster.append(u)
#			for v in range(n):
#				if v == u or assigned[v] == 1:
#					continue
#				var uv: float = float(m[u][v])
#				var vu: float = float(m[v][u])
#				if uv > CLUSTER_AFFINITY_THRESHOLD and vu > CLUSTER_AFFINITY_THRESHOLD:
#					assigned[v] = 1
#					queue.append(v)
#		if cluster.size() > 1:
#			cult_data.social_clusters.append(cluster)
