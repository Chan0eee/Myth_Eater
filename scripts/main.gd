class_name Main
extends Node2D

## Main 게임 관리자
## 게임 상태 머신 (TITLE -> PLAYING -> GAME_OVER) + 카메라 셰이크 + 게임필

enum GameState {
	TITLE,
	PLAYING,
	GAME_OVER
}

var current_state: GameState = GameState.TITLE

# 노드 참조
@onready var camera: Camera2D = $Camera2D
@onready var spawner: Spawner = $Spawner
@onready var hud: HUD = $HUD
@onready var player: Player = $Player
@onready var bg_rect_1: TextureRect = $BackgroundLayer/BgRect1
@onready var bg_rect_2: TextureRect = $BackgroundLayer/BgRect2
@onready var fx_layer: Node2D = $FXLayer

# 카메라 셰이크 (game-feel 스킬 트라우마 모델)
var camera_trauma: float = 0.0
var camera_time: float = 0.0
var camera_base_offset: Vector2 = Vector2.ZERO

# 배경 스크롤
var scroll_speed: float = Balance.SCROLL_BASE_SPEED
var bg_height: float = Balance.VIEWPORT_HEIGHT

# 파티클 텍스처
var bite_fx_tex: Texture2D = preload("res://assets/art/fx_bite.svg")
var ring_fx_tex: Texture2D = preload("res://assets/art/fx_ring.svg")


func _ready() -> void:
	camera_base_offset = camera.offset
	_connect_signals()
	_set_state(GameState.TITLE)


func _connect_signals() -> void:
	hud.start_pressed.connect(_on_start_pressed)
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.dash_pressed.connect(_on_dash_pressed)

	player.health_changed.connect(_on_player_health_changed)
	player.hunger_changed.connect(_on_player_hunger_changed)
	player.stage_changed.connect(_on_player_stage_changed)
	player.dash_triggered.connect(_on_player_dash_triggered)
	player.ate_target.connect(_on_player_ate_target)
	player.died.connect(_on_player_died)


func _physics_process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		_scroll_background(delta)

	_update_camera_shake(delta)


func _scroll_background(delta: float) -> void:
	# 배경이 아래로 내려가며 플레이어가 위로 오르는 느낌 연출
	bg_rect_1.position.y += scroll_speed * delta
	bg_rect_2.position.y += scroll_speed * delta

	if bg_rect_1.position.y >= bg_height:
		bg_rect_1.position.y = bg_rect_2.position.y - bg_height
	if bg_rect_2.position.y >= bg_height:
		bg_rect_2.position.y = bg_rect_1.position.y - bg_height


func _update_camera_shake(delta: float) -> void:
	if camera_trauma > 0.0:
		camera_trauma = maxf(0.0, camera_trauma - Balance.CAMERA_TRAUMA_DECAY * delta)
		var shake: float = camera_trauma * camera_trauma
		camera_time += delta * 35.0
		camera.offset = camera_base_offset + Vector2(
			Balance.CAMERA_MAX_OFFSET.x * shake * sin(camera_time * 1.8),
			Balance.CAMERA_MAX_OFFSET.y * shake * cos(camera_time * 2.3)
		)
	else:
		camera.offset = camera_base_offset


func add_camera_trauma(amount: float) -> void:
	camera_trauma = clampf(camera_trauma + amount, 0.0, 1.0)


func trigger_hit_stop(duration: float = Balance.HIT_STOP_DURATION, scale: float = Balance.HIT_STOP_TIME_SCALE) -> void:
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func _set_state(new_state: GameState) -> void:
	current_state = new_state

	match current_state:
		GameState.TITLE:
			spawner.stop_spawning()
			hud.show_title()
			player.visible = false
			player.set_physics_process(false)

		GameState.PLAYING:
			hud.show_in_game()
			player.visible = true
			player.set_physics_process(true)
			_reset_player()
			spawner.clear_entities()
			spawner.start_spawning()

		GameState.GAME_OVER:
			spawner.stop_spawning()
			add_camera_trauma(0.8)
			hud.show_game_over(player.current_score, player.current_stage)


func _reset_player() -> void:
	player.global_position = Vector2(Balance.VIEWPORT_WIDTH * 0.5, Balance.VIEWPORT_HEIGHT * 0.72)
	player.current_health = Balance.MAX_HEALTH
	player.current_hunger = Balance.MAX_HUNGER
	player.current_score = 0
	player.is_alive = true
	player.visuals.modulate.a = 1.0
	player.visuals.scale = Vector2.ONE
	player._apply_stage(1, false)
	player.target_drag_pos = player.global_position


func _on_start_pressed() -> void:
	_set_state(GameState.PLAYING)


func _on_restart_pressed() -> void:
	_set_state(GameState.PLAYING)


func _on_dash_pressed() -> void:
	if current_state == GameState.PLAYING:
		player.trigger_dash()


func _on_player_health_changed(hp: float, max_hp: float) -> void:
	hud.update_health(hp, max_hp)
	if hp < Balance.MAX_HEALTH and player.is_alive:
		add_camera_trauma(0.4)
		hud.flash_damage_vignette()


func _on_player_hunger_changed(hunger: float, max_hunger: float) -> void:
	hud.update_hunger(hunger, max_hunger)


func _on_player_stage_changed(new_stage: int) -> void:
	hud.update_stage(new_stage)
	add_camera_trauma(0.5)
	trigger_hit_stop(0.12, 0.02)
	_spawn_ring_fx(player.global_position)


func _on_player_dash_triggered(cooldown: float) -> void:
	hud.start_dash_cooldown(cooldown)


func _on_player_ate_target(_name: String, _score_gain: int, _hunger_gain: float) -> void:
	hud.update_score(player.current_score)
	add_camera_trauma(0.18)
	_spawn_bite_fx(player.global_position)


func _on_player_died() -> void:
	trigger_hit_stop(0.18, 0.02)
	_set_state(GameState.GAME_OVER)


func _spawn_bite_fx(pos: Vector2) -> void:
	var fx := Sprite2D.new()
	fx.texture = bite_fx_tex
	fx.position = pos + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	fx.scale = Vector2(0.5, 0.5)
	fx_layer.add_child(fx)

	var tw := create_tween()
	tw.tween_property(fx, "scale", Vector2(1.2, 1.2), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(fx, "modulate:a", 0.0, 0.22)
	tw.tween_callback(fx.queue_free)


func _spawn_ring_fx(pos: Vector2) -> void:
	var ring := Sprite2D.new()
	ring.texture = ring_fx_tex
	ring.position = pos
	ring.scale = Vector2(0.3, 0.3)
	fx_layer.add_child(ring)

	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector2(3.0, 3.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.45)
	tw.tween_callback(ring.queue_free)
