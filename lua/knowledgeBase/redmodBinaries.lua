local redmodBinaries = {}

local t = nil

local function intializeTable()
    return {
        "tools/redmod/bin/BCPack.dll",
        "tools/redmod/bin/freetype.dll",
        "tools/redmod/bin/libfbxsdk.dll",
        "tools/redmod/bin/liblz4.dll",
        "tools/redmod/bin/nvToolsExt64_1.dll",
        "tools/redmod/bin/omm-sdk.dll",
        "tools/redmod/bin/oo2ext_7_win64.dll",
        "tools/redmod/bin/PhysX3CharacterKinematic_x64.dll",
        "tools/redmod/bin/PhysX3Common_x64.dll",
        "tools/redmod/bin/PhysX3Cooking_x64.dll",
        "tools/redmod/bin/PhysX3_x64.dll",
        "tools/redmod/bin/PxFoundation_x64.dll",
        "tools/redmod/bin/PxPvdSDK_x64.dll",
        "tools/redmod/bin/redlexer_native.dll",
        "tools/redmod/bin/redMod.exe",
        "tools/redmod/bin/scc.exe"
    }
end

function redmodBinaries.getTable()
    if t == nil then
        t = intializeTable()
    end
    
    return t
end

return redmodBinaries