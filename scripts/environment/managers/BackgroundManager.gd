class_name BackgroundManager
extends ParallaxBackground

# Both EnvironmentTheme and TransitionHelper are available globally via class_name

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
var _debug_enabled: bool = false

func _ready():
	# Create layers if they don't exist
	if not far_layer:
		far_layer = _create_layer("FarLayer", 0.2)
	if not mid_layer:
		mid_layer = _create_layer("MidLayer", 0.5)
	if not near_layer:
		near_layer = _create_layer("NearLayer", 0.8)

func apply_theme(theme: EnvironmentTheme) -> void:
	if not theme:
		push_error("BackgroundManager: Null theme provided")
		return
	
	current_theme_id = theme.theme_id
	
	# Reset transition tracking
	completed_transitions = 0
	total_transitions = 3  # far, mid, near layers
	
	# Check if textures are missing and create placeholders if needed
	var far_texture = theme.background_far_texture
	var mid_texture = theme.background_mid_texture
	var near_texture = theme.background_near_texture
	
	if not far_texture:
		far_texture = _create_placeholder_texture(Color(0.2, 0.4, 0.8, 1.0), "far")  # Blue sky
		if _debug_enabled:
			print("BackgroundManager: Far texture missing in theme: " + theme.theme_id + " (using placeholder)")
	
	if not mid_texture and not theme.use_single_background:
		mid_texture = _create_placeholder_texture(Color(0.3, 0.5, 0.7, 1.0), "mid")  # Mid-distance blue
		if _debug_enabled:
			print("BackgroundManager: Mid texture missing in theme: " + theme.theme_id + " (using placeholder)")
	
	if not near_texture and not theme.use_single_background:
		near_texture = _create_placeholder_texture(Color(0.4, 0.6, 0.6, 1.0), "near")  # Near-distance blue-green
		if _debug_enabled:
			print("BackgroundManager: Near texture missing in theme: " + theme.theme_id + " (using placeholder)")
	
	# Apply textures based on theme configuration
	if theme.use_single_background:
		# Use far_texture for all layers with different tints
		_apply_layer_texture(far_layer, far_texture, theme.background_tint, theme.parallax_ratio)
		
		var mid_tint = theme.background_tint.darkened(0.1)
		var near_tint = theme.background_tint.darkened(0.2)
		
		_apply_layer_texture(mid_layer, far_texture, mid_tint, theme.parallax_ratio * 1.5)
		_apply_layer_texture(near_layer, far_texture, near_tint, theme.parallax_ratio * 2.0)
	else:
		# Use different textures for each layer
		_apply_layer_texture(far_layer, far_texture, theme.background_tint, theme.parallax_ratio)
		_apply_layer_texture(mid_layer, mid_texture, theme.background_tint, theme.parallax_ratio * 1.5)
		_apply_layer_texture(near_layer, near_texture, theme.background_tint, theme.parallax_ratio * 2.0)

func _create_layer(layer_name: String, motion_scale_value: float) -> ParallaxLayer:
	var parallax_layer = ParallaxLayer.new()
	parallax_layer.name = layer_name
	parallax_layer.motion_scale = Vector2(motion_scale_value, motion_scale_value)
	add_child(parallax_layer)
	return parallax_layer

func _apply_layer_texture(parallax_layer: ParallaxLayer, texture: Texture2D, tint: Color, motion_ratio: Vector2) -> void:
	if not parallax_layer:
		return
	
	parallax_layer.motion_scale = motion_ratio
	
	var sprite = parallax_layer.get_node_or_null("Sprite2D")
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.centered = false
		parallax_layer.add_child(sprite)
	
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

func _create_placeholder_texture(color: Color, layer_name: String) -> Texture2D:
	# Create a simple 128x128 texture with the given color
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	# Add some variation based on the layer
	if layer_name == "far":
		# Add some cloud-like patterns for far background
		for x in range(128):
			for y in range(128):
				var noise_value = sin(x * 0.05) * cos(y * 0.05) * 0.1
				var pixel_color = color.lightened(noise_value)
				image.set_pixel(x, y, pixel_color)
	elif layer_name == "mid":
		# Add some horizontal lines for mid background
		for y in range(128):
			if y % 16 < 8:
				for x in range(128):
					var pixel_color = color.lightened(0.05)
					image.set_pixel(x, y, pixel_color)
	elif layer_name == "near":
		# Add some vertical patterns for near background
		for x in range(128):
			if x % 20 < 10:
				for y in range(128):
					var pixel_color = color.lightened(0.08)
					image.set_pixel(x, y, pixel_color)
	
	return ImageTexture.create_from_image(image)

func _create_fallback_backgrounds() -> void:
	var bg_layers = [far_layer, mid_layer, near_layer]
	var colors = [
		Color(0.2, 0.4, 0.8, 1.0),  # Blue for far
		Color(0.3, 0.5, 0.7, 1.0),  # Mid-blue for mid
		Color(0.4, 0.6, 0.6, 1.0)   # Blue-green for near
	]
	
	for i in range(bg_layers.size()):
		var current_layer = bg_layers[i]
		if not current_layer:
			continue
		
		# Remove existing sprites
		for child in current_layer.get_children():
			child.queue_free()
		
		# Create colored rectangle as fallback
		var fallback = ColorRect.new()
		fallback.name = "Fallback"
		
		# Different shades of blue for different layers
		var alpha = 1.0 - (i * 0.2)  # 1.0, 0.8, 0.6
		fallback.color = colors[i]
		fallback.color.a = alpha
		
		fallback.size = Vector2(1920, 1080)  # Screen size
		
		# Set a very low z-index to ensure it's behind other elements
		fallback.z_index = -100
		
		# Add a label to indicate it's a fallback
		var label = Label.new()
		label.text = "FALLBACK BACKGROUND"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size = fallback.size
		fallback.add_child(label)
		
		current_layer.add_child(fallback)
	
	# Emit fallback signal
	fallback_activated.emit("Using fallback backgrounds due to missing textures")
	
	# No transition to track
	transition_completed.emit()

func _on_transition_completed() -> void:
	completed_transitions += 1
	if completed_transitions >= total_transitions:
		transition_completed.emit()

# Enable/disable debug output
func set_debug_enabled(enabled: bool) -> void:
	_debug_enabled = enabled
