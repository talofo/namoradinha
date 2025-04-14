class_name EnvironmentSystem
extends Node2D

# In Godot 4.4+, resources should be loaded when needed rather than preloaded
# We'll load the default ground config when required

# All these classes are available globally via class_name

signal visuals_updated(theme_id, biome_id)
signal transition_completed
signal fallback_activated(manager_name, reason)

# Configuration
@export var transition_duration: float = 0.5
@export var debug_mode: bool = false
@export var theme_database: ThemeDatabase

# Child components
@onready var ground_manager: GroundVisualManager = $GroundVisualManager
@onready var background_manager = $BackgroundManager
@onready var effects_manager = $EffectsManager

# State tracking
var current_theme_id: String = "default"
var current_biome_id: String = "default"
var current_config: StageConfig = null

# Track transitions
var _pending_transitions = {}
var _active_transition = false

# Resolver reference
var _motion_profile_resolver: MotionProfileResolver = null

func _ready():
    # Connect manager signals
    if ground_manager:
        ground_manager.transition_completed.connect(_on_ground_transition_completed)
        ground_manager.fallback_activated.connect(_on_manager_fallback)
    
    if background_manager:
        background_manager.transition_completed.connect(_on_background_transition_completed)
        background_manager.fallback_activated.connect(_on_manager_fallback)
    
    if effects_manager:
        effects_manager.transition_completed.connect(_on_effects_transition_completed)
        effects_manager.fallback_activated.connect(_on_manager_fallback)
    
    # Connect to global signals
    GlobalSignals.stage_loaded.connect(apply_stage_config)
    GlobalSignals.theme_changed.connect(apply_theme_by_id)
    GlobalSignals.biome_changed.connect(change_biome)
    
    # Connect to GroundManager for position data
    # This will be handled by the chunk instantiation system now
    # Listen for ground_tiles_created signals from any GroundManager that might be added
    # The signal connection will be set up when chunks are instantiated
    
    # Apply default theme
    apply_theme_by_id("default")
    
    # Add debug overlay in debug builds if needed
    if OS.is_debug_build() and debug_mode:
        var debug_overlay_scene = load("res://environment/debug/EnvironmentDebugOverlay.tscn")
        if debug_overlay_scene:
            var debug_overlay = debug_overlay_scene.instantiate()
            debug_overlay.environment_system = self
            add_child(debug_overlay)

func apply_stage_config(config) -> void:
    if !config:
        push_error("EnvironmentSystem: Null config provided")
        return
    
    # Handle StageConfig (from environment system)
    if config is StageConfig:
        current_config = config
        current_theme_id = config.theme_id
        current_biome_id = config.biome_id
    # Handle StageCompositionConfig (from stage composition system)
    elif "theme" in config:
        # Extract theme from StageCompositionConfig
        current_theme_id = config.theme
        current_biome_id = "default"  # Default biome if not specified
    else:
        push_error("EnvironmentSystem: Unknown config type provided")
        return
    
    apply_theme_by_id(current_theme_id)

func apply_theme_by_id(theme_id: String) -> void:
    if !theme_database:
        push_error("EnvironmentSystem: No theme database assigned")
        return
    
    var theme = theme_database.get_theme(theme_id)
    if theme:
        current_theme_id = theme_id
        _apply_theme(theme)
    else:
        push_warning("Theme not found: " + theme_id)

func get_theme_by_id(theme_id: String) -> EnvironmentTheme:
    if theme_database:
        return theme_database.get_theme(theme_id)
    return null

func change_biome(biome_id: String) -> void:
    if current_biome_id == biome_id and _motion_profile_resolver and _motion_profile_resolver._ground_config and _motion_profile_resolver._ground_config.biome_id == biome_id:
        # Avoid redundant updates if biome hasn't actually changed
        return
        
    current_biome_id = biome_id
    
    # Update MotionProfileResolver with the new biome's ground config
    _update_resolver_ground_config(biome_id)
    
    # In the future, biomes might affect theme selection
    # For now, just re-apply the current theme (existing logic)
    apply_theme_by_id(current_theme_id)


## Loads and sets the ground config in the MotionProfileResolver based on biome ID.
func _update_resolver_ground_config(biome_id: String) -> void:
    if not _motion_profile_resolver:
        push_warning("EnvironmentSystem: MotionProfileResolver not available to update ground config.")
        return

    # Construct the expected path for the biome's ground config resource
    var biome_config_path = "res://resources/motion/profiles/ground/%s_ground.tres" % biome_id
    
    var biome_config: GroundPhysicsConfig = null
    if ResourceLoader.exists(biome_config_path):
        biome_config = load(biome_config_path) as GroundPhysicsConfig

    if biome_config:
        _motion_profile_resolver.set_ground_config(biome_config)
        if debug_mode:
            print("EnvironmentSystem: Set ground config for biome '%s'." % biome_id)
    else:
        push_warning("EnvironmentSystem: No GroundPhysicsConfig found for biome '%s' at path '%s'. Falling back to default." % [biome_id, biome_config_path])
        # Fall back to the default config
        var default_config_path = "res://resources/motion/profiles/ground/default_ground.tres"
        if ResourceLoader.exists(default_config_path):
            var default_config = load(default_config_path)
            if default_config:
                _motion_profile_resolver.set_ground_config(default_config)
            else:
                push_error("EnvironmentSystem: DefaultGroundConfig could not be loaded for fallback.")
                _motion_profile_resolver.set_ground_config(null) # Clear config as last resort
        else:
            push_error("EnvironmentSystem: Default ground config not found at '%s'." % default_config_path)
            _motion_profile_resolver.set_ground_config(null) # Clear config as last resort


func _apply_theme(theme: EnvironmentTheme) -> void:
    if !theme:
        push_error("EnvironmentSystem: Null theme provided")
        return
    
    if debug_mode:
        print("EnvironmentSystem: Applying theme: " + theme.theme_id)
    
    # Begin transition tracking
    _start_transition()
    
    # Apply to ground manager
    if ground_manager:
        ground_manager.apply_theme(theme)
    else:
        _on_manager_transition_completed("ground")
    
    # Apply to background manager
    if background_manager:
        background_manager.apply_theme(theme)
    else:
        _on_manager_transition_completed("background")
    
    # Apply to effects manager
    if effects_manager:
        effects_manager.apply_theme(theme)
    else:
        _on_manager_transition_completed("effects")
    
    # Signal that visuals are being updated
    visuals_updated.emit(theme.theme_id, current_biome_id)

func _start_transition() -> void:
    _active_transition = true
    _pending_transitions.clear()
    
    # Register expected transitions
    if ground_manager:
        _pending_transitions["ground"] = true
    if background_manager:
        _pending_transitions["background"] = true
    if effects_manager:
        _pending_transitions["effects"] = true
    
    # If no transitions are expected, immediately complete
    if _pending_transitions.size() == 0:
        _complete_transition()

func _on_ground_transition_completed() -> void:
    _on_manager_transition_completed("ground")

func _on_background_transition_completed() -> void:
    _on_manager_transition_completed("background")

func _on_effects_transition_completed() -> void:
    _on_manager_transition_completed("effects")

func _on_manager_transition_completed(manager_name: String) -> void:
    if _pending_transitions.has(manager_name):
        _pending_transitions.erase(manager_name)
    
    if _pending_transitions.size() == 0 and _active_transition:
        _complete_transition()

func _complete_transition() -> void:
    _active_transition = false
    transition_completed.emit()

func _on_manager_fallback(reason: String) -> void:
    var manager_name = "unknown"
    
    # Determine which manager triggered the fallback
    if reason.begins_with("GroundVisualManager"):
        manager_name = "ground"
    elif reason.begins_with("BackgroundManager"):
        manager_name = "background"
    elif reason.begins_with("EffectsManager"):
        manager_name = "effects"
    
    # For missing textures that don't specify the manager
    if reason.contains("ground texture"):
        manager_name = "ground"
    elif reason.contains("background texture"):
        manager_name = "background"
    
    if debug_mode:
        print("Fallback in " + manager_name + ": " + reason)
    
    fallback_activated.emit(manager_name, reason)

# Handle ground tiles data from physics GroundManager
func _on_ground_tiles_created(ground_data: Array) -> void:
    if ground_manager:
        ground_manager.apply_ground_visuals(ground_data)

# Debug theme switching (development only)
func _unhandled_input(event):
    if OS.is_debug_build() and event is InputEventKey and event.pressed:
        if event.keycode == KEY_1:
            apply_theme_by_id("default")
        elif event.keycode == KEY_2:
            apply_theme_by_id("debug")


# --- Resolver Integration ---

## Called by Game.gd to provide the resolver instance.
func initialize_with_resolver(resolver: MotionProfileResolver) -> void:
    _motion_profile_resolver = resolver
    # Immediately update resolver with the initial biome's config if available
    if current_biome_id:
        _update_resolver_ground_config(current_biome_id)
    else:
        # If no biome set yet, use default
        var default_config_path = "res://resources/motion/profiles/ground/default_ground.tres"
        if ResourceLoader.exists(default_config_path):
            var default_config = load(default_config_path)
            if default_config:
                _motion_profile_resolver.set_ground_config(default_config)
        
    if debug_mode:
        print("EnvironmentSystem: MotionProfileResolver initialized.")
