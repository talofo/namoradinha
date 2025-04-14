# scripts/utils/GlobalSignals.gd
# Autoload script for globally accessible signals (Event Bus)
extends Node

# StageConfig is available globally via class_name

# Signal emitted when a player character is spawned and added to the scene tree.
# Connect to this signal if you need to react to player spawning (e.g., UI, controllers).
# This signal is emitted by PlayerSpawner when a new player is spawned.
@warning_ignore("unused_signal")
signal player_spawned(player_node: PlayerCharacter)

# Environment signals
# Signal emitted when a stage is loaded with its configuration
@warning_ignore("unused_signal")
signal stage_loaded(config: StageConfig)

# Signal emitted when the biome changes
@warning_ignore("unused_signal")
signal biome_changed(biome_id: String)

# Signal emitted when the theme changes
@warning_ignore("unused_signal")
signal theme_changed(theme_id: String)

# Add other global signals here as needed, for example:
# signal score_updated(new_score: int)
# signal game_over()
