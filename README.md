# Myth Eater (가제: 신화를 삼키는 자)

신들에게 계략에 빠져 힘을 잃은 '공허의 포식자'가 신화 속 존재들을 삼키며 힘을 되찾고,
약한 신부터 강한 신까지 판테온을 정복해 올라가는 모바일 종스크롤 아케이드.
Godot 4 + Antigravity(agy) 개발. 레퍼런스: 외계인은 배고파 (Hungry Aliens, 화풍만 참고).

## 시작하기
1. Godot 4.3+ 설치 후 이 폴더를 프로젝트로 열기
2. `prompts/01-kickoff.md`의 프롬프트를 agy에 붙여넣기
3. 실기기 테스트: Android Export (godot-export 스킬 참조)

## 구조
- `scenes/` — Main, 플레이어, 적, UI 씬
- `scripts/` — GDScript (balance.gd에 튜닝 수치)
- `assets/` — 아트/오디오 (프롬프트는 `_prompts/`)
- `docs/GDD.md` — 1페이지 기획서
- `.agent/skills/` — 게임 개발 스킬팩 (Antigravity: `.agents/skills` 심볼릭링크)
