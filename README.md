# ARMA2

A Flutter + Firebase property management app with role-based access for owners and tenants.

## Overview

ARMA2 helps owners manage properties, units, occupancy, and tenant assignments in real time.  
The app uses Firebase Authentication for login/signup, Cloud Firestore for data storage, and Firebase Messaging + local notifications for push alerts.

## Key Features

### Authentication and Roles

- Email/password sign up and login
- Role-aware navigation after login:
  - `owner` -> Owner portal
  - `tenant` -> Tenant portal
- Forgot password flow

### Owner Portal

- Home dashboard:
  - Total properties
  - Occupancy count and percentage
  - Monthly revenue (calculated from occupied units)
  - Quick actions (add property, add tenant)
- Property management:
  - Add property
  - Update property settings
  - Delete property
- Tenant management:
  - Add tenant to a property/unit by tenant email
  - Tenant settings page to:
    - Change assigned property/unit
    - Remove tenant assignment
  - Real-time tenant list across owner properties
- Analytics tab:
  - Occupancy KPIs
  - Occupancy by property
  - Revenue by property

### Assignment Rules Implemented

- One unit (room) in a property can have only one tenant assignment.
- One tenant can have multiple unit assignments.
- Property `occupied` counters are updated on add/move/remove assignment operations.

### Tenant Portal

- Tenant home screen is currently a placeholder ("Coming Soon").

## Tech Stack

- Flutter (Dart)
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- flutter_local_notifications

## Project Structure

```text
lib/
  backend/
    models/
    services/
      auth/
      properties/
      tenants/
  frontend/
    pages/
      Owner_home_page.dart
      Tenant_home_page.dart
      properties_page.dart
      tenants_page.dart
      tenant_settings_page.dart
      analytics_page.dart
      login_page.dart
      signup_page.dart
  main.dart
```

## Firestore Data Model (Current)

```text
users/{uid}
  uid
  name
  email
  age
  address
  nicNumber
  mobileNumber
  role
  createdAt

users/{ownerId}/properties/{propertyId}
  ownerId
  propertyName
  address
  rentAmount
  units
  occupied
  createdAt

users/{ownerId}/properties/{propertyId}/tenants/{assignmentDocId}
  tenantUid
  unitId
  unitIdNormalized
  createdAt
```

Notes:

- `assignmentDocId` is based on normalized unit ID for uniqueness.
- Unit uniqueness is enforced per property.

## Prerequisites

- Flutter SDK (`>=3.10.0 <4.0.0`)
- Android Studio / VS Code with Flutter tooling
- A Firebase project with:
  - Authentication (Email/Password enabled)
  - Cloud Firestore enabled
  - Cloud Messaging enabled (optional for push notifications)

## Setup

1. Clone the repository

```bash
git clone <your-repo-url>
cd <repo-folder>
```

2. Install dependencies

```bash
flutter pub get
```

3. Configure Firebase

- Android: place `google-services.json` in `android/app/`
- iOS: add `GoogleService-Info.plist` in `ios/Runner/` (if iOS is used)

4. Run the app

```bash
flutter run
```

## Build APK

```bash
flutter build apk --release
```

## Notifications

- `MessagingService` requests FCM permissions and listens for foreground messages.
- `NotificationService` displays local notifications for incoming FCM notifications.

## Current Status and Next Steps

- Owner workflows are implemented and functional.
- Tenant portal is still in progress.
- Recommended next enhancements:
  - Tenant-side data screens
  - Unit availability suggestions in forms
  - Automated tests for tenant move/remove transactions

## Contributing

1. Create a feature branch.
2. Keep changes focused and testable.
3. Open a pull request with a clear summary.

