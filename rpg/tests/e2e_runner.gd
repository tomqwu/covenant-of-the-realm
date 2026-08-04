extends SceneTree

const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const PatrolStateScript := preload("res://src/domain/patrol_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const TEST_SAVE_PATH := "user://automated-e2e-save.json"
const TEST_SETTINGS_PATH := "user://automated-e2e-settings.json"

var assertions := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveGameScript.remove(TEST_SAVE_PATH)
	SettingsStoreScript.remove(TEST_SETTINGS_PATH)
	var scene: PackedScene = load("res://src/ui/main.tscn")
	var game := scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()

	_expect(game.get_node("%TitleOverlay").visible, "E2E 从标题界面开始")
	_expect(game.settings["dialogue_speed"] == "standard" and game.get_node("%TitleDialogueSpeedButton").text == "对话显字：标准", "E2E 缺失设置使用标准对话显字")
	game.toggle_dialogue_speed()
	_expect(game.settings["dialogue_speed"] == "fast" and game.get_node("%PauseDialogueSpeedButton").text == "对话显字：快速", "E2E 标题设置同步切到快速对话显字")
	game.get_node("%NewGameButton").pressed.emit()
	await _settle()
	_expect(game.get_node("%LocationLabel").text == "照禾渡口", "E2E 新游戏进入照禾渡口")
	var initial_camera: Dictionary = game.world_camera_contract()
	_expect(initial_camera["world_size"] == Vector2(1536, 864), "E2E 新游戏载入 48×27 滚动世界")
	_expect(initial_camera["safe_frame"]["rect"].has_point(initial_camera["world_focus"] - initial_camera["origin"]), "E2E 出生点避开顶部 HUD 与底部纸面")
	_expect(game.get_node("%FerryGround").get_parent() == game.get_node("%WorldRoot") and game.get_node("%MapCanvas").get_parent() == game.get_node("%WorldRoot"), "E2E 地表、人物和交互标记共享世界镜头")
	await _trigger_semantic_action(game, "interact")
	await _settle()
	_expect(game.dialogue.active and game.get_node("%DialogueOverlay").visible, "E2E 交互开启逐句风险简报")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "yanqing", "E2E 开场台词显示砚青纸绘头像")
	game._process_dialogue_reveal(0.10)
	var fast_visible_characters: int = game.get_node("%DialogueLabel").visible_characters
	_expect(fast_visible_characters > 0 and fast_visible_characters < game.get_node("%DialogueLabel").text.length(), "E2E 快速模式仍确定性逐字显示而不自动推进")
	var speed_journey_before: Dictionary = game.journey.snapshot()
	var speed_dialogue_before: Dictionary = game.dialogue.snapshot()
	var speed_save_before := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	game.toggle_dialogue_speed()
	_expect(game.settings["dialogue_speed"] == "instant" and game.get_node("%DialogueLabel").visible_characters == -1, "E2E 切到整句模式只补全当前台词")
	_expect(_snapshots_match(game.journey.snapshot(), speed_journey_before) and game.dialogue.snapshot() == speed_dialogue_before, "E2E 对话显字不修改 Journey 或结构化对话位置")
	_expect(FileAccess.get_file_as_string(TEST_SAVE_PATH) == speed_save_before, "E2E 对话显字写入独立设置且不改动 save v17")
	game.advance_dialogue()
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "protagonist" and game.get_node("%DialogueLabel").visible_characters == -1, "E2E 整句模式下一句切换头像并完整显示")
	game.advance_dialogue()
	var interrupted_line: int = game.dialogue.line_index
	var interrupted_text: String = game.get_node("%DialogueLabel").text
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.settings["dialogue_speed"] == "instant" and game.get_node("%TitleDialogueSpeedButton").text == "对话显字：整句", "E2E 新场景先恢复整句显示偏好")
	_expect(game.continue_game(), "E2E 可从新场景恢复对话中途存档")
	_expect(game.dialogue.active and game.dialogue.line_index == interrupted_line, "E2E 中断恢复保持对话行号")
	_expect(game.get_node("%DialogueLabel").text == interrupted_text, "E2E 中断恢复保持当前台词")
	_expect(game.get_node("%DialogueLabel").visible_characters == -1, "E2E 活动对话恢复按整句偏好完整显示但不持久化逐字进度")
	game.skip_dialogue_to_response()
	await _settle()
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "protagonist", "E2E 回应阶段明确由主角作出选择")
	await _press_dialogue_choice(game, "先看退路，再进山。")
	_expect(game.journey.talked_to_companion, "E2E 选择谨慎回应完成风险简报")
	_expect(game.get_node("%ObjectiveLabel").text.contains("月芽田"), "E2E 简报后任务切换到采药")
	var initial_patrol_visual: Dictionary = game.get_node("%MapCanvas").patrol_visual_contract()
	_expect(initial_patrol_visual["visible"] and initial_patrol_visual["active"], "E2E 简报后陶小满以独立巡路角色进入渡口")
	_expect(initial_patrol_visual["normalized_position"].is_equal_approx(Vector2(0.55, 0.66)), "E2E 陶小满从固定南侧停留点开始巡路")

	game.move_player(Vector2.DOWN, 0.50)
	game.move_player(Vector2.RIGHT, 0.266667)
	await _settle()
	_expect(game.nearby_action_id == "talk_to_patrol_runner", "E2E 玩家可从出生点公开步行接近陶小满")
	_expect(game.patrol.yielding_to_player, "E2E 玩家进入礼让半径后陶小满暂停巡路")
	var yielded_patrol: Dictionary = game.patrol.snapshot()
	game.patrol.advance(0.75, game.exploration.player_position)
	_expect(_snapshots_match(game.patrol.snapshot(), yielded_patrol), "E2E 礼让期间推进时间不会让巡路行动从玩家面前消失")
	game.move_player(Vector2.LEFT, 0.50)
	await _settle()
	var resumed_patrol_before: Dictionary = game.patrol.snapshot()
	game.patrol.advance(0.25, game.exploration.player_position)
	_expect(not game.patrol.yielding_to_player and not _snapshots_match(game.patrol.snapshot(), resumed_patrol_before), "E2E 玩家离开迟滞半径后巡路恢复")
	game.toggle_pause_menu()
	var paused_patrol: Dictionary = game.patrol.snapshot()
	game._process(1.0)
	_expect(_snapshots_match(game.patrol.snapshot(), paused_patrol), "E2E 暂停菜单冻结巡路时钟")
	game.toggle_pause_menu()
	game._process(0.25)
	_expect(not _snapshots_match(game.patrol.snapshot(), paused_patrol), "E2E 关闭暂停菜单后巡路时钟继续")

	game.patrol.reset()
	game._render([])
	game.move_player(Vector2.RIGHT, 0.50)
	await _settle()
	await _trigger_semantic_action(game, "interact")
	_expect(game.dialogue.active and game.dialogue.dialogue_id == "patrol_runner_briefing", "E2E 近距离交互开启陶小满巡路对话")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "tao_xiaoman", "E2E 陶小满台词显示独立纸绘头像")
	_expect(game.get_node("%DialoguePortraitLabel").text == "陶小满 · 照禾渡口跑腿人", "E2E 陶小满头像保留中文身份说明")
	game.show_full_dialogue_line()
	game.advance_dialogue()
	var patrol_dialogue_line: int = game.dialogue.line_index
	var patrol_dialogue_text: String = game.get_node("%DialogueLabel").text
	var patrol_dialogue_snapshot: Dictionary = game.patrol.snapshot()
	var patrol_dialogue_disk: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect(patrol_dialogue_disk["data"]["save_version"] == SaveGameScript.SAVE_VERSION, "E2E 巡路对话写入 save v17")
	_expect(_snapshots_match(patrol_dialogue_disk["data"]["patrol"], patrol_dialogue_snapshot), "E2E save v17 顶层保存完整巡路快照")
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复陶小满对话")
	_expect(game.dialogue.dialogue_id == "patrol_runner_briefing" and game.dialogue.line_index == patrol_dialogue_line, "E2E 巡路对话恢复保持稳定标识与行号")
	_expect(game.get_node("%DialogueLabel").text == patrol_dialogue_text, "E2E 巡路对话恢复保持当前台词")
	_expect(_snapshots_match(game.patrol.snapshot(), patrol_dialogue_snapshot), "E2E 巡路对话恢复保持顶层 patrol 位置、目标与礼让状态")
	game.skip_dialogue_to_response()
	await _settle()
	await _press_dialogue_choice(game, "木楔怕潮，先送船架。")
	_expect(game.journey.patrol_response == "boat_first", "E2E 主路线保存先送船架选择")
	_expect(game.patrol.target_index == 1 and game.patrol.route_step == -1, "E2E 先送船架立即把确定性路线指向西端")
	var chosen_patrol_disk: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect(chosen_patrol_disk["data"]["journey"]["patrol_response"] == "boat_first", "E2E 巡路先后进入 v17 旅程快照")
	_expect(_snapshots_match(chosen_patrol_disk["data"]["patrol"], game.patrol.snapshot()), "E2E 路线重定向与选择原子写入同一 v17 存档")
	var boat_distance_before: float = game.patrol.position.distance_to(PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT])
	game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51})
	game.patrol.advance(0.25, game.exploration.player_position)
	_expect(game.patrol.position.distance_to(PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT]) < boat_distance_before, "E2E 木楔优先后的首次位移实际接近补船架")
	_expect(game.get_node("%EventLabel").text.contains("木楔"), "E2E 巡路选择显示原创中文结果")

	var boat_priority_context: Dictionary = _wait_for_worksite(
		game,
		PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT],
		"talk_at_boat_worksite",
		"木楔优先路线抵达补船工位"
	)
	_expect(boat_priority_context.get("worksite_id") == "boat" and boat_priority_context.get("route_role") == "priority", "E2E 补船端点识别木楔优先路线")
	var boat_priority_journey: Dictionary = game.journey.snapshot()
	await _trigger_semantic_action(game, "interact")
	_expect(game.dialogue.active and game.dialogue.dialogue_id == "patrol_boat_priority", "E2E 补船优先端点开启结构化空间回响")
	game.show_full_dialogue_line()
	game.advance_dialogue()
	var boat_worksite_line: int = game.dialogue.line_index
	var boat_worksite_text: String = game.get_node("%DialogueLabel").text
	var boat_worksite_patrol: Dictionary = game.patrol.snapshot()
	var boat_worksite_disk: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect(boat_worksite_disk["data"]["save_version"] == SaveGameScript.SAVE_VERSION, "E2E 工位中途对话写入 save v17")
	_expect(_snapshots_match(boat_worksite_disk["data"]["journey"], boat_priority_journey), "E2E 工位对话不提前改写旅程")
	_expect(_snapshots_match(boat_worksite_disk["data"]["patrol"], boat_worksite_patrol), "E2E 工位中途存档保留端点停留")
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复补船工位中途对话")
	_expect(game.dialogue.dialogue_id == "patrol_boat_priority" and game.dialogue.line_index == boat_worksite_line, "E2E 工位恢复保持路线对话标识与行号")
	_expect(game.get_node("%DialogueLabel").text == boat_worksite_text, "E2E 工位恢复保持当前原创台词")
	_expect(_snapshots_match(game.patrol.snapshot(), boat_worksite_patrol), "E2E 工位恢复保持端点坐标、目标与停留")
	_expect(_snapshots_match(game.journey.snapshot(), boat_priority_journey), "E2E 工位恢复不伪造奖励或剧情进度")
	game.skip_dialogue_to_response()
	await _settle()
	await _press_dialogue_choice(game, "替她压稳篷布边角。")
	_expect(_snapshots_match(game.journey.snapshot(), boat_priority_journey), "E2E 压住油布只结束工位停留而不改变 Journey")
	_expect(game.get_node("%EventLabel").text == str(game.content["messages"]["patrol_boat_cloth_secured"]), "E2E 补船工位选项返回稳定语义回声")
	_expect(game.patrol.worksite_context(game.journey.patrol_response).is_empty(), "E2E 补船回应后当前停留结束")
	_expect(is_zero_approx(game.patrol.dwell_remaining), "E2E 补船回应把当前端点停留归零")
	_expect(game.exploration.restore({
		"map_id": "zhaohe_ferry",
		"player_x": ExplorationStateScript.BOAT_REPAIR_POSITION.x,
		"player_y": ExplorationStateScript.BOAT_REPAIR_POSITION.y,
	}), "E2E 工位回应后站到补船木架")
	game._render([])
	_expect(game.nearby_action_id == "inspect_boat_repair", "E2E 陶小满离开当前停留后固定补船地标立即恢复")

	var herbs_followup_context: Dictionary = _wait_for_worksite(
		game,
		PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT],
		"talk_at_herbs_worksite",
		"木楔优先路线继续抵达晾晒工位"
	)
	_expect(herbs_followup_context.get("worksite_id") == "herbs" and herbs_followup_context.get("route_role") == "followup", "E2E 晾晒端点识别木楔优先的后续工位")
	await _complete_worksite_dialogue(
		game,
		"patrol_herbs_followup",
		"陪她看清叶背日影。",
		"patrol_herbs_light_checked",
		"木楔优先路线的晾晒后续回响"
	)
	var repeated_boat_context: Dictionary = _wait_for_worksite(
		game,
		PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT],
		"talk_at_boat_worksite",
		"巡路一轮后重新抵达补船工位"
	)
	_expect(repeated_boat_context.get("route_role") == "priority", "E2E 无一次性标记的补船空间回响可重复")
	await _complete_worksite_dialogue(
		game,
		"patrol_boat_priority",
		"陪她核对木楔尺痕。",
		"patrol_boat_measure_checked",
		"巡路一轮后重复补船回响"
	)
	game.open_journal()
	await _settle()
	_expect(game.journal_contract()["entries_text"].contains("先往补船架的脚步"), "E2E 巡路结果进入内容驱动札记")
	game.close_journal()
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51}), "E2E 巡路支线后返回同行起点")
	game._render([])

	game.move_player(Vector2.LEFT, 0.27)
	game.move_player(Vector2.UP, 0.80)
	await _settle()
	var boat_life_snapshot: Dictionary = game.journey.snapshot()
	await _press_action(game, "查看补船木架")
	_expect(game.get_node("%EventLabel").text.contains("湿麻绳和桐油"), "E2E 公开移动到补船木架并显示中文生活事件")
	_expect(game.journey.snapshot() == boat_life_snapshot, "E2E 补船木架不修改完整旅程快照")
	await _press_action(game, "查看补船木架")
	_expect(game.journey.snapshot() == boat_life_snapshot, "E2E 补船木架可重复且仍不修改旅程快照")

	game.move_player(Vector2.DOWN, 0.80)
	game.move_player(Vector2.RIGHT, 0.27)
	game.move_player(Vector2.LEFT, 0.10)
	game.move_player(Vector2.UP, 1.17)
	game.move_player(Vector2.RIGHT, 1.60)
	game.move_player(Vector2.DOWN, 0.91)
	await _settle()
	var drying_life_snapshot: Dictionary = game.journey.snapshot()
	await _press_action(game, "查看晾晒竹架")
	_expect(game.get_node("%EventLabel").text.contains("药香与河风"), "E2E 公开移动到晾晒竹架并显示中文生活事件")
	_expect(game.journey.snapshot() == drying_life_snapshot, "E2E 晾晒竹架不修改完整旅程快照")
	await _press_action(game, "查看晾晒竹架")
	_expect(game.journey.snapshot() == drying_life_snapshot, "E2E 晾晒竹架可重复且仍不修改旅程快照")

	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.41, "player_y": 0.66}), "E2E 到达渡口守堤人")
	game._render([])
	await _trigger_semantic_action(game, "interact")
	_expect(game.dialogue.dialogue_id == "ferryman_briefing", "E2E 开启守堤支线对话")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "liangshu", "E2E 守堤台词显示梁叔纸绘头像")
	game.skip_dialogue_to_response()
	await _settle()
	await _press_dialogue_choice(game, "一起扶正水尺。")
	_expect(game.journey.ferryman_response == "repair", "E2E 主路线保存扶尺选择")
	_expect(game.get_node("%MapCanvas").ferryman_visual_contract()["gauge_upright"], "E2E 扶尺后地图残留直立水尺")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.43, "player_y": 0.42}), "E2E 到达渡口旧水痕")
	game._render([])
	await _trigger_semantic_action(game, "interact")
	_expect(game.journey.discoveries == ["ferry_watermark"], "E2E 语义交互记录渡口见闻")
	_expect(game.get_node("%EventLabel").text.contains("转移药苗"), "E2E 呈现渡口环境历史")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51}), "E2E 调查后回到同行起点")
	game._render([])

	game.move_player(Vector2.DOWN, 0.40)
	game.move_player(Vector2.RIGHT, 0.74)
	await _settle()
	await _trigger_semantic_action(game, "interact")
	await _settle()
	_expect(game.journey.gathered_moonleaf, "E2E 通过语义交互采集月芽草")
	_expect(game.journey.moonleaf_method == "whole_plant", "E2E 语义交互保留向后兼容的旧规取药")

	game.move_player(Vector2.LEFT, 0.82)
	game.move_player(Vector2.UP, 1.56)
	game.move_player(Vector2.RIGHT, 1.46)
	game.move_player(Vector2.DOWN, 0.06)
	await _settle()
	await _press_action(game, "进入藏泉山道")
	_expect(game.journey.phase_id() == "mountain_path", "E2E 从山门进入可探索山道")
	_expect(game.exploration.map_id == "cangquan_path", "E2E 山道使用独立地图标识")
	var path_camera: Dictionary = game.world_camera_contract()
	_expect(path_camera["normalized_focus"].is_equal_approx(game.exploration.player_position), "E2E 换图在同一帧把镜头重定位到山道出生点")
	_expect(path_camera["pixel_snap"], "E2E 山道换图不产生半像素镜头")
	game.get_node("%SceneTransition").finish()
	var path_spawn: Dictionary = game.exploration.snapshot()
	var path_keeper_visual: Dictionary = game.get_node("%MapCanvas").path_keeper_visual_contract()
	_expect(path_keeper_visual["visible"] and path_keeper_visual["active"], "E2E 岑苇以独立巡山角色进入山道")
	_expect(path_keeper_visual["normalized_position"].is_equal_approx(game.path_keeper.position), "E2E 岑苇地图坐标来自确定性巡山状态")
	_expect(game.get_node("%PathKeeperSprite").animation_contract()["frame_size"] == Vector2(32, 56), "E2E 岑苇使用四向 32×56 像素人物合同")
	var path_keeper_before_pause: Dictionary = game.path_keeper.snapshot()
	game.toggle_pause_menu()
	game._process(1.0)
	_expect(_snapshots_match(game.path_keeper.snapshot(), path_keeper_before_pause), "E2E 暂停菜单冻结岑苇巡山时钟")
	game.toggle_pause_menu()
	game._process(0.25)
	_expect(not _snapshots_match(game.path_keeper.snapshot(), path_keeper_before_pause), "E2E 关闭暂停后岑苇继续巡山")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": game.path_keeper.position.x, "player_y": game.path_keeper.position.y}), "E2E 玩家可站到岑苇当前路线位置")
	game._render([])
	_expect(game.nearby_action_id == "talk_to_path_keeper", "E2E 岑苇在全路线提供稳定近距行动")
	var path_keeper_journey_before: Dictionary = game.journey.snapshot()
	await _press_action(game, "问问岑苇")
	_expect(game.get_node("%EventLabel").text.contains("亮面朝下山"), "E2E 初见岑苇呈现原创巡山路签回声")
	_expect(_snapshots_match(game.journey.snapshot(), path_keeper_journey_before), "E2E 问路回声不修改 Journey 或发放隐藏奖励")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.40, "player_y": 0.30}), "E2E 玩家可离开岑苇礼让半径")
	game._render([])
	var path_keeper_before_route: Dictionary = game.path_keeper.snapshot()
	game._process(2.0)
	_expect(not _snapshots_match(game.path_keeper.snapshot(), path_keeper_before_route), "E2E 岑苇在有界时间内沿四点路线继续移动")
	_expect(game.exploration.restore(path_spawn), "E2E 巡山验收后恢复山道出生点")
	game._render([])
	game.move_player(Vector2.UP, 0.20)
	game.move_player(Vector2.RIGHT, 1.24)
	game.move_player(Vector2.DOWN, 0.17)
	await _settle()
	var shelter_life_snapshot: Dictionary = game.journey.snapshot()
	await _press_action(game, "查看避雨石棚")
	_expect(game.get_node("%EventLabel").text.contains("取一束，后来补一束"), "E2E 公开移动到避雨石棚并显示中文生活旧规")
	_expect(game.journey.snapshot() == shelter_life_snapshot, "E2E 避雨石棚不修改完整旅程快照")
	await _press_action(game, "查看避雨石棚")
	_expect(game.journey.snapshot() == shelter_life_snapshot, "E2E 避雨石棚可重复且仍不修改旅程快照")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.40, "player_y": 0.30}), "E2E 到达石缝泉纹")
	game._render([])
	await _trigger_semantic_action(game, "interact")
	_expect(game.journey.discoveries == ["ferry_watermark", "spring_seam"], "E2E 山道见闻追加到同一存档列表")
	_expect(SaveGameScript.read(TEST_SAVE_PATH)["data"]["exploration"]["map_id"] == "cangquan_path", "E2E 山道地图与坐标自动保存")
	var saved_path_keeper: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)["data"]["path_keeper"]
	var saved_path_camera: Dictionary = game.world_camera_contract()
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复山道中途存档")
	_expect(game.journey.phase_id() == "mountain_path" and game.exploration.map_id == "cangquan_path", "E2E 中途恢复保持剧情与地图一致")
	_expect(game.journey.discoveries == ["ferry_watermark", "spring_seam"], "E2E 中途恢复保持已读环境见闻")
	_expect(game.journey.ferryman_response == "repair", "E2E 中途恢复保持守堤选择")
	_expect(game.world_camera_contract()["origin"] == saved_path_camera["origin"], "E2E 中途读档恢复相同整数像素镜头原点")
	_expect(game.world_camera_contract()["normalized_focus"].is_equal_approx(game.exploration.player_position), "E2E 读档镜头焦点与恢复坐标一致")
	_expect(_snapshots_match(game.path_keeper.snapshot(), saved_path_keeper), "E2E save v17 精确恢复岑苇位置、目标、方向、停留与礼让状态")
	game.get_node("%SceneTransition").finish()
	await _settle()
	game.open_journal()
	await _settle()
	var resumed_journal: Dictionary = game.journal_contract()
	_expect(resumed_journal["visible"] and resumed_journal["discovered_count"] == 2, "E2E 读档后的札记恢复两处见闻")
	_expect(resumed_journal["entries_text"].contains("分向旧圃的泉纹"), "E2E 札记显示已恢复的山道条目")
	_expect(resumed_journal["unlocked_titles"].has("扶正的照禾水尺"), "E2E 札记恢复守堤结果")
	_expect(not resumed_journal["entries_text"].contains("换过两次的提绳"), "E2E 札记不剧透仍未发现的药篓标题")
	game.close_journal()
	var resumed_follow: Dictionary = game.get_node("%MapCanvas").companion_follow_contract()
	_expect(resumed_follow["context_id"] == "mountain_path" and resumed_follow["point_count"] == 2, "E2E 读档在当前地图重建同行轨迹")
	_expect(game.exploration.player_position.distance_to(resumed_follow["normalized_position"]) < 0.05, "E2E 读档把砚青放在主角安全近旁")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.68, "player_y": 0.60}), "E2E 到达弃置药篓")
	game._render([])
	await _trigger_semantic_action(game, "interact")
	_expect(game.journey.discoveries == ["ferry_watermark", "spring_seam", "abandoned_basket"], "E2E 药篓生活痕迹进入持久见闻")
	_expect(game.get_node("%EventLabel").text.contains("提绳"), "E2E 药篓调查呈现原创空间线索")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.10, "player_y": 0.68}), "E2E 到达山道退路")
	game._render([])
	await _trigger_semantic_action(game, "interact")
	_expect(game.journey.phase_id() == "riverbank" and game.exploration.map_id == "zhaohe_ferry", "E2E 可从山道主动返回渡口")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.75, "player_y": 0.66}), "E2E 带药篓到达渡口药圃守")
	game._render([])
	await _trigger_semantic_action(game, "interact")
	_expect(game.dialogue.active and game.dialogue.dialogue_id == "herbkeeper_basket", "E2E 开启蕙婶药篓支线")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "huishen", "E2E 药篓台词显示蕙婶纸绘头像")
	game.show_full_dialogue_line()
	game.advance_dialogue()
	var basket_line: int = game.dialogue.line_index
	var basket_text: String = game.get_node("%DialogueLabel").text
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复药篓对话")
	_expect(game.dialogue.dialogue_id == "herbkeeper_basket" and game.dialogue.line_index == basket_line, "E2E 药篓对话恢复保持稳定标识与行号")
	_expect(game.get_node("%DialogueLabel").text == basket_text, "E2E 药篓对话恢复保持当前台词")
	game.skip_dialogue_to_response()
	await _settle()
	await _press_dialogue_choice(game, "把药篓带回圃里。")
	_expect(game.journey.basket_response == "return", "E2E 主路线保存药篓归圃选择")
	_expect(game.get_node("%MapCanvas").basket_visual_contract()["returned_to_ferry"], "E2E 归圃后渡口留下公用药篓")
	game.open_journal()
	await _settle()
	_expect(game.journal_contract()["unlocked_titles"].has("回到药圃的公用篓"), "E2E 药篓结果进入内容驱动札记")
	game.close_journal()
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "E2E 返回后再次到达山门")
	game._render([])
	await _trigger_semantic_action(game, "interact")
	_expect(game.journey.phase_id() == "mountain_path", "E2E 返回后可以再次进入山道")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.43, "player_y": 0.57}), "E2E 到达旧石标")
	game._render([])
	await _trigger_semantic_action(game, "interact")
	_expect(game.get_node("%EventLabel").text.contains("箭记"), "E2E 调查旧石标")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.73, "player_y": 0.34}), "E2E 到达敌人预警区")
	game._render([])
	await _trigger_semantic_action(game, "interact")
	_expect(game.journey.phase_id() == "battle", "E2E 接近敌人才进入战斗")
	var battle_camera: Dictionary = game.world_camera_contract()
	var battle_safe_frame: Rect2 = battle_camera["safe_frame"]["rect"]
	for battle_actor_path in ["%PlayerSprite", "%CompanionSprite", "%BattleEnemySprite"]:
		var battle_actor: Node2D = game.get_node(battle_actor_path)
		_expect(battle_safe_frame.has_point(battle_actor.position - battle_camera["origin"]), "E2E 战斗演员保持在 HUD 与行动纸面之间")
	var unknown_intent: Dictionary = game.get_node("%IntentTelegraph").presentation_contract()
	_expect(
		unknown_intent["active"]
		and unknown_intent["enemy_id"] == "rock_armor_young"
		and unknown_intent["intent_id"] == "rock_probing_charge"
		and unknown_intent["current_name"] == "试探冲撞"
		and unknown_intent["current_damage"] == 3
		and unknown_intent["recognized_intent"]
		and unknown_intent["shape_id"] == "probing_charge",
		"E2E 未调查时独立势签明示当前敌势、伤害与稳定图形"
	)
	_expect(
		not unknown_intent["intel_known"]
		and not unknown_intent["next_intent_visible"]
		and unknown_intent["next_intent_id"] == ""
		and unknown_intent["counter_text"] == ""
		and unknown_intent["second_line"] == "敌迹未辨　｜　后一势与破绽暂不显示",
		"E2E 未调查时独立势签不剧透后一势与应对"
	)
	await _press_action(game, "撤到旧石标")
	var retreat_feedback: Dictionary = game.get_node("%MapCanvas").feedback_contract()
	_expect(
		game.journey.phase_id() == "mountain_path"
		and not retreat_feedback["active"]
		and retreat_feedback["text"] == ""
		and retreat_feedback["enemy_id_before"] == ""
		and retreat_feedback["announced_intent_id"] == ""
		and retreat_feedback["resolved_intent_id"] == ""
		and retreat_feedback["outgoing_enemy_id"] == ""
		and retreat_feedback["replacement_enemy_id"] == "",
		"E2E 可沿退路撤到山道并清空动作前敌人与意图瞬时上下文"
	)
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": game.path_keeper.position.x, "player_y": game.path_keeper.position.y}), "E2E 撤退后可在当前巡山位置找到岑苇")
	game._render([])
	var setback_path_keeper_journey: Dictionary = game.journey.snapshot()
	await _press_action(game, "问问岑苇")
	_expect(game.get_node("%EventLabel").text.contains("退回来不是走错"), "E2E 战斗撤退后岑苇给出进度感知的温和回声")
	_expect(_snapshots_match(game.journey.snapshot(), setback_path_keeper_journey), "E2E 撤退回声仍不取得任务、战斗或奖励权威")
	for spoor_case in [
		{"position": Vector2(0.65, 0.22), "intel_id": "rock_armor_young", "event_text": "两短一深"},
		{"position": Vector2(0.36, 0.43), "intel_id": "spring_moss_shell", "event_text": "孢尘"},
		{"position": Vector2(0.91, 0.34), "intel_id": "unbalanced_stone_puppet", "event_text": "拖痕"},
	]:
		_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": spoor_case["position"].x, "player_y": spoor_case["position"].y}), "E2E 到达三痕辨势位置")
		game._render([])
		await _trigger_semantic_action(game, "interact")
		_expect(game.journey.enemy_intel.has(spoor_case["intel_id"]), "E2E 调查后记录稳定灵物标识")
		_expect(game.get_node("%EventLabel").text.contains(spoor_case["event_text"]), "E2E 三处痕迹各自呈现原创空间线索")
	var spoor_visual: Dictionary = game.get_node("%MapCanvas").enemy_intel_visual_contract()
	_expect(spoor_visual["read_count"] == 3 and spoor_visual["studied"] == game.journey.enemy_intel, "E2E 三处已读痕迹保留地图残痕")
	game.open_journal()
	await _settle()
	game.select_journal_page(1)
	var intel_journal: Dictionary = game.journal_contract()
	_expect(intel_journal["page_title"] == "灵物志" and intel_journal["intel_count"] == 3, "E2E 灵物志为可选第二页并回显三项敌情")
	_expect(intel_journal["enemy_titles"].has("岩甲幼兽 · 两短一深") and intel_journal["entries_text"].contains("只在吸潮时"), "E2E 灵物志显示内容驱动的痕迹、行止与应对")
	game.close_journal()
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.56, "player_y": 0.48}), "E2E 撤退后接近另一种敌人")
	game._render([])
	await _press_action(game, "触碰泉苔寄壳")
	_expect(game.journey.enemy_id == "spring_moss_shell", "E2E 非默认遭遇选择泉苔配置")
	var known_moss_intent: Dictionary = game.get_node("%IntentTelegraph").presentation_contract()
	_expect(
		known_moss_intent["active"]
		and known_moss_intent["enemy_id"] == "spring_moss_shell"
		and known_moss_intent["intent_id"] == "moss_absorb_tide"
		and known_moss_intent["shape_id"] == "absorb_tide"
		and known_moss_intent["intel_known"],
		"E2E 已读泉苔敌情由独立势签显示当前吸潮势"
	)
	_expect(
		known_moss_intent["next_intent_visible"]
		and known_moss_intent["next_intent_id"] == "moss_spore_spray"
		and known_moss_intent["counter_text"] == "引气术"
		and known_moss_intent["second_line"].contains("喷苔孢雾")
		and known_moss_intent["second_line"].contains("破绽　引气术"),
		"E2E 已读泉苔敌情显示后一势与当前破绽"
	)
	var saved_intent: String = game.journey.current_enemy_intent()["name"]
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复非默认敌人战斗")
	_expect(game.journey.enemy_id == "spring_moss_shell", "E2E 战斗恢复保持敌人标识")
	_expect(game.journey.current_enemy_intent()["name"] == saved_intent, "E2E 战斗恢复保持下一意图")
	_expect(game.get_node("%BattleEnemySprite").animation == &"idle_spring_moss_shell", "E2E 读档只恢复敌人规则标识，不持久化旧表现姿态")
	var restored_moss_intent: Dictionary = game.get_node("%IntentTelegraph").presentation_contract()
	_expect(
		restored_moss_intent["active"]
		and restored_moss_intent["enemy_id"] == "spring_moss_shell"
		and restored_moss_intent["intent_id"] == "moss_absorb_tide"
		and restored_moss_intent["intel_known"],
		"E2E 读档从规则快照重建泉苔势签"
	)
	var restored_moss_feedback: Dictionary = game.get_node("%MapCanvas").feedback_contract()
	_expect(
		restored_moss_feedback["enemy_id_before"] == ""
		and restored_moss_feedback["announced_intent_id"] == ""
		and restored_moss_feedback["resolved_intent_id"] == ""
		and restored_moss_feedback["outgoing_enemy_id"] == ""
		and restored_moss_feedback["replacement_enemy_id"] == "",
		"E2E 读档不恢复上一场景的瞬时战斗反馈身份"
	)
	var restored_moss_accent: Dictionary = game.get_node("%MapCanvas").attack_accent_contract()
	_expect(
		not restored_moss_accent["active"]
		and restored_moss_accent["enemy_id_before"] == ""
		and restored_moss_accent["resolved_intent_id"] == ""
		and restored_moss_accent["resolution_event_id"] == ""
		and restored_moss_accent["shape_id"] == ""
		and restored_moss_accent["label_text"] == "",
		"E2E 读档不恢复上一场景的敌足攻击势痕"
	)
	await _press_action(game, "布置引泉石灯")
	_expect(game.journey.lamp_turns == 1, "E2E 战术石灯进入持续状态")
	_expect(game.get_node("%BattleEnemySprite").presentation_contract()["state"] == "attack", "E2E 石灯回合消费敌方攻击语义")
	var moss_absorb_accent: Dictionary = game.get_node("%MapCanvas").attack_accent_contract()
	var advanced_spore_telegraph: Dictionary = game.get_node("%IntentTelegraph").presentation_contract()
	_expect(
		moss_absorb_accent["active"]
		and moss_absorb_accent["enemy_id_before"] == "spring_moss_shell"
		and moss_absorb_accent["resolved_intent_id"] == "moss_absorb_tide"
		and moss_absorb_accent["resolution_event_id"] == "enemy_glanced"
		and moss_absorb_accent["shape_id"] == "absorb_tide"
		and moss_absorb_accent["label_text"] == "刚才 · 吸潮蓄壳 · 化开冲势"
		and advanced_spore_telegraph["intent_id"] == "moss_spore_spray"
		and advanced_spore_telegraph["shape_id"] == "spore_spray",
		"E2E 石灯结算同帧以“刚才”势痕保留旧吸潮势，顶部势签已推进到孢雾"
	)
	_expect(
		moss_absorb_accent["supported_intent_ids"].size() == 9
		and moss_absorb_accent["supported_shape_ids"].size() == 9
		and typeof(moss_absorb_accent["source_anchor"]) == TYPE_VECTOR2
		and typeof(moss_absorb_accent["target_anchor"]) == TYPE_VECTOR2
		and typeof(moss_absorb_accent["shape_bounds"]) == TYPE_RECT2
		and typeof(moss_absorb_accent["label_bounds"]) == TYPE_RECT2
		and moss_absorb_accent["shape_bounds"].has_area()
		and moss_absorb_accent["label_bounds"].has_area()
		and moss_absorb_accent["duration"] == 0.70
		and moss_absorb_accent["remaining"] > 0.0
		and moss_absorb_accent["remaining"] <= moss_absorb_accent["duration"]
		and moss_absorb_accent["motion_enabled"]
		and not moss_absorb_accent["reduced_motion_static"]
		and moss_absorb_accent["world_space"]
		and moss_absorb_accent["decorative_only"]
		and not moss_absorb_accent["blocks_input"]
		and _attack_accent_has_zero_authority(moss_absorb_accent),
		"E2E 标准势痕暴露九形、安全框、时序与零权威公开合同"
	)
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 势痕活跃时可从新场景恢复同一泉苔战斗")
	_expect(
		game.journey.phase_id() == "battle"
		and game.journey.enemy_id == "spring_moss_shell"
		and game.get_node("%IntentTelegraph").presentation_contract()["intent_id"] == "moss_spore_spray",
		"E2E 势痕活跃时的读档只恢复同一战斗的下一规则意图"
	)
	var restored_armed_accent: Dictionary = game.get_node("%MapCanvas").attack_accent_contract()
	_expect(
		not restored_armed_accent["active"]
		and restored_armed_accent["enemy_id_before"] == ""
		and restored_armed_accent["resolved_intent_id"] == ""
		and restored_armed_accent["resolution_event_id"] == ""
		and restored_armed_accent["shape_id"] == ""
		and restored_armed_accent["label_text"] == ""
		and is_zero_approx(restored_armed_accent["remaining"]),
		"E2E 保存、重建与继续同一战斗不会持久化或重放旧敌足势痕"
	)
	game.toggle_battle_speed()
	game.toggle_reduced_motion()
	game.toggle_text_scale()
	game.toggle_high_contrast()
	await _press_action(game, "请砚青援护")
	_expect(game.get_node("%BattleEnemySprite").presentation_contract()["state"] == "attack", "E2E 援护回合仍呈现敌方回应")
	var moss_spore_accent: Dictionary = game.get_node("%MapCanvas").attack_accent_contract()
	_expect(
		moss_spore_accent["active"]
		and moss_spore_accent["enemy_id_before"] == "spring_moss_shell"
		and moss_spore_accent["resolved_intent_id"] == "moss_spore_spray"
		and moss_spore_accent["resolution_event_id"] == "enemy_glanced"
		and moss_spore_accent["shape_id"] == "spore_spray"
		and moss_spore_accent["label_text"] == "刚才 · 喷苔孢雾 · 化开冲势"
		and moss_spore_accent["duration"] == 0.18
		and moss_spore_accent["reduced_motion_static"]
		and moss_spore_accent["large_text"]
		and moss_spore_accent["label_font_size"] == 23
		and moss_spore_accent["label_bounds"].size.y == 40.0
		and moss_spore_accent["high_contrast"]
		and moss_spore_accent["panel_color"] == Color("fdfaf1")
		and moss_spore_accent["text_color"] == Color("131a17")
		and game.get_node("%EventLabel").text.contains("刚才 · 喷苔孢雾 · 化开冲势")
		and game.get_node("%IntentTelegraph").presentation_contract()["intent_id"] == "moss_absorb_tide",
		"E2E 快速简化动态以大字高对比势痕结算孢雾，并在持续事件文字保留同等结果"
	)
	var moss_spore_screen_bounds: Rect2 = game.get_node("%MapCanvas").get_global_transform_with_canvas() * moss_spore_accent["label_bounds"]
	var battle_screen_safe_frame: Rect2 = game.world_camera_contract()["safe_frame"]["rect"]
	var story_screen_bounds: Rect2 = game.get_node("StoryPanel").get_global_rect()
	var status_screen_bounds: Rect2 = game.get_node("StatusHud").get_global_rect()
	var intent_screen_bounds: Rect2 = game.get_node("%IntentTelegraph").get_global_rect()
	var enemy_foot_bounds := Rect2(game.get_node("%BattleEnemySprite").global_position - Vector2(24, 56), Vector2(48, 64))
	var player_foot_bounds := Rect2(game.get_node("%PlayerSprite").global_position - Vector2(24, 56), Vector2(48, 64))
	_expect(
		battle_screen_safe_frame.encloses(moss_spore_screen_bounds)
		and not moss_spore_screen_bounds.intersects(story_screen_bounds)
		and not moss_spore_screen_bounds.intersects(status_screen_bounds)
		and not moss_spore_screen_bounds.intersects(intent_screen_bounds)
		and not moss_spore_screen_bounds.intersects(enemy_foot_bounds)
		and not moss_spore_screen_bounds.intersects(player_foot_bounds),
		"E2E 大字势痕标签经世界镜头变换后仍位于屏幕安全框，且不遮挡 HUD、剧情纸面或战斗脚点"
	)
	game.toggle_battle_speed()
	game.toggle_reduced_motion()
	game.toggle_text_scale()
	game.toggle_high_contrast()
	await _press_action(game, "镇岩符")
	_expect(game.get_node("%BattleEnemySprite").presentation_contract()["state"] == "react", "E2E 符箓命中呈现泉苔受击")
	await _press_action(game, "引气术")
	_expect(game.journey.enemy_id == "rock_armor_warden", "E2E 普通遭遇后进入共享首领战")
	_expect(game.get_node("%BattleEnemySprite").animation == &"idle_rock_armor_warden", "E2E 换首领抑制旧敌受击并回到首领待机")
	var replacement_feedback: Dictionary = game.get_node("%MapCanvas").feedback_contract()
	_expect(
		replacement_feedback["enemy_id_before"] == "spring_moss_shell"
		and replacement_feedback["announced_intent_id"] == "moss_spore_spray"
		and replacement_feedback["resolved_intent_id"] == ""
		and replacement_feedback["outgoing_enemy_id"] == "spring_moss_shell"
		and replacement_feedback["replacement_enemy_id"] == "rock_armor_warden",
		"E2E 普通敌退场与首领替换保留同一行动的旧新身份"
	)
	var lethal_regular_accent: Dictionary = game.get_node("%MapCanvas").attack_accent_contract()
	_expect(
		not lethal_regular_accent["active"]
		and lethal_regular_accent["enemy_id_before"] == ""
		and lethal_regular_accent["resolved_intent_id"] == ""
		and lethal_regular_accent["resolution_event_id"] == ""
		and lethal_regular_accent["shape_id"] == ""
		and lethal_regular_accent["label_text"] == "",
		"E2E 普通敌致命回合中已公告但未执行的孢雾势不会伪造攻击势痕"
	)
	var replacement_intent: Dictionary = game.get_node("%IntentTelegraph").presentation_contract()
	_expect(
		replacement_intent["active"]
		and replacement_intent["enemy_id"] == "rock_armor_warden"
		and replacement_intent["intent_id"] == "warden_pressing_charge"
		and replacement_intent["shape_id"] == "pressing_charge"
		and replacement_intent["intel_known"]
		and replacement_intent["next_intent_id"] == "warden_stonebreaking_blow",
		"E2E 首领替换当帧只显示新敌的稳定势签身份"
	)
	_expect(
		replacement_intent["counter_text"] == ""
		and replacement_intent["second_line"].contains("本势无特定破绽"),
		"E2E 岩甲痕迹识别同类首领且不误报肩撞破绽"
	)
	var outgoing_replacement: Dictionary = game.get_node("%MapCanvas").outgoing_enemy_defeat_contract()
	_expect(
		outgoing_replacement["active"]
		and outgoing_replacement["visible"]
		and outgoing_replacement["enemy_id"] == "spring_moss_shell"
		and outgoing_replacement["state"] == "defeat"
		and outgoing_replacement["event_id"] == "regular_enemy_won"
		and outgoing_replacement["role"] == "outgoing"
		and outgoing_replacement["duration"] == 0.70
		and outgoing_replacement["motion_enabled"]
		and not outgoing_replacement["motion_skipped"]
		and not outgoing_replacement["rule_authority"]
		and not outgoing_replacement["timing_authority"]
		and not outgoing_replacement["save_authority"]
		and not outgoing_replacement["blocks_input"]
		and game.journey.enemy_id == "rock_armor_warden"
		and game.get_node("%BattleEnemySprite").enemy_id == "rock_armor_warden"
		and replacement_intent["enemy_id"] == "rock_armor_warden",
		"E2E 标准动态让旧泉苔独立退场，同时首领与当前势签保持唯一规则身份"
	)
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可恢复刚完成普通敌替换的首领战")
	var restored_replacement_feedback: Dictionary = game.get_node("%MapCanvas").feedback_contract()
	_expect(
		restored_replacement_feedback["enemy_id_before"] == ""
		and restored_replacement_feedback["announced_intent_id"] == ""
		and restored_replacement_feedback["resolved_intent_id"] == ""
		and restored_replacement_feedback["outgoing_enemy_id"] == ""
		and restored_replacement_feedback["replacement_enemy_id"] == "",
		"E2E 首领替换的旧新身份属于瞬时表现且不会写入存档"
	)
	var restored_replacement_intent: Dictionary = game.get_node("%IntentTelegraph").presentation_contract()
	_expect(
		restored_replacement_intent["active"]
		and restored_replacement_intent["enemy_id"] == "rock_armor_warden"
		and restored_replacement_intent["intent_id"] == "warden_pressing_charge",
		"E2E 读档仍从首领规则状态重建当前势签"
	)
	var restored_outgoing_replacement: Dictionary = game.get_node("%MapCanvas").outgoing_enemy_defeat_contract()
	var restored_attack_accent: Dictionary = game.get_node("%MapCanvas").attack_accent_contract()
	_expect(
		not restored_outgoing_replacement["active"]
		and not restored_outgoing_replacement["visible"]
		and restored_outgoing_replacement["enemy_id"] == ""
		and restored_outgoing_replacement["state"] == "idle"
		and restored_outgoing_replacement["event_id"] == "",
		"E2E 重新实例化与继续游戏都不恢复上一场旧敌退场姿态"
	)
	_expect(
		not restored_attack_accent["active"]
		and restored_attack_accent["enemy_id_before"] == ""
		and restored_attack_accent["resolved_intent_id"] == ""
		and restored_attack_accent["resolution_event_id"] == ""
		and restored_attack_accent["shape_id"] == "",
		"E2E 继续游戏只从规则重建当前势签，不持久化旧攻击势痕"
	)
	await _press_action(game, "守势调息")
	_expect(game.journey.armor_break_turns == 0, "E2E 守势在压阵肩撞时只做普通防御")
	_expect(game.get_node("%BattleEnemySprite").presentation_contract()["state"] == "attack", "E2E 首领普通回应呈现攻击姿态")
	var post_guard_outgoing: Dictionary = game.get_node("%MapCanvas").outgoing_enemy_defeat_contract()
	_expect(
		not post_guard_outgoing["active"]
		and not post_guard_outgoing["visible"]
		and post_guard_outgoing["enemy_id"] == ""
		and game.journey.enemy_id == "rock_armor_warden"
		and game.get_node("%BattleEnemySprite").enemy_id == "rock_armor_warden",
		"E2E 读档后的下一行动只推进当前首领，不重播已清退旧敌"
	)
	var warden_pressing_accent: Dictionary = game.get_node("%MapCanvas").attack_accent_contract()
	_expect(
		warden_pressing_accent["active"]
		and warden_pressing_accent["enemy_id_before"] == "rock_armor_warden"
		and warden_pressing_accent["resolved_intent_id"] == "warden_pressing_charge"
		and warden_pressing_accent["resolution_event_id"] == "enemy_glanced"
		and warden_pressing_accent["shape_id"] == "pressing_charge"
		and warden_pressing_accent["label_text"] == "刚才 · 压阵肩撞 · 化开冲势",
		"E2E 首领守势先保留已结算的压阵肩撞势痕"
	)
	var stonebreaking_intent: Dictionary = game.get_node("%IntentTelegraph").presentation_contract()
	_expect(
		stonebreaking_intent["intent_id"] == "warden_stonebreaking_blow"
		and stonebreaking_intent["shape_id"] == "stonebreaking_blow"
		and stonebreaking_intent["next_intent_id"] == "warden_nest_guard"
		and stonebreaking_intent["counter_text"] == "守势调息"
		and stonebreaking_intent["second_line"].contains("破绽　守势调息"),
		"E2E 首领重击回合由势签显示正确后一势与守势破绽"
	)
	await _press_action(game, "守势调息")
	_expect(game.journey.armor_break_turns == 2, "E2E 守势只在首领重击回合施加破甲")
	_expect(game.get_node("%BattleEnemySprite").presentation_contract()["event_id"] == "weakness_exposed", "E2E 重击破绽优先呈现首领受击")
	var warden_stonebreaking_accent: Dictionary = game.get_node("%MapCanvas").attack_accent_contract()
	_expect(
		warden_stonebreaking_accent["active"]
		and warden_stonebreaking_accent["enemy_id_before"] == "rock_armor_warden"
		and warden_stonebreaking_accent["resolved_intent_id"] == "warden_stonebreaking_blow"
		and warden_stonebreaking_accent["resolution_event_id"] == "enemy_glanced"
		and warden_stonebreaking_accent["shape_id"] == "stonebreaking_blow"
		and warden_stonebreaking_accent["label_text"] == "刚才 · 崩石重击 · 化开冲势"
		and warden_stonebreaking_accent["resolved_intent_id"] != warden_pressing_accent["resolved_intent_id"],
		"E2E 重击真实结算后立即替换肩撞势痕，不被破绽受击姿态遮掉"
	)
	await _press_action(game, "引气术")
	await _press_action(game, "请砚青援护")
	_expect(game.journey.focus_turns == 2, "E2E 同伴援护施加凝息")
	var boss_intent: String = game.journey.current_enemy_intent()["name"]
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可恢复带状态的首领战")
	_expect(game.journey.armor_break_turns == 1 and game.journey.focus_turns == 2, "E2E 恢复保留破甲与凝息层数")
	_expect(game.journey.current_enemy_intent()["name"] == boss_intent, "E2E 首领恢复保持下一意图")
	_expect(game.get_node("%BattleEnemySprite").animation == &"idle_rock_armor_warden", "E2E 首领读档从可推导待机姿态开始")
	await _press_action(game, "引气术")
	await _press_action(game, "引气术")
	_expect(game.journey.phase_id() == "spring", "E2E 击败首领后打开泉室")
	var terminal_intent: Dictionary = game.get_node("%IntentTelegraph").presentation_contract()
	var terminal_attack_accent: Dictionary = game.get_node("%MapCanvas").attack_accent_contract()
	_expect(
		not terminal_intent["active"]
		and terminal_intent["enemy_id"] == ""
		and terminal_intent["intent_id"] == ""
		and terminal_intent["first_line"] == ""
		and terminal_intent["second_line"] == "",
		"E2E 终局离开战斗时清空独立势签"
	)
	_expect(
		not terminal_attack_accent["active"]
		and terminal_attack_accent["enemy_id_before"] == ""
		and terminal_attack_accent["resolved_intent_id"] == ""
		and terminal_attack_accent["resolution_event_id"] == ""
		and terminal_attack_accent["shape_id"] == ""
		and terminal_attack_accent["label_text"] == "",
		"E2E 击败首领离开战斗时原子清空最后一道敌足势痕"
	)
	_expect(game.exploration.map_id == ExplorationStateScript.CANGQUAN_SPRING_MAP_ID, "E2E 战斗路线汇入独立藏泉石室地图")
	_expect(game.journey.first_breath_stage == "unstarted", "E2E 战斗路线从未开始的引息仪轨汇入")
	game.get_node("%SceneTransition").finish()
	await _settle()

	await _place_at_spring(game, ExplorationStateScript.SPRING_WARM_POSITION, "E2E 乱序测试先到温脉位置")
	var before_wrong_journey: Dictionary = game.journey.snapshot()
	var before_wrong_exploration: Dictionary = game.exploration.snapshot()
	var before_wrong_save := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	await _press_action(game, "月芽温脉")
	_expect(game.journey.snapshot() == before_wrong_journey, "E2E 乱序温脉不修改完整旅程快照")
	_expect(game.exploration.snapshot() == before_wrong_exploration, "E2E 乱序温脉不移动或替换石室位置")
	_expect(FileAccess.get_file_as_string(TEST_SAVE_PATH) == before_wrong_save, "E2E 乱序提示不触发自动存档写入")
	_expect(game.get_node("%MapCanvas").first_breath_visual_contract()["current_action"] == "listen_to_spring", "E2E 乱序后仍指向正确的听泉步骤而不死锁")

	await _place_at_spring(game, ExplorationStateScript.SPRING_LISTEN_POSITION, "E2E 到达听泉辨脉位置")
	await _press_action(game, "听泉辨脉")
	_expect(game.journey.first_breath_stage == "listened" and game.journey.gathered_moonleaf, "E2E 第一步听泉完成且尚未消耗月芽草")
	var listened_journey: Dictionary = game.journey.snapshot()
	var listened_exploration: Dictionary = game.exploration.snapshot()
	var listened_disk: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect(_snapshots_match(listened_disk["data"]["journey"], listened_journey), "E2E 听泉后完整旅程立即自动存档")
	_expect(_snapshots_match(listened_disk["data"]["exploration"], listened_exploration), "E2E 听泉后石室地图与坐标立即自动存档")
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复听泉后的中间存档")
	_expect(_snapshots_match(game.journey.snapshot(), listened_journey), "E2E 听泉重启恢复完整旅程快照")
	_expect(_snapshots_match(game.exploration.snapshot(), listened_exploration), "E2E 听泉重启恢复完整石室地图与坐标")
	_expect(game.get_node("%MapCanvas").first_breath_visual_contract()["current_action"] == "warm_meridians", "E2E 听泉恢复后准确指向月芽温脉")
	game.get_node("%SceneTransition").finish()
	await _settle()

	await _place_at_spring(game, ExplorationStateScript.SPRING_WARM_POSITION, "E2E 到达月芽温脉位置")
	await _press_action(game, "月芽温脉")
	_expect(game.journey.first_breath_stage == "warmed" and not game.journey.gathered_moonleaf, "E2E 第二步温脉原子消耗月芽草")
	var warmed_journey: Dictionary = game.journey.snapshot()
	var warmed_exploration: Dictionary = game.exploration.snapshot()
	var warmed_disk: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect(_snapshots_match(warmed_disk["data"]["journey"], warmed_journey), "E2E 温脉后完整旅程立即自动存档")
	_expect(_snapshots_match(warmed_disk["data"]["exploration"], warmed_exploration), "E2E 温脉后石室地图与坐标立即自动存档")
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复温脉后的中间存档")
	_expect(_snapshots_match(game.journey.snapshot(), warmed_journey), "E2E 温脉重启恢复完整旅程快照")
	_expect(_snapshots_match(game.exploration.snapshot(), warmed_exploration), "E2E 温脉重启恢复完整石室地图与坐标")
	_expect(game.get_node("%MapCanvas").first_breath_visual_contract()["current_action"] == "breakthrough", "E2E 温脉恢复后准确指向静坐引息")
	game.get_node("%SceneTransition").finish()
	await _settle()

	await _place_at_spring(game, ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION, "E2E 到达静坐引息位置")
	await _press_action(game, "静坐引息")
	_expect(game.journey.phase_id() == "complete", "E2E 完成第一次引息")
	var complete_camera: Dictionary = game.world_camera_contract()
	var complete_safe_frame: Rect2 = complete_camera["safe_frame"]["rect"]
	for complete_actor_path in ["%PlayerSprite", "%CompanionSprite"]:
		var complete_actor: Node2D = game.get_node(complete_actor_path)
		_expect(complete_safe_frame.has_point(complete_actor.position - complete_camera["origin"]), "E2E 结算演员保持在底部章节纸面之外")
	_expect(game.journey.first_breath_stage == "completed" and game.journey.realm == "引息境一层", "E2E 最终步骤完成仪轨并更新境界")
	_expect(game.get_node("%DescriptionLabel").text.contains("本节结算"), "E2E 显示章节结算")
	_expect(game.get_node("%DescriptionLabel").text.contains("见闻 3/3"), "E2E 章节结算回显实际探索完成度")
	_expect(game.get_node("%DescriptionLabel").text.contains("敌情 3/3"), "E2E 章节结算回显三痕辨势完成度")
	_expect(game.get_node("%DescriptionLabel").text.contains("水尺扶正"), "E2E 章节结算回显扶尺选择")
	_expect(game.get_node("%DescriptionLabel").text.contains("药篓归圃"), "E2E 章节结算回显药篓归圃选择")
	_expect(game.get_node("%DescriptionLabel").text.contains("先送船架"), "E2E 章节结算回显陶小满巡路先后")
	var completed_disk: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)
	_expect(_snapshots_match(completed_disk["data"]["journey"], game.journey.snapshot()), "E2E 完成态完整旅程已落盘")
	_expect(_snapshots_match(completed_disk["data"]["exploration"], game.exploration.snapshot()), "E2E 完成态仍精确保留藏泉石室地图")
	await _press_action(game, "回顾此行")
	_expect(game.dialogue.active and game.dialogue.dialogue_id == "chapter_epilogue", "E2E 完成态进入章节余波对话")
	_expect(game.get_node("%DialogueLabel").text.contains("沿途3处生活痕迹"), "E2E 余波回显实际见闻数量")
	_expect(game._resolved_dialogue_text("{intel_reflection}").contains("三种灵物"), "E2E 余波回显已辨明的三种灵物")
	_expect(game._resolved_dialogue_text("{ferryman_reflection}").contains("重新立稳"), "E2E 余波回显扶尺结果")
	_expect(game._resolved_dialogue_text("{basket_reflection}").contains("挂回圃门"), "E2E 余波回显药篓归圃结果")
	_expect(game._resolved_dialogue_text("{patrol_reflection}").contains("木楔"), "E2E 余波回显先送船架结果")
	game.show_full_dialogue_line()
	game.advance_dialogue()
	var epilogue_line: int = game.dialogue.line_index
	var epilogue_text: String = game.get_node("%DialogueLabel").text
	game.queue_free()
	await _settle()
	game = scene.instantiate()
	game.configure_save_path(TEST_SAVE_PATH)
	game.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(game.continue_game(), "E2E 可从新场景恢复章节余波对话")
	_expect(game.journey.phase_id() == "complete" and game.dialogue.dialogue_id == "chapter_epilogue", "E2E 余波恢复保持完成态与对话标识")
	_expect(game.dialogue.line_index == epilogue_line and game.get_node("%DialogueLabel").text == epilogue_text, "E2E 余波恢复保持当前行与动态文本")
	game.get_node("%SceneTransition").finish()
	game.skip_dialogue_to_response()
	await _settle()
	await _press_dialogue_choice(game, "先把所见写进札记。")
	_expect(game.get_node("%EventLabel").text.contains("逐条写进札记"), "E2E 余波回应产生内容驱动回声")

	await _press_action(game, "完成本节并返回标题")
	_expect(game.get_node("%TitleOverlay").visible, "E2E 从结算返回标题")
	var completed_save_text := FileAccess.get_file_as_string(TEST_SAVE_PATH)
	game.get_node("%NewGameButton").pressed.emit()
	await _settle()
	_expect(game.new_game_confirmation_contract()["visible"], "E2E 有进度时重新开始先进入确认态")
	_expect(game.journey.phase_id() == "complete", "E2E 覆盖确认不提前替换完成态旅程")
	_expect(FileAccess.get_file_as_string(TEST_SAVE_PATH) == completed_save_text, "E2E 覆盖确认不提前改写存档")
	game.get_node("%ContinueButton").pressed.emit()
	await _settle()
	_expect(not game.new_game_confirmation_contract()["visible"], "E2E 取消覆盖回到普通标题态")
	_expect(FileAccess.get_file_as_string(TEST_SAVE_PATH) == completed_save_text, "E2E 取消覆盖保留完整存档")
	game.queue_free()
	await _settle()

	var resumed := scene.instantiate()
	resumed.configure_save_path(TEST_SAVE_PATH)
	resumed.configure_settings_path(TEST_SETTINGS_PATH)
	root.add_child(resumed)
	await _settle()
	_expect(not resumed.get_node("%ContinueButton").disabled, "E2E 新实例发现完成存档")
	_expect(resumed.settings["dialogue_speed"] == "instant", "E2E 完成态新实例仍保留整句显示偏好")
	resumed.get_node("%ContinueButton").pressed.emit()
	await _settle()
	_expect(resumed.journey.phase_id() == "complete", "E2E 继续游戏恢复完成态")
	await _press_action(resumed, "重游序章（重置进度）")
	_expect(resumed.journey.phase_id() == "riverbank", "E2E 重游回到序章起点")
	var replay_attack_accent: Dictionary = resumed.get_node("%MapCanvas").attack_accent_contract()
	_expect(
		not replay_attack_accent["active"]
		and replay_attack_accent["enemy_id_before"] == ""
		and replay_attack_accent["resolved_intent_id"] == ""
		and replay_attack_accent["resolution_event_id"] == ""
		and replay_attack_accent["shape_id"] == ""
		and replay_attack_accent["label_text"] == ""
		and is_zero_approx(replay_attack_accent["remaining"]),
		"E2E 章节重游建立干净序章，不带入上轮攻击势痕"
	)
	_expect(resumed.settings["dialogue_speed"] == "instant", "E2E 重游只重置旅程而不清除对话显字偏好")
	_expect(resumed.exploration.player_position == ExplorationStateScript.START_POSITION, "E2E 重游重置地图坐标")
	_expect(resumed.exploration.map_id == ExplorationStateScript.DEFAULT_MAP_ID, "E2E 重游从藏泉石室清回渡口地图")
	_expect(resumed.journey.first_breath_stage == "unstarted", "E2E 重游清空三步引息进度")
	_expect(resumed.journey.enemy_intel.is_empty(), "E2E 重游只在明确重置时清空灵物志")
	resumed._on_action("talk_to_companion")
	resumed.skip_dialogue_to_response()
	await _press_dialogue_choice(resumed, "我信你的判断，一起走。")
	_expect(resumed.journey.briefing_response == "trusting", "E2E 重游可选择不同同行态度")
	resumed.move_player(Vector2.DOWN, 0.50)
	resumed.move_player(Vector2.RIGHT, 0.266667)
	await _settle()
	await _trigger_semantic_action(resumed, "interact")
	_expect(resumed.dialogue.dialogue_id == "patrol_runner_briefing", "E2E 重游仍可近距离询问陶小满")
	resumed.skip_dialogue_to_response()
	await _settle()
	await _press_dialogue_choice(resumed, "药叶怕闷，先翻竹架。")
	_expect(resumed.journey.patrol_response == "herbs_first", "E2E 重游可选择先翻药叶分支")
	_expect(resumed.patrol.target_index == 2 and resumed.patrol.route_step == 1, "E2E 先翻药叶立即把确定性路线指向东端")
	var herbs_distance_before: float = resumed.patrol.position.distance_to(PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT])
	resumed.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51})
	resumed.patrol.advance(0.25, resumed.exploration.player_position)
	_expect(resumed.patrol.position.distance_to(PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT]) < herbs_distance_before, "E2E 药叶优先后的首次位移实际接近晾晒架")
	var herbs_priority_context: Dictionary = _wait_for_worksite(
		resumed,
		PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT],
		"talk_at_herbs_worksite",
		"药叶优先重游抵达晾晒工位"
	)
	_expect(herbs_priority_context.get("worksite_id") == "herbs" and herbs_priority_context.get("route_role") == "priority", "E2E 重游晾晒端点识别药叶优先路线")
	await _complete_worksite_dialogue(
		resumed,
		"patrol_herbs_priority",
		"替她扶稳晾叶竹匾。",
		"patrol_herbs_tray_steadied",
		"药叶优先路线的晾晒优先回响"
	)
	var boat_followup_context: Dictionary = _wait_for_worksite(
		resumed,
		PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT],
		"talk_at_boat_worksite",
		"药叶优先重游继续抵达补船工位"
	)
	_expect(boat_followup_context.get("worksite_id") == "boat" and boat_followup_context.get("route_role") == "followup", "E2E 重游补船端点识别药叶优先的后续工位")
	await _complete_worksite_dialogue(
		resumed,
		"patrol_boat_followup",
		"陪她核对木楔尺痕。",
		"patrol_boat_measure_checked",
		"药叶优先路线的补船后续回响"
	)
	_expect(resumed.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.41, "player_y": 0.66}), "E2E 重游到达渡口守堤人")
	resumed._render([])
	await _trigger_semantic_action(resumed, "interact")
	resumed.skip_dialogue_to_response()
	await _settle()
	await _press_dialogue_choice(resumed, "先记下涨水时辰。")
	_expect(resumed.journey.ferryman_response == "record", "E2E 重游可选择记时分支")
	var recorded_visual: Dictionary = resumed.get_node("%MapCanvas").ferryman_visual_contract()
	_expect(recorded_visual["record_tag"] and not recorded_visual["gauge_upright"], "E2E 记时分支留下纸签而不扶正水尺")
	resumed._on_action("gather_moonleaf_cutting")
	_expect(resumed.journey.moonleaf_method == "cutting", "E2E 重游可选择剪叶留根")
	_expect(resumed.get_node("%MapCanvas").moonleaf_visual_contract()["regrowing"], "E2E 剪叶后地图显示留根新芽")
	resumed._on_action("enter_spring")
	_expect(resumed.exploration.restore({"map_id": "cangquan_path", "player_x": 0.68, "player_y": 0.60}), "E2E 重游到达山道药篓")
	resumed._render([])
	await _trigger_semantic_action(resumed, "interact")
	_expect(resumed.journey.discoveries == ["abandoned_basket"], "E2E 重游可只发现药篓见闻")
	_expect(resumed.exploration.restore({"map_id": "cangquan_path", "player_x": 0.10, "player_y": 0.68}), "E2E 重游带药篓返回山脚")
	resumed._render([])
	await _trigger_semantic_action(resumed, "interact")
	_expect(resumed.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.75, "player_y": 0.66}), "E2E 重游到达蕙婶身旁")
	resumed._render([])
	await _trigger_semantic_action(resumed, "interact")
	resumed.skip_dialogue_to_response()
	await _settle()
	await _press_dialogue_choice(resumed, "补好提绳，留在山道。")
	_expect(resumed.journey.basket_response == "trail", "E2E 重游可选择补绳留山分支")
	_expect(resumed.get_node("%MapCanvas").basket_visual_contract()["repaired_on_trail"], "E2E 留山分支进入稳定地图表现状态")
	_expect(resumed.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "E2E 重游再次到达山门")
	resumed._render([])
	await _trigger_semantic_action(resumed, "interact")
	resumed.get_node("%SceneTransition").finish()
	_expect(resumed.exploration.restore({"map_id": "cangquan_path", "player_x": resumed.path_keeper.position.x, "player_y": resumed.path_keeper.position.y}), "E2E 留山分支可在当前路线找到岑苇")
	resumed._render([])
	var trail_path_keeper_journey: Dictionary = resumed.journey.snapshot()
	await _press_action(resumed, "问问岑苇")
	_expect(resumed.get_node("%EventLabel").text.contains("篓子留在背风处"), "E2E 岑苇回应药篓留山分支且不抢主线")
	_expect(_snapshots_match(resumed.journey.snapshot(), trail_path_keeper_journey), "E2E 药篓回声不修改旅程快照")
	_expect(resumed.exploration.restore({"map_id": "cangquan_path", "player_x": 0.86, "player_y": 0.18}), "E2E 重游后到达绕行入口")
	resumed._render([])
	await _trigger_semantic_action(resumed, "interact")
	_expect(resumed.journey.phase_id() == "spring", "E2E 沿溪绕行不进入战斗即可到泉室")
	_expect(resumed.exploration.map_id == ExplorationStateScript.CANGQUAN_SPRING_MAP_ID, "E2E 绕行与战斗汇入同一藏泉石室地图")
	_expect(resumed.journey.first_breath_stage == "unstarted", "E2E 绕行不会跳过任何引息步骤")
	_expect(resumed.journey.player_hp == 12 and resumed.journey.talismans == 1 and resumed.journey.round_number == 1, "E2E 绕行保留气血、符箓和战斗回合")
	resumed.get_node("%SceneTransition").finish()
	await _settle()
	await _place_at_spring(resumed, ExplorationStateScript.SPRING_LISTEN_POSITION, "E2E 绕行路线到达听泉位置")
	await _press_action(resumed, "听泉辨脉")
	await _place_at_spring(resumed, ExplorationStateScript.SPRING_WARM_POSITION, "E2E 绕行路线到达温脉位置")
	await _press_action(resumed, "月芽温脉")
	await _place_at_spring(resumed, ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION, "E2E 绕行路线到达引息位置")
	await _press_action(resumed, "静坐引息")
	_expect(resumed.journey.first_breath_stage == "completed", "E2E 绕行路线也完成同一三步引息")
	_expect(resumed.get_node("%DescriptionLabel").text.contains("以信任同行"), "E2E 结算回应重游时的信任选择")
	_expect(resumed.get_node("%DescriptionLabel").text.contains("敌情 0/3"), "E2E 绕行结算不伪造未调查敌情")
	_expect(resumed.get_node("%DescriptionLabel").text.contains("月芽留根"), "E2E 结算回应重游时的采集选择")
	_expect(resumed.get_node("%DescriptionLabel").text.contains("涨时入簿"), "E2E 结算回应重游时的记时选择")
	_expect(resumed.get_node("%DescriptionLabel").text.contains("先翻药叶"), "E2E 结算回应重游时的另一巡路选择")
	await _press_action(resumed, "回顾此行")
	_expect(resumed.get_node("%DialogueLabel").text.contains("把月芽留了根"), "E2E 重游余波回显留根采集")
	_expect(resumed.get_node("%DialogueLabel").text.contains("沿途1处生活痕迹"), "E2E 重游余波只回显实际发现的一处见闻")
	_expect(resumed._resolved_dialogue_text("{setback_reflection}").contains("没有因求快而失手"), "E2E 无战绕行余波回显零挫败")
	_expect(resumed._resolved_dialogue_text("{companion_reflection}").contains("把判断交给同伴"), "E2E 余波回显重游时的信任回应")
	_expect(resumed._resolved_dialogue_text("{ferryman_reflection}").contains("守堤簿"), "E2E 余波回显重游时的记时结果")
	_expect(resumed._resolved_dialogue_text("{basket_reflection}").contains("仍在山道"), "E2E 余波回显重游时的药篓留山结果")
	_expect(resumed._resolved_dialogue_text("{patrol_reflection}").contains("翻好了药叶"), "E2E 余波回显重游时的先翻药叶结果")
	_expect(resumed._resolved_dialogue_text("{intel_reflection}").contains("尚未辨明"), "E2E 绕行余波不伪造灵物情报")
	resumed.skip_dialogue_to_response()
	await _press_dialogue_choice(resumed, "明日再沿河走一趟。")
	_expect(resumed.get_node("%EventLabel").text.contains("修行已经开始"), "E2E 重游可选择另一项余波收束")
	resumed.return_to_title()
	resumed.get_node("%NewGameButton").pressed.emit()
	await _settle()
	resumed.get_node("%NewGameButton").pressed.emit()
	await _settle()
	_expect(not resumed.get_node("%TitleOverlay").visible, "E2E 第二次明确确认后重新开局")
	_expect(resumed.settings["dialogue_speed"] == "instant", "E2E 明确新开序章仍保留本机对话显字偏好")
	_expect(resumed.journey.phase_id() == "riverbank" and resumed.journey.ferryman_response == "unanswered" and resumed.journey.basket_response == "unanswered" and resumed.journey.patrol_response == "unanswered", "E2E 明确覆盖建立干净序章状态")
	_expect(SaveGameScript.read(TEST_SAVE_PATH)["data"]["journey"]["phase"] == "riverbank", "E2E 新序章状态已安全落盘")
	var replay_reset_disk: Dictionary = SaveGameScript.read(TEST_SAVE_PATH)["data"]
	_expect(_snapshots_match(replay_reset_disk["patrol"], resumed.patrol.snapshot()), "E2E 新序章将默认巡路状态写入 v17 顶层")
	_expect(_snapshots_match(replay_reset_disk["path_keeper"], resumed.path_keeper.snapshot()), "E2E 新序章将默认守径状态写入 v17 顶层")

	resumed.queue_free()
	await _settle()
	SaveGameScript.remove(TEST_SAVE_PATH)
	SettingsStoreScript.remove(TEST_SETTINGS_PATH)
	if failures.is_empty():
		print("RPG E2E passed: %d assertions, new game to replay." % assertions)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _wait_for_worksite(
	game: Node,
	worksite_position: Vector2,
	expected_action_id: String,
	label: String
) -> Dictionary:
	_expect(game.exploration.restore({
		"map_id": ExplorationStateScript.DEFAULT_MAP_ID,
		"player_x": worksite_position.x,
		"player_y": worksite_position.y,
	}), "%s：玩家可以提前在端点守候" % label)
	game._render([])
	var context: Dictionary = game.patrol.worksite_context(game.journey.patrol_response)
	for _step in range(400):
		if str(context.get("action_id", "")) == expected_action_id:
			break
		game._process(0.10)
		context = game.patrol.worksite_context(game.journey.patrol_response)
	_expect(str(context.get("action_id", "")) == expected_action_id, "%s：确定性巡路在 40 秒内到达" % label)
	_expect(game.patrol.position.is_equal_approx(worksite_position), "%s：陶小满精确停在工位路点" % label)
	_expect(game.patrol.dwell_remaining > 0.0, "%s：空间回响只在端点停留期出现" % label)
	_expect(game.nearby_action_id == expected_action_id, "%s：守候玩家获得对应中文交互" % label)
	return context


func _complete_worksite_dialogue(
	game: Node,
	expected_dialogue_id: String,
	choice_label: String,
	expected_event_id: String,
	label: String
) -> void:
	var journey_before: Dictionary = game.journey.snapshot()
	var patrol_before: Dictionary = game.patrol.snapshot()
	await _trigger_semantic_action(game, "interact")
	_expect(game.dialogue.active and game.dialogue.dialogue_id == expected_dialogue_id, "%s：开启稳定路线对话" % label)
	game._process(PatrolStateScript.ENDPOINT_DWELL_SECONDS + 1.0)
	_expect(_snapshots_match(game.patrol.snapshot(), patrol_before), "%s：活动对话冻结端点巡路" % label)
	game.skip_dialogue_to_response()
	await _settle()
	await _press_dialogue_choice(game, choice_label)
	_expect(not game.dialogue.active, "%s：真实选项完成工位回响" % label)
	_expect(_snapshots_match(game.journey.snapshot(), journey_before), "%s：完成前后 Journey 逐字段不变" % label)
	_expect(game.get_node("%EventLabel").text == str(game.content["messages"][expected_event_id]), "%s：选项产生稳定内容事件" % label)
	_expect(is_zero_approx(game.patrol.dwell_remaining), "%s：完成后仅结束当前停留" % label)
	_expect(game.patrol.worksite_context(game.journey.patrol_response).is_empty(), "%s：当前工位不在离开前重复弹出" % label)


func _place_at_spring(game: Node, position: Vector2, label: String) -> void:
	_expect(game.exploration.restore({
		"map_id": ExplorationStateScript.CANGQUAN_SPRING_MAP_ID,
		"player_x": position.x,
		"player_y": position.y,
	}), label)
	game._render([])
	await _settle()


func _press_action(game: Node, label: String) -> void:
	for child in game.get_node("%Actions").get_children():
		if child is Button and child.text == label:
			child.pressed.emit()
			await _settle()
			return
	failures.append("E2E 找不到行动：%s" % label)


func _press_dialogue_choice(game: Node, label: String) -> void:
	for child in game.get_node("%DialogueChoices").get_children():
		if child is Button and child.text == label:
			child.pressed.emit()
			await _settle()
			return
	failures.append("E2E 找不到对话回应：%s" % label)


func _trigger_semantic_action(game: Node, action_name: StringName) -> void:
	var transition: Control = game.get_node("%SceneTransition")
	if transition.is_transitioning():
		transition.advance(1.0)
		await process_frame
	var pressed := InputEventAction.new()
	pressed.action = action_name
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventAction.new()
	released.action = action_name
	released.pressed = false
	Input.parse_input_event(released)
	await process_frame


func _settle() -> void:
	await process_frame
	await process_frame


func _snapshots_match(left: Variant, right: Variant) -> bool:
	var left_type := typeof(left)
	var right_type := typeof(right)
	if left_type in [TYPE_INT, TYPE_FLOAT] and right_type in [TYPE_INT, TYPE_FLOAT]:
		return is_equal_approx(float(left), float(right))
	if left_type != right_type:
		return false
	if left_type == TYPE_DICTIONARY:
		var left_dictionary: Dictionary = left
		var right_dictionary: Dictionary = right
		if left_dictionary.size() != right_dictionary.size():
			return false
		for key in right_dictionary:
			if not left_dictionary.has(key) or not _snapshots_match(left_dictionary[key], right_dictionary[key]):
				return false
		return true
	if left_type == TYPE_ARRAY:
		var left_array: Array = left
		var right_array: Array = right
		if left_array.size() != right_array.size():
			return false
		for index in right_array.size():
			if not _snapshots_match(left_array[index], right_array[index]):
				return false
		return true
	return left == right


func _attack_accent_has_zero_authority(contract: Dictionary) -> bool:
	for authority_key in [
		"rule_authority",
		"damage_authority",
		"intent_authority",
		"gameplay_timing_authority",
		"save_authority",
		"input_authority",
	]:
		if bool(contract.get(authority_key, true)):
			return false
	return true


func _expect(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failures.append("%s：期望 true" % label)
