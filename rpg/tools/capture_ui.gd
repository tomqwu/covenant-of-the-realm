extends SceneTree

const OUTPUT_DIR := "res://../docs/concepts/gameplay-ui-v1"
const CAPTURE_SAVE_PATH := "user://capture-ui-save.json"
const SaveGameScript := preload("res://src/domain/save_game.gd")


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
	instance.configure_save_path(CAPTURE_SAVE_PATH)
	root.add_child(instance)
	await _settle()
	await _save_frame("01-title-screen.png")

	instance.start_new_game()
	await _settle()
	await _save_frame("01-zhaohe-ferry.png")

	instance._on_action("talk_to_companion")
	instance._on_action("gather_moonleaf")
	instance._on_action("enter_spring")
	await _settle()
	await _save_frame("02-cangquan-battle.png")

	instance._on_action("use_talisman")
	instance._on_action("use_art")
	instance._on_action("use_art")
	await _settle()
	await _save_frame("03-spring-chamber.png")

	instance._on_action("breakthrough")
	await _settle()
	await _save_frame("04-first-breath.png")
	SaveGameScript.remove(CAPTURE_SAVE_PATH)
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
