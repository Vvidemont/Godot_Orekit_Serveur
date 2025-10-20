extends OptionButton

@onready var hohman_param : GridContainer = $"../../GridContainerHohmann"
@onready var inclination_param : GridContainer = $"../../GridContainerInclination"
@onready var panel : Panel = $"../../../../.."
@onready var margin : MarginContainer = $"../../../.."
func _ready() -> void:
	select(0)

	# Connexion du signal (il passe l'index sélectionné)
	item_selected.connect(_on_item_selected)

	# État initial
	_on_item_selected(get_selected())

func _on_item_selected(index: int) -> void:
	match index:
		0:
			_hohman_selected()
			_autosize_panel()
		1:
			inclination_selected()
			_autosize_panel()
		_:
			# Sécurité
			hohman_param.visible = false
			inclination_param.visible = false

func _hohman_selected() -> void :
	hohman_param.visible = true
	inclination_param.visible = false


func inclination_selected() -> void :
	hohman_param.visible = false
	inclination_param.visible = true
	
func _autosize_panel() -> void:
	margin.queue_sort() # force le recalcul du layout
	await get_tree().process_frame
	var min := margin.get_combined_minimum_size()
	panel.custom_minimum_size = min  # le Panel s’adapte au contenu
