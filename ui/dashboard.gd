extends Control

# Pantalla principal del dashboard

@onready var user_label = $VBoxContainer/TopBar/UserLabel
@onready var tickets_hoy_value = $VBoxContainer/MainContainer/LeftPanel/KPIContainer/TicketsHoyPanel/VBox/Value
@onready var stock_bajo_value = $VBoxContainer/MainContainer/LeftPanel/KPIContainer/StockBajoPanel/VBox2/Value
@onready var estados_container = $VBoxContainer/MainContainer/CenterPanel/EstadosContainer
@onready var ultimos_tickets = $VBoxContainer/MainContainer/CenterPanel/UltimosTickets

# Referencias a botones para controlar permisos
@onready var inventario_btn = $VBoxContainer/MainContainer/LeftPanel/AccesosRapidos/InventarioBtn

var kpis_data: Dictionary = {}

func _ready():
	configurar_interfaz()
	cargar_datos()

func configurar_interfaz():
	# Mostrar nombre del usuario actual
	user_label.text = "Usuario: " + AppState.get_usuario_nombre() + " (" + AppState.usuario_actual.get("rol_nombre", "") + ")"
	
	# Configurar permisos de botones
	inventario_btn.visible = AppState.tiene_permiso("gestionar_inventario")
	
	# Solo administradores pueden gestionar empleados
	var empleados_btn = $VBoxContainer/MainContainer/LeftPanel/AccesosRapidos/EmpleadosBtn
	if empleados_btn:
		empleados_btn.visible = AppState.es_admin
	
	# Configurar tree de últimos tickets
	ultimos_tickets.set_column_title(0, "Código")
	ultimos_tickets.set_column_title(1, "Cliente") 
	ultimos_tickets.set_column_title(2, "Estado")
	ultimos_tickets.set_column_title(3, "Fecha")
	
	ultimos_tickets.set_column_custom_minimum_width(0, 120)
	ultimos_tickets.set_column_custom_minimum_width(1, 200)
	ultimos_tickets.set_column_custom_minimum_width(2, 120)
	ultimos_tickets.set_column_custom_minimum_width(3, 100)

func cargar_datos():
	# Cargar KPIs
	kpis_data = DataService.obtener_kpis_dashboard()
	actualizar_kpis()
	
	# Cargar estados de tickets
	cargar_estados_tickets()
	
	# Cargar últimos tickets
	cargar_ultimos_tickets()

func actualizar_kpis():
	tickets_hoy_value.text = str(kpis_data.get("tickets_hoy", 0))
	stock_bajo_value.text = str(kpis_data.get("productos_stock_bajo", 0))
	
	# Cambiar color si hay alertas
	if kpis_data.get("productos_stock_bajo", 0) > 0:
		stock_bajo_value.modulate = Color(1.0, 0.6, 0.0) # Naranja
	else:
		stock_bajo_value.modulate = Color.WHITE

func cargar_estados_tickets():
	# Limpiar container anterior
	for child in estados_container.get_children():
		child.queue_free()
	
	var estados_data = kpis_data.get("tickets_por_estado", {})
	
	# Definir colores por estado
	var colores_estados = {
		"Nuevo": Color(0.3, 0.6, 1.0),
		"Diagnosticando": Color(1.0, 0.8, 0.2),
		"Presupuestado": Color(0.8, 0.4, 1.0),
		"Aprobado": Color(0.2, 1.0, 0.6),
		"En reparación": Color(1.0, 0.6, 0.2),
		"En pruebas": Color(0.6, 1.0, 0.8),
		"Listo para entrega": Color(0.2, 0.8, 0.2),
		"Entregado": Color(0.7, 0.7, 0.7),
		"Rechazado": Color(1.0, 0.4, 0.4),
		"No reparable": Color(0.6, 0.6, 0.6)
	}
	
	for estado in AppState.estados_ticket:
		var cantidad = estados_data.get(estado, 0)
		
		# Crear panel para el estado
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(100, 80)
		
		# Aplicar color de fondo
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = colores_estados.get(estado, Color.GRAY)
		stylebox.corner_radius_top_left = 5
		stylebox.corner_radius_top_right = 5
		stylebox.corner_radius_bottom_left = 5
		stylebox.corner_radius_bottom_right = 5
		panel.add_theme_stylebox_override("panel", stylebox)
		
		# Crear contenido del panel
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.add_theme_constant_override("separation", 5)
		
		# Etiqueta del estado
		var label_estado = Label.new()
		label_estado.text = estado
		label_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(label_estado)
		
		# Valor de cantidad
		var label_cantidad = Label.new()
		label_cantidad.text = str(cantidad)
		label_cantidad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_cantidad.add_theme_font_size_override("font_size", 24)
		vbox.add_child(label_cantidad)
		
		# Hacer el panel clickeable si hay tickets
		if cantidad > 0:
			panel.gui_input.connect(_on_estado_panel_clicked.bind(estado))
		
		estados_container.add_child(panel)

func cargar_ultimos_tickets():
	ultimos_tickets.clear()
	var root = ultimos_tickets.create_item()
	
	# Obtener últimos 10 tickets
	var tickets = DataService.buscar_tickets({"limit": 10})
	
	for ticket_data in tickets:
		var item = ultimos_tickets.create_item(root)
		
		# Usar str() para convertir valores nil a string vacío
		var codigo = ticket_data.get("codigo", "")
		var cliente_nombre = ticket_data.get("cliente_nombre", "")
		var estado = ticket_data.get("estado", "")
		
		item.set_text(0, str(codigo) if codigo != null else "Sin código")
		item.set_text(1, str(cliente_nombre) if cliente_nombre != null else "Sin cliente")
		item.set_text(2, str(estado) if estado != null else "Sin estado")
		
		# Formatear fecha
		var fecha_entrada = ticket_data.get("fecha_entrada", "")
		if fecha_entrada != null and fecha_entrada != "":
			var fecha_parts = str(fecha_entrada).split(" ")
			if fecha_parts.size() > 0:
				item.set_text(3, fecha_parts[0])
		else:
			item.set_text(3, "Sin fecha")
		
		# Guardar ID del ticket como metadatos
		var ticket_id = ticket_data.get("id", 0)
		item.set_metadata(0, int(ticket_id) if ticket_id != null else 0)

func _on_estado_panel_clicked(estado: String, event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Navegar a lista de tickets filtrada por estado
		Router.ir_a_tickets({"estado": estado})

func _on_logout_button_pressed():
	AppState.logout()

func _on_nuevo_ticket_pressed():
	print("📋 [DASHBOARD] Abriendo nuevo ticket...")
	Router.ir_a_nuevo_ticket()

func _on_ver_tickets_pressed():
	print("🎫 [DASHBOARD] Abriendo lista de tickets...")
	Router.ir_a_tickets()

func _on_inventario_pressed():
	Router.ir_a_inventario()

func _on_clientes_pressed():
	Router.ir_a_clientes()

func _on_empleados_pressed():
	print("👨‍💼 [DASHBOARD] Navegando a gestión de empleados...")
	Router.ir_a_empleados()

func _on_ultimos_tickets_item_activated():
	var selected = ultimos_tickets.get_selected()
	if selected:
		var ticket_id = selected.get_metadata(0)
		if ticket_id > 0:
			Router.ir_a_ticket_detalle(ticket_id)

# Función para actualizar datos periódicamente
func _on_timer_timeout():
	cargar_datos()

func configurar(parametros: Dictionary):
	# Configuración de la pantalla con parámetros
	if parametros.has("actualizar"):
		cargar_datos()
