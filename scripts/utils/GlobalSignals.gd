# scripts/utils/GlobalSignals.gd
# Autoload script for globally accessible signals (Event Bus)
extends Node

# Signal emitted when a player character is spawned and added to the scene tree.
# Connect to this signal if you need to react to player spawning (e.g., UI, controllers).
# This signal is emitted by PlayerSpawner when a new player is spawned.
@warning_ignore("unused_signal")
signal player_spawned(player_node: PlayerCharacter)

# Add other global signals here as needed, for example:
# signal score_updated(new_score: int)
# signal game_over()
