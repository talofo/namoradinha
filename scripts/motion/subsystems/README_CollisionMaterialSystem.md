# CollisionMaterialSystem

A subsystem for the MotionSystem that provides material-specific physics properties based on collision context.

## Overview

The CollisionMaterialSystem acts as a lookup service for surface properties. When an entity collides with something, other systems (like `MotionSystem` or `PlayerCharacter`) can determine the type of material collided with (e.g., "ice", "mud", "default"). This system then provides the relevant physics parameters associated with that material type, such as friction coefficients or bounce ratios.

## Features

- Stores physics properties (friction, bounce ratio, etc.) associated with different material names.
- Provides a method (`get_material_properties`) to retrieve the properties dictionary for a given material name.
- Allows for easy definition and extension of new material types and their associated physics behaviors.

## Integration with MotionSystem

The CollisionMaterialSystem implements the `IMotionSubsystem` interface and is registered with the `MotionSystem`. It doesn't typically generate `MotionModifier`s itself. Instead, other systems query it during their calculations.

## Usage

1.  **Define Materials:** Material properties are typically defined directly within the `CollisionMaterialSystem.gd` script (or potentially loaded from an external resource file in a more advanced implementation).
    ```gdscript
    # Example definition within CollisionMaterialSystem.gd
    var _material_properties = {
        "default": {"friction": 0.2, "bounce_ratio": 0.5},
        "ice": {"friction": 0.05, "bounce_ratio": 0.7},
        "mud": {"friction": 0.8, "bounce_ratio": 0.1}
    }
    ```
2.  **Determine Material Type:** The colliding entity (e.g., `PlayerCharacter`) or the `MotionSystem` determines the name of the material involved in the collision (e.g., based on the physics body collided with, or position as currently implemented in `PlayerCharacter`).
3.  **Query Properties:** The system needing the properties (e.g., `MotionSystem` when calculating sliding friction) gets the subsystem and queries it:
    ```gdscript
    # Example within MotionSystem.resolve_collision
    var collision_material_system = get_subsystem("CollisionMaterialSystem")
    var material_type = collision_info.get("material", "default") # Get material name from context
    var base_friction = physics_config.default_ground_friction # Default fallback

    if collision_material_system:
        var material_properties = collision_material_system.get_material_properties(material_type)
        base_friction = material_properties.get("friction", base_friction) # Use material friction if available
    
    # ... use base_friction in calculations ...
    ```

## Configuration

While base default values (like `default_ground_friction`) exist in `PhysicsConfig`, the specific properties for named materials ("ice", "mud", etc.) are currently managed within the `CollisionMaterialSystem.gd` script itself.
