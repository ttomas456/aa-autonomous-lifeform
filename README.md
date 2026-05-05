# Buster & Cleo: Autonomous Lifeform

Godot 4.5 project for the Autonomous Agents assignment. The project is a 2D artificial-life garden with two digital dogs, Buster and Cleo, who make autonomous decisions from their needs, personality settings, memories, and the player's actions.

## Concept

Buster and Cleo are not directly controlled. They wander, follow the player, seek food, play with toys, nap in their beds, and react to petting and whistles. The goal is to make a small virtual creature system that feels alive through readable needs, procedural animation, sound, emotion particles, and visible decision-making.

## Controls

- `WASD` or arrow keys: move the player marker
- Left click: drop food
- Right click: drop toy
- `E`: pet the nearest dog
- `Q`: whistle both dogs with an audible player whistle
- `G`: toggle debug gizmos

## Autonomous Behaviour

Each dog uses a finite state machine with these states:

- `Idle`
- `Wander`
- `Follow Player`
- `Seek Food`
- `Play`
- `Sleep`

The state machine is influenced by:

- hunger
- energy
- happiness
- curiosity
- sociability
- playfulness
- rest bias
- trust and recent memories

Buster is faster, more social, and more playful. Cleo is calmer, more curious, and more independent.

## Architecture

- `scripts/main.gd`: world, player input, spawning, HUD, yard visuals, camera feedback
- `scripts/dog.gd`: autonomous body, FSM, steering, procedural drawing, reactions
- `scripts/dog_needs.gd`: hunger, energy, happiness, and need changes over time
- `scripts/dog_memory.gd`: trust, excitement, and recent player interactions
- `scripts/world_item.gd`: food and toy behaviours
- `scripts/procedural_sound.gd`: generated tones for barks, chirps, eating, play, and sleep

## Polish Features

- Two agents with distinct personalities
- Steering-style seek and arrive movement
- Procedural body, ears, eyes, tail wagging, and state icons
- Emotion particles for petting, play, eating, whistle, and sleep
- Quieter procedural audio mix with distinct barking, happy yips, whining, chewing, toy squeaks, snoring, clicks, player whistle calls, and a gentle looping background track
- Animated sky, clouds, grass texture, beds, activity zones, and enrichment spots
- Player bonding system through petting and trust
- Debug gizmos showing world bounds and each dog's current target
- Live HUD showing needs, mood, trust, and recent events

## Running The Project

1. Open Godot 4.5.
2. Import this folder as a project.
3. Run the main scene: `scenes/main.tscn`.

The configured main scene is already set in `project.godot`.

## Build And Demo Checklist

- Export a desktop build before recording.
- Record the video from the build, not from inside the editor.
- Show autonomous wandering for at least 15 seconds.
- Drop food near a hungry dog.
- Drop a toy and show Buster playing.
- Pet a dog with `E`.
- Whistle both dogs with `Q`.
- Toggle gizmos with `G` and briefly explain the FSM/needs system.

## Sources

All current visuals and sounds are procedural and generated in Godot/GDScript. No third-party art or audio assets are required for the current version.

## Reflection

The most important learning in this prototype was connecting simple independent systems into a more believable creature: needs create pressure, the FSM chooses a behaviour, steering makes the body move, memory changes future social behaviour, and particles/sounds communicate emotion back to the player.

If continuing the project, the next best upgrades would be skeletal dog sprites, richer animations, saveable memories, obstacle sensing with `Area2D`, and a short exported gameplay trailer.
