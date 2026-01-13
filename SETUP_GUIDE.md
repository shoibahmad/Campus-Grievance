# 🚀 Quick Setup Guide

Follow these steps to get your Campus Grievance System up and running!

## Step 1: Install Dependencies ✅

```bash
flutter pub get
```

## Step 2: Configure Firebase 🔥

### 2.1 Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 2.2 Configure Firebase

```bash
flutterfire configure
```

This command will:
- Prompt you to select or create a Firebase project
- Register your Flutter app with Firebase
- Generate `firebase_options.dart` automatically

**Select these Firebase services when prompted:**
- ✅ Firestore
- ✅ Authentication (optional, for future use)

### 2.3 Set up Firestore Database

1. Go to https://console.firebase.google.com/
2. Select your project
3. Click on "Firestore Database" in the left menu
4. Click "Create Database"
5. Choose "Start in test mode" (for development)
6. Select a location close to you
7. Click "Enable"

**Your Firestore is now ready!** The app will automatically create the `grievances` collection when you submit your first complaint.

## Step 3: Get Gemini API Key 🤖

### 3.1 Get the API Key

1. Go to https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Select "Create API key in new project" or choose an existing project
4. Copy the generated API key

### 3.2 Add API Key to App

1. Open `lib/config/app_config.dart`
2. Find this line:
   ```dart
   static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```
3. Replace with your actual key:
   ```dart
   static const String geminiApiKey = 'AIzaSyC...your-actual-key-here';
   ```

## Step 4: Run the App 🎉

```bash
flutter run
```

**That's it!** Your app should now launch with:
- Beautiful animated splash screen
- Working Firebase connection
- AI-powered complaint analysis

## 🧪 Testing the AI Feature

1. Tap the "New Complaint" button
2. Enter a test complaint:
   - **Title**: "Broken Light in Classroom"
   - **Description**: "The light in Room 301 is sparking and not working properly. This is urgent and dangerous."
   - **Location**: "Academic Block, Room 301"
3. Tap "Analyze with AI"
4. Watch the AI categorize it as "Electrical" with high severity!

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web (with some limitations)
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🔧 Troubleshooting

### Issue: "Firebase not initialized"

**Solution:**
```bash
flutterfire configure
```

### Issue: "Gemini API error"

**Check:**
- ✅ API key is correctly pasted in `app_config.dart`
- ✅ No extra spaces or quotes
- ✅ Internet connection is working

### Issue: "Build failed"

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "Firestore permission denied"

**Solution:**
1. Go to Firebase Console
2. Navigate to Firestore Database → Rules
3. Make sure rules allow read/write (in test mode):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```

## 🎨 Customization

### Change App Colors

Edit `lib/theme/app_theme.dart`:
```dart
static const Color primaryColor = Color(0xFF6366F1); // Change this!
static const Color secondaryColor = Color(0xFF8B5CF6); // And this!
```

### Add More Categories

Edit `lib/config/app_config.dart`:
```dart
static const List<String> categories = [
  'Plumbing',
  'Electrical',
  'Your New Category', // Add here!
];
```

### Adjust Severity Keywords

Edit `lib/config/app_config.dart`:
```dart
static const Map<String, int> severityKeywords = {
  'your_keyword': 10, // Add custom keywords!
};
```

## 📊 Next Steps

### For Production Use:

1. **Add Authentication**
   - Implement Firebase Auth
   - Add login/signup screens
   - Use real user IDs instead of hardcoded values

2. **Secure Firestore**
   - Update security rules
   - Implement role-based access control

3. **Add Admin Panel**
   - Create admin dashboard
   - Add complaint management features

4. **Enable Notifications**
   - Set up Firebase Cloud Messaging
   - Send push notifications on status updates

5. **Add Image Upload**
   - Integrate Firebase Storage
   - Allow users to attach photos

## 🎓 Learning Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

## ✅ Checklist

Before running the app, make sure:

- [ ] Flutter SDK is installed
- [ ] Dependencies are installed (`flutter pub get`)
- [ ] Firebase is configured (`flutterfire configure`)
- [ ] Firestore database is created
- [ ] Gemini API key is added to `app_config.dart`
- [ ] Internet connection is available

## 🎉 You're All Set!

Your Campus Grievance System is ready to use. Enjoy the AI-powered complaint management! 🚀

---

**Need help?** Check the main README.md for detailed documentation.
