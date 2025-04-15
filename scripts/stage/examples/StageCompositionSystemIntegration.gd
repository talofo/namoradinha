extends Node
# Example script showing how to integrate the Stage Composition System into a game

# Import required classes
# In Godot 4.4+, classes with class_name are globally available

# --- Core Systems ---
@onready var stage_composition_system = $StageCompositionSystem
@onready var motion_system = $MotionSystem
@onready var environment_system = $EnvironmentSystem
@onready var player_character = $PlayerCharacter

# --- Game State ---
var current_game_mode = "story"
var current_stage_id = "default_stage"

func _ready():
    # Initialize the Stage Composition System
    initialize_stage_composition_system()
    
    # Connect to signals
    connect_signals()
    
    # Start the game
    start_game()

func _process(delta):
    # Update player position in the Stage Composition System
    if player_character and stage_composition_system:
        stage_composition_system.update_player_position(player_character.global_position)
        
        # Record performance metrics
        if player_character.has_method("get_velocity"):
            var speed = player_character.get_velocity().length()
            stage_composition_system.record_performance_event(
                FlowAndDifficultyController.PerformanceMetric.PLAYER_SPEED,
                speed
            )

# Initialize the Stage Composition System
func initialize_stage_composition_system():
    if not stage_composition_system:
        push_error("StageCompositionSystemIntegration: StageCompositionSystem not found")
        return
    
    # Initialize with motion profile resolver
    if motion_system and motion_system.has_method("get_motion_profile_resolver"):
        var resolver = motion_system.get_motion_profile_resolver()
        if resolver:
            stage_composition_system.initialize_with_resolver(resolver)
    
    # Set the player node for tracking
    if player_character:
        stage_composition_system.set_player_node(player_character)
    
    # Enable debug mode in development builds
    if OS.is_debug_build():
        stage_composition_system.set_debug_enabled(true)

# Connect to signals
func connect_signals():
    # Connect to Stage Composition System signals
    GlobalSignals.stage_loaded.connect(_on_stage_loaded)
    GlobalSignals.stage_generation_failed.connect(_on_stage_generation_failed)
    GlobalSignals.story_stage_completed.connect(_on_story_stage_completed)
    GlobalSignals.biome_changed.connect(_on_biome_change_detected)
    GlobalSignals.request_chunk_instantiation.connect(_on_request_chunk_instantiation)
    GlobalSignals.request_content_placement.connect(_on_request_content_placement)
    
    # Connect to player signals
    if player_character:
        if player_character.has_signal("collectible_collected"):
            player_character.collectible_collected.connect(_on_collectible_collected)
        if player_character.has_signal("obstacle_hit"):
            player_character.obstacle_hit.connect(_on_obstacle_hit)
        if player_character.has_signal("boost_used"):
            player_character.boost_used.connect(_on_boost_used)

# Start the game
func start_game():
    # Generate the initial stage
    if stage_composition_system:
        stage_composition_system.generate_stage(current_stage_id, current_game_mode)

# Handle stage loaded event
func _on_stage_loaded(config):
    print("Stage ready: %s" % config.id)
    
    # Update environment system with the stage theme
    if environment_system and environment_system.has_method("apply_theme_by_id"):
        environment_system.apply_theme_by_id(config.theme)
    
    # Handle launch event type
    match config.launch_event_type:
        "player_start":
            # Player starts automatically
            pass
        "npc_kick":
            # Trigger an NPC to kick the player
            GlobalSignals.gameplay_event_triggered.emit("npc_kick", {})
        "automatic":
            # Apply an initial impulse to the player
            if player_character and player_character.has_method("apply_impulse"):
                player_character.apply_impulse(Vector3(0, 0, 10))

# Handle stage generation failed event
func _on_stage_generation_failed(reason):
    push_error("Stage generation failed: %s" % reason)
    
    # Fallback to default stage
    if stage_composition_system and current_stage_id != "default_stage":
        current_stage_id = "default_stage"
        stage_composition_system.generate_stage(current_stage_id, current_game_mode)

# Handle story stage completed event
func _on_story_stage_completed(stage_id):
    print("Story stage completed: %s" % stage_id)
    
    # Show interstitial UI
    # ...
    
    # Load next stage (example logic)
    var next_stage_id = get_next_stage_id(stage_id)
    if next_stage_id:
        current_stage_id = next_stage_id
        stage_composition_system.generate_stage(current_stage_id, current_game_mode)

# Handle biome change detected event
func _on_biome_change_detected(old_biome, new_biome):
    print("Biome changed from %s to %s" % [old_biome, new_biome])
    
    # Update environment system with the new biome
    if environment_system and environment_system.has_method("change_biome"):
        environment_system.change_biome(new_biome)

# Handle request chunk instantiation event
func _on_request_chunk_instantiation(chunk_definition, position):
    # Instantiate the chunk
    # This would typically involve loading a scene or creating objects
    # For example:
    var chunk_scene = load("res://stage/chunks/%s.tscn" % chunk_definition.chunk_id)
    if chunk_scene:
        var chunk_instance = chunk_scene.instantiate()
        chunk_instance.global_position = position
        add_child(chunk_instance)
    else:
        # Fallback to a default chunk
        var default_chunk_scene = load("res://stage/chunks/default_chunk.tscn")
        if default_chunk_scene:
            var chunk_instance = default_chunk_scene.instantiate()
            chunk_instance.global_position = position
            add_child(chunk_instance)

# Handle request content placement event
func _on_request_content_placement(placement_data: Dictionary):
    # Extract values from the placement dictionary
    var content_category = placement_data["category"]
    var content_type = placement_data["type"]
    var distance = placement_data["distance_along_chunk"]
    var height = placement_data["height"]
    
    # Create a 2D position from distance and height
    var position = Vector2(distance, height)
    
    # Instantiate the content
    # This would typically involve loading a scene or creating objects
    # For example:
    var content_scene = load("res://stage/content/%s/%s.tscn" % [content_category, content_type])
    if content_scene:
        var content_instance = content_scene.instantiate()
        content_instance.global_position = position
        add_child(content_instance)

# Handle collectible collected event
func _on_collectible_collected(collectible_type):
    # Record the performance event
    if stage_composition_system:
        stage_composition_system.record_performance_event(
            FlowAndDifficultyController.PerformanceMetric.COLLECTIBLE_COLLECTION_RATE,
            1.0
        )

# Handle obstacle hit event
func _on_obstacle_hit(obstacle_type):
    # Record the performance event
    if stage_composition_system:
        stage_composition_system.record_performance_event(
            FlowAndDifficultyController.PerformanceMetric.OBSTACLE_COLLISION_RATE,
            1.0
        )

# Handle boost used event
func _on_boost_used(boost_type):
    # Record the performance event
    if stage_composition_system:
        stage_composition_system.record_performance_event(
            FlowAndDifficultyController.PerformanceMetric.BOOST_USAGE_RATE,
            1.0
        )

# Get the next stage ID based on the current stage
func get_next_stage_id(current_id):
    # This is just an example - you would implement your own logic
    match current_id:
        "default_stage":
            return "forest_stage"
        "forest_stage":
            return "mountain_stage"
        "mountain_stage":
            return "desert_stage"
        _:
            return "default_stage"
