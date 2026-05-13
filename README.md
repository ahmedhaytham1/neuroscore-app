# NeuroScore — Flutter + Firebase App

> تطبيق متابعة الأداء العصبي لمرضى التصلب المتعدد  
> Multiple Sclerosis Neurological Performance Tracker

---

## 📁 Project Structure

```
lib/
├── main.dart                          # Entry point
├── firebase_options.dart              # 🔥 YOUR Firebase config here
├── models/
│   └── user_model.dart                # AppUser, TestResult, TestType
├── services/
│   ├── auth_service.dart              # Firebase Auth + Firestore user ops
│   ├── test_service.dart              # Test results CRUD + Storage upload
│   ├── ai_service.dart                # TFLite model loader + inference
│   └── app_provider.dart             # Global state (ChangeNotifier)
├── utils/
│   ├── app_theme.dart                 # Colors, theme, Arabic strings
│   └── app_router.dart               # go_router navigation
├── widgets/
│   └── shared_widgets.dart           # Logo, StatCard, GradientButton…
└── screens/
    ├── auth/
    │   ├── login_screen.dart
    │   └── signup_screen.dart
    ├── doctor/
    │   ├── doctor_dashboard.dart
    │   └── patient_detail_screen.dart
    └── patient/
        ├── patient_dashboard.dart
        ├── progress_screen.dart
        └── tests/
            ├── video_test_base.dart   # Shared base for 4 video tests
            ├── tandem_walk_screen.dart
            ├── finger_nose_screen.dart
            ├── romberg_screen.dart
            ├── gait_analysis_screen.dart
            ├── drawing_test_screen.dart
            ├── memory_test_screen.dart
            ├── finger_tapping_screen.dart
            ├── mood_questionnaire_screen.dart
            └── fatigue_questionnaire_screen.dart
```

---

## 🚀 Setup Steps

### 1. Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project → name it `neuroscore`
3. Enable **Authentication** → Email/Password
4. Enable **Cloud Firestore** → Start in production mode
5. Enable **Firebase Storage**

### 2. Connect Firebase to Flutter

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# In project root:
flutterfire configure --project=YOUR_PROJECT_ID
```

This auto-generates `lib/firebase_options.dart` with real values.

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Add Arabic Font (Cairo)

Download Cairo font from [Google Fonts](https://fonts.google.com/specimen/Cairo) and place in:
```
assets/fonts/
  Cairo-Regular.ttf
  Cairo-Bold.ttf
  Cairo-SemiBold.ttf
  Cairo-Light.ttf
```

### 5. Create Asset Directories

```bash
mkdir -p assets/fonts assets/models assets/images assets/animations
touch assets/models/.gitkeep
```

### 6. Apply Firestore Security Rules

In Firebase Console → Firestore → Rules, paste the contents of `firestore.rules`.

### 7. Apply Storage Security Rules

In Firebase Console → Storage → Rules, paste the contents of `storage.rules`.

### 8. Run the App

```bash
flutter run
```

---

## 🤖 Connecting Your Local AI Models

The app is pre-wired to load **TFLite models** from `assets/models/`.  
The integration point is `lib/services/ai_service.dart`.

### Step 1 — Copy Your Model Files

```
assets/models/
  tandem_walk.tflite       ← for Tandem Walk test
  finger_nose.tflite       ← for Finger-to-Nose test
  romberg.tflite           ← for Romberg Balance test
  gait_analysis.tflite     ← for Gait Analysis test
```

### Step 2 — Match Input/Output Shape

Open `lib/services/ai_service.dart` and update `_runInference()`:

```dart
// Check what your model expects:
final inputShape = interpreter.getInputTensor(0).shape;
// e.g. [1, 224, 224, 3]  →  1 image, 224×224 pixels, RGB

final outputShape = interpreter.getOutputTensor(0).shape;
// e.g. [1, 1]  →  single score output
```

### Step 3 — Implement Frame Preprocessing

In `_extractKeyFrames()`, use one of these packages:

```yaml
# Option A — fast thumbnails
video_thumbnail: ^0.5.3

# Option B — full FFmpeg (heavier, more control)
ffmpeg_kit_flutter: ^6.0.3
```

Example with `video_thumbnail`:
```dart
import 'package:video_thumbnail/video_thumbnail.dart';

Future<List<Uint8List>> _extractKeyFrames(File videoFile, {int maxFrames = 16}) async {
  final List<Uint8List> frames = [];
  // Get video duration first, then sample evenly
  for (int i = 0; i < maxFrames; i++) {
    final bytes = await VideoThumbnail.thumbnailData(
      video: videoFile.path,
      imageFormat: ImageFormat.JPEG,
      timeMs: (i * 1000),   // every 1 second
      maxWidth: 224,
      quality: 85,
    );
    if (bytes != null) frames.add(bytes);
  }
  return frames;
}
```

### Step 4 — Map Output to Score

```dart
// If model outputs a probability 0–1:
final score = rawScore * 100.0;

// If model outputs class logits [good, bad]:
// Apply softmax then take "good" class × 100

// If model outputs a regression value in a custom range:
// Map to 0–100 accordingly
```

### Step 5 — Model-Specific Scoring

If each model outputs differently, customize per test in `_runInference()`:

```dart
switch (testType) {
  case TestType.tandemWalk:
    // e.g. pose landmark model → balance score
    return _scoreTandemFromPose(output);
  case TestType.gaitAnalysis:
    // e.g. regression model → gait quality
    return output[0][0] * 100;
  // ...
}
```

### MediaPipe Integration (Optional)

If your models use **MediaPipe pose landmarks** as input instead of raw frames:

```yaml
# pubspec.yaml
google_mlkit_pose_detection: ^0.10.0
```

```dart
// In ai_service.dart
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

final poseDetector = PoseDetector(options: PoseDetectorOptions());
final inputImage = InputImage.fromFilePath(videoFramePath);
final poses = await poseDetector.processImage(inputImage);
// Then feed pose landmarks into your TFLite model
```

---

## 🗄️ Firestore Data Structure

```
users/
  {uid}/
    name, email, userType, age, gender, createdAt
    [doctor]: specialization, hospital, experienceYears, phone
    [patient]: doctorId, doctorName

test_results/
  {resultId}/
    patientId, patientName, doctorId
    testType, score, completedAt
    videoUrl (optional), aiAnalysis (optional)
    metadata: { ... test-specific data ... }
```

---

## 📱 Test Screens Summary

| Test | Type | Input | AI |
|------|------|-------|-----|
| المشي المتتالي | Video | Camera/Gallery | ✅ TFLite |
| الأنف بالإصبع | Video | Camera/Gallery | ✅ TFLite |
| رومبيرغ | Video | Camera/Gallery | ✅ TFLite |
| الرسم | Interactive | Canvas drawing | ⚙️ Algorithm |
| الذاكرة | Interactive | Card game | ⚙️ Algorithm |
| النقر بالأصابع | Interactive | Touch count | ⚙️ Algorithm |
| استبيان المزاج | Questionnaire | 5 questions | ⚙️ Algorithm |
| استبيان الإرهاق | Questionnaire | 5 questions | ⚙️ Algorithm |
| تحليل المشي | Video | Camera/Gallery | ✅ TFLite |

---

## 🔒 Security Notes

- Passwords are handled entirely by Firebase Auth (never stored in Firestore)
- Firestore rules ensure doctors only see their own patients
- Storage rules limit video uploads to 100MB per file
- All network calls go through Firebase SDK (HTTPS only)

---

## 📦 Dependencies Overview

| Package | Purpose |
|---------|---------|
| `firebase_auth` | Authentication |
| `cloud_firestore` | Database |
| `firebase_storage` | Video storage |
| `provider` | State management |
| `go_router` | Navigation |
| `fl_chart` | Charts & graphs |
| `tflite_flutter` | On-device AI inference |
| `image_picker` | Camera + gallery |
| `video_player` | Video preview |
| `flutter_animate` | Animations |
| `permission_handler` | Runtime permissions |
| `intl` | Date formatting + Arabic |

---

## 🌐 Arabic RTL Support

The app is fully RTL. Key things already configured:
- `locale: Locale('ar')` in `MaterialApp`
- All text uses `fontFamily: 'Cairo'`
- `textAlign: TextAlign.right` on all Arabic text
- `Directionality` is handled by Flutter's RTL engine

---

*Built with Flutter 3.x + Firebase + TFLite*
