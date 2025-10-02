import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../chat.dart';
import '../home.dart';
import 'farm_location.dart';
import 'package:flutter/gestures.dart';



class AllowMultipleGestureRecognizer extends PanGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}
class CropsRetailersPage extends StatefulWidget {
  const CropsRetailersPage({super.key});

  @override
  State<CropsRetailersPage> createState() => _CropsRetailersPageState();
}



class _CropsRetailersPageState extends State<CropsRetailersPage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _showMapView = false;
  bool _isLoading = false;

  // Map related variables
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  Set<Marker> _markers = {};

  // Retailers data - using cache to avoid redundant API calls
  List<Map<String, dynamic>> _nearbyRetailers = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // Cache for API results to optimize performance
  Map<String, List<Map<String, dynamic>>> _searchCache = {};
  DateTime? _lastSearchTime;

  // Location dropdown
  String? _selectedSavedLocation;
  LatLng? _currentSearchLocation;

  // Google Places API Key
  static const String _apiKey = 'AIzaSyCK7fJEms7Er2bCPxImt0-atqL2Oop4muo';

  // Search radius in meters
  static const int _searchRadius = 50000; // 50km

  // Banned keywords for filtering
  static const List<String> _bannedKeywords = [
    'hardware',
    'paints',
    'electrical',
    'plumbing',
    'sanitary',
    'cement',
    'tiles',
    'building',
    'construction'
  ];

  // Optimized search queries for crop buyers
  static const List<Map<String, String>> _searchQueries = [
    {'keyword': 'produce wholesaler', 'type': 'store'},
    {'keyword': 'agricultural cooperative', 'type': 'establishment'},
    {'keyword': 'farmers market', 'type': 'establishment'},
    {'keyword': 'crop buyer', 'type': 'establishment'},
    {'keyword': 'mandi', 'type': 'store'},
    {'keyword': 'grain merchant', 'type': 'store'},
    {'keyword': 'food processor', 'type': 'establishment'},
    {'keyword': 'produce distributor', 'type': 'store'},
    {'keyword': 'agri marketing', 'type': 'establishment'},
    {'keyword': 'vegetable wholesale market', 'type': 'store'},
  ];

  @override
  void initState() {
    super.initState();
    _loadGlobalLocations();
    _getCurrentLocationAndSearchRetailers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadGlobalLocations() async {
    await GlobalLocations.loadLocations();
    if (mounted) setState(() {});
  }

  Future<void> _getCurrentLocationAndSearchRetailers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      Position position = await Geolocator.getCurrentPosition();
      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      _currentSearchLocation = currentLocation;
      await _searchNearbyRetailers(currentLocation);

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error getting location: $e');
      }
    }
  }

  // Optimized search with caching and batching
  Future<void> _searchNearbyRetailers(LatLng location) async {
    if (!mounted) return;

    // Check cache validity (5 minutes)
    String cacheKey = '${location.latitude}_${location.longitude}';
    if (_searchCache.containsKey(cacheKey) &&
        _lastSearchTime != null &&
        DateTime.now().difference(_lastSearchTime!).inMinutes < 5) {
      setState(() {
        _nearbyRetailers = _searchCache[cacheKey]!;
        _isLoading = false;
      });
      _updateMapMarkers();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> allRetailers = [];
      Map<String, Map<String, dynamic>> uniqueRetailers = {};

      // Batch API calls with proper error handling
      List<Future<List<Map<String, dynamic>>>> searchFutures = [];

      for (var queryData in _searchQueries) {
        searchFutures.add(_performPlacesSearchWithType(
            location,
            queryData['keyword']!,
            queryData['type']!
        ));
      }

      // Execute searches in parallel for better performance
      List<List<Map<String, dynamic>>> results = await Future.wait(
          searchFutures,
          eagerError: false
      );

      for (var result in results) {
        allRetailers.addAll(result);
      }

      // If no specific results, try general search
      if (allRetailers.isEmpty) {
        List<Map<String, dynamic>> nearbyResults = await _performSimpleNearbySearch(location);
        allRetailers.addAll(nearbyResults);
      }

      // Remove duplicates efficiently
      for (var retailer in allRetailers) {
        String placeId = retailer['place_id'] ?? '';
        if (placeId.isNotEmpty && !uniqueRetailers.containsKey(placeId)) {
          uniqueRetailers[placeId] = retailer;
        }
      }

      // Calculate distances and filter
      List<Map<String, dynamic>> retailersWithDistance = [];
      for (var retailer in uniqueRetailers.values) {
        // Apply filtering before distance calculation
        if (_shouldFilterRetailer(retailer)) continue;

        double distance = _calculateDistance(
          location.latitude,
          location.longitude,
          retailer['latitude'],
          retailer['longitude'],
        );
        retailer['distance'] = distance;
        retailersWithDistance.add(retailer);
      }

      // Use sample data if no results
      if (retailersWithDistance.isEmpty) {
        retailersWithDistance = _getSampleRetailers(location);
      }

      // Sort by distance
      retailersWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));

      // Cache results
      _searchCache[cacheKey] = retailersWithDistance.take(20).toList();
      _lastSearchTime = DateTime.now();

      if (mounted) {
        setState(() {
          _nearbyRetailers = _searchCache[cacheKey]!;
          _isLoading = false;
        });

        _updateMapMarkers();
      }

    } catch (e) {
      print('Error searching retailers: $e');

      List<Map<String, dynamic>> sampleRetailers = _getSampleRetailers(location);

      if (mounted) {
        setState(() {
          _nearbyRetailers = sampleRetailers;
          _isLoading = false;
        });

        _updateMapMarkers();
        _showErrorSnackBar('Using sample data - API error');
      }
    }
  }

  // Filter function to exclude irrelevant retailers
  bool _shouldFilterRetailer(Map<String, dynamic> retailer) {
    String name = (retailer['name'] as String? ?? '').toLowerCase();
    List<String> types = (retailer['types'] as List<dynamic>? ?? [])
        .map((t) => t.toString().toLowerCase())
        .toList();

    // Check banned keywords
    for (String keyword in _bannedKeywords) {
      if (name.contains(keyword)) return true;
    }

    // Check specific banned types
    if (types.contains('hardware_store') ||
        types.contains('home_goods_store') ||
        types.contains('electronics_store')) {
      return true;
    }

    return false;
  }

  List<Map<String, dynamic>> _getSampleRetailers(LatLng location) {
    List<Map<String, dynamic>> sampleRetailers = [
      {
        'place_id': 'sample_1',
        'name': 'Green Valley Produce Buyers',
        'address': 'Main Market, Agricultural Area',
        'latitude': location.latitude + 0.01,
        'longitude': location.longitude + 0.01,
        'rating': 4.5,
        'types': ['store', 'establishment'],
        'isOpen': true,
      },
      {
        'place_id': 'sample_2',
        'name': 'Krishi Mandi Wholesale Market',
        'address': 'Village Market, Local Area',
        'latitude': location.latitude - 0.015,
        'longitude': location.longitude + 0.008,
        'rating': 4.2,
        'types': ['agricultural_store'],
        'isOpen': true,
      },
      {
        'place_id': 'sample_3',
        'name': 'Modern Agro Export Hub',
        'address': 'Industrial Area, Export Center',
        'latitude': location.latitude + 0.008,
        'longitude': location.longitude - 0.012,
        'rating': 4.7,
        'types': ['equipment_store'],
        'isOpen': false,
      },
      {
        'place_id': 'sample_4',
        'name': 'Farmers Cooperative Society',
        'address': 'Highway Junction, Collection Center',
        'latitude': location.latitude - 0.008,
        'longitude': location.longitude - 0.008,
        'rating': 4.0,
        'types': ['general_store'],
        'isOpen': true,
      },
    ];

    for (var retailer in sampleRetailers) {
      double distance = _calculateDistance(
        location.latitude,
        location.longitude,
        retailer['latitude'],
        retailer['longitude'],
      );
      retailer['distance'] = distance;
    }

    return sampleRetailers;
  }

  // Optimized API call with timeout and error handling
  Future<List<Map<String, dynamic>>> _performPlacesSearchWithType(
      LatLng location,
      String keyword,
      String type
      ) async {
    final newApiUrl = 'https://places.googleapis.com/v1/places:searchText';

    final requestBody = {
      "textQuery": "$keyword near me",
      "locationBias": {
        "circle": {
          "center": {
            "latitude": location.latitude,
            "longitude": location.longitude
          },
          "radius": _searchRadius.toDouble()
        }
      },
      "maxResultCount": 10,
      "includedType": type,
      "languageCode": "en"
    };

    try {
      final response = await http.post(
        Uri.parse(newApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.rating,places.priceLevel,places.currentOpeningHours,places.types,places.id'
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['places'] != null) {
          List<Map<String, dynamic>> retailers = [];

          for (var place in data['places']) {
            if (place['location'] != null) {
              retailers.add({
                'place_id': place['id'] ?? '',
                'name': place['displayName']?['text'] ?? 'Unknown Store',
                'address': place['formattedAddress'] ?? 'No address available',
                'latitude': place['location']['latitude'],
                'longitude': place['location']['longitude'],
                'rating': place['rating']?.toDouble() ?? 0.0,
                'types': place['types'] ?? [],
                'isOpen': place['currentOpeningHours']?['openNow'] ?? true,
                'price_level': place['priceLevel'] ?? 0,
              });
            }
          }

          return retailers;
        }
      }
    } catch (e) {
      print('API Exception for $keyword: $e');
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> _performSimpleNearbySearch(LatLng location) async {
    final nearbyUrl = 'https://places.googleapis.com/v1/places:searchNearby';

    final requestBody = {
      "includedPrimaryTypes": ["store", "establishment"],
      "maxResultCount": 20,
      "locationRestriction": {
        "circle": {
          "center": {
            "latitude": location.latitude,
            "longitude": location.longitude
          },
          "radius": _searchRadius.toDouble()
        }
      },
      "languageCode": "en"
    };

    try {
      final response = await http.post(
        Uri.parse(nearbyUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.rating,places.currentOpeningHours,places.types,places.id'
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['places'] != null) {
          List<Map<String, dynamic>> retailers = [];

          for (var place in data['places']) {
            if (place['location'] != null) {
              retailers.add({
                'place_id': place['id'] ?? '',
                'name': place['displayName']?['text'] ?? 'Unknown Store',
                'address': place['formattedAddress'] ?? 'No address available',
                'latitude': place['location']['latitude'],
                'longitude': place['location']['longitude'],
                'rating': place['rating']?.toDouble() ?? 0.0,
                'types': place['types'] ?? [],
                'isOpen': place['currentOpeningHours']?['openNow'] ?? true,
                'price_level': 0,
              });
            }
          }

          return retailers;
        }
      }
    } catch (e) {
      print('Nearby API Exception: $e');
    }

    return [];
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = _degreeToRadian(lat2 - lat1);
    double dLon = _degreeToRadian(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreeToRadian(lat1)) * math.cos(_degreeToRadian(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreeToRadian(double degree) {
    return degree * (math.pi / 180);
  }

  void _updateMapMarkers() {
    if (!mounted) return;

    Set<Marker> markers = {};

    if (_currentSearchLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentSearchLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    for (int i = 0; i < _nearbyRetailers.length; i++) {
      final retailer = _nearbyRetailers[i];
      markers.add(
        Marker(
          markerId: MarkerId('retailer_$i'),
          position: LatLng(retailer['latitude'], retailer['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: retailer['name'],
            snippet: '${retailer['distance'].toStringAsFixed(1)} km away',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  // Debounced search for location
  Timer? _searchDebounceTimer;

  Future<void> _searchLocations(String query) async {
    if (!mounted) return;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Start new timer
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      setState(() {
        _isSearching = true;
      });

      try {
        List<Location> locations = await locationFromAddress(query);
        List<Map<String, dynamic>> results = [];

        for (Location location in locations.take(5)) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              location.latitude,
              location.longitude,
            );

            if (placemarks.isNotEmpty) {
              Placemark place = placemarks.first;
              String address = _buildAddressString(place);
              results.add({
                'address': address,
                'latitude': location.latitude,
                'longitude': location.longitude,
              });
            }
          } catch (e) {
            print('Error getting placemark: $e');
          }
        }

        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        print('Error searching locations: $e');
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  String _buildAddressString(Placemark place) {
    List<String> addressParts = [];
    if (place.name != null && place.name!.isNotEmpty) addressParts.add(place.name!);
    if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
    if (place.country != null && place.country!.isNotEmpty) addressParts.add(place.country!);
    return addressParts.join(', ');
  }

  void _onMapTapped(LatLng location) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _selectedLocation = location;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = _buildAddressString(place);
        if (mounted) {
          setState(() {
            _selectedAddress = address;
          });
        }
      }

      _currentSearchLocation = location;
      await _searchNearbyRetailers(location);

    } catch (e) {
      print('Error getting address: $e');
      if (mounted) {
        setState(() {
          _selectedAddress = 'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        child: Column(
          children: [
            // Fixed Header
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

            // Fixed Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Crop Buyers',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_showMapView) ...[
                      // Location Selection Card
                      Container(
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
                            Text(
                              'Search Location',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Fixed Dropdown with proper visibility
                            if (GlobalLocations.locations.isNotEmpty) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedSavedLocation,
                                  isExpanded: true,
                                  menuMaxHeight: 300, // Fixed dropdown height
                                  decoration: InputDecoration(
                                    labelText: 'Select Saved Location',
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  dropdownColor: Colors.white, // Ensure dropdown background is white
                                  elevation: 8, // Add shadow to dropdown menu
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'Use Current Location',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    ...GlobalLocations.locations.map((location) {
                                      return DropdownMenuItem<String>(
                                        value: location['id'],
                                        child: Container(
                                          constraints: const BoxConstraints(maxWidth: 250),
                                          child: Text(
                                            location['name'] ?? 'Unknown Location',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (String? value) async {
                                    setState(() {
                                      _selectedSavedLocation = value;
                                    });

                                    if (value == null) {
                                      _getCurrentLocationAndSearchRetailers();
                                    } else {
                                      try {
                                        final selectedLocation = GlobalLocations.locations
                                            .firstWhere((loc) => loc['id'] == value);

                                        if (selectedLocation['latitude'] != null &&
                                            selectedLocation['longitude'] != null) {
                                          LatLng location = LatLng(
                                            selectedLocation['latitude'].toDouble(),
                                            selectedLocation['longitude'].toDouble(),
                                          );
                                          _currentSearchLocation = location;
                                          await _searchNearbyRetailers(location);
                                        }
                                      } catch (e) {
                                        print('Error selecting location: $e');
                                      }
                                    }
                                  },
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                            ],

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _getCurrentLocationAndSearchRetailers,
                                    icon: const Icon(Icons.my_location),
                                    label: Text(
                                      'Current Location',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9CAF88),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showMapView = true;
                                    });
                                  },
                                  icon: const Icon(Icons.map),
                                  label: Text(
                                    'Use Map',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE67E22),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Loading indicator
                      if (_isLoading) ...[
                        Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(
                                color: Color(0xFF9CAF88),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Finding nearby retailers...',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Debug info
                      if (!_isLoading) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Debug: Found ${_nearbyRetailers.length} retailers. Loading: $_isLoading',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Nearby Retailers List
                      if (_nearbyRetailers.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nearby Retailers (${_nearbyRetailers.length})',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showMapView = true;
                                });
                              },
                              icon: const Icon(Icons.map, size: 16),
                              label: Text(
                                'View Map',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _nearbyRetailers.length,
                          itemBuilder: (context, index) {
                            final retailer = _nearbyRetailers[index];
                            return _buildRetailerCard(retailer);
                          },
                        ),

                        const SizedBox(height: 24),
                      ],

                      // Benefits Section
                      if (!_isLoading) ...[
                        Text(
                          'Benefits',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildBenefitCard(
                          icon: Icons.location_on,
                          title: 'Nearest Retailers',
                          description: 'Find the closest agricultural stores and suppliers',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitCard(
                          icon: Icons.directions,
                          title: 'Distance & Directions',
                          description: 'Get accurate distance and navigation to retailers',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitCard(
                          icon: Icons.star,
                          title: 'Ratings & Reviews',
                          description: 'See ratings and reviews from other farmers',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitCard(
                          icon: Icons.store,
                          title: 'Store Information',
                          description: 'View store details, timings, and contact information',
                        ),
                      ],

                    ] else ...[



                      // Map View
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Column(
                          children: [
                            // Search and controls (keep this section as is)
                            Container(
                              padding: const EdgeInsets.all(16),
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
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: 'Search location...',
                                            border: InputBorder.none,
                                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                                          ),
                                          onChanged: (value) {
                                            _searchLocations(value);
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _getCurrentLocationAndSearchRetailers,
                                        icon: const Icon(Icons.my_location),
                                        color: const Color(0xFF9CAF88),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _showMapView = false;
                                          });
                                        },
                                        icon: const Icon(Icons.close),
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),

                                  // Search results
                                  if (_searchResults.isNotEmpty) ...[
                                    const Divider(),
                                    SizedBox(
                                      height: 120,
                                      child: ListView.builder(
                                        itemCount: _searchResults.length,
                                        itemBuilder: (context, index) {
                                          final result = _searchResults[index];
                                          return ListTile(
                                            dense: true,
                                            leading: const Icon(Icons.location_on, size: 16),
                                            title: Text(
                                              result['address'],
                                              style: GoogleFonts.poppins(fontSize: 12),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            onTap: () async {
                                              LatLng location = LatLng(
                                                result['latitude'].toDouble(),
                                                result['longitude'].toDouble(),
                                              );
                                              _onMapTapped(location);

                                              if (_mapController != null) {
                                                _mapController!.animateCamera(
                                                  CameraUpdate.newLatLngZoom(location, 15),
                                                );
                                              }

                                              setState(() {
                                                _searchResults = [];
                                                _searchController.clear();
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Map with gesture handling - THIS IS THE KEY FIX
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: RawGestureDetector(
                                    gestures: {
                                      // Allow all gestures to be handled by the map
                                      AllowMultipleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                                          AllowMultipleGestureRecognizer>(
                                            () => AllowMultipleGestureRecognizer(),
                                            (AllowMultipleGestureRecognizer instance) {},
                                      ),
                                    },
                                    child: GoogleMap(
                                      onMapCreated: (GoogleMapController controller) {
                                        _mapController = controller;
                                        if (_currentSearchLocation != null) {
                                          controller.animateCamera(
                                            CameraUpdate.newLatLngZoom(_currentSearchLocation!, 12),
                                          );
                                        }
                                      },
                                      initialCameraPosition: CameraPosition(
                                        target: _currentSearchLocation ?? const LatLng(20.5937, 78.9629),
                                        zoom: _currentSearchLocation != null ? 12 : 5,
                                      ),
                                      onTap: _onMapTapped,
                                      markers: _markers,
                                      myLocationEnabled: true,
                                      myLocationButtonEnabled: false,
                                      // Add these properties to handle gestures better
                                      gestureRecognizers: Set()
                                        ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
                                        ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()))
                                        ..add(Factory<TapGestureRecognizer>(() => TapGestureRecognizer()))
                                        ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()))
                                        ..add(Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer())),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            if (_isLoading) ...[
                              const SizedBox(height: 16),
                              const LinearProgressIndicator(
                                color: Color(0xFF9CAF88),
                              ),
                            ],
                          ],
                        ),
                      ),





                    ],

                    const SizedBox(height: 100), // Space for bottom navigation
                  ],
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

  Widget _buildRetailerCard(Map<String, dynamic> retailer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CAF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getRetailerIcon(retailer['types'] ?? []),
                  color: const Color(0xFF9CAF88),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      retailer['name'] ?? 'Unknown Store',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${retailer['distance']?.toStringAsFixed(1) ?? '0.0'} km away',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFE67E22),
                          ),
                        ),
                        const Spacer(),
                        if (retailer['rating'] != null && retailer['rating'] > 0) ...[
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            retailer['rating'].toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: retailer['isOpen'] == true ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            retailer['address'] ?? 'No address available',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to location
                    _navigateToRetailer(retailer);
                  },
                  icon: const Icon(Icons.directions, size: 16),
                  label: Text(
                    'Directions',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9CAF88),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  // Show more details
                  _showRetailerDetails(retailer);
                },
                icon: const Icon(Icons.info_outline, size: 16),
                label: Text(
                  'Details',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getRetailerIcon(List<dynamic> types) {
    for (String type in types.cast<String>()) {
      switch (type.toLowerCase()) {
        case 'store':
        case 'establishment':
          return Icons.store;
        case 'hardware_store':
          return Icons.hardware;
        case 'home_goods_store':
          return Icons.home;
        default:
          continue;
      }
    }
    return Icons.agriculture;
  }

  void _navigateToRetailer(Map<String, dynamic> retailer) {
    // This would integrate with navigation apps
    _triggerHaptic();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening directions to ${retailer['name']}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF9CAF88),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRetailerDetails(Map<String, dynamic> retailer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              retailer['name'] ?? 'Unknown Store',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  '${retailer['distance']?.toStringAsFixed(1) ?? '0.0'} km away',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFFE67E22),
                  ),
                ),
                const Spacer(),
                if (retailer['rating'] != null && retailer['rating'] > 0) ...[
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${retailer['rating'].toStringAsFixed(1)} rating',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Address',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              retailer['address'] ?? 'No address available',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Status',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: retailer['isOpen'] == true ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  retailer['isOpen'] == true ? 'Currently Open' : 'Currently Closed',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: retailer['isOpen'] == true ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToRetailer(retailer);
                },
                icon: const Icon(Icons.directions),
                label: Text(
                  'Get Directions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9CAF88),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF9CAF88).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF9CAF88),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
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
