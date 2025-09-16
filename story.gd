extends Node
class_name StorySystem

signal story_ready(pattern_name: String)

@export var cult_data: CultData
var inciting_event: StringName = &""  # unchanged

# Patterns now work purely on stats
var story_patterns := [
	{
		"name": "SCHISM",
		"check": func(): return _check_piety_schism(),
	},
	{
		"name": "PIETY_WAVE",
		"check": func(): return _check_piety_wave(),
	},
	{
		"name": "BREWING_BETRAYAL",
		"check": func(): return _check_for_betrayal(),
	},
]

func check_emergence() -> void:
	for pattern in story_patterns:
		if pattern.check.call():
			emit_signal("story_ready", pattern.name)
	if inciting_event != &"":
		return
	var k = DetRng.key([&"story", &"inciting"])
	inciting_event = StringName(DetRng.choice_from(k, [
		&"eclipse_omen", &"famine", &"stranger_arrives", &"blood_tax"
	]))

# 1. Schism: multiple clusters with high piety
func _check_piety_schism() -> bool:
	if cult_data.social_clusters.size() < 2:
		return false
	var threshold := 60.0
	var high_piety_clusters := 0
	for cluster in cult_data.social_clusters:
		var avg_piety := 0.0
		for i in cluster:
			avg_piety += cult_data.npcs[i].get_stat("piety")
		avg_piety /= cluster.size()
		if avg_piety > threshold:
			high_piety_clusters += 1
	return high_piety_clusters >= 2

# 2. Piety Wave: low-piety NPCs with high-piety friends
func _check_piety_wave() -> bool:
	var threshold := 60.0
	var wave_candidates := []
	for i in cult_data.npcs.size():
		var npc_piety := cult_data.npcs[i].get_stat("piety")
		if npc_piety >= threshold:
			continue
		var high_piety_friends := 0
		for j in cult_data.npcs.size():
			if i == j:
				continue
			var friend_piety := cult_data.npcs[j].get_stat("piety")
			var rel := cult_data.relationship_matrix[i][j]
			if friend_piety > threshold and rel > 60.0:
				high_piety_friends += 1
		if high_piety_friends >= 2:
			wave_candidates.append(i)
	cult_data.narrative_candidates["piety_wave"] = wave_candidates
	return wave_candidates.size() > 0

# 3. Betrayal: high anger + high piety
func _check_for_betrayal() -> bool:
	var anger_thresh := 80.0
	var loyalty_thresh := 40.0
	var candidates := []
	var anger_idx := GameDefs.STAT.ANGER
	var loyalty_idx := GameDefs.STAT.LOYALTY
	for i in cult_data.npcs.size():
		var anger := cult_data.npcs[i].stats[anger_idx]
		var loyalty := cult_data.npcs[i].stats[loyalty_idx]
		if anger > anger_thresh and loyalty < loyalty_thresh:
			candidates.append(i)
	cult_data.narrative_candidates["betrayal"] = candidates
	return candidates.size() > 0


func _check_for_sacrifice() -> bool:
	var piety_thresh := 70.0  # or tune to desired drama
	var anger_thresh := 80.0
	var candidates := []
	var anger_idx := GameDefs.STAT.ANGER
	var piety_idx := GameDefs.STAT.PIETY
	for i in cult_data.npcs.size():
		var anger := cult_data.npcs[i].stats[anger_idx]
		var piety := cult_data.npcs[i].stats[piety_idx]
		if anger > anger_thresh and piety > piety_thresh:
			candidates.append(i)
	cult_data.narrative_candidates["sacrifice"] = candidates
	return candidates.size() > 0
