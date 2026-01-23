# Expenza - Field Expense Manager

A Flutter-based expense management application for tracking field expenses, trips, and generating reports. Features AI-powered bill scanning, PDF/Excel export, and secure local data storage.

## Features

- 📊 **Trip Management**: Create and manage business trips with date ranges and locations
- 💰 **Expense Tracking**: Track expenses with categories, sub-categories, and bill attachments
- 🤖 **AI-Powered Scanning**: Automatically extract expense details from receipts using Google Gemini 2.0 Flash
- 📄 **Export Capabilities**: Generate PDF and Excel reports for expense submissions
- 🔒 **Secure Storage**: Encrypted local database using SQLCipher
- 👤 **User Profiles**: Manage employee profiles with banking and contact information
- 📱 **Android Native**: Optimized for Android devices

## Tech Stack

- **Framework**: Flutter 3.10.7+
- **State Management**: Riverpod
- **Database**: SQLCipher (encrypted SQLite)
- **AI Integration**: Google Gemini 2.0 Flash
- **Export**: PDF and Excel generation

## Prerequisites

- Flutter SDK 3.10.7 or higher
- Dart SDK 3.10.7 or higher
- Android Studio / Xcode (for mobile development)
- Google Gemini API key (for bill scanning feature)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Expenses
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Gemini API Key

1. Get a Google Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Open the app and navigate to Profile → Manage Gemini Keys
3. Add your API key with a label

### 4. Run the App

```bash
# For development
flutter run

# For Android release build
flutter build apk --release

# For iOS release build
flutter build ios --release
```

## Building for Production

### Android (APK/AAB)

1. **Create a keystore** (if you don't have one):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Create `android/key.properties`**:
   ```properties
   storePassword=<your-keystore-password>
   keyPassword=<your-key-password>
   keyAlias=upload
   storeFile=<path-to-keystore>/upload-keystore.jks
   ```

3. **Update `android/app/build.gradle.kts`** to use the signing config (see `DEPLOYMENT_REVIEW.md` for details)

4. **Build release APK**:
   ```bash
   flutter build apk --release
   ```

5. **Build App Bundle** (for Play Store):
   ```bash
   flutter build appbundle --release
   ```

### iOS

**Note:** iOS deployment is not planned. The iOS folder exists for Flutter compatibility but is not configured for production.

## Project Structure

```
lib/
├── core/              # Core utilities, constants, theme
├── data/             # Data layer (repositories, database)
├── models/           # Data models
├── providers/        # Riverpod state providers
├── screens/          # UI screens
├── services/         # Business logic services
└── widgets/          # Reusable widgets
```

## Security Notes

- **Database Encryption**: Uses SQLCipher with cryptographically secure random passwords
- **API Keys**: Stored securely using `flutter_secure_storage` on Android
- **Platform**: Android-only deployment (web platform code exists but is not deployed)

## Known Limitations

- Android-only deployment (no iOS or web deployment planned)
- No pagination for expense lists (may be slow with 1000+ expenses)
- No cloud sync (data stored locally only)
- Minimal test coverage (work in progress)

## Development

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Building for Different Platforms

```bash
# Android
flutter build apk

# iOS (not deployed)
# flutter build ios

# Web (not deployed)
# flutter build web
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[Add your license here]

## Support

For issues and feature requests, please use the [GitHub Issues](link-to-issues) page.

## Acknowledgments

- Google Gemini API for AI-powered bill scanning
- Flutter team for the amazing framework
- All contributors and testers

---

**Version**: 1.0.0+1  
**Last Updated**: January 2026
