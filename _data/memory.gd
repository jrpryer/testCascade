# memory.gd
extends Resource
class_name MemoryNote

@export var t: int = 0
@export var event_id: int = -1
@export var note: String = ""  # optional per-NPC annotation

static func from_event(ev: GameEvent) -> MemoryNote:
	var m := MemoryNote.new()
	m.t = ev.timestamp_ms
	m.event_id = ev.id
	return m

func resolve_event() -> GameEvent:
	return EventLog.get_event(event_id)

func to_pretty_string(name_of: Callable) -> String:
	var ev := resolve_event()
	return format_event(ev, name_of) if ev != null else "Missing event #%d" % [event_id]

func _to_string() -> String:
	return "MemoryNote(id=%d, t=%d, note=%s)" % [event_id, t, note]

func format_event(ev: GameEvent, name_of: Callable) -> String:
	if ev == null: return "<missing event>"
	var meta_text: String = "{}"
	if not ev.metadata.is_empty():
		meta_text = JSON.stringify(ev.metadata)

	var src: String = "N/A"
	if name_of.is_valid():
		src = String(name_of.call(int(ev.source_npc)))

	var line: String = "Action: %s, Meta: %s, Strength: %.2f, Decay: %.2f, Source: %s" % [
	str(ev.action), meta_text, float(ev.strength), float(ev.decay_rate), src
	]

	if ev.target_npc >= 0 and name_of.is_valid():
		line += ", Target: %s" % [String(name_of.call(int(ev.target_npc)))]
	if ev.chain_id >= 0:
		line += ", Chain: %d" % [int(ev.chain_id)]
	if ev.parent_id >= 0:
		line += ", Parent: %d" % [int(ev.parent_id)]
	return line
