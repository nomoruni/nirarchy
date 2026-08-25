--
-- Nirarchy Theme Menu for Elephant/Walker (with image previews)
--
Name = "nirarchythemes"
NamePretty = "Nirarchy Themes"
HideFromProviderlist = true
Cache = false

local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function first_image_in_dir(dir)
  local handle = io.popen("ls -1 '" .. dir .. "' 2>/dev/null | head -n 1")
  if handle then
    local file = handle:read("*l")
    handle:close()
    if file and file ~= "" then
      return dir .. "/" .. file
    end
  end
  return nil
end

local function find_preview_path(dir)
  local png = dir .. "/preview.png"
  local jpg = dir .. "/preview.jpg"
  if file_exists(png) then return png end
  if file_exists(jpg) then return jpg end
  return first_image_in_dir(dir .. "/backgrounds")
end

function GetEntries()
  local entries = {}
  local home = os.getenv("HOME")
  local user_theme_dir = home .. "/.config/nirarchy/themes"
  local default_theme_dir = home .. "/.local/share/nirarchy/themes"

  local seen_themes = {}

  local function process_themes_from_dir(theme_dir)
    local handle = io.popen("find -L '" .. theme_dir .. "' -mindepth 1 -maxdepth 1 -type d 2>/dev/null")
    if not handle then
      return
    end

    for theme_path in handle:lines() do
      local theme_name = theme_path:match(".*/(.+)$")

      if theme_name and not seen_themes[theme_name] then
        seen_themes[theme_name] = true

        local preview_path = find_preview_path(theme_path)

        if preview_path and preview_path ~= "" then
          local display_name = theme_name:gsub("_", " "):gsub("%-", " ")
          display_name = display_name:gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
          end)

          table.insert(entries, {
            Text = display_name,
            Preview = preview_path,
            PreviewType = "file",
            Actions = {
              activate = "nirarchy-theme-set " .. theme_name,
            },
          })
        end
      end
    end

    handle:close()
  end

  process_themes_from_dir(user_theme_dir)
  process_themes_from_dir(default_theme_dir)

  return entries
end
