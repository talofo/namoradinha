# Boost System

A modular system for applying boosts to entities during gameplay.

## Overview

The Boost System allows entities to receive velocity changes during gameplay based on different boost types. The system is designed to be extensible, allowing for various boost types with different behaviors.

## Core Components

- **BoostSystem**: Main entry point implementing the IMotionSubsystem interface
- **BoostTypeRegistry**: Manages registration of different boost types
- **BoostCalculator**: Handles boost vector calculations
- **IBoostType**: Interface for all boost types
- **ManualAirBoost**: Implementation of the Manual Air Boost type

## Data Structures

- **BoostContext**: Input data for boost calculations
- **BoostOutcome**: Output data with calculation results

## Manual Air Boost

The Manual Air Boost is a player-triggered boost that can only be used while airborne. It provides a directional motion change based on the player's vertical movement:

- When rising: Applies an upward-forward boost (orange-yellow visual effect)
- When falling: Applies a downward-forward boost (orange-yellow visual effect)

## Visual Effects

Each boost type can have its own unique visual effect:

- **Manual Air Boost**: Orange-yellow particles with a matching trail
- **Environmental Boost** (future): Green particles with a matching trail
- **Mega Boost** (future): Purple particles with a matching trail

The visual effects system is designed to be easily extensible. To add a new visual effect for a boost type:

1. Add a new entry to the `EFFECT_CONFIGS` dictionary in `BoostEffect.gd`
2. Pass the boost type name to the `show_effect` method when applying the boost

## Setup Instructions

### 1. Add Input Mapping

Before using the Manual Air Boost, you need to add an input action in the Godot project settings:

1. Open the Godot editor
2. Go to Project > Project Settings
3. Select the "Input Map" tab
4. Add a new action called "boost"
5. Assign a key (e.g., Space) to this action

![Input Mapping](https://docs.godotengine.org/en/stable/_images/input_event_mapping.png)

### 2. Physics Configuration (Optional)

For better configurability, you can add these parameters to your physics configuration:

```gdscript
# Boost parameters
var manual_air_boost_rising_strength: float = 300.0
var manual_air_boost_rising_angle: float = 45.0
var manual_air_boost_falling_strength: float = 500.0
var manual_air_boost_falling_angle: float = -60.0
var boost_cooldown: float = 0.5
```

## Usage

The PlayerCharacter class now has input handling for the Manual Air Boost. When the player presses the "boost" key (Space by default) while airborne, it will:

1. Check if the player is in a valid state for boosting
2. Call the BoostSystem's `try_apply_boost` method with the current state
3. Apply the resulting velocity if successful

## Extending with New Boost Types

To add a new boost type:

1. Create a new class that implements the IBoostType interface
2. Register it with the BoostTypeRegistry in BoostSystem's `_init` method
3. Implement the activation mechanism appropriate for that boost type

Different boost types can have different activation mechanisms:
- Manual boosts: Triggered by player input
- Passive/Buff boosts: Triggered automatically based on game state
- Environmental boosts: Triggered by collision with objects
- Mega boosts: Triggered by special conditions
