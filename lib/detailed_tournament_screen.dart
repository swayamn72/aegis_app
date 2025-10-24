import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async';
import 'services/api_service.dart';

class DetailedTournamentScreen extends StatefulWidget {
  final String tournamentId;

  const DetailedTournamentScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<DetailedTournamentScreen> createState() => _DetailedTournamentScreenState();
}

class _DetailedTournamentScreenState extends State<DetailedTournamentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data states
  Map<String, dynamic>? tournamentData;
  List<dynamic> matches = [];
  Map<String, dynamic> groupsData = {};
  Map<String, dynamic>? registrationStatus;

  // Loading states
  bool isLoadingSummary = true;
  bool isLoadingDetails = false;
  bool isLoadingMatches = false;
  bool isRegistering = false;

  // Error states
  String? error;

  // Pagination
  int matchOffset = 0;
  bool hasMoreMatches = true;

  // Selected filters
  String? selectedPhase;
  String selectedGroup = 'A';

  // Modal states
  bool showRegistrationModal = false;
  bool showNonCaptainModal = false;
  bool showPrizeModal = false;
  bool agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTournamentSummary();
    _checkRegistrationStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 3 && matches.isEmpty) {
      _loadMatches();
    } else if (_tabController.index == 1 && !isLoadingDetails && tournamentData?['phases'] == null) {
      _loadFullDetails();
    }
  }

  Future<void> _loadTournamentSummary() async {
    setState(() {
      isLoadingSummary = true;
      error = null;
    });

    try {
      final response = await ApiService.getTournamentSummary(widget.tournamentId);

      if (response['error']) {
        setState(() {
          error = response['message'];
          isLoadingSummary = false;
        });
        return;
      }

      setState(() {
        tournamentData = response['data']['tournament'];
        isLoadingSummary = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load tournament: $e';
        isLoadingSummary = false;
      });
    }
  }

  Future<void> _loadFullDetails() async {
    setState(() => isLoadingDetails = true);

    try {
      final response = await ApiService.getTournamentDetails(
        widget.tournamentId,
        includeMatches: false,
      );

      if (!response['error']) {
        setState(() {
          tournamentData = {
            ...tournamentData ?? {},
            ...response['data']['tournamentData'],
          };
          groupsData = response['data']['groupsData'] ?? {};
          if (tournamentData?['phases'] != null && (tournamentData!['phases'] as List).isNotEmpty) {
            selectedPhase = tournamentData!['phases'][0]['name'];
          }
        });
      }
    } catch (e) {
      // print('Error loading full details: $e');
    } finally {
      setState(() => isLoadingDetails = false);
    }
  }

  Future<void> _loadMatches() async {
    if (isLoadingMatches || !hasMoreMatches) return;

    setState(() => isLoadingMatches = true);

    try {
      final response = await ApiService.getTournamentMatches(
        widget.tournamentId,
        limit: 20,
        offset: matchOffset,
      );

      if (!response['error']) {
        final newMatches = response['data']['matches'] as List;
        final pagination = response['data']['pagination'];

        setState(() {
          matches.addAll(newMatches);
          matchOffset += newMatches.length;
          hasMoreMatches = pagination['hasMore'] ?? false;
        });
      }
    } catch (e) {
      // print('Error loading matches: $e');
    } finally {
      setState(() => isLoadingMatches = false);
    }
  }

  Future<void> _checkRegistrationStatus() async {
    try {
      final response = await ApiService.checkTournamentRegistration(widget.tournamentId);
      if (!response['error']) {
        setState(() {
          registrationStatus = response['data'];
        });
      }
    } catch (e) {
      // print('Error checking registration: $e');
    }
  }

  Future<void> _handleRegistration() async {
    if (!agreedToTerms) {
      _showSnackBar('Please agree to terms and conditions', isError: true);
      return;
    }

    setState(() => isRegistering = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/team-tournaments/register/${widget.tournamentId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await ApiService.getToken()}',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          showRegistrationModal = false;
          agreedToTerms = false;
        });
        _showSnackBar('Team registered successfully!');
        _checkRegistrationStatus();
      } else {
        _showSnackBar(data['error'] ?? 'Registration failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    } finally {
      setState(() => isRegistering = false);
    }
  }

  Future<void> _sendReferenceMessage() async {
    try {
      final token = await ApiService.getToken();
      final captainId = registrationStatus?['team']?['captain']?['_id'];

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/chat/tournament-reference/${widget.tournamentId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'captainId': captainId,
          'tournamentId': widget.tournamentId,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => showNonCaptainModal = false);
        _showSnackBar('Reference sent to captain!');
      } else {
        _showSnackBar('Failed to send reference', isError: true);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingSummary) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090b),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orange.shade400,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading tournament...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090b),
        appBar: AppBar(
          backgroundColor: const Color(0xFF18181b),
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadTournamentSummary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090b),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
        ],
        body: Column(
          children: [
            _buildQuickStats(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      floatingActionButton: _buildRegistrationFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    final media = tournamentData?['media'] ?? {};
    final banner = media['banner'] ?? media['coverImage'];

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF18181b),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (banner != null)
              Image.network(
                banner,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF27272a),
                ),
              )
            else
              Container(color: const Color(0xFF27272a)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color.fromRGBO(9, 9, 11, 0.8),
                    const Color(0xFF09090b),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (media['logo'] != null)
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange, width: 2),
                            image: DecorationImage(
                              image: NetworkImage(media['logo']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusBadge(tournamentData?['status']),
                            const SizedBox(height: 4),
                            Text(
                              tournamentData?['name'] ?? 'Tournament',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        Icons.sports_esports,
                        tournamentData?['game'] ?? '',
                      ),
                      _buildInfoChip(
                        Icons.location_on,
                        tournamentData?['region'] ?? '',
                      ),
                      _buildInfoChip(
                        Icons.people,
                        '${tournamentData?['teams'] ?? 0} Teams',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            // Favorite functionality
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'in_progress':
      case 'live':
        color = Colors.red;
        text = 'LIVE';
        icon = Icons.circle;
        break;
      case 'completed':
        color = Colors.green;
        text = 'Completed';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.blue;
        text = 'Upcoming';
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        border: Border.all(color: color.withAlpha(128)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.orange.shade400),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final stats = tournamentData?['statistics'] ?? {};
    final prizePool = tournamentData?['prizePool'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              Icons.emoji_events,
              'Prize Pool',
              _formatPrizePool(prizePool),
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              Icons.gamepad,
              'Matches',
              '${stats['totalMatches'] ?? 0}',
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              Icons.whatshot,
              'Total Kills',
              '${stats['totalKills'] ?? 0}',
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272a)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF18181b),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.orange,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Schedule'),
          Tab(text: 'Groups'),
          Tab(text: 'Matches'),
          Tab(text: 'Stats'),
          Tab(text: 'Streams'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildScheduleTab(),
        _buildGroupsTab(),
        _buildMatchesTab(),
        _buildStatsTab(),
        _buildStreamsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Tournament Information',
            Text(
              tournamentData?['description'] ?? 'No description available',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Details',
            Column(
              children: [
                _buildDetailRow('Organizer', tournamentData?['organizer']?['name'] ?? 'N/A'),
                _buildDetailRow('Format', tournamentData?['format'] ?? 'N/A'),
                _buildDetailRow('Game Mode', tournamentData?['gameSettings']?['gameMode'] ?? 'N/A'),
                _buildDetailRow('Server', tournamentData?['gameSettings']?['serverRegion'] ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Prize Distribution',
            Column(
              children: [
                if (tournamentData?['prizePool']?['distribution'] != null)
                  ...List.generate(
                    (tournamentData!['prizePool']!['distribution'] as List).length.clamp(0, 3),
                        (index) {
                      final prize = tournamentData!['prizePool']!['distribution'][index];
                      return _buildPrizeRow(
                        prize['position'] ?? '${index + 1}',
                        '₹${prize['amount']?.toString() ?? '0'}',
                      );
                    },
                  ),
                if (tournamentData?['prizePool']?['distribution'] != null &&
                    (tournamentData!['prizePool']!['distribution'] as List).length > 3)
                  TextButton(
                    onPressed: () => setState(() => showPrizeModal = true),
                    child: const Text('View Full Breakdown'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Social Media',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (tournamentData?['socialMedia']?['youtube'] != null)
                  _buildSocialButton(Icons.play_circle, 'YouTube', Colors.red),
                if (tournamentData?['socialMedia']?['twitter'] != null)
                  _buildSocialButton(Icons.flutter_dash, 'Twitter', Colors.blue),
                if (tournamentData?['socialMedia']?['instagram'] != null)
                  _buildSocialButton(Icons.camera_alt, 'Instagram', Colors.pink),
                if (tournamentData?['socialMedia']?['discord'] != null)
                  _buildSocialButton(Icons.chat, 'Discord', Colors.indigo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    if (isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Tournament Schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (tournamentData?['phases'] != null)
          ...List.generate(
            (tournamentData!['phases'] as List).length,
                (index) {
              final phase = tournamentData!['phases'][index];
              return _buildPhaseCard(phase);
            },
          )
        else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Schedule will be updated soon',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupsTab() {
    if (groupsData.isEmpty) {
      if (!isLoadingDetails) _loadFullDetails();
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Phase selector
        if (tournamentData?['phases'] != null)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                (tournamentData!['phases'] as List).length,
                    (index) {
                  final phase = tournamentData!['phases'][index];
                  final phaseName = phase['name'];
                  final isSelected = selectedPhase == phaseName;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(phaseName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => selectedPhase = phaseName);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        // Group selector
        if (selectedPhase != null && groupsData[selectedPhase] != null)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: (groupsData[selectedPhase] as Map).keys.map((groupKey) {
                final isSelected = selectedGroup == groupKey;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('Group $groupKey'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedGroup = groupKey);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        Expanded(
          child: _buildGroupTeams(),
        ),
      ],
    );
  }

  Widget _buildGroupTeams() {
    if (selectedPhase == null || groupsData[selectedPhase] == null) {
      return const Center(child: Text('No groups available', style: TextStyle(color: Colors.grey)));
    }

    final group = groupsData[selectedPhase]![selectedGroup];
    if (group == null || group['teams'] == null) {
      return const Center(child: Text('No teams in this group', style: TextStyle(color: Colors.grey)));
    }

    final teams = group['teams'] as List;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        final team = teams[index];
        return _buildTeamCard(team);
      },
    );
  }

  Widget _buildMatchesTab() {
    if (matches.isEmpty && !isLoadingMatches) {
      _loadMatches();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!isLoadingMatches &&
            hasMoreMatches &&
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMatches();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length + (hasMoreMatches ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == matches.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildMatchCard(matches[index]);
        },
      ),
    );
  }

  Widget _buildStatsTab() {
    final stats = tournamentData?['statistics'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(
          'Tournament Statistics',
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildLargeStatCard(
                      'Total Eliminations',
                      '${stats['totalKills'] ?? 0}',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLargeStatCard(
                      'Total Matches',
                      '${stats['totalMatches'] ?? 0}',
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildLargeStatCard(
                      'Participating Teams',
                      '${stats['totalParticipatingTeams'] ?? 0}',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLargeStatCard(
                      'Avg Duration',
                      '${stats['avgMatchDuration']?.toStringAsFixed(0) ?? 0}m',
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreamsTab() {
    final streamLinks = tournamentData?['streamLinks'] ?? [];
    final stats = tournamentData?['statistics']?['viewership'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (streamLinks.isNotEmpty) ...[
          _buildSection(
            'Live Streams',
            Column(
              children: List.generate(
                streamLinks.length,
                    (index) {
                  final stream = streamLinks[index];
                  return _buildStreamCard(stream);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildSection(
          'Stream Statistics',
          Column(
            children: [
              _buildDetailRow('Current Viewers', '${stats['currentViewers'] ?? 0}'),
              _buildDetailRow('Peak Viewers', '${stats['peakViewers'] ?? 0}'),
              _buildDetailRow('Total Views', '${stats['totalViews'] ?? 0}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272a)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeRow(String position, String amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF27272a),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(position, style: const TextStyle(color: Colors.white70)),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String label, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(51),
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withAlpha(128)),
        ),
      ),
    );
  }

  Widget _buildPhaseCard(Map<String, dynamic> phase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272a)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  phase['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(phase['status']),
            ],
          ),
          const SizedBox(height: 8),
          if (phase['description'] != null)
            Text(
              phase['description'],
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          const SizedBox(height: 8),
          Text(
            '${_formatDate(phase['startDate'])} - ${_formatDate(phase['endDate'])}',
            style: const TextStyle(color: Colors.orange, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272a)),
      ),
      child: Row(
        children: [
          if (team['logo'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                team['logo'],
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFF27272a),
                  child: const Icon(Icons.shield, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF27272a),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Colors.grey),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team['name'] ?? 'Unknown Team',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (team['tag'] != null)
                  Text(
                    team['tag'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final teams = match['participatingTeams'] as List? ?? [];
    final winner = teams.firstWhere(
          (team) => team['chickenDinner'] == true,
      orElse: () => null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272a)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to match details
            // Navigator.push(context, MaterialPageRoute(...));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${match['matchNumber'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match['tournamentPhase'] ?? 'Match',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Match ${match['matchNumber'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(match['status']),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF27272a),
                      ),
                      child: Center(
                        child: Text(
                          match['map'] ?? 'MAP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Teams:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                '${teams.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kills:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                '${match['matchStats']?['totalKills'] ?? 0}',
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (winner != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withAlpha(51),
                          Colors.orange.withAlpha(51),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Winner:',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            winner['team']?['teamName'] ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.orange.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Colors.orange.shade400, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272a),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreamCard(Map<String, dynamic> stream) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272a),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_circle_filled, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stream['platform'] ?? 'Stream',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  stream['language'] ?? 'English',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Open stream URL
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Watch'),
          ),
        ],
      ),
    );
  }

  Widget? _buildRegistrationFAB() {
    if (registrationStatus == null) return null;

    final hasTeam = registrationStatus!['hasTeam'] ?? false;
    final isRegistered = registrationStatus!['isRegistered'] ?? false;
    final isCaptain = registrationStatus!['isCaptain'] ?? false;

    if (isRegistered) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check_circle),
        label: const Text('Registered'),
      );
    }

    if (!hasTeam) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/my-teams');
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.group_add),
        label: const Text('Join Team'),
      );
    }

    if (!isCaptain) {
      return FloatingActionButton.extended(
        onPressed: () {
          setState(() => showNonCaptainModal = true);
        },
        backgroundColor: Colors.yellow.shade700,
        icon: const Icon(Icons.send),
        label: const Text('Request Captain'),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () {
        setState(() => showRegistrationModal = true);
      },
      backgroundColor: Colors.green,
      icon: const Icon(Icons.how_to_reg),
      label: const Text('Register Team'),
    );
  }

  String _formatPrizePool(Map<String, dynamic> prizePool) {
    final total = prizePool['total'];
    if (total == null || total == 0) return 'TBD';

    if (total >= 10000000) {
      return '₹${(total / 10000000).toStringAsFixed(1)}Cr';
    } else if (total >= 100000) {
      return '₹${(total / 100000).toStringAsFixed(1)}L';
    } else if (total >= 1000) {
      return '₹${(total / 1000).toStringAsFixed(1)}K';
    }
    return '₹$total';
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'TBD';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return 'TBD';
    }
  }

void _showRegistrationModal(BuildContext context, _DetailedTournamentScreenState state) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF18181b),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF27272a)),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Register Team',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272a),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          // Team info would go here
                          Text(
                            'Your team details will be displayed here',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      value: state.agreedToTerms,
                      onChanged: (value) {
                        setState(() => state.agreedToTerms = value ?? false);
                      },
                      title: const Text(
                        'I agree to the terms and conditions',
                        style: TextStyle(color: Colors.white),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF27272a)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF27272a)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: state.agreedToTerms && !state.isRegistering
                          ? () {
                        state._handleRegistration();
                        Navigator.pop(context);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state.isRegistering
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text('Register'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}