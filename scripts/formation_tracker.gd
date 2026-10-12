extends RefCounted
class_name FormationTracker

var groups: Dictionary = {}

func register(id: int, members: int, supply: bool = false) -> void:
	groups[id] = {"remaining": members, "members": members, "supply": supply, "escaped": false, "rewarded": false, "resolved_ids": {}}

func resolve(id: int, enemy_id: int, killed: bool) -> Dictionary:
	if not groups.has(id): return {}
	var group: Dictionary = groups[id]
	if group.resolved_ids.has(enemy_id): return {}
	group.resolved_ids[enemy_id] = true
	group.remaining -= 1
	if not killed: group.escaped = true
	if group.remaining == 0 and not group.escaped and not group.rewarded:
		group.rewarded = true
		return {"bonus": 25 * group.members, "supply": group.supply}
	return {}

func clear() -> void:
	groups.clear()
