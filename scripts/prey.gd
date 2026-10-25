class_name Prey
extends Area2D

## 먹이 생물 (하피, 사티로스)
## 지그재그 이동 + 크기 판정 + 플레이어 삼킴 상호작용

signal eaten(creature_name: String, global_pos: Vector2)

enum PreyType {
	HARPY,
	SATYR
}

@export var prey_type: PreyType = PreyType.HARPY
@export var harpy_texture: Texture2D = preload("res://assets/art/prey_harpy.svg")
@export var satyr_texture: Texture2D = preload("res://assets/art/prey_satyr.svg")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var creature_name: String = "하피"
var creature_size: float = Balance.HARPY_SIZE
var speed: float = Balance.HARPY_SPEED
var zigzag_freq: float = Balance.HARPY_ZIGZAG_FREQ
var zigzag_amp: float = Balance.HARPY_ZIGZAG_AMP
var hunger_restore: float = Balance.HARPY_HUNGER_RESTORE
var score_value: int = Balance.HARPY_SCORE

var base_x: float = 0.0
var move_time: float = 0.0
var is_eaten: bool = false


func _ready() -> void:
	_setup_type_data()
	base_x = position.x
	area_entered.connect(_on_area_entered)


func _setup_type_data() -> void:
	match prey_type:
		PreyType.HARPY:
			creature_name = "하피"
			creature_size = Balance.HARPY_SIZE
			speed = Balance.HARPY_SPEED
			zigzag_freq = Balance.HARPY_ZIGZAG_FREQ
			zigzag_amp = Balance.HARPY_ZIGZAG_AMP
			hunger_restore = Balance.HARPY_HUNGER_RESTORE
			score_value = Balance.HARPY_SCORE
			if sprite:
				sprite.texture = harpy_texture
			scale = Vector2.ONE * Balance.HARPY_SIZE
			if collision_shape and collision_shape.shape is CircleShape2D:
				(collision_shape.shape as CircleShape2D).radius = Balance.HARPY_COLLISION_RADIUS

		PreyType.SATYR:
			creature_name = "사티로스"
			creature_size = Balance.SATYR_SIZE
			speed = Balance.SATYR_SPEED
			zigzag_freq = Balance.SATYR_ZIGZAG_FREQ
			zigzag_amp = Balance.SATYR_ZIGZAG_AMP
			hunger_restore = Balance.SATYR_HUNGER_RESTORE
			score_value = Balance.SATYR_SCORE
			if sprite:
				sprite.texture = satyr_texture
			scale = Vector2.ONE * Balance.SATYR_SIZE
			if collision_shape and collision_shape.shape is CircleShape2D:
				(collision_shape.shape as CircleShape2D).radius = Balance.SATYR_COLLISION_RADIUS


func _physics_process(delta: float) -> void:
	if is_eaten:
		return

	move_time += delta
	# 아래로 하강 (월드 스크롤 시뮬레이션)
	position.y += speed * delta
	# 좌우 지그재그 이동
	var target_x: float = base_x + sin(move_time * zigzag_freq) * zigzag_amp
	position.x = clampf(target_x, Balance.SPAWN_MARGIN_X, Balance.VIEWPORT_WIDTH - Balance.SPAWN_MARGIN_X)

	# 이동 방향에 따른 스프라이트 기울기 연출
	var tilt: float = cos(move_time * zigzag_freq) * 0.2
	rotation = tilt

	# 중첩 영역 체크 (성장 직후나 고속 대시 시 안정적인 삼킴 보장)
	for area in get_overlapping_areas():
		if is_eaten:
			break
		_on_area_entered(area)

	# 화면 하단 이탈 시 디스폰
	if position.y > Balance.VIEWPORT_HEIGHT + Balance.DESPAWN_BEHIND_DISTANCE_Y:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if is_eaten:
		return

	# 플레이어의 EatDetector와 충돌했는지 확인
	var player := area.get_parent() as Player
	if not player or not player.is_alive:
		return

	# 크기 판정: 플레이어의 현재 스케일이 먹이 크기 이상이어야 삼킴 가능
	var player_size: float = player._get_stage_scale()
	if player_size >= creature_size:
		_be_eaten_by(player)
	else:
		# 플레이어가 더 작으면 먹지 못하고 살짝 튕겨남
		var bounce_dir: Vector2 = (global_position - player.global_position).normalized()
		base_x += bounce_dir.x * 20.0


func _be_eaten_by(player: Player) -> void:
	is_eaten = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	eaten.emit(creature_name, global_position)
	player.eat(creature_name, score_value, hunger_restore)

	# 흡입 연출: 플레이어 중심부로 빨려들어가며 축소
	var tw := create_tween()
	tw.tween_property(self, "global_position", player.global_position, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
