import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// Correct import
import '../../chat.dart';
import '../../home.dart';
import '../../sign_in.dart';

class MentalHealthSupportPage extends StatefulWidget {
  const MentalHealthSupportPage({super.key});

  @override
  State<MentalHealthSupportPage> createState() => _MentalHealthSupportPageState();
}

class _MentalHealthSupportPageState extends State<MentalHealthSupportPage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _selectedCategory = 'All';

  List<Map<String, dynamic>> _videos = [];
  Timer? _searchDebounceTimer;
  YoutubePlayerController? _youtubeController;
  String? _currentPlayingVideoId;

  // YouTube API Key - Replace with your actual API key
  static const String _youtubeApiKey = 'AIzaSyD0Qru74Hz5CfL6Jq4I5qSLnyBiHSDOLkY';

  Map<String, Map<String, String>> get _categories => {
    'All': {
      'en': 'mental health wellness mindfulness meditation',
      'hi': 'मानसिक स्वास्थ्य wellness ध्यान',
      'mr': 'मानसिक आरोग्य wellness ध्यान',
    },
    'Stress Management': {
      'en': 'stress management techniques relaxation yoga',
      'hi': 'तनाव प्रबंधन योग',
      'mr': 'तणाव व्यवस्थापन योग',
    },
    'Anxiety Relief': {
      'en': 'anxiety relief calm breathing exercises',
      'hi': 'चिंता राहत श्वास व्यायाम',
      'mr': 'चिंता मुक्ती श्वास व्यायाम',
    },
    'Mindfulness': {
      'en': 'mindfulness meditation guided relaxation',
      'hi': 'mindfulness ध्यान relaxation',
      'mr': 'mindfulness ध्यान relaxation',
    },
    'Depression Support': {
      'en': 'depression support mental health coping',
      'hi': 'अवसाद सहायता मानसिक स्वास्थ्य',
      'mr': 'नैराश्य समर्थन मानसिक आरोग्य',
    },
    'Sleep Hygiene': {
      'en': 'sleep hygiene better sleep relaxation',
      'hi': 'नींद स्वच्छता आराम',
      'mr': 'झोप स्वच्छता आराम',
    },
    'Emotional Wellness': {
      'en': 'emotional wellness self care mental health',
      'hi': 'भावनात्मक wellness self care',
      'mr': 'भावनिक wellness self care',
    },
    'Breathing Exercises': {
      'en': 'breathing exercises pranayama calm anxiety',
      'hi': 'श्वास व्यायाम प्राणायाम',
      'mr': 'श्वास व्यायाम प्राणायाम',
    },
  };

  String get _languageCode {
    final languageMap = {
      'English': 'en',
      'हिन्दी': 'hi',
      'मराठी': 'mr',
      'ਪੰਜਾਬੀ': 'pa',
      'ಕನ್ನಡ': 'kn',
      'தமிழ்': 'ta',
      'తెలుగు': 'te',
      'മലയാളം': 'ml',
      'ગુજરાતી': 'gu',
      'বাংলা': 'bn',
      'ଓଡ଼ିଆ': 'or',
      'اردو': 'ur',
    };
    return languageMap[selectedLanguageGlobal] ?? 'en';
  }

  @override
  void initState() {
    super.initState();
    _fetchVideos(_getCategoryQuery(_selectedCategory));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    _youtubeController?.dispose();
    super.dispose();
  }

  String _getCategoryQuery(String category) {
    final queries = _categories[category];
    if (queries == null) return 'mental health wellness mindfulness';
    return queries[_languageCode] ?? queries['en'] ?? 'mental health wellness';
  }

  Future<void> _fetchVideos(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _videos = [];
    });

    try {
      if (_youtubeApiKey == 'YOUR_YOUTUBE_API_KEY_HERE' || _youtubeApiKey.isEmpty) {
        throw 'Please configure your YouTube API key';
      }

      final safeQuery = '$query mental health wellness';
      final languageParam = _languageCode;

      final url = Uri.parse(
          'https://www.googleapis.com/youtube/v3/search?'
              'part=snippet&'
              'q=${Uri.encodeComponent(safeQuery)}&'
              'type=video&'
              'videoDuration=medium&'
              'safeSearch=strict&'
              'relevanceLanguage=$languageParam&'
              'maxResults=25&'
              'order=relevance&'
              'key=$_youtubeApiKey'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] != null && data['items'].isNotEmpty) {
          List<Map<String, dynamic>> videos = [];

          for (var item in data['items']) {
            final snippet = item['snippet'];
            final videoId = item['id']['videoId'];

            if (videoId == null || videoId.isEmpty) continue;

            final title = snippet['title'].toString().toLowerCase();
            final description = snippet['description'].toString().toLowerCase();

            if (_isRelevantMentalHealthContent(title, description)) {
              videos.add({
                'videoId': videoId,
                'title': snippet['title'],
                'description': snippet['description'] ?? 'No description available',
                'thumbnail': snippet['thumbnails']?['high']?['url'] ??
                    snippet['thumbnails']?['medium']?['url'] ??
                    'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                'channelTitle': snippet['channelTitle'] ?? 'Unknown Channel',
                'publishedAt': snippet['publishedAt'] ?? '',
              });
            }
          }

          if (mounted) {
            setState(() {
              _videos = videos;
              _isLoading = false;
            });
          }
        } else {
          throw 'No videos found';
        }
      } else if (response.statusCode == 403) {
        throw 'API key is invalid or quota exceeded';
      } else {
        throw 'Failed to fetch videos: HTTP ${response.statusCode}';
      }
    } catch (e) {
      print('Error fetching videos: $e');
      if (mounted) {
        setState(() {
          _videos = [];
          _isLoading = false;
        });
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  bool _isRelevantMentalHealthContent(String title, String description) {
    final mentalHealthKeywords = [
      'mental health', 'wellness', 'anxiety', 'depression', 'stress',
      'mindfulness', 'meditation', 'therapy', 'counseling', 'self care',
      'emotional', 'psychological', 'breathing', 'relaxation', 'calm',
      'coping', 'support', 'resilience', 'wellbeing', 'mental wellness',
      'yoga', 'pranayama', 'affirmation', 'healing', 'peace',
      'मानसिक स्वास्थ्य', 'तनाव', 'चिंता', 'अवसाद', 'ध्यान', 'योग',
      'मानसिक आरोग्य', 'तणाव', 'नैराश्य', 'प्राणायाम',
    ];

    final text = '$title $description'.toLowerCase();
    return mentalHealthKeywords.any((keyword) => text.contains(keyword.toLowerCase()));
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      _fetchVideos(_getCategoryQuery(_selectedCategory));
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _fetchVideos(query);
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
    });
    _fetchVideos(_getCategoryQuery(category));
  }

  void _playVideo(Map<String, dynamic> video) {
    final videoId = video['videoId'];

    _triggerHaptic();

    // Dispose previous controller if exists
    _youtubeController?.dispose();

    // Create new controller with proper fullscreen configuration
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
        hideControls: false,
        forceHD: false,
        // Critical for fullscreen
        useHybridComposition: true,
      ),
    );

    setState(() {
      _currentPlayingVideoId = videoId;
    });

    // Navigate to fullscreen page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _VideoPlayerPage(
          controller: _youtubeController!,
          video: video,
        ),
      ),
    ).then((_) {
      // Dispose controller when page is closed
      _youtubeController?.dispose();
      _youtubeController = null;
      setState(() {
        _currentPlayingVideoId = null;
      });
    });
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF9CAF88),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation - Unchanged
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mental Health Support',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search mental health topics...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF9CAF88)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Category chips
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _categories.keys.length,
                itemBuilder: (context, index) {
                  final category = _categories.keys.elementAt(index);
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) => _onCategoryChanged(category),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF9CAF88),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF9CAF88)
                              : Colors.black.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Videos list
            Expanded(
              child: _isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF9CAF88),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading videos...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
                  : _videos.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No videos found',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or category',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                itemCount: _videos.length,
                itemBuilder: (context, index) {
                  final video = _videos[index];
                  return _buildVideoCard(video);
                },
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation - Unchanged
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

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return GestureDetector(
      onTap: () => _playVideo(video),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video['thumbnail'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.video_library, size: 48),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF9CAF88),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Video info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          video['channelTitle'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
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

// Separate fullscreen video player page
class _VideoPlayerPage extends StatefulWidget {
  final YoutubePlayerController controller;
  final Map<String, dynamic> video;

  const _VideoPlayerPage({
    required this.controller,
    required this.video,
  });

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: widget.controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF9CAF88),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFF9CAF88),
          handleColor: Color(0xFFE67E22),
        ),
        onReady: () {
          print('Player is ready');
        },
        onEnded: (metadata) {
          print('Video ended');
          Navigator.pop(context);
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Video player
                player,

                // Video details
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.video['title'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9CAF88).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Color(0xFF9CAF88),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.video['channelTitle'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF9CAF88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Description',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.video['description'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE67E22).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE67E22).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFE67E22),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This content is for educational purposes. If you\'re experiencing mental health difficulties, please consult a healthcare professional.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
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
        );
      },
    );
  }
}