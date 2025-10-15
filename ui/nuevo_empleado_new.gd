extends AcceptDialog

# Formulario para crear/editar empleados

signal empleado_guardado(empleado_data: Dictionary)

# Referencias a controles
@onready var nombre_input = $MainContainer/ScrollContainer/FormContainer/DatosPanel/DatosContent/GridContainer/NombreInput
@onready var email_input = $MainContainer/ScrollContainer/FormContainer/DatosPanel/DatosContent/GridContainer/EmailInput
@onready var rol_option = $MainContainer/ScrollContainer/FormContainer/RolPanel/RolContent/RolContainer/RolOption
@onready var password_input = $MainContainer/ScrollContainer/FormContainer/PasswordPanel/PasswordContent/PasswordContainer/PasswordInput
@onready var activo_check = $MainContainer/ScrollContainer/FormContainer/ConfigPanel/ConfigContent/ActivoCheck
@onready var error_label = $MainContainer/ButtonsPanel/ButtonsContent/ErrorLabel
@onready var guardar_btn = $MainContainer/ButtonsPanel/ButtonsContent/GuardarButton
@onready var cancelar_btn = $MainContainer/ButtonsPanel/ButtonsContent/CancelarButton

var empleado_editando: Dictionary = {}
var es_edicion: bool = false

func _ready():
	print("👨‍💼 [NUEVO_EMPLEADO] Inicializando formulario de empleado...")
	configurar_roles()
	configurar_controles()

func configurar_roles():
	"""Configura las opciones de rol disponibles"""
	if rol_option:
		rol_option.clear()
		rol_option.add_item("👤 TECNICO", 2)
		rol_option.add_item("👨‍💼 SUPERVISOR", 3)
		rol_option.add_item("👑 ADMIN", 1)
		rol_option.selected = 0  # Por defecto TÉCNICO

func configurar_controles():
	"""Configura los controles del formulario"""
	# Limpiar error inicial
	if error_label:
		error_label.text = ""
	
	# Conectar botones
	if guardar_btn:
		if not guardar_btn.pressed.is_connected(_on_guardar_pressed):
			guardar_btn.pressed.connect(_on_guardar_pressed)
	
	if cancelar_btn:
		if not cancelar_btn.pressed.is_connected(_on_cancelar_pressed):
			cancelar_btn.pressed.connect(_on_cancelar_pressed)
	
	# Configurar validación en tiempo real
	if nombre_input:
		nombre_input.text_changed.connect(_on_validar_campos)
	if email_input:
		email_input.text_changed.connect(_on_validar_campos)
	if password_input:
		password_input.text_changed.connect(_on_validar_campos)

func cargar_datos_empleado(empleado: Dictionary):
	"""Carga los datos de un empleado existente para edición"""
	print("📝 [NUEVO_EMPLEADO] Cargando datos para edición: ", empleado.get("nombre", ""))
	
	empleado_editando = empleado
	es_edicion = true
	
	# Verificar si es el admin principal
	var empleado_id = int(empleado.get("id", 0))
	var es_admin_principal = empleado_id == 1
	
	# Cambiar título según el tipo de empleado
	if es_admin_principal:
		title = "🔒 ADMIN - SOLO CONTRASEÑA"
		var title_label = $MainContainer/HeaderPanel/HeaderContent/TitleLabel
		if title_label:
			title_label.text = "🔒 ADMIN PRINCIPAL - SOLO CONTRASEÑA"
	else:
		title = "✏️ EDITAR EMPLEADO"
		var title_label = $MainContainer/HeaderPanel/HeaderContent/TitleLabel
		if title_label:
			title_label.text = "✏️ MODIFICAR EMPLEADO"
	
	# Cargar datos en los campos
	if nombre_input:
		nombre_input.text = empleado.get("nombre", "")
		# Si es admin principal, deshabilitar edición de nombre
		nombre_input.editable = not es_admin_principal
		if es_admin_principal:
			nombre_input.modulate = Color(0.7, 0.7, 0.7, 1)
	
	if email_input:
		email_input.text = empleado.get("email", "")
		# Si es admin principal, deshabilitar edición de email
		email_input.editable = not es_admin_principal
		if es_admin_principal:
			email_input.modulate = Color(0.7, 0.7, 0.7, 1)
	
	if activo_check:
		# Compatibilidad de tipos para el campo activo
		var activo_value = empleado.get("activo", 1)
		var esta_activo = (typeof(activo_value) == TYPE_BOOL and activo_value) or (typeof(activo_value) == TYPE_INT and activo_value == 1)
		activo_check.button_pressed = esta_activo
		# Si es admin principal, deshabilitar cambio de estado
		activo_check.disabled = es_admin_principal
		if es_admin_principal:
			activo_check.modulate = Color(0.7, 0.7, 0.7, 1)
	
	# Seleccionar rol
	if rol_option:
		var rol_id = empleado.get("rol_id", 2)
		for i in range(rol_option.get_item_count()):
			if rol_option.get_item_id(i) == rol_id:
				rol_option.selected = i
				break
		# Si es admin principal, deshabilitar cambio de rol
		rol_option.disabled = es_admin_principal
		if es_admin_principal:
			rol_option.modulate = Color(0.7, 0.7, 0.7, 1)
	
	# En edición, la contraseña es opcional
	if password_input:
		if es_admin_principal:
			password_input.placeholder_text = "Nueva contraseña del admin"
		else:
			password_input.placeholder_text = "Dejar vacío para mantener contraseña actual"

func _on_guardar_pressed():
	"""Valida y guarda el empleado"""
	print("💾 [NUEVO_EMPLEADO] Guardando empleado...")
	
	if not validar_formulario():
		return
	
	var empleado_data = recopilar_datos()
	
	if es_edicion:
		actualizar_empleado(empleado_data)
	else:
		crear_empleado(empleado_data)

func validar_formulario() -> bool:
	"""Valida que todos los campos obligatorios estén completos"""
	var errores = []
	
	# Verificar si es el admin principal para validación especial
	var es_admin_principal = false
	if es_edicion and empleado_editando.has("id"):
		es_admin_principal = int(empleado_editando.get("id", 0)) == 1
	
	if es_admin_principal:
		# Para admin principal, solo validar contraseña si se proporciona
		if password_input and not password_input.text.strip_edges().is_empty():
			if password_input.text.length() < 4:
				errores.append("• La contraseña debe tener al menos 4 caracteres")
	else:
		# Validación normal para otros empleados
		# Validar nombre
		if not nombre_input or nombre_input.text.strip_edges().is_empty():
			errores.append("• El nombre es obligatorio")
		
		# Validar email
		if not email_input or email_input.text.strip_edges().is_empty():
			errores.append("• El email es obligatorio")
		elif not es_email_valido(email_input.text):
			errores.append("• El email no tiene formato válido")
		
		# Validar contraseña (solo para nuevos empleados)
		if not es_edicion:
			if not password_input or password_input.text.strip_edges().is_empty():
				errores.append("• La contraseña es obligatoria")
			elif password_input.text.length() < 6:
				errores.append("• La contraseña debe tener al menos 6 caracteres")
		
		# Validar rol
		if not rol_option or rol_option.selected < 0:
			errores.append("• Debe seleccionar un rol")
	
	# Mostrar errores
	if errores.size() > 0:
		if error_label:
			error_label.text = "❌ ERRORES:\n" + "\n".join(errores)
		return false
	
	if error_label:
		error_label.text = ""
	return true

func es_email_valido(email: String) -> bool:
	"""Valida formato básico de email"""
	var regex = RegEx.new()
	regex.compile("^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null

func recopilar_datos() -> Dictionary:
	"""Recopila los datos del formulario"""
	var datos = {}
	
	# Verificar si es el admin principal
	var es_admin_principal = false
	if es_edicion and empleado_editando.has("id"):
		es_admin_principal = int(empleado_editando.get("id", 0)) == 1
	
	if es_admin_principal:
		# Para admin principal, solo permitir cambio de contraseña
		datos["id"] = empleado_editando["id"]
		# Solo incluir contraseña si se proporciona
		if password_input and not password_input.text.strip_edges().is_empty():
			datos["password"] = password_input.text.strip_edges()
		
		# Mantener datos originales para otros campos
		datos["nombre"] = empleado_editando.get("nombre", "")
		datos["email"] = empleado_editando.get("email", "")
		datos["rol_id"] = empleado_editando.get("rol_id", 1)
		datos["activo"] = empleado_editando.get("activo", 1)
	else:
		# Recopilación normal para otros empleados
		if nombre_input:
			datos["nombre"] = nombre_input.text.strip_edges()
		if email_input:
			datos["email"] = email_input.text.strip_edges()
		if rol_option and rol_option.selected >= 0:
			datos["rol_id"] = rol_option.get_item_id(rol_option.selected)
		if activo_check:
			datos["activo"] = 1 if activo_check.button_pressed else 0
		
		# Solo incluir contraseña si se proporciona
		if password_input and not password_input.text.strip_edges().is_empty():
			datos["password"] = password_input.text.strip_edges()
		
		# Si es edición, incluir ID
		if es_edicion and empleado_editando.has("id"):
			datos["id"] = empleado_editando["id"]
	
	return datos

func crear_empleado(empleado_data: Dictionary):
	"""Crea un nuevo empleado"""
	print("➕ [NUEVO_EMPLEADO] Creando nuevo empleado...")
	
	# Mostrar mensaje de procesamiento
	mostrar_procesando("Creando empleado...")
	
	if not DataService:
		mostrar_error("Error: DataService no disponible")
		return
	
	var resultado = DataService.crear_empleado(empleado_data)
	
	if resultado.success:
		print("✅ [NUEVO_EMPLEADO] Empleado creado exitosamente")
		mostrar_exito("Empleado creado exitosamente: " + empleado_data.get("nombre", ""))
		empleado_guardado.emit(resultado.empleado)
		
		# Esperar un poco antes de cerrar para que el usuario vea el mensaje
		await get_tree().create_timer(1.5).timeout
		hide()
	else:
		mostrar_error("Error al crear empleado: " + resultado.message)

func actualizar_empleado(empleado_data: Dictionary):
	"""Actualiza un empleado existente"""
	print("✏️ [NUEVO_EMPLEADO] Actualizando empleado existente...")
	
	# Mostrar mensaje de procesamiento
	mostrar_procesando("Actualizando empleado...")
	
	if not DataService:
		mostrar_error("Error: DataService no disponible")
		return
	
	var resultado = DataService.actualizar_empleado(empleado_data)
	
	if resultado.success:
		print("✅ [NUEVO_EMPLEADO] Empleado actualizado exitosamente")
		mostrar_exito("Empleado actualizado exitosamente: " + empleado_data.get("nombre", ""))
		empleado_guardado.emit(resultado.empleado)
		
		# Esperar un poco antes de cerrar para que el usuario vea el mensaje
		await get_tree().create_timer(1.5).timeout
		hide()
	else:
		mostrar_error("Error al actualizar empleado: " + resultado.message)

func mostrar_error(mensaje: String):
	"""Muestra un mensaje de error"""
	if error_label:
		error_label.text = "❌ " + mensaje
		error_label.add_theme_color_override("font_color", Color.RED)

func mostrar_exito(mensaje: String):
	"""Muestra un mensaje de éxito"""
	if error_label:
		error_label.text = "✅ " + mensaje  
		error_label.add_theme_color_override("font_color", Color.GREEN)

func mostrar_procesando(mensaje: String):
	"""Muestra un mensaje de procesamiento"""
	if error_label:
		error_label.text = "⏳ " + mensaje
		error_label.add_theme_color_override("font_color", Color.YELLOW)

func _on_validar_campos(_texto: String = ""):
	"""Valida campos en tiempo real"""
	# Validación básica en tiempo real
	if error_label and error_label.text.begins_with("❌"):
		error_label.text = ""  # Limpiar errores previos al escribir

func _on_cancelar_pressed():
	"""Cancela y cierra el formulario"""
	print("❌ [NUEVO_EMPLEADO] Cancelando...")
	hide()

# Función _on_validar_campos duplicada eliminada