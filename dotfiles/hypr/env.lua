-- ENVIRONMENT VARIABLES

MAIN_SCALING=2

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_SCALE", MAIN_SCALING*0.75)

hl.env("HYPRSHOT_DIR", "Pictures/Screenshots")

hl.env("GTK_THEME","Adwaita:dark")
hl.env("QT_QPA_PLATFORMTHEME","qt5ct")
hl.env("QT_STYLE_OVERRIDE","kvantum")
hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme \"prefer-dark\"")
hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme \"Adwaita-dark\"")
