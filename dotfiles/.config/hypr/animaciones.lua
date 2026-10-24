-- Animaciones con rebote medio: las ventanas aparecen con un rebote corto.
-- Más rebote: bajar dampening (8 fuerte, 5 exagerado) y subir el 1.1 de overshot.
hl.config({ animations = { enabled = true } })
hl.curve("overshot", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.1} } })
hl.curve("smooth",   { type = "bezier", points = { {0.25, 0.9}, {0.3, 1} } })
hl.curve("bouncy",   { type = "spring", mass = 1, stiffness = 180, dampening = 12 })
hl.animation({ leaf = "global",     enabled = true, speed = 8,   bezier = "default" })
hl.animation({ leaf = "border",     enabled = true, speed = 5,   bezier = "smooth" })
hl.animation({ leaf = "windows",    enabled = true, speed = 5,   spring = "bouncy" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 5,   spring = "bouncy", style = "popin 70%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3,   bezier = "smooth", style = "popin 80%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3,   bezier = "smooth" })
hl.animation({ leaf = "layers",     enabled = true, speed = 4,   bezier = "overshot", style = "popin 80%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5,   bezier = "overshot", style = "slide" })
