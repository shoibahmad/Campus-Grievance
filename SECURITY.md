# 🔐 Secure Setup Guide

## Environment Configuration

This project uses environment variables to keep API keys secure. Follow these steps:

### 1. Create Environment File
Copy `.env.example` to `.env`:
```bash
copy .env.example .env
```

### 2. Add Your API Key
Edit `.env` and replace `your_gemini_api_key_here` with your actual Gemini API key:
```
GEMINI_API_KEY=AIza...your-actual-key-here
```

### 3. Run with Environment Variables
```bash
flutter run --dart-define-from-file=.env
```

### 4. Build with Environment Variables
```bash
flutter build apk --dart-define-from-file=.env
```

## ⚠️ Security Notes

- **NEVER** commit `.env` files to version control
- The `.env` file is already in `.gitignore`
- Only commit `.env.example` with placeholder values
- Each developer needs their own `.env` file

## 🚀 Quick Start

1. Clone the repository
2. Copy `.env.example` to `.env`
3. Add your Gemini API key to `.env`
4. Run: `flutter run --dart-define-from-file=.env`