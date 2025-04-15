extends Node2D

# This is a simple test script to diagnose issues with rock obstacles
# It will manually create and place rock obstacles in the scene

func _ready():
	print("RockObstacleTest: Starting test")
	
	# Wait a short time to ensure the scene is fully loaded
	await get_tree().create_timer(1.0).timeout
	
	# Test creating a rock obstacle
	create_test_rock()

func create_test_rock():
	print("RockObstacleTest: Creating test rock")
	
	# Load the rock obstacle scene
	var rock_scene_path = "res://obstacles/RockObstacle.tscn"
	
	if not ResourceLoader.exists(rock_scene_path):
		push_error("RockObstacleTest: Rock obstacle scene not found at path: %s" % rock_scene_path)
		return
	
	var rock_scene = load(rock_scene_path)
	if not rock_scene is PackedScene:
		push_error("RockObstacleTest: Resource at path is not a PackedScene: %s" % rock_scene_path)
		return
	
	print("RockObstacleTest: Rock scene loaded successfully")
	
	# Create an instance of the rock
	var rock_instance = rock_scene.instantiate()
	
	# Set position to be visible in the scene
	# Position it in front of the player's starting position
	rock_instance.position = Vector2(0, 100)
	
	# Add to the scene tree
	add_child(rock_instance)
	
	print("RockObstacleTest: Rock added to scene at position %s" % str(rock_instance.position))
	
	# Test creating multiple rocks in a pattern
	create_rock_pattern()

func create_rock_pattern():
	print("RockObstacleTest: Creating rock pattern")
	
	# Load the rock obstacle scene
	var rock_scene_path = "res://obstacles/RockObstacle.tscn"
	var rock_scene = load(rock_scene_path)
	
	# Create a pattern of rocks
	for i in range(5):
		var rock_instance = rock_scene.instantiate()
		
		# Position rocks in a diagonal line
		rock_instance.position = Vector2(-100 + i * 50, 200 + i * 50)
		
		# Add to the scene tree
		add_child(rock_instance)
		
		print("RockObstacleTest: Pattern rock %d added at position %s" % [i, str(rock_instance.position)])
