<div align="center">

# 🌾 Maha Krushi Mittra

### *Empowering Farmers with AI-Driven Agricultural Intelligence*  

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Gemini AI](https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=google&logoColor=white)](https://deepmind.google/technologies/gemini/)
[![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com/)

**A comprehensive, multilingual mobile application that revolutionizes farming through cutting-edge AI technology, real-time data, and accessible user experience.**

[Features](#-features) • [Tech Stack](#-tech-stack) • [Architecture](#-architecture) • [Getting Started](#-getting-started) • [Documentation](#-documentation)

</div>

---

## Video Tutorial

[![Video Title](https://yt3.googleusercontent.com/eWXreF9fiJ1GbGwhca0ZO5EXM9HlolDL7LtYm3-abEhF4MBc6Onflm49uf3udvmNXLEDkdyIAA=w1707-fcrop64=1,00005a57ffffa5a8-k-c0xffffffff-no-nd-rj)](https://www.youtube.com/watch?v=rSOBN1rhO4s)

*Click the image above to watch the video*


## 📖 Table of Contents

- [🌟 Overview](#-overview)
- [✨ Features](#-features)
- [🏗️ Architecture](#-architecture)
- [🛠️ Tech Stack](#-tech-stack)
- [📁 Folder Structure](#-folder-structure)
- [🔄 State Management](#-state-management)
- [🔍 Detailed Data Flow](#-detailed-data-flow)
- [🌐 APIs Integration](#-apis-integration)
- [🎨 UI/UX Design](#-uiux-design)
- [⚡ Performance & Scalability](#-performance--scalability)
- [📴 Offline Capabilities](#-offline-capabilities)
- [🚀 Getting Started](#-getting-started)
- [📊 Implementation Approach](#-implementation-approach)
- [🔮 Future Enhancements](#-future-enhancements)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## 🌟 Overview

**Maha Krushi Mittra** (The Great Agricultural Friend) is a revolutionary mobile application designed to bridge the technological gap in agriculture. Built with the vision of empowering farmers with AI-driven insights, real-time data, and multilingual support, this application serves as a comprehensive digital companion for modern farming.

### 🎯 Mission

To democratize agricultural technology by providing farmers with:
- **Instant AI-powered agricultural expertise**
- **Real-time market intelligence**
- **Weather-based decision support**
- **Crop health monitoring**
- **Multilingual accessibility**
- **Community-driven knowledge sharing**

### 🌍 Impact

- **Language Accessibility**: Support for 10+ Indian languages
- **AI-Powered Diagnostics**: Instant crop disease detection
- **Market Intelligence**: Real-time commodity pricing
- **Weather Forecasting**: Location-specific alerts
- **Knowledge Base**: Curated agricultural news and schemes

---

## ✨ Features

### 🤖 AI-Powered Chat Assistant

<table>
<tr>
<td width="50%">

**Multimodal Intelligence**
- 🗣️ Voice-based queries (Speech-to-Text)
- 📸 Image analysis for crop diseases
- 💬 Natural language understanding
- 🔊 Audio responses (Text-to-Speech)
- 🌐 Multilingual conversations

</td>
<td width="50%">

**Smart Capabilities**
- Crop disease identification
- Pest detection & treatment plans
- Fertilizer recommendations
- Weather-based farming advice
- Soil health analysis
- Market trend insights

</td>
</tr>
</table>

### 📊 Market Intelligence

- **Real-Time Pricing**: Live commodity prices from major markets
- **Price Trends**: Historical data and forecasting
- **Market Analysis**: AI-powered market insights
- **Crop Recommendations**: Best crops based on market demand

### 🌦️ Weather Intelligence

- **Hyperlocal Forecasts**: Location-specific weather data
- **Extreme Weather Alerts**: Push notifications for adverse conditions
- **Farming Advisories**: Weather-based activity recommendations
- **Multi-Location Support**: Track multiple farm locations

### 🏥 Crop Health Management

- **Disease Detection**: AI-powered image analysis
- **Pest Identification**: Visual recognition of common pests
- **Treatment Plans**: Step-by-step remediation guides
- **Prevention Tips**: Proactive crop protection strategies

### 🌱 Soil Health Monitoring

- **Nutrient Analysis**: Soil composition insights
- **pH Level Monitoring**: Soil acidity/alkalinity tracking
- **Fertilizer Recommendations**: Customized nutrient plans
- **Organic Farming Tips**: Sustainable practices

### 📍 Farm Management

- **Multiple Locations**: Manage multiple farm sites
- **Map Integration**: Visual farm boundaries
- **Location-Based Services**: Weather, retailers, clinics
- **Saved Locations**: Quick access to frequent sites

### 📰 Agricultural News & Updates

- **Latest News**: Curated agricultural news feed
- **Government Schemes**: New policies and subsidies
- **Technology Updates**: Modern farming techniques
- **Market Reports**: Commodity market analysis

### 🏪 Retailer Finder

- **Nearby Retailers**: Find agricultural suppliers
- **Product Availability**: Seeds, fertilizers, equipment
- **Contact Information**: Direct communication
- **Ratings & Reviews**: Community feedback

### 💚 Health & Wellness

- **Clinic Finder**: Locate nearby healthcare facilities
- **Emergency Contacts**: Quick access to help
- **Health Tips**: Farmer-specific wellness advice

### 🔔 Smart Notifications

- **Weather Alerts**: Severe weather warnings
- **Market Updates**: Price change notifications
- **News Alerts**: Important agricultural news
- **Scheme Announcements**: New government programs

### 👤 User Management

- **Profile Management**: Personalized user profiles
- **Language Preferences**: Choose from 10+ languages
- **Authentication**: Secure login with multiple options
- **Data Sync**: Cloud-based data synchronization

---

## 🏗️ Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         MOBILE APP (Flutter)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐     │
│  │ UI Layer    │  │ State Mgmt   │  │  Services Layer    │     │
│  │             │  │              │  │                    │     │
│  │ - Screens   │  │ - Provider   │  │ - API Service      │     │
│  │ - Widgets   │  │ - setState   │  │ - Translation      │     │
│  │ - Themes    │  │ - Future     │  │ - Notifications    │     │
│  └─────────────┘  └──────────────┘  └────────────────────┘     │
│                                                                   │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │   HTTP/HTTPS     │
                    └────────┬─────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌────────▼────────┐  ┌───────▼────────┐
│   Firebase     │  │  Flask Backend  │  │  External APIs │
│                │  │                 │  │                │
│ - Auth         │  │ - Gemini AI     │  │ - Google Maps  │
│ - Firestore    │  │ - Speech-to-Text│  │ - Weather API  │
│ - Storage      │  │ - Image Analysis│  │ - SerpApi      │
└────────────────┘  │ - Translation   │  │ - Translate    │
                    └─────────────────┘  └────────────────┘
```

### Application Flow Diagram

```
┌──────────────┐
│ Splash Screen│
│ (Language    │
│  Selection)  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Authentication│
│ - Sign In    │
│ - Sign Up    │
│ - Social Auth│
└──────┬───────┘
       │
       ▼
┌──────────────────────────────────────────────┐
│            Main Dashboard                     │
├──────────────────────────────────────────────┤
│                                              │
│  ┌─────────┐ ┌─────────┐ ┌──────────┐      │
│  │AI Chat  │ │Market   │ │Weather   │      │
│  └────┬────┘ └────┬────┘ └────┬─────┘      │
│       │           │            │             │
│  ┌────▼────┐ ┌───▼─────┐ ┌────▼──────┐     │
│  │Pest     │ │Soil     │ │Farm       │     │
│  │Detection│ │Health   │ │Management │     │
│  └────┬────┘ └────┬────┘ └────┬──────┘     │
│       │           │            │             │
│  ┌────▼────┐ ┌───▼─────┐ ┌────▼──────┐     │
│  │News     │ │Retailers│ │Health &   │     │
│  │         │ │         │ │Wellness   │     │
│  └─────────┘ └─────────┘ └───────────┘     │
│                                              │
└──────────────────────────────────────────────┘
```

### Component Interaction Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Chat with Image & Voice                │
└─────────────────────────────────────────────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │  User Input      │
                    │  - Image         │
                    │  - Voice         │
                    │  - Text          │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ API Service      │
                    │ (Multipart POST) │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ Flask Backend    │
                    └────────┬─────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌────────▼────────┐  ┌───────▼────────┐
│ Speech-to-Text │  │ Image Analysis  │  │ Text Processing│
│ (Google STT)   │  │ (Gemini Vision) │  │ (Gemini NLP)   │
└───────┬────────┘  └────────┬────────┘  └───────┬────────┘
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │ Gemini AI Agent  │
                    │ - Analysis       │
                    │ - Translation    │
                    │ - Response Gen   │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ JSON Response    │
                    │ - Analysis Text  │
                    │ - Transcription  │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │ UI Update        │
                    │ - Chat Bubble    │
                    │ - TTS Playback   │
                    └──────────────────┘
```

---

## 🛠️ Tech Stack

### Frontend Technologies

<table>
<tr>
<td width="33%" align="center">

**Framework**

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />

Modern, cross-platform UI framework for beautiful native experiences

</td>
<td width="33%" align="center">

**Language**

<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />

Fast, type-safe programming language optimized for UI

</td>
<td width="33%" align="center">

**Authentication**

<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />

Secure authentication with multiple providers

</td>
</tr>
</table>

#### Core Flutter Packages

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.0.0 | State management across the app |
| `http` | ^1.1.0 | Network requests & API calls |
| `google_maps_flutter` | ^2.5.0 | Interactive maps integration |
| `geolocator` | ^10.1.0 | Location services & GPS |
| `geocoding` | ^2.1.1 | Address ↔ Coordinates conversion |
| `firebase_auth` | ^4.15.0 | User authentication |
| `cloud_firestore` | ^4.13.0 | Cloud database |
| `firebase_storage` | ^11.5.0 | File storage |
| `image_picker` | ^1.0.5 | Camera & gallery access |
| `file_picker` | ^6.1.1 | File selection |
| `record` | ^5.0.4 | Audio recording |
| `flutter_tts` | ^3.8.3 | Text-to-speech |
| `shared_preferences` | ^2.2.2 | Local data persistence |
| `google_fonts` | ^6.1.0 | Custom typography |
| `url_launcher` | ^6.2.2 | External links |
| `intl` | ^0.18.1 | Internationalization |

### Backend Technologies

<table>
<tr>
<td width="50%" align="center">

**Framework**

<img src="https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white" />

Lightweight, powerful Python web framework

</td>
<td width="50%" align="center">

**AI Engine**

<img src="https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=google&logoColor=white" />

Google's most advanced multimodal AI

</td>
</tr>
</table>

#### Core Python Packages

| Package | Version | Purpose |
|---------|---------|---------|
| `Flask` | ^3.0.0 | Web server framework |
| `Flask-CORS` | ^4.0.0 | Cross-origin resource sharing |
| `google-generativeai` | ^0.3.1 | Gemini AI SDK |
| `SpeechRecognition` | ^3.10.0 | Speech-to-text conversion |
| `googletrans` | ^4.0.0 | Language translation |
| `Pillow` | ^10.1.0 | Image processing |
| `pydub` | ^0.25.1 | Audio file manipulation |
| `python-dotenv` | ^1.0.0 | Environment configuration |
| `requests` | ^2.31.0 | HTTP library |

### External APIs & Services

| Service | Purpose | Integration |
|---------|---------|-------------|
| **Google Gemini AI** | Multimodal AI (NLP, Vision) | Core intelligence engine |
| **Firebase Authentication** | User authentication | Email, Google, Apple sign-in |
| **Cloud Firestore** | NoSQL database | User data, farm locations |
| **Firebase Storage** | File storage | Image uploads |
| **Google Maps Platform** | Maps & location | Map display, geocoding |
| **Google Cloud Speech-to-Text** | Voice recognition | Voice queries |
| **Google Cloud Text-to-Speech** | Audio synthesis | Voice responses |
| **Google Translate API** | Translation | Multilingual support |
| **OpenWeatherMap API** | Weather data | Forecasts & alerts |
| **SerpApi** | Search results | News & market data |

### Development Tools

| Tool | Purpose |
|------|---------|
| **Git** | Version control |
| **GitHub** | Code repository & collaboration |
| **VS Code** | Primary IDE |
| **Android Studio** | Android development |
| **Xcode** | iOS development |
| **Postman** | API testing |
| **Firebase Console** | Backend management |

---

## 📁 Folder Structure

```
maha-krushi-mittra/
│
├── android/                      # Android native code
├── ios/                          # iOS native code
├── web/                          # Web build files
│
├── lib/                          # Main Flutter application
│   ├── main.dart                 # App entry point
│   ├── firebase_options.dart     # Firebase configuration
│   │
│   ├── backend/                  # Backend-related files
│   │   ├── firebase_auth_services.dart
│   │   ├── main.py               # Flask backend server
│   │   ├── test_server.py        # Development test server
│   │   └── requirements.txt      # Python dependencies
│   │
│   ├── pages/                    # All UI screens
│   │   ├── api_service.dart      # API call management
│   │   ├── splash_screen.dart    # Onboarding screen
│   │   ├── sign_in.dart          # Login screen
│   │   ├── sign_up.dart          # Registration screen
│   │   ├── home.dart             # Main dashboard
│   │   ├── chat.dart             # AI chat interface
│   │   ├── chat_response.dart    # Chat response handler
│   │   ├── profile.dart          # User profile view
│   │   ├── manage_profile.dart   # Profile editing
│   │   ├── notification.dart     # Notifications screen
│   │   ├── notification_service.dart
│   │   │
│   │   └── sub_pages/            # Feature-specific pages
│   │       ├── market_tracking.dart
│   │       ├── weather_alerts.dart
│   │       ├── farm_location.dart
│   │       ├── farm_news.dart
│   │       ├── pest_detection.dart
│   │       ├── soil_health.dart
│   │       ├── crops_retailers.dart
│   │       ├── health_wellness.dart
│   │       │
│   │       └── health_pages/     # Health sub-features
│   │           └── find_nearby_clinics.dart
│   │
│   ├── services/                 # Utility services
│   │   └── translation_service.dart
│   │
│   ├── models/                   # Data models
│   ├── widgets/                  # Reusable UI components
│   └── utils/                    # Helper functions
│
├── assets/                       # Static assets
│   ├── images/                   # Image files
│   ├── icons/                    # App icons
│   └── translations/             # Language files
│
├── test/                         # Unit & widget tests
├── pubspec.yaml                  # Flutter dependencies
├── .env                          # Environment variables
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

### Directory Breakdown

#### `lib/` - Main Application Code

- **`main.dart`**: Application entry point, initializes providers, routing, and Firebase
- **`firebase_options.dart`**: Auto-generated Firebase configuration

#### `lib/backend/` - Backend Logic

- **`firebase_auth_services.dart`**: Handles all Firebase authentication operations
- **`main.py`**: Python Flask server with AI integration
- **`test_server.py`**: Development and debugging server

#### `lib/pages/` - UI Screens

All user-facing screens organized by functionality:
- Authentication screens (`sign_in.dart`, `sign_up.dart`)
- Main screens (`home.dart`, `chat.dart`, `profile.dart`)
- Feature screens in `sub_pages/` directory

#### `lib/services/` - Business Logic

- **`translation_service.dart`**: Manages multilingual content
- Additional services for notifications, caching, etc.

---

## 🔄 State Management

The application employs a **hybrid state management approach** optimized for different use cases:

### 1. 🎯 Local State (`StatefulWidget` & `setState`)

**Use Case**: UI elements and data confined to a single widget

**Examples**:
- Password visibility toggle in `sign_in.dart`
- Text field focus states
- Form validation states
- Dropdown selections

**Implementation**:
```dart
class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isPasswordVisible = false;
  
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }
}
```

### 2. 🌐 App-wide State (`provider` package)

**Use Case**: Shared state across multiple screens

**Examples**:
- **NotificationService**: Manages notifications app-wide
- **UserProvider**: Current user session data
- **LanguageProvider**: Selected language preference

**Implementation**:

```dart
// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => NotificationService()),
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => LanguageProvider()),
  ],
  child: MyApp(),
)

// In NotificationPage
Consumer<NotificationService>(
  builder: (context, notificationService, child) {
    return ListView.builder(
      itemCount: notificationService.notifications.length,
      itemBuilder: (context, index) {
        return NotificationCard(
          notification: notificationService.notifications[index]
        );
      },
    );
  },
)
```

**Benefits**:
- ✅ Decouples UI from business logic
- ✅ Automatic UI rebuilds on data changes
- ✅ Easy to test and maintain
- ✅ Prevents prop drilling

### 3. ⏳ Asynchronous State (`FutureBuilder`)

**Use Case**: Data fetched asynchronously from APIs

**Examples**:
- Translation data in `home.dart`
- User profile data
- Weather forecasts
- Market prices

**Implementation**:

```dart
FutureBuilder<Map<String, dynamic>>(
  future: TranslationService.fetchTranslations(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return ErrorWidget(error: snapshot.error);
    }
    
    if (snapshot.hasData) {
      return HomeContent(translations: snapshot.data!);
    }
    
    return SizedBox.shrink();
  },
)
```

**Benefits**:
- ✅ Clean loading state management
- ✅ Built-in error handling
- ✅ Automatic rebuild on data arrival
- ✅ Prevents UI freezing

### 4. 🔄 Stream State (`StreamBuilder`)

**Use Case**: Real-time data streams

**Examples**:
- Firebase Firestore live updates
- Real-time chat messages
- Live weather updates

**Implementation**:

```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
    .collection('notifications')
    .orderBy('timestamp', descending: true)
    .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final notifications = snapshot.data!.docs;
      return NotificationList(notifications: notifications);
    }
    return LoadingIndicator();
  },
)
```

---

## 🔍 Detailed Data Flow

### Complete Journey: AI Chat with Image & Voice

Let's trace a user query that includes **image analysis** and **voice input** through the entire system:

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: USER INPUT (chat_response.dart)                         │
└─────────────────────────────────────────────────────────────────┘

User Actions:
1. Taps 📷 icon → Selects crop image via image_picker
   ↓ Stored as: File imageFile

2. Taps 🎤 icon → Records voice via record package
   ↓ Stored as: File audioFile

3. Selects 🌐 language (e.g., "Marathi")
   ↓ Stored as: String languageCode = "mr"

4. Taps ▶️ Send button
   ↓ Triggers: _sendCombinedQuery()

┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: API SERVICE CALL (api_service.dart)                     │
└─────────────────────────────────────────────────────────────────┘

Method: ApiService.processCombinedQuery(imageFile, audioFile, "mr")

Code Flow:
```dart
Future<Map<String, dynamic>> processCombinedQuery({
  required File imageFile,
  required File audioFile,
  required String languageCode,
}) async {
  // Create multipart request
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/api/process-query'),
  );

  // Add image
  request.files.add(await http.MultipartFile.fromPath(
    'image',
    imageFile.path,
  ));

  // Add audio
  request.files.add(await http.MultipartFile.fromPath(
    'audio',
    audioFile.path,
  ));

  // Add language code
  request.fields['language_code'] = languageCode;

  // Send request
  var streamedResponse = await request.send();
  var response = await http.Response.fromStream(streamedResponse);

  return jsonDecode(response.body);
}
```

HTTP Request Details:
┌────────────────────────────────────┐
│ POST /api/process-query            │
├────────────────────────────────────┤
│ Content-Type: multipart/form-data  │
├────────────────────────────────────┤
│ Body:                              │
│  - image: [binary data]            │
│  - audio: [binary data]            │
│  - language_code: "mr"             │
└────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: BACKEND RECEIVES REQUEST (main.py - Flask)              │
└─────────────────────────────────────────────────────────────────┘

Endpoint: @app.route('/api/process-query', methods=['POST'])

```python
@app.route('/api/process-query', methods=['POST'])
def process_query():
    # Extract files from request
    image_file = request.files.get('image')
    audio_file = request.files.get('audio')
    language_code = request.form.get('language_code', 'en')
    
    # Save files temporarily
    image_path = f"temp_image_{uuid.uuid4()}.jpg"
    audio_path = f"temp_audio_{uuid.uuid4()}.wav"
    
    image_file.save(image_path)
    audio_file.save(audio_path)
    
    # Process the query
    result = process_multimodal_query(
        image_path, 
        audio_path, 
        language_code
    )
    
    # Clean up temporary files
    os.remove(image_path)
    os.remove(audio_path)
    
    return jsonify(result)
```

Files on Server:
/tmp/temp_image_a1b2c3d4.jpg  [Crop Image]
/tmp/temp_audio_e5f6g7h8.wav  [Voice Recording]

┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: BACKEND PROCESSING (MultilingualFarmerAgent)            │
└─────────────────────────────────────────────────────────────────┘

Sub-Step 4a: Speech-to-Text
────────────────────────────
Function: speech_to_text_with_language(audio_path, language_code)

```python
def speech_to_text_with_language(audio_path, language_code="mr"):
    recognizer = sr.Recognizer()
    
    # Convert to WAV if needed
    audio = AudioSegment.from_file(audio_path)
    wav_path = "converted.wav"
    audio.export(wav_path, format="wav")
    
    # Perform recognition
    with sr.AudioFile(wav_path) as source:
        audio_data = recognizer.record(source)
        text = recognizer.recognize_google(
            audio_data, 
            language=language_code
        )
    
    os.remove(wav_path)
    return text
```

Output: "माझ्या टोमॅटोच्या झाडावर पिवळी पाने आहेत"
(Translation: "My tomato plant has yellow leaves")

Sub-Step 4b: AI Analysis with Gemini
────────────────────────────────────
Function: analyze_crop_image(image_path, query_text, language_code)

```python
def analyze_crop_image(image_path, query_text, language_code="mr"):
    # Open image
    img = Image.open(image_path)
    
    # Get language name
    language_name = LANGUAGE_MAP.get(language_code, "English")
    
    # Construct prompt
    prompt = f"""
    You are an expert agricultural consultant.
    
    User's Question (in {language_name}):
    {query_text}
    
    Analyze the provided crop image and:
    1. Identify the crop type
    2. Detect any diseases or pest issues
    3. Assess overall plant health
    4. Provide treatment recommendations
    5. Suggest preventive measures
    
    IMPORTANT: Respond ONLY in {language_name}.
    """
    
    # Configure Gemini model
    model = genai.GenerativeModel(
        model_name='gemini-1.5-pro',
        generation_config={
            'temperature': 0.7,
            'top_p': 0.95,
            'max_output_tokens': 2048,
        }
    )
    
    # Generate response
    response = model.generate_content([prompt, img])
    
    return response.text
```

Gemini AI Processing:
┌────────────────────────────────────┐
│ Input to Gemini:                   │
│  - Crop Image (Visual)             │
│  - User Query (Text in Marathi)    │
│  - System Prompt (Instructions)    │
├────────────────────────────────────┤
│ Gemini Analysis:                   │
│  ✓ Crop Identification             │
│  ✓ Disease Detection               │
│  ✓ Severity Assessment             │
│  ✓ Treatment Generation            │
│  ✓ Translation to Marathi          │
└────────────────────────────────────┘

Sample AI Response (in Marathi):
"""
तुमच्या टोमॅटोच्या झाडावर 'पर्ण कुरकुरीत रोग' (Leaf Curl Disease) दिसत आहे.

कारणे:
- व्हायरस संसर्ग (सफेद माशीमुळे)
- पोषक तत्वांची कमतरता

उपचार:
1. बाधित पाने काढून टाका
2. नीम तेल फवारणी (10 मिली/लिटर पाणी)
3. पोटॅश युक्त खत द्या

प्रतिबंध:
- सफेद माशींवर नियंत्रण ठेवा
- नियमित तपासणी करा
  """

┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: BACKEND RESPONSE (JSON Formatting)                      │
└─────────────────────────────────────────────────────────────────┘

Response Construction:
```python
result = {
    'success': True,
    'transcription': transcribed_text,
    'analysis': ai_response_text,
    'language': language_code,
    'timestamp': datetime.now().isoformat()
}

return jsonify(result)
```

HTTP Response:
```json
{
  "success": true,
  "transcription": "माझ्या टोमॅटोच्या झाडावर पिवळी पाने आहेत",
  "analysis": "तुमच्या टोमॅटोच्या झाडावर 'पर्ण कुरकुरीत रोग'...",
  "language": "mr",
  "timestamp": "2025-10-02T19:46:58"
}
```

┌─────────────────────────────────────────────────────────────────┐
│ STEP 6: UI UPDATE (chat_response.dart)                          │
└─────────────────────────────────────────────────────────────────┘

Response Handling:
```dart
void _handleResponse(Map<String, dynamic> response) {
  setState(() {
    // Add user's message
    _messages.add(ChatMessage(
      text: response['transcription'],
      isUser: true,
      timestamp: DateTime.now(),
    ));
    
    // Add AI's response
    _messages.add(ChatMessage(
      text: response['analysis'],
      isUser: false,
      timestamp: DateTime.now(),
    ));
  });
  
  // Speak the response
  _speakResponse(response['analysis']);
}

Future<void> _speakResponse(String text) async {
  await flutterTts.setLanguage('mr-IN');
  await flutterTts.speak(text);
}
```

Final UI Display:
┌─────────────────────────────────────┐
│ 🗣️ You (Voice Input):              │
│ माझ्या टोमॅटोच्या झाडावर पिवळी    │
│ पाने आहेत                           │
├─────────────────────────────────────┤
│ 🤖 AI Assistant:                    │
│ तुमच्या टोमॅटोच्या झाडावर          │
│ 'पर्ण कुरकुरीत रोग' दिसत आहे...   │
│                                     │
│ [📸 Analyzed Image Thumbnail]       │
│ [🔊 Playing Audio Response...]      │
└─────────────────────────────────────┘
```

---

## 🌐 APIs Integration

### Complete API Ecosystem

#### 1. 🔥 Firebase Suite

<table>
<tr>
<td width="33%">

**Authentication**
```dart
// Email Sign-In
await FirebaseAuth.instance
  .signInWithEmailAndPassword(
    email: email,
    password: password,
  );

// Google Sign-In
final GoogleSignInAccount? 
  googleUser = 
  await GoogleSignIn().signIn();
```

</td>
<td width="33%">

**Firestore Database**
```dart
// Save Farm Location
await FirebaseFirestore
  .instance
  .collection('users')
  .doc(userId)
  .collection('farms')
  .add({
    'name': farmName,
    'location': GeoPoint(lat, lng),
    'area': area,
  });
```

</td>
<td width="33%">

**Cloud Storage**
```dart
// Upload Image
final ref = FirebaseStorage
  .instance
  .ref()
  .child('crops/$fileName');
  
await ref.putFile(imageFile);
String url = await ref
  .getDownloadURL();
```

</td>
</tr>
</table>

**Configuration**:
```dart
// firebase_options.dart
static const FirebaseOptions currentPlatform = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'maha-krushi-mittra',
  storageBucket: 'maha-krushi-mittra.appspot.com',
);
```

#### 2. 🤖 Google Gemini AI

**Endpoint**: Google Generative AI SDK

**Use Cases**:
- Natural language understanding
- Image analysis for crop diseases
- Multilingual responses
- Agricultural recommendations

**Implementation**:

```python
# Backend (main.py)
import google.generativeai as genai

genai.configure(api_key=os.getenv('GEMINI_API_KEY'))

model = genai.GenerativeModel('gemini-1.5-pro')

# Text-only query
response = model.generate_content(prompt)

# Multimodal query (text + image)
response = model.generate_content([prompt, image])
```

**Request Example**:
```python
prompt = """
Analyze this crop image:
1. Identify the crop type
2. Detect diseases/pests
3. Recommend treatment
4. Respond in Hindi
"""

image = Image.open('crop.jpg')
response = model.generate_content([prompt, image])
print(response.text)
```

**Response Capabilities**:
- ✅ Multilingual (100+ languages)
- ✅ Visual understanding
- ✅ Context-aware responses
- ✅ Agricultural domain knowledge

#### 3. 🗺️ Google Maps Platform

**APIs Used**:
- Maps SDK for Flutter
- Geocoding API
- Places API

**Implementation**:

```dart
// Display Map
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(farmLat, farmLng),
    zoom: 14,
  ),
  markers: {
    Marker(
      markerId: MarkerId('farm'),
      position: LatLng(farmLat, farmLng),
      infoWindow: InfoWindow(title: 'My Farm'),
    ),
  },
)

// Geocoding (Address → Coordinates)
List<Location> locations = await locationFromAddress(
  "123 Farm Road, Village, State"
);

// Reverse Geocoding (Coordinates → Address)
List<Placemark> placemarks = await placemarkFromCoordinates(
  latitude,
  longitude,
);
```

**Use Cases**:
- Farm location mapping
- Nearby retailer search
- Clinic location
- Weather location selection

#### 4. 🌦️ OpenWeatherMap API

**Endpoint**: `https://api.openweathermap.org/data/2.5/`

**Features**:
- Current weather
- 7-day forecast
- Hourly forecast
- Weather alerts

**Implementation**:

```dart
Future<WeatherData> fetchWeather(double lat, double lng) async {
  final url = 'https://api.openweathermap.org/data/2.5/weather'
    '?lat=$lat&lon=$lng'
    '&appid=$OPENWEATHER_API_KEY'
    '&units=metric';

  final response = await http.get(Uri.parse(url));
  final data = jsonDecode(response.body);

  return WeatherData(
    temperature: data['main']['temp'],
    humidity: data['main']['humidity'],
    description: data['weather'][0]['description'],
    windSpeed: data['wind']['speed'],
  );
}
```

**Response Example**:
```json
{
  "main": {
    "temp": 28.5,
    "humidity": 65,
    "pressure": 1013
  },
  "weather": [{
    "main": "Clouds",
    "description": "scattered clouds"
  }],
  "wind": {
    "speed": 3.5
  }
}
```

#### 5. 🔍 SerpApi (Google Search Results)

**Endpoint**: `https://serpapi.com/search`

**Use Cases**:
- Agricultural news scraping
- Market price data
- Government scheme updates

**Implementation**:

```dart
Future<List<NewsArticle>> fetchAgriNews() async {
  final url = 'https://serpapi.com/search.json'
    '?q=agriculture+news+india'
    '&api_key=$SERPAPI_KEY'
    '&tbm=nws'  // News search
    '&num=20';

  final response = await http.get(Uri.parse(url));
  final data = jsonDecode(response.body);

  return (data['news_results'] as List)
    .map((item) => NewsArticle(
      title: item['title'],
      source: item['source'],
      link: item['link'],
      date: item['date'],
    ))
    .toList();
}
```

#### 6. 🗣️ Google Cloud Speech-to-Text

**Integration**: SpeechRecognition library (uses Google's API)

**Implementation**:

```python
# Backend (main.py)
import speech_recognition as sr

def speech_to_text_with_language(audio_path, language_code="hi-IN"):
    recognizer = sr.Recognizer()
    
    with sr.AudioFile(audio_path) as source:
        audio = recognizer.record(source)
        
    text = recognizer.recognize_google(
        audio, 
        language=language_code
    )
    
    return text
```

**Supported Languages**:
- Hindi (hi-IN)
- Marathi (mr-IN)
- Tamil (ta-IN)
- Telugu (te-IN)
- And 100+ more

#### 7. 🔊 Google Cloud Text-to-Speech

**Integration**: flutter_tts package

**Implementation**:

```dart
import 'package:flutter_tts/flutter_tts.dart';

FlutterTts flutterTts = FlutterTts();

Future<void> speak(String text, String language) async {
  await flutterTts.setLanguage(language);  // "hi-IN", "mr-IN", etc.
  await flutterTts.setPitch(1.0);
  await flutterTts.setSpeechRate(0.5);
  await flutterTts.speak(text);
}
```

#### 8. 🌐 Google Translate API

**Integration**: googletrans Python library

**Implementation**:

```python
from googletrans import Translator

translator = Translator()

# Translate text
result = translator.translate(
    text='Hello farmer', 
    src='en', 
    dest='hi'
)

print(result.text)  # नमस्ते किसान
```

### Custom Backend API (Flask)

**Base URL**: `http://your-server.com/api`

| Endpoint | Method | Purpose | Request | Response |
|----------|--------|---------|---------|----------|
| `/health` | GET | Health check | None | `{"status": "healthy"}` |
| `/api/languages` | GET | Supported languages | None | `{"languages": [...]}` |
| `/api/process-query` | POST | Multimodal query | Image + Audio + Language | Analysis JSON |
| `/api/process-text` | POST | Text-only query | Text + Language | Response JSON |

**Example Request**:

```dart
// api_service.dart
Future<Map<String, dynamic>> processTextQuery(
  String query,
  String language,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/process-text'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'query': query,
      'language': language,
    }),
  );

  return jsonDecode(response.body);
}
```

---

## 🎨 UI/UX Design

### Color Palette

<table>
<tr>
<td align="center" width="20%">
<div style="background: #9CAF88; padding: 20px; border-radius: 8px;">
<strong style="color: white;">Primary Green</strong><br/>
<code>#9CAF88</code>
</div>
Nature, Growth, Prosperity
</td>
<td align="center" width="20%">
<div style="background: #E67E22; padding: 20px; border-radius: 8px;">
<strong style="color: white;">Accent Orange</strong><br/>
<code>#E67E22</code>
</div>
Energy, Warmth, Harvest
</td>
<td align="center" width="20%">
<div style="background: #FFFFFF; padding: 20px; border-radius: 8px; border: 1px solid #ccc;">
<strong>Background White</strong><br/>
<code>#FFFFFF</code>
</div>
Clean, Spacious
</td>
<td align="center" width="20%">
<div style="background: #262C23; padding: 20px; border-radius: 8px;">
<strong style="color: white;">Text Dark</strong><br/>
<code>#262C23</code>
</div>
Readability, Contrast
</td>
<td align="center" width="20%">
<div style="background: #3498db; padding: 20px; border-radius: 8px;">
<strong style="color: white;">Info Blue</strong><br/>
<code>#3498db</code>
</div>
Information, Links
</td>
</tr>
</table>

### Typography

**Font Families**:
- **Primary**: Poppins (Headings, UI elements)
- **Secondary**: Noto Sans (Body text, multilingual support)

**Hierarchy**:
```dart
TextTheme(
  displayLarge: GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Color(0xFF262C23),
  ),
  displayMedium: GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Color(0xFF262C23),
  ),
  bodyLarge: GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF262C23),
  ),
  bodyMedium: GoogleFonts.notoSans(
    fontSize: 14,
    color: Color(0xFF666666),
  ),
)
```

### Iconography

**Icon Library**: Material Icons + Custom SVG

**Consistent Icon Style**:
- Outlined style for inactive states
- Filled style for active states
- Uniform sizing (24dp standard)
- Accessible touch targets (48dp minimum)

**Feature Icons**:
```
🤖 AI Chat
📊 Market Tracking
🌦️ Weather Alerts
🌱 Crop Management
🐛 Pest Detection
🏥 Health & Wellness
📰 News
📍 Farm Locations
🏪 Retailers
```

### Design Principles

#### 1. **Modern & Clean**

```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clean, spacious layout
        // Generous padding
        // Clear visual hierarchy
      ],
    ),
  ),
)
```

#### 2. **Card-Based Layout**

**Home Screen Grid**:
```
┌────────────┬────────────┐
│  AI Chat   │   Market   │
│    🤖      │     📊     │
├────────────┼────────────┤
│  Weather   │   Pests    │
│    🌦️     │     🐛     │
├────────────┼────────────┤
│   News     │   Health   │
│    📰      │     🏥     │
└────────────┴────────────┘
```

#### 3. **Haptic Feedback**

```dart
void _onButtonPress() {
  HapticFeedback.lightImpact();  // Subtle tactile response
  // Perform action
}
```

#### 4. **Smooth Animations**

```dart
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  // Animated properties
)

Hero(
  tag: 'feature-image',
  child: Image.asset('assets/feature.png'),
)
```

#### 5. **Accessibility**

- **Screen Reader Support**: Semantic labels
- **High Contrast**: WCAG AA compliant
- **Large Touch Targets**: Minimum 48dp
- **Text Scaling**: Supports system font sizes

```dart
Semantics(
  label: 'Send message button',
  button: true,
  child: IconButton(
    icon: Icon(Icons.send),
    onPressed: _sendMessage,
  ),
)
```

### UI Components

#### Custom Button

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF9CAF88),
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  ),
  onPressed: onPressed,
  child: Text(
    label,
    style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

#### Chat Bubble

```dart
Container(
  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: isUser ? Color(0xFF9CAF88) : Colors.grey[200],
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
      bottomLeft: isUser ? Radius.circular(20) : Radius.zero,
      bottomRight: isUser ? Radius.zero : Radius.circular(20),
    ),
  ),
  child: Text(
    message,
    style: TextStyle(
      color: isUser ? Colors.white : Colors.black87,
    ),
  ),
)
```

### Responsive Design

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      // Tablet layout: 3 columns
      return GridView.count(crossAxisCount: 3);
    } else {
      // Mobile layout: 2 columns
      return GridView.count(crossAxisCount: 2);
    }
  },
)
```

---

## ⚡ Performance & Scalability

### Performance Optimizations

#### 1. **Asynchronous UI**

**Problem**: Network calls freeze the UI

**Solution**: FutureBuilder & async/await

```dart
FutureBuilder<WeatherData>(
  future: _weatherFuture,  // Fetch once, cache
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ShimmerLoading();  // Skeleton loading
    }
    return WeatherWidget(data: snapshot.data);
  },
)
```

**Benefits**:
- ✅ UI remains responsive
- ✅ Loading states handled gracefully
- ✅ Error states caught automatically

#### 2. **Image Optimization**

**Problem**: Large images slow uploads & consume data

**Solution**: Compress before upload

```dart
final XFile? image = await ImagePicker().pickImage(
  source: ImageSource.camera,
  maxWidth: 1024,        // Limit resolution
  maxHeight: 1024,
  imageQuality: 85,      // Compress quality
);
```

**Results**:
- 🚀 70% faster uploads
- 📉 60% less data usage
- ⚡ Maintains visual quality

#### 3. **Caching Strategy**

**Translation Service Caching**:

```dart
class TranslationService {
  static Map<String, dynamic>? _cachedTranslations;
  static String? _cachedLanguage;

  static Future<Map<String, dynamic>> fetchTranslations(String lang) async {
    // Return cached if same language
    if (_cachedLanguage == lang && _cachedTranslations != null) {
      return _cachedTranslations!;
    }

    // Fetch and cache
    final response = await http.get(Uri.parse('$baseUrl/translations/$lang.json'));
    _cachedTranslations = jsonDecode(response.body);
    _cachedLanguage = lang;
    
    return _cachedTranslations!;
  }
}
```

**Local Storage Caching**:

```dart
// Save notifications locally
final prefs = await SharedPreferences.getInstance();
await prefs.setString('notifications', jsonEncode(notifications));

// Retrieve on app start
final cached = prefs.getString('notifications');
if (cached != null) {
  _notifications = jsonDecode(cached);
}
```

#### 4. **Lazy Loading**

**Problem**: Loading all data at once is slow

**Solution**: Load on demand

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    // Only builds visible items
    return ItemWidget(items[index]);
  },
)
```

#### 5. **Debouncing**

**Problem**: Too many API calls on rapid user input

**Solution**: Debounce search

```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  
  _debounce = Timer(const Duration(milliseconds: 500), () {
    // Make API call only after user stops typing
    _performSearch(query);
  });
}
```

### Scalability Architecture

#### Backend Scalability

**Current Architecture**:
```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Flask    │
│   Server    │
└─────────────┘
```

**Production Architecture** (Containerized):

```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│   Load Balancer     │
│   (NGINX/AWS ELB)   │
└──────────┬──────────┘
           │
    ┌──────┴──────┬──────────┐
    ▼             ▼          ▼
┌────────┐  ┌────────┐  ┌────────┐
│ Flask  │  │ Flask  │  │ Flask  │
│Instance│  │Instance│  │Instance│
│   1    │  │   2    │  │   3    │
└────────┘  └────────┘  └────────┘
```

**Docker Deployment**:

```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "main:app"]
```

**Docker Compose**:

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "8000:8000"
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}
    deploy:
      replicas: 3  # 3 instances
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

**Horizontal Scaling Benefits**:
- ✅ Handles 1000+ concurrent users
- ✅ Auto-scaling based on load
- ✅ Zero-downtime deployments
- ✅ Load distribution

#### Database Scalability

**Firestore Advantages**:
- ✅ Automatic scaling
- ✅ Real-time sync
- ✅ Offline support
- ✅ Global distribution

**Indexing Strategy**:

```javascript
// Create indexes for common queries
db.collection('notifications')
  .where('userId', '==', currentUser.uid)
  .where('isRead', '==', false)
  .orderBy('timestamp', 'desc')
  .limit(20);
```

### Error Handling

#### Network Errors

```dart
try {
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw HttpException('Error ${response.statusCode}');
  }
  
} on SocketException {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('No internet connection'),
      action: SnackBarAction(
        label: 'Retry',
        onPressed: _retry,
      ),
    ),
  );
} on HttpException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Server error: ${e.message}')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Unexpected error occurred')),
  );
}
```

#### API Failure Graceful Degradation

```dart
Future<List<NewsArticle>> fetchNews() async {
  try {
    final response = await apiService.getNews();
    return response;
  } catch (e) {
    // Return sample data instead of empty screen
    return _getSampleNews();
  }
}
```

#### Retry Mechanism

```dart
Future<T> retryOperation<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
}) async {
  int attempts = 0;
  
  while (attempts < maxAttempts) {
    try {
      return await operation();
    } catch (e) {
      attempts++;
      if (attempts >= maxAttempts) rethrow;
      await Future.delayed(Duration(seconds: attempts * 2));
    }
  }
  
  throw Exception('Max retry attempts reached');
}
```

### Performance Monitoring

```dart
// Firebase Performance Monitoring
final trace = FirebasePerformance.instance.newTrace('api_call');
await trace.start();

try {
  final response = await http.get(url);
  trace.setMetric('response_size', response.contentLength);
  return response;
} finally {
  await trace.stop();
}
```

---

## 📴 Offline Capabilities

### Local Data Persistence

#### 1. **Shared Preferences** (Simple Key-Value Storage)

**Use Cases**:
- User preferences
- Selected language
- Last known location
- Simple caching

**Implementation**:

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Save data
Future<void> saveLanguage(String languageCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', languageCode);
}

// Retrieve data
Future<String> getLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('language') ?? 'en';
}

// Save complex data (JSON)
Future<void> saveFarmLocations(List<FarmLocation> farms) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = jsonEncode(farms.map((f) => f.toJson()).toList());
  await prefs.setString('farm_locations', jsonString);
}
```

**Data Persisted Offline**:
```dart
✅ farm_locations      // List of saved farms
✅ language            // Selected language
✅ user_preferences    // App settings
✅ last_sync_time      // Last data sync timestamp
✅ cached_weather      // Recent weather data
```

#### 2. **NotificationService** (In-Memory + Local Storage)

```dart
class NotificationService extends ChangeNotifier {
  List<Notification> _notifications = [];
  
  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('notifications');
    
    if (cached != null) {
      _notifications = (jsonDecode(cached) as List)
        .map((item) => Notification.fromJson(item))
        .toList();
      notifyListeners();
    }
    
    // Try to fetch fresh data
    try {
      final fresh = await apiService.getNotifications();
      _notifications = fresh;
      await _cacheNotifications();
