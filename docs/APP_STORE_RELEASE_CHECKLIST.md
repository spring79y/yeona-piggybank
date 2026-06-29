# App Store 출시 체크리스트

Archive 업로드 전·후에 순서대로 확인하세요.

---

## A. Xcode 프로젝트 설정

| # | 항목 | 현재 값 | 확인 |
|---|------|---------|------|
| A1 | Team | 64RT682DQ4 | ☐ |
| A2 | Automatically manage signing | 켜짐 (두 타깃) | ☐ |
| A3 | 앱 번들 ID | `com.yeona.piggybank` | ☐ |
| A4 | 위젯 번들 ID | `com.yeona.piggybank.widget` | ☐ |
| A5 | App Group (양쪽) | `group.com.yeona.piggybank` | ☐ |
| A6 | Marketing Version | 1.0 | ☐ |
| A7 | Build Number | 1 | ☐ |
| A8 | Deployment Target | iOS 17.0 | ☐ |
| A9 | Display Name | 내 아이의 저금통 | ☐ |

> **재제출 시**: Build Number만 +1 (예: 1 → 2). Marketing Version은 기능 변경 시에만 올림.

---

## B. Info.plist / 규정 준수

| # | 항목 | 상태 | 확인 |
|---|------|------|------|
| B1 | `ITSAppUsesNonExemptEncryption` = false | ✅ 설정됨 | ☐ |
| B2 | `NSUserNotificationsUsageDescription` | ✅ 설정됨 | ☐ |
| B3 | `PrivacyInfo.xcprivacy` 포함 | ✅ 있음 | ☐ |
| B4 | App Icon 1024×1024 | Assets 확인 | ☐ |
| B5 | `UIRequiredDeviceCapabilities` armv7 | ✅ 제거됨 (iOS 17) | ☐ |

---

## C. Archive 전 실기기 테스트

| # | 시나리오 | 확인 |
|---|----------|------|
| C1 | 최초 실행 온보딩 → 비밀번호 필수 → 다음만 진행 | ☐ |
| C2 | 나눔/용돈/저축 입출금 + 비밀번호 + 완료 후 창 닫힘 | ☐ |
| C3 | 할 일 게시 → 완료 → 승인/거절 | ☐ |
| C4 | 칭찬스티커 터치·드래그 붙이기 | ☐ |
| C5 | 돌림판 → 확인 → 보드 리셋 | ☐ |
| C6 | 홈 화면 위젯 표시 | ☐ |
| C7 | 전체 초기화 → 온보딩 재표시 | ☐ |
| C8 | 다크 모드 가독성 | ☐ |

---

## D. Archive & Upload (Xcode)

```
1. 상단 기기: Any iOS Device (arm64)
2. Product → Clean Build Folder (⇧⌘K)
3. Product → Archive
4. Organizer → Validate App → 통과
5. Distribute App → App Store Connect → Upload
```

| # | 확인 |
|---|------|
| D1 | Archive 성공 | ☐ |
| D2 | Validate 통과 | ☐ |
| D3 | Upload 완료 | ☐ |

---

## E. App Store Connect

| # | 항목 | 확인 |
|---|------|------|
| E1 | 앱 생성 (번들 ID 연결) | ☐ |
| E2 | 스크린샷 iPhone + iPad | ☐ |
| E3 | 설명·키워드·부제 (`docs/app-store-metadata-ko.md`) | ☐ |
| E4 | 지원 URL | ☐ |
| E5 | 개인정보 처리방침 URL | ☐ |
| E6 | App Privacy → 데이터 수집 없음 | ☐ |
| E7 | 빌드 1.0(1) 선택 (Processing 후) | ☐ |
| E8 | 심사 메모 작성 | ☐ |
| E9 | 심사를 위해 제출 | ☐ |

---

## F. GitHub Pages 배포 (URL용)

```bash
# 저장소 루트에서 docs/ 폴더를 Pages 소스로 설정
# GitHub → Settings → Pages → Source: Deploy from branch
# Branch: main, Folder: /docs
```

배포 후 URL 예:
- 지원: `https://YOUR_USERNAME.github.io/yeona-piggybank/`
- 개인정보: `https://YOUR_USERNAME.github.io/yeona-piggybank/privacy-policy.html`

| # | 확인 |
|---|------|
| F1 | `docs/index.html` 이메일 주소 수정 | ☐ |
| F2 | `docs/privacy-policy.html` 이메일 주소 수정 | ☐ |
| F3 | GitHub Pages 활성화 | ☐ |
| F4 | App Store Connect URL 반영 | ☐ |

---

## G. 심사 거절 시 자주 나오는 이유

| 사유 | 대응 |
|------|------|
| 스크린샷 크기 불일치 | ASC 요구 해상도 재업로드 |
| 개인정보 URL 404 | GitHub Pages 배포 확인 |
| Guideline 2.1 크래시 | 실기기 재테스트 후 빌드 번호 +1 |
| Kids 카테고리 | 일반(교육) 카테고리로 재검토 |

---

## 버전 관리 규칙

| 변경 종류 | Marketing Version | Build Number |
|-----------|-------------------|--------------|
| 심사 거절 후 재업로드 (동일 1.0) | 1.0 | +1 |
| 버그 수정 출시 | 1.0.1 | +1 |
| 기능 추가 출시 | 1.1 | +1 |
