extends Control
# Interface d’affichage des informations d’un satellite sélectionné.

# Label affichant le nom du satellite.
@onready var label_name : Label = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Labelname
# Rectangle coloré représentant la couleur du satellite.
@onready var color : ColorRect = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ColorRect
# Bouton pour revenir à la liste des satellites.
@onready var ret_button : Button = $Panel/MarginContainer/VBoxContainer/Buttonret
# Bouton pour modifier les paramêtres initiaux du satellite.
@onready var modif_button : Button = $Panel/MarginContainer/VBoxContainer/Buttonmodif

# Paramètres décrits par l'utilisateur dans le formulaire.
@onready var paramp1 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Paramp1
@onready var paramp2 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Paramp2
@onready var paramp3 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Paramp3
@onready var paramp4 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Paramp4
@onready var paramp5 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Paramp5
@onready var paramp6 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Paramp6

# Label décrivant les paramètres
@onready var labelp1 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Labelp1
@onready var labelp2 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Labelp2
@onready var labelp3 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Labelp3
@onready var labelp4 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Labelp4
@onready var labelp5 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Labelp5
@onready var labelp6 : Label = $Panel/MarginContainer/VBoxContainer/GridContainer/Labelp6

var type
var meta: Dictionary
func _ready() -> void:
	# Initialise l’interface et connecte le bouton retour.
	ret_button.pressed.connect(_on_retour)
	modif_button.pressed.connect(_on_modif)
	
	# Récupère le satellite sélectionné via son ID global.
	var sat_id: int = Global.id_info
	var sat: SatelliteRegistry.Satellite = SatelliteRegistry.get_one(sat_id)
	
	# Met à jour les éléments visuels avec les infos du satellite.
	label_name.text = str(sat.name)
	color.color = sat.color
	
	# Récupère les données d’entrée associées au satellite.
	meta = sat.meta_input
	type = meta["type"]
	_set_text_label()
	


func _set_text_label() :
	# fonction qui écrit les infos du satellite
	
	if type == 0 :
		# Paramètres initiaux de type orbitaux
		labelp1.text = "a"
		labelp2.text = "e"
		labelp3.text = "i"
		labelp4.text = "RAAN"
		labelp5.text = "Argp"
		labelp6.text = "Ta"
		
		paramp1.text = str(int(meta["p1"]) * 1e-3) + " km"
		paramp2.text = str((meta["p2"]))
		paramp3.text = str(int(meta["p3"])) + " °"
		paramp4.text = str(int(meta["p4"])) + " °"
		paramp5.text = str(int(meta["p5"])) + " °"
		paramp6.text = str(int(meta["p6"])) + " °"
	else :
		# Paramètres initiaux de type cartésien
		labelp1.text = "X"
		labelp2.text = "Y"
		labelp3.text = "Z"
		labelp4.text = "VX"
		labelp5.text = "VY"
		labelp6.text = "VZ"
		
		paramp1.text = str(int(meta["p1"]) * 1e-3) + " km"
		paramp2.text = str(int(meta["p2"]) * 1e-3) + " km"
		paramp3.text = str(int(meta["p3"]) * 1e-3) + " km"
		paramp4.text = str((meta["p4"]) * 1e-3) + " km/s"
		paramp5.text = str((meta["p5"]) * 1e-3) + " km/s"
		paramp6.text = str((meta["p6"]) * 1e-3) + " km/s"

func _on_retour() -> void:
	# Réinitialise l’ID global et retourne à la liste des satellites.
	Global.id_info = null
	var ui_parent := get_parent()
	var form_sat: PackedScene = load("res://scenes/listes_satellites.tscn")
	var form := form_sat.instantiate()
	ui_parent.add_child(form)
	queue_free()

func _on_modif() -> void :
	var ui_parent := get_parent()
	var form_sat: PackedScene = load("res://scenes/formulaire_satellite.tscn")
	var form := form_sat.instantiate()
	ui_parent.add_child(form)
	queue_free()
	
