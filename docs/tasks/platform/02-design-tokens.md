# 02 디자인 토큰

## 목표

디자인 시스템의 컬러·타이포·간격·반경을 코드 상수와 `ThemeData`로 옮긴다. B·C는 수치를 직접 쓰지 않고 이 토큰만 쓴다.

## 할 일

- [x] 컬러: Primary / Primary Pressed / Primary Tint / Gold / 경희블루 / Positive / Gray 900·700·500, 설계서 DS-00에만 있는 Gray 200(`#E5E8EB`)·Gray 100(`#F2F4F6`)
- [x] 타이포 7단계(H1·H2·H3·Body1·Body2·Label·Caption). 자간 -1~-2%는 글자 크기에 비례한 `letterSpacing`으로 환산
- [ ] Pretendard 폰트 번들. Flutter Web 첫 로딩 크기를 보고 사용하는 weight(400·500·600·700)만 넣는다
- [x] 간격(4·8·12·16·20·24·32), 반경(12·14·16·24·full) 상수
- [x] `lib/core/theme/app_theme.dart`에서 `ThemeData` 구성(colorScheme, textTheme, 기본 배경)
- [x] 7단계 밖 스타일을 만들지 않도록 TextTheme에 없는 값은 노출하지 않는다

## 완료 조건

- 토큰 값이 `docs/design-system.md` 표와 일치함을 Unit Test로 확인한다
- 샘플 화면에서 Pretendard가 실제로 적용된다

## 참고

- `docs/design-system.md` 1~3장
- 화면 설계서 DS-00
