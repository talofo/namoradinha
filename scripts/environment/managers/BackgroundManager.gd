class_name BackgroundManager
extends ParallaxBackground

# Class references
const EnvironmentTheme = preload("res://resources/environment/EnvironmentTheme.gd")
const TransitionHelper = preload("res://scripts/environment/utils/TransitionHelper.gd")

signal transition_completed
signal fallback_activated(reason)

@export var transition_duration: float = 0.5

# Layers
@onready var far_layer = $FarLayer
@onready var mid_layer = $MidLayer
@onready var near_layer = $NearLayer

# Tracking
var active_tweens = []
var completed_transitions = 0
var total_transitions = 0
var current_theme_id: String = ""

func _ready():
    # Create layers if they don't exist
    if !far_layer:
        far_layer = _create_layer("FarLayer", 0.2)
    if !mid_layer:
        mid_layer = _create_layer("MidLayer", 0.5)
    if !near_layer:
        near_layer = _create_layer("NearLayer", 0.8)

func apply_theme(theme: EnvironmentTheme) -> void:
    if !theme:
        push_error("BackgroundManager: Null theme provided")
        return
    
    current_theme_id = theme.theme_id
    
    var missing_textures = false
    if theme.use_single_background and !theme.background_far_texture:
        missing_textures = true
    elif !theme.use_single_background and (!theme.background_far_texture or 
                                           !theme.background_mid_texture or 
                                           !theme.background_near_texture):
        missing_textures = true
        
    if missing_textures:
        push_warning("Background texture(s) missing in theme: " + theme.theme_id)
        _create_fallback_backgrounds()
        fallback_activated.emit("Missing background texture(s) in theme: " + theme.theme_id)
        return
    
    # Reset transition tracking
    completed_transitions = 0
    total_transitions = 3  # far, mid, near layers
    
    # Apply textures based on theme configuration
    if theme.use_single_background:
        # Use background_far_texture for all layers with different tints
        _apply_layer_texture(far_layer, theme.background_far_texture, theme.background_tint, theme.parallax_ratio)
        
        var mid_tint = theme.background_tint.darkened(0.1)
        var near_tint = theme.background_tint.darkened(0.2)
        
        _apply_layer_texture(mid_layer, theme.background_far_texture, mid_tint, theme.parallax_ratio * 1.5)
        _apply_layer_texture(near_layer, theme.background_far_texture, near_tint, theme.parallax_ratio * 2.0)
    else:
        # Use different textures for each layer
        _apply_layer_texture(far_layer, theme.background_far_texture, theme.background_tint, theme.parallax_ratio)
        
        var mid_texture = theme.background_mid_texture if theme.background_mid_texture else theme.background_far_texture
        var near_texture = theme.background_near_texture if theme.background_near_texture else theme.background_far_texture
        
        _apply_layer_texture(mid_layer, mid_texture, theme.background_tint, theme.parallax_ratio * 1.5)
        _apply_layer_texture(near_layer, near_texture, theme.background_tint, theme.parallax_ratio * 2.0)

func _create_layer(name: String, motion_scale_value: float) -> ParallaxLayer:
    var layer = ParallaxLayer.new()
    layer.name = name
    layer.motion_scale = Vector2(motion_scale_value, motion_scale_value)
    add_child(layer)
    return layer

func _apply_layer_texture(layer: ParallaxLayer, texture: Texture2D, tint: Color, motion_ratio: Vector2) -> void:
    if !layer:
        return
    
    layer.motion_scale = motion_ratio
    
    var sprite = layer.get_node_or_null("Sprite2D")
    if !sprite:
        sprite = Sprite2D.new()
        sprite.name = "Sprite2D"
        sprite.centered = false
        layer.add_child(sprite)
    
    # Transition to new texture
    _transition_sprite_texture(sprite, texture, tint)

func _transition_sprite_texture(sprite: Sprite2D, new_texture: Texture2D, new_tint: Color) -> void:
    # If sprite already has the same texture, just update tint
    if sprite.texture == new_texture:
        sprite.modulate = new_tint
        _on_transition_completed()
        return
    
    # Create new sprite for transition
    var new_sprite = Sprite2D.new()
    new_sprite.texture = new_texture
    new_sprite.modulate = new_tint
    new_sprite.modulate.a = 0.0  # Start transparent
    new_sprite.position = Vector2(0, 0)
    new_sprite.centered = false
    sprite.get_parent().add_child(new_sprite)
    
    # Use helper for transition
    var tween = TransitionHelper.fade_transition(
        sprite, 
        new_sprite, 
        transition_duration,
        func():
            sprite.queue_free()
            new_sprite.name = "Sprite2D"
            _on_transition_completed()
    )
    
    active_tweens.append(tween)

func _create_fallback_backgrounds() -> void:
    var layers = [far_layer, mid_layer, near_layer]
    
    for i in range(layers.size()):
        var layer = layers[i]
        if !layer:
            continue
        
        # Remove existing sprites
        for child in layer.get_children():
            child.queue_free()
        
        # Create colored rectangle as fallback
        var fallback = ColorRect.new()
        fallback.name = "Fallback"
        
        # Different shades of magenta for different layers
        var alpha = 1.0 - (i * 0.2)  # 1.0, 0.8, 0.6
        fallback.color = Color(1, 0, 1, alpha)  # Magenta with varying alpha
        
        fallback.size = Vector2(1920, 1080)  # Screen size
        layer.add_child(fallback)
    
    # No transition to track
    transition_completed.emit()

func _on_transition_completed() -> void:
    completed_transitions += 1
    if completed_transitions >= total_transitions:
        transition_completed.emit()
