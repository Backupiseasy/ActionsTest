local lfs = require("lfs")

-- Ignore the following directories or files 
local IGNORE_LIST = {
  ".git",
  ".github",
  ".idea",
  ".release",
  ".lua", ".luarocks", ".install",
  "Libs",
  "Locales",
  "Source",
  "Test",
}

function string_starts(String,Start)
  return string.sub(String,1,string.len(Start))==Start
end

-- This function takes two arguments:
-- - the directory to walk recursively;
-- - an optional function that takes a file name as argument, and returns a boolean.
function ScanDirectory(self, fn)
  return coroutine.wrap(function()
    for f in lfs.dir(self) do
      if f ~= "." and f ~= ".." then
        local _f = self .. "/" .. f
        if not fn or fn(_f) then
          coroutine.yield(_f)
        end
        if lfs.attributes(_f, "mode") == "directory" then
          for n in ScanDirectory(_f, fn) do
            coroutine.yield(n)
          end
        end
      end
    end
  end)
end

-- Prefix to all files if this script is run from a subdir, for example
local function ParseFile(file_name)
  local phrase_keys = {}
  local file = assert(io.open(string.format("%s%s", "", file_name), "r"), "Could not open " .. file_name)
  local text = file:read("*all")
  file:close()

  print (file_name)
  for match in string.gmatch(text or "", "L%[\"(.-)\"%]") do
    if not match:find('"%.%.(.+)%.%."') then
      phrase_keys[#phrase_keys + 1] = match
    end
end

  return phrase_keys
end

do
  -- Get the current directory (must be Addons/TidyPlates_ThreatPlates)
  local working_dir = arg[1] or os.getenv("PWD")
  
  local file_list = ScanDirectory(working_dir)
  local CheckFile = function(self)
    local file_with_phrase_keys = self:match("%.lua$")
    
    for i, prefix in ipairs(IGNORE_LIST) do
      if string_starts(self, working_dir .. "/" .. prefix) then
        file_with_phrase_keys = false
      end
    end 

    return file_with_phrase_keys
  end
  
  local phrase_keys = {}

  for file_name in ScanDirectory(working_dir, CheckFile) do
    local phrase_keys_in_file = ParseFile(file_name)
    for _, phrase_key in ipairs(phrase_keys_in_file) do
      phrase_keys[phrase_key] = true
    end
  end

  local sorted_phrase_keys = {}
  for key, _ in pairs(phrase_keys) do
    sorted_phrase_keys[#sorted_phrase_keys + 1] = key
  end
  table.sort(sorted_phrase_keys)

  local locale_file_header = [[
---------------------------------------------------------------------------------------------------
-- Strings which are created dynamically in the addon
---------------------------------------------------------------------------------------------------
L["Show Friendly Units"] = true
L["Players"] = true
L["NPCs"] = true
L["Totems"] = true
L["Guardians"] = true
L["Pets"] = true

L["Show Enemy Units"] = true
L["Minuss"] = "Minors"

L["Show Neutral Units"] = true

---------------------------------------------------------------------------------------------------
-- String constants in the game
---------------------------------------------------------------------------------------------------
]]  

  local phrase_keys_import_file_name = arg[2] or "phrase_keys_export_file.txt"
  local phrase_keys_import_file = assert(io.open(phrase_keys_import_file_name, "w"), "Error opening file")
  phrase_keys_import_file:write(locale_file_header)

  for _, phrase_key in ipairs(sorted_phrase_keys) do
    phrase_keys_import_file:write(string.format("L[\"%s\"] = true\n", phrase_key))
  end

  print("(" .. #sorted_phrase_keys .. ") " .. phrase_keys_import_file_name)

  phrase_keys_import_file:close()
end
