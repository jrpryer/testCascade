# res://scenes/test_runner.gd
extends Node

@onready var cm: CultManager = $CultManager
@onready var cs: CascadeSystem = $CascadeSystem
@onready var story: StorySystem = $StorySystem

func _ready() -> void:
	# 0) Deterministic bootstrap
	IdGen.init(123456)        # ← set/pipe your seed here (UI/devtool/etc.)
	DetRng.init(123456)       # ← must match IdGen for reproducible runs
	
	# 1) Build a tiny world: 4 NPCs, simple relationships & stats
	var data := _make_cult_data(4)
	_print_stats(data, "Before cascade: ")
	
	# 2) Inject dependencies
	cm.cult_data = data
	cm.cascade_system = cs
	cs.cult_manager = cm
	story.cult_data = data
	
	# 3) Observe signals
	cm.state_changed.connect(_on_state_changed)
	story.story_ready.connect(_on_story_ready)
	
	# 4) Prime some beliefs so StorySystem has something to read
	# (optional; adjust to your StorySystem logic) 
	data.belief_states[0] = GameDefs.BeliefState.BELIEVER
	data.belief_states[1] = GameDefs.BeliefState.SEEKER
		
	# 5) Queue a stat cascade from NPC 0 affecting "fortune"
	var eid: int = IdGen.next_event_id()
	var ev: GameEvent = GameEvent.make(eid, &"stat_cascade", &"fortune", 0, 20.0, 0.25)
	cs.cascades_queue.append(ev)	
		# Two distinct events
	cs.queue_stat_cascade("fortune", 0, +12.0, 0.40)   # blessing from NPC0
	cs.queue_stat_cascade("anger",   2, +15.0, 0.25)   # outburst from NPC2
	
	cs.process_all()  # executes via CultManager.spread_stat

	# 6) Show results
	_print_stats(data, "After 1st cascade: fortune & anger")

	# 7) Direct action through CultManager API
	eid = IdGen.next_event_id()
	cm.process_action(GameEvent.make(eid, &"bless", &"fortune", 0, 2, 5.0, 0.0))
	_print_stats(data, "After Action: bless, indirectly triggering 2nd cascade: ")
	
	# 8) Recompute story patterns
	story.check_emergence()
	
	print("\nRunning memory tails...")
	_print_memory_tails(data, 3)  # show last 3 per NPC

func _make_cult_data(n: int) -> CultData:
	var wd := WorldGen.new()
	# 1) Pick biome deterministically
	wd.biome = WorldGen.pick_biome(&"main_region")  # use your region token
	# 2) Derive its unique resource
	wd.resource_kind = WorldGen.resource_for_biome(wd.biome)
	# 3A) Allocate a fixed number of spots (e.g., 12) across a WxH map
	var W := 64
	var H := 64
	wd.resource_spots = WorldGen.allocate_resource_spots(wd.resource_kind, W, H, 12)

	# (or 3B) If you prefer tile-wise test, build spots from a pass)
	# var spots: Array[Vector2i] = []
	# for y in range(H):
	#     for x in range(W):
	#         if WorldGen.tile_has_resource(x, y, wd.resource_kind, 0.015):
	#             spots.append(Vector2i(x, y))
	# wd.resource_spots = spots
	
	var cd := CultData.new()
	
	cd.ensure_npcs(n)
	# If you seed matrix separately, mirror once:
	# cd.sync_matrix_from_npcs() or cd.sync_npcs_from_matrix(), whichever is your source of truth.
	
	# Relationship matrix n x n (0..100 weights). Make a simple network:
	cd.relationship_matrix.resize(n)
	for i in range(n):
		cd.relationship_matrix[i] = PackedFloat32Array()
		cd.relationship_matrix[i].resize(n)
		cd.relationship_matrix[i].fill(0.0)

	for a in range(n):
		for b in range(a + 1, n):
			var ida := cd.npcs[a].id
			var idb := cd.npcs[b].id
			var low : int = min(int(ida), int(idb))
			var high : int = max(int(ida), int(idb))
			var k := DetRng.key([&"rel", low, high])
			var w := float(DetRng.randi_range(k, 10, 90))  # 10..90, taste to flavor
			cd.relationship_matrix[a][b] = w
			cd.relationship_matrix[b][a] = w
	
	# Strong ties from 0 to others; symmetric-ish for test
	cd.relationship_matrix[0][1] = 80.0
	cd.relationship_matrix[1][0] = 75.0
	cd.relationship_matrix[0][2] = 60.0
	cd.relationship_matrix[2][0] = 55.0
	cd.relationship_matrix[0][3] = 30.0
	cd.relationship_matrix[3][0] = 30.0
	
	# Beliefs
	cd.belief_states.resize(n)
	for i in n:
		cd.belief_states[i] = GameDefs.BeliefState.UNALIGNED
	
	
	# Stats matrix n x STAT_COUNT --> I might be doing something wrong here
	cd.stats_matrix.resize(n)
	for i in n:
		cd.stats_matrix[i] = PackedFloat32Array()
		cd.stats_matrix[i].resize(GameDefs.STAT_COUNT)
		cd.stats_matrix[i].fill(0.0)
	
	# Seed a few starting stats in the matrix (example)
	cd.stats_matrix[0][GameDefs.STAT.FORTUNE] = 50.0
	cd.stats_matrix[1][GameDefs.STAT.FORTUNE] = 20.0

	# Mirror into NPCData so they’re “live”
	cd.sync_npcs_from_matrix()
	
	# Optional cached containers
	cd.social_clusters = []
	cd.narrative_candidates = {}
	
	for i in range(n):
		print("NPC", i, "#", cd.npcs[i].id, " name=", cd.npcs[i].display_name, " role=", String(cd.npcs[i].role),
		" fortune=", cd.npcs[i].stats[GameDefs.STAT.FORTUNE])
	
	return cd


func _print_stats(cd: CultData, label: String) -> void:
	var fortune_idx: int = int(GameDefs.STAT_INDICES["fortune"])
	var line := "%s | fortune: " % label
	for i in cd.stats_matrix.size():
		line += "NPC%d=%.2f  " % [i, cd.stats_matrix[i][fortune_idx]]
	print(line)

func _on_state_changed(change_type: String, affected_npcs: Array) -> void:
	print("[state_changed] type=%s affected=%s" % [change_type, affected_npcs])

func _on_story_ready(pattern_name: String) -> void:
	print("[story_ready] %s" % pattern_name)

func _print_memory_tails(cd: CultData, tail: int) -> void:
	for i in range(cd.npcs.size()):
		var npc := cd.npcs[i]
		print("NPC%d memories:" % i)
		for m in npc.get_memories_ordered(tail):
			print("  ", m)
