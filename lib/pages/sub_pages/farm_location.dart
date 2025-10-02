import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  static Future<void> saveLocations() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String locationsJson = json.encode(locations);
      await prefs.setString('farm_locations', locationsJson);
    } catch (e) {
      print('Error saving locations: $e');
    }
  }

  static void addLocation(Map<String, dynamic> location) {
    // Check if location already exists (by coordinates)
    bool exists = locations.any((loc) =>
    (loc['latitude'] - location['latitude']).abs() < 0.0001 &&
        (loc['longitude'] - location['longitude']).abs() < 0.0001
    );

    if (!exists) {
      locations.add({
        ...location,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'dateAdded': DateTime.now().toIso8601String(),
      });
      saveLocations();
    }
  }

  static void removeLocation(String id) {
    locations.removeWhere((loc) => loc['id'] == id);
    saveLocations();
  }
}

class FarmLocationPage extends StatefulWidget {
  const FarmLocationPage({super.key});

  @override
  State<FarmLocationPage> createState() => _FarmLocationPageState();
}

class _FarmLocationPageState extends State<FarmLocationPage> {
  int _selectedIndex = 0;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationNameController = TextEditingController();
  bool _showMapView = false;
  bool _isLoading = false;

  // Map related variables
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  Set<Marker> _markers = {};

  // Search results
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadGlobalLocations();
  }

  // Load global locations
  Future<void> _loadGlobalLocations() async {
    await GlobalLocations.loadLocations();
    setState(() {});
  }

  // Search for locations using Google Places API
  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Using a simple geocoding approach for demo
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

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching locations: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  String _buildAddressString(Placemark place) {
    List<String> addressParts = [];
    if (place.name != null && place.name!.isNotEmpty) addressParts.add(place.name!);
    if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
    if (place.country != null && place.country!.isNotEmpty) addressParts.add(place.country!);
    return addressParts.join(', ');
  }

  // Handle map tap
  void _onMapTapped(LatLng location) async {
    setState(() {
      _isLoading = true;
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      };
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = _buildAddressString(place);

        setState(() {
          _selectedAddress = address;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedAddress = 'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
        _isLoading = false;
      });
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
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

      _onMapTapped(currentLocation);

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation, 15),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error getting current location: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  // Save location to global array
  void _saveLocationToGlobal() async {
    String locationName = _locationNameController.text.trim();
    String locationAddress = _locationController.text.trim();

    if (locationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a location name',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Map<String, dynamic> newLocation;

    if (_selectedLocation != null && _selectedAddress != null) {
      // Save with map coordinates
      newLocation = {
        'name': locationName,
        'address': _selectedAddress!,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'type': 'coordinates',
      };
    } else if (locationAddress.isNotEmpty) {
      // Save with manual address
      newLocation = {
        'name': locationName,
        'address': locationAddress,
        'type': 'manual',
      };
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a location or select on map',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    GlobalLocations.addLocation(newLocation);

    // Reset form
    _locationNameController.clear();
    _locationController.clear();
    _selectedLocation = null;
    _selectedAddress = null;
    _markers.clear();

    setState(() {
      _showMapView = false;
    });

    _triggerHaptic();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location "$locationName" saved successfully!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Remove location from global array
  void _removeLocation(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Location', style: GoogleFonts.poppins()),
        content: Text('Are you sure you want to remove "$name"?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              GlobalLocations.removeLocation(id);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Location removed successfully!',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text('Remove', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
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
                  'Farm Locations',
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
                    // Map View Toggle
                    if (!_showMapView) ...[
                      // Add New Location Card
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
                              'Add New Farm Location',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Location Name Field
                            TextField(
                              controller: _locationNameController,
                              decoration: InputDecoration(
                                labelText: 'Location Name',
                                hintText: 'e.g., Main Farm, North Field',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.black54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF9CAF88),
                                  ),
                                ),
                              ),
                              style: GoogleFonts.poppins(),
                            ),

                            const SizedBox(height: 16),

                            // Location Address Field
                            TextField(
                              controller: _locationController,
                              decoration: InputDecoration(
                                labelText: 'Address',
                                hintText: 'Village, District, State',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.black54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF9CAF88),
                                  ),
                                ),
                              ),
                              style: GoogleFonts.poppins(),
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _saveLocationToGlobal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9CAF88),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Save Location',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
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

                      // Saved Locations
                      if (GlobalLocations.locations.isNotEmpty) ...[
                        Text(
                          'Saved Locations (${GlobalLocations.locations.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: GlobalLocations.locations.length,
                          itemBuilder: (context, index) {
                            final location = GlobalLocations.locations[index];
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
                                      location['type'] == 'coordinates' ? Icons.location_on : Icons.place,
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
                                          location['name'] ?? 'Unknown Location',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          location['address'] ?? 'No address',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        if (location['type'] == 'coordinates') ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Lat: ${location['latitude']?.toStringAsFixed(4)}, Lng: ${location['longitude']?.toStringAsFixed(4)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black38,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeLocation(
                                      location['id'] ?? '',
                                      location['name'] ?? 'Unknown',
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                      ],

                      // Feature Benefits
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
                        icon: Icons.wb_sunny,
                        title: 'Weather Updates',
                        description: 'Get real-time weather information for your specific locations',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitCard(
                        icon: Icons.water_drop,
                        title: 'Rainfall Predictions',
                        description: 'Receive accurate rainfall forecasts to plan irrigation',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitCard(
                        icon: Icons.warning,
                        title: 'Weather Alerts',
                        description: 'Get notified about extreme weather conditions for all locations',
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitCard(
                        icon: Icons.map,
                        title: 'Multiple Locations',
                        description: 'Save and manage multiple farm locations with precise coordinates',
                      ),

                    ] else ...[
                      // Map View - Full Height Container
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Column(
                          children: [
                            // Search bar
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
                                        onPressed: _getCurrentLocation,
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
                                            onTap: () {
                                              LatLng location = LatLng(
                                                result['latitude'],
                                                result['longitude'],
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

                            // Map
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
                                  child: GoogleMap(
                                    onMapCreated: (GoogleMapController controller) {
                                      _mapController = controller;
                                      if (_selectedLocation != null) {
                                        controller.animateCamera(
                                          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
                                        );
                                      }
                                    },
                                    initialCameraPosition: CameraPosition(
                                      target: _selectedLocation ?? const LatLng(20.5937, 78.9629), // India center
                                      zoom: _selectedLocation != null ? 15 : 5,
                                    ),
                                    onTap: _onMapTapped,
                                    markers: _markers,
                                    myLocationEnabled: true,
                                    myLocationButtonEnabled: false,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Selected location info and save button
                            if (_selectedLocation != null) ...[
                              Container(
                                width: double.infinity,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selected Location',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_isLoading)
                                      const Center(child: CircularProgressIndicator())
                                    else ...[
                                      Text(
                                        _selectedAddress ?? 'Getting address...',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),

                                    // Location Name Field for Map Selection
                                    TextField(
                                      controller: _locationNameController,
                                      decoration: InputDecoration(
                                        labelText: 'Location Name',
                                        hintText: 'Enter a name for this location',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF9CAF88),
                                          ),
                                        ),
                                      ),
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),

                                    const SizedBox(height: 12),

                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _selectedAddress != null ? _saveLocationToGlobal : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF9CAF88),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Save This Location',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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

  Widget _buildCompactBenefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF9CAF88).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF9CAF88),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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