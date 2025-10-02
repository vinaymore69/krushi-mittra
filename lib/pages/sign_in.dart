import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../backend/firebase_auth_services.dart';
import 'home.dart';
import 'sign_up.dart';
import '../services/translation_service.dart'; // Import the translation service

String selectedLanguageGlobal = 'English';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // final FirebaseAuthServices _auth = FirebaseAuthServices();
  bool _isPasswordVisible = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  final _formKey2 = GlobalKey<FormState>();
  Future<Map<String, dynamic>>? _translationsFuture;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Language dropdown variables
  String _selectedLanguage = 'English';
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇮🇳'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'mr', 'name': 'मराठी', 'flag': '🇮🇳'},
    {'code': 'pa', 'name': 'ਪੰਜਾਬੀ', 'flag': '🇮🇳'},
    {'code': 'kn', 'name': 'ಕನ್ನಡ', 'flag': '🇮🇳'},
    {'code': 'ta', 'name': 'தமிழ்', 'flag': '🇮🇳'},
    {'code': 'te', 'name': 'తెలుగు', 'flag': '🇮🇳'},
    {'code': 'ml', 'name': 'മലയാളം', 'flag': '🇮🇳'},
    {'code': 'gu', 'name': 'ગુજરાતી', 'flag': '🇮🇳'},
    {'code': 'bn', 'name': 'বাংলা', 'flag': '🇮🇳'},
    {'code': 'or', 'name': 'ଓଡ଼ିଆ', 'flag': '🇮🇳'},
    {'code': 'ur', 'name': 'اردو', 'flag': '🇮🇳'},
  ];

  @override
  void initState() {
    super.initState();
    _translationsFuture = TranslationService.fetchTranslations();
    _selectedLanguage = selectedLanguageGlobal;

    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _onLanguageChanged(String newLanguage) {
    _triggerHaptic();
    setState(() {
      _selectedLanguage = newLanguage;
      selectedLanguageGlobal = newLanguage;
    });
    // Clear cache and reload translations when language changes
    TranslationService.clearCache();
    _translationsFuture = TranslationService.fetchTranslations();
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

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Top Row with Setup Fields Header, Sign In, and Language Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side - Setup and Fields stacked vertically
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE67E22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                TranslationService.getText(translations, "signin", "setup", _selectedLanguage),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Transform.translate(
                              offset: const Offset(0, -5),
                              child: Text(
                                TranslationService.getText(translations, "signin", "fields", _selectedLanguage),
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Right side - Language Dropdown and Sign In
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Language Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9CAF88).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF9CAF88).withOpacity(0.3)),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                underline: Container(),
                                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                dropdownColor: Colors.white,
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    _onLanguageChanged(newValue);
                                  }
                                },
                                items: _languages.map<DropdownMenuItem<String>>((Map<String, String> language) {
                                  return DropdownMenuItem<String>(
                                    value: language['name']!,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          language['flag']!,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          language['name']!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Sign In text
                            Transform.translate(
                              offset: const Offset(0, -15),
                              child: Text(
                                TranslationService.getText(translations, "signin", "signin", _selectedLanguage),
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Logo Section
                    Center(
                      child: Column(
                        children: [
                          // Logo image
                          Container(
                            width: 140,
                            height: 180,
                            margin: const EdgeInsets.only(bottom: 10),
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

                    const SizedBox(height: 10),

                    // Email Field
                    Text(
                      TranslationService.getText(translations, "signin", "email", _selectedLanguage),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 8),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: _isEmailFocused ? Colors.transparent : const Color(0xFF262C23),
                        border: _isEmailFocused
                            ? Border.all(color: const Color(0xFF262C23), width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        onTap: _triggerHaptic,
                        style: GoogleFonts.poppins(
                          color: _isEmailFocused ? Colors.black : Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: TranslationService.getText(translations, "signin", "email_hint", _selectedLanguage),
                          hintStyle: GoogleFonts.poppins(
                            color: _isEmailFocused ? Colors.black54 : Colors.white,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Password Field
                    Text(
                      TranslationService.getText(translations, "signin", "password", _selectedLanguage),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 8),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: _isPasswordFocused ? Colors.transparent : const Color(0xFF262C23),
                        border: _isPasswordFocused
                            ? Border.all(color: const Color(0xFF262C23), width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: !_isPasswordVisible,
                        onTap: _triggerHaptic,
                        style: GoogleFonts.poppins(
                          color: _isPasswordFocused ? Colors.black : Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: '....',
                          hintStyle: GoogleFonts.poppins(
                            color: _isPasswordFocused ? Colors.black54 : Colors.white70,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          suffixIcon: IconButton(
                            padding: const EdgeInsets.only(right: 20),
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: _isPasswordFocused ? Colors.black : Colors.white,
                            ),
                            onPressed: () {
                              _triggerHaptic();
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Forgot Password
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_reset,
                          size: 27,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            _triggerHaptic();
                            // Handle forgot password
                          },
                          child: Text(
                            TranslationService.getText(translations, "signin", "forgot_password", _selectedLanguage),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _triggerHaptic();
                          // _signIn();
                          // Handle sign in
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE67E22),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          TranslationService.getText(translations, "signin", "signin", _selectedLanguage),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Or Sign In with
                    Center(
                      child: Text(
                        TranslationService.getText(translations, "signin", "or_signin_with", _selectedLanguage),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Apple Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _triggerHaptic();
                          // Handle Apple sign in
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9CAF88),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.apple,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              TranslationService.getText(translations, "signin", "apple", _selectedLanguage),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Google Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _triggerHaptic();
                          // Handle Google sign in
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9CAF88),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              TranslationService.getText(translations, "signin", "google", _selectedLanguage),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Home Button (temporary)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _triggerHaptic();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9CAF88),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'H',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              TranslationService.getText(translations, "signin", "home", _selectedLanguage),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Sign Up Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            TranslationService.getText(translations, "signin", "no_account", _selectedLanguage),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _triggerHaptic();
                              // Navigate to sign up
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignUpPage()),
                              );
                            },
                            child: Text(
                              TranslationService.getText(translations, "signin", "signup", _selectedLanguage),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}