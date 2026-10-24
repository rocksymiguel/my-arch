-- Rebote: las ventanas aparecen con un rebote. El nivel lo elige `rebote`
-- (suave, medio, fuerte, exagerado) y se guarda en ~/.cache/theme/rebote
local niveles = {
    suave     = { dampening = 18, overshot = 1.05 },
    medio     = { dampening = 12, overshot = 1.1  },
    fuerte    = { dampening = 8,  overshot = 1.2  },
    exagerado = { dampening = 5,  overshot = 1.35 },
}
local nivel = "medio"
local f = io.open(os.getenv("HOME") .. "/.cache/theme/rebote", "r")
if f then
    local v = f:read("*l")
    f:close()
    if v and niveles[v] then nivel = v end
end
local n = niveles[nivel]

hl.config({ animations = { enabled = true } })
hl.curve("overshot", { type = "bezier", points = { {0.05, 0.9}, {0.1, n.overshot} } })
hl.curve("smooth",   { type = "bezier", points = { {0.25, 0.9}, {0.3, 1} } })
hl.curve("bouncy",   { type = "spring", mass = 1, stiffness = 180, dampening = n.dampening })
hl.animation({ leaf = "global",     enabled = true, speed = 8,   bezier = "default" })
hl.animation({ leaf = "border",     enabled = true, speed = 5,   bezier = "smooth" })
hl.animation({ leaf = "windows",    enabled = true, speed = 5,   spring = "bouncy" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 5,   spring = "bouncy", style = "popin 70%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3,   bezier = "smooth", style = "popin 80%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3,   bezier = "smooth" })
hl.animation({ leaf = "layers",     enabled = true, speed = 4,   bezier = "overshot", style = "popin 80%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5,   bezier = "overshot", style = "slide" })
