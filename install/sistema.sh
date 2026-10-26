#!/bin/bash
# Herramientas del menú de ajustes (⚙ → Sistema) que necesitan root:
#   - /usr/local/bin/limpiar-sistema: copia de install/limpiar.sh, de root, que el menú ejecuta
#     en segundo plano sin pedir contraseña (sudoers solo para esa copia; la del repo la puede
#     editar el usuario, por eso no se permite directamente)
# Vuelve a ejecutarlo si cambias install/limpiar.sh.
# Ejecutar con: sudo bash ~/my-arch/install/sistema.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ] || { echo "Ejecuta con: sudo bash ~/my-arch/install/sistema.sh"; exit 1; }
U="$SUDO_USER"
D="$(getent passwd "$U" | cut -d: -f6)/my-arch/install"

echo "==> Limpiar desde los ajustes, sin contraseña"
install -o root -g root -m 755 "$D/limpiar.sh" /usr/local/bin/limpiar-sistema
echo "$U ALL=(root) NOPASSWD: /usr/local/bin/limpiar-sistema" > /etc/sudoers.d/limpiar-sistema.tmp
chmod 440 /etc/sudoers.d/limpiar-sistema.tmp
visudo -cf /etc/sudoers.d/limpiar-sistema.tmp
mv /etc/sudoers.d/limpiar-sistema.tmp /etc/sudoers.d/limpiar-sistema
echo "==> LISTO"
