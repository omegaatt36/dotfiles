local wezterm = require 'wezterm'
local config = {}
config.font = wezterm.font_with_fallback({'MesloLGS Nerd Font', 'Noto Color Emoji', 'Noto Sans CJK TC'})
config.color_scheme = 'nord'
config.font_size = 14.0
config.hide_mouse_cursor_when_typing = true
config.window_background_opacity = 0.85
config.window_padding = {
    bottom = 0,
    left = 0,
    right = 0,
    top = 0,
}

config.hide_tab_bar_if_only_one_tab = true
config.enable_tab_bar = false

config.default_prog = {"/bin/zsh", "-l", "-c", 'tmux attach || tmux -l'}

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    return 'Tab ' .. tab.tab_index
end)
wezterm.on('format-window-title', function(tab, pane, tabes, panes, config)
    return 'WezTerm ' .. wezterm.version
end)
return config
