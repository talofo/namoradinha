class_name ContentFactory
extends Node

# Configuration
var _content_paths: Dictionary = {
	"obstacles": {
		"Rock": "res://obstacles/RockObstacle.tscn"
	},
	"boosts": {
		# Example: "SpeedPad": "res://boosts/SpeedPad.tscn"
	},
	"collectibles": {
		# Example: "Coin": "res://collectibles/Coin.tscn"
	}
}

# Debug mode
var debug_enabled: bool = true

# Create a content instance based on category and type
func create_content(content_category: String, content_type: String, distance: float, height: float, width_offset: float, chunk_parent: Node = null) -> Node:
	# Normalize category to lowercase for case-insensitive matching
	var category = content_category.to_lower()
	
	# Find the appropriate scene path
	var scene_path = _get_scene_path(category, content_type)
	if scene_path.is_empty():
		if debug_enabled:
			push_warning("ContentFactory: No scene path found for %s/%s" % [category, content_type])
		return null
	
	# Load the scene
	var content_scene = _load_scene(scene_path)
	if not content_scene:
		return null
	
	# Instantiate the content
	var content_instance = content_scene.instantiate()
	
	# Set position based on node type using distance, height, and width_offset
	_set_instance_position(content_instance, distance, height, width_offset, chunk_parent)
	
	# Add to parent if provided
	if chunk_parent and chunk_parent.is_inside_tree():
		print("ContentFactory: Adding %s/%s to parent %s" % [category, content_type, chunk_parent.name])
		chunk_parent.add_child(content_instance)
		
		# Force process to ensure the node is properly added
		content_instance.set_process(true)
		content_instance.set_physics_process(true)
		
		# Verify the content was added to the scene tree
		print("ContentFactory: Content added to parent, is in scene tree: %s" % str(content_instance.is_inside_tree()))
	else:
		# If no parent is provided or parent is not in tree, use GameSignalBus
		print("ContentFactory: No valid parent for %s/%s, using GameSignalBus" % [category, content_type])
		
		# Get the GameSignalBus singleton
		var game_signal_bus = Engine.get_singleton("GameSignalBus")
		if game_signal_bus:
			if game_signal_bus.has_method("add_content_to_scene"):
				var success = game_signal_bus.add_content_to_scene(content_instance)
				print("ContentFactory: Added via GameSignalBus: %s" % str(success))
			else:
				push_error("ContentFactory: GameSignalBus doesn't have add_content_to_scene method")
				# Fallback: add directly to the scene root
				get_tree().root.add_child(content_instance)
				print("ContentFactory: Fallback - Added directly to scene root")
		else:
			push_error("ContentFactory: GameSignalBus singleton not available")
			# Fallback: add directly to the scene root
			get_tree().root.add_child(content_instance)
			print("ContentFactory: Fallback - Added directly to scene root")
	
	if debug_enabled:
		print("ContentFactory: Created %s/%s at position (%s, %s)" % [category, content_type, str(distance), str(height)])
		print("ContentFactory: DEBUG - Content is in scene tree: %s" % str(content_instance.is_inside_tree()))
		
		# Fix for incompatible ternary warning - use explicit variable assignment
		var parent_name = "none"
		if content_instance.get_parent():
			parent_name = content_instance.get_parent().name
		print("ContentFactory: DEBUG - Content parent: %s" % parent_name)
		
		# Fix for incompatible ternary warning - use explicit variable assignment
		var z_index_str = "N/A"
		if content_instance is Node2D:
			z_index_str = str(content_instance.z_index)
		print("ContentFactory: DEBUG - Content z-index: %s" % z_index_str)
	
	return content_instance

# Get the scene path for a content type
func _get_scene_path(category: String, content_type: String) -> String:
	# Check if category exists in the paths dictionary
	if not _content_paths.has(category):
		if debug_enabled:
			push_warning("ContentFactory: Unknown category '%s'" % category)
		return ""
	
	# Check if content type exists in the category
	if not _content_paths[category].has(content_type):
		# Instead of just warning, register a placeholder for this content type
		if category == "boosts" and content_type == "SpeedPad":
			# Create a placeholder entry for SpeedPad
			register_content_type(category, content_type, "res://obstacles/RockObstacle.tscn")
			if debug_enabled:
				print("ContentFactory: Created placeholder for %s/%s" % [category, content_type])
		elif category == "collectibles" and content_type == "Coin":
			# Create a placeholder entry for Coin
			register_content_type(category, content_type, "res://obstacles/RockObstacle.tscn")
			if debug_enabled:
				print("ContentFactory: Created placeholder for %s/%s" % [category, content_type])
		else:
			if debug_enabled:
				push_warning("ContentFactory: Unknown content type '%s' in category '%s'" % [content_type, category])
			return ""
	
	var scene_path = _content_paths[category][content_type]
	if debug_enabled:
		print("DEBUG: Scene path for %s/%s: %s" % [category, content_type, scene_path])
	
	return scene_path

# Load a scene from path
func _load_scene(scene_path: String) -> PackedScene:
	if not ResourceLoader.exists(scene_path):
		push_error("ContentFactory: Scene not found at path: %s" % scene_path)
		return null
	
	var scene = load(scene_path)
	if not scene is PackedScene:
		push_error("ContentFactory: Resource at path is not a PackedScene: %s" % scene_path)
		return null
	
	if debug_enabled:
		print("DEBUG: Scene loaded successfully: %s" % scene_path)
	
	return scene

# Set the position of an instance based on its type
func _set_instance_position(instance: Node, distance: float, _height: float, width_offset: float, _chunk_parent: Node) -> void:
	if instance is Node2D:
		# In a 2D game, we need to map the 3D-like coordinates to 2D space
		# width_offset is the x position (left/right)
		# distance should be used for sorting/depth, not vertical position
		# height is the z position (up/down) - typically 0 for ground objects
		
		var position_2d
		
		# Special case for obstacles (like rocks) - always place at ground level (y=0)
		if instance is RockObstacle or (instance.get_groups().has("obstacles")):
			# For obstacles, use width_offset for X and always set Y to 0
			position_2d = Vector2(width_offset, 0)
			
			# Use distance for z-index to handle depth sorting
			# Higher distance = further away = lower z-index
			instance.z_index = 1000 - int(distance / 10)
		else:
			# For other objects, use the original positioning
			position_2d = Vector2(width_offset, distance)
			
			# Set a high z-index to ensure visibility
			instance.z_index = 50
		
		# Set the position directly
		instance.position = position_2d
		
		if debug_enabled:
			print("DEBUG: Set position of %s to (%s, %s)" % [instance.name, str(position_2d.x), str(position_2d.y)])
	else:
		push_warning("ContentFactory: Instantiated content '%s' is not Node2D. Cannot set 2D position reliably." % instance.name)

# Register a new content type
func register_content_type(category: String, content_type: String, scene_path: String) -> void:
	# Normalize category to lowercase
	category = category.to_lower()
	
	# Create category if it doesn't exist
	if not _content_paths.has(category):
		_content_paths[category] = {}
	
	# Register the content type
	_content_paths[category][content_type] = scene_path
	
	if debug_enabled:
		print("ContentFactory: Registered %s/%s at path %s" % [category, content_type, scene_path])

# Set debug mode
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
