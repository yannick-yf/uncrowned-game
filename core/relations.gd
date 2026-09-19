class_name Relations
extends RefCounted

## Who stands in what relation to whom.
##
## §9's second context source, and the thing that lets an NPC be told about their
## neighbours without any of it being written into their dialogue. Ids only, no
## words — so unlike every other content file this one needs no translation.
##
## Directed on purpose. "Nessa is Cadan's daughter" and "Cadan employs Nessa" are
## one fact and two different sentences, and which one you put in front of a reader
## changes what they write.

const PATH: String = "res://content/relations.json"

var _out: Dictionary = {}

static var _shared: Relations = null


static func shared() -> Relations:
	if _shared == null:
		_shared = load_from(PATH)
	return _shared


static func load_from(path: String) -> Relations:
	var web := Relations.new()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return web
	for entry: Variant in ((parsed as Dictionary).get("edges", []) as Array):
		var edge: Dictionary = entry as Dictionary
		var from: StringName = StringName(edge.get("from", ""))
		if not web._out.has(from):
			web._out[from] = []
		(web._out[from] as Array).append({
			"to": StringName(edge.get("to", "")),
			"kind": StringName(edge.get("kind", "")),
		})
	return web


## Everybody this person stands in a named relation to.
func of(who: StringName) -> Array:
	return (_out.get(who, []) as Array).duplicate()


## One and two hops out, in a stable order. Two hops is where the interesting
## things are — Sena works for Harry, who buys scrap from Wren — and three is
## where it stops being about this person.
func near(who: StringName, hops: int = 2) -> Array:
	var seen: Dictionary = {who: true}
	var out: Array = []
	var frontier: Array[StringName] = [who]
	for hop: int in maxi(hops, 1):
		var next: Array[StringName] = []
		for person: StringName in frontier:
			for edge: Dictionary in of(person):
				var to: StringName = edge["to"] as StringName
				out.append({"from": person, "to": to, "kind": edge["kind"], "hops": hop + 1})
				if not seen.has(to):
					seen[to] = true
					next.append(to)
		frontier = next
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["hops"]) != int(b["hops"]):
			return int(a["hops"]) < int(b["hops"])
		return "%s%s" % [a["from"], a["to"]] < "%s%s" % [b["from"], b["to"]])
	return out


func everybody() -> Array[StringName]:
	var out: Array[StringName] = []
	for who: StringName in _out.keys():
		out.append(who)
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out
