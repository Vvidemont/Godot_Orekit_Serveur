extends Control
# Le script contrôle une interface utilisateur (hérite de Control).

@onready var button_simsat : Button = $Panel/MarginContainer/VBoxContainer/ButtonSimSat
# Référence au bouton "ButtonSimSat" dans la hiérarchie de la scène.

func _ready() -> void:
	# Appelée quand la scène est prête.
	button_simsat.pressed.connect(_on_button_simsat_pressed)
	# Connecte le clic du bouton à la fonction de gestion.

func _on_button_simsat_pressed() -> void:
	# Fonction exécutée quand le bouton est cliqué.
	get_tree().change_scene_to_file("res://scenes/time_control.tscn")
	# Change la scène actuelle vers "time_control.tscn".
