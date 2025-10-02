import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisan_krushi/pages/sign_in.dart';
import '../services/translation_service.dart';

class ManageProfilePage extends StatefulWidget {
  const ManageProfilePage({super.key});

  @override
  State<ManageProfilePage> createState() => _ManageProfilePageState();
}

class _ManageProfilePageState extends State<ManageProfilePage> {
  final TextEditingController _fullNameController = TextEditingController(
      text: 'Parves Ahamad');
  final TextEditingController _phoneController = TextEditingController(
      text: '(+880) 1759263000');
  final TextEditingController _emailController = TextEditingController(
      text: 'nirobparvesahammod@gmail.com');
  final TextEditingController _usernameController = TextEditingController(
      text: '@parvesahamad');

  String _selectedGender = 'Male';
  String _selectedDate = '05-01-2001';
  int _selectedIndex = 3; // Profile tab is selected
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
  String _getNestedText(Map<String, dynamic> translations, String section,
      List<String> keys, String language) {
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
      case 0: // Explore
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case 1: // Chat
      // Navigate to chat
        break;
      case 2: // Alerts
      // Navigate to alerts
        break;
      case 3: // Profile
        Navigator.pop(context);
        break;
    }
  }

  void _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2001, 1, 5),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate =
        '${picked.day.toString().padLeft(2, '0')}-${picked.month
            .toString()
            .padLeft(2, '0')}-${picked.year}';
      });
    }
  }

  void _saveProfile(Map<String, dynamic> translations) {
    _triggerHaptic();
    // Handle save profile logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile saved successfully!',
          // You can add this to translations if needed
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFFE67E22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      // Logo
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

                  const SizedBox(height: 40),

                  // Profile Picture and Name
                  Row(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                          image: const DecorationImage(
                            image: AssetImage("assets/logo1.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getNestedText(
                                translations, "profile", ["user_name"],
                                _selectedLanguage),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            _getNestedText(
                                translations, "profile", ["user_subtitle"],
                                _selectedLanguage),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Full Name
                          _buildTextField(
                            label: 'Full name', // Can be added to translations
                            controller: _fullNameController,
                          ),

                          const SizedBox(height: 16),

                          // Gender and Date Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Male', // Can be added to translations
                                  value: _selectedGender,
                                  items: ['Male', 'Female', 'Other'],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _selectDate,
                                  child: _buildDateField(
                                    label: _selectedDate,
                                    value: _selectedDate,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Phone Number
                          _buildTextField(
                            label: 'Phone number',
                            // Can be added to translations
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 16),

                          // Email
                          _buildTextField(
                            label: 'Email', // Can be added to translations
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 16),

                          // Username
                          _buildTextField(
                            label: 'User name', // Can be added to translations
                            controller: _usernameController,
                          ),

                          const SizedBox(height: 40),

                          // Save Button
                          GestureDetector(
                            onTap: () => _saveProfile(translations),
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9CAF88),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _getNestedText(translations, "profile",
                                      ["actions", "save"], _selectedLanguage),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            dropdownColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Icon(
                Icons.calendar_today,
                color: Colors.grey[600],
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem(Map<String, dynamic> translations, {
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
              _getNestedText(
                  translations, "profile", labelKey, _selectedLanguage),
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}