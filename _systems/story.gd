# res://systems/story.gd
extends Node
class_name StorySystem

@export var cascade: CascadeSystem
@export var cult: CultManager

var started: bool = false
var inciting: StringName = &""

func _ready() -> void:
	assert(cascade != null)
	assert(cult != null)

# -- Public API ---------------------------------------------------------------

func start_new_story() -> void:
	if started:
		return
	inciting = _pick_inciting()
	_fire_inciting(inciting)
	started = true

# Optional: quick smoke test for your runner
func debug_sanity() -> void:
	start_new_story()
	cascade.process(32)

# -- Core ---------------------------------------------------------------------

func _pick_inciting() -> StringName:
	var key: StringName = DetRng.key([&"story", &"inciting"])
	var options: Array[StringName] = [
						  &"eclipse_omen", &"famine", &"stranger_arrives", &"blood_tax"
						  ]
	return DetRng.choice_sn(key, options)  # returns an element from options
	

func _fire_inciting(kind: StringName) -> void:
	var src: int = _pick_source_id()  # minimalist; extend later when roles exist
	if kind == &"famine":
		# Raise anger via relationship-weighted cascade
		cascade.enqueue_stat_cascade(&"anger", src, 12.0, 0.30, {"min_affinity": 40.0})
	elif kind == &"eclipse_omen":
		# Raise piety
		cascade.enqueue_stat_cascade(&"piety", src, 15.0, 0.20, {"min_affinity": 30.0})
	elif kind == &"blood_tax":
		# Reduce loyalty
		cascade.enqueue_stat_cascade(&"loyalty", src, -10.0, 0.40, {"min_affinity": 50.0})
	elif kind == &"stranger_arrives":
		# Single target fortune bump
		var tgt: int = _pick_random_npc_id(&"story:target")
		if tgt >= 0:
			cascade.enqueue_stat_delta(&"fortune", tgt, 10.0, {"reason": "stranger"})
	else:
		# Safe default
		cascade.enqueue_stat_delta(&"fortune", src, 5.0, {"reason": "default_inciting"})

# -- Tiny helpers -------------------------------------------------------------

func _pick_source_id() -> int:
	var n: int = cult.get_npc_count()
	if n <= 0:
		return -1
	# Minimal: choose NPC 0 as the “narrative source.” Replace when roles/leader exist.
	return 0

func _pick_random_npc_id(stream_key: StringName) -> int:
	var n: int = cult.get_npc_count()
	if n <= 0:
		return -1
	return DetRng.randi_range(stream_key, 0, n - 1)


	#extends Node
#class_name StorySystem
#
#signal story_moment_detected(moment_type: String, participants: Array[int], context: Dictionary, options: Array)
#signal pattern_recognized(pattern_name: String, severity: float, npcs_involved: Array[int])
#
#@export var cult_data: CultData
#@export var enable_pattern_detection: bool = true
#@export var moment_detection_threshold: float = 0.6  # How dramatic an event must be to generate a story moment
#
## Pattern tracking
#var _relationship_history: Dictionary = {}  # [npc_a][npc_b] -> Array of recent values
#var _event_chains: Dictionary = {}          # chain_id -> Array[event_id]
#var _recent_betrayals: Array[Dictionary] = []
#var _faction_tensions: Dictionary = {}
#
## Moment detectors (modular system)
#var _moment_detectors: Dictionary = {}
#
#func _ready() -> void:
#	assert(cult_data != null, "StorySystem requires cult_data")
#	
#	if not EventLog.event_recorded.is_connected(_analyze_event_for_drama):
#		EventLog.event_recorded.connect(_analyze_event_for_drama)
#	
#	_initialize_detectors()
#
#func _initialize_detectors() -> void:
#	# Register built-in moment detectors
#	register_moment_detector("betrayal", _detect_betrayal)
#	register_moment_detector("faction_split", _detect_faction_split)
#	register_moment_detector("power_shift", _detect_power_shift)
#	register_moment_detector("cascade_chain", _detect_cascade_chain)
#	register_moment_detector("social_collapse", _detect_social_collapse)
#
#func register_moment_detector(_name: String, detector_func: Callable) -> void:
#	#"""Allow external systems to add custom drama detection"""
#	_moment_detectors[_name] = detector_func
#
#func _analyze_event_for_drama(ev: GameEvent) -> void:
#	if not enable_pattern_detection:
#		return
#	
#	_update_relationship_history(ev)
#	_track_event_chains(ev)
#	
#	# Run all registered detectors
#	for detector_name in _moment_detectors:
#		var detector_func: Callable = _moment_detectors[detector_name]
#		var moment_data: Dictionary = detector_func.call(ev)
#		
#		if moment_data.size() > 0:
#			_process_detected_moment(detector_name, moment_data, ev)
#
#func _update_relationship_history(ev: GameEvent) -> void:
#	#"""Track relationship changes over time for pattern recognition"""
#	if ev.source_npc < 0 or ev.target_npc < 0:
#		return
#	
#	var src: int = ev.source_npc
#	var tgt: int = ev.target_npc
#	
#	# Initialize history tracking
#	if not _relationship_history.has(src):
#		_relationship_history[src] = {}
#	if not _relationship_history[src].has(tgt):
#		_relationship_history[src][tgt] = []
#	
#	# Store current relationship value with timestamp
#	var current_rel: float = cult_data.relationship_matrix[src][tgt]
#	var history_entry: Dictionary = {
#		"value": current_rel,
#		"time": ev.timestamp_ms,
#		"event_id": ev.id
#	}
#	
#	_relationship_history[src][tgt].append(history_entry)
#	
#	# Keep only recent history (last 10 entries)
#	if _relationship_history[src][tgt].size() > 10:
#		_relationship_history[src][tgt] = _relationship_history[src][tgt].slice(-10)
#
#func _track_event_chains(ev: GameEvent) -> void:
#	#"""Group related events into narrative chains"""
#	# Auto-assign chain_id based on rapid succession of related events
#	var chain_id: int = ev.chain_id
#	
#	if chain_id < 0:
#		# Look for recent events involving same NPCs
#		var recent_events: Array[Variant] = _get_recent_events_involving([ev.source_npc, ev.target_npc], 5000) # 5 second window
#		if recent_events.size() > 0:
#			# Continue existing chain
#			var last_event: GameEvent = recent_events[-1]
#			if last_event.has_chain():
#				chain_id = last_event.chain_id
#		else:
#			# Start new chain
#			chain_id = IdGen.next_id(&"chain")
#			ev.chain_id = chain_id
#	
#	if not _event_chains.has(chain_id):
#		_event_chains[chain_id] = []
#	_event_chains[chain_id].append(ev.id)
#
#func _get_recent_events_involving(npc_ids: Array, time_window_ms: int) -> Array[int]:
#	#"""Get events involving specified NPCs within time window"""
#	var recent : Array[int] = []
#	var cutoff_time: int = Time.get_ticks_msec() - time_window_ms
#	
#	if EventLog.events.size() != 0:
#		for event in EventLog.events:
#			if event.timestamp_ms < cutoff_time:
#				continue
#			if event.source_npc in npc_ids or event.target_npc in npc_ids:
#				recent.append(event)
#	return recent
#
## MOMENT DETECTORS ============================================================
#
#func _detect_betrayal(ev: GameEvent) -> Dictionary:
#	#""Detect when a trusted relationship turns sour dramatically"""
#	if ev.source_npc < 0 or ev.target_npc < 0:
#		return {}
#	
#	var src: int = ev.source_npc
#	var tgt: int = ev.target_npc
#	
#	# Need relationship history to detect betrayal
#	if not _relationship_history.has(src) or not _relationship_history[src].has(tgt):
#		return {}
#	
#	var history = _relationship_history[src][tgt]
#	if history.size() < 3:
#		return {}
#	
#	# Look for dramatic relationship drop after high trust
#	var current_rel = history[-1].value
#	var previous_rel = history[-2].value
#	var peak_rel: float = 0.0
#	
#	for entry in history.slice(0, -1):
#		peak_rel = max(peak_rel, entry.value)
#	
#	# Betrayal criteria: was high trust (>70), now significant drop (>30 points)
#	var trust_drop: int = previous_rel - current_rel
#	var was_high_trust: bool   = peak_rel > 70.0
#	var significant_drop: bool = trust_drop > 30.0
#	
#	if was_high_trust and significant_drop:
#		var witnesses: Array[int] = _get_witnesses_for_event(ev)
#		var severity = min(trust_drop / 50.0, 1.0)  # Normalize to 0-1
#		
#		return {
#			"betrayer": src,
#			"victim": tgt,
#			"severity": severity,
#			"trust_lost": trust_drop,
#			"peak_trust": peak_rel,
#			"witnesses": witnesses,
#			"is_public": witnesses.size() > 2
#		}
#	
#	return {}
#
#func _detect_faction_split(ev: GameEvent) -> Dictionary:
#	#"""Detect when social clusters are breaking apart"""
#	var moment_data: Dictionary = {}
#	
#	# Check if this event caused a cluster to split
#	var pre_split_clusters: Array = cult_data.social_clusters.duplicate()
#	# Clusters get rebuilt in cult_manager after relationship changes
#	
#	# Compare cluster membership before/after
#	for old_cluster in pre_split_clusters:
#		if old_cluster.size() < 3:
#			continue
#		
#		var still_together: Array[Variant] = []
#		var broken_away: Array[Variant]    = []
#		
#		# Check which members are still in same cluster
#		for new_cluster in cult_data.social_clusters:
#			var overlap: Array = _array_intersection(old_cluster, new_cluster)
#			if overlap.size() > still_together.size():
#				still_together = overlap
#		
#		broken_away = _array_difference(old_cluster, still_together)
#		
#		if broken_away.size() >= 2 and still_together.size() >= 2:
#			moment_data = {
#				"original_cluster": old_cluster,
#				"remaining_faction": still_together,
#				"split_faction": broken_away,
#				"catalyst_event": ev.id,
#				"severity": float(broken_away.size()) / float(old_cluster.size())
#			}
#			break
#	
#	return moment_data
#
#func _detect_power_shift(ev: GameEvent) -> Dictionary:
#	#"""Detect when influence/power dynamics change significantly"""
#	if GameDefs.action_name(ev.action) != &"stat_cascade":
#		return {}
#	
#	var affected_stat: String = String(ev.stat)
#	if affected_stat not in ["influence", "charisma", "piety"]:
#		return {}
#	
#	# Check for major stat changes in key NPCs
#	var power_changes: Array[Dictionary] = []
#	var stat_idx: int = GameDefs.stat_index(ev.stat)
#	
#	for i in cult_data.npcs.size():
#		var npc: NPCData = cult_data.npcs[i]
#		var current_stat: float = npc.stats[stat_idx]
#		
#		# Look for NPCs who crossed power thresholds (25, 50, 75)
#		var recent_memories = npc.get_memory_ids(5)
#		for mem_id in recent_memories:
#			var mem_ev = EventLog.get_event(mem_id)
#			if mem_ev and mem_ev.stat == ev.stat:
#				var old_tier :int = int(current_stat - ev.strength) / 25
#				var new_tier: int = int(current_stat) / 25
#				
#				if old_tier != new_tier:
#					power_changes.append({
#						"npc": i,
#						"old_tier": old_tier,
#						"new_tier": new_tier,
#						"stat": affected_stat
#					})
#	
#	if power_changes.size() > 0:
#		return {
#			"power_changes": power_changes,
#			"catalyst": ev.source_npc,
#			"stat_affected": affected_stat
#		}
#	
#	return {}
#
#func _detect_cascade_chain(ev: GameEvent) -> Dictionary:
#	#"""Detect when cascading events create major ripple effects"""
#	var chain_id = ev.metadata.get("chain_id", -1)
#	if chain_id < 0:
#		return {}
#	
#	var chain_events = _event_chains.get(chain_id, [])
#	if chain_events.size() < 4:  # Need significant chain
#		return {}
#	
#	# Analyze chain for escalation
#	var involved_npcs = {}
#	var stat_changes = {}
#	var escalation_score = 0.0
#	
#	for event_id in chain_events:
#		var chain_ev = EventLog.get_event(event_id)
#		if not chain_ev:
#			continue
#		
#		involved_npcs[chain_ev.source_npc] = true
#		involved_npcs[chain_ev.target_npc] = true
#		
#		var stat_key = String(chain_ev.stat)
#		if not stat_changes.has(stat_key):
#			stat_changes[stat_key] = 0.0
#		stat_changes[stat_key] += abs(chain_ev.strength)
#		
#		escalation_score += chain_ev.strength * chain_events.find(event_id) # Later events weighted higher
#	
#	if escalation_score > 100.0 and involved_npcs.size() >= 3:
#		return {
#			"chain_id": chain_id,
#			"events_count": chain_events.size(),
#			"npcs_affected": involved_npcs.keys(),
#			"escalation_score": escalation_score,
#			"dominant_stats": stat_changes
#		}
#	
#	return {}
#
#func _detect_social_collapse(ev: GameEvent) -> Dictionary:
#	#"""Detect when social fabric is breaking down"""
#	# Check overall relationship health
#	var total_relationships = 0
#	var negative_relationships = 0
#	var average_relationship = 0.0
#	
#	var n = cult_data.npcs.size()
#	for i in range(n):
#		for j in range(i + 1, n):
#			var rel_ij = cult_data.relationship_matrix[i][j]
#			var rel_ji = cult_data.relationship_matrix[j][i]
#			var avg_rel = (rel_ij + rel_ji) / 2.0
#			
#			total_relationships += 1
#			average_relationship += avg_rel
#			
#			if avg_rel < 25.0:  # Consider <25 as negative
#				negative_relationships += 1
#	
#	average_relationship /= total_relationships
#	var negative_ratio = float(negative_relationships) / float(total_relationships)
#	
#	# Social collapse if >60% relationships are negative and average is low
#	if negative_ratio > 0.6 and average_relationship < 30.0:
#		return {
#			"average_relationship": average_relationship,
#			"negative_ratio": negative_ratio,
#			"total_npcs": n,
#			"trigger_event": ev.id
#		}
#	
#	return {}
#
## MOMENT PROCESSING ===========================================================
#
#func _process_detected_moment(detector_name: String, moment_data: Dictionary, trigger_event: GameEvent) -> void:
#	#"""Process a detected story moment and generate player options"""
#	var severity = moment_data.get("severity", 0.5)
#	
#	if severity < moment_detection_threshold:
#		return
#	
#	# Generate contextual player options
#	var options = _generate_player_options(detector_name, moment_data, trigger_event)
#	
#	# Get all involved NPCs
#	var participants = _extract_participants(moment_data)
#	
#	# Add temporal context
#	var context = moment_data.duplicate()
#	context["trigger_event"] = trigger_event.id
#	context["detection_time"] = Time.get_ticks_msec()
#	context["season"] = _get_current_season()  # If you have seasons
#	
#	# Emit signals
#	emit_signal("pattern_recognized", detector_name, severity, participants)
#	emit_signal("story_moment_detected", detector_name, participants, context, options)
#
#func _generate_player_options(moment_type: String, data: Dictionary, ev: GameEvent) -> Array:
#	#"""Generate contextual player response options for story moments"""
#	var options = []
#	
#	match moment_type:
#		"betrayal":
#			options = [
#				{
#					"id": "mediate",
#					"text": "Send a trusted mediator to heal the rift",
#					"cost": {"influence": 15},
#					"success_chance": 0.7,
#					"outcomes": ["relationship_restored", "mediator_gains_trust"]
#				},
#				{
#					"id": "punish_betrayer", 
#					"text": "Make an example of the betrayer",
#					"cost": {"piety": 10},
#					"risk": 0.4,
#					"outcomes": ["order_restored", "fear_increased", "potential_martyrdom"]
#				},
#				{
#					"id": "exploit_division",
#					"text": "Use this division to consolidate power",
#					"requirement": {"stat": "cunning", "value": 50},
#					"outcomes": ["power_gained", "trust_decreased"]
#				},
#				{
#					"id": "let_resolve",
#					"text": "Allow them to work it out naturally",
#					"time_cost": 10,
#					"outcomes": ["unpredictable", "authentic_resolution"]
#				}
#			]
#		
#		"faction_split":
#			options = [
#				{
#					"id": "reunification_ritual",
#					"text": "Hold a grand reunification ceremony",
#					"cost": {"resources": 25, "piety": 20},
#					"outcomes": ["factions_merged", "ceremony_bonus"]
#				},
#				{
#					"id": "choose_side",
#					"text": "Openly support one faction over the other",
#					"outcomes": ["chosen_faction_empowered", "other_faction_resentful"]
#				},
#				{
#					"id": "balanced_approach",
#					"text": "Maintain neutrality and balance both sides",
#					"difficulty": "high",
#					"outcomes": ["delicate_balance", "continued_tension"]
#				}
#			]
#		
#		"power_shift":
#			var rising_npcs = data.get("power_changes", [])
#			options = [
#				{
#					"id": "embrace_change",
#					"text": "Publicly acknowledge the new power structure",
#					"outcomes": ["stability_restored", "old_guard_resentful"]
#				},
#				{
#					"id": "counter_shift",
#					"text": "Take action to restore previous balance",
#					"cost": {"influence": 20},
#					"outcomes": ["power_struggle", "authority_challenged"]
#				}
#			]
#	
#	return options
#
## UTILITY FUNCTIONS ===========================================================
#
#func _get_witnesses_for_event(ev: GameEvent) -> Array[int]:
#	#"""Determine which NPCs witnessed this event"""
#	var witnesses = []
#	
#	# Simple proximity-based witnessing - can be enhanced with location system
#	var participants = [ev.source_npc, ev.target_npc]
#	
#	for i in cult_data.npcs.size():
#		if i in participants:
#			continue
#		
#		# High relationship NPCs are more likely to be present/aware
#		var max_rel = 0.0
#		for participant in participants:
#			if participant >= 0:
#				max_rel = max(max_rel, cult_data.relationship_matrix[i][participant])
#		
#		if max_rel > 60.0:  # Close NPCs likely to witness
#			witnesses.append(i)
#	
#	return witnesses
#
#func _extract_participants(moment_data: Dictionary) -> Array[int]:
#	#"""Extract all NPC IDs involved in a story moment"""
#	var participants = []
#	
#	# Common participant field names
#	for field in ["betrayer", "victim", "catalyst", "source_npc", "target_npc"]:
#		if moment_data.has(field):
#			var npc_id = moment_data[field]
#			if npc_id >= 0 and npc_id not in participants:
#				participants.append(npc_id)
#	
#	# Array fields
#	for field in ["npcs_affected", "remaining_faction", "split_faction", "witnesses"]:
#		if moment_data.has(field) and moment_data[field] is Array:
#			for npc_id in moment_data[field]:
#				if npc_id >= 0 and npc_id not in participants:
#					participants.append(npc_id)
#	
#	return participants
#
#func _array_intersection(a: Array, b: Array) -> Array:
#	var result = []
#	for item in a:
#		if item in b and item not in result:
#			result.append(item)
#	return result
#
#func _array_difference(a: Array, b: Array) -> Array:
#	var result = []
#	for item in a:
#		if item not in b:
#			result.append(item)
#	return result
#
#func _get_current_season() -> String:
#	# Placeholder - implement based on your game's time system
#	return "unknown"
#
## PUBLIC API ==================================================================
#
#func get_active_story_threads() -> Array[Dictionary]:
#	#"""Get currently developing story situations"""
#	var threads = []
#	
#	# Recent betrayals still having effects
#	for betrayal in _recent_betrayals:
#		if Time.get_ticks_msec() - betrayal.get("time", 0) < 60000:  # 1 minute
#			threads.append({
#				"type": "betrayal_aftermath",
#				"data": betrayal,
#				"age_ms": Time.get_ticks_msec() - betrayal.get("time", 0)
#			})
#	
#	# Active event chains
#	for chain_id in _event_chains:
#		var events = _event_chains[chain_id]
#		if events.size() > 0:
#			var last_event = EventLog.get_event(events[-1])
#			if last_event and Time.get_ticks_msec() - last_event.timestamp_ms < 30000:  # 30 seconds
#				threads.append({
#					"type": "cascade_chain",
#					"chain_id": chain_id,
#					"events_count": events.size(),
#					"last_activity": last_event.timestamp_ms
#				})
#	
#	return threads
#
#func force_moment_detection(moment_type: String, custom_data: Dictionary = {}) -> void:
#	#"""Allow external systems to trigger story moments manually"""
#	if _moment_detectors.has(moment_type):
#		var dummy_event = GameEvent.new()
#		dummy_event.action = &"manual_trigger"
#		dummy_event.metadata = custom_data
#		
#		_process_detected_moment(moment_type, custom_data, dummy_event)
