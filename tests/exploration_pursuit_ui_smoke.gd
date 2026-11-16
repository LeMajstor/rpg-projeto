extends "res://tests/exploration_combat_parity_ui_smoke.gd"
## Cena atual: 18 participantes, sensores estáticos e dois layouts distintos.
func run() -> void:
	screen=load("res://scenes/exploration_test.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_physics_process(false)
	screen._toggle_menu()
	screen.leader_buttons[2].pressed.emit()
	travel("town_exit")
	travel("dungeon_entrance")
	var lower=screen.session.world
	expect(lower.data["encounter_groups"].size()==3 and lower.data["encounters"].size()==9,"Três encontros/nove monstros no piso1")
	expect(lower.party_order[0]=="p3","Líder selecionado preservado")
	await capture("individual-lower-entry")
	var heavy=lower.entity_by_id("test_map_enemy_01_e1")
	var flyer=lower.entity_by_id("test_map_enemy_01_e2")
	var statue=lower.entity_by_id("test_map_enemy_01_e3")
	var stationary_position: Vector2=statue["position"]
	place(Vector2(340,760))
	screen._physics_process(0.3)
	expect(heavy["awareness"]["state"]=="chase" and flyer["awareness"]["state"]=="patrol" and statue["position"]==stationary_position,"Só pesado detecta; voador patrulha e estático não move")
	expect(heavy["awareness"]["speed"]<=108,"Perseguição pesada respeita108")
	await capture("individual-detection")
	screen._toggle_menu()
	var before=lower.entities.duplicate(true)
	screen._physics_process(1)
	expect(lower.entities==before,"Menu pausa os nove inimigos e seus RNGs")
	screen._toggle_menu()
	place(Vector2(1000,1060))
	screen._physics_process(2)
	expect(heavy["awareness"]["state"]!="chase" and statue["position"]==stationary_position,"Perseguição termina e estático continua no lugar")
	place(Vector2(560,660))
	await capture("individual-lower-corners")
	place(Vector2(420,1165))
	screen.map_view.show_path=true
	screen._refresh_map()
	await capture("static-circle-and-cone")
	expect(screen.session.state=="exploration" and not lower.Perception.in_static_area(statue,lower.leader_position),"Líder fora das duas áreas não inicia luta")
	screen.map_view.show_path=false
	screen._refresh_map()
	var shared=screen.session.battle
	place(Vector2(410,1100))
	screen._physics_process(1.0/120.0)
	lab=screen.combat_ui
	lab.set_process(false)
	expect(screen.session.state=="battle" and screen.session.active_encounter_id==statue["id"],"Cone fixo inicia batalha sem contato físico")
	expect(shared.enemies.size()==3 and shared.preset["id"]=="exploration_seeded_open" and lab.model==shared,"Estático inicia o mesmo encontro completo")
	await capture("static-trigger-full-battle")
	for actor in shared.enemies:
		actor["ini_modifier"]=-actor["ini"]
	shared.party[0]["hp"]=29
	shared.inventory["remedy_test"]=2
	shared.data["settings"]["escape_chance"]=0.0
	shared.debug_ready_allies()
	lab._refresh()
	key(KEY_1)
	key(KEY_F)
	finish()
	await process_frame
	expect(screen.combat_ui==lab and lower.entities.filter(func(e):return e.get("encounter_id","")=="test_map_enemy_01" and e["present"]).size()==3,"Fuga falha mantém os três representantes")
	shared.data["settings"]["escape_chance"]=1.0
	shared.debug_ready_allies()
	lab._refresh()
	key(KEY_1)
	key(KEY_F)
	finish()
	await process_frame
	expect(screen.combat_ui==null and lower.entities.filter(func(e):return e.get("encounter_id","")=="test_map_enemy_01" and not e["present"]).size()==3,"Fuga remove todo encontro, inclusive quem não detectou")
	expect(lower.entities.filter(func(e):return e["kind"]=="encounter" and e["present"]).size()==6,"Outros dois grupos continuam presentes")
	expect(shared.party[0]["hp"]==29 and shared.inventory["remedy_test"]==2,"Recursos preservados")
	await capture("individual-group-after-escape")
	travel("stairs_up")
	var upper=screen.session.world
	expect(upper.data["encounters"].size()==9 and "andar 2" in screen.area_label.text,"Escadas levam ao outro layout com nove monstros")
	await capture("individual-upper-entry")
	place(Vector2(1620,570))
	await capture("individual-upper-angles")
	var target=upper.entity_by_id("test_map_enemy_05_e2")
	place(target["position"])
	screen._physics_process(1.0/120.0)
	lab=screen.combat_ui
	lab.set_process(false)
	expect(lab.model==shared and screen.session.active_encounter_group_id=="test_map_enemy_05","Contato no voador inicia grupo correspondente")
	expect(preload("res://tests/fixtures/current_combat.gd").win_by_basics(shared),"Vitória real com as mesmas regras de dano")
	lab._refresh()
	await process_frame
	expect(screen.session.world==upper and upper.entities.filter(func(e):return e.get("encounter_id","")=="test_map_enemy_05" and not e["present"]).size()==3,"Vitória remove todos do grupo no piso correto")
	await capture("individual-upper-after-victory")
	travel("stairs_down")
	expect(screen.session.world==lower and not statue["present"] and not heavy["present"] and not flyer["present"],"Revisita mantém remoção do encontro completo")
	screen._restart()
	await process_frame
	travel("town_exit")
	expect(screen.session.world.entities.all(func(e):return e["kind"]!="encounter"),"Mapa-múndi permanece sem monstros")
	travel("dungeon_entrance")
	expect(screen.session.world.entities.filter(func(e):return e["kind"]=="encounter" and e["present"]).size()==9,"Reinício restaura representantes")
	screen.queue_free()
	await process_frame
	print("PERSEGUIÇÃO EXPLORAÇÃO UI: %d verificações, %d falhas"%[checks,failures])
	quit(0 if failures==0 else 1)
