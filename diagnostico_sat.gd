extends Node

# Script de diagnóstico rápido para la aplicación SAT
# Ejecutar desde Godot para verificar el estado del sistema

func _ready():
	var linea = "=".repeat(50)
	print("\n" + linea)
	print("🔧 DIAGNÓSTICO SAT - TIENDA INFORMÁTICA")
	print(linea)
	
	await get_tree().create_timer(0.5).timeout
	
	verificar_autoloads()
	await get_tree().create_timer(0.5).timeout
	
	verificar_base_datos()
	await get_tree().create_timer(0.5).timeout
	
	verificar_archivos_criticos()
	await get_tree().create_timer(0.5).timeout
	
	probar_funcionalidad()
	
	var linea_fin = "=".repeat(50)
	print("\n" + linea_fin)
	print("✅ DIAGNÓSTICO COMPLETADO")
	print(linea_fin + "\n")

func verificar_autoloads():
	print("\n📋 VERIFICANDO AUTOLOADS...")
	
	# AppState
	if has_node("/root/AppState"):
		print("✅ AppState: OK")
	else:
		print("❌ AppState: NO ENCONTRADO")
	
	# Router  
	if has_node("/root/Router"):
		print("✅ Router: OK")
	else:
		print("❌ Router: NO ENCONTRADO")
	
	# DataService
	if has_node("/root/DataService"):
		print("✅ DataService: OK")
		if DataService.db:
			print("✅ Database: INICIALIZADA")
		else:
			print("❌ Database: NO INICIALIZADA")
	else:
		print("❌ DataService: NO ENCONTRADO")

func verificar_base_datos():
	print("\n💾 VERIFICANDO BASE DE DATOS...")
	
	if not DataService or not DataService.db:
		print("❌ Base de datos no disponible")
		return
	
	# Verificar datos por defecto
	var usuarios = DataService.execute_sql("SELECT * FROM usuarios")
	var roles = DataService.execute_sql("SELECT * FROM roles") 
	var config = DataService.execute_sql("SELECT * FROM configuracion")
	
	print("👥 Usuarios: ", usuarios.size())
	print("🔐 Roles: ", roles.size())
	print("⚙️ Configuración: ", config.size())
	
	if usuarios.size() > 0:
		print("✅ Usuario admin existe: ", usuarios[0].get("email", "NO_EMAIL"))
	else:
		print("❌ No hay usuarios en la BD")

func verificar_archivos_criticos():
	print("\n📁 VERIFICANDO ARCHIVOS...")
	
	var archivos_criticos = [
		"res://ui/login.tscn",
		"res://ui/login.gd", 
		"res://ui/dashboard.tscn",
		"res://autoload/AppState.gd",
		"res://autoload/Router.gd",
		"res://autoload/DataService.gd",
		"res://data/sqlite/database.gd"
	]
	
	for archivo in archivos_criticos:
		if FileAccess.file_exists(archivo):
			print("✅ ", archivo)
		else:
			print("❌ ", archivo, " - NO ENCONTRADO")

func probar_funcionalidad():
	print("\n🧪 PROBANDO FUNCIONALIDAD...")
	
	if not DataService or not DataService.db:
		print("❌ No se puede probar - BD no disponible")
		return
	
	# Probar login
	var login_ok = AppState.login("admin@tienda-sat.com", "admin123")
	
	if login_ok:
		print("✅ Login funcionando correctamente")
		print("👤 Usuario logueado: ", AppState.get_usuario_nombre())
		print("🔑 Es admin: ", AppState.es_admin)
		
		# Logout
		AppState.logout()
		print("✅ Logout OK")
	else:
		print("❌ Login FALLÓ - verificar credenciales por defecto")
		
		# Debug adicional
		var usuarios = DataService.execute_sql("SELECT * FROM usuarios")
		if usuarios.size() > 0:
			print("🔍 Usuario en BD:", usuarios[0])
		else:
			print("🔍 No hay usuarios en BD")

# Función auxiliar para ejecutar desde el editor
func ejecutar_diagnostico_manual():
	_ready()