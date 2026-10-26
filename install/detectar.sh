#!/bin/bash
# Detecta el hardware del equipo. No se ejecuta solo: lo cargan los demás scripts con
#   source "$D/detectar.sh"
# y deja estas variables:
#   GPUS       gráficas encontradas: amd, nvidia, intel (puede haber varias, p. ej. intel nvidia)
#   VIRT       none en un equipo real; vmware, oracle, kvm, microsoft… en una máquina virtual
#   PORTATIL   si / no (si tiene batería)
#   RES        resolución de la pantalla principal, p. ej. 1366x768 (1920x1080 si no se sabe)
#   TAMANO     tamaño de la interfaz que le va (% del menú Tamaño), según la densidad de la pantalla
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
RES=""; CM=0
for c in /sys/class/drm/card*-*; do
    [ "$(cat "$c/status" 2>/dev/null)" = connected ] || continue
    RES="$(head -n1 "$c/modes" 2>/dev/null)"
    CM="$(od -An -tu1 -j21 -N1 "$c/edid" 2>/dev/null | tr -d ' ')"   # ancho físico en cm (EDID)
    [ -n "$RES" ] && break
done
RES="${RES:-1920x1080}"

# Tamaño de la interfaz: la Lenovo (1366 px en 34 cm, ~102 ppp) es el 100 %. Un monitor de
# escritorio se mira de más lejos: +10 %. Se redondea al valor del menú más cercano.
TAMANO=100
if [ "${CM:-0}" -gt 0 ] 2>/dev/null; then
    t=$(( ${RES%x*} * 254 / CM * 100 / 102 / 100 ))   # ppp relativo a 102, en %
    [ "$PORTATIL" = no ] && t=$(( t * 110 / 100 ))
    for v in 50 75 90 100 110 125 150 175 200; do
        [ $(( (v - t) * (v - t) )) -lt $(( (TAMANO - t) * (TAMANO - t) )) ] && TAMANO=$v
    done
fi

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
    echo "Pantalla:  $RES · tamaño de la interfaz: $TAMANO %"
    echo "initramfs: ${KMS:-(nada)}"
    echo "EFI:       $EFI_DISCO partición $EFI_PART"
}
