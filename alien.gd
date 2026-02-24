extends StaticBody3D

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

func easter_egg():
	audio_stream_player_3d.play()
