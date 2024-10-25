# GameModules

## `IsLoaded()`

### Description:
Returns whether a library file has been loaded by the game. Can be used to detect presence of certain frameworks or mods like dlssg-to-fsr3 or ReShade (inculding ReShade's addons).

### Parameters:
`libraryName` (`string`) - The library's full file name with its file extension. The parameter is not case-sensitive.

### Returns:
`bool` - `true` if the library was loaded by the game, `false` otherwise.

### Exemplary Usage (CET-lua):
```
local isNukem = GameModules.IsLoaded("dlssg_to_fsr3_amd_is_better.dll")
    
print(isNukem)
```

## `GetVersion()`

### Description:
Returns version of a loaded library if available in the file.

### Parameters:
`libraryName` (`string`) - Library's full file name with its file extension. The parameter is not case-sensitive.

### Returns:
`string` - The library's version if available, or "Unknown" if the version cannot be determined.

### Exemplary Usage (CET-lua):
```
local dlssgVer = GameModules.GetVersion("nvngx_dlssg.dll")
    
print(dlssgVer)
```
