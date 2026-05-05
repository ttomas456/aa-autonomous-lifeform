# Architecture Notes

The project is split into small scripts so the autonomous behaviour is easier to explain.

- `main.gd` owns the world, player marker, HUD, spawning, camera feedback, and background audio.
- `dog.gd` owns the visible creature, FSM, movement, drawing, reactions, and debug gizmo drawing.
- `dog_needs.gd` owns hunger, energy, happiness, and need changes over time.
- `dog_memory.gd` owns trust, excitement, and recent interaction memory.
- `world_item.gd` owns food and toy lifetime, drawing, and bump feedback.
- `procedural_sound.gd` owns generated sound effects and background music.

This keeps the creature brain separate from world management and makes the final demo easier to explain.
