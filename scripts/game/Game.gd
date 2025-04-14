extends Node2D

# --- Resources ---
# In Godot 4.4+, resources should be loaded when needed rather than preloaded

# --- Core Systems ---
var motion_profile_resolver: MotionProfileResolver
var ground_created: bool = false  # Track if the shared ground has been created

# --- Nodes ---
@onready var camera_manager = $CameraManager
@onready var player_spawner = $PlayerSpawner
@onready var stage_composition_system = $StageCompositionSystem
@onready var motion_system = $MotionSystem  # Reference to the MotionSystem node
@onready var environment_system = $EnvironmentSystem  # Reference to the EnvironmentSystem node

func _ready():
	# Initialize core systems
	initialize_motion_profile_resolver()
	initialize_motion_system() # Keep existing motion system init
	initialize_systems_with_resolver() # Pass resolver to relevant systems
	
	# Create a single shared ground for the entire level
	create_shared_ground()
	
	# Connect to signals for content placement
	connect_signals()
	
	# Pass motion system reference to player spawner (Keep existing logic)
	player_spawner.set_motion_system(motion_system)
	
	# Generate the default stage
	stage_composition_system.generate_stage("default_stage", "story")

	# Spawn the player after a short delay to ensure MotionSystem is fully initialized
	# This helps prevent timing issues with subsystem registration
	get_tree().create_timer(0.1).timeout.connect(func(): player_spawner.spawn_player())

# Create a single shared ground for the entire level
func create_shared_ground():
	# Create ground with collision shape
	var ground = StaticBody2D.new()
	ground.name = "SharedGround"
	ground.position = Vector2(0, 540)  # Position at Y=540 to match previous implementation
	ground.collision_layer = 1  # Set to appropriate layer for ground
	ground.collision_mask = 0   # Ground doesn't need to detect collisions
	add_child(ground)
	
	# Create collision shape for ground
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	ground.add_child(collision_shape)
	
	# Create rectangle shape with size based on chunk length
	var shape = RectangleShape2D.new()
	shape.size = Vector2(90000, 100)  # Width of 90000 to match previous implementation, height of 100
	collision_shape.shape = shape
	
	# Create visual representation for the ground (semi-transparent for debugging)
	var visual = ColorRect.new()
	visual.size = Vector2(90000, 100)   # Match collision shape size
	visual.position = Vector2(-45000, -50)  # Center the rect
	visual.color = Color(0.5, 0.5, 0.5, 0.3)  # Semi-transparent gray
	ground.add_child(visual)
	
	# Collect ground data for visuals
	var ground_data = []
	var data = {
		"position": Vector2(0, 0),  # Relative to ground
		"size": Vector2(90000, 100)  # Size of the ground
	}
	ground_data.append(data)
	
	# Emit signal for GroundVisualManager to create visuals
	if environment_system and environment_system.ground_manager:
		environment_system.ground_manager.apply_ground_visuals(ground_data)
	
	ground_created = true
	print("Game: Created shared ground for the entire level")

# Connect to signals
func connect_signals():
	# Connect to StageCompositionSystem signals
	GlobalSignals.request_chunk_instantiation.connect(_on_request_chunk_instantiation)
	GlobalSignals.request_content_placement.connect(_on_request_content_placement)

# Handle request chunk instantiation event
func _on_request_chunk_instantiation(chunk_definition: ChunkDefinition, position: Vector3):
	# Create a container node for the chunk
	var chunk_instance = Node2D.new()
	chunk_instance.name = "Chunk_" + chunk_definition.chunk_id
	chunk_instance.global_position = Vector2(position.x, position.z)  # Convert Vector3 to Vector2
	add_child(chunk_instance)
	
	# Note: We no longer create a ground for each chunk
	# The shared ground is created once in create_shared_ground()
	
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
					push_warning("Game: Unknown marker category '%s' in chunk '%s'" % [marker.intended_category, chunk_definition.chunk_id])

			# Request content placement using the calculated global position
			GlobalSignals.request_content_placement.emit(
				marker.intended_category,
				content_type,
				marker_global_position,
				chunk_instance
			)

# Handle request content placement event
# Added chunk_parent parameter
func _on_request_content_placement(content_category: String, content_type: String, position: Vector3, chunk_parent: Node):
	# Instantiate the content based on category and type
	var content_scene: PackedScene = null
	
	# Load the appropriate scene based on category and type
	match content_category.to_lower(): # Use lower case for robustness
		"obstacle": 
			if content_type == "Rock":
				var scene_path = "res://obstacles/RockObstacle.tscn"
				if ResourceLoader.exists(scene_path):
					content_scene = load(scene_path)
				else:
					push_error("Game: Obstacle scene not found: %s" % scene_path)
		"boost": 
			# Example: Load boost scene when implemented
			# var scene_path = "res://boosts/%s.tscn" % content_type 
			# if ResourceLoader.exists(scene_path): content_scene = load(scene_path) ...
			pass 
		"collectible": 
			# Example: Load collectible scene when implemented
			# var scene_path = "res://collectibles/%s.tscn" % content_type
			# if ResourceLoader.exists(scene_path): content_scene = load(scene_path) ...
			pass
		_:
			push_warning("Game: Cannot place content for unknown category '%s'" % content_category)

	
	# Instantiate the content if a scene was found
	if content_scene:
		var content_instance = content_scene.instantiate()
		
		# Set position - Assuming content is Node2D, use Vector2(X, Z)
		if content_instance is Node2D:
			# Position relative to the chunk parent
			if chunk_parent:
				# Calculate local position within the chunk
				var local_pos_2d = chunk_parent.to_local(Vector2(position.x, position.z))
				content_instance.position = local_pos_2d
			else: # Fallback if parent is invalid
				content_instance.global_position = Vector2(position.x, position.z)
		elif content_instance is Node3D:
			# Position relative to the chunk parent (assuming parent is Node3D or spatial)
			if chunk_parent and chunk_parent is Node3D:
				content_instance.global_position = position # Set global first
				content_instance.global_transform = chunk_parent.global_transform.inverse() * content_instance.global_transform # Then make relative
			elif chunk_parent and chunk_parent is Node2D:
				# Handle 3D content in 2D chunk parent (might need offset adjustments)
				content_instance.global_position = position 
			else: # Fallback
				content_instance.global_position = position 
		else:
			push_warning("Game: Instantiated content '%s' is not Node2D or Node3D. Cannot set position reliably." % content_type)

		# Add the content as a child of the chunk it belongs to
		if chunk_parent and chunk_parent.is_inside_tree():
			chunk_parent.add_child(content_instance)
		else:
			push_warning("Game: Chunk parent node is invalid or not in tree. Adding content '%s' directly to Game node." % content_type)
			add_child(content_instance) # Fallback: add to Game node
	elif content_category in ["obstacle", "boost", "collectible"]: # Only warn if it was a known category we failed to load
		push_warning("Game: Failed to load or find scene for content type '%s' in category '%s'" % [content_type, content_category])

# Initialize the MotionSystem
func initialize_motion_system() -> void:
	if not motion_system:
		return

	# Explicitly register all subsystems
	# This allows for more dynamic control over when subsystems are loaded
	var core = motion_system._core
	if core:
		# Make sure the PhysicsConfig is loaded
		var physics_config = core.get_physics_config()
		if physics_config:
			print("Game: PhysicsConfig loaded successfully")
		else:
			push_warning("Game: PhysicsConfig not loaded in MotionSystemCore")
			
		# Register all subsystems
		core.register_all_subsystems()
		
		# Set debug mode to true to see more detailed logs
		core.set_debug_enabled(true)
	else:
		return

# Initialize the MotionProfileResolver
func initialize_motion_profile_resolver() -> void:
	motion_profile_resolver = MotionProfileResolver.new()
	# Enable debug logging in debug builds
	motion_profile_resolver.set_debug_enabled(OS.is_debug_build())
	
	# Load and set the initial default ground configuration
	var default_ground_config_path = "res://resources/motion/profiles/ground/default_ground.tres"
	if ResourceLoader.exists(default_ground_config_path):
		var default_ground_config = load(default_ground_config_path)
		if default_ground_config:
			motion_profile_resolver.set_ground_config(default_ground_config)
			print("Game: Default ground config loaded and set in MotionProfileResolver")
		else:
			push_error("Game: Failed to load default ground config as resource from %s" % default_ground_config_path)
	else:
		push_error("Game: Default ground config file not found at %s" % default_ground_config_path)
		
	# Load and set the physics configuration
	var physics_config_path = "res://resources/physics/default_physics.tres"
	if ResourceLoader.exists(physics_config_path):
		var physics_config = load(physics_config_path) as PhysicsConfig
		if physics_config:
			motion_profile_resolver.set_physics_config(physics_config)
			print("Game: PhysicsConfig loaded and set in MotionProfileResolver")
		else:
			push_error("Game: Failed to load PhysicsConfig as resource from %s" % physics_config_path)
	else:
		push_error("Game: PhysicsConfig file not found at %s" % physics_config_path)

# Pass the resolver instance to systems that need it
func initialize_systems_with_resolver() -> void:
	if not motion_profile_resolver:
		push_error("Game: MotionProfileResolver not initialized before passing to systems.")
		return
		
	# Pass to MotionSystem (which will pass to MotionSystemCore)
	if motion_system and motion_system.has_method("initialize_with_resolver"):
		motion_system.initialize_with_resolver(motion_profile_resolver)
	
	# Directly pass to subsystems if needed
	var bounce_system = motion_system.get_subsystem("BounceSystem")
	if bounce_system and bounce_system.has_method("initialize_with_resolver"):
		bounce_system.initialize_with_resolver(motion_profile_resolver)
		
	var boost_system = motion_system.get_subsystem("BoostSystem")
	if boost_system and boost_system.has_method("initialize_with_resolver"):
		boost_system.initialize_with_resolver(motion_profile_resolver)
		
	var launch_system = motion_system.get_subsystem("LaunchSystem")
	if launch_system and launch_system.has_method("initialize_with_resolver"):
		launch_system.initialize_with_resolver(motion_profile_resolver)
		
	var collision_material_system = motion_system.get_subsystem("CollisionMaterialSystem")
	if collision_material_system:
		# Pass resolver (if still needed for other things)
		if collision_material_system.has_method("initialize_with_resolver"):
			collision_material_system.initialize_with_resolver(motion_profile_resolver)
		# Pass PhysicsConfig
		if collision_material_system.has_method("set_physics_config"):
			var physics_config = motion_system.get_physics_config() # Get config from MotionSystem/Core
			if physics_config:
				collision_material_system.set_physics_config(physics_config)
			else:
				push_error("Game: Could not get PhysicsConfig to pass to CollisionMaterialSystem.")
	
	# Pass to StageCompositionSystem and EnvironmentSystem for biome updates
	if stage_composition_system and stage_composition_system.has_method("initialize_with_resolver"):
		stage_composition_system.initialize_with_resolver(motion_profile_resolver)
	
	if environment_system and environment_system.has_method("initialize_with_resolver"):
		# EnvironmentSystem handles biome config updates
		environment_system.initialize_with_resolver(motion_profile_resolver)
