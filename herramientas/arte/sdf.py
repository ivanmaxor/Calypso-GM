# -*- coding: utf-8 -*-
"""Mini motor "3D a pixel art" sin dependencias raras: solo numpy y PIL.

Idea (la misma de Dead Cells, pero por codigo): el enemigo es un modelo 3D hecho
con formas simples. Se renderiza a muy baja resolucion, con luz por escalones y
una paleta cerrada, y se le pone borde. Como es 3D, las animaciones salen solas:
basta con cambiar un parametro y volver a renderizar.
"""
import numpy as np
from PIL import Image


def _dot(a, b):
    return (a * b).sum(-1)


def _len(a):
    return np.sqrt(_dot(a, a))


def _v(*x):
    return np.array(x, dtype=np.float64)


def _norm(v):
    return v / np.linalg.norm(v)


# --- primitivas (p: array Nx3) ---------------------------------------------
def esfera(p, c, r):
    return _len(p - _v(*c)) - r


def elipsoide(p, c, r):
    r = _v(*r)
    q = (p - _v(*c))
    k0 = _len(q / r)
    k1 = _len(q / (r * r))
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-6)


def capsula(p, a, b, r):
    a, b = _v(*a), _v(*b)
    pa, ba = p - a, b - a
    h = np.clip(_dot(pa, ba) / _dot(ba, ba), 0, 1)
    return _len(pa - ba * h[..., None]) - r


def caja(p, c, b, redondeo=0.0):
    q = np.abs(p - _v(*c)) - (_v(*b) - redondeo)
    return _len(np.maximum(q, 0)) + np.minimum(q.max(-1), 0) - redondeo


def cono_truncado(p, a, b, ra, rb):
    a, b = _v(*a), _v(*b)
    rba = rb - ra
    ba = b - a
    baba = _dot(ba, ba)
    pa = p - a
    papa = _dot(pa, pa)
    paba = _dot(pa, ba) / baba
    x = np.sqrt(np.maximum(papa - paba * paba * baba, 0))
    cax = np.maximum(0, x - np.where(paba < 0.5, ra, rb))
    cay = np.abs(paba - 0.5) - 0.5
    k = rba * rba + baba
    f = np.clip((rba * (x - ra) + paba * baba) / k, 0, 1)
    cbx = x - ra - f * rba
    cby = paba - f
    s = np.where((cbx < 0) & (cay < 0), -1.0, 1.0)
    return s * np.sqrt(np.minimum(cax * cax + cay * cay * baba, cbx * cbx + cby * cby * baba))


def toro(p, c, eje, R, r):
    q = p - _v(*c)
    n = _norm(_v(*eje))
    h = _dot(q, n)
    d = np.sqrt(np.maximum(_dot(q, q) - h * h, 0)) - R
    return np.sqrt(d * d + h * h) - r


def cilindro(p, a, b, r):
    a, b = _v(*a), _v(*b)
    ba = b - a
    pa = p - a
    baba = _dot(ba, ba)
    paba = _dot(pa, ba)
    x = _len(pa * baba - ba * paba[..., None]) - r * baba
    y = np.abs(paba - baba * 0.5) - baba * 0.5
    x2 = x * x
    y2 = y * y * baba
    d = np.where(np.maximum(x, y) < 0, -np.minimum(x2, y2), np.where(x > 0, x2, 0) + np.where(y > 0, y2, 0))
    return np.sign(d) * np.sqrt(np.abs(d)) / baba


def resta(a, b):
    return np.maximum(a, -b)


def union_suave(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
    return b + (a - b) * h - k * h * (1 - h)


def rot_x(p, ang):
    c, s = np.cos(ang), np.sin(ang)
    return np.stack([p[..., 0], c * p[..., 1] - s * p[..., 2], s * p[..., 1] + c * p[..., 2]], -1)


def rot_y(p, ang):
    c, s = np.cos(ang), np.sin(ang)
    return np.stack([c * p[..., 0] + s * p[..., 2], p[..., 1], -s * p[..., 0] + c * p[..., 2]], -1)


def rot_z(p, ang):
    c, s = np.cos(ang), np.sin(ang)
    return np.stack([c * p[..., 0] - s * p[..., 1], s * p[..., 0] + c * p[..., 1], p[..., 2]], -1)


# --- paleta -----------------------------------------------------------------
def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


class Rampa:
    """Colores de oscuro a claro. emisiva=True: no le afecta la luz."""

    def __init__(self, colores, emisiva=False, curva=1.0, mate=False):
        self.c = [hex2rgb(x) for x in colores]
        self.emisiva = emisiva
        self.curva = curva
        self.mate = mate


CONTORNO = hex2rgb("#0d0a18")


def _escena_mat(escena, p):
    ds = escena(p)  # lista de (dist, id_material)
    d = np.stack([x[0] for x in ds], 0)
    i = d.argmin(0)
    dmin = np.take_along_axis(d, i[None], 0)[0]
    return dmin, np.array([x[1] for x in ds])[i]


def _normal(escena, p, e=0.012):
    n = np.zeros_like(p)
    for k in range(3):
        o = np.zeros(3)
        o[k] = e
        n[..., k] = _escena_mat(escena, p + o)[0] - _escena_mat(escena, p - o)[0]
    return n / np.maximum(_len(n)[..., None], 1e-9)


def renderizar(escena, rampas, ancho, alto=None, encuadre=1.0, centro=(0, 0), inclinacion=0.0,
               luz=(-0.55, 0.75, 0.6), borde_rim=(0.75, -0.55, 0.25), ss=3, contorno=True,
               oscuro_interior=True, devolver_codigo=False):
    """Devuelve RGBA uint8. encuadre: mitad del ancho visible en unidades del modelo."""
    alto = alto or ancho
    W, H = ancho * ss, alto * ss
    xs = (np.arange(W) + 0.5) / W * 2 - 1
    ys = 1 - (np.arange(H) + 0.5) / H * 2
    asp = alto / ancho
    X, Y = np.meshgrid(xs * encuadre + centro[0], ys * encuadre * asp + centro[1])
    o = np.stack([X, Y, np.full_like(X, 3.0)], -1).reshape(-1, 3)
    d = np.tile(_v(0, 0, -1.0), (o.shape[0], 1))
    if inclinacion:
        o = rot_x(o, inclinacion)
        d = rot_x(d, inclinacion)
    t = np.zeros(o.shape[0])
    golpe = np.zeros(o.shape[0], bool)
    vivo = np.ones(o.shape[0], bool)
    for _ in range(70):
        if not vivo.any():
            break
        p = o[vivo] + d[vivo] * t[vivo][:, None]
        dd, _m = _escena_mat(escena, p)
        idx = np.where(vivo)[0]
        t[idx] += dd * 0.9
        g = dd < 0.003
        golpe[idx[g]] = True
        vivo[idx[g]] = False
        fuera = t[idx] > 7.0
        vivo[idx[fuera]] = False

    L = _norm(_v(*luz))
    R = _norm(_v(*borde_rim))
    V = _norm(_v(0, 0, 1))
    Hh = _norm(L + V)
    color_idx = np.full(o.shape[0], -1, dtype=np.int32)  # codigo = mat*16 + tono
    prof = np.full(o.shape[0], 99.0)
    mat_px = np.full(o.shape[0], -1, dtype=np.int32)
    if golpe.any():
        p = o[golpe] + d[golpe] * t[golpe][:, None]
        n = _normal(escena, p)
        _d, m = _escena_mat(escena, p)
        dif = np.clip(_dot(n, L), 0, 1)
        # oclusion barata
        ao = np.clip(_escena_mat(escena, p + n * 0.09)[0] / 0.09, 0, 1)
        val = 0.16 + 0.78 * dif * (0.55 + 0.45 * ao)
        esp = np.clip(_dot(n, Hh), 0, 1) ** 28
        rim = np.clip(_dot(n, R), 0, 1) ** 3
        tono = np.zeros(p.shape[0], dtype=np.int32)
        for mi, r in enumerate(rampas):
            sel = m == mi
            if not sel.any():
                continue
            N = len(r.c)
            if r.emisiva:
                # el centro de la forma brilla mas (mira de frente)
                v = np.clip(_dot(n[sel], V), 0, 1) ** r.curva
                tono[sel] = np.clip((v * N).astype(int), 0, N - 1)
            else:
                v = val[sel] ** r.curva
                x = np.clip((v * N).astype(int), 0, N - 2)
                if not r.mate:
                    x = np.where(esp[sel] > 0.72, N - 1, x)
                # luz de rebote: sube un tono en el lado contrario a la luz
                x = np.where((rim[sel] > 0.45) & (x <= 1), x + 1, x)
                tono[sel] = x
        color_idx[golpe] = m * 16 + tono
        prof[golpe] = t[golpe]
        mat_px[golpe] = m

    color_idx = color_idx.reshape(H, W)
    prof = prof.reshape(H, W)
    # reduccion por moda: el color mas repetido de cada celda (sin mezclar colores)
    salida = np.zeros((alto, ancho, 4), dtype=np.uint8)
    codigo = np.full((alto, ancho), -1, dtype=np.int32)
    pr = np.full((alto, ancho), 99.0)
    for y in range(alto):
        for x in range(ancho):
            celda = color_idx[y * ss:(y + 1) * ss, x * ss:(x + 1) * ss].ravel()
            llenos = celda[celda >= 0]
            if llenos.size * 2 < celda.size:
                continue
            v, c = np.unique(llenos, return_counts=True)
            codigo[y, x] = v[c.argmax()]
            pr[y, x] = prof[y * ss:(y + 1) * ss, x * ss:(x + 1) * ss].min()
    for y in range(alto):
        for x in range(ancho):
            k = codigo[y, x]
            if k < 0:
                continue
            m, ton = k // 16, k % 16
            salida[y, x, :3] = rampas[m].c[ton]
            salida[y, x, 3] = 255
    # borde interior: un tono mas oscuro donde hay salto de profundidad
    if oscuro_interior:
        copia = salida.copy()
        for y in range(alto):
            for x in range(ancho):
                k = codigo[y, x]
                if k < 0:
                    continue
                m, ton = k // 16, k % 16
                if rampas[m].emisiva:
                    continue
                for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < ancho and 0 <= ny < alto and codigo[ny, nx] >= 0:
                        if pr[y, x] - pr[ny, nx] > 0.22:  # este pixel esta detras
                            copia[y, x, :3] = rampas[m].c[0]
                            break
        salida = copia
    # contorno exterior
    if contorno:
        a = salida[..., 3] > 0
        vec = np.zeros_like(a)
        vec[1:, :] |= a[:-1, :]
        vec[:-1, :] |= a[1:, :]
        vec[:, 1:] |= a[:, :-1]
        vec[:, :-1] |= a[:, 1:]
        anillo = vec & ~a
        salida[anillo, :3] = CONTORNO
        salida[anillo, 3] = 255
    if devolver_codigo:
        return salida, codigo
    return salida


def a_imagen(arr):
    return Image.fromarray(arr, "RGBA")


def escalar(im, k):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def poligono(p, pts, h, r=0.0):
    """Silueta 2D (en el plano XY) con grosor h en Z. r redondea los bordes."""
    pts = np.array(pts, dtype=np.float64)
    x = p[..., :2]
    d = ((x - pts[0]) ** 2).sum(-1)
    s = np.ones(d.shape)
    n = len(pts)
    for i in range(n):
        j = (i - 1) % n
        e = pts[j] - pts[i]
        w = x - pts[i]
        t = np.clip((w * e).sum(-1) / (e * e).sum(), 0, 1)
        b = w - e * t[..., None]
        d = np.minimum(d, (b * b).sum(-1))
        c1 = x[..., 1] >= pts[i, 1]
        c2 = x[..., 1] < pts[j, 1]
        c3 = e[0] * w[..., 1] > e[1] * w[..., 0]
        vuelta = (c1 & c2 & c3) | (~c1 & ~c2 & ~c3)
        s = np.where(vuelta, -s, s)
    d2 = s * np.sqrt(d)
    wx = d2
    wy = np.abs(p[..., 2]) - h
    return np.minimum(np.maximum(wx, wy), 0) + np.sqrt(np.maximum(wx, 0) ** 2 + np.maximum(wy, 0) ** 2) - r
