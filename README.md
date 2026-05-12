# Comandix POS — Sistema de Gestión de Restaurantes

Plataforma SaaS multi-tenant para restaurantes, bares, cafeterías y hamburgueserías.

## Stack

- **Backend**: NestJS + TypeORM + PostgreSQL + Redis
- **Frontend Desktop**: Flutter Desktop (Windows)
- **Infraestructura**: Docker + Nginx en VPS Ubuntu

---

## Desarrollo Local

### Requisitos
- Node.js 18+
- PostgreSQL 15 local (o usar el VPS)
- Flutter SDK

### Iniciar backend
```bash
cd comandix-backend
cp .env.example .env
# Editar .env con los datos de tu DB local
npm install
npm run start:dev
```

---

## Deploy en VPS (Ubuntu 22.04)

### 1. Crear repo en GitHub y subir el código
```bash
# En tu PC local, desde la carpeta COMANDIX:
git init
git add .
git commit -m "feat: initial Comandix scaffold"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/comandix.git
git push -u origin main
```

### 2. Conectarse al VPS y ejecutar el script de setup
```bash
ssh root@IP_DE_TU_VPS
curl -fsSL https://raw.githubusercontent.com/TU_USUARIO/comandix/main/vps-setup.sh | bash
```

### 3. Configurar las variables de entorno en el VPS
```bash
nano /opt/comandix/comandix-backend/.env
```

Variables críticas que DEBÉS cambiar:
```env
DB_PASSWORD=password_muy_segura_aqui
JWT_SECRET=clave_jwt_muy_larga_y_aleatoria_aqui
NODE_ENV=production
```

### 4. Verificar que todo esté corriendo
```bash
docker compose ps
# Deberías ver: nginx, api, db, redis todos como "Up"

# Ver logs de la API
docker compose logs -f api
```

### 5. Testear el endpoint de login
```bash
curl -X POST http://IP_DE_TU_VPS/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@mirestaurante.com","password":"admin123"}'
```

---

## Actualizar el backend en el VPS

Cuando hagas cambios y los subas a GitHub:
```bash
ssh root@IP_DE_TU_VPS
cd /opt/comandix
git pull
docker compose up -d --build api
```

---

## Estructura del Proyecto

```
COMANDIX/
├── comandix-backend/     # API NestJS
├── comandix_desktop/     # App Flutter Desktop
├── docker-compose.yml    # Orquestación Docker
├── nginx.conf            # Reverse Proxy
└── vps-setup.sh          # Script de instalación VPS
```
