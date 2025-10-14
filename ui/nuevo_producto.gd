extends Control

# Referencias a los nodos del formulario
@onready var title_label: Label = $ScrollContainer/VBoxContainer/HeaderContainer/TitleContainer/TitleLabel
@onready var save_button: Button = $ScrollContainer/VBoxContainer/HeaderContainer/TitleContainer/ButtonsContainer/SaveButton
@onready var cancel_button: Button = $ScrollContainer/VBoxContainer/HeaderContainer/TitleContainer/ButtonsContainer/CancelButton

# Campos básicos
@onready var sku_input: LineEdit = $ScrollContainer/VBoxContainer/FormContainer/BasicInfoContainer/BasicInfoGrid/SkuInput
@onready var nombre_input: LineEdit = $ScrollContainer/VBoxContainer/FormContainer/BasicInfoContainer/BasicInfoGrid/NombreInput
@onready var categoria_input: LineEdit = $ScrollContainer/VBoxContainer/FormContainer/BasicInfoContainer/BasicInfoGrid/CategoriaInput
@onready var tipo_option: OptionButton = $ScrollContainer/VBoxContainer/FormContainer/BasicInfoContainer/BasicInfoGrid/TipoOption

# Campos de precios
@onready var coste_spinbox: SpinBox = $ScrollContainer/VBoxContainer/FormContainer/PreciosContainer/PreciosGrid/CosteSpinBox
@onready var pvp_spinbox: SpinBox = $ScrollContainer/VBoxContainer/FormContainer/PreciosContainer/PreciosGrid/PvpSpinBox
@onready var iva_spinbox: SpinBox = $ScrollContainer/VBoxContainer/FormContainer/PreciosContainer/PreciosGrid/IvaSpinBox
@onready var margen_info: Label = $ScrollContainer/VBoxContainer/FormContainer/PreciosContainer/PreciosGrid/MargenInfo

# Campos de stock
@onready var stock_spinbox: SpinBox = $ScrollContainer/VBoxContainer/FormContainer/StockContainer/StockGrid/StockSpinBox
@onready var stock_min_spinbox: SpinBox = $ScrollContainer/VBoxContainer/FormContainer/StockContainer/StockGrid/StockMinSpinBox

# Proveedor
@onready var proveedor_input: LineEdit = $ScrollContainer/VBoxContainer/FormContainer/ProveedorContainer/ProveedorInput

# Variables de control
var producto_id: int = -1
var modo_edicion: bool = false
var producto_original: Dictionary = {}

func _ready():
	print("📦 [NUEVO_PRODUCTO] Inicializando pantalla de nuevo producto...")
	configurar_interfaz()
	conectar_senales()
	
	# Verificar si se pasaron parámetros para edición
	var parametros = Router.obtener_parametros_actuales()
	print("📦 [NUEVO_PRODUCTO] Parámetros recibidos: ", parametros)
	
	if parametros.has("modo") and parametros.modo == "editar":
		print("📦 [NUEVO_PRODUCTO] Configurando MODO EDICIÓN")
		modo_edicion = true
		producto_id = parametros.get("producto_id", -1)
		print("📦 [NUEVO_PRODUCTO] ID del producto a editar: ", producto_id)
		cargar_producto_para_edicion()
	else:
		print("📦 [NUEVO_PRODUCTO] Configurando MODO CREACIÓN")
		modo_edicion = false
		configurar_modo_crear()

func configurar_interfaz():
	# Configurar opciones de tipo
	tipo_option.add_item("REPUESTO", 0)
	tipo_option.add_item("ACCESORIO", 1) 
	tipo_option.add_item("SERVICIO", 2)
	
	# Configurar permisos
	save_button.visible = AppState.tiene_permiso("crear_producto") or AppState.tiene_permiso("editar_producto")

func conectar_senales():
	save_button.pressed.connect(_on_save_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# Conectar cambios de precios para calcular margen automáticamente
	coste_spinbox.value_changed.connect(_on_precio_changed)
	pvp_spinbox.value_changed.connect(_on_precio_changed)

func configurar_modo_crear():
	print("📦 [NUEVO_PRODUCTO] Configurando modo CREAR")
	title_label.text = "Nuevo Producto"
	save_button.text = "Crear Producto"
	
	# Valores por defecto
	iva_spinbox.value = 21.0
	tipo_option.selected = 0  # REPUESTO por defecto

func cargar_producto_para_edicion():
	print("📦 [NUEVO_PRODUCTO] ===== CONFIGURANDO MODO EDITAR =====")
	print("📦 [NUEVO_PRODUCTO] Producto ID: ", producto_id)
	print("📦 [NUEVO_PRODUCTO] Modo edición: ", modo_edicion)
	
	title_label.text = "Editar Producto"
	save_button.text = "Actualizar Producto"
	
	if producto_id <= 0:
		print("❌ [NUEVO_PRODUCTO] Error: ID de producto inválido: ", producto_id)
		Router.ir_a_inventario()
		return
	
	# Obtener datos del producto
	print("📦 [NUEVO_PRODUCTO] Obteniendo datos del producto ID: ", producto_id)
	producto_original = DataService.obtener_producto(producto_id)
	print("📦 [NUEVO_PRODUCTO] Datos obtenidos: ", producto_original)
	
	if producto_original.is_empty():
		print("❌ [NUEVO_PRODUCTO] Error: No se encontró el producto con ID: ", producto_id)
		Router.ir_a_inventario()
		return
	
	# Cargar datos en el formulario
	cargar_datos_formulario(producto_original)
	print("📦 [NUEVO_PRODUCTO] ===== MODO EDITAR CONFIGURADO =====")

# Variable para verificar que se mantiene el estado
func verificar_estado_edicion():
	print("🔍 [NUEVO_PRODUCTO] VERIFICACIÓN ESTADO:")
	print("🔍 [NUEVO_PRODUCTO] - modo_edicion: ", modo_edicion)
	print("🔍 [NUEVO_PRODUCTO] - producto_id: ", producto_id)
	print("🔍 [NUEVO_PRODUCTO] - title_label.text: ", title_label.text)
	print("🔍 [NUEVO_PRODUCTO] - save_button.text: ", save_button.text)

func cargar_datos_formulario(datos: Dictionary):
	print("📦 [NUEVO_PRODUCTO] ===== CARGANDO DATOS EN FORMULARIO =====")
	print("📦 [NUEVO_PRODUCTO] Datos a cargar: ", datos)
	
	# Datos básicos
	sku_input.text = str(datos.get("sku", ""))
	nombre_input.text = str(datos.get("nombre", ""))
	categoria_input.text = str(datos.get("categoria", ""))
	
	print("📦 [NUEVO_PRODUCTO] SKU cargado: '", sku_input.text, "'")
	print("📦 [NUEVO_PRODUCTO] Nombre cargado: '", nombre_input.text, "'")
	print("📦 [NUEVO_PRODUCTO] Categoría cargada: '", categoria_input.text, "'")
	
	# Tipo
	var tipo = datos.get("tipo", "REPUESTO")
	print("📦 [NUEVO_PRODUCTO] Tipo del producto: ", tipo)
	match tipo:
		"REPUESTO":
			tipo_option.selected = 0
		"ACCESORIO":
			tipo_option.selected = 1
		"SERVICIO":
			tipo_option.selected = 2
		_:
			tipo_option.selected = 0
	
	# Precios
	coste_spinbox.value = float(datos.get("coste", 0.0))
	pvp_spinbox.value = float(datos.get("pvp", 0.0))
	iva_spinbox.value = float(datos.get("iva", 21.0))
	
	# Stock
	stock_spinbox.value = float(datos.get("stock", 0))
	stock_min_spinbox.value = float(datos.get("stock_min", 0))
	
	# Proveedor
	proveedor_input.text = str(datos.get("proveedor", ""))
	
	print("📦 [NUEVO_PRODUCTO] Coste cargado: ", coste_spinbox.value)
	print("📦 [NUEVO_PRODUCTO] PVP cargado: ", pvp_spinbox.value)
	print("📦 [NUEVO_PRODUCTO] Stock cargado: ", stock_spinbox.value)
	print("📦 [NUEVO_PRODUCTO] Proveedor cargado: '", proveedor_input.text, "'")
	
	# Actualizar margen
	_on_precio_changed(0)
	
	print("📦 [NUEVO_PRODUCTO] ===== DATOS CARGADOS COMPLETAMENTE =====")
	
	# Verificar estado final
	verificar_estado_edicion()

func _on_precio_changed(_value: float):
	"""Calcula y muestra el margen automáticamente"""
	var coste = coste_spinbox.value
	var pvp = pvp_spinbox.value
	
	if coste > 0:
		var margen_euros = pvp - coste
		var margen_porcentaje = (margen_euros / coste) * 100.0
		margen_info.text = "%.2f%% (%.2f€)" % [margen_porcentaje, margen_euros]
		
		# Colorear según el margen
		if margen_porcentaje < 10:
			margen_info.modulate = Color(1, 0.4, 0.4)  # Rojo - margen bajo
		elif margen_porcentaje < 25:
			margen_info.modulate = Color(1, 0.8, 0.2)  # Amarillo - margen medio
		else:
			margen_info.modulate = Color(0.2, 0.8, 0.2)  # Verde - buen margen
	else:
		margen_info.text = "0.00% (0.00€)"
		margen_info.modulate = Color.WHITE

func validar_formulario() -> Dictionary:
	"""Valida el formulario y devuelve un diccionario con el resultado"""
	var errores = []
	
	# Validar campos obligatorios
	if sku_input.text.strip_edges() == "":
		errores.append("El código SKU es obligatorio")
	
	if nombre_input.text.strip_edges() == "":
		errores.append("El nombre del producto es obligatorio")
	
	if pvp_spinbox.value <= 0:
		errores.append("El PVP debe ser mayor que 0")
	
	if stock_spinbox.value < 0:
		errores.append("El stock no puede ser negativo")
	
	if stock_min_spinbox.value < 0:
		errores.append("El stock mínimo no puede ser negativo")
	
	# Validar SKU único (solo en modo crear o si cambió el SKU)
	var sku_actual = sku_input.text.strip_edges()
	var sku_original = producto_original.get("sku", "")
	
	if modo_edicion == false or sku_actual != sku_original:
		# Verificar que el SKU no exista
		var productos_existentes = DataService.buscar_productos({"busqueda": sku_actual})
		for prod in productos_existentes:
			if str(prod.get("sku", "")).to_upper() == sku_actual.to_upper():
				if not modo_edicion or int(prod.get("id", 0)) != producto_id:
					errores.append("Ya existe un producto con ese código SKU")
					break
	
	return {
		"valido": errores.is_empty(),
		"errores": errores
	}

func recopilar_datos_formulario() -> Dictionary:
	"""Recopila todos los datos del formulario"""
	print("📦 [NUEVO_PRODUCTO] ===== RECOPILANDO DATOS =====")
	print("📦 [NUEVO_PRODUCTO] modo_edicion: ", modo_edicion)
	print("📦 [NUEVO_PRODUCTO] producto_id: ", producto_id)
	
	var tipos = ["REPUESTO", "ACCESORIO", "SERVICIO"]
	var tipo_seleccionado = tipos[tipo_option.selected] if tipo_option.selected < tipos.size() else "REPUESTO"
	
	var datos = {
		"sku": sku_input.text.strip_edges(),
		"nombre": nombre_input.text.strip_edges(),
		"categoria": categoria_input.text.strip_edges(),
		"tipo": tipo_seleccionado,
		"coste": coste_spinbox.value,
		"pvp": pvp_spinbox.value,
		"iva": iva_spinbox.value,
		"stock": int(stock_spinbox.value),
		"stock_min": int(stock_min_spinbox.value),
		"proveedor": proveedor_input.text.strip_edges()
	}
	
	# Si es edición, añadir el ID
	if modo_edicion and producto_id > 0:
		datos["id"] = producto_id
		print("📦 [NUEVO_PRODUCTO] ✅ ID añadido para edición: ", producto_id)
	else:
		print("📦 [NUEVO_PRODUCTO] ⚠️ Modo creación - NO se añade ID")
	
	print("📦 [NUEVO_PRODUCTO] Datos finales: ", datos)
	return datos

func _on_save_button_pressed():
	print("📦 [NUEVO_PRODUCTO] ===== BOTÓN GUARDAR PRESIONADO =====")
	
	# Verificar estado antes de guardar
	verificar_estado_edicion()
	
	# Validar formulario
	var validacion = validar_formulario()
	if not validacion.valido:
		mostrar_errores(validacion.errores)
		return
	
	# Recopilar datos
	var datos = recopilar_datos_formulario()
	print("📦 [NUEVO_PRODUCTO] Datos recopilados: ", datos)
	
	# Guardar producto
	var producto_id_resultado = DataService.guardar_producto(datos)
	print("📦 [NUEVO_PRODUCTO] Resultado del guardado: ", producto_id_resultado)
	
	if producto_id_resultado > 0:
		var accion = "creado" if not modo_edicion else "actualizado"
		print("✅ [NUEVO_PRODUCTO] Producto ", accion, " exitosamente - ID: ", producto_id_resultado)
		
		# Mostrar mensaje de éxito
		mostrar_mensaje_exito(accion)
		
		# Volver al inventario después de un breve delay
		await get_tree().create_timer(1.5).timeout
		Router.ir_a_inventario()
	else:
		print("❌ [NUEVO_PRODUCTO] Error al guardar producto")
		mostrar_mensaje_error("No se pudo guardar el producto. Inténtalo de nuevo.")

func _on_cancel_button_pressed():
	print("📦 [NUEVO_PRODUCTO] Cancelando...")
	Router.ir_a_inventario()

func mostrar_errores(errores: Array):
	"""Muestra los errores de validación"""
	var mensaje = "Se encontraron los siguientes errores:\n\n"
	for error in errores:
		mensaje += "• " + error + "\n"
	
	var dialog = AcceptDialog.new()
	dialog.title = "Errores de validación"
	dialog.dialog_text = mensaje
	add_child(dialog)
	dialog.popup_centered()
	
	await dialog.confirmed
	dialog.queue_free()

func mostrar_mensaje_exito(accion: String):
	"""Muestra mensaje de éxito"""
	var dialog = AcceptDialog.new()
	dialog.title = "Éxito"
	dialog.dialog_text = "Producto " + accion + " correctamente."
	add_child(dialog)
	dialog.popup_centered()
	
	await dialog.confirmed
	dialog.queue_free()

func mostrar_mensaje_error(mensaje: String):
	"""Muestra mensaje de error"""
	var dialog = AcceptDialog.new()
	dialog.title = "Error"
	dialog.dialog_text = mensaje
	add_child(dialog)
	dialog.popup_centered()
	
	await dialog.confirmed
	dialog.queue_free()