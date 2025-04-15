class_name GameSignalBus
extends RefCounted

# Import required classes
# In Godot 4.4+, classes with class_name are globally available

# Debug mode
static var debug_enabled: bool = false

# Connect game signals
static func connect_game_signals(game_node: Node) -> void:
	# Connect to StageCompositionSystem signals
	_connect_stage_signals(game_node)
	
	# Connect to content placement signals
	_connect_content_signals(game_node)
	
	if debug_enabled:
		print("GameSignalBus: Game signals connected")

# Connect stage-related signals
static func _connect_stage_signals(game_node: Node) -> void:
	# Connect to GlobalSignals for stage events
	GlobalSignals.request_chunk_instantiation.connect(
		_create_chunk_instantiation_callback(game_node)
	)
	
	if debug_enabled:
		print("GameSignalBus: Stage signals connected")

# Connect content-related signals
static func _connect_content_signals(game_node: Node) -> void:
	# Connect to GlobalSignals for content placement
	GlobalSignals.request_content_placement.connect(
		_create_content_placement_callback(game_node)
	)
	
	if debug_enabled:
		print("GameSignalBus: Content signals connected")

# Create a callback for chunk instantiation
static func _create_chunk_instantiation_callback(game_node: Node) -> Callable:
	# Create a ContentFactory if it doesn't exist
	var content_factory = _get_or_create_content_factory(game_node)
	
	# Return the callback
	return func(chunk_definition: ChunkDefinition, position: Vector3):
		# Create a container node for the chunk
		var chunk_instance = Node2D.new()
		chunk_instance.name = "Chunk_" + chunk_definition.chunk_id
		chunk_instance.global_position = Vector2(position.x, position.z)  # Convert Vector3 to Vector2
		game_node.add_child(chunk_instance)
		
		# Process layout markers to place content
		for marker in chunk_definition.layout_markers:
			# Calculate the marker's *global* position based on the chunk's position
			var marker_global_position = Vector3(
				position.x + marker.position.x, 
				position.y + marker.position.y,
				position.z + marker.position.z
			)
			
			# Create a visual indicator for the marker (optional, for debugging)
			var marker_visual = ColorRect.new()
			marker_visual.size = Vector2(4, 4)
			marker_visual.color = Color(1, 0, 0, 0.7)  # Semi-transparent red
			marker_visual.position = Vector2(marker.position.x - 2, marker.position.z - 2)  # Center the rect
			chunk_instance.add_child(marker_visual)
			
			# If the marker has an intended category, request content placement
			if marker.has("intended_category"):
				# Find a suitable content type for this category
				var content_type = "default"
				match marker.intended_category.to_lower():
					"obstacle": 
						content_type = "Rock"
					"collectible": 
						content_type = "Coin"
					"boost": 
						content_type = "SpeedPad"
					_:
						if debug_enabled:
							push_warning("GameSignalBus: Unknown marker category '%s' in chunk '%s'" % [marker.intended_category, chunk_definition.chunk_id])

				# Request content placement using the calculated global position
				GlobalSignals.request_content_placement.emit(
					marker.intended_category,
					content_type,
					marker_global_position,
					chunk_instance
				)

# Create a callback for content placement
static func _create_content_placement_callback(game_node: Node) -> Callable:
	# Create a ContentFactory if it doesn't exist
	var content_factory = _get_or_create_content_factory(game_node)
	
	# Return the callback
	return func(content_category: String, content_type: String, position: Vector3, chunk_parent: Node = null):
		# Use the ContentFactory to create the content
		content_factory.create_content(content_category, content_type, position, chunk_parent)

# Get or create a ContentFactory
static func _get_or_create_content_factory(game_node: Node) -> Node:
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
static func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
