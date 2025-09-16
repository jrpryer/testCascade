extends Resource
class_name CultData

@export var npcs: Array[NPCData] = []
@export var relationship_matrix: Array[PackedFloat32Array] = []  # NPC_CAPACITY x NPC_CAPACITY
@export var community_roles: PackedInt32Array = []                 # enum CommunityRole
#@export var stats_matrix: Array[PackedFloat32Array] = []         # NPC_CAPACITY x STAT_COUNT

# Cached queries
#var believers_by_family: Dictionary = {}  # family_id -> Array[npc_id]
var social_clusters: Array[Array] = []
var narrative_candidates: Dictionary = {}

func _init() -> void:
	var n := GameDefs.NPC_CAPACITY
	relationship_matrix.resize(n)
	for i in range(n):
		relationship_matrix[i] = PackedFloat32Array()
		relationship_matrix[i].resize(n)
		relationship_matrix[i].fill(0.0)

	community_roles.resize(n)

	#stats_matrix.resize(n)
	#for i in n:
		#stats_matrix[i] = PackedFloat32Array()
		#stats_matrix[i].resize(GameDefs.STAT_COUNT)

#func ensure_npcs(count: int) -> void:
	#if npcs.size() < count:
		#var start := npcs.size()
		#npcs.resize(count)
		#for i in range(start, count):
			#var npc := NPCData.new()
			#npc.id = IdGen.next_npc_id()
			#npc.ensure_sizes()
			#npc.stats.fill(0.0)
			#npcs[i] = npc

func ensure_npcs(count: int) -> void:
	if npcs.size() >= count: return
	var names: Array[StringName] = [
		&"Frodo",&"Samwise",&"Gandalf",&"Aragorn",&"Legolas",&"Gimli",
		&"Boromir",&"Merry",&"Pippin",&"Éowyn",&"Faramir",&"Galadriel",
	]
	var roles: Array[StringName] = [&"apostle",&"priest",&"worker",&"builder"]
	var start := npcs.size()
	npcs.resize(count)
	for i in range(start, count):
		var npc := NPCData.new()
		npc.id = IdGen.next_npc_id()
		npc.ensure_sizes()
		npc.stats.fill(0.0)

		# Deterministic name
		var k_name := DetRng.key([&"npc", npc.id, &"name", &"lotr"])
		npc.display_name = String(DetRng.choice_from(k_name, names))  # add display_name field if you don’t have one

		# Deterministic role
		var k_role := DetRng.key([&"npc", npc.id, &"role"])
		npc.role = StringName(DetRng.choice_from(k_role, roles))      # add role field on NPCData

		# Deterministic initial stats (0..100)
		for s in range(GameDefs.STAT_COUNT):
			var stat_sn := GameDefs.stat_name(s)                  # &"fortune", etc.
			var k_stat := DetRng.key([&"npc", npc.id, &"stat", stat_sn])
			npc.stats[s] = floor(lerp(20.0, 80.0, DetRng.randf(k_stat)))

		npcs[i] = npc


## Copy matrix → per-NPC (use after you seed stats_matrix)
#func sync_npcs_from_matrix() -> void:
	#var n : int = min(int(npcs.size()), int(stats_matrix.size()))
	#for i in range(n):
		#var row := stats_matrix[i]
		#if row.size() == GameDefs.STAT_COUNT:
			#npcs[i].ensure_sizes()
			#for s in range(GameDefs.STAT_COUNT):
				#npcs[i].stats[s] = row[s]

# Copy per-NPC → matrix (if you prefer NPCData as source of truth)
#func sync_matrix_from_npcs() -> void:
	#var n : int = min(int(npcs.size()), int(stats_matrix.size()))
	#for i in range(n):
		#var row := stats_matrix[i]
		#if row.size() == GameDefs.STAT_COUNT:
			#for s in range(GameDefs.STAT_COUNT):
				#row[s] = npcs[i].stats[s]
