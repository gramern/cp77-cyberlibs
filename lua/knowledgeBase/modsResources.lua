local modsResources = {
    __VERSION = { 0, 2, 0 },
}

local t = nil

local function intializeTable()
    return {
        "ArchiveXL.dll",
        "cyber_engine_tweaks.asi",
        "Codeware.dll",
        "Cyberlibs.dll",
        "fmod.dll",
        "input_loader.dll",
        "mod_settings.dll",
        "RadioExt.dll",
        "RED4ext.dll",
        "RedFileSystem.dll",
        "RedHotTools.dll",
        "RedHttpClient.dll",
        "RedMemoryDump.dll",
        "scc.exe",
        "scc_lib.dll",
        "TweakXL.dll",
        "winmm.dll",
        "version.dll"
    }
end

function modsResources.getTable()
    if t == nil then
        t = intializeTable()
    end
    
    return t
end

return modsResources