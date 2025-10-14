extends Node

# Script para actualizar el cliente de prueba
func _ready():
	print("🔧 Actualizando cliente de prueba...")
	actualizar_cliente_prueba()

func actualizar_cliente_prueba():
	# Usar DataService para actualizar el cliente
	var cliente_data = {
		"id": 1,
		"nombre": "Juan Pérez García",
		"telefono": "666-123-456",
		"email": "cliente@email.com", 
		"nif": "12345678A",
		"direccion": "Calle Mayor 123, Madrid",
		"telefono_alt": "",
		"notas": "",
		"rgpd_consent": 1
	}
	
	var resultado = DataService.guardar_cliente(cliente_data)
	
	if resultado > 0:
		print("✅ Cliente actualizado correctamente: ", cliente_data.nombre)
		print("   - Teléfono: ", cliente_data.telefono)
		print("   - Email: ", cliente_data.email)
		print("   - NIF: ", cliente_data.nif)
	else:
		print("❌ Error al actualizar cliente")