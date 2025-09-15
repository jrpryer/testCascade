extends Resource
class_name GameEvent

@export var id: int = -1
@export var action: StringName = &""     # e.g. &"stat_cascade"
@export var stat: StringName = &""       # e.g. &"fortune"
@export var source_npc: int = -1
@export var target_npc: int = -1
@export var strength: float = 0.0        # intensity / delta
@export var decay_rate: float = 0.0      # [0..1]
@export var text: PackedStringArray = []

# Single place that knows how to assign from a payload
func _apply(d: Dictionary) -> GameEvent:
	id          = int(d.get("id", id))
	action      = StringName(d.get("action", action))
	stat        = StringName(d.get("stat", stat))
	source_npc  = int(d.get("source_npc", d.get("origin", source_npc)))
	target_npc  = int(d.get("target_npc", target_npc))
	strength    = float(d.get("strength", strength))
	decay_rate  = clampf(float(d.get("decay_rate", d.get("decay", decay_rate))), 0.0, 1.0)
	text        = PackedStringArray(d.get("text", text))
	return self

static func make(id: int, action: StringName, stat: StringName, source: int, strength: float, decay: float = 0.0, target: int = -1) -> GameEvent:
	return GameEvent.new()._apply({
		"id": id,
		"action": action,
		"stat": stat,
		"source_npc": source,
		"target_npc": target,
		"strength": strength,
		"decay_rate": decay
	})
