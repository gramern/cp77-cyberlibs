local modsResources = {}

local t = nil

local function intializeTable()
    return {
        ["ArchiveXL"] = "red4ext/plugins/ArchiveXL/ArchiveXL.dll",
        ["Cyber Engine Tweaks"] = "bin/x64/plugins/cyber_engine_tweaks.asi",
        ["Codeware"] = "red4ext/plugins/Codeware/Codeware.dll",
        ["Cyberlibs"] = "red4ext/plugins/Cyberlibs/Cyberlibs.dll",
        ["Input Loader"] = "red4ext/plugins/input_loader/input_loader.dll",
        ["Mod Settings"] = "red4ext/plugins/mod_settings/mod_settings.dll",
        ["RadioExt"] = "red4ext/plugins/RadioExt/RadioExt.dll",
        ["RED4ext"] = "red4ext/RED4ext.dll",
        ["Red File System"] = "red4ext/plugins/RedFileSystem/RedFileSystem.dll",
        ["Red Hot Tools"] = "red4ext/plugins/RedHotTools/RedHotTools.dll",
        ["Red Http Client"] = "red4ext/plugins/RedHttpClient/RedHttpClient.dll",
        ["Red Memory Dump"] = "red4ext/plugins/RedMemoryDump/RedMemoryDump.dll",
        ["Redscript"] = "engine/tools/scc_lib.dll",
        ["TweakXL"] = "red4ext/plugins/TweakXL/TweakXL.dll",
        ["RED4ext Loader"] = "bin/x64/winmm.dll",
        ["Ultimate ASI Loader"] = "bin/x64/version.dll"
    }
end

function modsResources.getTable()
    if t == nil then
        t = intializeTable()
    end

    return t
end

return modsResources