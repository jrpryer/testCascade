# res://systems/det_rng.gd
## How To Use: ##
## at boot (e.g., in test_runner or main) ##
#DetRng.init(123456)  # your world seed
#

## anywhere
#var pick := DetRng.choice(&"story", [&"blood_for_blood", &"love_blessing", &"kidnap"])
#var temp  := 15.0 + DetRng.randf(&"weather") * 10.0
#var roll  := DetRng.randi_range(&"plague", 0, 99)


extends Node
class_name DetRng_type

var world_seed: int = 0
var _streams: Dictionary = {}  # name:StringName -> RandomNumberGenerator

func init(seed: int) -> void:
	world_seed = seed
	_streams.clear()

func _derive_seed(name: StringName) -> int:
	# Derive a per-stream seed from (world_seed, name) via SHA-256 → first 8 bytes
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var data := PackedByteArray()
	data.append_array(str(world_seed).to_utf8_buffer())
	data.append_array(String(name).to_utf8_buffer())
	ctx.update(data)
	var digest := ctx.finish()  # PackedByteArray (32 bytes)
	var s := 0
	for i in 8:
		s = (s << 8) | int(digest[i])
	return int(s)

func get_stream(name: StringName) -> RandomNumberGenerator:
	if not _streams.has(name):
		var rng := RandomNumberGenerator.new()
		rng.seed = _derive_seed(name)
		_streams[name] = rng
	return _streams[name]

# Sugar (Godot 4.4 — no generic function params)
func randf(name: StringName) -> float: return get_stream(name).randf()

func randi(name: StringName) -> int: return get_stream(name).randi()

func randi_range(name: StringName, a: int, b: int) -> int: return get_stream(name).randi_range(a, b)

func choice_int(name: StringName, arr: Array[int]) -> int:
	return arr[get_stream(name).randi_range(0, arr.size() - 1)] if not arr.is_empty() else 0

func choice_sn(name: StringName, arr: Array[StringName]) -> StringName:
	return arr[get_stream(name).randi_range(0, arr.size() - 1)] if not arr.is_empty() else StringName("")



# Save/Load exact mid-stream state (optional, for perfect resume)
func export_state() -> Dictionary:
	var out := {}
	for k in _streams.keys():
		var rng: RandomNumberGenerator = _streams[k]
		out[String(k)] = {"seed": rng.seed, "state": rng.state}
	return {"world_seed": world_seed, "streams": out}

func import_state(d: Dictionary) -> void:
	world_seed = int(d.get("world_seed", 0))
	_streams.clear()
	for k in d.get("streams", {}).keys():
		var info: Dictionary = d["streams"][k]
		var rng := RandomNumberGenerator.new()
		rng.seed = int(info.get("seed", 0))
		if info.has("state"):
			rng.state = int(info["state"])
		_streams[StringName(k)] = rng

func key(parts: Array) -> StringName:
	if parts.is_empty():
		return StringName("")
	var sb := str(str(parts[0]))
	for i in range(1, parts.size()):
		sb += ":" + str(parts[i])
	return StringName(sb)

func local_rng(parts: Array) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _derive_seed(key(parts))  # same _derive_seed as before
	return rng

func choice_from(name: StringName, arr: Array) -> Variant:
	return arr[get_stream(name).randi_range(0, arr.size()-1)]

#Two pitfalls to avoid:
#Never key by array index if that index can change; always key by stable IDs (npc.id) or absolute coords (x,y).
#Use DetRng.key([...]) only for initialization / worldgen. For runtime randomness (e.g., chance to convert during a beat), use persistent stream names like &"story" or &"ai": DetRng.randf(&"story"). That keeps worldgen unaffected by later draws.
