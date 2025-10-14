extends SceneTree

func _init():
	print("=== VERIFICACIÓN DE USUARIOS EN BD ===")
	
	# Esperar a que DataService esté listo
	await get_tree().process_frame
	await get_tree().process_frame
	
	var data_service = preload("res://autoload/DataService.gd").new()
	
	print("\n--- TODOS LOS USUARIOS ---")
	var usuarios = data_service.execute_sql("SELECT * FROM usuarios")
	
	if usuarios.is_empty():
		print("❌ NO HAY USUARIOS EN LA BASE DE DATOS")
	else:
		for i in range(usuarios.size()):
			var user = usuarios[i]
			print("Usuario %d:" % (i + 1))
			print("  - ID: %s" % user.get("id", "N/A"))
			print("  - Nombre: %s" % user.get("nombre", "N/A"))
			print("  - Email: %s" % user.get("email", "N/A"))
			print("  - Password Hash: %s" % user.get("pass_hash", "N/A"))
			print("  - Password Hash 2: %s" % user.get("password_hash", "N/A"))
			print("  - Rol ID: %s" % user.get("rol_id", "N/A"))
			print("  - Activo: %s" % user.get("activo", "N/A"))
			print("  - Todos los campos: %s" % user)
			print("")
	
	print("\n--- USUARIO ESPECÍFICO: user@mail.com ---")
	var user_especifico = data_service.execute_sql("SELECT * FROM usuarios WHERE email = ?", ["user@mail.com"])
	
	if user_especifico.is_empty():
		print("❌ NO SE ENCONTRÓ user@mail.com")
	else:
		print("✅ ENCONTRADO:")
		var user = user_especifico[0]
		print("  - Nombre: %s" % user.get("nombre", "N/A"))
		print("  - Password Hash: %s" % user.get("pass_hash", "N/A"))
		print("  - Password Hash 2: %s" % user.get("password_hash", "N/A"))
		print("  - Activo: %s" % user.get("activo", "N/A"))
		print("  - Rol ID: %s" % user.get("rol_id", "N/A"))
	
	print("\n--- PRUEBA DE LOGIN SIMULADA ---")
	# Simular el proceso de login
	if not user_especifico.is_empty():
		var user = user_especifico[0]
		var password_almacenada = user.get("pass_hash", "")
		var password_almacenada2 = user.get("password_hash", "")
		
		print("Contraseña ingresada por usuario: user")
		print("Contraseña almacenada (pass_hash): ", password_almacenada)
		print("Contraseña almacenada (password_hash): ", password_almacenada2)
		
		# Test con diferentes contraseñas
		var tests = ["user", "123", "user123", "password", ""]
		for test_pwd in tests:
			var match1 = test_pwd == password_almacenada
			var match2 = test_pwd == password_almacenada2
			print("¿'%s' == pass_hash? %s" % [test_pwd, match1])
			print("¿'%s' == password_hash? %s" % [test_pwd, match2])
		
		# Test hash
		var hash_test = str("user".hash())
		print("Hash de 'user': ", hash_test)
		print("¿Hash coincide con pass_hash? ", hash_test == password_almacenada)
		print("¿Hash coincide con password_hash? ", hash_test == password_almacenada2)
	
	print("\n=== FIN DE VERIFICACIÓN ===")
	quit()