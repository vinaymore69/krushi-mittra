import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:kisan_krushi/pages/profile.dart';
import 'dart:convert';
import 'dart:async';
import '../chat.dart';
import '../home.dart';
// import 'weather_alerts.dart';

// NewsArticle model class - Enhanced with better image handling
class NewsArticle {
  final String title;
  final String snippet;
  final String link;
  final String sourceName;
  final String thumbnail;
  final String date;

  NewsArticle({
    required this.title,
    required this.snippet,
    required this.link,
    required this.sourceName,
    required this.thumbnail,
    required this.date,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    // Handle nested source object
    String sourceName = 'Unknown';
    if (json['source'] != null) {
      if (json['source'] is String) {
        sourceName = json['source'];
      } else if (json['source'] is Map<String, dynamic>) {
        sourceName = json['source']['name'] ?? json['source']['title'] ?? 'Unknown';
      }
    }

    // Enhanced thumbnail extraction logic
    String thumbnail = '';

    // Try multiple possible thumbnail fields from SerpAPI
    if (json['thumbnail'] != null) {
      if (json['thumbnail'] is String) {
        thumbnail = json['thumbnail'];
      } else if (json['thumbnail'] is Map<String, dynamic>) {
        thumbnail = json['thumbnail']['url'] ??
            json['thumbnail']['src'] ??
            json['thumbnail']['href'] ?? '';
      }
    }

    // Try alternative image fields
    if (thumbnail.isEmpty) {
      thumbnail = json['image']?.toString() ??
          json['urlToImage']?.toString() ??
          json['imageUrl']?.toString() ??
          json['img']?.toString() ?? '';
    }

    // Try nested stories for Google News
    if (thumbnail.isEmpty && json['stories'] != null) {
      final stories = json['stories'] as List?;
      if (stories != null && stories.isNotEmpty) {
        final firstStory = stories[0] as Map<String, dynamic>?;
        if (firstStory?['thumbnail'] != null) {
          thumbnail = firstStory?['thumbnail']['url']?.toString() ??
              firstStory?['thumbnail']['src']?.toString() ?? '';
        }
      }
    }

    // Handle date - might be in different formats
    String date = DateTime.now().toString();
    if (json['date'] != null && json['date'] is String) {
      date = json['date'];
    } else if (json['published_date'] != null && json['published_date'] is String) {
      date = json['published_date'];
    } else if (json['publishedAt'] != null && json['publishedAt'] is String) {
      date = json['publishedAt'];
    }

    return NewsArticle(
      title: json['title']?.toString() ?? '',
      snippet: json['snippet']?.toString() ?? json['description']?.toString() ?? '',
      link: json['link']?.toString() ?? json['url']?.toString() ?? '',
      sourceName: sourceName,
      thumbnail: thumbnail,
      date: date,
    );
  }

  // Method to get a category-based fallback image when thumbnail is missing
  String getFallbackImageUrl() {
    final title = this.title.toLowerCase();
    final snippet = this.snippet.toLowerCase();
    final content = '$title $snippet';

    if (content.contains('yojana') || content.contains('scheme') || content.contains('government') || content.contains('pm kisan')) {
      return 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=250&fit=crop&crop=entropy'; // Government building
    } else if (content.contains('price') || content.contains('market') || content.contains('mandi') || content.contains('trading')) {
      return 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=250&fit=crop&crop=entropy'; // Market/trading
    } else if (content.contains('technology') || content.contains('drone') || content.contains('digital') || content.contains('app')) {
      return 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=400&h=250&fit=crop&crop=entropy'; // Technology/farming
    } else if (content.contains('weather') || content.contains('climate') || content.contains('monsoon') || content.contains('rain')) {
      return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=250&fit=crop&crop=entropy'; // Weather/clouds
    } else if (content.contains('crop') || content.contains('harvest') || content.contains('wheat') || content.contains('rice')) {
      return 'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=400&h=250&fit=crop&crop=entropy'; // Crops/harvest
    } else {
      return 'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=400&h=250&fit=crop&crop=entropy'; // General farming
    }
  }

  // Get the best available image URL
  String getImageUrl() {
    if (thumbnail.isNotEmpty && _isValidImageUrl(thumbnail)) {
      return thumbnail;
    }
    return getFallbackImageUrl();
  }

  // Validate if URL is a proper image URL
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme.startsWith('http') &&
          (url.toLowerCase().contains('.jpg') ||
              url.toLowerCase().contains('.jpeg') ||
              url.toLowerCase().contains('.png') ||
              url.toLowerCase().contains('.webp') ||
              url.contains('unsplash') ||
              url.contains('images'));
    } catch (e) {
      return false;
    }
  }

  String getFormattedDate() {
    try {
      final dateTime = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recent';
    }
  }

  // Method to create Google search URL for article
  String getGoogleSearchUrl() {
    final searchQuery = Uri.encodeComponent(title);
    return 'https://www.google.com/search?q=$searchQuery';
  }

  // Method to show link options to user
  void showLinkOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How would you like to read this article?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.open_in_new, color: Colors.blue),
              ),
              title: Text(
                'Open Original Article',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                link.isNotEmpty ? 'View on original website' : 'Link not available',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                if (link.isNotEmpty) {
                  _copyToClipboard(context, link, 'Article link copied!');
                } else {
                  _copyToClipboard(context, getGoogleSearchUrl(), 'Google search link copied!');
                }
              },
              enabled: true,
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.search, color: Colors.red),
              ),
              title: Text(
                'Search on Google',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Find this article on Google',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(context, getGoogleSearchUrl(), 'Google search link copied!');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Helper method to copy links to clipboard
  static void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFE67E22),
      ),
    );
  }
}

// NewsFilter model class
class NewsFilter {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> queries;

  NewsFilter({
    required this.name,
    required this.icon,
    required this.color,
    required this.queries,
  });
}

class FarmNewsPage extends StatefulWidget {
  const FarmNewsPage({super.key});

  @override
  State<FarmNewsPage> createState() => _FarmNewsPageState();
}

class _FarmNewsPageState extends State<FarmNewsPage> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  int _selectedFilterIndex = 0;
  List<NewsArticle> _newsArticles = [];
  List<NewsArticle> _filteredArticles = [];
  NewsArticle? _featuredNews;
  bool _isLoading = true;
  String _error = '';

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // SerpApi configuration
  static const String _apiKey = '539f6e6085b9479678ab9f8430016d84ea4a4bafb7c51328224ebc330c65a01f';
  static const String _baseUrl = 'https://serpapi.com/search.json';

  // Enhanced filter categories
  final List<NewsFilter> _filters = [
    NewsFilter(
      name: 'All News',
      icon: Icons.article,
      color: const Color(0xFFE67E22),
      queries: ['agriculture farming India', 'farming news India', 'crop prices India'],
    ),
    NewsFilter(
      name: 'Government Schemes',
      icon: Icons.account_balance,
      color: Colors.blue,
      queries: [
        'PM Kisan Yojana India',
        'Pradhan Mantri Fasal Bima Yojana',
        'PM Krishi Sinchai Yojana',
        'government agriculture scheme India',
        'farmer welfare scheme India',
      ],
    ),
    NewsFilter(
      name: 'Market & Prices',
      icon: Icons.trending_up,
      color: Colors.green,
      queries: [
        'crop prices India mandi',
        'agriculture market India',
        'MSP minimum support price India',
        'commodity prices India',
      ],
    ),
    NewsFilter(
      name: 'Technology',
      icon: Icons.precision_manufacturing,
      color: Colors.purple,
      queries: [
        'agriculture technology India',
        'farming drone India',
        'digital agriculture India',
        'AgriTech India',
      ],
    ),
    NewsFilter(
      name: 'Weather & Climate',
      icon: Icons.wb_sunny,
      color: Colors.orange,
      queries: [
        'weather forecast farming India',
        'monsoon agriculture India',
        'climate change farming India',
        'rainfall agriculture India',
      ],
    ),
    NewsFilter(
      name: 'Policies',
      icon: Icons.policy,
      color: Colors.indigo,
      queries: [
        'agriculture policy India',
        'farming laws India',
        'agricultural reforms India',
        'farmer bills India',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start the animation immediately
    _animationController.forward();
    _loadFarmNews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  Future<void> _loadFarmNews() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final articles = await _fetchNewsFromSerpApi();

      if (mounted) {
        setState(() {
          _newsArticles = articles;
          _filterArticles();
          if (articles.isNotEmpty) {
            _featuredNews = articles.first;
          }
          _isLoading = false;
        });

        // Only animate if the controller is still active
        if (_animationController.isCompleted || _animationController.isDismissed) {
          _animationController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load news: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _filterArticles() {
    if (_selectedFilterIndex == 0) {
      _filteredArticles = List.from(_newsArticles);
    } else {
      _filteredArticles = _newsArticles.where((article) {
        return _getCategoryForArticle(article) == _filters[_selectedFilterIndex].name;
      }).toList();

      if (_filteredArticles.isEmpty && _newsArticles.isNotEmpty) {
        _filteredArticles = _newsArticles.take(3).toList();
      }
    }
  }

  String _getCategoryForArticle(NewsArticle article) {
    final title = article.title.toLowerCase();
    final snippet = article.snippet.toLowerCase();
    final content = '$title $snippet';

    if (content.contains('yojana') || content.contains('scheme') ||
        content.contains('government') || content.contains('pm kisan') ||
        content.contains('pradhan mantri') || content.contains('ministry')) {
      return 'Government Schemes';
    } else if (content.contains('price') || content.contains('market') ||
        content.contains('mandi') || content.contains('msp') ||
        content.contains('commodity') || content.contains('trading')) {
      return 'Market & Prices';
    } else if (content.contains('technology') || content.contains('drone') ||
        content.contains('digital') || content.contains('app') ||
        content.contains('innovation') || content.contains('AI')) {
      return 'Technology';
    } else if (content.contains('weather') || content.contains('climate') ||
        content.contains('monsoon') || content.contains('rainfall') ||
        content.contains('temperature') || content.contains('season')) {
      return 'Weather & Climate';
    } else if (content.contains('policy') || content.contains('law') ||
        content.contains('reform') || content.contains('regulation') ||
        content.contains('bill') || content.contains('act')) {
      return 'Policies';
    }
    return 'All News';
  }

  Future<List<NewsArticle>> _fetchNewsFromSerpApi() async {
    try {
      final currentFilter = _filters[_selectedFilterIndex];
      final query = currentFilter.queries[DateTime.now().millisecond % currentFilter.queries.length];

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'engine': 'google_news',
        'q': query,
        'gl': 'in',
        'hl': 'en',
        'api_key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          final newsResults = data['news_results'] as List?;

          if (newsResults != null && newsResults.isNotEmpty) {
            List<NewsArticle> articles = [];

            for (var item in newsResults) {
              try {
                if (item is Map<String, dynamic>) {
                  articles.add(NewsArticle.fromJson(item));
                }
              } catch (e) {
                continue;
              }
            }

            if (articles.isNotEmpty) {
              return articles;
            }
          }
        }

        return _getSampleArticles();
      }

      throw Exception('Failed to load news data: ${response.statusCode}');
    } catch (e) {
      return _getSampleArticles();
    }
  }

  List<NewsArticle> _getSampleArticles() {
    return [
      NewsArticle(
        title: 'PM Kisan Yojana: Latest Updates for Farmers',
        snippet: 'Government announces new benefits under PM Kisan scheme for small and marginal farmers across India.',
        link: '',
        sourceName: 'Agriculture Ministry',
        thumbnail: 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=250&fit=crop',
        date: DateTime.now().subtract(const Duration(hours: 2)).toString(),
      ),
      NewsArticle(
        title: 'Crop Prices Rise in Major Mandis',
        snippet: 'Wheat and rice prices show upward trend in major agricultural markets across the country.',
        link: '',
        sourceName: 'Market Watch',
        thumbnail: 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=250&fit=crop',
        date: DateTime.now().subtract(const Duration(hours: 5)).toString(),
      ),
      NewsArticle(
        title: 'New Agriculture Technology for Small Farmers',
        snippet: 'Digital tools and modern farming techniques being introduced to help small-scale farmers increase productivity.',
        link: '',
        sourceName: 'Tech Agriculture',
        thumbnail: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=400&h=250&fit=crop',
        date: DateTime.now().subtract(const Duration(hours: 8)).toString(),
      ),
      NewsArticle(
        title: 'Monsoon Weather Update for Agriculture',
        snippet: 'Meteorological department forecasts good rainfall for upcoming farming season across multiple states.',
        link: '',
        sourceName: 'Weather Department',
        thumbnail: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=250&fit=crop',
        date: DateTime.now().subtract(const Duration(days: 1)).toString(),
      ),
    ];
  }

  Future<void> _refreshNews() async {
    if (mounted) {
      _animationController.reset();
      await _loadFarmNews();
    }
  }

  void _onFilterChanged(int index) {
    if (_selectedFilterIndex != index) {
      setState(() {
        _selectedFilterIndex = index;
        _isLoading = true;
      });
      _triggerHaptic();
      if (mounted) {
        _animationController.reset();
        _loadFarmNews();
      }
    }
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  void _showArticleDetails(NewsArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced image display with loading states
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            child: Image.network(
                              article.getImageUrl(),
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 220,
                                  color: Colors.grey[100],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: const Color(0xFFE67E22),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 220,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getCategoryColor(article).withOpacity(0.3),
                                        _getCategoryColor(article).withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.article,
                                          size: 50,
                                          color: _getCategoryColor(article),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'News Image',
                                          style: GoogleFonts.poppins(
                                            color: _getCategoryColor(article),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          article.title,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(article).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                article.sourceName,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getCategoryColor(article),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getCategoryForArticle(article),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              article.getFormattedDate(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          article.snippet,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Enhanced action buttons - Updated approach
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _triggerHaptic();
                                  Navigator.pop(context);
                                  article.showLinkOptions(context);
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Read Article'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getCategoryColor(article),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: _getCategoryColor(article)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  _triggerHaptic();
                                  Navigator.pop(context);
                                  NewsArticle._copyToClipboard(
                                      context,
                                      article.getGoogleSearchUrl(),
                                      'Google search link copied to clipboard!'
                                  );
                                },
                                icon: Icon(
                                  Icons.search,
                                  color: _getCategoryColor(article),
                                ),
                                tooltip: 'Copy Google Search Link',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Additional info card - Updated text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tap "Read Article" to get link options, or use the search button to copy Google search link to your clipboard.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
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
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterTabs(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshNews,
                color: const Color(0xFFE67E22),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(26),
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
                height: 70,
                decoration: BoxDecoration(
                  // borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage("assets/logo1.png"),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      // blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm News',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Stay updated with latest agriculture news',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  _triggerHaptic();
                  _refreshNews();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE67E22).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isLoading ? Icons.hourglass_empty : Icons.refresh,
                    color: const Color(0xFFE67E22),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = index == _selectedFilterIndex;

          return GestureDetector(
            onTap: () => _onFilterChanged(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(16),
              width: 100,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [filter.color, filter.color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? filter.color.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : filter.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      filter.icon,
                      color: isSelected ? Colors.white : filter.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    filter.name,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
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

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    } else if (_error.isNotEmpty) {
      return _buildErrorState();
    } else if (_filteredArticles.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildNewsContent();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE67E22),
                  const Color(0xFFE67E22).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Fetching latest ${_filters[_selectedFilterIndex].name.toLowerCase()}...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshNews,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.article_outlined,
                size: 40,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No news available',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pull down to refresh or try a different category',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_featuredNews != null && _selectedFilterIndex == 0) ...[
              _buildFeaturedNewsCard(_featuredNews!),
              const SizedBox(height: 32),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedFilterIndex == 0 ? 'Latest Updates' : _filters[_selectedFilterIndex].name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _filters[_selectedFilterIndex].color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_filteredArticles.length} articles',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _filters[_selectedFilterIndex].color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 1.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredArticles.length,
              itemBuilder: (context, index) {
                final article = _filteredArticles[index];
                return _buildEnhancedNewsCard(article, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () {
        _triggerHaptic();
        _showArticleDetails(article);
      },
      child: Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                child: Image.network(
                  article.getImageUrl(),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFFE67E22),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF9CAF88),
                            const Color(0xFF7A8A6A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.article,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'FEATURED',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            article.sourceName,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          article.getFormattedDate(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildEnhancedNewsCard(NewsArticle article, int index) {
    return GestureDetector(
      onTap: () {
        _triggerHaptic();
        _showArticleDetails(article);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      child: Image.network(
                        article.getImageUrl(),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                                color: _filters[_selectedFilterIndex].color,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _filters[_selectedFilterIndex].color.withOpacity(0.3),
                                  _filters[_selectedFilterIndex].color.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.article,
                                size: 40,
                                color: _filters[_selectedFilterIndex].color,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(article).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCategoryForArticle(article),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          article.title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          article.snippet,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              article.sourceName,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _filters[_selectedFilterIndex].color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            article.getFormattedDate(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(NewsArticle article) {
    final category = _getCategoryForArticle(article);
    switch (category) {
      case 'Government Schemes':
        return Colors.orange;
      case 'Market & Prices':
        return Colors.orange;
      case 'Technology':
        return Colors.orange;
      case 'Weather & Climate':
        return Colors.orange;
      case 'Policies':
        return Colors.orange;
      default:
        return const Color(0xFFE67E22);
    }
  }

  Widget _buildBottomNavigationBar() {
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
            icon: Icons.cloud_outlined,
            label: 'Profile',
            index: 3,
          ),
        ],
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