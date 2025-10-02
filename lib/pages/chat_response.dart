import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;
import 'dart:io';
import 'api_service.dart';
import 'sign_in.dart';

class ChatResponsePage extends StatefulWidget {
  const ChatResponsePage({super.key});

  @override
  State<ChatResponsePage> createState() => _ChatResponsePageState();
}

class _ChatResponsePageState extends State<ChatResponsePage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isRecording = false;
  bool _showVoiceDrawer = false;
  File? _selectedImage;
  File? _audioFile;

  // Enhanced TTS variables
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  String _currentSpeakingMessageId = '';
  bool _ttsInitialized = false;

  // Audio recorder
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Animation controllers
  AnimationController? _drawerAnimationController;
  AnimationController? _amplifierAnimationController;
  Animation<double>? _drawerAnimation;
  Animation<double>? _amplifierAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize TTS first
    _initTts();

    // Initialize animation controllers
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _amplifierAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _drawerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _drawerAnimationController!,
      curve: Curves.easeInOut,
    ));

    _amplifierAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _amplifierAnimationController!,
      curve: Curves.easeInOut,
    ));

    // Add initial welcome message
    _addWelcomeMessage();

    // Test server connection
    _testServerConnection();
  }

  // Enhanced TTS initialization
  Future<void> _initTts() async {
    try {
      _flutterTts = FlutterTts();

      // Wait for TTS to be ready
      await _flutterTts!.awaitSpeakCompletion(true);

      // Enhanced TTS Settings
      await _flutterTts!.setVolume(0.8);
      await _flutterTts!.setSpeechRate(0.45); // Slightly slower for better clarity
      await _flutterTts!.setPitch(1.0);

      // Set language based on selected language
      await _setTtsLanguage();

      // Enhanced TTS event handlers
      _flutterTts!.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
          });
        }
        print('🔊 TTS Started speaking');
      });

      _flutterTts!.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentSpeakingMessageId = '';
          });
        }
        print('✅ TTS Completed speaking');
      });

      _flutterTts!.setProgressHandler((String text, int startOffset, int endOffset, String word) {
        // Optional: You can add visual feedback here
        print('🗣️ TTS Progress: $word');
      });

      _flutterTts!.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentSpeakingMessageId = '';
          });
        }
        print('❌ TTS Error: $msg');

        // Show user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice playback error. Please try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      });

      _ttsInitialized = true;
      print('✅ TTS initialized successfully');
    } catch (e) {
      print('❌ TTS initialization error: $e');
      _ttsInitialized = false;
    }
  }

  // Enhanced language setting with better error handling
  Future<void> _setTtsLanguage() async {
    try {
      if (!_ttsInitialized || _flutterTts == null) {
        print('⚠️ TTS not initialized, skipping language setting');
        return;
      }

      // Enhanced language mapping for TTS
      Map<String, String> ttsLanguageCodes = {
        'English': 'en-US',
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
        'اردو': 'ur-PK',
      };

      String languageCode = ttsLanguageCodes[selectedLanguageGlobal] ?? 'en-US';

      // Check if language is available
      List<dynamic> languages = await _flutterTts!.getLanguages;
      print('📋 Available TTS languages: $languages');

      bool isLanguageAvailable = languages.any((lang) =>
          lang.toString().toLowerCase().contains(languageCode.split('-')[0].toLowerCase()));

      if (isLanguageAvailable) {
        await _flutterTts!.setLanguage(languageCode);
        print('✅ TTS Language set to: $languageCode for $selectedLanguageGlobal');
      } else {
        // Fallback to English if selected language not available
        await _flutterTts!.setLanguage('en-US');
        print('⚠️ Language $languageCode not available, falling back to en-US');

        // Show warning to user
        if (mounted && selectedLanguageGlobal != 'English') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice for $selectedLanguageGlobal not available. Using English voice.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error setting TTS language: $e');
      // Fallback to default language
      try {
        await _flutterTts!.setLanguage('en-US');
      } catch (fallbackError) {
        print('❌ Fallback language setting failed: $fallbackError');
      }
    }
  }

  // Enhanced speak method with better error handling
  Future<void> _speak(String text, String messageId) async {
    try {
      if (!_ttsInitialized || _flutterTts == null) {
        print('⚠️ TTS not initialized, attempting to reinitialize...');
        await _initTts();
        if (!_ttsInitialized) {
          _showTtsError('Voice feature not available');
          return;
        }
      }

      // Stop any ongoing speech
      if (_isSpeaking) {
        await _flutterTts!.stop();
        await Future.delayed(Duration(milliseconds: 100)); // Brief pause
      }

      // Clean text for better speech
      String cleanedText = _cleanTextForSpeech(text);

      if (cleanedText.trim().isEmpty) {
        print('⚠️ Empty text, skipping TTS');
        return;
      }

      setState(() {
        _currentSpeakingMessageId = messageId;
      });

      // Ensure correct language is set
      await _setTtsLanguage();

      // Add delay to ensure TTS is ready
      await Future.delayed(Duration(milliseconds: 200));

      print('🔊 Speaking: ${cleanedText.substring(0, math.min(50, cleanedText.length))}...');

      // Start speaking
      var result = await _flutterTts!.speak(cleanedText);

      if (result == 0) {
        print('❌ TTS speak returned error code 0');
        _showTtsError('Failed to start voice playback');
      }
    } catch (e) {
      print('❌ Error in speak method: $e');
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentSpeakingMessageId = '';
        });
      }
      _showTtsError('Voice playback failed');
    }
  }

  // Clean text for better speech synthesis
  String _cleanTextForSpeech(String text) {
    // Remove excessive punctuation and special characters that might confuse TTS
    String cleaned = text
        .replaceAll(RegExp(r'[*_~`]'), '') // Remove markdown formatting
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .replaceAll(RegExp(r'\.{2,}'), '.') // Replace multiple dots with single dot
        .trim();

    return cleaned;
  }

  // Show TTS error to user
  void _showTtsError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Enhanced stop TTS method
  Future<void> _stopTts() async {
    try {
      if (_flutterTts != null && _isSpeaking) {
        await _flutterTts!.stop();
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _currentSpeakingMessageId = '';
          });
        }
        print('🔇 TTS stopped');
      }
    } catch (e) {
      print('❌ Error stopping TTS: $e');
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentSpeakingMessageId = '';
        });
      }
    }
  }

  void _testServerConnection() async {
    try {
      bool isConnected = await ApiService.testConnection();
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Cannot connect to server'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        print('✅ Server connection successful');
      }
    } catch (e) {
      print('Connection test error: $e');
    }
  }

  void _addWelcomeMessage() {
    final Map<String, String> welcomeMessages = {
      'English': 'Hello! How can I help you with your farming needs today?',
      'हिन्दी': 'नमस्ते! मैं आपकी कृषि संबंधी जरूरतों में कैसे मदद कर सकता हूं?',
      'ਪੰਜਾਬੀ': 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ! ਮੈਂ ਤੁਹਾਡੀ ਖੇਤੀਬਾੜੀ ਦੀਆਂ ਲੋੜਾਂ ਵਿੱਚ ਕਿਵੇਂ ਮਦਦ ਕਰ ਸਕਦਾ ਹਾਂ?',
      'मराठी': 'नमस्कार! मी तुमच्या शेतकरी गरजांमध्ये कशी मदत करू शकतो?',
      'ગુજરાતી': 'નમસ્તે! હું તમારી ખેતીની જરૂરિયાતોમાં કેવી રીતે મદદ કરી શકું?',
      'தமிழ்': 'வணக்கம்! உங்கள் விவசாய தேவைகளில் நான் எப்படி உதவ முடியும்?',
      'తెలుగు': 'నమస్కారం! మీ వ్యవసాయ అవసరాలలో నేను ఎలా సహాయపడగలను?',
      'ಕನ್ನಡ': 'ನಮಸ್ಕಾರ! ನಿಮ್ಮ ಕೃಷಿ ಅಗತ್ಯಗಳಲ್ಲಿ ನಾನು ಹೇಗೆ ಸಹಾಯ ಮಾಡಬಹುದು?',
      'മലയാളം': 'നമസ്കാരം! നിങ്ങളുടെ കൃഷിയുടെ ആവശ്യങ്ങളിൽ എനിക്ക് എങ്ങനെ സഹായിക്കാനാകും?',
      'বাংলা': 'নমস্কার! আপনার কৃষি প্রয়োজনে আমি কীভাবে সাহায্য করতে পারি?',
      'اردو': 'السلام علیکم! آج میں آپ کی کھیتی باڑی کی ضروریات میں کیسے مدد کر سکتا ہوں؟',
    };

    String welcomeText = welcomeMessages[selectedLanguageGlobal] ??
        welcomeMessages['English']!;

    String messageId = 'welcome_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _messages.add(ChatMessage(
        message: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
        id: messageId,
      ));
    });

    // Auto-play welcome message after a delay
    Future.delayed(Duration(milliseconds: 1500), () {
      _speak(welcomeText, messageId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _drawerAnimationController?.dispose();
    _amplifierAnimationController?.dispose();
    _audioRecorder.dispose();

    // Enhanced TTS cleanup
    if (_flutterTts != null) {
      _flutterTts!.stop();
      _flutterTts = null;
    }

    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  // Method to handle file-based queries (image and/or audio)
  Future<void> _processFileQuery() async {
    try {
      if (_selectedImage == null && _audioFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image or record audio first'),
          ),
        );
        return;
      }

      // Show loading indicator
      setState(() {
        _messages.add(ChatMessage(
          message: "Processing your request...",
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: true,
          id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
        ));
      });
      _scrollToBottom();

      // Call API with available files
      final response = await ApiService.processQuery(
        languageCode: selectedLanguageGlobal,
        imageFile: _selectedImage,
        audioFile: _audioFile,
      );

      // Remove loading message
      setState(() {
        if (_messages.isNotEmpty && _messages.last.isLoading) {
          _messages.removeLast();
        }
      });

      if (response['success'] == true) {
        setState(() {
          // Add user query if available from audio transcription
          if (response['query']?.isNotEmpty ?? false) {
            _messages.add(ChatMessage(
              message: response['query'],
              isUser: true,
              timestamp: DateTime.now(),
              id: 'user_${DateTime.now().millisecondsSinceEpoch}',
            ));
          }

          // Add bot response
          String responseText = response['analysis'] ?? 'Analysis completed successfully.';
          String messageId = 'bot_${DateTime.now().millisecondsSinceEpoch}';

          _messages.add(ChatMessage(
            message: responseText,
            isUser: false,
            timestamp: DateTime.now(),
            id: messageId,
          ));
        });
        _scrollToBottom();

        // Auto-play TTS for bot response with delay
        Future.delayed(Duration(milliseconds: 500), () {
          String responseText = response['analysis'] ?? 'Analysis completed successfully.';
          String messageId = 'bot_${DateTime.now().millisecondsSinceEpoch - 1}';
          _speak(responseText, messageId);
        });

        // Clear the selected files after processing
        setState(() {
          _selectedImage = null;
          _audioFile = null;
        });
      } else {
        // Show error message in chat
        setState(() {
          _messages.add(ChatMessage(
            message: response['error'] ?? 'Unknown error occurred. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
            id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          ));
        });
        _scrollToBottom();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Processing failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error in _processFileQuery: $e');

      // Remove loading message if error occurs
      if (_messages.isNotEmpty && _messages.last.isLoading) {
        setState(() {
          _messages.removeLast();
        });
      }

      setState(() {
        _messages.add(ChatMessage(
          message: 'Sorry, there was a problem processing your request. Please check your internet connection and try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        ));
      });
      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Method for handling text messages
  Future<void> _processTextMessage(String messageText) async {
    try {
      // Show loading indicator
      setState(() {
        _messages.add(ChatMessage(
          message: "Processing your query...",
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: true,
          id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
        ));
      });
      _scrollToBottom();

      // Call API for text processing
      final response = await ApiService.processTextQuery(
        text: messageText,
      );

      // Remove loading message
      setState(() {
        if (_messages.isNotEmpty && _messages.last.isLoading) {
          _messages.removeLast();
        }
      });

      if (response['success'] == true) {
        String responseText = response['response'] ?? 'Message received successfully.';
        String messageId = 'bot_${DateTime.now().millisecondsSinceEpoch}';

        setState(() {
          _messages.add(ChatMessage(
            message: responseText,
            isUser: false,
            timestamp: DateTime.now(),
            id: messageId,
          ));
        });
        _scrollToBottom();

        // Auto-play TTS for bot response with delay
        Future.delayed(Duration(milliseconds: 500), () {
          _speak(responseText, messageId);
        });
      } else {
        // Show error message in chat
        setState(() {
          _messages.add(ChatMessage(
            message: response['error'] ?? 'Sorry, I could not process your message. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
            id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          ));
        });
        _scrollToBottom();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Processing failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error in _processTextMessage: $e');

      // Remove loading message if error occurs
      if (_messages.isNotEmpty && _messages.last.isLoading) {
        setState(() {
          _messages.removeLast();
        });
      }

      setState(() {
        _messages.add(ChatMessage(
          message: 'Sorry, there was a connection problem. Please check your internet and try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        ));
      });
      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: Please check your connection'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final File? image = await ApiService.pickImage();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
      await _processFileQuery();
    }
  }

  // Fixed _sendMessage method for text only
  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      final String messageText = _messageController.text.trim();

      setState(() {
        _messages.add(ChatMessage(
          message: messageText,
          isUser: true,
          timestamp: DateTime.now(),
        ));
      });

      _messageController.clear();
      _scrollToBottom();
      _triggerHaptic();

      // Process text message
      _processTextMessage(messageText);
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check permission
      if (await _audioRecorder.hasPermission()) {
        // Get temporary directory
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

        setState(() {
          _isRecording = true;
        });
        _amplifierAnimationController?.repeat();

        // Enhanced recording configuration for better speech recognition
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,      // WAV format for better compatibility
            bitRate: 128000,               // Good quality
            sampleRate: 16000,             // Optimal for speech recognition
            numChannels: 1,                // Mono for speech
            autoGain: true,                // Automatic gain control
            echoCancel: true,              // Echo cancellation
            noiseSuppress: true,           // Noise suppression
          ),
          path: filePath,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recording started... Speak clearly',
              style: GoogleFonts.poppins(),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFFE67E22),
          ),
        );

        // Auto-stop recording after 30 seconds to prevent very long recordings
        Timer(Duration(seconds: 30), () {
          if (_isRecording) {
            _stopRecording();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Recording stopped automatically after 30 seconds'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission denied'),
          ),
        );
      }
    } catch (e) {
      print('Recording error: $e');

      // Fallback to m4a if WAV fails
      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String filePath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        setState(() {
          _isRecording = true;
        });
        _amplifierAnimationController?.repeat();

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 16000,
            numChannels: 1,
            autoGain: true,
            echoCancel: true,
            noiseSuppress: true,
          ),
          path: filePath,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recording started (fallback format)... Speak clearly',
              style: GoogleFonts.poppins(),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );

      } catch (fallbackError) {
        setState(() {
          _isRecording = false;
        });
        _amplifierAnimationController?.stop();
        _amplifierAnimationController?.reset();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $fallbackError'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      setState(() {
        _isRecording = false;
      });
      _amplifierAnimationController?.stop();
      _amplifierAnimationController?.reset();

      // Stop recording and get the file path
      final String? path = await _audioRecorder.stop();

      if (path != null) {
        // Check file size
        final File audioFile = File(path);
        final int fileSize = await audioFile.length();

        print('Recorded audio file: $path');
        print('File size: $fileSize bytes');

        if (fileSize < 1000) { // Less than 1KB indicates a very short or empty recording
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Recording too short. Please record for at least 2-3 seconds.',
                style: GoogleFonts.poppins(),
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );

          // Delete the short file
          try {
            await audioFile.delete();
          } catch (e) {
            print('Error deleting short audio file: $e');
          }

          return;
        }

        setState(() {
          _audioFile = audioFile;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recording saved (${(fileSize / 1024).toStringAsFixed(1)} KB). Processing...',
              style: GoogleFonts.poppins(),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        // Process the recorded audio
        await _processFileQuery();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      _amplifierAnimationController?.stop();
      _amplifierAnimationController?.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleVoiceDrawer() {
    _triggerHaptic();
    setState(() {
      _showVoiceDrawer = !_showVoiceDrawer;
    });

    if (_showVoiceDrawer) {
      _drawerAnimationController?.forward();
    } else {
      _drawerAnimationController?.reverse();
      _stopRecording();
    }
  }

  Future<void> _handleImageSelection() async {
    final File? image = await ApiService.pickImage();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });

      // Show image preview message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image selected. Add audio or text message, then tap send.',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
      // Process the query with the selected image
      // await _processFileQuery();
    }
  }

  void _clearSelectedFiles() {
    setState(() {
      _selectedImage = null;
      _audioFile = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Files cleared')),
    );
  }
  void _sendCombinedMessage() {
    final bool hasImage = _selectedImage != null;
    final bool hasAudio = _audioFile != null;
    final bool hasText = _messageController.text.trim().isNotEmpty;

    if (!hasImage && !hasAudio && !hasText) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a message, image, or audio')),
      );
      return;
    }

    // Create a combined message description
    String messageDescription = '';
    if (hasText) {
      messageDescription = _messageController.text.trim();
    } else {
      List<String> parts = [];
      if (hasImage) parts.add('📷 Image');
      if (hasAudio) parts.add('🎤 Audio recording');
      messageDescription = parts.join(' + ');
    }

    // Add the combined message to chat
    setState(() {
      _messages.add(ChatMessage(
        message: messageDescription,
        isUser: true,
        timestamp: DateTime.now(),
        imageFile: _selectedImage,
        audioFile: _audioFile,
      ));
    });

    _scrollToBottom();
    _triggerHaptic();

    // Process the combined query
    _processCombinedQuery(_messageController.text.trim());

    // Clear inputs
    _messageController.clear();
    setState(() {
      _selectedImage = null;
      _audioFile = null;
    });
  }
  Future<void> _processCombinedQuery(String? textMessage) async {
    try {
      // Show loading indicator
      setState(() {
        _messages.add(ChatMessage(
          message: "Processing your combined query...",
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: true,
          id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
        ));
      });
      _scrollToBottom();

      // Call API with all available data
      final response = await ApiService.processCombinedQuery(
        text: textMessage,
        languageCode: selectedLanguageGlobal,
        imageFile: _selectedImage,
        audioFile: _audioFile,
      );

      // Remove loading message
      setState(() {
        if (_messages.isNotEmpty && _messages.last.isLoading) {
          _messages.removeLast();
        }
      });

      if (response['success'] == true) {
        String responseText = response['analysis'] ?? 'Analysis completed successfully.';
        String messageId = 'bot_${DateTime.now().millisecondsSinceEpoch}';

        setState(() {
          _messages.add(ChatMessage(
            message: responseText,
            isUser: false,
            timestamp: DateTime.now(),
            id: messageId,
          ));
        });
        _scrollToBottom();

        // Auto-play TTS for bot response
        Future.delayed(Duration(milliseconds: 500), () {
          _speak(responseText, messageId);
        });

      } else {
        // Error handling
        setState(() {
          _messages.add(ChatMessage(
            message: response['error'] ?? 'Processing failed. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
            id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          ));
        });
        _scrollToBottom();
      }

    } catch (e) {
      print('Error in _processCombinedQuery: $e');

      // Remove loading message
      if (_messages.isNotEmpty && _messages.last.isLoading) {
        setState(() {
          _messages.removeLast();
        });
      }

      setState(() {
        _messages.add(ChatMessage(
          message: 'Connection error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        ));
      });
      _scrollToBottom();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header with language indicator
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
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
                      // Title with language
                      Column(
                        children: [
                          Text(
                            'ChatBot',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            selectedLanguageGlobal,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      // Logo
                      Container(
                        width: 48,
                        height: 48,
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

                // Chat Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),

                // Message Input
                // Message Input Section
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // File selection indicators
                      if (_selectedImage != null || _audioFile != null)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              if (_selectedImage != null)
                                Row(
                                  children: [
                                    Icon(Icons.image, color: Colors.green[700], size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Image selected',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              if (_audioFile != null)
                                Row(
                                  children: [
                                    Icon(Icons.mic, color: Colors.blue[700], size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Audio recorded',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                  ],
                                ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _clearSelectedFiles,
                                child: Icon(Icons.clear, color: Colors.red, size: 16),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        children: [
                          // Image Upload Button
                          GestureDetector(
                            onTap: _handleImageSelection,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _selectedImage != null
                                    ? Colors.green[200]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.image,
                                color: _selectedImage != null
                                    ? Colors.green[700]
                                    : const Color(0xFFE67E22),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      maxLines: null,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Write Your Message (optional)',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                      ),
                                      onSubmitted: (_) => _sendCombinedMessage(),
                                    ),
                                  ),
                                  // Mic Button
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: _toggleVoiceDrawer,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: _showVoiceDrawer
                                              ? Colors.red.withOpacity(0.1)
                                              : _audioFile != null
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: Icon(
                                          _showVoiceDrawer
                                              ? Icons.mic
                                              : _audioFile != null
                                              ? Icons.mic
                                              : Icons.mic_none,
                                          color: _showVoiceDrawer
                                              ? Colors.red
                                              : _audioFile != null
                                              ? Colors.blue[700]
                                              : Colors.grey[600],
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _sendCombinedMessage,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: (_selectedImage != null || _audioFile != null || _messageController.text.isNotEmpty)
                                    ? const Color(0xFFE67E22)
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.send,
                                color: (_selectedImage != null || _audioFile != null || _messageController.text.isNotEmpty)
                                    ? Colors.white
                                    : Colors.grey[500],
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Voice Recording Drawer
                _buildVoiceDrawer(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVoiceDrawer() {
    const double drawerHeight = 450.0; // Slightly taller for tips

    if (_drawerAnimationController == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _drawerAnimationController!,
      builder: (context, child) {
        final double value = _drawerAnimationController!.value;
        final double bottom = -drawerHeight + (value * drawerHeight);

        return Positioned(
          left: 0,
          right: 0,
          bottom: bottom,
          child: Container(
            width: double.infinity,
            height: drawerHeight,
            decoration: const BoxDecoration(
              color: Color(0xFF2C3E2D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  _audioFile != null ? 'Audio Recorded!' : 'Voice Recording',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                // Recording tips
                if (!_isRecording && _audioFile == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'Tips for better recognition:\n• Speak clearly and slowly\n• Record in a quiet place\n• Hold phone close to your mouth',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const Spacer(),

                // Voice Amplifier Animation
                _buildVoiceAmplifier(),

                const SizedBox(height: 30),

                // Record Button
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? Colors.red
                          : _audioFile != null
                          ? Colors.green
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording
                          ? Icons.stop
                          : _audioFile != null
                          ? Icons.check
                          : Icons.mic,
                      color: _isRecording || _audioFile != null
                          ? Colors.white
                          : const Color(0xFF2C3E2D),
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Recording status
                Text(
                  _isRecording
                      ? 'Recording... Tap to stop'
                      : _audioFile != null
                      ? 'Ready to send'
                      : 'Tap to start recording',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                const Spacer(),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Clear recording button
                    if (_audioFile != null && !_isRecording)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _audioFile = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Recording cleared')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Clear',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Close Button
                    GestureDetector(
                      onTap: _toggleVoiceDrawer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceAmplifier() {
    if (_amplifierAnimationController == null) {
      return SizedBox(
        height: 60,
        child: _audioFile != null
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.audio_file,
              color: Colors.white.withOpacity(0.8),
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(
              'Audio ready to send',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        )
            : const SizedBox.shrink(),
      );
    }

    return AnimatedBuilder(
      animation: _amplifierAnimationController!,
      builder: (context, child) {
        return SizedBox(
          height: 60,
          child: _audioFile != null && !_isRecording
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.audio_file,
                color: Colors.white.withOpacity(0.8),
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                'Audio ready to send',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(15, (index) {
              final double animationValue = _isRecording
                  ? _amplifierAnimationController!.value
                  : 0.0;
              final double baseHeight = 4.0;
              final double maxHeight = 40.0;
              final double centerIndex = 7.0;
              final double distanceFromCenter = (index - centerIndex).abs();

              final double waveEffect = math.sin(
                  (animationValue * 2 * math.pi) + (index * 0.5));
              final double heightMultiplier = (1.0 -
                  (distanceFromCenter / 7.0)) * waveEffect;
              final double barHeight = baseHeight +
                  (maxHeight * heightMultiplier.abs() * animationValue);

              return Container(
                width: 3,
                height: math.max(baseHeight, barHeight),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(_isRecording ? 0.8 : 0.3),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isCurrentlySpeaking = _currentSpeakingMessageId == message.id && _isSpeaking;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // Bot Avatar
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/logo1.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          // Message Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: message.isLoading
                        ? Colors.grey[200]
                        : message.isError
                        ? Colors.red[50]
                        : message.isUser
                        ? const Color(0xFFE67E22)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: message.isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(5),
                      bottomRight: message.isUser
                          ? const Radius.circular(5)
                          : const Radius.circular(20),
                    ),
                    border: !message.isUser
                        ? Border.all(
                      color: message.isError
                          ? Colors.red[200]!
                          : Colors.grey[300]!,
                      width: 1,
                    )
                        : null,
                  ),
                  child: message.isLoading
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[600]!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        message.message,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text
                      Row(
                        children: [
                          if (message.isError)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.red[600],
                                size: 18,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              message.message,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: message.isError
                                    ? Colors.red[700]
                                    : message.isUser
                                    ? Colors.white
                                    : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // File indicators for user messages
                      if (message.isUser && (message.imageFile != null || message.audioFile != null))
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (message.imageFile != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.image, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Image',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (message.audioFile != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.audio_file, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Audio',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Enhanced TTS Controls for bot messages
                if (!message.isUser && !message.isLoading && !message.isError)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Listen/Stop Button
                        GestureDetector(
                          onTap: () => isCurrentlySpeaking
                              ? _stopTts()
                              : _speak(message.message, message.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCurrentlySpeaking
                                  ? Colors.red[100]
                                  : Colors.blue[100],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isCurrentlySpeaking
                                    ? Colors.red[300]!
                                    : Colors.blue[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCurrentlySpeaking
                                      ? Icons.stop
                                      : Icons.volume_up,
                                  size: 16,
                                  color: isCurrentlySpeaking
                                      ? Colors.red[700]
                                      : Colors.blue[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCurrentlySpeaking ? 'Stop' : 'Listen',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: isCurrentlySpeaking
                                        ? Colors.red[700]
                                        : Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Language indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.green[300]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            selectedLanguageGlobal,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if (message.isUser) ...[
            // User Avatar
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF9CAF88),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final File? imageFile;
  final File? audioFile; // Add this
  final bool isLoading;
  final bool isError;
  final String id;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.imageFile,
    this.audioFile, // Add this
    this.isLoading = false,
    this.isError = false,
    String? id,
  }) : id = id ?? 'msg_${DateTime.now().millisecondsSinceEpoch}';
}