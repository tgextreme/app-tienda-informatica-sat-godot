extends Control

# Pantalla de detalle/edición de cliente

# Referencias a los nodos
@onready var nombre_input: LineEdit = $VBoxContainer/ScrollContainer/FormContainer/GridContainer/NombreInput
@onready var telefono_input: LineEdit = $VBoxContainer/ScrollContainer/FormContainer/GridContainer/TelefonoInput
@onready var email_input: LineEdit = $VBoxContainer/ScrollContainer/FormContainer/GridContainer/EmailInput
@onready var nif_input: LineEdit = $VBoxContainer/ScrollContainer/FormContainer/GridContainer/NIFInput
@onready var direccion_input: TextEdit = $VBoxContainer/ScrollContainer/FormContainer/DireccionInput
@onready var error_label: Label = $VBoxContainer/ButtonsContainer/ErrorLabel
@onready var titulo_label: Label = $VBoxContainer/TopBar/TituloLabel

var cliente_id_editar: int = 0  # 0 = nuevo, > 0 = editando
var cliente_data_actual: Dictionary = {}

func _ready():
	print("👤 [CLIENTE_DETAIL] Pantalla de cliente inicializada")
	
	# Verificar que todos los nodos existen
	print("🔍 [CLIENTE_DETAIL] Verificando nodos...")
	print("  - nombre_input: ", nombre_input != null)
	print("  - telefono_input: ", telefono_input != null) 
	print("  - email_input: ", email_input != null)
	print("  - nif_input: ", nif_input != null)
	print("  - direccion_input: ", direccion_input != null)
	print("  - titulo_label: ", titulo_label != null)

func configurar(parametros: Dictionary):
	"""Configura la pantalla según los parámetros del Router"""
	print("👤 [CLIENTE_DETAIL] Configurando con parámetros: ", parametros)
	
	# Esperar un frame para asegurar que todos los nodos están listos
	await get_tree().process_frame
	
	if parametros.has("cliente_id"):
		# Modo edición
		cliente_id_editar = int(parametros["cliente_id"])
		if titulo_label != null:
			titulo_label.text = "📋 INFORMACIÓN DEL CLIENTE"
		cargar_cliente_para_editar()
	elif parametros.has("nuevo") and parametros["nuevo"]:
		# Modo creación
		cliente_id_editar = 0
		limpiar_formulario()
		if titulo_label != null:
			titulo_label.text = "➕ NUEVO CLIENTE"
	else:
		# Por defecto, nuevo cliente
		cliente_id_editar = 0
		limpiar_formulario()
		if titulo_label != null:
			titulo_label.text = "➕ NUEVO CLIENTE"

func cargar_cliente_para_editar():
	"""Carga los datos del cliente desde la base de datos"""
	print("📥 [CLIENTE_DETAIL] Cargando cliente ID: ", cliente_id_editar)
	
	if cliente_id_editar <= 0:
		print("❌ [CLIENTE_DETAIL] ID de cliente inválido")
		return
	
	# Obtener datos del cliente
	var clientes = DataService.execute_sql("SELECT * FROM clientes WHERE id = ?", [cliente_id_editar])
	
	if clientes.size() > 0:
		cliente_data_actual = clientes[0]
		cargar_datos_cliente(cliente_data_actual)
	else:
		print("❌ [CLIENTE_DETAIL] Cliente no encontrado")
		mostrar_error("Cliente no encontrado")

func cargar_datos_cliente(cliente_data: Dictionary):
	"""Carga los datos de un cliente en el formulario"""
	print("📝 [CLIENTE_DETAIL] Cargando datos para editar: ", cliente_data.get("nombre", ""))
	print("🔍 [CLIENTE_DETAIL] Datos completos del cliente: ", cliente_data)
	
	# Función auxiliar para limpiar valores null
	var limpiar_valor = func(valor):
		if valor == null or str(valor) == "null" or str(valor) == "":
			return ""
		return str(valor)
	
	# Cargar datos con manejo seguro de valores null
	var nombre_limpio = limpiar_valor.call(cliente_data.get("nombre", ""))
	var telefono_limpio = limpiar_valor.call(cliente_data.get("telefono", ""))
	var email_limpio = limpiar_valor.call(cliente_data.get("email", ""))
	var nif_limpio = limpiar_valor.call(cliente_data.get("nif", ""))
	var direccion_limpia = limpiar_valor.call(cliente_data.get("direccion", ""))
	
	# Verificar que los nodos están disponibles antes de asignar
	if nombre_input == null:
		print("❌ [CLIENTE_DETAIL] nombre_input es null!")
		return
	if telefono_input == null:
		print("❌ [CLIENTE_DETAIL] telefono_input es null!")
		return
	
	# Asignar valores a los campos
	print("📝 [CLIENTE_DETAIL] Asignando valores a campos...")
	
	# Asignar valores reales directamente
	nombre_input.text = nombre_limpio
	telefono_input.text = telefono_limpio
	email_input.text = email_limpio
	nif_input.text = nif_limpio
	direccion_input.text = direccion_limpia
	
	# Mantener el título general para edición
	if titulo_label != null:
		titulo_label.text = "📋 INFORMACIÓN DEL CLIENTE"
	
	print("✅ [CLIENTE_DETAIL] Datos cargados en formulario:")
	print("   - Nombre: '", nombre_limpio, "' -> Campo texto: '", nombre_input.text, "'")
	print("   - Teléfono: '", telefono_limpio, "' -> Campo texto: '", telefono_input.text, "'")
	print("   - Email: '", email_limpio, "' -> Campo texto: '", email_input.text, "'") 
	print("   - NIF: '", nif_limpio, "' -> Campo texto: '", nif_input.text, "'")
	print("   - Dirección: '", direccion_limpia, "' -> Campo texto: '", direccion_input.text, "'")

func limpiar_formulario():
	"""Limpia todos los campos del formulario"""
	if nombre_input == null:
		return  # Los nodos aún no están listos
		
	cliente_id_editar = 0
	cliente_data_actual.clear()
	nombre_input.text = ""
	telefono_input.text = ""
	email_input.text = ""
	nif_input.text = ""
	direccion_input.text = ""
	if error_label != null:
		error_label.text = ""

func validar_formulario() -> bool:
	"""Valida que los campos obligatorios estén completos"""
	error_label.text = ""
	
	if nombre_input.text.strip_edges().is_empty():
		mostrar_error("El nombre es obligatorio")
		nombre_input.grab_focus()
		return false
	
	if telefono_input.text.strip_edges().is_empty():
		mostrar_error("El teléfono es obligatorio") 
		telefono_input.grab_focus()
		return false
	
	return true

func mostrar_error(mensaje: String):
	"""Muestra un mensaje de error"""
	error_label.text = mensaje
	error_label.modulate = Color.RED

func mostrar_exito(mensaje: String):
	"""Muestra un mensaje de éxito"""
	error_label.text = mensaje
	error_label.modulate = Color.GREEN

func _on_guardar_pressed():
	"""Guarda el cliente (crear o actualizar)"""
	if not validar_formulario():
		return
	
	print("💾 [CLIENTE_DETAIL] Guardando cliente...")
	
	var datos = {
		"nombre": nombre_input.text.strip_edges(),
		"telefono": telefono_input.text.strip_edges(),
		"email": email_input.text.strip_edges(),
		"nif": nif_input.text.strip_edges(),
		"direccion": direccion_input.text.strip_edges(),
		# Campos adicionales de la BD con valores por defecto
		"telefono_alt": "",
		"notas": "",
		"rgpd_consent": 0
	}
	
	if cliente_id_editar > 0:
		# Actualizar cliente existente
		datos["id"] = cliente_id_editar
		print("✏️ [CLIENTE_DETAIL] Actualizando cliente existente ID: ", cliente_id_editar)
	else:
		print("🆕 [CLIENTE_DETAIL] Creando nuevo cliente")
	
	# Usar el método existente de DataService
	var cliente_id = DataService.guardar_cliente(datos)
	
	if cliente_id > 0:
		if cliente_id_editar > 0:
			mostrar_exito("Cliente actualizado correctamente")
		else:
			mostrar_exito("Cliente creado correctamente")
		
		await get_tree().create_timer(1.5).timeout
		Router.ir_a_clientes()
	else:
		mostrar_error("Error al guardar el cliente")

func _on_cancelar_pressed():
	"""Cancela y vuelve a la lista de clientes"""
	Router.ir_a_clientes()

func _on_volver_pressed():
	"""Vuelve a la lista de clientes"""
	Router.ir_a_clientes()