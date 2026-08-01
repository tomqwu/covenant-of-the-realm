extends RefCounted
class_name JourneyState

enum Phase { RIVERBANK, BATTLE, SPRING, COMPLETE }

const GATHER_MOONLEAF := "gather_moonleaf"
const ENTER_SPRING := "enter_spring"
const USE_ART := "use_art"
const USE_TALISMAN := "use_talisman"
const GUARD := "guard"
const BREAKTHROUGH := "breakthrough"
const REVIEW_JOURNEY := "review_journey"

var phase := Phase.RIVERBANK
var gathered_moonleaf := false
var player_hp := 12
var enemy_hp := 9
var talismans := 1
var round_number := 1
var realm := "凡身"


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
			var actions := PackedStringArray([ENTER_SPRING])
			if not gathered_moonleaf:
				actions.insert(0, GATHER_MOONLEAF)
			return actions
		Phase.BATTLE:
			return PackedStringArray([USE_ART, USE_TALISMAN, GUARD])
		Phase.SPRING:
			return PackedStringArray([BREAKTHROUGH])
		_:
			return PackedStringArray([REVIEW_JOURNEY])


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
	return _result(false, ["invalid_action"])


func snapshot() -> Dictionary:
	return {
		"phase": phase_id(),
		"gathered_moonleaf": gathered_moonleaf,
		"player_hp": player_hp,
		"enemy_hp": enemy_hp,
		"talismans": talismans,
		"round": round_number,
		"realm": realm,
	}


func _choose_riverbank(action_id: String) -> Dictionary:
	if action_id == GATHER_MOONLEAF:
		if gathered_moonleaf:
			return _result(false, ["already_gathered"])
		gathered_moonleaf = true
		return _result(true, ["gathered"])
	if action_id == ENTER_SPRING:
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
		_:
			return _result(false, ["invalid_action"])

	if enemy_hp <= 0:
		phase = Phase.SPRING
		events.append("battle_won")
		return _result(true, events)

	var damage: int = maxi(0, 3 - guard_amount)
	player_hp = maxi(0, player_hp - damage)
	events.append("enemy_glanced" if guard_amount > 0 else "enemy_hit")
	round_number += 1
	return _result(true, events)


func _result(ok: bool, events: Array[String]) -> Dictionary:
	return {"ok": ok, "events": events, "snapshot": snapshot()}
