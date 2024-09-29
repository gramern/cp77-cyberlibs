local utils = {
  __VERSION = { 0, 2, 0 },
}

function utils.getFileName(path)
  path = path:match("^%[%[(.*)%]%]$") or path

  return path:match(".*[/\\](.+)$") or path
end

return utils