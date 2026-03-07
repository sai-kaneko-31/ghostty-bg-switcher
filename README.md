# wezterm-bg-switcher

A WezTerm module that sets a random Pokemon background on each launch.

Images are downloaded from [Pokemon-Terminal](https://github.com/LazoVelko/Pokemon-Terminal) on first run and cached locally.

## Install

1. Copy `plugin/init.lua` to your WezTerm config directory as `bg-switcher.lua`:

```bash
# Windows
copy plugin\init.lua %USERPROFILE%\.config\wezterm\bg-switcher.lua

# macOS / Linux
cp plugin/init.lua ~/.config/wezterm/bg-switcher.lua
```

2. Add to your `wezterm.lua`:

```lua
local wezterm = require 'wezterm'
local bg = require 'bg-switcher'
local config = wezterm.config_builder()

bg.apply_to_config(config)

return config
```

## Keybinding

`Ctrl+Shift+B` — switch to a random background image.

## Auto-rotation

Add `wezterm.time.call_after` at the **top level** of your `wezterm.lua` (not inside a function):

```lua
-- Rotate background every 3 minutes
wezterm.time.call_after(180, function()
  wezterm.reload_configuration()
end)
```

> Note: `call_after` only works at the top level scope of `wezterm.lua`. It does not fire when called inside plugin functions.

## Options

```lua
bg.apply_to_config(config, {
  brightness = 0.15,   -- image brightness (0.0-1.0, lower = darker)
  hue = 1.0,           -- hue multiplier
  saturation = 1.0,    -- saturation multiplier
  generations = {      -- filter by generation (nil = all)
    'Generation I - Kanto',
    'Generation II - Johto',
    'Generation III - Hoenn',
    'Generation IV - Sinnoh',
    'Generation V - Unova',
    'Generation VI - Kalos',
    'Extra',
  },
})
```

## How it works

1. On first launch, downloads [Pokemon-Terminal](https://github.com/LazoVelko/Pokemon-Terminal) images (ZIP, ~17MB) to `~/.cache/wezterm-bg-switcher/`
2. Picks a random image from the cached collection
3. Sets it as the WezTerm background with darkened brightness for readability

## Credits

- Pokemon backgrounds by [Teej](https://pldh.net/gallery/the493) via [Pokemon-Terminal](https://github.com/LazoVelko/Pokemon-Terminal)
- Pokemon is a trademark of Nintendo / Game Freak / The Pokemon Company

## License

GPL-3.0
