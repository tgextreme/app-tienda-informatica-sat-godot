extends Control

func _ready():
	print("🔧 Creando usuario técnico...")
	await get_tree().create_timer(1.0).timeout
	
	if DataService.db:
		# Crear usuario técnico
		var password_hash = str("tecnico123".hash())
		
		# Verificar si ya existe
		var existente = DataService.execute_sql("SELECT * FROM usuarios WHERE email = 'tecnico@test.com'")
		
		if existente.size() == 0:
			var resultado = DataService.execute_sql("""
				INSERT INTO usuarios (nombre, email, pass_hash, rol_id, activo) 
				VALUES (?, ?, ?, ?, ?)
				""", ["Técnico Test", "tecnico@test.com", password_hash, 2, 1])
			
			if resultado != null:
				print("✅ Usuario técnico creado:")
				print("   Email: tecnico@test.com")
				print("   Password: tecnico123") 
				print("   Rol: TECNICO (2)")
		else:
			print("✅ Usuario técnico ya existe")