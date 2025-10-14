extends Node

# Script de prueba para verificar la funcionalidad del sistema

func _ready():
	print("=== INICIANDO PRUEBAS DEL SISTEMA SAT ===")
	
	# Esperar a que los autoloads estén listos
	await get_tree().create_timer(1.0).timeout
	
	probar_base_datos()
	probar_autenticacion()
	
	print("=== PRUEBAS COMPLETADAS ===")

func probar_base_datos():
	print("\n--- Probando Base de Datos ---")
	
	if not DataService.db:
		print("ERROR: Base de datos no inicializada")
		return
	
	print("✓ Base de datos inicializada correctamente")
	
	# Probar consulta básica
	var usuarios = DataService.execute_sql("SELECT * FROM usuarios")
	print("Usuarios en BD: ", usuarios.size())
	
	if usuarios.size() > 0:
		print("✓ Datos de prueba cargados")
		print("Primer usuario: ", usuarios[0])
	else:
		print("⚠ No hay usuarios en la BD")

func probar_autenticacion():
	print("\n--- Probando Autenticación ---")
	
	# Intentar login con credenciales por defecto
	var exito = AppState.login("admin@tienda-sat.com", "admin123")
	
	if exito:
		print("✓ Login exitoso")
		print("Usuario actual: ", AppState.usuario_actual)
		print("Permisos - Admin: ", AppState.es_admin)
		print("Permisos - Técnico: ", AppState.es_tecnico)
	else:
		print("✗ Login falló")
	
	# Logout
	AppState.logout()
	print("✓ Logout completado")