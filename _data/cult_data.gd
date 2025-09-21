extends Resource
class_name CultData

@export var npcs: Array[NPCData] = []
@export var relationship_matrix: Array[PackedFloat32Array] = []  # NPC_CAPACITY x NPC_CAPACITY
@export var community_roles: PackedInt32Array = []

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
	# TODO: Family surnames will have to be inferred from relationship matrix 
	var names: Array[StringName] = [
		&"Frodo",&"Samwise",&"Gandalf",&"Aragorn",&"Legolas",&"Gimli",
		&"Boromir",&"Merry",&"Pippin",&"Éowyn",&"Faramir",&"Galadriel",
	]
	var roles: Array[StringName] = [&"apostle",&"priest",&"worker",&"builder",&"unbeliever"]
	var start := npcs.size()
	npcs.resize(count)
	for i in range(start, count):
		var npc := NPCData.new()
		npc.id = IdGen.next_id(&"npc")
		npc.ensure_sizes()
		npc.stats.fill(0.0)

		# Deterministic name
		var k_name := DetRng.key([&"npc", npc.id, &"name", &"lotr"])
		npc.display_name = String(DetRng.choice_from(k_name, names))  # add display_name field if you don’t have one

		# Deterministic role
		# TODO: Wipe this in future? All NPCs but 1 will start as unbelievers 
		var k_role := DetRng.key([&"npc", npc.id, &"role"])
		var newRole: StringName =  StringName(DetRng.choice_from(k_role, roles))      # add role field on NPCData
		npc.role = GameDefs.ROLE_INDEX_SN[newRole]

		# Deterministic initial stats (0..100)
		for s in range(GameDefs.STAT_COUNT):
			var stat_sn := GameDefs.stat_name(s)                  # &"fortune", etc.
			var k_stat :=  DetRng.key([&"npc", npc.id, &"stat", stat_sn])
			npc.stats[s] = floor(lerp(20.0, 80.0, DetRng.randf(k_stat)))

		npcs[i] = npc

func get_relationship_tier(a: int, b: int) -> String:
	var rel: float = relationship_matrix[a][b]
	if rel >= 80: return "devoted"
	elif rel >= 60: return "loyal"
	elif rel >= 40: return "neutral"
	elif rel >= 20: return "distant"
	else: return "hostile"

func find_social_tensions() -> Array[Dictionary]:
	var tensions: Array[Variant] = []
	for i in range(npcs.size()):
		for j in range(i + 1, npcs.size()):
			var rel_ij: float = relationship_matrix[i][j]
			var rel_ji: float = relationship_matrix[j][i]

			# Asymmetric relationships create tension
			if abs(rel_ij - rel_ji) > 30:
				tensions.append({
					"npcs": [i, j],
					"asymmetry": abs(rel_ij - rel_ji),
					"dynamic": "unrequited" if rel_ij > rel_ji else "dismissive"
				})
	return tensions
