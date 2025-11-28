#!/bin/bash

# --- CONFIGURACIÓN AUTOMÁTICA ---
# Detectamos el usuario actual para evitar errores de permisos (ej. isard vs ubuntu)
USER_APP=$(whoami)
HOME_DIR=$(eval echo ~$USER_APP)
PROJECT_DIR="$HOME_DIR/webapp_py"
SERVICE_NAME="webapp_py"
PORT="8081"

echo "--- [PASO 0] Limpieza preventiva ---"
# Detenemos el servicio si ya existía y dio error
sudo systemctl stop $SERVICE_NAME 2>/dev/null || true

echo "--- [PASO 1] Preparando sistema y directorios ---"
sudo apt update
sudo apt install -y python3 python3-venv python3-pip
mkdir -p $PROJECT_DIR

echo "--- [PASO 2] Generando archivo requirements.txt ---"
# Creamos el archivo directamente en el destino
cat <<EOF > $PROJECT_DIR/requirements.txt
flask
gunicorn
EOF

echo "--- [PASO 3] Generando archivo app.py ---"
# Creamos el código de la app directamente en el destino
cat <<'EOF' > $PROJECT_DIR/app.py
from flask import Flask, request
from datetime import datetime
import sys

app = Flask(__name__)

@app.route("/")
def index():
    client_ip = request.remote_addr
    user_agent = request.headers.get("User-Agent", "Desconocido")
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    python_version = sys.version.replace("\n", "<br>")

    screen_resolution_script = """
    <script>
      document.addEventListener("DOMContentLoaded", function() {
        var res = screen.width + " x " + screen.height;
        document.getElementById("screen-resolution").innerText = res;
      });
    </script>
    """

    html = f"""
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <title>Información del Cliente - Python</title>
    </head>
    <body>
      <h1>Aplicación Web en Python</h1>
      <p><a href="/contacto">Ir a la página de contacto</a></p>
      <h2>Datos del Servidor</h2>
      <p>Fecha y hora del servidor: {now}</p>
      <p>Versión de Python:</p>
      <pre>{python_version}</pre>
      <h2>Datos del Cliente</h2>
      <p>IP del cliente: {client_ip}</p>
      <p>Navegador (User-Agent): {user_agent}</p>
      <p>Resolución de pantalla: <span id="screen-resolution">Calculando...</span></p>
      {screen_resolution_script}
      <h3>Lenguaje utilizado: Python</h3>
    </body>
    </html>
    """
    return html

@app.route("/contacto")
def contacto():
    html = """
    <!DOCTYPE html>
    <html lang="es">
    <head><meta charset="UTF-8"><title>Contacto</title></head>
    <body>
      <h1>Formulario de Contacto</h1>
      <form>
        <label>Nombre:</label><br><input type="text"><br><br>
        <label>Email:</label><br><input type="email"><br><br>
        <label>Mensaje:</label><br><textarea></textarea><br><br>
        <button type="submit">Enviar</button>
      </form>
      <p><a href="/">Volver</a></p>
    </body>
    </html>
    """
    return html

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8081)
EOF

echo "--- [PASO 4] Configurando entorno virtual e instalando dependencias ---"
# Recreamos el entorno virtual para asegurar que está limpio
rm -rf $PROJECT_DIR/venv
python3 -m venv $PROJECT_DIR/venv
$PROJECT_DIR/venv/bin/pip install -r $PROJECT_DIR/requirements.txt

echo "--- [PASO 5] Configurando servicio Systemd (Usuario: $USER_APP, Puerto: $PORT) ---"
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Webapp Python Flask con Gunicorn
After=network.target

[Service]
User=$USER_APP
Group=$USER_APP
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin"
ExecStart=$PROJECT_DIR/venv/bin/gunicorn -w 3 -b 0.0.0.0:$PORT app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "--- [PASO 6] Iniciando el servicio ---"
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl restart $SERVICE_NAME

echo "---------------------------------------------------"
echo "REPARACIÓN Y DESPLIEGUE COMPLETADO"
echo "---------------------------------------------------"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Accede a la app en: http://$SERVER_IP:$PORT"
echo ""
echo "Comprobaciones si falla:"
echo "1. sudo systemctl status $SERVICE_NAME"
echo "2. sudo journalctl -u $SERVICE_NAME -n 50 --no-pager"