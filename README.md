# Fin 3 - *a proper fin tool* - propeller tool now included!

Fin 3 is a tool intended to create a "close enough" simulation of airflow over an airfoil in Garry's Mod.

Up until this point, the only way to have an aircraft fly in a somewhat realistic manner was to code something yourself via Expression 2 or Starfall. All fin/wing addons I have tested on the workshop are very old, unrealistic, hard to use, or some combination of the three (I'm looking at you, Fin 2).

Fin 3 brings to the table a more realistic option for aircraft enthusiasts.

## Features
- 2 primary airfoil types, consisting of:
    - A flat plate - stalls at quite a low angle of attack (around 5 degrees), works best as an air brake
    - A standard airfoil - A customizable camber airfoil for general aviation use. Has a base stall angle of around 15 degrees, which slightly increases with higher camber
- Lift and drag approximations based on real data - *including stalling!*
- Full parenting support, unlike Fin 2 which required a constraint
- Lift and drag forces are based on the fin's surface area, rather than the prop's mass
    - There is a slider to multiply the final lift/drag forces, ranging from 0.1x to 1.5x if needed
- Debug display allowing you to visualize the lift and drag vectors, and see exactly how much force is applied to each fin
- A tool for converting any prop into a simulated propeller, to propel your vehicles
    - E2 functions for changing blade pitch are included, allowing for variable pitch propellers

## Serverside Console Commands
- `sbox_max_fin3` - maximum number of fins allowed per player - default 20

## Disclaimer
I don't claim to be anything close to an aerospace engineer. All of my information regarding aerodynamics has come from either friends (thanks Kel) or from the internet. If something can be improved, optimized, or changed for the better, post an issue or create a pull request.

Inspired by [Cathier/Alexandre's Better Fin Tool](https://github.com/Cathier/better-fin-tool/tree/master) which was seemingly abandoned.
