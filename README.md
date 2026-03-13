# Smart Class Check-in & Learning Reflection App

This repository contains a university **Mobile Application Development** midterm project built with Flutter.

## 1) Project Description

The **Smart Class Check-in & Learning Reflection App** helps students confirm class attendance and reflect on learning outcomes.

Before class, students complete check-in using:
- GPS location capture
- QR code scanning
- pre-class reflection fields

After class, students submit a short learning reflection and feedback. Data is stored in Firebase Firestore and can be viewed in-app.

## 2) Features

- **Class Check-in**
- **GPS location capture**
- **QR code scanning**
- **Learning reflection form**
- **Firebase Firestore data storage**
- **Firebase Hosting deployment**

## 3) Tech Stack

- **Flutter**
- **Dart**
- **Firebase Firestore**
- **Firebase Hosting**
- **mobile_scanner** (QR scanning)
- **geolocator** (GPS)

## 4) Setup Instructions

Clone and install dependencies:

```bash
git clone <repository_url>
cd project_folder
flutter pub get
```

## 5) How to Run the App

Run on your default connected device/emulator:

```bash
flutter run
```

Run the web version in Chrome:

```bash
flutter run -d chrome
```

## 6) Firebase Configuration Notes

This project uses Firebase for:
- **Firestore database** (storing check-in and reflection data)
- **Firebase Hosting** (web deployment)

To run this project in your own environment, you must create your own Firebase project and configure it for Flutter:

1. Create a Firebase project in the Firebase Console.
2. Add your platform apps (Android/Web/iOS as needed).
3. Add Firebase configuration files/values:
	- Android: `google-services.json`
	- Web/iOS: Firebase options generated via FlutterFire CLI (or equivalent config)
4. Update Firestore rules and project settings for your environment.

## 7) Deployment

The Flutter web build is deployed using **Firebase Hosting**.

- **Deployment URL:** `<your_firebase_hosting_url>`

---

## Academic Note

This project was developed as an individual midterm prototype. AI tools may be used to support scaffolding, documentation, and implementation speed, while core understanding and final integration decisions remain the student's responsibility.
