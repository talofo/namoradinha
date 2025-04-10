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

## Material Types

Material types are now defined as separate classes in the `scripts/collision_materials/` directory:

- **DefaultMaterial**: The base material with standard friction and bounce properties
- Additional materials (Ice, Mud, Rubber) are currently defined inline but will be moved to separate classes when needed

## Usage

1.  **Define Materials:** Create a new material class in `scripts/collision_materials/` that implements the `ICollisionMaterial` interface:
    ```gdscript
    # Example: scripts/collision_materials/IceMaterial.gd
    class_name IceMaterial
    extends RefCounted
    
    const ICollisionMaterial = preload("res://scripts/motion/subsystems/collision_material_system/interfaces/ICollisionMaterial.gd")
    
    func get_properties() -> Dictionary:
        return {
            "friction": 0.1,
            "bounce": 0.8,
            "sound": "ice_slide"
        }
    ```

2.  **Register Materials:** The CollisionMaterialSystem loads material classes and registers their properties.

3.  **Determine Material Type:** The colliding entity (e.g., `PlayerCharacter`) or the `MotionSystem` determines the name of the material involved in the collision.

4.  **Query Properties:** The system needing the properties gets the subsystem and queries it:
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

## Extending with New Material Types

To add a new material type:

1. Create a new class in `scripts/collision_materials/` that implements the ICollisionMaterial interface
2. Register it with the CollisionMaterialSystem (or update the _register_default_materials method)
