class_name EnvironmentSystem
extends Node2D

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
    # Find the GroundManager in the current stage
    var stage_manager = get_node_or_null("/root/Game/StageManager")
    if stage_manager and stage_manager.current_stage:
        var ground_manager_physics = stage_manager.current_stage.find_child("GroundManager", true, false)
        if ground_manager_physics and ground_manager_physics.has_signal("ground_tiles_created"):
            ground_manager_physics.ground_tiles_created.connect(_on_ground_tiles_created)
    
    # Apply default theme
    apply_theme_by_id("default")
    
    # Add debug overlay in debug builds if needed
    if OS.is_debug_build() and debug_mode:
        var debug_overlay_scene = load("res://environment/debug/EnvironmentDebugOverlay.tscn")
        if debug_overlay_scene:
            var debug_overlay = debug_overlay_scene.instantiate()
            debug_overlay.environment_system = self
            add_child(debug_overlay)

func apply_stage_config(config: StageConfig) -> void:
    if !config:
        push_error("EnvironmentSystem: Null StageConfig provided")
        return
    
    current_config = config
    current_theme_id = config.theme_id
    current_biome_id = config.biome_id
    
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
    current_biome_id = biome_id
    
    # In the future, biomes might affect theme selection
    # For now, just re-apply the current theme
    apply_theme_by_id(current_theme_id)

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
