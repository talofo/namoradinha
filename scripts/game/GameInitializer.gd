class_name GameInitializer
extends RefCounted

# Debug mode
var debug_enabled: bool = false

# Motion profile resolver instance
var _motion_profile_resolver: MotionProfileResolver = null

# Initialize all game systems
func initialize_systems(game_node: Node) -> void:
	# Create and initialize the motion profile resolver
	initialize_motion_profile_resolver()
	
	# Initialize motion system
	if game_node.motion_system:
		initialize_motion_system(game_node.motion_system)
	
	# Pass resolver to relevant systems
	initialize_systems_with_resolver(game_node)
	
	if debug_enabled:
		print("GameInitializer: All systems initialized")

# Initialize the MotionProfileResolver
func initialize_motion_profile_resolver() -> void:
	_motion_profile_resolver = MotionProfileResolver.new()
	
	# Enable debug logging in debug builds
	_motion_profile_resolver.set_debug_enabled(OS.is_debug_build() and debug_enabled)
	
	# Load and set the initial default ground configuration
	var default_ground_config_path = "res://resources/motion/profiles/ground/default_ground.tres"
	if ResourceLoader.exists(default_ground_config_path):
		var default_ground_config = load(default_ground_config_path)
		if default_ground_config:
			_motion_profile_resolver.set_ground_config(default_ground_config)
			if debug_enabled:
				print("GameInitializer: Default ground config loaded and set in MotionProfileResolver")
		else:
			push_error("GameInitializer: Failed to load default ground config as resource from %s" % default_ground_config_path)
	else:
		push_error("GameInitializer: Default ground config file not found at %s" % default_ground_config_path)
	
	# Load and set the physics configuration
	var physics_config_path = "res://resources/physics/default_physics.tres"
	if ResourceLoader.exists(physics_config_path):
		var physics_config = load(physics_config_path) as PhysicsConfig
		if physics_config:
			_motion_profile_resolver.set_physics_config(physics_config)
			if debug_enabled:
				print("GameInitializer: PhysicsConfig loaded and set in MotionProfileResolver")
		else:
			push_error("GameInitializer: Failed to load PhysicsConfig as resource from %s" % physics_config_path)
	else:
		push_error("GameInitializer: PhysicsConfig file not found at %s" % physics_config_path)

# Initialize the MotionSystem
func initialize_motion_system(motion_system: Node) -> void:
	if not motion_system:
		push_error("GameInitializer: Motion system is null")
		return

	# Get the core from the motion system
	var core = motion_system._core
	if core:
		# Make sure the PhysicsConfig is loaded
		var physics_config = core.get_physics_config()
		if physics_config:
			if debug_enabled:
				print("GameInitializer: PhysicsConfig loaded successfully in MotionSystemCore")
		else:
			push_warning("GameInitializer: PhysicsConfig not loaded in MotionSystemCore")
		
		# Register all subsystems
		core.register_all_subsystems()
		
		# Set debug mode to true to see more detailed logs
		core.set_debug_enabled(debug_enabled)
		
		if debug_enabled:
			print("GameInitializer: Motion system initialized")
	else:
		push_error("GameInitializer: Motion system core is null")

# Pass the resolver instance to systems that need it
func initialize_systems_with_resolver(game_node: Node) -> void:
	if not _motion_profile_resolver:
		push_error("GameInitializer: MotionProfileResolver not initialized before passing to systems.")
		return
	
	# Pass to MotionSystem (which will pass to MotionSystemCore)
	if game_node.motion_system and game_node.motion_system.has_method("initialize_with_resolver"):
		game_node.motion_system.initialize_with_resolver(_motion_profile_resolver)
		
		# Get subsystems from motion system
		_initialize_motion_subsystems(game_node.motion_system)
	
	# Pass to StageCompositionSystem for biome updates
	if game_node.stage_composition_system and game_node.stage_composition_system.has_method("initialize_with_resolver"):
		game_node.stage_composition_system.initialize_with_resolver(_motion_profile_resolver)
	
	# Pass to EnvironmentSystem for biome updates
	if game_node.environment_system and game_node.environment_system.has_method("initialize_with_resolver"):
		# EnvironmentSystem handles biome config updates
		game_node.environment_system.initialize_with_resolver(_motion_profile_resolver)
		
	if debug_enabled:
		print("GameInitializer: Systems initialized with resolver")

# Initialize motion subsystems with resolver
func _initialize_motion_subsystems(motion_system: Node) -> void:
	# Get subsystems that need the resolver
	var subsystems = {
		"BounceSystem": "initialize_with_resolver",
		"BoostSystem": "initialize_with_resolver",
		"LaunchSystem": "initialize_with_resolver",
		"CollisionMaterialSystem": "initialize_with_resolver"
	}
	
	# Initialize each subsystem
	for subsystem_name in subsystems:
		var method_name = subsystems[subsystem_name]
		var subsystem = motion_system.get_subsystem(subsystem_name)
		
		if subsystem and subsystem.has_method(method_name):
			subsystem.call(method_name, _motion_profile_resolver)
			
			if debug_enabled:
				print("GameInitializer: Initialized %s with resolver" % subsystem_name)
		
		# Special case for CollisionMaterialSystem which also needs PhysicsConfig
		if subsystem_name == "CollisionMaterialSystem" and subsystem and subsystem.has_method("set_physics_config"):
			var physics_config = motion_system.get_physics_config()
			if physics_config:
				subsystem.set_physics_config(physics_config)
				
				if debug_enabled:
					print("GameInitializer: Set PhysicsConfig in CollisionMaterialSystem")
			else:
				push_error("GameInitializer: Could not get PhysicsConfig to pass to CollisionMaterialSystem.")

# Get the motion profile resolver
func get_motion_profile_resolver() -> MotionProfileResolver:
	return _motion_profile_resolver

# Set debug mode
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	
	# Update debug mode in resolver if it exists
	if _motion_profile_resolver:
		_motion_profile_resolver.set_debug_enabled(enabled and OS.is_debug_build())
