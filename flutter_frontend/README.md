# Crypto Insight Flutter Frontend

A modern Flutter frontend for the Crypto Insight Spring Boot backend application. This app provides a beautiful Material Design 3 interface for browsing cryptocurrency market data, managing favorites, viewing detailed charts, and accessing AI-powered analysis.

## Features

### 🏠 Market Overview
- Real-time cryptocurrency market data
- Price tracking with 24h change indicators
- Market cap, volume, and rank information
- Pull-to-refresh functionality
- Responsive grid/list layout

### 🔍 Search
- Real-time search across cryptocurrencies
- Smart search suggestions
- Error handling and loading states
- Search history (coming soon)

### ❤️ Favorites
- Add/remove cryptocurrencies from favorites
- Persistent favorites storage
- Quick access to favorite coins
- Empty state handling

### 📊 Detailed Views
- Comprehensive cryptocurrency details
- Interactive price charts (powered by fl_chart)
- Historical data visualization
- AI analysis integration
- Multiple tabs for organized information

### 🎨 Modern UI/UX
- Material Design 3 theming
- Light and dark theme support
- Smooth animations and transitions
- Loading skeletons (shimmer effects)
- Responsive design for all screen sizes
- Beautiful cards and typography

## Architecture

### State Management
- **Provider pattern** for reactive state management
- Separate providers for crypto data and favorites
- Clean separation of concerns

### API Integration
- RESTful API client for Spring Boot backend
- Comprehensive error handling
- Type-safe data models
- Response caching (planned)

### Data Models
- `Cryptocurrency` - Core crypto data model
- `ApiResponse<T>` - Generic API response wrapper
- `ChartDataPoint` - Price chart data
- `AnalysisResponse` - AI analysis data

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── cryptocurrency.dart
│   ├── api_response.dart
│   ├── chart_data_point.dart
│   └── analysis_response.dart
├── providers/                # State management
│   ├── crypto_provider.dart
│   └── favorites_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── search_screen.dart
│   ├── crypto_detail_screen.dart
│   └── favorites_screen.dart
├── services/                 # API services
│   └── crypto_api_service.dart
├── theme/                    # App theming
│   └── app_theme.dart
└── widgets/                  # Reusable widgets
    ├── crypto_list_item.dart
    ├── loading_shimmer.dart
    └── search_bar_widget.dart
```

## Dependencies

### Core
- `flutter` - Flutter SDK
- `provider` - State management
- `http` - HTTP client for API calls

### UI/UX
- `fl_chart` - Beautiful charts and graphs
- `cached_network_image` - Image caching
- `shimmer` - Loading animations
- `google_fonts` - Typography
- `font_awesome_flutter` - Icons
- `animations` - Smooth transitions
- `flutter_staggered_animations` - List animations

### Storage & Utils
- `shared_preferences` - Local storage for favorites
- `intl` - Internationalization
- `lottie` - Animations (planned)

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Spring Boot backend running on localhost:8082

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd crypto-main-main/flutter_frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Start the Spring Boot backend**
   - Ensure the backend is running on `http://localhost:8082`
   - API endpoints should be accessible

4. **Run the Flutter app**
   ```bash
   # For development
   flutter run
   
   # For web
   flutter run -d chrome
   
   # For specific device
   flutter devices
   flutter run -d <device-id>
   ```

### Configuration

The app is configured to connect to the backend at `http://localhost:8082`. To change this:

1. Edit `lib/services/crypto_api_service.dart`
2. Update the `baseUrl` constant
3. Restart the app

## Backend Integration

The app integrates with the following Spring Boot endpoints:

- `GET /api/crypto/market?page={page}&size={size}` - Market data
- `GET /api/crypto/search?query={query}&limit={limit}` - Search
- `GET /api/crypto/{id}` - Cryptocurrency details
- `GET /api/crypto/{id}/chart?days={days}` - Price charts
- `GET /api/crypto/{id}/analysis` - AI analysis

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Analyze code
flutter analyze
```

## Building

```bash
# Android APK
flutter build apk

# iOS (requires macOS with Xcode)
flutter build ios

# Web
flutter build web
```

## Known Issues

1. **Gradle Configuration**: The project may need Android configuration updates for proper APK building
2. **iOS Setup**: iOS-specific configuration may be required for iOS builds

## Future Enhancements

- [ ] Portfolio tracking
- [ ] Price alerts and notifications
- [ ] Offline data caching
- [ ] Dark/light theme toggle
- [ ] Multi-language support
- [ ] Advanced charting features
- [ ] Social features (sharing, comments)
- [ ] Widget support for home screen
- [ ] Wear OS support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and analysis
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
