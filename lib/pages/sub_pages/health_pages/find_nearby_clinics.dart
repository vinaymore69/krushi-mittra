import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../chat.dart';
import '../../home.dart';

class FarmClinicPage extends StatefulWidget {
  const FarmClinicPage({super.key});

  @override
  State<FarmClinicPage> createState() => _FarmClinicPageState();
}

class _FarmClinicPageState extends State<FarmClinicPage> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  // Map related variables
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _clinics = [];
  Map<String, dynamic>? _selectedClinic;

  // Filter options
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Veterinary Clinics',
    'Agricultural Centers',
    'Animal Hospitals',
    'Farm Consultants'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndSearch();
  }

  // Get current location and search for clinics
  Future<void> _getCurrentLocationAndSearch() async {
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
      LatLng location = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentLocation = location;
      });

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 13),
        );
      }

      // Search for clinics near current location
      await _searchClinicsNearby(location);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error getting location: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Search for clinics using Serper API
  Future<void> _searchClinicsNearby(LatLng location) async {
    const String apiKey = 'c098b6a72884590a0e9895b36502b52b7d989664';

    setState(() {
      _isLoading = true;
    });

    String searchQuery = _selectedFilter == 'All'
        ? 'veterinary clinic animal hospital agricultural center'
        : _selectedFilter.toLowerCase();

    try {
      final response = await http.post(
        Uri.parse('https://google.serper.dev/places'),
        headers: {
          'X-API-KEY': apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'q': searchQuery,
          'lat': location.latitude.toString(),
          'lon': location.longitude.toString(),
          'gl': 'in',
          'hl': 'en',
          'num': 20,
        }),
      );

      print('Search Query: $searchQuery');
      print('Location: ${location.latitude}, ${location.longitude}');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> clinics = [];
        Set<Marker> markers = {};

        if (data['places'] != null) {
          for (var place in data['places']) {
            // Handle different possible position formats
            double lat = 0.0;
            double lng = 0.0;

            if (place['latitude'] != null && place['longitude'] != null) {
              lat = (place['latitude'] is double) ? place['latitude'] : double.parse(place['latitude'].toString());
              lng = (place['longitude'] is double) ? place['longitude'] : double.parse(place['longitude'].toString());
            } else if (place['position'] != null && place['position'] is Map) {
              lat = (place['position']['lat'] is double) ? place['position']['lat'] : double.parse(place['position']['lat'].toString());
              lng = (place['position']['lng'] is double) ? place['position']['lng'] : double.parse(place['position']['lng'].toString());
            }

            if (lat != 0.0 && lng != 0.0) {

              Map<String, dynamic> clinic = {
                'name': place['title'] ?? 'Unknown Clinic',
                'address': place['address'] ?? 'Address not available',
                'latitude': lat,
                'longitude': lng,
                'rating': place['rating']?.toString() ?? 'N/A',
                'phone': place['phoneNumber'] ?? place['phone'] ?? 'Not available',
                'type': _determineClinicType(place['title'] ?? ''),
                'distance': _calculateDistance(
                  location.latitude,
                  location.longitude,
                  lat,
                  lng,
                ),
              };

              clinics.add(clinic);

              // Add marker
              markers.add(
                Marker(
                  markerId: MarkerId('clinic_$lat$lng'),
                  position: LatLng(lat, lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
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
          }

          // Sort by distance
          clinics.sort((a, b) => a['distance'].compareTo(b['distance']));
        }

        // Add current location marker
        if (_currentLocation != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: _currentLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: const InfoWindow(title: 'Your Location'),
            ),
          );
        }

        setState(() {
          _clinics = clinics;
          _markers = markers;
          _isLoading = false;
        });
      } else {
        throw 'Failed to fetch clinics';
      }
    } catch (e) {
      print('Error searching clinics: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error finding clinics: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Determine clinic type from name
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

  // Calculate distance between two coordinates (in km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // Show clinic details
  void _showClinicDetails(Map<String, dynamic> clinic) {
    setState(() {
      _selectedClinic = clinic;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildClinicDetailsSheet(clinic),
    );
  }

  // Build clinic details bottom sheet
  Widget _buildClinicDetailsSheet(Map<String, dynamic> clinic) {
    return Container(
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
          // Handle
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
                  // Type badge
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

                  // Name
                  Text(
                    clinic['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        clinic['rating'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Distance
                  _buildInfoRow(
                    Icons.location_on,
                    'Distance',
                    '${clinic['distance'].toStringAsFixed(2)} km away',
                  ),

                  const SizedBox(height: 16),

                  // Address
                  _buildInfoRow(
                    Icons.place,
                    'Address',
                    clinic['address'],
                  ),

                  const SizedBox(height: 16),

                  // Phone
                  _buildInfoRow(
                    Icons.phone,
                    'Phone',
                    clinic['phone'],
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Open maps for directions
                            final lat = clinic['latitude'];
                            final lng = clinic['longitude'];
                            // In real app, use url_launcher to open maps
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Opening directions to ${clinic['name']}',
                                  style: GoogleFonts.poppins(),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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
                            // Call clinic
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Calling ${clinic['name']}',
                                  style: GoogleFonts.poppins(),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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
                  'Farm Clinics',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Filter chips and Refresh button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
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
                                if (_currentLocation != null) {
                                  _searchClinicsNearby(_currentLocation!);
                                }
                              },
                              labelStyle: GoogleFonts.poppins(
                                fontSize: 12,  
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFF9CAF88),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF9CAF88)
                                      : Colors.black.withOpacity(0.1),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refresh button
                  GestureDetector(
                    onTap: () {
                      _triggerHaptic();
                      _getCurrentLocationAndSearch();
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Map and Clinic List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  // Map View
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
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
                          if (_currentLocation != null) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(_currentLocation!, 13),
                            );
                          }
                        },
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation ?? const LatLng(20.5937, 78.9629),
                          zoom: 13,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        onTap: (LatLng tappedLocation) async {
                          // When user taps on map, search clinics at that location
                          _triggerHaptic();
                          setState(() {
                            _currentLocation = tappedLocation;
                          });

                          // Move camera to tapped location
                          if (_mapController != null) {
                            await _mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(tappedLocation, 13),
                            );
                          }

                          // Search clinics at this new location
                          await _searchClinicsNearby(tappedLocation);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Searching clinics near this location...',
                                style: GoogleFonts.poppins(),
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Clinics List
                  Expanded(
                    child: _clinics.isEmpty
                        ? Center(
                      child: Text(
                        'No clinics found nearby',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Nearby Clinics (${_clinics.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _clinics.length,
                            itemBuilder: (context, index) {
                              final clinic = _clinics[index];
                              return _buildClinicCard(clinic);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
      // Bottom Navigation Bar
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

  Widget _buildClinicCard(Map<String, dynamic> clinic) {
    return GestureDetector(
      onTap: () => _showClinicDetails(clinic),
      child: Container(
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
        child: Row(
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
                    clinic['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        clinic['rating'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on, color: Colors.black54, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${clinic['distance'].toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black54,
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