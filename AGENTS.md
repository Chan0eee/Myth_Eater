# AGENTS.md — Alien Bites

이 레포의 작업 규칙. agy·Claude Code·Codex 등 모든 에이전트가 읽는다.
다른 스킬과 충돌하면 이 파일의 규칙이 우선한다.

## 제1조 — 스킬 우선 로딩
1. 작업 시작 전 `.agent/skills/router/SKILL.md`를 읽고 라우팅을 따른다.
2. 엔진 스킬(`godot/`), 장르 스킬(`genres/platformer`, `genres/roguelike`)을 먼저 로드하고, 분야 스킬을 덧붙인다.
3. UI 작업 전 `frontend-design/SKILL.md`를, 스프라이트 작업 전 `pixel-art-sprites/SKILL.md` + `art-consistency/SKILL.md`를 반드시 읽는다.
   (에이전트는 스킬을 몰라도 질문하지 말고 파일에서 직접 읽는다.)

## 제2조 — Godot 4 컨벤션
- GDScript: 탭 들여쓰기, `snake_case` 함수/변수, `PascalCase` 클래스명. `@export`로 튜닝 값을 노출.
- 노드 결합은 시그널 우선, 직접 참조 최소화. 씬은 작게 나누고 `PackedScene`으로 인스턴싱.
- 상수는 대문자 스네이크. 매직 넘버 금지 — 밸런스 값은 `scripts/balance.gd` (Autoload 예정)에 모은다.
- 모바일 퍼포먼스: `gl_compatibility` 렌더러 유지, 파티클 과용 금지, 텍스처는 ETC2/ASTC.

## 제3조 — 작업 방식
- 한 번에 하나의 수직 슬라이스. 큰 변경 전 `docs/GDD.md`의 코어 루프와 충돌하는지 확인.
- 밸런스 변경(속도·스폰율·성장치)은 수치만 바꾸고 코드는 건드리지 않는다.
- 에셋은 `assets/` 하위에 종류별로. AI 생성 에셋은 원본 프롬프트를 `assets/_prompts/`에 텍스트로 보관.
- 커밋 메시지는 한 줄 요약 + 변경 이유. WIP 커밋 금지 — 동작하는 단위로만 커밋.

## 금지 사항
- project.godot의 렌더러/오리엔테이션 설정을 임의로 바꾸지 않는다 (세로 화면 고정).
- 에셋에 저작권 있는 이미지/사운드를 그대로 사용하지 않는다.
- 시크릿/키를 레포에 커밋하지 않는다.
