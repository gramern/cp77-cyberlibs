# Cyberlibs (WIP)

A RED4ext plugin for Cyberpunk 2077 for diagnostics and inspection of libraries and plugins loaded by the game.

## Features

### GameModules
Adds methods that can be called from other mods or CET's console:
- `GameModules.IsLoaded(string fileNameOrPath)`:  Get a boolean indicating whether a module is loaded by the game
- `GameModules.GetVersion(string fileNameOrPath)`: Get the version of a module as a string

...and others, both implemented already and planned. Build the project, install it and type `Cyberlibs.Help()` in CET's console for help. The project is a WIP.

See [methods.md](docs/methods.md) for detailed documentation (WIP).

## Requirements
+ Cyberpunk 2.13
+ [RED4ext](https://github.com/WopsS/RED4ext) 1.25.1+
+ [redscript](https://github.com/jac3km4/redscript) 0.5.27+
+ [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks) 1.33.0+

## Installation
Place the `Cyberlibs.dll` file in the `..\your Cyberpunk 2077 folder\red4ext\plugins\Cyberlibs` folder.

Place `*.reds` scripts in `..\Cyberpunk 2077\r6\scripts\Cyberlibs`. 

The Lua (CET) part goes to `..\Cyberpunk 2077\bin\x64\plugins\cyber_engine_tweaks\mods\Cyberlibs`.

## Building
1. Clone the repository: (`git clone https://github.com/gramern/cp77-cyberlibs.git`).
2. Navigate to the project directory (`cd cp77-cyberlibs`)
2. Clone dependencies  (`git submodule update --init --recursive`).
3. Create the "build" folder, navigate to it and run `cmake ..`.
4. Build [RED4ext.SDK](https://github.com/WopsS/RED4ext.SDK) projects.
4. Build this project.

## License
The plugin is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
