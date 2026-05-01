# Autonomous Lifeform

## Buster & Cleo

This repository is now set up as a **Godot 4 starter project** for your autonomous agents idea. It includes a small 2D prototype with two digital dogs, **Buster** and **Cleo**, who make state-based decisions from their internal needs and the world around them.

## What Is Included

- A runnable Godot project in [project.godot](/Users/tomasmacsweeney/Documents/TU/autonomous-lifeform/project.godot)
- A main scene in [scenes/main.tscn](/Users/tomasmacsweeney/Documents/TU/autonomous-lifeform/scenes/main.tscn)
- Reusable dog logic in [scripts/dog.gd](/Users/tomasmacsweeney/Documents/TU/autonomous-lifeform/scripts/dog.gd)
- Simple food and toy world items in [scripts/world_item.gd](/Users/tomasmacsweeney/Documents/TU/autonomous-lifeform/scripts/world_item.gd)
- A clearer play space with beds, activity zones, and live dog status cards

## Prototype Behaviour

Each dog uses a lightweight FSM-style decision loop with these behaviours:

- `Idle`
- `Wander`
- `Follow Player`
- `Seek Food`
- `Play`
- `Sleep`

The state selection is influenced by:

- `hunger`
- `energy`
- `happiness`
- individual personality tuning

The two dogs are intentionally different:

- `Buster` is more social, faster, and much more playful
- `Cleo` is more curious, calmer, and more independent

The improved prototype now also includes:

- dedicated bed positions for sleeping
- favourite roam spots for each dog
- live thought text over each dog
- a pack-status HUD on the right
- item lifetime so food and toys clear out naturally

## Controls

- `WASD` or arrow keys move the player marker
- Left click drops food
- Right click drops a toy
- Food disappears after a while, and toys slowly expire too

## How To Open It

1. Open Godot.
2. Import the folder: `/Users/tomasmacsweeney/Documents/TU/autonomous-lifeform`
3. Open the project and run the main scene.

## Suggested Next Steps

- Replace the procedural dog drawings with dog sprites or skeletal animation
- Move from the simple FSM into a more modular state machine folder structure
- Add object sensing with `Area2D`
- Add barking, sound effects, and better interaction feedback
- Expand from the current 2D prototype into the style required for your assignment
