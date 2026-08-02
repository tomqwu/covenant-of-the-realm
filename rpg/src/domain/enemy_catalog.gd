extends RefCounted
class_name EnemyCatalog

const ROCK_ARMOR_YOUNG := "rock_armor_young"
const SPRING_MOSS_SHELL := "spring_moss_shell"
const UNBALANCED_STONE_PUPPET := "unbalanced_stone_puppet"
const DEFAULT_ENEMY_ID := ROCK_ARMOR_YOUNG
const ENEMY_IDS := [ROCK_ARMOR_YOUNG, SPRING_MOSS_SHELL, UNBALANCED_STONE_PUPPET]

const PROFILES := {
	ROCK_ARMOR_YOUNG: {
		"name": "岩甲兽幼体",
		"max_hp": 12,
		"weak_action": "use_talisman",
		"weak_bonus": 1,
		"weakness": "镇岩符压住甲缝",
		"description": "幼兽的岩甲尚未闭合，却会用肩背连续撞击。",
		"intents": [
			{"name": "试探冲撞", "damage": 3},
			{"name": "裂石冲撞", "damage": 4},
		],
	},
	SPRING_MOSS_SHELL: {
		"name": "泉苔寄壳",
		"max_hp": 8,
		"weak_action": "use_art",
		"weak_bonus": 1,
		"weakness": "引气术吹散湿苔",
		"description": "泉苔借空壳移动，吸水时迟缓，喷出孢雾时危险。",
		"intents": [
			{"name": "吸潮蓄壳", "damage": 2},
			{"name": "喷苔孢雾", "damage": 3},
		],
	},
	UNBALANCED_STONE_PUPPET: {
		"name": "失衡石傀",
		"max_hp": 10,
		"weak_action": "guard",
		"weak_bonus": 2,
		"weakness": "守势借力令它倾倒",
		"description": "废弃石傀的重心已经偏斜，摆锤越重，回正越慢。",
		"intents": [
			{"name": "失衡摆锤", "damage": 4},
			{"name": "踏地回正", "damage": 2},
		],
	},
}


static func supports(enemy_id: Variant) -> bool:
	return typeof(enemy_id) == TYPE_STRING and PROFILES.has(enemy_id)


static func profile(enemy_id: String) -> Dictionary:
	return PROFILES.get(enemy_id, {}).duplicate(true)


static func max_hp(enemy_id: String) -> int:
	return int(PROFILES.get(enemy_id, {}).get("max_hp", 0))


static func intent(enemy_id: String, round_number: int) -> Dictionary:
	var enemy_profile: Dictionary = PROFILES.get(enemy_id, {})
	var intents: Array = enemy_profile.get("intents", [])
	if intents.is_empty() or round_number <= 0:
		return {}
	return intents[(round_number - 1) % intents.size()].duplicate(true)


static func player_damage(enemy_id: String, action_id: String) -> int:
	var base_damage: int = {"use_art": 3, "use_talisman": 5, "guard": 0}.get(action_id, 0)
	var enemy_profile: Dictionary = PROFILES.get(enemy_id, {})
	if action_id == enemy_profile.get("weak_action"):
		base_damage += int(enemy_profile.get("weak_bonus", 0))
	return base_damage


static func exposes_weakness(enemy_id: String, action_id: String) -> bool:
	return action_id == PROFILES.get(enemy_id, {}).get("weak_action", "")
