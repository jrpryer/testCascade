# res://systems/id_gen.gd
extends Node
class_name IdGen_type

var world_seed: int = 0
var npc_counter: int = 0
var event_counter: int = 0
var _world_tag: int = 0  # 32-bit hash of the seed

func init(seed: int) -> void:
	world_seed = seed
	npc_counter = 0
	event_counter = 0
	_world_tag = int(hash(str(seed))) & 0xFFFF_FFFF

static func _make_id(tag32: int, type8: int, counter24: int) -> int:
	# 64-bit: [ tag32 | type8 | counter24 ]
	return (int(tag32) << 32) | (int(type8 & 0xFF) << 24) | int(counter24 & 0xFFFFFF)

func next_npc_id() -> int:
	npc_counter += 1
	return _make_id(_world_tag, 1, npc_counter)

func next_event_id() -> int:
	event_counter += 1
	return _make_id(_world_tag, 2, event_counter)

# For save/load
func export_state() -> Dictionary:
	return {
		"world_seed": world_seed,
		"npc_counter": npc_counter,
		"event_counter": event_counter,
		"world_tag": _world_tag
	}

func import_state(d: Dictionary) -> void:
	world_seed   = int(d.get("world_seed", 0))
	npc_counter  = int(d.get("npc_counter", 0))
	event_counter= int(d.get("event_counter", 0))
	_world_tag   = int(d.get("world_tag", int(hash(str(world_seed))) & 0xFFFF_FFFF))
