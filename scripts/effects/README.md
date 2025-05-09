# Effects

This directory contains various effect implementations for the game.

## Structure

- **visual_effects/**: Visual feedback effects (particles, animations, etc.)
- **audio_effects/**: Sound effects (to be implemented)
- **game_effects/**: Game-wide effects like slow motion, screen shake, etc. (to be implemented)

## Visual Effects

Visual effects are purely cosmetic and provide visual feedback to the player. They don't affect gameplay mechanics directly.

Examples:
- **BoostEffect**: Particle effect shown when a boost is applied

## Audio Effects

Audio effects provide sound feedback to the player. This directory will be implemented in the future.

## Game Effects

Game effects affect the entire game state, such as slow motion or screen effects. This directory will be implemented in the future.

## Usage

Effects are typically instantiated and attached to game objects that need them:

```gdscript
# Example: Creating a boost effect
var boost_effect = load("res://scripts/effects/visual_effects/BoostEffect.gd").new()
add_child(boost_effect)
boost_effect.show_effect(direction, "manual_air")
