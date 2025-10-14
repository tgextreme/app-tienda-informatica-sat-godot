extends SceneTree

func _init():
	print("=== TEST DE SEGURIDAD EMPLEADOS ===")
	
	# Simular inicio de sesión como admin
	AppState.usuario_actual = {
		"id": 1,
		"nombre": "Administrador",
		"email": "admin@tienda-sat.com", 
		"rol": "ADMIN",
		"rol_id": 1
	}
	
	print("✅ Usuario admin simulado: ", AppState.usuario_actual.nombre)
	print("🎭 Rol: ", AppState.usuario_actual.rol)
	
	# Crear DataService para pruebas
	var data_service = preload("res://autoload/DataService.gd").new()
	
	print("\n=== PRUEBA 1: Verificación de empleados existentes ===")
	
	# Verificar función obtener_empleados
	if data_service.has_method("obtener_empleados"):
		print("✅ Función obtener_empleados disponible")
	else:
		print("❌ Función obtener_empleados NO disponible")
	
	print("\n=== PRUEBA 2: Protección del admin principal ===")
	
	# Simular intento de eliminar admin (ID=1) 
	if data_service.has_method("eliminar_empleado"):
		print("🧪 Probando eliminar empleado ID=1 (admin)...")
		var resultado = data_service.eliminar_empleado(1)
		if resultado is Dictionary and not resultado.get("success", true):
			print("✅ PROTECCIÓN ACTIVA: ", resultado.get("message", "Admin protegido"))
		else:
			print("❌ FALLO DE SEGURIDAD: Admin no está protegido")
	else:
		print("❌ Función eliminar_empleado NO disponible")
	
	print("\n=== PRUEBA 3: Verificación de controles de UI ===")
	print("ℹ️  Para probar completamente:")
	print("1. Ejecutar aplicación normal")
	print("2. Iniciar sesión como admin@tienda-sat.com / admin123")
	print("3. Ir a Dashboard > Empleados")
	print("4. Verificar que:")
	print("   - Solo admin ve botón 'AÑADIR'")
	print("   - Admin principal muestra 'PROTEGIDO' en lugar de 'ELIMINAR'")
	print("   - Al editar admin, solo permite cambiar contraseña")
	
	print("\n=== TEST COMPLETADO ===")
	quit()