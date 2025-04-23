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
@onready var effects_manager = $EffectsManager
@onready var visual_background_system = $VisualBackgroundSystem

# Ground management
var shared_ground_manager = null

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
    
    if effects_manager:
        effects_manager.transition_completed.connect(_on_effects_transition_completed)
        effects_manager.fallback_activated.connect(_on_manager_fallback)
    
    if visual_background_system:
        visual_background_system.transition_completed.connect(_on_background_transition_completed)
    
    # Connect to global signals
    GlobalSignals.stage_loaded.connect(apply_stage_config)
    GlobalSignals.theme_changed.connect(apply_theme_by_id)
    GlobalSignals.biome_changed.connect(change_biome)
    
    # Apply default theme
    apply_theme_by_id("default")
    
    # Add debug overlay in debug builds if needed
    if OS.is_debug_build() and debug_mode:
        var debug_overlay_scene = load("res://environment/debug/EnvironmentDebugOverlay.tscn")
        if debug_overlay_scene:
            var debug_overlay = debug_overlay_scene.instantiate()
            debug_overlay.environment_system = self
            add_child(debug_overlay)
        
        # Enable debug logging for this system
        Debug.toggle_system("ENVIRONMENT", true)

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

func get_theme_database() -> ThemeDatabase:
    return theme_database

func change_biome(biome_id: String) -> void:
    if current_biome_id == biome_id and _motion_profile_resolver and _motion_profile_resolver._ground_config and _motion_profile_resolver._ground_config.biome_id == biome_id:
        # Avoid redundant updates if biome hasn't actually changed
        return
        
    current_biome_id = biome_id
    
    # Update MotionProfileResolver with the new biome's ground config
    if _motion_profile_resolver:
        _motion_profile_resolver.update_ground_config_for_biome(biome_id)
    else:
        push_warning("EnvironmentSystem: MotionProfileResolver not available to update ground config for biome '%s'." % biome_id)
    
    # In the future, biomes might affect theme selection
    # For now, just re-apply the current theme (existing logic)
    apply_theme_by_id(current_theme_id)


func _apply_theme(theme: EnvironmentTheme) -> void:
    if !theme:
        push_error("EnvironmentSystem: Null theme provided")
        return
    
    Debug.print("ENVIRONMENT", "Applying theme:", theme.theme_id)
    
    # Begin transition tracking
    _start_transition()
    
    # Apply to ground manager
    if ground_manager:
        ground_manager.apply_theme(theme)
    else:
        _on_manager_transition_completed("ground")
    
    # Apply to visual background system
    if visual_background_system:
        var visual_bg_theme = _get_visual_background_theme(theme.theme_id)
        if visual_bg_theme:
            visual_background_system.apply_theme(visual_bg_theme)
        # The visual_background_system will emit its own transition_completed signal
    else:
        _on_manager_transition_completed("background")
    
    # Apply to effects manager
    if effects_manager:
        effects_manager.apply_theme(theme)
    else:
        _on_manager_transition_completed("effects")
    
    # Signal that visuals are being updated
    visuals_updated.emit(theme.theme_id, current_biome_id)

# Get the visual background theme configuration
func _get_visual_background_theme(theme_id: String) -> Resource:
    if theme_database:
        return theme_database.get_visual_background_theme(theme_id)
    return null

func _start_transition() -> void:
    _active_transition = true
    _pending_transitions.clear()
    
    # Register expected transitions
    if ground_manager:
        _pending_transitions["ground"] = true
    if visual_background_system:
        _pending_transitions["background"] = true
    if effects_manager:
        _pending_transitions["effects"] = true
    
    # If no transitions are expected, immediately complete
    if _pending_transitions.size() == 0:
        _complete_transition()

func _on_ground_transition_completed() -> void:
    _on_manager_transition_completed("ground")

func _on_effects_transition_completed() -> void:
    _on_manager_transition_completed("effects")

func _on_background_transition_completed() -> void:
    _on_manager_transition_completed("background")

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
    elif reason.begins_with("EffectsManager"):
        manager_name = "effects"
    
    # For missing textures that don't specify the manager
    if reason.contains("ground texture"):
        manager_name = "ground"
    
    Debug.print("ENVIRONMENT", "Fallback in " + manager_name + ":", reason)
    
    fallback_activated.emit(manager_name, reason)

# Debug theme switching (development only)
func _unhandled_input(event):
    if OS.is_debug_build() and event is InputEventKey and event.pressed:
        if event.keycode == KEY_1:
            apply_theme_by_id("default")
        elif event.keycode == KEY_2:
            apply_theme_by_id("debug")


# --- Ground Management ---

# Create and initialize the shared ground manager
func create_shared_ground_manager() -> Node:
    if shared_ground_manager:
        return shared_ground_manager
    
    # Load the SharedGroundManager script
    var ground_manager_script = load("res://scripts/environment/ground/SharedGroundManager.gd")
    if not ground_manager_script:
        push_error("EnvironmentSystem: Failed to load SharedGroundManager script")
        return null
    
    # Create a new SharedGroundManager
    shared_ground_manager = ground_manager_script.new(self)
    shared_ground_manager.set_debug_enabled(debug_mode)
    
    Debug.print("ENVIRONMENT", "Created SharedGroundManager")
    
    return shared_ground_manager

# Create a shared ground for the entire level
func create_shared_ground(parent_node: Node) -> Node:
    if not shared_ground_manager:
        create_shared_ground_manager()
    
    if shared_ground_manager:
        var ground = shared_ground_manager.create_shared_ground(parent_node)
        
        Debug.print("ENVIRONMENT", "Created shared ground")
        
        return ground
    
    push_error("EnvironmentSystem: Failed to create shared ground - SharedGroundManager not available")
    return null

# --- Resolver Integration ---

## Called by Game.gd to provide the resolver instance.
func initialize_with_resolver(resolver: MotionProfileResolver) -> void:
    _motion_profile_resolver = resolver
    # Immediately update resolver with the initial biome's config if available
    # If no biome set yet, update_ground_config_for_biome will handle fallback to default
    _motion_profile_resolver.update_ground_config_for_biome(current_biome_id if current_biome_id else "default")
        
    Debug.print("ENVIRONMENT", "MotionProfileResolver initialized")
