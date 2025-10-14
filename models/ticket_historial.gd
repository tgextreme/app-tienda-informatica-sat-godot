extends RefCounted
class_name TicketHistorial

# Entrada del historial de un ticket

var id: int = -1
var ticket_id: int = -1
var fecha: String = ""
var usuario_id: int = -1
var usuario_nombre: String = ""
var accion: String = ""
var detalle: String = ""

func _init(data: Dictionary = {}):
	cargar_desde_diccionario(data)

func cargar_desde_diccionario(data: Dictionary):
	if data.has("id"): id = int(data.id)
	if data.has("ticket_id"): ticket_id = int(data.ticket_id)
	if data.has("fecha"): fecha = data.fecha
	if data.has("usuario_id"): usuario_id = int(data.usuario_id)
	if data.has("usuario_nombre"): usuario_nombre = data.usuario_nombre
	if data.has("accion"): accion = data.accion
	if data.has("detalle"): detalle = data.detalle

func a_diccionario() -> Dictionary:
	return {
		"id": id,
		"ticket_id": ticket_id,
		"fecha": fecha,
		"usuario_id": usuario_id,
		"accion": accion,
		"detalle": detalle
	}