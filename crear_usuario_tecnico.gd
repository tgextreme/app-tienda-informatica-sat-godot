extends SceneTree

func _init():
	print("=== CREANDO USUARIO TÉCNICO DE PRUEBA ===")
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Cargar DataService
	var data_service = preload("res://autoload/DataService.gd").new()
	data_service.inicializar_db()
	
	await get_tree().create_timer(1.0).timeout
	
	# Verificar si ya existe user@mail.com
	var usuarios_existentes = data_service.execute_sql("SELECT * FROM usuarios WHERE email = ?", ["user@mail.com"])
	
	if usuarios_existentes.size() > 0:
		print("✅ Usuario user@mail.com ya existe")
		var user = usuarios_existentes[0]
		print("  - Nombre: %s" % user.get("nombre", ""))
		print("  - Activo: %s" % user.get("activo", ""))
		print("  - Password actual: %s" % user.get("password_hash", ""))
		
		# Actualizar la contraseña a algo conocido
		print("\n🔧 Actualizando contraseña a 'user123'...")
		var nueva_password = "user123"
		var password_hash = str(nueva_password.hash())
		
		var resultado = data_service.execute_sql(
			"UPDATE usuarios SET password_hash = ?, activo = 1 WHERE email = ?", 
			[password_hash, "user@mail.com"]
		)
		
		if not resultado.is_empty():
			print("✅ Contraseña actualizada exitosamente")
			print("   - Nueva contraseña: %s" % nueva_password)
			print("   - Hash: %s" % password_hash)
		else:
			print("❌ Error al actualizar contraseña")
			
	else:
		print("❌ Usuario user@mail.com no existe")
		print("🔧 Creando usuario técnico...")
		
		# Crear usuario técnico
		var nueva_password = "user123"
		var password_hash = str(nueva_password.hash())
		
		var resultado = data_service.execute_sql("""
			INSERT INTO usuarios (nombre, email, password_hash, rol_id, activo, created_at) 
			VALUES (?, ?, ?, ?, ?, datetime('now'))
		""", ["Técnico Usuario", "user@mail.com", password_hash, 2, 1])
		
		if not resultado.is_empty():
			print("✅ Usuario técnico creado exitosamente")
			print("   - Email: user@mail.com")
			print("   - Contraseña: %s" % nueva_password)
			print("   - Hash: %s" % password_hash)
		else:
			print("❌ Error al crear usuario")
	
	print("\n📋 CREDENCIALES FINALES:")
	print("   Email: user@mail.com")
	print("   Contraseña: user123")
	print("   Rol: Técnico (ID: 2)")
	
	print("\n=== PROCESO COMPLETADO ===")
	quit()