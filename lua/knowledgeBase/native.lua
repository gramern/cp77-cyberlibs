local native = {
    __VERSION = { 0, 2, 0 },
}

local t = nil

local function intializeTable()
    return {
        "bin/x64/amd_ags_x64.dll",
        "bin/x64/api-ms-win-downlevel-kernel32-l2-1-0.dll",
        "bin/x64/bink2w64.dll",
        "bin/x64/CChromaEditorLibrary64.dll",
        "bin/x64/CrashReporter/7za.exe",
        "bin/x64/CrashReporter/ar/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/CrashReporter.exe",
        "bin/x64/CrashReporter/cs/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/de/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/es-es/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/es/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/fr/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/hu/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/it/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/ja/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/ko/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/pl/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/pt/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/ru/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/th/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/tr/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/uk/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/zh-hans/CrashReporter.resources.dll",
        "bin/x64/CrashReporter/zh-hant/CrashReporter.resources.dll",
        "bin/x64/Cyberpunk2077.exe",
        "bin/x64/d3d12on7/d3d11on12.dll",
        "bin/x64/d3d12on7/d3d12.dll",
        "bin/x64/dbgcore.dll",
        "bin/x64/dbghelp.dll",
        "bin/x64/dxilconv7.dll",
        "bin/x64/ffx_backend_dx12_x64.dll",
        "bin/x64/ffx_frameinterpolation_x64.dll",
        "bin/x64/ffx_fsr3upscaler_x64.dll",
        "bin/x64/ffx_fsr3_x64.dll",
        "bin/x64/ffx_opticalflow_x64.dll",
        "bin/x64/freetype.dll",
        "bin/x64/Galaxy64.dll",
        "bin/x64/GameServicesGOG.dll",
        "bin/x64/GfnRuntimeSdk.dll",
        "bin/x64/GFSDK_Aftermath_Lib.x64.dll",
        "bin/x64/icudt.dll",
        "bin/x64/icuin.dll",
        "bin/x64/icuio.dll",
        "bin/x64/icuuc.dll",
        "bin/x64/libcurl.dll",
        "bin/x64/libeay32.dll",
        "bin/x64/libxess.dll",
        "bin/x64/nvngx_dlss.dll",
        "bin/x64/nvngx_dlssd.dll",
        "bin/x64/nvngx_dlssg.dll",
        "bin/x64/nvToolsExt64_1.dll",
        "bin/x64/oo2ext_7_win64.dll",
        "bin/x64/PhysX3CharacterKinematic_x64.dll",
        "bin/x64/PhysX3Common_x64.dll",
        "bin/x64/PhysX3Cooking_x64.dll",
        "bin/x64/PhysX3_x64.dll",
        "bin/x64/PxFoundation_x64.dll",
        "bin/x64/PxPvdSDK_x64.dll",
        "bin/x64/REDEngineErrorReporter.exe",
        "bin/x64/REDGalaxy64.dll",
        "bin/x64/redlexer_native.dll",
        "bin/x64/sl.common.dll",
        "bin/x64/sl.dlss.dll",
        "bin/x64/sl.dlss_d.dll",
        "bin/x64/sl.dlss_g.dll",
        "bin/x64/sl.interposer.dll",
        "bin/x64/sl.nis.dll",
        "bin/x64/sl.reflex.dll",
        "bin/x64/ssleay32.dll",
        "bin/x64/symsrv.dll",
        "bin/x64/WinPixEventRuntime.dll",
        "libcrypto-1_1.dll",
        "libssl-1_1.dll",
        "pcre2-16.dll",
        "pcre2-8.dll",
        "PocoData.dll",
        "PocoDataSQLite.dll",
        "PocoFoundation.dll",
        "PocoJSON.dll",
        "PocoUtil.dll",
        "PocoXML.dll",
        "Qt5Core.dll",
        "Qt5Network.dll",
        "REDprelauncher.exe",
        "sqlite3.dll",
        "unins000.exe",
        "unins001.exe",
        "unins002.exe",
        "zlib1.dll",
    }
end

function native.getTable()
    if t == nil then
        t = intializeTable()
    end
    
    return t
end

return native