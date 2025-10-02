import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_in.dart';

// Global variable to store selected language
String selectedLanguage = 'English';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _languageController;
  late AnimationController _glowController;
  late AnimationController _dropdownController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _dropdownAnimation;

  int currentLanguageIndex = 0;
  bool showDropdown = false;
  String? dropdownValue;

  final List<Map<String, dynamic>> languages = [
    {
      'greeting': 'Welcome',
      'language': 'English',
      'code': 'en',
      'fontSize': 48.0,
      'fontFamily': 'Poppins',
    },
    {
      'greeting': 'स्वागत है',
      'language': 'हिंदी',
      'code': 'hi',
      'fontSize': 44.0,
      'fontFamily': 'NotoSansDevanagari',
    },
    {
      'greeting': 'स्वागत आहे',
      'language': 'मराठी',
      'code': 'mr',
      'fontSize': 44.0,
      'fontFamily': 'NotoSansDevanagari',
    },
    {
      'greeting': 'ਸੁਆਗਤ ਹੈ',
      'language': 'ਪੰਜਾਬੀ',
      'code': 'pa',
      'fontSize': 44.0,
      'fontFamily': 'NotoSans',
    },
    {
      'greeting': 'ಸ್ವಾಗತ',
      'language': 'ಕನ್ನಡ',
      'code': 'kn',
      'fontSize': 44.0,
      'fontFamily': 'NotoSansKannada',
    },
  ];

  @override
  void initState() {
    super.initState();

    _languageController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _dropdownController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _languageController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ))..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _glowController.forward();
      }
    });

    _dropdownAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dropdownController,
      curve: Curves.elasticOut,
    ));

    _startLanguageAnimation();
  }

  void _startLanguageAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _languageController.forward();
    _glowController.forward();

    // Show first language, then cycle through the rest
    await Future.delayed(const Duration(milliseconds: 2000));

    // Cycle through remaining languages
    for (int i = 1; i < languages.length; i++) {
      if (mounted) {
        // Fade out current text
        _languageController.reverse();
        await Future.delayed(const Duration(milliseconds: 300));

        // Change to next language
        setState(() {
          currentLanguageIndex = i;
        });

        // Fade in new text
        _languageController.forward();
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    }

    // // Cycle through all languages one more time
    // for (int cycle = 0; cycle < 1; cycle++) {
    //   for (int i = 0; i < languages.length; i++) {
    //     if (mounted) {
    //       // Fade out current text
    //       _languageController.reverse();
    //       await Future.delayed(const Duration(milliseconds: 300));
    //
    //       // Change to next language
    //       setState(() {
    //         currentLanguageIndex = i;
    //       });
    //
    //       // Fade in new text
    //       _languageController.forward();
    //       await Future.delayed(const Duration(milliseconds: 1800));
    //     }
    //   }
    // }

    // After showing all languages, show dropdown
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        showDropdown = true;
      });
      _dropdownController.forward();
    }
  }

  void _navigateToSignIn() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const SignInPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  TextStyle _getLanguageTextStyle(Map<String, dynamic> lang, double fontSize, Color color) {
    switch (lang['code']) {
      case 'hi':
      case 'mr':
        return GoogleFonts.notoSansDevanagari(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        );
      case 'kn':
        return GoogleFonts.notoSansKannada(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        );
      case 'pa':
        return GoogleFonts.notoSans(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        );
      default:
        return GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        );
    }
  }

  TextStyle _getDropdownTextStyle(Map<String, dynamic> lang) {
    switch (lang['code']) {
      case 'hi':
      case 'mr':
        return GoogleFonts.notoSansDevanagari(
          fontSize: 14.0,
          color: const Color(0xFFE67E22),
          fontWeight: FontWeight.w400,
        );
      case 'kn':
        return GoogleFonts.notoSansKannada(
          fontSize: 14.0,
          color: const Color(0xFFE67E22),
          fontWeight: FontWeight.w500,
        );
      case 'pa':
        return GoogleFonts.notoSans(
          fontSize: 14.0,
          color: const Color(0xFFE67E22),
          fontWeight: FontWeight.w500,
        );
      default:
        return GoogleFonts.poppins(
          fontSize: 14.0,
          color: const Color(0xFFE67E22),
          fontWeight: FontWeight.w500,
        );
    }
  }

  @override
  void dispose() {
    _languageController.dispose();
    _glowController.dispose();
    _dropdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),

                    // App Logo
                    Container(
                      width: 140,
                      height: 180,
                      margin: const EdgeInsets.only(bottom: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          "assets/logo1.png",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF8BC34A),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.agriculture,
                                size: 40,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Animated Language Greetings
                    if (!showDropdown)
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _fadeAnimation,
                          _glowAnimation,
                        ]),
                        builder: (context, child) {
                          final currentLang = languages[currentLanguageIndex];
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  // Glowing greeting text
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Glow effect
                                      Text(
                                        currentLang['greeting'],
                                        textAlign: TextAlign.center,
                                        style: _getLanguageTextStyle(
                                          currentLang,
                                          currentLang['fontSize'],
                                          const Color(0xFFE67E22).withOpacity(
                                            _glowAnimation.value * 0.5,
                                          ),
                                        ).copyWith(
                                          shadows: [
                                            Shadow(
                                              blurRadius: 30,
                                              color: const Color(0xFFE67E22).withOpacity(
                                                _glowAnimation.value,
                                              ),
                                              offset: const Offset(0, 0),
                                            ),
                                            Shadow(
                                              blurRadius: 50,
                                              color: const Color(0xFF4CAF50).withOpacity(
                                                _glowAnimation.value * 0.3,
                                              ),
                                              offset: const Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Main text
                                      Text(
                                        currentLang['greeting'],
                                        textAlign: TextAlign.center,
                                        style: _getLanguageTextStyle(
                                          currentLang,
                                          currentLang['fontSize'],
                                          const Color(0xFFE67E22),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  // Language name
                                  Text(
                                    currentLang['language'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // App Name
                    SizedBox(height: showDropdown ? 10 : 80),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Team Tech',
                          style: GoogleFonts.poppins(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'NOVA',
                          style: GoogleFonts.poppins(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE67E22),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  ],
                ),
              ),
            ),

            // Fixed Language Selection Dropdown at bottom
            if (showDropdown)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _dropdownAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _dropdownAnimation.value,
                      child: FadeTransition(
                        opacity: _dropdownAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Choose Your Language',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            // const SizedBox(height: 6),
                            // Text(
                            //   'अपनी भाषा चुनें',
                            //   style: GoogleFonts.notoSansDevanagari(
                            //     fontSize: 12,
                            //     fontWeight: FontWeight.w400,
                            //     color: Colors.black54,
                            //   ),
                            // ),
                            const SizedBox(height: 25),

                            // Dropdown Container
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 280),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white,
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: dropdownValue,
                                  hint: Text(
                                    'Select Language',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.black87,
                                    size: 24,
                                  ),
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  items: languages.map<DropdownMenuItem<String>>((lang) {
                                    return DropdownMenuItem<String>(
                                      value: lang['language'],
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              lang['greeting'],
                                              style: _getDropdownTextStyle(lang),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${lang['language']})',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11.0,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      dropdownValue = newValue;
                                      selectedLanguage = newValue!;
                                    });
                                  },
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Continue Button
                            if (dropdownValue != null)
                              ElevatedButton(
                                onPressed: () {
                                  print('Selected Language: $selectedLanguage');
                                  _navigateToSignIn();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF85A938),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}