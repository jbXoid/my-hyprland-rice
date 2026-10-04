-- AUTOSTART

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar & hyprpaper & pipewire-pulse & hypridle &")
    hl.exec_cmd("swayosd-server &")
    hl.exec_cmd("~/.config/hypr/watchers_scripts/bat_check.sh &")

end)

