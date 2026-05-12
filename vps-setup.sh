#!/bin/bash
# ============================================================
# Comandix VPS Setup Script
# Probado en Ubuntu 22.04 LTS
# Uso: bash vps-setup.sh
# ============================================================

set -e

echo "🚀 [1/5] Actualizando sistema..."
apt-get update -y && apt-get upgrade -y

echo "🐳 [2/5] Instalando Docker..."
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker
echo "✅ Docker instalado: $(docker --version)"

echo "📁 [3/5] Clonando repositorio..."
# Reemplazar con tu URL de GitHub
REPO_URL="https://github.com/Scribax/Comandix.git"
APP_DIR="/opt/comandix"

if [ -d "$APP_DIR" ]; then
  echo "📦 Repo ya existe, haciendo pull..."
  cd "$APP_DIR" && git pull
else
  git clone "$REPO_URL" "$APP_DIR"
  cd "$APP_DIR"
fi

echo "🔐 [4/5] Configurando variables de entorno..."
# Solo copia si no existe ya el .env en producción
if [ ! -f "$APP_DIR/comandix-backend/.env" ]; then
  cp "$APP_DIR/comandix-backend/.env.example" "$APP_DIR/comandix-backend/.env"
  echo ""
  echo "⚠️  IMPORTANTE: Editá el archivo de entorno con tus valores reales:"
  echo "   nano $APP_DIR/comandix-backend/.env"
  echo ""
  echo "   Al menos configurá:"
  echo "   - DB_PASSWORD=una_password_segura"
  echo "   - JWT_SECRET=una_clave_secreta_larga"
  echo ""
  read -p "Presioná ENTER cuando hayas editado el .env para continuar..."
fi

echo "🐳 [5/5] Levantando contenedores con Docker Compose..."
cd "$APP_DIR"
docker compose up -d --build

echo ""
echo "✅ ¡Comandix levantado!"
echo "   API: http://$(curl -s ifconfig.me)/api/v1"
echo ""
echo "Para ver los logs:"
echo "   docker compose logs -f api"
