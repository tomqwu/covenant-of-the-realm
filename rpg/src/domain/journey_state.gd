extends RefCounted
class_name JourneyState

const EnemyCatalogScript := preload("res://src/domain/enemy_catalog.gd")

enum Phase { RIVERBANK, MOUNTAIN_PATH, BATTLE, SPRING, COMPLETE }

const GATHER_MOONLEAF := "gather_moonleaf"
const GATHER_MOONLEAF_CUTTING := "gather_moonleaf_cutting"
const ENTER_SPRING := "enter_spring"
const TALK_TO_COMPANION := "talk_to_companion"
const TALK_TO_FERRYMAN := "talk_to_ferryman"
const INSPECT_PATH_MARKER := "inspect_path_marker"
const INSPECT_FERRY_WATERMARK := "inspect_ferry_watermark"
const INSPECT_SPRING_SEAM := "inspect_spring_seam"
const INSPECT_ABANDONED_BASKET := "inspect_abandoned_basket"
const APPROACH_ENEMY := "approach_enemy"
const APPROACH_MOSS_SHELL := "approach_moss_shell"
const APPROACH_STONE_PUPPET := "approach_stone_puppet"
const BYPASS_ENEMY := "bypass_enemy"
const RETURN_TO_FERRY := "return_to_ferry"
const USE_ART := "use_art"
const USE_TALISMAN := "use_talisman"
const GUARD := "guard"
const COMPANION_SUPPORT := "companion_support"
const DEPLOY_SPRING_LAMP := "deploy_spring_lamp"
const RETREAT := "retreat"
const BREAKTHROUGH := "breakthrough"
const REVIEW_JOURNEY := "review_journey"
const RETURN_TO_TITLE := "return_to_title"
const REPLAY_CHAPTER := "replay_chapter"
const RESPONSE_UNANSWERED := "unanswered"
const RESPONSE_CAREFUL := "careful"
const RESPONSE_TRUSTING := "trusting"
const BRIEFING_RESPONSES := [RESPONSE_CAREFUL, RESPONSE_TRUSTING]
const EPILOGUE_RECORD := "record"
const EPILOGUE_RETURN := "return"
const EPILOGUE_RESPONSES := [EPILOGUE_RECORD, EPILOGUE_RETURN]
const FERRYMAN_UNANSWERED := "unanswered"
const FERRYMAN_REPAIR := "repair"
const FERRYMAN_RECORD := "record"
const FERRYMAN_RESPONSES := [FERRYMAN_UNANSWERED, FERRYMAN_REPAIR, FERRYMAN_RECORD]
const MOONLEAF_UNSELECTED := "unselected"
const MOONLEAF_WHOLE_PLANT := "whole_plant"
const MOONLEAF_CUTTING := "cutting"
const MOONLEAF_METHODS := [MOONLEAF_UNSELECTED, MOONLEAF_WHOLE_PLANT, MOONLEAF_CUTTING]
const DISCOVERY_FERRY_WATERMARK := "ferry_watermark"
const DISCOVERY_SPRING_SEAM := "spring_seam"
const DISCOVERY_ABANDONED_BASKET := "abandoned_basket"
const DISCOVERY_IDS := [DISCOVERY_FERRY_WATERMARK, DISCOVERY_SPRING_SEAM, DISCOVERY_ABANDONED_BASKET]

var phase := Phase.RIVERBANK
var gathered_moonleaf := false
var talked_to_companion := false
var player_hp := 12
var enemy_id := EnemyCatalogScript.DEFAULT_ENEMY_ID
var enemy_hp := EnemyCatalogScript.max_hp(enemy_id)
var talismans := 1
var round_number := 1
var realm := "凡身"
var companion_supports := 1
var spring_lamps := 1
var lamp_turns := 0
var setbacks := 0
var briefing_response := RESPONSE_UNANSWERED
var moonleaf_method := MOONLEAF_UNSELECTED
var armor_break_turns := 0
var focus_turns := 0
var discoveries: Array[String] = []
var ferryman_response := FERRYMAN_UNANSWERED


func phase_id() -> String:
	match phase:
		Phase.RIVERBANK:
			return "riverbank"
		Phase.MOUNTAIN_PATH:
			return "mountain_path"
		Phase.BATTLE:
			return "battle"
		Phase.SPRING:
			return "spring"
		_:
			return "complete"


func available_actions() -> PackedStringArray:
	match phase:
		Phase.RIVERBANK:
			var actions := PackedStringArray()
			if not discoveries.has(DISCOVERY_FERRY_WATERMARK):
				actions.append(INSPECT_FERRY_WATERMARK)
			if not talked_to_companion:
				actions.append(TALK_TO_COMPANION)
			if ferryman_response == FERRYMAN_UNANSWERED:
				actions.append(TALK_TO_FERRYMAN)
			if not gathered_moonleaf:
				actions.append(GATHER_MOONLEAF)
				actions.append(GATHER_MOONLEAF_CUTTING)
			actions.append(ENTER_SPRING)
			return actions
		Phase.MOUNTAIN_PATH:
			var path_actions := PackedStringArray([INSPECT_PATH_MARKER])
			if not discoveries.has(DISCOVERY_SPRING_SEAM):
				path_actions.append(INSPECT_SPRING_SEAM)
			if not discoveries.has(DISCOVERY_ABANDONED_BASKET):
				path_actions.append(INSPECT_ABANDONED_BASKET)
			path_actions.append_array(PackedStringArray([
				APPROACH_ENEMY,
				APPROACH_MOSS_SHELL,
				APPROACH_STONE_PUPPET,
				BYPASS_ENEMY,
				RETURN_TO_FERRY,
			]))
			return path_actions
		Phase.BATTLE:
			var battle_actions := PackedStringArray([USE_ART])
			if talismans > 0:
				battle_actions.append(USE_TALISMAN)
			battle_actions.append(GUARD)
			if companion_supports > 0:
				battle_actions.append(COMPANION_SUPPORT)
			if spring_lamps > 0:
				battle_actions.append(DEPLOY_SPRING_LAMP)
			battle_actions.append(RETREAT)
			return battle_actions
		Phase.SPRING:
			return PackedStringArray([BREAKTHROUGH])
		_:
			return PackedStringArray([REVIEW_JOURNEY, RETURN_TO_TITLE, REPLAY_CHAPTER])


func choose(action_id: String) -> Dictionary:
	match phase:
		Phase.RIVERBANK:
			return _choose_riverbank(action_id)
		Phase.MOUNTAIN_PATH:
			if action_id == INSPECT_PATH_MARKER:
				return _result(true, ["path_marker_inspected"])
			if action_id == INSPECT_SPRING_SEAM:
				return _record_discovery(DISCOVERY_SPRING_SEAM, "spring_seam_discovered")
			if action_id == INSPECT_ABANDONED_BASKET:
				return _record_discovery(DISCOVERY_ABANDONED_BASKET, "abandoned_basket_discovered")
			var encounter_id := _enemy_for_approach_action(action_id)
			if not encounter_id.is_empty():
				enemy_id = encounter_id
				enemy_hp = EnemyCatalogScript.max_hp(enemy_id)
				round_number = 1
				armor_break_turns = 0
				focus_turns = 0
				phase = Phase.BATTLE
				return _result(true, ["battle_started_%s" % enemy_id])
			if action_id == BYPASS_ENEMY:
				enemy_hp = 0
				phase = Phase.SPRING
				return _result(true, ["enemy_bypassed"])
			if action_id == RETURN_TO_FERRY:
				phase = Phase.RIVERBANK
				return _result(true, ["returned_to_ferry"])
		Phase.BATTLE:
			return _choose_battle(action_id)
		Phase.SPRING:
			if action_id == BREAKTHROUGH:
				gathered_moonleaf = false
				realm = "引息境一层"
				phase = Phase.COMPLETE
				return _result(true, ["breakthrough"])
		Phase.COMPLETE:
			if action_id == REVIEW_JOURNEY:
				return _result(true, ["review"])
			if action_id == RETURN_TO_TITLE:
				return _result(true, ["chapter_closed"])
			if action_id == REPLAY_CHAPTER:
				_reset_chapter()
				return _result(true, ["chapter_replayed"])
	return _result(false, ["invalid_action"])


func snapshot() -> Dictionary:
	return {
		"phase": phase_id(),
		"gathered_moonleaf": gathered_moonleaf,
		"talked_to_companion": talked_to_companion,
		"player_hp": player_hp,
		"enemy_id": enemy_id,
		"enemy_hp": enemy_hp,
		"talismans": talismans,
		"round": round_number,
		"realm": realm,
		"companion_supports": companion_supports,
		"spring_lamps": spring_lamps,
		"lamp_turns": lamp_turns,
		"setbacks": setbacks,
		"briefing_response": briefing_response,
		"moonleaf_method": moonleaf_method,
		"armor_break_turns": armor_break_turns,
		"focus_turns": focus_turns,
		"discoveries": discoveries.duplicate(),
		"ferryman_response": ferryman_response,
	}


func restore(snapshot_data: Dictionary) -> bool:
	var required_keys := [
		"phase",
		"gathered_moonleaf",
		"talked_to_companion",
		"player_hp",
		"enemy_id",
		"enemy_hp",
		"talismans",
		"round",
		"realm",
		"companion_supports",
		"spring_lamps",
		"lamp_turns",
		"setbacks",
		"briefing_response",
		"moonleaf_method",
		"armor_break_turns",
		"focus_turns",
		"discoveries",
		"ferryman_response",
	]
	for key in required_keys:
		if not snapshot_data.has(key):
			return false
	if typeof(snapshot_data["phase"]) != TYPE_STRING:
		return false
	if typeof(snapshot_data["gathered_moonleaf"]) != TYPE_BOOL:
		return false
	if typeof(snapshot_data["talked_to_companion"]) != TYPE_BOOL:
		return false
	if typeof(snapshot_data["realm"]) != TYPE_STRING:
		return false
	if typeof(snapshot_data["briefing_response"]) != TYPE_STRING:
		return false
	if typeof(snapshot_data["moonleaf_method"]) != TYPE_STRING:
		return false
	if not _valid_discoveries(snapshot_data["discoveries"]):
		return false
	if typeof(snapshot_data["ferryman_response"]) != TYPE_STRING:
		return false
	if not EnemyCatalogScript.supports(snapshot_data["enemy_id"]):
		return false
	if not _integer_in_range(snapshot_data["player_hp"], 0, 12):
		return false
	if not _integer_in_range(snapshot_data["enemy_hp"], 0, EnemyCatalogScript.max_hp(snapshot_data["enemy_id"])):
		return false
	if not _integer_in_range(snapshot_data["talismans"], 0, 1):
		return false
	if not _integer_in_range(snapshot_data["round"], 1, 100):
		return false
	if not _integer_in_range(snapshot_data["companion_supports"], 0, 1):
		return false
	if not _integer_in_range(snapshot_data["spring_lamps"], 0, 1):
		return false
	if not _integer_in_range(snapshot_data["lamp_turns"], 0, 2):
		return false
	if not _integer_in_range(snapshot_data["setbacks"], 0, 99):
		return false
	if not _integer_in_range(snapshot_data["armor_break_turns"], 0, 2):
		return false
	if not _integer_in_range(snapshot_data["focus_turns"], 0, 2):
		return false

	var next_phase: Phase
	match snapshot_data["phase"]:
		"riverbank":
			next_phase = Phase.RIVERBANK
		"mountain_path":
			next_phase = Phase.MOUNTAIN_PATH
		"battle":
			next_phase = Phase.BATTLE
		"spring":
			next_phase = Phase.SPRING
		"complete":
			next_phase = Phase.COMPLETE
		_:
			return false

	var next_gathered: bool = snapshot_data["gathered_moonleaf"]
	var next_talked: bool = snapshot_data["talked_to_companion"]
	var next_player_hp := int(snapshot_data["player_hp"])
	var next_enemy_id: String = snapshot_data["enemy_id"]
	var next_enemy_hp := int(snapshot_data["enemy_hp"])
	var next_talismans := int(snapshot_data["talismans"])
	var next_round := int(snapshot_data["round"])
	var next_realm: String = snapshot_data["realm"]
	var next_companion_supports := int(snapshot_data["companion_supports"])
	var next_spring_lamps := int(snapshot_data["spring_lamps"])
	var next_lamp_turns := int(snapshot_data["lamp_turns"])
	var next_setbacks := int(snapshot_data["setbacks"])
	var next_briefing_response: String = snapshot_data["briefing_response"]
	var next_moonleaf_method: String = snapshot_data["moonleaf_method"]
	var next_armor_break_turns := int(snapshot_data["armor_break_turns"])
	var next_focus_turns := int(snapshot_data["focus_turns"])
	var next_discoveries: Array[String] = []
	for discovery_id in snapshot_data["discoveries"]:
		next_discoveries.append(discovery_id)
	var next_ferryman_response: String = snapshot_data["ferryman_response"]
	if not _valid_phase_invariants(
		next_phase,
		next_gathered,
		next_talked,
		next_player_hp,
		next_enemy_id,
		next_enemy_hp,
		next_talismans,
		next_round,
		next_realm,
		next_companion_supports,
		next_spring_lamps,
		next_lamp_turns,
		next_setbacks,
		next_briefing_response,
		next_moonleaf_method,
		next_armor_break_turns,
		next_focus_turns,
		next_discoveries,
		next_ferryman_response
	):
		return false

	phase = next_phase
	gathered_moonleaf = next_gathered
	talked_to_companion = next_talked
	player_hp = next_player_hp
	enemy_id = next_enemy_id
	enemy_hp = next_enemy_hp
	talismans = next_talismans
	round_number = next_round
	realm = next_realm
	companion_supports = next_companion_supports
	spring_lamps = next_spring_lamps
	lamp_turns = next_lamp_turns
	setbacks = next_setbacks
	briefing_response = next_briefing_response
	moonleaf_method = next_moonleaf_method
	armor_break_turns = next_armor_break_turns
	focus_turns = next_focus_turns
	discoveries = next_discoveries
	ferryman_response = next_ferryman_response
	return true


func _choose_riverbank(action_id: String) -> Dictionary:
	if action_id == INSPECT_FERRY_WATERMARK:
		return _record_discovery(DISCOVERY_FERRY_WATERMARK, "ferry_watermark_discovered")
	if action_id == TALK_TO_COMPANION:
		return complete_companion_briefing(RESPONSE_CAREFUL)
	if action_id == TALK_TO_FERRYMAN:
		return complete_ferryman_dialogue(FERRYMAN_REPAIR)
	if action_id in [GATHER_MOONLEAF, GATHER_MOONLEAF_CUTTING]:
		if gathered_moonleaf:
			return _result(false, ["already_gathered"])
		gathered_moonleaf = true
		moonleaf_method = MOONLEAF_CUTTING if action_id == GATHER_MOONLEAF_CUTTING else MOONLEAF_WHOLE_PLANT
		return _result(true, ["gathered_cutting" if moonleaf_method == MOONLEAF_CUTTING else "gathered"])
	if action_id == ENTER_SPRING:
		if not talked_to_companion:
			return _result(false, ["need_briefing"])
		if not gathered_moonleaf:
			return _result(false, ["need_moonleaf"])
		phase = Phase.MOUNTAIN_PATH
		return _result(true, ["path_entered"])
	return _result(false, ["invalid_action"])


func _choose_battle(action_id: String) -> Dictionary:
	var events: Array[String] = []
	var guard_amount := 0
	match action_id:
		USE_ART:
			enemy_hp = max(0, enemy_hp - _resolved_player_damage(action_id))
			events.append("art_hit")
		USE_TALISMAN:
			if talismans <= 0:
				return _result(false, ["no_talisman"])
			talismans -= 1
			enemy_hp = max(0, enemy_hp - _resolved_player_damage(action_id))
			events.append("talisman_hit")
		GUARD:
			guard_amount = 2
			enemy_hp = max(0, enemy_hp - _resolved_player_damage(action_id))
			events.append("guarded")
		COMPANION_SUPPORT:
			if companion_supports <= 0:
				return _result(false, ["no_companion_support"])
			companion_supports -= 1
			player_hp = mini(12, player_hp + 3)
			guard_amount = 2
			focus_turns = 2
			events.append("companion_supported")
		DEPLOY_SPRING_LAMP:
			if spring_lamps <= 0:
				return _result(false, ["no_spring_lamp"])
			spring_lamps -= 1
			lamp_turns = 2
			events.append("spring_lamp_deployed")
		RETREAT:
			setbacks += 1
			phase = Phase.MOUNTAIN_PATH
			player_hp = mini(12, player_hp + 3)
			enemy_hp = EnemyCatalogScript.max_hp(enemy_id)
			round_number = 1
			companion_supports = 1
			spring_lamps = 1
			lamp_turns = 0
			armor_break_turns = 0
			focus_turns = 0
			return _result(true, ["retreated"])
		_:
			return _result(false, ["invalid_action"])
	if action_id in [USE_ART, USE_TALISMAN, GUARD] and EnemyCatalogScript.exposes_weakness(enemy_id, action_id):
		armor_break_turns = 2
		events.append("weakness_exposed")

	if enemy_hp <= 0:
		if not EnemyCatalogScript.is_boss(enemy_id):
			_start_boss_encounter()
			events.append("regular_enemy_won")
			events.append("boss_arrived")
		else:
			phase = Phase.SPRING
			armor_break_turns = 0
			focus_turns = 0
			events.append("battle_won")
		return _result(true, events)
	if lamp_turns > 0:
		guard_amount += 1
		lamp_turns -= 1
		events.append("spring_lamp_absorbed")

	var intent := current_enemy_intent()
	var damage: int = maxi(0, int(intent.get("damage", 0)) - guard_amount)
	player_hp = maxi(0, player_hp - damage)
	events.append("enemy_glanced" if guard_amount > 0 else "enemy_hit")
	if player_hp <= 0:
		setbacks += 1
		phase = Phase.RIVERBANK
		player_hp = 8
		enemy_hp = EnemyCatalogScript.max_hp(enemy_id)
		round_number = 1
		companion_supports = 1
		spring_lamps = 1
		lamp_turns = 0
		armor_break_turns = 0
		focus_turns = 0
		events.append("companion_rescue")
		return _result(true, events)
	round_number += 1
	return _result(true, events)


func _result(ok: bool, events: Array[String]) -> Dictionary:
	return {"ok": ok, "events": events, "snapshot": snapshot()}


func _record_discovery(discovery_id: String, event_id: String) -> Dictionary:
	if discoveries.has(discovery_id):
		return _result(false, ["already_discovered"])
	discoveries.append(discovery_id)
	return _result(true, [event_id])


func complete_companion_briefing(response_id: String) -> Dictionary:
	if phase != Phase.RIVERBANK or talked_to_companion:
		return _result(false, ["already_briefed"])
	if not BRIEFING_RESPONSES.has(response_id):
		return _result(false, ["invalid_briefing_response"])
	talked_to_companion = true
	briefing_response = response_id
	return _result(true, ["companion_briefing", "briefing_%s" % response_id])


func complete_epilogue(response_id: String) -> Dictionary:
	if phase != Phase.COMPLETE:
		return _result(false, ["epilogue_unavailable"])
	if response_id not in EPILOGUE_RESPONSES:
		return _result(false, ["invalid_epilogue_response"])
	var event_id := "epilogue_recorded" if response_id == EPILOGUE_RECORD else "epilogue_returned"
	return _result(true, [event_id])


func complete_ferryman_dialogue(response_id: String) -> Dictionary:
	if phase != Phase.RIVERBANK or ferryman_response != FERRYMAN_UNANSWERED:
		return _result(false, ["ferryman_already_answered"])
	if response_id not in [FERRYMAN_REPAIR, FERRYMAN_RECORD]:
		return _result(false, ["invalid_ferryman_response"])
	ferryman_response = response_id
	return _result(true, ["ferryman_%s" % response_id])


func current_enemy_profile() -> Dictionary:
	return EnemyCatalogScript.profile(enemy_id)


func current_enemy_intent() -> Dictionary:
	return EnemyCatalogScript.intent(enemy_id, round_number)


func _resolved_player_damage(action_id: String) -> int:
	var damage := EnemyCatalogScript.player_damage(enemy_id, action_id)
	if action_id in [USE_ART, USE_TALISMAN]:
		if armor_break_turns > 0:
			damage += 1
			armor_break_turns -= 1
		if focus_turns > 0:
			damage += 1
			focus_turns -= 1
	return damage


func _start_boss_encounter() -> void:
	enemy_id = EnemyCatalogScript.ROCK_ARMOR_WARDEN
	enemy_hp = EnemyCatalogScript.max_hp(enemy_id)
	player_hp = 12
	round_number = 1
	companion_supports = 1
	spring_lamps = 1
	lamp_turns = 0
	armor_break_turns = 0
	focus_turns = 0


func _reset_chapter() -> void:
	phase = Phase.RIVERBANK
	gathered_moonleaf = false
	talked_to_companion = false
	player_hp = 12
	enemy_id = EnemyCatalogScript.DEFAULT_ENEMY_ID
	enemy_hp = EnemyCatalogScript.max_hp(enemy_id)
	talismans = 1
	round_number = 1
	realm = "凡身"
	companion_supports = 1
	spring_lamps = 1
	lamp_turns = 0
	setbacks = 0
	briefing_response = RESPONSE_UNANSWERED
	moonleaf_method = MOONLEAF_UNSELECTED
	armor_break_turns = 0
	focus_turns = 0
	discoveries.clear()
	ferryman_response = FERRYMAN_UNANSWERED


func _integer_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var numeric := float(value)
	return is_finite(numeric) and numeric == floorf(numeric) and numeric >= minimum and numeric <= maximum


func _valid_phase_invariants(
	next_phase: Phase,
	next_gathered: bool,
	next_talked: bool,
	next_player_hp: int,
	next_enemy_id: String,
	next_enemy_hp: int,
	next_talismans: int,
	next_round: int,
	next_realm: String,
	next_companion_supports: int,
	next_spring_lamps: int,
	next_lamp_turns: int,
	next_setbacks: int,
	next_briefing_response: String,
	next_moonleaf_method: String,
	next_armor_break_turns: int,
	next_focus_turns: int,
	next_discoveries: Array[String],
	next_ferryman_response: String
) -> bool:
	if next_ferryman_response not in FERRYMAN_RESPONSES:
		return false
	if not _valid_discoveries(next_discoveries):
		return false
	if (
		(next_discoveries.has(DISCOVERY_SPRING_SEAM) or next_discoveries.has(DISCOVERY_ABANDONED_BASKET))
		and (not next_talked or next_moonleaf_method == MOONLEAF_UNSELECTED)
	):
		return false
	if next_briefing_response not in [RESPONSE_UNANSWERED, RESPONSE_CAREFUL, RESPONSE_TRUSTING]:
		return false
	if next_talked != (next_briefing_response != RESPONSE_UNANSWERED):
		return false
	if next_moonleaf_method not in MOONLEAF_METHODS:
		return false
	if next_phase == Phase.COMPLETE:
		if next_moonleaf_method == MOONLEAF_UNSELECTED:
			return false
	elif next_gathered != (next_moonleaf_method != MOONLEAF_UNSELECTED):
		return false
	var next_enemy_max := EnemyCatalogScript.max_hp(next_enemy_id)
	if next_phase == Phase.RIVERBANK:
		return next_realm == "凡身" and next_player_hp > 0 and next_enemy_hp == next_enemy_max and next_round == 1 and next_companion_supports == 1 and next_spring_lamps == 1 and next_lamp_turns == 0 and next_armor_break_turns == 0 and next_focus_turns == 0
	if next_phase == Phase.MOUNTAIN_PATH:
		return next_realm == "凡身" and next_gathered and next_talked and next_player_hp > 0 and next_enemy_hp == next_enemy_max and next_round == 1 and next_lamp_turns == 0 and next_armor_break_turns == 0 and next_focus_turns == 0
	if next_phase == Phase.BATTLE:
		return next_realm == "凡身" and next_gathered and next_talked and next_enemy_hp > 0 and (next_lamp_turns == 0 or next_spring_lamps == 0)
	if next_phase == Phase.SPRING:
		return next_realm == "凡身" and next_gathered and next_talked and next_enemy_hp == 0 and next_armor_break_turns == 0 and next_focus_turns == 0
	return next_realm == "引息境一层" and not next_gathered and next_enemy_hp == 0 and next_setbacks >= 0 and next_armor_break_turns == 0 and next_focus_turns == 0


func _valid_discoveries(candidate: Variant) -> bool:
	if typeof(candidate) != TYPE_ARRAY:
		return false
	var seen: Array[String] = []
	for discovery_id in candidate:
		if typeof(discovery_id) != TYPE_STRING or discovery_id not in DISCOVERY_IDS or seen.has(discovery_id):
			return false
		seen.append(discovery_id)
	return true


func _enemy_for_approach_action(action_id: String) -> String:
	match action_id:
		APPROACH_ENEMY:
			return EnemyCatalogScript.ROCK_ARMOR_YOUNG
		APPROACH_MOSS_SHELL:
			return EnemyCatalogScript.SPRING_MOSS_SHELL
		APPROACH_STONE_PUPPET:
			return EnemyCatalogScript.UNBALANCED_STONE_PUPPET
	return ""
