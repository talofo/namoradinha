extends Node2D

@onready var camera_manager = $CameraManager
@onready var player_spawner = $PlayerSpawner
@onready var stage_manager = $StageManager

func _ready():
	# Example: load stage 1
	stage_manager.load_stage(1)

	# Spawn the player
	player_spawner.spawn_player()
