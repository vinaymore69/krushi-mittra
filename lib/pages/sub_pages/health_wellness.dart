import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'health_pages/find_nearby_clinics.dart';
import '../../services/translation_service.dart';
import '../sign_in.dart';
import '../chat.dart';
import '../notification.dart';
import '../profile.dart';

class HealthWellnessPage extends StatefulWidget {
  const HealthWellnessPage({super.key});

  @override
  State<HealthWellnessPage> createState() => _HealthWellnessPageState();
}

class _HealthWellnessPageState extends State<HealthWellnessPage> {
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
      return keys.last;
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
      case 'Health News & Schemes':
        page = const FarmClinicPage();
        break;
      case 'First Aid Guide':
        page = const FarmClinicPage();
        break;
      case 'Seasonal Wellness':
        page = const FarmClinicPage();
        break;
      case 'Mental Health Support':
        page = const FarmClinicPage();
        break;
      case 'Nutrition Corner':
        page = const FarmClinicPage();
        break;
      case 'Find Nearby Clinics':
        page = const FarmClinicPage();
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
                          Navigator.pop(context);
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
                      "Health & Wellness",
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
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
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
                          // Health News & Schemes Card
                          _buildFeatureCard(
                            icon: Icons.newspaper,
                            title: "Health News & Schemes",
                            description: "Latest health news, updates on government health schemes, and vaccination camp information.",
                            color: const Color(0xFFE67E22),
                            featureKey: 'Health News & Schemes',
                          ),
                          // First Aid Guide Card
                          _buildFeatureCard(
                            icon: Icons.medical_services,
                            title: "First Aid Guide",
                            description: "Quick access guide for treating common farm injuries like cuts, sprains, and insect bites.",
                            color: const Color(0xFF9CAF88),
                            featureKey: 'First Aid Guide',
                          ),
                          // Seasonal Wellness Card
                          _buildFeatureCard(
                            icon: Icons.wb_sunny_outlined,
                            title: "Seasonal Wellness",
                            description: "Tips to stay healthy different seasons, from prevenistroce to aving monsoo-related illness.",
                            color: const Color(0xFF9CAF88),
                            featureKey: 'Seasonal Wellness',
                          ),
                          // Mental Health Support Card
                          _buildFeatureCard(
                            icon: Icons.psychology,
                            title: "Mental Health Support",
                            description: "Resources for managing stress, connectin of support groups, and mosl mental wbening",
                            color: const Color(0xFFE67E22),
                            featureKey: 'Mental Health Support',
                          ),
                          // Nutrition Corner Card
                          _buildFeatureCard(
                            icon: Icons.restaurant,
                            title: "Nutrition Corner",
                            description: "Dietary recommendations anutrition tips to maintain energy for demangy for demaning farm work.",
                            color: const Color(0xFFE67E22),
                            featureKey: 'Nutrition Corner',
                          ),
                          // Find Nearby Clinics Card
                          _buildFeatureCard(
                            icon: Icons.local_hospital,
                            title: "Find Nearby Clinics",
                            description: "Recommendations clinics guisllatals, and prinsmary primary health centers.",
                            color: const Color(0xFF9CAF88),
                            featureKey: 'Find Nearby Clinics',
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String featureKey,
  }) {
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
}