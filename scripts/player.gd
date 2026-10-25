class_name Player
extends CharacterBody2D

## 공허의 포식자 (주인공)
## 드래그 이동 + 탭 대시 + 배고픔/성장 시스템

signal health_changed(current_hp: float, max_hp: float)
signal hunger_changed(current_hunger: float, max_hunger: float)
signal stage_changed(new_stage: int)
signal dash_triggered(cooldown_time: float)
signal dash_ready()
signal ate_target(target_name: String, score_gain: int, hunger_gain: float)
signal died()

# 노드 참조
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var circle_shape: CircleShape2D = $CollisionShape2D.shape as CircleShape2D
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var eat_detector: Area2D = $EatDetector
@onready var eat_collision_shape: CollisionShape2D = $EatDetector/CollisionShape2D

# 텍스처 (성장 3단계)
@export var texture_stage_1: Texture2D = preload("res://assets/art/player_stage1.svg")
@export var texture_stage_2: Texture2D = preload("res://assets/art/player_stage2.svg")
@export var texture_stage_3: Texture2D = preload("res://assets/art/player_stage3.svg")

# 상태 변수
var current_health: float = Balance.MAX_HEALTH
var current_hunger: float = Balance.MAX_HUNGER
var current_stage: int = 1
var current_score: int = 0
var is_alive: bool = true

# 대시 상태
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.UP

# 입력 및 터치 드래그 추적
var is_touch_active: bool = false
var touch_start_pos: Vector2 = Vector2.ZERO
var touch_current_pos: Vector2 = Vector2.ZERO
var touch_start_time: float = 0.0
var target_drag_pos: Vector2 = Vector2.ZERO
var last_move_direction: Vector2 = Vector2.UP

# 카메라 오프셋 제한용
var min_screen_x: float = Balance.SPAWN_MARGIN_X
var max_screen_x: float = Balance.VIEWPORT_WIDTH - Balance.SPAWN_MARGIN_X


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_apply_stage(1, false)
	health_changed.emit(current_health, Balance.MAX_HEALTH)
	hunger_changed.emit(current_hunger, Balance.MAX_HUNGER)
	target_drag_pos = global_position


func _unhandled_input(event: InputEvent) -> void:
	if not is_alive:
		return

	if event is InputEventScreenTouch:
		_process_touch_press(event.pressed, event.position)
	elif event is InputEventScreenDrag:
		_process_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_process_touch_press(event.pressed, event.position)
	elif event is InputEventMouseMotion and is_touch_active:
		_process_drag(event.position)


func _process_touch_press(pressed: bool, pos: Vector2) -> void:
	if pressed:
		is_touch_active = true
		touch_start_pos = pos
		touch_current_pos = pos
		touch_start_time = Time.get_ticks_msec() / 1000.0
		target_drag_pos = Vector2(
			clampf(pos.x, min_screen_x, max_screen_x),
			pos.y + Balance.PLAYER_TOUCH_OFFSET_Y
		)
	else:
		if is_touch_active:
			var press_duration: float = (Time.get_ticks_msec() / 1000.0) - touch_start_time
			var press_dist: float = touch_start_pos.distance_to(pos)
			if press_duration <= Balance.TAP_MAX_DURATION and press_dist <= Balance.TAP_MAX_DISTANCE:
				trigger_dash()
		is_touch_active = false


func _process_drag(pos: Vector2) -> void:
	if is_touch_active:
		touch_current_pos = pos
		target_drag_pos = Vector2(
			clampf(pos.x, min_screen_x, max_screen_x),
			pos.y + Balance.PLAYER_TOUCH_OFFSET_Y
		)


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_update_hunger_and_health(delta)
	_update_dash(delta)
	_handle_movement(delta)
	move_and_slide()
	_clamp_to_screen()


func _handle_movement(delta: float) -> void:
	if is_dashing:
		velocity = dash_direction * Balance.PLAYER_DASH_SPEED
		return

	# 1. 키보드/조이패드 방향 입력 확인
	var keyboard_dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	# 스페이스바 / 대시 액션 지원
	if Input.is_action_just_pressed("ui_accept"):
		trigger_dash()

	if keyboard_dir.length_squared() > 0.01:
		last_move_direction = keyboard_dir.normalized()
		velocity = last_move_direction * Balance.PLAYER_BASE_SPEED
		# 키보드 이동 시 타겟 드래그 위치 동기화
		target_drag_pos = global_position
	elif is_touch_active:
		# 2. 터치 부드러운 추종 이동
		var to_target: Vector2 = target_drag_pos - global_position
		if to_target.length() > 6.0:
			last_move_direction = to_target.normalized()
			var desired_velocity: Vector2 = to_target * Balance.PLAYER_DRAG_SMOOTHING
			# 최대 속도 제한
			if desired_velocity.length() > Balance.PLAYER_BASE_SPEED:
				desired_velocity = desired_velocity.normalized() * Balance.PLAYER_BASE_SPEED
			velocity = desired_velocity
		else:
			velocity = Vector2.ZERO
	else:
		velocity = velocity.move_toward(Vector2.ZERO, Balance.PLAYER_BASE_SPEED * 8.0 * delta)

	# 이동 방향에 따른 미세한 틸트/회전 연출 (Game Feel)
	if velocity.x != 0.0:
		visuals.rotation = lerp_angle(visuals.rotation, clampf(velocity.x / Balance.PLAYER_BASE_SPEED * 0.25, -0.3, 0.3), 10.0 * delta)
	else:
		visuals.rotation = lerp_angle(visuals.rotation, 0.0, 10.0 * delta)


func trigger_dash() -> void:
	if is_dashing or dash_cooldown_timer > 0.0 or not is_alive:
		return

	is_dashing = true
	dash_timer = Balance.PLAYER_DASH_DURATION
	dash_cooldown_timer = Balance.PLAYER_DASH_COOLDOWN
	dash_direction = last_move_direction.normalized()
	if dash_direction.length_squared() < 0.1:
		dash_direction = Vector2.UP

	dash_triggered.emit(Balance.PLAYER_DASH_COOLDOWN)

	# 대시 스쿼시 & 스트레치 연출
	var tw := create_tween()
	tw.tween_property(visuals, "scale", Vector2(0.8, 1.4) * _get_stage_scale(), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(visuals, "scale", Vector2.ONE * _get_stage_scale(), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_dash(delta: float) -> void:
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0:
			dash_cooldown_timer = 0.0
			dash_ready.emit()


func _update_hunger_and_health(delta: float) -> void:
	# 배고픔 감소
	if current_hunger > 0.0:
		current_hunger = maxf(0.0, current_hunger - Balance.HUNGER_DECAY_RATE * delta)
		hunger_changed.emit(current_hunger, Balance.MAX_HUNGER)
	else:
		# 배고픔 0: 아사 생명력 피해
		take_damage(Balance.STARVATION_DAMAGE_RATE * delta, false)


func take_damage(amount: float, can_knockback: bool = true) -> void:
	if not is_alive or amount <= 0.0:
		return

	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, Balance.MAX_HEALTH)

	# 피격 시각 효과: 붉은색 플래시
	var tw := create_tween()
	sprite.modulate = Color(2.5, 0.4, 0.4, 1.0)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.18)

	if can_knockback:
		# 피격 넉백
		velocity = -last_move_direction * 250.0

	if current_health <= 0.0:
		_die()


func eat(target_name: String, score_gain: int, hunger_gain: float) -> void:
	if not is_alive:
		return

	current_score += score_gain
	current_hunger = minf(Balance.MAX_HUNGER, current_hunger + hunger_gain)
	hunger_changed.emit(current_hunger, Balance.MAX_HUNGER)
	ate_target.emit(target_name, score_gain, hunger_gain)

	# 삼킴 연출: 스쿼시 & 스트레치 (TRANS_BACK으로 탄력적인 팝)
	var base_scale: float = _get_stage_scale()
	var tw := create_tween()
	visuals.scale = Vector2(Balance.EAT_SQUASH_SCALE.x * base_scale, Balance.EAT_SQUASH_SCALE.y * base_scale)
	tw.tween_property(visuals, "scale", Vector2.ONE * base_scale, Balance.EAT_RECOVERY_DURATION)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	_check_growth()


func _check_growth() -> void:
	if current_stage == 1 and current_score >= Balance.STAGE_2_THRESHOLD_SCORE:
		_apply_stage(2, true)
	elif current_stage == 2 and current_score >= Balance.STAGE_3_THRESHOLD_SCORE:
		_apply_stage(3, true)


func _apply_stage(new_stage: int, play_fx: bool) -> void:
	current_stage = new_stage

	var target_scale_val: float = Balance.STAGE_1_SCALE
	var radius_val: float = Balance.STAGE_1_COLLISION_RADIUS
	var new_tex: Texture2D = texture_stage_1

	match new_stage:
		1:
			target_scale_val = Balance.STAGE_1_SCALE
			radius_val = Balance.STAGE_1_COLLISION_RADIUS
			new_tex = texture_stage_1
		2:
			target_scale_val = Balance.STAGE_2_SCALE
			radius_val = Balance.STAGE_2_COLLISION_RADIUS
			new_tex = texture_stage_2
		3:
			target_scale_val = Balance.STAGE_3_SCALE
			radius_val = Balance.STAGE_3_COLLISION_RADIUS
			new_tex = texture_stage_3

	sprite.texture = new_tex
	if circle_shape:
		circle_shape.radius = radius_val
	if eat_collision_shape and eat_collision_shape.shape is CircleShape2D:
		(eat_collision_shape.shape as CircleShape2D).radius = radius_val * 1.25

	if play_fx:
		stage_changed.emit(new_stage)
		# 성장 연출: 거대 팝 + 글로우
		var tw := create_tween()
		visuals.scale = Vector2.ONE * (target_scale_val * 1.5)
		tw.tween_property(visuals, "scale", Vector2.ONE * target_scale_val, 0.35)\
			.set_trans(Tween.TRANS_ELASTIC)\
			.set_ease(Tween.EASE_OUT)
	else:
		visuals.scale = Vector2.ONE * target_scale_val


func _get_stage_scale() -> float:
	match current_stage:
		1: return Balance.STAGE_1_SCALE
		2: return Balance.STAGE_2_SCALE
		3: return Balance.STAGE_3_SCALE
	return Balance.STAGE_1_SCALE


func _clamp_to_screen() -> void:
	global_position.x = clampf(global_position.x, min_screen_x, max_screen_x)
	# Y축 화면 제한 (화면 밖으로 과도하게 이탈 방지: 화면 상하단 여백)
	var viewport_rect := get_viewport_rect()
	global_position.y = clampf(global_position.y, 80.0, viewport_rect.size.y - 80.0)


func _die() -> void:
	is_alive = false
	velocity = Vector2.ZERO
	died.emit()
	var tw := create_tween()
	tw.tween_property(visuals, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_property(visuals, "scale", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
