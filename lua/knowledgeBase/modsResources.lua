local modsResources = {}

local t = nil

local function intializeTable()
    return {
        ["ArchiveXL"] = "red4ext/plugins/ArchiveXL/ArchiveXL.dll",
        ["Browser Extension"] = "r6/scripts/BrowserExtension/BrowserExtension.System.reds",
        ["cybercmd"] = "bin/x64/plugins/cybercmd.asi",
        ["Cyber Engine Tweaks"] = "bin/x64/plugins/cyber_engine_tweaks.asi",
        ["Codeware"] = "red4ext/plugins/Codeware/Codeware.dll",
        ["Cyberlibs"] = "red4ext/plugins/Cyberlibs/Cyberlibs.dll",
        ["Deceptious Quest Core"] = "archive/pc/mod/zDeceptiousQuestCore.archive",
        ["Input Loader"] = "red4ext/plugins/input_loader/input_loader.dll",
        ["Mod Settings"] = "red4ext/plugins/mod_settings/mod_settings.dll",
        ["Native Settings UI"] = "bin/x64/plugins/cyber_engine_tweaks/mods/nativeSettings/init.lua",
        ["RadioExt"] = "red4ext/plugins/RadioExt/RadioExt.dll",
        ["RED4ext"] = "red4ext/RED4ext.dll",
        ["Red File System"] = "red4ext/plugins/RedFileSystem/RedFileSystem.dll",
        ["Red Hot Tools"] = "red4ext/plugins/RedHotTools/RedHotTools.dll",
        ["Red Http Client"] = "red4ext/plugins/RedHttpClient/RedHttpClient.dll",
        ["Red Memory Dump"] = "red4ext/plugins/RedMemoryDump/RedMemoryDump.dll",
        ["RedData"] = "red4ext/plugins/RedData/RedData.dll",
        ["Redscript"] = "engine/tools/scc_lib.dll",
        ["RedSuit"] = "bin/x64/plugins/cyber_engine_tweaks/mods/RedSuit/Init.lua",
        ["TweakXL"] = "red4ext/plugins/TweakXL/TweakXL.dll",
        ["RED4ext Loader"] = "bin/x64/winmm.dll",
        ["Ultimate ASI Loader"] = "bin/x64/version.dll",
        ["Virtual Atelier"] = "archive/pc/mod/VirtualAtelier.archive",
        ["Virtual Car Dealer"] = "archive/pc/mod/VirtualCarDealer.archive"
    }
end

function modsResources.getTable()
    if t == nil then
        t = intializeTable()
    end

    return t
end

return modsResources