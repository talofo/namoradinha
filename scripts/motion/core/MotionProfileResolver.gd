class_name MotionProfileResolver
extends RefCounted

# No need to preload classes that are globally available via class_name

## Emitted when any configuration source is updated.
## Passes the type of config that changed (e.g., "ground", "air").
signal config_changed(config_type: String)

# --- Configuration Sources ---
# Reference to the currently active ground physics configuration.
var _ground_config: GroundPhysicsConfig = null
# Reference to the physics configuration.
var _physics_config: PhysicsConfig = null
# Future config sources will be added here (e.g., _air_config, _trait_profile)

# --- Caching ---
# Stores the last resolved profile to avoid redundant calculations.
var _cached_profile: Dictionary = {}
# Flag indicating if the cached profile is still valid.
var _cache_valid: bool = false
# Instance ID of the player for which the profile was cached.
var _cached_player_id: int = -1

# --- Default Values ---
# Fallback values used when no configuration source provides a specific parameter.
# These ensure the resolver always returns a complete, valid profile.
const DEFAULTS := {
	# Base motion parameters
	"friction": 0.2,
	"bounce": 0.8,
	"drag": 0.1,
	"gravity_scale": 1.0,
	"mass_multiplier": 1.0,
	"velocity_modifier": 1.0,
	"air_control_multiplier": 1.0,
	
	# Bounce parameters
	"min_bounce_height_threshold": 20.0,  # Lower value means more bounces
	"min_bounce_kinetic_energy": 2000.0,  # Lower value means more bounces
	"min_bounce_energy_ratio": 0.7,       # Higher value means more energetic bounces
	"min_stop_speed": 5.0,                # Lower value means longer slides
	"horizontal_preservation": 0.98,      # Higher value means more horizontal momentum preserved
	
	# Boost parameters
	"manual_air_boost_rising_strength": 300.0,
	"manual_air_boost_rising_angle": 45.0,
	"manual_air_boost_falling_strength": 800.0,  # Higher value means stronger downward boost
	"manual_air_boost_falling_angle": -60.0,
	
	# Material properties
	"default_material_friction": 0.3,
	"default_material_bounce": 0.8,       # Higher value means bouncier surfaces
	"ice_material_friction": 0.05,        # Very low friction for ice
	"ice_material_bounce": 0.9,           # Very bouncy ice
	"mud_material_friction": 1.5,         # High friction for mud
	"mud_material_bounce": 0.3,           # Low bounce for mud
	"rubber_material_friction": 1.0,
	"rubber_material_bounce": 0.95        # Very bouncy rubber
}

# --- Debugging ---
# Enables detailed logging for debugging purposes.
var _debug_enabled := false
# Tracks warnings logged for missing configs to avoid spam.
var _logged_missing_configs := {}
# Stores the source of each resolved parameter for debugging.
var _parameter_sources := {}

# Map TYPE_* constants to readable strings for debugging
const TYPE_NAMES = {
	TYPE_NIL: "Nil", TYPE_BOOL: "Bool", TYPE_INT: "Int", TYPE_FLOAT: "Float",
	TYPE_STRING: "String", TYPE_VECTOR2: "Vector2", TYPE_VECTOR2I: "Vector2i",
	TYPE_RECT2: "Rect2", TYPE_RECT2I: "Rect2i", TYPE_VECTOR3: "Vector3",
	TYPE_VECTOR3I: "Vector3i", TYPE_TRANSFORM2D: "Transform2D", TYPE_VECTOR4: "Vector4",
	TYPE_VECTOR4I: "Vector4i", TYPE_PLANE: "Plane", TYPE_QUATERNION: "Quaternion",
	TYPE_AABB: "AABB", TYPE_BASIS: "Basis", TYPE_TRANSFORM3D: "Transform3D",
	TYPE_PROJECTION: "Projection", TYPE_COLOR: "Color", TYPE_STRING_NAME: "StringName",
	TYPE_NODE_PATH: "NodePath", TYPE_RID: "RID", TYPE_OBJECT: "Object",
	TYPE_CALLABLE: "Callable", TYPE_SIGNAL: "Signal", TYPE_DICTIONARY: "Dictionary",
	TYPE_ARRAY: "Array", TYPE_PACKED_BYTE_ARRAY: "PackedByteArray",
	TYPE_PACKED_INT32_ARRAY: "PackedInt32Array", TYPE_PACKED_INT64_ARRAY: "PackedInt64Array",
	TYPE_PACKED_FLOAT32_ARRAY: "PackedFloat32Array", TYPE_PACKED_FLOAT64_ARRAY: "PackedFloat64Array",
	TYPE_PACKED_STRING_ARRAY: "PackedStringArray", TYPE_PACKED_VECTOR2_ARRAY: "PackedVector2Array",
	TYPE_PACKED_VECTOR3_ARRAY: "PackedVector3Array", TYPE_PACKED_COLOR_ARRAY: "PackedColorArray",
	TYPE_MAX: "Max" # Should not appear
}


# --- Setters ---

## Updates the active ground physics configuration.
func set_ground_config(config: GroundPhysicsConfig) -> void:
	# Check if the config has actually changed to avoid unnecessary cache invalidation.
	if _ground_config != config:
		_ground_config = config
		_invalidate_cache()
		emit_signal("config_changed", "ground")
		if _debug_enabled:
			var config_id = config.biome_id if config else "null"
			print("MotionProfileResolver: Ground config updated to '%s'" % config_id)

## Updates the physics configuration.
func set_physics_config(config: PhysicsConfig) -> void:
	# Check if the config has actually changed to avoid unnecessary cache invalidation.
	if _physics_config != config:
		_physics_config = config
		_invalidate_cache()
		emit_signal("config_changed", "physics")
		if _debug_enabled:
			print("MotionProfileResolver: Physics config updated")

## Updates the ground config by loading the resource for the specified biome ID.
## Handles fallback to the default ground config if the biome-specific one is not found.
func update_ground_config_for_biome(biome_id: String) -> void:
	if not biome_id or biome_id.is_empty():
		push_warning("MotionProfileResolver: Invalid biome_id provided for ground config update.")
		# Optionally, set to default here or leave as is
		# set_ground_config(load("res://resources/motion/profiles/ground/default_ground.tres"))
		return

	# Construct the expected path for the biome's ground config resource
	var biome_config_path = "res://resources/motion/profiles/ground/%s_ground.tres" % biome_id
	var loaded_config: GroundPhysicsConfig = null

	if ResourceLoader.exists(biome_config_path):
		loaded_config = load(biome_config_path) as GroundPhysicsConfig

	if loaded_config:
		set_ground_config(loaded_config)
		if _debug_enabled:
			print("MotionProfileResolver: Set ground config for biome '%s' from '%s'." % [biome_id, biome_config_path])
	else:
		push_warning("MotionProfileResolver: No GroundPhysicsConfig found for biome '%s' at path '%s'. Falling back to default." % [biome_id, biome_config_path])
		# Fall back to the default config
		var default_config_path = "res://resources/motion/profiles/ground/default_ground.tres"
		if ResourceLoader.exists(default_config_path):
			var default_config = load(default_config_path) as GroundPhysicsConfig
			if default_config:
				set_ground_config(default_config)
			else:
				push_error("MotionProfileResolver: DefaultGroundConfig could not be loaded for fallback from '%s'." % default_config_path)
				set_ground_config(null) # Clear config as last resort
		else:
			push_error("MotionProfileResolver: Default ground config not found at '%s'." % default_config_path)
			set_ground_config(null) # Clear config as last resort

# --- Cache Management ---

## Invalidates the cached motion profile.
## Called whenever an input configuration changes.
func _invalidate_cache() -> void:
	if _cache_valid: # Only print if cache was actually valid before
		if _debug_enabled:
			print("MotionProfileResolver: Cache invalidated.")
	_cache_valid = false
	_cached_profile.clear()
	_cached_player_id = -1
	_parameter_sources.clear() # Clear debug source tracking too

# --- Resolution ---

## Resolves the final motion parameters based on all active configurations.
## player: The player node, used for context (e.g., caching key, future state checks).
## Returns: A Dictionary containing the resolved motion parameters.
func resolve_motion_profile(player: Node) -> Dictionary:
	# Ensure player node is valid
	if not is_instance_valid(player):
		push_error("MotionProfileResolver: Invalid player node passed to resolve_motion_profile.")
		return DEFAULTS.duplicate() # Return defaults if player is invalid

	var player_instance_id = player.get_instance_id()

	# Return cached result if still valid for the same player instance
	if _cache_valid and _cached_player_id == player_instance_id:
		return _cached_profile.duplicate() # Return a copy to prevent external modification

	# --- Resolution Logic ---
	# Start with a fresh profile based on global defaults.
	var profile = DEFAULTS.duplicate()
	var sources = {} # Track the source of each parameter for debugging

	# Apply configurations in reverse priority order (lowest priority first)
	# Layer 4: Global Physics Config (highest priority for physics parameters)
	_apply_physics_config(_physics_config, profile.keys(), profile, sources)
	
	# Layer 3: Biome/Chunk Ground Physics
	_apply_config(_ground_config, profile.keys(), "ground", profile, sources)

	# Layer 2: Equipment + Traits (Future)
	# _apply_config(_equipment_profile, profile.keys(), "equipment", profile, sources)
	# _apply_config(_trait_profile, profile.keys(), "trait", profile, sources)

	# Layer 1: Temporary Modifiers (Future - might need a different application method)
	# _apply_environmental_effect(_environmental_effect, profile, sources)

	# --- Caching ---
	# Cache the final resolved profile.
	_cached_profile = profile.duplicate() # Store a copy
	_cache_valid = true
	_cached_player_id = player_instance_id
	_parameter_sources = sources.duplicate() # Store debug sources

	# --- Debug Output ---
	if _debug_enabled:
		print("MotionProfileResolver: Resolved profile for player %d:" % player_instance_id)
		for key in profile:
			var src = sources.get(key, "default") # Default source is 'default'
			# Format floats nicely for printing
			var value_str = str(profile[key])
			if typeof(profile[key]) == TYPE_FLOAT:
				value_str = "%.3f" % profile[key]
			print("  - %s: %s (%s)" % [key, value_str, src])

	return profile.duplicate() # Return a copy

# --- Helper Functions ---

## Applies values from the PhysicsConfig onto the profile.
## config: The PhysicsConfig object.
## keys: The list of parameter keys to potentially update.
## profile: The profile dictionary being built (mutated by this function).
## sources: The dictionary tracking parameter sources (mutated by this function).
func _apply_physics_config(config: PhysicsConfig, keys: Array, profile: Dictionary, sources: Dictionary) -> void:
	if not config:
		_log_once_missing("physics")
		return # Skip if physics config is not set
	
	# Map of parameter names in profile to property names in PhysicsConfig
	var param_map = {
		"min_bounce_height_threshold": "min_bounce_height_threshold",
		"min_bounce_kinetic_energy": "min_bounce_kinetic_energy",
		"min_bounce_energy_ratio": "min_bounce_energy_ratio",
		"min_stop_speed": "min_stop_speed",
		"horizontal_preservation": "horizontal_preservation",
		"manual_air_boost_rising_strength": "manual_air_boost_rising_strength",
		"manual_air_boost_rising_angle": "manual_air_boost_rising_angle",
		"manual_air_boost_falling_strength": "manual_air_boost_falling_strength",
		"manual_air_boost_falling_angle": "manual_air_boost_falling_angle",
		"default_material_friction": "default_material_friction",
		"default_material_bounce": "default_material_bounce",
		"ice_material_friction": "ice_material_friction",
		"ice_material_bounce": "ice_material_bounce",
		"mud_material_friction": "mud_material_friction",
		"mud_material_bounce": "mud_material_bounce",
		"rubber_material_friction": "rubber_material_friction",
		"rubber_material_bounce": "rubber_material_bounce"
	}
	
	# Apply each parameter from the PhysicsConfig
	for key in keys:
		# Skip if key is not in our parameter map
		if not param_map.has(key):
			continue
		
		# Get the property name in PhysicsConfig
		var prop_name = param_map[key]
		
		# Check if the property exists in the PhysicsConfig
		if not config.get(prop_name):
			continue
		
		# Get the value from the PhysicsConfig
		var value = config.get(prop_name)
		
		# Apply the value and record its source
		profile[key] = value
		sources[key] = "physics"
		
		if _debug_enabled:
			print("MotionProfileResolver: Applied physics parameter %s = %s" % [key, value])

## Applies values from a specific configuration source onto the profile.
## config: The configuration object (e.g., GroundPhysicsConfig instance).
## keys: The list of parameter keys to potentially update (e.g., ["friction", "bounce"]).
## label: A string identifying the source (e.g., "ground", "trait").
## profile: The profile dictionary being built (mutated by this function).
## sources: The dictionary tracking parameter sources (mutated by this function).
func _apply_config(config, keys: Array, label: String, profile: Dictionary, sources: Dictionary) -> void:
	if not config:
		_log_once_missing(label)
		return # Skip if this config source is not set

	# Simple, standard approach for all config types
	for key in keys:
		# Ensure the key is valid for our profile structure
		if not profile.has(key) or not DEFAULTS.has(key):
			continue # Skip keys not part of the expected profile structure

		# Check if the config source actually defines this property
		var has_key = false
		var value = null
		
		# Handle different config types
		if config is GroundPhysicsConfig:
			# Direct property access for known GroundPhysicsConfig properties
			match key:
				"friction": 
					has_key = true
					value = config.friction
				"bounce": 
					has_key = true
					value = config.bounce
				"drag": 
					has_key = true
					value = config.drag
				"gravity_scale": 
					has_key = true
					value = config.gravity_scale
				"mass_multiplier": 
					has_key = true
					value = config.mass_multiplier
				"velocity_modifier": 
					has_key = true
					value = config.velocity_modifier
				"air_control_multiplier": 
					has_key = true
					value = config.air_control_multiplier
		elif config is Dictionary:
			# Dictionary access
			has_key = config.has(key)
			if has_key:
				value = config.get(key)
		else:
			# Unsupported config type
			push_warning("MotionProfileResolver: Unsupported config type: %s" % typeof(config))
			continue

		# Skip if key not found or value is null
		if not has_key or value == null:
			continue

		# Type checking and conversion
		var default_type = typeof(DEFAULTS[key])
		var current_type = typeof(value)
		var converted_value = value

		# Convert types if needed
		if current_type != default_type:
			match default_type:
				TYPE_FLOAT:
					if current_type == TYPE_INT:
						converted_value = float(value)
					else:
						push_warning("MotionProfileResolver: Type mismatch for '%s'. Expected float." % key)
						continue
				TYPE_INT:
					if current_type == TYPE_FLOAT:
						converted_value = int(value)
					else:
						push_warning("MotionProfileResolver: Type mismatch for '%s'. Expected int." % key)
						continue
				TYPE_BOOL:
					if current_type == TYPE_INT or current_type == TYPE_FLOAT:
						converted_value = bool(value)
					else:
						push_warning("MotionProfileResolver: Type mismatch for '%s'. Expected bool." % key)
						continue
				_:
					push_warning("MotionProfileResolver: Type mismatch for '%s'." % key)
					continue

		# Apply the value and record its source
		profile[key] = converted_value
		sources[key] = label

# --- Logging Helpers ---

## Logs a warning once if a specific configuration source is missing.
func _log_once_missing(source: String) -> void:
	if not _logged_missing_configs.has(source):
		if _debug_enabled:
			push_warning("MotionProfileResolver: Missing config source '%s'. Using defaults/lower priority values." % source)
		_logged_missing_configs[source] = true

## Enables or disables debug logging.
func set_debug_enabled(enabled: bool) -> void:
	_debug_enabled = enabled
	if _debug_enabled:
		print("MotionProfileResolver: Debug logging enabled.")
	else:
		print("MotionProfileResolver: Debug logging disabled.")

## Returns a dictionary containing current debug information.
func get_debug_info() -> Dictionary:
	# Provide info about which configs are currently loaded
	var loaded_configs = {
		"ground": _ground_config != null,
		# Add future configs here
		# "air": _air_config != null,
		# "trait": _trait_profile != null,
	}
	return {
		"cached_profile": _cached_profile.duplicate(),
		"parameter_sources": _parameter_sources.duplicate(),
		"loaded_configs": loaded_configs,
		"cached_player_id": _cached_player_id,
		"cache_valid": _cache_valid,
		"debug_enabled": _debug_enabled,
	}
