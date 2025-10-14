extends Control

# Script para agregar clientes de prueba

func _ready():
	print("🧪 [AGREGAR_CLIENTES] Añadiendo clientes de prueba...")
	
	# Esperar a que el sistema esté listo
	await get_tree().create_timer(1.0).timeout
	
	# Crear clientes de prueba
	var clientes_prueba = [
		{
			"nombre": "Juan Pérez García",
			"telefono": "666-111-222",
			"email": "juan@email.com",
			"nif": "12345678A",
			"direccion": "Calle Mayor 123, Madrid"
		},
		{
			"nombre": "María López Martín",
			"telefono": "666-333-444", 
			"email": "maria@email.com",
			"nif": "87654321B",
			"direccion": "Avenida España 456, Barcelona"
		},
		{
			"nombre": "Carlos Rodríguez Sánchez",
			"telefono": "666-555-666",
			"email": "carlos@email.com", 
			"nif": "11223344C",
			"direccion": "Plaza Central 789, Valencia"
		}
	]
	
	# Insertar cada cliente
	for cliente_data in clientes_prueba:
		if DataService:
			var resultado = DataService.crear_cliente(cliente_data)
			if resultado.success:
				print("✅ [AGREGAR_CLIENTES] Cliente creado: ", cliente_data.nombre)
			else:
				print("❌ [AGREGAR_CLIENTES] Error creando cliente: ", cliente_data.nombre)
	
	print("🎉 [AGREGAR_CLIENTES] Clientes de prueba agregados")
	
	# Terminar
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()