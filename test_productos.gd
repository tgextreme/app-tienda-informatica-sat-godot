extends Node

# Script temporal para probar creación directa de productos

func _ready():
	print("🧪 [TEST] Iniciando prueba directa de productos...")
	
	# Esperar un poco a que DataService esté inicializado
	await get_tree().create_timer(2.0).timeout
	
	# Intentar crear un producto directamente
	var producto_test = {
		"sku": "TEST-001",
		"nombre": "Producto de Prueba",
		"categoria": "Test",
		"tipo": "REPUESTO",
		"coste": 10.0,
		"pvp": 15.0,
		"iva": 21.0,
		"stock": 5,
		"stock_min": 2,
		"proveedor": "Proveedor Test"
	}
	
	print("🧪 [TEST] Creando producto test...")
	var resultado = DataService.guardar_producto(producto_test)
	print("🧪 [TEST] Resultado creación: ", resultado)
	
	# Buscar productos
	print("🧪 [TEST] Buscando todos los productos...")
	var productos = DataService.buscar_productos({})
	print("🧪 [TEST] Productos encontrados: ", productos.size())
	
	for i in range(min(productos.size(), 3)):
		print("🧪 [TEST] Producto ", i, ": ", productos[i])
	
	# Eliminar este script después de la prueba
	queue_free()