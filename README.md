# 🚀 Zippa Logistics

> **Fast, Easy and Safe** — A unified logistics platform for Customers, Riders, and Vendors.

![Zippa Logo](imageslogo%20and%20mockup/logo.png)

## 📱 What Is This?

Zippa Logistics is a **single mobile app** that serves three types of users:
- **Customers** — Send packages, track deliveries, rate riders
- **Riders** — Accept deliveries, earn money, manage wallet
- **Vendors** — Create bulk orders, manage business deliveries

## 🏗️ Project Structure

```
zippa-logistics/
├── zippa-backend/     → Node.js + Express API server (PostgreSQL)
├── zippa-app/         → Flutter mobile app (iOS & Android)
├── .github/workflows/ → CI/CD pipelines (GitHub Actions)
└── docs/              → Documentation & PRD
```

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile App** | Flutter (Dart) |
| **Backend API** | Node.js + Express |
| **Database** | PostgreSQL 16 |
| **Real-time** | WebSockets (Socket.io) |
| **Maps** | Google Maps SDK |
| **Payments** | Paystack API |
| **AI Chatbot** | Google Gemini API |
| **Push Notifications** | Firebase Cloud Messaging |
| **CI/CD** | GitHub Actions |

## 🚀 Getting Started

### Prerequisites
- Node.js v18+ 
- Flutter 3.x+
- PostgreSQL 16
- Git

### Backend Setup
```bash
cd zippa-backend
cp .env.example .env          # Copy environment template
# Edit .env with your database credentials
npm install                    # Install dependencies
npm run db:setup               # Create database tables
npm run dev                    # Start development server
```

### Flutter App Setup
```bash
cd zippa-app
flutter pub get                # Install dependencies
flutter run                    # Run on connected device/emulator
```

## 🔄 CI/CD

Every push to `main` triggers:
- ✅ Backend: Lint → Test → Build
- ✅ Flutter: Analyze → Test → Build APK

## 📄 License

Copyright © 2026 Zippa Logistics. All rights reserved.
