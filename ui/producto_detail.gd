extends Control

# Referencias a los nodos
@onready var title_label: Label = $ScrollContainer/VBoxContainer/HeaderContainer/TitleContainer/TitleLabel
@onready var edit_button: Button = $ScrollContainer/VBoxContainer/HeaderContainer/TitleContainer/ButtonsContainer/EditButton
@onready var delete_button: Button = $ScrollContainer/VBoxContainer/HeaderContainer/TitleContainer/ButtonsContainer/DeleteButton
@onready var back_button: Button = $ScrollContainer/VBoxContainer/HeaderContainer/TitleContainer/ButtonsContainer/BackButton

# Referencias a los valores básicos
@onready var sku_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/BasicInfoContainer/BasicInfoCard/BasicInfoGrid/SkuValue
@onready var nombre_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/BasicInfoContainer/BasicInfoCard/BasicInfoGrid/NombreValue
@onready var categoria_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/BasicInfoContainer/BasicInfoCard/BasicInfoGrid/CategoriaValue
@onready var tipo_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/BasicInfoContainer/BasicInfoCard/BasicInfoGrid/TipoValue

# Referencias a los valores de precios
@onready var coste_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/PreciosContainer/PreciosCard/PreciosGrid/CosteValue
@onready var pvp_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/PreciosContainer/PreciosCard/PreciosGrid/PvpValue
@onready var iva_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/PreciosContainer/PreciosCard/PreciosGrid/IvaValue
@onready var margen_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/PreciosContainer/PreciosCard/PreciosGrid/MargenValue

# Referencias a los valores de stock
@onready var stock_actual_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/StockContainer/StockCard/StockGrid/StockActualValue
@onready var stock_min_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/StockContainer/StockCard/StockGrid/StockMinValue
@onready var estado_stock_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/StockContainer/StockCard/StockGrid/EstadoStockValue

# Referencia al proveedor
@onready var proveedor_value: Label = $ScrollContainer/VBoxContainer/ContentContainer/ProveedorContainer/ProveedorCard/ProveedorValue

# Variables de control
var producto_id: int = -1
var producto_data: Dictionary = {}

func _ready():
	print("📦 [PRODUCTO_DETAIL] Inicializando detalle del producto...")
	configurar_interfaz()
	conectar_senales()
	
	# Obtener ID del producto desde parámetros
	var parametros = Router.obtener_parametros_actuales()
	producto_id = parametros.get("producto_id", -1)
	
	if producto_id > 0:
		cargar_producto()
	else:
		print("❌ [PRODUCTO_DETAIL] Error: No se especificó ID del producto")
		Router.ir_a_inventario()

func configurar_interfaz():
	# Configurar permisos de botones
	edit_button.visible = AppState.tiene_permiso("editar_producto")
	delete_button.visible = AppState.tiene_permiso("eliminar_producto")

func conectar_senales():
	edit_button.pressed.connect(_on_edit_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func cargar_producto():
	print("📦 [PRODUCTO_DETAIL] Cargando producto ID: ", producto_id)
	
	producto_data = DataService.obtener_producto(producto_id)
	
	if producto_data.is_empty():
		print("❌ [PRODUCTO_DETAIL] Error: No se encontró el producto")
		mostrar_mensaje_error("No se encontró el producto solicitado.")
		await get_tree().create_timer(2.0).timeout
		Router.ir_a_inventario()
		return
	
	mostrar_datos_producto()

func mostrar_datos_producto():
	print("📦 [PRODUCTO_DETAIL] Mostrando datos del producto...")
	
	# Actualizar título
	var nombre = str(producto_data.get("nombre", "Producto sin nombre"))
	title_label.text = "Detalle: " + nombre
	
	# Información básica
	sku_value.text = str(producto_data.get("sku", "-"))
	nombre_value.text = nombre
	categoria_value.text = str(producto_data.get("categoria", "-"))
	tipo_value.text = str(producto_data.get("tipo", "-"))
	
	# Precios
	var coste = float(producto_data.get("coste", 0.0))
	var pvp = float(producto_data.get("pvp", 0.0))
	var iva = float(producto_data.get("iva", 21.0))
	
	coste_value.text = "€%.2f" % coste
	pvp_value.text = "€%.2f" % pvp
	iva_value.text = "%.1f%%" % iva
	
	# Calcular y mostrar margen
	if coste > 0:
		var margen_euros = pvp - coste
		var margen_porcentaje = (margen_euros / coste) * 100.0
		margen_value.text = "%.2f%% (€%.2f)" % [margen_porcentaje, margen_euros]
		
		# Colorear según el margen
		if margen_porcentaje < 10:
			margen_value.modulate = Color(1, 0.4, 0.4)  # Rojo - margen bajo
		elif margen_porcentaje < 25:
			margen_value.modulate = Color(1, 0.8, 0.2)  # Amarillo - margen medio
		else:
			margen_value.modulate = Color(0.2, 0.8, 0.2)  # Verde - buen margen
	else:
		margen_value.text = "No calculable"
		margen_value.modulate = Color.WHITE
	
	# Stock
	var stock = int(producto_data.get("stock", 0))
	var stock_min = int(producto_data.get("stock_min", 0))
	
	stock_actual_value.text = str(stock)
	stock_min_value.text = str(stock_min)
	
	# Estado del stock con colores
	var estado_texto = ""
	var color_estado = Color.WHITE
	
	if stock <= 0:
		estado_texto = "SIN STOCK"
		color_estado = Color(1, 0.2, 0.2)  # Rojo
	elif stock <= stock_min:
		estado_texto = "STOCK BAJO"
		color_estado = Color(1, 0.8, 0.2)  # Amarillo
	elif stock <= stock_min * 2:
		estado_texto = "Stock Medio"
		color_estado = Color(1, 0.6, 0.2)  # Naranja
	else:
		estado_texto = "Stock OK"
		color_estado = Color(0.2, 0.8, 0.2)  # Verde
	
	estado_stock_value.text = estado_texto
	estado_stock_value.modulate = color_estado
	
	# También colorear el stock actual
	stock_actual_value.modulate = color_estado
	
	# Proveedor
	var proveedor = str(producto_data.get("proveedor", ""))
	proveedor_value.text = proveedor if proveedor != "" else "Sin proveedor especificado"

func _on_edit_button_pressed():
	print("📦 [PRODUCTO_DETAIL] Editando producto...")
	Router.ir_a_editar_producto(producto_id)

func _on_delete_button_pressed():
	print("📦 [PRODUCTO_DETAIL] Eliminando producto...")
	confirmar_eliminar_producto()

func _on_back_button_pressed():
	print("📦 [PRODUCTO_DETAIL] Volviendo al inventario...")
	Router.ir_a_inventario()

func confirmar_eliminar_producto():
	"""Confirma la eliminación del producto"""
	var nombre_producto = str(producto_data.get("nombre", "Producto desconocido"))
	
	var dialog = AcceptDialog.new()
	dialog.title = "Confirmar eliminación"
	dialog.dialog_text = "¿Estás seguro de que deseas eliminar el producto:\n\n" + nombre_producto + "\n\nEsta acción no se puede deshacer."
	
	# Añadir botón de cancelar
	dialog.add_cancel_button("Cancelar")
	dialog.get_ok_button().text = "Eliminar"
	
	add_child(dialog)
	dialog.popup_centered()
	
	var result = await dialog.confirmed
	dialog.queue_free()
	
	if result:
		eliminar_producto()

func eliminar_producto():
	"""Elimina el producto actual"""
	print("📦 [PRODUCTO_DETAIL] Eliminando producto ID: ", producto_id)
	
	var eliminado = DataService.eliminar_producto(producto_id)
	
	if eliminado:
		print("✅ [PRODUCTO_DETAIL] Producto eliminado exitosamente")
		mostrar_mensaje_exito("Producto eliminado correctamente.")
		
		# Volver al inventario después del mensaje
		await get_tree().create_timer(1.5).timeout
		Router.ir_a_inventario()
	else:
		print("❌ [PRODUCTO_DETAIL] Error al eliminar el producto")
		mostrar_mensaje_error("No se pudo eliminar el producto. Inténtalo de nuevo.")

func mostrar_mensaje_exito(mensaje: String):
	"""Muestra mensaje de éxito"""
	var dialog = AcceptDialog.new()
	dialog.title = "Éxito"
	dialog.dialog_text = mensaje
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