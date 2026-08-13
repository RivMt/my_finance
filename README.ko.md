# MyFinance

<p>
  <img src="assets/icon/icon-full.png" alt="MyFinance 아이콘" width="200">
</p>

## 앱 소개

MyFinance는 계좌, 결제 수단, 수입·지출 거래를 한곳에서 관리하는 Flutter 기반 개인 재무 관리 앱입니다. 여러 앱의 API 엔드포인트를 함께 제공하는 별도 백엔드 프로젝트 `kyro`를 통해 데이터를 저장하고 OIDC(OpenID Connect) 인증 서버를 사용하며, 모바일·데스크톱·웹 화면 크기에 맞춰 UI가 바뀝니다.

- Flutter / Dart로 작성된 멀티 플랫폼 클라이언트
- `my_api` 패키지를 통한 REST API 통신과 OIDC 로그인
- 한국어, 영어, 일본어 지원
- 시스템 설정에 따른 라이트·다크 테마 지원

> 이 저장소는 클라이언트 앱입니다. 실제로 사용하려면 MyFinance 엔드포인트가 활성화된 `kyro` 백엔드와 OIDC 공급자가 별도로 필요합니다.

## 기능

- **계좌 관리**: 계좌별 잔액, 통화, 한도, 아이콘과 색상을 설정하고 계좌별 거래 내역을 확인합니다.
- **결제 수단 관리**: 카드 등의 결제 수단과 결제일·이용 기간·한도를 관리하고 결제 예정 금액을 계산합니다.
- **거래 관리**: 수입과 지출을 기록하고 계좌, 결제 수단, 카테고리, 사용일, 결제일, 설명 등을 함께 저장합니다. 서로 다른 통화를 사용하는 거래도 기록할 수 있습니다.
- **카테고리 관리**: 수입·지출 카테고리를 구분하고 통계 포함 여부, 아이콘과 색상을 설정합니다.
- **대시보드와 통계**: 이번 달 카테고리별 지출, 향후 결제 예정 금액, 통화별 목표 잔액을 확인합니다. 월별 카테고리 지출 화면도 제공합니다.
- **검색과 조회**: 거래 설명을 검색하고, 기간을 지정한 고급 조회 결과를 표로 확인하거나 CSV로 내보냅니다.
- **CSV 가져오기**: CSV의 날짜·금액 열, 날짜 형식, 계좌, 결제 수단, 수입·지출 카테고리를 지정해 거래를 미리 보고 일괄 등록합니다.
- **삭제 항목 복원**: 삭제한 계좌와 결제 수단을 휴지통에서 복원합니다.
- **환경 설정**: 기본 통화, 원형 차트 항목 수, 날짜별 목표 잔액을 설정합니다.

## 설정 방법

### 1. 개발 환경 준비

다음 항목이 필요합니다.

- Flutter SDK(Dart `>=3.0.0 <4.0.0`)
- 대상 플랫폼의 Flutter 빌드 도구
- MyFinance API 엔드포인트를 제공하는 `kyro` 백엔드 및 OIDC 서버

저장소를 받은 뒤 의존성을 설치합니다.

```bash
flutter pub get
```

`my_api`는 기본적으로 `pubspec.yaml`에 지정된 Git 저장소의 `master` 브랜치에서 설치됩니다. 앱과 `my_api`를 나란히 체크아웃해 함께 개발한다면 `pubspec_overrides_dev.yaml`을 `pubspec_overrides.yaml`로 복사해 로컬 `../my_api`를 사용합니다. `pubspec_overrides.yaml`은 Git에 포함되지 않습니다.

### 2. `assets/key/config.json` 작성

앱은 시작할 때 `assets/key/config.json`을 읽어 API 클라이언트와 OIDC 인증을 초기화합니다. 이 파일이 없거나 JSON 형식이 잘못되면 앱이 시작되지 않습니다.

`assets/key` 디렉터리에 다음 형식으로 파일을 만듭니다.

```json
{
  "apiUri": "api.example.com",
  "authUri": "https://auth.example.com/realms/my-finance",
  "clientId": "my-finance",
  "clientSecret": "replace-with-your-client-secret",
  "redirectUri": "https://app.example.com/redirect.html",
  "mode": "production"
}
```

| 키 | 설명 |
| --- | --- |
| `apiUri` | `kyro` REST API의 호스트와 선택적 포트입니다. 현재 구현은 스킴 없이 `host` 또는 `host:port` 형식을 사용합니다. 예: `api.example.com`, `localhost:8080` |
| `authUri` | OIDC 공급자 또는 realm의 전체 URI입니다. 이 URI를 기준으로 discovery 문서를 찾습니다. |
| `clientId` | OIDC에 등록한 클라이언트 ID입니다. |
| `clientSecret` | OIDC 클라이언트 secret입니다. |
| `redirectUri` | OIDC 로그인 결과를 받을 URI입니다. OIDC 서버에 등록한 값과 정확히 같아야 합니다. 웹에서는 배포 주소의 `/redirect.html`을 사용할 수 있습니다. |
| `mode` | 애플리케이션 모드입니다: `production`, `dev`, `demo`. `dev`는 REST API에 HTTP를 사용하고, 나머지 모드는 HTTPS를 사용합니다. |

`assets/key/*`는 `.gitignore`에 포함되어 있어 저장소에 커밋되지 않습니다. 다만 Flutter asset은 빌드 결과물에 패키징되므로 `config.json`의 값은 최종 사용자에게 완전히 비밀로 유지되지 않습니다. 운영 환경에서는 노출되어도 안전한 OIDC 클라이언트 구성을 사용하고, 실제 비밀값을 소스 관리나 배포 가능한 공개 빌드에 넣지 마세요.

### 3. locale 키 생성

번역 원본은 다음 JSON 파일입니다.

- `assets/locale/ko-KR.json`
- `assets/locale/en-US.json`
- `assets/locale/ja-JP.json`

앱은 `easy_localization`으로 번역 파일을 런타임에 읽고, 코드에서는 `LocaleKeys` 상수를 사용합니다. `lib/generated/locale_keys.g.dart`는 생성 파일이라 Git에서 제외되어 있으므로, 최초 실행 전이나 번역 키를 추가·삭제한 뒤 아래 명령으로 다시 생성해야 합니다.

```bash
dart run easy_localization:generate \
  -S assets/locale \
  -O lib/generated \
  -o locale_keys.g.dart \
  -f keys
```

PowerShell에서는 한 줄로 실행할 수 있습니다.

```powershell
dart run easy_localization:generate -S assets/locale -O lib/generated -o locale_keys.g.dart -f keys
```

새 언어를 추가하려면 번역 JSON을 만든 뒤 `lib/main.dart`의 `supportedLocales`에도 해당 `Locale`을 추가하고 locale 키를 다시 생성합니다. 세 번역 파일은 같은 키 구조를 유지하는 것이 좋습니다.

### 4. 실행

연결된 기기를 확인하고 원하는 대상으로 실행합니다.

```bash
flutter devices
flutter run -d <device-id>
```

웹으로 실행하는 예시는 다음과 같습니다.

```bash
flutter run -d chrome
```

OIDC 서버에는 실행 환경에서 사용하는 `redirectUri`를 허용된 redirect URI로 등록해야 합니다. 웹 배포 시에는 저장소의 `web/redirect.html`도 함께 배포됩니다.
