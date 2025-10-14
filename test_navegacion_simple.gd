extends Control

# Test de navegación al CRUD de clientes

func _ready():
	print("🧪 [TEST] === INICIANDO PRUEBA NAVEGACIÓN CLIENTES ===")
	
	# Esperar a que el sistema esté listo
	await get_tree().create_timer(1.0).timeout
	
	# Simular login
	print("🧪 [TEST] Simulando login...")
	AppState.usuario_actual = {
		"id": 1,
		"nombre": "Admin Test",
		"email": "admin@test.com", 
		"rol_id": 1,
		"rol_nombre": "ADMIN"
	}
	AppState.es_admin = true
	print("✅ [TEST] Usuario configurado: ", AppState.usuario_actual.nombre)
	
	# Probar navegación
	await get_tree().create_timer(1.0).timeout
	print("🧪 [TEST] Intentando navegar a clientes...")
	
	if Router.has_method("ir_a_clientes"):
		Router.ir_a_clientes()
		print("✅ [TEST] Comando de navegación enviado")
	else:
		print("❌ [TEST] Router no tiene método ir_a_clientes")
	
	# Esperar un momento para ver el resultado
	await get_tree().create_timer(3.0).timeout
	
	print("🧪 [TEST] Pantalla actual: ", Router.pantalla_actual)
	print("🧪 [TEST] === PRUEBA COMPLETADA ===")
	
	# Terminar
	get_tree().quit()