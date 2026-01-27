#!/usr/bin/env python3
import json
import subprocess
import sys
import urllib.request, urllib.error
import time
from collections import Counter


def run_cmd(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print("ERROR ejecutando:", " ".join(cmd))
        print(result.stderr)
        sys.exit(1)
    return result.stdout.strip()


def http_get(url):
    req = urllib.request.Request(url, headers={"Connection": "close"})
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            return r.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        return ""

def main():
    workspace = sys.argv[1]

    # init del workspace
    run_cmd(["sudo", "terraform", f"-chdir=infra", "init", "-input=false"])

    # Seleccionar workspace
    workspace_ok = subprocess.run(
        ["sudo", "terraform", f"-chdir=infra", "workspace", "select", workspace],
        capture_output=True,
        text=True
    )
    # Si falla se crea
    if workspace_ok.returncode != 0:
        run_cmd(["sudo", "terraform", f"-chdir=infra", "workspace", "new", workspace])

    # Sacar outputs
    url_balanceador = run_cmd(["sudo", "terraform", f"-chdir=infra", "output", "-raw", "lb_url"])
    replicas_esperadas = int(run_cmd(["sudo", "terraform", f"-chdir=infra", "output", "-raw", "web_replicas"]))
    print()
    print("URL balanceador:", url_balanceador)
    print("Réplicas esperadas:", replicas_esperadas)
    print()

    # Ver backends configurados en Nginx
    url_backends = url_balanceador + "/__backends"
    texto_backends = http_get(url_backends)

    lista_backends = []
    for linea in texto_backends.splitlines():
        linea = linea.strip()
        if linea:
            lista_backends.append(linea)

    print("Replicas configuradas en el LB:")
    for b in lista_backends:
        print(" -", b)

    print()

    if len(lista_backends) != replicas_esperadas:
        print()
        print("El loadbalancer tiene configuradas", len(lista_backends), "replicas y se esperaban", replicas_esperadas)
        sys.exit(1)

    #Comprobar que realmente responde más de una instancia
    url_instancia = url_balanceador + "/instance"
    num_peticiones = max(10, replicas_esperadas * 6)

    instancias_vistas = set()

    for _ in range(num_peticiones):
        respuesta = http_get(url_instancia)
        try:
            datos = json.loads(respuesta)
            if "instance" in datos:
                instancias_vistas.add(datos["instance"])
        except Exception:
            pass
        time.sleep(0.05)

    print("Instancias validadas por peticiones:")
    for x in sorted(instancias_vistas):
        print(" -", x)

    if len(instancias_vistas) < replicas_esperadas:
        print()
        print("ERROR: solo se hay", len(instancias_vistas), "instancias, se esperaban", replicas_esperadas)
        sys.exit(1)

    print()
    print("Número de replicas activas OK")
    print()


    # Comprobar round-robin
    contador_instancias = Counter()
    instancias_vistas.clear()
    num_peticiones = max(30, replicas_esperadas * 20)

    for _ in range(num_peticiones):
        respuesta = http_get(url_instancia)
        try:
            datos = json.loads(respuesta)
            if "instance" in datos:
                nombre = datos["instance"]
                instancias_vistas.add(nombre)
                contador_instancias[nombre] += 1
        except Exception:
            pass
        time.sleep(0.05)

    print()
    print("Probando balanceado round-robin:")
    for nombre, veces in contador_instancias.most_common():
        print(" -", nombre, "->", veces)
     
if __name__ == "__main__":
    main()