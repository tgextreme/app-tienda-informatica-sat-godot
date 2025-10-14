extends Control

# Pantalla de login de la aplicación SAT

@onready var email_input = $CenterContainer/LoginPanel/VBoxContainer/EmailInput
@onready var password_input = $CenterContainer/LoginPanel/VBoxContainer/PasswordInput
@onready var remember_check = $CenterContainer/LoginPanel/VBoxContainer/RememberCheck
@onready var login_button = $CenterContainer/LoginPanel/VBoxContainer/LoginButton
@onready var error_label = $CenterContainer/LoginPanel/VBoxContainer/ErrorLabel

var intentos_login = 0
var max_intentos = 3

func _ready():
	# Configurar interfaz inicial
	email_input.grab_focus()
	error_label.text = ""
	
	# Cargar credenciales guardadas si existen
	cargar_credenciales_guardadas()
	
	# Conectar señales
	email_input.text_submitted.connect(_on_enter_pressed)
	password_input.text_submitted.connect(_on_enter_pressed)
	
	# No verificar sesión aquí ya que Main.gd se encarga de la navegación inicial

func cargar_credenciales_guardadas():
	var config = ConfigFile.new()
	var error = config.load("user://login.cfg")
	
	if error == OK:
		var email = config.get_value("login", "email", "")
		var recordar = config.get_value("login", "recordar", false)
		
		if recordar and email != "":
			email_input.text = email
			remember_check.button_pressed = true

func guardar_credenciales():
	var config = ConfigFile.new()
	
	if remember_check.button_pressed:
		config.set_value("login", "email", email_input.text)
		config.set_value("login", "recordar", true)
	else:
		config.set_value("login", "email", "")
		config.set_value("login", "recordar", false)
	
	config.save("user://login.cfg")

func _on_login_button_pressed():
	realizar_login()

func _on_enter_pressed(_text: String):
	realizar_login()

func realizar_login():
	var email = email_input.text.strip_edges()
	var password = password_input.text
	
	# Validaciones básicas
	if email == "":
		mostrar_error("Por favor, ingrese su email")
		email_input.grab_focus()
		return
	
	if password == "":
		mostrar_error("Por favor, ingrese su contraseña")
		password_input.grab_focus()
		return
	
	# Deshabilitar botón mientras se valida
	login_button.disabled = true
	error_label.text = "Validando credenciales..."
	
	# Intentar login con un pequeño delay para UX
	await get_tree().create_timer(0.5).timeout
	
	var exito = AppState.login(email, password)
	
	if exito:
		# Login exitoso
		guardar_credenciales()
		mostrar_mensaje_exito("¡Bienvenido " + AppState.get_usuario_nombre() + "!")
		
		await get_tree().create_timer(1.0).timeout
		ir_a_dashboard_simple()
	else:
		# Login fallido - verificar si el sistema está listo
		if not DataService.db:
			mostrar_error("Sistema iniciando... por favor espere un momento.")
			login_button.disabled = false
		else:
			intentos_login += 1
			
			if intentos_login >= max_intentos:
				mostrar_error("Demasiados intentos fallidos. Cierre y reabra la aplicación.")
				login_button.disabled = true
				email_input.editable = false
				password_input.editable = false
			else:
				var intentos_restantes = max_intentos - intentos_login
				mostrar_error("Credenciales incorrectas. Intentos restantes: " + str(intentos_restantes))
				password_input.text = ""
				password_input.grab_focus()
				
				login_button.disabled = false

func mostrar_error(mensaje: String):
	error_label.text = mensaje
	error_label.modulate = Color(1.0, 0.4, 0.4, 1.0)

func mostrar_mensaje_exito(mensaje: String):
	error_label.text = mensaje
	error_label.modulate = Color(0.4, 1.0, 0.4, 1.0)

func ir_a_dashboard_simple():
	print("🎯 [LOGIN] Navegando a dashboard simple...")
	
	# Verificar que existe dashboard
	if not FileAccess.file_exists("res://ui/dashboard.tscn"):
		mostrar_error("Error: dashboard.tscn no encontrado")
		return
	
	# Cargar dashboard
	var dashboard_scene = load("res://ui/dashboard.tscn")
	if dashboard_scene == null:
		mostrar_error("Error: No se puede cargar dashboard")
		return
	
	# Instanciar
	var dashboard_instance = dashboard_scene.instantiate()
	if dashboard_instance == null:
		mostrar_error("Error: No se puede instanciar dashboard")
		return
	
	# Navegar usando Router
	Router.ir_a_dashboard()
	print("✅ [LOGIN] Navegado a dashboard")

func _input(event):
	# Atajo para desarrollo: Ctrl+D para login directo como admin
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_D:
			email_input.text = "admin@tienda-sat.com"
			password_input.text = "admin123"
			realizar_login()