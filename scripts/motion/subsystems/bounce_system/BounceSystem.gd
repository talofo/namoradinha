class_name BounceSystem
extends RefCounted
#warning-ignore-all:unused_class_variable # Interface methods might not use all variables

# Note: Other preloads removed as classes are globally available via class_name

# --- Constants ---
# Threshold for considering a collision normal as "floor" (dot product with UP vector)
const FLOOR_NORMAL_THRESHOLD = 0.7 

# --- Private Variables ---
var _calculator: BounceCalculator = null
var _motion_profile_resolver: MotionProfileResolver = null # Resolver reference
var _core = null # Reference to MotionSystemCore for accessing PhysicsConfig
var _last_outcome: BounceOutcome = null # Store the last bounce outcome for state tracking

# --- Initialization ---
func _init() -> void:
	_calculator = BounceCalculator.new()

# Initialize with the MotionProfileResolver
func initialize_with_resolver(resolver: MotionProfileResolver) -> void:
	_motion_profile_resolver = resolver
	# Debug print removed

# --- IMotionSubsystem Implementation ---

func get_name() -> String:
	return "BounceSystem"

func on_register() -> void:
	# Store reference to MotionSystem for accessing PhysicsConfig
	if "_motion_system" in self and self._motion_system:
		_core = self._motion_system
		# Debug print removed

func on_unregister() -> void:
	_core = null

func get_continuous_modifiers(_delta: float) -> Array[MotionModifier]:
	# Bounce system is purely reactive to collisions, no continuous modifiers.
	return []

# Updated to accept CollisionContext directly and use the new approach
func get_collision_modifiers(context: CollisionContext) -> Array[MotionModifier]:
	# Debug print removed
	var modifiers: Array[MotionModifier] = []

	# --- Input Validation ---
	if not context or not context.player_node or not context.incoming_motion_state or not context.impact_surface_data or not context.player_bounce_profile:
		printerr("BounceSystem: Invalid or incomplete CollisionContext received (player_node is required).")
		return modifiers
		
	# Debug print removed

	# --- Resolve Motion Profile ---
	var resolved_profile = {}
	if _motion_profile_resolver:
		resolved_profile = _motion_profile_resolver.resolve_motion_profile(context.player_node)
	else:
		# Fallback if resolver is not set
		resolved_profile = MotionProfileResolver.DEFAULTS.duplicate()
		push_warning("BounceSystem: MotionProfileResolver not available.")

	# --- Get Physics Rules ---
	var physics_rules = null
	# Attempt to get PhysicsConfig from the core system
	if _core and _core.has_method("get_physics_config"):
		physics_rules = _core.get_physics_config()
		# Debug print removed
	
	# If still not found after checking core, try to load it directly
	if not physics_rules:
		var config_path = "res://resources/physics/default_physics.tres"
		if ResourceLoader.exists(config_path):
			physics_rules = load(config_path) as PhysicsConfig
			# Debug print removed
	
	# If still not found, use a default instance
	if not physics_rules:
		push_warning("BounceSystem: PhysicsConfig not available. Creating default instance.")
		physics_rules = PhysicsConfig.new() # Use default class values

	# Check if it's a floor collision based on the normal in the context
	var normal: Vector2 = context.impact_surface_data.normal
	# Debug print removed
	# If the upward component of the normal (dot product with UP) is less than the threshold,
	# it's considered a wall or ceiling, not a floor.
	if normal.dot(Vector2.UP) < FLOOR_NORMAL_THRESHOLD: 
		# Debug print removed
		# Not a floor collision (or slope is too steep to be considered floor)
		return modifiers
		
	# Debug print removed
	
	# --- Perform Calculation ---
	# Ensure generate_debug_data flag is set correctly based on engine state
	context.generate_debug_data = Engine.is_editor_hint() or OS.is_debug_build()
	
	# Debug print removed
	var outcome: BounceOutcome = _calculator.calculate(context, resolved_profile, physics_rules)
	
	# Store the outcome for state tracking
	_last_outcome = outcome
	
	# Debug print removed

	# --- Handle Outcome ---
	if outcome:
		# Debug print removed

		# Debug print removed

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

# --- Public Methods ---

# Get the last bounce outcome
# Returns: The last BounceOutcome or null if no bounce has occurred yet
func get_last_outcome() -> BounceOutcome:
	return _last_outcome
