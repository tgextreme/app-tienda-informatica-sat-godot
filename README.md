# 🔧 Sistema SAT - Gestión de Servicio de Atención Técnica

![Godot Engine](https://img.shields.io/badge/Godot-v4.5-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Windows%20|%20Linux%20|%20macOS-lightgrey)

Sistema completo de gestión para servicios de atención técnica de tiendas de informática, desarrollado en **Godot Engine 4.5** por **Tomás González**.

## ✨ Características Principales

### 📋 Gestión de Tickets SAT
- **Estados del flujo**: Nuevo → Diagnosticando → Presupuestado → Aprobado → En reparación → En pruebas → Listo para entrega → Entregado → Cerrado
- **Información completa**: Cliente, equipo, avería, diagnóstico, repuestos, mano de obra
- **Seguimiento de tiempos** de trabajo por técnico
- **Historial completo** de cambios y eventos
- **Adjuntos** (fotos, documentos)
- **Sistema de aprobaciones** con registro de fechas y usuarios

### 👥 Gestión de Clientes
- **Datos completos**: contacto, direcciones, preferencias
- **RGPD**: consentimiento para comunicaciones
- **Historial** de reparaciones por cliente
- **Búsqueda rápida** por nombre, teléfono, email

### 📦 Inventario y Productos
- **Repuestos y servicios** con stock
- **Control de stock** con alertas de nivel mínimo  
- **Categorización** y búsqueda
- **Precios, IVA y márgenes**
- **Actualización automática** de stock al usar repuestos

### 💰 Facturación Ligera
- **Presupuestos** con aprobación del cliente
- **Facturas simplificadas**
- **Múltiples formas de pago**: efectivo, tarjeta, transferencia, Bizum
- **Control de pagos** y cobros

### 🖨️ Sistema de Impresión
- **Plantillas HTML** profesionales y personalizables:
  - Presupuesto
  - Orden de reparación  
  - Entrega y garantía
  - Factura simplificada
- **Generación PDF** opcional con wkhtmltopdf
- **Impresión directa** desde navegador

### 👤 Usuarios y Roles
- **Admin**: Acceso completo y configuración
- **Técnico**: Tickets asignados, diagnósticos, tiempos
- **Recepción**: Alta de tickets, clientes, cobros
- **Solo lectura**: Consulta de información

### 📊 Dashboard y Reportes  
- **KPIs en tiempo real**: tickets por estado, stock bajo, actividad diaria
- **Listados filtrados** por múltiples criterios
- **Búsqueda rápida** por código, cliente, serie, IMEI
- **Exportación CSV** de datos

### 🔐 Seguridad y Backup
- **Sistema de login** con hash de contraseñas
- **Control de permisos** granular por rol
- **Backups automáticos** en formato ZIP
- **Restauración** de datos con validación

## 🏗️ Arquitectura Técnica

### Base de Datos
- **SQLite** con sistema de migraciones automáticas
- **Esquema normalizado** con integridad referencial
- **Índices optimizados** para consultas frecuentes

### Estructura del Proyecto
```
/autoload          # Servicios globales (AppState, Router, DataService)
/data              # Repositorios y base de datos
/models            # Clases de modelo (Ticket, Cliente, Producto...)
/ui                # Pantallas e interfaces
/printing          # Plantillas HTML y servicio de impresión
/assets            # Temas, iconos y recursos
/adjuntos          # Archivos subidos por ticket
```

### Patrones de Diseño
- **Repository Pattern** para acceso a datos
- **Service Layer** para lógica de negocio
- **Router** para navegación centralizada
- **State Management** global con AppState

## 🚀 Instalación y Uso

### Requisitos
- **Godot 4.x** (4.3 o superior recomendado)
- **Windows** (diseñado específicamente para Windows)

### Opcional para PDF
- **wkhtmltopdf**: Para generar PDFs directamente (incluido en `/wkhtmltox-0.12.6-1.mxe-cross-win64/`)

### Primera Ejecución
1. **Abrir proyecto** en Godot Engine
2. **Ejecutar** la aplicación (F5)
3. **Login inicial**:
   - Email: `admin@tienda-sat.com`
   - Contraseña: `admin123`

### Configuración Inicial
1. **Ir a Ajustes** (solo Admin)
2. **Configurar datos de empresa**: nombre, NIF, dirección, contacto
3. **Configurar rutas**: wkhtmltopdf (opcional)
4. **Crear usuarios** adicionales con sus roles

## 📖 Manual de Usuario

### Flujo Típico de Trabajo

#### 1. Recepción de Equipo
- **Crear nuevo ticket** desde Dashboard
- **Seleccionar/crear cliente**
- **Registrar datos del equipo**: tipo, marca, modelo, serie
- **Describir avería** reportada por cliente
- **Adjuntar fotos** si es necesario
- **Imprimir orden** de reparación para firma

#### 2. Diagnóstico (Técnico)
- **Cambiar estado** a "Diagnosticando" 
- **Registrar tiempo** trabajado (cronómetro o manual)
- **Completar diagnóstico** técnico
- **Agregar líneas** de repuestos y mano de obra
- **Cambiar a "Presupuestado"** y generar presupuesto

#### 3. Aprobación del Cliente
- **Enviar/mostrar presupuesto** al cliente
- **Marcar como aprobado** una vez confirmado
- **Registrar método** de aprobación (verbal/email/firma)
- **Estado cambia** a "Aprobado" automáticamente

#### 4. Reparación
- **Cambiar a "En reparación"**
- **Consumir repuestos** del inventario automáticamente
- **Registrar tiempos** adicionales
- **Cambiar a "En pruebas"** al finalizar

#### 5. Entrega
- **Cambiar a "Listo para entrega"**
- **Registrar pago** (efectivo/tarjeta/etc.)
- **Generar factura** simplificada
- **Imprimir documento** de entrega y garantía
- **Cambiar a "Entregado"** y luego "Cerrado"

### Características Avanzadas

#### Búsqueda Rápida
- **Buscar por cualquier campo**: código, nombre, teléfono, serie, IMEI
- **Filtros combinados**: estado + técnico + fechas
- **Resultados en tiempo real**

#### Gestión de Stock
- **Alertas automáticas** cuando stock < mínimo
- **Actualización automática** al usar repuestos
- **Historial de movimientos** (próxima versión)

#### Impresión Flexible
- **Vista previa HTML** antes de imprimir
- **Plantillas personalizables** con variables
- **PDF directo** si wkhtmltopdf está configurado

#### Backup y Seguridad
- **Backup manual** desde Ajustes
- **Incluye base de datos** y adjuntos
- **Restauración selectiva** con validación
- **Historial de backups** con información

## 🔧 Configuración Avanzada

### Variables de Empresa
Configurables desde **Ajustes > Empresa**:
- `empresa_nombre`: Nombre para documentos
- `empresa_nif`: NIF/CIF fiscal  
- `empresa_direccion`: Dirección completa
- `empresa_telefono`: Teléfono de contacto
- `empresa_email`: Email de contacto

### Variables de Sistema  
- `iva_defecto`: IVA por defecto para nuevos productos (21%)
- `ticket_prefix`: Prefijo para códigos de ticket (SAT)
- `wkhtmltopdf_path`: Ruta al ejecutable para PDFs
- `stock_negativo_permitido`: Permitir ventas sin stock (0=No, 1=Sí)

### Personalización de Plantillas
Las plantillas HTML están en `/printing/templates/`:
- `presupuesto.html`
- `orden_reparacion.html`  
- `entrega_garantia.html`
- `factura_simplificada.html`

**Variables disponibles**: `{{empresa.*}}`, `{{cliente.*}}`, `{{ticket.*}}`, `{{equipo.*}}`, `{{lineas}}`, `{{totales.*}}`

## 🐛 Resolución de Problemas

### 🔴 ERROR: "Base de datos no inicializada" / No funciona el login
**SOLUCIÓN INMEDIATA:**
1. **Cerrar completamente Godot** si está abierto
2. **Borrar archivo de BD**: `%APPDATA%\Godot\app_userdata\Tienda SAT\tienda_sat.db` si existe
3. **Abrir el proyecto** en Godot 4.x
4. **Ejecutar** el proyecto (F5 o botón Play)
5. **Esperar 3-5 segundos** en la pantalla de login para que el sistema se inicialice
6. **Login**: `admin@tienda-sat.com` / `admin123`

### ⚠️ Si el error persiste:
1. En Godot: **Project > Project Settings > Application > Config**
2. Verificar que **Name** sea "Tienda SAT" 
3. Ir a **Autoload** y verificar que existen:
   - `AppState`: `*res://autoload/AppState.gd` ✅ Enable
   - `Router`: `*res://autoload/Router.gd` ✅ Enable  
   - `DataService`: `*res://autoload/DataService.gd` ✅ Enable
4. **Cerrar y reabrir** el proyecto completamente
5. **Reinstalar** Godot 4.x si es necesario

### "Error al generar PDF"
- Verificar ruta de wkhtmltopdf en Ajustes  
- Si no tienes wkhtmltopdf, usar impresión HTML normal

### "No se pueden crear tickets"
- Verificar permisos de usuario
- Comprobar que hay al menos un cliente creado

## 📋 Roadmap y Mejoras Futuras

### v1.1 - Mejoras Inmediatas
- [ ] Detalle completo de ticket (formulario de edición)
- [ ] Cronómetro integrado para tiempos
- [ ] Más reportes (rentabilidad, técnicos, periodos)
- [ ] Importación/exportación CSV

### v1.2 - Funcionalidades Avanzadas  
- [ ] Notificaciones por email automáticas
- [ ] API REST para integración externa
- [ ] App móvil compañera
- [ ] Sincronización multi-tienda

### v1.3 - Empresa
- [ ] Multi-empresa/sucursales
- [ ] Integración con proveedores
- [ ] Facturación completa con series
- [ ] Contabilidad básica

## 🏆 Créditos

**Desarrollado por**: Tomás González  
**Año**: 2025  
**Motor**: Godot Engine 4.5  
**Versión**: 1.0.0

### Agradecimientos

- Comunidad de Godot Engine por la documentación y recursos
- Usuarios beta que ayudaron a probar el sistema
- Tiendas de informática que proporcionaron feedback valioso

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

**Copyright (c) 2025 Tomás González**

## 🤝 Soporte

Para soporte técnico, personalización o nuevas funcionalidades:
- Revisar la documentación incluida
- Comprobar los logs de Godot en caso de errores
- El código está completamente documentado para facilitar modificaciones

## 🌟 ¿Te gusta el proyecto?

Si este sistema te ha sido útil, considera:
- ⭐ Dar una estrella al repositorio
- 🍴 Hacer un fork para contribuir
- 📢 Compartir con otros técnicos
- 🐛 Reportar bugs o sugerir mejoras

---

**¡Desarrollado con ❤️ en Godot Engine por Tomás González!**#   a p p - t i e n d a - i n f o r m a t i c a - s a t - g o d o t 
 
 