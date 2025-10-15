extends RefCounted
class_name Database

# Clase para manejar la conexión y operaciones con SQLite
# Utiliza una implementación simple basada en archivos para Godot

var db_path: String
var tables: Dictionary = {}
var data: Dictionary = {}
var last_insert_id: int = 0  # ✅ Almacena el último ID insertado

func _init(database_path: String = "user://tienda_sat.db"):
	db_path = database_path
	load_database()

func load_database():
	# Cargar datos existentes si el archivo existe
	var file = FileAccess.open(db_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		if json_string.length() > 0:
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				data = json.data
		else:
			data = {}
	else:
		data = {}
	
	# Asegurar que los datos básicos existan siempre
	initialize_default_data()
	save_database()

func save_database():
	var file = FileAccess.open(db_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data)
		file.store_string(json_string)
		file.close()
		return true
	return false

func execute_sql(query: String, params: Array = []) -> Array:
	# Parseamos consultas SQL básicas manualmente
	var clean_query = query.strip_edges().to_upper()
	
	if clean_query.begins_with("SELECT"):
		return handle_select(query, params)
	elif clean_query.begins_with("INSERT"):
		handle_insert(query, params)
		return []
	elif clean_query.begins_with("UPDATE"):
		handle_update(query, params)
		return []
	elif clean_query.begins_with("DELETE"):
		handle_delete(query, params)
		return []
	elif clean_query.begins_with("CREATE TABLE"):
		handle_create_table(query, params)
		return []
	else:
		print("Tipo de query no soportado: ", query)
		return []

func execute_non_query(query: String, params: Array = []) -> bool:
	var result = execute_sql(query, params)
	# Verificar si fue un INSERT exitoso buscando un indicador específico
	var clean_query = query.strip_edges().to_upper()
	if clean_query.begins_with("INSERT"):
		# Para INSERT, verificar si el último ID cambió (indicando éxito)
		return insert_success
	return true

# Variable para tracking del éxito de INSERT
var insert_success: bool = false

func handle_select(query: String, _params: Array) -> Array:
	# Implementación mejorada de SELECT con soporte básico para JOINs
	var result = []
	var query_upper = query.to_upper()
	
	print("🔍 [DATABASE] Ejecutando SELECT: ", query)
	print("🔍 [DATABASE] Parámetros: ", _params)
	
	# Detectar consultas específicas comunes
	if query_upper.find("COUNT(*)") != -1:
		# Consulta COUNT
		var count_from_pos = query_upper.find("FROM")
		if count_from_pos != -1:
			var count_table_part = query.substr(count_from_pos + 4).strip_edges()
			var count_table_name = count_table_part.split(" ")[0].to_lower()
			
			if data.has(count_table_name):
				var count = data[count_table_name].size()
				result.append({"total": count})
				print("✅ [DATABASE] COUNT resultado: ", count)
				return result
		return [{"total": 0}]
	
	# Detectar consultas con JOIN (ticket con cliente/empleado)
	if query_upper.find("LEFT JOIN") != -1 and query_upper.find("FROM TICKETS") != -1:
		print("🔗 [DATABASE] Detectada consulta JOIN con tickets - derivando a handle_ticket_join_query")
		return handle_ticket_join_query(query, _params)
	
	# Extraer tabla principal de la consulta
	var from_pos = query_upper.find("FROM")
	if from_pos == -1:
		return result
	
	var table_part = query.substr(from_pos + 4).strip_edges()
	var table_name = table_part.split(" ")[0].to_lower()
	
	print("🔍 [DATABASE] Tabla objetivo: ", table_name)
	
	# 🔍 LOG ESPECIAL PARA USUARIOS (DEBUG REDUCIDO)
	if table_name == "usuarios":
		print("👥 [DEBUG] Consultando usuarios: ", data.get("usuarios", []).size(), " encontrados")
	
	if not data.has(table_name):
		print("❌ [DATABASE] Tabla no existe: ", table_name)
		return result
	
	var table_data = data[table_name]
	if not table_data is Array:
		return result
	
	# Manejar WHERE básico
	if query_upper.find("WHERE") != -1:
		# Para consultas específicas comunes
		if query.find("email = ?") != -1 and _params.size() > 0:
			# Buscar por email
			for record in table_data:
				if record is Dictionary and record.get("email") == _params[0]:
					result.append(record)
			print("✅ [DATABASE] Búsqueda por email encontró: ", result.size(), " registros")
			return result
		elif (query.find("id = ?") != -1 or query.find("t.id = ?") != -1) and _params.size() > 0:
			# Buscar por ID
			var search_id = _params[0]
			for record in table_data:
				if record is Dictionary and int(record.get("id", 0)) == int(search_id):
					result.append(record)
			print("✅ [DATABASE] Búsqueda por ID ", search_id, " encontró: ", result.size(), " registros")
			return result
	
	# Por simplicidad, devolvemos todos los datos de la tabla
	print("✅ [DATABASE] Devolviendo todos los registros: ", table_data.size())
	return table_data

func handle_ticket_join_query(query: String, params: Array) -> Array:
	"""Maneja consultas de tickets con JOINs a clientes y empleados"""
	print("🔗 [DATABASE] Procesando consulta con JOIN de tickets")
	print("🔍 [DATABASE] Query: ", query)
	print("🔍 [DATABASE] Params: ", params)
	
	if not data.has("tickets"):
		print("❌ [DATABASE] No hay tabla tickets")
		return []
	
	var tickets = data["tickets"]
	var clientes = data.get("clientes", [])
	var usuarios = data.get("usuarios", [])
	
	print("📊 [DATABASE] Datos disponibles:")
	print("   - Tickets: ", tickets.size())
	print("   - Clientes: ", clientes.size())
	print("   - Usuarios: ", usuarios.size())
	
	# Debug: mostrar algunos tickets y clientes
	if tickets.size() > 0:
		print("🔍 [DATABASE] Ejemplo ticket: ", tickets[0])
	if clientes.size() > 0:
		print("🔍 [DATABASE] Ejemplo cliente: ", clientes[0])
	
	# Crear mapas para lookup rápido
	var clientes_map = {}
	for cliente in clientes:
		if cliente.has("id"):
			clientes_map[int(cliente.id)] = cliente
	
	var usuarios_map = {}
	for usuario in usuarios:
		if usuario.has("id"):
			usuarios_map[int(usuario.id)] = usuario
	
	var result = []
	
	# Si hay WHERE con ID específico
	if query.to_upper().find("WHERE T.ID = ?") != -1 and params.size() > 0:
		var search_id = int(params[0])
		print("🔍 [DATABASE] Buscando ticket con ID: ", search_id)
		
		for ticket in tickets:
			if int(ticket.get("id", 0)) == search_id:
				print("🎯 [DATABASE] Ticket encontrado con ID ", search_id, ": ", ticket)
				var ticket_completo = ticket.duplicate()
				
				# Agregar datos del cliente
				var cliente_id = int(ticket.get("cliente_id", 0))
				print("🔍 [DATABASE] Buscando cliente con ID: ", cliente_id)
				print("🔍 [DATABASE] Clientes disponibles en map: ", clientes_map.keys())
				
				if clientes_map.has(cliente_id):
					var cliente = clientes_map[cliente_id]
					print("✅ [DATABASE] Cliente encontrado: ", cliente)
					ticket_completo["cliente_nombre"] = cliente.get("nombre", "")
					ticket_completo["cliente_telefono"] = cliente.get("telefono", "")
					ticket_completo["cliente_email"] = cliente.get("email", "")
				else:
					print("❌ [DATABASE] Cliente con ID ", cliente_id, " no encontrado en map")
					ticket_completo["cliente_nombre"] = ""
					ticket_completo["cliente_telefono"] = ""
					ticket_completo["cliente_email"] = ""
				
				# Agregar datos del técnico/empleado
				var tecnico_id = ticket.get("tecnico_id")
				if tecnico_id != null and int(tecnico_id) > 0 and usuarios_map.has(int(tecnico_id)):
					var tecnico = usuarios_map[int(tecnico_id)]
					ticket_completo["tecnico_nombre"] = tecnico.get("nombre", "")
				
				result.append(ticket_completo)
				print("✅ [DATABASE] Ticket combinado: ", ticket_completo)
				break
	else:
		# Devolver todos los tickets con datos combinados
		for ticket in tickets:
			var ticket_completo = ticket.duplicate()
			
			# Agregar datos del cliente
			var cliente_id = int(ticket.get("cliente_id", 0))
			if clientes_map.has(cliente_id):
				var cliente = clientes_map[cliente_id]
				ticket_completo["cliente_nombre"] = cliente.get("nombre", "")
				ticket_completo["cliente_telefono"] = cliente.get("telefono", "")
				ticket_completo["cliente_email"] = cliente.get("email", "")
			
			# Agregar datos del técnico
			var tecnico_id = ticket.get("tecnico_id")
			if tecnico_id != null and int(tecnico_id) > 0 and usuarios_map.has(int(tecnico_id)):
				var tecnico = usuarios_map[int(tecnico_id)]
				ticket_completo["tecnico_nombre"] = tecnico.get("nombre", "")
			
			result.append(ticket_completo)
	
	print("✅ [DATABASE] JOIN query completado - ", result.size(), " registros")
	return result

func handle_insert(query: String, params: Array):
	# Reset del estado de éxito
	insert_success = false
	
	# Extraer tabla y valores
	var into_pos = query.to_upper().find("INTO")
	if into_pos == -1:
		return
	
	var remaining = query.substr(into_pos + 4).strip_edges()
	var parts = remaining.split(" ")
	if parts.size() < 1:
		return
	
	var table_name = parts[0]
	
	# Asegurar que la tabla existe
	if not data.has(table_name):
		data[table_name] = []
	
	# Para simplicidad, creamos un registro con un ID autoincremental
	var new_record = {}
	
	# Si hay parámetros, los usamos como valores
	if params.size() > 0:
		var new_id = get_next_id(table_name)
		new_record["id"] = new_id
		last_insert_id = new_id  # ✅ Actualizar último ID insertado
		# Agregar otros campos según los parámetros
		# Esto es muy básico, en una implementación real necesitaríamos parsear la consulta
		if table_name == "usuarios":
			if params.size() >= 4:
				new_record["nombre"] = params[0] if params.size() > 0 else ""
				new_record["email"] = params[1] if params.size() > 1 else ""
				new_record["password_hash"] = params[2] if params.size() > 2 else ""
				new_record["rol_id"] = params[3] if params.size() > 3 else 1
				new_record["activo"] = params[4] if params.size() > 4 else true
				new_record["created_at"] = Time.get_datetime_string_from_system()
		elif table_name == "roles":
			if params.size() >= 2:
				new_record["id"] = params[0]
				new_record["nombre"] = params[1]
		elif table_name == "configuracion":
			if params.size() >= 3:
				new_record["clave"] = params[0]
				new_record["valor"] = params[1]
				new_record["descripcion"] = params[2]
		elif table_name == "clientes":
			if params.size() >= 8:
				new_record["nombre"] = params[0] if params.size() > 0 else ""
				new_record["nif"] = params[1] if params.size() > 1 else ""
				new_record["email"] = params[2] if params.size() > 2 else ""
				new_record["telefono"] = params[3] if params.size() > 3 else ""
				new_record["telefono_alt"] = params[4] if params.size() > 4 else ""
				new_record["direccion"] = params[5] if params.size() > 5 else ""
				new_record["notas"] = params[6] if params.size() > 6 else ""
				new_record["rgpd_consent"] = params[7] if params.size() > 7 else 0
				new_record["creado_en"] = Time.get_datetime_string_from_system()
			else:
				print("❌ [DATABASE] Parámetros insuficientes para insertar cliente: ", params.size(), " (esperados: 8)")
		elif table_name == "tickets":
			if params.size() >= 16:
				# Mapeo correcto según las migraciones y DataService.gd
				new_record["codigo"] = params[0] if params.size() > 0 else ""
				new_record["estado"] = params[1] if params.size() > 1 else "Nuevo"
				new_record["prioridad"] = params[2] if params.size() > 2 else "NORMAL"
				# Manejar cliente_id con conversión de tipo segura
				if params.size() > 3 and params[3] != null:
					new_record["cliente_id"] = int(params[3])
				else:
					new_record["cliente_id"] = null
				
				# Manejar tecnico_id con conversión de tipo segura
				if params.size() > 4 and params[4] != null and str(params[4]) != "":
					new_record["tecnico_id"] = int(params[4])
				else:
					new_record["tecnico_id"] = null
				new_record["equipo_tipo"] = params[5] if params.size() > 5 else ""
				new_record["equipo_marca"] = params[6] if params.size() > 6 else ""
				new_record["equipo_modelo"] = params[7] if params.size() > 7 else ""
				new_record["numero_serie"] = params[8] if params.size() > 8 else ""
				new_record["imei"] = params[9] if params.size() > 9 else ""
				new_record["accesorios"] = params[10] if params.size() > 10 else ""
				new_record["password_bloqueo"] = params[11] if params.size() > 11 else ""
				new_record["averia_cliente"] = params[12] if params.size() > 12 else ""
				new_record["diagnostico"] = params[13] if params.size() > 13 else ""
				new_record["notas_internas"] = params[14] if params.size() > 14 else ""
				new_record["notas_cliente"] = params[15] if params.size() > 15 else ""
				new_record["fecha_entrada"] = Time.get_datetime_string_from_system()
			else:
				print("❌ [DATABASE] Parámetros insuficientes para insertar ticket: ", params.size(), " (esperados: 16)")
		elif table_name == "productos":
			if params.size() >= 10:
				new_record["sku"] = params[0] if params.size() > 0 else ""
				new_record["nombre"] = params[1] if params.size() > 1 else ""
				new_record["categoria"] = params[2] if params.size() > 2 else ""
				new_record["tipo"] = params[3] if params.size() > 3 else "REPUESTO"
				new_record["coste"] = params[4] if params.size() > 4 else 0.0
				new_record["pvp"] = params[5] if params.size() > 5 else 0.0
				new_record["iva"] = params[6] if params.size() > 6 else 21.0
				new_record["stock"] = params[7] if params.size() > 7 else 0
				new_record["stock_min"] = params[8] if params.size() > 8 else 0
				new_record["proveedor"] = params[9] if params.size() > 9 else ""
				print("✅ [DATABASE] Creando producto completo: ", new_record)
			else:
				print("❌ [DATABASE] Parámetros insuficientes para insertar producto: ", params.size(), " (esperados: 10)")
		else:
			print("⚠️ [DATABASE] Tabla no reconocida para INSERT: ", table_name, " - Solo creando con ID")
	else:
		print("⚠️ [DATABASE] INSERT sin parámetros para tabla: ", table_name)
	
	# Validar foreign keys antes de insertar
	var validation_passed = true
	if table_relations.has(table_name):
		for field_name in table_relations[table_name]:
			if new_record.has(field_name):
				var fk_value = new_record[field_name]
				# Saltar validación si es null o vacío (FK opcional)
				if fk_value != null and str(fk_value) != "" and str(fk_value) != "0":
					if not validate_foreign_key(table_name, field_name, fk_value):
						print("❌ [DATABASE] INSERT fallido - FK inválida: ", field_name, "=", fk_value)
						validation_passed = false
						break
	
	if validation_passed:
		data[table_name].append(new_record)
		save_database()
		insert_success = true
		print("✅ [DATABASE] INSERT exitoso en ", table_name, " con ID: ", new_record.get("id", "N/A"))
	else:
		insert_success = false
		print("❌ [DATABASE] INSERT cancelado por FK inválidas")

func handle_update(query: String, params: Array):
	# Implementación básica de UPDATE
	print("🔄 [DATABASE] UPDATE ejecutado: ", query)
	print("🔄 [DATABASE] Parámetros: ", params)
	
	# 🔍 DEBUGGING ESPECIAL PARA USUARIOS (REDUCIDO)
	if query.to_upper().contains("UPDATE USUARIOS"):
		print("⚠️ [DEBUG] Actualizando usuarios: ", data.get("usuarios", []).size(), " registros")
	
	# Extraer tabla de forma más robusta
	var query_clean = query.strip_edges().replace("\n", " ").replace("\t", " ")
	var query_upper = query_clean.to_upper()
	var set_pos = query_upper.find("SET")
	var where_pos = query_upper.find("WHERE")
	
	if set_pos == -1 or where_pos == -1:
		print("❌ [DATABASE] UPDATE mal formado")
		return
	
	# Extraer nombre de tabla entre UPDATE y SET
	var update_to_set = query_clean.substr(6, set_pos - 6).strip_edges()  # Después de "UPDATE"
	var table_name = update_to_set.split(" ")[0].strip_edges()
	
	print("🔍 [DATABASE] Tabla extraída: '", table_name, "'")
	
	if not data.has(table_name):
		print("❌ [DATABASE] Tabla no existe: ", table_name)
		return
	
	# Para simplicidad, asumimos que es una actualización por ID (último parámetro)
	if params.size() == 0:
		print("❌ [DATABASE] No hay parámetros para UPDATE")
		return
	
	var id_to_update = params[params.size() - 1]  # Último parámetro es el ID
	
	# Buscar el registro
	for i in range(data[table_name].size()):
		var record = data[table_name][i]
		if int(record.get("id", 0)) == int(id_to_update):
			# Actualizar campos específicos según la tabla
			if table_name == "clientes" and params.size() >= 9:
				record["nombre"] = params[0]
				record["nif"] = params[1]
				record["email"] = params[2]
				record["telefono"] = params[3]
				record["telefono_alt"] = params[4]
				record["direccion"] = params[5]
				record["notas"] = params[6]
				record["rgpd_consent"] = params[7]
				# ID es params[8]
				print("✅ [DATABASE] Cliente actualizado: ", record.get("nombre"))
			elif table_name == "usuarios" and params.size() >= 2:
				# Actualización genérica de usuarios - maneja campos dinámicos
				# El último parámetro es siempre el ID
				var user_id = params[params.size() - 1]
				
				# Determinar qué campos actualizar basado en el número de parámetros
				if params.size() == 2:  # Solo activo
					record["activo"] = params[0]
				elif params.size() == 4:  # password_hash, rol_id, nombre
					record["password_hash"] = params[0]
					record["rol_id"] = params[1]
					record["nombre"] = params[2]
				elif params.size() == 5:  # nombre, email, rol_id, activo
					record["nombre"] = params[0]
					record["email"] = params[1]
					record["rol_id"] = params[2]
					record["activo"] = params[3]
				elif params.size() == 6:  # nombre, email, password_hash, rol_id, activo
					record["nombre"] = params[0]
					record["email"] = params[1]
					record["password_hash"] = params[2]
					record["rol_id"] = params[3]
					record["activo"] = params[4]
				
				record["updated_at"] = Time.get_datetime_string_from_system()
				print("✅ [DATABASE] Usuario actualizado: ", record.get("nombre"))
			elif table_name == "productos" and params.size() >= 11:
				print("🔧 [DATABASE] Actualizando producto ID ", record.get("id"), ":")
				print("🔧 [DATABASE] - Stock ANTES: ", record.get("stock"))
				print("🔧 [DATABASE] - Stock NUEVO: ", params[7])
				
				record["sku"] = params[0]
				record["nombre"] = params[1]
				record["categoria"] = params[2]
				record["tipo"] = params[3]
				record["coste"] = params[4]
				record["pvp"] = params[5]
				record["iva"] = params[6]
				record["stock"] = params[7]
				record["stock_min"] = params[8]
				record["proveedor"] = params[9]
				# ID es params[10]
				
				print("🔧 [DATABASE] - Stock DESPUÉS: ", record.get("stock"))
				print("✅ [DATABASE] Producto actualizado: ", record.get("nombre"), " (ID: ", record.get("id"), ")")
			elif table_name == "tickets" and params.size() >= 13:
				print("🎫 [DATABASE] Actualizando ticket ID ", record.get("id"), ":")
				print("🎫 [DATABASE] - Estado ANTES: ", record.get("estado"))
				print("🎫 [DATABASE] - Estado NUEVO: ", params[0])
				
				record["estado"] = params[0]
				record["prioridad"] = params[1] 
				record["cliente_id"] = params[2]
				record["tecnico_id"] = params[3]
				record["equipo_tipo"] = params[4]
				record["equipo_marca"] = params[5]
				record["equipo_modelo"] = params[6]
				record["numero_serie"] = params[7]
				record["password_bloqueo"] = params[8]
				record["accesorios"] = params[9]
				record["averia_cliente"] = params[10]
				record["notas_cliente"] = params[11]
				# params[12] es el ID para WHERE
				
				print("🎫 [DATABASE] - Estado DESPUÉS: ", record.get("estado"))
				print("✅ [DATABASE] Ticket actualizado: ", record.get("codigo"), " (ID: ", record.get("id"), ")")
			else:
				print("⚠️ [DATABASE] UPDATE no implementado para tabla: ", table_name, " con ", params.size(), " parámetros")
			break
	
	# 🔍 DEBUGGING ESPECIAL PARA USUARIOS - DESPUÉS (REDUCIDO)
	if query.to_upper().contains("UPDATE USUARIOS"):
		print("✅ [DEBUG] Actualización usuarios completada")
	
	save_database()

func handle_delete(query: String, params: Array):
	# Implementación básica de DELETE
	print("🗑️ [DATABASE] DELETE ejecutado: ", query)
	print("🗑️ [DATABASE] Parámetros: ", params)
	
	# Extraer tabla
	var from_pos = query.to_upper().find("FROM")
	var _where_pos = query.to_upper().find("WHERE")
	
	if from_pos == -1:
		print("❌ [DATABASE] DELETE mal formado")
		return
	
	var table_part = query.substr(from_pos + 4).strip_edges()
	var table_name = table_part.split(" ")[0]
	
	if not data.has(table_name):
		print("❌ [DATABASE] Tabla no existe: ", table_name)
		return
	
	# Para simplicidad, asumimos DELETE por ID
	if params.size() > 0:
		var id_to_delete = params[0]
		
		for i in range(data[table_name].size() - 1, -1, -1):  # Iterar hacia atrás
			var record = data[table_name][i]
			if record.get("id") == id_to_delete:
				data[table_name].remove_at(i)
				print("✅ [DATABASE] Registro eliminado con ID: ", id_to_delete)
				break
	
	save_database()

func handle_create_table(query: String, _params: Array):
	# Extraer nombre de tabla
	var table_start = query.to_upper().find("TABLE")
	if table_start == -1:
		return
	
	var remaining = query.substr(table_start + 5).strip_edges()
	
	# Manejar "IF NOT EXISTS"
	if remaining.to_upper().begins_with("IF NOT EXISTS"):
		remaining = remaining.substr(13).strip_edges()
	
	var table_name = remaining.split(" ")[0].split("(")[0].strip_edges()
	
	# Crear tabla si no existe
	if not data.has(table_name):
		data[table_name] = []
		print("Tabla creada: ", table_name)
	
	save_database()

func get_next_id(table_name: String) -> int:
	if not data.has(table_name):
		return 1
	
	var max_id = 0
	for record in data[table_name]:
		if record is Dictionary and record.has("id"):
			var id_val = int(str(record["id"]))
			if id_val > max_id:
				max_id = id_val
	
	return max_id + 1

func get_last_insert_id() -> int:
	# Retorna el último ID insertado usando la variable last_insert_id
	print("📊 [DATABASE] Último ID insertado: ", last_insert_id)
	return last_insert_id

# Métodos auxiliares para inicialización
func initialize_default_data():
	# Crear roles por defecto
	if not data.has("roles"):
		data["roles"] = [
			{"id": 1, "nombre": "ADMIN"},
			{"id": 2, "nombre": "TECNICO"},
			{"id": 3, "nombre": "RECEPCION"},
			{"id": 4, "nombre": "READONLY"}
		]
	
	# Crear usuario admin por defecto SOLO si no hay usuarios
	if not data.has("usuarios") or data["usuarios"].size() == 0:
		print("🔧 [DATABASE] Creando usuarios por defecto...")
		data["usuarios"] = []
		data["usuarios"].append({
			"id": 1,
			"nombre": "Administrador",
			"email": "admin@tienda-sat.com",
			"pass_hash": "admin123",  # En producción debería ser un hash real
			"rol_id": 1,
			"activo": true
		})
	else:
		print("✅ [DATABASE] Usuarios ya existen, no se sobreescriben")
	
	# Crear configuración por defecto
	if not data.has("configuracion"):
		data["configuracion"] = [
			{"clave": "empresa_nombre", "valor": "Mi Tienda SAT", "descripcion": "Nombre de la empresa"},
			{"clave": "empresa_nif", "valor": "", "descripcion": "NIF/CIF de la empresa"},
			{"clave": "iva_defecto", "valor": "21", "descripcion": "IVA por defecto (%)"},
			{"clave": "ticket_prefix", "valor": "SAT", "descripcion": "Prefijo para códigos de ticket"}
		]
	
	# Crear otras tablas vacías
	var table_names = ["clientes", "productos", "tickets", "ticket_lineas", "ticket_tiempos", 
				  "ticket_historial", "adjuntos", "ventas", "migrations"]
	
	for table in table_names:
		if not data.has(table):
			data[table] = []
	
	save_database()
	print("Datos iniciales creados")

# =====================================================
# SISTEMA DE RELACIONES TIPO FOREIGN KEY
# =====================================================

# Definir las relaciones entre tablas (similar a foreign keys)
var table_relations = {
	"tickets": {
		"cliente_id": {"table": "clientes", "field": "id", "cascade_delete": false},
		"tecnico_id": {"table": "usuarios", "field": "id", "cascade_delete": false}
	},
	"ticket_lineas": {
		"ticket_id": {"table": "tickets", "field": "id", "cascade_delete": true},
		"producto_id": {"table": "productos", "field": "id", "cascade_delete": false}
	},
	"ticket_tiempos": {
		"ticket_id": {"table": "tickets", "field": "id", "cascade_delete": true},
		"tecnico_id": {"table": "usuarios", "field": "id", "cascade_delete": false}
	},
	"ticket_historial": {
		"ticket_id": {"table": "tickets", "field": "id", "cascade_delete": true},
		"usuario_id": {"table": "usuarios", "field": "id", "cascade_delete": false}
	},
	"adjuntos": {
		"ticket_id": {"table": "tickets", "field": "id", "cascade_delete": true}
	},
	"usuarios": {
		"rol_id": {"table": "roles", "field": "id", "cascade_delete": false}
	}
}

func validate_foreign_key(table_name: String, field_name: String, value) -> bool:
	"""Valida que un valor de foreign key exista en la tabla referenciada"""
	if not table_relations.has(table_name):
		return true  # No hay relaciones definidas para esta tabla
		
	if not table_relations[table_name].has(field_name):
		return true  # Este campo no tiene relación definida
		
	# Si el valor es null, considerarlo válido (foreign key opcional)
	if value == null:
		return true
		
	var relation = table_relations[table_name][field_name]
	var referenced_table = relation["table"]
	var referenced_field = relation["field"]
	
	# Verificar que la tabla referenciada existe
	if not data.has(referenced_table):
		print("❌ [DATABASE] Tabla referenciada no existe: ", referenced_table)
		return false
	
	# Buscar el valor en la tabla referenciada
	for record in data[referenced_table]:
		if record is Dictionary and record.has(referenced_field):
			var record_value = record[referenced_field]
			
			# Convertir ambos valores a número para comparación numérica
			var record_num = float(str(record_value))
			var search_num = float(str(value))
			
			if record_num == search_num:
				return true
				
	print("❌ [DATABASE] FK inválida: ", field_name, "=", value, " no encontrado en ", referenced_table)
	return false

func get_related_records(table_name: String, record_id, relation_field: String) -> Array:
	"""Obtiene registros relacionados (similar a SELECT con JOIN)"""
	var result = []
	
	# Buscar tablas que tengan foreign keys hacia esta tabla
	for related_table in table_relations:
		var relations = table_relations[related_table]
		for field_name in relations:
			var relation = relations[field_name]
			if relation["table"] == table_name and relation["field"] == relation_field:
				# Esta tabla tiene una FK hacia la tabla actual
				if data.has(related_table):
					for record in data[related_table]:
						if record is Dictionary and record.has(field_name):
							if str(record[field_name]) == str(record_id):
								result.append(record)
								
	return result

func delete_with_cascade(table_name: String, record_id) -> bool:
	"""Elimina un registro y maneja cascade delete de relaciones"""
	print("🗑️ [DATABASE] Eliminando registro ID ", record_id, " de ", table_name)
	
	# Primero, manejar cascade deletes
	for related_table in table_relations:
		var relations = table_relations[related_table]
		for field_name in relations:
			var relation = relations[field_name]
			if relation["table"] == table_name and relation.get("cascade_delete", false):
				print("🔗 [DATABASE] Cascade delete en ", related_table, ".", field_name)
				# Eliminar registros relacionados
				if data.has(related_table):
					var records_to_delete = []
					for i in range(data[related_table].size()):
						var record = data[related_table][i]
						if record is Dictionary and record.has(field_name):
							if str(record[field_name]) == str(record_id):
								records_to_delete.append(i)
								
					# Eliminar en orden inverso para no afectar índices
					for i in range(records_to_delete.size() - 1, -1, -1):
						data[related_table].remove_at(records_to_delete[i])
						print("✅ [DATABASE] Eliminado registro relacionado en ", related_table)
	
	# Finalmente, eliminar el registro principal
	if data.has(table_name):
		for i in range(data[table_name].size()):
			var record = data[table_name][i]
			if record is Dictionary and record.has("id"):
				if str(record["id"]) == str(record_id):
					data[table_name].remove_at(i)
					save_database()
					print("✅ [DATABASE] Registro eliminado de ", table_name)
					return true
					
	print("❌ [DATABASE] No se encontró el registro a eliminar")
	return false

func get_record_with_relations(table_name: String, record_id) -> Dictionary:
	"""Obtiene un registro con sus datos relacionados incluidos"""
	var main_record = {}
	
	# Obtener el registro principal
	if data.has(table_name):
		for record in data[table_name]:
			if record is Dictionary and record.has("id"):
				if str(record["id"]) == str(record_id):
					main_record = record.duplicate()
					break
					
	if main_record.is_empty():
		return {}
		
	# Agregar datos de foreign keys
	if table_relations.has(table_name):
		var relations = table_relations[table_name]
		for field_name in relations:
			if main_record.has(field_name):
				var relation = relations[field_name]
				var fk_value = main_record[field_name]
				
				if fk_value != null and fk_value != "":
					# Buscar el registro relacionado
					var related_table = relation["table"]
					var related_field = relation["field"]
					
					if data.has(related_table):
						for related_record in data[related_table]:
							if related_record is Dictionary and related_record.has(related_field):
								if str(related_record[related_field]) == str(fk_value):
									# Agregar campos del registro relacionado con prefijo
									var table_prefix = related_table.rstrip("s") + "_"  # "clientes" -> "cliente_"
									for key in related_record:
										if key != related_field:  # No duplicar el ID
											main_record[table_prefix + key] = related_record[key]
									break
	
	return main_record
