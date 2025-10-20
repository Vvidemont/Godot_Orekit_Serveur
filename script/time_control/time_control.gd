extends Control
# Le script gère une interface avec deux boutons et deux champs de texte.

@onready var button_val : Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ButtonVal
# Bouton pour valider les dates et lancer la simulation.
@onready var button_ret : Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ButtonRet
# Bouton pour revenir au menu principal.

@onready var line_timestart : LineEdit = $Panel/MarginContainer/VBoxContainer/GridContainer/LineEditts
# Champ texte pour l’heure de début de simulation.
@onready var line_timeend: LineEdit = $Panel/MarginContainer/VBoxContainer/GridContainer/LineEditte
# Champ texte pour l’heure de fin de simulation.

func _ready() -> void:
	# Connecte les signaux des boutons à leurs fonctions respectives.
	button_val.pressed.connect(_on_button_val__pressed)
	button_ret.pressed.connect(_on_button_ret_pressed)

func _on_button_val__pressed()-> void:
	# Récupère les textes saisis et enlève les espaces inutiles.
	Global.sim_start = line_timestart.text.strip_edges()
	Global.sim_end = line_timeend.text.strip_edges()

	# Convertit les chaînes en dictionnaires de type datetime.
	var start_dt := Time.get_datetime_dict_from_datetime_string(Global.sim_start, true)
	var end_dt   := Time.get_datetime_dict_from_datetime_string(Global.sim_end, true)

	# Convertit ces dates en timestamps UNIX.
	var start_unix := Time.get_unix_time_from_datetime_dict(start_dt)
	var end_unix   := Time.get_unix_time_from_datetime_dict(end_dt)

	# Calcule la différence de temps en secondes.
	var diff_sec = end_unix - start_unix
	print("Secondes écoulées : ", diff_sec)

	# Stocke la durée totale dans une variable globale.
	Global.sim_duration = diff_sec
	get_tree().change_scene_to_file("res://scenes/simulation_3d.tscn")
	# Passe à la scène principale de simulation 3D.

func _on_button_ret_pressed() -> void :
	# Retourne à la fenêtre principale.
	get_tree().change_scene_to_file("res://scenes/fenêtre_principale.tscn")
