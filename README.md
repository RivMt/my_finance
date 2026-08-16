# MyFinance

[한국어](README.ko.md)

<p>
  <img src="assets/icon/icon-full.png" alt="MyFinance icon" width="200">
</p>

## Introduction

[Demo Page](https://rivmt.github.io/my_finance/)

MyFinance is a Flutter-based personal finance application for managing accounts, payment methods, income, and expenses in one place. It stores data through `kyro`, a separate backend project that provides API endpoints for multiple applications, and uses an OIDC (OpenID Connect) authentication server. Its interface adapts to mobile, desktop, and web screen sizes.

- Cross-platform client built with Flutter and Dart
- REST API communication and OIDC login through the `my_api` package
- Korean, English, and Japanese localization
- Light and dark themes based on the system setting

> This repository contains the client application. A running `kyro` backend with the MyFinance endpoints enabled and an OIDC provider are required to use it.

## Features

- **Account management**: Configure the balance, currency, limit, icon, and colors of each account, and view its transaction history.
- **Payment method management**: Manage payment methods such as cards, including their payment date, billing period, and limit, and calculate upcoming payment amounts.
- **Transaction management**: Record income and expenses with an account, payment method, category, transaction date, payment date, and description. Transactions involving different currencies are also supported.
- **Category management**: Organize income and expense categories and configure whether each category is included in statistics, along with its icon and colors.
- **Dashboard and statistics**: View spending by category for the current month, upcoming payment amounts, and target balances by currency. A monthly category expense view is also available.
- **Search and queries**: Search transaction descriptions, inspect advanced query results for a selected date range in a table, and export the results as CSV.
- **CSV import**: Select date and amount columns, a date format, an account, a payment method, and income and expense categories; preview the resulting transactions; and import them in bulk.
- **Deleted item recovery**: Restore deleted accounts and payment methods from the trash.
- **Preferences**: Configure the default currency, the number of pie chart entries, and target balances by date.

## Setup

### 1. Prepare the development environment

You will need:

- Flutter SDK with Dart `>=3.0.0 <4.0.0`
- Flutter build tools for the target platform
- Access to a `kyro` backend serving the MyFinance API endpoints and an OIDC server

After cloning the repository, install the dependencies:

```bash
flutter pub get
```

By default, `my_api` is installed from the `master` branch of the Git repository specified in `pubspec.yaml`. To develop this application and `my_api` side by side, copy `pubspec_overrides_dev.yaml` to `pubspec_overrides.yaml`. This makes the project use the local `../my_api` directory. `pubspec_overrides.yaml` is excluded from Git.

### 2. Create `assets/key/config.json`

At startup, the application reads `assets/key/config.json` to initialize the API client and OIDC authentication. The application will not start if this file is missing or contains invalid JSON.

Create the file under `assets/key` using the following structure:

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

| Key | Description |
| --- | --- |
| `apiUri` | The `kyro` REST API host and optional port. The current implementation expects `host` or `host:port` without a URI scheme, for example `api.example.com` or `localhost:8080`. |
| `authUri` | The full URI of the OIDC provider or realm. The application uses it to locate the discovery document. |
| `clientId` | The client ID registered with the OIDC provider. |
| `clientSecret` | The OIDC client secret. |
| `redirectUri` | The URI that receives the OIDC login result. It must exactly match a redirect URI registered with the OIDC provider. On the web, this can point to `/redirect.html` on the deployed application. |
| `mode` | Application mode: `production`, `dev`, or `demo`. `dev` uses HTTP for the REST API; the other modes use HTTPS. |

`assets/key/*` is excluded by `.gitignore` and must not be committed. However, Flutter assets are packaged into the build, so values in `config.json` are not completely secret from end users. Use OIDC client settings that are safe to expose in production, and do not place real secrets in source control or publicly distributed builds.

### 3. Generate locale keys

The translation sources are:

- `assets/locale/ko-KR.json`
- `assets/locale/en-US.json`
- `assets/locale/ja-JP.json`

The application loads these translation files at runtime with `easy_localization` and references translations in code through `LocaleKeys` constants. Because the generated `lib/generated/locale_keys.g.dart` file is excluded from Git, generate it before the first run and whenever translation keys are added or removed:

```bash
dart run easy_localization:generate \
  -S assets/locale \
  -O lib/generated \
  -o locale_keys.g.dart \
  -f keys
```

In PowerShell, run the command on one line:

```powershell
dart run easy_localization:generate -S assets/locale -O lib/generated -o locale_keys.g.dart -f keys
```

To add another language, create its translation JSON file, add the corresponding `Locale` to `supportedLocales` in `lib/main.dart`, and regenerate the locale keys. Keep the same key structure across all translation files.

### 4. Run the application

List the connected devices and run the application on the desired target:

```bash
flutter devices
flutter run -d <device-id>
```

For example, to run the web application:

```bash
flutter run -d chrome
```

Register the `redirectUri` used by the target environment as an allowed redirect URI with the OIDC provider. For web deployments, the repository's `web/redirect.html` is included in the deployed output.
