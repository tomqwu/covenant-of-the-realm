extends SceneTree

const OUTPUT_DIR := "res://../docs/concepts/gameplay-ui-v1"
const CAPTURE_SAVE_PATH := "user://capture-ui-save.json"
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const PatrolStateScript := preload("res://src/domain/patrol_state.gd")
const PathKeeperStateScript := preload("res://src/domain/path_keeper_state.gd")
const DialoguePortraitScript := preload("res://src/ui/dialogue_portrait.gd")
const CAPTURE_SETTINGS_PATH := "user://capture-ui-settings.json"

var capture_output_dir := OUTPUT_DIR


func _initialize() -> void:
	var user_args := OS.get_cmdline_user_args()
	if user_args.size() > 1:
		push_error("UI capture accepts at most one output directory")
		quit(1)
		return
	if not user_args.is_empty():
		capture_output_dir = str(user_args[0])
	_capture_flow.call_deferred()


func _capture_flow() -> void:
	var scale_scene: PackedScene = load("res://tools/scale_test.tscn")
	var scale_instance := scale_scene.instantiate()
	root.add_child(scale_instance)
	await _settle()
	await _save_frame("00-actor-scale-test.png")
	scale_instance.queue_free()
	await process_frame
	await _capture_portrait_gallery()

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
	var worksite_journey_snapshot: Dictionary = instance.journey.snapshot()
	var worksite_patrol_snapshot: Dictionary = instance.patrol.snapshot()
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
	var path_keeper_capture_position: Vector2 = PathKeeperStateScript.WAYPOINTS[1]
	assert(instance.path_keeper.restore({
		"position_x": path_keeper_capture_position.x,
		"position_y": path_keeper_capture_position.y,
		"target_index": 2,
		"route_step": 1,
		"dwell_remaining": 0.0,
		"yielding_to_player": true,
	}), "守径参考图必须恢复到第二个稳定路点")
	assert(instance.exploration.restore({
		"map_id": ExplorationStateScript.MOUNTAIN_PATH_MAP_ID,
		"player_x": path_keeper_capture_position.x + 0.05,
		"player_y": path_keeper_capture_position.y,
	}), "守径参考图必须把玩家恢复到公开交互半径内")
	instance._render([])
	await _settle()
	var path_keeper_capture_contract: Dictionary = instance.get_node("%MapCanvas").path_keeper_visual_contract()
	assert(
		path_keeper_capture_contract["visible"]
		and path_keeper_capture_contract["active"]
		and path_keeper_capture_contract["normalized_position"].is_equal_approx(path_keeper_capture_position),
		"守径参考图必须显示位于确定路线上的岑苇"
	)
	assert(
		path_keeper_capture_contract["interaction_action"] == PathKeeperStateScript.TALK_TO_PATH_KEEPER
		and instance.nearby_action_id == PathKeeperStateScript.TALK_TO_PATH_KEEPER,
		"守径参考图必须使用真实近距交互行动"
	)
	assert(
		not path_keeper_capture_contract["collision_authority"]
		and not path_keeper_capture_contract["quest_authority"]
		and not path_keeper_capture_contract["battle_authority"]
		and not path_keeper_capture_contract["reward_authority"],
		"守径参考图不得引入第二套玩法权威"
	)
	await _save_frame("02-path-keeper-route.png", false, true)
	instance.path_keeper.reset()
	var path_mark_journey_snapshot: Dictionary = instance.journey.snapshot()
	assert(instance.exploration.restore({
		"map_id": ExplorationStateScript.MOUNTAIN_PATH_MAP_ID,
		"player_x": ExplorationStateScript.PATH_MARKER_POSITION.x,
		"player_y": ExplorationStateScript.PATH_MARKER_POSITION.y,
	}), "晴绳参考图必须把玩家恢复到旧石标交互锚点")
	instance._render([])
	var path_mark_start: Dictionary = instance.interact()
	assert(
		path_mark_start.get("ok", false)
		and instance.dialogue.active
		and instance.dialogue.dialogue_id == "path_mark_briefing",
		"晴绳参考图必须通过真实旧石标交互进入结构化同伴对话"
	)
	instance.skip_dialogue_to_response()
	await _settle()
	await _save_frame("02-path-mark-choice.png")
	instance._choose_dialogue_response("high_streamer")
	await _settle()
	assert(instance.exploration.restore({
		"map_id": ExplorationStateScript.MOUNTAIN_PATH_MAP_ID,
		"player_x": 0.55,
		"player_y": ExplorationStateScript.PATH_MARKER_POSITION.y,
	}), "晴绳结果参考图必须让玩家移开以完整显示路签几何")
	instance._render(["path_mark_high_streamer"])
	await _settle()
	var path_mark_capture_contract: Dictionary = instance.get_node("%MapCanvas").path_mark_visual_contract()
	assert(
		path_mark_capture_contract["visible"]
		and path_mark_capture_contract["response"] == "high_streamer"
		and path_mark_capture_contract["shape"] == "high_double_streamer",
		"晴绳结果参考图必须显示玩家真实选择的高穗几何"
	)
	assert(
		not path_mark_capture_contract["collision_authority"]
		and not path_mark_capture_contract["quest_authority"]
		and not path_mark_capture_contract["battle_authority"]
		and not path_mark_capture_contract["reward_authority"]
		and not path_mark_capture_contract["rule_authority"]
		and not path_mark_capture_contract["input_authority"]
		and not path_mark_capture_contract["gameplay_timing_authority"]
		and not path_mark_capture_contract["save_authority"],
		"晴绳结果参考图不得持有规则或存档权威"
	)
	await _save_frame("02-path-mark-high-streamer.png", false, true)
	assert(instance.journey.restore(path_mark_journey_snapshot), "晴绳参考态结束后必须恢复中立旅程夹具")
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
	_assert_intent_telegraph(instance, "rock_armor_young", "rock_rending_charge", "rock_probing_charge", "镇岩符", "岩甲战斗")
	var battle_attack_accent: Dictionary = instance.get_node("%MapCanvas").attack_accent_contract()
	assert(
		battle_attack_accent["active"]
		and battle_attack_accent["enemy_id_before"] == "rock_armor_young"
		and battle_attack_accent["resolved_intent_id"] == "rock_probing_charge"
		and battle_attack_accent["resolution_event_id"] == "enemy_glanced"
		and battle_attack_accent["shape_id"] == "probing_charge"
		and battle_attack_accent["label_text"] == "刚才 · 试探冲撞 · 化开冲势"
		and battle_attack_accent["duration"] == 0.70
		and battle_attack_accent["motion_enabled"],
		"岩甲战斗参考图必须以敌足势痕显示旧试探势，同时临势签已进到裂石势"
	)
	await _save_frame("02-cangquan-battle.png")
	instance._on_action("use_art")
	assert(instance.get_node("%BattleEnemySprite").presentation_contract()["state"] == "react",
		"受击参考图必须在真实时间推进前锁定语义姿态")
	await _save_frame("02-cangquan-battle-react.png")
	instance._on_action("retreat")
	instance._on_action("approach_moss_shell")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	_assert_intent_telegraph(instance, "spring_moss_shell", "moss_absorb_tide", "moss_spore_spray", "引气术", "泉苔战斗")
	await _save_frame("02-cangquan-moss-battle.png")
	instance._on_action("retreat")
	instance._on_action("approach_stone_puppet")
	instance.get_node("%SceneTransition").finish()
	await _settle()
	var puppet_journey_before_accessibility: Dictionary = instance.journey.snapshot()
	instance.toggle_text_scale()
	instance.toggle_high_contrast()
	_assert_intent_telegraph(instance, "unbalanced_stone_puppet", "puppet_unbalanced_swing", "puppet_rebalance_step", "守势调息", "石傀大字高对比战斗")
	var accessible_intent: Dictionary = instance.get_node("%IntentTelegraph").presentation_contract()
	assert(accessible_intent["large_text"] and accessible_intent["high_contrast"],
		"石傀参考图必须实际启用大字与高对比签面")
	assert(instance.journey.snapshot() == puppet_journey_before_accessibility,
		"签面无障碍偏好不得修改旅程规则")
	await _save_frame("02-cangquan-puppet-battle.png")
	instance.toggle_text_scale()
	instance.toggle_high_contrast()

	instance._on_action("guard")
	instance._on_action("use_talisman")
	instance._on_action("use_art")
	var defeat_canvas = instance.get_node("%MapCanvas")
	var outgoing_defeat: Dictionary = defeat_canvas.outgoing_enemy_defeat_contract()
	assert(
		outgoing_defeat["active"]
		and outgoing_defeat["visible"]
		and outgoing_defeat["outgoing_enemy_id"] == "unbalanced_stone_puppet"
		and outgoing_defeat["replacement_enemy_id"] == "rock_armor_warden",
		"普通敌退场参考图必须同时保留失衡石傀旧影与守巢者替换身份"
	)
	assert(
		not outgoing_defeat["blocks_input"]
		and not outgoing_defeat["rule_authority"]
		and not outgoing_defeat["save_authority"],
		"普通敌退场旧影只能承担非阻断的瞬时表现职责"
	)
	var defeat_attack_accent: Dictionary = defeat_canvas.attack_accent_contract()
	assert(
		not defeat_attack_accent["active"]
		and defeat_attack_accent["enemy_id_before"] == ""
		and defeat_attack_accent["resolved_intent_id"] == ""
		and defeat_attack_accent["resolution_event_id"] == ""
		and defeat_attack_accent["shape_id"] == ""
		and defeat_attack_accent["label_text"] == "",
		"普通敌致命回合中已公告但未执行的敌势不得污染退场参考图"
	)
	var settled_warden: Dictionary = instance.get_node("%BattleEnemySprite").presentation_contract()
	assert(
		instance.journey.enemy_id == "rock_armor_warden"
		and settled_warden["enemy_id"] == "rock_armor_warden"
		and settled_warden["state"] == "idle",
		"普通敌退场参考图必须让正式战斗精灵同帧落在守巢者待机态"
	)
	_assert_intent_telegraph(instance, "rock_armor_warden", "warden_pressing_charge", "warden_stonebreaking_blow", "", "普通敌退场")
	assert(not instance.get_node("%SceneTransition").is_transitioning(),
		"普通敌退场参考图不得用全屏转场遮挡旧影或接管输入")
	await _save_frame("02-cangquan-enemy-defeat.png")
	defeat_canvas.clear_battle_feedback()
	var cleared_defeat: Dictionary = defeat_canvas.outgoing_enemy_defeat_contract()
	assert(
		not cleared_defeat["active"]
		and not cleared_defeat["visible"]
		and cleared_defeat["outgoing_enemy_id"] == ""
		and cleared_defeat["replacement_enemy_id"] == "",
		"退场参考帧写入后必须清除旧敌瞬时身份再拍摄稳定首领态"
	)
	await _settle()
	_assert_intent_telegraph(instance, "rock_armor_warden", "warden_pressing_charge", "warden_stonebreaking_blow", "", "首领战斗")
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
	await _capture_worksite_reactions(instance, worksite_journey_snapshot, worksite_patrol_snapshot)
	await _capture_dialogue_speed_setting(instance)
	SaveGameScript.remove(CAPTURE_SAVE_PATH)
	SettingsStoreScript.remove(CAPTURE_SETTINGS_PATH)
	quit(0)


func _settle() -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame


func _capture_portrait_gallery() -> void:
	var gallery := Control.new()
	gallery.name = "PortraitGallery"
	gallery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(gallery)
	gallery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color("f2e6cb")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gallery.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dawn_wash := Polygon2D.new()
	dawn_wash.polygon = PackedVector2Array([
		Vector2(720, 0), Vector2(1152, 0), Vector2(1152, 214), Vector2(898, 151),
	])
	dawn_wash.color = Color(0.91, 0.65, 0.44, 0.22)
	gallery.add_child(dawn_wash)

	var title := _make_gallery_label(
		"照禾人物纸绘谱 · v2",
		Rect2(48, 19, 680, 42),
		29,
		Color("27312e")
	)
	gallery.add_child(title)
	var subtitle := _make_gallery_label(
		"同一尺寸下校准轮廓、神情与随身物件 · 无外部贴图",
		Rect2(50, 61, 720, 30),
		15,
		Color("58738f")
	)
	gallery.add_child(subtitle)

	var profiles := [
		{"id": "protagonist", "identity": "行旅者 · 初入山河", "cue": "高束发 · 蓑肩 · 靛青系带"},
		{"id": "yanqing", "identity": "砚青 · 照禾药师", "cue": "低髻 · 草药簪 · 随身药匣"},
		{"id": "liangshu", "identity": "梁叔 · 照禾守堤人", "cue": "斗笠 · 短须 · 水尺"},
		{"id": "huishen", "identity": "蕙婶 · 照禾药圃守", "cue": "包巾 · 低髻 · 织纹围裙"},
		{"id": "tao_xiaoman", "identity": "陶小满 · 渡口跑腿人", "cue": "短巾 · 挎包 · 补船木楔"},
		{"id": "journal", "identity": "行旅札记 · 最近四句", "cue": "山纹 · 墨行 · 晨桃印"},
	]
	var card_size := Vector2(336, 232)
	var portrait_size := Vector2(134, 154)
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(1152, 648))
	for index in range(profiles.size()):
		var column := index % 3
		var row := index / 3
		var card_position := Vector2(48 + column * 360, 104 + row * 248)
		var card := Panel.new()
		card.name = "PortraitCard%02d" % index
		card.position = card_position
		card.size = card_size
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.97, 0.93, 0.84, 0.94)
		card_style.border_color = Color(0.21, 0.37, 0.39, 0.42)
		card_style.set_border_width_all(2)
		card_style.corner_radius_top_left = 4
		card_style.corner_radius_top_right = 4
		card_style.corner_radius_bottom_left = 4
		card_style.corner_radius_bottom_right = 4
		card.add_theme_stylebox_override("panel", card_style)
		gallery.add_child(card)

		var portrait: Control = DialoguePortraitScript.new()
		portrait.name = "Portrait%02d" % index
		portrait.position = Vector2(14, 39)
		portrait.size = portrait_size
		card.add_child(portrait)
		assert(portrait.set_portrait(profiles[index]["id"]), "肖像总览只能使用稳定角色 ID")

		var identity := _make_gallery_label(
			profiles[index]["identity"],
			Rect2(160, 40, 162, 56),
			18,
			Color("27312e")
		)
		identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(identity)
		var cue := _make_gallery_label(
			profiles[index]["cue"],
			Rect2(160, 103, 158, 66),
			14,
			Color("58738f")
		)
		cue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(cue)
		var stable_id := _make_gallery_label(
			profiles[index]["id"],
			Rect2(160, 183, 158, 27),
			12,
			Color(0.48, 0.29, 0.18, 0.82)
		)
		card.add_child(stable_id)

		var contract: Dictionary = portrait.visual_contract()
		assert(contract["portrait_id"] == profiles[index]["id"], "肖像总览 ID 必须与纸绘契约一致")
		assert(contract["style_revision"] == 2 and contract["deterministic"], "肖像总览必须使用确定性 v2 纸绘")
		assert(not contract["external_assets"] and contract["asset_dependencies"].is_empty(), "肖像总览不得依赖外部贴图")
		assert(contract["motion_free"] and not contract["rule_authority"] and not contract["save_authority"], "肖像总览只能承担无动画表现职责")
		assert(portrait.size == portrait_size and portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE, "六张肖像必须使用真实对话框尺寸且不拦截输入")
		assert(viewport_rect.encloses(Rect2(card_position, card_size)), "肖像总览卡片必须完整落在最小窗口内")

	await _settle()
	await _save_frame("01-portrait-gallery.png")
	gallery.queue_free()
	await process_frame


func _make_gallery_label(text_value: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = rect.position
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _capture_worksite_reactions(
	instance,
	journey_snapshot: Dictionary,
	patrol_snapshot: Dictionary
) -> void:
	assert(instance.journey.restore(journey_snapshot), "工位参考图必须恢复已选择的渡口旅程")
	assert(instance.patrol.restore(patrol_snapshot), "工位参考图必须恢复已选择的巡路方向")
	assert(instance.dialogue.restore({"active": false, "dialogue_id": "", "line_index": 0}),
		"工位参考图必须从空闲对话状态开始")
	instance.get_node("%DialogueOverlay").hide()
	instance.get_node("%SceneTransition").finish()

	assert(instance.patrol.restore({
		"position_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].x,
		"position_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].y,
		"target_index": PatrolStateScript.BOAT_WAYPOINT + 1,
		"route_step": 1,
		"dwell_remaining": PatrolStateScript.ENDPOINT_DWELL_SECONDS,
		"yielding_to_player": false,
	}), "补船工位参考图必须从合法端点停留开始")
	assert(instance.exploration.restore({
		"map_id": ExplorationStateScript.DEFAULT_MAP_ID,
		"player_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].x,
		"player_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT].y,
	}), "补船工位参考图玩家必须在交互半径内")
	instance._render([])
	instance.get_node("%SceneTransition").finish()
	var boat_capture_context: Dictionary = instance.patrol.worksite_context(instance.journey.patrol_response)
	assert(boat_capture_context.get("action_id") == "talk_at_boat_worksite" and boat_capture_context.get("route_role") == "priority",
		"补船工位参考图必须保留木楔优先空间语义")
	instance._on_action("talk_at_boat_worksite")
	instance.show_full_dialogue_line()
	assert(instance.patrol.position.is_equal_approx(PatrolStateScript.WAYPOINTS[PatrolStateScript.BOAT_WAYPOINT])
		and instance.dialogue.dialogue_id == "patrol_boat_priority",
		"补船参考图必须锁定端点与优先台词")
	await _settle()
	_assert_tao_dialogue_ready(instance, "补船工位")
	await _save_frame("01-patrol-boat-reaction.png", true)
	instance.skip_dialogue_to_response()
	instance._choose_dialogue_response("secure_boat_cloth")
	await _settle()

	assert(instance.patrol.restore({
		"position_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT].x,
		"position_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT].y,
		"target_index": PatrolStateScript.HERBS_WAYPOINT - 1,
		"route_step": -1,
		"dwell_remaining": PatrolStateScript.ENDPOINT_DWELL_SECONDS,
		"yielding_to_player": false,
	}), "晾晒工位参考图必须从合法端点停留开始")
	assert(instance.exploration.restore({
		"map_id": ExplorationStateScript.DEFAULT_MAP_ID,
		"player_x": PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT].x,
		"player_y": PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT].y,
	}), "晾晒工位参考图玩家必须在交互半径内")
	instance._render([])
	var herbs_capture_context: Dictionary = instance.patrol.worksite_context(instance.journey.patrol_response)
	assert(herbs_capture_context.get("action_id") == "talk_at_herbs_worksite" and herbs_capture_context.get("route_role") == "followup",
		"晾晒工位参考图必须保留木楔优先后续语义")
	instance._on_action("talk_at_herbs_worksite")
	instance.show_full_dialogue_line()
	assert(instance.patrol.position.is_equal_approx(PatrolStateScript.WAYPOINTS[PatrolStateScript.HERBS_WAYPOINT])
		and instance.dialogue.dialogue_id == "patrol_herbs_followup",
		"晾晒参考图必须锁定端点与后续台词")
	await _settle()
	_assert_tao_dialogue_ready(instance, "晾晒工位")
	await _save_frame("01-patrol-herbs-reaction.png", true)


func _capture_dialogue_speed_setting(instance) -> void:
	assert(instance.dialogue.active and instance.dialogue.dialogue_id == "patrol_herbs_followup",
		"对话显字参考图必须复用末尾稳定的活动工位对话")
	assert(instance.settings["dialogue_speed"] == "standard",
		"对话显字参考图必须从默认标准偏好开始")
	var journey_before: Dictionary = instance.journey.snapshot()
	var dialogue_before: Dictionary = instance.dialogue.snapshot()
	var save_before := FileAccess.get_file_as_string(CAPTURE_SAVE_PATH)
	instance.toggle_dialogue_speed()
	instance.toggle_dialogue_speed()
	assert(instance.settings["dialogue_speed"] == "instant",
		"对话显字参考图必须切到整句模式")
	assert(instance.journey.snapshot() == journey_before and instance.dialogue.snapshot() == dialogue_before,
		"对话显字偏好不得修改 Journey 或结构化对话位置")
	assert(FileAccess.get_file_as_string(CAPTURE_SAVE_PATH) == save_before,
		"对话显字偏好不得改写 save v16")
	instance.toggle_pause_menu()
	await _settle()
	var pause_speed_button: Button = instance.get_node("%PauseDialogueSpeedButton")
	assert(instance.get_node("%PauseOverlay").visible,
		"整句模式参考图必须显示暂停设置")
	assert(
		pause_speed_button.text == "对话显字：整句"
		and instance.get_node("%TitleDialogueSpeedButton").text == "对话显字：整句",
		"标题与暂停必须同步显示整句偏好"
	)
	assert(not instance.get_node("%SceneTransition").visible,
		"整句模式参考图不得残留场景转场")
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(1152, 648))
	assert(viewport_rect.encloses(pause_speed_button.get_global_rect()),
		"整句模式按钮必须完整落在最小窗口内")
	await _save_frame("01-dialogue-speed-setting.png", true)
	instance.toggle_pause_menu()
	instance.toggle_dialogue_speed()
	await _settle()
	assert(instance.settings["dialogue_speed"] == "standard",
		"新增参考图后必须恢复标准对话显字偏好")


func _save_frame(
	filename: String,
	preserve_patrol: bool = false,
	preserve_path_keeper: bool = false
) -> void:
	var was_paused := paused
	paused = true
	_normalize_capture_state(preserve_patrol, preserve_path_keeper)
	_freeze_animated_sprites()
	RenderingServer.force_draw(false)
	await process_frame
	var output_dir := ProjectSettings.globalize_path(capture_output_dir)
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


func _assert_tao_dialogue_ready(game, label: String) -> void:
	var portrait: Control = game.get_node("%DialoguePortrait")
	var identity: Label = game.get_node("%DialoguePortraitLabel")
	assert(game.get_node("%DialogueOverlay").visible, "%s参考图必须显示对话层" % label)
	assert(not game.get_node("%SceneTransition").visible, "%s参考图不得残留场景转场" % label)
	assert(portrait.visible and portrait.visual_contract()["portrait_id"] == "tao_xiaoman",
		"%s参考图必须完整显示陶小满头像" % label)
	assert(identity.visible and identity.text == "陶小满 · 照禾渡口跑腿人",
		"%s参考图必须完整显示陶小满身份条" % label)


func _assert_intent_telegraph(
	game,
	expected_enemy_id: String,
	expected_intent_id: String,
	expected_next_intent_id: String,
	expected_counter_text: String,
	label: String
) -> void:
	var contract: Dictionary = game.get_node("%IntentTelegraph").presentation_contract()
	assert(contract["active"] and contract["recognized_intent"],
		"%s参考图必须显示已识别的独立临势签" % label)
	assert(contract["enemy_id"] == expected_enemy_id and contract["intent_id"] == expected_intent_id,
		"%s参考图必须显示当前权威敌人与意图" % label)
	assert(contract["next_intent_id"] == expected_next_intent_id,
		"%s参考图必须显示已门控的后一势" % label)
	assert(contract["counter_text"] == expected_counter_text,
		"%s参考图必须显示已门控的当前破绽" % label)
	assert(contract["nine_shape_complete"] and not contract["rule_authority"] and not contract["save_authority"],
		"%s参考图签面必须保持九形完整且没有规则或存档权威" % label)


func _normalize_capture_state(
	preserve_patrol: bool = false,
	preserve_path_keeper: bool = false
) -> void:
	var game := root.find_child("Main", true, false)
	if game != null and game.get("patrol") != null:
		var patrol_state = game.get("patrol")
		var journey_state = game.get("journey")
		if not preserve_patrol:
			patrol_state.reset()
		if journey_state.phase_id() == "riverbank":
			game.get_node("%MapCanvas").set_patrol_state(
				patrol_state.position,
				patrol_state.motion_direction(),
				patrol_state.is_moving(),
				journey_state.talked_to_companion,
				str(patrol_state.worksite_context(journey_state.patrol_response).get("worksite_id", ""))
			)
	if game != null and game.get("path_keeper") != null:
		var path_keeper_state = game.get("path_keeper")
		var journey_state = game.get("journey")
		if not preserve_path_keeper:
			path_keeper_state.reset()
		game.get_node("%MapCanvas").set_path_keeper_state(
			path_keeper_state.position,
			path_keeper_state.motion_direction(),
			path_keeper_state.is_moving(),
			journey_state.phase_id() == "mountain_path"
		)
	var map_canvas := root.find_child("MapCanvas", true, false)
	if map_canvas != null:
		var attack_accent: Dictionary = map_canvas.attack_accent_contract()
		if bool(attack_accent["active"]):
			var target_remaining := float(attack_accent["duration"]) * 0.5
			var advance_delta := float(attack_accent["remaining"]) - target_remaining
			assert(advance_delta >= 0.0,
				"截图标准化不得将攻击势痕时钟倒退到中点")
			if advance_delta > 0.0:
				assert(map_canvas.advance_battle_feedback(advance_delta),
					"截图标准化必须通过公开推进器锁定攻击势痕中点")
			var normalized_accent: Dictionary = map_canvas.attack_accent_contract()
			assert(
				normalized_accent["active"]
				and is_equal_approx(float(normalized_accent["remaining"]), target_remaining),
				"截图标准化必须把活动攻击势痕确定性锁在 50% 时相"
			)
	if map_canvas != null and map_canvas.feedback_remaining > 0.0:
		map_canvas.feedback_remaining = map_canvas.feedback_duration * 0.5
		map_canvas.feedback_phase = 0.0
		map_canvas.queue_redraw()
	var intent_telegraph := root.find_child("IntentTelegraph", true, false)
	if intent_telegraph != null and intent_telegraph.cue_duration > 0.0:
		intent_telegraph.cue_remaining = intent_telegraph.cue_duration * 0.5
		intent_telegraph.set_process(false)
		intent_telegraph.queue_redraw()
	var transition := root.find_child("SceneTransition", true, false)
	if transition != null and transition.is_transitioning():
		transition.elapsed = 0.0
		transition.advance(0.12)
