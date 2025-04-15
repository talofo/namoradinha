class_name StageConfigGenerator
extends RefCounted

# Constants for stage parameters
const DIFFICULTY_EASY = "easy"
const DIFFICULTY_MEDIUM = "medium"
const DIFFICULTY_HARD = "hard"

const FLOW_PROFILE_EASY = ["low", "low", "low"]
const FLOW_PROFILE_MEDIUM = ["low", "mid", "low"]
const FLOW_PROFILE_HARD = ["low", "mid", "high", "mid"]

# Generate a stage configuration based on parameters
func generate_stage_config(params: Dictionary) -> StageCompositionConfig:
	var config = StageCompositionConfig.new()
	
	# Set basic properties
	config.id = "generated_" + str(Time.get_unix_time_from_system()).md5_text().substr(0, 8)
	config.theme = params.get("theme", "default")
	config.target_difficulty = params.get("difficulty", DIFFICULTY_EASY)
	config.launch_event_type = params.get("launch_event", "player_start")
	config.debug_markers = params.get("debug_markers", false)
	
	# Set flow profile based on difficulty
	match config.target_difficulty:
		DIFFICULTY_EASY:
			config.flow_profile = FLOW_PROFILE_EASY
		DIFFICULTY_HARD:
			config.flow_profile = FLOW_PROFILE_HARD
		_: # Medium or default
			config.flow_profile = FLOW_PROFILE_MEDIUM
	
	# Set end condition
	var distance = params.get("distance", 1000.0)
	config.story_end_condition = {
		"type": "distance",
		"value": distance
	}
	
	# Set chunk selection criteria
	config.chunk_selection = {
		"allowed_types": params.get("chunk_types", ["straight"]),
		"theme_tags": _get_theme_tags_for_difficulty(config.target_difficulty)
	}
	
	# Set content distribution
	config.content_distribution_id = params.get("content_distribution", "default")
	
	# Set chunk count estimate based on distance
	config.chunk_count_estimate = int(distance / 100.0)
	
	# Add mandatory intro chunk if specified
	if params.get("use_intro_chunk", true):
		var intro_chunk_id = _get_intro_chunk_for_difficulty(config.target_difficulty)
		config.mandatory_events.append({
			"type": "chunk",
			"chunk_id": intro_chunk_id,
			"trigger_distance": 0.0
		})
	
	# Validate the config
	config.validate()
	
	return config

# Get appropriate theme tags based on difficulty
func _get_theme_tags_for_difficulty(difficulty: String) -> Array[String]:
	var tags: Array[String] = ["standard"]
	
	match difficulty:
		DIFFICULTY_EASY:
			tags.append("sparse")
		DIFFICULTY_MEDIUM:
			# Mix of sparse and dense
			if randf() > 0.7:
				tags.append("dense")
			else:
				tags.append("sparse")
		DIFFICULTY_HARD:
			tags.append("dense")
	
	return tags

# Get appropriate intro chunk based on difficulty
func _get_intro_chunk_for_difficulty(difficulty: String) -> String:
	# Always use sparse rocks for intro regardless of difficulty
	return "sparse_rocks"

# Generate a stage config for a specific stage number
func generate_for_stage(stage_number: int) -> StageCompositionConfig:
	var params = {
		"theme": "default",
		"use_intro_chunk": true
	}
	
	# Adjust difficulty based on stage number
	if stage_number <= 3:
		params["difficulty"] = DIFFICULTY_EASY
		params["distance"] = 800.0 + stage_number * 100.0
	elif stage_number <= 6:
		params["difficulty"] = DIFFICULTY_MEDIUM
		params["distance"] = 1000.0 + (stage_number - 3) * 200.0
	else:
		params["difficulty"] = DIFFICULTY_HARD
		params["distance"] = 1500.0 + (stage_number - 6) * 300.0
	
	return generate_stage_config(params)
