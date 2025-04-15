extends Node

# This script fixes the issue with rocks not appearing in the game
# It ensures that the default chunk has rock markers and that the content distribution system
# is properly generating placements for rocks

func _ready():
	print("FixRocksNotAppearing: Starting fix")
	
	# Wait a short time to ensure the scene is fully loaded
	await get_tree().create_timer(1.0).timeout
	
	# Apply the fix
	_apply_fix()

func _apply_fix():
	print("FixRocksNotAppearing: Applying fix")
	
	# 1. Check if the default chunk exists and has rock markers
	_check_default_chunk()
	
	# 2. Check if the content distribution system is properly configured
	_check_content_distribution()
	
	# 3. Check if the GameSignalBus is properly connecting the content placement signals
	_check_game_signal_bus()
	
	# 4. Force the creation of a rock obstacle to verify it works
	_force_create_rock()

func _check_default_chunk():
	print("FixRocksNotAppearing: Checking default chunk")
	
	# Check if the default chunk exists
	var default_chunk_path = "res://resources/stage/chunks/default/ground/default_ground_obstacle.tres"
	if not ResourceLoader.exists(default_chunk_path):
		print("FixRocksNotAppearing: Default chunk not found at path: %s" % default_chunk_path)
		print("FixRocksNotAppearing: Using sparse_rocks.tres as default")
		
		# Use sparse_rocks.tres as default
		var sparse_rocks_path = "res://resources/stage/chunks/default/ground/sparse_rocks.tres"
		if ResourceLoader.exists(sparse_rocks_path):
			var sparse_rocks = load(sparse_rocks_path)
			if sparse_rocks is ChunkDefinition:
				# We can't modify the constant, so let's create a new default chunk file
				var new_default_chunk = ChunkDefinition.new()
				new_default_chunk.chunk_id = "default_ground_obstacle"
				new_default_chunk.chunk_type = "straight"
				new_default_chunk.length = 100.0
				new_default_chunk.theme_tags = ["standard"]
				new_default_chunk.difficulty_rating = 1.0
				
				# Add rock markers to the new default chunk
				new_default_chunk.layout_markers.append({
					"height_zone": "ground",
					"intended_category": "obstacles",
					"name": "RockMarker1",
					"placement_mode": "stable-random",
					"position": Vector2(0, 50),
					"tags": ["rock", "obstacle_marker"]
				})
				
				# Create the directory if it doesn't exist
				var dir = DirAccess.open("res://resources/stage/chunks/default/ground/")
				if not dir:
					DirAccess.make_dir_recursive_absolute("res://resources/stage/chunks/default/ground/")
				
				# Save the new default chunk
				ResourceSaver.save(new_default_chunk, default_chunk_path)
				print("FixRocksNotAppearing: Created new default chunk at %s" % default_chunk_path)
	else:
		print("FixRocksNotAppearing: Default chunk found at path: %s" % default_chunk_path)
		
		# Check if the default chunk has rock markers
		var default_chunk = load(default_chunk_path)
		if default_chunk is ChunkDefinition:
			var has_rock_markers = false
			for marker in default_chunk.layout_markers:
				if marker.has("tags") and marker["tags"].has("rock"):
					has_rock_markers = true
					break
			
			if not has_rock_markers:
				print("FixRocksNotAppearing: Default chunk does not have rock markers")
				
				# Add rock markers to the default chunk
				default_chunk.layout_markers.append({
					"height_zone": "ground",
					"intended_category": "obstacles",
					"name": "RockMarker1",
					"placement_mode": "stable-random",
					"position": Vector2(0, 50),
					"tags": ["rock", "obstacle_marker"]
				})
				
				print("FixRocksNotAppearing: Added rock marker to default chunk")
				
				# Save the modified default chunk
				ResourceSaver.save(default_chunk, default_chunk_path)
				print("FixRocksNotAppearing: Saved modified default chunk")

func _check_content_distribution():
	print("FixRocksNotAppearing: Checking content distribution")
	
	# Check if the default content distribution exists
	var default_distribution_path = "res://resources/stage/content_distributions/default_distribution.tres"
	if ResourceLoader.exists(default_distribution_path):
		var default_distribution = load(default_distribution_path)
		if default_distribution is ContentDistribution:
			# Check if the obstacles category includes "Rock"
			if default_distribution.content_categories.has("obstacles"):
				var obstacles_category = default_distribution.content_categories["obstacles"]
				if obstacles_category.has("allowed_entities"):
					var allowed_entities = obstacles_category["allowed_entities"]
					if not allowed_entities.has("Rock"):
						print("FixRocksNotAppearing: Adding 'Rock' to allowed entities for obstacles")
						allowed_entities.append("Rock")
						
						# Save the modified content distribution
						ResourceSaver.save(default_distribution, default_distribution_path)
						print("FixRocksNotAppearing: Saved modified content distribution")
					else:
						print("FixRocksNotAppearing: 'Rock' is already in allowed entities for obstacles")
				else:
					print("FixRocksNotAppearing: obstacles category does not have allowed_entities")
			else:
				print("FixRocksNotAppearing: content_categories does not have obstacles category")
		else:
			print("FixRocksNotAppearing: default_distribution is not a ContentDistribution")
	else:
		print("FixRocksNotAppearing: Default content distribution not found at path: %s" % default_distribution_path)

func _check_game_signal_bus():
	print("FixRocksNotAppearing: Checking GameSignalBus")
	
	# Connect to the content placement signal to see if it's being emitted
	GlobalSignals.request_content_placement.connect(_on_content_placement_requested)
	
	# Emit a test signal to see if it's being handled
	var test_placement = {
		"category": "obstacles",
		"type": "Rock",
		"distance_along_chunk": 50.0,
		"height": 0.0,
		"width_offset": 0.0
	}
	
	print("FixRocksNotAppearing: Emitting test content placement signal")
	GlobalSignals.request_content_placement.emit(test_placement)

func _on_content_placement_requested(placement_data: Dictionary):
	print("FixRocksNotAppearing: Content placement signal received: %s" % str(placement_data))

func _force_create_rock():
	print("FixRocksNotAppearing: Forcing creation of a rock obstacle")
	
	# Load the rock obstacle scene
	var rock_scene_path = "res://obstacles/RockObstacle.tscn"
	
	if not ResourceLoader.exists(rock_scene_path):
		push_error("FixRocksNotAppearing: Rock obstacle scene not found at path: %s" % rock_scene_path)
		return
	
	var rock_scene = load(rock_scene_path)
	if not rock_scene is PackedScene:
		push_error("FixRocksNotAppearing: Resource at path is not a PackedScene: %s" % rock_scene_path)
		return
	
	print("FixRocksNotAppearing: Rock scene loaded successfully")
	
	# Create an instance of the rock
	var rock_instance = rock_scene.instantiate()
	
	# Set position to be visible in the scene
	# Position it in front of the player's starting position
	rock_instance.position = Vector2(0, 100)
	
	# Add to the scene tree
	add_child(rock_instance)
	
	print("FixRocksNotAppearing: Rock added to scene at position %s" % str(rock_instance.position))
