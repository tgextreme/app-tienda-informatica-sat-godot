extends RefCounted
class_name TicketTiempo

# Tiempo imputado en un ticket

var id: int = -1
var ticket_id: int = -1
var tecnico_id: int = -1
var tecnico_nombre: String = ""
var inicio: String = ""
var fin: String = ""
var minutos: int = 0
var descripcion: String = ""

func _init(data: Dictionary = {}):
	cargar_desde_diccionario(data)

func cargar_desde_diccionario(data: Dictionary):
	if data.has("id"): id = int(data.id)
	if data.has("ticket_id"): ticket_id = int(data.ticket_id)
	if data.has("tecnico_id"): tecnico_id = int(data.tecnico_id)
	if data.has("tecnico_nombre"): tecnico_nombre = data.tecnico_nombre
	if data.has("inicio"): inicio = data.inicio
	if data.has("fin"): fin = data.fin
	if data.has("minutos"): minutos = int(data.minutos)
	if data.has("descripcion"): descripcion = data.descripcion

func a_diccionario() -> Dictionary:
	return {
		"id": id,
		"ticket_id": ticket_id,
		"tecnico_id": tecnico_id,
		"inicio": inicio,
		"fin": fin,
		"minutos": minutos,
		"descripcion": descripcion
	}

func obtener_duracion_formateada() -> String:
	var horas = minutos / 60
	var mins = minutos % 60
	return "%dh %02dm" % [horas, mins]