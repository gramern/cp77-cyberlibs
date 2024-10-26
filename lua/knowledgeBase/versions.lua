local versions = {}

local t = nil

local function intializeTable()
    return {
        ["cyber_engine_tweaks.asi"] = {
            ["2024-09-13 13:02:28"] = "1.33.0.0",
        },
        ["dlssg_to_fsr3_amd_is_better.dll"] = {
            ["2024-07-09 16:58:42"] = "0.100.0.0",
            ["2024-07-24 08:47:51"] = "0.110.0.0",
        },
        ["scc_lib.dll"] = {
            ["2024-09-01 03:57:23"] = "0.5.27.0",
            ["2024-08-18 18:07:59"] = "0.5.26.0",
            ["2024-06-16 13:22:50"] = "0.5.25.0",
            ["2024-05-31 22:16:40"] = "0.5.24.0",
            ["2024-05-28 00:31:52"] = "0.5.23.0",
            ["2024-05-16 03:40:33"] = "0.5.21.0",
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