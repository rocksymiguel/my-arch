#!/usr/bin/env python3
"""Convierte la salida JSON de `matugen image ... --json hex` en un archivo .colors del tema."""
import json
import sys

d = json.load(sys.stdin)
colors = d["colors"]
base16 = d.get("base16", {})


def c(name, fallback):
    try:
        return colors[name]["default"]["color"].lstrip("#")
    except KeyError:
        return fallback


def b(name, fallback):
    try:
        return base16[name]["default"]["color"].lstrip("#")
    except KeyError:
        return fallback


valores = {
    "bg": c("surface_container_lowest", c("background", "1f232b")),
    "bg_alt": c("surface_container_low", "272c36"),
    "surface": c("surface_container", "2b303b"),
    "surface_hi": c("surface_container_highest", "3b4252"),
    "border_off": c("outline_variant", "434c5e"),
    "text": c("on_surface", "eceff4"),
    "muted": c("on_surface_variant", "8a93a6"),
    "accent": c("primary", "88c0d0"),
    "accent2": c("tertiary", "5e81ac"),
    "ok": "a3be8c",
    "warn": "ebcb8b",
    "err": c("error", "bf616a"),
    "purple": c("secondary", "b48ead"),
    "ansi_black": c("surface_container_highest", "3b4252"),
    "ansi_white": c("on_surface_variant", "e5e9f0"),
    "scheme": "dark",
    "icons": "Papirus-Dark",
    "gtk": "Nordic",
    "cursor": "Bibata-Modern-Ice",
    "carpetas": "bluegrey",
}

print("# Generado por matugen a partir del fondo actual")
for k, v in valores.items():
    print(f"{k}={v}")
