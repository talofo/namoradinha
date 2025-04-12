class_name EnvironmentDebugOverlay
extends CanvasLayer

# Class references
const EnvironmentSystem = preload("res://scripts/environment/EnvironmentSystem.gd")

@export var environment_system: EnvironmentSystem

@onready var info_panel = $Control/Panel
@onready var theme_label = $Control/Panel/VBoxContainer/ThemeLabel
@onready var biome_label = $Control/Panel/VBoxContainer/BiomeLabel
@onready var asset_label = $Control/Panel/VBoxContainer/AssetLabel
@onready var theme_buttons = $Control/Panel/VBoxContainer/ThemeButtons
@onready var fallback_label = $Control/Panel/VBoxContainer/FallbackLabel

func _ready():
    # Only enable in debug builds
    if !OS.is_debug_build():
        queue_free()
        return
    
    # Find environment system if not set
    if !environment_system:
        environment_system = get_node_or_null("/root/Game/EnvironmentSystem")
        if !environment_system:
            theme_label.text = "ERROR: EnvironmentSystem not found!"
            return
    
    # Connect to signals
    environment_system.visuals_updated.connect(_on_visuals_updated)
    environment_system.fallback_activated.connect(_on_fallback_activated)
    
    # Create theme buttons
    _create_theme_buttons()
    
    # Initial update
    _update_debug_info()

func _update_debug_info() -> void:
    if !environment_system:
        return
    
    theme_label.text = "Theme: " + environment_system.current_theme_id
    biome_label.text = "Biome: " + environment_system.current_biome_id
    
    # Asset info
    if !environment_system.theme_database:
        asset_label.text = "No theme database available"
        return
        
    var theme = environment_system.theme_database.get_theme(environment_system.current_theme_id)
    if !theme:
        asset_label.text = "No theme data available"
        return
    
    var asset_info = "Assets:"
    asset_info += "\nGround: " + (theme.ground_texture.resource_path if theme.ground_texture else "None")
    
    if theme.use_single_background:
        asset_info += "\nBackground: " + (theme.background_far_texture.resource_path if theme.background_far_texture else "None")
    else:
        asset_info += "\nBG Far: " + (theme.background_far_texture.resource_path if theme.background_far_texture else "None")
        asset_info += "\nBG Mid: " + (theme.background_mid_texture.resource_path if theme.background_mid_texture else "None")
        asset_info += "\nBG Near: " + (theme.background_near_texture.resource_path if theme.background_near_texture else "None")
    
    asset_info += "\nEffects: " + ("Enabled - " + theme.effect_type if theme.enable_effects else "Disabled")
    
    asset_label.text = asset_info

func _on_visuals_updated(_theme_id: String, _biome_id: String) -> void:
    _update_debug_info()

func _on_fallback_activated(manager_name: String, reason: String) -> void:
    # Add fallback info to the debug overlay
    if fallback_label:
        fallback_label.text = "Fallback in " + manager_name + ": " + reason
        fallback_label.modulate = Color(1, 0.5, 0.5)  # Light red

func _create_theme_buttons() -> void:
    # Clear existing buttons
    for child in theme_buttons.get_children():
        child.queue_free()
    
    # Add button for each theme
    if environment_system.theme_database:
        for theme_id in environment_system.theme_database.themes.keys():
            var button = Button.new()
            button.text = theme_id
            button.pressed.connect(func(): environment_system.apply_theme_by_id(theme_id))
            theme_buttons.add_child(button)
    
    # Add a button to test biome changes
    var biome_button = Button.new()
    biome_button.text = "Test Biome"
    biome_button.pressed.connect(func(): environment_system.change_biome("test_biome"))
    theme_buttons.add_child(biome_button)
