import 'package:flutter/material.dart';
import 'aegismyprofile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';



// Main Navigation Scaffold
class AegisMainScaffold extends StatefulWidget {
  const AegisMainScaffold({super.key});

  @override
  State<AegisMainScaffold> createState() => _AegisMainScaffoldState();
}

class _AegisMainScaffoldState extends State<AegisMainScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userData');


    // Navigate to login screen
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
  // Your screen widgets will go here
  final List<Widget> _screens = [
    const FeedScreen(),
    const TournamentsScreen(),
    const TeamUpScreen(),
    const MessagesScreen(),
    const AegisMyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF09090b),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Custom App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF18181b),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFF06b6d4), // cyan
            Color(0xFF7c3aed), // purple
          ],
        ).createShader(bounds),
        child: const Text(
          'Aegis',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        // Search Icon
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            // Navigate to search screen
          },
        ),
        // Notifications with badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () {
                // Navigate to notifications
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFef4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Feed',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events,
                label: 'Tournaments',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.group_outlined,
                activeIcon: Icons.group,
                label: 'TeamUp',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Messages',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
            colors: [
              Color(0xFF06b6d4),
              Color(0xFF7c3aed),
            ],
          )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer Menu
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF18181b),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF06b6d4),
                    Color(0xFF7c3aed),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // User Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 35,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'swayam1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Coins Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Colors.amber.shade300,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '28',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Drawer Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.emoji_events,
                    title: 'Rewards & Coins',
                    color: const Color(0xFFf59e0b),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to rewards screen
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.leaderboard,
                    title: 'Leaderboards',
                    color: const Color(0xFF06b6d4),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to leaderboards
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    color: const Color(0xFFef4444),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFef4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to notifications
                    },
                  ),
                  const Divider(
                    color: Color(0xFF27272a),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to help
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.policy_outlined,
                    title: 'Community Guidelines',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to guidelines
                    },
                  ),
                  const Divider(
                    color: Color(0xFF27272a),
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    color: const Color(0xFFef4444),
                    onTap: () {
                      // Show logout confirmation
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            ),
            // App Version
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(); // Call the logout function
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFef4444)),
            ),
          ),

        ],
      ),
    );
  }
}

// Placeholder screens (replace with your actual screens)
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Feed Screen',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class TournamentsScreen extends StatelessWidget {
  const TournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tournaments Screen',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class TeamUpScreen extends StatelessWidget {
  const TeamUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'TeamUp Screen',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Messages Screen',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile Screen',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}