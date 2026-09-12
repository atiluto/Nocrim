extends RefCounted
## Presentation and walkable routes for the opening region. Campaign IDs stay stable.
const DATA_PATH = "res://data/chapter_01_map.json"
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))

func neighbors(id: String) -> Array:
	var result: Array = []
	for edge in data.edges:
		if edge[0] == id: result.append(edge[1])
		elif edge[1] == id: result.append(edge[0])
	return result

func accessible(id: String, owned: Array) -> bool:
	if not data.nodes.has(id): return false
	var node: Dictionary = data.nodes[id]
	if node.kind == "exit": return false
	if node.kind == "mountain": return id in owned
	for guard in node.guards:
		if guard in owned: return true
	return false

func path_to(start: String, target: String, owned: Array) -> Array:
	if not accessible(target, owned): return []
	if start == target: return [start]
	var queue: Array = [start]
	var previous: Dictionary = {}
	previous[start] = ""
	while not queue.is_empty():
		var here: String = queue.pop_front()
		for next in neighbors(here):
			if previous.has(next) or not accessible(next, owned): continue
			previous[next] = here
			if next == target:
				var route: Array = [target]
				var cursor: String = target
				while cursor != start:
					cursor = previous[cursor]; route.push_front(cursor)
				return route
			queue.append(next)
	return []

func attack_targets(id: String, frontier: Array) -> Array:
	var result: Array = []
	if id in frontier: result.append(id)
	for target in data.nodes.get(id, {}).get("approaches", []):
		if target in frontier and target not in result: result.append(target)
	return result
