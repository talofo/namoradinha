extends Node2D

@onready var camera_manager = $CameraManager
@onready var player_spawner = $PlayerSpawner
@onready var stage_manager = $StageManager
@onready var motion_system = $MotionSystem  # Reference to the MotionSystem node
@onready var environment_system = $EnvironmentSystem  # Reference to the EnvironmentSystem node

func _ready():
	# Initialize motion system
	initialize_motion_system()
	
	# Pass motion system reference to player spawner
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
