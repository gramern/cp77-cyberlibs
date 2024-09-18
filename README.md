# LibInspector

A RED4ext plugin for Cyberpunk 2077 that allows detection and inspection of libraries and plugins loaded by the game.

## Features
Adds global methods that can be called from other mods or CET's console:
- `LibInspector_IsLibraryLoaded(string libraryName)`:  Get a boolean indicating whether a library is loaded by the game
- `LibInspector_GetVersionAsString(string libraryName)`: Get the version of a library as a string

See [methods.md](docs/methods.md) for detailed documentation.

## Requirements
+ Cyberpunk 2.13
+ [RED4ext](https://github.com/WopsS/RED4ext) 1.25.1+

## Installation
Place the `libinspector.dll` file in the `..\your Cyberpunk 2077 folder\red4ext\plugins\libinspector` folder or unzip the archive to the game folder.

## Building
1. Clone the repository: (`git clone https://github.com/gramern/cp77-libinspector.git`).
2. Navigate to the project directory (`cd cp77-libinspector`)
2. Clone dependencies  (`git submodule update --init --recursive`).
3. Build [RED4ext.SDK](https://github.com/WopsS/RED4ext.SDK) projects.
4. Build this project.

## License
The plugin is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
