#!/bin/bash

# Este script despliega la aplicación web PHP usando Nginx y PHP-FPM,
# configurándola para escuchar únicamente en el puerto 8082.

# Salir inmediatamente si un comando falla
set -e

# Configuración
USER_ADMIN="www-data" 
PORT="8082"
APP_DIR="/var/www/phpapp"

echo "Iniciando el despliegue de la aplicación PHP en el puerto $PORT..."

# 1. Actualización e Instalación
echo "1. Actualizando paquetes e instalando Nginx y PHP-FPM..."
sudo apt update && sudo apt upgrade -y
sudo apt install nginx php-fpm -y

# 2. Comprobación inicial de servicios
echo "Comprobando que los servicios Nginx y PHP-FPM estén activos..."
# El tutorial indica verificar el estado de nginx y php8.3-fpm [2].
sudo systemctl status nginx --no-pager
sudo systemctl status php*-fpm --no-pager

# 3. Creación del directorio web y asignación de permisos
echo "3. Creando el directorio de la aplicación ($APP_DIR) y ajustando permisos..."
sudo mkdir -p $APP_DIR
# Se usan los permisos con el usuario administrador, como se especifica en el tutorial [2].
sudo chown -R $USER_ADMIN:$USER_ADMIN $APP_DIR

# 4. Creación de los archivos de la aplicación PHP (index.php, style.css, contacto.php)
echo "4. Creando los archivos index.php, style.css y contacto.php..."

# Creación de index.php (contenido omitido por brevedad, se mantiene el contenido dinámico del script anterior basado en las fuentes [3, 4])
sudo tee $APP_DIR/index.php > /dev/null << EOF
<?php
// Información del cliente y del servidor
\$fecha = date("d/m/Y H:i:s");
\$ip = \$_SERVER['REMOTE_ADDR'] ?? 'Desconocida';
\$navegador = \$_SERVER["HTTP_USER_AGENT"] ?? 'No disponible';
\$php_version = phpversion();
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Página principal dinámica</title>
<!-- Enlace al archivo CSS externo -->
<link rel="stylesheet" href="style.css">
</head>
<body>
<h1>Aplicación web dinámica (PHP + Nginx)</h1>
<h2>Hecho por: Daniel Gonzalez Velez, Javier Alamo y Nahuel</h2>
<p>Fecha y Hora: <strong><?php echo \$fecha; ?></strong></p>
<p>IP del Cliente: <strong><?php echo \$ip; ?></strong></p>
<p>Navegador: <strong><?php echo \$navegador; ?></strong></p>
<p>Versión de PHP: <strong><?php echo \$php_version; ?></strong></p>
<p>Enlace a <a class="contact" href="contacto.php">Contacto</a></p>
<div class="section info">
    <p>Esta información es generada dinámicamente por PHP en el servidor.</p>
</div>
</body>
</html>
EOF

# Creación de style.css (contenido basado en las fuentes [4, 5])
sudo tee $APP_DIR/style.css > /dev/null << EOF
/* Estilos generales */
body {
font-family: Arial, sans-serif;
max-width: 800px;
margin: 0 auto;
padding: 20px;
background-color: #f5f5f5;
color: #333;
}
h1 {
color: #2c3e50;
text-align: center;
border-bottom: 2px solid #3498db;
padding-bottom: 10px;
}
h2 {
color: #34495e;
margin-top: 30px;
}
.section {
background-color: white;
padding: 15px;
margin: 15px 0;
border-radius: 5px;
box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}
.info {
background-color: #f8f9fa;
padding: 15px;
border-radius: 3px;
border-left: 4px solid #3498db;
}
.contact {
color: #e74c3c;
text-decoration: none;
font-weight: bold;
}
.contact:hover {
text-decoration: underline;
}
strong {
color: #2c3e50;
}
p {
margin: 8px 0;
line-height: 1.5;
}
EOF

# Creación de contacto.php (contenido basado en las fuentes [5, 6])
sudo tee $APP_DIR/contacto.php > /dev/null << EOF
<?php
// Información del servidor para la página de contacto
\$fecha = date("d/m/Y H:i:s");
\$servidor = \$_SERVER['SERVER_SOFTWARE'] ?? 'Desconocido';
\$php_version = phpversion();
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Página de Contacto</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<h1>Página de Contacto</h1>
<h2>Información de Contacto y Servidor</h2>
<p>Servidor: <strong><?php echo \$servidor; ?></strong></p>
<p>Versión de PHP: <strong><?php echo \$php_version; ?></strong></p>
<p>Hora del Servidor: <strong><?php echo \$fecha; ?></strong></p>
<p><a href="index.php">Volver a la página principal</a></p>
</body>
</html>
EOF


# 5. Configuración de Nginx para usar el puerto 8082
echo "5. Configurando Nginx para escuchar en el puerto $PORT..."

# Se crea una copia de seguridad del archivo 'default' antes de editarlo [6].
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.copia

# Editamos el archivo del host virtual [6].
# Cambiamos las líneas "listen 80" [7] a "listen 8082", siguiendo el patrón de cambio de puerto del tutorial [1].

sudo tee /etc/nginx/sites-available/default > /dev/null << EOF
server {
    # Cambiamos los puertos de escucha por defecto (80) al puerto solicitado ($PORT)
    listen $PORT default_server;
    listen [::]:$PORT default_server;

    root $APP_DIR;

    index index.php index.html index.htm;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Pass PHP scripts to FPM
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        # Se asume el socket estándar de PHP-FPM:
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

}
EOF

# 6. Verificación de la configuración de Nginx y recarga del servicio
echo "6. Verificando la sintaxis de Nginx y recargando el servicio..."
sudo nginx -t
# Recargamos el servicio para aplicar la nueva configuración del puerto [1, 7].
sudo systemctl reload nginx

# 7. Configuración del Firewall (UFW)
echo "7. Abriendo el puerto $PORT en el firewall (UFW)..."
# Abrimos el puerto específico, tal como se recomienda si el firewall está activo [1].
sudo ufw allow $PORT
sudo ufw reload

echo "Despliegue completado. La aplicación PHP está sirviendo contenido en HTTP en el puerto $PORT."
echo "Compruebe el acceso en: http://<tu_ip>:$PORT"