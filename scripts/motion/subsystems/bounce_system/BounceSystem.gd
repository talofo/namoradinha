class_name BounceSystem
extends RefCounted
#warning-ignore-all:unused_class_variable # Interface methods might not use all variables

const MotionProfileResolver = preload("res://scripts/motion/core/MotionProfileResolver.gd")
# Note: Other preloads removed as classes are globally available via class_name

# --- Constants ---
# Threshold for considering a collision normal as "floor" (dot product with UP vector)
const FLOOR_NORMAL_THRESHOLD = 0.7 

# --- Private Variables ---
var _calculator: BounceCalculator = null
var _motion_profile_resolver: MotionProfileResolver = null # Added resolver reference
# var _motion_system_core = null # Removed unused variable

# Dictionary to track bounce counts for each entity
var _bounce_counts: Dictionary = {}

# --- Initialization ---
func _init() -> void:
	_calculator = BounceCalculator.new()

# --- IMotionSubsystem Implementation ---

func get_name() -> String:
	return "BounceSystem"

func on_register() -> void:
	# Initialize bounce counts dictionary
	_bounce_counts.clear()

func on_unregister() -> void:
	# Clear bounce counts dictionary
	_bounce_counts.clear()

func get_continuous_modifiers(_delta: float) -> Array[MotionModifier]:
	# Bounce system is purely reactive to collisions, no continuous modifiers.
	return []

# Updated to accept CollisionContext directly
func get_collision_modifiers(context: CollisionContext) -> Array[MotionModifier]:
	print("[DEBUG] BounceSystem.get_collision_modifiers called")
	var modifiers: Array[MotionModifier] = []

	# --- Input Validation ---
	if not context or not context.player_node or not context.incoming_motion_state or not context.impact_surface_data or not context.player_bounce_profile:
		printerr("BounceSystem: Invalid or incomplete CollisionContext received (player_node is required).")
		return modifiers
		
	print("[DEBUG] BounceSystem: Context validation passed")

	# --- Resolve Motion Profile ---
	var motion_profile = {}
	if _motion_profile_resolver:
		motion_profile = _motion_profile_resolver.resolve_motion_profile(context.player_node)
	else:
		# Fallback if resolver is not set
		motion_profile = MotionProfileResolver.DEFAULTS.duplicate()
		push_warning("BounceSystem: MotionProfileResolver not available.")

	# Extract relevant parameters from profile
	var resolved_bounce_coefficient = motion_profile.get("bounce", 0.8) # Default from resolver DEFAULTS

	# --- Update Context with Resolved Data ---
	# Apply the resolved bounce coefficient, potentially modifying the player's base multiplier
	# Assuming we multiply the player's inherent bounciness by the surface/profile coefficient
	context.player_bounce_profile.bounciness_multiplier *= resolved_bounce_coefficient
	# Note: This modifies the context object directly. Ensure this is the intended design.
	# Alternatively, the calculator could take the resolved coefficient as a separate parameter.

	# Check if it's a floor collision based on the normal in the context
	var normal: Vector2 = context.impact_surface_data.normal
	print("[DEBUG] BounceSystem: Surface normal = ", normal, ", dot with UP = ", normal.dot(Vector2.UP))
	# If the upward component of the normal (dot product with UP) is less than the threshold,
	# it's considered a wall or ceiling, not a floor.
	if normal.dot(Vector2.UP) < FLOOR_NORMAL_THRESHOLD: 
		print("[DEBUG] BounceSystem: Not a floor collision, skipping")
		# Not a floor collision (or slope is too steep to be considered floor)
		return modifiers
		
	print("[DEBUG] BounceSystem: Floor collision detected")
	
	# Context is already provided.
	
	# --- Perform Calculation ---
	# Ensure generate_debug_data flag is set correctly based on engine state
	# (The context object passed in might have it set differently by the caller,
	# but we override here for consistency within the subsystem call)
	context.generate_debug_data = Engine.is_editor_hint() or OS.is_debug_build()
	
	print("[DEBUG] BounceSystem: Calling BounceCalculator.calculate")
	var outcome: BounceOutcome = _calculator.calculate(context)
	print("[DEBUG] BounceSystem: BounceCalculator.calculate returned outcome with state: ", outcome.termination_state)

	# --- Handle Outcome ---
	if outcome:
		# Log debug info if available
		if outcome.debug_data:
			print("BounceSystem Debug: ", outcome.debug_data)

		# Print debug info about the outcome state
		print("[DEBUG] BounceSystem: Outcome state is ", outcome.termination_state)

		# Create a modifier to apply the calculated velocity
		# Priority should be high to override other collision responses if bouncing/sliding.
		var velocity_modifier = MotionModifier.new(
			get_name(),           # source
			"velocity",           # type
			20,                   # priority (high)
			outcome.new_velocity, # vector (calculated bounce/slide/stop response)
			1.0,                  # scalar (unused for velocity)
			false,                # is_additive (replace velocity)
			-1                    # duration (instantaneous change)
		)
		modifiers.append(velocity_modifier)

	return modifiers


func get_provided_signals() -> Dictionary:
	# Example: Define signals if needed for effects
	# return {
	# 	"bounce_occurred": ["int"], # entity_id
	# 	"bounce_terminated": ["int", "String"] # entity_id, termination_state
	# }
	return {}

func get_signal_dependencies() -> Array:
	# This system doesn't depend on signals from other subsystems in this design.
	return []

# --- Bounce Count Tracking ---

# Get the current bounce count for an entity
func get_bounce_count(entity_id: int) -> int:
	return _bounce_counts.get(entity_id, 0)

# Increment the bounce count for an entity
func increment_bounce_count(entity_id: int) -> void:
	if not _bounce_counts.has(entity_id):
		_bounce_counts[entity_id] = 0
	_bounce_counts[entity_id] += 1
	print("[DEBUG] BounceSystem: Incremented bounce count for entity ", entity_id, " to ", _bounce_counts[entity_id])

# Reset the bounce count for an entity
func reset_bounce_count(entity_id: int) -> void:
	_bounce_counts[entity_id] = 0
	print("[DEBUG] BounceSystem: Reset bounce count for entity ", entity_id)

# --- Resolver Integration ---

## Called by Game.gd (or MotionSystemCore) to provide the resolver instance.
func initialize_with_resolver(resolver: MotionProfileResolver) -> void:
	_motion_profile_resolver = resolver
	# Optionally print debug message if needed
	# print("BounceSystem: MotionProfileResolver initialized.")
