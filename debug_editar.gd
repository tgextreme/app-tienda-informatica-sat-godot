extends Node

# Script de debug para probar la funcionalidad de editar productos

func _ready():
	print("🧪 [DEBUG] === TEST EDITAR PRODUCTO ===")
	
	# Simular navegación a editar producto
	test_parametros_edicion()

func test_parametros_edicion():
	print("🧪 [DEBUG] Probando parámetros de edición...")
	
	# Simular los parámetros que debería recibir
	var parametros_test = {
		"modo": "editar",
		"producto_id": 1
	}
	
	print("🧪 [DEBUG] Parámetros simulados: ", parametros_test)
	
	# Verificar lógica
	if parametros_test.has("modo") and parametros_test.modo == "editar":
		print("✅ [DEBUG] Modo edición detectado correctamente")
		var producto_id = parametros_test.get("producto_id", -1)
		print("✅ [DEBUG] ID del producto: ", producto_id)
		
		# Verificar datos del producto
		if producto_id > 0:
			var datos = {
				"id": producto_id,
				"sku": "TEST-001",
				"nombre": "Producto de prueba"
			}
			
			if datos.has("id") and int(datos.id) > 0:
				print("✅ [DEBUG] Datos tienen ID para actualización: ", datos.id)
			else:
				print("❌ [DEBUG] Datos NO tienen ID - se creará nuevo producto")
	else:
		print("❌ [DEBUG] Modo edición NO detectado")
	
	print("🧪 [DEBUG] === FIN TEST ===")