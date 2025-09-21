extends Node
class_name EventLog_class

signal event_recorded(ev: GameEvent)

var events: Array[GameEvent] = []
var _by_id: Dictionary = {}   # id -> GameEvent

func record(ev: GameEvent) -> GameEvent:
	events.append(ev)
	_by_id[ev.id] = ev
	event_recorded.emit(ev)
	return ev

func get_event(id: int) -> GameEvent:
	return _by_id.get(id, null)

func clear() -> void:
	events.clear()
	_by_id.clear()

## Append-only list of events in chronological order
#var _events: Array[GameEvent] = []
## Indices for fast lookup
#var _by_id: Dictionary = {}            # id -> GameEvent
#var _by_npc: Dictionary = {}           # npc_id -> Array[int] (event ids)
#var _by_action: Dictionary = {}        # action:string -> Array[int]
#var _by_stat: Dictionary = {}          # stat:string -> Array[int]
#
#func _ready() -> void:
#	# Optionally load persisted log here
#	pass
#
#func clear() -> void:
#	_events.clear()
#	_by_id.clear()
#	_by_npc.clear()
#	_by_action.clear()
#	_by_stat.clear()
#
#func append(ev: GameEvent) -> void:
#	# Ensure timestamp present
#	if ev.t <= 0:
#		ev.t = Time.get_ticks_msec()
#
#	_events.append(ev)
#	_by_id[ev.id] = ev
#
#	# index by participants
#	_index_npc(ev.source_npc, ev.id)
#	_index_npc(ev.target_npc, ev.id)
#
#	# index by action/stat
#	var act := String(ev.action)
#	if act != "":
#		if not _by_action.has(act):
#			_by_action[act] = []
#		_by_action[act].append(ev.id)
#	var st := String(ev.stat)
#	if st != "":
#		if not _by_stat.has(st):
#			_by_stat[st] = []
#		_by_stat[st].append(ev.id)
#
#func _index_npc(npc_id: int, eid: int) -> void:
#	if npc_id < 0:
#		return
#	if not _by_npc.has(npc_id):
#		_by_npc[npc_id] = []
#	_by_npc[npc_id].append(eid)
#
#func get_event(id: int) -> GameEvent:
#	return _by_id.get(id, null)
#
#func get_all() -> Array[GameEvent]:
#	return _events
#
#func get_events_for_npc(npc_id: int, limit: int = -1) -> Array[GameEvent]:
#	var ids: Array = _by_npc.get(npc_id, [])
#	var result: Array[GameEvent] = []
#	var start := 0
#	if limit > 0 and ids.size() > limit:
#		start = ids.size() - limit
#	for i in range(start, ids.size()):
#		var eid: int = int(ids[i])
#		var ev: GameEvent = _by_id.get(eid, null)
#		if ev:
#			result.append(ev)
#	return result
#
#func get_ids_for_npc(npc_id: int, limit: int = -1) -> Array[int]:
#	var ids: Array = _by_npc.get(npc_id, [])
#	if limit > 0 and ids.size() > limit:
#		return ids.slice(ids.size() - limit, ids.size())
#	return ids.duplicate()
#
## Simple persistence as JSONL (one event per line)
#func save_jsonl(path: String = "user://event_log.jsonl") -> void:
#	var f := FileAccess.open(path, FileAccess.WRITE)
#	if f == null:
#		push_error("EventLog: failed to open " + path + " for writing")
#		return
#	for ev in _events:
#		f.store_line(JSON.stringify(ev.to_dict()))
#	f.close()
#
#func load_jsonl(path: String = "user://event_log.jsonl") -> bool:
#	if not FileAccess.file_exists(path):
#		return false
#	clear()
#	var f := FileAccess.open(path, FileAccess.READ)
#	if f == null:
#		return false
#	while not f.eof_reached():
#		var line := f.get_line()
#		if line.strip_edges() == "":
#			continue
#		var parsed := JSON.parse_string(line)
#		if typeof(parsed) == TYPE_DICTIONARY:
#			var ev := GameEvent.new()._apply(parsed)
#			append(ev)
#	f.close()
#	return true
