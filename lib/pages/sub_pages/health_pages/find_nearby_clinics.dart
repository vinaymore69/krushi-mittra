import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../../chat.dart';
import '../../home.dart';
import '../farm_location.dart';
import 'package:flutter/gestures.dart';

class AllowMultipleGestureRecognizer extends PanGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class FarmClinicPage extends StatefulWidget {
  const FarmClinicPage({super.key});

  @override
  State<FarmClinicPage> createState() => _FarmClinicPageState();
}

class _FarmClinicPageState extends State<FarmClinicPage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _showMapView = false;
  bool _isLoading = false;

  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  Set<Marker> _markers = {};

  List<Map<String, dynamic>> _nearbyClinics = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Map<String, List<Map<String, dynamic>>> _searchCache = {};
  DateTime? _lastSearchTime;

  String? _selectedSavedLocation;
  LatLng? _currentSearchLocation;

  static const String _apiKey = 'AIzaSyCK7fJEms7Er2bCPxImt0-atqL2Oop4muo';
  static const int _searchRadius = 50000;

  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Veterinary Clinics',
    'Agricultural Centers',
    'Animal Hospitals',
    'Farm Consultants'
  ];

  static const List<Map<String, String>> _searchQueries = [
    {'keyword': 'veterinary clinic', 'type': 'veterinary_care'},
    {'keyword': 'animal hospital', 'type': 'veterinary_care'},
    {'keyword': 'agricultural center', 'type': 'establishment'},
    {'keyword': 'farm consultant', 'type': 'establishment'},
    {'keyword': 'livestock clinic', 'type': 'veterinary_care'},
  ];

  @override
  void initState() {
    super.initState();
    _loadGlobalLocations();
    _getCurrentLocationAndSearchClinics();
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

  Future<void> _getCurrentLocationAndSearchClinics() async {
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentSearchLocation = currentLocation;
        });
      }

      await _searchNearbyClinics(currentLocation);

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error getting location: $e');
      }
    }
  }

  Future<void> _searchNearbyClinics(LatLng location) async {
    if (!mounted) return;

    String cacheKey = '${location.latitude}_${location.longitude}_$_selectedFilter';
    if (_searchCache.containsKey(cacheKey) &&
        _lastSearchTime != null &&
        DateTime.now().difference(_lastSearchTime!).inMinutes < 5) {
      setState(() {
        _nearbyClinics = _searchCache[cacheKey]!;
        _isLoading = false;
      });
      _updateMapMarkers();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> allClinics = [];
      Map<String, Map<String, dynamic>> uniqueClinics = {};

      List<Future<List<Map<String, dynamic>>>> searchFutures = [];

      for (var queryData in _searchQueries) {
        if (_selectedFilter != 'All') {
          if (_selectedFilter == 'Veterinary Clinics' && !queryData['keyword']!.contains('veterinary')) continue;
          if (_selectedFilter == 'Animal Hospitals' && !queryData['keyword']!.contains('hospital')) continue;
          if (_selectedFilter == 'Agricultural Centers' && !queryData['keyword']!.contains('agricultural')) continue;
          if (_selectedFilter == 'Farm Consultants' && !queryData['keyword']!.contains('consultant')) continue;
        }

        searchFutures.add(_performPlacesSearchWithType(
            location,
            queryData['keyword']!,
            queryData['type']!
        ));
      }

      List<List<Map<String, dynamic>>> results = await Future.wait(
          searchFutures,
          eagerError: false
      );

      for (var result in results) {
        allClinics.addAll(result);
      }

      if (allClinics.isEmpty) {
        List<Map<String, dynamic>> nearbyResults = await _performSimpleNearbySearch(location);
        allClinics.addAll(nearbyResults);
      }

      for (var clinic in allClinics) {
        String placeId = clinic['place_id'] ?? '';
        if (placeId.isNotEmpty && !uniqueClinics.containsKey(placeId)) {
          uniqueClinics[placeId] = clinic;
        }
      }

      List<Map<String, dynamic>> clinicsWithDistance = [];
      for (var clinic in uniqueClinics.values) {
        double distance = _calculateDistance(
          location.latitude,
          location.longitude,
          clinic['latitude'],
          clinic['longitude'],
        );
        clinic['distance'] = distance;
        clinicsWithDistance.add(clinic);
      }

      if (clinicsWithDistance.isEmpty) {
        clinicsWithDistance = _getSampleClinics(location);
      }

      clinicsWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));

      _searchCache[cacheKey] = clinicsWithDistance.take(20).toList();
      _lastSearchTime = DateTime.now();

      if (mounted) {
        setState(() {
          _nearbyClinics = _searchCache[cacheKey]!;
          _isLoading = false;
        });
        _updateMapMarkers();
      }

    } catch (e) {
      print('Error searching clinics: $e');

      List<Map<String, dynamic>> sampleClinics = _getSampleClinics(location);

      if (mounted) {
        setState(() {
          _nearbyClinics = sampleClinics;
          _isLoading = false;
        });
        _updateMapMarkers();
        _showErrorSnackBar('Using sample data - API error');
      }
    }
  }

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
          'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.rating,places.currentOpeningHours,places.types,places.id,places.nationalPhoneNumber'
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['places'] != null) {
          List<Map<String, dynamic>> clinics = [];

          for (var place in data['places']) {
            if (place['location'] != null) {
              clinics.add({
                'place_id': place['id'] ?? '',
                'name': place['displayName']?['text'] ?? 'Unknown Clinic',
                'address': place['formattedAddress'] ?? 'No address available',
                'latitude': place['location']['latitude'],
                'longitude': place['location']['longitude'],
                'rating': place['rating']?.toDouble() ?? 0.0,
                'phone': place['nationalPhoneNumber'] ?? 'Not available',
                'type': _determineClinicType(place['displayName']?['text'] ?? ''),
                'isOpen': place['currentOpeningHours']?['openNow'] ?? true,
              });
            }
          }

          return clinics;
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
      "includedPrimaryTypes": ["veterinary_care", "establishment"],
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
          'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.rating,places.currentOpeningHours,places.types,places.id,places.nationalPhoneNumber'
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['places'] != null) {
          List<Map<String, dynamic>> clinics = [];

          for (var place in data['places']) {
            if (place['location'] != null) {
              clinics.add({
                'place_id': place['id'] ?? '',
                'name': place['displayName']?['text'] ?? 'Unknown Clinic',
                'address': place['formattedAddress'] ?? 'No address available',
                'latitude': place['location']['latitude'],
                'longitude': place['location']['longitude'],
                'rating': place['rating']?.toDouble() ?? 0.0,
                'phone': place['nationalPhoneNumber'] ?? 'Not available',
                'type': _determineClinicType(place['displayName']?['text'] ?? ''),
                'isOpen': place['currentOpeningHours']?['openNow'] ?? true,
              });
            }
          }

          return clinics;
        }
      }
    } catch (e) {
      print('Nearby API Exception: $e');
    }

    return [];
  }

  List<Map<String, dynamic>> _getSampleClinics(LatLng location) {
    List<Map<String, dynamic>> sampleClinics = [
      {
        'place_id': 'sample_1',
        'name': 'Green Valley Veterinary Clinic',
        'address': 'Main Road, Agricultural Area',
        'latitude': location.latitude + 0.01,
        'longitude': location.longitude + 0.01,
        'rating': 4.5,
        'type': 'Veterinary',
        'phone': '+91 9876543210',
        'isOpen': true,
      },
      {
        'place_id': 'sample_2',
        'name': 'Animal Care Hospital',
        'address': 'Village Center, Local Area',
        'latitude': location.latitude - 0.015,
        'longitude': location.longitude + 0.008,
        'rating': 4.2,
        'type': 'Hospital',
        'phone': '+91 9876543211',
        'isOpen': true,
      },
      {
        'place_id': 'sample_3',
        'name': 'Agricultural Consultancy Center',
        'address': 'Highway Junction, Farm District',
        'latitude': location.latitude + 0.008,
        'longitude': location.longitude - 0.012,
        'rating': 4.7,
        'type': 'Agricultural',
        'phone': '+91 9876543212',
        'isOpen': false,
      },
      {
        'place_id': 'sample_4',
        'name': 'Farm Animal Clinic',
        'address': 'Rural Road, Veterinary Complex',
        'latitude': location.latitude - 0.008,
        'longitude': location.longitude - 0.008,
        'rating': 4.0,
        'type': 'Veterinary',
        'phone': '+91 9876543213',
        'isOpen': true,
      },
    ];

    for (var clinic in sampleClinics) {
      double distance = _calculateDistance(
        location.latitude,
        location.longitude,
        clinic['latitude'],
        clinic['longitude'],
      );
      clinic['distance'] = distance;
    }

    return sampleClinics;
  }

  String _determineClinicType(String name) {
    String lowerName = name.toLowerCase();
    if (lowerName.contains('veterinary') || lowerName.contains('vet')) {
      return 'Veterinary';
    } else if (lowerName.contains('hospital')) {
      return 'Hospital';
    } else if (lowerName.contains('agricultural') || lowerName.contains('farm')) {
      return 'Agricultural';
    } else if (lowerName.contains('consultant')) {
      return 'Consultant';
    }
    return 'Clinic';
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

    for (int i = 0; i < _nearbyClinics.length; i++) {
      final clinic = _nearbyClinics[i];
      markers.add(
        Marker(
          markerId: MarkerId('clinic_$i'),
          position: LatLng(clinic['latitude'], clinic['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: clinic['name'],
            snippet: '${clinic['distance'].toStringAsFixed(1)} km away',
          ),
          onTap: () {
            _showClinicDetails(clinic);
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });

      if (_mapController != null && _currentSearchLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentSearchLocation!, 12),
        );
      }
    }
  }

  Timer? _searchDebounceTimer;

  Future<void> _searchLocations(String query) async {
    if (!mounted) return;

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    _searchDebounceTimer?.cancel();

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
      await _searchNearbyClinics(location);

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

  void _showClinicDetails(Map<String, dynamic> clinic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CAF88).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        clinic['type'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CAF88),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      clinic['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (clinic['rating'] != null && clinic['rating'] > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            clinic['rating'].toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      Icons.location_on,
                      'Distance',
                      '${clinic['distance'].toStringAsFixed(2)} km away',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.place,
                      'Address',
                      clinic['address'],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.phone,
                      'Phone',
                      clinic['phone'],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showSnackBar('Opening directions to ${clinic['name']}');
                            },
                            icon: const Icon(Icons.directions),
                            label: Text(
                              'Directions',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9CAF88),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showSnackBar('Calling ${clinic['name']}');
                            },
                            icon: const Icon(Icons.call),
                            label: Text(
                              'Call',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE67E22),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF9CAF88).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF9CAF88),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF9CAF88),
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
                  'Farm Clinics',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            Expanded(
              child: _showMapView ? _buildMapView() : _buildListView(),
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

  Widget _buildListView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      menuMaxHeight: 300,
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
                      dropdownColor: Colors.white,
                      elevation: 8,
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
                          _getCurrentLocationAndSearchClinics();
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
                              await _searchNearbyClinics(location);
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

                  SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterOptions.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedFilter == _filterOptions[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_filterOptions[index]),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = _filterOptions[index];
                              });
                              if (_currentSearchLocation != null) {
                                _searchNearbyClinics(_currentSearchLocation!);
                              }
                            },
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF9CAF88),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _getCurrentLocationAndSearchClinics,
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

          if (_isLoading) ...[
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF9CAF88),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Finding nearby clinics...',
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

          if (_nearbyClinics.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Clinics (${_nearbyClinics.length})',
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
              itemCount: _nearbyClinics.length,
              itemBuilder: (context, index) {
                final clinic = _nearbyClinics[index];
                return _buildClinicCard(clinic);
              },
            ),

            const SizedBox(height: 24),
          ],

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
              icon: Icons.local_hospital,
              title: 'Find Veterinary Care',
              description: 'Locate the nearest veterinary clinics and animal hospitals',
            ),
            const SizedBox(height: 12),
            _buildBenefitCard(
              icon: Icons.directions,
              title: 'Get Directions',
              description: 'Navigate to clinics with accurate distance and routes',
            ),
            const SizedBox(height: 12),
            _buildBenefitCard(
              icon: Icons.star,
              title: 'Ratings & Reviews',
              description: 'Check ratings and reviews from other farmers',
            ),
            const SizedBox(height: 12),
            _buildBenefitCard(
              icon: Icons.phone,
              title: 'Contact Information',
              description: 'Get phone numbers and clinic details instantly',
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
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
                      onPressed: _getCurrentLocationAndSearchClinics,
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
        ),

        const SizedBox(height: 16),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
                    target: _currentSearchLocation ?? const LatLng(19.0760, 72.8777),
                    zoom: _currentSearchLocation != null ? 12 : 11,
                  ),
                  onTap: _onMapTapped,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: LinearProgressIndicator(
              color: Color(0xFF9CAF88),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildClinicCard(Map<String, dynamic> clinic) {
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
                child: const Icon(
                  Icons.local_hospital,
                  color: Color(0xFF9CAF88),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic['name'] ?? 'Unknown Clinic',
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
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${clinic['distance']?.toStringAsFixed(1) ?? '0.0'} km away',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFE67E22),
                          ),
                        ),
                        const Spacer(),
                        if (clinic['rating'] != null && clinic['rating'] > 0) ...[
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            clinic['rating'].toStringAsFixed(1),
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
                  color: clinic['isOpen'] == true ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            clinic['address'] ?? 'No address available',
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
                    _navigateToClinic(clinic);
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
                  _showClinicDetails(clinic);
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

  void _navigateToClinic(Map<String, dynamic> clinic) {
    _triggerHaptic();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening directions to ${clinic['name']}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF9CAF88),
        behavior: SnackBarBehavior.floating,
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