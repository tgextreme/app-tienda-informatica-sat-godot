extends Node

# Script de prueba para verificar el sistema de empleados

func _ready():
	print("🧪 [TEST] Iniciando pruebas del sistema...")
	
	# Esperar a que DataService esté listo
	await get_tree().create_timer(2.0).timeout
	
	# Probar la creación de datos iniciales
	test_datos_iniciales()
	
	# Probar login
	test_login()

func test_datos_iniciales():
	print("\n📋 [TEST] Probando creación de datos iniciales...")
	
	# Cargar datos
	var data = DataService.cargar_datos_json()
	
	print("📊 [TEST] Datos cargados:")
	print("  - Usuarios: ", data.get("usuarios", []).size())
	print("  - Roles: ", data.get("roles", []).size())
	print("  - Clientes: ", data.get("clientes", []).size())
	
	# Mostrar usuario admin
	var usuarios = data.get("usuarios", [])
	if usuarios.size() > 0:
		var admin = usuarios[0]
		print("👤 [TEST] Usuario admin:")
		print("  - ID: ", admin.get("id"))
		print("  - Nombre: ", admin.get("nombre"))
		print("  - Email: ", admin.get("email"))
		print("  - Hash: ", admin.get("pass_hash"))
		print("  - Activo: ", admin.get("activo"))

func test_login():
	print("\n🔐 [TEST] Probando login...")
	
	# Probar hash de contraseña
	var password_original = "admin123"
	var hash_generado = DataService.hash_password(password_original)
	print("🔑 [TEST] Hash generado para 'admin123': ", hash_generado)
	
	# Probar login con AppState
	print("🔐 [TEST] Intentando login con admin@tienda-sat.com / admin123")
	var login_exitoso = AppState.login("admin@tienda-sat.com", "admin123")
	print("✅ [TEST] Login exitoso: ", login_exitoso)
	
	if login_exitoso:
		print("👤 [TEST] Usuario logueado: ", AppState.usuario_actual.get("nombre"))
	else:
		print("❌ [TEST] Login falló - revisando datos...")
		
		# Cargar datos y verificar manualmente
		var data = DataService.cargar_datos_json()
		var usuarios = data.get("usuarios", [])
		
		if usuarios.size() > 0:
			var admin = usuarios[0]
			var email_matches = str(admin.get("email", "")).to_lower() == "admin@tienda-sat.com"
			var is_active = int(admin.get("activo", 1)) == 1
			var password_hash = admin.get("pass_hash", "")
			var new_hash = DataService.hash_password("admin123")
			var password_matches = new_hash == password_hash
			
			print("📋 [TEST] Verificaciones:")
			print("  - Email coincide: ", email_matches)
			print("  - Usuario activo: ", is_active)
			print("  - Hash almacenado: ", password_hash)
			print("  - Hash calculado: ", new_hash)
			print("  - Contraseñas coinciden: ", password_matches)