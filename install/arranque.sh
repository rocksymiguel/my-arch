#!/bin/bash
# Arranque limpio: de la animación de Plymouth se pasa directo a Hyprland (o a Gamescope) sin ver
# la consola, también al cambiar de modo, y la contraseña del bloqueo desbloquea el llavero.
#   - Plymouth se cierra dejando su última imagen en pantalla hasta que el modo dibuje
#   - sin Plymouth al apagar o reiniciar (solo sale al encender y al cambiar de modo)
#   - el inicio de sesión automático en tty1 no escribe nada
#   - modo-splash: muestra/oculta Plymouth al cambiar de modo (sudo sin contraseña solo para eso)
#   - hyprlock desbloquea el llavero «login» de gnome-keyring con la misma contraseña
#   - Steam (modo juego) puede cambiar el brillo: sudo sin contraseña solo para escribirlo
#   - amdgpu en el initramfs (MODULES y hook kms): Plymouth espera a la gráfica (~5 s en negro tras
#     Limine) y su última imagen se queda hasta el bloqueo. Probado y descartado:
#     · sacar amdgpu del initramfs: tardaba ~9 s y quedaban ~6 s en negro antes del bloqueo
#     · plymouth.use-simpledrm: la animación sale al instante en la pantalla del firmware, pero al
#       llegar amdgpu baja el brillo, la animación empieza otra vez y se pierde la imagen fija
#   - Limine: silencio del kernel, sin consola en tty1 (fbcon=vc:2-6: la imagen de Plymouth se
#     queda hasta que el modo dibuja; consola de emergencia en Ctrl+Alt+F2), cursor oculto y
#     colores (lo hace limine.sh)
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

echo "==> Sin Plymouth al apagar ni al reiniciar"
systemctl mask plymouth-halt.service plymouth-poweroff.service plymouth-reboot.service plymouth-kexec.service

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

echo "==> Brillo desde Steam (gamescope-session usa: sudo tee /sys/class/backlight/<pantalla>/brightness)"
: > /etc/sudoers.d/brillo-steam.tmp
for b in /sys/class/backlight/*/brightness; do
    echo "$U ALL=(root) NOPASSWD: /usr/bin/tee $b" >> /etc/sudoers.d/brillo-steam.tmp
done
chmod 440 /etc/sudoers.d/brillo-steam.tmp
visudo -cf /etc/sudoers.d/brillo-steam.tmp
mv /etc/sudoers.d/brillo-steam.tmp /etc/sudoers.d/brillo-steam

echo "==> Gráfica en el initramfs (Plymouth la usa desde el principio y no se ve negro)"
grep -qE '^MODULES=.*\bamdgpu\b' /etc/mkinitcpio.conf || sed -i -E 's/^MODULES=\((.*)\)/MODULES=(\1 amdgpu)/; s/^MODULES=\( /MODULES=(/' /etc/mkinitcpio.conf
grep -qE '^HOOKS=.*\bkms\b' /etc/mkinitcpio.conf || sed -i -E '/^HOOKS=/ s/ modconf / modconf kms /' /etc/mkinitcpio.conf
grep -E '^(MODULES|HOOKS)' /etc/mkinitcpio.conf
mkinitcpio -P

echo "==> Limine (colores y arranque silencioso)"
bash "$D/limine.sh"
echo "==> LISTO: reinicia para verlo"
