<div align="center">

# 💊 MediAssure

###  Medicine Tracking & Adherence App_

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue)](pubspec.yaml)

> **MediAssure** is a cross-platform mobile application built with Flutter that helps patients never miss a dose, enables caretakers to remotely monitor medication adherence, and empowers doctors to manage prescriptions — all in one place.

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [App Roles](#-app-roles)
- [Screenshots & Flow](#-screenshots--flow)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Getting Started](#-getting-started)
- [Firebase Setup](#-firebase-setup)
- [Dependencies](#-dependencies)
- [How It Works](#-how-it-works)
- [Contributing](#-contributing)

---

## 🌟 Overview

MediAssure solves a critical real-world problem: **medication non-adherence**. Studies show that nearly 50% of patients don't take medicines as prescribed. MediAssure bridges this gap by creating a connected ecosystem of **Patients**, **Caretakers**, and **Doctors**.

- 🔔 **Patients** receive scheduled local notifications for each medicine dose.
- 👁️ **Caretakers** get real-time alerts when a patient misses or takes their medicine — with **photo proof**.
- 🩺 **Doctors** can view their patients' adherence history and issue digital prescriptions.

---

## ✨ Features

### 👤 For Patients
- 📅 **Medicine Schedule** — Add medicines with name, dosage, frequency (daily/weekly), and duration
- ⏰ **Smart Reminders** — Scheduled local push notifications at the exact time of each dose
- 📸 **Photo Verification** — Take a photo of the medicine while marking it as "taken"
- 📊 **Adherence History** — Visual calendar and chart showing past adherence rates
- 💬 **Chat with Caretaker** — Built-in real-time messaging channel
- 👨‍⚕️ **View Prescriptions** — Access doctor-issued digital prescriptions

### 🧑‍🤝‍🧑 For Caretakers
- 📡 **Live Patient Dashboard** — View all linked patients in one place
- 🚨 **Missed Dose Alerts** — Instant alerts when a patient skips a scheduled dose
- 🖼️ **Photo Evidence** — See the photo taken by the patient as proof of consumption
- 📜 **Patient Logs** — Full history of adherence actions with timestamps
- ➕ **Add Prescriptions** — Create and assign medicine schedules to patients

### 🩺 For Doctors
- 🏥 **Doctor Dashboard** — Overview of all registered patients
- 📋 **Patient Detail View** — View individual patient profiles and adherence reports
- 📝 **Digital Prescriptions** — Issue and manage prescriptions digitally

### 🔒 General
- 🔐 **Firebase Authentication** — Secure email/password sign-up & login
- 👤 **Role-Based Access** — Separate dashboards for Patient, Caretaker, and Doctor
- 🎨 **Custom Theme** — Clean, modern UI with a consistent design system
- 📱 **Portrait Lock** — Optimized for mobile portrait use

---

## 👥 App Roles

MediAssure supports **three user roles**, each with a completely different experience:

| Role | What They Do |
|------|-------------|
| 🧑‍⚕️ **Patient** | Manages their own medicine schedule, receives reminders, logs adherence with photo proof |
| 🧑‍🤝‍🧑 **Caretaker** | Monitors linked patients remotely, views alerts, tracks adherence history |
| 👨‍⚕️ **Doctor** | Views patient profiles, issues digital prescriptions, monitors adherence |

> Roles are assigned at **signup** and cannot be changed after profile completion.

---

## 🗂️ Project Structure

```
mediassure/
├── lib/
│   ├── main.dart                        # App entry point — Firebase init, notifications
│   ├── auth_wrapper.dart                # Smart router: redirects based on role & auth state
│   ├── firebase_options.dart            # Auto-generated Firebase config
│   │
│   ├── models/                          # Data models (plain Dart classes)
│   │   ├── user_role_model.dart         # UserModel + UserRole enum (patient/caretaker/doctor)
│   │   ├── medicine_model.dart          # Medicine name, dosage, schedule, duration
│   │   ├── prescription_model.dart      # Doctor-issued prescriptions
│   │   ├── adherence_log_model.dart     # Log of taken/missed doses with photo
│   │   ├── patient_log_model.dart       # Caretaker-visible patient activity log
│   │   ├── caretaker_model.dart         # Caretaker profile data
│   │   ├── chat_message_model.dart      # Chat message structure
│   │   ├── app_notification_model.dart  # In-app notification model
│   │   └── patient_model.dart           # Patient profile data
│   │
│   ├── services/                        # Business logic & Firebase interactions
│   │   ├── auth_service.dart            # Sign-up, login, logout via Firebase Auth
│   │   ├── firestore_service.dart       # Core Firestore read/write helpers
│   │   ├── notification_service.dart    # Local notifications scheduling & cancellation
│   │   ├── adherence_service.dart       # Mark taken/missed, recover lost camera data
│   │   ├── medicine_service.dart        # CRUD for medicine schedules
│   │   ├── prescription_service.dart    # Create & fetch prescriptions
│   │   ├── patient_service.dart         # Patient-caretaker linking, patient data
│   │   ├── caretaker_service.dart       # Caretaker-specific queries
│   │   ├── chat_service.dart            # Real-time chat messages
│   │   ├── image_picker_service.dart    # Camera / gallery image selection
│   │   └── patient_log_service.dart     # Write & read patient activity logs
│   │
│   ├── screens/                         # UI screens organized by role
│   │   ├── splash_screen.dart           # Animated launch screen
│   │   ├── login_screen.dart            # Login UI
│   │   ├── signup_screen.dart           # Registration with role selection
│   │   ├── profile_completion_screen.dart # First-time profile setup
│   │   ├── dashboard_screen.dart        # Role-selector landing screen
│   │   ├── add_medicine_screen.dart     # Add/edit medicine form
│   │   ├── medicine_list_screen.dart    # View all medicines
│   │   ├── prescription_screen.dart     # View prescriptions
│   │   ├── caretaker_screen.dart        # Link caretaker flow
│   │   ├── chat_screen.dart             # Real-time chat UI
│   │   ├── profile_screen.dart          # Edit user profile
│   │   ├── app_theme.dart               # App-wide color & typography theme
│   │   │
│   │   ├── patient/                     # Patient-specific screens
│   │   │   ├── main_patient_screen.dart # Bottom-nav shell for patient
│   │   │   ├── dashboard.dart           # Today's medicines + adherence summary
│   │   │   ├── medications.dart         # Full medicine list with schedule
│   │   │   ├── history.dart             # Calendar view + adherence chart
│   │   │   ├── notifications.dart       # In-app notification feed
│   │   │   └── profile.dart             # Patient profile & caretaker links
│   │   │
│   │   ├── caretaker/                   # Caretaker-specific screens
│   │   │   ├── caretaker_main_screen.dart  # Bottom-nav shell for caretaker
│   │   │   ├── patient_detail_screen.dart  # Detailed view of one patient
│   │   │   ├── patient_logs_screen.dart    # Full activity log of a patient
│   │   │   └── add_prescription_screen.dart # Issue a new prescription
│   │   │
│   │   └── doctor/                      # Doctor-specific screens
│   │       ├── doctor_dashboard_screen.dart      # List of all patients
│   │       └── doctor_patient_detail_screen.dart # Patient adherence detail
│   │
│   ├── widgets/                         # Reusable UI components
│   └── utils/                           # Utility/helper functions
│
├── assets/
│   └── wellness_bg.png                  # Background image asset
│
├── android/                             # Android platform files
├── ios/                                 # iOS platform files
├── firestore.rules                      # Firestore security rules
├── firebase.json                        # Firebase project config
└── pubspec.yaml                         # Package dependencies
```

---

## 🛠️ Tech Stack

| Technology | Purpose |
|-----------|---------|
| **Flutter 3.x** | Cross-platform mobile UI framework |
| **Dart 3.x** | Programming language |
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | Real-time NoSQL database |
| **Firebase Messaging** | Push notification delivery |
| **flutter_local_notifications** | Scheduling local dose reminders |
| **flutter_timezone** | Accurate timezone-aware scheduling |
| **fl_chart** | Adherence rate charts & graphs |
| **table_calendar** | Calendar view for history tab |
| **image_picker** | Camera & gallery photo capture |
| **geolocator** | Location services (optional features) |
| **shared_preferences** | Local key-value persistence |
| **intl** | Date/time formatting & internationalization |

---

## 📋 Prerequisites

Before you begin, make sure you have the following installed:

- ✅ [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- ✅ [Dart SDK](https://dart.dev/get-dart) `>=3.0.0`
- ✅ [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extension
- ✅ A physical Android device or emulator (API 21+)
- ✅ A [Firebase project](https://console.firebase.google.com) (free tier works)
- ✅ [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) for Firebase configuration

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/manvitha0101/mediassure.git
cd mediassure
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

See the [Firebase Setup](#-firebase-setup) section below.

### 4. Run the App

```bash
# For debug mode
flutter run

# For a specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

### 5. Build for Release (Android)

```bash
flutter build apk --release
```

---

## 🔥 Firebase Setup

MediAssure uses Firebase as its backend. Follow these steps to connect your own Firebase project:

### Step 1: Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **"Add Project"** and follow the setup wizard

### Step 2: Enable Services
In your Firebase project, enable:
- ✅ **Authentication** → Email/Password sign-in method
- ✅ **Cloud Firestore** → Start in **Test mode** first, then apply security rules
- ✅ **Firebase Storage** (for photo uploads)
- ✅ **Firebase Messaging** (for push notifications)

### Step 3: Connect Flutter App
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (run from project root)
flutterfire configure
```
This generates `lib/firebase_options.dart` automatically.

### Step 4: Apply Firestore Security Rules
Copy the contents of `firestore.rules` to your Firebase Console under:
> Firestore → Rules → Edit rules → Publish

---

## 📦 Dependencies

```yaml
dependencies:
  firebase_core: ^3.3.0         # Firebase initialization
  firebase_auth: ^5.1.4         # Authentication
  cloud_firestore: ^5.2.1       # Database
  firebase_messaging: ^15.2.10  # Push notifications
  flutter_local_notifications: ^17.2.2  # Scheduled reminders
  flutter_timezone: ^5.0.2      # Timezone support
  timezone: ^0.9.4              # Timezone data
  image_picker: ^1.1.2          # Camera / gallery
  fl_chart: ^1.2.0              # Charts & graphs
  table_calendar: ^3.2.0        # Calendar widget
  geolocator: ^13.0.1           # Location
  shared_preferences: ^2.5.5    # Local storage
  intl: ^0.20.2                 # Date formatting
  cupertino_icons: ^1.0.8       # iOS-style icons
```

---

## ⚙️ How It Works

### Authentication Flow
```
App Launch
   └── AuthWrapper checks Firebase Auth state
         ├── Not logged in → SplashScreen → LoginScreen
         ├── Logged in, profile incomplete → ProfileCompletionScreen
         └── Logged in, profile complete
               ├── role = patient    → MainPatientScreen
               ├── role = caretaker  → CaretakerMainScreen
               └── role = doctor     → DoctorDashboardScreen
```

### Notification Flow
```
User adds Medicine
   └── NotificationService.scheduleAllRemindersForUser()
         └── For each medicine dose time
               └── flutter_local_notifications schedules alarm
                     └── At dose time → Notification fires
                           └── Patient marks "Taken" + captures photo
                                 └── AdherenceService logs to Firestore
                                       └── Caretaker sees update in real-time
```

### Caretaker Linking
```
Patient shares their UID/email
   └── Caretaker enters Patient ID in app
         └── Firestore transaction links both accounts
               └── Caretaker can now view patient's dashboard
```

---

## 🔐 Security

- All Firestore reads/writes are protected by security rules in `firestore.rules`
- Users can only read/write their **own** data
- Caretakers can only read patient data for **explicitly linked** patients
- Doctors can view patient data for their **registered patients** only

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push to the branch: `git push origin feature/your-feature-name`
5. Open a Pull Request

---


<div align="center">

Built with ❤️ using **Flutter** & **Firebase**

⭐ If you found this project useful, please give it a star!

</div>
