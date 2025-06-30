# 🚀 Quick Start Guide

## Running the Flutter App

### Method 1: PowerShell Script (Recommended)
```powershell
.\run_app.ps1
```

### Method 2: Manual Commands
```bash
# Make sure you're in the flutter_frontend directory
cd "D:\programs\spring -boot\crypto-main-main\flutter_frontend"

# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome
```

### Method 3: Windows Desktop
```bash
flutter run -d windows
```

## ⚠️ Important Prerequisites

1. **Spring Boot Backend**: Make sure your Spring Boot backend is running on `localhost:8082`
2. **Flutter Installation**: Ensure Flutter is properly installed and in your PATH
3. **Chrome Browser**: For web version, Chrome should be available

## 🔧 Troubleshooting

### "No pubspec.yaml file found"
- Make sure you're in the correct directory: `flutter_frontend`
- Try: `cd "D:\programs\spring -boot\crypto-main-main\flutter_frontend"`

### "Flutter not found"
- Install Flutter: https://flutter.dev/docs/get-started/install
- Add Flutter to your system PATH

### App takes long to load
- First run always takes longer (compilation)
- Subsequent runs will be faster
- Try running `flutter clean` then `flutter pub get` if issues persist

### Backend Connection Issues
- Ensure Spring Boot is running on port 8082
- Check if you can access `http://localhost:8082/api/crypto/market` in browser
- Verify CORS is configured in Spring Boot for web requests

## 📱 Supported Platforms

- ✅ **Chrome** (Web) - Primary development target
- ✅ **Edge** (Web) - Alternative web browser
- ✅ **Windows** (Desktop) - Native Windows app
- ⚠️ **Android** - Requires Android Studio setup
- ⚠️ **iOS** - Requires macOS with Xcode

## 🔍 Development Commands

```bash
# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Check available devices
flutter devices

# Check Flutter installation
flutter doctor

# Hot reload (during development)
# Press 'r' in terminal while app is running

# Hot restart (during development)
# Press 'R' in terminal while app is running
```

## 🏗️ Build Commands

```bash
# Web build
flutter build web

# Windows build  
flutter build windows

# Debug APK (Android)
flutter build apk --debug
```

## 📊 Features Available

When the app launches, you'll have access to:

- **Market Tab**: Real-time cryptocurrency market data
- **Favorites Tab**: Your saved cryptocurrencies  
- **Analysis Tab**: AI-powered market analysis
- **Search**: Find specific cryptocurrencies
- **Detail Views**: Comprehensive crypto information with charts

Enjoy exploring the crypto market! 🚀📈
