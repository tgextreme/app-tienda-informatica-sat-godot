extends Node

# Router - Maneja la navegación entre pantallas

signal pantalla_cambiada(nueva_pantalla: String, parametros: Dictionary)

var pantalla_actual: String = ""
var historial_navegacion: Array[String] = []
var root_control: Control
var pantallas_cargadas: Dictionary = {}

# Rutas de las pantallas
var rutas_pantallas = {
	"login": "res://ui/login.tscn",
	"dashboard": "res://ui/dashboard.tscn", 
	"nuevo_ticket": "res://ui/nuevo_ticket.tscn",
	"tickets_lista": "res://ui/tickets_list.tscn",
	"ticket_detalle": "res://ui/ticket_detail.tscn",
	"clientes_lista": "res://ui/gestionar_clientes.tscn",
	"cliente_detalle": "res://ui/cliente_detail.tscn",
	"empleados_lista": "res://ui/gestionar_empleados_new.tscn",
	"empleado_detalle": "res://ui/empleado_detail.tscn",
	"inventario_lista": "res://ui/inventario_list.tscn",
	"producto_detalle": "res://ui/producto_detail.tscn",
	"reportes": "res://ui/reportes.tscn",
	"ajustes": "res://ui/ajustes.tscn"
}

func _ready():
	# Conectar señal de logout para volver al login
	AppState.usuario_deslogueado.connect(_on_usuario_deslogueado)

func inicializar(control_root: Control):
	print("🧭 [ROUTER] Inicializando Router...")
	print("📊 [ROUTER] Control recibido: ", control_root)
	print("📊 [ROUTER] Control es válido: ", control_root != null)
	
	root_control = control_root
	
	if root_control == null:
		push_error("❌ [ROUTER] control_root es null!")
		return
	
	print("✅ [ROUTER] Router inicializado con contenedor: ", root_control.name)
	print("📊 [ROUTER] Tipo de control: ", root_control.get_class())
	print("📊 [ROUTER] Contenedor válido: ", root_control.is_inside_tree())
	
	# Conectar señal de eliminación del nodo para detectar cuando se libera
	if root_control.tree_exiting.is_connected(_on_root_control_freed):
		root_control.tree_exiting.disconnect(_on_root_control_freed)
	root_control.tree_exiting.connect(_on_root_control_freed)

func _on_root_control_freed():
	print("⚠️ [ROUTER] ContentContainer se está liberando - reinicializando...")
	root_control = null
	
	# Intentar reinicializar inmediatamente
	call_deferred("_intentar_reinicializar_inmediato")

func ir_a(pantalla: String, parametros: Dictionary = {}):
	print("🧭 [ROUTER] Navegando a: ", pantalla)
	print("📊 [ROUTER] root_control estado: ", root_control)
	
	if root_control == null or not is_instance_valid(root_control):
		push_error("❌ [ROUTER] Router no inicializado - root_control es null o inválido")
		print("🔧 [ROUTER] Intentando reinicializar automáticamente...")
		
		# Buscar el contenedor en el árbol de nodos
		var main_node = buscar_nodo_main()
		
		if main_node != null:
			var content_container = main_node.get_node_or_null("ContentContainer")
			if content_container != null and is_instance_valid(content_container):
				print("🔧 [ROUTER] Contenedor encontrado, reinicializando...")
				inicializar(content_container)
			else:
				print("❌ [ROUTER] ContentContainer no encontrado o inválido en Main")
				# Intentar crear el ContentContainer si no existe
				intentar_crear_content_container(main_node)
		else:
			print("❌ [ROUTER] Nodo Main no encontrado")
			push_error("❌ [ROUTER] CRÍTICO: No se puede navegar sin Main scene. Reinicia la aplicación.")
			return
		
		# Verificar nuevamente después del intento de reinicialización
		if root_control == null or not is_instance_valid(root_control):
			push_error("❌ [ROUTER] CRÍTICO: No se pudo reinicializar el Router")
			return
	
	if not rutas_pantallas.has(pantalla):
		push_error("Pantalla no encontrada: " + pantalla)
		return
	
	# Verificar permisos de navegación
	if not puede_navegar_a(pantalla):
		push_warning("Sin permisos para acceder a: " + pantalla)
		return
	
	# Guardar en historial
	if pantalla_actual != "":
		historial_navegacion.append(pantalla_actual)
	
	# Cargar nueva pantalla
	var nueva_scene = cargar_pantalla(pantalla)
	if nueva_scene == null:
		push_error("No se pudo cargar la pantalla: " + pantalla)
		return
	
	print("✅ Pantalla cargada: ", pantalla)
	
	# Limpiar pantalla anterior
	if root_control != null:
		for child in root_control.get_children():
			child.queue_free()
	
	# Añadir nueva pantalla
	root_control.add_child(nueva_scene)
	
	# Configurar la nueva pantalla con parámetros
	if nueva_scene.has_method("configurar"):
		nueva_scene.configurar(parametros)
	
	pantalla_actual = pantalla
	pantalla_cambiada.emit(pantalla, parametros)
	
	print("🎯 Navegación completada a: ", pantalla)

func cargar_pantalla(pantalla: String) -> Control:
	var ruta = rutas_pantallas[pantalla]
	print("📂 Cargando pantalla desde: ", ruta)
	
	# Verificar que el archivo existe
	if not FileAccess.file_exists(ruta):
		push_error("Archivo de pantalla no existe: " + ruta)
		return null
	
	# Cache de pantallas para mejorar rendimiento
	if pantallas_cargadas.has(pantalla):
		print("♻️ Usando pantalla del cache: ", pantalla)
		return pantallas_cargadas[pantalla].instantiate()
	
	var resource = load(ruta)
	if resource == null:
		push_error("No se puede cargar: " + ruta)
		return null
	
	print("✅ Recurso cargado: ", ruta)
	pantallas_cargadas[pantalla] = resource
	
	var instancia = resource.instantiate()
	if instancia == null:
		push_error("No se puede instanciar: " + ruta)
		return null
	
	print("✅ Pantalla instanciada: ", pantalla)
	return instancia

func puede_navegar_a(pantalla: String) -> bool:
	# Si no hay usuario logueado, solo permitir login
	if AppState.usuario_actual.is_empty():
		return pantalla == "login"
	
	# Si hay usuario, no permitir login
	if pantalla == "login":
		return false
	
	# Verificar permisos específicos por pantalla
	match pantalla:
		"ajustes":
			return AppState.es_admin
		"reportes":
			return AppState.tiene_permiso("ver_reportes")
		"inventario_lista":
			return AppState.tiene_permiso("gestionar_inventario")
		"empleados_lista":
			return AppState.es_admin
		_:
			return true # Resto de pantallas accesibles para usuarios logueados

func volver_atras():
	if historial_navegacion.size() > 0:
		var pantalla_anterior = historial_navegacion.pop_back()
		ir_a(pantalla_anterior)

func ir_a_dashboard():
	ir_a("dashboard")

func ir_a_login():
	ir_a("login")

func ir_a_tickets(filtros: Dictionary = {}):
	ir_a("tickets_lista", {"filtros": filtros})

func ir_a_ticket_detalle(ticket_id: int):
	ir_a("ticket_detalle", {"ticket_id": ticket_id})

func ir_a_nuevo_ticket():
	ir_a("nuevo_ticket")

func ir_a_editar_ticket(ticket_id: int):
	print("🎯 [ROUTER] Navegando a editar ticket con ID: ", ticket_id)
	ir_a("nuevo_ticket", {"ticket_id": ticket_id, "modo": "editar"})

func ir_a_tickets_lista():
	print("🎯 [ROUTER] Navegando a lista de tickets")
	ir_a("tickets_lista")

func ir_a_clientes():
	ir_a("clientes_lista")

func ir_a_empleados():
	ir_a("empleados_lista")

func ir_a_cliente_detalle(cliente_id: int):
	ir_a("cliente_detalle", {"cliente_id": cliente_id})

func ir_a_nuevo_cliente():
	ir_a("cliente_detalle", {"nuevo": true})

func ir_a_inventario():
	ir_a("inventario_lista")

func ir_a_producto_detalle(producto_id: int):
	ir_a("producto_detalle", {"producto_id": producto_id})

func ir_a_nuevo_producto():
	ir_a("producto_detalle", {"nuevo": true})

func ir_a_reportes():
	ir_a("reportes")

func ir_a_ajustes():
	ir_a("ajustes")

func _on_usuario_deslogueado():
	# Limpiar historial y volver al login
	historial_navegacion.clear()
	pantalla_actual = ""
	ir_a("login")

func buscar_nodo_main() -> Node:
	"""Busca el nodo Main en diferentes ubicaciones posibles"""
	print("🔍 [ROUTER] Iniciando búsqueda del nodo Main...")
	
	# Verificar si la escena actual ES la main.tscn
	var current_scene = get_tree().current_scene
	print("📊 [ROUTER] Escena actual: ", current_scene.name if current_scene else "null")
	
	if current_scene != null and current_scene.scene_file_path == "res://main.tscn":
		print("🔍 [ROUTER] Main encontrado como escena actual (main.tscn)")
		# Asegurar que esté en el grupo main
		if not current_scene.is_in_group("main"):
			current_scene.add_to_group("main")
			print("✅ [ROUTER] Main agregado al grupo")
		return current_scene
	
	# Buscar por grupo primero
	var main_nodes = get_tree().get_nodes_in_group("main")
	print("📊 [ROUTER] Nodos en grupo 'main': ", main_nodes.size())
	if main_nodes.size() > 0:
		var found_main = main_nodes[0]
		print("🔍 [ROUTER] Main encontrado por grupo: ", found_main.name)
		print("📊 [ROUTER] Main tiene ContentContainer: ", found_main.has_node("ContentContainer"))
		return found_main
	
	# Buscar en la raíz por nombre
	var root_main = get_tree().root.get_node_or_null("Main")
	if root_main != null:
		print("🔍 [ROUTER] Main encontrado en raíz: ", root_main.name)
		return root_main
	
	# Buscar recursivamente por cualquier nodo que tenga ContentContainer
	var found = buscar_main_recursivo(get_tree().root)
	if found != null:
		print("🔍 [ROUTER] Main encontrado recursivamente: ", found.name)
		return found
	
	print("❌ [ROUTER] Main no encontrado en ninguna ubicación")
	print("📊 [ROUTER] Información de debug:")
	var scene_name = "null"
	var scene_path = "null"
	if get_tree().current_scene:
		scene_name = get_tree().current_scene.name
		scene_path = get_tree().current_scene.scene_file_path
	print("  - Escena actual: ", scene_name, " (", scene_path, ")")
	var children_names = []
	for child in get_tree().root.get_children():
		children_names.append(child.name)
	print("  - Hijos de root: ", children_names)
	return null

func buscar_main_recursivo(nodo: Node) -> Node:
	"""Busca el nodo Main recursivamente"""
	# Buscar por nombre Main O por tener ContentContainer
	if (nodo.name == "Main" and nodo.get_script() != null) or (nodo.has_node("ContentContainer")):
		print("🔍 [ROUTER] Candidato encontrado: ", nodo.name, " - Tiene ContentContainer: ", nodo.has_node("ContentContainer"))
		return nodo
	
	for child in nodo.get_children():
		var result = buscar_main_recursivo(child)
		if result != null:
			return result
	
	return null

func intentar_crear_content_container(main_node: Node):
	"""Intenta crear un ContentContainer si no existe"""
	print("🔨 [ROUTER] Intentando crear ContentContainer en: ", main_node.name)
	
	# Verificar si ya existe
	if main_node.has_node("ContentContainer"):
		return
	
	# Crear un nuevo ContentContainer
	var content_container = Control.new()
	content_container.name = "ContentContainer"
	content_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_node.add_child(content_container)
	
	# Reinicializar el Router con el nuevo contenedor
	inicializar(content_container)
	print("✅ [ROUTER] ContentContainer creado exitosamente")

func intentar_navegacion_directa(pantalla: String, _parametros: Dictionary = {}):
	"""Navegación de último recurso - Ya no cambia escena directamente"""
	print("⚠️ [ROUTER] Navegación directa deshabilitada por seguridad")
	print("❌ [ROUTER] No se puede navegar a: ", pantalla)
	print("💡 [ROUTER] Sugerencia: Reiniciar la aplicación para cargar main.tscn")
	
	# NO cambiar escena directamente - esto rompe la estructura
	# get_tree().change_scene_to_packed(escena)  # DESHABILITADO
	
	push_error("❌ [ROUTER] Navegación fallida - aplicación en estado inconsistente")

func _intentar_reinicializar_inmediato():
	"""Intenta reinicializar el Router inmediatamente después de perder conexión"""
	print("⚡ [ROUTER] Intento de reinicialización inmediata...")
	
	# Esperar un frame para que el árbol se estabilice
	await get_tree().process_frame
	
	var main_node = buscar_nodo_main()
	if main_node != null:
		var content_container = main_node.get_node_or_null("ContentContainer")
		if content_container != null and is_instance_valid(content_container):
			print("⚡ [ROUTER] Reinicialización inmediata exitosa")
			inicializar(content_container)
		else:
			intentar_crear_content_container(main_node)
	else:
		print("⚡ [ROUTER] Reinicialización inmediata falló - Main no encontrado")