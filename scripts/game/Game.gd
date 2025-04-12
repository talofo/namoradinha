extends Node2D

# --- Preloads ---
const MotionProfileResolver = preload("res://scripts/motion/core/MotionProfileResolver.gd")
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
		core.register_all_subsystems()
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

# Pass the resolver instance to systems that need it
func initialize_systems_with_resolver() -> void:
	if not motion_profile_resolver:
		push_error("Game: MotionProfileResolver not initialized before passing to systems.")
		return
		
	# Pass to systems that require motion profile data
	# Note: Systems need an 'initialize_with_resolver(resolver)' method
	if motion_system and motion_system.has_method("initialize_with_resolver"):
		motion_system.initialize_with_resolver(motion_profile_resolver)
	# Example for BounceSystem (assuming it's part of MotionSystem or accessible)
	# if motion_system._bounce_system and motion_system._bounce_system.has_method("initialize_with_resolver"):
	#	 motion_system._bounce_system.initialize_with_resolver(motion_profile_resolver)
	# Example for BoostSystem
	# if motion_system._boost_system and motion_system._boost_system.has_method("initialize_with_resolver"):
	#	 motion_system._boost_system.initialize_with_resolver(motion_profile_resolver)
	# Example for ObstacleSystem (if it exists and needs it)
	# if $ObstacleSystem and $ObstacleSystem.has_method("initialize_with_resolver"):
	#	 $ObstacleSystem.initialize_with_resolver(motion_profile_resolver)
	
	# Pass to StageManager or EnvironmentSystem for biome updates
	if stage_manager and stage_manager.has_method("initialize_with_resolver"):
		stage_manager.initialize_with_resolver(motion_profile_resolver)
	elif environment_system and environment_system.has_method("initialize_with_resolver"):
		# Choose one place (StageManager or EnvironmentSystem) to handle biome config updates
		environment_system.initialize_with_resolver(motion_profile_resolver)
