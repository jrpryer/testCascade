extends Node
class_name StorySystem

signal story_ready(pattern_name: String)

@export var cult_data: CultData
var inciting_event: StringName = &""

func check_emergence() -> void:
	for pattern in story_patterns:
		if pattern.check.call():
			emit_signal("story_ready", pattern.name)
	
	if inciting_event != &"": return
	var k := DetRng.key([&"story", &"inciting"])
	inciting_event = StringName(DetRng.choice_from(k, [
		&"eclipse_omen", &"famine", &"stranger_arrives", &"blood_tax"
	]))
	# Optionally enqueue a GameEvent immediately:
	# cascade_system.queue_stat_cascade("panic", -1, +10.0, 0.0)

var story_patterns := [
	{
		"name": "CULT_SCHISM",
		"check": func(): return _check_belief_clusters(),
	},
	{
		"name": "CONVERSION_WAVE",
		"check": func(): return _check_conversion_pressure(),
	},
	{
		"name": "BETRAYAL_BREWING",
		"check": func(): return _check_betrayal_risk(),
	},
]

func _check_belief_clusters() -> bool:
	# Two clusters each with majority BELIEVER
	if cult_data.social_clusters.size() < 2:
		return false
	var believer_majority := func(cluster: Array) -> bool:
		var believers := 0
		for i in cluster:
			if cult_data.belief_states[i] >= GameDefs.BeliefState.BELIEVER:
				believers += 1
		return believers * 2 >= cluster.size()
	var majors := 0
	for c in cult_data.social_clusters:
		if believer_majority.call(c):
			majors += 1
	return majors >= 2

func _check_conversion_pressure() -> bool:
	var idx := GameDefs.STAT.ANGER
	var r := []
	for i in cult_data.belief_states.size():
		if cult_data.belief_states[i] < GameDefs.BeliefState.BELIEVER:
			var believer_friends := 0
			for j in cult_data.belief_states.size():
				if cult_data.belief_states[j] >= GameDefs.BeliefState.BELIEVER and cult_data.relationship_matrix[i][j] > 60.0:
					believer_friends += 1
			if believer_friends >= 2:
				r.append(i)
	cult_data.narrative_candidates["conversion"] = r
	return r.size() > 0

func _check_betrayal_risk() -> bool:
	var anger_idx := GameDefs.STAT.ANGER
	var risky := []
	for i in cult_data.belief_states.size():
		if cult_data.belief_states[i] == GameDefs.BeliefState.APOSTATE:
			if cult_data.stats_matrix[i][anger_idx] > 80.0:
				risky.append(i)
	cult_data.narrative_candidates["betrayal"] = risky
	return risky.size() > 0
