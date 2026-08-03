extends SceneTree

const OUTPUT_DIR := "res://../docs/concepts/gameplay-ui-v1"
const CAPTURE_SAVE_PATH := "user://capture-ui-save.json"
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const CAPTURE_SETTINGS_PATH := "user://capture-ui-settings.json"


func _initialize() -> void:
	_capture_flow.call_deferred()


func _capture_flow() -> void:
	var scale_scene: PackedScene = load("res://tools/scale_test.tscn")
	var scale_instance := scale_scene.instantiate()
	root.add_child(scale_instance)
	await _settle()
	await _save_frame("00-actor-scale-test.png")
	scale_instance.queue_free()
	await process_frame

	var scene: PackedScene = load("res://src/ui/main.tscn")
	var instance := scene.instantiate()
	SaveGameScript.remove(CAPTURE_SAVE_PATH)
	SettingsStoreScript.remove(CAPTURE_SETTINGS_PATH)
	instance.configure_save_path(CAPTURE_SAVE_PATH)
	instance.configure_settings_path(CAPTURE_SETTINGS_PATH)
	root.add_child(instance)
	await _settle()
	await _save_frame("01-title-screen.png")

	instance.start_new_game()
	await _settle()
	instance.return_to_title()
	instance.start_new_game()
	await _settle()
	assert(instance.new_game_confirmation_contract()["visible"], "覆盖确认截图必须保留现有旅程")
	await _save_frame("01-new-game-confirmation.png")
	instance.cancel_new_game_confirmation()
	assert(instance.continue_game(), "覆盖确认截图后应继续原旅程")
	instance._render([])
	await _settle()
	await _save_frame("01-zhaohe-ferry.png")
	instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.40, "player_y": 0.20})
	instance._render([])
	await _settle()
	await _save_frame("01-y-depth-occlusion.png")
	instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51})
	instance._render([])

	instance._on_action("talk_to_companion")
	instance.show_full_dialogue_line()
	await _settle()
	await _save_frame("01-companion-dialogue.png")
	instance.toggle_text_scale()
	instance.toggle_high_contrast()
	await _settle()
	await _save_frame("01-accessible-dialogue.png")
	instance.toggle_text_scale()
	instance.toggle_high_contrast()
	var restored_accessibility: Dictionary = instance.accessibility_contract()
	assert(restored_accessibility["text_scale"] == "standard" and not restored_accessibility["high_contrast"],
		"后续参考截图必须在标准文字与普通对比下拍摄")
	instance.advance_dialogue()
	instance.show_full_dialogue_line()
	await _settle()
	await _save_frame("01-protagonist-dialogue.png")
	instance.toggle_dialogue_history()
	await _settle()
	await _save_frame("01-dialogue-journal.png")
	instance.toggle_dialogue_history()
	instance.skip_dialogue_to_response()
	instance._choose_dialogue_response("careful")
	instance.patrol.reset()
	instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.55, "player_y": 0.61})
	instance._render([])
	await _settle()
	await _save_frame("01-patrol-runner.png")
	instance._on_action("talk_to_patrol_runner")
	instance.skip_dialogue_to_response()
	await _settle()
	await _save_frame("01-patrol-choice.png")
	instance._choose_dialogue_response("boat_first")
	instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.41, "player_y": 0.66})
	instance._render([])
	await _settle()
	await _save_frame("01-ferryman-choice.png")
	instance._on_action("talk_to_ferryman")
	instance.show_full_dialogue_line()
	await _settle()
	await _save_frame("01-ferryman-dialogue.png")
	instance.skip_dialogue_to_response()
	instance._choose_dialogue_response("repair")
	await _settle()
	await _save_frame("01-ferryman-repaired.png")
	instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.43, "player_y": 0.42})
	instance._render([])
	await _settle()
	await _save_frame("01-ferry-watermark.png")
	instance._on_action("inspect_ferry_watermark")
	instance.open_journal()
	await _settle()
	await _save_frame("01-journey-journal.png")
	instance.close_journal()
	await _settle()
	assert(not instance.get_node("%JournalOverlay").visible, "札记参考态关闭后必须先完成画面同步")
	for _step in range(6):
		instance.move_player(Vector2.RIGHT, 0.08)
	for _step in range(4):
		instance.move_player(Vector2.DOWN, 0.08)
	await _settle()
	await _save_frame("01-companion-following.png")
	instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.69, "player_y": 0.62})
	instance._render([])
	await _settle()
	await _save_frame("01-moonleaf-choice.png")
	instance._on_action("gather_moonleaf_cutting")
	await _settle()
	await _save_frame("01-moonleaf-regrowth.png")
	instance._on_action("enter_spring")
	await _settle()
	instance.get_node("%SceneTransition").advance(0.12)
	RenderingServer.force_draw(false)
	await process_frame
	await _save_frame("01-scene-transition.png")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	await _save_frame("02-cangquan-path.png")
	instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.40, "player_y": 0.30})
	instance._render([])
	await _settle()
	await _save_frame("02-path-discoveries.png")
	instance._on_action("inspect_spring_seam")
	instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.68, "player_y": 0.60})
	instance._render([])
	instance._on_action("inspect_abandoned_basket")
	instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.10, "player_y": 0.68})
	instance._render([])
	instance._on_action("return_to_ferry")
	instance.get_node("%SceneTransition").finish()
	instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.75, "player_y": 0.66})
	instance._render([])
	await _settle()
	await _save_frame("01-herbkeeper-choice.png")
	instance._on_action("talk_to_herbkeeper")
	instance.show_full_dialogue_line()
	await _settle()
	await _save_frame("01-herbkeeper-dialogue.png")
	instance.skip_dialogue_to_response()
	instance._choose_dialogue_response("return")
	await _settle()
	await _save_frame("01-basket-returned.png")
	instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18})
	instance._render([])
	instance._on_action("enter_spring")
	instance.get_node("%SceneTransition").finish()
	instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.65, "player_y": 0.22})
	instance._render([])
	await _settle()
	await _save_frame("02-enemy-spoors.png")
	for spoor_case in [
		{"position": Vector2(0.65, 0.22), "action": "inspect_rock_spoor"},
		{"position": Vector2(0.36, 0.43), "action": "inspect_moss_spoor"},
		{"position": Vector2(0.91, 0.34), "action": "inspect_puppet_spoor"},
	]:
		instance.exploration.restore({"map_id": "cangquan_path", "player_x": spoor_case["position"].x, "player_y": spoor_case["position"].y})
		instance._render([])
		instance._on_action(spoor_case["action"])
	instance.open_journal()
	instance.select_journal_page(1)
	await _settle()
	await _save_frame("02-enemy-intel-journal.png")
	instance.close_journal()
	await _settle()
	assert(not instance.get_node("%JournalOverlay").visible, "灵物志参考态关闭后必须先完成画面同步")
	instance.exploration.restore({"map_id": "cangquan_path", "player_x": 0.73, "player_y": 0.34})
	instance._render([])

	instance._on_action("approach_enemy")
	instance._on_action("deploy_spring_lamp")
	instance.get_node("%SceneTransition").finish()
	assert(instance.get_node("%BattleEnemySprite").presentation_contract()["state"] == "attack",
		"攻击参考图必须在真实时间推进前锁定语义姿态")
	await _save_frame("02-cangquan-battle.png")
	instance._on_action("use_art")
	assert(instance.get_node("%BattleEnemySprite").presentation_contract()["state"] == "react",
		"受击参考图必须在真实时间推进前锁定语义姿态")
	await _save_frame("02-cangquan-battle-react.png")
	instance._on_action("retreat")
	instance._on_action("approach_moss_shell")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	await _save_frame("02-cangquan-moss-battle.png")
	instance._on_action("retreat")
	instance._on_action("approach_stone_puppet")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	await _save_frame("02-cangquan-puppet-battle.png")

	instance._on_action("guard")
	instance._on_action("use_talisman")
	instance._on_action("use_art")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	await _save_frame("02-cangquan-boss.png")
	instance._on_action("guard")
	instance._on_action("guard")
	instance._on_action("use_art")
	instance._on_action("companion_support")
	instance._on_action("use_art")
	instance._on_action("use_art")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	await _save_frame("03-spring-chamber.png")
	# The player cannot physically reach the first ritual point before the
	# short victory banner expires. Teleported reference states clear it so
	# the captures represent what a player sees on arrival at each point.
	instance.get_node("%MapCanvas").feedback_remaining = 0.0
	instance.get_node("%MapCanvas").feedback_text = ""
	instance.get_node("%MapCanvas").queue_redraw()

	var listen_position: Vector2 = ExplorationStateScript.SPRING_LISTEN_POSITION
	assert(instance.exploration.restore({
		"map_id": ExplorationStateScript.CANGQUAN_SPRING_MAP_ID,
		"player_x": listen_position.x,
		"player_y": listen_position.y,
	}), "听泉辨脉截图点必须可以恢复")
	instance._render([])
	instance._on_action("listen_to_spring")
	await _settle()
	await _save_frame("03-spring-listened.png")

	var warm_position: Vector2 = ExplorationStateScript.SPRING_WARM_POSITION
	assert(instance.exploration.restore({
		"map_id": ExplorationStateScript.CANGQUAN_SPRING_MAP_ID,
		"player_x": warm_position.x,
		"player_y": warm_position.y,
	}), "月芽温脉截图点必须可以恢复")
	instance._render([])
	instance._on_action("warm_meridians")
	await _settle()
	await _save_frame("03-moonleaf-warmed.png")

	var breakthrough_position: Vector2 = ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION
	assert(instance.exploration.restore({
		"map_id": ExplorationStateScript.CANGQUAN_SPRING_MAP_ID,
		"player_x": breakthrough_position.x,
		"player_y": breakthrough_position.y,
	}), "静坐引息截图点必须可以恢复")
	instance._render([])
	instance._on_action("breakthrough")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	await _save_frame("04-first-breath.png")
	instance._on_action("review_journey")
	instance.show_full_dialogue_line()
	await _settle()
	await _save_frame("04-chapter-epilogue.png")
	SaveGameScript.remove(CAPTURE_SAVE_PATH)
	SettingsStoreScript.remove(CAPTURE_SETTINGS_PATH)
	quit(0)


func _settle() -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame


func _save_frame(filename: String) -> void:
	var was_paused := paused
	paused = true
	_normalize_capture_state()
	_freeze_animated_sprites()
	RenderingServer.force_draw(false)
	await process_frame
	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_texture().get_image()
	var error := image.save_png(output_dir.path_join(filename))
	if error != OK:
		push_error("无法保存 RPG 截图：%s" % filename)
		quit(1)
	paused = was_paused
	await process_frame


func _freeze_animated_sprites() -> void:
	for candidate in root.find_children("*", "AnimatedSprite2D", true, false):
		var sprite := candidate as AnimatedSprite2D
		sprite.pause()
		sprite.frame = 0
		sprite.frame_progress = 0.0


func _normalize_capture_state() -> void:
	var game := root.find_child("Main", true, false)
	if game != null and game.get("patrol") != null:
		var patrol_state = game.get("patrol")
		var journey_state = game.get("journey")
		patrol_state.reset()
		if journey_state.phase_id() == "riverbank":
			game.get_node("%MapCanvas").set_patrol_state(
				patrol_state.position,
				patrol_state.motion_direction(),
				patrol_state.is_moving(),
				journey_state.talked_to_companion
			)
	var map_canvas := root.find_child("MapCanvas", true, false)
	if map_canvas != null and map_canvas.feedback_remaining > 0.0:
		map_canvas.feedback_remaining = map_canvas.feedback_duration * 0.5
		map_canvas.feedback_phase = 0.0
		map_canvas.queue_redraw()
	var transition := root.find_child("SceneTransition", true, false)
	if transition != null and transition.is_transitioning():
		transition.elapsed = 0.0
		transition.advance(0.12)
