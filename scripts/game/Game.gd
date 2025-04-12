extends Node2D

# --- Preloads ---
# No need to preload classes that are globally available via class_name
const DefaultGroundConfig = preload("res://resources/motion/profiles/ground/default_ground.tres")

# --- Core Systems ---
var motion_profile_resolver: MotionProfileResolver

# --- Nodes ---
@onready var camera_manager = $CameraManager
@onready var player_spawner = $PlayerSpawner
@onready var stage_manager = $StageManager
@onready var motion_system = $MotionSystem  # Reference to the MotionSystem node
@onready var environment_system = $EnvironmentSystem  # Reference to the EnvironmentSystem node

func _ready():
	# Initialize core systems
	initialize_motion_profile_resolver()
	initialize_motion_system() # Keep existing motion system init
	initialize_systems_with_resolver() # Pass resolver to relevant systems
	
	# Pass motion system reference to player spawner (Keep existing logic)
	player_spawner.set_motion_system(motion_system)
	
	# Example: load stage 1
	stage_manager.load_stage(1)

	# Spawn the player after a short delay to ensure MotionSystem is fully initialized
	# This helps prevent timing issues with subsystem registration
	get_tree().create_timer(0.1).timeout.connect(func(): player_spawner.spawn_player())

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
	if DefaultGroundConfig:
		motion_profile_resolver.set_ground_config(DefaultGroundConfig)
	else:
		push_error("Game: Failed to load DefaultGroundConfig at res://resources/motion/profiles/ground/default_ground.tres")
		
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
	
	# Pass to StageManager or EnvironmentSystem for biome updates
	if stage_manager and stage_manager.has_method("initialize_with_resolver"):
		stage_manager.initialize_with_resolver(motion_profile_resolver)
	elif environment_system and environment_system.has_method("initialize_with_resolver"):
		# Choose one place (StageManager or EnvironmentSystem) to handle biome config updates
		environment_system.initialize_with_resolver(motion_profile_resolver)
