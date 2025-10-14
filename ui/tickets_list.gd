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
		
		# Agregar botón azul claro de imprimir HTML (será ID 1)
		if AppState.tiene_permiso("imprimir_ticket"):
			print("✅ [TICKETS_LIST] Añadiendo botón IMPRIMIR HTML (azul claro) para ticket ID: ", ticket_id)
			var texture_html = ImageTexture.new()
			var image_html = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			image_html.fill(Color(0.4, 0.8, 1.0, 1))  # Azul claro para HTML
			texture_html.set_image(image_html)
			
			item.add_button(6, texture_html, 1, false, "Imprimir en HTML")
		
		# Agregar botón amarillo de imprimir PDF (será ID 2)
		if AppState.tiene_permiso("imprimir_ticket"):
			print("✅ [TICKETS_LIST] Añadiendo botón IMPRIMIR PDF (amarillo) para ticket ID: ", ticket_id)
			var texture_pdf = ImageTexture.new()
			var image_pdf = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			image_pdf.fill(Color(1.0, 0.8, 0.2, 1))  # Amarillo para PDF
			texture_pdf.set_image(image_pdf)
			
			item.add_button(6, texture_pdf, 2, false, "Imprimir en PDF")

		# Agregar botón rojo de eliminar DESPUÉS (será ID 3)
		if AppState.tiene_permiso("eliminar_ticket"):
			print("✅ [TICKETS_LIST] Añadiendo botón ELIMINAR (rojo) para ticket ID: ", ticket_id)
			var texture_delete = ImageTexture.new()
			var image_delete = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			image_delete.fill(Color(1, 0.4, 0.4, 1))  # Rojo para eliminar
			texture_delete.set_image(image_delete)
			
			item.add_button(6, texture_delete, 3, false, "Eliminar Ticket")

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
			elif id == 1:  # ID 1 es el botón de imprimir HTML (azul claro)
				print("🌐 [TICKETS_LIST] Clic en botón IMPRIMIR HTML - Ticket ID: ", ticket_id)
				imprimir_ticket_html(int(ticket_id))
				return
			elif id == 2:  # ID 2 es el botón de imprimir PDF (amarillo)
				print("📄 [TICKETS_LIST] Clic en botón IMPRIMIR PDF - Ticket ID: ", ticket_id)
				imprimir_ticket_pdf(int(ticket_id))
				return
			elif id == 3:  # ID 3 es el botón de eliminar (rojo)
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
	popup.add_item("🌐 Imprimir HTML", 2)
	popup.add_item("📄 Imprimir PDF", 3)
	popup.add_separator()
	popup.add_item("🗑️ Eliminar", 4)
	
	# Configurar permisos
	if not AppState.tiene_permiso("editar_ticket"):
		popup.set_item_disabled(1, true)
	if not AppState.tiene_permiso("imprimir_ticket"):
		popup.set_item_disabled(2, true)  # Imprimir HTML
		popup.set_item_disabled(3, true)  # Imprimir PDF
	if not AppState.tiene_permiso("eliminar_ticket"):
		popup.set_item_disabled(4, true)  # Eliminar
	
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
		2: # Imprimir HTML
			imprimir_ticket_html(ticket_id)
		3: # Imprimir PDF
			imprimir_ticket_pdf(ticket_id)
		4: # Eliminar
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

# === FUNCIONES DE IMPRESIÓN ===

func imprimir_ticket_html(ticket_id: int):
	"""Generar e imprimir ticket en formato HTML"""
	print("🌐 [TICKETS_LIST] Generando impresión HTML para ticket ID: ", ticket_id)
	
	# Obtener datos del ticket
	var ticket_data = DataService.obtener_ticket_por_id(ticket_id)
	if ticket_data.is_empty():
		mostrar_error("No se pudo obtener los datos del ticket para imprimir")
		return
	
	# Generar HTML
	var html_content = generar_html_ticket(ticket_data)
	
	# Guardar archivo temporal HTML
	var temp_path = "user://temp_ticket_%d.html" % ticket_id
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if file:
		file.store_string(html_content)
		file.close()
		print("✅ [TICKETS_LIST] Archivo HTML generado en: ", temp_path)
		
		# Mostrar confirmación y abrir
		var dialog = AcceptDialog.new()
		dialog.title = "🌐 Ticket HTML Generado"
		dialog.dialog_text = "El ticket ha sido generado en formato HTML.\n\nRuta: %s\n\n¿Desea abrirlo en el navegador?" % temp_path
		
		dialog.confirmed.connect(func():
			OS.shell_open(ProjectSettings.globalize_path(temp_path))
			dialog.queue_free()
		)
		
		add_child(dialog)
		dialog.popup_centered(Vector2(500, 250))
	else:
		mostrar_error("Error al crear el archivo HTML")

func imprimir_ticket_pdf(ticket_id: int):
	"""Generar e imprimir ticket en formato PDF"""
	print("📄 [TICKETS_LIST] Generando impresión PDF para ticket ID: ", ticket_id)
	
	# Obtener datos del ticket
	var ticket_data = DataService.obtener_ticket_por_id(ticket_id)
	if ticket_data.is_empty():
		mostrar_error("No se pudo obtener los datos del ticket para imprimir")
		return
	
	# Por ahora, generar HTML y mostrar opción de conversión a PDF
	var html_content = generar_html_ticket(ticket_data)
	
	# Guardar archivo temporal HTML para conversión
	var temp_path = "user://temp_ticket_for_pdf_%d.html" % ticket_id
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if file:
		file.store_string(html_content)
		file.close()
		print("✅ [TICKETS_LIST] Archivo HTML para PDF generado en: ", temp_path)
		
		# Mostrar diálogo con instrucciones para PDF
		var dialog = AcceptDialog.new()
		dialog.title = "📄 Generar PDF"
		dialog.dialog_text = """El ticket ha sido preparado para conversión a PDF.

📝 INSTRUCCIONES:
1. Se abrirá el archivo HTML en su navegador
2. Use Ctrl+P o 'Imprimir'
3. Seleccione 'Guardar como PDF' como destino
4. Elija la ubicación y guarde

¿Desea abrir el archivo HTML ahora?"""
		
		dialog.confirmed.connect(func():
			OS.shell_open(ProjectSettings.globalize_path(temp_path))
			dialog.queue_free()
		)
		
		add_child(dialog)
		dialog.popup_centered(Vector2(600, 300))
	else:
		mostrar_error("Error al crear el archivo HTML para PDF")

func generar_html_ticket(ticket_data: Dictionary) -> String:
	"""Genera el contenido HTML del ticket"""
	var codigo = ticket_data.get("codigo", "Sin código")
	var fecha_entrada = ticket_data.get("fecha_entrada", "")
	var estado = ticket_data.get("estado", "")
	var prioridad = ticket_data.get("prioridad", "")
	
	# Datos del cliente
	var cliente_nombre = ticket_data.get("cliente_nombre", "Sin nombre")
	var cliente_telefono = ticket_data.get("cliente_telefono", "")
	var cliente_email = ticket_data.get("cliente_email", "")
	var cliente_nif = ticket_data.get("cliente_nif", "")
	var cliente_direccion = ticket_data.get("cliente_direccion", "")
	
	# Datos del equipo
	var equipo_tipo = ticket_data.get("equipo_tipo", "")
	var equipo_marca = ticket_data.get("equipo_marca", "")
	var equipo_modelo = ticket_data.get("equipo_modelo", "")
	var numero_serie = ticket_data.get("numero_serie", "")
	var password_bloqueo = ticket_data.get("password_bloqueo", "")
	var accesorios = ticket_data.get("accesorios", "")
	
	# Descripciones
	var averia_cliente = ticket_data.get("averia_cliente", "")
	var notas_cliente = ticket_data.get("notas_cliente", "")
	var diagnostico = ticket_data.get("diagnostico", "")
	
	# Técnico asignado
	var tecnico_nombre = ticket_data.get("tecnico_nombre", "Sin asignar")
	
	var html = """<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Ticket SAT - %s</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .ticket { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 800px; margin: 0 auto; }
        .header { text-align: center; border-bottom: 3px solid #2196F3; padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { color: #2196F3; margin: 0; font-size: 28px; }
        .header h2 { color: #666; margin: 5px 0 0 0; font-size: 16px; }
        .section { margin-bottom: 25px; }
        .section h3 { background: #2196F3; color: white; padding: 10px 15px; margin: 0 0 15px 0; border-radius: 5px; font-size: 16px; }
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 15px; }
        .info-item { display: flex; }
        .info-label { font-weight: bold; min-width: 120px; color: #333; }
        .info-value { color: #555; }
        .full-width { grid-column: 1 / -1; }
        .textarea-field { background: #f9f9f9; border: 1px solid #ddd; border-radius: 4px; padding: 10px; min-height: 80px; white-space: pre-wrap; }
        .status-badge { padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: bold; color: white; }
        .status-nuevo { background: #4CAF50; }
        .status-proceso { background: #FF9800; }
        .status-finalizado { background: #2196F3; }
        .priority-normal { color: #2196F3; }
        .priority-alta { color: #FF5722; }
        .priority-critica { color: #F44336; font-weight: bold; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 2px solid #eee; color: #666; font-size: 14px; }
        @media print {
            body { background: white; margin: 0; }
            .ticket { box-shadow: none; margin: 0; }
        }
    </style>
</head>
<body>
    <div class="ticket">
        <div class="header">
            <h1>🔧 TICKET DE SERVICIO TÉCNICO</h1>
            <h2>Mi Tienda SAT - Reparación y Mantenimiento</h2>
        </div>
        
        <div class="section">
            <h3>📋 Información General</h3>
            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">Código:</span>
                    <span class="info-value"><strong>%s</strong></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Fecha Entrada:</span>
                    <span class="info-value">%s</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Estado:</span>
                    <span class="info-value"><span class="status-badge status-%s">%s</span></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Prioridad:</span>
                    <span class="info-value priority-%s">%s</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Técnico:</span>
                    <span class="info-value">%s</span>
                </div>
            </div>
        </div>

        <div class="section">
            <h3>👤 Datos del Cliente</h3>
            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">Nombre:</span>
                    <span class="info-value"><strong>%s</strong></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Teléfono:</span>
                    <span class="info-value">%s</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Email:</span>
                    <span class="info-value">%s</span>
                </div>
                <div class="info-item">
                    <span class="info-label">NIF:</span>
                    <span class="info-value">%s</span>
                </div>
                <div class="info-item full-width">
                    <span class="info-label">Dirección:</span>
                    <span class="info-value">%s</span>
                </div>
            </div>
        </div>

        <div class="section">
            <h3>💻 Datos del Equipo</h3>
            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">Tipo:</span>
                    <span class="info-value">%s</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Marca:</span>
                    <span class="info-value">%s</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Modelo:</span>
                    <span class="info-value">%s</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Nº Serie:</span>
                    <span class="info-value">%s</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Password:</span>
                    <span class="info-value">%s</span>
                </div>
                <div class="info-item full-width">
                    <span class="info-label">Accesorios:</span>
                    <span class="info-value">%s</span>
                </div>
            </div>
        </div>

        <div class="section">
            <h3>🔧 Descripción de la Avería</h3>
            <div class="info-item full-width">
                <span class="info-label">Avería reportada:</span>
            </div>
            <div class="textarea-field">%s</div>
            
            <div class="info-item full-width" style="margin-top: 15px;">
                <span class="info-label">Notas del cliente:</span>
            </div>
            <div class="textarea-field">%s</div>
            
            <div class="info-item full-width" style="margin-top: 15px;">
                <span class="info-label">Diagnóstico técnico:</span>
            </div>
            <div class="textarea-field">%s</div>
        </div>

        <div class="footer">
            <p><strong>Mi Tienda SAT</strong> | Servicio Técnico Especializado</p>
            <p>Documento generado automáticamente el %s</p>
        </div>
    </div>
</body>
</html>""" % [
		codigo, codigo, fecha_entrada, estado.to_lower(), estado, prioridad.to_lower(), prioridad, tecnico_nombre,
		cliente_nombre, cliente_telefono, cliente_email, cliente_nif, cliente_direccion,
		equipo_tipo, equipo_marca, equipo_modelo, numero_serie, password_bloqueo, accesorios,
		averia_cliente, notas_cliente, diagnostico,
		Time.get_datetime_string_from_system()
	]
	
	return html

func mostrar_error(mensaje: String):
	"""Muestra un diálogo de error"""
	var error = AcceptDialog.new()
	error.title = "❌ Error"
	error.dialog_text = mensaje
	add_child(error)
	error.popup_centered()
	error.confirmed.connect(func(): error.queue_free())
