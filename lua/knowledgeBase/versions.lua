local versions = {
  __VERSION = { 0, 2, 0 },
}

-- all stamps are in UTC time
function versions.getTable()
  local t = {
    ["dlssg_to_fsr3_amd_is_better.dll"] = {
      ["2024-07-24 08:47:51"] = "0.110.0.0"
    }
  }

  return t
end

return versions