class_name ParallaxLayerController
extends ParallaxBackground

# Configuration
@export var performance_monitoring: bool = true
@export var recommended_layer_count: int = 7  # Performance guideline from brief, NOT a hard limit
@export var debug_mode: bool = false

# Performance tracking
var texture_memory_usage: float = 0  # Estimate in MB
var active_layer_count: int = 0
var draw_call_estimate: int = 0

# Internal tracking
var active_layers = {}  # Dictionary to track created layers by name

func build_layers(layer_configs: Array, initial_position: Vector2 = Vector2.ZERO):
	# Reset performance counters
	texture_memory_usage = 0
	active_layer_count = 0
	draw_call_estimate = 0
	
	# Set the initial scroll offset based on the initial camera position
	scroll_offset = initial_position
	
	# Process each layer config
	for config in layer_configs:
		# Skip if invalid config
		if not config:
			continue
			
		# Create parallax layer
		var parallax_layer = ParallaxLayer.new()
		parallax_layer.motion_scale = config.parallax_ratio
		parallax_layer.z_index = config.z_index
		parallax_layer.name = "Layer_" + str(config.layer_name)
		
		# Get the viewport size (needed for potential future use, keep it for now)
		var viewport_size = get_viewport().get_visible_rect().size

		# Process each element in the layer
		for element in config.elements:
			# Skip if invalid element
			if not element or not element.texture:
				continue
				
			# Create sprite for this element
			var sprite = Sprite2D.new()
			sprite.texture = element.texture
			
			# Calculate sprite position relative to the ParallaxLayer origin (0,0)
			# Position the sprite so its center aligns horizontally with the texture center,
			# and its bottom edge aligns vertically with the layer's origin (y=0).
			var sprite_position = element.offset # Start with the element's defined offset
			if element.texture:
				var texture_size = element.texture.get_size() * element.scale
				sprite_position.x += texture_size.x / 2.0 # Center horizontally
				sprite_position.y += texture_size.y / 2.0 # Align bottom edge to y=0

				# Set motion mirroring for horizontal tiling using the texture width
				# This applies to ALL layers, including ground, ensuring they tile correctly.
				parallax_layer.motion_mirroring.x = element.texture.get_width()
				# Ensure vertical mirroring is off unless specified otherwise (though not typical for backgrounds)
				# parallax_layer.motion_mirroring.y = 0 # Default is 0, so explicit set might not be needed

				# Add a debug print to show the sprite position and mirroring
				print("[ParallaxLayerController] Element positioned at: ", sprite_position,
					" (texture size: ", texture_size, ", layer: ", config.layer_name, ")",
					" Mirroring.x: ", parallax_layer.motion_mirroring.x)

			sprite.position = sprite_position
			sprite.scale = element.scale
			sprite.modulate = element.modulate
			sprite.z_index = element.z_index
			print("[ParallaxLayerController]   Creating Sprite2D for element with texture: ", element.texture.resource_path if element.texture else "None",
				"\n      - Final Position: ", sprite.position,
				"\n      - Base offset: ", element.offset,
				"\n      - Layer type: ", config.layer_name,
				"\n      - Parallax ratio: ", config.parallax_ratio,
				"\n      - Mirroring: ", parallax_layer.motion_mirroring) # DEBUG PRINT

			# Track approximate texture memory (very rough estimate)
			if element.texture:
				var tex_size = element.texture.get_width() * element.texture.get_height() * 4  # 4 bytes per pixel (RGBA)
				texture_memory_usage += tex_size / (1024 * 1024)  # Convert to MB
			
			# Estimate draw calls (very rough)
			draw_call_estimate += 1

			# Tiling is now handled by ParallaxLayer.motion_mirroring set earlier.
			# The old Sprite2D region/repeat logic is removed.

			# Add sprite to layer
			parallax_layer.add_child(sprite)
		
		# Add the layer to the parallax background
		add_child(parallax_layer)
		active_layer_count += 1
		
		# Track this layer
		active_layers[config.layer_name] = parallax_layer
		
	# Performance monitoring (if enabled)
	if performance_monitoring:
		# Check against performance guidelines
		if active_layer_count > recommended_layer_count:
			push_warning("Performance Warning: Using %d active layers (recommended: %d)" % [active_layer_count, recommended_layer_count])
		
		if texture_memory_usage > 12.0:  # 12MB guideline from brief
			push_warning("Performance Warning: Estimated texture memory usage is %.2f MB (recommended: 12 MB)" % texture_memory_usage)
			
		if draw_call_estimate > 15:  # 15 draw calls guideline from brief
			push_warning("Performance Warning: Estimated draw calls per frame: %d (recommended: 15)" % draw_call_estimate)
		
		if debug_mode:
			print("Background System Stats - Layers: %d, Memory: %.2f MB, Draw Calls: %d" % 
				[active_layer_count, texture_memory_usage, draw_call_estimate])

func clear_layers():
	# Remove all existing parallax layers
	for child in get_children():
		if child is ParallaxLayer:
			child.queue_free()
	
	# Clear our tracking dictionary
	active_layers.clear()
	
	# Reset counters
	active_layer_count = 0
	texture_memory_usage = 0
	draw_call_estimate = 0

func update_scroll(camera_position: Vector2):
	# Update the scroll offset based on camera position
	# ParallaxBackground handles the differential scrolling automatically based on each layer's motion_scale
	# This works in conjunction with our initial layer positioning to maintain proper parallax effect
	scroll_offset = camera_position
