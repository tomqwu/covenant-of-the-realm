extends SceneTree

const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const PatrolStateScript := preload("res://src/domain/patrol_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const SAVE_PATH := "user://automated-input-save.json"
const SETTINGS_PATH := "user://automated-input-settings.json"

var assertions := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveGameScript.remove(SAVE_PATH)
	SettingsStoreScript.remove(SETTINGS_PATH)
	var scene: PackedScene = load("res://src/ui/main.tscn")
	var game := scene.instantiate()
	game.configure_save_path(SAVE_PATH)
	game.configure_settings_path(SETTINGS_PATH)
	root.add_child(game)
	await _settle()

	_expect(ProjectSettings.get_setting("display/window/size/min_width") == 1152, "最小窗口宽度保持可读基准")
	_expect(ProjectSettings.get_setting("display/window/size/min_height") == 648, "最小窗口高度保持可读基准")
	_expect(root.gui_get_focus_owner() == game.get_node("%NewGameButton"), "首次标题焦点落在新游戏")
	var title_dialogue_speed: Button = game.get_node("%TitleDialogueSpeedButton")
	_expect(title_dialogue_speed.text == "对话显字：标准", "标题默认显示标准对话显字")
	title_dialogue_speed.grab_focus()
	await _trigger_ui_key(KEY_ENTER)
	_expect(
		title_dialogue_speed.text == "对话显字：快速"
		and game.get_node("%PauseDialogueSpeedButton").text == "对话显字：快速",
		"真实键盘确认同步切换标题与暂停的快速对话显字"
	)
	await _trigger_mouse_click(title_dialogue_speed.get_global_rect().get_center())
	_expect(
		game.settings["dialogue_speed"] == "instant"
		and title_dialogue_speed.text == "对话显字：整句",
		"真实鼠标点击切换到整句显示"
	)
	_expect(
		SettingsStoreScript.read(SETTINGS_PATH)["data"]["dialogue_speed"] == "instant",
		"键鼠切换整句显示写入独立 settings v4"
	)
	game.get_node("%NewGameButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(not game.get_node("%TitleOverlay").visible, "手柄 A 启动新游戏")
	var input_camera_initial: Dictionary = game.world_camera_contract()
	_expect(input_camera_initial["world_size"] == Vector2(1536, 864), "真实输入场景使用 48×27 滚动世界")
	_expect(input_camera_initial["pixel_snap"], "真实输入场景镜头保持整数像素")
	_expect(input_camera_initial["safe_frame"]["rect"].has_point(input_camera_initial["world_focus"] - input_camera_initial["origin"]), "新游戏脚点位于 HUD 安全取景区")
	var input_hud_position: Vector2 = game.get_node("%ChapterLabel").global_position
	var journal_position: Vector2 = game.exploration.player_position
	await _trigger_key(KEY_J)
	_expect(game.get_node("%JournalOverlay").visible, "键盘 J 打开行旅札记")
	_expect(root.gui_get_focus_owner() == game.get_node("%JournalCloseButton"), "键盘打开札记后焦点落在关闭按钮")
	_expect(game.get_node("%JournalTabs").tab_count == 2 and game.get_node("%JournalTabs").focus_mode == Control.FOCUS_ALL, "见闻与灵物志为可聚焦的可选页")
	var journal_tabs: TabBar = game.get_node("%JournalTabs")
	var second_tab_center: Vector2 = journal_tabs.get_screen_transform() * journal_tabs.get_tab_rect(1).get_center()
	await _trigger_mouse_click(second_tab_center)
	_expect(game.journal_contract()["page_title"] == "灵物志", "真实鼠标点击切换到灵物志")
	_expect(game.journal_contract()["locked_enemy_count"] == 3 and not game.journal_contract()["entries_text"].contains("岩甲幼兽"), "未调查灵物页只显示不剧透占位")
	await _trigger_key(KEY_E)
	_expect(not game.dialogue.active, "札记模态会阻断背后地图交互")
	await _trigger_key(KEY_Q)
	_expect(game.journal_contract()["page_title"] == "见闻", "键盘 Q 循环切回见闻页")
	await _trigger_joy_button(JOY_BUTTON_RIGHT_SHOULDER)
	_expect(game.journal_contract()["page_title"] == "灵物志", "手柄 RB 循环切到灵物志")
	await _hold_key(KEY_D, 0.12)
	_expect(game.exploration.player_position == journal_position, "札记打开时真实移动输入不会作用于背后地图")
	await _trigger_joy_button(JOY_BUTTON_Y)
	_expect(not game.get_node("%JournalOverlay").visible, "手柄 Y 关闭行旅札记")
	var camera_origin_before_input: Vector2 = game.world_camera_contract()["origin"]
	await _hold_key(KEY_D, 0.12)
	_expect(game.world_camera_contract()["origin"].x > camera_origin_before_input.x, "真实持续移动输入同步推动世界镜头")
	_expect(game.get_node("%WorldRoot").position == game.world_camera_contract()["world_offset"], "世界根节点应用真实输入后的镜头偏移")
	_expect(game.get_node("%ChapterLabel").global_position == input_hud_position, "真实镜头移动不挪动 HUD")
	await _trigger_key(KEY_E)
	_expect(game.dialogue.active and game.get_node("%DialogueOverlay").visible, "键盘 E 开启同伴简报")
	_expect(game.get_node("%DialoguePortrait").mouse_filter == Control.MOUSE_FILTER_IGNORE, "纸绘头像不截获键盘或手柄对话焦点")
	_expect(
		game.get_node("%DialogueLabel").visible_characters == -1
		and game.get_node("%DialogueNextButton").text == "继续",
		"整句偏好让新台词完整显示但仍等待玩家推进"
	)
	await _trigger_key(KEY_E)
	_expect(game.dialogue.line_index == 1 and game.get_node("%DialogueLabel").visible_characters == -1, "整句模式下真实键盘 E 只推进一行")
	await _trigger_joy_button(JOY_BUTTON_START)
	_expect(game.get_node("%PauseOverlay").visible, "活动对话中手柄 Start 打开暂停设置")
	await _settle()
	var speed_journey_before: Dictionary = game.journey.snapshot()
	var speed_dialogue_before: Dictionary = game.dialogue.snapshot()
	var speed_save_before := FileAccess.get_file_as_string(SAVE_PATH)
	game.get_node("%PauseDialogueSpeedButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(
		game.settings["dialogue_speed"] == "standard"
		and game.get_node("%PauseDialogueSpeedButton").text == "对话显字：标准"
		and game.get_node("%TitleDialogueSpeedButton").text == "对话显字：标准",
		"真实手柄 A 从暂停菜单循环回标准对话显字"
	)
	_expect(game.journey.snapshot() == speed_journey_before and game.dialogue.snapshot() == speed_dialogue_before, "对话显字设置不取得 Journey 或 Dialogue 权威")
	_expect(FileAccess.get_file_as_string(SAVE_PATH) == speed_save_before, "对话显字设置只写 settings 而不改动 save v17 字节")
	game.get_node("%ResumeButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(not game.get_node("%PauseOverlay").visible, "手柄恢复后返回同一活动对话")
	await _trigger_key(KEY_E)
	_expect(game.dialogue.line_index == 2 and game.get_node("%DialogueLabel").visible_characters == 0, "标准速度在下一句重新从逐字显示开始")
	var reveal_line_before: int = game.dialogue.line_index
	var reveal_save_before := FileAccess.get_file_as_string(SAVE_PATH)
	await _trigger_mouse_click(game.get_node("%DialogueNextButton").get_global_rect().get_center())
	_expect(game.dialogue.line_index == reveal_line_before and game.get_node("%DialogueLabel").visible_characters == -1, "真实鼠标第一次点击只显示当前全文")
	_expect(FileAccess.get_file_as_string(SAVE_PATH) == reveal_save_before, "显示全文属于瞬时表现且不写游戏存档")
	await _trigger_mouse_click(game.get_node("%DialogueSkipButton").get_global_rect().get_center())
	await _settle()
	_expect(game.dialogue.at_choices(game.content["dialogues"]["companion_briefing"]["lines"].size()), "真实鼠标快进只到回应而不代选")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "protagonist", "手柄回应前显示主角纸绘头像")
	var response_focus := root.gui_get_focus_owner()
	_expect(response_focus is Button and response_focus.text == "先看退路，再进山。", "回应选择默认聚焦第一项")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.journey.talked_to_companion and game.journey.briefing_response == "careful", "手柄 A 确认对话回应")
	var patrol_visual: Dictionary = game.get_node("%MapCanvas").patrol_visual_contract()
	_expect(patrol_visual["visible"] and patrol_visual["active"], "完成简报后陶小满巡路角色可见")
	_expect(game.get_node("%PatrolSprite").animation_contract()["frame_size"] == Vector2(32, 56), "陶小满复用固定人物动画合同")

	game.move_player(Vector2.DOWN, 0.50)
	game.move_player(Vector2.RIGHT, 0.266667)
	await _settle()
	_expect(game.patrol.yielding_to_player, "公开移动进入礼让半径会暂停陶小满")
	var yielded_patrol: Dictionary = game.patrol.snapshot()
	await create_timer(0.12).timeout
	_expect(game.patrol.snapshot() == yielded_patrol, "礼让暂停期间真实帧推进不移动陶小满")
	game.move_player(Vector2.LEFT, 0.50)
	await _settle()
	var resumed_patrol: Dictionary = game.patrol.snapshot()
	await create_timer(0.12).timeout
	_expect(not game.patrol.yielding_to_player and game.patrol.snapshot() != resumed_patrol, "玩家离开迟滞半径后真实帧推进恢复巡路")

	game.patrol.reset()
	game._render([])
	game.move_player(Vector2.RIGHT, 0.50)
	await _settle()
	var patrol_button := _find_action_button(game, "问问陶小满")
	_expect(patrol_button != null, "公开路线可到达陶小满并显示中文行动")
	if patrol_button != null:
		await _trigger_mouse_click(patrol_button.get_global_rect().get_center())
	_expect(game.dialogue.active and game.dialogue.dialogue_id == "patrol_runner_briefing", "真实鼠标点击开启巡路对话")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "tao_xiaoman", "巡路对话显示陶小满纸绘头像")
	game.skip_dialogue_to_response()
	await _settle()
	var patrol_focus := root.gui_get_focus_owner()
	_expect(patrol_focus is Button and patrol_focus.text == "木楔怕潮，先送船架。", "巡路选择默认聚焦先送船架")
	await _trigger_ui_key(KEY_TAB)
	patrol_focus = root.gui_get_focus_owner()
	_expect(patrol_focus is Button and patrol_focus.text == "药叶怕闷，先翻竹架。", "真实键盘 Tab 可选择另一巡路先后")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.journey.patrol_response == "herbs_first", "手柄 A 确认先翻药叶选择")
	_expect(game.patrol.target_index == 2 and game.patrol.route_step == 1, "巡路选择立即重定向确定性路线")
	var patrol_disk: Dictionary = SaveGameScript.read(SAVE_PATH)
	_expect(patrol_disk["data"]["save_version"] == SaveGameScript.SAVE_VERSION, "巡路选择写入 save v17")
	var stored_patrol: Dictionary = patrol_disk["data"]["patrol"]
	_expect(
		is_equal_approx(float(stored_patrol["position_x"]), game.patrol.position.x)
		and is_equal_approx(float(stored_patrol["position_y"]), game.patrol.position.y)
		and int(stored_patrol["target_index"]) == game.patrol.target_index
		and int(stored_patrol["route_step"]) == game.patrol.route_step
		and is_equal_approx(float(stored_patrol["dwell_remaining"]), game.patrol.dwell_remaining)
		and bool(stored_patrol["yielding_to_player"]) == game.patrol.yielding_to_player,
		"save v17 顶层原子保存巡路位置与目标"
	)
	var herbs_distance_before: float = game.patrol.position.distance_to(PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT])
	game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51})
	game.patrol.advance(0.25, game.exploration.player_position)
	_expect(game.patrol.position.distance_to(PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT]) < herbs_distance_before, "真实输入选择后首次位移实际接近晾晒架")
	var input_worksite_context: Dictionary = _wait_for_worksite_input(
		game,
		PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT],
		"talk_at_herbs_worksite"
	)
	_expect(input_worksite_context.get("worksite_id") == "herbs" and input_worksite_context.get("route_role") == "priority", "真实输入到达药叶优先晾晒工位")
	var worksite_button := _first_action_button(game)
	_expect(worksite_button != null and worksite_button.text == "问问竹架这头", "端点停留显示可点击中文工位行动")
	var worksite_journey_before: Dictionary = game.journey.snapshot()
	if worksite_button != null:
		await _trigger_mouse_click(worksite_button.get_global_rect().get_center())
	_expect(game.dialogue.active and game.dialogue.dialogue_id == "patrol_herbs_priority", "真实鼠标点击开启晾晒优先回响")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "tao_xiaoman", "工位回响保持陶小满纸绘头像")
	await _trigger_key(KEY_E)
	await _trigger_key(KEY_E)
	_expect(game.dialogue.line_index == 1, "真实键盘 E 可显示全文并推进工位台词")
	game.skip_dialogue_to_response()
	await _settle()
	var worksite_focus := root.gui_get_focus_owner()
	_expect(worksite_focus is Button and worksite_focus.text == "替她扶稳晾叶竹匾。", "晾晒工位默认聚焦第一项对等回应")
	await _trigger_ui_key(KEY_TAB)
	worksite_focus = root.gui_get_focus_owner()
	_expect(worksite_focus is Button and worksite_focus.text == "陪她看清叶背日影。", "真实键盘 Tab 可选择第二项工位回应")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(not game.dialogue.active, "手柄 A 确认晾晒工位回应")
	_expect(game.journey.snapshot() == worksite_journey_before, "工位键鼠手柄流程不修改任何 Journey 字段")
	_expect(game.get_node("%EventLabel").text == str(game.content["messages"]["patrol_herbs_light_checked"]), "手柄确认产生稳定日影回声")
	_expect(is_zero_approx(game.patrol.dwell_remaining), "工位回应只将当前停留归零")
	var worksite_disk: Dictionary = SaveGameScript.read(SAVE_PATH)
	_expect(worksite_disk["data"]["save_version"] == SaveGameScript.SAVE_VERSION and worksite_disk["data"]["dialogue"]["active"] == false, "端点回应原子写入空闲对话 save v17")
	_expect(_snapshots_match(worksite_disk["data"]["journey"], worksite_journey_before), "端点 save v17 不夹带隐藏奖励")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51}), "巡路输入验收后返回同行起点")
	game._render([])

	game.move_player(Vector2.LEFT, 0.27)
	game.move_player(Vector2.UP, 0.80)
	await _settle()
	_expect(_find_action_button(game, "查看补船木架") != null, "公开移动可到达补船木架并显示中文行动")
	var boat_life_snapshot: Dictionary = game.journey.snapshot()
	await _trigger_key(KEY_E)
	_expect(game.get_node("%EventLabel").text.contains("旧船板被削成楔子"), "真实键盘 E 查看补船木架并显示中文生活细节")
	_expect(game.journey.snapshot() == boat_life_snapshot, "补船木架不修改完整旅程快照")
	await _trigger_key(KEY_E)
	_expect(_find_action_button(game, "查看补船木架") != null, "补船木架可用键盘 E 重复查看")
	_expect(game.journey.snapshot() == boat_life_snapshot, "重复查看补船木架仍不修改旅程快照")

	game.move_player(Vector2.DOWN, 0.80)
	game.move_player(Vector2.RIGHT, 0.27)
	game.move_player(Vector2.LEFT, 0.10)
	game.move_player(Vector2.UP, 1.17)
	game.move_player(Vector2.RIGHT, 1.60)
	game.move_player(Vector2.DOWN, 0.91)
	await _settle()
	var drying_button := _find_action_button(game, "查看晾晒竹架")
	_expect(drying_button != null, "公开移动可到达晾晒竹架并显示中文行动")
	var drying_life_snapshot: Dictionary = game.journey.snapshot()
	if drying_button != null:
		await _trigger_mouse_click(drying_button.get_global_rect().get_center())
	_expect(game.get_node("%EventLabel").text.contains("翻晒时辰"), "真实鼠标点击查看晾晒竹架并显示中文生活细节")
	_expect(game.journey.snapshot() == drying_life_snapshot, "晾晒竹架不修改完整旅程快照")
	drying_button = _find_action_button(game, "查看晾晒竹架")
	if drying_button != null:
		await _trigger_mouse_click(drying_button.get_global_rect().get_center())
	_expect(_find_action_button(game, "查看晾晒竹架") != null, "晾晒竹架可用真实鼠标重复查看")
	_expect(game.journey.snapshot() == drying_life_snapshot, "重复查看晾晒竹架仍不修改旅程快照")

	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.41, "player_y": 0.66}), "输入验收到达渡口守堤人")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.dialogue.active and game.dialogue.dialogue_id == "ferryman_briefing", "键盘 E 开启守堤支线")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "liangshu", "守堤支线显示梁叔纸绘头像")
	game.skip_dialogue_to_response()
	await _settle()
	var ferryman_focus := root.gui_get_focus_owner()
	_expect(ferryman_focus is Button and ferryman_focus.text == "一起扶正水尺。", "守堤选择默认聚焦第一项")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.journey.ferryman_response == "repair", "手柄 A 确认守堤选择")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.43, "player_y": 0.42}), "输入验收到达渡口旧水痕")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.journey.discoveries == ["ferry_watermark"], "键盘 E 记录近距离环境见闻")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.47, "player_y": 0.51}), "输入验收调查后回到同行起点")
	game._render([])

	var before_move: Vector2 = game.exploration.player_position
	await _hold_key(KEY_S, 0.12)
	_expect(game.exploration.player_position.y > before_move.y, "键盘 S 持续驱动角色位置")
	var follow_contract: Dictionary = game.get_node("%MapCanvas").companion_follow_contract()
	_expect(follow_contract["active"] and follow_contract["point_count"] > 2, "真实持续输入为砚青留下可跟随脚印")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.40, "player_y": 0.16}), "暂停验收把玩家放到巡路礼让半径外")
	game._render([])
	await _settle()
	await _trigger_joy_button(JOY_BUTTON_START)
	_expect(game.get_node("%PauseOverlay").visible, "手柄 Start 打开暂停界面")
	await _settle()
	var paused_patrol: Dictionary = game.patrol.snapshot()
	await create_timer(0.12).timeout
	_expect(game.patrol.snapshot() == paused_patrol, "暂停界面冻结陶小满巡路时钟")
	_expect(root.gui_get_focus_owner() == game.get_node("%ResumeButton"), "暂停焦点落在继续修行")
	game.get_node("%PauseBattleSpeedButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseBattleSpeedButton").text == "战斗表现：快速", "手柄 A 切换快速战斗反馈")
	game.get_node("%PauseMotionButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseMotionButton").text == "动态效果：简化", "手柄 A 切换简化动态")
	game.get_node("%PauseDialogueSpeedButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseDialogueSpeedButton").text == "对话显字：快速", "手柄 A 在常规暂停中切换快速对话显字")
	game.get_node("%PauseTextScaleButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseTextScaleButton").text == "文字大小：大字", "手柄 A 切换大字模式")
	game.get_node("%PauseContrastButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseContrastButton").text == "高对比：开启", "手柄 A 开启高对比文字")
	game.get_node("%PauseTextScaleButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseTextScaleButton").text == "文字大小：标准", "手柄 A 恢复标准文字大小")
	game.get_node("%PauseContrastButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%PauseContrastButton").text == "高对比：关闭", "手柄 A 关闭高对比文字")
	game.get_node("%ResumeButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(not game.get_node("%PauseOverlay").visible, "手柄 A 从暂停恢复")
	await create_timer(0.12).timeout
	_expect(game.patrol.snapshot() != paused_patrol, "关闭暂停后陶小满继续巡路")

	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.69, "player_y": 0.62}), "输入验收移动到合法月芽田坐标")
	game._render([])
	await _trigger_action("interact")
	_expect(game.journey.gathered_moonleaf, "交互动作在月芽田采集")
	_expect(game.journey.moonleaf_method == "whole_plant", "单键交互采用稳定的旧规取药默认项")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "输入验收移动到合法山门坐标")
	game._render([])
	await _trigger_action("interact")
	_expect(game.journey.phase_id() == "mountain_path", "交互动作从山门进入可探索山道")
	game.get_node("%SceneTransition").finish()
	var path_input_spawn: Dictionary = game.exploration.snapshot()
	var path_keeper_visual: Dictionary = game.get_node("%MapCanvas").path_keeper_visual_contract()
	_expect(path_keeper_visual["visible"] and path_keeper_visual["active"], "进入山道后岑苇巡山角色立即可见")
	_expect(game.get_node("%PathKeeperSprite").animation_contract()["frame_size"] == Vector2(32, 56), "岑苇像素图集保持四向 32×56 人物合同")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": game.path_keeper.position.x, "player_y": game.path_keeper.position.y}), "输入验收可站到岑苇当前路线位置")
	game._render([])
	await _settle()
	var path_keeper_button := _find_action_button(game, "问问岑苇")
	_expect(path_keeper_button != null, "岑苇近距行动可由键鼠与手柄共享选择")
	var path_keeper_journey_before: Dictionary = game.journey.snapshot()
	if path_keeper_button != null:
		await _trigger_mouse_click(path_keeper_button.get_global_rect().get_center())
	_expect(game.get_node("%EventLabel").text.contains("亮面朝下山"), "真实鼠标点击触发岑苇原创巡山回声")
	_expect(game.journey.snapshot() == path_keeper_journey_before, "鼠标问路不修改 Journey 或取得奖励权威")
	var mouse_path_keeper_echo: String = game.get_node("%EventLabel").text
	await _trigger_key(KEY_E)
	_expect(game.get_node("%EventLabel").text == mouse_path_keeper_echo, "真实键盘 E 重复同一岑苇巡山回声")
	_expect(game.journey.snapshot() == path_keeper_journey_before, "键盘问路不修改 Journey 或取得奖励权威")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.40, "player_y": 0.30}), "输入验收可离开岑苇礼让半径")
	game._render([])
	await _trigger_joy_button(JOY_BUTTON_START)
	var paused_path_keeper: Dictionary = game.path_keeper.snapshot()
	await create_timer(0.12).timeout
	_expect(game.path_keeper.snapshot() == paused_path_keeper, "真实手柄 Start 暂停时冻结岑苇巡山")
	await _trigger_joy_button(JOY_BUTTON_START)
	await create_timer(0.12).timeout
	_expect(game.path_keeper.snapshot() != paused_path_keeper, "真实手柄 Start 恢复后岑苇继续巡山")
	_expect(game.exploration.restore(path_input_spawn), "岑苇输入验收后恢复山道出生点")
	game._render([])
	game.move_player(Vector2.UP, 0.20)
	game.move_player(Vector2.RIGHT, 1.24)
	game.move_player(Vector2.DOWN, 0.17)
	await _settle()
	_expect(_find_action_button(game, "查看避雨石棚") != null, "公开移动可从山道入口到达避雨石棚")
	var shelter_life_snapshot: Dictionary = game.journey.snapshot()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%EventLabel").text.contains("后来补一束"), "真实手柄 A 查看避雨石棚并显示中文生活旧规")
	_expect(game.journey.snapshot() == shelter_life_snapshot, "避雨石棚不修改完整旅程快照")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(_find_action_button(game, "查看避雨石棚") != null, "避雨石棚可用手柄 A 重复查看")
	_expect(game.journey.snapshot() == shelter_life_snapshot, "重复查看避雨石棚仍不修改旅程快照")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.36, "player_y": 0.43}), "输入验收移动到泉苔痕迹")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.journey.enemy_intel == ["spring_moss_shell"], "键盘 E 调查泉苔痕迹")
	_expect(game.get_node("%MapCanvas").enemy_intel_visual_contract()["studied"] == ["spring_moss_shell"], "已读泉苔痕迹在地图保留识读残痕")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.65, "player_y": 0.22}), "输入验收移动到岩甲爪痕")
	game._render([])
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.journey.enemy_intel.has("rock_armor_young"), "手柄 A 调查岩甲爪痕并进入同一敌情状态")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.91, "player_y": 0.34}), "输入验收移动到石傀拖痕")
	game._render([])
	await _trigger_action("interact")
	_expect(game.journey.enemy_intel.size() == 3, "输入验收集齐三种灵物情报")
	game.toggle_text_scale()
	await _trigger_key(KEY_J)
	game.select_journal_page(1)
	await _settle()
	var journal_entries: RichTextLabel = game.get_node("%JournalEntriesLabel")
	var journal_scroll := journal_entries.get_v_scroll_bar()
	_expect(journal_entries.focus_mode == Control.FOCUS_ALL and journal_scroll.max_value > journal_scroll.page, "大字三条灵物志可聚焦且产生可滚动内容")
	journal_entries.grab_focus()
	await _settle()
	var before_keyboard_scroll: float = journal_scroll.value
	await _trigger_key(KEY_PAGEDOWN)
	_expect(journal_scroll.value > before_keyboard_scroll, "键盘 PageDown 可阅读大字灵物志下方内容")
	journal_scroll.value = 0.0
	journal_entries.grab_focus()
	await _trigger_joy_button(JOY_BUTTON_DPAD_DOWN)
	_expect(journal_scroll.value > 0.0, "手柄方向键下可滚动灵物志")
	journal_scroll.value = maxf(0.0, journal_scroll.max_value - journal_scroll.page)
	journal_entries.grab_focus()
	await _trigger_joy_button(JOY_BUTTON_DPAD_DOWN)
	_expect(root.gui_get_focus_owner() == game.get_node("%JournalCloseButton"), "手柄在末页继续向下可移到关闭按钮")
	await _trigger_joy_button(JOY_BUTTON_Y)
	game.toggle_text_scale()
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.68, "player_y": 0.60}), "输入验收移动到山道弃置药篓")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.journey.discoveries.has("abandoned_basket"), "键盘 E 调查药篓生活痕迹")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.10, "player_y": 0.68}), "输入验收带药篓到达山道退路")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.journey.phase_id() == "riverbank", "键盘 E 从山道返回渡口")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.75, "player_y": 0.66}), "输入验收到达药圃守蕙婶")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.dialogue.active and game.dialogue.dialogue_id == "herbkeeper_basket", "键盘 E 开启药篓支线")
	_expect(game.get_node("%DialoguePortrait").visual_contract()["portrait_id"] == "huishen", "药篓支线显示蕙婶纸绘头像")
	game.skip_dialogue_to_response()
	await _settle()
	var basket_focus := root.gui_get_focus_owner()
	_expect(basket_focus is Button and basket_focus.text == "把药篓带回圃里。", "药篓选择默认聚焦归圃项")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.journey.basket_response == "return", "手柄 A 确认药篓归圃选择")
	_expect(game.exploration.restore({"map_id": "zhaohe_ferry", "player_x": 0.88, "player_y": 0.18}), "输入验收再次到达山门")
	game._render([])
	await _trigger_key(KEY_E)
	_expect(game.journey.phase_id() == "mountain_path", "键盘 E 在支线后重新进入山道")
	game.get_node("%SceneTransition").finish()
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": game.path_keeper.position.x, "player_y": game.path_keeper.position.y}), "支线后可重新接近岑苇")
	game._render([])
	await _settle()
	_expect(_find_action_button(game, "问问岑苇") != null, "药篓归圃后岑苇行动仍可选择")
	var returned_basket_path_keeper_journey: Dictionary = game.journey.snapshot()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.get_node("%EventLabel").text.contains("篓子回了药圃"), "真实手柄 A 触发岑苇对药篓归圃的进度回声")
	_expect(game.journey.snapshot() == returned_basket_path_keeper_journey, "手柄问路不修改药篓或主线状态")
	_expect(game.exploration.restore({"map_id": "cangquan_path", "player_x": 0.73, "player_y": 0.34}), "输入验收移动到敌人预警区")
	game._render([])
	await _trigger_action("interact")
	_expect(game.journey.phase_id() == "battle", "交互动作从敌人预警区进入战斗")
	await _settle()
	var input_telegraph: Control = game.get_node("%IntentTelegraph")
	var input_map_canvas: Control = game.get_node("%MapCanvas")
	var input_telegraph_contract: Dictionary = input_telegraph.presentation_contract()
	_expect(
		input_telegraph_contract["active"]
		and input_telegraph_contract["enemy_id"] == "rock_armor_young"
		and input_telegraph_contract["intent_id"] == "rock_probing_charge",
		"真实输入战斗显示当前敌势签"
	)
	_expect(
		input_telegraph.mouse_filter == Control.MOUSE_FILTER_IGNORE
		and input_telegraph.focus_mode == Control.FOCUS_NONE
		and input_telegraph_contract["mouse_filter"] == Control.MOUSE_FILTER_IGNORE
		and input_telegraph_contract["focus_mode"] == Control.FOCUS_NONE
		and not input_telegraph_contract["blocks_input"],
		"势签忽略鼠标命中且不进入键盘或手柄焦点链"
	)
	_expect(
		input_map_canvas.mouse_filter == Control.MOUSE_FILTER_IGNORE
		and input_map_canvas.focus_mode == Control.FOCUS_NONE,
		"承载敌足势痕的世界画布忽略鼠标且不进入键盘或手柄焦点链"
	)
	var first_focus := root.gui_get_focus_owner()
	_expect(first_focus is Button and first_focus.text == "引气术", "战斗焦点落在第一项术式")
	await _trigger_action("ui_right")
	var moved_focus := root.gui_get_focus_owner()
	_expect(moved_focus is Button and moved_focus != first_focus and moved_focus != input_telegraph, "方向动作穿过势签在战斗网格中移动焦点")
	await _trigger_action("ui_accept")
	_expect(game.journey.round_number == 2, "确认动作执行当前战斗焦点")
	_expect(game.get_node("%BattleEnemySprite").presentation_contract()["state"] == "react", "真实方向与确认输入触发同一敌人受击语义")
	var post_action_telegraph: Dictionary = input_telegraph.presentation_contract()
	var fast_static_probing_accent: Dictionary = input_map_canvas.attack_accent_contract()
	var post_action_focus := root.gui_get_focus_owner()
	_expect(
		post_action_telegraph["intent_id"] == "rock_rending_charge"
		and post_action_telegraph["shape_id"] == "rending_charge",
		"确认战斗行动后势签随规则回合更新"
	)
	_expect(
		post_action_focus is Button
		and game.get_node("%Actions").is_ancestor_of(post_action_focus)
		and post_action_focus != input_telegraph,
		"势签更新后战斗行动网格保持输入焦点"
	)
	_expect(
		fast_static_probing_accent["active"]
		and fast_static_probing_accent["enemy_id_before"] == "rock_armor_young"
		and fast_static_probing_accent["resolved_intent_id"] == "rock_probing_charge"
		and fast_static_probing_accent["resolution_event_id"] == "enemy_hit"
		and fast_static_probing_accent["shape_id"] == "probing_charge"
		and fast_static_probing_accent["label_text"] == "刚才 · 试探冲撞 · 受到冲击"
		and fast_static_probing_accent["duration"] == 0.18
		and fast_static_probing_accent["remaining"] > 0.0
		and fast_static_probing_accent["remaining"] <= 0.18
		and not fast_static_probing_accent["motion_enabled"]
		and fast_static_probing_accent["reduced_motion_static"]
		and fast_static_probing_accent["secondary_offset"] == 0.0
		and fast_static_probing_accent["world_space"]
		and fast_static_probing_accent["decorative_only"]
		and not fast_static_probing_accent["blocks_input"]
		and _attack_accent_has_zero_authority(fast_static_probing_accent),
		"快速加简化动态以 0.18 秒静态大字高对比标签显示已结算的试探冲撞"
	)
	_expect(
		game.get_node("%EventLabel").text.contains("刚才 · 试探冲撞 · 受到冲击"),
		"快速简化动态把旧势名称与结果同步保留在持续事件文字中"
	)
	var controller_replacement_round: int = int(game.journey.round_number)
	await _trigger_joy_button(JOY_BUTTON_A)
	var controller_rending_accent: Dictionary = input_map_canvas.attack_accent_contract()
	_expect(
		game.journey.round_number == controller_replacement_round + 1
		and controller_rending_accent["active"]
		and controller_rending_accent["enemy_id_before"] == "rock_armor_young"
		and controller_rending_accent["resolved_intent_id"] == "rock_rending_charge"
		and controller_rending_accent["resolution_event_id"] == "enemy_hit"
		and controller_rending_accent["shape_id"] == "rending_charge"
		and controller_rending_accent["resolved_intent_id"] != fast_static_probing_accent["resolved_intent_id"]
		and root.gui_get_focus_owner() is Button
		and game.get_node("%Actions").is_ancestor_of(root.gui_get_focus_owner()),
		"下一次独立手柄 A 立即结算下一回合并用裂石势痕替换试探势，不等待动画"
	)
	for _finishing_round in range(2):
		await _trigger_action("ui_accept")
	var input_outgoing_defeat: Dictionary = game.get_node("%MapCanvas").outgoing_enemy_defeat_contract()
	var lethal_regular_input_accent: Dictionary = input_map_canvas.attack_accent_contract()
	var replacement_focus := root.gui_get_focus_owner()
	var replacement_input_intent: Dictionary = input_telegraph.presentation_contract()
	_expect(
		input_outgoing_defeat["active"]
		and input_outgoing_defeat["visible"]
		and input_outgoing_defeat["enemy_id"] == "rock_armor_young"
		and input_outgoing_defeat["state"] == "defeat"
		and input_outgoing_defeat["event_id"] == "regular_enemy_won"
		and input_outgoing_defeat["role"] == "outgoing"
		and input_outgoing_defeat["duration"] == 0.18
		and not input_outgoing_defeat["motion_enabled"]
		and input_outgoing_defeat["motion_skipped"]
		and game.journey.enemy_id == "rock_armor_warden"
		and game.get_node("%BattleEnemySprite").enemy_id == "rock_armor_warden"
		and replacement_input_intent["enemy_id"] == "rock_armor_warden",
		"真实确认输入按快速简化偏好显示旧幼兽静态退场，同时切换当前首领与势签"
	)
	_expect(
		not lethal_regular_input_accent["active"]
		and lethal_regular_input_accent["enemy_id_before"] == ""
		and lethal_regular_input_accent["resolved_intent_id"] == ""
		and lethal_regular_input_accent["resolution_event_id"] == ""
		and lethal_regular_input_accent["shape_id"] == ""
		and lethal_regular_input_accent["label_text"] == "",
		"快速确认的普通敌致命回合不会把未执行敌势画成攻击势痕"
	)
	_expect(
		replacement_focus is Button
		and game.get_node("%Actions").is_ancestor_of(replacement_focus)
		and not input_outgoing_defeat["blocks_input"]
		and not input_outgoing_defeat["rule_authority"]
		and not input_outgoing_defeat["timing_authority"]
		and not input_outgoing_defeat["save_authority"],
		"旧敌退场不接管焦点，也不阻断首领行动网格的下一次输入"
	)
	var replacement_round: int = int(game.journey.round_number)
	await _trigger_joy_button(JOY_BUTTON_A)
	var post_replacement_input_defeat: Dictionary = game.get_node("%MapCanvas").outgoing_enemy_defeat_contract()
	var post_replacement_attack_accent: Dictionary = input_map_canvas.attack_accent_contract()
	_expect(
		game.journey.enemy_id == "rock_armor_warden"
		and game.journey.round_number == replacement_round + 1
		and not post_replacement_input_defeat["active"]
		and not post_replacement_input_defeat["visible"]
		and post_replacement_input_defeat["enemy_id"] == ""
		and root.gui_get_focus_owner() is Button
		and game.get_node("%Actions").is_ancestor_of(root.gui_get_focus_owner()),
		"退场出现后的下一次独立手柄 A 会立即结算首领回合并清除旧敌，不发生输入穿透或等待"
	)
	_expect(
		post_replacement_attack_accent["active"]
		and post_replacement_attack_accent["enemy_id_before"] == "rock_armor_warden"
		and post_replacement_attack_accent["resolved_intent_id"] == "warden_pressing_charge"
		and post_replacement_attack_accent["resolution_event_id"] == "enemy_hit"
		and post_replacement_attack_accent["shape_id"] == "pressing_charge"
		and post_replacement_attack_accent["duration"] == 0.18
		and post_replacement_attack_accent["reduced_motion_static"],
		"同一次手柄 A 在清除旧敌后立即显示已真实结算的首领肩撞势痕"
	)
	game.return_to_title()
	await _settle()
	game._apply_accessibility_settings()
	var title_feedback: Dictionary = game.get_node("%MapCanvas").feedback_contract()
	var title_outgoing_defeat: Dictionary = game.get_node("%MapCanvas").outgoing_enemy_defeat_contract()
	var title_attack_accent: Dictionary = input_map_canvas.attack_accent_contract()
	_expect(
		game.get_node("%TitleDialogueSpeedButton").text == "对话显字：快速"
		and not input_telegraph.presentation_contract()["active"]
		and not input_telegraph.visible
		and not title_feedback["active"]
		and title_feedback["text"] == ""
		and title_feedback["enemy_id_before"] == ""
		and title_feedback["announced_intent_id"] == ""
		and not title_outgoing_defeat["active"]
		and not title_outgoing_defeat["visible"]
		and title_outgoing_defeat["enemy_id"] == ""
		and title_outgoing_defeat["state"] == "idle"
		and title_outgoing_defeat["event_id"] == ""
		and not title_attack_accent["active"]
		and title_attack_accent["enemy_id_before"] == ""
		and title_attack_accent["resolved_intent_id"] == ""
		and title_attack_accent["resolution_event_id"] == ""
		and title_attack_accent["shape_id"] == ""
		and title_attack_accent["label_text"] == "",
		"战斗返回标题保留显字偏好，并在标题设置重刷后仍清除势签与瞬时反馈"
	)
	var battle_save_text := FileAccess.get_file_as_string(SAVE_PATH)
	game.get_node("%NewGameButton").grab_focus()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.new_game_confirmation_contract()["visible"], "手柄 A 对有效存档只打开覆盖确认")
	_expect(game.get_node("%TitleOverlay").visible and game.journey.phase_id() == "battle", "手柄确认态保留当前战斗旅程")
	_expect(root.gui_get_focus_owner() == game.get_node("%ContinueButton"), "手柄覆盖确认默认聚焦取消")
	await _trigger_joy_button(JOY_BUTTON_START)
	_expect(not game.new_game_confirmation_contract()["visible"], "手柄 Start 安全取消覆盖确认")
	_expect(FileAccess.get_file_as_string(SAVE_PATH) == battle_save_text, "手柄取消覆盖保持存档字节不变")
	_expect(root.gui_get_focus_owner() == game.get_node("%NewGameButton"), "手柄取消后焦点回到重新开始")
	await _trigger_joy_button(JOY_BUTTON_A)
	await _trigger_action("ui_down")
	_expect(root.gui_get_focus_owner() == game.get_node("%NewGameButton"), "方向动作可从取消移到确认重新开始")
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(not game.get_node("%TitleOverlay").visible and game.journey.phase_id() == "riverbank", "手柄二次确认建立新旅程")
	_expect(game.settings["dialogue_speed"] == "fast", "明确新开旅程不会清除本机对话显字偏好")

	game.get_node("%AudioManager").set_audio_enabled(false)
	game.queue_free()
	await _settle()

	SaveGameScript.remove(SAVE_PATH)
	var breath_journey = JourneyStateScript.new()
	breath_journey.choose("talk_to_companion")
	breath_journey.choose("gather_moonleaf")
	breath_journey.choose("enter_spring")
	breath_journey.choose("bypass_enemy")
	var breath_exploration = ExplorationStateScript.new()
	_expect(breath_exploration.transition_to(ExplorationStateScript.CANGQUAN_SPRING_MAP_ID), "输入验收建立合法藏泉石室地图")
	_expect(SaveGameScript.write(breath_journey.snapshot(), breath_exploration.snapshot(), SAVE_PATH)["ok"], "输入验收建立未开始的三步引息 save v17 存档")
	var breath_disk: Dictionary = SaveGameScript.read(SAVE_PATH)
	_expect(
		breath_disk["data"]["save_version"] == SaveGameScript.SAVE_VERSION
		and typeof(breath_disk["data"].get("patrol")) == TYPE_DICTIONARY
		and typeof(breath_disk["data"].get("path_keeper")) == TYPE_DICTIONARY,
		"输入夹具包含 save v17 顶层 patrol 与 path_keeper 快照"
	)

	game = scene.instantiate()
	game.configure_save_path(SAVE_PATH)
	game.configure_settings_path(SETTINGS_PATH)
	root.add_child(game)
	await _settle()
	_expect(
		game.settings["dialogue_speed"] == "fast"
		and game.get_node("%TitleDialogueSpeedButton").text == "对话显字：快速",
		"新场景在继续游戏前恢复独立对话显字偏好"
	)
	_expect(game.continue_game(), "输入验收从标题恢复藏泉石室")
	game.get_node("%SceneTransition").finish()
	await _settle()

	_expect(game.exploration.restore({
		"map_id": ExplorationStateScript.CANGQUAN_SPRING_MAP_ID,
		"player_x": ExplorationStateScript.SPRING_LISTEN_POSITION.x,
		"player_y": ExplorationStateScript.SPRING_LISTEN_POSITION.y,
	}), "输入验收到达听泉辨脉位置")
	game._render([])
	await _settle()
	var listen_button := _find_action_button(game, "听泉辨脉")
	_expect(listen_button != null and listen_button.focus_mode == Control.FOCUS_NONE, "石室鼠标行动存在且不抢探索焦点")
	if listen_button != null:
		await _trigger_mouse_click(listen_button.get_global_rect().get_center())
	_expect(game.journey.first_breath_stage == "listened", "真实鼠标点击完成听泉辨脉")
	_expect(SaveGameScript.read(SAVE_PATH)["data"]["journey"]["first_breath_stage"] == "listened", "鼠标步骤立即写入 v17 存档")

	_expect(game.exploration.restore({
		"map_id": ExplorationStateScript.CANGQUAN_SPRING_MAP_ID,
		"player_x": ExplorationStateScript.SPRING_WARM_POSITION.x,
		"player_y": ExplorationStateScript.SPRING_WARM_POSITION.y,
	}), "输入验收到达月芽温脉位置")
	game._render([])
	await _settle()
	await _trigger_key(KEY_E)
	_expect(game.journey.first_breath_stage == "warmed" and not game.journey.gathered_moonleaf, "真实键盘 E 完成月芽温脉并消耗灵草")
	_expect(SaveGameScript.read(SAVE_PATH)["data"]["journey"]["first_breath_stage"] == "warmed", "键盘步骤立即写入 v17 存档")

	_expect(game.exploration.restore({
		"map_id": ExplorationStateScript.CANGQUAN_SPRING_MAP_ID,
		"player_x": ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION.x,
		"player_y": ExplorationStateScript.SPRING_BREAKTHROUGH_POSITION.y,
	}), "输入验收到达静坐引息位置")
	game._render([])
	await _settle()
	await _trigger_joy_button(JOY_BUTTON_A)
	_expect(game.journey.first_breath_stage == "completed" and game.journey.phase_id() == "complete", "真实手柄 A 完成静坐引息")
	_expect(SaveGameScript.read(SAVE_PATH)["data"]["journey"]["first_breath_stage"] == "completed", "手柄步骤立即写入 v17 存档")

	game.get_node("%AudioManager").set_audio_enabled(false)
	game.queue_free()
	await _settle()
	SaveGameScript.remove(SAVE_PATH)
	SettingsStoreScript.remove(SETTINGS_PATH)
	if failures.is_empty():
		print("RPG input passed: %d semantic input and focus assertions." % assertions)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _wait_for_worksite_input(game: Node, worksite_position: Vector2, expected_action_id: String) -> Dictionary:
	_expect(game.exploration.restore({
		"map_id": ExplorationStateScript.DEFAULT_MAP_ID,
		"player_x": worksite_position.x,
		"player_y": worksite_position.y,
	}), "真实输入玩家可在工位端点守候")
	game._render([])
	var context: Dictionary = game.patrol.worksite_context(game.journey.patrol_response)
	for _step in range(400):
		if str(context.get("action_id", "")) == expected_action_id:
			break
		game._process(0.10)
		context = game.patrol.worksite_context(game.journey.patrol_response)
	_expect(str(context.get("action_id", "")) == expected_action_id, "真实输入巡路在有界步数内到达工位")
	_expect(game.patrol.position.is_equal_approx(worksite_position) and game.patrol.dwell_remaining > 0.0, "真实输入工位行动绑定精确端点停留")
	_expect(game.nearby_action_id == expected_action_id, "真实输入玩家可在工位半径内交互")
	return context


func _first_action_button(game: Node) -> Button:
	for child in game.get_node("%Actions").get_children():
		if child is Button:
			return child
	return null


func _find_action_button(game: Node, label: String) -> Button:
	for child in game.get_node("%Actions").get_children():
		if child is Button and child.text == label:
			return child
	return null


func _trigger_action(action_name: StringName) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action_name
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventAction.new()
	released.action = action_name
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _hold_action(action_name: StringName, seconds: float) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action_name
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await create_timer(seconds).timeout
	var released := InputEventAction.new()
	released.action = action_name
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _trigger_key(keycode: Key) -> void:
	var pressed := InputEventKey.new()
	pressed.physical_keycode = keycode
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventKey.new()
	released.physical_keycode = keycode
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _trigger_ui_key(keycode: Key) -> void:
	var pressed := InputEventKey.new()
	pressed.keycode = keycode
	pressed.physical_keycode = keycode
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventKey.new()
	released.keycode = keycode
	released.physical_keycode = keycode
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _hold_key(keycode: Key, seconds: float) -> void:
	var pressed := InputEventKey.new()
	pressed.physical_keycode = keycode
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await create_timer(seconds).timeout
	var released := InputEventKey.new()
	released.physical_keycode = keycode
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _trigger_joy_button(button_index: JoyButton) -> void:
	var pressed := InputEventJoypadButton.new()
	pressed.button_index = button_index
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventJoypadButton.new()
	released.button_index = button_index
	released.pressed = false
	Input.parse_input_event(released)
	await _settle()


func _trigger_mouse_click(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion, true)
	await process_frame
	var pressed := InputEventMouseButton.new()
	pressed.position = position
	pressed.global_position = position
	pressed.button_index = MOUSE_BUTTON_LEFT
	pressed.pressed = true
	root.push_input(pressed, true)
	await process_frame
	var released := InputEventMouseButton.new()
	released.position = position
	released.global_position = position
	released.button_index = MOUSE_BUTTON_LEFT
	released.pressed = false
	root.push_input(released, true)
	await _settle()


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
		"input_authority",
		"save_authority",
	]:
		if bool(contract.get(authority_key, true)):
			return false
	return true


func _expect(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failures.append("%s：期望 true" % label)
