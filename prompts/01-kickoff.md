# agy 프롬프트 01 — 수직 슬라이스 킥오프

아래 블록을 그대로 agy에 붙여넣으세요. 작업 디렉토리: 이 레포 루트.

---

```
AGENTS.md와 docs/GDD.md를 먼저 읽어.

작업 순서:
1. .agent/skills/router/SKILL.md를 읽고 라우팅에 따라 필요한 스킬을 로드해.
   이번 작업에 필요한 스킬: godot-gdscript, godot-2d-movement,
   genres/roguelike, disciplines/game-feel, disciplines/input-systems.
2. UI/HUD를 만들기 전에 .agent/skills/frontend-design/SKILL.md를 읽고
   디자인 원칙을 적용해. (색상·타이포·여백 — 투박한 기본 UI 금지)
3. 스프라이트는 .agent/skills/character-design/SKILL.md +
   .agent/skills/art-consistency/SKILL.md + .agent/skills/concept-art/SKILL.md를 읽고,
   볼드 카툰 치비 스타일(굵은 외곽선, 셀 셰이딩, 고채도, 치비 비율, 글로시 하이라이트)의
   오리지널 캐릭터로 만들어. (외계인 3단계 성장, 플랑크톤, 소형 물고기, 포식자)
   ⚠️ 레퍼런스 게임의 캐릭터·에셋을 모방하지 말 것 — 화풍만 참고, 디자인은 오리지널.
   에셋 프롬프트는 assets/_prompts/에 텍스트로 보관.

구현 범위 (GDD의 "수직 슬라이스 범위"만):
- scenes/main.tscn: Main 씬, 게임 상태 머신 (TITLE → PLAYING → GAME_OVER)
- scripts/player.gd: CharacterBody2D 기반 상하좌우 이동 + 탭 대시(쿨타임 3초)
- scripts/spawner.gd: 먹이/포식자 스폰, 난이도 곡선 (고도에 따라 속도·밀도 증가)
- scripts/prey.gd, scripts/predator.gd: 먹이 지그재그 이동, 포식자 추적 AI
- scripts/hud.gd: 점수/레벨/배고픔 게이지, 게임 오버 화면
- scripts/balance.gd: Autoload, 모든 튜닝 수치 (속도, 스폰율, 성장치, 게이지 감소율)

제약:
- Godot 4.3, gl_compatibility, 세로 화면(portrait 720x1280), 모바일 터치 우선 (마우스 에뮬레이션은 테스트용)
- 한 번에 다 만들지 말고: 플레이어 이동 → 스폰/삼킴 → 포식자/게임오버 → HUD 순서로,
  각 단계가 끝날 때마다 뭘 테스트해야 하는지 알려줘.
- 밸런스 수치는 balance.gd에만. 매직 넘버 금지.

다 끝나면: 변경 파일 목록 + 각 단계 테스트 방법 + 다음에 할 일(3지선다 업그레이드)을 정리해줘.
```
