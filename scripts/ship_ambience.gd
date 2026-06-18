extends Node2D

const LIGHT_TEXTURE := "res://assets/2d_lights_and_shadows_neutral_point_light.png"

const LIGHT_POSITIONS: Array = [
	Vector2(250, 200),
	Vector2(420, 260),
	Vector2(560, 320),
	Vector2(340, 420),
	Vector2(480, 500),
	Vector2(200, 520),
	Vector2(620, 560),
	Vector2(300, 600),
	Vector2(450, 640),
]

const FLICKER_INDICES := [1, 4, 7]


func _ready() -> void:
	var light_texture: Texture2D = load(LIGHT_TEXTURE)
	var flicker_script: Script = load("res://scripts/flickering_light.gd")

	for index in LIGHT_POSITIONS.size():
		var light := PointLight2D.new()
		light.name = "CorridorLight_%02d" % (index + 1)
		light.position = LIGHT_POSITIONS[index]
		light.texture = light_texture
		light.texture_scale = 0.55
		light.energy = 0.95
		light.color = Color(0.75, 0.88, 1.0)
		light.shadow_enabled = false
		if index in FLICKER_INDICES:
			light.set_script(flicker_script)
			light.set("min_energy", 0.45)
			light.set("max_energy", 1.05)
			light.set("flicker_speed", randf_range(1.8, 3.2))
		add_child(light)
