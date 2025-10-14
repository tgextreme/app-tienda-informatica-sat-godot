extends ScriptableRenderPipeline

# Script para crear un cliente de prueba que coincida con la imagen
func create_test_client():
	print("🧪 Creando cliente de prueba...")
	
	# Conectar a la base de datos
	var database = preload("res://data/sqlite/database.gd").new()
	
	# Crear cliente que coincida con la imagen
	var cliente_data = {
		"nombre": "Juan Pérez García",
		"telefono": "666-123-456", 
		"email": "cliente@email.com",
		"nif": "12345678A",
		"direccion": "Calle Mayor 123, Madrid",
		"telefono_alt": "",
		"notas": "",
		"rgpd_consent": 1
	}
	
	# Insertar en la base de datos
	database.execute_sql("""
		INSERT OR REPLACE INTO clientes (id, nombre, telefono, email, nif, direccion, telefono_alt, notas, rgpd_consent, creado_en)
		VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
	""", [
		cliente_data.nombre,
		cliente_data.telefono,
		cliente_data.email,
		cliente_data.nif,
		cliente_data.direccion,
		cliente_data.telefono_alt,
		cliente_data.notas,
		cliente_data.rgpd_consent
	])
	
	print("✅ Cliente de prueba creado: ", cliente_data.nombre)

func _init():
	create_test_client()