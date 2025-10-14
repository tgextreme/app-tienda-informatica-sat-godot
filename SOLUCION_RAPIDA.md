# 🚑 SOLUCIÓN RÁPIDA - ERROR DE LOGIN

## ❌ PROBLEMA
La aplicación muestra "Demasiados intentos fallidos" y no permite hacer login, indicando problemas con la base de datos.

## ✅ SOLUCIÓN (PASO A PASO)

### 1️⃣ **Cerrar Godot completamente**
- Si Godot está abierto, cerrarlo completamente
- Asegurarse de que no queden procesos en segundo plano

### 2️⃣ **Limpiar datos de la aplicación** 
Abrir el Explorador de Windows y navegar a:
```
%APPDATA%\Godot\app_userdata\Tienda SAT\
```

Si existe el archivo `tienda_sat.db`, **eliminarlo**.

### 3️⃣ **Abrir el proyecto**
1. Abrir Godot 4.x
2. Abrir el proyecto desde: `C:\Users\usuario\Documents\tienda-sat`
3. Verificar que aparezcan los archivos del proyecto

### 4️⃣ **Verificar configuración** 
En Godot, ir a `Project > Project Settings`:

**Application > Config:**
- Name: `Tienda SAT`

**Autoload (debe existir):**
- `AppState` → `*res://autoload/AppState.gd` ✅ Enable
- `Router` → `*res://autoload/Router.gd` ✅ Enable 
- `DataService` → `*res://autoload/DataService.gd` ✅ Enable

### 5️⃣ **Ejecutar el proyecto**
1. Presionar **F5** o el botón ▶️ Play
2. Se abrirá la pantalla de login
3. **ESPERAR 5-10 SEGUNDOS** (importante: el sistema se está inicializando)
4. Usar credenciales:
   - **Email:** `admin@tienda-sat.com`
   - **Contraseña:** `admin123`

### 6️⃣ **Si sigue fallando**
1. En Godot, abrir el archivo `diagnostico_sat.gd`
2. En el editor de scripts, hacer clic derecho → "Change Script Type" → "Tool Script"
3. Ejecutar el script para ver diagnósticos detallados

---

## 🔧 DIAGNÓSTICO ADICIONAL

Si el problema persiste, revisar en la consola de Godot (Output) los mensajes durante la inicialización:

✅ **Mensajes correctos:**
```
Iniciando inicialización de base de datos...
Base de datos creada, ejecutando migraciones...
Ejecutando migraciones...
Migraciones completadas - sistema simplificado listo
Base de datos inicializada correctamente
Datos iniciales creados
AppState inicializando...
AppState listo
```

❌ **Mensajes de error a buscar:**
- `ERROR: Base de datos no inicializada`
- `Error creando instancia de base de datos`
- `DataService no está listo`

---

## 📞 ÚLTIMO RECURSO

Si nada funciona:
1. Descargar Godot 4.5 fresh desde godotengine.org
2. Crear nuevo proyecto 
3. Copiar todos los archivos de `tienda-sat` al nuevo proyecto
4. Configurar autoloads manualmente
5. Ejecutar

La aplicación **SÍ FUNCIONA** - el problema es de inicialización temporal que se soluciona con estos pasos.