#!/bin/bash
# Arranque limpio: de la animación de Plymouth se pasa directo a Hyprland (o a Gamescope) sin ver
# la consola, también al cambiar de modo, y la contraseña del bloqueo desbloquea el llavero.
#   - Plymouth se cierra dejando su última imagen en pantalla hasta que el modo dibuje
#   - el inicio de sesión automático en tty1 no escribe nada
#   - modo-splash: muestra/oculta Plymouth al cambiar de modo (sudo sin contraseña solo para eso)
#   - hyprlock desbloquea el llavero «login» de gnome-keyring con la misma contraseña
#   - Limine: silencio del kernel, cursor oculto y colores (lo hace limine.sh)
# Ejecutar con: sudo bash ~/my-arch/install/arranque.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ] || { echo "Ejecuta con: sudo bash ~/my-arch/install/arranque.sh"; exit 1; }
U="$SUDO_USER"
D="$(getent passwd "$U" | cut -d: -f6)/my-arch/install"

echo "==> Plymouth deja su última imagen al terminar el arranque"
mkdir -p /etc/systemd/system/plymouth-quit.service.d
cat > /etc/systemd/system/plymouth-quit.service.d/conservar.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/usr/bin/plymouth quit --retain-splash
EOF

echo "==> Inicio de sesión automático en tty1 sin texto"
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\\\u' --noclear --noissue --nohostname --nonewline --skip-login --autologin $U %I \$TERM
EOF
systemctl daemon-reload

echo "==> modo-splash: Plymouth entre un modo y otro"
cat > /usr/local/bin/modo-splash <<'EOF'
#!/bin/sh
# Plymouth entre modos (lo llama modo-bin con sudo; solo admite estas dos órdenes)
case "$1" in
    mostrar) plymouthd --mode=boot && plymouth show-splash ;;
    ocultar) plymouth quit --retain-splash ;;
    *) echo "Uso: modo-splash mostrar|ocultar" >&2; exit 1 ;;
esac
EOF
chmod 755 /usr/local/bin/modo-splash
echo "$U ALL=(root) NOPASSWD: /usr/local/bin/modo-splash mostrar, /usr/local/bin/modo-splash ocultar" > /etc/sudoers.d/modo-splash.tmp
chmod 440 /etc/sudoers.d/modo-splash.tmp
visudo -cf /etc/sudoers.d/modo-splash.tmp
mv /etc/sudoers.d/modo-splash.tmp /etc/sudoers.d/modo-splash

echo "==> hyprlock desbloquea el llavero"
grep -q pam_gnome_keyring /etc/pam.d/hyprlock || echo "auth        optional    pam_gnome_keyring.so" >> /etc/pam.d/hyprlock
cat /etc/pam.d/hyprlock

echo "==> Limine (colores y arranque silencioso)"
bash "$D/limine.sh"
echo "==> LISTO: reinicia para verlo"
