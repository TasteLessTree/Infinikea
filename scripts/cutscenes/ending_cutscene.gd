extends Control

signal ending_cutscene_finished

@onready var fade_rect: ColorRect = $FadeRect
@onready var image: TextureRect = $Image
@onready var label: Label = $Label
@onready var audio_ambient: AudioStreamPlayer = $AudioStreamPlayer
@onready var audio_voices: AudioStreamPlayer = $AudioVoices

var slides: Array = []
var current_slide: int = 0
var is_skipping: bool = false

const AMBIENT_NORMAL_DB: float = 0.0
const AMBIENT_DUCKED_DB: float = -12.0
const DUCK_TIME: float = 0.5

func _ready() -> void:
	Inventario.hide_inventory()
	setup_slides()
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
			"image": preload("res://assets/cutscenes/images/door_open.jpg"),
			"text": "¡Por fin!\n\nLlevo 6 años atrapado en este sitio...",
			"audio": preload("res://assets/cutscenes/audios/creaky_door.mp3"),
			"voice": preload("res://assets/cutscenes/voice-over/outro_pt1.mp3")
		},
		{
			"image": preload("res://assets/cutscenes/images/free.jpg"),
			"text": "No me lo puedo creer...\nAl fin, la luz del día...",
			"audio": preload("res://assets/cutscenes/audios/birds_chirping.mp3"),
			"voice": preload("res://assets/cutscenes/voice-over/outro_pt2.mp3")
		},
		{
			"image": preload("res://assets/cutscenes/images/ikea.png"),
			"text": "Desarrollado por Filipe y Andrés\n\n- Unsplash, Pixabay, Freesound.org, Sketchfab, CGTrader -",
			"audio": preload("res://assets/cutscenes/audios/eerie-atmosphere.mp3"),
			"duration": 4.0
		}
	]

func play_slide(idx: int) -> void:
	if idx >= slides.size():
		end_cutscene()
		return

	current_slide = idx
	var slide = slides[idx]

	# Visual
	label.text = ""
	image.texture = slide["image"] # slide es un diccionario

	# Ambiente
	if slide.has("audio") and slide["audio"]:
		audio_ambient.stream = slide["audio"]
		audio_ambient.volume_db = AMBIENT_NORMAL_DB
		audio_ambient.play()

	# Voz
	if slide.has("voice") and slide["voice"]:
		audio_voices.stream = slide["voice"]
		audio_voices.play()

		duck_ambient(true)

		audio_voices.finished.connect(_on_voice_finished, CONNECT_ONE_SHOT)
	await typing_effect(slide["text"])

	# Duración, si la hubiese
	if slide.has("duration"):
		duck_ambient(false)
		await get_tree().create_timer(slide["duration"]).timeout
		play_slide(idx + 1)

func typing_effect(text: String) -> void:
	label.text = ""
	for i in text.length():
		if is_skipping:
			label.text = text
			return
		label.text += text[i]
		await get_tree().create_timer(0.03).timeout

func end_cutscene() -> void:
	emit_signal("ending_cutscene_finished")
	queue_free()

func duck_ambient(enabled: bool) -> void:
	var target_db = AMBIENT_DUCKED_DB if enabled else AMBIENT_NORMAL_DB

	var twin = create_tween()
	twin.tween_property(audio_ambient, "volume_db", target_db, DUCK_TIME)

func _on_voice_finished() -> void:
	duck_ambient(false)

	await get_tree().create_timer(0.5).timeout

	if not is_skipping:
		play_slide(current_slide + 1)
