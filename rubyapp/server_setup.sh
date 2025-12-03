#!/bin/bash

# Salir si ocurre algún error
set -e

# 1. Actualizar el sistema
echo "Actualizando el sistema..."
sudo apt update
sudo apt upgrade -y

# 2. Instalar Ruby y herramientas de compilación
echo "Instalando Ruby y herramientas de compilación..."
sudo apt install -y ruby ruby-dev build-essential

# 3. Instalar Bundler (gestor de dependencias de Ruby)
echo "Instalando Bundler..."
sudo gem install bundler

# 4. Crear Gemfile y agregar Sinatra (ejemplo mínimo)
echo "Creando Gemfile con Sinatra..."
echo -e 'source "https://rubygems.org"\ngem "sinatra"' > Gemfile

# Instalar dependencias del Gemfile
echo "Instalando dependencias con Bundler..."
bundle install

echo "¡Todo listo! Ruby y Sinatra han sido instalados."





