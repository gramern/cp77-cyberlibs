# Cyberlibs

A RED4ext plugin for Cyberpunk 2077 for diagnostics and inspection of libraries and plugins loaded by the game.

## Features

### GameModule
Adds methods that can be called from other mods or CET's console:
- `GameModule.IsLoaded(string fileNameOrPath)`:  Get a boolean indicating whether a module is loaded by the game
- `GameModule.GetVersion(string fileNameOrPath)`: Get the version of a module as a string

See [methods.md](docs/methods.md) for detailed documentation.

## Requirements
+ Cyberpunk 2.13
+ [RED4ext](https://github.com/WopsS/RED4ext) 1.25.1+
+ [redscript](https://github.com/jac3km4/redscript) 0.5.27+
+ [Cyber Engine Tweaks](https://github.com/maximegmd/CyberEngineTweaks) 1.33.0+

## Installation
Place the `Cyberlibs.dll` file in the `..\your Cyberpunk 2077 folder\red4ext\plugins\Cyberlibs` folder or unzip the archive to the game folder.

## Building
1. Clone the repository: (`git clone https://github.com/gramern/cp77-cyberlibs.git`).
2. Navigate to the project directory (`cd cp77-cyberlibs`)
2. Clone dependencies  (`git submodule update --init --recursive`).
3. Create the "build" folder, navigate to it and run `cmake ..`.
4. Build [RED4ext.SDK](https://github.com/WopsS/RED4ext.SDK) projects.
4. Build this project.

## License
The plugin is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
