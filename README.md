# SmartPay Customer Flutter App

Native Flutter/Dart customer app for SmartPay hire-purchase customers.

## Customer capabilities

The app provides customer-only sign-in, account details, loan summaries, loan balance, paid-through timestamp, next scheduled repayment, installment schedule, repayment history, Mobile Money repayment initiation and polling, customer-care cases, case feedback activity, and read-only account security information.

## Backend API additions

The Laravel backend adds these customer-authenticated endpoints:

```text
POST /api/customer/login
POST /api/customer/logout
GET  /api/customer/me
GET  /api/customer/loans
GET  /api/customer/loans/{loan}
POST /api/customer/loans/{loan}/repayments
GET  /api/customer/loans/{loan}/repayments/{payment}/status
GET  /api/customer/cases
GET  /api/customer/cases/{case}
```

All endpoints after login require a Sanctum bearer token and the `customer` role. Every loan and case query is ownership-scoped to the authenticated customer. Existing staff API routes are unchanged.

## Flutter setup

Install Flutter locally, then from this directory run:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://app.smartpayug.com/api
```

For a production build:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://app.smartpayug.com/api
```

The sandbox used to author this source did not have Flutter or Dart installed, so the project could not be compiled in this environment. Run `flutter analyze` and `flutter test` on a machine with the Flutter SDK before releasing.

## Production backend deployment

Copy the Laravel backend files from the accompanying backend archive into the live SmartPay project. Then run:

```bash
php artisan optimize:clear
php artisan route:list --path=api/customer
```

The customer app reuses the existing MamboPay payment integration. It never receives provider credentials; the Laravel server initiates and polls Mobile Money transactions.

## Suggested release hardening

Before public release, add password reset, email/phone verification, rate limiting on customer login and repayment initiation, API request logging without secrets, and push notifications for payment status changes.
