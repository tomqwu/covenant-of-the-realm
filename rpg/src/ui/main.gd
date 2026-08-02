extends Control

const CONTENT_PATH := "res://content/prologue.json"
const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const DialogueStateScript := preload("res://src/domain/dialogue_state.gd")

@onready var map_canvas: Control = %MapCanvas
@onready var chapter_label: Label = %ChapterLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var location_label: Label = %LocationLabel
@onready var description_label: Label = %DescriptionLabel
@onready var status_label: Label = %StatusLabel
@onready var event_label: Label = %EventLabel
@onready var actions: GridContainer = %Actions
@onready var input_hint: Label = %InputHint
@onready var title_overlay: Control = %TitleOverlay
@onready var title_status: Label = %TitleStatus
@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var pause_overlay: Control = %PauseOverlay
@onready var resume_button: Button = %ResumeButton
@onready var return_title_button: Button = %ReturnTitleButton
@onready var title_audio_button: Button = %TitleAudioButton
@onready var title_volume_button: Button = %TitleVolumeButton
@onready var pause_audio_button: Button = %PauseAudioButton
@onready var pause_volume_button: Button = %PauseVolumeButton
@onready var title_battle_speed_button: Button = %TitleBattleSpeedButton
@onready var pause_battle_speed_button: Button = %PauseBattleSpeedButton
@onready var title_motion_button: Button = %TitleMotionButton
@onready var pause_motion_button: Button = %PauseMotionButton
@onready var audio_manager: AudioStreamPlayer = %AudioManager
@onready var dialogue_overlay: Control = %DialogueOverlay
@onready var dialogue_speaker_label: Label = %DialogueSpeakerLabel
@onready var dialogue_label: Label = %DialogueLabel
@onready var dialogue_portrait: Control = %DialoguePortrait
@onready var dialogue_portrait_label: Label = %DialoguePortraitLabel
@onready var dialogue_choices: GridContainer = %DialogueChoices
@onready var dialogue_history_button: Button = %DialogueHistoryButton
@onready var dialogue_skip_button: Button = %DialogueSkipButton
@onready var dialogue_next_button: Button = %DialogueNextButton
@onready var scene_transition: Control = %SceneTransition
@onready var journal_button: Button = %JournalButton
@onready var journal_overlay: Control = %JournalOverlay
@onready var journal_location_label: Label = %JournalLocationLabel
@onready var journal_objective_label: Label = %JournalObjectiveLabel
@onready var journal_count_label: Label = %JournalCountLabel
@onready var journal_entries_label: Label = %JournalEntriesLabel
@onready var journal_close_button: Button = %JournalCloseButton

var content: Dictionary = {}
var journey = JourneyStateScript.new()
var exploration = ExplorationStateScript.new()
var dialogue = DialogueStateScript.new()
var nearby_action_id := ""
var save_path := SaveGameScript.DEFAULT_SAVE_PATH
var settings_path := SettingsStoreScript.DEFAULT_PATH
var settings := SettingsStoreScript.defaults()
var is_playing := false
var autosave_elapsed := 0.0
var dialogue_history_visible := false
var dialogue_reveal_elapsed := 0.0
var journal_previous_focus: Control = null


func _ready() -> void:
	_ensure_input_actions()
	content = _load_content()
	settings = SettingsStoreScript.read(settings_path)["data"]
	_render([])
	_style_menu_button(new_game_button)
	_style_menu_button(continue_button)
	_style_menu_button(resume_button)
	_style_menu_button(return_title_button)
	_style_settings_button(title_audio_button)
	_style_settings_button(title_volume_button)
	_style_settings_button(pause_audio_button)
	_style_settings_button(pause_volume_button)
	_style_settings_button(title_battle_speed_button)
	_style_settings_button(pause_battle_speed_button)
	_style_settings_button(title_motion_button)
	_style_settings_button(pause_motion_button)
	_style_settings_button(dialogue_history_button)
	_style_settings_button(dialogue_skip_button)
	_style_settings_button(dialogue_next_button)
	_style_action_button(journal_button)
	journal_button.focus_mode = Control.FOCUS_ALL
	_style_menu_button(journal_close_button)
	new_game_button.pressed.connect(start_new_game)
	continue_button.pressed.connect(continue_game)
	resume_button.pressed.connect(toggle_pause_menu)
	return_title_button.pressed.connect(return_to_title)
	title_audio_button.pressed.connect(toggle_audio)
	pause_audio_button.pressed.connect(toggle_audio)
	title_volume_button.pressed.connect(cycle_audio_volume)
	pause_volume_button.pressed.connect(cycle_audio_volume)
	title_battle_speed_button.pressed.connect(toggle_battle_speed)
	pause_battle_speed_button.pressed.connect(toggle_battle_speed)
	title_motion_button.pressed.connect(toggle_reduced_motion)
	pause_motion_button.pressed.connect(toggle_reduced_motion)
	dialogue_history_button.pressed.connect(toggle_dialogue_history)
	dialogue_skip_button.pressed.connect(skip_dialogue_to_response)
	dialogue_next_button.pressed.connect(advance_dialogue)
	journal_button.pressed.connect(toggle_journal)
	journal_close_button.pressed.connect(close_journal)
	scene_transition.transition_finished.connect(_restore_action_focus)
	_apply_audio_settings()
	pause_overlay.hide()
	dialogue_overlay.hide()
	journal_overlay.hide()
	journal_button.hide()
	_refresh_title_state()
	title_overlay.show()
	if continue_button.disabled:
		new_game_button.grab_focus.call_deferred()
	else:
		continue_button.grab_focus.call_deferred()


func _process(delta: float) -> void:
	if scene_transition.is_transitioning():
		return
	if journal_overlay.visible:
		return
	if dialogue.active and dialogue_overlay.visible and not pause_overlay.visible:
		_process_dialogue_reveal(delta)
		return
	if not is_playing or title_overlay.visible or pause_overlay.visible or not _is_exploration_phase():
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not direction.is_zero_approx():
		var before: Vector2 = exploration.player_position
		move_player(direction, delta)
		if not exploration.player_position.is_equal_approx(before):
			autosave_elapsed += delta
			if autosave_elapsed >= 1.0:
				_save_game()
				autosave_elapsed = 0.0
	else:
		map_canvas.set_player_motion(Vector2.ZERO)


func _unhandled_input(event: InputEvent) -> void:
	if scene_transition.is_transitioning():
		get_viewport().set_input_as_handled()
		return
	if journal_overlay.visible:
		if event.is_action_pressed("open_journal") or event.is_action_pressed("pause_menu"):
			close_journal()
		get_viewport().set_input_as_handled()
		return
	if is_playing and event.is_action_pressed("open_journal") and _can_open_journal():
		open_journal()
		get_viewport().set_input_as_handled()
		return
	if is_playing and event.is_action_pressed("pause_menu"):
		toggle_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if dialogue.active and dialogue_overlay.visible and event.is_action_pressed("interact"):
		if not _dialogue_at_choices():
			advance_dialogue()
			get_viewport().set_input_as_handled()
		return
	if not is_playing or title_overlay.visible or pause_overlay.visible:
		return
	if _is_exploration_phase() and event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()


func _load_content() -> Dictionary:
	var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if file == null:
		push_error("无法读取原创剧情文件：%s" % CONTENT_PATH)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("剧情文件不是有效对象：%s" % CONTENT_PATH)
		return {}
	return parsed


func _render(event_ids: Array) -> void:
	if content.is_empty():
		return
	var previous_phase: String = map_canvas.current_visual_mode()
	var snapshot := journey.snapshot()
	var node: Dictionary = content["nodes"][snapshot["phase"]]
	journal_button.visible = is_playing and not title_overlay.visible
	chapter_label.text = "序章 · 第一息"
	objective_label.text = _objective_text(snapshot)
	location_label.text = node["title"]
	description_label.text = node["description"]
	if snapshot["phase"] == "battle":
		description_label.text += "\n" + str(journey.current_enemy_profile().get("description", ""))
	if snapshot["phase"] == "complete":
		description_label.text += "\n\n" + _chapter_summary(snapshot)
	if journal_overlay.visible:
		_render_journal()
	status_label.text = _status_text(snapshot)
	event_label.text = _event_text(event_ids)
	map_canvas.set_story_state(
		snapshot["phase"],
		snapshot["gathered_moonleaf"],
		snapshot["talked_to_companion"],
		snapshot["lamp_turns"],
		snapshot["enemy_id"],
		snapshot["moonleaf_method"],
		snapshot["discoveries"],
		snapshot["ferryman_response"]
	)
	nearby_action_id = exploration.interaction_action(snapshot["gathered_moonleaf"], snapshot["talked_to_companion"], snapshot["discoveries"], snapshot["ferryman_response"])
	map_canvas.set_exploration_state(exploration.player_position, nearby_action_id)
	map_canvas.show_battle_feedback(
		event_ids,
		settings["battle_speed"] == "fast",
		settings["reduced_motion"]
	)
	_build_actions(node)
	_render_dialogue_overlay()
	var transition_text: String = _transition_text(previous_phase, snapshot["phase"], event_ids)
	if not transition_text.is_empty():
		scene_transition.play(transition_text, bool(settings["reduced_motion"]))


func _transition_text(previous_phase: String, next_phase: String, event_ids: Array) -> String:
	if not is_playing:
		return ""
	var transitions: Dictionary = content.get("transitions", {})
	if event_ids.has("boss_arrived"):
		return str(transitions.get("boss_arrived", ""))
	if previous_phase != next_phase:
		return str(transitions.get(next_phase, ""))
	return ""


func _restore_action_focus() -> void:
	if not is_playing or title_overlay.visible or pause_overlay.visible or dialogue_overlay.visible:
		return
	if _is_exploration_phase():
		return
	_focus_first_action.call_deferred()


func _focus_first_action() -> void:
	if not is_playing or title_overlay.visible or pause_overlay.visible or dialogue_overlay.visible:
		return
	for child in actions.get_children():
		if child is Button and not child.disabled and not child.is_queued_for_deletion():
			child.grab_focus()
			return


func _status_text(snapshot: Dictionary) -> String:
	var herb := "有" if snapshot["gathered_moonleaf"] else "无"
	if snapshot["phase"] == "battle":
		var profile := journey.current_enemy_profile()
		var effects: Array[String] = []
		if snapshot["armor_break_turns"] > 0:
			effects.append("破甲 %d" % snapshot["armor_break_turns"])
		if snapshot["focus_turns"] > 0:
			effects.append("凝息 %d" % snapshot["focus_turns"])
		var effect_text := "" if effects.is_empty() else "　状态 " + "/".join(effects)
		return ("%s　气血 %d/12　%s %d/%d　符 %d　援护 %d　石灯 %d　回合 %d%s" % [
			snapshot["realm"],
			snapshot["player_hp"],
			profile.get("name", "未知灵物"),
			snapshot["enemy_hp"],
			profile.get("max_hp", 0),
			snapshot["talismans"],
			snapshot["companion_supports"],
			snapshot["spring_lamps"],
			snapshot["round"],
			effect_text,
		])
	return "%s　气血 %d/12　月芽草：%s　同行：砚青" % [snapshot["realm"], snapshot["player_hp"], herb]


func _objective_text(snapshot: Dictionary) -> String:
	match snapshot["phase"]:
		"riverbank":
			if not snapshot["talked_to_companion"]:
				return "当前目标　与渡碑旁的砚青交谈"
			if not snapshot["gathered_moonleaf"]:
				return "当前目标　前往月芽田准备护脉灵草"
			return "当前目标　沿石路寻找藏泉山门"
		"battle":
			var profile := journey.current_enemy_profile()
			var intent := journey.current_enemy_intent()
			return "下一回合　%s（%d 伤害）　材质弱点　%s" % [
				intent.get("name", "未知"),
				intent.get("damage", 0),
				profile.get("weakness", "尚未识别"),
			]
		"mountain_path":
			return "当前目标　沿石标探查碎甲声，随时可以折返"
		"spring":
			return "当前目标　借月芽草完成第一次引息"
		_:
			return "本节完成　山河自此显出第一道灵息"


func _event_text(event_ids: Array) -> String:
	if event_ids.is_empty():
		if journey.phase_id() == "riverbank":
			return "沿路寻找发光的月芽草；金色圆环会提示可交互地点。"
		return "选择行动。所有结果由确定性规则结算。"
	var messages: Array[String] = []
	var enemy_name := str(journey.current_enemy_profile().get("name", "山道灵物"))
	for event_id in event_ids:
		messages.append(str(content["messages"].get(event_id, event_id)).replace("{enemy}", enemy_name))
	return "\n".join(messages)


func _chapter_summary(snapshot: Dictionary) -> String:
	var setback_text := "全程无失手" if snapshot["setbacks"] == 0 else "经历 %d 次撤退或救援" % snapshot["setbacks"]
	var talisman_text := "镇岩符留存" if snapshot["talismans"] > 0 else "镇岩符已用"
	var lamp_text := "石灯未布" if snapshot["spring_lamps"] > 0 else "石灯已护阵"
	var response_text := "你与砚青先认清了退路" if snapshot["briefing_response"] == "careful" else "你与砚青以信任同行"
	var harvest_text := "月芽留根" if snapshot["moonleaf_method"] == "cutting" else "依旧规取药"
	var discovery_text := "见闻 %d/3" % snapshot["discoveries"].size()
	var ferryman_text: String = {
		"repair": "水尺扶正",
		"record": "涨时入簿",
	}.get(snapshot["ferryman_response"], "未问守堤")
	return "本节结算　%s · %s · %s · %s · %s · %s · %s · %s" % [snapshot["realm"], setback_text, talisman_text, lamp_text, harvest_text, discovery_text, ferryman_text, response_text]


func _build_actions(node: Dictionary) -> void:
	for child in actions.get_children():
		child.queue_free()
	var available := journey.available_actions()
	var first_button: Button = null
	for action: Dictionary in node["actions"]:
		if not available.has(action["id"]):
			continue
		if _is_exploration_phase() and not _action_matches_nearby(action["id"]):
			continue
		var button := Button.new()
		button.text = action["label"]
		button.custom_minimum_size = Vector2(0, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE if _is_exploration_phase() else Control.FOCUS_ALL
		_style_action_button(button)
		button.pressed.connect(_on_action.bind(action["id"]))
		actions.add_child(button)
		if first_button == null:
			first_button = button
	if first_button == null and _is_exploration_phase():
		var guidance := Label.new()
		guidance.text = "附近暂无可交互目标"
		guidance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		guidance.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		guidance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		guidance.size_flags_vertical = Control.SIZE_EXPAND_FILL
		guidance.add_theme_color_override("font_color", Color("5f674f"))
		actions.add_child(guidance)
	if first_button != null and not _is_exploration_phase():
		_focus_first_action.call_deferred()
	input_hint.text = "WASD / 方向键移动 · E / 空格 / 手柄 A 交互 · J / 手柄 Y 札记" if _is_exploration_phase() else "鼠标点击 · 方向键选择 · Enter / 手柄 A 确认 · J / 手柄 Y 札记"


func _style_action_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("e2d2b3")
	normal.border_color = Color("7f846d")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)

	var hover := normal.duplicate()
	hover.bg_color = Color("f7eccf")
	hover.border_color = Color("9b8050")

	var pressed := normal.duplicate()
	pressed.bg_color = Color("ccb68f")
	pressed.border_color = Color("5f674f")

	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = Color("e4c36e")
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(2)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color("27312e"))
	button.add_theme_color_override("font_hover_color", Color("27312e"))
	button.add_theme_color_override("font_pressed_color", Color("27312e"))
	button.add_theme_color_override("font_focus_color", Color("27312e"))
	button.add_theme_font_size_override("font_size", 17)


func _style_menu_button(button: Button) -> void:
	_style_action_button(button)
	button.custom_minimum_size = Vector2(320, 52)
	button.focus_mode = Control.FOCUS_ALL


func _style_settings_button(button: Button) -> void:
	_style_action_button(button)
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL


func _on_action(action_id: String) -> void:
	if action_id == JourneyStateScript.TALK_TO_COMPANION and not journey.talked_to_companion:
		_start_companion_dialogue()
		return
	if action_id == JourneyStateScript.TALK_TO_FERRYMAN and journey.ferryman_response == JourneyStateScript.FERRYMAN_UNANSWERED:
		_start_ferryman_dialogue()
		return
	if action_id == JourneyStateScript.REVIEW_JOURNEY and journey.phase_id() == "complete":
		_start_chapter_epilogue()
		return
	var result: Dictionary = journey.choose(action_id)
	if result["ok"]:
		_sync_exploration_after_action(action_id, result["events"])
	_render(result["events"])
	if result["ok"]:
		_save_game()
	if result["ok"] and action_id == JourneyStateScript.RETURN_TO_TITLE:
		return_to_title()


func move_player(direction: Vector2, delta: float) -> Vector2:
	if not _is_exploration_phase():
		return exploration.player_position
	var previous_action := nearby_action_id
	var previous_position: Vector2 = exploration.player_position
	exploration.move(direction, delta)
	map_canvas.set_player_motion(direction if not exploration.player_position.is_equal_approx(previous_position) else Vector2.ZERO)
	nearby_action_id = exploration.interaction_action(journey.gathered_moonleaf, journey.talked_to_companion, journey.discoveries, journey.ferryman_response)
	map_canvas.set_exploration_state(exploration.player_position, nearby_action_id)
	if nearby_action_id != previous_action:
		_build_actions(content["nodes"][journey.phase_id()])
	return exploration.player_position


func interact() -> Dictionary:
	if not _is_exploration_phase() or nearby_action_id.is_empty():
		var no_target := {"ok": false, "events": ["nothing_nearby"], "snapshot": journey.snapshot()}
		_render(no_target["events"])
		return no_target
	if nearby_action_id == JourneyStateScript.TALK_TO_COMPANION and not journey.talked_to_companion:
		return _start_companion_dialogue()
	if nearby_action_id == JourneyStateScript.TALK_TO_FERRYMAN and journey.ferryman_response == JourneyStateScript.FERRYMAN_UNANSWERED:
		return _start_ferryman_dialogue()
	var result: Dictionary = journey.choose(nearby_action_id)
	if result["ok"]:
		_sync_exploration_after_action(nearby_action_id, result["events"])
	_render(result["events"])
	if result["ok"]:
		_save_game()
	return result


func _is_exploration_phase() -> bool:
	return journey.phase_id() in ["riverbank", "mountain_path"]


func _action_matches_nearby(action_id: String) -> bool:
	if nearby_action_id == JourneyStateScript.GATHER_MOONLEAF:
		return action_id in [JourneyStateScript.GATHER_MOONLEAF, JourneyStateScript.GATHER_MOONLEAF_CUTTING]
	return action_id == nearby_action_id


func _sync_exploration_after_action(action_id: String, event_ids: Array) -> void:
	if action_id == JourneyStateScript.REPLAY_CHAPTER:
		exploration = ExplorationStateScript.new()
		dialogue = DialogueStateScript.new()
		return
	if action_id == JourneyStateScript.ENTER_SPRING and journey.phase_id() == "mountain_path":
		exploration.transition_to(ExplorationStateScript.MOUNTAIN_PATH_MAP_ID)
		return
	if action_id == JourneyStateScript.RETURN_TO_FERRY:
		exploration.transition_to(ExplorationStateScript.DEFAULT_MAP_ID, ExplorationStateScript.SPRING_GATE_POSITION)
		return
	if action_id == JourneyStateScript.RETREAT:
		exploration.transition_to(ExplorationStateScript.MOUNTAIN_PATH_MAP_ID, ExplorationStateScript.PATH_RETREAT_POSITION)
		return
	if event_ids.has("companion_rescue"):
		exploration.transition_to(ExplorationStateScript.DEFAULT_MAP_ID)


func configure_save_path(path: String) -> void:
	save_path = path


func configure_settings_path(path: String) -> void:
	settings_path = path


func toggle_audio() -> void:
	settings["audio_enabled"] = not settings["audio_enabled"]
	SettingsStoreScript.write(settings, settings_path)
	_apply_audio_settings()


func cycle_audio_volume() -> void:
	var current := float(settings["audio_volume"])
	if current < 0.5:
		settings["audio_volume"] = 0.6
	elif current < 0.8:
		settings["audio_volume"] = 1.0
	else:
		settings["audio_volume"] = 0.35
	SettingsStoreScript.write(settings, settings_path)
	_apply_audio_settings()


func toggle_battle_speed() -> void:
	settings["battle_speed"] = "fast" if settings["battle_speed"] == "standard" else "standard"
	SettingsStoreScript.write(settings, settings_path)
	_apply_presentation_settings()


func toggle_reduced_motion() -> void:
	settings["reduced_motion"] = not settings["reduced_motion"]
	SettingsStoreScript.write(settings, settings_path)
	_apply_presentation_settings()


func _apply_audio_settings() -> void:
	audio_manager.set_audio_volume(float(settings["audio_volume"]))
	audio_manager.set_audio_enabled(bool(settings["audio_enabled"]))
	var audio_text := "环境音：开启" if settings["audio_enabled"] else "环境音：关闭"
	var volume_text := "音量：%d%%" % roundi(float(settings["audio_volume"]) * 100.0)
	title_audio_button.text = audio_text
	pause_audio_button.text = audio_text
	title_volume_button.text = volume_text
	pause_volume_button.text = volume_text
	_apply_presentation_settings()


func _apply_presentation_settings() -> void:
	var speed_text := "战斗表现：快速" if settings["battle_speed"] == "fast" else "战斗表现：标准"
	var motion_text := "动态效果：简化" if settings["reduced_motion"] else "动态效果：完整"
	title_battle_speed_button.text = speed_text
	pause_battle_speed_button.text = speed_text
	title_motion_button.text = motion_text
	pause_motion_button.text = motion_text


func start_new_game() -> void:
	SaveGameScript.remove(save_path)
	journey = JourneyStateScript.new()
	exploration = ExplorationStateScript.new()
	dialogue = DialogueStateScript.new()
	dialogue_history_visible = false
	nearby_action_id = ""
	autosave_elapsed = 0.0
	is_playing = true
	title_overlay.hide()
	pause_overlay.hide()
	dialogue_overlay.hide()
	journal_overlay.hide()
	_render([])
	_save_game()


func continue_game() -> bool:
	var loaded: Dictionary = SaveGameScript.read(save_path)
	var decoded := _decode_save(loaded)
	if not decoded["ok"]:
		_refresh_title_state()
		return false
	journey = decoded["journey"]
	exploration = decoded["exploration"]
	dialogue = decoded["dialogue"]
	is_playing = true
	autosave_elapsed = 0.0
	title_overlay.hide()
	pause_overlay.hide()
	journal_overlay.hide()
	var load_event := "save_loaded"
	if loaded["recovered_from_backup"]:
		load_event = "save_loaded_backup"
	elif loaded["migrated_from_version"] > 0:
		load_event = "save_migrated"
	_render([load_event])
	if loaded["migrated_from_version"] > 0:
		_save_game()
	return true


func toggle_pause_menu() -> void:
	if not is_playing or title_overlay.visible:
		return
	if journal_overlay.visible:
		close_journal()
	pause_overlay.visible = not pause_overlay.visible
	if pause_overlay.visible:
		_save_game()
		dialogue_overlay.hide()
		resume_button.grab_focus.call_deferred()
	else:
		_render_dialogue_overlay()


func return_to_title() -> void:
	if is_playing:
		_save_game()
	is_playing = false
	pause_overlay.hide()
	dialogue_overlay.hide()
	journal_overlay.hide()
	journal_button.hide()
	_refresh_title_state()
	title_overlay.show()
	if continue_button.disabled:
		new_game_button.grab_focus.call_deferred()
	else:
		continue_button.grab_focus.call_deferred()


func _save_game() -> bool:
	if not is_playing:
		return false
	var result: Dictionary = SaveGameScript.write(journey.snapshot(), exploration.snapshot(), save_path, dialogue.snapshot())
	if not result["ok"]:
		event_label.text = "自动存档失败（%s）。当前游戏仍可继续。" % result["reason"]
	return result["ok"]


func _refresh_title_state() -> void:
	var loaded: Dictionary = SaveGameScript.read(save_path)
	var decoded := _decode_save(loaded)
	continue_button.disabled = not decoded["ok"]
	if decoded["ok"]:
		var phase_name := _phase_display_name(str(loaded["data"]["journey"].get("phase", "")))
		title_status.text = "发现本地存档 · %s" % phase_name
		new_game_button.text = "重新开始（覆盖存档）"
	elif loaded["reason"] == "missing":
		title_status.text = "尚无旅程存档。"
		new_game_button.text = "踏入山河"
	elif loaded["ok"]:
		title_status.text = "%s；原文件已保留。" % decoded["reason"]
		new_game_button.text = "开始新游戏（覆盖异常存档）"
	else:
		title_status.text = "存档暂不可读取（%s）；原文件已保留。" % loaded["reason"]
		new_game_button.text = "开始新游戏（覆盖异常存档）"


func _decode_save(loaded: Dictionary) -> Dictionary:
	if not loaded["ok"]:
		return {"ok": false, "reason": "存档文件不可读取"}
	var restored_journey = JourneyStateScript.new()
	if not restored_journey.restore(loaded["data"]["journey"]):
		return {"ok": false, "reason": "存档中的剧情状态无效"}
	var restored_exploration = ExplorationStateScript.new()
	if not restored_exploration.restore(loaded["data"]["exploration"]):
		return {"ok": false, "reason": "存档中的地图位置无效"}
	var restored_dialogue = DialogueStateScript.new()
	if not restored_dialogue.restore(loaded["data"]["dialogue"]):
		return {"ok": false, "reason": "存档中的对话状态无效"}
	if restored_dialogue.active:
		match restored_dialogue.dialogue_id:
			DialogueStateScript.COMPANION_BRIEFING:
				if restored_journey.talked_to_companion or restored_journey.phase_id() != "riverbank":
					return {"ok": false, "reason": "存档中的对话与剧情进度不一致"}
			DialogueStateScript.CHAPTER_EPILOGUE:
				if restored_journey.phase_id() != "complete":
					return {"ok": false, "reason": "存档中的对话与剧情进度不一致"}
			DialogueStateScript.FERRYMAN_BRIEFING:
				if restored_journey.phase_id() != "riverbank" or restored_journey.ferryman_response != JourneyStateScript.FERRYMAN_UNANSWERED:
					return {"ok": false, "reason": "存档中的对话与剧情进度不一致"}
		var dialogue_data: Dictionary = content.get("dialogues", {}).get(restored_dialogue.dialogue_id, {})
		if dialogue_data.is_empty() or restored_dialogue.line_index > dialogue_data.get("lines", []).size():
			return {"ok": false, "reason": "存档中的对话位置无效"}
	return {
		"ok": true,
		"reason": "",
		"journey": restored_journey,
		"exploration": restored_exploration,
		"dialogue": restored_dialogue,
	}


func _start_companion_dialogue() -> Dictionary:
	if not dialogue.start(DialogueStateScript.COMPANION_BRIEFING):
		return {"ok": false, "events": ["already_briefed"], "snapshot": journey.snapshot()}
	dialogue_history_visible = false
	_render_dialogue_overlay()
	_save_game()
	return {"ok": true, "events": ["dialogue_started"], "snapshot": journey.snapshot()}


func _start_chapter_epilogue() -> Dictionary:
	if journey.phase_id() != "complete" or not dialogue.start(DialogueStateScript.CHAPTER_EPILOGUE):
		return {"ok": false, "events": ["epilogue_unavailable"], "snapshot": journey.snapshot()}
	dialogue_history_visible = false
	_render_dialogue_overlay()
	_save_game()
	return {"ok": true, "events": ["dialogue_started"], "snapshot": journey.snapshot()}


func _start_ferryman_dialogue() -> Dictionary:
	if (
		journey.phase_id() != "riverbank"
		or journey.ferryman_response != JourneyStateScript.FERRYMAN_UNANSWERED
		or not dialogue.start(DialogueStateScript.FERRYMAN_BRIEFING)
	):
		return {"ok": false, "events": ["ferryman_already_answered"], "snapshot": journey.snapshot()}
	dialogue_history_visible = false
	_render_dialogue_overlay()
	_save_game()
	return {"ok": true, "events": ["dialogue_started"], "snapshot": journey.snapshot()}


func advance_dialogue() -> void:
	if not dialogue.active or _dialogue_at_choices():
		return
	if dialogue_label.visible_characters != -1:
		show_full_dialogue_line()
		return
	var lines: Array = _current_dialogue_data().get("lines", [])
	dialogue.advance(lines.size())
	dialogue_history_visible = false
	_render_dialogue_overlay()
	_save_game()


func show_full_dialogue_line() -> void:
	if not dialogue.active or _dialogue_at_choices():
		return
	dialogue_label.visible_characters = -1
	dialogue_reveal_elapsed = 0.0
	dialogue_next_button.text = "继续"


func skip_dialogue_to_response() -> void:
	if not dialogue.active:
		return
	var lines: Array = _current_dialogue_data().get("lines", [])
	if dialogue.skip_to_choices(lines.size()):
		dialogue_history_visible = false
		_render_dialogue_overlay()
		_save_game()


func toggle_dialogue_history() -> void:
	if not dialogue.active:
		return
	dialogue_history_visible = not dialogue_history_visible
	_render_dialogue_overlay()


func _choose_dialogue_response(response_id: String) -> void:
	if not _dialogue_at_choices():
		return
	var result: Dictionary
	match dialogue.dialogue_id:
		DialogueStateScript.COMPANION_BRIEFING:
			result = journey.complete_companion_briefing(response_id)
		DialogueStateScript.CHAPTER_EPILOGUE:
			result = journey.complete_epilogue(response_id)
		DialogueStateScript.FERRYMAN_BRIEFING:
			result = journey.complete_ferryman_dialogue(response_id)
		_:
			return
	if not result["ok"]:
		return
	var expected_event_id := _dialogue_choice_event(response_id)
	if expected_event_id.is_empty() or not result["events"].has(expected_event_id):
		push_error("对话回应与规则事件不一致：%s" % response_id)
		return
	dialogue.finish()
	dialogue_history_visible = false
	dialogue_overlay.hide()
	_render(result["events"])
	_save_game()


func _current_dialogue_data() -> Dictionary:
	return content.get("dialogues", {}).get(dialogue.dialogue_id, {})


func _dialogue_choice_event(response_id: String) -> String:
	for raw_choice in _current_dialogue_data().get("choices", []):
		var choice: Dictionary = raw_choice
		if choice.get("id") == response_id:
			return str(choice.get("event_id", ""))
	return ""


func _dialogue_at_choices() -> bool:
	if not dialogue.active:
		return false
	return dialogue.at_choices(_current_dialogue_data().get("lines", []).size())


func _render_dialogue_overlay() -> void:
	if not dialogue.active or title_overlay.visible or pause_overlay.visible:
		dialogue_overlay.hide()
		return
	var dialogue_data := _current_dialogue_data()
	var lines: Array = dialogue_data.get("lines", [])
	if dialogue_data.is_empty() or lines.is_empty():
		dialogue_overlay.hide()
		return
	dialogue_overlay.show()
	for child in dialogue_choices.get_children():
		child.queue_free()
	dialogue_choices.hide()
	dialogue_history_button.text = "返回对话" if dialogue_history_visible else "回顾"
	if dialogue_history_visible:
		_render_dialogue_history(lines)
		return
	if dialogue.at_choices(lines.size()):
		_render_dialogue_choices(dialogue_data.get("choices", []))
		return
	var line: Dictionary = lines[dialogue.line_index]
	var speaker := str(line.get("speaker", ""))
	dialogue_speaker_label.text = speaker
	_set_dialogue_portrait("protagonist" if speaker == "你" else "yanqing" if speaker == "砚青" else "liangshu" if speaker == "梁叔" else "journal")
	dialogue_label.text = _resolved_dialogue_text(str(line.get("text", "")))
	dialogue_label.visible_characters = 0
	dialogue_reveal_elapsed = 0.0
	dialogue_skip_button.show()
	dialogue_next_button.show()
	dialogue_next_button.text = "显示全文"
	dialogue_next_button.grab_focus.call_deferred()


func _render_dialogue_choices(choices: Array) -> void:
	dialogue_speaker_label.text = "你的回应"
	_set_dialogue_portrait("protagonist")
	dialogue_label.text = str(_current_dialogue_data().get("choice_prompt", "请选择回应。"))
	dialogue_label.visible_characters = -1
	dialogue_skip_button.hide()
	dialogue_next_button.hide()
	dialogue_choices.show()
	var first_button: Button = null
	for raw_choice in choices:
		var choice: Dictionary = raw_choice
		var button := Button.new()
		button.text = str(choice.get("label", ""))
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		_style_action_button(button)
		button.pressed.connect(_choose_dialogue_response.bind(str(choice.get("id", ""))))
		dialogue_choices.add_child(button)
		if first_button == null:
			first_button = button
	if first_button != null:
		first_button.grab_focus.call_deferred()


func _render_dialogue_history(lines: Array) -> void:
	var seen_count := mini(dialogue.line_index + 1, lines.size())
	var first_index := maxi(0, seen_count - 4)
	var history_lines: Array[String] = []
	for index in range(first_index, seen_count):
		var line: Dictionary = lines[index]
		history_lines.append("%s：%s" % [line.get("speaker", ""), _resolved_dialogue_text(str(line.get("text", "")))])
	dialogue_speaker_label.text = "对话回顾"
	_set_dialogue_portrait("journal")
	dialogue_label.text = "\n".join(history_lines)
	dialogue_label.visible_characters = -1
	dialogue_choices.hide()
	dialogue_skip_button.hide()
	dialogue_next_button.hide()
	dialogue_history_button.grab_focus.call_deferred()


func _set_dialogue_portrait(portrait_id: String) -> void:
	var accepted: bool = dialogue_portrait.set_portrait(portrait_id)
	var stable_id := portrait_id if accepted else "journal"
	dialogue_portrait_label.text = {
		"protagonist": "行旅者 · 初入山河",
		"yanqing": "砚青 · 照禾药师",
		"liangshu": "梁叔 · 照禾守堤人",
		"journal": "行旅札记 · 最近四句",
	}.get(stable_id, "行旅札记 · 最近四句")


func _resolved_dialogue_text(source_text: String) -> String:
	var snapshot: Dictionary = journey.snapshot()
	var harvest_reflection := "剪下成熟叶、把月芽留了根" if snapshot["moonleaf_method"] == "cutting" else "依旧规只取了一株月芽"
	var discovery_count: int = snapshot["discoveries"].size()
	var discovery_reflection := "沿途尚未看清的空处" if discovery_count == 0 else "沿途%d处生活痕迹" % discovery_count
	var setback_count := int(snapshot["setbacks"])
	var setback_reflection := "你没有因求快而失手"
	if setback_count == 1:
		setback_reflection = "你在山道退过一次，却知道何时回头"
	elif setback_count > 1:
		setback_reflection = "你经历%d次撤退或救援，仍肯重新准备" % setback_count
	var companion_reflection := "你先认清退路再迈步" if snapshot["briefing_response"] == "careful" else "你肯把判断交给同伴，也肯在危险时提醒我"
	var ferryman_reflection: String = {
		"repair": "梁叔的水尺已经重新立稳",
		"record": "梁叔把你记下的涨水时辰夹进了守堤簿",
	}.get(snapshot["ferryman_response"], "渡口那根水尺仍等着人去看")
	return source_text.replace("{harvest_reflection}", harvest_reflection) \
		.replace("{discovery_reflection}", discovery_reflection) \
		.replace("{setback_reflection}", setback_reflection) \
		.replace("{companion_reflection}", companion_reflection) \
		.replace("{ferryman_reflection}", ferryman_reflection)


func _can_open_journal() -> bool:
	return (
		is_playing
		and not title_overlay.visible
		and not pause_overlay.visible
		and not dialogue_overlay.visible
		and not scene_transition.is_transitioning()
	)


func toggle_journal() -> void:
	if journal_overlay.visible:
		close_journal()
	elif _can_open_journal():
		open_journal()


func open_journal() -> void:
	if not _can_open_journal():
		return
	journal_previous_focus = get_viewport().gui_get_focus_owner()
	_render_journal()
	journal_overlay.show()
	journal_close_button.grab_focus.call_deferred()


func close_journal() -> void:
	if not journal_overlay.visible:
		return
	journal_overlay.hide()
	if is_instance_valid(journal_previous_focus) and journal_previous_focus.is_visible_in_tree():
		journal_previous_focus.grab_focus.call_deferred()
	elif _is_exploration_phase():
		get_viewport().gui_release_focus()
	else:
		_focus_first_action.call_deferred()
	journal_previous_focus = null


func _render_journal() -> void:
	var snapshot: Dictionary = journey.snapshot()
	journal_location_label.text = "%s · 序章第一息" % _phase_display_name(snapshot["phase"])
	journal_objective_label.text = _objective_text(snapshot)
	journal_count_label.text = "照禾见闻 · %d/3" % snapshot["discoveries"].size()
	var entry_content: Dictionary = content.get("journal_entries", {})
	var lines: Array[String] = []
	var locked_index := 0
	for discovery_id in JourneyStateScript.DISCOVERY_IDS:
		if snapshot["discoveries"].has(discovery_id):
			var entry: Dictionary = entry_content.get(discovery_id, {})
			lines.append("◆ %s\n%s" % [entry.get("title", "未命名见闻"), entry.get("summary", "这段记忆暂时无法辨认。")])
		else:
			locked_index += 1
			lines.append("◇ 未记之事 %d\n靠近可疑的生活痕迹，亲自辨认后才会写入。" % locked_index)
	if snapshot["ferryman_response"] != JourneyStateScript.FERRYMAN_UNANSWERED:
		var side_id := "ferryman_%s" % snapshot["ferryman_response"]
		var side_entry: Dictionary = content.get("journal_side_entries", {}).get(side_id, {})
		lines.append("◆ %s\n%s" % [side_entry.get("title", "守堤小记"), side_entry.get("summary", "这段守堤记录暂时无法辨认。")])
	journal_entries_label.text = "\n\n".join(lines)


func journal_contract() -> Dictionary:
	var entries: Dictionary = content.get("journal_entries", {})
	var unlocked_titles: Array[String] = []
	for discovery_id in journey.discoveries:
		if entries.has(discovery_id):
			unlocked_titles.append(str(entries[discovery_id].get("title", "")))
	if journey.ferryman_response != JourneyStateScript.FERRYMAN_UNANSWERED:
		var side_id := "ferryman_%s" % journey.ferryman_response
		var side_entries: Dictionary = content.get("journal_side_entries", {})
		if side_entries.has(side_id):
			unlocked_titles.append(str(side_entries[side_id].get("title", "")))
	return {
		"visible": journal_overlay.visible,
		"discovered_count": journey.discoveries.size(),
		"total": JourneyStateScript.DISCOVERY_IDS.size(),
		"locked_count": JourneyStateScript.DISCOVERY_IDS.size() - journey.discoveries.size(),
		"unlocked_titles": unlocked_titles,
		"objective": journal_objective_label.text,
		"entries_text": journal_entries_label.text,
		"blocks_input": journal_overlay.mouse_filter == Control.MOUSE_FILTER_STOP,
		"depth": journal_overlay.z_index,
	}


func _process_dialogue_reveal(delta: float) -> void:
	if dialogue_history_visible or _dialogue_at_choices() or dialogue_label.visible_characters == -1:
		return
	dialogue_reveal_elapsed += delta * 42.0
	dialogue_label.visible_characters = mini(dialogue_label.text.length(), floori(dialogue_reveal_elapsed))
	if dialogue_label.visible_characters >= dialogue_label.text.length():
		dialogue_label.visible_characters = -1
		dialogue_next_button.text = "继续"


func _phase_display_name(phase_name: String) -> String:
	match phase_name:
		"riverbank":
			return "照禾渡口"
		"mountain_path":
			return "藏泉山道"
		"battle":
			return "藏泉山道"
		"spring":
			return "藏泉石室"
		"complete":
			return "第一息"
	return "未知地点"


func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("interact", [KEY_E, KEY_SPACE])
	_add_key_action("pause_menu", [KEY_ESCAPE])
	_add_key_action("open_journal", [KEY_J])
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button("interact", JOY_BUTTON_A)
	_add_joy_button("pause_menu", JOY_BUTTON_START)
	_add_joy_button("open_journal", JOY_BUTTON_Y)
	_add_joy_button("ui_accept", JOY_BUTTON_A)


func _add_key_action(action_name: StringName, keycodes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keycodes:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func _add_joy_axis(action_name: StringName, axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)


func _add_joy_button(action_name: StringName, button_index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)
