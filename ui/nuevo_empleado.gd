extends AcceptDialog

# Formulario para crear/editar empleados

# Referencias a los nodos
@onready var nombre_input: LineEdit = $MainContainer/ScrollContainer/FormContainer/DatosPersonalesPanel/VBox/GridContainer/NombreInput
@onready var email_input: LineEdit = $MainContainer/ScrollContainer/FormContainer/DatosPersonalesPanel/VBox/GridContainer/EmailInput
@onready var rol_option: OptionButton = $MainContainer/ScrollContainer/FormContainer/AccesoPanel/VBox2/GridContainer2/RolOption
@onready var password_input: LineEdit = $MainContainer/ScrollContainer/FormContainer/AccesoPanel/VBox2/GridContainer2/PasswordInput
@onready var confirm_password_input: LineEdit = $MainContainer/ScrollContainer/FormContainer/AccesoPanel/VBox2/GridContainer2/ConfirmPasswordInput
@onready var activo_check: CheckBox = $MainContainer/ScrollContainer/FormContainer/ConfigPanel/VBox3/ActivoCheck
@onready var notificaciones_check: CheckBox = $MainContainer/ScrollContainer/FormContainer/ConfigPanel/VBox3/NotificacionesCheck
@onready var error_label: Label = $MainContainer/ButtonsPanel/ButtonsContent/ErrorLabel

# Señal para notificar cuando se guarda un empleado
signal empleado_guardado(empleado_data: Dictionary)

var empleado_id_editar: int = 0  # 0 = nuevo, > 0 = editando
var roles_disponibles: Array = []

func _ready():
	print("👨‍💼 [NUEVO_EMPLEADO] Formulario inicializado")
	limpiar_formulario()
	cargar_roles()
	configurar_estilo()
	
	# Ocultar botón OK por defecto
	get_ok_button().visible = false
	
	# Enfocar el primer campo
	await get_tree().process_frame
	nombre_input.grab_focus()

func configurar_estilo():
	"""Configura el estilo visual del formulario"""
	# Paneles con estilos
	var paneles = [
		$MainContainer/ScrollContainer/FormContainer/DatosPersonalesPanel,
		$MainContainer/ScrollContainer/FormContainer/AccesoPanel,
		$MainContainer/ScrollContainer/FormContainer/ConfigPanel,
		$MainContainer/ButtonsPanel
	]
	
	for i in range(paneles.size()):
		var panel = paneles[i]
		if panel:
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.15, 0.18, 1)
			style.border_width_left = 2
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			
			# Diferentes colores de borde para cada panel
			match i:
				0: style.border_color = Color(0.9, 0.7, 0.3, 1)  # Datos personales
				1: style.border_color = Color(0.3, 0.8, 0.9, 1)  # Acceso
				2: style.border_color = Color(0.8, 0.3, 0.9, 1)  # Config
				3: style.border_color = Color(0.5, 0.5, 0.5, 1)  # Botones
			
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_right = 6
			style.corner_radius_bottom_left = 6
			panel.add_theme_stylebox_override("panel", style)

func cargar_roles():
	"""Carga los roles disponibles desde la base de datos"""
	print("📋 [NUEVO_EMPLEADO] Cargando roles...")
	
	roles_disponibles = DataService.obtener_todos_los_roles()
	
	# Limpiar opciones
	rol_option.clear()
	
	# Agregar opción por defecto
	rol_option.add_item("-- Seleccionar rol --", -1)
	
	# Agregar roles
	for rol in roles_disponibles:
		var rol_id = int(rol.get("id", 0))
		var rol_nombre = rol.get("nombre", "Sin nombre")
		var rol_descripcion = rol.get("descripcion", "")
		
		var texto_opcion = "%s" % rol_nombre
		if rol_descripcion != "":
			texto_opcion += " (%s)" % rol_descripcion
		
		rol_option.add_item(texto_opcion, rol_id)
	
	print("✅ [NUEVO_EMPLEADO] ", roles_disponibles.size(), " roles cargados")

func limpiar_formulario():
	"""Limpia todos los campos del formulario"""
	empleado_id_editar = 0
	nombre_input.text = ""
	email_input.text = ""
	password_input.text = ""
	confirm_password_input.text = ""
	activo_check.button_pressed = true
	notificaciones_check.button_pressed = true
	error_label.text = ""
	title = "👨‍💼 NUEVO EMPLEADO"
	
	if rol_option:
		rol_option.selected = 0

func cargar_datos_empleado(empleado_data: Dictionary):
	"""Carga los datos de un empleado existente para editar"""
	print("📝 [NUEVO_EMPLEADO] Cargando datos para editar: ", empleado_data.get("nombre", ""))
	
	empleado_id_editar = int(empleado_data.get("id", 0))
	nombre_input.text = empleado_data.get("nombre", "")
	email_input.text = empleado_data.get("email", "")
	
	# Manejar campo activo (compatibilidad bool/int)
	var activo_value = empleado_data.get("activo", true)
	if activo_value is bool:
		activo_check.button_pressed = activo_value
	else:
		activo_check.button_pressed = (int(activo_value) == 1)
		
	# Manejar campo notificaciones (compatibilidad bool/int)
	var notif_value = empleado_data.get("notificaciones", true)
	if notif_value is bool:
		notificaciones_check.button_pressed = notif_value
	else:
		notificaciones_check.button_pressed = (int(notif_value) == 1)
	
	# Seleccionar el rol correcto
	var rol_id = int(empleado_data.get("rol_id", 0))
	for i in range(rol_option.item_count):
		if rol_option.get_item_id(i) == rol_id:
			rol_option.selected = i
			break
	
	# Cambiar título y ocultar campos de contraseña para edición
	title = "✏️ EDITAR EMPLEADO"
	password_input.get_parent().get_node("PasswordLabel").text = "🔑 Nueva Contraseña: (dejar vacío para mantener)"
	password_input.placeholder_text = "Dejar vacío para no cambiar"
	confirm_password_input.get_parent().get_node("ConfirmPasswordLabel").text = "🔑 Confirmar Nueva Contraseña:"
	confirm_password_input.placeholder_text = "Repetir nueva contraseña"

func validar_formulario() -> bool:
	"""Valida que los campos obligatorios estén completos"""
	var errores = []
	
	# Validar nombre
	if nombre_input.text.strip_edges() == "":
		errores.append("El nombre es obligatorio")
	
	# Validar email
	var email = email_input.text.strip_edges()
	if email == "":
		errores.append("El email es obligatorio")
	elif not email.contains("@") or not email.contains("."):
		errores.append("El email no tiene un formato válido")
	
	# Validar rol
	if rol_option.selected <= 0:
		errores.append("Debe seleccionar un rol")
	
	# Validar contraseñas solo si es empleado nuevo o si se cambió la contraseña
	var password = password_input.text.strip_edges()
	var confirm_password = confirm_password_input.text.strip_edges()
	
	if empleado_id_editar == 0:  # Empleado nuevo
		if password == "":
			errores.append("La contraseña es obligatoria")
		elif password.length() < 6:
			errores.append("La contraseña debe tener al menos 6 caracteres")
		elif password != confirm_password:
			errores.append("Las contraseñas no coinciden")
	else:  # Editando empleado
		if password != "" and password.length() < 6:
			errores.append("La nueva contraseña debe tener al menos 6 caracteres")
		elif password != confirm_password:
			errores.append("Las contraseñas no coinciden")
	
	# Mostrar errores
	if errores.size() > 0:
		error_label.text = "❌ " + " • ".join(errores)
		error_label.modulate = Color(1.0, 0.4, 0.4, 1.0)
		return false
	
	error_label.text = ""
	return true

func crear_empleado_data() -> Dictionary:
	"""Crea el diccionario con los datos del empleado"""
	var empleado_data = {
		"nombre": nombre_input.text.strip_edges(),
		"email": email_input.text.strip_edges(),
		"rol_id": rol_option.get_item_id(rol_option.selected),
		"activo": activo_check.button_pressed,
		"notificaciones": notificaciones_check.button_pressed
	}
	
	# Agregar ID si estamos editando
	if empleado_id_editar > 0:
		empleado_data["id"] = empleado_id_editar
	
	# Agregar contraseña solo si es necesario
	var password = password_input.text.strip_edges()
	if password != "":
		empleado_data["password"] = password
	
	return empleado_data

func _on_guardar_pressed():
	print("💾 [NUEVO_EMPLEADO] Guardando empleado...")
	
	if not validar_formulario():
		return
	
	var empleado_data = crear_empleado_data()
	
	# Verificar si el email ya existe (excepto el empleado actual)
	if not verificar_email_unico(empleado_data["email"]):
		error_label.text = "❌ Ya existe un empleado con ese email"
		error_label.modulate = Color(1.0, 0.4, 0.4, 1.0)
		return
	
	# Guardar en la base de datos
	var resultado = DataService.guardar_empleado(empleado_data)
	
	if resultado > 0:
		print("✅ [NUEVO_EMPLEADO] Empleado guardado con ID: ", resultado)
		
		# Agregar el ID al diccionario
		empleado_data["id"] = resultado
		
		# Emitir señal con los datos del empleado guardado
		empleado_guardado.emit(empleado_data)
		
		# Mostrar mensaje de éxito
		error_label.text = "✅ Empleado guardado correctamente"
		error_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		
		# Cerrar después de un momento
		await get_tree().create_timer(1.0).timeout
		hide()
	else:
		error_label.text = "❌ Error al guardar el empleado"
		error_label.modulate = Color(1.0, 0.4, 0.4, 1.0)

func verificar_email_unico(email: String) -> bool:
	"""Verifica que el email no esté en uso por otro empleado"""
	var empleados_existentes = DataService.buscar_empleados_por_email(email)
	
	# Si no encontró ninguno, el email está libre
	if empleados_existentes.size() == 0:
		return true
	
	# Si estamos editando y el email pertenece al mismo empleado, está bien
	if empleado_id_editar > 0:
		for emp in empleados_existentes:
			if int(emp.get("id", 0)) == empleado_id_editar:
				return true
	
	# En cualquier otro caso, el email ya está en uso
	return false

func _on_cancelar_pressed():
	print("❌ [NUEVO_EMPLEADO] Cancelando...")
	hide()

func _on_close_requested():
	print("❌ [NUEVO_EMPLEADO] Cerrando formulario...")
	hide()