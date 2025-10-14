extends Node

# AppState - Maneja el estado global de la aplicación
# Sesión de usuario, permisos, configuraciones

signal usuario_logueado(usuario: Dictionary)
signal usuario_deslogueado()
signal configuracion_actualizada(clave: String, valor: String)

var usuario_actual: Dictionary = {}
var configuracion: Dictionary = {}
var es_admin: bool = false
var es_tecnico: bool = false
var es_recepcion: bool = false
var es_readonly: bool = false

# Estados de tickets válidos y transiciones permitidas
var estados_ticket = [
	"Nuevo",
	"Diagnosticando", 
	"Presupuestado",
	"Aprobado",
	"En reparación",
	"En pruebas", 
	"Listo para entrega",
	"Entregado",
	"Cerrado",
	"Rechazado",
	"No reparable"
]

var transiciones_permitidas = {
	"Nuevo": ["Diagnosticando"],
	"Diagnosticando": ["Nuevo", "Presupuestado", "No reparable"],
	"Presupuestado": ["Diagnosticando", "Aprobado", "Rechazado"],
	"Aprobado": ["En reparación"],
	"En reparación": ["En pruebas", "Presupuestado"],
	"En pruebas": ["En reparación", "Listo para entrega"],
	"Listo para entrega": ["Entregado"],
	"Entregado": ["Cerrado"],
	"Cerrado": [],
	"Rechazado": ["Presupuestado"],
	"No reparable": ["Cerrado"]
}

# Tipos de equipos
var tipos_equipo = [
	"PC",
	"Portátil", 
	"Móvil",
	"Tablet",
	"Impresora",
	"Monitor",
	"Consola",
	"Otro"
]

# Prioridades
var prioridades = [
	"BAJA",
	"NORMAL", 
	"ALTA",
	"URGENTE"
]

func _ready():
	print("AppState inicializando...")
	# Dar tiempo a DataService para inicializar
	await get_tree().create_timer(0.5).timeout
	cargar_configuracion()
	print("AppState listo")

func login(email: String, password: String) -> bool:
	print("🔐 [APPSTATE] Intentando login con: ", email)
	
	# Verificar credenciales contra la base de datos SQLite
	var usuarios = DataService.execute_sql("SELECT * FROM usuarios WHERE email = ? AND activo = 1", [email])
	print("👤 [APPSTATE] Usuarios encontrados: ", usuarios.size())
	
	# Si no se encuentra con activo=1, buscar sin filtro para debug
	if usuarios.size() == 0:
		print("🔍 [APPSTATE] Buscando usuario sin filtro activo...")
		var usuarios_debug = DataService.execute_sql("SELECT * FROM usuarios WHERE email = ?", [email])
		print("👤 [APPSTATE] Usuarios sin filtro: ", usuarios_debug.size())
		if usuarios_debug.size() > 0:
			var user_debug = usuarios_debug[0]
			print("🔍 [DEBUG] Usuario encontrado pero inactivo:")
			print("  - Nombre: ", user_debug.get("nombre", ""))
			print("  - Activo: ", user_debug.get("activo", ""))
			print("  - Email: ", user_debug.get("email", ""))
		
		print("❌ [APPSTATE] No se encontró usuario activo con email: ", email)
		return false
	
	var usuario = usuarios[0]
	print("👤 [APPSTATE] Usuario encontrado: ", usuario.get("nombre", ""))
	print("🔑 [APPSTATE] Hash almacenado (password_hash): ", usuario.get("password_hash", ""))
	print("🔑 [APPSTATE] Hash almacenado (pass_hash): ", usuario.get("pass_hash", ""))
	
	# Usar el campo correcto (password_hash es el estándar)
	var password_almacenada = usuario.get("password_hash", usuario.get("pass_hash", ""))
	
	# Verificar password con compatibilidad hacia atrás
	if not verificar_password(password, password_almacenada):
		print("❌ [APPSTATE] Contraseña incorrecta")
		print("🔍 [DEBUG] Usuario completo para debug: ", usuario)
		return false
	
	# Obtener información del rol
	var roles = DataService.execute_sql("SELECT * FROM roles WHERE id = ?", [usuario.rol_id])
	if roles.size() > 0:
		usuario["rol_nombre"] = roles[0].nombre
		print("🎭 [APPSTATE] Rol asignado: ", roles[0].nombre)
	
	# Establecer usuario actual
	usuario_actual = usuario
	actualizar_permisos()
	
	print("✅ [APPSTATE] Login exitoso para: ", usuario.get("nombre", ""))
	usuario_logueado.emit(usuario)
	return true

func logout():
	usuario_actual.clear()
	es_admin = false
	es_tecnico = false  
	es_recepcion = false
	es_readonly = false
	usuario_deslogueado.emit()

func tiene_permiso(accion: String) -> bool:
	match accion:
		"crear_ticket":
			return es_admin or es_recepcion or es_tecnico
		"editar_ticket":
			return es_admin or es_recepcion or es_tecnico
		"eliminar_ticket":
			return es_admin
		"cambiar_estado_ticket":
			return es_admin or es_tecnico or es_recepcion
		"ver_configuracion":
			return es_admin
		"editar_configuracion":
			return es_admin
		"hacer_backup":
			return es_admin
		"ver_reportes":
			return es_admin or es_tecnico or es_recepcion
		"gestionar_inventario":
			return es_admin or es_recepcion
		"facturar":
			return es_admin or es_recepcion
		_:
			return false

func puede_cambiar_estado(estado_actual: String, estado_nuevo: String) -> bool:
	if not transiciones_permitidas.has(estado_actual):
		return false
	return estado_nuevo in transiciones_permitidas[estado_actual]

func generar_codigo_ticket() -> String:
	var year = Time.get_datetime_dict_from_system().year
	var prefix = get_config("ticket_prefix", "SAT")
	
	# Obtener siguiente número secuencial
	var result = DataService.execute_sql("""
		SELECT MAX(CAST(SUBSTR(codigo, LENGTH(?) + 6) AS INTEGER)) as ultimo_num 
		FROM tickets 
		WHERE codigo LIKE ?
	""", [prefix, prefix + "-" + str(year) + "-%"])
	
	var siguiente_num = 1
	if result.size() > 0 and result[0].has("ultimo_num") and result[0]["ultimo_num"] != "":
		siguiente_num = int(result[0]["ultimo_num"]) + 1
	
	return "%s-%d-%06d" % [prefix, year, siguiente_num]

func actualizar_permisos():
	if usuario_actual.is_empty():
		return
		
	match int(usuario_actual.rol_id):
		1: # ADMIN
			es_admin = true
			es_tecnico = true
			es_recepcion = true
		2: # TECNICO
			es_tecnico = true
		3: # RECEPCION  
			es_recepcion = true
		4: # READONLY
			es_readonly = true

func verificar_password(password: String, password_hash: String) -> bool:
	print("🔍 [APPSTATE] Verificando password:")
	print("  - Password ingresado: ", password)
	print("  - Hash almacenado: ", password_hash)
	
	# Intentar comparación directa primero (para admin legacy)
	var resultado_directo = password == password_hash
	
	# Intentar comparación con hash (para empleados nuevos)
	var hash_password = str(password.hash())
	var resultado_hash = hash_password == password_hash
	
	var resultado_final = resultado_directo or resultado_hash
	
	print("  - Comparación directa: ", resultado_directo)
	print("  - Hash generado: ", hash_password)
	print("  - Comparación hash: ", resultado_hash)
	print("  - Resultado final: ", resultado_final)
	
	return resultado_final

func cargar_configuracion():
	# Esperar a que DataService esté listo
	if not DataService.db:
		print("DataService no está listo, reintentando en 1 segundo...")
		await get_tree().create_timer(1.0).timeout
		if not DataService.db:
			print("DataService sigue sin estar listo, usando configuración por defecto")
			return
		
	var configs = DataService.execute_sql("SELECT * FROM configuracion")
	configuracion.clear()
	
	for config in configs:
		if config.has("clave") and config.has("valor"):
			configuracion[config.clave] = config.valor
	
	print("Configuración cargada: ", configuracion)

func get_config(clave: String, defecto: String = "") -> String:
	return configuracion.get(clave, defecto)

func set_config(clave: String, valor: String):
	configuracion[clave] = valor
	DataService.execute_non_query(
		"INSERT OR REPLACE INTO configuracion (clave, valor) VALUES (?, ?)",
		[clave, valor]
	)
	configuracion_actualizada.emit(clave, valor)

func get_usuario_id() -> int:
	if usuario_actual.has("id"):
		return int(usuario_actual.id)
	return -1

func get_usuario_nombre() -> String:
	return usuario_actual.get("nombre", "")

static func hash_password(password: String) -> String:
	"""Genera un hash simple de la contraseña (para demostración)"""
	# NOTA: En un sistema real se debería usar bcrypt o similar
	var context = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(password.to_utf8_buffer())
	var result = context.finish()
	return result.hex_encode()