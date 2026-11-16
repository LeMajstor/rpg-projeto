extends RefCounted
## Fixture de retorno ao mapa: elimina esquiva/ATB inimigo, usa impactos reais.
static func win_by_basics(battle) -> bool:
	for actor in battle.actors():
		actor["ini_modifier"] = -actor["ini"]
	for enemy in battle.enemies:
		enemy["hp"] = 1
		enemy["damage_stats"]["evasion_base"] = 0
		battle.party[0]["atb"] = 1.0
		if not battle.select_actor("p1") or not battle.submit("attack", enemy["id"]):
			return false
		for step in range(240):
			if battle.action.is_empty():
				break
			battle.tick(1.0 / 120.0)
		if not battle.action.is_empty():
			return false
	return battle.outcome == "victory"
