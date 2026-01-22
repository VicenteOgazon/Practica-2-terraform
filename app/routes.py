import os
from flask import Blueprint, render_template, request, redirect, jsonify, current_app
import mysql.connector
from mysql.connector import Error

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

    # Intentar obtener desde caché
    try:
        usuarios = get_cache(cache_key)
    except Exception as e:
        print(f"Error accediendo a Redis: {e}")

    if usuarios:
        return jsonify({"usuarios": usuarios})

    conn = get_connection()
    if conn is None:
        return jsonify({"error": "No se pudo conectar con la base de datos"}), 500

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM usuarios")
        usuarios = cursor.fetchall()
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Error al ejecutar consulta MySQL: {e}")
        return jsonify({"error": "Error al consultar la base de datos"}), 500

    # Intentar guardar en caché
    try:
        set_cache(cache_key, usuarios)
    except Exception as e:
        print(f"No se pudo guardar en Redis: {e}")

    return jsonify({"usuarios": usuarios})


@bp.route("/set", methods=["POST"])
def set_user():
    nombre = request.form["nombre"]
    apellido = request.form["apellido"]
    edad = request.form["edad"]
    correo = request.form["correo"]
    ciudad = request.form["ciudad"]

    conn = get_connection()
    if conn is None:
        return jsonify({"error": "No se pudo conectar con la base de datos"}), 500

    try:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO usuarios (nombre, apellido, edad, correo, ciudad)
            VALUES (%s, %s, %s, %s, %s)
        """, (nombre, apellido, edad, correo, ciudad))
        conn.commit()
        cursor.close()
        conn.close()
    except Exception as e:
        
        return jsonify({"error": "Error al modificar la base de datos"}), 500

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
            return jsonify({"error": "No se pudo conectar con la base de datos"}), 500
        try:
            cursor = conn.cursor()
            formato = ",".join(["%s"] * len(ids))
            cursor.execute(f"DELETE FROM usuarios WHERE id IN ({formato})", ids)
            conn.commit()
            cursor.close()
            conn.close()
        except Exception as e:
            
            return jsonify({"error": "Error al modificar la base de datos"}), 500

        try:
            delete_cache("usuarios_todos")
        except Exception as e:
            print(f"No se pudo eliminar en Redis: {e}")

    return redirect("/")


@bp.route("/status", methods=["GET"])
def status_page():
    """Renderiza una página HTML con el estado de los servicios."""
    status = {"web: ": "up", "db: ": "unknown", "cache: ": "unknown"}

    # --- Base de datos ---
    conn = get_connection()
    status["db: "] = "up" if conn else "down"
    if conn:
        conn.close()

    try:
        from .cache import get_cache_connection
        cache = get_cache_connection()
        if cache and cache.ping():
            status["cache: "] = "up"
        else:
            status["cache: "] = "down"
    except Exception:
        status["cache: "] = "down"

    return render_template("status.html", status=status)


@bp.route("/health", methods=["GET"])
def health():
    """Devuelve el estado de los servicios en formato JSON (para la interfaz dinámica)."""
    status = {"web": "up", "db": "unknown", "cache": "unknown"}

    # --- Base de datos ---
    conn = get_connection()
    status["db"] = "up" if conn else "down"
    if conn:
        conn.close()

    # --- Caché ---
    try:
        from .cache import get_cache_connection
        cache = get_cache_connection()
        if cache and cache.ping():
            status["cache"] = "up"
        else:
            status["cache"] = "down"
    except Exception:
        status["cache"] = "down"

    return jsonify(status)

@bp.route("/crash")
def crash():
    
    os._exit(1)
    
    return "This will never be returned"