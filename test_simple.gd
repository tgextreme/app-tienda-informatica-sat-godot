extends SceneTree

func _init():
	print("=== INICIANDO TEST SIMPLE ===")
	
	# Test 1: Verificar DataService
	print("Test 1: Verificando DataService...")
	var data_service = preload("res://autoload/DataService.gd").new()
	
	print("Test 2: Verificando función generar_hash_password...")
	var hash_result = data_service.generar_hash_password("test123")
	print("Hash generado: ", hash_result)
	
	print("Test 3: Verificando funciones de empleados...")
	
	# Verificar que las funciones existen
	if data_service.has_method("obtener_empleados"):
		print("✅ Función obtener_empleados existe")
	else:
		print("❌ Función obtener_empleados NO existe")
	
	if data_service.has_method("crear_empleado"):
		print("✅ Función crear_empleado existe")
	else:
		print("❌ Función crear_empleado NO existe")
	
	if data_service.has_method("actualizar_empleado"):
		print("✅ Función actualizar_empleado existe")
	else:
		print("❌ Función actualizar_empleado NO existe")
	
	if data_service.has_method("eliminar_empleado"):
		print("✅ Función eliminar_empleado existe")
	else:
		print("❌ Función eliminar_empleado NO existe")
	
	print("=== TEST COMPLETADO ===")
	quit()