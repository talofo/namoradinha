extends Node2D

# This script creates multiple rock obstacles with different z-index values
# to ensure they're visible regardless of what might be obscuring them

var rocks = []
var current_zoom = 1.0
var zoom_levels = [1.0, 0.5, 0.2]
var zoom_index = 0

func _ready():
	print("VisibleRocksTest: Starting test")
	
	# Wait a short time to ensure the scene is fully loaded
	await get_tree().create_timer(0.5).timeout
	
	# Create rocks at different positions and z-indices
	create_rock_grid()
	
	# Update debug info
	update_debug_info()

func _process(_delta):
	# Check for space key to toggle zoom
	if Input.is_action_just_pressed("ui_accept"):
		toggle_zoom()

func toggle_zoom():
	zoom_index = (zoom_index + 1) % zoom_levels.size()
	current_zoom = zoom_levels[zoom_index]
	
	# Apply zoom to camera
	$Camera2D.zoom = Vector2(current_zoom, current_zoom)
	
	# Update debug info
	update_debug_info()
	
	print("VisibleRocksTest: Zoom set to %f" % current_zoom)

func update_debug_info():
	$DebugInfo.text = "Rock Visibility Test - Current Zoom: %f - Press Space to toggle zoom" % current_zoom

func create_rock_grid():
	print("VisibleRocksTest: Creating rock grid")
	
	# Load the rock obstacle scene
	var rock_scene_path = "res://obstacles/RockObstacle.tscn"
	
	if not ResourceLoader.exists(rock_scene_path):
		push_error("VisibleRocksTest: Rock obstacle scene not found at path: %s" % rock_scene_path)
		return
	
	var rock_scene = load(rock_scene_path)
	if not rock_scene is PackedScene:
		push_error("VisibleRocksTest: Resource at path is not a PackedScene: %s" % rock_scene_path)
		return
	
	print("VisibleRocksTest: Rock scene loaded successfully")
	
	# Create a grid of rocks with different z-index values
	var grid_size = 3
	var spacing = 150
	
	for x in range(grid_size):
		for y in range(grid_size):
			var rock_instance = rock_scene.instantiate()
			
			# Position in grid
			var pos_x = (x - grid_size/2) * spacing
			var pos_y = (y - grid_size/2) * spacing
			rock_instance.position = Vector2(pos_x, pos_y)
			
			# Set z-index based on position (higher z-index = drawn on top)
			var z_index = 10 + x + y
			rock_instance.z_index = z_index
			
			# Add a label to show z-index
			var z_label = Label.new()
			z_label.text = "z=%d" % z_index
			z_label.position = Vector2(-20, -60)
			rock_instance.add_child(z_label)
			
			# Add to the scene tree
			add_child(rock_instance)
			rocks.append(rock_instance)
			
			print("VisibleRocksTest: Rock added at position %s with z-index %d" % [str(rock_instance.position), z_index])
	
	# Create a background rectangle to test if rocks are visible on top of it
	create_background_rectangle()

func create_background_rectangle():
	print("VisibleRocksTest: Creating background rectangle")
	
	# Create a pink rectangle similar to what the user described
	var rect = ColorRect.new()
	rect.size = Vector2(1000, 1000)
	rect.position = Vector2(-500, -500)
	rect.color = Color(1.0, 0.5, 0.5, 0.5)  # Semi-transparent pink
	rect.z_index = 5  # Set z-index lower than rocks
	
	# Add to the scene tree
	add_child(rect)
	
	# Add a label to show it's the background
	var label = Label.new()
	label.text = "Background Rectangle (z=5)"
	label.position = Vector2(0, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = rect.size
	rect.add_child(label)
	
	print("VisibleRocksTest: Background rectangle added with z-index 5")
