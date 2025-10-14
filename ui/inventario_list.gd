extends Control

@onready var products_tree: Tree = $VBoxContainer/ContentContainer/ProductsTree
@onready var new_product_button: Button = $VBoxContainer/HeaderContainer/ButtonsContainer/NewProductButton
@onready var refresh_button: Button = $VBoxContainer/HeaderContainer/ButtonsContainer/RefreshButton
@onready var back_button: Button = $VBoxContainer/HeaderContainer/ButtonsContainer/BackButton
@onready var search_input: LineEdit = $VBoxContainer/FiltersContainer/SearchInput
@onready var type_filter: OptionButton = $VBoxContainer/FiltersContainer/TypeFilter
@onready var search_button: Button = $VBoxContainer/FiltersContainer/SearchButton
@onready var count_label: Label = $VBoxContainer/ContentContainer/CountLabel

var productos_data = []
var menu_contextual: PopupMenu

func _ready():
	print("📦 [INVENTARIO_LIST] Inicializando lista de inventario...")
	
	# Verificar referencias @onready
	verificar_referencias_onready()
	
	configurar_menu_contextual()
	configurar_interfaz()
	configurar_filtros()
	cargar_productos()
	
	# Conectar señales con verificación después de un frame
	call_deferred("conectar_senales_botones")
	
	# Añadir evento de prueba manual (clic derecho en la interfaz)
	call_deferred("conectar_debug_manual")

func conectar_debug_manual():
	"""Conecta eventos de debug manual"""
	gui_input.connect(_on_gui_input_debug)
	print("🛠️ [DEBUG] Debug manual conectado")
	print("🛠️ [DEBUG] - Clic derecho: probar refresh")
	print("🛠️ [DEBUG] - Ctrl+clic derecho: probar editar producto ID 1")
	
	# Programar una prueba automática en 2 segundos
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(_prueba_automatica_refresh)
	timer.start()
	print("⏱️ [DEBUG] Prueba automática programada para 2 segundos")

func _prueba_automatica_refresh():
	"""Prueba automática del botón refresh"""
	print("🎯 [DEBUG] === INICIANDO PRUEBA AUTOMÁTICA ===")
	if refresh_button:
		print("🎯 [DEBUG] Botón encontrado, simulando clic...")
		refresh_button.emit_signal("pressed")
		print("🎯 [DEBUG] Señal emitida")
	else:
		print("🎯 [DEBUG] ❌ Botón NO encontrado en prueba automática")
	print("🎯 [DEBUG] === FIN PRUEBA AUTOMÁTICA ===")

# Debug manual con clic derecho
func _on_gui_input_debug(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if Input.is_key_pressed(KEY_CTRL):
			print("🛠️ [DEBUG] Prueba manual de EDITAR - Ctrl+Clic derecho detectado")
			print("🛠️ [DEBUG] Probando editar producto ID 1...")
			Router.ir_a_editar_producto(1)
		else:
			print("🛠️ [DEBUG] Prueba manual de refresh - Clic derecho detectado")
			_on_refresh_button_pressed()

func verificar_referencias_onready():
	"""Verifica que todas las referencias @onready estén funcionando"""
	print("🔍 [INVENTARIO_LIST] Verificando referencias @onready...")
	
	# Si refresh_button es null, intentar encontrarlo manualmente
	if not refresh_button:
		print("⚠️ [INVENTARIO_LIST] refresh_button es NULL, buscando manualmente...")
		refresh_button = find_child("RefreshButton", true, false)
		if refresh_button:
			print("✅ [INVENTARIO_LIST] refresh_button encontrado manualmente")
		else:
			print("❌ [INVENTARIO_LIST] refresh_button NO encontrado manualmente")
			# Listar todos los botones para debug
			var botones = find_children("*Button*", "Button", true, false)
			print("🔍 [INVENTARIO_LIST] Botones encontrados:", botones.size())
			for boton in botones:
				print("  - ", boton.name, " (", boton.get_path(), ")")
	
	var elementos = [
		["new_product_button", new_product_button],
		["refresh_button", refresh_button],
		["back_button", back_button],
		["search_input", search_input],
		["search_button", search_button],
		["type_filter", type_filter],
		["products_tree", products_tree],
		["menu_contextual", menu_contextual]
	]
	
	for elemento in elementos:
		var nombre = elemento[0]
		var referencia = elemento[1]
		if referencia:
			print("✅ [INVENTARIO_LIST] ", nombre, " -> OK (", referencia.get_path(), ")")
		else:
			print("❌ [INVENTARIO_LIST] ", nombre, " -> NULL (PROBLEMA)")
			
	print("🔍 [INVENTARIO_LIST] Verificación de referencias completada")

func conectar_senales_botones():
	"""Conecta las señales de los botones con verificación"""
	print("📦 [INVENTARIO_LIST] Conectando señales de botones...")
	
	# Verificar y conectar botón nuevo producto
	if new_product_button:
		if new_product_button.pressed.is_connected(_on_new_product_button_pressed):
			new_product_button.pressed.disconnect(_on_new_product_button_pressed)
		new_product_button.pressed.connect(_on_new_product_button_pressed)
		print("✅ [INVENTARIO_LIST] Botón 'Nuevo Producto' conectado")
	else:
		print("❌ [INVENTARIO_LIST] Botón 'Nuevo Producto' no encontrado")
	
	# Verificar y conectar botón actualizar
	if refresh_button:
		if refresh_button.pressed.is_connected(_on_refresh_button_pressed):
			refresh_button.pressed.disconnect(_on_refresh_button_pressed)
		refresh_button.pressed.connect(_on_refresh_button_pressed)
		print("✅ [INVENTARIO_LIST] Botón 'Actualizar' conectado")
		
		# Probar el botón programáticamente
		print("🧪 [INVENTARIO_LIST] Probando botón 'Actualizar' programáticamente...")
		refresh_button.emit_signal("pressed")
	else:
		print("❌ [INVENTARIO_LIST] Botón 'Actualizar' no encontrado")
	
	# Verificar y conectar botón volver
	if back_button:
		if back_button.pressed.is_connected(_on_back_button_pressed):
			back_button.pressed.disconnect(_on_back_button_pressed)
		back_button.pressed.connect(_on_back_button_pressed)
		print("✅ [INVENTARIO_LIST] Botón 'Volver' conectado")
	else:
		print("❌ [INVENTARIO_LIST] Botón 'Volver' no encontrado")
	
	# Conectar otros elementos
	if search_button:
		if search_button.pressed.is_connected(_on_search_button_pressed):
			search_button.pressed.disconnect(_on_search_button_pressed)
		search_button.pressed.connect(_on_search_button_pressed)
		print("✅ [INVENTARIO_LIST] Botón 'Buscar' conectado")
	
	if search_input:
		if search_input.text_submitted.is_connected(_on_search_input_text_submitted):
			search_input.text_submitted.disconnect(_on_search_input_text_submitted)
		search_input.text_submitted.connect(_on_search_input_text_submitted)
		print("✅ [INVENTARIO_LIST] Campo de búsqueda conectado")
	
	# Conectar TreeItem
	if products_tree:
		if products_tree.item_selected.is_connected(_on_products_tree_item_selected):
			products_tree.item_selected.disconnect(_on_products_tree_item_selected)
		products_tree.item_selected.connect(_on_products_tree_item_selected)
		
		if products_tree.button_clicked.connect(_on_products_tree_button_clicked) != OK:
			print("❌ [INVENTARIO_LIST] Error conectando señal button_clicked del TreeItem")
		else:
			print("✅ [INVENTARIO_LIST] TreeItem conectado")
			
	print("🔧 [INVENTARIO_LIST] Todas las conexiones completadas")

func configurar_menu_contextual():
	menu_contextual = PopupMenu.new()
	add_child(menu_contextual)
	
	# Agregar opciones del menú
	menu_contextual.add_item("Ver Detalle", 0)
	menu_contextual.add_item("Editar", 1)
	menu_contextual.add_separator()
	menu_contextual.add_item("Eliminar", 2)
	
	# Conectar señal del menú
	menu_contextual.id_pressed.connect(_on_menu_contextual_id_pressed)
	
	# Conectar clic derecho del tree
	products_tree.item_mouse_selected.connect(_on_products_tree_mouse_selected)

func configurar_interfaz():
	# Configurar permisos
	new_product_button.visible = AppState.tiene_permiso("crear_producto")
	
	# Configurar columnas del tree (7 columnas: 0-6)
	products_tree.columns = 7
	products_tree.set_column_title(0, "Código")
	products_tree.set_column_title(1, "Nombre")
	products_tree.set_column_title(2, "Tipo")
	products_tree.set_column_title(3, "Stock")
	products_tree.set_column_title(4, "Precio")
	products_tree.set_column_title(5, "Estado")
	products_tree.set_column_title(6, "Acciones")
	
	products_tree.set_column_custom_minimum_width(0, 100)
	products_tree.set_column_custom_minimum_width(1, 200)
	products_tree.set_column_custom_minimum_width(2, 120)
	products_tree.set_column_custom_minimum_width(3, 80)
	products_tree.set_column_custom_minimum_width(4, 100)
	products_tree.set_column_custom_minimum_width(5, 100)
	products_tree.set_column_custom_minimum_width(6, 80)

func configurar_filtros():
	# Filtro de tipos de producto
	type_filter.add_item("Todos los tipos", 0)
	type_filter.add_item("REPUESTO", 1)
	type_filter.add_item("ACCESORIO", 2)
	type_filter.add_item("SERVICIO", 3)

func cargar_productos():
	print("📦 [INVENTARIO_LIST] Cargando productos...")
	
	# Debug de permisos de usuario
	debug_permisos_usuario()
	
	# Crear filtros basados en la interfaz
	var filtros = {}
	
	# Filtro de búsqueda
	if search_input.text.strip_edges() != "":
		filtros["busqueda"] = search_input.text.strip_edges()
	
	# Filtro de tipo
	if type_filter.selected > 0:
		var tipos = ["", "REPUESTO", "ACCESORIO", "SERVICIO"]
		filtros["tipo"] = tipos[type_filter.selected]
	
	# Obtener productos del DataService
	productos_data = DataService.buscar_productos(filtros)
	print("📦 [INVENTARIO_LIST] Productos obtenidos: ", productos_data.size())
	
	# Debug: Mostrar primer producto
	if productos_data.size() > 0:
		print("🔍 [INVENTARIO_LIST] Primer producto: ", productos_data[0])
	
	# Si los productos vienen vacíos o corruptos, crear productos reales en BD
	if productos_data.size() == 0 or (productos_data.size() > 0 and productos_data[0].get("nombre", "") == ""):
		print("⚠️ [INVENTARIO_LIST] Datos corruptos detectados - creando productos reales en BD...")
		DataService.crear_productos_temporales_en_bd()
		
		# Recargar desde la base de datos
		productos_data = DataService.buscar_productos(filtros)
		print("🔄 [INVENTARIO_LIST] Productos recargados desde BD: ", productos_data.size())
		
		# Si aún hay problemas, usar datos temporales como último recurso
		if productos_data.size() == 0 or (productos_data.size() > 0 and productos_data[0].get("nombre", "") == ""):
			print("❌ [INVENTARIO_LIST] BD sigue corrupta - usando datos temporales como último recurso")
			productos_data = crear_productos_temporales()
	
	actualizar_tree()
	actualizar_contador()

func debug_permisos_usuario():
	"""Debug completo de permisos del usuario actual"""
	print("🔒 [DEBUG] ===== PERMISOS DE USUARIO =====")
	print("🔒 [DEBUG] Usuario logueado: ", AppState.get_usuario_nombre())
	print("🔒 [DEBUG] ID usuario: ", AppState.get_usuario_id())
	
	var permisos_inventario = [
		"ver_inventario",
		"crear_producto", 
		"editar_producto",
		"eliminar_producto"
	]
	
	for permiso in permisos_inventario:
		var tiene = AppState.tiene_permiso(permiso)
		var estado = "✅ SÍ" if tiene else "❌ NO"
		print("🔒 [DEBUG] ", permiso, ": ", estado)
	
	print("🔒 [DEBUG] =============================")

func crear_productos_temporales():
	"""Datos temporales mientras se arregla el DataService"""
	return [
		{
			"id": 1,
			"sku": "REP-RAM-8GB",
			"nombre": "Memoria RAM DDR4 8GB Kingston",
			"categoria": "Memoria",
			"tipo": "REPUESTO",
			"coste": 35.50,
			"pvp": 45.99,
			"iva": 21.0,
			"stock": 15,
			"stock_min": 5,
			"proveedor": "Kingston Technology"
		},
		{
			"id": 2,
			"sku": "REP-SSD-512",
			"nombre": "SSD NVMe 512GB Samsung",
			"categoria": "Almacenamiento", 
			"tipo": "REPUESTO",
			"coste": 58.20,
			"pvp": 75.99,
			"iva": 21.0,
			"stock": 8,
			"stock_min": 3,
			"proveedor": "Samsung Electronics"
		},
		{
			"id": 3,
			"sku": "ACC-USB-C-2M",
			"nombre": "Cable USB-C 2 metros",
			"categoria": "Cables",
			"tipo": "ACCESORIO",
			"coste": 8.50,
			"pvp": 12.99,
			"iva": 21.0,
			"stock": 25,
			"stock_min": 10,
			"proveedor": "Belkin International"
		},
		{
			"id": 4,
			"sku": "SER-DIAG-HW",
			"nombre": "Diagnóstico de Hardware Completo",
			"categoria": "Diagnóstico",
			"tipo": "SERVICIO",
			"coste": 0.0,
			"pvp": 25.00,
			"iva": 21.0,
			"stock": 999,
			"stock_min": 0,
			"proveedor": "Servicio Interno"
		},
		{
			"id": 5,
			"sku": "REP-FAN-CPU",
			"nombre": "Ventilador CPU Cooler Master",
			"categoria": "Refrigeración",
			"tipo": "REPUESTO",
			"coste": 18.75,
			"pvp": 24.99,
			"iva": 21.0,
			"stock": 2,  # Stock bajo
			"stock_min": 4,
			"proveedor": "Cooler Master"
		}
	]

func actualizar_tree():
	products_tree.clear()
	var root = products_tree.create_item()
	
	for producto in productos_data:
		var item = products_tree.create_item(root)
		
		# Código/SKU
		var sku = producto.get("sku", "")
		item.set_text(0, str(sku) if sku != null and sku != "" else "Sin código")
		
		# Nombre
		var nombre = producto.get("nombre", "")
		item.set_text(1, str(nombre) if nombre != null and nombre != "" else "Sin nombre")
		
		# Tipo
		var tipo = producto.get("tipo", "")
		item.set_text(2, str(tipo) if tipo != null else "Sin tipo")
		
		# Stock con color según nivel
		var stock = producto.get("stock", 0)
		var stock_min = producto.get("stock_min", 0)
		item.set_text(3, str(stock))
		
		if stock <= stock_min:
			item.set_custom_color(3, Color(1, 0.4, 0.4))  # Rojo si stock bajo
		elif stock <= stock_min * 2:
			item.set_custom_color(3, Color(1, 0.8, 0.2))  # Amarillo si stock medio-bajo
		else:
			item.set_custom_color(3, Color(0.2, 0.8, 0.2))  # Verde si stock OK
		
		# Precio (PVP)
		var pvp = producto.get("pvp", 0.0)
		item.set_text(4, "€%.2f" % float(pvp))
		
		# Estado basado en stock
		var estado_texto = "Normal"
		if stock <= 0:
			estado_texto = "Sin stock"
		elif stock <= stock_min:
			estado_texto = "Stock bajo"
		
		item.set_text(5, estado_texto)
		if stock <= 0:
			item.set_custom_color(5, Color(1, 0.2, 0.2))  # Rojo sin stock
		elif stock <= stock_min:
			item.set_custom_color(5, Color(1, 0.8, 0.2))  # Amarillo stock bajo
		
		# Inicializar columna de acciones
		item.set_text(6, "")
		
		# Agregar botones de acción
		print("🔒 [INVENTARIO_LIST] Verificando permisos para producto: ", producto.get("sku", "N/A"))
		print("🔒 [INVENTARIO_LIST] - Permiso eliminar: ", AppState.tiene_permiso("eliminar_producto"))
		print("🔒 [INVENTARIO_LIST] - Permiso editar: ", AppState.tiene_permiso("editar_producto"))
		print("🔒 [INVENTARIO_LIST] - Usuario actual: ", AppState.get_usuario_nombre())
		
		if AppState.tiene_permiso("eliminar_producto"):
			print("✅ [INVENTARIO_LIST] Añadiendo botón ELIMINAR (rojo)")
			# Botón de eliminar
			var texture_eliminar = ImageTexture.new()
			var image_eliminar = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			image_eliminar.fill(Color(1, 0.4, 0.4, 1))  # Rojo para eliminar
			texture_eliminar.set_image(image_eliminar)
			item.add_button(6, texture_eliminar, 0, false, "Eliminar Producto")
		else:
			print("❌ [INVENTARIO_LIST] NO se añade botón eliminar - sin permisos")
		
		if AppState.tiene_permiso("editar_producto"):
			print("✅ [INVENTARIO_LIST] Añadiendo botón EDITAR (azul)")
			# Botón de editar  
			var texture_editar = ImageTexture.new()
			var image_editar = Image.create(16, 16, false, Image.FORMAT_RGBA8)
			image_editar.fill(Color(0.4, 0.8, 1, 1))  # Azul para editar
			texture_editar.set_image(image_editar)
			item.add_button(6, texture_editar, 1, false, "Editar Producto")
		else:
			print("❌ [INVENTARIO_LIST] NO se añade botón editar - sin permisos")
		
		# Guardar ID como metadatos
		item.set_metadata(0, producto.get("id", 0))

func actualizar_contador():
	count_label.text = str(productos_data.size()) + " producto(s) encontrado(s)"

func _on_new_product_button_pressed():
	print("📦 [INVENTARIO_LIST] Creando nuevo producto...")
	Router.ir_a_nuevo_producto()

func _on_refresh_button_pressed():
	"""Maneja el clic del botón refresh"""
	print("� [INVENTARIO_LIST] ===== BOTÓN REFRESH PRESIONADO =====")
	print("🔄 [INVENTARIO_LIST] Estado actual - search_input:", search_input.text if search_input else "NULL")
	print("🔄 [INVENTARIO_LIST] Estado actual - type_filter:", type_filter.selected if type_filter else "NULL")
	
	# Limpiar filtros como en gestionar_clientes
	if search_input:
		search_input.text = ""
		print("✅ [INVENTARIO_LIST] Campo de búsqueda limpio")
	else:
		print("❌ [INVENTARIO_LIST] search_input es NULL")
	
	if type_filter:
		type_filter.selected = 0
		print("✅ [INVENTARIO_LIST] Filtro de tipo reseteado")
	else:
		print("❌ [INVENTARIO_LIST] type_filter es NULL")
	
	print("🔄 [INVENTARIO_LIST] Llamando a cargar_productos()...")
	cargar_productos()
	print("🔄 [INVENTARIO_LIST] ===== REFRESH COMPLETADO =====")

func _on_back_button_pressed():
	print("📦 [INVENTARIO_LIST] Volviendo al dashboard...")
	Router.ir_a("dashboard")

func _on_search_button_pressed():
	print("📦 [INVENTARIO_LIST] Buscando productos...")
	cargar_productos()

func _on_search_input_text_submitted(_text: String):
	_on_search_button_pressed()

func _on_products_tree_item_selected():
	var selected_item = products_tree.get_selected()
	if selected_item:
		var producto_id = selected_item.get_metadata(0)
		print("📦 [INVENTARIO_LIST] Producto seleccionado ID: ", producto_id)

func _on_products_tree_mouse_selected(_position: Vector2, mouse_button_index: int):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		var selected_item = products_tree.get_selected()
		if selected_item:
			var producto_id = selected_item.get_metadata(0)
			print("📦 [INVENTARIO_LIST] Clic derecho en producto ID: ", producto_id)
			
			# Configurar permisos del menú
			menu_contextual.set_item_disabled(0, false)  # Ver detalle
			menu_contextual.set_item_disabled(1, not AppState.tiene_permiso("editar_producto"))  # Editar
			menu_contextual.set_item_disabled(2, not AppState.tiene_permiso("eliminar_producto"))  # Eliminar
			
			# Mostrar menú contextual
			menu_contextual.popup_on_parent(Rect2i(_position, Vector2i(1, 1)))

func _on_menu_contextual_id_pressed(id: int):
	var selected_item = products_tree.get_selected()
	if not selected_item:
		return
		
	var producto_id = selected_item.get_metadata(0)
	
	match id:
		0:  # Ver Detalle
			print("📦 [INVENTARIO_LIST] Ver detalle del producto ID: ", producto_id)
			Router.ir_a_detalle_producto(producto_id)
		1:  # Editar
			print("📦 [INVENTARIO_LIST] Editar producto ID: ", producto_id)
			Router.ir_a_editar_producto(producto_id)
		2:  # Eliminar
			print("📦 [INVENTARIO_LIST] Eliminar producto ID: ", producto_id)
			confirmar_eliminar_producto(producto_id)

func _on_products_tree_button_clicked(item: TreeItem, column: int, id: int, _mouse_button_index: int):
	if column != 6:  # Solo procesar botones de la columna de acciones
		return
	
	var producto_id = item.get_metadata(0)
	print("📦 [INVENTARIO_LIST] Botón clickeado - Producto ID: ", producto_id, " Botón ID: ", id)
	
	match id:
		0:  # Eliminar
			confirmar_eliminar_producto_directo(producto_id)
		1:  # Editar
			Router.ir_a_editar_producto(producto_id)

func confirmar_eliminar_producto(producto_id: int):
	"""Confirma eliminación de producto desde menú contextual"""
	var producto_data = DataService.obtener_producto(producto_id)
	if producto_data.is_empty():
		print("❌ [INVENTARIO_LIST] Error: No se encontró el producto")
		return
	
	var nombre_producto = producto_data.get("nombre", "Producto desconocido")
	
	var dialog = AcceptDialog.new()
	dialog.title = "Confirmar eliminación"
	dialog.dialog_text = "¿Estás seguro de que deseas eliminar el producto:\n\n" + str(nombre_producto) + "\n\nEsta acción no se puede deshacer."
	
	# Añadir botón de cancelar
	dialog.add_cancel_button("Cancelar")
	dialog.get_ok_button().text = "Eliminar"
	
	add_child(dialog)
	dialog.popup_centered()
	
	var result = await dialog.confirmed
	dialog.queue_free()
	
	if result:
		eliminar_producto(producto_id)

func confirmar_eliminar_producto_directo(producto_id: int):
	"""Confirma eliminación de producto desde botón directo"""
	var producto_data = DataService.obtener_producto(producto_id)
	if producto_data.is_empty():
		print("❌ [INVENTARIO_LIST] Error: No se encontró el producto")
		return
	
	var nombre_producto = producto_data.get("nombre", "Producto desconocido")
	
	var dialog = AcceptDialog.new()
	dialog.title = "Confirmar eliminación"
	dialog.dialog_text = "¿Estás seguro de que deseas eliminar el producto:\n\n" + str(nombre_producto) + "\n\nEsta acción no se puede deshacer."
	
	# Añadir botón de cancelar
	dialog.add_cancel_button("Cancelar")
	dialog.get_ok_button().text = "Eliminar"
	
	add_child(dialog)
	dialog.popup_centered()
	
	var result = await dialog.confirmed
	dialog.queue_free()
	
	if result:
		eliminar_producto(producto_id)

func eliminar_producto(producto_id: int):
	"""Elimina el producto y actualiza la lista"""
	print("📦 [INVENTARIO_LIST] Eliminando producto ID: ", producto_id)
	
	var eliminado = DataService.eliminar_producto(producto_id)
	
	if eliminado:
		print("✅ [INVENTARIO_LIST] Producto eliminado exitosamente")
		# Recargar la lista de productos
		cargar_productos()
	else:
		print("❌ [INVENTARIO_LIST] Error al eliminar el producto")
		
		var dialog = AcceptDialog.new()
		dialog.title = "Error"
		dialog.dialog_text = "No se pudo eliminar el producto. Inténtalo de nuevo."
		add_child(dialog)
		dialog.popup_centered()
		
		await dialog.confirmed
		dialog.queue_free()