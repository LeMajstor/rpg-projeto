extends RefCounted
## Profundidade visual a partir da base no chão; não altera colisões ou posições.
static func footprint(definition: Dictionary) -> Rect2:
	var value: Array = definition["rect"]
	return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))

static func base_y(definition: Dictionary) -> float:
	return float(definition.get("sort_y", footprint(definition).end.y))

static func height(definition: Dictionary) -> float:
	return maxf(0, float(definition.get("visual_height", 28)))

static func draw_order(world) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for feature in world.data.get("terrain", []):
		if feature["kind"] in ["hill", "forest"]:
			# Borda norte: quem está atrás é encoberto; quem subiu fica sobre o platô.
			var area = footprint(feature)
			result.append({"kind": "terrain", "definition": feature, "depth": area.position.y if feature["kind"] == "hill" else area.end.y, "sequence": result.size()})
	for definition in world.data["obstacles"]:
		if definition.get("ground_only", false):
			continue
		result.append({"kind": "obstacle", "definition": definition, "depth": base_y(definition), "sequence": result.size()})
	for entity in world.entities:
		if not entity["present"] or entity["kind"] == "transition":
			continue
		# Porta aberta é só uma marca no chão, desenhada antes dos corpos.
		if entity.get("object_type", "") == "door" and entity["open"]:
			continue
		var depth: float = base_y(entity) if entity.get("object_type", "") == "door" else entity["position"].y
		result.append({"kind": "entity", "entity": entity, "depth": depth, "sequence": result.size()})
	var positions = world.formation_positions()
	for index in range(world.party_order.size()):
		result.append({"kind": "member", "slot": index, "position": positions[index], "depth": positions[index].y, "sequence": result.size()})
	# Empates estáveis: estrutura primeiro, ator depois, mantendo ordem dos dados/fila.
	result.sort_custom(func(a, b): return a["sequence"] < b["sequence"] if a["depth"] == b["depth"] else a["depth"] < b["depth"])
	return result
