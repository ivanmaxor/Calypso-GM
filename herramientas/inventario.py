# -*- coding: utf-8 -*-
"""Genera memorias/inventario.md desde el volcado de los catálogos (ver volcar_catalogos.gd).
Así el inventario sale del código y no se desactualiza a mano.
Uso: python herramientas/inventario.py <catalogos.json> <salida.md>
"""
import json
import sys

d = json.load(open(sys.argv[1], encoding="utf-8"))
salida = sys.argv[2]
L = []


def w(s=""):
    L.append(s)


def celda(s):
    return str(s).replace("|", "/").replace("\n", " ")


def num(v):
    if isinstance(v, float):
        return ("%.2f" % v).rstrip("0").rstrip(".").replace(".", ",")
    return str(v)


ARMAS, HABS = d["armas"], d["habilidades"]
base = d["base_por_mundo"]
como = {}  # id -> cómo se consigue
for i, b in enumerate(base, start=1):
    for a in b.get("armas", []):
        como.setdefault(a, "Base desde el Mundo %d" % i)
    for h in b.get("habs", []):
        como.setdefault(h, "Base desde el Mundo %d" % i)
for x in d["desafios"]:
    p = x.get("premio", {})
    if p.get("id"):
        como.setdefault(p["id"], "Desafío: %s" % x["txt"])

w("# Inventario")
w()
w("> **Archivo generado.** No se edita a mano: sale de `juego/nucleo/catalogo_*.gd`. Para actualizarlo, ver la sección")
w("> \"Regenerar\" al final. Si cambias el contenido del juego, regenera este archivo en el mismo PR.")
w()
w("Resumen: %d armas, %d habilidades, %d naves, %d mascotas, %d piezas, %d enemigos y jefes, %d niveles, %d desafíos."
  % (len(ARMAS), len(HABS), len(d["naves"]), len(d["mascotas"]), len(d["items"]), len(d["enemigos"]),
     len(d["niveles"]), len(d["desafios"])))
w()
w("Unidades: `cad`, `dur` y similares van en cuadros (60 por segundo). `dmg` se multiplica por el Ataque de la nave.")
w()

w("## Armas")
w()
w("| id | Nombre | Tipo | Qué hace | Daño base | Recarga (cuadros) | Sinergia | Evolución | Cómo se consigue |")
w("|---|---|---|---|---|---|---|---|---|")
for k, a in ARMAS.items():
    b = a.get("base", {})
    sin = a.get("sinergia", "")
    sin_n = HABS.get(sin, {}).get("nombre", sin)
    evo = a.get("evo", {})
    w("| `%s` | %s | %s | %s | %s | %s | %s | %s: %s | %s |" % (
        k, a["nombre"], a.get("tipo", ""), celda(a.get("desc", "")), num(b.get("dmg", "")), num(b.get("cad", "")),
        sin_n, evo.get("nombre", ""), celda(evo.get("desc", "")), como.get(k, "?")))
w()

w("## Habilidades")
w()
w("| id | Nombre | Qué hace | Por nivel | Nivel máximo | Hace evolucionar | Cómo se consigue |")
w("|---|---|---|---|---|---|---|")
evoluciona = {}
for k, a in ARMAS.items():
    if a.get("sinergia"):
        evoluciona.setdefault(a["sinergia"], []).append(a["nombre"])
for k, h in HABS.items():
    w("| `%s` | %s | %s | %s | %s | %s | %s |" % (
        k, h["nombre"], celda(h.get("desc", "")), celda(h.get("por_nivel", "")), h.get("max", 5),
        ", ".join(evoluciona.get(k, [])) or "—", como.get(k, "?")))
w()

w("## Naves")
w()
w("| id | Nombre | Arma inicial | Pasiva | Números | Cómo se consigue |")
w("|---|---|---|---|---|---|")
for k, n in d["naves"].items():
    des = n.get("desbloqueo", {})
    txt = des.get("txt") or ("Desde el inicio" if des.get("tipo") == "inicial" else des.get("tipo", ""))
    w("| `%s` | %s | %s | %s | %s | %s |" % (k, n["nombre"], ARMAS.get(n.get("arma"), {}).get("nombre", n.get("arma")),
                                         celda(n.get("pasiva", "")), ", ".join(n.get("numeros", [])), celda(txt)))
w()

w("## Mascotas")
w()
w("| id | Nombre | Mundo | Comportamiento (`ia`) | Qué hace | Cómo se consigue |")
w("|---|---|---|---|---|---|")
for k, m in d["mascotas"].items():
    des = m.get("desbloqueo", {})
    w("| `%s` | %s | %s | %s | %s | %s |" % (k, m["nombre"], m.get("mundo", ""), m.get("ia", ""), celda(m.get("desc", "")),
                                         celda(des.get("txt", des.get("tipo", "")))))
w()

w("## Rarezas")
w()
w("| id | Nombre | Multiplicador | Probabilidad de caer |")
w("|---|---|---|---|")
for r in d["rarezas"]:
    w("| `%s` | %s | ×%s | %s %% |" % (r["id"], r["nombre"], num(r["mult"]), num(r["prob"] * 100)))
w()

w("## Piezas")
w()
mej = d["mejora_por_nivel"]
mej_txt = ", ".join("%s %s %%" % (d["dificultades"][k]["nombre"], num(v * 100)) for k, v in mej.items())
w("Cada pieza da su base por rareza (× multiplicador) y suma un porcentaje de esa base por nivel de mejora, según la")
w("dificultad de la partida: %s. Las pasivas se abren" % mej_txt)
w("según la rareza (`r`: 2 Poco común, 3 Raro, 4 Épico, 5 Legendario).")
w()
w("| id | Ranura | Nombre | Qué hace | Base | Pasivas | Mundo | Empieza a caer |")
w("|---|---|---|---|---|---|---|---|")
for k, it in d["items"].items():
    base_txt = ", ".join("%s %s" % (s, num(v)) for s, v in it.get("base", {}).items())
    pas = "; ".join("r%s %s" % (p["r"], p["txt"]) for p in it.get("pasivas", []))
    w("| `%s` | %s | %s | %s | %s | %s | %s | %s |" % (k, it.get("ranura", ""), it["nombre"], celda(it.get("desc", "")),
                                                   base_txt, celda(pas), it.get("mundo", ""), it.get("desde") or "desde el inicio"))
w()

w("## Enemigos y jefes")
w()
w("| id | Nombre | Vida | XP | Comportamiento (`ia`) | Jefe | Ayuda que ve el jugador |")
w("|---|---|---|---|---|---|---|")
for k, e in d["enemigos"].items():
    jefe = "Sí, fases en %s" % ", ".join(num(f) for f in e["fases"]) if e.get("fases") else ""
    w("| `%s` | %s | %s | %s | %s | %s | %s |" % (k, e["nombre"], num(e.get("hp", "")), num(e.get("xp", "")), e.get("ia", ""),
                                              jefe, celda(e.get("ayuda", ""))))
w()

w("## Mundos")
w()
for i, m in enumerate(d["mundos"], start=1):
    w("%d. **%s**: %s%s" % (i, m["nombre"], m.get("desc", ""), "" if m.get("abierto") else " *(cerrado)*"))
w()

w("## Niveles")
w()
w("| id | Nombre | Duración | Estrella 2 (golpes máx.) | Estrella 3 (cadena en Normal) | Enemigos | Jefe | Premio |")
w("|---|---|---|---|---|---|---|---|")
for k, n in d["niveles"].items():
    p = n.get("premio", {})
    sin_fin = not n.get("duracion")
    w("| `%s` | %s | %s | %s | %s | %s | %s | %s |" % (
        k, n["nombre"], "sin fin" if sin_fin else num(n.get("duracion", "")) + " s",
        "—" if sin_fin else n.get("golpes", "—"), "—" if sin_fin else n.get("cadena", "—"),
        ", ".join(n.get("enemigos", [])), n.get("jefe", ""), celda(p.get("nombre", "")) if p else ""))
w()

w("## Dificultades")
w()
w("Multiplicadores sobre Normal: `hp` y `dano` de los enemigos, `vel` de sus balas, `disparo` = tiempo entre disparos")
w("(menos es más seguido), `botin` y `chatarra`.")
w("Presión: `ritmo` multiplica los enemigos por segundo del director, `inicio` sube además el comienzo,")
w("`ganas` es cuánto disparan los Bots al empezar el nivel, `salva` = tiempo entre salvas y `jefe cd` = tiempo")
w("entre ataques de los jefes (menos es más seguido). `cadena` multiplica la meta de cadena de la 3.ª estrella")
w("(se redondea a múltiplos de 5).")
w()
w("| id | Nombre | hp | daño | vel | disparo | botín | chatarra | ritmo | inicio | ganas | salva | jefe cd | cadena | Notas |")
w("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for k, x in d["dificultades"].items():
    notas = []
    if x.get("sin_pizza"):
        notas.append("sin pizzas")
    if x.get("requiere"):
        notas.append("requiere %s" % x["requiere"])
    w("| `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (k, x["nombre"], num(x["hp"]), num(x["dano"]), num(x["vel"]),
        num(x["disparo"]), num(x["botin"]), num(x["chatarra"]), num(x.get("ritmo", 1)), num(x.get("inicio", 1)),
        num(x.get("ganas", 0.35)), num(x.get("salva", 1)), num(x.get("jefe_cd", 1)), num(x.get("cadena", 1)), ", ".join(notas)))
w()

w("## Desafíos")
w()
w("| id | Mundo | Desafío | Meta | Premio |")
w("|---|---|---|---|---|")
for x in d["desafios"]:
    p = x.get("premio", {})
    pid = p.get("id", "")
    nombre = ARMAS.get(pid, HABS.get(pid, d["naves"].get(pid, d["mascotas"].get(pid, {})))).get("nombre", pid)
    w("| `%s` | %s | %s | %s | %s %s |" % (x["id"], x.get("mundo", ""), celda(x["txt"]), num(x.get("meta", "")),
                                         p.get("tipo", ""), nombre))
w()

w("## Regenerar")
w()
w("```bash")
w("cd juego")
w("<godot> --headless --path . --script ../herramientas/volcar_catalogos.gd -- ../build/catalogos.json --pruebas --guardado=volcado")
w("cd ..")
w("python herramientas/inventario.py build/catalogos.json memorias/inventario.md")
w("```")

open(salida, "w", encoding="utf-8", newline="\n").write("\n".join(L) + "\n")
print("inventario escrito:", salida, len(L), "líneas")
