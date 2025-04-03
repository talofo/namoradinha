extends Node2D

# This is an example of how to use the MotionSystem in a game context
# It demonstrates how to set up the system, register subsystems, and use it to resolve motion

# Reference to the motion system
var motion_system = null

# Player velocity
var velocity = Vector2.ZERO

# Debug flag
var debug_enabled = true

func _ready():
	print("Initializing MotionSystem example...")
	
	# Create the motion system
	motion_system = load("res://scripts/motion/MotionSystem.gd").new()
	motion_system.set_debug_enabled(debug_enabled)
	add_child(motion_system)
	
	# Create and register all subsystems
	_register_subsystems()
	
	print("MotionSystem example initialized")

func _register_subsystems():
	print("Registering subsystems...")
	
	# Create subsystems
	var boost_system = load("res://scripts/motion/subsystems/BoostSystem.gd").new()
	var obstacle_system = load("res://scripts/motion/subsystems/ObstacleSystem.gd").new()
	var equipment_system = load("res://scripts/motion/subsystems/EquipmentSystem.gd").new()
	var trait_system = load("res://scripts/motion/subsystems/TraitSystem.gd").new()
	var environmental_force_system = load("res://scripts/motion/subsystems/EnvironmentalForceSystem.gd").new()
	var status_effect_system = load("res://scripts/motion/subsystems/StatusEffectSystem.gd").new()
	var collision_material_system = load("res://scripts/motion/subsystems/CollisionMaterialSystem.gd").new()
	
	# Register subsystems with the motion system
	motion_system.register_subsystem(boost_system)
	motion_system.register_subsystem(obstacle_system)
	motion_system.register_subsystem(equipment_system)
	motion_system.register_subsystem(trait_system)
	motion_system.register_subsystem(environmental_force_system)
	motion_system.register_subsystem(status_effect_system)
	motion_system.register_subsystem(collision_material_system)
	
	print("All subsystems registered")

func _physics_process(delta):
	# In a real game, this would be where you apply player input, gravity, etc.
	# For this example, we'll just use a simple velocity
	
	# Start with a base velocity (e.g., from player input)
	velocity = Vector2(100, 50)  # Example: moving right and down
	
	# Resolve continuous motion using the motion system
	var motion_delta = motion_system.resolve_continuous_motion(delta)
	
	# Apply the motion delta to the velocity
	velocity += motion_delta
	
	# In a real game, you would then move the character using the velocity
	# For example:
	# var collision = move_and_collide(velocity * delta)
	
	# For this example, we'll just print the velocity
	if debug_enabled:
		print("Current velocity: %s" % velocity)

func _on_collision(collision_info):
	# This would be called when a collision occurs
	# For example, from the move_and_collide method
	
	# Resolve collision motion using the motion system
	var collision_motion = motion_system.resolve_collision_motion(collision_info)
	
	# Apply the collision motion to the velocity
	velocity = collision_motion
	
	# In a real game, you would then handle the collision
	# For example, play a sound, show a particle effect, etc.
	
	if debug_enabled:
		print("Collision velocity: %s" % velocity)

# Example of triggering a boost
func trigger_boost():
	var boost_system = motion_system.get_subsystem("BoostSystem")
	if boost_system:
		boost_system.trigger_boost(Vector2(1, 0), 10.0)  # Boost right with strength 10

# Example of applying a status effect
func apply_slow_effect(duration: float):
	var status_system = motion_system.get_subsystem("StatusEffectSystem")
	if status_system:
		status_system.apply_effect("slow", duration, 0.5)  # 50% slow for the specified duration
