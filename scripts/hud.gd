class_name HUD
extends CanvasLayer

## 게임 UI / HUD 관리자
## 프론트엔드 디자인 원칙 적용 (올림포스-공허 테마, 색상 토큰, 가독성, 타이포그래피)

signal start_pressed()
signal restart_pressed()
signal dash_pressed()

# --- 노드 참조 ---
# 인게임 HUD
@onready var in_game_ui: Control = $InGameUI
@onready var score_label: Label = $InGameUI/TopBar/Margin/HBox/ScoreContainer/ScoreLabel
@onready var stage_label: Label = $InGameUI/TopBar/Margin/HBox/StageContainer/StageBadgeLabel
@onready var hunger_bar: ProgressBar = $InGameUI/TopBar/Margin/HBox/HungerContainer/HungerBar
@onready var hunger_label: Label = $InGameUI/TopBar/Margin/HBox/HungerContainer/HBoxHungerHead/HungerLabel
@onready var dash_button: Button = $InGameUI/DashButton
@onready var dash_cd_overlay: ColorRect = $InGameUI/DashButton/CooldownOverlay
@onready var dash_cd_label: Label = $InGameUI/DashButton/VBox/CooldownLabel

# 타이틀 화면
@onready var title_screen: Control = $TitleScreen
@onready var start_button: Button = $TitleScreen/VBoxContainer/StartButton

# 게임 오버 화면
@onready var game_over_screen: Control = $GameOverScreen
@onready var final_score_label: Label = $GameOverScreen/VBoxContainer/StatsBox/Margin/VBox/HBoxScore/FinalScoreLabel
@onready var final_stage_label: Label = $GameOverScreen/VBoxContainer/StatsBox/Margin/VBox/HBoxStage/FinalStageLabel
@onready var restart_button: Button = $GameOverScreen/VBoxContainer/RestartButton

# 피격 비네트
@onready var damage_vignette: ColorRect = $DamageVignette

var total_dash_cooldown: float = Balance.PLAYER_DASH_COOLDOWN
var current_dash_cooldown: float = 0.0


func _ready() -> void:
	start_button.pressed.connect(func(): start_pressed.emit())
	restart_button.pressed.connect(func(): restart_pressed.emit())
	dash_button.pressed.connect(func(): dash_pressed.emit())
	damage_vignette.modulate.a = 0.0


func _process(delta: float) -> void:
	if current_dash_cooldown > 0.0:
		current_dash_cooldown = maxf(0.0, current_dash_cooldown - delta)
		var progress: float = current_dash_cooldown / total_dash_cooldown
		dash_cd_overlay.size.y = dash_button.size.y * progress
		dash_cd_label.text = "%.1fs" % current_dash_cooldown
		dash_button.disabled = true
	else:
		dash_cd_overlay.size.y = 0.0
		dash_cd_label.text = "READY"
		dash_button.disabled = false


func show_title() -> void:
	title_screen.visible = true
	in_game_ui.visible = false
	game_over_screen.visible = false


func show_in_game() -> void:
	title_screen.visible = false
	in_game_ui.visible = true
	game_over_screen.visible = false
	update_score(0)
	update_stage(1)
	update_hunger(Balance.MAX_HUNGER, Balance.MAX_HUNGER)
	current_dash_cooldown = 0.0


func show_game_over(final_score: int, final_stage: int) -> void:
	in_game_ui.visible = false
	game_over_screen.visible = true
	final_score_label.text = "%d" % final_score

	var stage_name := "I (심연의 새끼)"
	match final_stage:
		2: stage_name = "II (공허의 포식자)"
		3: stage_name = "III (신화급 거대체)"
	final_stage_label.text = stage_name

	# 등장 트윈
	game_over_screen.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(game_over_screen, "modulate:a", 1.0, 0.4)


func update_score(score: int) -> void:
	score_label.text = "%d" % score
	# 점수 상승 미세 팝 효과
	var tw := create_tween()
	score_label.scale = Vector2(1.15, 1.15)
	tw.tween_property(score_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func update_stage(stage: int) -> void:
	match stage:
		1:
			stage_label.text = "STAGE I"
			stage_label.modulate = Color("#00f5d4")
		2:
			stage_label.text = "STAGE II"
			stage_label.modulate = Color("#ffd166")
		3:
			stage_label.text = "STAGE III"
			stage_label.modulate = Color("#ff007f")

	# 배지 강조 팝
	var tw := create_tween()
	stage_label.scale = Vector2(1.25, 1.25)
	tw.tween_property(stage_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func update_hunger(current: float, max_val: float) -> void:
	hunger_bar.max_value = max_val
	hunger_bar.value = current
	hunger_label.text = "%d / %d" % [int(current), int(max_val)]

	# 배고픔 경고 상태 (게이지 25% 미만 시 붉은색 점멸)
	if current <= Balance.HUNGER_WARNING_THRESHOLD:
		hunger_bar.modulate = Color("#ff2a6d")
	else:
		hunger_bar.modulate = Color("#f5a623")


func start_dash_cooldown(cooldown_time: float) -> void:
	total_dash_cooldown = cooldown_time
	current_dash_cooldown = cooldown_time


func flash_damage_vignette() -> void:
	damage_vignette.modulate.a = 0.55
	var tw := create_tween()
	tw.tween_property(damage_vignette, "modulate:a", 0.0, 0.35)
