extends Control

# Lista de tickets SAT con filtros y búsqueda

@onready var search_input = $VBoxContainer/FiltersContainer/SearchInput
@onready var estado_filter = $VBoxContainer/FiltersContainer/EstadoFilter  
@onready var tecnico_filter = $VBoxContainer/FiltersContainer/TecnicoFilter
@onready var tickets_tree = $VBoxContainer/TicketsTree
@onready var count_label = $VBoxContainer/StatusBar/CountLabel
@onready var new_ticket_button = $VBoxContainer/TopBar/NewTicketButton

var tickets_data: Array = []
var filtros_actuales: Dictionary = {}

func _ready():
	configurar_interfaz()
	configurar_filtros()
	cargar_tickets()
	
	# Conectar señal para menú contextual y botones
	if tickets_tree.button_clicked.connect(_on_tickets_tree_button_clicked) != OK:
		print("❌ Error conectando señal button_clicked del TreeItem")

func configurar_interfaz():
	# Configurar permisos
	new_ticket_button.visible = AppState.tiene_permiso("crear_ticket")
	
	# Configurar columnas del tree (7 columnas en total: 0-6)
	tickets_tree.columns = 7
	tickets_tree.set_column_title(0, "Código")
	tickets_tree.set_column_title(1, "Cliente")
	tickets_tree.set_column_title(2, "Equipo")
	tickets_tree.set_column_title(3, "Estado")
	tickets_tree.set_column_title(4, "Técnico")
	tickets_tree.set_column_title(5, "Fecha")
	tickets_tree.set_column_title(6, "Acciones")
	
	tickets_tree.set_column_custom_minimum_width(0, 120)
	tickets_tree.set_column_custom_minimum_width(1, 200)
	tickets_tree.set_column_custom_minimum_width(2, 150)
	tickets_tree.set_column_custom_minimum_width(3, 120)
	tickets_tree.set_column_custom_minimum_width(4, 150)
	tickets_tree.set_column_custom_minimum_width(5, 100)
	tickets_tree.set_column_custom_minimum_width(6, 80)  # Columna para botones

func configurar_filtros():
	# Filtro de estados
	estado_filter.add_item("Todos los estados", 0)
	for i in range(AppState.estados_ticket.size()):
		estado_filter.add_item(AppState.estados_ticket[i], i + 1)
	
	# Filtro de técnicos
	tecnico_filter.add_item("Todos los técnicos", 0)
	var tecnicos = DataService.obtener_tecnicos()
	for i in range(tecnicos.size()):
		var tecnico = tecnicos[i]
		tecnico_filter.add_item(tecnico.nombre, int(tecnico.id))

func cargar_tickets():
	# Construir filtros de búsqueda
	var filtros = {}
	
	# Filtro de búsqueda general
	if search_input.text.strip_edges() != "":
		filtros["busqueda"] = search_input.text.strip_edges()
	
	# Filtro de estado
	var estado_seleccionado = estado_filter.get_selected_id()
	if estado_seleccionado > 0:
		var estado = AppState.estados_ticket[estado_seleccionado - 1]
		filtros["estado"] = estado
	
	# Filtro de técnico
	var tecnico_seleccionado = tecnico_filter.get_selected_id()
	if tecnico_seleccionado > 0:
		filtros["tecnico_id"] = tecnico_seleccionado
	
	# Aplicar filtros externos si los hay
	if filtros_actuales.size() > 0:
		for clave in filtros_actuales:
			filtros[clave] = filtros_actuales[clave]
	
	# Cargar datos
	tickets_data = DataService.buscar_tickets(filtros)
	actualizar_tree()
	actualizar_contador()

func actualizar_tree():
	tickets_tree.clear()
	var root = tickets_tree.create_item()
	
	# Definir colores por estado
	var colores_estados = {
		"Nuevo": Color(0.3, 0.6, 1.0),
		"Diagnosticando": Color(1.0, 0.8, 0.2),
		"Presupuestado": Color(0.8, 0.4, 1.0),
		"Aprobado": Color(0.2, 1.0, 0.6),
		"En reparación": Color(1.0, 0.6, 0.2),
		"En Reparación": Color(1.0, 0.6, 0.2),  # Alias
		"Pendiente": Color(0.8, 0.8, 0.2),      # Nuevo estado
		"En pruebas": Color(0.6, 1.0, 0.8),
		"Listo para entrega": Color(0.2, 0.8, 0.2),
		"Entregado": Color(0.7, 0.7, 0.7),
		"Rechazado": Color(1.0, 0.4, 0.4),
		"No reparable": Color(0.6, 0.6, 0.6)
	}
	
	for ticket_data in tickets_data:
		var item = tickets_tree.create_item(root)
		
		# Código - validar nil
		var codigo = ticket_data.get("codigo", "")
		item.set_text(0, str(codigo) if codigo != null else "Sin código")
		
		# Cliente - validar nil
		var cliente_nombre = ticket_data.get("cliente_nombre", "")
		item.set_text(1, str(cliente_nombre) if cliente_nombre != null else "Sin cliente")
		
		# Equipo (tipo + marca/modelo) - validar nil
		var equipo_tipo = ticket_data.get("equipo_tipo", "")
		var equipo = str(equipo_tipo) if equipo_tipo != null else "Sin especificar"
		
		var marca = ticket_data.get("equipo_marca", "")
		var modelo = ticket_data.get("equipo_modelo", "")
		
		# Convertir a string y validar
		var marca_str = str(marca) if marca != null else ""
		var modelo_str = str(modelo) if modelo != null else ""
		
		if marca_str != "" and marca_str != "null" and marca_str != "0":
			equipo += " " + marca_str
		if modelo_str != "" and modelo_str != "null" and modelo_str != "0":
			equipo += " " + modelo_str
		item.set_text(2, equipo)
		
		# Estado con color - validar nil
		var estado = ticket_data.get("estado", "")
		var estado_str = str(estado) if estado != null else "Sin estado"
		item.set_text(3, estado_str)
		if colores_estados.has(estado_str):
			item.set_custom_color(3, colores_estados[estado_str])
		
		# Técnico - validar nil
		var tecnico_nombre = ticket_data.get("tecnico_nombre", "Sin asignar")
		item.set_text(4, str(tecnico_nombre) if tecnico_nombre != null else "Sin asignar")
		
		# Fecha (solo la fecha, sin hora) - validar nil
		var fecha_entrada = ticket_data.get("fecha_entrada", "")
		if fecha_entrada != null and fecha_entrada != "":
			var fecha_parts = str(fecha_entrada).split(" ")
			if fecha_parts.size() > 0:
				item.set_text(5, fecha_parts[0])
			else:
				item.set_text(5, "Sin fecha")
		else:
			item.set_text(5, "Sin fecha")
		
		# Guardar ID del ticket como metadatos - validar nil
		var ticket_id = ticket_data.get("id", 0)
		item.set_metadata(0, int(ticket_id) if ticket_id != null else 0)
		
		# Inicializar columna de acciones
		item.set_text(6, "")  # Inicializar la columna 6 primero
		
		# Agregar botón azul de editar PRIMERO (será ID 0)
		if AppState.tiene_permiso("editar_ticket"):
			print("✅ [TICKETS_LIST] Añadiendo botón EDITAR (azul) para ticket ID: ", ticket_id)
			var texture_edit = ImageTexture.new()
			var image_edit = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			image_edit.fill(Color(0.3, 0.6, 1.0, 1))  # Azul para editar
			texture_edit.set_image(image_edit)
			
			item.add_button(6, texture_edit, 0, false, "Editar Ticket")
		
		# Agregar botón rojo de eliminar DESPUÉS (será ID 1)
		if AppState.tiene_permiso("eliminar_ticket"):
			print("✅ [TICKETS_LIST] Añadiendo botón ELIMINAR (rojo) para ticket ID: ", ticket_id)
			var texture_delete = ImageTexture.new()
			var image_delete = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			image_delete.fill(Color(1, 0.4, 0.4, 1))  # Rojo para eliminar
			texture_delete.set_image(image_delete)
			
			item.add_button(6, texture_delete, 1, false, "Eliminar Ticket")

func actualizar_contador():
	count_label.text = str(tickets_data.size()) + " ticket(s) encontrado(s)"

func _on_search_button_pressed():
	cargar_tickets()

func _on_search_input_text_submitted(_text: String):
	cargar_tickets()

func _on_estado_filter_item_selected(_index: int):
	cargar_tickets()

func _on_tecnico_filter_item_selected(_index: int):
	cargar_tickets()

func _on_refresh_button_pressed():
	cargar_tickets()

func _on_back_button_pressed():
	Router.ir_a_dashboard()

func _on_new_ticket_button_pressed():
	Router.ir_a_nuevo_ticket()

func _on_tickets_tree_item_activated():
	var selected = tickets_tree.get_selected()
	if selected:
		var ticket_id = selected.get_metadata(0)
		if ticket_id != null and int(ticket_id) > 0:
			Router.ir_a_ticket_detalle(int(ticket_id))

# Menú contextual para acciones de ticket
func _on_tickets_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int):
	# Si es clic en la columna de acciones (columna 6)
	if column == 6:
		var ticket_id = item.get_metadata(0)
		if ticket_id != null and int(ticket_id) > 0:
			if id == 0:  # ID 0 es el botón de editar (azul)
				print("🔵 [TICKETS_LIST] Clic en botón EDITAR - Ticket ID: ", ticket_id)
				Router.ir_a_editar_ticket(int(ticket_id))
				return
			elif id == 1:  # ID 1 es el botón de eliminar (rojo)
				print("🔴 [TICKETS_LIST] Clic en botón ELIMINAR - Ticket ID: ", ticket_id)
				confirmar_eliminar_ticket_directo(int(ticket_id))
				return
	
	# Si es clic derecho, mostrar menú contextual
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		mostrar_menu_contextual(item)

func mostrar_menu_contextual(item: TreeItem):
	var ticket_id = item.get_metadata(0)
	if ticket_id == null or int(ticket_id) <= 0:
		return
		
	var popup = PopupMenu.new()
	add_child(popup)
	
	popup.add_item("🔍 Ver Detalles", 0)
	popup.add_item("✏️ Editar", 1)  
	popup.add_separator()
	popup.add_item("🗑️ Eliminar", 2)
	
	# Configurar permisos
	if not AppState.tiene_permiso("editar_ticket"):
		popup.set_item_disabled(1, true)
	if not AppState.tiene_permiso("eliminar_ticket"):
		popup.set_item_disabled(2, true)
	
	# Conectar señal
	popup.id_pressed.connect(_on_menu_contextual_pressed.bind(ticket_id))
	
	# Mostrar en posición del mouse
	popup.position = get_global_mouse_position()
	popup.popup()

func _on_menu_contextual_pressed(id: int, ticket_id: int):
	match id:
		0: # Ver detalles
			Router.ir_a_ticket_detalle(ticket_id)
		1: # Editar  
			Router.ir_a_editar_ticket(ticket_id)
		2: # Eliminar
			confirmar_eliminar_ticket(ticket_id)

func confirmar_eliminar_ticket(ticket_id: int):
	var dialog = AcceptDialog.new()
	add_child(dialog)
	
	dialog.title = "Confirmar Eliminación"
	dialog.dialog_text = "¿Está seguro de que desea eliminar este ticket?\n\nEsta acción no se puede deshacer."
	
	# Agregar botón de cancelar
	dialog.add_cancel_button("Cancelar")
	dialog.get_ok_button().text = "Eliminar"
	
	dialog.confirmed.connect(_on_eliminar_confirmado.bind(ticket_id))
	dialog.popup_centered()

func _on_eliminar_confirmado(ticket_id: int):
	print("🗑️ [TICKETS_LIST] Eliminando ticket ID: ", ticket_id)
	
	var resultado = DataService.eliminar_ticket(ticket_id)
	if resultado:
		print("✅ [TICKETS_LIST] Ticket eliminado correctamente")
		# Mostrar notificación de éxito
		var notif = AcceptDialog.new()
		add_child(notif)
		notif.title = "Éxito"
		notif.dialog_text = "Ticket eliminado correctamente"
		notif.popup_centered()
		
		# Recargar lista
		cargar_tickets()
	else:
		print("❌ [TICKETS_LIST] Error al eliminar ticket")
		# Mostrar error
		var error = AcceptDialog.new()
		add_child(error)
		error.title = "Error"
		error.dialog_text = "No se pudo eliminar el ticket. Inténtelo de nuevo."
		error.popup_centered()

func confirmar_eliminar_ticket_directo(ticket_id: int):
	"""Confirma la eliminación directa de un ticket desde el botón de la lista"""
	print("🗑️ [TICKETS_LIST] Solicitud de eliminación directa del ticket ID: ", ticket_id)
	
	# Buscar datos del ticket para mostrar información en el diálogo
	var ticket_info = {}
	for ticket in tickets_data:
		if int(ticket.get("id", 0)) == ticket_id:
			ticket_info = ticket
			break
	
	var codigo = ticket_info.get("codigo", "Sin código")
	var cliente_nombre = ticket_info.get("cliente_nombre", "Sin cliente")
	
	var dialog = ConfirmationDialog.new()
	dialog.title = "⚠️ Confirmar Eliminación"
	dialog.dialog_text = "¿Está seguro de que desea ELIMINAR PERMANENTEMENTE este ticket?\n\n🎫 Código: %s\n👤 Cliente: %s\n\n⚠️ ESTA ACCIÓN NO SE PUEDE DESHACER" % [codigo, cliente_nombre]
	
	dialog.get_ok_button().text = "🗑️ ELIMINAR"
	dialog.get_ok_button().modulate = Color(1, 0.4, 0.4, 1)
	dialog.get_cancel_button().text = "❌ CANCELAR"
	
	dialog.confirmed.connect(func():
		_on_eliminar_confirmado(ticket_id)
		dialog.queue_free()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered(Vector2(500, 300))

# Configurar la pantalla con parámetros externos
func configurar(parametros: Dictionary):
	if parametros.has("filtros"):
		filtros_actuales = parametros.filtros
		
		# Aplicar filtros a la interfaz
		if filtros_actuales.has("estado"):
			var estado = filtros_actuales.estado
			var index = AppState.estados_ticket.find(estado)
			if index >= 0:
				estado_filter.select(index + 1)
	
	# Cargar datos con filtros aplicados
	if is_node_ready():
		cargar_tickets()

# Método para actualizar desde señales externas
func _on_ticket_guardado(_ticket_id: int):
	cargar_tickets()

func _ready_connections():
	# Conectar señales de DataService
	if DataService.ticket_guardado.connect(_on_ticket_guardado) != OK:
		print("Error conectando señal ticket_guardado")
