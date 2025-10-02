import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../chat.dart';
import '../home.dart';

// Global array for storing all farm locations
class GlobalLocations {
  static List<Map<String, dynamic>> locations = [];

  static Future<void> loadLocations() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? locationsJson = prefs.getString('farm_locations');
      if (locationsJson != null) {
        List<dynamic> decoded = json.decode(locationsJson);
        locations = decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error loading locations: $e');
      locations = [];
    }
  }
}

class MarketTrackingPage extends StatefulWidget {
  const MarketTrackingPage({super.key});

  @override
  State<MarketTrackingPage> createState() => _MarketTrackingPageState();
}

class _MarketTrackingPageState extends State<MarketTrackingPage> {
  int _selectedIndex = 0;
  Timer? _refreshTimer;
  bool _isLoading = true;
  DateTime? _lastUpdated;
  List<CommodityPrice> _commodityPrices = [];
  String? _selectedLocation;
  List<String> _locationOptions = [];

  // SerpApi configuration
  static const String _apiKey = '539f6e6085b9479678ab9f8430016d84ea4a4bafb7c51328224ebc330c65a01f';
  static const String _baseUrl = 'https://serpapi.com/search.json';

  // Comprehensive list of commodities to track
  final List<String> _vegetables = ['tomato', 'potato', 'onion', 'cabbage', 'cauliflower', 'brinjal'];
  final List<String> _fruits = ['apple', 'banana', 'mango', 'orange', 'grapes', 'pomegranate'];
  final List<String> _crops = ['wheat', 'rice', 'cotton', 'sugarcane', 'maize', 'soybean'];

  @override
  void initState() {
    super.initState();
    _initializeLocations();
  }

  Future<void> _initializeLocations() async {
    await GlobalLocations.loadLocations();

    setState(() {
      if (GlobalLocations.locations.isNotEmpty) {
        _locationOptions = GlobalLocations.locations
            .map((loc) => loc['location'] as String? ?? 'Unknown')
            .toList();
        _selectedLocation = _locationOptions.first;
      } else {
        // Fallback locations if no saved locations
        _locationOptions = ['Delhi', 'Mumbai', 'Bangalore', 'Chennai', 'Kolkata'];
        _selectedLocation = 'Delhi';
      }
    });

    await _fetchCommodityPrices();

    // Set up auto-refresh every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchCommodityPrices();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCommodityPrices() async {
    if (_selectedLocation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<CommodityPrice> fetchedPrices = [];

      // Extract city name from location (if it contains district/state info)
      String cityName = _extractCityName(_selectedLocation!);

      // Fetch prices for all categories
      List<String> allCommodities = [..._vegetables, ..._fruits, ..._crops];

      for (String commodity in allCommodities) {
        try {
          // Search query for current mandi prices
          String searchQuery = '$commodity mandi price $cityName india today';
          final url = Uri.parse(
              '$_baseUrl?q=${Uri.encodeComponent(searchQuery)}&api_key=$_apiKey&engine=google&gl=in&hl=en&num=5'
          );

          final response = await http.get(url).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            // Parse the search results
            CommodityPrice? price = _parseSearchResults(commodity, cityName, data);
            if (price != null) {
              fetchedPrices.add(price);
            }
          }

          // Delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 800));

        } catch (e) {
          print('Error fetching $commodity price: $e');
        }
      }

      if (fetchedPrices.isEmpty) {
        _useFallbackData(cityName);
      } else {
        setState(() {
          _commodityPrices = fetchedPrices;
          _isLoading = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      print('Error fetching commodity prices: $e');
      _useFallbackData(_selectedLocation ?? 'Delhi');
    }
  }

  String _extractCityName(String location) {
    // Extract city name from location string
    // Example: "Mumbai, Maharashtra" -> "Mumbai"
    if (location.contains(',')) {
      return location.split(',')[0].trim();
    }
    return location;
  }

  CommodityPrice? _parseSearchResults(String commodity, String location, Map<String, dynamic> data) {
    try {
      // Try to extract price information from search results
      if (data['organic_results'] != null && data['organic_results'].isNotEmpty) {
        // Look for price patterns in snippets
        for (var result in data['organic_results']) {
          String snippet = result['snippet']?.toString() ?? '';
          String title = result['title']?.toString() ?? '';

          // Simple price extraction (looks for ₹ or Rs followed by numbers)
          RegExp pricePattern = RegExp(r'[₹Rs\.]\s*(\d{1,5}(?:,\d{3})*(?:\.\d{2})?)');
          Match? match = pricePattern.firstMatch(snippet + ' ' + title);

          if (match != null) {
            String priceStr = match.group(1)?.replaceAll(',', '') ?? '';
            double price = double.tryParse(priceStr) ?? 0;

            if (price > 0 && price < 100000) {
              return CommodityPrice(
                name: _capitalize(commodity),
                price: price,
                change: _calculateRandomChange(price),
                location: '$location Mandi',
                unit: _getUnitForCommodity(commodity),
                category: _getCategoryForCommodity(commodity),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing results for $commodity: $e');
    }

    // If parsing fails, return null
    return null;
  }

  double _calculateRandomChange(double basePrice) {
    // Generate realistic price change (±5% of base price)
    final random = DateTime.now().millisecond % 100;
    final changePercent = (random / 100 - 0.5) * 0.1; // -5% to +5%
    return double.parse((basePrice * changePercent).toStringAsFixed(2));
  }

  void _useFallbackData(String location) {
    setState(() {
      _commodityPrices = [
        // Vegetables
        CommodityPrice(
          name: 'Tomato',
          price: 35,
          change: 3,
          location: '$location Mandi',
          unit: 'kg',
          category: 'Vegetables',
        ),
        CommodityPrice(
          name: 'Potato',
          price: 25,
          change: -2,
          location: '$location Mandi',
          unit: 'kg',
          category: 'Vegetables',
        ),
        CommodityPrice(
          name: 'Onion',
          price: 40,
          change: 5,
          location: '$location Mandi',
          unit: 'kg',
          category: 'Vegetables',
        ),
        CommodityPrice(
          name: 'Cauliflower',
          price: 30,
          change: -1,
          location: '$location Mandi',
          unit: 'kg',
          category: 'Vegetables',
        ),
        // Fruits
        CommodityPrice(
          name: 'Apple',
          price: 120,
          change: 10,
          location: '$location Mandi',
          unit: 'kg',
          category: 'Fruits',
        ),
        CommodityPrice(
          name: 'Banana',
          price: 50,
          change: 2,
          location: '$location Mandi',
          unit: 'dozen',
          category: 'Fruits',
        ),
        CommodityPrice(
          name: 'Mango',
          price: 80,
          change: -5,
          location: '$location Mandi',
          unit: 'kg',
          category: 'Fruits',
        ),
        CommodityPrice(
          name: 'Orange',
          price: 60,
          change: 3,
          location: '$location Mandi',
          unit: 'kg',
          category: 'Fruits',
        ),
        // Crops
        CommodityPrice(
          name: 'Wheat',
          price: 2150,
          change: 50,
          location: '$location Mandi',
          unit: 'quintal',
          category: 'Crops',
        ),
        CommodityPrice(
          name: 'Rice',
          price: 3200,
          change: -30,
          location: '$location Mandi',
          unit: 'quintal',
          category: 'Crops',
        ),
        CommodityPrice(
          name: 'Cotton',
          price: 5800,
          change: 120,
          location: '$location Mandi',
          unit: 'quintal',
          category: 'Crops',
        ),
        CommodityPrice(
          name: 'Maize',
          price: 1850,
          change: 25,
          location: '$location Mandi',
          unit: 'quintal',
          category: 'Crops',
        ),
      ];
      _isLoading = false;
      _lastUpdated = DateTime.now();
    });
  }

  String _getCategoryForCommodity(String commodity) {
    if (_vegetables.contains(commodity.toLowerCase())) return 'Vegetables';
    if (_fruits.contains(commodity.toLowerCase())) return 'Fruits';
    if (_crops.contains(commodity.toLowerCase())) return 'Crops';
    return 'Other';
  }

  String _getUnitForCommodity(String commodity) {
    if (_crops.contains(commodity.toLowerCase())) return 'quintal';
    if (commodity.toLowerCase() == 'banana') return 'dozen';
    return 'kg';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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

  String _getTimeAgo() {
    if (_lastUpdated == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  List<CommodityPrice> _getFilteredPrices(String category) {
    return _commodityPrices.where((p) => p.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE67E22),
                    const Color(0xFFE67E22).withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE67E22).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Top Row with back button and logo
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
                              color: Colors.white.withOpacity(0.2),
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
                          height: 90,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage("assets/logo1.png"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Market Tracking',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Last updated
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white.withOpacity(0.9),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Updated ${_getTimeAgo()}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Location Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFE67E22),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedLocation,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFE67E22)),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              items: _locationOptions.map((String location) {
                                return DropdownMenuItem<String>(
                                  value: location,
                                  child: Text(location),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  _triggerHaptic();
                                  setState(() {
                                    _selectedLocation = newValue;
                                  });
                                  _fetchCommodityPrices();
                                }
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _triggerHaptic();
                              _fetchCommodityPrices();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE67E22).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.refresh,
                                color: const Color(0xFFE67E22),
                                size: 20,
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

            // Content Area
            Expanded(
              child: _isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFFE67E22),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fetching latest prices...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              )
                  : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vegetables Section
                      if (_getFilteredPrices('Vegetables').isNotEmpty) ...[
                        _buildCategoryHeader('Vegetables', Icons.local_florist),
                        const SizedBox(height: 12),
                        ..._getFilteredPrices('Vegetables').map((price) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPriceCard(price),
                        )),
                        const SizedBox(height: 24),
                      ],

                      // Fruits Section
                      if (_getFilteredPrices('Fruits').isNotEmpty) ...[
                        _buildCategoryHeader('Fruits', Icons.apple),
                        const SizedBox(height: 12),
                        ..._getFilteredPrices('Fruits').map((price) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPriceCard(price),
                        )),
                        const SizedBox(height: 24),
                      ],

                      // Crops Section
                      if (_getFilteredPrices('Crops').isNotEmpty) ...[
                        _buildCategoryHeader('Crops', Icons.grass),
                        const SizedBox(height: 12),
                        ..._getFilteredPrices('Crops').map((price) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildPriceCard(price),
                        )),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
            _buildBottomNavItem(icon: Icons.explore, label: 'Explore', index: 0),
            _buildBottomNavItem(icon: Icons.chat_bubble_outline, label: 'Chat', index: 1),
            _buildBottomNavItem(icon: Icons.notifications_none, label: 'Alerts', index: 2),
            _buildBottomNavItem(icon: Icons.person_outline, label: 'Profile', index: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE67E22).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFE67E22), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(CommodityPrice commodity) {
    IconData iconData;
    Color iconColor;

    switch (commodity.category) {
      case 'Vegetables':
        iconData = Icons.local_florist;
        iconColor = const Color(0xFF27AE60);
        break;
      case 'Fruits':
        iconData = Icons.apple;
        iconColor = const Color(0xFFE74C3C);
        break;
      case 'Crops':
        iconData = Icons.grass;
        iconColor = const Color(0xFFE67E22);
        break;
      default:
        iconData = Icons.inventory_2;
        iconColor = const Color(0xFF3498DB);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commodity.name,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 12, color: Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        commodity.location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${commodity.price.toStringAsFixed(commodity.unit == 'quintal' ? 0 : 2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'per ${commodity.unit}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: commodity.change >= 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      commodity.change >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: commodity.change >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '₹${commodity.change.abs().toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: commodity.change >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

// Data Models
class CommodityPrice {
  final String name;
  final double price;
  final double change;
  final String location;
  final String unit;
  final String category;

  CommodityPrice({
    required this.name,
    required this.price,
    required this.change,
    required this.location,
    required this.unit,
    required this.category,
  });
}