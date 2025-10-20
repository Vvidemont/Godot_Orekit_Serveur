extends Control
# Interface d’affichage des informations d’un satellite sélectionné.

@onready var label_name : Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Labelname
# Label affichant le nom du satellite.
@onready var color : ColorRect = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ColorRect
# Rectangle coloré représentant la couleur du satellite.
@onready var ret_button : Button = $Panel/MarginContainer/VBoxContainer/Buttonret
# Bouton pour revenir à la liste des satellites.
@onready var test : Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/Labela
# Label affichant une donnée orbitale (ex : demi-grand axe).

func _ready() -> void:
	# Initialise l’interface et connecte le bouton retour.
	ret_button.pressed.connect(_on_retour)
	
	# Récupère le satellite sélectionné via son ID global.
	var sat_id: int = Global.id_info
	var sat: SatelliteRegistry.Satellite = SatelliteRegistry.get_one(sat_id)
	
	# Met à jour les éléments visuels avec les infos du satellite.
	label_name.text = str(sat.name)
	color.color = sat.color
	
	# Récupère les données d’entrée associées au satellite.
	var meta: Dictionary = sat.meta_input
	if meta.has("a"):
		test.text = str(int(meta["a"]) * 1e-3) + " km"
		# Affiche le demi-grand axe en kilomètres (conversion m → km).

func _on_retour() -> void:
	# Réinitialise l’ID global et retourne à la liste des satellites.
	Global.id_info = null
	var ui_parent := get_parent()
	var form_sat: PackedScene = load("res://scenes/listes_satellites.tscn")
	var form := form_sat.instantiate()
	ui_parent.add_child(form)
	queue_free()
