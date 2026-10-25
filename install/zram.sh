#!/bin/bash
# Ajustes del kernel para swap en zram (memoria comprimida), como recomienda la wiki de Arch:
# con zram, mover a swap es barato, así que conviene hacerlo antes y de página en página.
# Uso:  sudo bash ~/my-arch/install/zram.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Ejecútalo con sudo: sudo bash $0" >&2; exit 1; }

cat > /etc/sysctl.d/99-zram.conf <<'CONF'
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
CONF
sysctl -q --system
sysctl vm.swappiness vm.page-cluster
