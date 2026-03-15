# aa-autonomous-lifeform
# Autonomous Agents Assignment  
## Buster & Cleo – Autonomous Digital Dogs

### Project Overview
This project will create two autonomous artificial lifeforms: Buster and Cleo, inspired by my real-life dogs. The goal is to simulate believable digital creatures that behave independently and interact with the player and their environment. Each dog will have its own behaviours and internal needs, creating the illusion that they are living beings with personalities and emotions.

The lifeforms will exist in a small virtual environment where they can wander, react to the player, and interact with objects such as food or toys. The player will not directly control the dogs; instead, the creatures will act autonomously based on their internal states and environmental stimuli.

### Behaviour System
The dogs will use a Finite State Machine (FSM) architecture to manage behaviour. Each dog will switch between behavioural states depending on its needs and what is happening in the environment.

Possible states include:

- Idle – the dog rests or observes the environment  
- Wander – the dog explores the space using steering behaviours  
- Follow Player – the dog approaches the player when nearby  
- Seek Food – the dog searches for food objects when hungry  
- Play – the dog chases a toy or interacts with the other dog  
- Sleep – the dog rests when energy is low  

These states will transition dynamically depending on internal variables such as hunger, energy, and happiness.

### Movement and Animation
Movement will be implemented using steering behaviours such as wander, seek, and arrive. These behaviours will allow the dogs to move in a natural and believable way rather than using rigid scripted movement.

Procedural animation techniques will be used to simulate behaviours such as tail wagging, looking at the player, or subtle idle movements. This will help convey emotion and personality in the creatures.

### Interaction
The player will be able to influence the dogs through simple interactions such as:

- moving near the dogs  
- dropping food objects  
- interacting with toys  

The dogs will react to these interactions autonomously. For example, a hungry dog may move toward food, while a curious dog may approach the player. The dogs may also interact with each other, reinforcing the impression that they are independent lifeforms.

### Technology
The project will be developed using Godot Engine and GDScript. It will incorporate code and systems from the provided repositories that include steering behaviours and procedural animation systems. These tools will be used to implement the autonomous movement and behavioural systems for the lifeforms.

### Expected Outcome
The final result will be a small interactive simulation featuring two autonomous digital dogs that demonstrate believable artificial life behaviour. Through autonomous movement, reactions to the player, and emotional responses such as excitement or tiredness, the project will aim to convince the user that the creatures possess a mind and personality of their own.
