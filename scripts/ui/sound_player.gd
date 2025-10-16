extends AudioStreamPlayer

@export var soundOK: AudioStreamWAV
@export var soundCancel: AudioStreamWAV
@export var soundLT: AudioStreamWAV
@export var soundRT: AudioStreamWAV
@export var soundUp: AudioStreamWAV
@export var soundDown: AudioStreamWAV

func play_sound(sound: String) -> void:
	match sound:
		"ok": set_stream(soundOK)
		"cancel": set_stream(soundCancel)
		"lt": set_stream(soundLT)
		"rt": set_stream(soundRT)
		"up": set_stream(soundUp)
		"down": set_stream(soundDown)
	play()
