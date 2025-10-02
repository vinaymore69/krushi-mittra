import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../chat.dart';
import '../home.dart';

class WeatherAlertsPage extends StatefulWidget {
  const WeatherAlertsPage({super.key});

  @override
  State<WeatherAlertsPage> createState() => _WeatherAlertsPageState();
}

class _WeatherAlertsPageState extends State<WeatherAlertsPage> {
  int _selectedIndex = 0;

  // Weather data variables
  Map<String, dynamic>? currentWeather;
  List<Map<String, dynamic>> weatherAlerts = [];
  bool isLoading = true;
  String? errorMessage;
  String? locationName;

  // New variables for data persistence
  DateTime? lastSuccessfulUpdate;
  bool isRefreshing = false;
  String? refreshErrorMessage;

  // OpenWeatherMap API key
  static const String apiKey = '7d6d4928cb40dbb300568669c4fd1b79';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData({bool isManualRefresh = false}) async {
    try {
      setState(() {
        if (isManualRefresh) {
          isRefreshing = true;
          refreshErrorMessage = null;
        } else {
          isLoading = true;
          errorMessage = null;
        }
      });

      // Get location
      Position position = await _getCurrentLocation();

      // Fetch current weather
      await _fetchCurrentWeather(position.latitude, position.longitude);

      // Fetch weather alerts
      await _fetchWeatherAlerts(position.latitude, position.longitude);

      // Update last successful update time
      setState(() {
        lastSuccessfulUpdate = DateTime.now();
      });

    } catch (e) {
      setState(() {
        if (isManualRefresh) {
          // Keep existing data, just show refresh error
          refreshErrorMessage = e.toString();
          isRefreshing = false;
        } else {
          // Initial load failed
          errorMessage = e.toString();
          isLoading = false;
        }
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    // Check permissions
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

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _fetchCurrentWeather(double lat, double lon) async {
    try {
      // Fetch current weather
      final weatherResponse = await http.get(
        Uri.parse('$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
      );

      if (weatherResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);

        // Fetch more accurate location name using reverse geocoding
        try {
          final geoResponse = await http.get(
            Uri.parse('http://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey'),
          );

          if (geoResponse.statusCode == 200) {
            final geoData = json.decode(geoResponse.body);
            if (geoData.isNotEmpty) {
              String locationDisplay = '';

              // Build location name with preference for city name
              if (geoData[0]['name'] != null && geoData[0]['name'].toString().isNotEmpty) {
                locationDisplay = geoData[0]['name'];
              }

              // Add state/region if different from city name
              if (geoData[0]['state'] != null &&
                  geoData[0]['state'] != geoData[0]['name'] &&
                  geoData[0]['state'].toString().isNotEmpty) {
                locationDisplay += locationDisplay.isNotEmpty ? ', ${geoData[0]['state']}' : geoData[0]['state'];
              }

              // Add country if needed
              if (geoData[0]['country'] != null && geoData[0]['country'].toString().isNotEmpty) {
                locationDisplay += locationDisplay.isNotEmpty ? ', ${geoData[0]['country']}' : geoData[0]['country'];
              }

              setState(() {
                currentWeather = weatherData;
                locationName = locationDisplay.isNotEmpty ? locationDisplay : weatherData['name'];
              });
            } else {
              // Fallback to weather API location name
              setState(() {
                currentWeather = weatherData;
                locationName = weatherData['name'];
              });
            }
          } else {
            // Fallback to weather API location name if geocoding fails
            setState(() {
              currentWeather = weatherData;
              locationName = weatherData['name'];
            });
          }
        } catch (e) {
          // If geocoding fails, use weather API location name
          print('Geocoding error: $e');
          setState(() {
            currentWeather = weatherData;
            locationName = weatherData['name'];
          });
        }

      } else {
        throw 'Failed to load weather data: ${weatherResponse.statusCode}';
      }
    } catch (e) {
      throw 'Error fetching current weather: $e';
    }
  }

  Future<void> _fetchWeatherAlerts(double lat, double lon) async {
    try {
      // Fetch 5-day forecast to generate alerts
      final response = await http.get(
        Uri.parse('$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> alerts = _generateAlertsFromForecast(data);

        setState(() {
          weatherAlerts = alerts;
          isLoading = false;
          isRefreshing = false;
        });
      } else {
        throw 'Failed to load forecast data: ${response.statusCode}';
      }
    } catch (e) {
      setState(() {
        if (weatherAlerts.isEmpty) {
          weatherAlerts = _getDefaultAlerts(); // Fallback to default alerts only if no previous data
        }
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateAlertsFromForecast(Map<String, dynamic> forecastData) {
    List<Map<String, dynamic>> alerts = [];
    List<dynamic> forecastList = forecastData['list'];

    for (int i = 0; i < forecastList.length && i < 8; i++) {
      var forecast = forecastList[i];
      var main = forecast['main'];
      var weather = forecast['weather'][0];
      var wind = forecast['wind'];

      // Temperature alerts
      if (main['temp'] > 35) {
        alerts.add({
          'icon': Icons.wb_sunny,
          'title': 'Heat Wave Alert',
          'description': 'Temperature expected to reach ${main['temp'].round()}°C. Ensure adequate irrigation and shade for crops.',
          'time': _getTimeFromNow(i * 3),
          'priority': 'High',
          'color': Colors.red,
        });
      } else if (main['temp'] < 5) {
        alerts.add({
          'icon': Icons.ac_unit,
          'title': 'Cold Wave Warning',
          'description': 'Temperature may drop to ${main['temp'].round()}°C. Protect sensitive crops from frost.',
          'time': _getTimeFromNow(i * 3),
          'priority': 'High',
          'color': Colors.blue,
        });
      }

      // Rain alerts
      if (forecast.containsKey('rain') && forecast['rain'].containsKey('3h')) {
        double rainfall = forecast['rain']['3h'];
        if (rainfall > 10) {
          alerts.add({
            'icon': Icons.water_drop,
            'title': 'Heavy Rain Alert',
            'description': 'Heavy rainfall (${rainfall.toStringAsFixed(1)}mm) expected. Consider drainage for crops.',
            'time': _getTimeFromNow(i * 3),
            'priority': rainfall > 25 ? 'High' : 'Medium',
            'color': Colors.blue,
          });
        }
      }

      // Wind alerts
      if (wind['speed'] > 10) {
        alerts.add({
          'icon': Icons.air,
          'title': 'Strong Wind Warning',
          'description': 'Wind speeds up to ${(wind['speed'] * 3.6).round()} km/h expected. Secure loose structures.',
          'time': _getTimeFromNow(i * 3),
          'priority': wind['speed'] > 15 ? 'High' : 'Medium',
          'color': Colors.orange,
        });
      }

      // Humidity alerts
      if (main['humidity'] > 80) {
        alerts.add({
          'icon': Icons.cloud,
          'title': 'High Humidity Alert',
          'description': 'Humidity levels at ${main['humidity']}%. Monitor for fungal diseases in crops.',
          'time': _getTimeFromNow(i * 3),
          'priority': 'Medium',
          'color': Colors.teal,
        });
      }
    }

    // Remove duplicates and limit to 4 most important alerts
    var uniqueAlerts = alerts.toSet().toList();
    uniqueAlerts.sort((a, b) => _getPriorityValue(a['priority']).compareTo(_getPriorityValue(b['priority'])));
    return uniqueAlerts.take(4).toList();
  }

  int _getPriorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return 1;
      case 'medium': return 2;
      case 'low': return 3;
      default: return 4;
    }
  }

  String _getTimeFromNow(int hours) {
    if (hours == 0) return 'Now';
    if (hours < 24) return '${hours}h from now';
    return '${(hours / 24).round()}d from now';
  }

  List<Map<String, dynamic>> _getDefaultAlerts() {
    return [
      {
        'icon': Icons.warning,
        'title': 'Weather Alert System',
        'description': 'Weather alerts will appear here based on current conditions and forecasts.',
        'time': 'System message',
        'priority': 'Low',
        'color': Colors.grey,
      },
    ];
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

  String _getWeatherIcon(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear': return '☀️';
      case 'clouds': return '☁️';
      case 'rain': return '🌧️';
      case 'drizzle': return '🌦️';
      case 'thunderstorm': return '⛈️';
      case 'snow': return '❄️';
      case 'mist':
      case 'fog': return '🌫️';
      default: return '🌤️';
    }
  }

  IconData _getWeatherIconData(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear': return Icons.wb_sunny;
      case 'clouds': return Icons.cloud;
      case 'rain': return Icons.grain;
      case 'drizzle': return Icons.grain;
      case 'thunderstorm': return Icons.flash_on;
      case 'snow': return Icons.ac_unit;
      case 'mist':
      case 'fog': return Icons.cloud_queue;
      default: return Icons.wb_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
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

              const SizedBox(height: 30),

              // Title with location
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weather Alerts',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (locationName != null)
                      Text(
                        locationName!,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Refresh button and last update info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Last update time
                  if (lastSuccessfulUpdate != null)
                    Text(
                      'Updated ${_formatLastUpdateTime(lastSuccessfulUpdate!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),

                  // Refresh button
                  GestureDetector(
                    onTap: () {
                      _triggerHaptic();
                      _fetchWeatherData(isManualRefresh: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isRefreshing ? Colors.grey : const Color(0xFFE67E22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isRefreshing)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 16,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            isRefreshing ? 'Refreshing...' : 'Refresh',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Show refresh error if any
              if (refreshErrorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to refresh. Showing last available data.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            refreshErrorMessage = null;
                          });
                        },
                        child: Icon(Icons.close, color: Colors.red, size: 16),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E22)),
                  ),
                )
                    : errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading weather data',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _fetchWeatherData(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE67E22),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Current Weather Card
                      if (currentWeather != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9CAF88), Color(0xFF7A8A6A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Weather',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    _getWeatherIconData(currentWeather!['weather'][0]['main']),
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${currentWeather!['main']['temp'].round()}°C',
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          currentWeather!['weather'][0]['description']
                                              .toString()
                                              .split(' ')
                                              .map((word) => word[0].toUpperCase() + word.substring(1))
                                              .join(' '),
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildWeatherDetail('Feels like', '${currentWeather!['main']['feels_like'].round()}°C'),
                                  const SizedBox(width: 20),
                                  _buildWeatherDetail('Humidity', '${currentWeather!['main']['humidity']}%'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildWeatherDetail('Wind', '${(currentWeather!['wind']['speed'] * 3.6).round()} km/h'),
                                  const SizedBox(width: 20),
                                  _buildWeatherDetail('Pressure', '${currentWeather!['main']['pressure']} hPa'),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Alert Cards
                      if (weatherAlerts.isNotEmpty)
                        ...weatherAlerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildAlertCard(
                            icon: alert['icon'],
                            title: alert['title'],
                            description: alert['description'],
                            time: alert['time'],
                            priority: alert['priority'],
                            color: alert['color'],
                          ),
                        ))
                      else
                        _buildAlertCard(
                          icon: Icons.check_circle_outline,
                          title: 'No Active Alerts',
                          description: 'Weather conditions are normal. No alerts at this time.',
                          time: 'Current status',
                          priority: 'Low',
                          color: Colors.green,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  // Helper method to format last update time
  String _formatLastUpdateTime(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required String priority,
    required Color color,
  }) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getPriorityColor(priority),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
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