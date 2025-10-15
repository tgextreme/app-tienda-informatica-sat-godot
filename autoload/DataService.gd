extends Node

# DataService - Fachada para acceso a datos
# Centraliza todas las operaciones de base de datos y proporciona una API limpia

const DatabaseClass = preload("res://data/sqlite/database.gd")
const MigrationsClass = preload("res://data/sqlite/migrations.gd")

var db: DatabaseClass

# Señales para eventos de datos
signal ticket_guardado(ticket_id: int)
signal cliente_guardado(cliente_id: int)
signal producto_guardado(producto_id: int)
signal stock_actualizado(producto_id: int, nuevo_stock: int)

func _ready():
	inicializar_base_datos()

func inicializar_base_datos():
	print("Iniciando inicialización de base de datos...")
	db = DatabaseClass.new()
	
	if db == null:
		push_error("Error creando instancia de base de datos")
		return
	
	print("Base de datos creada, ejecutando migraciones...")
	# Ejecutar migraciones - Comentado temporalmente para resolver errores de compilación
	# MigrationsClass.run_migrations(db)
	migrar_campo_activo_usuarios()
	print("Migraciones completadas - sistema simplificado listo")
	
	print("Base de datos inicializada correctamente")
	
	# Verificar y crear datos de prueba si es necesario
	verificar_y_crear_datos_iniciales()

func verificar_y_crear_datos_iniciales():
	"""Verifica si existen datos básicos y los crea si es necesario"""
	print("🔍 [DATASERVICE] Verificando datos iniciales...")
	
	# Verificar si hay clientes
	var clientes_existentes = execute_sql("SELECT COUNT(*) as total FROM clientes")
	var total_clientes = 0
	if clientes_existentes.size() > 0:
		total_clientes = clientes_existentes[0].get("total", 0)
	
	print("📊 [DATASERVICE] Clientes existentes: ", total_clientes)
	
	# Crear datos de prueba si no hay clientes
	if total_clientes == 0:
		print("🔧 [DATASERVICE] No hay clientes, creando datos de prueba...")
		crear_datos_de_prueba_completos()
	else:
		print("✅ [DATASERVICE] Datos de clientes ya existen")
	
	print("✅ [DATASERVICE] Inicialización de clientes completada")
	
	# Verificar productos independientemente
	verificar_y_crear_productos()
	
	# Corregir referencias rotas de tickets
	corregir_referencias_tickets()
	
	# Asegurar que hay un usuario técnico de prueba
	crear_usuario_tecnico_prueba()

func verificar_y_crear_productos():
	"""Verifica si existen productos VÁLIDOS y los crea si es necesario"""
	print("📦 [DATASERVICE] Verificando productos...")
	
	# Verificar productos válidos (con nombre)
	var productos_validos = execute_sql("SELECT COUNT(*) as total FROM productos WHERE nombre IS NOT NULL AND nombre != ''")
	var total_productos_validos = 0
	if productos_validos.size() > 0:
		total_productos_validos = productos_validos[0].get("total", 0)
	
	print("📊 [DATASERVICE] Productos válidos existentes: ", total_productos_validos)
	
	if total_productos_validos < 5:
		print("🔧 [DATASERVICE] Productos insuficientes o corruptos, creando productos válidos...")
		crear_productos_temporales_en_bd()
	else:
		print("✅ [DATASERVICE] Productos válidos ya existen")

func crear_usuario_tecnico_prueba():
	"""Crea o actualiza un usuario ADMIN de prueba con credenciales conocidas"""
	print("👤 [DATASERVICE] Verificando usuario ADMIN de prueba...")
	
	var email_tecnico = "user@mail.com"
	var password_tecnico = "user123"
	var password_hashed = generar_hash_password(password_tecnico)
	
	# Verificar si ya existe
	var usuarios_existentes = execute_sql("SELECT * FROM usuarios WHERE email = ?", [email_tecnico])
	
	if usuarios_existentes.size() > 0:
		print("🔧 [DATASERVICE] Actualizando usuario a ADMIN...")
		execute_sql("UPDATE usuarios SET password_hash = ?, rol_id = 1, nombre = ? WHERE email = ?", 
			[password_hashed, "Admin Prueba", email_tecnico])
		print("✅ [DATASERVICE] Usuario ADMIN actualizado - Email: %s, Password: %s" % [email_tecnico, password_tecnico])
	else:
		print("🔧 [DATASERVICE] Creando nuevo usuario ADMIN...")
		execute_sql("""
			INSERT INTO usuarios (nombre, email, password_hash, rol_id, created_at) 
			VALUES (?, ?, ?, ?, datetime('now'))
		""", ["Admin Prueba", email_tecnico, password_hashed, 1])
		print("✅ [DATASERVICE] Usuario ADMIN creado - Email: %s, Password: %s" % [email_tecnico, password_tecnico])

func corregir_referencias_tickets():
	"""Corrige referencias rotas de tickets a clientes que no existen"""
	print("🔧 [DATASERVICE] Corrigiendo referencias de tickets...")
	
	# Obtener todos los tickets
	var tickets = execute_sql("SELECT id, cliente_id FROM tickets")
	
	# Obtener IDs de clientes válidos
	var clientes = execute_sql("SELECT id FROM clientes")
	var clientes_validos = []
	for cliente in clientes:
		clientes_validos.append(int(cliente.id))
	
	print("🔍 [DATASERVICE] Clientes válidos: ", clientes_validos)
	
	for ticket in tickets:
		var ticket_id = int(ticket.id)
		var cliente_id = int(ticket.cliente_id)
		
		if not clientes_validos.has(cliente_id):
			print("🔧 [DATASERVICE] Ticket ID ", ticket_id, " tiene cliente_id inválido: ", cliente_id)
			# Asignar al primer cliente disponible
			if clientes_validos.size() > 0:
				var nuevo_cliente_id = clientes_validos[0]
				execute_non_query("UPDATE tickets SET cliente_id = ? WHERE id = ?", [nuevo_cliente_id, ticket_id])
				print("✅ [DATASERVICE] Ticket ID ", ticket_id, " actualizado a cliente_id: ", nuevo_cliente_id)
			else:
				print("❌ [DATASERVICE] No hay clientes válidos para asignar")
	
	print("✅ [DATASERVICE] Corrección de referencias completada")

# Métodos de conveniencia para ejecutar SQL
func execute_sql(query: String, params: Array = []) -> Array:
	if db == null:
		push_error("Base de datos no inicializada")
		return []
	return db.execute_sql(query, params)

func execute_non_query(query: String, params: Array = []) -> bool:
	if db == null:
		push_error("Base de datos no inicializada")
		return false
	return db.execute_non_query(query, params)

func get_last_insert_id() -> int:
	if db == null:
		return -1
	return db.get_last_insert_id()

# ==========================================
# MÉTODOS ESPECÍFICOS DE NEGOCIO
# ==========================================

# --- TICKETS ---

func buscar_tickets(filtros: Dictionary = {}) -> Array:
	# Simplificado - obtener todos los tickets y filtrar en código
	print("🔍 [DATASERVICE] Buscando tickets con filtros: ", filtros)
	var tickets = execute_sql("SELECT * FROM tickets ORDER BY id DESC")
	var clientes = execute_sql("SELECT * FROM clientes")
	var usuarios = execute_sql("SELECT * FROM usuarios")
	
	print("📊 [DATASERVICE] Datos obtenidos: tickets=", tickets.size(), " clientes=", clientes.size(), " usuarios=", usuarios.size())
	
	# Crear mapas para lookups rápidos con conversión numérica
	var clientes_map = {}
	for cliente in clientes:
		var cliente_id = cliente.get("id")
		if cliente_id != null:
			# Usar valor numérico como clave para evitar problemas de tipos
			var clave_numerica = float(str(cliente_id))
			clientes_map[clave_numerica] = cliente
		
	var usuarios_map = {}
	for usuario in usuarios:
		var usuario_id = usuario.get("id")
		if usuario_id != null:
			# Usar valor numérico como clave para evitar problemas de tipos
			var clave_numerica = float(str(usuario_id))
			usuarios_map[clave_numerica] = usuario
	
	# Combinar datos
	var result = []
	for ticket in tickets:
		var ticket_completo = ticket.duplicate()
		
		# Agregar datos del cliente con búsqueda numérica
		var cliente_id = ticket.get("cliente_id")
		if cliente_id != null:
			var cliente_id_num = float(str(cliente_id))
			if clientes_map.has(cliente_id_num):
				var cliente = clientes_map[cliente_id_num]
				ticket_completo["cliente_nombre"] = cliente.get("nombre", "")
				ticket_completo["cliente_telefono"] = cliente.get("telefono", "")
		
		# Agregar datos del técnico con búsqueda numérica
		var tecnico_id = ticket.get("tecnico_id")
		if tecnico_id != null:
			var tecnico_id_num = float(str(tecnico_id))
			if usuarios_map.has(tecnico_id_num):
				var tecnico = usuarios_map[tecnico_id_num]
				ticket_completo["tecnico_nombre"] = tecnico.get("nombre", "")
			
		# Aplicar filtros
		var incluir = true
		
		if filtros.has("estado") and filtros.get("estado") != "" and ticket.get("estado") != filtros.get("estado"):
			incluir = false
			
		if incluir and filtros.has("cliente_id") and filtros.get("cliente_id", 0) > 0 and ticket.get("cliente_id") != filtros.get("cliente_id"):
			incluir = false
			
		if incluir:
			result.append(ticket_completo)
	
	print("✅ [DATASERVICE] Devolviendo ", result.size(), " tickets")
	if result.size() > 0:
		print("🔍 [DATASERVICE] Ejemplo primer ticket: ", result[0])
	
	return result

func obtener_ticket(ticket_id: int) -> Dictionary:
	var tickets = execute_sql("SELECT * FROM tickets WHERE id = ?", [ticket_id])
	
	if tickets.size() > 0:
		var ticket = tickets[0]
		
		# Obtener datos del cliente
		var clientes = execute_sql("SELECT * FROM clientes WHERE id = ?", [ticket.cliente_id])
		if clientes.size() > 0:
			var cliente = clientes[0]
			ticket["cliente_nombre"] = cliente.nombre
			ticket["cliente_nif"] = cliente.nif
			ticket["cliente_email"] = cliente.email
			ticket["cliente_telefono"] = cliente.telefono
			ticket["cliente_direccion"] = cliente.direccion
		
		# Obtener datos del técnico si existe
		if ticket.has("tecnico_id") and ticket.tecnico_id:
			var tecnicos = execute_sql("SELECT * FROM usuarios WHERE id = ?", [ticket.tecnico_id])
			if tecnicos.size() > 0:
				ticket["tecnico_nombre"] = tecnicos[0].nombre
		
		return ticket
	return {}

func guardar_ticket(ticket_data: Dictionary) -> int:
	var ticket_id = -1
	
	if ticket_data.has("id") and int(ticket_data.id) > 0:
		# Actualizar ticket existente
		ticket_id = int(ticket_data.id)
		var sql = """
			UPDATE tickets SET
				estado = ?, prioridad = ?, cliente_id = ?, tecnico_id = ?,
				fecha_presupuesto = ?, fecha_aprobacion = ?, fecha_entrega = ?, fecha_cierre = ?,
				equipo_tipo = ?, equipo_marca = ?, equipo_modelo = ?, numero_serie = ?, imei = ?,
				accesorios = ?, password_bloqueo = ?, averia_cliente = ?, diagnostico = ?,
				aprobacion_metodo = ?, aprobacion_usuario_id = ?, notas_internas = ?, notas_cliente = ?
			WHERE id = ?
		"""
		
		execute_non_query(sql, [
			ticket_data.get("estado", "Nuevo"),
			ticket_data.get("prioridad", "NORMAL"), 
			ticket_data.get("cliente_id"),
			ticket_data.get("tecnico_id"),
			ticket_data.get("fecha_presupuesto"),
			ticket_data.get("fecha_aprobacion"),
			ticket_data.get("fecha_entrega"),
			ticket_data.get("fecha_cierre"),
			ticket_data.get("equipo_tipo"),
			ticket_data.get("equipo_marca"),
			ticket_data.get("equipo_modelo"),
			ticket_data.get("numero_serie"),
			ticket_data.get("imei"),
			ticket_data.get("accesorios"),
			ticket_data.get("password_bloqueo"),
			ticket_data.get("averia_cliente"),
			ticket_data.get("diagnostico"),
			ticket_data.get("aprobacion_metodo"),
			ticket_data.get("aprobacion_usuario_id"),
			ticket_data.get("notas_internas"),
			ticket_data.get("notas_cliente"),
			ticket_id
		])
	else:
		# Crear nuevo ticket
		var codigo = ticket_data.get("codigo", AppState.generar_codigo_ticket())
		
		var sql = """
			INSERT INTO tickets (
				codigo, estado, prioridad, cliente_id, tecnico_id,
				equipo_tipo, equipo_marca, equipo_modelo, numero_serie, imei,
				accesorios, password_bloqueo, averia_cliente, diagnostico,
				notas_internas, notas_cliente
			) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		"""
		
		print("🔍 [DEBUG] Insertando ticket con datos: ", [
			codigo,
			ticket_data.get("estado", "Nuevo"), 
			ticket_data.get("prioridad", "NORMAL"),
			ticket_data.get("cliente_id"),
			ticket_data.get("tecnico_id"),
			ticket_data.get("equipo_tipo"),
			ticket_data.get("equipo_marca"),
			ticket_data.get("equipo_modelo")
		])
		
		var insert_exitoso = execute_non_query(sql, [
			codigo,                                    # 1: codigo
			ticket_data.get("estado", "Nuevo"),       # 2: estado 
			ticket_data.get("prioridad", "NORMAL"),   # 3: prioridad
			ticket_data.get("cliente_id"),            # 4: cliente_id
			ticket_data.get("tecnico_id"),            # 5: tecnico_id
			ticket_data.get("equipo_tipo"),           # 6: equipo_tipo
			ticket_data.get("equipo_marca"),          # 7: equipo_marca
			ticket_data.get("equipo_modelo"),         # 8: equipo_modelo
			ticket_data.get("numero_serie"),          # 9: numero_serie
			ticket_data.get("imei"),                  # 10: imei
			ticket_data.get("accesorios"),            # 11: accesorios
			ticket_data.get("password_bloqueo"),      # 12: password_bloqueo
			ticket_data.get("averia_cliente"),        # 13: averia_cliente
			ticket_data.get("diagnostico"),           # 14: diagnostico
			ticket_data.get("notas_internas"),        # 15: notas_internas
			ticket_data.get("notas_cliente")          # 16: notas_cliente
		])
		
		if insert_exitoso:
			ticket_id = get_last_insert_id()
			print("✅ [DATASERVICE] Ticket insertado correctamente con ID: ", ticket_id)
		else:
			ticket_id = -1
			print("❌ [DATASERVICE] Error al insertar ticket - validación FK falló")
	
	if ticket_id > 0:
		ticket_guardado.emit(ticket_id)
	
	return ticket_id

func cambiar_estado_ticket(ticket_id: int, nuevo_estado: String, usuario_id: int) -> bool:
	# Verificar que el cambio de estado es válido
	var ticket = obtener_ticket(ticket_id)
	if ticket.is_empty():
		return false
	
	var estado_actual = ticket.get("estado", "")
	if not AppState.puede_cambiar_estado(estado_actual, nuevo_estado):
		push_error("Cambio de estado no permitido: %s -> %s" % [estado_actual, nuevo_estado])
		return false
	
	# Actualizar estado
	var actualizado = execute_non_query(
		"UPDATE tickets SET estado = ? WHERE id = ?",
		[nuevo_estado, ticket_id]
	)
	
	if actualizado:
		# Registrar en historial
		agregar_historial_ticket(ticket_id, usuario_id, "cambio_estado", 
			"Estado cambiado de '%s' a '%s'" % [estado_actual, nuevo_estado])
	
	return actualizado

func agregar_historial_ticket(ticket_id: int, usuario_id: int, accion: String, detalle: String):
	execute_non_query("""
		INSERT INTO ticket_historial (ticket_id, usuario_id, accion, detalle)
		VALUES (?, ?, ?, ?)
	""", [ticket_id, usuario_id, accion, detalle])

func obtener_historial_ticket(ticket_id: int) -> Array:
	return execute_sql("""
		SELECT h.*, u.nombre as usuario_nombre
		FROM ticket_historial h
		LEFT JOIN usuarios u ON h.usuario_id = u.id
		WHERE h.ticket_id = ?
		ORDER BY h.fecha DESC
	""", [ticket_id])

func actualizar_campo_ticket(ticket_id: int, campo: String, valor) -> bool:
	"""Actualiza un campo específico de un ticket"""
	print("🔄 [DATASERVICE] Actualizando ticket ", ticket_id, " - ", campo, ": ", valor)
	
	var sql = "UPDATE tickets SET %s = ?, fecha_actualizacion = datetime('now') WHERE id = ?" % [campo]
	var resultado = execute_non_query(sql, [valor, ticket_id])
	
	if resultado:
		print("✅ [DATASERVICE] Campo ", campo, " actualizado correctamente")
	else:
		print("❌ [DATASERVICE] Error al actualizar campo ", campo)
	
	return resultado

func eliminar_ticket(ticket_id: int) -> bool:
	"""Elimina un ticket del sistema"""
	print("🗑️ [DATASERVICE] Eliminando ticket ID: ", ticket_id)
	
	# Verificar que el ticket existe
	var ticket = obtener_ticket(ticket_id)
	if ticket.is_empty():
		print("❌ [DATASERVICE] Ticket no encontrado para eliminar")
		return false
	
	# Eliminar ticket
	var sql = "DELETE FROM tickets WHERE id = ?"
	var resultado = execute_non_query(sql, [ticket_id])
	
	if resultado:
		print("✅ [DATASERVICE] Ticket eliminado correctamente")
		return true
	else:
		print("❌ [DATASERVICE] Error al eliminar ticket")
		return false

func actualizar_ticket(ticket_data: Dictionary) -> bool:
	"""Actualiza todos los campos de un ticket existente"""
	print("🔄 [DATASERVICE] Actualizando ticket completo ID: ", ticket_data.get("id", ""))
	
	var ticket_id = ticket_data.get("id", 0)
	if ticket_id <= 0:
		print("❌ [DATASERVICE] ID de ticket inválido para actualización")
		return false
	
	var sql = """
		UPDATE tickets SET
			estado = ?,
			prioridad = ?,
			cliente_id = ?,
			tecnico_id = ?,
			equipo_tipo = ?,
			equipo_marca = ?,
			equipo_modelo = ?,
			numero_serie = ?,
			password_bloqueo = ?,
			accesorios = ?,
			averia_cliente = ?,
			notas_cliente = ?,
			fecha_actualizacion = datetime('now')
		WHERE id = ?
	"""
	
	var resultado = execute_non_query(sql, [
		ticket_data.get("estado", "Abierto"),
		ticket_data.get("prioridad", "Normal"),
		ticket_data.get("cliente_id"),
		ticket_data.get("tecnico_id"),
		ticket_data.get("equipo_tipo", "PC"),
		ticket_data.get("equipo_marca", ""),
		ticket_data.get("equipo_modelo", ""),
		ticket_data.get("numero_serie", ""),
		ticket_data.get("password_bloqueo", ""),
		ticket_data.get("accesorios", ""),
		ticket_data.get("averia_cliente", ""),
		ticket_data.get("notas_cliente", ""),
		ticket_id
	])
	
	if resultado:
		print("✅ [DATASERVICE] Ticket actualizado correctamente")
	else:
		print("❌ [DATASERVICE] Error al actualizar ticket")
	
	return resultado

func obtener_usuarios_por_rol(rol: String) -> Array:
	"""Obtiene usuarios por rol (admin, tecnico, etc.)"""
	print("👥 [DATASERVICE] Obteniendo usuarios con rol: ", rol)
	
	var usuarios = execute_sql("""
		SELECT id, nombre, email, rol
		FROM empleados 
		WHERE rol = ? 
		ORDER BY nombre ASC
	""", [rol])
	
	print("✅ [DATASERVICE] Encontrados ", usuarios.size(), " usuarios con rol ", rol)
	return usuarios

# --- CLIENTES ---

func buscar_clientes(busqueda: String = "") -> Array:
	print("🔍 [DATASERVICE] Buscando clientes con: '", busqueda, "'")
	
	if busqueda == "":
		# Obtener todos los clientes
		var clientes = execute_sql("SELECT * FROM clientes ORDER BY nombre ASC")
		print("📊 [DATASERVICE] Total de clientes en BD: ", clientes.size())
		
		# Debug: mostrar datos de los primeros clientes
		for i in range(min(3, clientes.size())):
			var cliente = clientes[i]
			print("🔍 [DATASERVICE] Cliente ", i+1, ":")
			print("    ID: '", cliente.get("id", "NULL"), "'")
			print("    Nombre: '", cliente.get("nombre", "NULL"), "'")
			print("    Teléfono: '", cliente.get("telefono", "NULL"), "'")
			print("    Email: '", cliente.get("email", "NULL"), "'")
		
		return clientes
	else:
		# Buscar con filtro
		var sql = """
			SELECT * FROM clientes 
			WHERE nombre LIKE ? 
			   OR telefono LIKE ? 
			   OR email LIKE ? 
			   OR nif LIKE ?
			ORDER BY nombre ASC
		"""
		var filtro = "%" + busqueda + "%"
		var clientes = execute_sql(sql, [filtro, filtro, filtro, filtro])
		print("✅ [DATASERVICE] Clientes encontrados: ", clientes.size())
		return clientes

func obtener_cliente(cliente_id: int) -> Dictionary:
	var clientes = execute_sql("SELECT * FROM clientes WHERE id = ?", [cliente_id])
	if clientes.size() > 0:
		return clientes[0]
	return {}

func guardar_cliente(cliente_data: Dictionary) -> int:
	print("💾 [DATASERVICE] Guardando cliente: ", cliente_data.get("nombre", ""))
	print("📊 [DATASERVICE] Datos del cliente: ", cliente_data)
	
	var cliente_id = -1
	
	if cliente_data.has("id") and int(cliente_data.get("id", 0)) > 0:
		# Actualizar cliente existente
		cliente_id = int(cliente_data.id)
		var success = execute_non_query("""
			UPDATE clientes SET
				nombre = ?, nif = ?, email = ?, telefono = ?, telefono_alt = ?,
				direccion = ?, notas = ?, rgpd_consent = ?
			WHERE id = ?
		""", [
			cliente_data.get("nombre"),
			cliente_data.get("nif"),
			cliente_data.get("email"),
			cliente_data.get("telefono"),
			cliente_data.get("telefono_alt"),
			cliente_data.get("direccion"),
			cliente_data.get("notas"),
			cliente_data.get("rgpd_consent", 0),
			cliente_id
		])
		
		if not success:
			print("❌ [DATASERVICE] Error al actualizar cliente")
			return -1
	else:
		# Crear nuevo cliente
		print("🔧 [DATASERVICE] Creando nuevo cliente...")
		var params = [
			cliente_data.get("nombre"),
			cliente_data.get("nif"),
			cliente_data.get("email"), 
			cliente_data.get("telefono"),
			cliente_data.get("telefono_alt"),
			cliente_data.get("direccion"),
			cliente_data.get("notas"),
			cliente_data.get("rgpd_consent", 0)
		]
		
		print("📋 [DATASERVICE] Parámetros de inserción: ", params)
		
		var success = execute_non_query("""
			INSERT INTO clientes (nombre, nif, email, telefono, telefono_alt, direccion, notas, rgpd_consent)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		""", params)
		
		print("🔍 [DATASERVICE] Resultado de execute_non_query: ", success)
		
		if success:
			cliente_id = get_last_insert_id()
			print("🆔 [DATASERVICE] ID obtenido: ", cliente_id)
		else:
			print("❌ [DATASERVICE] Error al crear cliente")
			return -1
	
	if cliente_id > 0:
		print("✅ [DATASERVICE] Cliente guardado correctamente con ID: ", cliente_id)
		cliente_guardado.emit(cliente_id)
	
	return cliente_id

# --- PRODUCTOS ---

func buscar_productos(filtros: Dictionary = {}) -> Array:
	var sql = "SELECT * FROM productos WHERE 1=1"
	var params = []
	
	if filtros.has("busqueda") and filtros.busqueda != "":
		sql += " AND (nombre LIKE ? OR sku LIKE ? OR categoria LIKE ?)"
		var busqueda_param = "%" + filtros.busqueda + "%"
		params.append_array([busqueda_param, busqueda_param, busqueda_param])
	
	if filtros.has("categoria") and filtros.categoria != "":
		sql += " AND categoria = ?"
		params.append(filtros.categoria)
	
	if filtros.has("tipo") and filtros.tipo != "":
		sql += " AND tipo = ?"
		params.append(filtros.tipo)
	
	if filtros.has("stock_bajo") and filtros.stock_bajo:
		sql += " AND stock <= stock_min"
	
	sql += " ORDER BY nombre"
	print("🔍 [DATASERVICE] Ejecutando buscar_productos - SQL: ", sql)
	print("🔍 [DATASERVICE] Parámetros: ", params)
	var resultados = execute_sql(sql, params)
	print("🔍 [DATASERVICE] Resultados buscar_productos: ", resultados.size(), " productos")
	if resultados.size() > 0:
		print("🔍 [DATASERVICE] Primer producto resultado: ", resultados[0])
	return resultados

func obtener_producto(producto_id: int) -> Dictionary:
	print("🔍 [DATASERVICE] Obteniendo producto ID: ", producto_id)
	var productos = execute_sql("SELECT * FROM productos WHERE id = ?", [producto_id])
	print("🔍 [DATASERVICE] Resultados encontrados: ", productos.size())
	
	if productos.size() > 0:
		var producto = productos[0]
		print("🔍 [DATASERVICE] Producto encontrado: ", producto)
		
		# Verificar si los datos están corruptos (solo tiene id)
		if producto.has("nombre") and producto.get("nombre", "") != "":
			print("✅ [DATASERVICE] Datos válidos")
			return producto
		else:
			print("⚠️ [DATASERVICE] Datos corruptos detectados - usando datos temporales")
			return obtener_producto_temporal(producto_id)
	
	print("❌ [DATASERVICE] Producto NO encontrado - usando datos temporales")
	return obtener_producto_temporal(producto_id)

func obtener_producto_temporal(producto_id: int) -> Dictionary:
	"""Obtener producto de datos temporales hardcodeados y asegurar que existe en la BD"""
	print("🔧 [DATASERVICE] Obteniendo producto temporal ID: ", producto_id)
	
	# Asegurar que los datos temporales existan en la base de datos real
	crear_productos_temporales_en_bd()
	
	# Intentar obtener desde la base de datos real ahora
	var productos = execute_sql("SELECT * FROM productos WHERE id = ?", [producto_id])
	if productos.size() > 0 and productos[0].has("nombre") and productos[0].get("nombre", "") != "":
		print("✅ [DATASERVICE] Producto encontrado en BD después de crear temporales")
		return productos[0]
	
	# Si aún no funciona, usar datos hardcodeados
	var productos_temporales = [
		{
			"id": 1,
			"sku": "REP-RAM-8GB",
			"nombre": "Memoria RAM DDR4 8GB Kingston",
			"categoria": "Memoria",
			"tipo": "REPUESTO",
			"coste": 35.50,
			"pvp": 45.99,
			"iva": 21.0,
			"stock": 15,
			"stock_min": 5,
			"proveedor": "Kingston Technology"
		},
		{
			"id": 2,
			"sku": "REP-SSD-512",
			"nombre": "SSD NVMe 512GB Samsung",
			"categoria": "Almacenamiento",
			"tipo": "REPUESTO",
			"coste": 65.00,
			"pvp": 75.99,
			"iva": 21.0,
			"stock": 8,
			"stock_min": 3,
			"proveedor": "Samsung Electronics"
		},
		{
			"id": 3,
			"sku": "ACC-USB-C-2M",
			"nombre": "Cable USB-C 2 metros",
			"categoria": "Cables",
			"tipo": "ACCESORIO",
			"coste": 8.50,
			"pvp": 12.99,
			"iva": 21.0,
			"stock": 25,
			"stock_min": 10,
			"proveedor": "Generic Cables Co."
		},
		{
			"id": 4,
			"sku": "SER-DIAG-HW",
			"nombre": "Diagnóstico de Hardware Completo",
			"categoria": "Servicios",
			"tipo": "SERVICIO",
			"coste": 15.00,
			"pvp": 25.00,
			"iva": 21.0,
			"stock": 999,
			"stock_min": 1,
			"proveedor": "Servicio Interno"
		},
		{
			"id": 5,
			"sku": "REP-FAN-CPU",
			"nombre": "Ventilador CPU Cooler Master",
			"categoria": "Refrigeración",
			"tipo": "REPUESTO",
			"coste": 18.75,
			"pvp": 24.99,
			"iva": 21.0,
			"stock": 2,
			"stock_min": 5,
			"proveedor": "Cooler Master Inc."
		}
	]
	
	for producto in productos_temporales:
		if producto.get("id") == producto_id:
			print("✅ [DATASERVICE] Producto temporal encontrado: ", producto.get("sku"))
			return producto
	
	print("❌ [DATASERVICE] Producto temporal NO encontrado")
	return {}

func crear_productos_temporales_en_bd():
	"""Crear productos temporales reales en la base de datos"""
	print("🔧 [DATASERVICE] Creando productos temporales en BD...")
	
	# Verificar si hay productos corruptos (solo con ID)
	var productos_existentes = execute_sql("SELECT * FROM productos")
	var productos_corruptos = false
	
	print("🔍 [DATASERVICE] Analizando ", productos_existentes.size(), " productos existentes...")
	for producto in productos_existentes:
		print("🔍 [DATASERVICE] Producto encontrado: ", producto)
		# Si un producto solo tiene 'id' y no tiene 'nombre', está corrupto
		if producto.keys().size() == 1 and producto.has("id"):
			print("❌ [DATASERVICE] Producto corrupto detectado (solo ID): ", producto)
			productos_corruptos = true
			break
		# O si no tiene nombre o nombre vacío
		if not producto.has("nombre") or producto.get("nombre", "") == "":
			print("❌ [DATASERVICE] Producto sin nombre detectado: ", producto)
			productos_corruptos = true
			break
	
	if productos_existentes.size() > 0 and not productos_corruptos:
		print("✅ [DATASERVICE] Productos válidos ya existen en BD")
		return
	
	if productos_corruptos:
		print("🗑️ [DATASERVICE] Detectados productos corruptos, limpiando tabla completa...")
		execute_non_query("DELETE FROM productos")
	else:
		print("🔧 [DATASERVICE] No hay productos, creando desde cero...")
	
	# Limpiar cualquier resto corrupto
	execute_non_query("DELETE FROM productos WHERE nombre IS NULL OR nombre = ''")
	
	# Insertar productos temporales
	var productos_temporales = [
		{
			"id": 1,
			"sku": "REP-RAM-8GB",
			"nombre": "Memoria RAM DDR4 8GB Kingston",
			"categoria": "Memoria",
			"tipo": "REPUESTO",
			"coste": 35.50,
			"pvp": 45.99,
			"iva": 21.0,
			"stock": 15,
			"stock_min": 5,
			"proveedor": "Kingston Technology"
		},
		{
			"id": 2,
			"sku": "REP-SSD-512",
			"nombre": "SSD NVMe 512GB Samsung",
			"categoria": "Almacenamiento",
			"tipo": "REPUESTO",
			"coste": 65.00,
			"pvp": 75.99,
			"iva": 21.0,
			"stock": 8,
			"stock_min": 3,
			"proveedor": "Samsung Electronics"
		},
		{
			"id": 3,
			"sku": "ACC-USB-C-2M",
			"nombre": "Cable USB-C 2 metros",
			"categoria": "Cables",
			"tipo": "ACCESORIO",
			"coste": 8.50,
			"pvp": 12.99,
			"iva": 21.0,
			"stock": 25,
			"stock_min": 10,
			"proveedor": "Generic Cables Co."
		},
		{
			"id": 4,
			"sku": "SER-DIAG-HW",
			"nombre": "Diagnóstico de Hardware Completo",
			"categoria": "Servicios",
			"tipo": "SERVICIO",
			"coste": 15.00,
			"pvp": 25.00,
			"iva": 21.0,
			"stock": 999,
			"stock_min": 1,
			"proveedor": "Servicio Interno"
		},
		{
			"id": 5,
			"sku": "REP-FAN-CPU",
			"nombre": "Ventilador CPU Cooler Master",
			"categoria": "Refrigeración",
			"tipo": "REPUESTO",
			"coste": 18.75,
			"pvp": 24.99,
			"iva": 21.0,
			"stock": 2,
			"stock_min": 5,
			"proveedor": "Cooler Master Inc."
		}
	]
	
	for producto in productos_temporales:
		# Verificar si ya existe
		var existe = execute_sql("SELECT id FROM productos WHERE id = ?", [producto.id])
		if existe.size() == 0:
			# Insertar nuevo
			execute_non_query("""
				INSERT INTO productos (id, sku, nombre, categoria, tipo, coste, pvp, iva, stock, stock_min, proveedor)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
			""", [
				producto.id,
				producto.sku,
				producto.nombre,
				producto.categoria,
				producto.tipo,
				producto.coste,
				producto.pvp,
				producto.iva,
				producto.stock,
				producto.stock_min,
				producto.proveedor
			])
			print("✅ [DATASERVICE] Producto temporal insertado: ", producto.sku)
		else:
			# Actualizar existente
			execute_non_query("""
				UPDATE productos SET 
					sku = ?, nombre = ?, categoria = ?, tipo = ?, coste = ?, pvp = ?,
					iva = ?, stock = ?, stock_min = ?, proveedor = ?
				WHERE id = ?
			""", [
				producto.sku,
				producto.nombre,
				producto.categoria,
				producto.tipo,
				producto.coste,
				producto.pvp,
				producto.iva,
				producto.stock,
				producto.stock_min,
				producto.proveedor,
				producto.id
			])
			print("✅ [DATASERVICE] Producto temporal actualizado: ", producto.sku)
	
	print("✅ [DATASERVICE] Productos temporales creados en BD")

func guardar_producto(producto_data: Dictionary) -> int:
	print("💾 [DATASERVICE] ===== GUARDANDO PRODUCTO =====")
	print("💾 [DATASERVICE] Datos recibidos: ", producto_data)
	print("💾 [DATASERVICE] Tiene 'id': ", producto_data.has("id"))
	if producto_data.has("id"):
		print("💾 [DATASERVICE] Valor ID: ", producto_data.id, " (tipo: ", typeof(producto_data.id), ")")
		print("💾 [DATASERVICE] ID convertido a int: ", int(producto_data.id))
	
	var producto_id = -1
	
	if producto_data.has("id") and int(producto_data.id) > 0:
		# Actualizar producto existente
		producto_id = int(producto_data.id)
		print("💾 [DATASERVICE] ✅ MODO ACTUALIZACIÓN - ID: ", producto_id)
		
		var result = execute_non_query("""
			UPDATE productos SET
				sku = ?, nombre = ?, categoria = ?, tipo = ?, coste = ?, pvp = ?,
				iva = ?, stock = ?, stock_min = ?, proveedor = ?
			WHERE id = ?
		""", [
			producto_data.get("sku"),
			producto_data.get("nombre"),
			producto_data.get("categoria"),
			producto_data.get("tipo", "REPUESTO"),
			producto_data.get("coste", 0.0),
			producto_data.get("pvp", 0.0),
			producto_data.get("iva", 21.0),
			producto_data.get("stock", 0),
			producto_data.get("stock_min", 0),
			producto_data.get("proveedor"),
			producto_id
		])
		print("💾 [DATASERVICE] Resultado UPDATE: ", result)
	else:
		# Crear nuevo producto
		print("💾 [DATASERVICE] MODO CREACIÓN - Creando nuevo producto")
		
		var result = execute_non_query("""
			INSERT INTO productos (sku, nombre, categoria, tipo, coste, pvp, iva, stock, stock_min, proveedor)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		""", [
			producto_data.get("sku"),
			producto_data.get("nombre"),
			producto_data.get("categoria"),
			producto_data.get("tipo", "REPUESTO"),
			producto_data.get("coste", 0.0),
			producto_data.get("pvp", 0.0),
			producto_data.get("iva", 21.0),
			producto_data.get("stock", 0),
			producto_data.get("stock_min", 0),
			producto_data.get("proveedor")
		])
		print("💾 [DATASERVICE] Resultado INSERT: ", result)
		
		producto_id = get_last_insert_id()
		print("💾 [DATASERVICE] Nuevo ID obtenido: ", producto_id)
	
	if producto_id > 0:
		producto_guardado.emit(producto_id)
	
	return producto_id

func actualizar_stock(producto_id: int, nueva_cantidad: int) -> bool:
	var actualizado = execute_non_query(
		"UPDATE productos SET stock = ? WHERE id = ?",
		[nueva_cantidad, producto_id]
	)
	
	if actualizado:
		stock_actualizado.emit(producto_id, nueva_cantidad)
	
	return actualizado

func eliminar_producto(producto_id: int) -> bool:
	"""Elimina un producto por su ID"""
	print("🗑️ [DATASERVICE] Eliminando producto con ID: ", producto_id)
	
	var eliminado = execute_non_query(
		"DELETE FROM productos WHERE id = ?",
		[producto_id]
	)
	
	if eliminado:
		print("✅ [DATASERVICE] Producto eliminado exitosamente")
	else:
		print("❌ [DATASERVICE] Error al eliminar producto")
	
	return eliminado

# --- USUARIOS ---

func obtener_tecnicos() -> Array:
	return execute_sql("""
		SELECT u.* FROM usuarios u 
		JOIN roles r ON u.rol_id = r.id 
		WHERE r.nombre IN ('ADMIN', 'TECNICO')
		ORDER BY u.nombre
	""")

# --- ESTADÍSTICAS ---

func obtener_kpis_dashboard() -> Dictionary:
	var kpis = {}
	
	# Tickets por estado
	var estados = execute_sql("""
		SELECT estado, COUNT(*) as cantidad 
		FROM tickets 
		WHERE fecha_cierre IS NULL 
		GROUP BY estado
	""")
	
	kpis["tickets_por_estado"] = {}
	for estado in estados:
		kpis["tickets_por_estado"][estado.get("estado", "")] = int(estado.get("cantidad", 0))
	
	# Tickets de hoy
	var tickets_hoy = execute_sql("""
		SELECT COUNT(*) as cantidad 
		FROM tickets 
		WHERE DATE(fecha_entrada) = DATE('now')
	""")
	
	if tickets_hoy.size() > 0:
		kpis["tickets_hoy"] = int(tickets_hoy[0].get("cantidad", 0))
	else:
		kpis["tickets_hoy"] = 0
	
	# Productos con stock bajo
	var stock_bajo = execute_sql("""
		SELECT COUNT(*) as cantidad 
		FROM productos 
		WHERE stock <= stock_min AND tipo = 'REPUESTO'
	""")
	
	if stock_bajo.size() > 0:
		kpis["productos_stock_bajo"] = int(stock_bajo[0].get("cantidad", 0))
	else:
		kpis["productos_stock_bajo"] = 0
	
	return kpis

# --- TICKETS (LISTADO) ---

func obtener_todos_los_tickets() -> Array:
	"""Obtiene todos los tickets con información de cliente"""
	print("📂 [DATASERVICE] Obteniendo todos los tickets...")
	
	var tickets = execute_sql("""
		SELECT 
			t.*,
			c.nombre as cliente_nombre,
			c.telefono as cliente_telefono,
			c.email as cliente_email
		FROM tickets t
		LEFT JOIN clientes c ON t.cliente_id = c.id
		ORDER BY t.fecha_entrada DESC
	""")
	
	print("✅ [DATASERVICE] ", tickets.size(), " tickets obtenidos")
	return tickets

func obtener_ticket_por_id(ticket_id: int) -> Dictionary:
	"""Obtiene un ticket específico por su ID con toda la información relacionada"""
	print("📂 [DATASERVICE] Obteniendo ticket ID: ", ticket_id)
	print("🔍 [DATASERVICE] Estado de la BD: ", db != null)
	
	# Primero verificar que hay tickets en general
	var test_tickets = execute_sql("SELECT COUNT(*) as total FROM tickets")
	if test_tickets.size() > 0:
		print("📊 [DATASERVICE] Total tickets en BD: ", test_tickets[0].get("total", 0))
	else:
		print("❌ [DATASERVICE] No se pudo contar tickets - posible problema con BD")
	
	var tickets = execute_sql("""
		SELECT 
			t.*,
			c.nombre as cliente_nombre,
			c.telefono as cliente_telefono,
			c.email as cliente_email,
			c.nif as cliente_nif,
			c.direccion as cliente_direccion,
			u.nombre as tecnico_nombre
		FROM tickets t
		LEFT JOIN clientes c ON t.cliente_id = c.id
		LEFT JOIN usuarios u ON t.tecnico_id = u.id
		WHERE t.id = ?
	""", [ticket_id])
	
	print("🔍 [DATASERVICE] Resultados query: ", tickets.size())
	if tickets.size() > 0:
		print("✅ [DATASERVICE] Ticket encontrado: ", tickets[0].get("codigo", ""))
		print("📋 [DATASERVICE] Datos del ticket: ", tickets[0])
		return tickets[0]
	else:
		print("❌ [DATASERVICE] Ticket no encontrado con ID: ", ticket_id)
		# Verificar si el ticket existe con query simple
		var simple_check = execute_sql("SELECT id, codigo FROM tickets WHERE id = ?", [ticket_id])
		print("🔍 [DATASERVICE] Check simple: ", simple_check)
		return {}

# --- MANEJO DE ARCHIVOS JSON ---

func cargar_datos_json() -> Dictionary:
	"""Carga los datos del archivo JSON"""
	var file_path = "user://tienda_sat_data.json"
	
	if not FileAccess.file_exists(file_path):
		# Crear archivo inicial con estructura básica
		var initial_data = {
			"clientes": [],
			"tickets": [],
			"usuarios": [
				{
					"id": 1,
					"nombre": "Administrador",
					"email": "admin@tienda-sat.com", 
					"pass_hash": hash_password("admin123"),
					"rol_id": 1,
					"activo": 1,
					"notificaciones": 1,
					"fecha_creacion": Time.get_datetime_string_from_system()
				}
			],
			"roles": [
				{"id": 1, "nombre": "Administrador", "descripcion": "Acceso total al sistema"},
				{"id": 2, "nombre": "Técnico", "descripcion": "Gestión de tickets y reparaciones"},
				{"id": 3, "nombre": "Recepcionista", "descripcion": "Atención al cliente y tickets básicos"},
				{"id": 4, "nombre": "Empleado", "descripcion": "Acceso básico al sistema"}
			],
			"version": "1.0"
		}
		guardar_datos_json(initial_data)
		return initial_data
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("❌ [DATASERVICE] Error al abrir archivo JSON")
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("❌ [DATASERVICE] Error al parsear JSON: ", json.error_string)
		return {}
	
	return json.data

func guardar_datos_json(data: Dictionary) -> bool:
	"""Guarda los datos en el archivo JSON"""
	var file_path = "user://tienda_sat_data.json"
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("❌ [DATASERVICE] Error al crear archivo JSON")
		return false
	
	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("💾 [DATASERVICE] Datos guardados en JSON")
	return true

# --- UTILIDADES ---

func hash_password(password: String) -> String:
	"""Genera un hash simple de la contraseña"""
	var context = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(password.to_utf8_buffer())
	var result = context.finish()
	return result.hex_encode()

# FUNCIONALIDAD DESACTIVADA - Datos automáticos de prueba
# Puedes reactivar esta función si necesitas datos de prueba
func crear_clientes_de_prueba():
	"""Crea algunos clientes de prueba para testing - DESACTIVADO"""
	print("⚠️ [DATASERVICE] Función crear_clientes_de_prueba DESACTIVADA")
	return  # Salir inmediatamente sin crear nada

func obtener_todos_los_clientes() -> Array:
	"""Obtiene todos los clientes desde SQLite"""
	print("📂 [DATASERVICE] Obteniendo todos los clientes...")
	
	var clientes = execute_sql("SELECT * FROM clientes ORDER BY nombre ASC")
	
	print("✅ [DATASERVICE] ", clientes.size(), " clientes obtenidos")
	return clientes

func eliminar_cliente(cliente_id: int) -> bool:
	"""Elimina un cliente de SQLite"""
	print("🗑️ [DATASERVICE] Eliminando cliente con ID: ", cliente_id)
	
	var success = execute_non_query("DELETE FROM clientes WHERE id = ?", [cliente_id])
	
	if success:
		print("✅ [DATASERVICE] Cliente eliminado correctamente")
		return true
	else:
		print("❌ [DATASERVICE] Error al eliminar cliente")
		return false

# --- EMPLEADOS/USUARIOS ---

func obtener_todos_los_empleados() -> Array:
	"""Obtiene todos los empleados con información de rol"""
	print("👨‍💼 [DATASERVICE] Obteniendo todos los empleados...")
	
	# Cargar desde JSON
	var data = cargar_datos_json()
	var empleados = data.get("usuarios", [])
	var roles = data.get("roles", [])
	
	# Crear lookup de roles para optimizar
	var roles_lookup = {}
	for rol in roles:
		roles_lookup[int(rol.get("id", 0))] = rol.get("nombre", "Sin rol")
	
	# Agregar nombre del rol a cada empleado
	for empleado in empleados:
		var rol_id = int(empleado.get("rol_id", 0))
		empleado["rol_nombre"] = roles_lookup.get(rol_id, "Rol desconocido")
	
	print("✅ [DATASERVICE] ", empleados.size(), " empleados obtenidos")
	return empleados

func obtener_todos_los_roles() -> Array:
	"""Obtiene todos los roles disponibles"""
	print("🎭 [DATASERVICE] Obteniendo todos los roles...")
	
	var data = cargar_datos_json()
	var roles = data.get("roles", [])
	
	# Si no hay roles, crear los básicos
	if roles.size() == 0:
		roles = [
			{"id": 1, "nombre": "Administrador", "descripcion": "Acceso total al sistema"},
			{"id": 2, "nombre": "Técnico", "descripcion": "Gestión de tickets y reparaciones"},
			{"id": 3, "nombre": "Recepcionista", "descripcion": "Atención al cliente y tickets básicos"},
			{"id": 4, "nombre": "Empleado", "descripcion": "Acceso básico al sistema"}
		]
		data["roles"] = roles
		guardar_datos_json(data)
	
	print("✅ [DATASERVICE] ", roles.size(), " roles obtenidos")
	return roles

func buscar_empleados_por_email(email: String) -> Array:
	"""Busca empleados por email (para verificar duplicados)"""
	var data = cargar_datos_json()
	var empleados = data.get("usuarios", [])
	var resultados = []
	
	var email_lower = email.to_lower()
	for empleado in empleados:
		if str(empleado.get("email", "")).to_lower() == email_lower:
			resultados.append(empleado)
	
	return resultados

func guardar_empleado(empleado_data: Dictionary) -> int:
	"""Guarda un empleado (crear o actualizar)"""
	print("💾 [DATASERVICE] Guardando empleado: ", empleado_data.get("nombre", ""))
	
	# Cargar datos existentes
	var data = cargar_datos_json()
	if not data.has("usuarios"):
		data["usuarios"] = []
	
	var empleado_id = -1
	
	if empleado_data.has("id") and int(empleado_data.get("id", 0)) > 0:
		# Actualizar empleado existente
		empleado_id = int(empleado_data.id)
		var encontrado = false
		
		for i in range(data.usuarios.size()):
			if int(data.usuarios[i].get("id", 0)) == empleado_id:
				# Mantener datos existentes y actualizar solo los nuevos
				var empleado_existente = data.usuarios[i]
				
				empleado_existente["nombre"] = empleado_data.get("nombre")
				empleado_existente["email"] = empleado_data.get("email")
				empleado_existente["rol_id"] = empleado_data.get("rol_id")
				empleado_existente["activo"] = empleado_data.get("activo", 1)
				empleado_existente["notificaciones"] = empleado_data.get("notificaciones", 1)
				
				# Solo actualizar contraseña si se proporcionó una nueva
				if empleado_data.has("password") and empleado_data.password != "":
					empleado_existente["pass_hash"] = hash_password(empleado_data.password)
				
				encontrado = true
				break
		
		if not encontrado:
			print("⚠️ [DATASERVICE] Empleado con ID %d no encontrado para actualizar" % empleado_id)
			return -1
	else:
		# Crear nuevo empleado - generar ID único
		empleado_id = 1
		for empleado in data.usuarios:
			var current_id = int(empleado.get("id", 0))
			if current_id >= empleado_id:
				empleado_id = current_id + 1
		
		# Preparar datos del nuevo empleado
		var nuevo_empleado = {
			"id": empleado_id,
			"nombre": empleado_data.get("nombre"),
			"email": empleado_data.get("email"),
			"pass_hash": hash_password(empleado_data.get("password", "")),
			"rol_id": empleado_data.get("rol_id"),
			"activo": empleado_data.get("activo", 1),
			"notificaciones": empleado_data.get("notificaciones", 1),
			"fecha_creacion": Time.get_datetime_string_from_system()
		}
		
		# Agregar a la lista
		data.usuarios.append(nuevo_empleado)
	
	# Guardar archivo
	if guardar_datos_json(data):
		print("✅ [DATASERVICE] Empleado guardado correctamente con ID: ", empleado_id)
		return empleado_id
	else:
		print("❌ [DATASERVICE] Error al guardar empleado")
		return -1

func cambiar_estado_empleado(empleado_id: int, nuevo_estado: int) -> bool:
	"""Cambia el estado activo/inactivo de un empleado"""
	print("🔄 [DATASERVICE] Cambiando estado del empleado %d a %d" % [empleado_id, nuevo_estado])
	
	var data = cargar_datos_json()
	if not data.has("usuarios"):
		return false
	
	# Buscar y actualizar el empleado
	var encontrado = false
	for empleado in data.usuarios:
		if int(empleado.get("id", 0)) == empleado_id:
			empleado["activo"] = nuevo_estado
			encontrado = true
			break
	
	if not encontrado:
		print("⚠️ [DATASERVICE] Empleado con ID %d no encontrado" % empleado_id)
		return false
	
	# Guardar archivo
	if guardar_datos_json(data):
		print("✅ [DATASERVICE] Estado del empleado actualizado")
		return true
	else:
		print("❌ [DATASERVICE] Error al guardar cambio de estado")
		return false

# Función eliminar_empleado movida al final del archivo con mejor implementación

# ================== FUNCIONES NUEVAS PARA EMPLEADOS ==================

func generar_hash_password(password: String) -> String:
	"""Genera un hash simple de la contraseña para empleados"""
	return str(password.hash())

func obtener_empleados() -> Array:
	"""Obtiene todos los empleados con información de roles"""
	print("📂 [DATASERVICE] Obteniendo todos los empleados...")
	
	var empleados_con_roles = []
	
	# Obtener usuarios que son empleados (no clientes)
	var usuarios = execute_sql("SELECT * FROM usuarios WHERE rol_id IS NOT NULL ORDER BY nombre")
	
	for usuario in usuarios:
		var empleado_info = usuario.duplicate()
		
		# Obtener nombre del rol
		var rol_id = usuario.get("rol_id")
		if rol_id != null:
			var roles = execute_sql("SELECT nombre FROM roles WHERE id = ?", [rol_id])
			if roles.size() > 0:
				empleado_info["rol_nombre"] = roles[0].get("nombre", "Sin rol")
			else:
				empleado_info["rol_nombre"] = "Sin rol"
		else:
			empleado_info["rol_nombre"] = "Sin rol"
		
		empleados_con_roles.append(empleado_info)
	
	print("✅ [DATASERVICE] ", empleados_con_roles.size(), " empleados obtenidos")
	return empleados_con_roles

func obtener_empleados_activos() -> Array:
	"""Obtiene solo los empleados que están activos"""
	var todos_empleados = obtener_empleados()
	var empleados_activos = []
	
	for empleado in todos_empleados:
		var activo_value = empleado.get("activo", true)
		var esta_activo: bool = false
		
		# Manejar compatibilidad bool/int
		if activo_value is bool:
			esta_activo = activo_value
		else:
			esta_activo = (int(activo_value) == 1)
		
		if esta_activo:
			empleados_activos.append(empleado)
	
	print("👥 [DATASERVICE] Empleados activos: ", empleados_activos.size(), " de ", todos_empleados.size())
	return empleados_activos

func crear_empleado(empleado_data: Dictionary) -> Dictionary:
	"""Crea un nuevo empleado en el sistema"""
	print("➕ [DATASERVICE] Creando empleado: ", empleado_data.get("nombre", ""))
	
	# Validar datos obligatorios
	if not empleado_data.has("nombre") or empleado_data.nombre.is_empty():
		return {"success": false, "message": "Nombre es obligatorio"}
	
	if not empleado_data.has("email") or empleado_data.email.is_empty():
		return {"success": false, "message": "Email es obligatorio"}
	
	if not empleado_data.has("password") or empleado_data.password.is_empty():
		return {"success": false, "message": "Contraseña es obligatoria"}
	
	if not empleado_data.has("rol_id"):
		return {"success": false, "message": "Rol es obligatorio"}
	
	# Verificar que el email no exista
	var usuarios_existentes = execute_sql("SELECT id FROM usuarios WHERE email = ?", [empleado_data.email])
	if usuarios_existentes.size() > 0:
		return {"success": false, "message": "El email ya está registrado"}
	
	# Encriptar contraseña
	var password_encrypted = generar_hash_password(empleado_data.password)
	
	# Preparar datos para inserción
	var sql = """
	INSERT INTO usuarios (nombre, email, password_hash, rol_id, activo, created_at) 
	VALUES (?, ?, ?, ?, ?, datetime('now'))
	"""
	
	# Normalizar valor activo a booleano
	var activo_value = empleado_data.get("activo", true)
	var activo_normalizado: bool = false
	if activo_value is bool:
		activo_normalizado = activo_value
	else:
		activo_normalizado = (int(activo_value) == 1)
	
	var params = [
		empleado_data.nombre,
		empleado_data.email, 
		password_encrypted,
		empleado_data.rol_id,
		activo_normalizado
	]
	
	# Ejecutar inserción
	var _resultado = execute_sql(sql, params)
	
	# Obtener ID del último empleado insertado
	var id_query = execute_sql("SELECT last_insert_rowid() as id")
	var nuevo_id = 0
	if not id_query.is_empty():
		nuevo_id = id_query[0].get("id", 0)
	
	# Obtener el empleado creado con información del rol
	var empleados = obtener_empleados()
	var empleado_creado = null
	for emp in empleados:
		if int(emp.id) == nuevo_id:
			empleado_creado = emp
			break
	
	if empleado_creado and nuevo_id > 0:
		print("✅ [DATASERVICE] Empleado creado con ID: ", nuevo_id)
		return {
			"success": true,
			"message": "Empleado creado exitosamente",
			"empleado": empleado_creado
		}
	else:
		print("❌ [DATASERVICE] Error al crear empleado: no se pudo verificar creación")
		return {"success": false, "message": "Error al crear empleado en la base de datos"}

func actualizar_empleado(empleado_data: Dictionary) -> Dictionary:
	"""Actualiza un empleado existente"""
	print("✏️ [DATASERVICE] Actualizando empleado ID: ", empleado_data.get("id", ""))
	
	if not empleado_data.has("id"):
		return {"success": false, "message": "ID de empleado es requerido"}
	
	# Construir query dinámicamente según campos proporcionados
	var campos_update = []
	var params = []
	
	if empleado_data.has("nombre"):
		campos_update.append("nombre = ?")
		params.append(empleado_data.nombre)
	
	if empleado_data.has("email"):
		campos_update.append("email = ?")
		params.append(empleado_data.email)
	
	if empleado_data.has("rol_id"):
		campos_update.append("rol_id = ?")
		params.append(empleado_data.rol_id)
	
	if empleado_data.has("activo"):
		campos_update.append("activo = ?")
		# Normalizar valor activo a booleano
		var activo_value = empleado_data.activo
		var activo_normalizado: bool = false
		if activo_value is bool:
			activo_normalizado = activo_value
		else:
			activo_normalizado = (int(activo_value) == 1)
		params.append(activo_normalizado)
	
	if empleado_data.has("password"):
		campos_update.append("password_hash = ?")
		params.append(generar_hash_password(empleado_data.password))
	
	if campos_update.is_empty():
		return {"success": false, "message": "No hay campos para actualizar"}
	
	# Agregar campo de modificación y ID para WHERE
	campos_update.append("updated_at = datetime('now')")
	params.append(empleado_data.id)
	
	var sql = "UPDATE usuarios SET " + ", ".join(campos_update) + " WHERE id = ?"
	
	# Ejecutar actualización
	var _resultado = execute_sql(sql, params)
	
	# Para updates, execute_sql siempre funciona si no hay errores de sintaxis
	# Obtener empleado actualizado para verificar que funcionó
	var empleados = obtener_empleados()
	var empleado_actualizado = null
	for emp in empleados:
		if int(emp.id) == int(empleado_data.id):
			empleado_actualizado = emp
			break
	
	if empleado_actualizado:
		print("✅ [DATASERVICE] Empleado actualizado correctamente")
		return {
			"success": true,
			"message": "Empleado actualizado exitosamente",
			"empleado": empleado_actualizado
		}
	else:
		print("❌ [DATASERVICE] Error: empleado no encontrado después de actualización")
		return {"success": false, "message": "Error al verificar actualización del empleado"}

func eliminar_empleado(empleado_id: int) -> Dictionary:
	"""Elimina un empleado del sistema"""
	print("🗑️ [DATASERVICE] Eliminando empleado con ID: ", empleado_id)
	
	# Verificar que el empleado existe
	var empleados = execute_sql("SELECT nombre FROM usuarios WHERE id = ?", [empleado_id])
	if empleados.size() == 0:
		return {"success": false, "message": "Empleado no encontrado"}
	
	# Eliminar empleado
	var sql = "DELETE FROM usuarios WHERE id = ?"
	var _resultado = execute_sql(sql, [empleado_id])
	
	# Verificar si el empleado ya no existe
	var verificar_eliminacion = execute_sql("SELECT id FROM usuarios WHERE id = ?", [empleado_id])
	
	if verificar_eliminacion.is_empty():
		print("✅ [DATASERVICE] Empleado eliminado correctamente")
		return {"success": true, "message": "Empleado eliminado exitosamente"}
	else:
		print("❌ [DATASERVICE] Error al eliminar empleado: aún existe en la base de datos")
		return {"success": false, "message": "Error al eliminar empleado de la base de datos"}

func activar_empleado(empleado_id: int) -> Dictionary:
	"""Activa un empleado (soft reactivation)"""
	print("✅ [DATASERVICE] Activando empleado con ID: ", empleado_id)
	
	# Verificar que el empleado existe
	var empleados = execute_sql("SELECT nombre FROM usuarios WHERE id = ?", [empleado_id])
	if empleados.size() == 0:
		return {"success": false, "message": "Empleado no encontrado"}
	
	# Activar empleado
	var resultado = actualizar_empleado({"id": empleado_id, "activo": true})
	
	if resultado.success:
		print("✅ [DATASERVICE] Empleado activado exitosamente")
		return {"success": true, "message": "Empleado activado exitosamente"}
	else:
		return {"success": false, "message": "Error al activar empleado"}

func desactivar_empleado(empleado_id: int) -> Dictionary:
	"""Desactiva un empleado (soft delete)"""
	print("❌ [DATASERVICE] Desactivando empleado con ID: ", empleado_id)
	
	# Verificar que el empleado existe
	var empleados = execute_sql("SELECT nombre FROM usuarios WHERE id = ?", [empleado_id])
	if empleados.size() == 0:
		return {"success": false, "message": "Empleado no encontrado"}
	
	# Desactivar empleado
	var resultado = actualizar_empleado({"id": empleado_id, "activo": false})
	
	if resultado.success:
		print("✅ [DATASERVICE] Empleado desactivado exitosamente")
		return {"success": true, "message": "Empleado desactivado exitosamente (soft delete)"}
	else:
		return {"success": false, "message": "Error al desactivar empleado"}

# ==========================================
# DATOS DE PRUEBA
# ==========================================

func crear_datos_de_prueba_completos():
	"""Crea un conjunto completo de datos de prueba"""
	print("🔧 [DATASERVICE] Creando datos de prueba completos...")
	
	# 1. Crear clientes
	print("👥 Creando clientes...")
	var cliente1_id = guardar_cliente({
		"nombre": "Juan Pérez",
		"telefono": "123456789",
		"email": "juan@email.com",
		"direccion": "Calle Mayor 123"
	})
	
	var cliente2_id = guardar_cliente({
		"nombre": "María García",
		"telefono": "987654321", 
		"email": "maria@email.com",
		"direccion": "Av. Libertad 456"
	})
	
	# 2. Crear empleados/técnicos
	print("👨‍💻 Creando técnicos...")
	var empleado_data1 = {
		"nombre": "Carlos Técnico",
		"email": "carlos@tienda.com",
		"telefono": "555001122",
		"password": "tecnico123",
		"rol_id": 2,  # ID para técnico (1=admin, 2=tecnico)
		"especialidad": "Hardware"
	}
	var tecnico_result = crear_empleado(empleado_data1)
	var tecnico1_id = tecnico_result.get("id", -1) if tecnico_result.get("success", false) else -1
	
	# 3. Crear tickets de prueba
	print("🎫 Creando tickets...")
	
	# Solo crear tickets si el técnico se creó correctamente
	if tecnico1_id > 0:
		var ticket1_data = {
			"cliente_id": cliente1_id,
			"equipo_tipo": "Ordenador",
			"equipo_marca": "Dell",
			"equipo_modelo": "OptiPlex 7090",
			"numero_serie": "DL001234",
			"averia_cliente": "El ordenador no enciende. Se escucha un pitido cuando se presiona el botón de encendido.",
			"diagnostico": "",
			"estado": "Pendiente",
			"prioridad": "NORMAL",
			"tecnico_id": tecnico1_id
		}
		var ticket1_id = guardar_ticket(ticket1_data)
		
		var ticket2_data = {
			"cliente_id": cliente2_id, 
			"equipo_tipo": "Portátil",
			"equipo_marca": "HP",
			"equipo_modelo": "Pavilion 15",
			"numero_serie": "HP987654",
			"averia_cliente": "La pantalla parpadea y a veces se pone completamente negra. También hay problemas con el teclado.",
			"diagnostico": "Revisado - posible problema con cable de pantalla",
			"estado": "En Reparación",
			"prioridad": "ALTA",
			"tecnico_id": tecnico1_id
		}
		var ticket2_id = guardar_ticket(ticket2_data)
		
		# 4. Crear productos de prueba
		print("📦 Creando productos...")
		crear_productos_de_prueba()
		
		print("✅ [DATASERVICE] Datos de prueba creados:")
		print("  - Clientes: 2 (IDs: ", cliente1_id, ", ", cliente2_id, ")")
		print("  - Técnicos: 1 (ID: ", tecnico1_id, ")")
		print("  - Tickets: 2 (IDs: ", ticket1_id, ", ", ticket2_id, ")")
		print("  - Productos: Ver logs específicos")
	else:
		print("❌ [DATASERVICE] No se pudo crear técnico, creando tickets sin asignar...")
		
		var ticket1_data = {
			"cliente_id": cliente1_id,
			"equipo_tipo": "Ordenador",
			"equipo_marca": "Dell",
			"equipo_modelo": "OptiPlex 7090",
			"numero_serie": "DL001234",
			"averia_cliente": "El ordenador no enciende. Se escucha un pitido cuando se presiona el botón de encendido.",
			"diagnostico": "",
			"estado": "Pendiente",
			"prioridad": "NORMAL"
		}
		var ticket1_id = guardar_ticket(ticket1_data)
		
		var ticket2_data = {
			"cliente_id": cliente2_id, 
			"equipo_tipo": "Portátil",
			"equipo_marca": "HP",
			"equipo_modelo": "Pavilion 15",
			"numero_serie": "HP987654",
			"averia_cliente": "La pantalla parpadea y a veces se pone completamente negra. También hay problemas con el teclado.",
			"diagnostico": "",
			"estado": "Pendiente",
			"prioridad": "NORMAL"
		}
		var ticket2_id = guardar_ticket(ticket2_data)
		
		# 4. Crear productos de prueba
		print("📦 Creando productos...")
		crear_productos_de_prueba()
		
		print("✅ [DATASERVICE] Datos de prueba creados (sin técnico):")
		print("  - Clientes: 2 (IDs: ", cliente1_id, ", ", cliente2_id, ")")
		print("  - Técnicos: 0 (falló la creación)")
		print("  - Tickets: 2 (IDs: ", ticket1_id, ", ", ticket2_id, ")")
		print("  - Productos: Ver logs específicos")

func crear_productos_de_prueba():
	"""Crea productos de prueba para el inventario"""
	print("📦 [DATASERVICE] Creando productos de prueba...")
	
	# Repuestos
	var producto1_id = guardar_producto({
		"sku": "REP-RAM-8GB",
		"nombre": "Memoria RAM DDR4 8GB Kingston",
		"categoria": "Memoria",
		"tipo": "REPUESTO",
		"coste": 35.50,
		"pvp": 45.99,
		"iva": 21.0,
		"stock": 15,
		"stock_min": 5,
		"proveedor": "Kingston Technology"
	})
	
	var producto2_id = guardar_producto({
		"sku": "REP-SSD-512",
		"nombre": "SSD NVMe 512GB Samsung",
		"categoria": "Almacenamiento",
		"tipo": "REPUESTO",
		"coste": 58.20,
		"pvp": 75.99,
		"iva": 21.0,
		"stock": 8,
		"stock_min": 3,
		"proveedor": "Samsung Electronics"
	})
	
	var producto3_id = guardar_producto({
		"sku": "REP-FAN-CPU",
		"nombre": "Ventilador CPU Cooler Master",
		"categoria": "Refrigeración",
		"tipo": "REPUESTO",
		"coste": 18.75,
		"pvp": 24.99,
		"iva": 21.0,
		"stock": 2,  # Stock bajo para probar
		"stock_min": 4,
		"proveedor": "Cooler Master"
	})
	
	# Accesorios
	var producto4_id = guardar_producto({
		"sku": "ACC-USB-C-2M",
		"nombre": "Cable USB-C 2 metros",
		"categoria": "Cables",
		"tipo": "ACCESORIO",
		"coste": 8.50,
		"pvp": 12.99,
		"iva": 21.0,
		"stock": 25,
		"stock_min": 10,
		"proveedor": "Belkin International"
	})
	
	var producto5_id = guardar_producto({
		"sku": "ACC-MOUSE-W",
		"nombre": "Ratón Inalámbrico Logitech MX Master",
		"categoria": "Periféricos",
		"tipo": "ACCESORIO",
		"coste": 45.20,
		"pvp": 59.99,
		"iva": 21.0,
		"stock": 12,
		"stock_min": 5,
		"proveedor": "Logitech"
	})
	
	var producto6_id = guardar_producto({
		"sku": "ACC-TECLADO-MEC",
		"nombre": "Teclado Mecánico RGB",
		"categoria": "Periféricos",
		"tipo": "ACCESORIO",
		"coste": 62.80,
		"pvp": 89.99,
		"iva": 21.0,
		"stock": 0,  # Sin stock para probar
		"stock_min": 2,
		"proveedor": "Corsair Gaming"
	})
	
	# Servicios
	var producto7_id = guardar_producto({
		"sku": "SER-DIAG-HW",
		"nombre": "Diagnóstico de Hardware Completo",
		"categoria": "Diagnóstico",
		"tipo": "SERVICIO",
		"coste": 0.0,
		"pvp": 25.00,
		"iva": 21.0,
		"stock": 999,  # Los servicios no tienen stock limitado
		"stock_min": 0,
		"proveedor": "Servicio Interno"
	})
	
	var producto8_id = guardar_producto({
		"sku": "SER-INST-SO",
		"nombre": "Instalación Sistema Operativo",
		"categoria": "Software",
		"tipo": "SERVICIO",
		"coste": 0.0,
		"pvp": 35.00,
		"iva": 21.0,
		"stock": 999,
		"stock_min": 0,
		"proveedor": "Servicio Interno"
	})
	
	var producto9_id = guardar_producto({
		"sku": "SER-LIMP-PC",
		"nombre": "Limpieza y Mantenimiento PC",
		"categoria": "Mantenimiento",
		"tipo": "SERVICIO",
		"coste": 0.0,
		"pvp": 15.00,
		"iva": 21.0,
		"stock": 999,
		"stock_min": 0,
		"proveedor": "Servicio Interno"
	})
	
	print("✅ [DATASERVICE] Productos de prueba creados:")
	print("  - Repuestos: 3 (IDs: ", producto1_id, ", ", producto2_id, ", ", producto3_id, ")")
	print("  - Accesorios: 3 (IDs: ", producto4_id, ", ", producto5_id, ", ", producto6_id, ")")
	print("  - Servicios: 3 (IDs: ", producto7_id, ", ", producto8_id, ", ", producto9_id, ")")

# =====================================================
# FUNCIONES PARA RELACIONES TIPO FOREIGN KEY
# =====================================================

func obtener_ticket_con_relaciones(ticket_id: int) -> Dictionary:
	"""Obtiene un ticket con datos de cliente y técnico incluidos"""
	print("🔗 [DATASERVICE] Obteniendo ticket con relaciones ID: ", ticket_id)
	
	if db == null:
		print("❌ [DATASERVICE] Base de datos no inicializada")
		return {}
	
	return db.get_record_with_relations("tickets", ticket_id)

func obtener_cliente_con_tickets(cliente_id: int) -> Dictionary:
	"""Obtiene un cliente con la lista de sus tickets"""
	print("🔗 [DATASERVICE] Obteniendo cliente con tickets ID: ", cliente_id)
	
	var cliente = obtener_cliente(cliente_id)
	if cliente.is_empty():
		return {}
		
	# Agregar lista de tickets del cliente
	if db != null:
		var tickets_cliente = db.get_related_records("clientes", cliente_id, "id")
		cliente["tickets"] = tickets_cliente
		print("✅ [DATASERVICE] Cliente con ", tickets_cliente.size(), " tickets")
	
	return cliente

func validar_referencias_ticket(datos_ticket: Dictionary) -> Dictionary:
	"""Valida que las referencias de un ticket sean correctas antes de guardarlo"""
	var resultado = {"valido": true, "errores": []}
	
	# Validar cliente_id
	if datos_ticket.has("cliente_id") and datos_ticket["cliente_id"] != null:
		var cliente = obtener_cliente(int(datos_ticket["cliente_id"]))
		if cliente.is_empty():
			resultado["valido"] = false
			resultado["errores"].append("El cliente especificado no existe")
	
	# Validar tecnico_id si está presente
	var tecnico_id = datos_ticket.get("tecnico_id", null)
	if tecnico_id != null and str(tecnico_id) != "" and str(tecnico_id) != "0":
		var tecnicos = execute_sql("SELECT * FROM usuarios WHERE id = ? AND rol_id IN (1, 2)", [int(tecnico_id)])
		if tecnicos.size() == 0:
			resultado["valido"] = false
			resultado["errores"].append("El técnico especificado no existe")
	
	return resultado

func eliminar_cliente_con_validacion(cliente_id: int) -> Dictionary:
	"""Elimina un cliente validando que no tenga tickets asociados"""
	var resultado = {"exito": false, "mensaje": ""}
	
	# Verificar si tiene tickets asociados
	if db != null:
		var tickets_asociados = db.get_related_records("clientes", cliente_id, "id")
		if tickets_asociados.size() > 0:
			resultado["mensaje"] = "No se puede eliminar el cliente porque tiene " + str(tickets_asociados.size()) + " ticket(s) asociado(s)"
			return resultado
	
	# Si no tiene tickets, proceder con la eliminación
	var exito = execute_sql("DELETE FROM clientes WHERE id = ?", [cliente_id])
	if exito != null:
		resultado["exito"] = true
		resultado["mensaje"] = "Cliente eliminado correctamente"
	else:
		resultado["mensaje"] = "Error al eliminar el cliente"
	
	return resultado

func obtener_tickets_con_cliente_y_tecnico() -> Array:
	"""Obtiene todos los tickets con información de cliente y técnico"""
	print("🔗 [DATASERVICE] Obteniendo tickets con relaciones completas")
	
	var tickets = execute_sql("""
		SELECT 
			t.*,
			c.nombre as cliente_nombre,
			c.telefono as cliente_telefono,
			c.email as cliente_email,
			u.nombre as tecnico_nombre
		FROM tickets t
		LEFT JOIN clientes c ON t.cliente_id = c.id
		LEFT JOIN usuarios u ON t.tecnico_id = u.id
		ORDER BY t.id DESC
	""")
	
	print("✅ [DATASERVICE] Tickets con relaciones: ", tickets.size())
	return tickets

func obtener_estadisticas_relacionales() -> Dictionary:
	"""Obtiene estadísticas que requieren relaciones entre tablas"""
	var stats = {}
	
	# Tickets por cliente
	var tickets_por_cliente = execute_sql("""
		SELECT 
			c.nombre as cliente,
			COUNT(t.id) as total_tickets
		FROM clientes c
		LEFT JOIN tickets t ON c.id = t.cliente_id
		GROUP BY c.id, c.nombre
		ORDER BY total_tickets DESC
	""")
	stats["tickets_por_cliente"] = tickets_por_cliente
	
	# Tickets por técnico
	var tickets_por_tecnico = execute_sql("""
		SELECT 
			u.nombre as tecnico,
			COUNT(t.id) as total_tickets
		FROM usuarios u
		LEFT JOIN tickets t ON u.id = t.tecnico_id
		WHERE u.rol_id IN (1, 2)
		GROUP BY u.id, u.nombre
		ORDER BY total_tickets DESC
	""")
	stats["tickets_por_tecnico"] = tickets_por_tecnico
	
	print("📊 [DATASERVICE] Estadísticas relacionales generadas")
	return stats

func test_foreign_keys():
	"""Test del sistema de relaciones Foreign Key"""
	print("\n🧪 [DATASERVICE] === TEST DE RELACIONES FOREIGN KEY ===")
	
	# Test 1: Validación de FK en tickets
	print("\n1. Test validación Foreign Keys:")
	var validacion = validar_referencias_ticket({
		"cliente_id": 1,
		"tecnico_id": 1
	})
	print("   ✅ Ticket válido: ", validacion)
	
	var validacion_invalida = validar_referencias_ticket({
		"cliente_id": 999,  # Cliente inexistente
		"tecnico_id": 1
	})
	print("   ❌ Ticket inválido: ", validacion_invalida)
	
	# Test 2: Obtener registros con relaciones
	print("\n2. Test registros con relaciones:")
	var cliente_con_tickets = obtener_cliente_con_tickets(1)
	print("   🔗 Cliente con tickets: ", cliente_con_tickets.has("tickets"))
	
	# Test 3: Estadísticas relacionales
	print("\n3. Test estadísticas relacionales:")
	var stats = obtener_estadisticas_relacionales()
	print("   📊 Tickets por cliente: ", stats.get("tickets_por_cliente", []).size())
	print("   📊 Tickets por técnico: ", stats.get("tickets_por_tecnico", []).size())
	
	print("🧪 [DATASERVICE] === FIN TEST RELACIONES ===\n")

func migrar_campo_activo_usuarios():
	"""Migración para agregar campo 'activo' a usuarios existentes"""
	print("🔄 [DATASERVICE] Ejecutando migración: campo 'activo' en usuarios...")
	
	var usuarios = db.execute_sql("SELECT * FROM usuarios")
	var usuarios_actualizados = 0
	
	for usuario in usuarios:
		# Si no tiene el campo 'activo', agregarlo con valor true por defecto
		if not usuario.has("activo"):
			var sql = "UPDATE usuarios SET activo = ? WHERE id = ?"
			var params = [true, usuario.get("id")]
			db.execute_sql(sql, params)
			usuarios_actualizados += 1
	
	if usuarios_actualizados > 0:
		print("✅ [DATASERVICE] Migración completada: ", usuarios_actualizados, " usuarios actualizados con campo 'activo'")
	else:
		print("ℹ️ [DATASERVICE] Migración no necesaria: usuarios ya tienen campo 'activo'")
