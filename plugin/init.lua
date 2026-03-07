local wezterm = require 'wezterm'

local M = {}

local POKEMON_ZIP_URL = 'https://github.com/LazoVelko/Pokemon-Terminal/archive/refs/heads/master.zip'
local IMAGES_REL = 'Pokemon-Terminal-master/pokemonterminal/Images'
local GENERATIONS = {
  'Generation I - Kanto',
  'Generation II - Johto',
  'Generation III - Hoenn',
  'Generation IV - Sinnoh',
  'Generation V - Unova',
  'Generation VI - Kalos',
  'Extra',
}

local DEFAULT_CONFIG = {
  brightness = 0.15,
  hue = 1.0,
  saturation = 1.0,
  generations = nil, -- nil = all
}

local cached_images = nil
local cached_user_config = nil

local function is_windows()
  return wezterm.target_triple:find('windows') ~= nil
end

local function get_cache_dir()
  local home = is_windows() and os.getenv('USERPROFILE') or os.getenv('HOME')
  if not home then return nil end
  local sep = is_windows() and '\\' or '/'
  return home .. sep .. '.cache' .. sep .. 'wezterm-bg-switcher'
end

local function dir_exists(path)
  local ok, _, code = os.rename(path, path)
  if ok then return true end
  return code == 13
end

local function download_images(cache_dir)
  local sep = is_windows() and '\\' or '/'
  local images_dir = cache_dir .. sep .. IMAGES_REL:gsub('/', sep)

  if dir_exists(images_dir) then
    return cache_dir
  end

  wezterm.log_info('wezterm-bg-switcher: downloading Pokemon images (first run)...')

  local zip_path = cache_dir .. sep .. 'pokemon.zip'
  local success, stdout, stderr

  if is_windows() then
    success, stdout, stderr = wezterm.run_child_process({
      'powershell', '-NoProfile', '-Command',
      string.format(
        "New-Item -ItemType Directory -Force -Path '%s' | Out-Null; " ..
        "Invoke-WebRequest -Uri '%s' -OutFile '%s'; " ..
        "Expand-Archive -Path '%s' -DestinationPath '%s' -Force; " ..
        "Remove-Item '%s'",
        cache_dir, POKEMON_ZIP_URL, zip_path, zip_path, cache_dir, zip_path
      ),
    })
  else
    success, stdout, stderr = wezterm.run_child_process({
      'sh', '-c',
      string.format(
        "mkdir -p '%s' && curl -sL '%s' -o '%s' && unzip -qo '%s' -d '%s' && rm '%s'",
        cache_dir, POKEMON_ZIP_URL, zip_path, zip_path, cache_dir, zip_path
      ),
    })
  end

  if not success then
    wezterm.log_error('wezterm-bg-switcher: download failed: ' .. (stderr or ''))
    return nil
  end

  wezterm.log_info('wezterm-bg-switcher: images downloaded successfully')
  return cache_dir
end

local function collect_images(cache_dir, generations)
  local sep = is_windows() and '\\' or '/'
  local base = cache_dir .. sep .. IMAGES_REL:gsub('/', sep)
  local images = {}

  local gens = generations or GENERATIONS
  for _, gen in ipairs(gens) do
    local gen_dir = base .. sep .. gen
    local ok, matches = pcall(wezterm.glob, gen_dir .. sep .. '*.jpg')
    if ok and matches then
      for _, file in ipairs(matches) do
        table.insert(images, file)
      end
    end
  end

  return images
end

local function pick_random(images)
  if #images == 0 then return nil end
  math.randomseed(os.time() + math.floor(math.random() * 10000))
  return images[math.random(#images)]
end

local function init_images(opts)
  if cached_images then return cached_images end

  opts = opts or {}
  cached_user_config = {}
  for k, v in pairs(DEFAULT_CONFIG) do
    if opts[k] ~= nil then
      cached_user_config[k] = opts[k]
    else
      cached_user_config[k] = v
    end
  end

  local cache_dir = get_cache_dir()
  if not cache_dir then
    wezterm.log_error('wezterm-bg-switcher: could not determine cache directory')
    return nil
  end

  local base_dir = download_images(cache_dir)
  if not base_dir then return nil end

  cached_images = collect_images(base_dir, cached_user_config.generations)
  return cached_images
end

function M.apply_to_config(config, opts)
  local images = init_images(opts)
  if not images then return end

  local uc = cached_user_config

  local image = pick_random(images)
  if not image then
    wezterm.log_warn('wezterm-bg-switcher: no images found')
    return
  end

  wezterm.log_info('wezterm-bg-switcher: ' .. image)
  config.window_background_image = image
  config.window_background_image_hsb = {
    brightness = uc.brightness,
    hue = uc.hue,
    saturation = uc.saturation,
  }

  -- Manual switch: Ctrl+Shift+B
  wezterm.on('switch-bg', function(window)
    local img = pick_random(images)
    if not img then return end
    wezterm.log_info('wezterm-bg-switcher: switched to ' .. img)
    window:set_config_overrides({
      window_background_image = img,
      window_background_image_hsb = {
        brightness = uc.brightness,
        hue = uc.hue,
        saturation = uc.saturation,
      },
    })
  end)

  table.insert(config.keys, {
    key = 'b',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.EmitEvent('switch-bg'),
  })

end

return M
