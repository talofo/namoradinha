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

**Note: Visual effects have been temporarily disabled to fix a flickering issue.**

The system includes code for visual effects, but they are currently not being used:

- **Manual Air Boost**: (Disabled) Orange-yellow particles with a matching trail
- **Environmental Boost** (future): (Disabled) Green particles with a matching trail
- **Mega Boost** (future): (Disabled) Purple particles with a matching trail

If visual effects need to be re-enabled in the future:

1. Restore the calls to `_create_boost_effect()` in `_ready()` and `_show_boost_effect()` in `_try_boost()` in PlayerCharacter.gd
2. Fix the flickering issue that occurs on the first boost application

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
