import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sub_pages/health_wellness.dart';
import 'package:kisan_krushi/pages/notification.dart';
import 'sub_pages/crops_retailers.dart';
import 'chat.dart';
import 'profile.dart';
import 'sign_in.dart';
import 'sub_pages/market_tracking.dart';
import 'sub_pages/farm_location.dart';
import 'sub_pages/weather_alerts.dart';
import 'sub_pages/farm_news.dart';
import 'sub_pages/pest_detection.dart';
import 'sub_pages/soil_health.dart';
import '../services/translation_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Future<Map<String, dynamic>>? _translationsFuture;

  // Get the selected language from the global variable and map to lowercase
  String get _selectedLanguage {
    final languageMap = {
      'English': 'english',
      'हिन्दी': 'hindi',
      'मराठी': 'marathi',
      'ਪੰਜਾਬੀ': 'punjabi',
      'ಕನ್ನಡ': 'kannada',
      'தமிழ்': 'tamil',
      'తెలుగు': 'telugu',
      'മലയാളം': 'malayalam',
      'ગુજરાતી': 'gujarati',
      'বাংলা': 'bengali',
      'ଓଡ଼ିଆ': 'odia',
      'اردو': 'urdu',
    };
    return languageMap[selectedLanguageGlobal] ?? 'english';
  }

  // Helper method to get nested translation text
  String _getNestedText(Map<String, dynamic> translations, String section, List<String> keys, String language) {
    try {
      dynamic current = translations[section];
      for (String key in keys) {
        current = current[key];
      }
      return current[language] ?? current['english'] ?? keys.last;
    } catch (e) {
      print('Translation error for $section.${keys.join('.')}: $e');
      return keys.last; // Return the last key as fallback
    }
  }

  @override
  void initState() {
    super.initState();
    _translationsFuture = TranslationService.fetchTranslations();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _onItemTapped(int index) {
    _triggerHaptic();
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on the selected tab
    switch (index) {
      case 1: // Chat
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
        break;
      case 2: // Alerts
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationPage()),
        );
        break;
      case 3: // Profile
      // Handle profile navigation
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  void _navigateToFeaturePage(String feature) {
    _triggerHaptic();

    Widget page;
    switch (feature) {
      case 'Market Tracking':
        page = const MarketTrackingPage();
        break;
      case 'Farm Location':
        page = const FarmLocationPage();
        break;
      case 'Weather Alerts':
        page = const WeatherAlertsPage();
        break;
      case 'Farm News':
        page = const FarmNewsPage();
        break;
      case 'Pest Detection':
        page = const PestDetectionPage();
        break;
      case 'Soil Health':
        page = const SoilHealthPage();
        break;
      case 'Crops Retailers':
        page = const CropsRetailersPage();
        break;
      case 'Health & Wellness':
        page = const HealthWellnessPage();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _translationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error loading translations: ${snapshot.error}",
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text("No translation data available"));
            }

            final translations = snapshot.data!;

            // Add debug prints
            print("Translations loaded: ${translations.keys}");
            print("Selected language: $_selectedLanguage");
            print("Home data: ${translations['home']}");

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () {
                          _triggerHaptic();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SignInPage()),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      // Logo
                      Container(
                        width: 60,
                        height: 70,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/logo1.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      TranslationService.getText(translations, "home", "lets_explore", _selectedLanguage),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Feature Cards Grid with Fade Effect
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent, // Top
                            Colors.black,
                            Colors.black,
                            Colors.transparent, // Bottom
                          ],
                          // This controls the length of the fades
                          stops: [0.0, 0.1, 0.9, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                        children: [
                          // Market Tracking Card
                          _buildFeatureCard(
                            icon: Icons.trending_up,
                            title: _getNestedText(translations, "home", ["market_tracking", "title"], _selectedLanguage),
                            description: _getNestedText(translations, "home", ["market_tracking", "description"], _selectedLanguage),
                            color: const Color(0xFFE67E22),
                            featureKey: 'Market Tracking',
                          ),
                          // Farm Location Card
                          _buildFeatureCard(
                            icon: Icons.map,
                            title: _getNestedText(translations, "home", ["farm_location", "title"], _selectedLanguage),
                            description: _getNestedText(translations, "home", ["farm_location", "description"], _selectedLanguage),
                            color: const Color(0xFF9CAF88),
                            featureKey: 'Farm Location',
                          ),
                          // Weather Alerts Card
                          _buildFeatureCard(
                            icon: Icons.wb_sunny,
                            title: _getNestedText(translations, "home", ["weather_alerts", "title"], _selectedLanguage),
                            description: _getNestedText(translations, "home", ["weather_alerts", "description"], _selectedLanguage),
                            color: const Color(0xFF9CAF88),
                            featureKey: 'Weather Alerts',
                          ),
                          // Farm News Card
                          _buildFeatureCard(
                            icon: Icons.article,
                            title: _getNestedText(translations, "home", ["farm_news", "title"], _selectedLanguage),
                            description: _getNestedText(translations, "home", ["farm_news", "description"], _selectedLanguage),
                            color: const Color(0xFFE67E22),
                            featureKey: 'Farm News',
                          ),
                          // Pest Detection Card
                          _buildFeatureCard(
                            icon: Icons.camera_alt,
                            title: _getNestedText(translations, "home", ["pest_detection", "title"], _selectedLanguage),
                            description: _getNestedText(translations, "home", ["pest_detection", "description"], _selectedLanguage),
                            color: const Color(0xFFE67E22),
                            featureKey: 'Pest Detection',
                          ),
                          // Soil Health Card
                          _buildFeatureCard(
                            icon: Icons.eco,
                            title: _getNestedText(translations, "home", ["soil_health", "title"], _selectedLanguage),
                            description: _getNestedText(translations, "home", ["soil_health", "description"], _selectedLanguage),
                            color: const Color(0xFF9CAF88),
                            featureKey: 'Soil Health',
                          ),
                          // Crops Retailers Card
                          _buildFeatureCard(
                            icon: Icons.eco,
                            title: _getNestedText(translations, "home", ["crops_retailers", "title"], _selectedLanguage),
                            description: _getNestedText(translations, "home", ["crops_retailers", "description"], _selectedLanguage),
                            color: const Color(0xFF9CAF88),
                            featureKey: 'Crops Retailers',
                          ),

                          _buildFeatureCard(
                            icon: Icons.eco,
                            title: _getNestedText(translations, "home", ["health_and_wellness", "title"], _selectedLanguage),
                            description: _getNestedText(translations, "home", ["health_and_wellness", "description"], _selectedLanguage),
                            color: const Color(0xFF9CAF88),
                            featureKey: 'Health & Wellness',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 0),
                ],
              ),
            );
          },
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
        future: _translationsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(); // Return empty container while loading
          }

          final translations = snapshot.data!;

          return Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  icon: Icons.explore,
                  label: _getNestedText(translations, "home", ["navigation", "explore"], _selectedLanguage),
                  index: 0,
                ),
                _buildBottomNavItem(
                  icon: Icons.chat_bubble_outline,
                  label: _getNestedText(translations, "home", ["navigation", "chat"], _selectedLanguage),
                  index: 1,
                ),
                _buildBottomNavItem(
                  icon: Icons.notifications_none,
                  label: _getNestedText(translations, "home", ["navigation", "alerts"], _selectedLanguage),
                  index: 2,
                ),
                _buildBottomNavItem(
                  icon: Icons.person_outline,
                  label: _getNestedText(translations, "home", ["navigation", "profile"], _selectedLanguage),
                  index: 3,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String featureKey,
  })


  {


    return GestureDetector(
      onTap: () {
        _navigateToFeaturePage(featureKey);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Expanded(
              child: Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFE67E22) : Colors.black54,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFFE67E22) : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}