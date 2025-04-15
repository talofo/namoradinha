# No class_name to avoid conflict with autoload singleton
extends Node

# Import required classes
# In Godot 4.4+, classes with class_name are globally available

# Debug mode
var debug_enabled: bool = true

# Game node reference
var game_node: Node = null
var content_parent: Node = null

func _ready():
	print("GameSignalBus: Initialized as autoload singleton")

# Connect game signals
func connect_game_signals(game_node_ref: Node) -> void:
	# Store reference to the game node
	game_node = game_node_ref
	
	# Create a dedicated parent for all content
	content_parent = Node2D.new()
	content_parent.name = "ContentParent"
	game_node.add_child(content_parent)
	
	# Connect to StageCompositionSystem signals
	_connect_stage_signals()
	
	# Connect to content placement signals
	_connect_content_signals()
	
	if debug_enabled:
		print("GameSignalBus: Game signals connected")
		print("GameSignalBus: ContentParent created at " + str(content_parent.get_path()))

# Connect stage-related signals
func _connect_stage_signals() -> void:
	# Connect to GlobalSignals for stage events
	GlobalSignals.request_chunk_instantiation.connect(
		_create_chunk_instantiation_callback()
	)
	
	if debug_enabled:
		print("GameSignalBus: Stage signals connected")

# Connect content-related signals
func _connect_content_signals() -> void:
	# Connect to GlobalSignals for content placement
	GlobalSignals.request_content_placement.connect(
		_create_content_placement_callback()
	)
	
	if debug_enabled:
		print("GameSignalBus: Content signals connected")

# Create a callback for chunk instantiation
func _create_chunk_instantiation_callback() -> Callable:
	# Create a ContentFactory if it doesn't exist
	var content_factory = _get_or_create_content_factory()
	
	# Return the callback
	return func(chunk_definition: ChunkDefinition, position: Vector2):
		# Create a container node for the chunk
		var chunk_instance = Node2D.new()
		chunk_instance.name = "Chunk_" + chunk_definition.chunk_id
		chunk_instance.global_position = position
		content_parent.add_child(chunk_instance)
		
		print("GameSignalBus: Created chunk " + chunk_definition.chunk_id + " at position " + str(position))
		
		# NOTE: Removed redundant marker processing loop. 
		# Content placement is now solely handled by ContentDistributionSystem.

# Create a callback for content placement
func _create_content_placement_callback() -> Callable:
	# Create a ContentFactory if it doesn't exist
	var content_factory = _get_or_create_content_factory()
	
	# Debug print
	print("DEBUG: Content factory exists: %s" % (content_factory != null))
	
	# Return the callback
	return func(placement_data: Dictionary):
		# Debug print
		print("GameSignalBus: Received content placement request: %s" % str(placement_data))
		
		# Extract values from the placement dictionary
		var content_category = placement_data["category"]
		var content_type = placement_data["type"]
		var distance = placement_data["distance_along_chunk"]
		var height = placement_data["height"]
		var width_offset = placement_data["width_offset"]
		var chunk_parent = placement_data.get("chunk_parent", null)
		
		# Debug print
		print("DEBUG: Creating content with category=%s, type=%s, distance=%s, height=%s, width_offset=%s, chunk_parent=%s" % 
			[content_category, content_type, str(distance), str(height), str(width_offset), str(chunk_parent)])
		
		# If no chunk parent is provided, use the content parent
		if chunk_parent == null:
			chunk_parent = content_parent
			print("GameSignalBus: Using ContentParent as parent for " + content_category + "/" + content_type)
		
		# Use the ContentFactory to create the content with explicit coordinates
		var content = content_factory.create_content(content_category, content_type, distance, height, width_offset, chunk_parent)
		
		# Verify the content was created and added to the scene tree
		if content:
			print("GameSignalBus: Content created and added to scene tree: %s" % str(content.is_inside_tree()))
			print("GameSignalBus: Content parent: %s" % (content.get_parent().name if content.get_parent() else "none"))

# Get or create a ContentFactory
func _get_or_create_content_factory() -> Node:
	# Check if the game node already has a ContentFactory
	if game_node.has_node("ContentFactory"):
		return game_node.get_node("ContentFactory")
	
	# Load the ContentFactory script
	var factory_script = load("res://scripts/stage/content/ContentFactory.gd")
	if not factory_script:
		push_error("GameSignalBus: Failed to load ContentFactory script")
		return null
	
	# Create a new ContentFactory
	var content_factory = factory_script.new()
	content_factory.name = "ContentFactory"
	content_factory.set_debug_enabled(debug_enabled)
	game_node.add_child(content_factory)
	
	return content_factory

# Set debug mode
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled

# Add content to the scene tree
func add_content_to_scene(content: Node) -> bool:
	if content_parent and is_instance_valid(content_parent):
		content_parent.add_child(content)
		print("GameSignalBus: Added content to scene tree via ContentParent")
		return true
	elif game_node and is_instance_valid(game_node):
		game_node.add_child(content)
		print("GameSignalBus: Added content to scene tree via game_node")
		return true
	else:
		push_error("GameSignalBus: Cannot add content to scene - no valid parent")
		return false
