# 📱 App Icon Assets

## 🎨 **Icon File**

Place your app icon here: `app_icon.png`

### **Requirements:**
- **Size:** 1024x1024 pixels
- **Format:** PNG
- **Name:** `app_icon.png`
- **Background:** Transparent or solid color

---

## 📥 **How to Add Icon**

1. **Copy the generated icon:**
   - Find `campus_grievance_icon.png` in the artifacts
   - Rename it to `app_icon.png`
   - Place it in this folder (`assets/icon/`)

2. **Run icon generator:**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

3. **Done!** Your icon will be generated for all platforms

---

## ✅ **What Gets Generated**

After running the icon generator, you'll have:

### **Web:**
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/favicon.png`

### **Android:**
- `android/app/src/main/res/mipmap-*/ic_launcher.png` (all densities)
- Adaptive icons with purple background

### **iOS:**
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (all sizes)

---

## 🎨 **Icon Design**

The generated icon features:
- 🎓 **Graduation cap** - Campus/Education
- 📢 **Megaphone** - Grievance/Feedback
- 🟣 **Purple gradient** - Brand colors (#6C63FF → #4834DF)
- ✨ **Modern design** - Professional and clean

---

## 🚀 **Quick Setup**

```bash
# 1. Place app_icon.png in this folder
# 2. Install dependencies
flutter pub get

# 3. Generate icons
flutter pub run flutter_launcher_icons

# 4. Rebuild app
flutter clean
flutter run -d chrome
```

---

**Ready to add your icon! 🎉**
