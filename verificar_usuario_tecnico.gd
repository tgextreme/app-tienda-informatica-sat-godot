extends SceneTree

func _init():
	print("=== VERIFICANDO USUARIO TÉCNICO ===")
	
	# Esperar frames para inicialización
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Cargar DataService
	var data_service = preload("res://autoload/DataService.gd").new()
	
	# Simular la inicialización (como haría _ready)
	data_service.inicializar_db()
	
	await get_tree().create_timer(1.0).timeout
	
	print("Buscando usuario: user@mail.com")
	var usuarios = data_service.execute_sql("SELECT * FROM usuarios WHERE email = ?", ["user@mail.com"])
	
	if usuarios.is_empty():
		print("❌ Usuario user@mail.com NO ENCONTRADO")
		
		print("\n📋 Mostrando TODOS los usuarios:")
		var todos_usuarios = data_service.execute_sql("SELECT * FROM usuarios")
		for i in range(todos_usuarios.size()):
			var u = todos_usuarios[i]
			print("Usuario %d: %s (%s) - Activo: %s" % [i+1, u.get("nombre", ""), u.get("email", ""), u.get("activo", "")])
	else:
		var usuario = usuarios[0]
		print("✅ Usuario ENCONTRADO:")
		print("  - Nombre: %s" % usuario.get("nombre", ""))
		print("  - Email: %s" % usuario.get("email", ""))
		print("  - password_hash: '%s'" % usuario.get("password_hash", ""))
		print("  - pass_hash: '%s'" % usuario.get("pass_hash", ""))
		print("  - rol_id: %s" % usuario.get("rol_id", ""))
		print("  - activo: %s" % usuario.get("activo", ""))
		
		# Probar contraseñas
		var password_almacenada = usuario.get("password_hash", usuario.get("pass_hash", ""))
		print("\n🧪 PROBANDO CONTRASEÑAS:")
		
		var contraseñas_prueba = ["user", "123", "user123", "", "password"]
		for pwd in contraseñas_prueba:
			var directo = pwd == password_almacenada
			var hash_pwd = str(pwd.hash())
			var hash_match = hash_pwd == password_almacenada
			print("  '%s' -> directo: %s | hash: %s (%s)" % [pwd, directo, hash_match, hash_pwd])
			
			if directo or hash_match:
				print("    ✅ ¡CONTRASEÑA CORRECTA!")
	
	print("\n=== FIN VERIFICACIÓN ===")
	quit()