extends Control

# Diagnóstico rápido del Router

func _ready():
	print("\n🔍 DIAGNÓSTICO ROUTER\n===============================")
	
	await get_tree().create_timer(2.0).timeout
	
	diagnosticar_router()

func diagnosticar_router():
	print("\n1. VERIFICANDO AUTOLOADS:")
	print("   AppState: ", AppState != null)
	print("   Router: ", Router != null)  
	print("   DataService: ", DataService != null)
	
	if Router == null:
		print("\n❌ ROUTER NO DISPONIBLE")
		return
	
	print("\n2. ESTADO DEL ROUTER:")
	print("   root_control: ", Router.root_control)
	print("   pantalla_actual: ", Router.pantalla_actual)
	
	print("\n3. BUSCANDO MAIN Y CONTENTCONTAINER:")
	var main_node = get_tree().get_first_node_in_group("main")
	print("   Main encontrado: ", main_node != null)
	
	if main_node:
		var content_container = main_node.get_node_or_null("ContentContainer")
		print("   ContentContainer encontrado: ", content_container != null)
		
		if content_container:
			print("   Tipo: ", content_container.get_class())
			print("   En árbol: ", content_container.is_inside_tree())
			
			print("\n4. PROBANDO INICIALIZACIÓN MANUAL:")
			Router.inicializar(content_container)
			
			await get_tree().create_timer(1.0).timeout
			
			print("   Router inicializado: ", Router.root_control != null)
			
			if Router.root_control != null:
				print("\n✅ ROUTER FUNCIONANDO - Probando navegación...")
				Router.ir_a_login()
			else:
				print("\n❌ ROUTER SIGUE FALLANDO")
	else:
		print("   ❌ Main no encontrado")
	
	print("\n===============================")
	
	get_tree().quit()