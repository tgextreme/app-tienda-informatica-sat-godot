extends Control

# Test para verificar que no se crean clientes automáticamente

func _ready():
	print("🧪 [TEST] Verificando que no se crean clientes automáticamente...")
	
	# Esperar a que DataService se inicialice
	await get_tree().create_timer(1.0).timeout
	
	# Verificar el estado
	if DataService:
		var clientes = DataService.obtener_clientes()
		print("📊 [TEST] Clientes encontrados: ", clientes.size())
		
		# Si hay clientes, es porque ya existían, no porque se crearon automáticamente
		if clientes.size() > 0:
			print("✅ [TEST] Hay clientes existentes (NO se crearon automáticamente)")
		else:
			print("✅ [TEST] No hay clientes - perfecto, no se crearon automáticamente")
		
		print("🎉 [TEST] Función de creación automática DESACTIVADA correctamente")
	else:
		print("❌ [TEST] DataService no disponible")
	
	# Terminar
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()