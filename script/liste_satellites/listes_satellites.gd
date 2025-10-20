extends Control
# Interface de gestion des satellites (liste, suppression, info).

@onready var item_list: ItemList = $Panel/MarginContainer/VBoxContainer/ItemList
# Liste affichant les satellites existants.
@onready var btn_delete: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Buttonsupr
# Bouton pour supprimer le satellite sélectionné.
@onready var btn_retour: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Buttonret
# Bouton pour revenir au menu précédent.
@onready var btn_info: Button = $Panel/MarginContainer/VBoxContainer/ButtonFocus
# Bouton pour afficher les informations détaillées d’un satellite.

var id_by_row: Array[int] = []
# Tableau associant chaque ligne de la liste à l’ID du satellite correspondant.

func _ready() -> void:
	# Initialise la liste et connecte les signaux nécessaires.
	_refresh()
	SatelliteRegistry.satellite_added.connect(func(_id): _refresh())
	SatelliteRegistry.satellite_removed.connect(func(_id): _refresh())
	btn_delete.pressed.connect(_on_delete_pressed)
	btn_retour.pressed.connect(_on_retour_pressed)
	btn_info.pressed.connect(_on_info_pressed)

func _refresh() -> void:
	# Recharge la liste complète des satellites depuis le registre.
	item_list.clear()
	id_by_row.clear()
	var sats := SatelliteRegistry.get_all()
	sats.sort_custom(func(a, b): return a.id < b.id)
	for s in sats:
		var row := item_list.item_count
		item_list.add_item(s.name)
		# Crée une icône colorée selon la couleur du satellite.
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(s.color)
		item_list.set_item_icon(row, ImageTexture.create_from_image(img))
		id_by_row.append(s.id)

func _on_delete_pressed() -> void:
	# Supprime le satellite sélectionné dans la liste.
	var sel := item_list.get_selected_items()
	if sel.is_empty():
		return
	SatelliteRegistry.remove_satellite(id_by_row[sel[0]])

func _on_retour_pressed() -> void:
	# Retourne au menu principal de simulation.
	var ui_parent := get_parent()
	var form_sat: PackedScene = load("res://scenes/formulaire_simulation.tscn")
	var form := form_sat.instantiate()
	ui_parent.add_child(form)
	queue_free()

func _on_info_pressed() -> void:
	# Ouvre la fenêtre d’informations du satellite sélectionné.
	var sel: PackedInt32Array = item_list.get_selected_items()
	if sel.is_empty():
		return
	var row: int = sel[0]
	var sat_id: int = id_by_row[row]

	Global.id_info = sat_id
	var ui_parent := get_parent()
	var form_sat: PackedScene = load("res://scenes/info_sat.tscn")
	var form := form_sat.instantiate()
	ui_parent.add_child(form)
	queue_free()
