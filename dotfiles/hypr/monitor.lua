-- MONITORS

local MAIN_SCALING = 1.5


hl.monitor({
    output = "",
    mode = "3840x2160@144",
    position = "auto",
    scale = MAIN_SCALING,
})

hl.config({
  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

