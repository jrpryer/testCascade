extends Node
class_name WorldGen

@export var biome: int = 0                        # BIOME enum value
@export var resource_kind: StringName = &""       # e.g., &"oasis"
@export var resource_spots: Array[Vector2i] = []  # deterministic placements

# 1) Pick exactly one biome using a deterministic key
static func pick_biome(region: StringName) -> int:
	var k := DetRng.key([&"worldgen", &"biome", region])
	var r: float = DetRng.randf(k)
	if r < 0.25:
		return GameDefs.BIOME.DESERT
	elif r < 0.50:
		return GameDefs.BIOME.PLAINS
	elif r < 0.75:
		return GameDefs.BIOME.MOUNTAIN
	else:
		return GameDefs.BIOME.FOREST

# 2) Get the unique resource for that biome
static func resource_for_biome(r_biome: int) -> StringName:
	return GameDefs.BIOME_RESOURCE.get(r_biome, &"")

# 3A) Deterministic sampling of N distinct spots (primary approach)
static func allocate_resource_spots(resource: StringName, width: int, height: int, count: int) -> Array[Vector2i]:
	var spots: Array[Vector2i] = []
	var used := {}
	# Base key isolates this allocation from other streams
	var base_key := DetRng.key([&"worldgen", &"resource_alloc", resource])
	var tries: int = 0
	while spots.size() < count and tries < count * 10:
		# Derive a per-spot subkey so order/loop calls don’t matter
		var k := DetRng.key([base_key, &"spot", spots.size()])
		var x := DetRng.randi_range(k, 0, width - 1)
		var y := DetRng.randi_range(k, 0, height - 1)
		var key := str(x, ":", y)
		if not used.has(key):
			used[key] = true
			spots.append(Vector2i(x, y))
		tries += 1
	return spots
	
# 3B) Alternative: tile-wise Bernoulli test using the user’s exact key form
#     worldgen:resource:(x):(y):(kind)

static func tile_has_resource(x: int, y: int, resource: StringName, threshold: float = 0.02) -> bool:
	var k := DetRng.key([&"worldgen", &"resource", x, y, resource])
	return DetRng.randf(k) < threshold
