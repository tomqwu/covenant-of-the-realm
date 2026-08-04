extends Control

const CONTENT_PATH := "res://content/prologue.json"
const LARGE_TEXT_SCALE := 1.25
const DIALOGUE_REVEAL_STANDARD_RATE := 42.0
const DIALOGUE_REVEAL_FAST_RATE := 84.0
const HIGH_CONTRAST_INK := Color("131a17")
const HIGH_CONTRAST_PAPER := Color("fdfaf1")
const STATUS_HUD_STANDARD_BOTTOM := 78.0
const STATUS_HUD_LARGE_BOTTOM := 102.0
const INTENT_TELEGRAPH_STANDARD_TOP := 86.0
const INTENT_TELEGRAPH_LARGE_TOP := 110.0
const INTENT_TELEGRAPH_HEIGHT := 90.0
const ATTACK_RESULT_TERMINAL_EVENTS := [
	"regular_enemy_won", "boss_arrived", "battle_won", "retreated", "companion_rescue",
]
const ENEMY_NOTE_IDS := [
	"rock_armor_young",
	"spring_moss_shell",
	"unbalanced_stone_puppet",
]
const JourneyStateScript := preload("res://src/domain/journey_state.gd")
const EnemyCatalogScript := preload("res://src/domain/enemy_catalog.gd")
const ExplorationStateScript := preload("res://src/domain/exploration_state.gd")
const SaveGameScript := preload("res://src/domain/save_game.gd")
const SettingsStoreScript := preload("res://src/domain/settings_store.gd")
const DialogueStateScript := preload("res://src/domain/dialogue_state.gd")
const PatrolStateScript := preload("res://src/domain/patrol_state.gd")
const PathKeeperStateScript := preload("res://src/domain/path_keeper_state.gd")

@onready var map_canvas: Control = %MapCanvas
@onready var map_frame: Control = %MapFrame
@onready var world_camera: Node2D = %WorldRoot
@onready var chapter_label: Label = %ChapterLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var location_label: Label = %LocationLabel
@onready var description_label: Label = %DescriptionLabel
@onready var status_label: Label = %StatusLabel
@onready var status_hud: Control = $StatusHud
@onready var intent_telegraph: Control = %IntentTelegraph
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
@onready var title_text_scale_button: Button = %TitleTextScaleButton
@onready var pause_text_scale_button: Button = %PauseTextScaleButton
@onready var title_contrast_button: Button = %TitleContrastButton
@onready var pause_contrast_button: Button = %PauseContrastButton
@onready var title_dialogue_speed_button: Button = %TitleDialogueSpeedButton
@onready var pause_dialogue_speed_button: Button = %PauseDialogueSpeedButton
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
@onready var journal_tabs: TabBar = %JournalTabs
@onready var journal_count_label: Label = %JournalCountLabel
@onready var journal_entries_label: RichTextLabel = %JournalEntriesLabel
@onready var journal_close_button: Button = %JournalCloseButton

var content: Dictionary = {}
var journey = JourneyStateScript.new()
var exploration = ExplorationStateScript.new()
var dialogue = DialogueStateScript.new()
var patrol = PatrolStateScript.new()
var path_keeper = PathKeeperStateScript.new()
var nearby_action_id := ""
var save_path := SaveGameScript.DEFAULT_SAVE_PATH
var settings_path := SettingsStoreScript.DEFAULT_PATH
var settings := SettingsStoreScript.defaults()
var is_playing := false
var autosave_elapsed := 0.0
var save_recovery_pending := false
var dialogue_history_visible := false
var dialogue_reveal_elapsed := 0.0
var journal_previous_focus: Control = null
var journal_page := 0
var new_game_confirmation_visible := false
var reading_labels: Array[Control] = []
var base_reading_font_sizes := {}
var base_reading_font_colors := {}


func _ready() -> void:
	_ensure_input_actions()
	content = _load_content()
	settings = SettingsStoreScript.read(settings_path)["data"]
	map_frame.resized.connect(_sync_world_camera)
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
	_style_settings_button(title_text_scale_button)
	_style_settings_button(pause_text_scale_button)
	_style_settings_button(title_contrast_button)
	_style_settings_button(pause_contrast_button)
	_style_settings_button(title_dialogue_speed_button)
	_style_settings_button(pause_dialogue_speed_button)
	_style_settings_button(dialogue_history_button)
	_style_settings_button(dialogue_skip_button)
	_style_settings_button(dialogue_next_button)
	_style_action_button(journal_button)
	journal_button.focus_mode = Control.FOCUS_ALL
	_style_menu_button(journal_close_button)
	new_game_button.pressed.connect(start_new_game)
	continue_button.pressed.connect(_on_continue_button_pressed)
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
	title_text_scale_button.pressed.connect(toggle_text_scale)
	pause_text_scale_button.pressed.connect(toggle_text_scale)
	title_contrast_button.pressed.connect(toggle_high_contrast)
	pause_contrast_button.pressed.connect(toggle_high_contrast)
	title_dialogue_speed_button.pressed.connect(toggle_dialogue_speed)
	pause_dialogue_speed_button.pressed.connect(toggle_dialogue_speed)
	dialogue_history_button.pressed.connect(toggle_dialogue_history)
	dialogue_skip_button.pressed.connect(skip_dialogue_to_response)
	dialogue_next_button.pressed.connect(advance_dialogue)
	journal_button.pressed.connect(toggle_journal)
	journal_tabs.tab_changed.connect(_on_journal_tab_changed)
	journal_close_button.pressed.connect(close_journal)
	journal_tabs.focus_neighbor_bottom = journal_tabs.get_path_to(journal_entries_label)
	journal_entries_label.focus_neighbor_top = journal_entries_label.get_path_to(journal_tabs)
	journal_entries_label.focus_neighbor_bottom = journal_entries_label.get_path_to(journal_close_button)
	journal_close_button.focus_neighbor_top = journal_close_button.get_path_to(journal_entries_label)
	scene_transition.transition_finished.connect(_restore_action_focus)
	_capture_reading_baseline()
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
	var patrol_before: Dictionary = patrol.snapshot()
	var path_keeper_before: Dictionary = path_keeper.snapshot()
	if journey.phase_id() == "riverbank" and journey.talked_to_companion:
		patrol.advance(delta, exploration.player_position, journey.patrol_response)
	if journey.phase_id() == "mountain_path":
		path_keeper.advance(delta, exploration.player_position)
	var patrol_changed := patrol.snapshot() != patrol_before
	var path_keeper_changed := path_keeper.snapshot() != path_keeper_before
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var player_moved := false
	if not direction.is_zero_approx():
		var before: Vector2 = exploration.player_position
		move_player(direction, delta)
		player_moved = not exploration.player_position.is_equal_approx(before)
	else:
		map_canvas.set_player_motion(Vector2.ZERO)
	if patrol_changed or path_keeper_changed:
		_refresh_nearby_action()
	# Route animation is durable at explicit checkpoints, but it must not turn
	# presentation ticks into permanent once-per-second disk writes while idle.
	if player_moved:
		autosave_elapsed += delta
		if autosave_elapsed >= 1.0:
			_save_game()
			autosave_elapsed = 0.0


func _input(event: InputEvent) -> void:
	# Page shortcuts are modal controls. Reading them before focused Controls
	# prevents a TabBar or button from swallowing keyboard/controller variants.
	if not is_node_ready() or not journal_overlay.visible:
		return
	if event.is_action_pressed("cycle_journal_page"):
		select_journal_page((journal_page + 1) % 2)
		get_viewport().set_input_as_handled()
		return
	if get_viewport().gui_get_focus_owner() == journal_entries_label:
		if event.is_action_pressed("journal_scroll_down"):
			_scroll_journal(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("journal_scroll_up"):
			_scroll_journal(-1)
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if scene_transition.is_transitioning():
		get_viewport().set_input_as_handled()
		return
	if title_overlay.visible and new_game_confirmation_visible and event.is_action_pressed("pause_menu"):
		cancel_new_game_confirmation()
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


func _render(event_ids: Array, presentation_context: Dictionary = {}) -> void:
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
	event_label.text = _event_text(event_ids, presentation_context)
	map_canvas.set_story_state(
		snapshot["phase"],
		snapshot["gathered_moonleaf"],
		snapshot["talked_to_companion"],
		snapshot["lamp_turns"],
		snapshot["enemy_id"],
		snapshot["moonleaf_method"],
		snapshot["discoveries"],
		snapshot["ferryman_response"],
		snapshot["basket_response"],
		snapshot["patrol_response"],
		snapshot.get("enemy_intel", []),
		str(snapshot.get("first_breath_stage", "unstarted")),
		str(snapshot.get("path_mark_response", "unanswered"))
	)
	map_canvas.set_patrol_state(
		patrol.position,
		patrol.motion_direction(),
		patrol.is_moving(),
		snapshot["talked_to_companion"],
		_patrol_worksite_id(snapshot)
	)
	map_canvas.set_path_keeper_state(
		path_keeper.position,
		path_keeper.motion_direction(),
		path_keeper.is_moving(),
		snapshot["phase"] == "mountain_path"
	)
	nearby_action_id = _resolved_nearby_action(snapshot)
	map_canvas.set_exploration_state(exploration.player_position, nearby_action_id)
	_sync_world_camera()
	_refresh_battle_intent_presentation(snapshot)
	map_canvas.show_battle_feedback(
		event_ids,
		settings["battle_speed"] == "fast",
		settings["reduced_motion"],
		presentation_context,
		str(settings.get("text_scale", "standard")) == "large",
		bool(settings.get("high_contrast", false))
	)
	_build_actions(node)
	_render_dialogue_overlay()
	var transition_text: String = _transition_text(previous_phase, snapshot["phase"], event_ids)
	if not transition_text.is_empty():
		scene_transition.play(transition_text, bool(settings["reduced_motion"]))


func _transition_text(previous_phase: String, next_phase: String, _event_ids: Array) -> String:
	if not is_playing:
		return ""
	var transitions: Dictionary = content.get("transitions", {})
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
	var first_breath_stage := str(snapshot.get("first_breath_stage", "unstarted"))
	var herb := "已温脉" if first_breath_stage in ["warmed", "completed"] else ("有" if snapshot["gathered_moonleaf"] else "无")
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
	var first_breath_text := ""
	if snapshot["phase"] == "spring":
		first_breath_text = "　引息仪轨 %d/3" % _first_breath_progress(first_breath_stage)
	return "%s　气血 %d/12　月芽草：%s　同行：砚青%s" % [snapshot["realm"], snapshot["player_hp"], herb, first_breath_text]


func _objective_text(snapshot: Dictionary) -> String:
	match snapshot["phase"]:
		"riverbank":
			if not snapshot["talked_to_companion"]:
				return "当前目标　与渡碑旁的砚青交谈"
			if not snapshot["gathered_moonleaf"]:
				return "当前目标　前往月芽田准备护脉灵草"
			return "当前目标　沿石路寻找藏泉山门"
		"battle":
			return "当前目标　看清敌势，选择行动或撤退"
		"mountain_path":
			return "当前目标　沿石标探查碎甲声，随时可以折返"
		"spring":
			match str(snapshot.get("first_breath_stage", "unstarted")):
				"listened":
					return "当前目标　引息仪轨 1/3 · 回到砚青身旁，以月芽温脉"
				"warmed":
					return "当前目标　引息仪轨 2/3 · 循亮起的石纹静坐引息"
				_:
					return "当前目标　引息仪轨 0/3 · 到泉池西沿听泉辨脉"
		_:
			return "本节完成　山河自此显出第一道灵息"


func _next_visible_intent(visible_intents: Array, current_intent: Dictionary) -> Dictionary:
	if visible_intents.size() < 2:
		return {}
	# The domain orders visible intelligence current-first. Keeping an id-based
	# fallback makes the presentation resilient if the catalog later returns a
	# canonical cycle instead.
	if str(visible_intents[0].get("id", "")) == str(current_intent.get("id", "")):
		return visible_intents[1]
	for index in range(visible_intents.size()):
		if str(visible_intents[index].get("id", "")) == str(current_intent.get("id", "")):
			return visible_intents[(index + 1) % visible_intents.size()]
	return {}


func _battle_action_display_name(action_id: String) -> String:
	return {
		"use_art": "引气术",
		"use_talisman": "镇岩符",
		"guard": "守势调息",
	}.get(action_id, "未知应对")


func _battle_intent_presentation_data(snapshot: Dictionary) -> Dictionary:
	if str(snapshot.get("phase", "")) != "battle":
		return {"active": false}
	var visible_intents: Array = journey.visible_enemy_intents()
	if visible_intents.is_empty():
		return {"active": false}
	var current_intent: Dictionary = visible_intents[0]
	var intel_known := journey.knows_enemy_intel(str(snapshot.get("enemy_id", "")))
	var next_intent := _next_visible_intent(visible_intents, current_intent) if intel_known else {}
	var counter_text := ""
	if intel_known:
		var counter_action := str(current_intent.get("counter_action", ""))
		if not counter_action.is_empty():
			counter_text = _battle_action_display_name(counter_action)
	return {
		"active": true,
		"current_id": str(current_intent.get("id", "")),
		"current_name": str(current_intent.get("name", "未知")),
		"current_damage": int(current_intent.get("damage", 0)),
		"intel_known": intel_known,
		"next_id": str(next_intent.get("id", "")),
		"next_name": str(next_intent.get("name", "")),
		"next_damage": int(next_intent.get("damage", 0)),
		"counter_text": counter_text,
	}


func _refresh_battle_intent_presentation(snapshot: Dictionary = journey.snapshot()) -> void:
	if not is_instance_valid(intent_telegraph):
		return
	if not is_playing:
		intent_telegraph.clear_battle_intent_presentation()
		return
	intent_telegraph.set_presentation(
		_battle_intent_presentation_data(snapshot),
		str(snapshot.get("enemy_id", "")),
		bool(settings.get("high_contrast", false)),
		str(settings.get("text_scale", "standard")) == "large",
		bool(settings.get("reduced_motion", false)),
		str(settings.get("battle_speed", "standard")) == "fast"
	)


func _event_text(event_ids: Array, presentation_context: Dictionary = {}) -> String:
	if event_ids.is_empty():
		if journey.phase_id() == "riverbank":
			return "沿路寻找发光的月芽草；金色圆环会提示可交互地点。"
		return "选择行动。所有结果由确定性规则结算。"
	var messages: Array[String] = []
	var enemy_name := str(journey.current_enemy_profile().get("name", "山道灵物"))
	var raw_battle_context = presentation_context.get("battle", {})
	var battle_context: Dictionary = raw_battle_context if raw_battle_context is Dictionary else {}
	var enemy_id_before := str(battle_context.get("enemy_id_before", ""))
	if EnemyCatalogScript.supports(enemy_id_before):
		enemy_name = str(EnemyCatalogScript.profile(enemy_id_before).get("name", enemy_name))
	for event_id in event_ids:
		messages.append(str(content["messages"].get(event_id, event_id)).replace("{enemy}", enemy_name))
	if event_ids.has("enemy_hit") or event_ids.has("enemy_glanced"):
		var resolved_attack_text := _resolved_attack_event_text(event_ids, battle_context)
		if not resolved_attack_text.is_empty():
			messages.append(resolved_attack_text)
	return "\n".join(messages)


func _resolved_attack_event_text(event_ids: Array, battle_context: Dictionary) -> String:
	if journey.phase_id() != "battle":
		return ""
	for event_id in event_ids:
		if typeof(event_id) != TYPE_STRING:
			return ""
	var response_count := event_ids.count("enemy_hit") + event_ids.count("enemy_glanced")
	if response_count != 1:
		return ""
	for terminal_event_id in ATTACK_RESULT_TERMINAL_EVENTS:
		if event_ids.has(terminal_event_id):
			return ""
	if (
		not battle_context.has("enemy_id_before")
		or not battle_context.has("announced_intent_id")
		or typeof(battle_context["enemy_id_before"]) != TYPE_STRING
		or typeof(battle_context["announced_intent_id"]) != TYPE_STRING
	):
		return ""
	var enemy_id_before := str(battle_context["enemy_id_before"])
	var intent_id := str(battle_context["announced_intent_id"])
	if not EnemyCatalogScript.supports(enemy_id_before) or str(journey.enemy_id) != enemy_id_before:
		return ""
	var intent_name := ""
	var enemy_profile: Dictionary = EnemyCatalogScript.PROFILES.get(enemy_id_before, {})
	for intent_data in enemy_profile.get("intents", []):
		if str(intent_data.get("id", "")) == intent_id:
			intent_name = str(intent_data.get("name", ""))
			break
	if intent_name.is_empty():
		return ""
	var result_text := "受到冲击" if event_ids.has("enemy_hit") else "化开冲势"
	return "刚才 · %s · %s" % [intent_name, result_text]


func _chapter_summary(snapshot: Dictionary) -> String:
	var setback_text := "全程无失手" if snapshot["setbacks"] == 0 else "经历 %d 次撤退或救援" % snapshot["setbacks"]
	var talisman_text := "镇岩符留存" if snapshot["talismans"] > 0 else "镇岩符已用"
	var lamp_text := "石灯未布" if snapshot["spring_lamps"] > 0 else "石灯已护阵"
	var response_text := "你与砚青先认清了退路" if snapshot["briefing_response"] == "careful" else "你与砚青以信任同行"
	var harvest_text := "月芽留根" if snapshot["moonleaf_method"] == "cutting" else "依旧规取药"
	var discovery_text := "见闻 %d/3" % snapshot["discoveries"].size()
	var intel_text := "敌情 %d/3" % snapshot.get("enemy_intel", []).size()
	var ferryman_text: String = {
		"repair": "水尺扶正",
		"record": "涨时入簿",
	}.get(snapshot["ferryman_response"], "未问守堤")
	var basket_text: String = {
		"return": "药篓归圃",
		"trail": "药篓留山",
	}.get(snapshot["basket_response"], "药篓未安置")
	var patrol_text: String = {
		"boat_first": "先送船架",
		"herbs_first": "先翻药叶",
	}.get(snapshot["patrol_response"], "巡路未定")
	var path_mark_text: String = {
		"low_knot": "低结护篓",
		"high_streamer": "高穗辨风",
	}.get(snapshot.get("path_mark_response", "unanswered"), "晴绳未系")
	return "本节结算　%s · %s · %s · %s · %s · %s · %s · %s · %s · %s · %s · %s" % [snapshot["realm"], setback_text, talisman_text, lamp_text, harvest_text, discovery_text, intel_text, ferryman_text, basket_text, path_mark_text, patrol_text, response_text]


func _build_actions(node: Dictionary) -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus_owner) and actions.is_ancestor_of(focus_owner):
		get_viewport().gui_release_focus()
	for child in actions.get_children():
		actions.remove_child(child)
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
	if action_id == JourneyStateScript.TALK_TO_HERBKEEPER and journey.basket_response == JourneyStateScript.BASKET_UNANSWERED:
		_start_herbkeeper_dialogue()
		return
	if action_id == JourneyStateScript.TALK_TO_PATROL_RUNNER and journey.patrol_response == JourneyStateScript.PATROL_UNANSWERED:
		_start_patrol_dialogue()
		return
	if action_id in [PatrolStateScript.TALK_AT_BOAT_WORKSITE, PatrolStateScript.TALK_AT_HERBS_WORKSITE]:
		_start_patrol_work_dialogue(action_id)
		return
	if action_id == JourneyStateScript.INSPECT_PATH_MARKER and journey.path_mark_response == JourneyStateScript.PATH_MARK_UNANSWERED:
		_start_path_mark_dialogue()
		return
	if action_id == JourneyStateScript.REVIEW_JOURNEY and journey.phase_id() == "complete":
		_start_chapter_epilogue()
		return
	var result: Dictionary = journey.choose(action_id)
	if result["ok"]:
		_sync_exploration_after_action(action_id, result["events"])
		if action_id == JourneyStateScript.REPLAY_CHAPTER:
			patrol.reset()
			path_keeper.reset()
	_render(result["events"], result.get("presentation_context", {}))
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
	nearby_action_id = _resolved_nearby_action(journey.snapshot())
	var snapshot := journey.snapshot()
	map_canvas.set_patrol_state(
		patrol.position,
		patrol.motion_direction(),
		patrol.is_moving(),
		journey.talked_to_companion,
		_patrol_worksite_id(snapshot)
	)
	map_canvas.set_path_keeper_state(
		path_keeper.position,
		path_keeper.motion_direction(),
		path_keeper.is_moving(),
		snapshot["phase"] == "mountain_path"
	)
	map_canvas.set_exploration_state(exploration.player_position, nearby_action_id)
	_sync_world_camera()
	if nearby_action_id != previous_action:
		_build_actions(content["nodes"][journey.phase_id()])
	return exploration.player_position


func _sync_world_camera() -> void:
	if (
		not is_node_ready()
		or not is_instance_valid(world_camera)
		or not is_instance_valid(map_frame)
		or not is_instance_valid(map_canvas)
	):
		return
	var focus: Vector2 = map_canvas.presentation_focus_normalized(exploration.player_position)
	world_camera.update_focus(focus, map_frame.size)


func world_camera_contract() -> Dictionary:
	return world_camera.camera_contract()


func _refresh_nearby_action() -> void:
	var previous_action := nearby_action_id
	var snapshot := journey.snapshot()
	nearby_action_id = _resolved_nearby_action(snapshot)
	map_canvas.set_patrol_state(
		patrol.position,
		patrol.motion_direction(),
		patrol.is_moving(),
		bool(snapshot["talked_to_companion"]),
		_patrol_worksite_id(snapshot)
	)
	map_canvas.set_path_keeper_state(
		path_keeper.position,
		path_keeper.motion_direction(),
		path_keeper.is_moving(),
		snapshot["phase"] == "mountain_path"
	)
	map_canvas.set_nearby_action(nearby_action_id)
	if nearby_action_id != previous_action:
		_build_actions(content["nodes"][journey.phase_id()])


func _resolved_nearby_action(snapshot: Dictionary) -> String:
	# A yielding moving person must remain addressable when a public road crosses
	# a static landmark radius. The briefing or temporary worksite dialogue wins
	# only while its live patrol eligibility holds; after it resolves (or the
	# runner leaves), the fixed landmark immediately becomes available again.
	if snapshot["phase"] == "riverbank":
		var patrol_action := patrol.interaction_action(
			exploration.player_position,
			str(snapshot["patrol_response"]),
			bool(snapshot["talked_to_companion"])
		)
		if not patrol_action.is_empty():
			return patrol_action
	if snapshot["phase"] == "mountain_path":
		var path_keeper_action := path_keeper.interaction_action(
			exploration.player_position,
			true
		)
		if not path_keeper_action.is_empty():
			return path_keeper_action
	var fixed_action := exploration.interaction_action(
		snapshot["gathered_moonleaf"],
		snapshot["talked_to_companion"],
		snapshot["discoveries"],
		snapshot["ferryman_response"],
		snapshot["basket_response"],
		snapshot.get("enemy_intel", [])
	)
	fixed_action = _visible_nearby_action(fixed_action, snapshot)
	if not fixed_action.is_empty():
		return fixed_action
	return ""


func _patrol_worksite_id(snapshot: Dictionary) -> String:
	if snapshot.get("phase") != "riverbank" or not bool(snapshot.get("talked_to_companion", false)):
		return ""
	return str(patrol.worksite_context(str(snapshot.get("patrol_response", "unanswered"))).get("worksite_id", ""))


func interact() -> Dictionary:
	if not _is_exploration_phase() or nearby_action_id.is_empty():
		var no_target := {"ok": false, "events": ["nothing_nearby"], "snapshot": journey.snapshot()}
		_render(no_target["events"])
		return no_target
	if nearby_action_id == JourneyStateScript.TALK_TO_COMPANION and not journey.talked_to_companion:
		return _start_companion_dialogue()
	if nearby_action_id == JourneyStateScript.TALK_TO_FERRYMAN and journey.ferryman_response == JourneyStateScript.FERRYMAN_UNANSWERED:
		return _start_ferryman_dialogue()
	if nearby_action_id == JourneyStateScript.TALK_TO_HERBKEEPER and journey.basket_response == JourneyStateScript.BASKET_UNANSWERED:
		return _start_herbkeeper_dialogue()
	if nearby_action_id == JourneyStateScript.TALK_TO_PATROL_RUNNER and journey.patrol_response == JourneyStateScript.PATROL_UNANSWERED:
		return _start_patrol_dialogue()
	if nearby_action_id in [PatrolStateScript.TALK_AT_BOAT_WORKSITE, PatrolStateScript.TALK_AT_HERBS_WORKSITE]:
		return _start_patrol_work_dialogue(nearby_action_id)
	if nearby_action_id == JourneyStateScript.INSPECT_PATH_MARKER and journey.path_mark_response == JourneyStateScript.PATH_MARK_UNANSWERED:
		return _start_path_mark_dialogue()
	var result: Dictionary = journey.choose(nearby_action_id)
	if result["ok"]:
		_sync_exploration_after_action(nearby_action_id, result["events"])
	_render(result["events"], result.get("presentation_context", {}))
	if result["ok"]:
		_save_game()
	return result


func _is_exploration_phase() -> bool:
	return journey.phase_id() in ["riverbank", "mountain_path", "spring"]


func _action_matches_nearby(action_id: String) -> bool:
	if nearby_action_id == JourneyStateScript.GATHER_MOONLEAF:
		return action_id in [JourneyStateScript.GATHER_MOONLEAF, JourneyStateScript.GATHER_MOONLEAF_CUTTING]
	return action_id == nearby_action_id


func _visible_nearby_action(candidate: String, snapshot: Dictionary) -> String:
	if snapshot.get("phase") != "spring":
		return candidate
	var stage := str(snapshot.get("first_breath_stage", "unstarted"))
	var completed_actions: Array[String] = []
	if stage in ["listened", "warmed", "completed"]:
		completed_actions.append(JourneyStateScript.LISTEN_TO_SPRING)
	if stage in ["warmed", "completed"]:
		completed_actions.append(JourneyStateScript.WARM_MERIDIANS)
	if stage == "completed":
		completed_actions.append(JourneyStateScript.BREAKTHROUGH)
	return "" if completed_actions.has(candidate) else candidate


func _first_breath_progress(stage: String) -> int:
	return {
		"unstarted": 0,
		"listened": 1,
		"warmed": 2,
		"completed": 3,
	}.get(stage, 0)


func _sync_exploration_after_action(action_id: String, event_ids: Array) -> void:
	if action_id == JourneyStateScript.REPLAY_CHAPTER:
		exploration = ExplorationStateScript.new()
		dialogue = DialogueStateScript.new()
		return
	if journey.phase_id() == "spring" and (event_ids.has("battle_won") or event_ids.has("enemy_bypassed")):
		exploration.transition_to(ExplorationStateScript.CANGQUAN_SPRING_MAP_ID, ExplorationStateScript.SPRING_START_POSITION)
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


func toggle_text_scale() -> void:
	settings["text_scale"] = "large" if settings["text_scale"] == "standard" else "standard"
	SettingsStoreScript.write(settings, settings_path)
	_apply_accessibility_settings()


func toggle_high_contrast() -> void:
	settings["high_contrast"] = not settings["high_contrast"]
	SettingsStoreScript.write(settings, settings_path)
	_apply_accessibility_settings()


func toggle_dialogue_speed() -> void:
	var candidate: Dictionary = settings.duplicate(true)
	match str(settings.get("dialogue_speed", "standard")):
		"standard":
			candidate["dialogue_speed"] = "fast"
		"fast":
			candidate["dialogue_speed"] = "instant"
		_:
			candidate["dialogue_speed"] = "standard"
	if not SettingsStoreScript.write(candidate, settings_path):
		return
	settings = candidate
	_apply_accessibility_settings()
	if (
		settings["dialogue_speed"] == "instant"
		and dialogue.active
		and not dialogue_history_visible
		and not _dialogue_at_choices()
	):
		show_full_dialogue_line()


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
	_apply_accessibility_settings()


func _capture_reading_baseline() -> void:
	reading_labels = [
		chapter_label,
		objective_label,
		location_label,
		description_label,
		status_label,
		event_label,
		input_hint,
		title_status,
		dialogue_speaker_label,
		dialogue_label,
		dialogue_portrait_label,
		journal_location_label,
		journal_objective_label,
		journal_count_label,
		journal_entries_label,
	]
	for reading_control in reading_labels:
		var size_key := _reading_font_size_key(reading_control)
		var color_key := _reading_font_color_key(reading_control)
		base_reading_font_sizes[reading_control] = reading_control.get_theme_font_size(size_key)
		base_reading_font_colors[reading_control] = reading_control.get_theme_color(color_key)


func _apply_accessibility_settings() -> void:
	var large_text: bool = str(settings["text_scale"]) == "large"
	var scale_text := "文字大小：大字" if large_text else "文字大小：标准"
	var contrast_text := "高对比：开启" if settings["high_contrast"] else "高对比：关闭"
	var dialogue_speed_labels: Dictionary = {
		"fast": "对话显字：快速",
		"instant": "对话显字：整句",
	}
	var dialogue_speed_text := str(dialogue_speed_labels.get(
		str(settings.get("dialogue_speed", "standard")),
		"对话显字：标准"
	))
	title_text_scale_button.text = scale_text
	pause_text_scale_button.text = scale_text
	title_contrast_button.text = contrast_text
	pause_contrast_button.text = contrast_text
	title_dialogue_speed_button.text = dialogue_speed_text
	pause_dialogue_speed_button.text = dialogue_speed_text
	for reading_control in reading_labels:
		var size_key := _reading_font_size_key(reading_control)
		var color_key := _reading_font_color_key(reading_control)
		var base_size := int(base_reading_font_sizes[reading_control])
		var next_size := ceili(float(base_size) * LARGE_TEXT_SCALE) if large_text else base_size
		reading_control.add_theme_font_size_override(size_key, next_size)
		var base_color: Color = base_reading_font_colors[reading_control]
		var next_color := _high_contrast_color(base_color) if settings["high_contrast"] else base_color
		reading_control.add_theme_color_override(color_key, next_color)
	status_hud.offset_bottom = STATUS_HUD_LARGE_BOTTOM if large_text else STATUS_HUD_STANDARD_BOTTOM
	intent_telegraph.offset_top = INTENT_TELEGRAPH_LARGE_TOP if large_text else INTENT_TELEGRAPH_STANDARD_TOP
	intent_telegraph.offset_bottom = intent_telegraph.offset_top + INTENT_TELEGRAPH_HEIGHT
	_refresh_battle_intent_presentation()


func _reading_font_size_key(reading_control: Control) -> StringName:
	return &"normal_font_size" if reading_control is RichTextLabel else &"font_size"


func _reading_font_color_key(reading_control: Control) -> StringName:
	return &"default_color" if reading_control is RichTextLabel else &"font_color"


func _high_contrast_color(base_color: Color) -> Color:
	return HIGH_CONTRAST_PAPER if base_color.get_luminance() >= 0.5 else HIGH_CONTRAST_INK


func accessibility_contract() -> Dictionary:
	var dialogue_speed := str(settings.get("dialogue_speed", "standard"))
	return {
		"text_scale": settings["text_scale"],
		"high_contrast": settings["high_contrast"],
		"dialogue_speed": dialogue_speed,
		"dialogue_characters_per_second": 0.0 if dialogue_speed == "instant" else _dialogue_reveal_rate(),
		"dialogue_instant": dialogue_speed == "instant",
		"reading_label_count": reading_labels.size(),
		"base_dialogue_font_size": int(base_reading_font_sizes.get(dialogue_label, 0)),
		"dialogue_font_size": dialogue_label.get_theme_font_size("font_size"),
		"dialogue_font_color": dialogue_label.get_theme_color("font_color"),
		"motion_free": true,
		"rule_authority": false,
	}


func start_new_game() -> void:
	if not new_game_confirmation_visible and _has_local_save_artifact():
		_show_new_game_confirmation()
		return
	_begin_new_game()


func _begin_new_game() -> void:
	new_game_confirmation_visible = false
	SaveGameScript.remove(save_path)
	journey = JourneyStateScript.new()
	exploration = ExplorationStateScript.new()
	dialogue = DialogueStateScript.new()
	patrol = PatrolStateScript.new()
	path_keeper = PathKeeperStateScript.new()
	dialogue_history_visible = false
	journal_page = 0
	journal_tabs.current_tab = 0
	nearby_action_id = ""
	autosave_elapsed = 0.0
	save_recovery_pending = false
	is_playing = true
	title_overlay.hide()
	pause_overlay.hide()
	dialogue_overlay.hide()
	journal_overlay.hide()
	_render([])
	_save_game()


func _on_continue_button_pressed() -> void:
	if new_game_confirmation_visible:
		cancel_new_game_confirmation()
		return
	continue_game()


func continue_game() -> bool:
	if new_game_confirmation_visible:
		cancel_new_game_confirmation()
		return false
	var selection := _decodable_save()
	var loaded: Dictionary = selection["loaded"]
	var decoded: Dictionary = selection["decoded"]
	if not decoded["ok"]:
		_refresh_title_state()
		return false
	journey = decoded["journey"]
	exploration = decoded["exploration"]
	dialogue = decoded["dialogue"]
	patrol = decoded["patrol"]
	path_keeper = decoded["path_keeper"]
	save_recovery_pending = loaded["recovered_from_temporary"] or loaded["recovered_from_backup"]
	is_playing = true
	autosave_elapsed = 0.0
	title_overlay.hide()
	pause_overlay.hide()
	journal_overlay.hide()
	var load_event := "save_loaded"
	if loaded["recovered_from_temporary"]:
		load_event = "save_loaded_temporary"
	elif loaded["recovered_from_backup"]:
		load_event = "save_loaded_backup"
	elif loaded["migrated_from_version"] > 0:
		load_event = "save_migrated"
	_render([load_event])
	if save_recovery_pending or loaded["migrated_from_version"] > 0:
		_save_game(save_recovery_pending)
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
		_restore_dialogue_after_pause()


func _restore_dialogue_after_pause() -> void:
	if not dialogue.active:
		dialogue_overlay.hide()
		return
	# Pausing only hides the existing presentation. Re-rendering here would
	# restart the current line and could conceal text the player already read
	# after changing a reveal-speed preference in the pause menu.
	dialogue_overlay.show()
	if dialogue_history_visible:
		dialogue_history_button.grab_focus.call_deferred()
	elif _dialogue_at_choices():
		_focus_first_dialogue_choice.call_deferred()
	else:
		dialogue_next_button.grab_focus.call_deferred()


func return_to_title() -> void:
	if is_playing:
		_save_game()
	is_playing = false
	pause_overlay.hide()
	dialogue_overlay.hide()
	journal_overlay.hide()
	journal_button.hide()
	intent_telegraph.clear_battle_intent_presentation()
	map_canvas.clear_battle_feedback()
	_refresh_title_state()
	title_overlay.show()
	if continue_button.disabled:
		new_game_button.grab_focus.call_deferred()
	else:
		continue_button.grab_focus.call_deferred()


func _save_game(preserve_existing_backup: bool = false) -> bool:
	if not is_playing:
		return false
	var protect_recovery := preserve_existing_backup or save_recovery_pending
	var result: Dictionary = SaveGameScript.write(
		journey.snapshot(),
		exploration.snapshot(),
		save_path,
		dialogue.snapshot(),
		protect_recovery,
		patrol.snapshot(),
		path_keeper.snapshot()
	)
	if not result["ok"]:
		event_label.text = "自动存档失败（%s）。当前游戏仍可继续。" % result["reason"]
	else:
		save_recovery_pending = false
	return result["ok"]


func _refresh_title_state() -> void:
	new_game_confirmation_visible = false
	continue_button.text = "继续旅程"
	_set_title_settings_disabled(false)
	var selection := _decodable_save()
	var loaded: Dictionary = selection["loaded"]
	var decoded: Dictionary = selection["decoded"]
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


func _show_new_game_confirmation() -> void:
	new_game_confirmation_visible = true
	var selection := _decodable_save()
	var decoded: Dictionary = selection["decoded"]
	title_status.text = "要删除现有进度与备份吗？此操作无法撤销。" if decoded["ok"] else "要删除异常存档与备份吗？此操作无法撤销。"
	continue_button.disabled = false
	continue_button.text = "取消，保留存档"
	new_game_button.text = "确认重新开始"
	_set_title_settings_disabled(true)
	continue_button.grab_focus.call_deferred()


func cancel_new_game_confirmation() -> void:
	if not new_game_confirmation_visible:
		return
	_refresh_title_state()
	new_game_button.grab_focus.call_deferred()


func _has_local_save_artifact() -> bool:
	return (
		FileAccess.file_exists(save_path)
		or FileAccess.file_exists(save_path + ".bak")
		or FileAccess.file_exists(save_path + ".tmp")
		or FileAccess.file_exists(save_path + ".repair")
	)


func _set_title_settings_disabled(disabled: bool) -> void:
	for button: Button in [
		title_audio_button,
		title_volume_button,
		title_battle_speed_button,
		title_motion_button,
		title_text_scale_button,
		title_contrast_button,
		title_dialogue_speed_button,
	]:
		button.disabled = disabled


func new_game_confirmation_contract() -> Dictionary:
	return {
		"visible": new_game_confirmation_visible,
		"warning": title_status.text,
		"confirm_label": new_game_button.text,
		"cancel_label": continue_button.text,
		"settings_disabled": (
			title_audio_button.disabled
			and title_contrast_button.disabled
			and title_dialogue_speed_button.disabled
		),
		"save_artifact_present": _has_local_save_artifact(),
		"rule_authority": false,
	}


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
	if typeof(loaded["data"].get("patrol")) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "存档中的巡路状态无效"}
	var restored_patrol = PatrolStateScript.new()
	if not restored_patrol.restore(loaded["data"]["patrol"]):
		return {"ok": false, "reason": "存档中的巡路状态无效"}
	if typeof(loaded["data"].get("path_keeper")) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "存档中的补签人状态无效"}
	var restored_path_keeper = PathKeeperStateScript.new()
	if not restored_path_keeper.restore(loaded["data"]["path_keeper"]):
		return {"ok": false, "reason": "存档中的补签人状态无效"}
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
			DialogueStateScript.HERBKEEPER_BASKET:
				if restored_journey.phase_id() != "riverbank" or not restored_journey.discoveries.has(JourneyStateScript.DISCOVERY_ABANDONED_BASKET) or restored_journey.basket_response != JourneyStateScript.BASKET_UNANSWERED:
					return {"ok": false, "reason": "存档中的对话与剧情进度不一致"}
			DialogueStateScript.PATROL_RUNNER_BRIEFING:
				if restored_journey.phase_id() != "riverbank" or not restored_journey.talked_to_companion or restored_journey.patrol_response != JourneyStateScript.PATROL_UNANSWERED:
					return {"ok": false, "reason": "存档中的对话与剧情进度不一致"}
				if restored_patrol.interaction_action(restored_exploration.player_position, restored_journey.patrol_response, true).is_empty():
					return {"ok": false, "reason": "存档中的巡路对话位置无效"}
			DialogueStateScript.PATROL_BOAT_PRIORITY, DialogueStateScript.PATROL_BOAT_FOLLOWUP, DialogueStateScript.PATROL_HERBS_PRIORITY, DialogueStateScript.PATROL_HERBS_FOLLOWUP:
				var saved_worksite: Dictionary = DialogueStateScript.patrol_work_context(restored_dialogue.dialogue_id)
				var current_worksite: Dictionary = restored_patrol.worksite_context(restored_journey.patrol_response)
				if (
					restored_journey.phase_id() != "riverbank"
					or not restored_journey.talked_to_companion
					or str(saved_worksite.get("patrol_response", "")) != restored_journey.patrol_response
					or str(current_worksite.get("worksite_id", "")) != str(saved_worksite.get("worksite_id", ""))
					or DialogueStateScript.patrol_work_dialogue_id(
						str(saved_worksite.get("worksite_id", "")),
						restored_journey.patrol_response
					) != restored_dialogue.dialogue_id
				):
					return {"ok": false, "reason": "存档中的工作点对话与巡路先后不一致"}
				if restored_patrol.interaction_action(
					restored_exploration.player_position,
					restored_journey.patrol_response,
					true
				) != str(current_worksite.get("action_id", "")):
					return {"ok": false, "reason": "存档中的工作点对话位置无效"}
			DialogueStateScript.PATH_MARK_BRIEFING:
				if (
					restored_journey.phase_id() != "mountain_path"
					or restored_journey.path_mark_response != JourneyStateScript.PATH_MARK_UNANSWERED
					or restored_exploration.interaction_action(
						restored_journey.gathered_moonleaf,
						restored_journey.talked_to_companion,
						restored_journey.discoveries,
						restored_journey.ferryman_response,
						restored_journey.basket_response,
						restored_journey.enemy_intel
					) != JourneyStateScript.INSPECT_PATH_MARKER
				):
					return {"ok": false, "reason": "存档中的晴绳对话与旧石标位置不一致"}
		var dialogue_data: Dictionary = content.get("dialogues", {}).get(restored_dialogue.dialogue_id, {})
		if dialogue_data.is_empty() or restored_dialogue.line_index > dialogue_data.get("lines", []).size():
			return {"ok": false, "reason": "存档中的对话位置无效"}
	return {
		"ok": true,
		"reason": "",
		"journey": restored_journey,
		"exploration": restored_exploration,
		"dialogue": restored_dialogue,
		"patrol": restored_patrol,
		"path_keeper": restored_path_keeper,
	}


func _decodable_save() -> Dictionary:
	var candidates: Array[Dictionary] = SaveGameScript.read_candidates(save_path)
	for loaded in candidates:
		var decoded := _decode_save(loaded)
		if decoded["ok"]:
			return {"loaded": loaded, "decoded": decoded}
	var failure: Dictionary = SaveGameScript.read(save_path)
	return {"loaded": failure, "decoded": _decode_save(failure)}


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


func _start_herbkeeper_dialogue() -> Dictionary:
	if (
		journey.phase_id() != "riverbank"
		or not journey.discoveries.has(JourneyStateScript.DISCOVERY_ABANDONED_BASKET)
		or journey.basket_response != JourneyStateScript.BASKET_UNANSWERED
		or not dialogue.start(DialogueStateScript.HERBKEEPER_BASKET)
	):
		return {"ok": false, "events": ["basket_unavailable"], "snapshot": journey.snapshot()}
	dialogue_history_visible = false
	_render_dialogue_overlay()
	_save_game()
	return {"ok": true, "events": ["dialogue_started"], "snapshot": journey.snapshot()}


func _start_patrol_dialogue() -> Dictionary:
	if (
		journey.phase_id() != "riverbank"
		or not journey.talked_to_companion
		or journey.patrol_response != JourneyStateScript.PATROL_UNANSWERED
		or patrol.interaction_action(exploration.player_position, journey.patrol_response, true).is_empty()
		or not dialogue.start(DialogueStateScript.PATROL_RUNNER_BRIEFING)
	):
		return {"ok": false, "events": ["patrol_unavailable"], "snapshot": journey.snapshot()}
	dialogue_history_visible = false
	_render_dialogue_overlay()
	_save_game()
	return {"ok": true, "events": ["dialogue_started"], "snapshot": journey.snapshot()}


func _start_patrol_work_dialogue(action_id: String) -> Dictionary:
	var worksite: Dictionary = patrol.worksite_context(journey.patrol_response)
	var dialogue_id := DialogueStateScript.patrol_work_dialogue_id(
		str(worksite.get("worksite_id", "")),
		journey.patrol_response
	)
	if (
		journey.phase_id() != "riverbank"
		or not journey.talked_to_companion
		or str(worksite.get("action_id", "")) != action_id
		or patrol.interaction_action(
			exploration.player_position,
			journey.patrol_response,
			true
		) != action_id
		or dialogue_id.is_empty()
		or not dialogue.start(dialogue_id)
	):
		return {"ok": false, "events": ["patrol_worksite_unavailable"], "snapshot": journey.snapshot()}
	dialogue_history_visible = false
	_render_dialogue_overlay()
	_save_game()
	return {"ok": true, "events": ["dialogue_started"], "snapshot": journey.snapshot()}


func _start_path_mark_dialogue() -> Dictionary:
	if (
		journey.phase_id() != "mountain_path"
		or journey.path_mark_response != JourneyStateScript.PATH_MARK_UNANSWERED
		or _resolved_nearby_action(journey.snapshot()) != JourneyStateScript.INSPECT_PATH_MARKER
		or not dialogue.start(DialogueStateScript.PATH_MARK_BRIEFING)
	):
		return {"ok": false, "events": ["path_mark_unavailable"], "snapshot": journey.snapshot()}
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
	if (
		dialogue.dialogue_id == DialogueStateScript.PATH_MARK_BRIEFING
		and _resolved_nearby_action(journey.snapshot()) != JourneyStateScript.INSPECT_PATH_MARKER
	):
		return
	var expected_event_id := _dialogue_choice_event(response_id)
	if expected_event_id.is_empty():
		push_error("对话回应缺少内容事件：%s" % response_id)
		return
	var staged_journey = JourneyStateScript.new()
	if not staged_journey.restore(journey.snapshot()):
		push_error("无法暂存对话回应前的旅程状态")
		return
	var journey_before: Dictionary = staged_journey.snapshot()
	var staged_patrol = null
	var patrol_work_context: Dictionary = DialogueStateScript.patrol_work_context(dialogue.dialogue_id)
	if dialogue.dialogue_id == DialogueStateScript.PATROL_RUNNER_BRIEFING:
		staged_patrol = PatrolStateScript.new()
		if not staged_patrol.restore(patrol.snapshot()) or not staged_patrol.apply_priority(response_id):
			push_error("巡路回应无法应用到确定性路线：%s" % response_id)
			return
	elif not patrol_work_context.is_empty():
		staged_patrol = PatrolStateScript.new()
		var current_worksite: Dictionary = patrol.worksite_context(staged_journey.patrol_response)
		if (
			not staged_patrol.restore(patrol.snapshot())
			or str(patrol_work_context.get("patrol_response", "")) != staged_journey.patrol_response
			or str(current_worksite.get("worksite_id", "")) != str(patrol_work_context.get("worksite_id", ""))
			or not staged_patrol.finish_worksite(str(patrol_work_context.get("worksite_id", "")))
		):
			push_error("巡路工作点回应无法原子结束停留：%s" % response_id)
			return
	var result: Dictionary
	match dialogue.dialogue_id:
		DialogueStateScript.COMPANION_BRIEFING:
			result = staged_journey.complete_companion_briefing(response_id)
		DialogueStateScript.CHAPTER_EPILOGUE:
			result = staged_journey.complete_epilogue(response_id)
		DialogueStateScript.FERRYMAN_BRIEFING:
			result = staged_journey.complete_ferryman_dialogue(response_id)
		DialogueStateScript.HERBKEEPER_BASKET:
			result = staged_journey.complete_basket_dialogue(response_id)
		DialogueStateScript.PATROL_RUNNER_BRIEFING:
			result = staged_journey.complete_patrol_dialogue(response_id)
		DialogueStateScript.PATROL_BOAT_PRIORITY, DialogueStateScript.PATROL_BOAT_FOLLOWUP, DialogueStateScript.PATROL_HERBS_PRIORITY, DialogueStateScript.PATROL_HERBS_FOLLOWUP:
			result = staged_journey.complete_patrol_work_dialogue(
				str(patrol_work_context.get("worksite_id", "")),
				response_id
			)
		DialogueStateScript.PATH_MARK_BRIEFING:
			result = staged_journey.complete_path_mark_dialogue(response_id)
		_:
			return
	if not result["ok"]:
		return
	if not patrol_work_context.is_empty() and staged_journey.snapshot() != journey_before:
		push_error("巡路工作点回应不得修改旅程状态：%s" % response_id)
		return
	if not result["events"].has(expected_event_id):
		push_error("对话回应与规则事件不一致：%s" % response_id)
		return
	if not dialogue.finish():
		push_error("活动对话无法提交回应：%s" % response_id)
		return
	journey = staged_journey
	if staged_patrol != null:
		patrol = staged_patrol
	dialogue_history_visible = false
	dialogue_overlay.hide()
	_render(result["events"], result.get("presentation_context", {}))
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
	var focus_owner := get_viewport().gui_get_focus_owner()
	if is_instance_valid(focus_owner) and dialogue_choices.is_ancestor_of(focus_owner):
		get_viewport().gui_release_focus()
	for child in dialogue_choices.get_children():
		dialogue_choices.remove_child(child)
		child.queue_free()
	dialogue_choices.hide()
	if not dialogue.active or title_overlay.visible or pause_overlay.visible:
		dialogue_overlay.hide()
		return
	var dialogue_data := _current_dialogue_data()
	var lines: Array = dialogue_data.get("lines", [])
	if dialogue_data.is_empty() or lines.is_empty():
		dialogue_overlay.hide()
		return
	dialogue_overlay.show()
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
	_set_dialogue_portrait("protagonist" if speaker == "你" else "yanqing" if speaker == "砚青" else "liangshu" if speaker == "梁叔" else "huishen" if speaker == "蕙婶" else "tao_xiaoman" if speaker == "陶小满" else "journal")
	dialogue_label.text = _resolved_dialogue_text(str(line.get("text", "")))
	dialogue_skip_button.show()
	dialogue_next_button.show()
	_begin_dialogue_reveal()
	dialogue_next_button.grab_focus.call_deferred()


func _render_dialogue_choices(choices: Array) -> void:
	dialogue_speaker_label.text = "你的回应"
	_set_dialogue_portrait("protagonist")
	dialogue_label.text = str(_current_dialogue_data().get("choice_prompt", "请选择回应。"))
	dialogue_label.visible_characters = -1
	dialogue_skip_button.hide()
	dialogue_next_button.hide()
	dialogue_choices.show()
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
	if not choices.is_empty():
		_focus_first_dialogue_choice.call_deferred()


func _focus_first_dialogue_choice() -> void:
	if not dialogue.active or not dialogue_choices.visible or title_overlay.visible or pause_overlay.visible:
		return
	for child in dialogue_choices.get_children():
		if child is Button and not child.disabled and not child.is_queued_for_deletion():
			child.grab_focus()
			return


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
		"huishen": "蕙婶 · 照禾药圃守",
		"tao_xiaoman": "陶小满 · 照禾渡口跑腿人",
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
	var basket_reflection: String = {
		"return": "蕙婶已把公用药篓挂回圃门",
		"trail": "补好提绳的药篓仍在山道等后来人",
	}.get(snapshot["basket_response"], "那只山道药篓还没有找到下一处归宿")
	var path_mark_reflection: String = {
		"low_knot": "旧石标的低结会先碰到负篓人的手",
		"high_streamer": "旧石标的亮穗会把山风方向递给雾里的人",
	}.get(snapshot.get("path_mark_response", "unanswered"), "旧石标背后的晴绳还等着人重新系好")
	var patrol_reflection: String = {
		"boat_first": "陶小满先把怕潮的木楔送往补船架",
		"herbs_first": "陶小满先赶在日头偏西前翻好了药叶",
	}.get(snapshot["patrol_response"], "陶小满还在渡口中央等人替她看一眼风和日头")
	var intel_count: int = snapshot.get("enemy_intel", []).size()
	var intel_reflection := "尚未辨明的灵物痕迹"
	if intel_count == ENEMY_NOTE_IDS.size():
		intel_reflection = "三种灵物的行止"
	elif intel_count > 0:
		intel_reflection = "%d种灵物的行止" % intel_count
	return source_text.replace("{harvest_reflection}", harvest_reflection) \
		.replace("{discovery_reflection}", discovery_reflection) \
		.replace("{setback_reflection}", setback_reflection) \
		.replace("{companion_reflection}", companion_reflection) \
		.replace("{ferryman_reflection}", ferryman_reflection) \
		.replace("{basket_reflection}", basket_reflection) \
		.replace("{path_mark_reflection}", path_mark_reflection) \
		.replace("{patrol_reflection}", patrol_reflection) \
		.replace("{intel_reflection}", intel_reflection)


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


func _on_journal_tab_changed(tab_index: int) -> void:
	journal_page = clampi(tab_index, 0, 1)
	_render_journal()


func select_journal_page(tab_index: int) -> void:
	journal_page = clampi(tab_index, 0, 1)
	journal_tabs.current_tab = journal_page
	_render_journal()


func _scroll_journal(direction: int) -> void:
	var scroll_bar := journal_entries_label.get_v_scroll_bar()
	var maximum_value := maxf(0.0, scroll_bar.max_value - scroll_bar.page)
	var page_step := maxf(48.0, scroll_bar.page * 0.75)
	if direction > 0:
		if scroll_bar.value >= maximum_value - 0.5:
			journal_close_button.grab_focus()
		else:
			scroll_bar.value = minf(maximum_value, scroll_bar.value + page_step)
	elif direction < 0:
		if scroll_bar.value <= 0.5:
			journal_tabs.grab_focus()
		else:
			scroll_bar.value = maxf(0.0, scroll_bar.value - page_step)


func _render_journal() -> void:
	var snapshot: Dictionary = journey.snapshot()
	journal_location_label.text = "%s · 序章第一息" % _phase_display_name(snapshot["phase"])
	journal_objective_label.text = _objective_text(snapshot)
	if journal_tabs.current_tab != journal_page:
		journal_tabs.current_tab = journal_page
	if journal_page == 1:
		_render_enemy_journal(snapshot)
	else:
		_render_discovery_journal(snapshot)
	journal_entries_label.scroll_to_line(0)


func _render_discovery_journal(snapshot: Dictionary) -> void:
	journal_count_label.text = "照禾见闻 · %d/3　Q / RB 切页" % snapshot["discoveries"].size()
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
	if snapshot["basket_response"] != JourneyStateScript.BASKET_UNANSWERED:
		var basket_side_id := "basket_%s" % snapshot["basket_response"]
		var basket_entry: Dictionary = content.get("journal_side_entries", {}).get(basket_side_id, {})
		lines.append("◆ %s\n%s" % [basket_entry.get("title", "药篓小记"), basket_entry.get("summary", "这段药篓去向暂时无法辨认。")])
	if snapshot.get("path_mark_response", JourneyStateScript.PATH_MARK_UNANSWERED) != JourneyStateScript.PATH_MARK_UNANSWERED:
		var path_mark_side_id := "path_mark_%s" % snapshot["path_mark_response"]
		var path_mark_entry: Dictionary = content.get("journal_side_entries", {}).get(path_mark_side_id, {})
		lines.append("◆ %s\n%s" % [path_mark_entry.get("title", "晴绳小记"), path_mark_entry.get("summary", "这段路签去向暂时无法辨认。")])
	if snapshot["patrol_response"] != JourneyStateScript.PATROL_UNANSWERED:
		var patrol_side_id := "patrol_%s" % snapshot["patrol_response"]
		var patrol_entry: Dictionary = content.get("journal_side_entries", {}).get(patrol_side_id, {})
		lines.append("◆ %s\n%s" % [patrol_entry.get("title", "巡路小记"), patrol_entry.get("summary", "这段巡路先后暂时无法辨认。")])
	journal_entries_label.text = "\n\n".join(lines)


func _render_enemy_journal(snapshot: Dictionary) -> void:
	var known_intel: Array = snapshot.get("enemy_intel", [])
	journal_count_label.text = "灵物志 · %d/%d　Q / RB 切页" % [known_intel.size(), ENEMY_NOTE_IDS.size()]
	var enemy_notes: Dictionary = content.get("enemy_notes", {})
	var lines: Array[String] = []
	for enemy_index in range(ENEMY_NOTE_IDS.size()):
		var enemy_id: String = ENEMY_NOTE_IDS[enemy_index]
		if known_intel.has(enemy_id):
			var note: Dictionary = enemy_notes.get(enemy_id, {})
			var cycle_lines: Array[String] = []
			for cycle_step in note.get("cycle", []):
				cycle_lines.append(str(cycle_step))
			lines.append("◆ %s\n痕迹　%s\n行止　%s\n应对　%s" % [
				note.get("title", "未命名灵物"),
				note.get("trace", "痕迹暂时无法辨认。"),
				"　→　".join(cycle_lines),
				note.get("counter", "应对方法暂时无法辨认。"),
			])
		else:
			lines.append("◇ 未辨灵物 %d\n寻见山道痕迹并亲自查看后，才会记下名目与行止。" % (enemy_index + 1))
	journal_entries_label.text = "\n\n".join(lines)


func journal_contract() -> Dictionary:
	var entries: Dictionary = content.get("journal_entries", {})
	var side_entries: Dictionary = content.get("journal_side_entries", {})
	var unlocked_titles: Array[String] = []
	for discovery_id in journey.discoveries:
		if entries.has(discovery_id):
			unlocked_titles.append(str(entries[discovery_id].get("title", "")))
	if journey.ferryman_response != JourneyStateScript.FERRYMAN_UNANSWERED:
		var side_id := "ferryman_%s" % journey.ferryman_response
		if side_entries.has(side_id):
			unlocked_titles.append(str(side_entries[side_id].get("title", "")))
	if journey.basket_response != JourneyStateScript.BASKET_UNANSWERED:
		var basket_side_id := "basket_%s" % journey.basket_response
		if side_entries.has(basket_side_id):
			unlocked_titles.append(str(side_entries[basket_side_id].get("title", "")))
	if journey.path_mark_response != JourneyStateScript.PATH_MARK_UNANSWERED:
		var path_mark_side_id := "path_mark_%s" % journey.path_mark_response
		if side_entries.has(path_mark_side_id):
			unlocked_titles.append(str(side_entries[path_mark_side_id].get("title", "")))
	if journey.patrol_response != JourneyStateScript.PATROL_UNANSWERED:
		var patrol_side_id := "patrol_%s" % journey.patrol_response
		if side_entries.has(patrol_side_id):
			unlocked_titles.append(str(side_entries[patrol_side_id].get("title", "")))
	var enemy_titles: Array[String] = []
	var enemy_notes: Dictionary = content.get("enemy_notes", {})
	for enemy_id in journey.enemy_intel:
		if enemy_notes.has(enemy_id):
			enemy_titles.append(str(enemy_notes[enemy_id].get("title", "")))
	return {
		"visible": journal_overlay.visible,
		"page": journal_page,
		"page_title": journal_tabs.get_tab_title(journal_page),
		"discovered_count": journey.discoveries.size(),
		"total": JourneyStateScript.DISCOVERY_IDS.size(),
		"locked_count": JourneyStateScript.DISCOVERY_IDS.size() - journey.discoveries.size(),
		"unlocked_titles": unlocked_titles,
		"intel_count": journey.enemy_intel.size(),
		"intel_total": ENEMY_NOTE_IDS.size(),
		"locked_enemy_count": ENEMY_NOTE_IDS.size() - journey.enemy_intel.size(),
		"enemy_titles": enemy_titles,
		"objective": journal_objective_label.text,
		"entries_text": journal_entries_label.text,
		"scrollable": journal_entries_label.scroll_active,
		"blocks_input": journal_overlay.mouse_filter == Control.MOUSE_FILTER_STOP,
		"depth": journal_overlay.z_index,
	}


func _process_dialogue_reveal(delta: float) -> void:
	if (
		not is_finite(delta)
		or delta <= 0.0
		or dialogue_history_visible
		or _dialogue_at_choices()
		or dialogue_label.visible_characters == -1
	):
		return
	var text_length := dialogue_label.text.length()
	var reveal_increment := delta * _dialogue_reveal_rate()
	if not is_finite(reveal_increment):
		dialogue_reveal_elapsed = float(text_length)
	else:
		dialogue_reveal_elapsed = minf(float(text_length), dialogue_reveal_elapsed + reveal_increment)
	dialogue_label.visible_characters = mini(text_length, floori(dialogue_reveal_elapsed))
	if dialogue_label.visible_characters >= text_length:
		dialogue_label.visible_characters = -1
		dialogue_next_button.text = "继续"


func _begin_dialogue_reveal() -> void:
	dialogue_reveal_elapsed = 0.0
	if str(settings.get("dialogue_speed", "standard")) == "instant":
		dialogue_label.visible_characters = -1
		dialogue_next_button.text = "继续"
		return
	dialogue_label.visible_characters = 0
	dialogue_next_button.text = "显示全文"


func _dialogue_reveal_rate() -> float:
	return (
		DIALOGUE_REVEAL_FAST_RATE
		if str(settings.get("dialogue_speed", "standard")) == "fast"
		else DIALOGUE_REVEAL_STANDARD_RATE
	)


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
	_add_key_action("cycle_journal_page", [KEY_Q])
	_add_key_action("journal_scroll_up", [KEY_PAGEUP])
	_add_key_action("journal_scroll_down", [KEY_PAGEDOWN])
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button("interact", JOY_BUTTON_A)
	_add_joy_button("pause_menu", JOY_BUTTON_START)
	_add_joy_button("open_journal", JOY_BUTTON_Y)
	_add_joy_button("cycle_journal_page", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button("journal_scroll_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button("journal_scroll_down", JOY_BUTTON_DPAD_DOWN)
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
