extends PointLight2D

@export var min_energy := 0.55
@export var max_energy := 1.15
@export var flicker_speed := 2.4
@export var flicker_amount := 0.22

var _phase := 0.0
var _base_energy := 1.0


func _ready() -> void:
	_base_energy = energy
	_phase = randf() * TAU


func _process(delta: float) -> void:
	_phase += delta * flicker_speed
	var wave := sin(_phase) * flicker_amount + sin(_phase * 2.7) * (flicker_amount * 0.35)
	energy = clampf(_base_energy + wave, min_energy, max_energy)
