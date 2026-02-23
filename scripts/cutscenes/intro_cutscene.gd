extends Control

signal cutscene_finished

@onready var fade_rect: ColorRect = $FadeRect
@onready var image: TextureRect = $Image
@onready var label: Label = $Label
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var slides: Array = []
var current_slide: int = 0
var is_skipping: bool = false

func _ready() -> void:
	Inventario.hide_inventory()
	setup_slides()
	#fade_in()
	await get_tree().create_timer(1.0).timeout
	play_slide(0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("skip_cutscene"):
		is_skipping = true
		end_cutscene()

func setup_slides() -> void:
	# Array de diccionarios
	slides = [
		{
			"image": preload("res://assets/cutscenes/images/job_application.png"),
			"text": "Llevo meses buscando empleo...\nApenas tengo dinero para el alquiler",
			"duration": 5.0,
			"audio": preload("res://assets/cutscenes/audios/typing.mp3")
		},
		{
			"image": preload("res://assets/cutscenes/images/approved.png"),
			"text": "Estimado candidato:\nNos complace informarle que ha sido seleccionado para el puesto de Auxiliar de Tienda...",
			"duration": 4.0,
			"audio": preload("res://assets/cutscenes/audios/stamp.mp3")
		},
		{
			"image": preload("res://assets/cutscenes/images/warehouse.jpg"),
			"text": "Este sitio es mucho más grande de lo que esperaba...\nNo he visto ninguna salida...\nParece todo un laberentio... oh no... me he perdido",
			"duration": 6.0,
			"audio": preload("res://assets/cutscenes/audios/eerie-atmosphere.mp3")
		}
	]

func play_slide(idx: int) -> void:
	if idx >= slides.size():
		end_cutscene()
		return

	current_slide = idx
	var slide = slides[idx]

	# Imagenes y audio
	image.texture = slide["image"] # slide es un diccionario
	if slide["audio"]:
		audio_stream_player.stream = slide["audio"]
		audio_stream_player.play()

	await typing_effect(slide["text"])

	await get_tree().create_timer(slide["duration"]).timeout

	if not is_skipping:
		#await fade_out()
		play_slide(idx + 1)

func typing_effect(text: String) -> void:
	label.text = ""
	for i in text.length():
		if is_skipping:
			label.text = text
			return
		label.text += text[i]
	await get_tree().create_timer(0.03).timeout

func fade_in() -> void:
	fade_rect.modulate.a = 1.0
	var twin = create_tween()
	twin.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	await twin.finished

func fade_out() -> void:
	var twin = create_tween()
	twin.tween_property(fade_rect, "modulate:a", 1.0, 1.5)
	await twin.finished
	fade_rect.modulate.a = 0.0

func end_cutscene() -> void:
	#await fade_out()
	emit_signal("cutscene_finished")
	queue_free()
	Inventario.show_inventory()
