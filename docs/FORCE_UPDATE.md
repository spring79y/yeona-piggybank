# 강제 업데이트 버전 정책

**정책: 모든 출시는 강제 업데이트입니다.**  
새 버전이 스토어에 공개되면, 아래 JSON의 최소 버전/빌드를 그 버전으로 올려 이전 앱을 막습니다.

앱은 시작 시 JSON을 읽어, 설치된 버전/빌드가 최소 요구보다 낮으면 스토어로만 보냅니다.

URL: `https://spring79y.github.io/yeona-piggybank/app-version.json`  
Fallback: `https://raw.githubusercontent.com/spring79y/yeona-piggybank/main/docs/app-version.json`  
파일(동기화 유지):
- `docs/app-version.json` (이 폴더 → GitHub Pages)
- 저장소 루트 `docs/app-version.json`

## 매 출시 절차 (필수)

1. 앱 버전 올리기 (iOS Marketing/Build, Android versionName/versionCode)
2. App Store / Play에 새 빌드 업로드·**스토어에 공개될 때까지 대기**
3. 두 `app-version.json`을 **방금 출시한 버전**으로 맞춤
   - iOS: `minimumVersion` = Marketing, `minimumBuild` = Build
   - Android: `minimumVersion` = versionName, `minimumBuild` = versionCode
4. `main`에 푸시해 GitHub Pages가 갱신되게 함

```json
{
  "ios": {
    "minimumVersion": "1.3.1",
    "minimumBuild": 2
  },
  "android": {
    "minimumVersion": "0.0.0",
    "minimumBuild": 0,
    "storeUrl": "https://play.google.com/store/apps/details?id=com.yeona.piggybank"
  }
}
```

> Android는 비공개 테스트 중에는 `minimumVersion`/`minimumBuild`를 `0.0.0` / `0`으로 두어 강제 업데이트를 끕니다. 정식 출시 후 강제가 필요하면 출시 버전으로 올립니다.

> 스토어에 새 빌드가 보이기 **전에** JSON만 올리면, 사용자가 스토어로 보내져도 새 버전을 못 받을 수 있습니다. 반드시 **스토어 공개 후** JSON을 푸시하세요.

## 비교 규칙

- 마케팅 버전이 더 낮으면 → 강제
- 버전이 같고 빌드만 낮으면 → 강제
- JSON을 못 읽으면(오프라인 등) → 앱을 막지 않음

## 주의

이미 설치된 앱에 **강제 업데이트 코드가 있어야** 동작합니다.  
강제 업데이트 코드가 없는 아주 오래된 빌드는 JSON을 올려도 막히지 않습니다.
