Name = "nirarchybackgrounds"
NamePretty = "Nirarchy Backgrounds"
Cache = false
HideFromProviderlist = true
SearchName = true

local function ShellEscape(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function FormatName(filename)
  local name = filename:gsub("^%d+", ""):gsub("^%-", "")
  name = name:gsub("%.[^%.]+$", "")
  name = name:gsub("-", " ")
  name = name:gsub("%S+", function(word)
    return word:sub(1, 1):upper() .. word:sub(2):lower()
  end)
  return name
end

function GetEntries()
  local entries = {}
  local home = os.getenv("HOME")

  local dirs = {
    home .. "/.config/nirarchy/current/theme/backgrounds",
    home .. "/.config/nirarchy/backgrounds",
  }

  local seen = {}

  for _, wallpaper_dir in ipairs(dirs) do
    local handle = io.popen(
      "find -L " .. ShellEscape(wallpaper_dir)
        .. " -maxdepth 1 -type f \\( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.gif' -o -name '*.bmp' -o -name '*.webp' \\) 2>/dev/null | sort"
    )
    if handle then
      for background in handle:lines() do
        local filename = background:match("([^/]+)$")
        if filename and not seen[filename] then
          seen[filename] = true
          table.insert(entries, {
            Text = FormatName(filename),
            Value = background,
            Actions = {
              activate = "nirarchy-background-set " .. ShellEscape(background),
            },
            Preview = background,
            PreviewType = "file",
          })
        end
      end
      handle:close()
    end
  end

  return entries
end
