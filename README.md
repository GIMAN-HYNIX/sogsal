# 속살 (가칭)

체중이 아니라 몸속 지방·근육·내장지방의 변화를 캐릭터로 보여주는 다이어트 앱.
기획은 상위 폴더의 `sogsal-project-handoff.md` 를 따른다.

## 지금 들어 있는 것 (로드맵 1단계 · MVP)

- 온보딩 3단계: 기본 정보(면책 동의, 저체중 목표 제한) → 체성분 입력(인바디 직접 / 치수로 추정) → 캐릭터 결과
- 체성분 추정(미 해군법), 체형 6종 분류(남·여 기준, 나이 미반영)
- 홈: 오늘의 체형, 한마디, 캐릭터 + 누를 수 있는 부위 점, 체중 빠른 기록
- 부위 속 보기: 배 / 팔뚝 / 허벅지·엉덩이 / 가슴·등의 피하지방이·근육이·내장지방이
- 리포트: 체중·체지방·골격근·허리 그래프, 감량의 질 카드
- 꾸미기(색상만), 마이(목표 수정, 체성분 재보정, 안내)
- 안전 가드: 저체중 목표 제한, 급감량 경고, 칼로리 하한

아직 없는 것: 식단(검색·성분표 촬영), 운동·근육통, 서버/로그인, 건강 앱 연동 (2~4단계).

## 실행

```bash
flutter pub get
flutter run            # 연결된 폰/시뮬레이터
flutter run -d chrome  # 브라우저로 빠르게 보기
flutter test           # 계산 로직 테스트
```

Flutter 3.27 이상 기준.

## 폰 웹앱 (홈 화면에 추가)

```bash
tool/build_web.sh            # build/web 에 결과. 기본 주소 경로는 /sogsal/
tool/build_web.sh /          # 도메인 맨 앞에 올릴 때
```

- `tool/make_sw.py` 가 Flutter 기본 서비스 워커를 바꿔 끼운다. 기본 것은 /sogsal/ 같은 하위 경로에서 저장본을 못 찾아 인터넷 없이 안 열린다.
- 한 번 열면 앱 파일이 폰에 저장되고, 다음부턴 인터넷 없이도 열린다. 인터넷이 되면 새 버전을 받는다.
- 아이콘은 `web/icons/` (캐릭터 얼굴). 기록은 그 폰 브라우저 저장소에만 남는다.

## 구조

```
lib/
  main.dart                 앱 시작, 하단 탭 5개
  theme.dart                색(잉크)·글꼴 규칙
  models/models.dart        USER, BODY_COMPOSITION, CHARACTER
  logic/body_calc.dart      체성분 추정, 체형 분류, 부위별 계산, 안전 가드
  data/store.dart           앱 상태 + 기기 내 저장(shared_preferences)
  widgets/character.dart    전신 캐릭터 (3등신 크레용 손그림, 속옷)
  widgets/cross_section.dart  부위 속 단면 그림 (뱃살 / 팔뚝·허벅지·가슴)
  widgets/riso_paint.dart   손그림 도구: 떨리는 선, 크레용 빗금
  widgets/ui.dart           체성분표, 버튼, 입력칸, 모눈 판 같은 공통 부품
  widgets/inner_blob.dart   속 친구 표정 종류
  widgets/body_comp_form.dart  체성분 입력 폼
  screens/                  onboarding, home, record, report, decorate, my
test/body_calc_test.dart
```

## 알아둘 점

- 캐릭터는 3등신 크레용 그림으로 확정. 머리 스타일은 아직 기본(여자 보브, 남자 짧은 머리)만 있다.
- 디자인 규칙(색, 글꼴, 하지 말 것)은 `DESIGN.md` 에 있다.
- **판정 기준은 모두 임시 규칙**이다(`logic/body_calc.dart`). 출시 전 영양사·전문가 검수가 필요하다.
- 데이터는 기기 안에만 저장한다. 서버(Supabase/Firebase)를 붙일 때는 `data/store.dart` 의 load/save 를 바꾼다.
- 글꼴은 도현(제목·숫자), Pretendard(본문), 나눔손글씨 펜(그림 속 글씨). 모두 OFL 라이선스, `assets/fonts/`.
