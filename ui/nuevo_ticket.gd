extends Control

# Pantalla para crear un nuevo ticket SAT

# Referencias a elementos del header
@onready var title_label: Label = $"MainContainer/HeaderPanel/HeaderContent/LeftHeader/TitleLabel"
@onready var subtitle_label: Label = $"MainContainer/HeaderPanel/HeaderContent/LeftHeader/SubtitleLabel"

# Referencias a nodos - Nueva estructura con TabContainer
@onready var buscar_cliente_input: LineEdit = $"MainContainer/TabContainer/👤 CLIENTE/ClienteVBox/BuscarClientePanel/BuscarClienteContent/BuscarContainer/BuscarClienteInput"
@onready var cliente_label: Label = $"MainContainer/TabContainer/👤 CLIENTE/ClienteVBox/ClienteSeleccionadoPanel/ClienteContent/ClienteLabel"
@onready var cliente_telefono: Label = $"MainContainer/TabContainer/👤 CLIENTE/ClienteVBox/ClienteSeleccionadoPanel/ClienteContent/ClienteTelefono"
@onready var cliente_email: Label = $"MainContainer/TabContainer/👤 CLIENTE/ClienteVBox/ClienteSeleccionadoPanel/ClienteContent/ClienteEmail"
@onready var cliente_nif: Label = $"MainContainer/TabContainer/👤 CLIENTE/ClienteVBox/ClienteSeleccionadoPanel/ClienteContent/ClienteNIF"
@onready var cliente_direccion: Label = $"MainContainer/TabContainer/👤 CLIENTE/ClienteVBox/ClienteSeleccionadoPanel/ClienteContent/ClienteDireccion"

# Equipo
@onready var tipo_option: OptionButton = $"MainContainer/TabContainer/💻 EQUIPO/EquipoVBox/DatosEquipoPanel/EquipoContent/EquipoGrid/TipoOption"
@onready var marca_input: LineEdit = $"MainContainer/TabContainer/💻 EQUIPO/EquipoVBox/DatosEquipoPanel/EquipoContent/EquipoGrid/MarcaInput"
@onready var modelo_input: LineEdit = $"MainContainer/TabContainer/💻 EQUIPO/EquipoVBox/DatosEquipoPanel/EquipoContent/EquipoGrid/ModeloInput"
@onready var serie_input: LineEdit = $"MainContainer/TabContainer/💻 EQUIPO/EquipoVBox/DatosEquipoPanel/EquipoContent/EquipoGrid/SerieInput"
@onready var accesorios_input: TextEdit = $"MainContainer/TabContainer/💻 EQUIPO/EquipoVBox/DatosEquipoPanel/EquipoContent/AccesoriosInput"
@onready var password_input: LineEdit = $"MainContainer/TabContainer/💻 EQUIPO/EquipoVBox/DatosEquipoPanel/EquipoContent/EquipoGrid/PasswordInput"

# Ticket
@onready var codigo_value: Label = $"MainContainer/TabContainer/🎫 TICKET/TicketVBox/DatosTicketPanel/TicketContent/TicketGrid/CodigoValue"
@onready var prioridad_option: OptionButton = $"MainContainer/TabContainer/🎫 TICKET/TicketVBox/DatosTicketPanel/TicketContent/TicketGrid/PrioridadOption"
@onready var tecnico_option: OptionButton = $"MainContainer/TabContainer/🎫 TICKET/TicketVBox/DatosTicketPanel/TicketContent/TicketGrid/TecnicoOption"

# Avería
@onready var averia_input: TextEdit = $"MainContainer/TabContainer/🔧 AVERÍA/AveriaVBox/DescripcionPanel/DescripcionContent/AveriaInput"
@onready var notas_input: TextEdit = $"MainContainer/TabContainer/🔧 AVERÍA/AveriaVBox/NotasPanel/NotasContent/NotasInput"

# Status
@onready var error_label: Label = $MainContainer/StatusPanel/StatusContent/ErrorLabel

# Datos del formulario
var cliente_seleccionado: Dictionary = {}
var clientes_disponibles: Array = []
var tecnicos_disponibles: Array = []

# Variables de control de edición
var modo_edicion: bool = false
var ticket_id_edicion: int = 0
var ticket_data: Dictionary = {}

# Popup para buscar clientes
var popup_clientes: AcceptDialog

func _ready():
	print("📋 [NUEVO_TICKET] Inicializando formulario...")
	
	# Configurar opciones
	configurar_tipos_equipo()
	configurar_prioridades()
	cargar_tecnicos()
	
	# Generar código de ticket
	codigo_value.text = AppState.generar_codigo_ticket()
	
	# Configurar búsqueda de clientes
	configurar_busqueda_clientes()
	
	# Limpiar estado
	limpiar_formulario()
	
	print("✅ [NUEVO_TICKET] Formulario listo")

func configurar(parametros: Dictionary = {}):
	"""Configura el formulario con parámetros externos (como edición)"""
	print("⚙️ [NUEVO_TICKET] Configurando con parámetros: ", parametros)
	
	if parametros.has("ticket_id") and parametros.has("modo"):
		if parametros.modo == "editar":
			print("✏️ [NUEVO_TICKET] Configurando modo edición para ticket: ", parametros.ticket_id)
			modo_edicion = true
			ticket_id_edicion = parametros.ticket_id
			configurar_modo_edicion()
			cargar_datos_ticket_para_editar()

func configurar_modo_edicion():
	"""Configura la interfaz para modo edición"""
	print("🎨 [NUEVO_TICKET] Configurando interfaz para modo EDICIÓN")
	
	# Cambiar título y subtítulo
	title_label.text = "📝 EDITAR TICKET SAT"
	subtitle_label.text = "Modifique los campos necesarios para actualizar el ticket"
	
	print("✅ [NUEVO_TICKET] Modo edición configurado")

func cargar_datos_ticket_para_editar():
	"""Carga los datos del ticket para edición"""
	print("📂 [NUEVO_TICKET] Cargando datos del ticket para editar ID: ", ticket_id_edicion)
	
	ticket_data = DataService.obtener_ticket_por_id(ticket_id_edicion)
	
	if ticket_data.is_empty():
		mostrar_error("No se pudo cargar el ticket para editar")
		return
	
	print("✅ [NUEVO_TICKET] Datos del ticket cargados: ", ticket_data.get("codigo", ""))
	
	# Rellenar formulario con datos del ticket
	rellenar_formulario_con_ticket()

func rellenar_formulario_con_ticket():
	"""Rellena el formulario con los datos del ticket cargado"""
	print("🎫 [NUEVO_TICKET] ===== RELLENANDO FORMULARIO =====")
	print("🎫 [NUEVO_TICKET] ticket_data: ", ticket_data)
	
	if ticket_data.is_empty():
		print("❌ [NUEVO_TICKET] ticket_data está vacío")
		return
	
	# Información del ticket
	var codigo = ticket_data.get("codigo")
	codigo_value.text = "" if codigo == null else str(codigo)
	print("🎫 [NUEVO_TICKET] Código: ", codigo_value.text)
	
	# Buscar y seleccionar prioridad
	var prioridad_texto = ticket_data.get("prioridad", "Normal")
	for i in range(prioridad_option.get_item_count()):
		if prioridad_option.get_item_text(i) == prioridad_texto:
			prioridad_option.selected = i
			break
	
	# Buscar y seleccionar técnico si está asignado
	print("🎫 [NUEVO_TICKET] Verificando técnico_id...")
	print("🎫 [NUEVO_TICKET] - tiene tecnico_id: ", ticket_data.has("tecnico_id"))
	if ticket_data.has("tecnico_id"):
		print("🎫 [NUEVO_TICKET] - tecnico_id valor: ", ticket_data.tecnico_id, " (tipo: ", typeof(ticket_data.tecnico_id), ")")
	
	if ticket_data.has("tecnico_id") and ticket_data.tecnico_id != null and int(ticket_data.tecnico_id) > 0:
		var tecnico_id = int(ticket_data.tecnico_id)
		print("🎫 [NUEVO_TICKET] Seleccionando técnico ID: ", tecnico_id)
		for i in range(tecnico_option.get_item_count()):
			if tecnico_option.get_item_id(i) == tecnico_id:
				tecnico_option.selected = i
				print("✅ [NUEVO_TICKET] Técnico seleccionado en índice: ", i)
				break
	else:
		print("🎫 [NUEVO_TICKET] Sin técnico asignado o tecnico_id inválido")
	
	# Datos del cliente
	if ticket_data.has("cliente_id") and ticket_data.cliente_id != null:
		var cliente_data = {
			"id": ticket_data.cliente_id,
			"nombre": ticket_data.get("cliente_nombre", ""),
			"telefono": ticket_data.get("cliente_telefono", ""),
			"email": ticket_data.get("cliente_email", ""),
			"nif": ticket_data.get("cliente_nif", ""),
			"direccion": ticket_data.get("cliente_direccion", "")
		}
		cliente_seleccionado = cliente_data
		print("👤 [NUEVO_TICKET] Cliente seleccionado configurado: ", cliente_seleccionado)
		actualizar_interfaz_cliente()
	
	# Datos del equipo
	var tipo_texto = ticket_data.get("equipo_tipo", "PC")
	for i in range(tipo_option.get_item_count()):
		if tipo_option.get_item_text(i) == tipo_texto:
			tipo_option.selected = i
			break
	
	var equipo_marca = ticket_data.get("equipo_marca")
	marca_input.text = "" if equipo_marca == null else str(equipo_marca)
	
	var equipo_modelo = ticket_data.get("equipo_modelo")
	modelo_input.text = "" if equipo_modelo == null else str(equipo_modelo)
	
	var numero_serie = ticket_data.get("numero_serie")
	serie_input.text = "" if numero_serie == null else str(numero_serie)
	
	var password_bloqueo = ticket_data.get("password_bloqueo")
	password_input.text = "" if password_bloqueo == null else str(password_bloqueo)
	
	var accesorios = ticket_data.get("accesorios")
	accesorios_input.text = "" if accesorios == null else str(accesorios)
	
	# Descripción de avería
	var averia_cliente = ticket_data.get("averia_cliente")
	averia_input.text = "" if averia_cliente == null else str(averia_cliente)
	
	var notas_cliente = ticket_data.get("notas_cliente")
	notas_input.text = "" if notas_cliente == null else str(notas_cliente)
	
	print("✅ [NUEVO_TICKET] Formulario rellenado con datos del ticket")

func configurar_tipos_equipo():
	tipo_option.clear()
	for tipo in AppState.tipos_equipo:
		tipo_option.add_item(tipo)
	
	# Seleccionar PC por defecto
	tipo_option.selected = 0

func configurar_prioridades():
	prioridad_option.clear()
	for prioridad in AppState.prioridades:
		prioridad_option.add_item(prioridad)
	
	# Seleccionar NORMAL por defecto
	prioridad_option.selected = 1

func cargar_tecnicos():
	print("👥 [NUEVO_TICKET] Cargando técnicos...")
	
	tecnico_option.clear()
	tecnico_option.add_item("Sin asignar", -1)
	
	# Obtener técnicos disponibles
	tecnicos_disponibles = DataService.obtener_tecnicos()
	
	for tecnico in tecnicos_disponibles:
		tecnico_option.add_item(tecnico.nombre, tecnico.id)
	
	print("✅ [NUEVO_TICKET] Técnicos cargados: ", tecnicos_disponibles.size())
	
	# Si no hay técnicos, crear algunos de prueba
	if tecnicos_disponibles.size() == 0:
		crear_datos_prueba()
	
	# También verificar si hay clientes disponibles
	verificar_datos_iniciales()

func configurar_busqueda_clientes():
	# Ya no usamos búsqueda automática, solo el botón de buscar
	print("📋 [NUEVO_TICKET] Búsqueda configurada para usar popup de selección")

func buscar_clientes_auto():
	var busqueda = buscar_cliente_input.text.strip_edges()
	if busqueda.length() < 2:
		return
	
	print("🔍 [NUEVO_TICKET] Buscando clientes: ", busqueda)
	
	clientes_disponibles = DataService.buscar_clientes(busqueda)
	
	if clientes_disponibles.size() == 1:
		# Auto-seleccionar si solo hay un resultado
		seleccionar_cliente(clientes_disponibles[0])
	elif clientes_disponibles.size() > 1:
		# Mostrar lista para elegir
		mostrar_popup_clientes()

func mostrar_popup_clientes():
	if popup_clientes:
		popup_clientes.queue_free()
	
	popup_clientes = AcceptDialog.new()
	popup_clientes.title = "👤 SELECCIONAR CLIENTE (" + str(clientes_disponibles.size()) + " disponibles)"
	popup_clientes.size = Vector2(700, 500)
	popup_clientes.get_ok_button().text = "❌ Cancelar"
	
	# Contenedor principal
	var main_container = VBoxContainer.new()
	popup_clientes.add_child(main_container)
	
	# Filtro de búsqueda en el popup
	var filtro_container = HBoxContainer.new()
	main_container.add_child(filtro_container)
	
	var filtro_label = Label.new()
	filtro_label.text = "🔍 Filtrar:"
	filtro_container.add_child(filtro_label)
	
	var filtro_input = LineEdit.new()
	filtro_input.placeholder_text = "Escriba para filtrar la lista..."
	filtro_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filtro_container.add_child(filtro_input)
	
	# Separador
	var separator = HSeparator.new()
	main_container.add_child(separator)
	
	# Scroll para la lista
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_container.add_child(scroll)
	
	var lista = VBoxContainer.new()
	lista.name = "ListaClientes"
	scroll.add_child(lista)
	
	# Función para actualizar la lista filtrada
	var actualizar_lista = func(filtro_texto: String = ""):
		# Limpiar lista actual
		for child in lista.get_children():
			child.queue_free()
		
		var clientes_filtrados = clientes_disponibles
		
		# Aplicar filtro si hay texto
		if filtro_texto.strip_edges() != "":
			clientes_filtrados = []
			var filtro_lower = filtro_texto.to_lower()
			for cliente in clientes_disponibles:
				var nombre = str(cliente.get("nombre", "")).to_lower()
				var telefono = str(cliente.get("telefono", "")).to_lower()
				var email = str(cliente.get("email", "")).to_lower()
				
				if (nombre.contains(filtro_lower) or 
					telefono.contains(filtro_lower) or 
					email.contains(filtro_lower)):
					clientes_filtrados.append(cliente)
		
		# Crear botones para clientes filtrados
		for cliente in clientes_filtrados:
			var cliente_panel = Panel.new()
			cliente_panel.custom_minimum_size = Vector2(0, 80)
			
			# Estilo del panel
			var style_box = StyleBoxFlat.new()
			style_box.bg_color = Color(0.2, 0.2, 0.2, 1)
			style_box.border_width_left = 2
			style_box.border_width_top = 2
			style_box.border_width_right = 2
			style_box.border_width_bottom = 2
			style_box.border_color = Color(0.4, 0.6, 0.9, 1)
			style_box.corner_radius_top_left = 6
			style_box.corner_radius_top_right = 6
			style_box.corner_radius_bottom_right = 6
			style_box.corner_radius_bottom_left = 6
			cliente_panel.add_theme_stylebox_override("panel", style_box)
			
			# Botón invisible que cubre todo el panel
			var btn = Button.new()
			btn.flat = true
			btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			btn.pressed.connect(func(): 
				seleccionar_cliente(cliente)
				popup_clientes.hide()
			)
			cliente_panel.add_child(btn)
			
			# Contenido del panel
			var hbox = HBoxContainer.new()
			hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			hbox.offset_left = 15
			hbox.offset_top = 10
			hbox.offset_right = -15
			hbox.offset_bottom = -10
			cliente_panel.add_child(hbox)
			
			# Información del cliente
			var info_vbox = VBoxContainer.new()
			info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(info_vbox)
			
			# Nombre
			var nombre_label = Label.new()
			var cliente_nombre = str(cliente.get("nombre", "Sin nombre")) if cliente.get("nombre") != null else "Sin nombre"
			nombre_label.text = "👤 " + cliente_nombre
			nombre_label.add_theme_font_size_override("font_size", 16)
			nombre_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1, 1))
			info_vbox.add_child(nombre_label)
			
			# Teléfono y Email
			var contacto_label = Label.new()
			var cliente_telefono = str(cliente.get("telefono", "-")) if cliente.get("telefono") != null else "-"
			var cliente_email = str(cliente.get("email", "-")) if cliente.get("email") != null else "-"
			contacto_label.text = "📞 " + cliente_telefono + "  ✉️ " + cliente_email
			contacto_label.add_theme_font_size_override("font_size", 14)
			info_vbox.add_child(contacto_label)
			
			# Seleccionar botón
			var seleccionar_btn = Button.new()
			seleccionar_btn.text = "✅ SELECCIONAR"
			seleccionar_btn.custom_minimum_size = Vector2(120, 30)
			seleccionar_btn.pressed.connect(func(): 
				seleccionar_cliente(cliente)
				popup_clientes.hide()
			)
			hbox.add_child(seleccionar_btn)
			
			lista.add_child(cliente_panel)
	
	# Conectar filtro
	filtro_input.text_changed.connect(actualizar_lista)
	
	# Llenar lista inicial
	actualizar_lista.call()
	
	add_child(popup_clientes)
	popup_clientes.popup_centered()
	
	# Enfocar el campo de filtro
	await get_tree().process_frame
	filtro_input.grab_focus()

func seleccionar_cliente(cliente: Dictionary):
	cliente_seleccionado = cliente
	
	var nombre = str(cliente.get("nombre", "Sin nombre")) if cliente.get("nombre") != null else "Sin nombre"
	var telefono = str(cliente.get("telefono", "-")) if cliente.get("telefono") != null else "-"
	var email = str(cliente.get("email", "-")) if cliente.get("email") != null else "-"
	var nif = str(cliente.get("nif", "-")) if cliente.get("nif") != null else "-"
	var direccion = str(cliente.get("direccion", "-")) if cliente.get("direccion") != null else "-"
	
	cliente_label.text = "Nombre: " + nombre
	cliente_telefono.text = "Teléfono: " + telefono
	cliente_email.text = "Email: " + email
	cliente_nif.text = "NIF: " + nif
	cliente_direccion.text = "Dirección: " + direccion
	
	buscar_cliente_input.text = nombre
	
	print("✅ [NUEVO_TICKET] Cliente seleccionado: ", cliente.get("nombre", "Sin nombre"))

func actualizar_interfaz_cliente():
	"""Actualiza la interfaz con la información del cliente seleccionado"""
	if cliente_seleccionado.is_empty():
		cliente_label.text = "Nombre: Ningún cliente seleccionado"
		cliente_telefono.text = "Teléfono: -"
		cliente_email.text = "Email: -"
		cliente_nif.text = "NIF: -"
		cliente_direccion.text = "Dirección: -"
		buscar_cliente_input.text = ""
	else:
		var nombre = str(cliente_seleccionado.get("nombre", "Sin nombre")) if cliente_seleccionado.get("nombre") != null else "Sin nombre"
		var telefono = str(cliente_seleccionado.get("telefono", "-")) if cliente_seleccionado.get("telefono") != null else "-"
		var email = str(cliente_seleccionado.get("email", "-")) if cliente_seleccionado.get("email") != null else "-"
		var nif = str(cliente_seleccionado.get("nif", "-")) if cliente_seleccionado.get("nif") != null else "-"
		var direccion = str(cliente_seleccionado.get("direccion", "-")) if cliente_seleccionado.get("direccion") != null else "-"
		
		cliente_label.text = "Nombre: " + nombre
		cliente_telefono.text = "Teléfono: " + telefono
		cliente_email.text = "Email: " + email
		cliente_nif.text = "NIF: " + nif
		cliente_direccion.text = "Dirección: " + direccion
		buscar_cliente_input.text = nombre

func limpiar_formulario():
	# Limpiar cliente
	cliente_seleccionado.clear()
	cliente_label.text = "Nombre: Ningún cliente seleccionado"
	cliente_telefono.text = "Teléfono: -"
	cliente_email.text = "Email: -"
	cliente_nif.text = "NIF: -"
	cliente_direccion.text = "Dirección: -"
	buscar_cliente_input.text = ""
	
	# Limpiar equipo
	tipo_option.selected = 0
	marca_input.text = ""
	modelo_input.text = ""
	serie_input.text = ""
	accesorios_input.text = ""
	password_input.text = ""
	
	# Limpiar ticket
	prioridad_option.selected = 1
	tecnico_option.selected = 0
	
	# Limpiar avería
	averia_input.text = ""
	notas_input.text = ""
	
	# Limpiar errores
	error_label.text = ""

func validar_formulario() -> bool:
	var errores = []
	
	# Validar cliente
	if cliente_seleccionado.is_empty():
		errores.append("Debe seleccionar un cliente")
	
	# Validar tipo de equipo
	if tipo_option.selected == -1:
		errores.append("Debe seleccionar el tipo de equipo")
	
	# Validar descripción de avería
	if averia_input.text.strip_edges() == "":
		errores.append("Debe describir la avería")
	
	# Mostrar errores
	if errores.size() > 0:
		error_label.text = "Error: " + " • ".join(errores)
		return false
	
	error_label.text = ""
	return true

func crear_ticket() -> Dictionary:
	var nuevo_ticket_data = {
		"cliente_id": cliente_seleccionado.id,
		"estado": "Nuevo",
		"prioridad": AppState.prioridades[prioridad_option.selected],
		"equipo_tipo": AppState.tipos_equipo[tipo_option.selected],
		"equipo_marca": marca_input.text.strip_edges(),
		"equipo_modelo": modelo_input.text.strip_edges(),
		"numero_serie": serie_input.text.strip_edges(),
		"accesorios": accesorios_input.text.strip_edges(),
		"password_bloqueo": password_input.text,
		"averia_cliente": averia_input.text.strip_edges(),
		"notas_cliente": notas_input.text.strip_edges(),
		"fecha_entrada": Time.get_datetime_string_from_system()
	}
	
	# Técnico asignado (opcional)
	if tecnico_option.selected > 0:
		nuevo_ticket_data["tecnico_id"] = tecnico_option.get_item_id(tecnico_option.selected)
	
	return nuevo_ticket_data

# === EVENTOS ===

func _on_guardar_pressed():
	print("💾 [NUEVO_TICKET] Guardando ticket...")
	
	if not validar_formulario():
		return
	
	if modo_edicion:
		actualizar_ticket_existente()
	else:
		crear_nuevo_ticket()

func crear_nuevo_ticket():
	"""Crea un nuevo ticket"""
	print("🆕 [NUEVO_TICKET] Creando nuevo ticket...")
	
	var ticket_data_new = crear_ticket()
	var ticket_id = DataService.guardar_ticket(ticket_data_new)
	
	if ticket_id > 0:
		print("✅ [NUEVO_TICKET] Ticket creado con ID: ", ticket_id)
		
		# Registrar en historial
		DataService.agregar_historial_ticket(
			ticket_id, 
			AppState.get_usuario_id(), 
			"creacion", 
			"Ticket creado por " + AppState.get_usuario_nombre()
		)
		
		# Mostrar confirmación de éxito y preguntar qué hacer
		mostrar_confirmacion_exito(ticket_id, codigo_value.text)
	else:
		error_label.text = "Error al guardar el ticket"

func actualizar_ticket_existente():
	"""Actualiza un ticket existente"""
	print("✏️ [NUEVO_TICKET] Actualizando ticket ID: ", ticket_id_edicion)
	
	var ticket_data_actualizado = crear_ticket()
	ticket_data_actualizado["id"] = ticket_id_edicion
	
	var exito = DataService.actualizar_ticket(ticket_data_actualizado)
	
	if exito:
		print("✅ [NUEVO_TICKET] Ticket actualizado correctamente")
		
		# Registrar en historial
		DataService.agregar_historial_ticket(
			ticket_id_edicion, 
			AppState.get_usuario_id(), 
			"actualizacion", 
			"Ticket actualizado por " + AppState.get_usuario_nombre()
		)
		
		# Mostrar confirmación y volver
		mostrar_confirmacion_actualizacion()
	else:
		error_label.text = "Error al actualizar el ticket"

func mostrar_confirmacion_actualizacion():
	"""Muestra confirmación de actualización y vuelve al detalle del ticket"""
	var dialog = AcceptDialog.new()
	dialog.title = "Ticket Actualizado"
	dialog.dialog_text = "El ticket ha sido actualizado correctamente."
	
	dialog.confirmed.connect(func():
		Router.ir_a_tickets_lista()
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered(Vector2i(400, 200))

func _on_cancelar_pressed():
	print("❌ [NUEVO_TICKET] Cancelando...")
	volver_dashboard()

func _on_buscar_cliente_changed(_text: String):
	# La búsqueda automática se maneja en configurar_busqueda_clientes()
	pass

func _on_buscar_cliente_pressed():
	print("🔍 [NUEVO_TICKET] Abriendo selector de clientes...")
	
	# Cargar todos los clientes disponibles
	clientes_disponibles = DataService.buscar_clientes()  # Sin parámetro = todos los clientes
	
	if clientes_disponibles.size() == 0:
		# Crear diálogo con opción de crear cliente
		var dialog = ConfirmationDialog.new()
		dialog.title = "⚠️ Sin Clientes"
		dialog.dialog_text = "No hay clientes registrados en el sistema.\n\n¿Desea crear un nuevo cliente ahora?"
		dialog.get_ok_button().text = "✅ Crear Cliente"
		dialog.get_cancel_button().text = "❌ Cancelar"
		
		# Conectar respuesta
		dialog.confirmed.connect(func():
			_on_nuevo_cliente_pressed()
			dialog.queue_free()
		)
		dialog.canceled.connect(func():
			dialog.queue_free()
		)
		
		add_child(dialog)
		dialog.popup_centered(Vector2(400, 200))
	else:
		error_label.text = ""
		mostrar_popup_clientes()

func _on_nuevo_cliente_pressed():
	print("➕ [NUEVO_TICKET] Abriendo formulario de nuevo cliente...")
	
	# Cargar y mostrar el formulario de nuevo cliente
	var nuevo_cliente_scene = preload("res://ui/nuevo_cliente.tscn")
	var nuevo_cliente_dialog = nuevo_cliente_scene.instantiate()
	
	# Conectar la señal para recibir el cliente creado
	nuevo_cliente_dialog.cliente_creado.connect(_on_cliente_creado)
	
	# Agregar al árbol y mostrar
	add_child(nuevo_cliente_dialog)
	nuevo_cliente_dialog.popup_centered()

func _on_cliente_creado(cliente_data: Dictionary):
	print("✅ [NUEVO_TICKET] Cliente creado y recibido: ", cliente_data.get("nombre", "Sin nombre"))
	
	# Seleccionar automáticamente el cliente recién creado
	seleccionar_cliente(cliente_data)
	
	# Limpiar el campo de búsqueda y mostrar mensaje de éxito
	buscar_cliente_input.text = ""
	error_label.text = "Cliente '" + cliente_data.get("nombre", "Sin nombre") + "' creado y seleccionado"
	error_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
	
	# Limpiar el mensaje después de unos segundos
	await get_tree().create_timer(3.0).timeout
	if error_label.text.begins_with("Cliente '"):
		error_label.text = ""
		error_label.modulate = Color(1.0, 0.4, 0.4, 1.0)

# === UTILIDADES ===

func mostrar_error(mensaje: String):
	"""Muestra un mensaje de error"""
	error_label.text = mensaje
	error_label.modulate = Color(1.0, 0.4, 0.4, 1.0)
	print("❌ [NUEVO_TICKET] Error: ", mensaje)

func mostrar_exito(mensaje: String):
	error_label.text = mensaje
	error_label.modulate = Color(0.4, 1.0, 0.4, 1.0)

func mostrar_confirmacion_exito(_ticket_id: int, codigo_ticket: String):
	# Crear diálogo de confirmación
	var confirmacion = ConfirmationDialog.new()
	confirmacion.title = "✅ Ticket Creado"
	confirmacion.dialog_text = "Ticket creado correctamente con código: " + codigo_ticket + "\n\n¿Desea volver al menú principal?"
	confirmacion.size = Vector2(450, 200)
	
	# Cambiar textos de los botones
	confirmacion.get_ok_button().text = "🏠 Volver al Menú"
	confirmacion.get_cancel_button().text = "➕ Crear Otro Ticket"
	
	# Conectar señales
	confirmacion.confirmed.connect(func(): volver_dashboard())
	confirmacion.cancelled.connect(func(): limpiar_formulario_nuevo_ticket())
	
	# Mostrar diálogo
	add_child(confirmacion)
	confirmacion.popup_centered()
	
	print("✅ [NUEVO_TICKET] Mostrando confirmación para ticket: ", codigo_ticket)

func limpiar_formulario_nuevo_ticket():
	# Limpiar formulario para crear otro ticket
	limpiar_formulario()
	
	# Generar nuevo código
	codigo_value.text = AppState.generar_codigo_ticket()
	
	# Mostrar mensaje
	error_label.text = "Formulario listo para crear otro ticket"
	error_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
	
	# Limpiar mensaje después de unos segundos
	await get_tree().create_timer(3.0).timeout
	if error_label.text == "Formulario listo para crear otro ticket":
		error_label.text = ""
		error_label.modulate = Color(1.0, 0.4, 0.4, 1.0)
	
	print("🔄 [NUEVO_TICKET] Formulario preparado para nuevo ticket")

func verificar_datos_iniciales():
	"""Verifica que existan clientes para poder realizar búsquedas"""
	print("🔍 [NUEVO_TICKET] Verificando datos iniciales...")
	
	# Buscar cualquier cliente existente
	var clientes_existentes = DataService.buscar_clientes()
	
	if clientes_existentes.size() == 0:
		print("⚠️ [NUEVO_TICKET] No hay clientes, creando cliente de ejemplo...")
		crear_cliente_ejemplo()

func crear_cliente_ejemplo():
	"""Crea un cliente de ejemplo para poder probar la funcionalidad"""
	var cliente_ejemplo = {
		"nombre": "Cliente Ejemplo",
		"telefono": "666-123-456", 
		"email": "ejemplo@email.com",
		"nif": "12345678A",
		"direccion": "Calle Ejemplo 123, Madrid"
	}
	
	var cliente_id = DataService.guardar_cliente(cliente_ejemplo)
	if cliente_id > 0:
		print("✅ Cliente de ejemplo creado: ", cliente_ejemplo.get("nombre", "Sin nombre"))

func crear_datos_prueba():
	print("🧪 [NUEVO_TICKET] Creando datos de prueba...")
	
	# Crear cliente de prueba
	var cliente_prueba = {
		"nombre": "Juan Pérez",
		"telefono": "666-123-456",
		"email": "juan.perez@email.com",
		"nif": "12345678A",
		"direccion": "Calle Ejemplo 123, Madrid"
	}
	
	var cliente_id = DataService.guardar_cliente(cliente_prueba)
	if cliente_id > 0:
		print("✅ Cliente de prueba creado: ", cliente_prueba.get("nombre", "Sin nombre"))

func volver_dashboard():
	# Volver al dashboard usando Router
	Router.ir_a_dashboard()
