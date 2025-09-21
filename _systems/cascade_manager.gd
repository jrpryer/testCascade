extends Node
class_name CascadeSystem

@export var cult_manager: CultManager
#@export var event_log: EventLog_class        # optional; set if you want logging here

var _q: Array[GameEvent] = []                # was cascades_queue
var _handlers: Dictionary = {}  # StringName -> Callable

func _ready() -> void:
	assert(cult_manager != null)
	register_action(&"stat_delta", _handle_stat_delta)
	register_action(&"stat_cascade", _handle_stat_cascade)
# register_action(&"famine", _handle_famine)  # example semantic action

func register_action(_name: StringName, func_ref: Callable) -> void:
	_handlers[_name] = func_ref

func has_action(_name: StringName) -> bool:
	return _handlers.has(_name)
	
# ---------------- Enqueue (called by test_runner, story, etc.) ----------------

func queue_cascade(ev: GameEvent) -> void:
	if ev.id < 0: ev.id = IdGen.next_id(&"event")
	if ev.timestamp_ms == 0: ev.timestamp_ms = Time.get_ticks_msec()
	if not has_action(ev.action):
		push_warning("Unknown action enqueued: %s" % [str(ev.action)])
		return
	_q.append(ev)
	if EventLog != null:
		EventLog.record(ev)

# Convenience helpers (MVP scope)
# Enqueue helpers: put stat into metadata for primitive ops
func enqueue_stat_delta(stat: StringName, npc_id: int, delta: float, meta: Dictionary = {}) -> void:
	meta["stat"] = stat
	var ev := GameEvent.new()
	ev.action = &"stat_delta"
	ev.source_npc = npc_id
	ev.strength = delta
	ev.metadata = meta
	queue_cascade(ev)

func enqueue_stat_cascade(stat: StringName, source_id: int, strength: float, decay: float = 0.4, meta: Dictionary = {}) -> void:
	meta["stat"] = stat
	var ev := GameEvent.new()
	ev.action = &"stat_cascade"
	ev.source_npc = source_id
	ev.strength = strength
	ev.decay_rate = clamp(decay, 0.0, 1.0)
	ev.metadata = meta
	queue_cascade(ev)

# ---------------- Processing ----------------

func process_all(max_iterations: int = 100) -> void:
	var i: int = 0
	while i < max_iterations and _q.size() > 0:
		var ev: GameEvent = _q.pop_front()
		_execute(ev)
		i += 1

func _execute(ev: GameEvent) -> void:
	var f: Callable = _handlers.get(ev.action, Callable())
	if not f.is_null():
		f.call(ev)
	else:
		push_warning("No handler for action: %s" % [str(ev.action)])

#func _act_sn(ev: GameEvent) -> StringName:
#	# Accepts StringName or enum/int; uses GameDefs.action_name(...) if needed
#	var t := typeof(ev.action)
#	if t == TYPE_STRING_NAME:
#		return ev.action
#	if t == TYPE_INT:
#		return GameDefs.action_name(int(ev.action))
#	# Fallback if someone passed a String
#	if t == TYPE_STRING:
#		return StringName(ev.action)
#	return &""

# ---------------- Handlers (MVP) ----------------
func _resolve_stat(ev: GameEvent) -> StringName:
	return StringName(ev.metadata.get("stat", &""))

# Handlers use _resolve_stat(...)
func _handle_stat_delta(ev: GameEvent) -> void:
	var stat_sn: StringName = _resolve_stat(ev)
	if stat_sn == &"": return  # no single stat applies
	var idx: int = GameDefs.stat_index(stat_sn)
	if idx < 0 or ev.source_npc < 0: return
	cult_manager.add_stat(ev.source_npc, idx, float(ev.strength), ev)

func _handle_stat_cascade(ev: GameEvent) -> void:
	var stat_sn: StringName = _resolve_stat(ev)
	if stat_sn == &"": return
	var idx: int = GameDefs.stat_index(stat_sn)
	if idx < 0 or ev.source_npc < 0: return

	var src: int = ev.source_npc
	var strength: float = float(ev.strength)
	var decay: float = clamp(float(ev.decay_rate), 0.0, 1.0)
	var min_aff: float = float(ev.metadata.get("min_affinity", 50.0))

	# source
	cult_manager.add_stat(src, idx, strength, ev)
	# spread
	var n: int = cult_manager.get_npc_count()
	for tgt in range(n):
		if tgt == src: continue
		var aff: float = cult_manager.get_affinity(src, tgt)
		if aff < min_aff: continue
		var d: float = strength * (aff / 100.0) * (1.0 - decay)
		if absf(d) < 0.0001: continue
		cult_manager.add_stat(tgt, idx, d, ev)


#extends Node
#class_name CascadeSystem
#
#@export var cult_manager: CultManager
#var cascades_queue: Array[GameEvent] = []
#
#func queue_cascade(ev) -> void:
#	cascades_queue.append(ev)
#
## ToDo: Make more cascade handlers
#
#
#func process_all(max_iterations: int = 100) -> void:
#	var i := 0
#	while i < max_iterations and cascades_queue.size() > 0:
#		var ev: GameEvent = cascades_queue.pop_front()
#		_execute(ev)
#		i += 1
#
#func _execute(ev: GameEvent) -> void:
#	match ev.action:
#		"stat_cascade":
#			cult_manager.spread_stat(ev)
#		"belief_cascade":
#			cult_manager.spread_belief(ev)
#		_:
#			push_warning("Unknown cascade action: %s" % ev.action)
