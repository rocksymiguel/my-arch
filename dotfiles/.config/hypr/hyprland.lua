-- Configuración de Hyprland para la Lenovo IdeaPad 3 (Ryzen 5 3500U, Vega 8)
-- Basada en el ejemplo oficial: /usr/share/hypr/hyprland.lua
-- Wiki: https://wiki.hypr.land/Configuring/Start/

-- Colores del tema activo; los genera `tema` en ~/.config/hypr/colors.lua
local theme = dofile(os.getenv("HOME") .. "/.config/hypr/colors.lua")

------------------
---- MONITORS ----
------------------
-- Pantalla de la laptop a 1:1; cualquier monitor externo, en automático.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "fuzzel"
local browser     = "zen-browser"

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("sleep 1 && waypaper --restore")
    -- Cursor y fuente para las apps GTK; claro/oscuro e iconos los pone `tema`
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 9'")
    hl.exec_cmd("sleep 2 && ~/.config/theme/tema \"$(~/.config/theme/tema actual)\"")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-----------------------
---- LOOK AND FEEL ----
-----------------------
-- Separación compacta, borde de 2 con degradado del tema y efecto vidrio.
hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 6,
        border_size = 2,
        col = {
            active_border   = { colors = { theme.accent, theme.accent2 }, angle = 45 },
            inactive_border = theme.border_off,
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "scrolling", -- columnas que se desplazan de lado, al estilo Niri
    },
    decoration = {
        rounding       = 10,
        rounding_power = 2,
        active_opacity   = theme.win_active,
        inactive_opacity = theme.win_inactive,
        fullscreen_opacity = 1.0, -- vídeos y juegos a pantalla completa, siempre opacos
        dim_inactive     = theme.dim,
        dim_strength     = theme.dim_strength,
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },
        blur = {
            enabled   = true,
            size      = theme.blur_size,
            passes    = theme.blur_passes,
            vibrancy  = 0.1696,
            noise     = 0.02,
            popups    = true,
        },
    },
})

-- Animaciones con rebote medio
dofile(os.getenv("HOME") .. "/.config/hypr/animaciones.lua")

----------------
----  MISC  ----
----------------
hl.config({
    misc = {
        force_default_wallpaper = 0,    -- sin los fondos de Hyprland: los pone `tema`
        disable_hyprland_logo   = true,
    },
})

---------------
---- INPUT ----
---------------
-- Teclado US; touchpad con toque para clic y desplazamiento clásico.
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll       = false,
            tap_to_click         = true,
            disable_while_typing = true,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

-- Apps: Enter = terminal, Espacio = lanzador, Z = Zen, T = Thunar, F = Feishin
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Space",  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + Z",      hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F",      hl.dsp.exec_cmd("feishin"))

-- Ventanas: Q = cerrar, SHIFT + Q = forzar cierre, B = pantalla completa, SHIFT + B = maximizar
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill())
hl.bind(mainMod .. " + B",         hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Bloquear, fondos y portapapeles
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("waypaper"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))

-- Capturas: Impr = zona al portapapeles; SHIFT + Impr = pantalla completa a ~/Imágenes/Capturas
hl.bind("Print",         hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("mkdir -p ~/Imágenes/Capturas && grim ~/Imágenes/Capturas/$(date +%Y-%m-%d_%H-%M-%S).png"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Teclas Fn: volumen, micrófono, brillo y multimedia
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Tapa: al cerrarla se apaga la pantalla interna; al abrirla vuelve.
hl.bind("switch:on:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = true })
end, { locked = true })
hl.bind("switch:off:Lid Switch", function()
    hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })
end, { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Ventanas pequeñas que van mejor flotando
hl.window_rule({
    name  = "float-tools",
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|waypaper|nwg-look)$" },
    float = true,
})

-- Efecto vidrio en la barra, el lanzador y las notificaciones
hl.layer_rule({
    name  = "glass-layers",
    match = { namespace = "^(waybar|launcher|notifications)$" },
    blur  = true,
    ignore_alpha = 0.2,
})

-- Opacidad propia de kitty (activa / inactiva), según el modo de vidrio
hl.window_rule({
    name    = "kitty-opacity",
    match   = { class = "^kitty$" },
    opacity = theme.kitty_active .. " " .. theme.kitty_inactive,
})

-- Ventanas de "Abrir", "Guardar" y "Seleccionar": flotando y centradas
hl.window_rule({
    name   = "dialogos-centrados",
    match  = { title = "^(Abrir|Guardar|Seleccionar|Open|Save|Select).*" },
    float  = true,
    center = true,
})

-- Progreso de copias en Thunar: flotando
hl.window_rule({
    name  = "thunar-progreso",
    match = { class = "^thunar$", title = "^(Progreso|File Operation).*" },
    float = true,
})

-- Vídeo flotante de Zen (imagen en imagen): siempre visible, abajo a la derecha
hl.window_rule({
    name  = "zen-pip",
    match = { title = "^(Picture-in-Picture|Imagen en imagen)$" },
    float = true,
    pin   = true,
    size  = "480 270",
    move  = "monitor_w-490 monitor_h-280",
})

-- No bajar el brillo ni bloquear mientras haya algo a pantalla completa (vídeos)
hl.window_rule({
    name  = "no-dormir-pantalla-completa",
    match = { class = ".*" },
    idle_inhibit = "fullscreen",
})
