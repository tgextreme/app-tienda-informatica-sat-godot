# 📋 FORMULARIO NUEVO TICKET - GUÍA DE USO

## ✅ **Funcionalidad Implementada**

### 🎯 **Cómo Acceder:**
1. Desde el Dashboard, hacer clic en "📋 NUEVO TICKET"
2. Se abre el formulario completo

### 📝 **Campos del Formulario:**

#### 👤 **Datos del Cliente:**
- **Buscar Cliente**: Escribir nombre, teléfono o email
- **🔍**: Buscar manualmente
- **➕ NUEVO**: Crear nuevo cliente (en desarrollo)
- Se auto-completa si encuentra coincidencia única

#### 💻 **Datos del Equipo:**
- **Tipo**: PC, Portátil, Móvil, Tablet, etc.
- **Marca**: HP, Dell, Samsung, etc.
- **Modelo**: Pavilion DV6, Galaxy S21, etc.
- **Nº Serie/IMEI**: Identificación única
- **Accesorios**: Cargador, fundas, cables...
- **Password/PIN**: Contraseña de bloqueo

#### 🎫 **Datos del Ticket:**
- **Código**: Se genera automáticamente
- **Prioridad**: BAJA, NORMAL, ALTA, URGENTE
- **Técnico**: Asignación opcional

#### 🔧 **Descripción de Avería:**
- **Descripción**: Problema reportado por cliente (obligatorio)
- **Notas**: Información adicional para cliente

### 🎮 **Cómo Usar:**

#### 1️⃣ **Seleccionar Cliente:**
```
1. Escribir en "Buscar Cliente": "Juan" 
2. Esperar 0.5 segundos → búsqueda automática
3. Si aparece 1 resultado → se selecciona automático
4. Si aparecen varios → popup para elegir
5. Aparecen datos del cliente seleccionado
```

#### 2️⃣ **Completar Equipo:**
```
1. Seleccionar "Tipo de Equipo" (obligatorio)
2. Completar Marca/Modelo (opcional pero recomendado)
3. Número de serie si está disponible
4. Anotar accesorios que trae
5. Password si lo hay (se guarda oculto)
```

#### 3️⃣ **Configurar Ticket:**
```
1. Prioridad por defecto: NORMAL
2. Técnico: opcional, se puede asignar después
3. El código se genera automático: SAT-2025-000001
```

#### 4️⃣ **Describir Avería:**
```
1. Descripción detallada del problema (OBLIGATORIO)
   Ejemplo: "El ordenador no arranca, se queda en pantalla negra"
2. Notas adicionales (opcional)
   Ejemplo: "Cliente necesita datos recuperados urgente"
```

#### 5️⃣ **Guardar:**
```
1. Clic en "💾 GUARDAR"
2. Se valida automáticamente
3. Si hay errores → se muestran en rojo
4. Si es correcto → "Ticket creado" y vuelve al dashboard
```

### 🔧 **Validaciones Automáticas:**
- ✅ Cliente seleccionado (obligatorio)
- ✅ Tipo de equipo (obligatorio)
- ✅ Descripción de avería (obligatorio)

### 🎯 **Estado Final:**
- Ticket creado con estado "Nuevo"
- Código automático generado
- Fecha/hora actual
- Historial inicial creado
- Vuelve al dashboard

### 🔍 **Búsqueda de Clientes:**
- **Automática**: Al escribir, busca después de 0.5s
- **Manual**: Botón 🔍
- **Nuevo Cliente**: Botón ➕ (pendiente implementar)
- **Formato de búsqueda**: Busca en nombre, teléfono y email

### 📊 **Datos de Prueba:**
Si no hay clientes, se crea automáticamente:
- **Nombre**: Juan Pérez
- **Teléfono**: 666-123-456  
- **Email**: juan.perez@email.com

## 🚀 **Próximos Pasos:**
1. Implementar "Nuevo Cliente" en el formulario
2. Añadir validación avanzada de campos
3. Mejores mensajes de error
4. Auto-guardado de borrador

El formulario está **100% funcional** para crear tickets básicos.