# Database Seeding Guide - Proyecto X SaaS

## 🌱 Overview
Este sistema de seeding pobla tu base de datos con datos realistas para desarrollo y testing. Incluye usuarios, tiendas, productos y eventos variados y coherentes con el proyecto Proyecto X SaaS.

## 🚀 Quick Start

### Método 1: Script Automatizado (Recomendado)
```bash
# Seeding básico
./seed-database.sh

# Limpiar BD y reseed completo
./seed-database.sh --clear

# Modo rápido para testing
./seed-database.sh --quick --clear

# Modo completo con máximos datos
./seed-database.sh --full --clear
```

### Método 2: Comando Directo
```bash
# Seeding básico
swift run App seed

# Limpiar y reseed
swift run App seed --clear

# Con cantidad específica
swift run App seed --clear --count 10
```

## 📊 Datos que se Crean

### 👥 Usuarios (15 por defecto)
- **Admin del sistema** (admin@proyectox.com, password: password123)
- **Usuarios variados** con diferentes membership levels
- **Distribución realista:** 40% Silver, 40% Gold, 20% Platinum
- **Puntos variables:** Desde usuarios nuevos (89 pts) hasta VIP (5000 pts)
- **Teléfonos españoles** (+34 format)
- **Fechas de registro** distribuidas en el último año

### 🏪 Tiendas (20 por defecto)
- **Geolocalización Madrid:** Coordenadas reales del centro
- **Categorías variadas:** Pizza, Sushi, Burger, Healthy, etc.
- **Horarios realistas:** 90% abierto, 10% cerrado
- **Rangos de precio:** $, $$, $$$, $$$$
- **Especialidades únicas** por tienda
- **Features específicas:** Terraza, WiFi, Delivery 24h, etc.
- **Ratings:** Entre 3.8 y 4.9 estrellas
- **Reviews:** Entre 12 y 456 reseñas

### 🍕 Productos (60+ por defecto)
- **Asociados a tiendas** correctamente
- **Variedad dietética:** Veganos, sin gluten, orgánicos
- **Información nutricional:** Calorías, ingredientes, alérgenos
- **Precios realistas:** Desde 4.80€ hasta 85€
- **Ratings:** Entre 3.5 y 4.8 estrellas
- **Disponibilidad:** 90% disponible, 10% agotado
- **Tiempos de preparación** variables
- **Productos especiales:** Algunos marcados como sponsored

### 🎉 Eventos (25 por defecto)
- **Fechas futuras:** Próximos 3 meses
- **Categorías:** Gastronómico, Bebidas, Educativo, Cultural, etc.
- **Precios variables:** Desde eventos gratuitos hasta premium (85€)
- **Capacidades realistas:** Desde 10 hasta 200 personas
- **Organizers variados:** Chefs, sommelier, asociaciones
- **Ubicaciones Madrid:** Direcciones reales de centros culturales
- **Horarios variados:** Mañana, tarde, noche
- **Algunos destacados:** Marcados como sponsored

## 🛠 Opciones del Script

```bash
# Opciones disponibles
./seed-database.sh [OPTIONS]

--clear, -c       # Limpiar datos existentes
--quick, -q       # Modo rápido (5 de cada)
--full, -f        # Modo completo (máximo datos)
--users N         # Número específico de usuarios
--stores N        # Número específico de tiendas  
--products N      # Número específico de productos
--events N        # Número específico de eventos
--help, -h        # Mostrar ayuda
```

## 📋 Ejemplos de Uso

### Desarrollo Diario
```bash
# Para trabajar normalmente
./seed-database.sh --clear
```

### Testing Rápido
```bash
# Solo datos mínimos para testing
./seed-database.sh --quick --clear
```

### Demo/Presentación
```bash
# Máximo datos para demo
./seed-database.sh --full --clear
```

### Testing API Específica
```bash
# Solo eventos para testing de EventController
swift run App seed --clear --count 50
```

## 🧪 Testing Después del Seeding

### 1. Health Check
```bash
curl http://localhost:8080/health
```

### 2. Testing Endpoints Públicos
```bash
# Ver todos los eventos
curl http://localhost:8080/api/events

# Ver tiendas por categoría
curl http://localhost:8080/api/stores/category/pizza

# Ver productos destacados
curl http://localhost:8080/api/products/featured

# Buscar productos veganos
curl -X POST http://localhost:8080/api/products/search \
  -H "Content-Type: application/json" \
  -d '{"isVegan": true, "limit": 10}'
```

### 3. Testing Autenticación
```bash
# Registrar usuario de prueba
curl -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@proyectox.com",
    "password": "password123",
    "confirmPassword": "password123",
    "firstName": "Test",
    "lastName": "User"
  }'

# Login con admin (creado por seeding)
curl -X POST http://localhost:8080/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@proyectox.com",
    "password": "password123"
  }'
```

## 📊 Datos de Login por Defecto

### Usuario Admin
- **Email:** admin@proyectox.com
- **Password:** password123
- **Level:** Platinum (5000 pts)

### Usuarios de Prueba
- **María García:** maria.garcia@email.com / password123 (Gold, 1250 pts)
- **Carlos López:** carlos.lopez@email.com / password123 (Silver, 340 pts)
- **Ana Martínez:** ana.martinez@email.com / password123 (Gold, 890 pts)

*Todos los usuarios usan la misma contraseña: **password123***

## 🔍 Verificar Seeding

### Contar Registros Creados
```bash
# En Railway/Producción puedes usar la Railway CLI
railway run swift run App seed --count 1  # Solo para ver logs
```

### Endpoints para Verificar
- `GET /api/events` → Debe devolver 25 eventos (por defecto)
- `GET /api/stores` → Debe devolver 20 tiendas
- `GET /api/products` → Debe devolver 60+ productos
- `POST /api/users/login` → Admin login debe funcionar

## ⚠️ Notas Importantes

1. **Password Universal:** Todos los usuarios usan `password123`
2. **Datos en Madrid:** Coordenadas y direcciones de Madrid, España
3. **Fechas Futuras:** Eventos programados para próximos 3 meses
4. **Relaciones FK:** Productos correctamente asociados a tiendas
5. **Variedad Real:** Datos coherentes con una app de delivery gastronómico

## 🔄 Re-seeding

Para volver a poblar con datos frescos:
```bash
./seed-database.sh --clear
```

Esto eliminará todos los datos existentes y creará datos nuevos (con variaciones aleatorias en ratings, fechas, etc.).

## 🚨 Troubleshooting

### Error: "Swift command not found"
```bash
# Instalar Xcode Command Line Tools
xcode-select --install
```

### Error: "Build failed"
```bash
# Limpiar y reconstruir
swift package clean
swift build
```

### Error: "Database connection failed"
```bash
# Verificar que PostgreSQL esté corriendo
# En desarrollo local, usar Docker:
docker-compose up db
```

### Error: "Migration failed"
```bash
# Ejecutar migraciones manualmente
swift run App migrate
```

---

## 🎯 Próximos Pasos

Después del seeding exitoso:
1. ✅ Probar endpoints con datos reales
2. ✅ Conectar app iOS con backend poblado
3. ✅ Ajustar búsquedas y filtros según necesidades
4. ✅ Optimizar queries basándose en datos reales

*Datos creados el: $(date)*