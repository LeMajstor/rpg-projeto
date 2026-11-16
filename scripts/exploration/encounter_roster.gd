extends RefCounted
## Cada representante lê identidade e movimento do participante do preset comum.
const Bridge = preload("res://scripts/combat/damage_v1_bridge.gd")
static var definitions: Dictionary = {}

static func battle_definitions() -> Dictionary:
	if definitions.is_empty():
		definitions=Bridge.exploration_definitions(JSON.parse_string(FileAccess.get_file_as_string("res://data/lab.json")))
	return definitions

static func assemble(source: Dictionary) -> Dictionary:
	if not source.get("encounters",[]) is Array:
		return source
	var data=battle_definitions()
	var exploration: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/exploration_enemy_behaviors.json"))
	var profiles: Dictionary=exploration["profiles"]
	var result=source.duplicate(true)
	var actors: Array=[]
	var groups: Array=[]
	for group in source["encounters"]:
		if not group.has("members"):
			actors.append(group.duplicate(true))
			continue # Fixtures históricas sem elenco mantêm sua representação original.
		var preset: Dictionary={}
		for candidate in data["presets"]:
			if candidate["id"]==group["battle_preset_id"]:
				preset=candidate
		if preset.is_empty() or group["members"].size()!=preset["enemies"].size():
			return {}
		groups.append(group.duplicate(true))
		for participant in preset["enemies"]:
			var placement: Dictionary=group["members"].get(participant["id"],{})
			if placement.is_empty():
				return {}
			var type: Dictionary=data["enemy_types"][participant["type"]]
			var profile_id: String=type["movement_behavior"]
			var behavior: Dictionary=data["movement_behaviors"][profile_id].duplicate(true)
			var title: String={"heavy":"Pesado","agile":"Ágil","flying":"Voador","static":"Estático"}[profile_id]
			var encounter_title: String=group["label"].split(" · ")[0]
			var actor: Dictionary=placement.duplicate(true)
			actor.merge({"id":group["id"]+"_"+participant["id"],"encounter_id":group["id"],"battle_actor_id":participant["id"],"battle_preset_id":preset["id"],
				"movement_profile":profile_id,"movement_behavior_data":behavior,"exploration_behavior":profiles[profile_id].duplicate(true),
				"reference_profile_id":type["reference_profile_id"],"color":type["color"],"speed":behavior["speed"],
				"label":encounter_title+"/"+participant["id"].to_upper()+" · "+title,"seed":int(data["settings"]["seed"]) ^ int((source["id"]+group["id"]+participant["id"]).hash())},true)
			actor["exploration_behavior"]["vision"]=exploration["vision"].duplicate(true)
			if profile_id=="static":
				actor["route"]=[actor["position"]]
			actors.append(actor)
	result["encounters"]=actors
	if not groups.is_empty():
		result["encounter_groups"]=groups
	return result
