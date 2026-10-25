extends Node

## Balance Autoload (싱글톤)
## 모든 게임 밸런스 수치와 상수 집약 (매직 넘버 금지)

# --- 화면 및 뷰포트 ---
const VIEWPORT_WIDTH: float = 720.0
const VIEWPORT_HEIGHT: float = 1280.0

# --- 카메라 및 월드 스크롤 ---
const SCROLL_BASE_SPEED: float = 80.0
const SCROLL_ACCEL_PER_SEC: float = 0.5
const SCROLL_MAX_SPEED: float = 240.0

# --- 플레이어 (공허의 포식자) ---
const PLAYER_BASE_SPEED: float = 380.0
const PLAYER_DASH_SPEED: float = 900.0
const PLAYER_DASH_DURATION: float = 0.25
const PLAYER_DASH_COOLDOWN: float = 3.0
const PLAYER_DRAG_SMOOTHING: float = 18.0
const PLAYER_TOUCH_OFFSET_Y: float = -70.0 # 손가락 가림 방지 오프셋 (터치 지점보다 위)

# 탭 대시 판정
const TAP_MAX_DURATION: float = 0.22
const TAP_MAX_DISTANCE: float = 30.0

# 플레이어 생명력(HP) 및 배고픔
const MAX_HEALTH: float = 100.0
const MAX_HUNGER: float = 100.0
const HUNGER_DECAY_RATE: float = 4.0 # 초당 배고픔 감소율
const HUNGER_WARNING_THRESHOLD: float = 25.0
const STARVATION_DAMAGE_RATE: float = 12.0 # 배고픔 0일 때 초당 생명력 피해

# 플레이어 3단계 성장 스케일 및 임계치
const STAGE_1_SCALE: float = 1.0
const STAGE_1_COLLISION_RADIUS: float = 26.0

const STAGE_2_THRESHOLD_SCORE: int = 150
const STAGE_2_SCALE: float = 1.45
const STAGE_2_COLLISION_RADIUS: float = 38.0

const STAGE_3_THRESHOLD_SCORE: int = 450
const STAGE_3_SCALE: float = 2.1
const STAGE_3_COLLISION_RADIUS: float = 54.0

# --- 먹이 (Stage 1 올림포스 변방: 하피, 사티로스) ---
const HARPY_SIZE: float = 0.85
const HARPY_COLLISION_RADIUS: float = 22.0
const HARPY_SPEED: float = 130.0
const HARPY_ZIGZAG_FREQ: float = 3.2
const HARPY_ZIGZAG_AMP: float = 110.0
const HARPY_HUNGER_RESTORE: float = 18.0
const HARPY_SCORE: int = 20

const SATYR_SIZE: float = 1.2
const SATYR_COLLISION_RADIUS: float = 30.0
const SATYR_SPEED: float = 100.0
const SATYR_ZIGZAG_FREQ: float = 2.0
const SATYR_ZIGZAG_AMP: float = 75.0
const SATYR_HUNGER_RESTORE: float = 35.0
const SATYR_SCORE: int = 45

# --- 포식자 (심연의 파수견 / 아레스 전위대) ---
const HOUND_SIZE: float = 1.7
const HOUND_COLLISION_RADIUS: float = 48.0
const HOUND_PATROL_SPEED: float = 120.0
const HOUND_CHASE_SPEED: float = 220.0
const HOUND_DETECTION_RADIUS: float = 360.0
const HOUND_DAMAGE: float = 35.0
const HOUND_HUNGER_RESTORE: float = 65.0
const HOUND_SCORE: int = 150

# --- 스포너 및 난이도 곡선 ---
const SPAWN_INTERVAL_INITIAL: float = 1.8
const SPAWN_INTERVAL_MINIMUM: float = 0.75
const SPAWN_DIFFICULTY_RAMP_SEC: float = 120.0 # 이 시간 경과 시 최소 스폰 주기 도달
const PREDATOR_SPAWN_INTERVAL: float = 7.0 # 포식자 스폰 주기
const SPAWN_MARGIN_X: float = 60.0
const SPAWN_AHEAD_DISTANCE_Y: float = 200.0
const DESPAWN_BEHIND_DISTANCE_Y: float = 350.0

# --- 게임필 / 연출 ---
const CAMERA_TRAUMA_DECAY: float = 1.4
const CAMERA_MAX_OFFSET: Vector2 = Vector2(16.0, 10.0)
const HIT_STOP_DURATION: float = 0.08
const HIT_STOP_TIME_SCALE: float = 0.05
const EAT_SQUASH_SCALE: Vector2 = Vector2(1.35, 0.75)
const EAT_RECOVERY_DURATION: float = 0.22
