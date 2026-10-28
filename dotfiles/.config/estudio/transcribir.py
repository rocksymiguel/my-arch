#!/usr/bin/env python3
"""Transcribe un audio (una clase grabada) a un apunte en Markdown, todo en local (faster-whisper).

    transcribir <audio> [modelo]

modelo: tiny | base (por defecto) | small | medium. Más grande = mejor español y más lento y más RAM
(small necesita unos 2 GB libres). El apunte queda en Transcripciones/ del vault, con marcas de tiempo.
Al terminar enseña cuánto tardó y la RAM máxima que usó, para decidir qué modelo conviene.
"""
import os
import resource
import sys
import time

MODELOS = ("tiny", "base", "small", "medium")
VAULT = os.environ.get("VAULT_ESTUDIO", os.path.expanduser("~/Documentos/obsidian-vault/rocksymiguel"))


def hms(s):
    s = int(s)
    return f"{s // 3600:02d}:{s % 3600 // 60:02d}:{s % 60:02d}"


def ram_libre_mib():
    for linea in open("/proc/meminfo"):
        if linea.startswith("MemAvailable:"):
            return int(linea.split()[1]) // 1024
    return 0


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        return 1
    audio = os.path.abspath(sys.argv[1])
    modelo = sys.argv[2] if len(sys.argv) > 2 else "base"
    if not os.path.isfile(audio):
        print(f"No encuentro el audio: {audio}")
        return 1
    if modelo not in MODELOS:
        print(f"Modelo desconocido: {modelo} (usa {', '.join(MODELOS)})")
        return 1
    necesita = {"tiny": 600, "base": 800, "small": 2000, "medium": 4500}[modelo]
    libre = ram_libre_mib()
    if libre < necesita:
        print(f"Aviso: hay {libre} MiB libres y «{modelo}» pide unos {necesita}. "
              f"Cierra programas o usa un modelo más pequeño.", file=sys.stderr)

    from faster_whisper import WhisperModel

    t0 = time.time()
    print(f"Cargando el modelo «{modelo}» (la primera vez lo descarga)…", file=sys.stderr)
    m = WhisperModel(modelo, device="cpu", compute_type="int8", cpu_threads=min(4, os.cpu_count() or 2))
    t_carga = time.time() - t0

    t1 = time.time()
    segmentos, info = m.transcribe(audio, language="es", vad_filter=True, beam_size=5)
    lineas, ultimo = [], -30
    for s in segmentos:
        lineas.append(f"**[{hms(s.start)}]** {s.text.strip()}")
        if s.end - ultimo >= 30:
            print(f"  … {hms(s.end)} de {hms(info.duration)}", file=sys.stderr)
            ultimo = s.end
    t_trans = time.time() - t1

    nombre = os.path.splitext(os.path.basename(audio))[0]
    destino = os.path.join(VAULT, "Transcripciones")
    os.makedirs(destino, exist_ok=True)
    salida = os.path.join(destino, f"{nombre}.md")
    with open(salida, "w", encoding="utf-8") as f:
        f.write(f"---\nfecha: {time.strftime('%Y-%m-%d')}\naudio: {os.path.basename(audio)}\n"
                f"modelo: {modelo}\nduracion: {hms(info.duration)}\n---\n\n# Transcripción: {nombre}\n\n")
        f.write("\n\n".join(lineas) + "\n")

    pico = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss // 1024
    veces = info.duration / t_trans if t_trans else 0
    print(f"\nListo: {salida}")
    print(f"Audio de {hms(info.duration)} transcrito en {hms(t_trans)} "
          f"({veces:.1f}× el tiempo real; carga del modelo {t_carga:.0f} s). "
          f"RAM máxima del proceso: {pico} MiB.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
