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
	# Implementación básica de SELECT
	var result = []
	
	# Extraer tabla de la consulta (muy básico)
	var from_pos = query.to_upper().find("FROM")
	if from_pos == -1:
		return result
	
	var table_part = query.substr(from_pos + 4).strip_edges()
	var table_name = table_part.split(" ")[0]
	
	if not data.has(table_name):
		return result
	
	var table_data = data[table_name]
	if not table_data is Array:
		return result
	
	# Manejar WHERE básico
	if query.to_upper().find("WHERE") != -1:
		# Para consultas específicas comunes
		if query.find("email = ?") != -1 and _params.size() > 0:
			# Buscar por email
			for record in table_data:
				if record is Dictionary and record.get("email") == _params[0]:
					result.append(record)
			return result
		elif query.find("id = ?") != -1 and _params.size() > 0:
			# Buscar por ID
			for record in table_data:
				if record is Dictionary and str(record.get("id")) == str(_params[0]):
					result.append(record)
			return result
	
	# Por simplicidad, devolvemos todos los datos de la tabla
	return table_data

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
				new_record["fecha_registro"] = Time.get_datetime_string_from_system()
		elif table_name == "tickets":
			if params.size() >= 8:
				new_record["codigo"] = params[0] if params.size() > 0 else ""
				new_record["cliente_id"] = params[1] if params.size() > 1 else 0
				new_record["tecnico_id"] = params[2] if params.size() > 2 else 0
				new_record["equipo_tipo"] = params[3] if params.size() > 3 else ""
				new_record["equipo_marca"] = params[4] if params.size() > 4 else ""
				new_record["equipo_modelo"] = params[5] if params.size() > 5 else ""
				new_record["descripcion_problema"] = params[6] if params.size() > 6 else ""
				new_record["estado"] = params[7] if params.size() > 7 else "Nuevo"
				new_record["fecha_entrada"] = Time.get_datetime_string_from_system()
	
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