# 업데이트 안내 정책 (소프트)

**정책: 앱을 막지 않습니다.**  
설치된 버전이 권장 버전보다 낮으면 **업데이트 안내**만 띄우고, 사용자는 「나중에」로 닫을 수 있습니다.

앱은 시작 시 JSON을 읽습니다.

URL: `https://spring79y.github.io/yeona-piggybank/app-version.json`  
Fallback: `https://raw.githubusercontent.com/spring79y/yeona-piggybank/main/docs/app-version.json`  
파일(동기화 유지):
- `docs/app-version.json` (이 폴더 → GitHub Pages)
- 저장소 루트 `docs/app-version.json`

## 필드

| 필드 | 용도 |
|------|------|
| `recommendedVersion` / `recommendedBuild` | **업데이트 안내** 기준 (새 앱 빌드) |
| `minimumVersion` / `minimumBuild` | 예전 강제 업데이트 앱 호환용. **항상 `0.0.0` / `0`으로 유지**해 강제 잠금을 끕니다 |

## 매 출시 절차

1. 새 빌드를 App Store / Play에 **공개**
2. `recommendedVersion` / `recommendedBuild`를 그 출시 버전으로 올림
3. `minimumVersion` / `minimumBuild`는 `0.0.0` / `0` 유지
4. `main`에 푸시

```json
{
  "ios": {
    "minimumVersion": "0.0.0",
    "minimumBuild": 0,
    "recommendedVersion": "1.3",
    "recommendedBuild": 1
  },
  "android": {
    "minimumVersion": "0.0.0",
    "minimumBuild": 0,
    "recommendedVersion": "0.0.0",
    "recommendedBuild": 0,
    "storeUrl": "https://play.google.com/store/apps/details?id=com.yeona.piggybank"
  }
}
```

> `recommended`는 스토어에 **실제 공개된 버전 이하**로만 올리세요. 스토어에 없는 버전으로 올리면 안내만 뜨고 업데이트 버튼이 「열기」로만 보입니다.

## 동작

- 권장 버전보다 낮음 → 「새 버전이 있어요」 안내 (닫기 가능)
- JSON을 못 읽으면 → 안내하지 않음
- 「나중에」 → 이번 실행에서는 다시 안 띄움
