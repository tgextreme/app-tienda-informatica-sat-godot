extends RefCounted
class_name SATMigrations

# Sistema de migraciones para la base de datos SAT

static func run_migrations(db: Database):
	print("Ejecutando migraciones...")
	
	# Crear tabla de migraciones si no existe
	db.execute_non_query("CREATE TABLE IF NOT EXISTS migrations (version INTEGER PRIMARY KEY)")
	
	print("Migraciones completadas - sistema simplificado listo")

static func get_current_version(db: Database) -> int:
	var result = db.execute_sql("SELECT MAX(version) as version FROM migrations;")
	if result.size() > 0 and result[0].has("version") and result[0]["version"] != "":
		return int(result[0]["version"])
	return 0

static func record_migration(db: Database, migration: Dictionary):
	db.execute_non_query(
		"INSERT INTO migrations (version, name) VALUES (?, ?);",
		[migration.version, migration.name]
	)

static func execute_migration(db: Database, migration: Dictionary) -> bool:
	return db.execute_non_query(migration.sql)

static func get_all_migrations() -> Array:
	return [
		{
			"version": 1,
			"name": "Crear tablas base del sistema",
			"sql": """
-- Roles de usuarios
CREATE TABLE roles (
	id INTEGER PRIMARY KEY,
	nombre TEXT UNIQUE NOT NULL
);

INSERT INTO roles (id, nombre) VALUES 
	(1,'ADMIN'),
	(2,'TECNICO'),
	(3,'RECEPCION'),
	(4,'READONLY');

-- Usuarios del sistema
CREATE TABLE usuarios (
	id INTEGER PRIMARY KEY,
	nombre TEXT NOT NULL,
	email TEXT UNIQUE NOT NULL,
	pass_hash TEXT NOT NULL,
	rol_id INTEGER NOT NULL REFERENCES roles(id),
	activo INTEGER NOT NULL DEFAULT 1,
	creado_en TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Clientes
CREATE TABLE clientes (
	id INTEGER PRIMARY KEY,
	nombre TEXT NOT NULL,
	nif TEXT,
	email TEXT,
	telefono TEXT,
	telefono_alt TEXT,
	direccion TEXT,
	notas TEXT,
	rgpd_consent INTEGER DEFAULT 0,
	creado_en TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Productos (repuestos/servicios)
CREATE TABLE productos (
	id INTEGER PRIMARY KEY,
	sku TEXT UNIQUE,
	nombre TEXT NOT NULL,
	categoria TEXT,
	tipo TEXT NOT NULL DEFAULT 'REPUESTO', -- REPUESTO | SERVICIO
	coste REAL NOT NULL DEFAULT 0,
	pvp REAL NOT NULL DEFAULT 0,
	iva REAL NOT NULL DEFAULT 21,
	stock INTEGER NOT NULL DEFAULT 0,
	stock_min INTEGER NOT NULL DEFAULT 0,
	proveedor TEXT
);

-- Tickets SAT
CREATE TABLE tickets (
	id INTEGER PRIMARY KEY,
	codigo TEXT UNIQUE, -- ej: SAT-2025-000123
	estado TEXT NOT NULL DEFAULT 'Nuevo', 
	prioridad TEXT DEFAULT 'NORMAL', -- BAJA | NORMAL | ALTA | URGENTE
	cliente_id INTEGER NOT NULL REFERENCES clientes(id),
	tecnico_id INTEGER REFERENCES usuarios(id),
	fecha_entrada TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	fecha_presupuesto TEXT,
	fecha_aprobacion TEXT,
	fecha_entrega TEXT,
	fecha_cierre TEXT,
	equipo_tipo TEXT NOT NULL, -- PC | Portátil | Móvil | Impresora | Otro
	equipo_marca TEXT,
	equipo_modelo TEXT,
	numero_serie TEXT,
	imei TEXT,
	accesorios TEXT,
	password_bloqueo TEXT,
	averia_cliente TEXT,
	diagnostico TEXT,
	aprobacion_metodo TEXT, -- verbal | email | firma
	aprobacion_usuario_id INTEGER REFERENCES usuarios(id),
	notas_internas TEXT,
	notas_cliente TEXT
);

-- Líneas del ticket (repuestos y mano de obra)
CREATE TABLE ticket_lineas (
	id INTEGER PRIMARY KEY,
	ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
	tipo TEXT NOT NULL, -- REPUESTO | MO (mano de obra)
	producto_id INTEGER REFERENCES productos(id),
	descripcion TEXT NOT NULL,
	cantidad REAL NOT NULL DEFAULT 1,
	precio_unit REAL NOT NULL DEFAULT 0,
	iva REAL NOT NULL DEFAULT 21,
	total REAL NOT NULL
);

-- Tiempos imputados por técnico
CREATE TABLE ticket_tiempos (
	id INTEGER PRIMARY KEY,
	ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
	tecnico_id INTEGER NOT NULL REFERENCES usuarios(id),
	inicio TEXT NOT NULL,
	fin TEXT NOT NULL,
	minutos INTEGER NOT NULL,
	descripcion TEXT
);

-- Historial de eventos del ticket
CREATE TABLE ticket_historial (
	id INTEGER PRIMARY KEY,
	ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
	fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	usuario_id INTEGER REFERENCES usuarios(id),
	accion TEXT NOT NULL,
	detalle TEXT
);

-- Adjuntos
CREATE TABLE adjuntos (
	id INTEGER PRIMARY KEY,
	ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
	nombre_archivo TEXT NOT NULL,
	ruta TEXT NOT NULL,
	tipo_mime TEXT,
	subido_por INTEGER REFERENCES usuarios(id),
	subido_en TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Pagos / facturación ligera
CREATE TABLE ventas (
	id INTEGER PRIMARY KEY,
	ticket_id INTEGER UNIQUE REFERENCES tickets(id),
	tipo_doc TEXT NOT NULL, -- PRESUPUESTO | FACTURA_SIMPLIFICADA | FACTURA
	numero_doc TEXT UNIQUE,
	fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
	base REAL NOT NULL,
	iva REAL NOT NULL,
	total REAL NOT NULL,
	pagado REAL NOT NULL DEFAULT 0,
	forma_pago TEXT -- efectivo | tarjeta | transferencia | bizum
);

-- Configuración de la aplicación
CREATE TABLE configuracion (
	clave TEXT PRIMARY KEY,
	valor TEXT NOT NULL,
	descripcion TEXT
);

-- Datos iniciales de configuración
INSERT INTO configuracion (clave, valor, descripcion) VALUES
	('empresa_nombre', 'Mi Tienda SAT', 'Nombre de la empresa'),
	('empresa_nif', '', 'NIF/CIF de la empresa'),
	('empresa_direccion', '', 'Dirección de la empresa'),
	('empresa_telefono', '', 'Teléfono de la empresa'),
	('empresa_email', '', 'Email de la empresa'),
	('iva_defecto', '21', 'IVA por defecto (%)'),
	('wkhtmltopdf_path', '', 'Ruta al ejecutable wkhtmltopdf'),
	('ticket_prefix', 'SAT', 'Prefijo para códigos de ticket'),
	('backup_auto', '0', 'Backup automático activado'),
	('stock_negativo_permitido', '0', 'Permitir stock negativo');
"""
		},
		{
			"version": 2,
			"name": "Añadir índices para rendimiento",
			"sql": """
-- Índices recomendados
CREATE INDEX IF NOT EXISTS idx_tickets_estado ON tickets(estado);
CREATE INDEX IF NOT EXISTS idx_tickets_cliente ON tickets(cliente_id);
CREATE INDEX IF NOT EXISTS idx_tickets_tecnico ON tickets(tecnico_id);
CREATE INDEX IF NOT EXISTS idx_tickets_fecha_entrada ON tickets(fecha_entrada);
CREATE INDEX IF NOT EXISTS idx_productos_sku ON productos(sku);
CREATE INDEX IF NOT EXISTS idx_productos_categoria ON productos(categoria);
CREATE INDEX IF NOT EXISTS idx_clientes_busqueda ON clientes(nombre, telefono, email);
CREATE INDEX IF NOT EXISTS idx_ticket_lineas_ticket ON ticket_lineas(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_tiempos_ticket ON ticket_tiempos(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_historial_ticket ON ticket_historial(ticket_id);
CREATE INDEX IF NOT EXISTS idx_adjuntos_ticket ON adjuntos(ticket_id);
"""
		},
		{
			"version": 3,
			"name": "Crear usuario admin por defecto",
			"sql": """
-- Usuario administrador por defecto (password: admin123)
-- Hash BCrypt de 'admin123': $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewgcU7Cxm1tWLyO2
INSERT OR IGNORE INTO usuarios (id, nombre, email, pass_hash, rol_id) VALUES 
	(1, 'Administrador', 'admin@tienda-sat.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewgcU7Cxm1tWLyO2', 1);
"""
		}
	]