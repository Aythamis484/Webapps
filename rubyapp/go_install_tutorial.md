# 📘 Tutorial Profesional: Servidor Web Básico en Ruby con Sinatra

Despliega una **aplicación web básica** en **Ruby (Sinatra)** que muestra la **fecha actual** y la **IP del cliente** en un servidor **Ubuntu 24.04**. Todo el proceso está incluido en este bloque.

---

## ✅ Prerrequisitos


- Ubuntu Server 24.04 con acceso **root/sudo**.
- Acceso SSH o mosh al servidor.
- Editor remoto o IDE para editar archivos.
- Servidor sin entorno web previo (instalaremos Ruby + Sinatra).

> Se recomeinda usar VS Code con Remote SSH para editar directamente desde el PC.

---

## 🛠 Instalación y Configuración

# ===========================
# 1️⃣ Actualizar el Sistema
# ===========================
sudo apt update
sudo apt upgrade -y

# ===========================
# 2️⃣ Instalar Ruby y herramientas de desarrollo
# ===========================
sudo apt install -y ruby ruby-dev build-essential

# ===========================
# 3️⃣ Instalar Bundler
# ===========================
sudo gem install bundler

# ===========================
# 4️⃣ Verificar Instalación
# ===========================
ruby -v
bundler -v

# ===========================
# 5️⃣ Crear Directorio del Proyecto
# ===========================
mkdir -p /root/Webapps/rubyapp
cd /root/Webapps/rubyapp

# ===========================
# 6️⃣ Crear Gemfile
# ===========================
cat > Gemfile <<'EOF'
source "https://rubygems.org"

gem "sinatra"
EOF

bundle install

# ===========================
# 7️⃣ Crear rubyapp.rb (Servidor Ruby con Sinatra)
# ===========================
cat > rubyapp.rb <<'EOF'
require 'sinatra'
require 'json'
require 'time'

def get_client_ip(request)
  if request.env["HTTP_X_FORWARDED_FOR"]
    return request.env["HTTP_X_FORWARDED_FOR"].split(",").first.strip
  end

  return request.env["HTTP_X_REAL_IP"] if request.env["HTTP_X_REAL_IP"]
  return request.env["HTTP_CF_CONNECTING_IP"] if request.env["HTTP_CF_CONNECTING_IP"]

  request.ip
end

get '/' do
  now = Time.now
  date_friendly = now.strftime("%Y-%m-%d %H:%M:%S %A")
  date_iso = now.iso8601
  client_ip = get_client_ip(request)

  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
<title>Info Cliente - Ruby Server</title>
<meta charset="UTF-8">
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, "San Francisco", Arial, sans-serif;
    background: #e5e5e5;
    margin: 0;
    padding: 40px 0;
    display: flex;
    justify-content: center;
  }

  .window {
    background: #ffffff;
    width: 700px;
    border-radius: 12px;
    box-shadow: 0 20px 40px rgba(0,0,0,0.15);
    overflow: hidden;
  }

  .titlebar {
    background: #f5f5f7;
    height: 32px;
    display: flex;
    align-items: center;
    padding-left: 12px;
    border-bottom: 1px solid #dcdcdc;
  }

  .btn {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    margin-right: 8px;
  }
  .red { background: #ff5f57; }
  .yellow { background: #ffbd2e; }
  .green { background: #28c840; }

  .content {
    padding: 30px 40px;
  }

  h1 {
    font-size: 26px;
    margin-bottom: 20px;
    color: #111;
  }

  .group {
    margin-bottom: 30px;
    padding: 20px;
    background: #f8f9fa;
    border-radius: 10px;
    border: 1px solid #e1e1e1;
  }

  h2 {
    font-size: 20px;
    margin-bottom: 10px;
    color: #333;
  }

  p {
    margin: 6px 0;
    font-size: 15px;
    color: #444;
  }

  strong {
    color: #000;
  }
</style>
</head>
<body>
<div class="window">
  <div class="titlebar">
    <div class="btn red"></div>
    <div class="btn yellow"></div>
    <div class="btn green"></div>
  </div>
  <div class="content">

    <h1>🕒 Información del Cliente</h1>

    <div class="group">
      <h2>Fecha del Servidor</h2>
      <p><strong>Legible:</strong> #{date_friendly}</p>
      <p><strong>ISO 8601:</strong> #{date_iso}</p>
      <p><strong>Unix:</strong> #{now.to_i}</p>
    </div>

    <div class="group">
      <h2>Datos del Cliente</h2>
      <p><strong>IP:</strong> #{client_ip}</p>
      <p><strong>User-Agent:</strong> #{request.user_agent}</p>
      <p><strong>Método:</strong> #{request.request_method}</p>
      <p><strong>URL:</strong> #{request.path_info}</p>
    </div>

  </div>
</div>
</body>
</html>
  HTML

  puts "IP #{client_ip} - #{request.path_info}"
  html
end

get '/api' do
  now = Time.now
  resp = {
    timestamp: now.iso8601,
    unix: now.to_i,
    ip: get_client_ip(request),
    method: request.request_method,
    path: request.path_info
  }

  puts "API hit from #{resp[:ip]}"
  content_type :json
  resp.to_json
end

set :port, ENV.fetch("PORT", "8083")
EOF

# ===========================
# 8️⃣ Ejecutar la App
# ===========================
ruby rubyapp.rb
# o
bundle exec ruby rubyapp.rb

# Acceder desde navegador:
# 🌐 http://IP_DEL_SERVIDOR:8083
# 🌐 http://IP_DEL_SERVIDOR:8083/api

# ===========================
# 9️⃣ Configurar como servicio systemd
# ===========================
sudo tee /etc/systemd/system/webapp.service > /dev/null <<'EOF'
[Unit]
Description=Ruby WebApp Fecha e IP
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/Webapps/rubyapp
ExecStart=/usr/bin/env ruby /root/Webapps/rubyapp/rubyapp.rb
Restart=on-failure
Environment=PORT=8083
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start webapp
sudo systemctl enable webapp

# ===========================
# 🔥 Configurar Firewall
# ===========================
sudo ufw allow 8083
sudo ufw status

# ===========================
# 🧪 Pruebas y Monitoreo
# ===========================
curl http://localhost:8083


