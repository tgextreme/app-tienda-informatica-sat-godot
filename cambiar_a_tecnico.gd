extends Control

"""
Script simple para cambiar user@mail.com a técnico
"""

func _ready():
	print("🔧 Cambiando user@mail.com a técnico...")
	
	# Esperar un poco para que DataService esté listo
	await get_tree().create_timer(1.0).timeout
	
	if DataService.db:
		# Cambiar el usuario a técnico
		var resultado = DataService.execute_sql(
			"UPDATE usuarios SET rol_id = 2, nombre = 'Usuario Técnico' WHERE email = 'user@mail.com'"
		)
		
		if resultado != null:
			print("✅ Usuario cambiado a técnico")
			
			# Verificar el cambio
			var usuario = DataService.execute_sql("SELECT * FROM usuarios WHERE email = 'user@mail.com'")
			if usuario.size() > 0:
				print("📋 Usuario verificado:")
				print("   - Nombre:", usuario[0].get("nombre"))
				print("   - Email:", usuario[0].get("email")) 
				print("   - Rol ID:", usuario[0].get("rol_id"))
		else:
			print("❌ Error al cambiar usuario")
	else:
		print("❌ DataService no disponible")