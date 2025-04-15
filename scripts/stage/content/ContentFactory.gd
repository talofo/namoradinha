class_name ContentFactory
extends Node

# Configuration
var _content_paths: Dictionary = {
	"obstacle": {
		"Rock": "res://obstacles/RockObstacle.tscn"
	},
	"boost": {
		# Example: "SpeedPad": "res://boosts/SpeedPad.tscn"
	},
	"collectible": {
		# Example: "Coin": "res://collectibles/Coin.tscn"
	}
}

# Debug mode
var debug_enabled: bool = false

# Create a content instance based on category and type
func create_content(content_category: String, content_type: String, position: Vector3, chunk_parent: Node = null) -> Node:
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
	
	# Set position based on node type
	_set_instance_position(content_instance, position, chunk_parent)
	
	# Add to parent if provided
	if chunk_parent and chunk_parent.is_inside_tree():
		chunk_parent.add_child(content_instance)
	
	if debug_enabled:
		print("ContentFactory: Created %s/%s at position %s" % [category, content_type, str(position)])
	
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
		if debug_enabled:
			push_warning("ContentFactory: Unknown content type '%s' in category '%s'" % [content_type, category])
		return ""
	
	return _content_paths[category][content_type]

# Load a scene from path
func _load_scene(scene_path: String) -> PackedScene:
	if not ResourceLoader.exists(scene_path):
		push_error("ContentFactory: Scene not found at path: %s" % scene_path)
		return null
	
	var scene = load(scene_path)
	if not scene is PackedScene:
		push_error("ContentFactory: Resource at path is not a PackedScene: %s" % scene_path)
		return null
	
	return scene

# Set the position of an instance based on its type
func _set_instance_position(instance: Node, position: Vector3, chunk_parent: Node) -> void:
	if instance is Node2D:
		# Position relative to the chunk parent
		if chunk_parent and chunk_parent is Node2D:
			# Calculate local position within the chunk
			var local_pos_2d = chunk_parent.to_local(Vector2(position.x, position.z))
			instance.position = local_pos_2d
		else: # Fallback if parent is invalid
			instance.global_position = Vector2(position.x, position.z)
	elif instance is Node3D:
		# Position relative to the chunk parent (assuming parent is Node3D or spatial)
		if chunk_parent and chunk_parent is Node3D:
			instance.global_position = position # Set global first
			instance.global_transform = chunk_parent.global_transform.inverse() * instance.global_transform # Then make relative
		elif chunk_parent and chunk_parent is Node2D:
			# Handle 3D content in 2D chunk parent (might need offset adjustments)
			instance.global_position = position 
		else: # Fallback
			instance.global_position = position
	else:
		push_warning("ContentFactory: Instantiated content is not Node2D or Node3D. Cannot set position reliably.")

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
