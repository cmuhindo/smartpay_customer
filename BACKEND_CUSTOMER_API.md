# SmartPay customer-authenticated API layer

## Added routes

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

Customer login is separate from the existing staff login route. It accepts the same email/password/device-name shape but only issues a token when the account is active and has the `customer` role.

All customer routes use Sanctum bearer tokens and the `role:customer` middleware. Loan details, repayments, and cases are ownership-scoped to the authenticated customer; unauthorized records return 404 rather than revealing their existence.

## Changed Laravel files

```text
app/Http/Controllers/Api/Customer/AuthController.php
app/Http/Controllers/Api/Customer/LoanController.php
app/Http/Controllers/Api/Customer/PaymentController.php
app/Http/Controllers/Api/Customer/CaseController.php
app/Http/Resources/LoanResource.php
routes/api.php
```

The customer repayment controller reuses the existing MamboPay provider, pending-payment lifecycle, and status polling behavior. Provider credentials remain server-side.

## Deployment

Copy the files to matching paths in the Laravel project, then run:

```bash
php artisan optimize:clear
php artisan route:list --path=api/customer
```

No database migration is required for this API layer.
