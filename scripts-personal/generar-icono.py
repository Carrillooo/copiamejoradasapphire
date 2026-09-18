#!/usr/bin/env python3
"""Genera el icono de Iris en todos los tamaños que pide macOS.

Sin dependencias: escribe los PNG a mano (zlib + CRC32). Se dibuja a 4x y se
reduce por promediado, que es lo que da el suavizado de bordes.

    python3 scripts-personal/generar-icono.py

El icono es un cuadrado redondeado (superelipse, como los de macOS) con degradado
violeta y un iris concéntrico: anillo claro, pupila oscura y un brillo especular.
"""
import math, os, struct, zlib

SS = 4  # supermuestreo


def _srgb(c):
    return max(0, min(255, int(round(c))))


def lerp(a, b, t):
    return a + (b - a) * t


def squircle_inside(x, y, cx, cy, half, n=5.0):
    """Superelipse |dx|^n + |dy|^n <= half^n: el cuadrado redondeado de Apple."""
    dx = abs(x - cx) / half
    dy = abs(y - cy) / half
    if dx > 1.0 or dy > 1.0:
        return False
    return (dx ** n + dy ** n) <= 1.0


def render(size):
    S = size * SS
    buf = bytearray(S * S * 4)

    # El contenido ocupa ~81.6% del lienzo, como los iconos de macOS.
    half = S * 0.816 / 2.0
    cx = cy = S / 2.0

    # Degradado de fondo: índigo profundo -> violeta.
    top = (49, 46, 129)
    bot = (124, 58, 237)

    r_iris = half * 0.52
    r_pupil = half * 0.21
    r_ring_in = half * 0.60
    r_ring_out = half * 0.68

    for py in range(S):
        row = py * S * 4
        t = py / max(1, S - 1)
        br, bg, bb = (lerp(top[i], bot[i], t) for i in range(3))
        for px in range(S):
            if not squircle_inside(px + 0.5, py + 0.5, cx, cy, half):
                continue
            r = br; g = bg; b = bb

            dx = px + 0.5 - cx
            dy = py + 0.5 - cy
            d = math.hypot(dx, dy)

            # Anillo exterior claro.
            if r_ring_in <= d <= r_ring_out:
                r, g, b = lerp(r, 196, .85), lerp(g, 181, .85), lerp(b, 253, .85)

            # Disco del iris, más claro hacia el centro.
            elif d <= r_iris:
                k = 1.0 - (d / r_iris)
                r = lerp(r, 167, .35 + .35 * k)
                g = lerp(g, 139, .35 + .35 * k)
                b = lerp(b, 250, .35 + .35 * k)

                # Estrías radiales: se pierden a 16 px, sólo dan textura arriba.
                if d > r_pupil:
                    stri = math.cos(math.atan2(dy, dx) * 24.0)
                    amt = 0.10 * max(0.0, stri)
                    r = lerp(r, 255, amt); g = lerp(g, 255, amt); b = lerp(b, 255, amt)

            # Pupila.
            if d <= r_pupil:
                k = d / r_pupil
                r = lerp(24, 40, k); g = lerp(20, 34, k); b = lerp(48, 70, k)

            # Brillo especular arriba a la izquierda.
            hx = cx - half * 0.20
            hy = cy - half * 0.22
            hd = math.hypot(px + 0.5 - hx, py + 0.5 - hy)
            hr = half * 0.11
            if hd < hr:
                a = (1.0 - hd / hr) ** 1.6
                r = lerp(r, 255, a * .9); g = lerp(g, 255, a * .9); b = lerp(b, 255, a * .9)

            i = row + px * 4
            buf[i] = _srgb(r); buf[i+1] = _srgb(g); buf[i+2] = _srgb(b); buf[i+3] = 255

    # Reducción por promediado -> suavizado.
    out = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            tr = tg = tb = ta = 0
            for sy in range(SS):
                base = ((y * SS + sy) * S + x * SS) * 4
                for sx in range(SS):
                    i = base + sx * 4
                    a = buf[i+3]
                    tr += buf[i] * a; tg += buf[i+1] * a; tb += buf[i+2] * a; ta += a
            n = SS * SS
            o = (y * size + x) * 4
            if ta:
                out[o] = _srgb(tr / ta); out[o+1] = _srgb(tg / ta); out[o+2] = _srgb(tb / ta)
            out[o+3] = _srgb(ta / n)
    return bytes(out)


def write_png(path, size, rgba):
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    raw = bytearray()
    for y in range(size):
        raw.append(0)  # filtro None
        raw += rgba[y * size * 4:(y + 1) * size * 4]

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


# (tamaño lógico, escala) -> píxeles reales
SPECS = [(16,1),(16,2),(32,1),(32,2),(128,1),(128,2),(256,1),(256,2),(512,1),(512,2)]

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    dest = os.path.join(here, "..", "Sapphire", "Assets.xcassets", "AppIcon.appiconset")
    dest = os.path.normpath(dest)
    os.makedirs(dest, exist_ok=True)

    cache = {}
    images = []
    for logical, scale in SPECS:
        px = logical * scale
        if px not in cache:
            print("  dibujando %dx%d…" % (px, px))
            cache[px] = render(px)
        name = "iris-%d.png" % px
        write_png(os.path.join(dest, name), px, cache[px])
        images.append({
            "filename": name,
            "idiom": "mac",
            "scale": "%dx" % scale,
            "size": "%dx%d" % (logical, logical),
        })

    import json
    with open(os.path.join(dest, "Contents.json"), "w") as f:
        json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)
    print("Icono generado en", dest)


if __name__ == "__main__":
    main()
