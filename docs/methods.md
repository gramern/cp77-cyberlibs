# Methods

All methods are global and can be called at any moment after the plugin is initialized by RED4ext.

## `LibInspector_IsLibraryLoaded()`

### Description:
Returns whether a library file has been loaded by the game. Can be used to detect presence of certain frameworks or mods like dlssg-to-fsr3 or ReShade (inculding ReShade's addons).

### Parameters:
`libraryName` (`string`) - The library's full file name with its file extension. The parameter is not case-sensitive.

### Returns:
`bool` - `true` if the library was loaded by the game, `false` otherwise.

### Exemplary Usage (CET-lua):
```
if type(LibInspector_IsLibraryLoaded) == "function" then -- check if the method is available
    local isNukem = LibInspector_IsLibraryLoaded("dlssg_to_fsr3_amd_is_better.dll")
    
    print(isNukem)
else
    print("Can't find function address 'LibInspector_IsLibraryLoaded'")
end 
```

## `LibInspector_GetVersionAsString()`

### Description:
Returns version of a loaded library if available.

### Parameters:
`libraryName` (`string`) - Library's full file name with its file extension. The parameter is not case-sensitive.

### Returns:
`string` - The library's version if available, or "Unknown" if the version cannot be determined.

### Exemplary Usage (CET-lua):
```
if type(LibInspector_GetVersionAsString) == "function" then -- check if the method is available
    local dlssgVer = LibInspector_GetVersionAsString("nvngx_dlssg.dll")
    
    print(dlssgVer)
else
    print("Can't find function address 'LibInspector_GetVersionAsString'")
end 
```
