extends Node

# This script disables all debug rock creation scripts
# to prevent them from adding extra rocks to the scene

func _ready():
	print("DisableDebugRocks: Disabling debug rock creation scripts")
	
	# List of debug scenes that create rocks
	var debug_scenes = [
		"res://scenes/debug/VisibleRocksTest.tscn",
		"res://scenes/debug/RockObstacleTest.tscn",
		"res://scenes/debug/FixRocksNotAppearing.tscn"
	]
	
	# Check if any of these scenes are loaded
	for scene_path in debug_scenes:
		_disable_scene(scene_path)
	
	# Also check for any instances of the debug scripts
	_disable_script_instances()
	
	print("DisableDebugRocks: All debug rock creation scripts disabled")

# Disable a scene by finding and removing any instances of it
func _disable_scene(scene_path: String) -> void:
	# Check if the scene exists
	if not ResourceLoader.exists(scene_path):
		print("DisableDebugRocks: Scene not found: %s" % scene_path)
		return
	
	# Get the scene filename without extension
	var scene_name = scene_path.get_file().get_basename()
	print("DisableDebugRocks: Looking for instances of %s" % scene_name)
	
	# Find all nodes with this name
	var nodes = get_tree().get_nodes_in_group(scene_name)
	if nodes.is_empty():
		# Try finding by class name
		for node in get_tree().get_nodes_in_group(""):
			if node.name == scene_name:
				nodes.append(node)
	
	# Remove any found nodes
	for node in nodes:
		print("DisableDebugRocks: Removing instance of %s" % scene_name)
		node.queue_free()

# Disable any instances of the debug scripts
func _disable_script_instances() -> void:
	# List of debug scripts that create rocks
	var debug_scripts = [
		"VisibleRocksTest",
		"RockObstacleTest",
		"FixRocksNotAppearing",
		"GlobalRockDebugOverlay"
	]
	
	# Find all nodes in the scene tree
	var root = get_tree().root
	_find_and_disable_scripts(root, debug_scripts)

# Recursively find and disable script instances
func _find_and_disable_scripts(node: Node, script_names: Array) -> void:
	# Check if this node has a script
	if node.get_script():
		var script_name = node.get_script().resource_path.get_file().get_basename()
		
		# Check if it's one of the debug scripts
		if script_names.has(script_name):
			print("DisableDebugRocks: Disabling script %s on node %s" % [script_name, node.name])
			node.set_script(null)  # Remove the script
	
	# Check all children
	for child in node.get_children():
		_find_and_disable_scripts(child, script_names)
