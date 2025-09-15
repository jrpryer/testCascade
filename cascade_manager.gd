extends Node
class_name CascadeSystem

@export var cult_manager: CultManager
var cascades_queue: Array[GameEvent] = []

func queue_stat_cascade(stat_type: String, source: int, strength: float, decay: float = 0.5, target: int = -1) -> void:
	var eid: int = IdGen.next_event_id()
	var newStats: GameEvent = GameEvent.make(eid, &"stat_cascade", stat_type, source, target, strength, decay)
	cascades_queue.append(newStats)

# ToDo: Make more cascade handlers

func process_all(max_iterations: int = 100) -> void:
	var i := 0
	while i < max_iterations and cascades_queue.size() > 0:
		var ev: GameEvent = cascades_queue.pop_front()
		_execute(ev)
		i += 1

func _execute(ev: GameEvent) -> void:
	match ev.action:
		"stat_cascade":
			cult_manager.spread_stat(ev)
		"belief_cascade":
			cult_manager.spread_belief(ev)
		_:
			push_warning("Unknown cascade action: %s" % ev.action)
