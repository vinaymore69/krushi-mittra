import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Timer? _timer;
  List<NotificationModel> _notifications = [];
  Set<int> _processedIds = {};

  static const String _baseUrl = 'https://maha-krushi-mittra.vercel.app';
  static const String _notificationUrl = '$_baseUrl/notification.json';
  static const Duration _checkInterval = Duration(seconds: 30);

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Initialize the notification service
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _loadStoredNotifications();
    await _loadProcessedIds();
    _startPeriodicCheck();
    debugPrint('NotificationService initialized');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final id = int.tryParse(response.payload ?? '');
    if (id != null) {
      markAsRead(id);
    }
    debugPrint('Notification tapped with payload: ${response.payload}');
  }

  // Start periodic checking for new notifications
  void _startPeriodicCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, (_) => _fetchAndProcessNotifications());
    debugPrint('Started periodic notification checking every ${_checkInterval.inSeconds} seconds');
  }

  // Fetch notifications from server
  Future<void> _fetchAndProcessNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(_notificationUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notificationsJson = data['notifications'] ?? [];

        final serverNotifications = notificationsJson
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        await _processNewNotifications(serverNotifications);
      } else {
        debugPrint('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  // Process new notifications
  Future<void> _processNewNotifications(List<NotificationModel> serverNotifications) async {
    final newNotifications = serverNotifications
        .where((notification) => !_processedIds.contains(notification.id))
        .toList();

    if (newNotifications.isNotEmpty) {
      // Add new notifications to local list
      _notifications.addAll(newNotifications);

      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Update processed IDs
      for (final notification in newNotifications) {
        _processedIds.add(notification.id);
        await _showLocalNotification(notification);
      }

      // Save to storage
      await _saveNotifications();
      await _saveProcessedIds();

      notifyListeners();
      debugPrint('Processed ${newNotifications.length} new notifications');
    }
  }

  // Show local push notification
  Future<void> _showLocalNotification(NotificationModel notification) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'maha_krushi_notifications',
      'Maha Krushi Mittra Notifications',
      channelDescription: 'Notifications from Maha Krushi Mittra',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id,
      notification.title,
      notification.message,
      details,
      payload: notification.id.toString(),
    );
  }

  // Load stored notifications from local storage
  Future<void> _loadStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('stored_notifications');

      if (notificationsJson != null) {
        final List<dynamic> decoded = json.decode(notificationsJson);
        _notifications = decoded
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        // Sort by timestamp (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        debugPrint('Loaded ${_notifications.length} stored notifications');
      }
    } catch (e) {
      debugPrint('Error loading stored notifications: $e');
    }
  }

  // Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = json.encode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString('stored_notifications', notificationsJson);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  // Load processed notification IDs
  Future<void> _loadProcessedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final processedIdsJson = prefs.getString('processed_notification_ids');

      if (processedIdsJson != null) {
        final List<dynamic> decoded = json.decode(processedIdsJson);
        _processedIds = decoded.cast<int>().toSet();
        debugPrint('Loaded ${_processedIds.length} processed notification IDs');
      }
    } catch (e) {
      debugPrint('Error loading processed IDs: $e');
    }
  }

  // Save processed notification IDs
  Future<void> _saveProcessedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final processedIdsJson = json.encode(_processedIds.toList());
      await prefs.setString('processed_notification_ids', processedIdsJson);
    } catch (e) {
      debugPrint('Error saving processed IDs: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    bool hasChanges = false;
    for (final notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _processedIds.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stored_notifications');
    await prefs.remove('processed_notification_ids');

    notifyListeners();
  }

  // Delete specific notification
  Future<void> deleteNotification(int id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  // Manually refresh notifications
  Future<void> refresh() async {
    await _fetchAndProcessNotifications();
  }

  // Dispose resources
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Stop the service
  void stop() {
    _timer?.cancel();
    debugPrint('NotificationService stopped');
  }
}