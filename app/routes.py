import os
from flask import Blueprint, render_template, request, redirect, jsonify, current_app
import mysql.connector
from mysql.connector import Error
from http import HTTPStatus
from urllib.parse import quote


bp = Blueprint("main", __name__)

def get_container_name():
   return current_app.config["INSTANCE_NAME"]

# --- Funciones vacías de caché (se sobrescribirán en __init__.py si se usa Redis), me devuelven el error si estoy de entorno dev ---
def get_cache(key):
    raise ConnectionError("Redis no disponible en este entorno")

def set_cache(key, value):
    raise ConnectionError("Redis no disponible en este entorno")

def delete_cache(key):
    raise ConnectionError("Redis no disponible en este entorno")



# --- Conexión MySQL ---
def get_connection():
    try:
        conn = mysql.connector.connect(
            host=current_app.config["MYSQL_HOST"],
            user=current_app.config["MYSQL_USER"],
            password=current_app.config["MYSQL_PASSWORD"],
            database=current_app.config["MYSQL_DATABASE"]
        )
        return conn
    except Error as e:
        print(f"Error de conexión con MySQL: {e}")
        return None


# --- Rutas ---
@bp.route("/", methods=["GET"])
def index():
    container_name = get_container_name()

    minio_base = current_app.config.get("MINIO_PUBLIC_URL")
    minio_bucket = current_app.config.get("MINIO_BUCKET")

    background_url = None
    if minio_base and minio_bucket:
        background_key = "fondo.png"
        background_url = f"{minio_base}/{minio_bucket}/{background_key}"

    return render_template("index.html", container_name=container_name, background_url=background_url,)


@bp.route("/usuarios/json", methods=["GET"])
def listar_usuarios_json():
    cache_key = "usuarios_todos"
    usuarios = None
    cache_accessible = False
    use_cache = current_app.config.get("USE_CACHE", False)

    x_cache = "NOT_FROM_CACHE"

    # Intento de caché
    if use_cache:
        try:
            usuarios = get_cache(cache_key)
            cache_accessible = True
        except Exception as e:
            print(f"Error accediendo a Redis: {e}")
            cache_accessible = False

    if use_cache and cache_accessible and usuarios is not None:
        resp = jsonify({"usuarios": usuarios})
        resp.headers["X-Cache"] = "FROM_CACHE"
        resp.headers["X-Instance"] = get_container_name()
        return resp, HTTPStatus.OK

    # Si no viene de Redis, vamos a MySQL
    conn = get_connection()
    if conn is None:
        if use_cache:
            if cache_accessible:
                resp = jsonify({"error": "BBDD caida y caché vacia"})
            else:
                resp = jsonify({"error": "BBDD y cache no disponibles"})
        else:
            resp = jsonify({"error": "No se pudo conectar con la base de datos"})

        resp.headers["X-Cache"] = x_cache
        resp.headers["X-Instance"] = get_container_name()
        return resp, HTTPStatus.SERVICE_UNAVAILABLE

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM usuarios")
        usuarios = cursor.fetchall()
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"No se pudo cargar los usuarios: {e}")
        resp = jsonify({"error": "No se pudo cargar los usuarios"})
        resp.headers["X-Cache"] = x_cache
        resp.headers["X-Instance"] = get_container_name()
        return resp, HTTPStatus.SERVICE_UNAVAILABLE

    # Intentar guardar en caché
    if use_cache and cache_accessible:
        try:
            set_cache(cache_key, usuarios)
        except Exception as e:
            print(f"No se pudo guardar en Redis: {e}")

    resp = jsonify({"usuarios": usuarios})
    resp.headers["X-Cache"] = x_cache
    resp.headers["X-Instance"] = get_container_name()
    return resp, HTTPStatus.OK

@bp.route("/set", methods=["POST"])
def set_user():
    nombre = request.form["nombre"]
    apellido = request.form["apellido"]
    edad = request.form["edad"]
    correo = request.form["correo"]
    ciudad = request.form["ciudad"]

    conn = get_connection()
    if conn is None:
        return redirect("/?msg=" + quote("No se pudo conectar con la base de datos"))

    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO usuarios (nombre, apellido, edad, correo, ciudad)
            VALUES (%s, %s, %s, %s, %s)
        """,
            (nombre, apellido, edad, correo, ciudad),
        )
        conn.commit()
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Error insertando en MySQL: {e}")

    # Borrar caché tras inserción
    try:
        delete_cache("usuarios_todos")
    except Exception as e:
        print(f"No se pudo eliminar en Redis: {e}")

    return redirect("/")


@bp.route("/delete", methods=["POST"])
def delete_users():
    ids = request.form.getlist("ids")
    if ids:

        conn = get_connection()
        if conn is None:
            return redirect(
                "/?msg=" + quote("No se pudo conectar con la base de datos")
            )

        try:
            cursor = conn.cursor()
            formato = ",".join(["%s"] * len(ids))
            cursor.execute(f"DELETE FROM usuarios WHERE id IN ({formato})", ids)
            conn.commit()
            cursor.close()
            conn.close()
        except Exception as e:
            print(f"Error borrando en MySQL: {e}")

        try:
            delete_cache("usuarios_todos")
        except Exception as e:
            print(f"No se pudo eliminar en Redis: {e}")

    return redirect("/")


@bp.route("/instance", methods=["GET"])
def instance():
    return jsonify({"instance": get_container_name()})


@bp.route("/status", methods=["GET"])
def status_page():
    """Renderiza una página HTML con el estado de los servicios."""
    status = {"web: ": "up", "db: ": "unknown", "cache: ": "unknown"}

    # --- Base de datos ---
    db_ok = check_db()
    status["db: "] = "up" if db_ok else "down"

    use_cache = current_app.config.get("USE_CACHE", False)

    cache_ok = None
    if use_cache:
        cache_ok = check_cache()
        if cache_ok:
            status["cache: "] = "up"
        else:
            status["cache: "] = "down"

    return render_template("status.html", status=status)


def check_db() -> bool:
    conn = None
    try:
        conn = get_connection()
        return conn is not None
    finally:
        if conn:
            try:
                conn.close()
            except Exception:
                pass


def check_cache() -> bool:
    try:
        from .cache import get_cache_connection

        cache = get_cache_connection()
        return bool(cache) and bool(cache.ping())
    except Exception:
        return False

@bp.route("/health", methods=["GET"])
def health():
    """
    Health para pipeline/tests:
      - DB siempre requerida
      - Redis solo si USE_CACHE=True
    Devuelve 200 si todo lo requerido está OK, si no 503.
    """
    db_ok = check_db()

    use_cache = current_app.config.get("USE_CACHE", False)
    cache_ok = None
    if use_cache:
        cache_ok = check_cache()

    ok = db_ok and (cache_ok if use_cache else True)
    code = HTTPStatus.OK if ok else HTTPStatus.SERVICE_UNAVAILABLE

    return (
        jsonify({"ok": ok, "db": db_ok, "cache": cache_ok if use_cache else None}),
        code,
    )


@bp.route("/crash")
def crash():
    
    os._exit(1)
    
    return "This will never be returned"