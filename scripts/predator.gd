class_name Predator
extends Area2D

## 포식자 생물 (심연의 파수견 / 아레스 전위대)
## 순찰 및 추적 AI + 플레이어 피격/포식 상호작용

signal attacked_player(damage: float)
signal devoured_by_player(predator_name: String, score: int)

enum State {
	PATROL,
	CHASE
}

@export var hound_texture: Texture2D = preload("res://assets/art/predator_hound.svg")

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var state: State = State.PATROL
var target_player: Player = null
var is_active: bool = true
var attack_cooldown: float = 0.0

var creature_name: String = "심연의 파수견"
var creature_size: float = Balance.HOUND_SIZE
var patrol_speed: float = Balance.HOUND_PATROL_SPEED
var chase_speed: float = Balance.HOUND_CHASE_SPEED
var damage_amount: float = Balance.HOUND_DAMAGE

var base_x: float = 0.0
var patrol_time: float = 0.0


func _ready() -> void:
	base_x = position.x
	scale = Vector2.ONE * Balance.HOUND_SIZE
	if sprite:
		sprite.texture = hound_texture
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = Balance.HOUND_COLLISION_RADIUS

	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if not is_active:
		return

	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			for area in get_overlapping_areas():
				_check_overlap(area)
				if attack_cooldown > 0.0:
					break

	_find_player_target()
	_update_movement(delta)

	if position.y > Balance.VIEWPORT_HEIGHT + Balance.DESPAWN_BEHIND_DISTANCE_Y:
		queue_free()


func _find_player_target() -> void:
	if not is_instance_valid(target_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0] as Player

	if is_instance_valid(target_player) and target_player.is_alive:
		var dist: float = global_position.distance_to(target_player.global_position)
		if dist <= Balance.HOUND_DETECTION_RADIUS:
			state = State.CHASE
		else:
			state = State.PATROL
	else:
		state = State.PATROL


func _update_movement(delta: float) -> void:
	match state:
		State.PATROL:
			patrol_time += delta
			position.y += patrol_speed * delta
			var target_x: float = base_x + sin(patrol_time * 1.5) * 40.0
			position.x = clampf(target_x, Balance.SPAWN_MARGIN_X, Balance.VIEWPORT_WIDTH - Balance.SPAWN_MARGIN_X)
			rotation = lerp_angle(rotation, 0.0, 5.0 * delta)
			sprite.modulate = Color.WHITE

		State.CHASE:
			if is_instance_valid(target_player) and target_player.is_alive:
				var dir: Vector2 = (target_player.global_position - global_position).normalized()
				position += dir * chase_speed * delta
				# 플레이어를 향해 살짝 회전
				rotation = lerp_angle(rotation, dir.x * 0.35, 8.0 * delta)
				# 추적 중 붉은색 분노 틴트
				sprite.modulate = Color(1.2, 0.6, 0.6, 1.0)
			else:
				state = State.PATROL


func _on_area_entered(area: Area2D) -> void:
	_check_overlap(area)


func _check_overlap(area: Area2D) -> void:
	if not is_active:
		return

	var player := area.get_parent() as Player
	if not player or not player.is_alive:
		return

	var player_size: float = player._get_stage_scale()

	if player_size >= creature_size:
		# 플레이어가 3단계 성장으로 포식자보다 거대해짐 -> 역으로 포식자를 삼킴!
		_be_devoured_by(player)
	else:
		# 플레이어가 포식자보다 작음 -> 플레이어 공격
		if attack_cooldown <= 0.0:
			attack_cooldown = 0.8
			attacked_player.emit(damage_amount)
			player.take_damage(damage_amount, true)

			# 공격 후 반동 반작용
			var bounce_dir: Vector2 = (global_position - player.global_position).normalized()
			position += bounce_dir * 60.0
			base_x = position.x


func _be_devoured_by(player: Player) -> void:
	is_active = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	devoured_by_player.emit(creature_name, Balance.HOUND_SCORE)
	player.eat(creature_name, Balance.HOUND_SCORE, Balance.HOUND_HUNGER_RESTORE)

	var tw := create_tween()
	tw.tween_property(self, "global_position", player.global_position, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
