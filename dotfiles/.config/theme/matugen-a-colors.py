#!/usr/bin/env python3
"""Convierte la salida JSON de `matugen image ... --json hex` en los acentos del fondo.

Solo salen el acento y el segundo acento (bordes de ventana, barra, lanzador...);
fondos, superficies y texto los pone el modo (oscuro o claro).
"""
import json
import sys

colors = json.load(sys.stdin)["colors"]


def c(name):
    return colors[name]["default"]["color"].lstrip("#")


print("# Acentos sacados del fondo actual con matugen")
print(f"accent={c('primary')}")
print(f"accent2={c('tertiary')}")
