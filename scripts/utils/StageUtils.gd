class_name StageUtils

static func get_stage_number_from_parent(node: Node) -> int:
	var current = node.get_parent()
	while current:
		var prefix := "Stage"
		if current.name.begins_with(prefix):
			var number_text = current.name.substr(prefix.length(), current.name.length())
			if number_text.is_valid_int():
				return int(number_text)
		current = current.get_parent()

	push_error("Could not determine stage number from parent nodes.")
	return -1
