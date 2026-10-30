class_name AudioManager
extends Node

@export var session_path := NodePath("../Session")
@export var spawn_director_path := NodePath("../World/SpawnDirector")
@export var ui_path := NodePath("../UI")

@onready var bgm: AudioStreamPlayer = $BGM


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		return
	var session := get_node(session_path) as SessionState
	var director := get_node(spawn_director_path) as SpawnDirector
	var ui := get_node(ui_path) as UIController
	session.shot_fired.connect(_on_shot_fired)
	session.net_resolved.connect(_on_net_resolved)
	session.fish_captured.connect(func(_player_id: int, _fish_id: StringName, _reward: int, _position: Vector2) -> void: $Capture.play())
	session.player_rescued.connect(func(_player_id: int, _amount: int) -> void: $Rescue.play())
	director.boss_warning_started.connect(func() -> void: $BossWarning.play())
	ui.ui_button_pressed.connect(func() -> void: $Button.play())
	bgm.finished.connect(_restart_bgm)
	_ensure_bgm()


func _input(event: InputEvent) -> void:
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		_ensure_bgm()


func _on_shot_fired(player_id: int, _cannon_level: int, _cost: int) -> void:
	var player := $ShotP1 if player_id == 1 else $ShotP2
	player.pitch_scale = 1.05 if player_id == 1 else 0.94
	player.play()


func _on_net_resolved(_player_id: int, eligible_count: int, _captured_ids: Array[StringName], _total_reward: int) -> void:
	if eligible_count >= 0:
		$Net.play()


func _ensure_bgm() -> void:
	if not bgm.playing:
		bgm.play()


func _restart_bgm() -> void:
	bgm.play()
