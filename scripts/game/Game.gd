extends Node2D

# Load required scripts
const GameInitializerScript = preload("res://scripts/game/GameInitializer.gd")
# ContentInstantiationService is now an autoload singleton

# --- Nodes ---
@onready var camera_manager = $CameraManager
@onready var player_spawner = $PlayerSpawner
@onready var stage_composition_system = $StageCompositionSystem
@onready var motion_system = $MotionSystem
@onready var environment_system = $EnvironmentSystem

# --- Initialization ---
var _game_initializer = null

func _ready():
	# Disable debug rocks
	_disable_debug_rocks()
	
	# Create initializer
	_game_initializer = GameInitializerScript.new()
	_game_initializer.set_debug_enabled(OS.is_debug_build())
	
	# Initialize core systems
	_game_initializer.initialize_systems(self)
	
	# Initialize the ContentInstantiationService autoload singleton
	var content_instantiation_service = get_node("/root/ContentInstantiationService")
	content_instantiation_service.set_debug_enabled(OS.is_debug_build())
	content_instantiation_service.initialize_service(self)
	
	# Create a single shared ground for the entire level
	if environment_system:
		environment_system.create_shared_ground(self)
	
	# Pass motion system reference to player spawner
	player_spawner.set_motion_system(motion_system)
	
	# Generate the default stage
	stage_composition_system.generate_stage("default_stage", "story")
	
	# Spawn the player after a short delay to ensure MotionSystem is fully initialized
	# This helps prevent timing issues with subsystem registration
	get_tree().create_timer(0.1).timeout.connect(func(): player_spawner.spawn_player())

# Disable debug rocks by loading and instantiating the DisableDebugRocks scene
func _disable_debug_rocks() -> void:
	var disable_debug_rocks_scene = load("res://scenes/debug/DisableDebugRocks.tscn")
	if disable_debug_rocks_scene:
		var disable_debug_rocks_instance = disable_debug_rocks_scene.instantiate()
		add_child(disable_debug_rocks_instance)
		print("Game: Added DisableDebugRocks to disable debug rock creation scripts")
	else:
		push_error("Game: Failed to load DisableDebugRocks scene")
