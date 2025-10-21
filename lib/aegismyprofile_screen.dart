import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

// Profile Screen
class AegisMyProfileScreen extends StatefulWidget {
  const AegisMyProfileScreen({super.key});

  @override
  State<AegisMyProfileScreen> createState() => _AegisMyProfileScreenState();
}

class _AegisMyProfileScreenState extends State<AegisMyProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _teamData;
  List<dynamic> _connections = [];
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
    });

    // Fetch user profile
    final profileResponse = await ApiService.getProfile();

    if (profileResponse['error'] == true) {
      _showError(profileResponse['message']);
      return;
    }

    final userData = profileResponse['data'];

    // Fetch connections
    final connectionsResponse = await ApiService.getConnections();
    List<dynamic> connections = [];
    if (connectionsResponse['error'] == false) {
      final connectionsData = connectionsResponse['data'];
      connections = connectionsData['connections'] ?? [];
    }

    // Fetch team data if user is in a team
    Map<String, dynamic>? teamData;
    if (userData['team'] != null) {
      final teamId =
      userData['team'] is Map ? userData['team']['_id'] : userData['team'];

      final teamResponse = await ApiService.getTeam(teamId);
      if (teamResponse['error'] == false) {
        teamData = teamResponse['data']['team'];
      }
    }

    setState(() {
      _userData = userData;
      _teamData = teamData;
      _connections = connections;
      _isLoading = false;
    });
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFef4444),
        ),
      );
    }
  }

  void _copyProfileLink() {
    final username = _userData?['username'] ?? '';
    Clipboard.setData(
        ClipboardData(text: 'https://aegis.com/player/$username'));
    setState(() {
      _copied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile link copied!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF16a34a),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Share Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF27272a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'https://aegis.com/player/${_userData?['username'] ?? ''}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _copyProfileLink();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.copy, color: Color(0xFF06b6d4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0891b2),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090b),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF06b6d4),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090b),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProfileData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0891b2),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _userData!;
    final statistics = user['statistics'] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF09090b),
      body: CustomScrollView(
        slivers: [
          // Compact App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF18181b),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0891b2),
                      Color(0xFF7c3aed),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _showShareSheet,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Navigate to settings
                },
              ),
            ],
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile Header - Compact
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    children: [
                      // Profile Picture
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF18181b),
                                width: 4,
                              ),
                              gradient: user['profilePicture'] == null
                                  ? const LinearGradient(
                                colors: [
                                  Color(0xFF06b6d4),
                                  Color(0xFF7c3aed),
                                ],
                              )
                                  : null,
                            ),
                            child: user['profilePicture'] != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                user['profilePicture'],
                                fit: BoxFit.cover,
                              ),
                            )
                                : const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          if (user['verified'] == true)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF06b6d4),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF18181b),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Username
                      Text(
                        user['username'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['realName'] ?? 'Not provided',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Action Buttons - Compact
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to edit profile
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0891b2),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Create post
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16a34a),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Post',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tags - Simplified
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            if (user['primaryGame'] != null &&
                                user['primaryGame'] != 'Not selected')
                              _buildTag(
                                user['primaryGame'],
                                const Color(0xFF06b6d4),
                              ),
                            if (user['teamStatus'] != null &&
                                user['teamStatus'] != 'Not specified')
                              _buildTag(
                                user['teamStatus'],
                                _getTeamStatusColor(user['teamStatus']),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Cards - 2x2 Grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _buildStatCard(
                        Icons.emoji_events,
                        'Rating',
                        '${user['aegisRating'] ?? 1200}',
                        const Color(0xFF06b6d4),
                      ),
                      _buildStatCard(
                        Icons.gps_fixed,
                        'Win Rate',
                        '${statistics['winRate'] ?? 0}%',
                        const Color(0xFF16a34a),
                      ),
                      _buildStatCard(
                        Icons.local_fire_department,
                        'Kills',
                        '${statistics['totalKills'] ?? 0}',
                        const Color(0xFFef4444),
                      ),
                      _buildStatCard(
                        Icons.military_tech,
                        'Events',
                        '${statistics['tournamentsPlayed'] ?? 0}',
                        const Color(0xFFf59e0b),
                      ),
                    ],
                  ),
                ),

                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181b),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF27272a)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade400,
                    indicatorColor: const Color(0xFF06b6d4),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontSize: 13),
                    tabs: const [
                      Tab(text: 'Stats'),
                      Tab(text: 'Team'),
                      Tab(text: 'Social'),
                    ],
                  ),
                ),

                // Tab Content
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStatsTab(statistics),
                      _buildTeamTab(),
                      _buildSocialTab(user),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getTeamStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'looking for a team':
        return const Color(0xFF16a34a);
      case 'in a team':
        return const Color(0xFF3b82f6);
      default:
        return const Color(0xFFf59e0b);
    }
  }

  Widget _buildStatCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        border: Border.all(color: const Color(0xFF27272a)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(Map<String, dynamic> statistics) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181b),
          border: Border.all(color: const Color(0xFF27272a)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildStatRow('Matches Played', '${statistics['matchesPlayed'] ?? 0}'),
            _buildStatRow('Matches Won', '${statistics['matchesWon'] ?? 0}'),
            _buildStatRow('Win Rate', '${statistics['winRate'] ?? 0}%'),
            _buildStatRow('Total Kills', '${statistics['totalKills'] ?? 0}'),
            _buildStatRow('Tournaments', '${statistics['tournamentsPlayed'] ?? 0}'),
            _buildStatRow('Avg Placement', '#${statistics['averagePlacement'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF18181b),
          border: Border.all(color: const Color(0xFF27272a)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _teamData != null
            ? Column(
          children: [
            if (_teamData!['logo'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _teamData!['logo'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
                  ),
                ),
                child: Center(
                  child: Text(
                    _teamData!['teamName']
                        ?.substring(0, 1)
                        .toUpperCase() ??
                        'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              _teamData!['teamName'] ?? 'Unknown Team',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Member since ${_userData?['createdAt'] != null ? DateTime.parse(_userData!['createdAt']).year : 'Unknown'}',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
          ],
        )
            : Column(
          children: [
            Icon(
              Icons.group_off,
              size: 56,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Not in a team',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to find team
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0891b2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Find a Team'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialTab(Map<String, dynamic> user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSocialCard(
            Icons.tag,
            'Discord',
            user['discordTag'],
            const Color(0xFF5865f2),
          ),
          const SizedBox(height: 10),
          _buildSocialCard(
            Icons.videocam,
            'Twitch',
            user['twitch'],
            const Color(0xFF9146ff),
          ),
          const SizedBox(height: 10),
          _buildSocialCard(
            Icons.play_circle,
            'YouTube',
            user['youtube'],
            const Color(0xFFef4444),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard(
      IconData icon, String platform, String? value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value != null ? color.withOpacity(0.1) : const Color(0xFF18181b),
        border: Border.all(
          color: value != null
              ? color.withOpacity(0.3)
              : const Color(0xFF27272a),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value != null ? color : Colors.grey.shade600,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? 'Not connected',
                  style: TextStyle(
                    color: value != null ? color : Colors.grey.shade500,
                    fontSize: 12,
                    fontStyle: value == null ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
          if (value != null)
            Icon(
              Icons.open_in_new,
              size: 16,
              color: Colors.grey.shade500,
            ),
        ],
      ),
    );
  }
}