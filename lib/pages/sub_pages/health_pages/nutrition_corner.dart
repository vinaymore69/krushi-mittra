import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../../chat.dart';
import '../../home.dart';
import '../../sign_in.dart';

class NutritionCornerPage extends StatefulWidget {
  const NutritionCornerPage({super.key});

  @override
  State<NutritionCornerPage> createState() => _NutritionCornerPageState();
}

class _NutritionCornerPageState extends State<NutritionCornerPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  static const String _geminiApiKey = 'AIzaSyDUksC8I2EoNn9Ss3WuzNQaCt2VhH5NGoE';

  String _tipOfTheDay = '';
  bool _isLoadingTip = true;

  List<Map<String, String>> _seasonalSuperfoods = [];
  bool _isLoadingSuperfoods = true;

  List<Map<String, dynamic>> _recipes = [];
  bool _isLoadingRecipes = true;

  String _hydrationTip = '';
  bool _isLoadingHydration = true;

  // Chat Section Variables
  bool _isChatOpen = false;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  List<ChatMessage> _chatMessages = [];
  bool _isSendingMessage = false;
  late AnimationController _chatAnimationController;
  late Animation<double> _chatScaleAnimation;
  late Animation<Offset> _chatSlideAnimation;

  // Voice Support Variables
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _listeningText = '';

  String get _languageCode {
    final languageMap = {
      'English': 'en-IN',
      'हिन्दी': 'hi-IN',
      'मराठी': 'mr-IN',
      'ਪੰਜਾਬੀ': 'pa-IN',
      'ಕನ್ನಡ': 'kn-IN',
      'தமிழ்': 'ta-IN',
      'తెలుగు': 'te-IN',
      'മലയാളം': 'ml-IN',
      'ગુજરાતી': 'gu-IN',
      'বাংলা': 'bn-IN',
      'ଓଡ଼ିଆ': 'or-IN',
      'اردو': 'ur-IN',
    };
    return languageMap[selectedLanguageGlobal] ?? 'en-IN';
  }

  String get _currentMonth {
    return DateTime.now().month.toString();
  }

  String get _currentSeason {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'Summer';
    if (month >= 6 && month <= 9) return 'Monsoon';
    if (month >= 10 && month <= 11) return 'Post-Monsoon';
    return 'Winter';
  }

  @override
  void initState() {
    super.initState();
    _fetchAllNutritionData();
    _initializeVoiceSupport();

    _chatAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _chatScaleAnimation = CurvedAnimation(
      parent: _chatAnimationController,
      curve: Curves.easeOutBack,
    );

    _chatSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _chatAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    _chatAnimationController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initializeVoiceSupport() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        print('Speech recognition error: $error');
      },
    );

    await _flutterTts.setLanguage(_languageCode.split('-')[0]);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _listeningText = '';
        });

        _speech.listen(
          onResult: (result) {
            setState(() {
              _listeningText = result.recognizedWords;
              if (result.finalResult) {
                _chatController.text = _listeningText;
                _isListening = false;
              }
            });
          },
          localeId: _languageCode,
        );
      }
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    await _flutterTts.speak(text);
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  void _toggleChat() {
    _triggerHaptic();
    setState(() {
      _isChatOpen = !_isChatOpen;
    });

    if (_isChatOpen) {
      _chatAnimationController.forward();
      if (_chatMessages.isEmpty) {
        _addWelcomeMessage();
      }
    } else {
      _chatAnimationController.reverse();
      _stopSpeaking();
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _chatMessages.add(ChatMessage(
        text: "Hello! I'm your nutrition assistant. Ask me anything about diet, recipes, or healthy eating for farmers! 🌾",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _fetchAllNutritionData() async {
    await Future.wait([
      _fetchTipOfTheDay(),
      _fetchSeasonalSuperfoods(),
      _fetchRecipes(),
      _fetchHydrationTip(),
    ]);
  }

  Future<String> _callGeminiAPI(String prompt) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _geminiApiKey,
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1000,
          }
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
        }
      }
      throw 'Failed to get response';
    } catch (e) {
      print('Gemini API Error: $e');
      return '';
    }
  }

  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty || _isSendingMessage) return;

    final userMessage = _chatController.text.trim();
    _chatController.clear();
    setState(() => _listeningText = '');

    setState(() {
      _chatMessages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isSendingMessage = true;
    });

    _scrollToBottom();

    final language = selectedLanguageGlobal;
    final prompt = '''You are a nutrition expert helping Indian farmers with diet and health advice.
User's question: "$userMessage"
Language: $language

Provide a helpful, practical answer in $language language. Keep it:
- Clear and simple
- Relevant to farmers' lifestyle
- Based on locally available foods
- Around 3-4 sentences

Only provide the answer, nothing else.''';

    final response = await _callGeminiAPI(prompt);

    final aiResponse = response.isNotEmpty
        ? response.trim()
        : "I'm sorry, I couldn't process that. Please try again.";

    setState(() {
      _chatMessages.add(ChatMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isSendingMessage = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _fetchTipOfTheDay() async {
    final language = selectedLanguageGlobal;
    final prompt = '''Generate a single practical nutrition tip for Indian farmers in $language language.
The tip should be:
- Short (1-2 sentences)
- About staying healthy and energized for farm work
- Focus on simple, affordable nutrition advice
- Relevant for Indian context

Only provide the tip text, nothing else.''';

    final tip = await _callGeminiAPI(prompt);
    if (mounted && tip.isNotEmpty) {
      setState(() {
        _tipOfTheDay = tip.trim();
        _isLoadingTip = false;
      });
    } else if (mounted) {
      setState(() {
        _tipOfTheDay = 'Stay hydrated! Drink at least 8-10 glasses of water daily.';
        _isLoadingTip = false;
      });
    }
  }

  Future<void> _fetchSeasonalSuperfoods() async {
    final language = selectedLanguageGlobal;
    final season = _currentSeason;
    final prompt = '''List 5 seasonal fruits or vegetables available in India during $season season.
Language: $language

For each item, provide in this exact JSON format:
[
  {
    "name": "vegetable name in $language",
    "emoji": "appropriate emoji",
    "benefits": "key health benefit in $language (max 4-5 words)"
  }
]

Only return valid JSON array, nothing else.''';

    final response = await _callGeminiAPI(prompt);
    if (mounted && response.isNotEmpty) {
      try {
        final jsonStart = response.indexOf('[');
        final jsonEnd = response.lastIndexOf(']') + 1;
        if (jsonStart != -1 && jsonEnd > jsonStart) {
          final jsonStr = response.substring(jsonStart, jsonEnd);
          final List<dynamic> items = json.decode(jsonStr);

          setState(() {
            _seasonalSuperfoods = items.map((item) => {
              'name': item['name'].toString(),
              'emoji': item['emoji'].toString(),
              'benefits': item['benefits'].toString(),
            }).toList();
            _isLoadingSuperfoods = false;
          });
        }
      } catch (e) {
        print('Error parsing superfoods: $e');
        _setDefaultSuperfoods();
      }
    } else if (mounted) {
      _setDefaultSuperfoods();
    }
  }

  void _setDefaultSuperfoods() {
    setState(() {
      _seasonalSuperfoods = [
        {'name': 'Spinach', 'emoji': '🥬', 'benefits': 'Rich in Iron'},
        {'name': 'Carrots', 'emoji': '🥕', 'benefits': 'Boosts Vision'},
        {'name': 'Tomatoes', 'emoji': '🍅', 'benefits': 'Rich in Antioxidants'},
      ];
      _isLoadingSuperfoods = false;
    });
  }

  Future<void> _fetchRecipes() async {
    final language = selectedLanguageGlobal;
    final prompt = '''Generate 3 simple, healthy recipes for Indian farmers in $language language.
Recipes should use common, locally available ingredients and be energy-rich.

For each recipe, provide in this exact JSON format:
[
  {
    "name": "recipe name",
    "emoji": "food emoji",
    "description": "short description (5-7 words)",
    "time": "preparation time (e.g., 20 min)",
    "ingredients": ["ingredient 1", "ingredient 2", "ingredient 3", "ingredient 4"],
    "instructions": "Step 1\\nStep 2\\nStep 3\\nStep 4"
  }
]

Only return valid JSON array, nothing else.''';

    final response = await _callGeminiAPI(prompt);
    if (mounted && response.isNotEmpty) {
      try {
        final jsonStart = response.indexOf('[');
        final jsonEnd = response.lastIndexOf(']') + 1;
        if (jsonStart != -1 && jsonEnd > jsonStart) {
          final jsonStr = response.substring(jsonStart, jsonEnd);
          final List<dynamic> items = json.decode(jsonStr);

          setState(() {
            _recipes = items.map((item) => {
              'name': item['name'].toString(),
              'emoji': item['emoji'].toString(),
              'description': item['description'].toString(),
              'time': item['time'].toString(),
              'ingredients': List<String>.from(item['ingredients']),
              'instructions': item['instructions'].toString(),
            }).toList();
            _isLoadingRecipes = false;
          });
        }
      } catch (e) {
        print('Error parsing recipes: $e');
        _setDefaultRecipes();
      }
    } else if (mounted) {
      _setDefaultRecipes();
    }
  }

  void _setDefaultRecipes() {
    setState(() {
      _recipes = [
        {
          'name': 'Bajra Khichdi',
          'emoji': '🍚',
          'description': 'Wholesome one-pot meal',
          'time': '30 min',
          'ingredients': ['Bajra', 'Moong dal', 'Vegetables', 'Spices'],
          'instructions': 'Wash bajra and dal\nCook with vegetables\nAdd spices\nServe hot',
        }
      ];
      _isLoadingRecipes = false;
    });
  }

  Future<void> _fetchHydrationTip() async {
    final language = selectedLanguageGlobal;
    final prompt = '''Generate a short hydration tip for farmers in $language language.
Include:
- Importance of staying hydrated during farm work
- Simple tip (1-2 sentences)

Only provide the tip text, nothing else.''';

    final tip = await _callGeminiAPI(prompt);
    if (mounted && tip.isNotEmpty) {
      setState(() {
        _hydrationTip = tip.trim();
        _isLoadingHydration = false;
      });
    } else if (mounted) {
      setState(() {
        _hydrationTip = 'Drink water regularly, especially during hot days in the field.';
        _isLoadingHydration = false;
      });
    }
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
        break;
      case 2:
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Top Navigation
                Padding(
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

                // Page Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _getPageTitle(),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Scrollable Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchAllNutritionData,
                    color: const Color(0xFF9CAF88),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tip of the Day
                          _buildTipOfTheDayCard(),
                          const SizedBox(height: 24),

                          // Seasonal Superfoods
                          _buildSectionTitle('Seasonal Superfoods'),
                          const SizedBox(height: 12),
                          _buildSeasonalSuperfoodsSection(),
                          const SizedBox(height: 34),

                          // Hydration Helper
                          _buildHydrationCard(),
                          const SizedBox(height: 24),

                          // Farmer's Cookbook
                          _buildSectionTitle('Farmer\'s Cookbook'),
                          const SizedBox(height: 22),
                          _buildRecipesSection(),
                          const SizedBox(height: 170),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Floating Chat Button
            if (!_isChatOpen)
              Positioned(
                right: 24,
                bottom: 100,
                child: GestureDetector(
                  onTap: _toggleChat,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE67E22).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.chat_bubble,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        if (_chatMessages.isNotEmpty)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // Chat Overlay
            if (_isChatOpen)
              GestureDetector(
                onTap: _toggleChat,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),

            // Chat Window
            if (_isChatOpen)
              SlideTransition(
                position: _chatSlideAnimation,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.75,
                    margin: const EdgeInsets.only(bottom: 90),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Chat Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(32),
                              topRight: Radius.circular(32),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.support_agent,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nutrition Assistant',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Online',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _toggleChat,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Chat Messages
                        Expanded(
                          child: _chatMessages.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Start a conversation!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : ListView.builder(
                            controller: _chatScrollController,
                            padding: const EdgeInsets.all(20),
                            itemCount: _chatMessages.length,
                            itemBuilder: (context, index) {
                              return _buildChatBubble(_chatMessages[index]);
                            },
                          ),
                        ),

                        // Typing Indicator
                        if (_isSendingMessage)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildTypingDot(0),
                                      const SizedBox(width: 4),
                                      _buildTypingDot(1),
                                      const SizedBox(width: 4),
                                      _buildTypingDot(2),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Listening Indicator
                        if (_isListening)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            color: const Color(0xFFE67E22).withOpacity(0.1),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.mic,
                                  color: Color(0xFFE67E22),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _listeningText.isEmpty
                                        ? 'Listening...'
                                        : _listeningText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFFE67E22),
                                      fontStyle: _listeningText.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                ),
                                _buildPulsingDot(),
                              ],
                            ),
                          ),

                        // Chat Input
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border(
                              top: BorderSide(
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              children: [
                                // Voice Button
                                GestureDetector(
                                  onTap: _isListening ? _stopListening : _startListening,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _isListening
                                          ? const Color(0xFFE67E22)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE67E22),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                      color: _isListening
                                          ? Colors.white
                                          : const Color(0xFFE67E22),
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Text Input
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.1),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _chatController,
                                      decoration: InputDecoration(
                                        hintText: 'Ask about nutrition...',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black38,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                      maxLines: null,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) => _sendChatMessage(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Send Button
                                GestureDetector(
                                  onTap: _sendChatMessage,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: Container(
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
              label: 'Explore',
              index: 0,
            ),
            _buildBottomNavItem(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              index: 1,
            ),
            _buildBottomNavItem(
              icon: Icons.notifications_none,
              label: 'Alerts',
              index: 2,
            ),
            _buildBottomNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle() {
    final titles = {
      'English': 'Nutrition Corner',
      'हिन्दी': 'पोषण कॉर्नर',
      'मराठी': 'पोषण कोपरा',
    };
    return titles[selectedLanguageGlobal] ?? 'Nutrition Corner';
  }

  Widget _buildTipOfTheDayCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9CAF88), Color(0xFF7A9B76)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9CAF88).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '💡 Tip of the Day',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoadingTip
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
              : Text(
            _tipOfTheDay,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildSeasonalSuperfoodsSection() {
    if (_isLoadingSuperfoods) {
      return const SizedBox(
        height: 170,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF9CAF88)),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _seasonalSuperfoods.length,
        itemBuilder: (context, index) {
          final food = _seasonalSuperfoods[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right:22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    food['emoji']!,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    food['name']!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food['benefits']!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9CAF88),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHydrationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '💧 Hydration Helper',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoadingHydration
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          )
              : Text(
            _hydrationTip,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.blue[900],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesSection() {
    if (_isLoadingRecipes) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF9CAF88)),
        ),
      );
    }

    return Column(
      children: _recipes.map((recipe) => _buildRecipeCard(recipe)).toList(),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return GestureDetector(
      onTap: () => _showRecipeDetails(recipe),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CAF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    recipe['emoji'],
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe['description'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color(0xFF9CAF88),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe['time'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CAF88),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFE67E22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF9CAF88)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: message.isUser ? Colors.white : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
                if (!message.isUser && !_isSendingMessage)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: () => _speak(message.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE67E22).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                              size: 16,
                              color: const Color(0xFFE67E22),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isSpeaking ? 'Playing...' : 'Listen',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFFE67E22),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF9CAF88),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * sin((value + index * 0.3) * 2 * pi)),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFE67E22),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isSendingMessage) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFE67E22),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isListening) {
          setState(() {});
        }
      },
    );
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    _triggerHaptic();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        recipe['emoji'],
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      recipe['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Color(0xFF9CAF88),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe['time'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CAF88),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ingredients',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List<Widget>.from(
                      (recipe['ingredients'] as List).map(
                            (ingredient) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF9CAF88),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ingredient,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Instructions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recipe['instructions'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.8,
                      ),
                    ),
                  ],
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

// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}