# Fin 3 - *a proper fin tool*

Fin 3 is a tool intended to create a "close enough" simulation of airflow over an airfoil in Garry's Mod.

Up until this point, the only way to have an aircraft fly in a somewhat realistic manner was to code something yourself via Expression 2 or Starfall. All fin/wing addons I have tested on the workshop are very old, unrealistic, hard to use, or some combination of the three (I'm looking at you, Fin 2).

Fin 3 brings to the table a more realistic option for aircraft enthusiasts.

## Features
- 3 airfoil types, consisting of:
    - A flat plate - quite bad flight characteristics, not many uses
    - A symmetrical airfoil, which produces no lift at zero [angle of attack](https://en.wikipedia.org/wiki/Angle_of_attack) - good for control surfaces
    - A cambered airfoil, which produces lift at zero AoA, useful for the main wing of an aircraft
- Lift and drag profiles for each airfoil based on real data - *including stalling!*
- Full parenting support, unlike Fin 2 which required a constraint
- Lift and drag forces are based on the fin's surface area, rather than the prop's mass
    - There is a slider to multiply the final lift/drag forces, ranging from 0.1x to 1.5x if needed
- Debug display allowing you to visualize the lift and drag vectors, and see exactly how much force is applied to each fin

## Known Problems
- Propellers made with Fin 3 are not very viable. Eventually, a simulated propeller tool will be added alongside the main Fin 3 tool.
- Extremely light fins or vehicles with a large fin surface area may spaz/wiggle due to extreme forces

## Serverside Console Commands
- `sbox_max_fin3` - maximum number of fins allowed per player - default 20
- `fin3_forceinduceddrag` - when set to 1, induced drag is forced on for all fins - may be useful for combat servers

## To Do
- [ ] Wind
- [ ] Thermals
- [x] Better way to define forward vector of fin (get normal of separately clicked prop?)
- [ ] Some way to reliably detect ground effect without optimization problems
- [ ] Stall angle changing based on airspeed
- [ ] Sample velocity at multiple points along the wing to make propellers/rotors more effective
- [ ] E2/SF functions to get information about/create a fin
- [X] Warn about/remove Fin 2 on entities that already have it when applying Fin 3

## Disclaimer
I don't claim to be anything close to an aerospace engineer. All of my information regarding aerodynamics has come from either friends (thanks Kel) or from the internet. If something can be improved, optimized, or changed for the better, post an issue or create a pull request.

Inspired by [Cathier/Alexandre's Better Fin Tool](https://github.com/Cathier/better-fin-tool/tree/master) which was seemingly abandoned.
