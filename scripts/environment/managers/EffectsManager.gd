class_name EffectsManager
extends Node2D

# Both EnvironmentTheme and TransitionHelper are available globally via class_name

signal transition_completed
signal fallback_activated(reason)

# Effect types
const EFFECT_FOG = "fog"
const EFFECT_PARTICLES = "particles"
const EFFECT_OVERLAY = "overlay"

@export var transition_duration: float = 0.5

var active_effects = {}
var active_tween: Tween = null
var current_theme_id: String = ""

func apply_theme(theme: EnvironmentTheme) -> void:
    if !theme:
        push_error("EffectsManager: Null theme provided")
        return
    
    current_theme_id = theme.theme_id
    
    # Clear existing effects with transition
    _transition_out_effects()
    
    # Skip if effects are disabled in theme
    if !theme.enable_effects:
        # Clear any existing effects
        for child in get_children():
            child.queue_free()
        active_effects.clear()
        transition_completed.emit()
        return
    
    # Create effects based on theme
    match theme.effect_type:
        EFFECT_FOG:
            _create_fog_effect(theme)
        EFFECT_PARTICLES:
            _create_particle_effect(theme)
        EFFECT_OVERLAY:
            _create_overlay_effect(theme)
        _:
            fallback_activated.emit("Unknown effect type: " + theme.effect_type)
            transition_completed.emit()  # No effect to create

func _transition_out_effects() -> void:
    if get_child_count() == 0:
        return
    
    # Fade out all existing effects
    if active_tween and active_tween.is_valid():
        active_tween.kill()
    
    var effects_to_remove = []
    for effect in get_children():
        effects_to_remove.append(effect)
    
    if effects_to_remove.size() > 0:
        var tween = create_tween()
        
        for effect in effects_to_remove:
            tween.parallel().tween_property(effect, "modulate:a", 0.0, transition_duration)
        
        tween.tween_callback(func():
            for effect in effects_to_remove:
                effect.queue_free()
            active_effects.clear()
        )
    else:
        active_effects.clear()

func _create_fog_effect(_theme: EnvironmentTheme) -> void:
    var fog = ColorRect.new()
    fog.name = "FogEffect"
    fog.color = Color(1, 1, 1, 0.2)  # Translucent white
    fog.size = Vector2(1920, 1080)   # Screen size
    fog.position = Vector2(-960, -540)  # Center it
    fog.modulate.a = 0.0  # Start transparent
    
    add_child(fog)
    active_effects[EFFECT_FOG] = fog
    
    var tween = create_tween()
    tween.tween_property(fog, "modulate:a", 1.0, transition_duration)
    tween.tween_callback(func(): transition_completed.emit())

func _create_particle_effect(_theme: EnvironmentTheme) -> void:
    var particles = GPUParticles2D.new()
    particles.name = "ParticleEffect"
    
    # Set up basic particles
    var particle_material = ParticleProcessMaterial.new()
    particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    particle_material.emission_box_extents = Vector3(960, 10, 1)
    particle_material.direction = Vector3(0, -1, 0)
    particle_material.spread = 10.0
    particle_material.gravity = Vector3(0, 9.8, 0)
    particle_material.initial_velocity_min = 20.0
    particle_material.initial_velocity_max = 40.0
    particle_material.scale_min = 2.0
    particle_material.scale_max = 4.0
    particle_material.color = Color(1, 1, 1, 0.8)
    
    particles.process_material = particle_material
    particles.amount = 100
    particles.lifetime = 5.0
    particles.modulate.a = 0.0  # Start transparent
    
    add_child(particles)
    active_effects[EFFECT_PARTICLES] = particles
    
    var tween = create_tween()
    tween.tween_property(particles, "modulate:a", 1.0, transition_duration)
    tween.tween_callback(func(): transition_completed.emit())

func _create_overlay_effect(_theme: EnvironmentTheme) -> void:
    var overlay = ColorRect.new()
    overlay.name = "OverlayEffect"
    overlay.color = Color(0.2, 0.2, 0.8, 0.1)  # Slight blue tint
    overlay.size = Vector2(1920, 1080)   # Screen size
    overlay.position = Vector2(-960, -540)  # Center
    overlay.modulate.a = 0.0  # Start transparent
    
    add_child(overlay)
    active_effects[EFFECT_OVERLAY] = overlay
    
    var tween = create_tween()
    tween.tween_property(overlay, "modulate:a", 1.0, transition_duration)
    tween.tween_callback(func(): transition_completed.emit())

func _create_custom_effect(theme: EnvironmentTheme) -> void:
    if !theme.effect_scene:
        fallback_activated.emit("Custom effect specified but no effect_scene provided")
        transition_completed.emit()
        return
    
    var effect = theme.effect_scene.instantiate()
    if !effect:
        fallback_activated.emit("Failed to instantiate custom effect")
        transition_completed.emit()
        return
    
    effect.modulate.a = 0.0  # Start transparent
    add_child(effect)
    active_effects["custom"] = effect
    
    var tween = create_tween()
    tween.tween_property(effect, "modulate:a", 1.0, transition_duration)
    tween.tween_callback(func(): transition_completed.emit())
