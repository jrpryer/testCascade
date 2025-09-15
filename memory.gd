extends Resource
class_name MemoryNote

@export var t: int = 0
@export var event_id: int = -1     # NEW
@export var source_npc: int = -1
@export var target_npc: int = -1
@export var action: StringName = &""
@export var stat: StringName = &""
@export var before: float = 0.0
@export var after: float = 0.0
@export var delta: float = 0.0
@export var note: String = ""

static func from_event(ev: GameEvent, for_npc: int, before: float, after: float, note_text: String = "") -> MemoryNote:
	var m := MemoryNote.new()
	m.t = Time.get_ticks_msec()
	m.event_id = ev.id
	m.source_npc = ev.source_npc
	m.target_npc = for_npc
	m.action = ev.action
	m.stat = ev.stat
	m.before = before
	m.after = after
	m.delta = after - before
	m.note = note_text
	return m
	
func _to_string() -> String:
	return "#%d  t=%d  %s/%s  src=%d  Δ=%.1f (%.1f→%.1f)  %s" % [
		event_id, t, String(action), String(stat), source_npc, delta, before, after, note
	]
