# Roblox Advanced Sound System

A high-performance, realistic audio propagation and simulation system for Roblox, leveraging the modern **Audio API** (Wires, Emitters, and Filters) to create immersive soundscapes.

## 🔊 Features

### 1. Realistic Distance Modeling (`SoundDistance`)
Simulates the physical properties of sound as it travels through space.
- **Speed of Sound Delay**: Calculates the time-of-flight for sound (343 m/s), adding a subtle delay for distant explosions or effects.
- **Environmental Occlusion**: Uses real-time raycasting to detect obstacles. Sounds behind walls are automatically muffled using **Lowpass Filters**.
- **Dynamic Reverb**: Automatically scales `DecayTime` and `WetLevel` based on the distance between the source and the listener.
- **Custom Attenuation**: Uses `AudioEmitter:SetDistanceAttenuation` for precise control over how volume drops over distance.

### 2. Sound Propagation Projectiles (`SoundBounce`)
A unique system that simulates "sound rays" to model complex acoustics and echoes.
- **Surface Awareness**: Integrated with `CollectionService` to react to different materials:
    - **Hard Surfaces**: High reflection, crisp echoes.
    - **Soft Surfaces**: High absorption, muffled response.
    - **Medium Surfaces**: Balanced acoustic profile.
- **Object Pooling**: Uses a high-performance part-pooling system to handle hundreds of sound rays simultaneously without performance lag.
- **Physics-Based Reflection**: Sound "projectiles" bounce off surfaces realistically using vector reflection math.

## 🛠️ Technical Stack
- **Roblox Audio API**: `AudioPlayer`, `AudioFilter`, `AudioReverb`, `AudioEmitter`, and `Wires`.
- **Parallel Processing Ready**: Designed to work within an Actor-based framework for maximum efficiency.
- **Luau Optimized**: Uses native Luau features and optimization attributes for peak performance.

## 🚀 Usage

### Sound Execution
To play a sound with distance and occlusion effects:
```lua
local SoundService = require(path.to.SoundDistance)
SoundService.Execution(originVector3, soundInstance, maxDistance)
```

### Sound Projectiles
To spawn a bouncing sound simulation:
```lua
local SoundBounce = require(path.to.SoundBounce)
local projectile = SoundBounce.new(speed, ownerPart, spawnLocation, soundInstance, rayCount)
```

---
*Created with focus on high-fidelity audio and performance optimization.*
