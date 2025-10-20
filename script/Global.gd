extends Node
# Script autoload (singleton) accessible partout dans le projet.

var sim_start : String = ""
# Date ISO de début de simulation (ex: "2025-09-22T00:00:00Z").
var sim_end : String = ""
# Date ISO de fin de simulation.

var orbits_root: Node3D = null
# Référence à la racine où sont instanciées orbites/satellites (scène 3D).

var sim_duration
# Durée totale de la simulation (en secondes). → idéalement : int.
signal orbit_added(data: Array)
# Signal (optionnel) pour notifier l’ajout d’une trajectoire.

var actual_time
# Temps simulé courant (en secondes depuis sim_start). → idéalement : int.

var id_info
# ID du satellite actuellement sélectionné pour l’affichage d’infos.

var orbits: Array = []
# Stockage des trajectoires (si besoin de cache global).
