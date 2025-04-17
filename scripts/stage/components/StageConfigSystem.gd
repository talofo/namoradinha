class_name StageConfigSystem
extends Node

# Import required classes
# In Godot 4.4+, classes with class_name are globally available
# Explicitly load the StageConfigGenerator script
var _generator_script = load("res://scripts/stage/components/StageConfigGenerator.gd")

# Cache of loaded configs
var _config_cache: Dictionary = {}

# Cache of generated configs
var _generated_configs: Dictionary = {}

# Debug flag
var _debug_enabled: bool = false

func _ready():
    pass

# Get a stage config by ID
func get_config(config_id: String) -> StageCompositionConfig:
    # Check cache first
    if _config_cache.has(config_id):
        return _config_cache[config_id]
    
    # Try to load from path
    var config = _load_config(config_id)
    
    # Cache for future use
    if config:
        _config_cache[config_id] = config
    
    return config

# Get a stage config by theme
func get_config_by_theme(theme: String) -> StageCompositionConfig:
    # Try to find a config with the given theme
    var configs_dir = "res://resources/stage/configs/"
    var dir = DirAccess.open(configs_dir)
    
    if not dir:
        push_error("StageConfigSystem: Failed to open configs directory")
        return StageCompositionConfig.get_default_resource()
    
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if not dir.current_is_dir() and file_name.ends_with(".tres"):
            var config_path = configs_dir + file_name
            var config = load(config_path)
            
            if config is StageCompositionConfig and config.theme == theme:
                if config.validate():
                    dir.list_dir_end()
                    return config
        
        file_name = dir.get_next()
    
    dir.list_dir_end()
    
    # If no matching config found, return default
    push_warning("StageConfigSystem: No config found for theme '%s', using default" % theme)
    return StageCompositionConfig.get_default_resource()

# Create a new stage config programmatically
func create_config(id: String, theme: String, difficulty: String = "low") -> StageCompositionConfig:
    var params = {
        "theme": theme,
        "difficulty": difficulty
    }
    
    var generator = _generator_script.new()
    var config = generator.generate_stage_config(params)
    
    # Override the generated ID if one was provided
    if not id.is_empty():
        config.id = id
    
    # Cache the config
    _config_cache[config.id] = config
    
    if _debug_enabled:
        print("StageConfigSystem: Created new config '%s' with theme '%s'" % [config.id, theme])
    
    return config

# Generate a stage config for a specific stage number
func generate_stage_config(stage_number: int) -> StageCompositionConfig:
    # Check if we already have a generated config for this stage
    var cache_key = "stage_%d" % stage_number
    if _generated_configs.has(cache_key):
        return _generated_configs[cache_key]
    
    # Generate a new config
    var generator = _generator_script.new()
    var config = generator.generate_for_stage(stage_number)
    
    # Cache the generated config
    _generated_configs[cache_key] = config
    
    if _debug_enabled:
        print("StageConfigSystem: Generated config for stage %d with difficulty '%s'" % [stage_number, config.target_difficulty])
    
    return config

# Generate a stage config with custom parameters
func generate_custom_stage(params: Dictionary) -> StageCompositionConfig:
    var generator = _generator_script.new()
    var config = generator.generate_stage_config(params)
    
    if _debug_enabled:
        print("StageConfigSystem: Generated custom stage with ID '%s'" % config.id)
    
    return config

# Save a config to disk
func save_config(config: StageCompositionConfig, path: String = "") -> bool:
    if not config:
        push_error("StageConfigSystem: Cannot save null config")
        return false
    
    if not config.validate():
        push_warning("StageConfigSystem: Validation failed for config '%s', saving anyway" % config.id)
    
    # Determine path
    var save_path = path
    if save_path.is_empty():
        save_path = "res://resources/stage/configs/%s.tres" % config.id
    
    # Save the resource
    var result = ResourceSaver.save(config, save_path)
    
    if result != OK:
        push_error("StageConfigSystem: Failed to save config to '%s'" % save_path)
        return false
    
    if _debug_enabled:
        print("StageConfigSystem: Saved config '%s' to '%s'" % [config.id, save_path])
    
    return true

# Load a config from disk
func _load_config(config_id: String) -> StageCompositionConfig:
    # Try to load from path
    var resource_path = "res://resources/stage/configs/%s.tres" % config_id
    
    if ResourceLoader.exists(resource_path):
        var resource = load(resource_path)
        if resource is StageCompositionConfig:
            if resource.validate():
                if _debug_enabled:
                    print("StageConfigSystem: Loaded config '%s'" % config_id)
                return resource
            else:
                push_warning("StageConfigSystem: Validation failed for '%s'" % resource_path)
        else:
            push_error("StageConfigSystem: Resource at '%s' is not a StageCompositionConfig" % resource_path)
    else:
        push_warning("StageConfigSystem: Config not found at '%s'" % resource_path)
    
    # Try default path
    return StageCompositionConfig.get_default_resource()

# List all available config IDs
func list_available_configs() -> Array:
    var config_ids = []
    
    var configs_dir = "res://resources/stage/configs/"
    var dir = DirAccess.open(configs_dir)
    
    if not dir:
        push_error("StageConfigSystem: Failed to open configs directory")
        return config_ids
    
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        if not dir.current_is_dir() and file_name.ends_with(".tres"):
            var config_id = file_name.get_basename()
            config_ids.append(config_id)
        
        file_name = dir.get_next()
    
    dir.list_dir_end()
    
    return config_ids

# Clear the config cache
func clear_cache() -> void:
    _config_cache.clear()
    _generated_configs.clear()
    if _debug_enabled:
        print("StageConfigSystem: Cache cleared")

# Enable/disable debug output
func set_debug_enabled(enabled: bool) -> void:
    _debug_enabled = enabled
