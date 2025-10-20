extends Control
# Interface principale du menu de simulation (accès aux sous-menus).

@onready var btn_sat : Button = $Panel/MarginContainer/VBoxContainer/Button
# Bouton pour ouvrir le formulaire de création de satellite.
@onready var btn_list : Button = $Panel/MarginContainer/VBoxContainer/Button2
# Bouton pour ouvrir la liste des satellites existants.
@onready var btn_man : Button = $Panel/MarginContainer/VBoxContainer/Button3
# Bouton pour accéder à l’interface des manœuvres.

func _ready() -> void:
	# Connexion des signaux des boutons à leurs fonctions respectives.
	btn_sat.pressed.connect(_on_open_form_sat)
	btn_list.pressed.connect(_on_open_list_sat)
	btn_man.pressed.connect(_on_open_form_man)

func _on_open_form_sat() -> void :
	# Ouvre le formulaire de création de satellite.
	var ui_parent := get_parent()
	var form_sat: PackedScene = load("res://scenes/formulaire_satellite.tscn")
	var form := form_sat.instantiate()
	ui_parent.add_child(form)
	queue_free()  # Ferme le menu actuel.

func _on_open_list_sat() -> void:
	# Ouvre la liste de gestion des satellites.
	var ui_parent := get_parent()
	var form_sat: PackedScene = load("res://scenes/listes_satellites.tscn")
	var form := form_sat.instantiate()
	ui_parent.add_child(form)
	queue_free()

func _on_open_form_man() -> void :
	# Ouvre l’interface de création de manœuvre.
	var ui_parent := get_parent()
	var form_sat: PackedScene = load("res://scenes/Interface_Manoeuvre.tscn")
	var form := form_sat.instantiate()
	ui_parent.add_child(form)
	queue_free()
