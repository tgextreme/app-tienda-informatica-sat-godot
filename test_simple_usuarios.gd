extends SceneTree

func _init():
	print("=== VERIFICACIÓN SIMPLE USUARIOS ===")
	
	# Cargar AppState para simular proceso
	var app_state = preload("res://autoload/AppState.gd").new()
	var data_service = preload("res://autoload/DataService.gd").new()
	
	print("1. Intentando obtener usuarios...")
	
	# Simular obtener usuarios
	print("2. Verificando user@mail.com...")
	
	# Verificar función de hash
	print("3. Test de hash:")
	print("   Hash de 'user': ", str("user".hash()))
	print("   Hash de '123': ", str("123".hash()))
	print("   Hash de 'user123': ", str("user123".hash()))
	
	print("4. Simulando verificación login...")
	
	quit()