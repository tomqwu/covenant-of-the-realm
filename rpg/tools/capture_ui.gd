extends SceneTree

const OUTPUT_DIR := "res://../docs/concepts/gameplay-ui-v1"
const CAPTURE_SAVE_PATH := "user://capture-ui-save.json"
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
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
	instance.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.43, "player_y": 0.42})
	instance._render([])
	await _settle()
	await _save_frame("01-ferry-watermark.png")
	instance._on_action("inspect_ferry_watermark")
	instance.open_journal()
	await _settle()
	await _save_frame("01-journey-journal.png")
	instance.close_journal()
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

	instance._on_action("approach_enemy")
	instance._on_action("deploy_spring_lamp")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	await _save_frame("02-cangquan-battle.png")
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

	instance._on_action("use_talisman")
	instance._on_action("use_art")
	instance._on_action("use_art")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	await _save_frame("02-cangquan-boss.png")
	instance._on_action("guard")
	instance._on_action("use_art")
	instance._on_action("companion_support")
	instance._on_action("use_art")
	instance._on_action("use_art")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	await _save_frame("03-spring-chamber.png")

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
	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var image := root.get_texture().get_image()
	var error := image.save_png(output_dir.path_join(filename))
	if error != OK:
		push_error("无法保存 RPG 截图：%s" % filename)
		quit(1)
	await process_frame
