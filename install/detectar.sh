#!/bin/bash
# Detecta el hardware del equipo. No se ejecuta solo: lo cargan los demás scripts con
#   source "$D/detectar.sh"
# y deja estas variables:
#   GPUS       gráficas encontradas: amd, nvidia, intel (puede haber varias, p. ej. intel nvidia)
#   VIRT       none en un equipo real; vmware, oracle, kvm, microsoft… en una máquina virtual
#   PORTATIL   si / no (si tiene batería)
#   RES        resolución de la pantalla principal, p. ej. 1366x768 (1920x1080 si no se sabe)
#   KMS        módulos de la gráfica para el initramfs, p. ej. "amdgpu"
#   EFI_DISCO, EFI_PART   disco y número de partición de /boot (para efibootmgr)

GPUS=""
while read -r id; do
    case "$id" in
        1002:*) GPUS+=" amd" ;;
        10de:*) GPUS+=" nvidia" ;;
        8086:*) GPUS+=" intel" ;;
    esac
done < <( { lspci -n -d ::0300; lspci -n -d ::0302; lspci -n -d ::0380; } 2>/dev/null | awk '{print $3}')
GPUS="$(echo "$GPUS" | tr ' ' '\n' | sort -u | paste -sd' ')"
GPUS="${GPUS# }"

VIRT="$(systemd-detect-virt 2>/dev/null || true)"
VIRT="${VIRT:-none}"

PORTATIL=no
ls /sys/class/power_supply/BAT* >/dev/null 2>&1 && PORTATIL=si

# Primer modo (el preferido) de la primera pantalla conectada
RES=""
for c in /sys/class/drm/card*-*; do
    [ "$(cat "$c/status" 2>/dev/null)" = connected ] || continue
    RES="$(head -n1 "$c/modes" 2>/dev/null)"
    [ -n "$RES" ] && break
done
RES="${RES:-1920x1080}"

KMS=""
[ "$VIRT" = none ] && for g in $GPUS; do
    case "$g" in
        amd) KMS+=" amdgpu" ;;
        intel) KMS+=" i915" ;;
        nvidia) KMS+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm" ;;
    esac
done
KMS="${KMS# }"

EFI_PART_DEV="$(findmnt -no SOURCE /boot 2>/dev/null || true)"
EFI_DISCO="/dev/$(lsblk -no PKNAME "$EFI_PART_DEV" 2>/dev/null | head -n1)"
EFI_PART="$(cat "/sys/class/block/$(basename "$EFI_PART_DEV")/partition" 2>/dev/null || echo 1)"

resumen_hardware() {
    echo "Gráfica:   ${GPUS:-ninguna detectada}"
    echo "Virtual:   $VIRT"
    echo "Portátil:  $PORTATIL"
    echo "Pantalla:  $RES"
    echo "initramfs: ${KMS:-(nada)}"
    echo "EFI:       $EFI_DISCO partición $EFI_PART"
}
