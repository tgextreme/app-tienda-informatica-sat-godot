extends RefCounted
class_name Database

# Clase para manejar la conexión y operaciones con SQLite
# Utiliza una implementación simple basada en archivos para Godot

var db_path: String
var tables: Dictionary = {}
var data: Dictionary = {}

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
	execute_sql(query, params)
	return true

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
		new_record["id"] = get_next_id(table_name)
		# Agregar otros campos según los parámetros
		# Esto es muy básico, en una implementación real necesitaríamos parsear la consulta
		if table_name == "usuarios":
			if params.size() >= 4:
				new_record["nombre"] = params[0] if params.size() > 0 else ""
				new_record["email"] = params[1] if params.size() > 1 else ""
				new_record["pass_hash"] = params[2] if params.size() > 2 else ""
				new_record["rol_id"] = params[3] if params.size() > 3 else 1
				new_record["activo"] = 1
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
				new_record["cliente_id"] = params[3] if params.size() > 3 else 0
				new_record["tecnico_id"] = params[4] if params.size() > 4 else null
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
	
	data[table_name].append(new_record)
	save_database()

func handle_update(query: String, params: Array):
	# Implementación básica de UPDATE
	print("🔄 [DATABASE] UPDATE ejecutado: ", query)
	print("🔄 [DATABASE] Parámetros: ", params)
	
	# Extraer tabla
	var set_pos = query.to_upper().find("SET")
	var where_pos = query.to_upper().find("WHERE")
	
	if set_pos == -1 or where_pos == -1:
		print("❌ [DATABASE] UPDATE mal formado")
		return
	
	var table_part = query.substr(6, set_pos - 6).strip_edges()  # Después de "UPDATE"
	var table_name = table_part.strip_edges()
	
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
			break
	
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
	# Retorna el último ID insertado (busca en todas las tablas el ID más alto recién insertado)
	var max_id = 0
	
	# Buscar en todas las tablas el ID más alto
	for table_name in data:
		if data[table_name] is Array and data[table_name].size() > 0:
			var last_record = data[table_name][data[table_name].size() - 1]
			if last_record.has("id"):
				var record_id = int(last_record.id)
				if record_id > max_id:
					max_id = record_id
	
	print("📊 [DATABASE] Último ID insertado: ", max_id)
	return max_id

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
	
	# Crear usuario admin por defecto
	if not data.has("usuarios"):
		data["usuarios"] = []
	
	# Verificar si ya existe el admin
	var admin_exists = false
	for user in data["usuarios"]:
		if user is Dictionary and user.get("email") == "admin@tienda-sat.com":
			admin_exists = true
			break
	
	if not admin_exists:
		data["usuarios"].append({
			"id": 1,
			"nombre": "Administrador",
			"email": "admin@tienda-sat.com",
			"pass_hash": "admin123",  # En producción debería ser un hash real
			"rol_id": 1,
			"activo": 1
		})
	
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