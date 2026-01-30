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


def http_get(url, with_headers=False):
    req = urllib.request.Request(url, headers={"Connection": "close"})
    try:
        with urllib.request.urlopen(req, timeout=5) as r:
            body = r.read().decode("utf-8", errors="replace")
            if with_headers:
                headers = dict(r.headers.items())
                return body, headers, r.status
            return body

    except urllib.error.HTTPError as e:
        if with_headers:
            try:
                return "", dict(e.headers.items()), e.code
            except Exception:
                return "", {}, e.code
        return ""

    except urllib.error.URLError:
        if with_headers:
            return "", {}, 0
        return ""

    except Exception:
        if with_headers:
            return "", {}, 0
        return ""

def main():

    if len(sys.argv) < 2 or sys.argv[1] not in ("dev", "prod"):
        print("Uso: make test_e2e.py env=dev|prod")
        sys.exit(1)

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

    print("=== LB: Comprobando instancias ===")
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

    print()
    print("=== LB: Probando round-robin ===")
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


    print()
    print("=== MinIO: listar contenido del bucket ===")

    # Sacar puerto y bucket de Terraform outputs
    puerto_minio = run_cmd(["sudo", "terraform", f"-chdir=infra", "output", "-raw", "minio_api_port"])
    bucket_minio = run_cmd(["sudo", "terraform", f"-chdir=infra", "output", "-raw", "minio_bucket"])

    print("Puerto MinIO:", puerto_minio)
    print("Bucket:", bucket_minio)

    # Leemos access/secret del archivo tfvars correspondiente
    ruta_tfvars = "environments/dev.tfvars" if workspace == "dev" else "environments/prod.tfvars"
    def leer_var_tfvars(nombre_var):
        with open(f"infra/{ruta_tfvars}", "r", encoding="utf-8") as f:
            for linea in f:
                linea = linea.strip()
                if linea.startswith(nombre_var):
                    partes = linea.split("=", 1)
                    if len(partes) == 2:
                        valor = partes[1].strip().strip('"')
                        return valor
        return ""

    minio_access = leer_var_tfvars("minio_access_key")
    minio_secret = leer_var_tfvars("minio_secret_key")

    if not minio_access or not minio_secret:
        print("ERROR: no se han podido leer credenciales minio_access_key/minio_secret_key del tfvars")
        sys.exit(1)

    # Ejecutar mc ls usando docker
    mc_host = f"http://{minio_access}:{minio_secret}@localhost:{puerto_minio}"

    cmd_ls = [
        "sudo", "docker", "run", "--rm", "--network", "host",
        "-e", f"MC_HOST_minio={mc_host}",
        "minio/mc", "ls", f"minio/{bucket_minio}"
    ]

    salida_ls = run_cmd(cmd_ls)
    print("Contenido del bucket:")
    print(salida_ls)

    # Comprobando que exista fondo.png
    if "fondo.png" not in salida_ls:
        print("AVISO: no aparece fondo.png en el listado del bucket.")
    else:
        print("OK: aparece fondo.png en el bucket.")

    print()
    print("=== Test caché ===")

    url_usuarios = url_balanceador + "/usuarios/json"

    body1, headers1, status1 = http_get(url_usuarios, with_headers=True)
    body2, headers2, status2 = http_get(url_usuarios, with_headers=True)


    xcache1 = headers1.get("X-Cache", "")
    xcache2 = headers2.get("X-Cache", "")

    print("Petición 1 -> status:", status1, "X-Cache:", xcache1)
    print("Petición 2 -> status:", status2, "X-Cache:", xcache2)

    if status1 == 0 or status2 == 0:
        print("ERROR: no se pudo hacer la petición a /usuarios/json")
        sys.exit(1)

    if not xcache1 or not xcache2:
        print("ERROR: no está llegando la cabecera X-Cache.")
        sys.exit(1)

    if workspace == "prod":
        if xcache2 != "FROM_CACHE":
            print("ERROR: en prod se esperaba X-Cache=FROM_CACHE en la segunda petición")
            sys.exit(1)
        print("OK: caché funcionando correctamente")
    else:
        if xcache1 != "NOT_FROM_CACHE":
            print("AVISO: en dev se esperaba NOT_FROM_CACHE, pero llegó:", xcache1)
        else:
            print("OK: dev sin caché")

     
if __name__ == "__main__":
    main()