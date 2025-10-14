extends Node

"""
Script para crear un usuario técnico real (no-admin) para testing
"""

func _ready():
	print("🔧 [CREAR_TECNICO] Creando usuario técnico real...")
	
	# Esperar DataService
	if not DataService.db:
		await get_tree().create_timer(2.0).timeout
	
	# Verificar si ya existe tecnico@test.com
	var usuarios_existentes = DataService.execute_sql("SELECT * FROM usuarios WHERE email = ?", ["tecnico@test.com"])
	
	if usuarios_existentes.size() > 0:
		print("✅ [CREAR_TECNICO] Usuario tecnico@test.com ya existe")
		mostrar_info_usuario(usuarios_existentes[0])
	else:
		crear_usuario_tecnico()
	
	get_tree().quit()

func crear_usuario_tecnico():
	print("📝 [CREAR_TECNICO] Creando nuevo usuario técnico...")
	
	# Hash de la contraseña "tecnico123"
	var password_hash = str("tecnico123".hash())
	
	# Insertar usuario técnico
	var resultado = DataService.execute_sql("""
		INSERT INTO usuarios (nombre, email, pass_hash, rol_id, activo) 
		VALUES (?, ?, ?, ?, ?)
		""", ["Técnico de Prueba", "tecnico@test.com", password_hash, 2, 1])
	
	if resultado:
		print("✅ [CREAR_TECNICO] Usuario técnico creado exitosamente:")
		print("   - Email: tecnico@test.com")
		print("   - Password: tecnico123")
		print("   - Rol: TECNICO (rol_id = 2)")
		print("   - Estado: Activo")
		
		# Verificar que se creó correctamente
		var usuario_creado = DataService.execute_sql("SELECT * FROM usuarios WHERE email = ?", ["tecnico@test.com"])
		if usuario_creado.size() > 0:
			mostrar_info_usuario(usuario_creado[0])
	else:
		print("❌ [CREAR_TECNICO] Error al crear usuario técnico")

func mostrar_info_usuario(usuario: Dictionary):
	print("\n📋 [CREAR_TECNICO] Información del usuario:")
	print("   - ID:", usuario.get("id"))
	print("   - Nombre:", usuario.get("nombre"))
	print("   - Email:", usuario.get("email"))
	print("   - Rol ID:", usuario.get("rol_id"))
	print("   - Activo:", usuario.get("activo"))
	print("   - Hash Password:", usuario.get("pass_hash"))