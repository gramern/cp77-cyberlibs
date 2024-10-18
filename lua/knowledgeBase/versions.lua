local versions = {
    __VERSION = { 0, 2, 0 },
}

local t = nil

local function intializeTable()
    return {
        ["cyber_engine_tweaks.asi"] = {
            ["2024-09-13 13:02:28"] = "1.33.0.0"
        },
        ["dlssg_to_fsr3_amd_is_better.dll"] = {
            ["2024-07-24 08:47:51"] = "0.110.0.0"
        }
    }
end

function versions.getTable()
    if t == nil then
        t = intializeTable()
    end
    
    return t
end

return versions