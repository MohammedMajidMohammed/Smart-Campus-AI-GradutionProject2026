<div align="center">

<img src="assets/images/app_icon.png" alt="MNU Smart Canvas Logo" width="150"/>

# MNU Smart Canvas
### AI-Powered University Management System for Menoufia National University (MNU)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Gemini AI](https://img.shields.io/badge/Gemini-AI-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://deepmind.google/technologies/gemini/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-success?style=for-the-badge)](pubspec.yaml)

*A next-generation university management platform that unifies attendance, academics, and AI assistance in one seamless experience.*

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Role-Based System](#-role-based-system)
- [Architecture](#️-architecture)
- [Technology Stack](#️-technology-stack)
- [Database Schema](#-database-schema)
- [Installation & Setup](#-installation--setup)
- [Project Structure](#-project-structure)
- [Security](#-security)
- [Screenshots](#-screenshots)
- [Contributing](#-contributing)

---

## 🌟 Overview

**MNU Smart Canvas** is a comprehensive, production-ready university management system built with Flutter and powered by Supabase as a backend-as-a-service platform. It serves three distinct user roles — **Students**, **Professors**, and **Administrators** — each with a tailored experience and specific feature set.

The platform's flagship feature is its **Anti-Fraud Attendance System**, which uses dynamic rotating QR codes validated against Wi-Fi SSID and device fingerprinting to guarantee physical presence — making it virtually impossible to spoof.

Beyond attendance, MNU Smart Canvas integrates **Google Gemini AI** for two specialized chatbots: an Academic Advisor and a Regulations Bot, giving students instant, intelligent answers.

---

## 🚀 Key Features

### 🔐 Anti-Fraud Attendance System
The most sophisticated feature of the platform, engineered to eliminate proxy attendance:

| Security Layer | Description |
|---|---|
| **Rotating QR Codes** | QR tokens regenerate every **5 minutes**, expiring old codes automatically |
| **Wi-Fi SSID Validation** | Student's device must be on the **same campus network** as the professor |
| **Device Fingerprinting** | Each scan is tied to a unique device ID — one device, one student |
| **Optional PIN Lock** | Professors can display a 4-digit PIN for an additional manual verification step |
| **Real-time Sync** | Attendance records update live via Supabase WebSockets |

### 🤖 AI-Powered Chatbots (Google Gemini)
- **Study Advisor Bot** — Provides personalized academic guidance, study tips, and schedule management using contextual conversation history.
- **University Regulations Bot (RAG)** — A Retrieval-Augmented Generation chatbot trained on university bylaws and regulations, answering student queries with precise, source-backed responses.

### 📅 Smart Schedule Management
- **Drag-and-drop schedule editing** for Administrators
- **Weekly timetable view** for Students and Professors
- **Google Calendar-style** layout with color-coded subjects
- Conflict detection for room and professor scheduling

### 📚 Subjects & Academic Materials
- Centralized repository for lecture notes, PDFs, and academic resources
- Subject-specific chat rooms for professor-student communication
- Material upload/download with file preview support

### 🎓 Assignments & Exams
- Assignment creation and submission workflow
- Exam scheduling with countdown timers on dashboards
- Grade tracking and GPA visualization

### 🎥 Online Sessions
- Live online session management for professors
- Students can join directly from their dashboard

### 🏢 Campus Infrastructure (Administrator)
- **Building & Room Management** — Define physical spaces, link them to schedules
- **College Management** — Organize faculties and departments
- **User Management** — Create, edit, and manage all users with role assignment

### 📊 Analytics Dashboards
- Attendance rate charts per subject and student
- User activity analytics for administrators
- Role-specific KPI widgets with real-time data

### 🔔 Notifications
- Firebase Cloud Messaging (FCM) for push notifications
- Targeted announcements by role
- Deep-linked alerts routing to relevant screens

### 🌍 Localization
- Multi-language support via `easy_localization`
- Translation files for Arabic and English

---

## 👥 Role-Based System

MNU Smart Canvas implements a strict **Role-Based Access Control (RBAC)** system with four defined roles stored in the database. Each role unlocks a completely different navigation shell and feature set.

```
Roles in Database
├── Student       → Student Home, Schedule, Attendance Scanner, Chatbots, Subjects
├── Doctor        → Professor Dashboard, Attendance Generator, Exam & Assignment Management
├── Admin         → Admin Dashboard, Subjects, Materials, Classroom Management, Schedule
└── Administrator → Full System Control, User Management, Buildings, Colleges, Rooms
```

| Feature | Student | Doctor | Admin | Administrator |
|---|:---:|:---:|:---:|:---:|
| View Schedule | ✅ | ✅ | ✅ | ✅ |
| Scan QR Attendance | ✅ | — | — | — |
| Generate QR Attendance | — | ✅ | — | — |
| AI Chatbots | ✅ | — | — | — |
| Manage Subjects | — | — | ✅ | — |
| Manage Users | — | — | — | ✅ |
| Manage Buildings/Rooms | — | — | — | ✅ |
| Edit Schedule | — | — | ✅ | ✅ |
| View Analytics | — | ✅ | ✅ | ✅ |
| Push Notifications | ✅ | ✅ | ✅ | ✅ |

---

## 🏛️ Architecture

MNU Smart Canvas follows **Clean Architecture** principles with a clear separation of concerns across three layers:

```
lib/
├── core/                          # Shared infrastructure
│   ├── app_route/                 # Named route definitions & navigation
│   ├── cache/                     # Hive local storage abstraction
│   ├── components/                # Shared reusable widgets
│   ├── constants/                 # App-wide constants (Supabase keys, routes, etc.)
│   ├── di/                        # Dependency injection (get_it)
│   ├── error/                     # Failure models & error handling
│   ├── helper/                    # Utility functions
│   ├── network/                   # Supabase data sources & repositories
│   ├── services/                  # Background services (notifications, FCM)
│   └── utilies/                   # Theme, extensions, formatters
│
└── features/                      # Feature modules (each self-contained)
    ├── auth/                      # Sign-in, sign-up, password reset
    ├── splash/                    # Splash screen & role-based routing
    ├── on_boarding/               # First-launch onboarding flow
    ├── student/                   # Student feature shell
    │   ├── home/                  # Student dashboard
    │   ├── attendance/            # QR code scanner
    │   ├── schedule/              # Timetable view
    │   ├── subject_details/       # Subject materials & chat
    │   ├── exams/                 # Exam list & countdown
    │   ├── assignments/           # Assignment submissions
    │   ├── chatbots/              # AI chatbot hub
    │   ├── study_chatbot/         # Gemini Study Advisor
    │   ├── regulations_chatbot/   # RAG Regulations Bot
    │   └── online_sessions/       # Session joining
    ├── professor/                 # Professor feature shell
    │   ├── home/                  # Professor dashboard
    │   ├── attendance/            # QR generator & session management
    │   ├── schedule/              # Timetable management
    │   ├── exams/                 # Exam management
    │   ├── assignments/           # Assignment management
    │   └── online_sessions/       # Session creation
    ├── admin/                     # Admin feature shell
    │   ├── home/                  # Admin dashboard
    │   ├── dashboard/             # Analytics & KPIs
    │   ├── subjects/              # Subject management
    │   ├── material/              # Material management
    │   ├── attendance/            # Attendance overview
    │   ├── schedule/              # Schedule editing
    │   └── classroom/             # Classroom management
    ├── administrator/             # Super admin feature shell
    │   ├── home/                  # Administrator dashboard
    │   ├── user_management/       # Full user CRUD
    │   ├── buildings/             # Building management
    │   ├── rooms/                 # Room management
    │   ├── collages/              # College management
    │   ├── schedule/              # Global schedule control
    │   └── chat/                  # System-wide messaging
    ├── chat/                      # Shared chat components
    ├── online_sessions/           # Shared session components
    └── profile/                   # User profile management
```

### State Management Pattern

Each feature follows the **BLoC / Cubit** pattern:

```
feature/
├── models/           # Data models (fromJson / toJson)
├── repositories/     # Abstract repository interface
├── data_sources/     # Supabase REST & Realtime calls
└── view_models/
    └── cubit/        # Business logic (Cubit + States)
        ├── feature_cubit.dart
        └── feature_state.dart
└── views/
    ├── screens/      # Full-page UI screens
    └── widgets/      # Composable UI components
```

---

## 🛠️ Technology Stack

### Frontend
| Technology | Purpose |
|---|---|
| **Flutter 3.x** | Cross-platform UI framework (Android, iOS, Web) |
| **Dart 3.x** | Primary programming language |
| **flutter_bloc ^9.1.1** | State management (BLoC / Cubit pattern) |
| **get_it ^8.0.3** | Dependency injection container |
| **google_fonts ^8.0.2** | Premium typography |
| **flutter_animate ^4.5.2** | Micro-animations & transitions |
| **fl_chart ^0.65.0** | Analytics charts & graphs |
| **lottie ^3.3.1** | Lottie animation playback |

### Backend
| Technology | Purpose |
|---|---|
| **Supabase ^2.8.4** | Backend-as-a-Service (Auth, DB, Realtime, Storage) |
| **PostgreSQL** | Primary relational database |
| **GoTrue** | JWT-based authentication & RBAC |
| **Supabase Realtime** | WebSocket subscriptions for live attendance |
| **Edge Functions** | Serverless PL/pgSQL RPCs for business logic |
| **Row-Level Security (RLS)** | Fine-grained data access policies |

### AI & Intelligence
| Technology | Purpose |
|---|---|
| **Google Gemini API** | LLM for Study Advisor & Regulations chatbots |
| **RAG Pipeline** | Context injection for regulations-aware responses |

### Device & Platform
| Technology | Purpose |
|---|---|
| **mobile_scanner ^3.5.5** | QR code scanning (attendance) |
| **qr_flutter ^4.1.0** | QR code generation (professors) |
| **device_info_plus ^11.3.0** | Device fingerprinting for attendance |
| **connectivity_plus ^6.1.3** | Network connectivity checks |
| **network_info_plus ^6.1.3** | Wi-Fi SSID validation |
| **geolocator ^14.0.2** | GPS location validation |
| **google_maps_flutter ^2.14.0** | Campus map integration |
| **firebase_messaging ^15.2.10** | Push notifications (FCM) |
| **hive ^2.2.3** | Local caching & offline support |
| **flutter_tts ^4.2.5** | Voice navigation & TTS output |
| **record ^6.2.0** | Voice input recording |
| **audioplayers ^6.6.0** | Audio playback |

---

## 🗄️ Database Schema

The core database is hosted on **Supabase (PostgreSQL)**. Below is a high-level overview of the main tables:

```sql
-- Core Identity
roles           (id, name, created_at)
users           (id, name, email, role_id, college_id, avatar_url, ...)

-- Academic Structure
colleges        (id, name, description, ...)
buildings       (id, name, college_id, ...)
rooms           (id, name, building_id, capacity, ...)
subjects        (id, name, code, college_id, professor_id, ...)
materials       (id, subject_id, title, file_url, ...)

-- Scheduling
schedule        (id, subject_id, room_id, day_of_week, start_time, end_time, ...)

-- Attendance
attendance_sessions (id, subject_id, professor_id, qr_token, pin, expires_at, ...)
attendance_records  (id, session_id, student_id, device_id, wifi_ssid, scanned_at, ...)

-- Assessments
exams           (id, subject_id, title, exam_date, room_id, ...)
assignments     (id, subject_id, title, due_date, description, ...)

-- Communication
messages        (id, sender_id, subject_id, content, created_at, ...)
notifications   (id, user_id, title, body, route, is_read, created_at, ...)
```

> **Row-Level Security (RLS)** is enforced on all tables to ensure users can only access data relevant to their role.

---

## 📦 Installation & Setup

### Prerequisites

Ensure the following are installed on your machine:

| Tool | Version | Download |
|---|---|---|
| Flutter SDK | Latest Stable (≥3.x) | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | ≥3.10.1 | Included with Flutter |
| Android Studio / VS Code | Latest | With Flutter & Dart extensions |
| Git | Any | [git-scm.com](https://git-scm.com) |

### Step 1 — Clone the Repository

```bash
git clone https://github.com/MohammedMajidMohammed/Smart-Canvas001.git
cd Smart-Canvas001
```

### Step 2 — Install Dependencies

```bash
flutter pub get
```

### Step 3 — Configure Environment Variables

This project uses `flutter_dotenv` for secure key management. Create a `.env` file in the **project root** (same level as `pubspec.yaml`):

```env
# ── Supabase ────────────────────────────────
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key

# ── Google Maps ─────────────────────────────
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# ── AI Services ─────────────────────────────
GEMINI_API_KEY=your-google-gemini-api-key

# ── Firebase ────────────────────────────────
# Place your google-services.json (Android) and
# GoogleService-Info.plist (iOS) in the respective platform folders.
```

> ⚠️ **Never commit your `.env` file.** It is already listed in `.gitignore`.

### Step 4 — Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Cloud Messaging (FCM)**
3. Download `google-services.json` → place in `android/app/`
4. Download `GoogleService-Info.plist` → place in `ios/Runner/`

### Step 5 — Run the App

```bash
# For Android
flutter run

# For a specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

### Step 6 — Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## 📁 Project Structure

```
Smart-Canvas001/
├── android/                    # Android platform configuration
├── ios/                        # iOS platform configuration
├── web/                        # Web platform configuration
├── windows/                    # Windows platform configuration
├── assets/
│   ├── images/                 # App icons, splash images, UI assets
│   ├── lotties/                # Lottie animation JSON files
│   └── translations/           # i18n JSON files (en.json, ar.json)
├── lib/
│   ├── main.dart               # App entry point & initialization
│   ├── core/                   # Shared infrastructure & utilities
│   └── features/               # Feature-based modules
├── supabase/                   # Supabase migrations & edge functions
├── test/                       # Unit & widget tests
├── .env                        # 🔒 Environment variables (not committed)
├── pubspec.yaml                # Dart dependencies
└── README.md                   # This file
```

---

## 🔒 Security

MNU Smart Canvas implements multiple security layers:

- **JWT Authentication** via Supabase GoTrue — all API calls are signed
- **Row-Level Security (RLS)** — PostgreSQL policies prevent unauthorized data access at the database level
- **Role-Based Access Control** — server-enforced, not just client-side checks
- **Dynamic QR Tokens** — short-lived (5 min) cryptographic tokens prevent replay attacks
- **Device Fingerprinting** — ties attendance records to a specific physical device
- **Wi-Fi SSID Validation** — requires presence on the campus network
- **Secure Key Management** — all secrets stored in `.env`, never hardcoded

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/your-feature-name`
3. **Commit** your changes: `git commit -m 'feat: add some feature'`
4. **Push** to the branch: `git push origin feature/your-feature-name`
5. **Open** a Pull Request

### Commit Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

```
feat:     New feature
fix:      Bug fix
docs:     Documentation update
style:    Formatting, no logic change
refactor: Code restructure
test:     Adding or updating tests
chore:    Build process or auxiliary tool changes
```

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Built with ❤️ using **Flutter** + **Supabase** + **Google Gemini AI**

*MNU Smart Canvas — Redefining the University Experience*

</div>
