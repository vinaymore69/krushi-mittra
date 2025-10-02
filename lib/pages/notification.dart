import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisan_krushi/pages/sign_in.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_service.dart';
import 'chat.dart';
import 'profile.dart';
import 'home.dart';
import '../services/translation_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;
  final Map<int, NotificationModel> _recentlyDeleted = {};
  int _selectedIndex = 2; // Alerts tab is active
  Future<Map<String, dynamic>>? _translationsFuture;

  // Get the selected language from the global variable and map to lowercase
  String get _selectedLanguage {
    final languageMap = {
      'English': 'english',
      'हिन्दी': 'hindi',
      'मराठी': 'marathi',
      'ਪੰਜਾਬੀ': 'punjabi',
      'ಕನ್ನಡ': 'kannada',
      'தமிழ்': 'tamil',
      'తెలుగు': 'telugu',
      'മലയാളം': 'malayalam',
      'ગુજરાતી': 'gujarati',
      'বাংলা': 'bengali',
      'ଓଡ଼ିଆ': 'odia',
      'اردو': 'urdu',
    };
    return languageMap[selectedLanguageGlobal] ?? 'english';
  }

  // Helper method to get nested translation text
  String _getNestedText(Map<String, dynamic> translations, String section, List<String> keys, String language) {
    try {
      dynamic current = translations[section];
      for (String key in keys) {
        current = current[key];
      }
      return current[language] ?? current['english'] ?? keys.last;
    } catch (e) {
      print('Translation error for $section.${keys.join('.')}: $e');
      return keys.last; // Return the last key as fallback
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _translationsFuture = TranslationService.fetchTranslations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  void _onItemTapped(int index) {
    _triggerHaptic();
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on the selected tab
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1: // Chat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
        break;
      case 2: // Alerts - Current page, no navigation needed
        break;
      case 3: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await context.read<NotificationService>().refresh();
    setState(() => _isRefreshing = false);
  }

  String _getDateKey(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _translationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              // Fallback UI without translations
              return _buildMainContent({});
            }

            final translations = snapshot.data!;
            return _buildMainContent(translations);
          },
        ),
      ),
      // Bottom Navigation Bar matching home.dart style
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
        future: _translationsFuture,
        builder: (context, snapshot) {
          final translations = snapshot.data ?? {};

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
                  label: translations.isNotEmpty ? _getNestedText(translations, "home", ["navigation", "explore"], _selectedLanguage) : "Explore",
                  index: 0,
                ),
                _buildBottomNavItem(
                  icon: Icons.chat_bubble_outline,
                  label: translations.isNotEmpty ? _getNestedText(translations, "home", ["navigation", "chat"], _selectedLanguage) : "Chat",
                  index: 1,
                ),
                _buildBottomNavItem(
                  icon: Icons.notifications,
                  label: translations.isNotEmpty ? _getNestedText(translations, "home", ["navigation", "alerts"], _selectedLanguage) : "Alerts",
                  index: 2,
                ),
                _buildBottomNavItem(
                  icon: Icons.person_outline,
                  label: translations.isNotEmpty ? _getNestedText(translations, "home", ["navigation", "profile"], _selectedLanguage) : "Profile",
                  index: 3,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic> translations) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header matching home.dart style
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              GestureDetector(
                onTap: () {
                  _triggerHaptic();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
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
              // Logo
              Container(
                width: 60,
                height: 70,
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

          // Title
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              // Actions Menu
              Consumer<NotificationService>(
                builder: (context, service, _) {
                  return PopupMenuButton<String>(
                    icon: Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_vert, color: Colors.black54),
                        ),
                        if (service.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE67E22),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onSelected: (value) async {
                      switch (value) {
                        case 'refresh':
                          await _refresh();
                          break;
                        case 'mark_all_read':
                          await service.markAllAsRead();
                          _showSuccessSnackBar('All notifications marked as read');
                          break;
                        case 'clear_all':
                          _showClearAllDialog();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(_isRefreshing ? Icons.hourglass_top : Icons.refresh, size: 20),
                            const SizedBox(width: 8),
                            Text(_isRefreshing ? 'Refreshing...' : 'Refresh'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'mark_all_read',
                        child: Row(
                          children: [
                            Icon(Icons.done_all, size: 20),
                            SizedBox(width: 8),
                            Text('Mark all as read'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Clear all', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Tabs
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1),

            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: const Color(0xFFE67E22),
              ),
              indicatorSize: TabBarIndicatorSize.tab, // This makes the indicator span the full tab width
              indicatorPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical:1.0), // Adjust padding as needed

              labelColor: Colors.white,
              unselectedLabelColor: Colors.black54,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'All Notifications'),
                Tab(text: 'Unread'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content
          Expanded(
            child: _isRefreshing
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE67E22)),
              ),
            )
                : TabBarView(
              controller: _tabController,
              physics: _isRefreshing
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              children: [
                _buildNotificationList(showOnlyUnread: false),
                _buildNotificationList(showOnlyUnread: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList({required bool showOnlyUnread}) {
    return Consumer<NotificationService>(
      builder: (context, service, _) {
        final notifications = showOnlyUnread
            ? service.notifications.where((n) => !n.isRead).toList()
            : service.notifications;

        if (notifications.isEmpty) {
          return _buildEmptyState(showOnlyUnread);
        }

        // Group notifications by date
        final Map<String, List<NotificationModel>> grouped = {};
        for (var notification in notifications) {
          final dateKey = _getDateKey(notification.timestamp);
          grouped.putIfAbsent(dateKey, () => []).add(notification);
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFFE67E22),
          child: ListView(
            physics: _isRefreshing
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            children: grouped.entries.expand((entry) {
              return [
                // Date header
                Container(
                  margin: EdgeInsets.only(bottom: 12, top: entry.key == grouped.keys.first ? 0 : 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE67E22),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${entry.value.length} notification${entry.value.length > 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Notifications for this date
                ...entry.value.map((notification) =>
                    _buildSwipeableNotificationCard(notification, service)
                ),
              ];
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSwipeableNotificationCard(
      NotificationModel notification,
      NotificationService service
      ) {
    return Dismissible(
      key: Key('notification_${notification.id}'),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF9CAF88),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              notification.isRead ? Icons.mark_email_unread : Icons.done,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              notification.isRead ? 'Mark Unread' : 'Mark Read',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Toggle read/unread status
          await service.markAsRead(notification.id);
          _showSuccessSnackBar(
              notification.isRead ? 'Marked as unread' : 'Marked as read'
          );
          return false; // Don't remove from list
        } else if (direction == DismissDirection.endToStart) {
          // Delete notification
          _recentlyDeleted[notification.id] = notification;
          await service.deleteNotification(notification.id);
          _showUndoSnackBar(notification, service);
          return true; // Remove from list
        }
        return false;
      },
      child: _buildNotificationCard(notification),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isToday = DateTime.now().difference(notification.timestamp).inDays == 0;
    final timeFormat = isToday
        ? '${notification.timestamp.hour.toString().padLeft(2, '0')}:${notification.timestamp.minute.toString().padLeft(2, '0')}'
        : '${notification.timestamp.day}/${notification.timestamp.month}/${notification.timestamp.year}';

    return GestureDetector(
      onTap: () => _showNotificationDetails(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          // borderRadius: BorderRadius.circular(10),
          // border: Border.all(
          //   color: notification.isRead
          //       ? Colors.black.withOpacity(0.1)
          //       : const Color(0xFFE67E22).withOpacity(0.3),
          //   width: 1,
          // ),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.05),
          //     blurRadius: 10,
          //     offset: const Offset(0, 5),
          //   )

          // ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.black.withOpacity(0.1)
                    : const Color(0xFFE67E22).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications,
                color: notification.isRead
                    ? Colors.black54
                    : const Color(0xFFE67E22),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: notification.isRead ? 0 : 8,
                        height: notification.isRead ? 0 : 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE67E22),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.black.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeFormat,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.4),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Swipe for actions',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.black.withOpacity(0.3),
                          fontStyle: FontStyle.italic,
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

  Widget _buildEmptyState(bool isUnreadTab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isUnreadTab ? Icons.mark_email_read : Icons.notifications_none,
              size: 64,
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isUnreadTab ? 'No unread notifications' : 'No notifications yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUnreadTab
                ? 'All caught up! You have no unread notifications.'
                : 'You\'ll see new notifications from Maha Krushi Mittra here.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isUnreadTab) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _refresh,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Check for notifications',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  void _showNotificationDetails(NotificationModel notification) {
    // Mark as read when viewed
    context.read<NotificationService>().markAsRead(notification.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE67E22).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Color(0xFFE67E22),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFullDate(notification.timestamp),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: Colors.black.withOpacity(0.1)),
                      const SizedBox(height: 24),
                      Text(
                        'Message',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        notification.message,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE67E22),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              'Close',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await context.read<NotificationService>().clearAllNotifications();
              Navigator.of(context).pop();
              _showSuccessSnackBar('All notifications cleared');
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFE67E22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showUndoSnackBar(NotificationModel notification, NotificationService service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notification deleted',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () async {
            // Restore the deleted notification by refreshing from server
            await service.refresh();
            _recentlyDeleted.remove(notification.id);
            _showSuccessSnackBar('Refreshed notifications');
          },
        ),
      ),
    );
  }

  String _formatFullDate(DateTime dateTime) {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${dateTime.day} ${months[dateTime.month]} ${dateTime.year}, '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}