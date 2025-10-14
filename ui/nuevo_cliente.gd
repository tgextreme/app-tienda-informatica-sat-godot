extends AcceptDialog

# Formulario para crear un nuevo cliente

# Referencias a los nodos
@onready var nombre_input: LineEdit = $MainContainer/ScrollContainer/FormContainer/DatosPanel/DatosContent/GridContainer/NombreInput
@onready var telefono_input: LineEdit = $MainContainer/ScrollContainer/FormContainer/DatosPanel/DatosContent/GridContainer/TelefonoInput
@onready var email_input: LineEdit = $MainContainer/ScrollContainer/FormContainer/DatosPanel/DatosContent/GridContainer/EmailInput
@onready var nif_input: LineEdit = $MainContainer/ScrollContainer/FormContainer/DatosPanel/DatosContent/GridContainer/NIFInput
@onready var direccion_input: TextEdit = $MainContainer/ScrollContainer/FormContainer/DatosPanel/DatosContent/DireccionInput
@onready var error_label: Label = $MainContainer/ButtonsPanel/ButtonsContent/ErrorLabel

# Señal para notificar cuando se crea un cliente
signal cliente_creado(cliente_data: Dictionary)

var cliente_id_editar: int = 0  # 0 = nuevo, > 0 = editando

func _ready():
	print("👤 [NUEVO_CLIENTE] Formulario inicializado")
	limpiar_formulario()
	
	# Configurar el formulario
	get_ok_button().visible = false  # Ocultar botón OK por defecto
	
	# Enfocar el primer campo
	await get_tree().process_frame
	nombre_input.grab_focus()

func limpiar_formulario():
	"""Limpia todos los campos del formulario"""
	cliente_id_editar = 0
	nombre_input.text = ""
	telefono_input.text = ""
	email_input.text = ""
	nif_input.text = ""
	direccion_input.text = ""
	error_label.text = ""
	title = "👤 NUEVO CLIENTE"

func validar_formulario() -> bool:
	"""Valida que los campos obligatorios estén completos"""
	var errores = []
	
	# Validar nombre
	if nombre_input.text.strip_edges() == "":
		errores.append("El nombre es obligatorio")
	
	# Validar teléfono
	if telefono_input.text.strip_edges() == "":
		errores.append("El teléfono es obligatorio")
	
	# Validar formato del email si se proporcionó
	var email = email_input.text.strip_edges()
	if email != "" and not email.contains("@"):
		errores.append("El email no tiene un formato válido")
	
	# Mostrar errores
	if errores.size() > 0:
		error_label.text = "Error: " + " • ".join(errores)
		return false
	
	error_label.text = ""
	return true

func crear_cliente_data() -> Dictionary:
	"""Crea el diccionario con los datos del cliente"""
	var data = {
		"nombre": nombre_input.text.strip_edges(),
		"telefono": telefono_input.text.strip_edges(),
		"email": email_input.text.strip_edges(),
		"nif": nif_input.text.strip_edges(),
		"direccion": direccion_input.text.strip_edges(),
		"telefono_alt": "",  # Campo adicional para SQLite
		"notas": "",         # Campo adicional para SQLite
		"rgpd_consent": 0    # Campo adicional para SQLite
	}
	
	# Solo agregar ID si estamos editando
	if cliente_id_editar > 0:
		data["id"] = cliente_id_editar
	
	return data

func _on_guardar_pressed():
	print("💾 [NUEVO_CLIENTE] Guardando cliente...")
	
	if not validar_formulario():
		return
	
	var cliente_data = crear_cliente_data()
	
	# Guardar en la base de datos
	var cliente_id = DataService.guardar_cliente(cliente_data)
	
	if cliente_id > 0:
		print("✅ [NUEVO_CLIENTE] Cliente creado con ID: ", cliente_id)
		
		# Agregar el ID al diccionario
		cliente_data["id"] = cliente_id
		
		# Emitir señal con los datos del cliente creado
		cliente_creado.emit(cliente_data)
		
		# Mostrar mensaje de éxito
		error_label.text = "Cliente guardado correctamente"
		error_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		
		# Cerrar después de un momento
		await get_tree().create_timer(1.0).timeout
		hide()
	else:
		error_label.text = "Error al guardar el cliente"
		error_label.modulate = Color(1.0, 0.4, 0.4, 1.0)

func _on_cancelar_pressed():
	print("❌ [NUEVO_CLIENTE] Cancelando...")
	hide()

func _on_close_requested():
	print("❌ [NUEVO_CLIENTE] Cerrando formulario...")
	hide()

func cargar_datos_cliente(cliente_data: Dictionary):
	"""Carga los datos de un cliente existente para editar"""
	print("📝 [NUEVO_CLIENTE] Cargando datos para editar: ", cliente_data.get("nombre", ""))
	
	cliente_id_editar = int(cliente_data.get("id", 0))
	nombre_input.text = cliente_data.get("nombre", "")
	telefono_input.text = cliente_data.get("telefono", "")
	email_input.text = cliente_data.get("email", "")
	nif_input.text = cliente_data.get("nif", "")
	direccion_input.text = cliente_data.get("direccion", "")
	
	# Cambiar el título para indicar que estamos editando
	title = "✏️ EDITAR CLIENTE"