extends RefCounted
class_name JourneyState

enum Phase { RIVERBANK, BATTLE, SPRING, COMPLETE }

const GATHER_MOONLEAF := "gather_moonleaf"
const ENTER_SPRING := "enter_spring"
const TALK_TO_COMPANION := "talk_to_companion"
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

var phase := Phase.RIVERBANK
var gathered_moonleaf := false
var talked_to_companion := false
var player_hp := 12
var enemy_hp := 9
var talismans := 1
var round_number := 1
var realm := "凡身"
var companion_supports := 1
var spring_lamps := 1
var lamp_turns := 0
var setbacks := 0


func phase_id() -> String:
	match phase:
		Phase.RIVERBANK:
			return "riverbank"
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
			if not talked_to_companion:
				actions.append(TALK_TO_COMPANION)
			if not gathered_moonleaf:
				actions.append(GATHER_MOONLEAF)
			actions.append(ENTER_SPRING)
			return actions
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
		"enemy_hp": enemy_hp,
		"talismans": talismans,
		"round": round_number,
		"realm": realm,
		"companion_supports": companion_supports,
		"spring_lamps": spring_lamps,
		"lamp_turns": lamp_turns,
		"setbacks": setbacks,
	}


func restore(snapshot_data: Dictionary) -> bool:
	var required_keys := [
		"phase",
		"gathered_moonleaf",
		"talked_to_companion",
		"player_hp",
		"enemy_hp",
		"talismans",
		"round",
		"realm",
		"companion_supports",
		"spring_lamps",
		"lamp_turns",
		"setbacks",
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
	if not _integer_in_range(snapshot_data["player_hp"], 0, 12):
		return false
	if not _integer_in_range(snapshot_data["enemy_hp"], 0, 9):
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

	var next_phase: Phase
	match snapshot_data["phase"]:
		"riverbank":
			next_phase = Phase.RIVERBANK
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
	var next_enemy_hp := int(snapshot_data["enemy_hp"])
	var next_talismans := int(snapshot_data["talismans"])
	var next_round := int(snapshot_data["round"])
	var next_realm: String = snapshot_data["realm"]
	var next_companion_supports := int(snapshot_data["companion_supports"])
	var next_spring_lamps := int(snapshot_data["spring_lamps"])
	var next_lamp_turns := int(snapshot_data["lamp_turns"])
	var next_setbacks := int(snapshot_data["setbacks"])
	if not _valid_phase_invariants(
		next_phase,
		next_gathered,
		next_talked,
		next_player_hp,
		next_enemy_hp,
		next_talismans,
		next_round,
		next_realm,
		next_companion_supports,
		next_spring_lamps,
		next_lamp_turns,
		next_setbacks
	):
		return false

	phase = next_phase
	gathered_moonleaf = next_gathered
	talked_to_companion = next_talked
	player_hp = next_player_hp
	enemy_hp = next_enemy_hp
	talismans = next_talismans
	round_number = next_round
	realm = next_realm
	companion_supports = next_companion_supports
	spring_lamps = next_spring_lamps
	lamp_turns = next_lamp_turns
	setbacks = next_setbacks
	return true


func _choose_riverbank(action_id: String) -> Dictionary:
	if action_id == TALK_TO_COMPANION:
		if talked_to_companion:
			return _result(false, ["already_briefed"])
		talked_to_companion = true
		return _result(true, ["companion_briefing"])
	if action_id == GATHER_MOONLEAF:
		if gathered_moonleaf:
			return _result(false, ["already_gathered"])
		gathered_moonleaf = true
		return _result(true, ["gathered"])
	if action_id == ENTER_SPRING:
		if not talked_to_companion:
			return _result(false, ["need_briefing"])
		if not gathered_moonleaf:
			return _result(false, ["need_moonleaf"])
		phase = Phase.BATTLE
		return _result(true, ["battle_started"])
	return _result(false, ["invalid_action"])


func _choose_battle(action_id: String) -> Dictionary:
	var events: Array[String] = []
	var guard_amount := 0
	match action_id:
		USE_ART:
			enemy_hp = max(0, enemy_hp - 3)
			events.append("art_hit")
		USE_TALISMAN:
			if talismans <= 0:
				return _result(false, ["no_talisman"])
			talismans -= 1
			enemy_hp = max(0, enemy_hp - 5)
			events.append("talisman_hit")
		GUARD:
			guard_amount = 2
			events.append("guarded")
		COMPANION_SUPPORT:
			if companion_supports <= 0:
				return _result(false, ["no_companion_support"])
			companion_supports -= 1
			player_hp = mini(12, player_hp + 3)
			guard_amount = 2
			events.append("companion_supported")
		DEPLOY_SPRING_LAMP:
			if spring_lamps <= 0:
				return _result(false, ["no_spring_lamp"])
			spring_lamps -= 1
			lamp_turns = 2
			events.append("spring_lamp_deployed")
		RETREAT:
			setbacks += 1
			phase = Phase.RIVERBANK
			player_hp = mini(12, player_hp + 3)
			enemy_hp = 9
			round_number = 1
			companion_supports = 1
			spring_lamps = 1
			lamp_turns = 0
			return _result(true, ["retreated"])
		_:
			return _result(false, ["invalid_action"])

	if enemy_hp <= 0:
		phase = Phase.SPRING
		events.append("battle_won")
		return _result(true, events)
	if lamp_turns > 0:
		guard_amount += 1
		lamp_turns -= 1
		events.append("spring_lamp_absorbed")

	var damage: int = maxi(0, 3 - guard_amount)
	player_hp = maxi(0, player_hp - damage)
	events.append("enemy_glanced" if guard_amount > 0 else "enemy_hit")
	if player_hp <= 0:
		setbacks += 1
		phase = Phase.RIVERBANK
		player_hp = 8
		enemy_hp = 9
		round_number = 1
		companion_supports = 1
		spring_lamps = 1
		lamp_turns = 0
		events.append("companion_rescue")
		return _result(true, events)
	round_number += 1
	return _result(true, events)


func _result(ok: bool, events: Array[String]) -> Dictionary:
	return {"ok": ok, "events": events, "snapshot": snapshot()}


func _reset_chapter() -> void:
	phase = Phase.RIVERBANK
	gathered_moonleaf = false
	talked_to_companion = false
	player_hp = 12
	enemy_hp = 9
	talismans = 1
	round_number = 1
	realm = "凡身"
	companion_supports = 1
	spring_lamps = 1
	lamp_turns = 0
	setbacks = 0


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
	next_enemy_hp: int,
	next_talismans: int,
	next_round: int,
	next_realm: String,
	next_companion_supports: int,
	next_spring_lamps: int,
	next_lamp_turns: int,
	next_setbacks: int
) -> bool:
	if next_phase == Phase.RIVERBANK:
		return next_realm == "凡身" and next_player_hp > 0 and next_enemy_hp == 9 and next_round == 1 and next_companion_supports == 1 and next_spring_lamps == 1 and next_lamp_turns == 0
	if next_phase == Phase.BATTLE:
		return next_realm == "凡身" and next_gathered and next_talked and next_enemy_hp > 0 and (next_lamp_turns == 0 or next_spring_lamps == 0)
	if next_phase == Phase.SPRING:
		return next_realm == "凡身" and next_gathered and next_talked and next_enemy_hp == 0
	return next_realm == "引息境一层" and not next_gathered and next_enemy_hp == 0 and next_setbacks >= 0
