# Product Requirements Document (PRD)

## Product Name
Smart Class Check-in & Learning Reflection App

## Date
March 13, 2026

## 1) Problem Statement
University instructors need reliable attendance records, while students need a fast, trustworthy way to confirm classroom presence. Traditional attendance methods (manual roll call, paper sign-in, or unverified app taps) are slow and easy to falsify. This product solves the issue by combining GPS-based location checks with in-class QR verification, then extends value by collecting pre-class and post-class learning reflections.

## 2) Target User
**Primary User:** University Students

### User Profile
- Attends multiple weekly classes in different buildings.
- Uses a smartphone for academic and campus workflows.
- Needs a low-friction, secure check-in process.

## 3) Product Goals
- Provide verified class check-in using both GPS location and QR scanning.
- Reduce fake or proxy attendance attempts.
- Capture lightweight student reflections before and after class.
- Give students and instructors structured engagement data over time.

## 4) Feature List
1. **Location-based check-in**
   - App captures student GPS coordinates at check-in time.
   - Check-in is accepted only when within allowed class location radius.

2. **QR scanning**
   - Student scans instructor-generated QR code during class.
   - QR token validates class session and prevents outdated code reuse.

3. **Pre-class reflection**
   - Student submits mood score (1-5) and expected topics/focus.
   - Reflection is attached to the same attendance record.

4. **Post-class feedback**
   - Student submits what they learned and any confusion points.
   - Feedback supports self-reflection and instructional improvement.

## 5) User Flow
**Splash -> Home -> Check-in Form -> Success -> Post-class Form**

### Flow Details
1. **Splash**
   - App initializes services and confirms authentication state.
2. **Home**
   - Student sees today’s classes and check-in status.
3. **Check-in Form**
   - Student scans QR, app reads GPS, student adds pre-class reflection.
4. **Success**
   - App confirms verified attendance and stores timestamped record.
5. **Post-class Form**
   - Student adds post-class reflection and submits feedback.

## 6) Data Fields
| Field | Type | Description |
|---|---|---|
| Latitude | Double | GPS latitude captured at check-in |
| Longitude | Double | GPS longitude captured at check-in |
| Timestamp | DateTime | Server/client time when check-in is submitted |
| Mood (1-5) | Integer | Student self-reported mood before class |
| Reflection Text | String | Free-text pre/post class reflection |

## 7) Tech Stack
- **Frontend:** Flutter (Android/iOS)
- **Authentication:** Firebase Auth
- **Database:** Cloud Firestore
- **Location:** geolocator package
- **QR Scanning:** mobile_scanner package

## 8) Success Criteria (MVP)
- Student can complete verified check-in in under 30 seconds.
- Attendance records include valid location + QR evidence.
- At least one pre-class and one post-class reflection can be submitted per session.
- Data is reliably saved and retrievable from Firestore for reporting.