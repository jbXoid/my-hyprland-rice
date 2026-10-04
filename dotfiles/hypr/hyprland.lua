-- My Hyprland config :)

               --####    #### 
               --####    ####
               --####    ####

               --############
               --############
               --############
            	--##########

-- Monitor configuration
-- Source: ~/.config/hypr/monitor.conf — convert this file to Lua and ensure it is on Lua's package.path.
require("monitor")

-- Default programs
-- Source: ~/.config/hypr/defaultProgs.conf — convert this file to Lua and ensure it is on Lua's package.path.
require("defaultProgs")

-- Autostart
-- Source: ~/.config/hypr/autostart.conf — convert this file to Lua and ensure it is on Lua's package.path.
require("autostart")

-- Env configuration
-- Source: ~/.config/hypr/env.conf — convert this file to Lua and ensure it is on Lua's package.path.
require("env")

-- Appearance configuration
-- Source: ~/.config/hypr/appearance.conf — convert this file to Lua and ensure it is on Lua's package.path.
require("appearance")

-- Keybinds configuration
-- Source: ~/.config/hypr/keybinds.conf — convert this file to Lua and ensure it is on Lua's package.path.
require("keybinds")

-- Input configuration
-- Source: ~/.config/hypr/input.conf — convert this file to Lua and ensure it is on Lua's package.path.
require("input")

-- Windows configuration. Not OS. Windows is shitty microslop product...
-- Source: ~/.config/hypr/windows.conf — convert this file to Lua and ensure it is on Lua's package.path.
require("windows")

