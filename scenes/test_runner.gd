extends Node

@onready var cm: CultManager       = $CultManager
@onready var cs: CascadeSystem     = $CascadeSystem
@onready var story: StorySystem    = $StorySystem
@onready var logger: RichTextLabel = $CanvasLayer/Control/PanelContainer/RichTextLabel

func _ready() -> void:
	# 0) Deterministic bootstrap
	IdGen.init(123456)
	DetRng.init(123456)

	# 1) Minimal worldgen sample (doesn't affect tests, but stays deterministic)
	var W: int = 64
	var H: int = 64
	var wd := WorldGen.new()
	wd.biome = WorldGen.pick_biome(&"main_region")
	wd.resource_kind = WorldGen.resource_for_biome(wd.biome)
	wd.resource_spots = WorldGen.allocate_resource_spots(wd.resource_kind, W, H, 12)

	# 2) Build cast + ties
	var data := _make_cult_data(4)
	cm.cult_data = data
	cs.cult_manager = cm
	story.cascade = cs
	story.cult = cm

	# 3) Observe systems
	#cs.event_enqueued.connect(_on_event_enqueued)
	#cs.event_processed.connect(_on_event_processed)
	cm.stat_changed.connect(_on_stat_changed)

	# 4) Show initial
	logger.append_text("\n")
	_print_stats(data, "Before")

	# 5) Unit tests (primitive + cascade)
	cs.enqueue_stat_delta(&"fortune", 0, +12.0, {"reason": "unit:bless"})
	cs.enqueue_stat_cascade(&"anger", 2, +15.0, 0.25, {"min_affinity": 50.0})
	cs.process_all()

	logger.append_text("\n")
	_print_stats(data, "After unit cascade")

	# 6) Story inciting → effects → process
	story.start_new_story()
	cs.process_all()

	logger.append_text("\n")
	_print_stats(data, "After story inciting")

	# 7) Memory tails
	logger.append_text("\n")
	_append_log_line("\n[memory tails]")
	_print_memory_tails(data, 3)

# --- Helpers ----------------------------------------------------------------

func _append_log_line(s: String) -> void:
	logger.append_text(s + "\n")
	logger.scroll_to_line(logger.get_line_count() - 1)

func _name_for(cd: CultData, npc_id: int) -> String:
	if npc_id >= 0 and npc_id < cd.npcs.size():
		return cd.npcs[npc_id].display_name
	return "N/A"

func _on_event_enqueued(ev: GameEvent) -> void:
	var meta_text: String = "{}"
	if not ev.metadata.is_empty():
		meta_text = JSON.stringify(ev.metadata)
	_append_log_line("[enq] id=%d act=%s src=%d str=%.2f dec=%.2f meta=%s" % [
	int(ev.id), str(ev.action), int(ev.source_npc), float(ev.strength), float(ev.decay_rate), meta_text
	])

func _on_event_processed(ev: GameEvent) -> void:
	_append_log_line("[done] id=%d act=%s" % [int(ev.id), str(ev.action)])

func _on_stat_changed(npc_id: int, stat_idx: int, before: float, after: float, ev: GameEvent) -> void:
	var cd: CultData = cm.cult_data
	var stat_sn: StringName = GameDefs.stat_name(stat_idx)
	_append_log_line("  stat_changed %s %s: %.1f→%.1f (act=%s,id=%d)" % [
	_name_for(cd, npc_id), String(stat_sn), before, after, str(ev.action), int(ev.id)
	])

func _print_stats(cd: CultData, label: String) -> void:
	var idx: int = GameDefs.stat_index(&"fortune")
	var line: String = "%s | fortune: " % label
	for i in range(cd.npcs.size()):
		line += "%s=%.2f  " % [cd.npcs[i].display_name, float(cd.npcs[i].stats[idx])]
	_append_log_line(line)

func _name_of(npc_id: int) -> String:
	var cd: CultData = cm.cult_data
	if cd == null:
		return "N/A"
	if npc_id < 0 or npc_id >= cd.npcs.size():
		return "N/A"
	return String(cd.npcs[npc_id].display_name)

func _print_memory_tails(cd: CultData, tail: int) -> void:
	var name_of := Callable(self, "_name_of")
	for i in range(cd.npcs.size()):
		_append_log_line("%s memories:" % cd.npcs[i].display_name)
		var notes : Array[MemoryNote] = cd.npcs[i].get_memories_ordered(tail)
		for j in range(notes.size()):
			_append_log_line("  " + notes[j].to_pretty_string(name_of))

# --- World build -------------------------------------------------------------

func _make_cult_data(n: int) -> CultData:
	var cd := CultData.new()
	cd.ensure_npcs(n)

	# Relationship matrix n x n (0..100 deterministic)
	cd.relationship_matrix.resize(n)
	for i in range(n):
		cd.relationship_matrix[i] = PackedFloat32Array()
		cd.relationship_matrix[i].resize(n)
		cd.relationship_matrix[i].fill(0.0)

	for a in range(n):
		for b in range(a + 1, n):
			var ida: int = int(cd.npcs[a].id)
			var idb: int = int(cd.npcs[b].id)
			var low: int = min(ida, idb)
			var high: int = max(ida, idb)
			var k: StringName = DetRng.key([&"rel", low, high])
			var w: float = float(DetRng.randi_range(k, 10, 90))
			cd.relationship_matrix[a][b] = w
			cd.relationship_matrix[b][a] = w

	# A few seeded stats
	cd.npcs[0].stats[GameDefs.STAT.FORTUNE] = 50.0
	cd.npcs[1].stats[GameDefs.STAT.FORTUNE] = 20.0

	# Debug print of roster
	for i in range(n):
		_append_log_line("NPC%d #%d name=%s fortune=%.1f" % [
		i, int(cd.npcs[i].id), cd.npcs[i].display_name,
		float(cd.npcs[i].stats[GameDefs.STAT.FORTUNE])
		])

	return cd

	#extends Node
#
#@onready var cm: CultManager = $CultManager
#@onready var cs: CascadeSystem = $CascadeSystem
#@onready var story: StorySystem = $StorySystem
#@onready var logger: RichTextLabel = $CanvasLayer/Control/PanelContainer/RichTextLabel
#
#func _ready() -> void:
#	#	if not EventLog.event_recorded.is_connected(_on_event_recorded):
#	#		EventLog.event_recorded.connect(_on_event_recorded)
#	#func _on_event_recorded(ev: GameEvent) -> void:
#	#	process_action(ev)
#	
#	# 0) Deterministic bootstrap
#	IdGen.init(123456)        # ← set/pipe your seed here (UI/devtool/etc.)
#	DetRng.init(123456)       # ← must match IdGen for reproducible runs
#	var wd := WorldGen.new()
#	# Pick biome deterministically
#	wd.biome = WorldGen.pick_biome(&"main_region")  # use your regions token
#	# Derive its unique resource
#	wd.resource_kind = WorldGen.resource_for_biome(wd.biome)
#	# A) Allocate a fixed number of spots (e.g., 12) across a WxH map
#	var W := 64
#	var H := 64
#	wd.resource_spots = WorldGen.allocate_resource_spots(wd.resource_kind, W, H, 12)
#	
#	# (or B) If you prefer tile-wise test, build spots from a pass)
#	# var spots: Array[Vector2i] = []
#	# for y in range(H):
#	#     for x in range(W):
#	#         if WorldGen.tile_has_resource(x, y, wd.resource_kind, 0.015):
#	#             spots.append(Vector2i(x, y))
#	# wd.resource_spots = spots
#	
#	# 1) Build 4 NPCs, simple relationships & stats
#	var data := _make_cult_data(4)
#	_print_stats(data, "Before cascade: ")
#	
#	# 2) Inject dependencies
#	cm.cult_data = data
#	cm.cascade_system = cs
#	cs.cult_manager = cm
#	story.cult_data = data
#	
#	# 3) Observe signals
#	cm.state_changed.connect(_on_state_changed)
#	#story.story_ready.connect(_on_story_ready)
#	
#	# 4) Prime some beliefs so StorySystem has something to read
#	# (optional; adjust to your StorySystem logic) 
#	data.community_roles[0] = GameDefs.COMMUNITY_ROLE.APOSTLE
#	data.community_roles[1] = GameDefs.COMMUNITY_ROLE.BUILDER
#	
#	##ASK Does the new EventLog system fully replace this code block? What needs to be preserved?
#	# 5) Queue a stat change for NPC 0 affecting "fortune"
#	var eid: int = IdGen.next_id(&"event")
#	var ev : = GameEvent.make(eid, &"bless", {}, 0, 0, +12.0, 0.40) # Single target envent
#	EventLog.record(ev)
#	_print_event_log(ev, data)
#	##ASK since the proceeding ev was a singletarget event, should this be a cascade_manager handler?
#	##ASK or a cult_manager handler? I'm leaning more cult
#	cm.queue_action(ev)
#
#	eid = IdGen.next_id(&"event")
#	ev = GameEvent.make(eid, &"bless", {"tag":"test"}, 1, 1, +2.0, 0.0) # Single target envent
#	EventLog.record(ev)
#	_print_event_log(ev, data)
#	cm.queue_action(ev)
#	#		# Two distinct events
#	#	("fortune", 0, +12.0, 0.40)   # blessing from NPC0
#	#	("anger",   2, +15.0, 0.25)   # outburst from NPC2	
#	
#
##	cm.process_actions()
#
##	cs.queue_cascade(ev)
##	cs.process_all()
#	
#
#	#	var eid: int = IdGen.next_event_id()
##	var ev := GameEvent.make(eid, &"stat_cascade", &"fortune", 0, 20.0, 0.25)
##	cs.queue_cascade(ev)
#
#
#
#	# Show results
#	_print_stats(data, "After 1st cascade: fortune & anger")
#	
#	eid = IdGen.next_id(&"event")
#	ev = (GameEvent.make(eid, &"bless", {}, 0, 5.0, 0.0, 2))
#	cm.queue_action(ev)
#	cm.process_actions()
#	_print_stats(data, "After Action: bless, indirectly triggering 2nd cascade: ")
#	
#	# Recompute story patterns
#	#story.check_emergence()
#	
#	print("\nRunning memory tails...")
#	_print_memory_tails(data, 3)  # show last 3 per NPC
#
## Build Functions ==================================================================
#
#func _make_cult_data(n: int) -> CultData:
#	var cd := CultData.new()
#	cd.ensure_npcs(n)
#	# If you seed matrix separately, mirror once:
#	
#	# Relationship matrix n x n (0..100 weights). Make a simple network:
#	cd.relationship_matrix.resize(n)
#	for i in range(n):
#		cd.relationship_matrix[i] = PackedFloat32Array()
#		cd.relationship_matrix[i].resize(n)
#		cd.relationship_matrix[i].fill(0.0)
#
#	for a in range(n):
#		for b in range(a + 1, n):
#			var ida := cd.npcs[a].id
#			var idb := cd.npcs[b].id
#			var low : int = min(int(ida), int(idb))
#			var high : int = max(int(ida), int(idb))
#			var k := DetRng.key([&"rel", low, high])
#			var w := float(DetRng.randi_range(k, 10, 90))  # 10..90, taste to flavor
#			cd.relationship_matrix[a][b] = w
#			cd.relationship_matrix[b][a] = w
#	
#	# Strong ties from 0 to others; symmetric-ish for test
#	cd.relationship_matrix[0][1] = 80.0
#	cd.relationship_matrix[1][0] = 75.0
#	cd.relationship_matrix[0][2] = 60.0
#	cd.relationship_matrix[2][0] = 55.0
#	cd.relationship_matrix[0][3] = 30.0
#	cd.relationship_matrix[3][0] = 30.0
#	
#	# Roles
#	cd.community_roles.resize(n)
#	for i in n:
#		cd.community_roles[i] = GameDefs.COMMUNITY_ROLE.WORKER
#	
#	
#	# Stats matrix n x STAT_COUNT --> I might be doing something wrong here
#	# Seed a few starting stats in the matrix (example)
#	cd.npcs[0].stats[GameDefs.STAT.FORTUNE] = 50.0
#	cd.npcs[1].stats[GameDefs.STAT.FORTUNE] = 20.0
#	
#	# Optional cached containers
#	cd.social_clusters = []
#	cd.narrative_candidates = {}
#	
#	for i in range(n):
#		var newRole: Array = GameDefs.COMMUNITY_ROLE.keys()
#		print("NPC", i, "#", cd.npcs[i].id, " name=", cd.npcs[i].display_name, " role=", newRole[cd.npcs[i].role],
#		" fortune=", cd.npcs[i].stats[GameDefs.STAT.FORTUNE])
#	
#	return cd
#
#
#func _append_log_line(s: String) -> void:
#	logger.append_text(s + "\n")
#	logger.scroll_to_line(logger.get_line_count() - 1)  # keep view pinned to latest
#
#func _print_event_log(ev: GameEvent, cd: CultData) -> void:
#	var line: String = "Action: %s, MetaData: %s, Impact Strength: %.2f, Decay Rate: %.2f" % [
#		str(GameDefs.action_name(ev.action)), str(JSON.stringify(ev.metadata)), ev.strength, ev.decay_rate
#	]
#	
#	if ev.has_chain():
#		line += ", Event Chain: %d" % ev.chain_id
#	if ev.has_parent():
#		line += ", Parent Event: %d" % ev.parent_id
#	if ev.has_source():
#		line += ", Source NPC: %s" % cd.npcs[ev.source_npc].display_name
#	if ev.has_target():
#		line += ", Target NPC: %s" % cd.npcs[ev.target_npc].display_name
#	
#	_append_log_line(line)   # your UI logger
#	logger.append_text("\n")
#
#func _print_stats(cd: CultData, label: String) -> void:
#	var idx :=  GameDefs.stat_index(&"fortune")
#	var line := "%s | fortune: " % label
#	for i in range(cd.npcs.size()):
#		line += "%s=%.2f  " % [cd.npcs[i].display_name, cd.npcs[i].stats[idx]]
#	_append_log_line(line)
#
#func _on_state_changed(change_type: String, affected_npcs: Array) -> void:
#	print("[state_changed] type=%s affected=%s" % [change_type, affected_npcs])
#
#func _on_story_ready(pattern_name: String) -> void:
#	print("[story_ready] %s" % pattern_name)
#
#
#func _print_memory_tails(cd: CultData, tail: int) -> void:
#	var n: int = cd.npcs.size()
#	for i in range(n):
#		_append_log_line("%s memories:" % cd.npcs[i].display_name)
#		var notes: Array = cd.npcs[i].get_memories_ordered(tail)
#		for j in range(notes.size()):
#			var m: MemoryNote = notes[j]
#			_append_log_line("  " + str(m))
