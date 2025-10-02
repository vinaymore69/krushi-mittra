import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisan_krushi/pages/sign_in.dart';
import 'manage_profile.dart';
import '../services/translation_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3;
  Future<Map<String, dynamic>>? _translationsFuture;
  bool _notificationsEnabled = true;

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

    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        break;
      case 2:
        break;
      case 3:
        break;
    }
  }

  void _navigateToManageProfile() {
    _triggerHaptic();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageProfilePage()),
    );
  }

  void _showLogoutDialog() {
    _triggerHaptic();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Add logout logic here
              },
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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

            return Column(
              children: [
                // Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/logo1.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header Card
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE67E22).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  image: const DecorationImage(
                                    image: AssetImage("assets/profile.png"),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getNestedText(translations, "profile", ["user_name"], _selectedLanguage),
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getNestedText(translations, "profile", ["user_subtitle"], _selectedLanguage),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Account Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Account',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSettingsOption(
                                translations,
                                icon: Icons.person_outline,
                                titleKey: ["options", "manage_user"],
                                subtitle: "Edit your profile information",
                                iconColor: const Color(0xFFE67E22),
                                onTap: _navigateToManageProfile,
                                isFirst: true,
                              ),
                              _buildDivider(),
                              _buildSettingsOption(
                                translations,
                                icon: Icons.description_outlined,
                                titleKey: ["options", "my_posts"],
                                subtitle: "View and manage your posts",
                                iconColor: const Color(0xFF3498DB),
                              ),
                              _buildDivider(),
                              _buildSettingsOption(
                                translations,
                                icon: Icons.bookmark_border,
                                titleKey: ["options", "saved_items"],
                                subtitle: "Access your saved content",
                                iconColor: const Color(0xFF9B59B6),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Preferences Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Preferences',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSettingsOption(
                                translations,
                                icon: Icons.notifications_outlined,
                                titleKey: ["options", "notifications"],
                                subtitle: "Manage notification settings",
                                iconColor: const Color(0xFFE74C3C),
                                hasSwitch: true,
                                switchValue: _notificationsEnabled,
                                onSwitchChanged: (value) {
                                  setState(() {
                                    _notificationsEnabled = value;
                                  });
                                },
                                isFirst: true,
                              ),
                              _buildDivider(),
                              _buildSettingsOption(
                                translations,
                                icon: Icons.language_outlined,
                                titleKey: ["options", "language"],
                                subtitle: "Change app language",
                                iconColor: const Color(0xFF16A085),
                              ),
                              _buildDivider(),
                              _buildSettingsOption(
                                translations,
                                icon: Icons.location_on_outlined,
                                titleKey: ["options", "location"],
                                subtitle: "Set your farming location",
                                iconColor: const Color(0xFFE67E22),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Support & Legal Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Support & Legal',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSettingsOption(
                                translations,
                                icon: Icons.help_outline,
                                titleKey: ["options", "help_support"],
                                subtitle: "Get help and contact us",
                                iconColor: const Color(0xFF3498DB),
                                isFirst: true,
                              ),
                              _buildDivider(),
                              _buildSettingsOption(
                                translations,
                                icon: Icons.security_outlined,
                                titleKey: ["options", "privacy_security"],
                                subtitle: "Manage privacy settings",
                                iconColor: const Color(0xFF2ECC71),
                              ),
                              _buildDivider(),
                              _buildSettingsOption(
                                translations,
                                icon: Icons.shield_outlined,
                                titleKey: ["options", "data_privacy"],
                                subtitle: "How we protect your data",
                                iconColor: const Color(0xFF9B59B6),
                              ),
                              _buildDivider(),
                              _buildSettingsOption(
                                translations,
                                icon: Icons.article_outlined,
                                titleKey: ["options", "terms_conditions"],
                                subtitle: "Read our terms of service",
                                iconColor: const Color(0xFF34495E),
                              ),
                              _buildDivider(),
                              _buildSettingsOption(
                                translations,
                                icon: Icons.policy_outlined,
                                titleKey: ["options", "privacy_policy"],
                                subtitle: "View our privacy policy",
                                iconColor: const Color(0xFF7F8C8D),
                              ),
                              _buildDivider(),
                              _buildSettingsOption(
                                translations,
                                icon: Icons.info_outline,
                                titleKey: ["options", "about"],
                                subtitle: "App version and information",
                                iconColor: const Color(0xFF95A5A6),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Logout Button
                        GestureDetector(
                          onTap: _showLogoutDialog,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Logout',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
        future: _translationsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
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
                  translations,
                  icon: Icons.explore,
                  labelKey: ["navigation", "explore"],
                  index: 0,
                ),
                _buildBottomNavItem(
                  translations,
                  icon: Icons.chat_bubble_outline,
                  labelKey: ["navigation", "chat"],
                  index: 1,
                ),
                _buildBottomNavItem(
                  translations,
                  icon: Icons.notifications_none,
                  labelKey: ["navigation", "alerts"],
                  index: 2,
                ),
                _buildBottomNavItem(
                  translations,
                  icon: Icons.person,
                  labelKey: ["navigation", "profile"],
                  index: 3,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[200],
      ),
    );
  }

  Widget _buildSettingsOption(
      Map<String, dynamic> translations, {
        required IconData icon,
        required List<String> titleKey,
        required String subtitle,
        required Color iconColor,
        bool hasSwitch = false,
        bool switchValue = false,
        Function(bool)? onSwitchChanged,
        VoidCallback? onTap,
        bool isFirst = false,
        bool isLast = false,
      }) {
    return GestureDetector(
      onTap: hasSwitch ? null : () {
        _triggerHaptic();
        if (onTap != null) {
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
            topRight: isFirst ? const Radius.circular(16) : Radius.zero,
            bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getNestedText(translations, "profile", titleKey, _selectedLanguage),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: (value) {
                  _triggerHaptic();
                  if (onSwitchChanged != null) {
                    onSwitchChanged(value);
                  }
                },
                activeColor: const Color(0xFFE67E22),
              )
            else
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
      Map<String, dynamic> translations, {
        required IconData icon,
        required List<String> labelKey,
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
              _getNestedText(translations, "profile", labelKey, _selectedLanguage),
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