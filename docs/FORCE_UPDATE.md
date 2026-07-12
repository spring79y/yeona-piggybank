# 강제 업데이트 버전 정책

앱은 시작 시 아래 JSON을 읽어, 설치된 버전/빌드가 최소 요구보다 낮으면 스토어로만 보냅니다.

URL: `https://spring79y.github.io/yeona-piggybank/app-version.json`  
Fallback: `https://raw.githubusercontent.com/spring79y/yeona-piggybank/main/docs/app-version.json`  
파일: `docs/app-version.json` (이 폴더 → GitHub Pages `/docs`)

## 새 빌드 배포할 때

1. App Store / Play에 새 빌드 업로드·출시
2. `docs/app-version.json`의 `minimumBuild`를 **그 빌드 번호**로 올림
3. `main`에 푸시해 GitHub Pages / raw URL이 갱신되게 함

```json
{
  "ios": {
    "minimumVersion": "1.2",
    "minimumBuild": 5
  },
  "android": {
    "minimumVersion": "1.1",
    "minimumBuild": 1,
    "storeUrl": "https://play.google.com/store/apps/details?id=com.yeona.piggybank"
  }
}
```

## 비교 규칙

- 마케팅 버전이 더 낮으면 → 강제
- 버전이 같고 빌드만 낮으면 → 강제
- JSON을 못 읽으면 → 앱을 막지 않음
