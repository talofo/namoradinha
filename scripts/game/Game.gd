extends Node2D

@onready var camera_manager = $CameraManager
@onready var player_spawner = $PlayerSpawner
@onready var stage_manager = $StageManager
@onready var motion_system = $MotionSystem  # Reference to the MotionSystem node

func _ready():
	# Initialize motion system
	initialize_motion_system()
	
	# Example: load stage 1
	stage_manager.load_stage(1)

	# Spawn the player after a short delay to ensure MotionSystem is fully initialized
	# This helps prevent timing issues with subsystem registration
	get_tree().create_timer(0.1).timeout.connect(func(): player_spawner.spawn_player())

# Initialize the MotionSystem and register all subsystems
func initialize_motion_system() -> void:
	if not motion_system:
		push_error("MotionSystem node not found!")
		return
	
	print("Initializing MotionSystem...")
	
	# Create and register all subsystems
	# Physics parameters are now loaded directly by MotionSystem from PhysicsConfig resource
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
	
	# Connect LaunchSystem's signal (via MotionSystem) to BounceSystem's recording method
	if motion_system.has_signal("entity_launched") and bounce_system.has_method("record_launch"):
		motion_system.entity_launched.connect(bounce_system.record_launch)
		print("[Game] Connected entity_launched signal to BounceSystem.record_launch")
	else:
		push_warning("[Game] Failed to connect entity_launched signal to BounceSystem")
		
	print("MotionSystem initialized with all subsystems")
