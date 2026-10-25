class_name Spawner
extends Node2D

## 먹이 및 포식자 스포너
## 난이도 곡선 (고도/시간 경과에 따라 밀도 및 속도 증가)

signal entity_spawned(entity: Node2D)

@export var harpy_scene: PackedScene = preload("res://scenes/enemies/prey_harpy.tscn")
@export var satyr_scene: PackedScene = preload("res://scenes/enemies/prey_satyr.tscn")
@export var hound_scene: PackedScene = preload("res://scenes/enemies/predator_hound.tscn")

var is_spawning_active: bool = false
var elapsed_time: float = 0.0

var prey_spawn_timer: float = 0.0
var predator_spawn_timer: float = 0.0

# 엔티티 컨테이너 참조
@onready var entities_container: Node2D = $EntitiesContainer


func _ready() -> void:
	prey_spawn_timer = Balance.SPAWN_INTERVAL_INITIAL
	predator_spawn_timer = Balance.PREDATOR_SPAWN_INTERVAL


func start_spawning() -> void:
	is_spawning_active = true
	elapsed_time = 0.0
	prey_spawn_timer = 0.5 # 첫 시작 시 바로 첫 먹이 등장
	predator_spawn_timer = Balance.PREDATOR_SPAWN_INTERVAL


func stop_spawning() -> void:
	is_spawning_active = false


func clear_entities() -> void:
	for child in entities_container.get_children():
		child.queue_free()


func _physics_process(delta: float) -> void:
	if not is_spawning_active:
		return

	elapsed_time += delta

	# 현재 난이도 비율 (0.0 ~ 1.0)
	var difficulty_factor: float = clampf(elapsed_time / Balance.SPAWN_DIFFICULTY_RAMP_SEC, 0.0, 1.0)
	# 스폰 간격 점진적 단축 (밀도 증가)
	var current_spawn_interval: float = lerpf(Balance.SPAWN_INTERVAL_INITIAL, Balance.SPAWN_INTERVAL_MINIMUM, difficulty_factor)

	# 1. 먹이 스폰 처리
	prey_spawn_timer -= delta
	if prey_spawn_timer <= 0.0:
		prey_spawn_timer = current_spawn_interval
		_spawn_random_prey(difficulty_factor)

	# 2. 포식자 스폰 처리
	predator_spawn_timer -= delta
	if predator_spawn_timer <= 0.0:
		predator_spawn_timer = Balance.PREDATOR_SPAWN_INTERVAL
		_spawn_predator(difficulty_factor)


func _spawn_random_prey(difficulty_factor: float) -> void:
	# 사티로스 등장 확률: 초반 20% -> 후반 50%
	var satyr_prob: float = lerpf(0.2, 0.5, difficulty_factor)
	var chosen_scene: PackedScene = satyr_scene if randf() < satyr_prob else harpy_scene

	var prey := chosen_scene.instantiate() as Prey
	var spawn_x: float = randf_range(Balance.SPAWN_MARGIN_X, Balance.VIEWPORT_WIDTH - Balance.SPAWN_MARGIN_X)
	var spawn_y: float = -Balance.SPAWN_AHEAD_DISTANCE_Y
	prey.position = Vector2(spawn_x, spawn_y)

	# 고도/진행도에 따른 속도 증가
	prey.speed *= lerpf(1.0, 1.45, difficulty_factor)

	entities_container.add_child(prey)
	entity_spawned.emit(prey)


func _spawn_predator(difficulty_factor: float) -> void:
	var predator := hound_scene.instantiate() as Predator
	var spawn_x: float = randf_range(Balance.SPAWN_MARGIN_X, Balance.VIEWPORT_WIDTH - Balance.SPAWN_MARGIN_X)
	var spawn_y: float = -Balance.SPAWN_AHEAD_DISTANCE_Y
	predator.position = Vector2(spawn_x, spawn_y)

	# 난이도에 따른 속도 증가
	predator.chase_speed *= lerpf(1.0, 1.35, difficulty_factor)

	entities_container.add_child(predator)
	entity_spawned.emit(predator)
