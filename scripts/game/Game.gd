extends Node2D

@onready var camera_manager = $CameraManager
@onready var player_spawner = $PlayerSpawner
@onready var stage_manager = $StageManager
@onready var motion_system = $MotionSystem  # Reference to the MotionSystem node

# Physics parameters that can be tuned in the editor
@export_category("Physics Parameters")
@export var gravity: float = 1200.0
@export var ground_friction: float = 0.01
@export var stop_threshold: float = 1.0

func _ready():
	# Initialize motion system with physics parameters
	initialize_motion_system()
	
	# Example: load stage 1
	stage_manager.load_stage(1)

	# Spawn the player
	player_spawner.spawn_player()

# Initialize the MotionSystem and register all subsystems
func initialize_motion_system() -> void:
	if not motion_system:
		push_error("MotionSystem node not found!")
		return
	
	print("Initializing MotionSystem...")
	
	# Set physics parameters
	motion_system.default_gravity = gravity
	motion_system.default_ground_friction = ground_friction
	motion_system.default_stop_threshold = stop_threshold
	
	# Create and register all subsystems
	var bounce_system = load("res://scripts/motion/subsystems/BounceSystem.gd").new()
	var obstacle_system = load("res://scripts/motion/subsystems/ObstacleSystem.gd").new()
	var equipment_system = load("res://scripts/motion/subsystems/EquipmentSystem.gd").new()
	var trait_system = load("res://scripts/motion/subsystems/TraitSystem.gd").new()
	var environmental_force_system = load("res://scripts/motion/subsystems/EnvironmentalForceSystem.gd").new()
	var status_effect_system = load("res://scripts/motion/subsystems/StatusEffectSystem.gd").new()
	var collision_material_system = load("res://scripts/motion/subsystems/CollisionMaterialSystem.gd").new()
	var launch_system = load("res://scripts/motion/subsystems/LaunchSystem.gd").new()
	
	# Register all subsystems
	motion_system.register_subsystem(bounce_system)
	motion_system.register_subsystem(obstacle_system)
	motion_system.register_subsystem(equipment_system)
	motion_system.register_subsystem(trait_system)
	motion_system.register_subsystem(environmental_force_system)
	motion_system.register_subsystem(status_effect_system)
	motion_system.register_subsystem(collision_material_system)
	motion_system.register_subsystem(launch_system)
	
	print("MotionSystem initialized with all subsystems")
