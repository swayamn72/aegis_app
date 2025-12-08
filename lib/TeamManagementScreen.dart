import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aegis_app/services/api_service.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _teamData;
  List<dynamic> _invitations = [];
  List<dynamic> _previousTeams = [];
  bool _isCaptain = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final profileResponse = await ApiService.getProfile();
      if (profileResponse['error'] == true) {
        _showError(profileResponse['message']);
        return;
      }

      final userData = profileResponse['data'];
      Map<String, dynamic>? teamData;

      if (userData['team'] != null) {
        final teamId = userData['team'] is Map
            ? userData['team']['_id']
            : userData['team'];
        final teamResponse = await ApiService.getTeam(teamId);
        if (teamResponse['error'] == false) {
          teamData = teamResponse['data']['team'];
        }
      }

      final invitationsResponse = await ApiService.getConnections();
      List<dynamic> invitations = [];
      if (invitationsResponse['error'] == false) {
        invitations = invitationsResponse['data']['invitations'] ?? [];
      }

      setState(() {
        _userData = userData;
        _teamData = teamData;
        _invitations = invitations;
        _previousTeams = userData['previousTeams'] ?? [];
        _isCaptain = teamData != null &&
            teamData['captain'] != null &&
            (teamData['captain']['_id'] == userData['_id'] ||
                teamData['captain'] == userData['_id']);
        _isLoading = false;
      });
    } catch (e) {
      _showError('Failed to load data: $e');
    }
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: const Color(0xFFef4444)),
      );
    }
  }

  void _showCreateTeamDialog() {
    final formKey = GlobalKey<FormState>();
    String teamName = '';
    String teamTag = '';
    String bio = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text('Create New Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Team Name *'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  onSaved: (value) => teamName = value ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Team Tag (Optional)'),
                  maxLength: 5,
                  onSaved: (value) => teamTag = value ?? '',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272a).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF27272a)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_esports, size: 16, color: Color(0xFF06b6d4)),
                      const SizedBox(width: 8),
                      const Text('BGMI', style: TextStyle(color: Color(0xFF06b6d4))),
                      const Spacer(),
                      Text('Default', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272a).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF27272a)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public, size: 16, color: Color(0xFF06b6d4)),
                      const SizedBox(width: 8),
                      const Text('India', style: TextStyle(color: Color(0xFF06b6d4))),
                      const Spacer(),
                      Text('Default', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Team Bio (Optional)'),
                  maxLines: 3,
                  maxLength: 200,
                  onSaved: (value) => bio = value ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                Navigator.pop(context);
                _createTeam(teamName, teamTag, bio);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0891b2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create Team'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTeam(String name, String tag, String bio) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Team created successfully!'), backgroundColor: Color(0xFF16a34a)),
    );
    _fetchData();
  }

  void _showInvitePlayerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text('Invite Players', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search players...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF06b6d4)),
              filled: true,
              fillColor: const Color(0xFF27272a),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invitation sent!'), backgroundColor: Color(0xFF16a34a)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0891b2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Send Invitation'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFF27272a),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF06b6d4)),
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
              const CircularProgressIndicator(color: Color(0xFF06b6d4)),
              const SizedBox(height: 16),
              Text('Loading team data...', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090b),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: const Color(0xFF18181b),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0891b2), Color(0xFF7c3aed)],
                  ),
                ),
              ),
              title: const Text('My Team', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            actions: [
              if (_teamData == null) IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _showCreateTeamDialog),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
            ],
          ),
          if (_invitations.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3b82f6), Color(0xFF7c3aed)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${_invitations.length} team invitation(s)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => _tabController.animateTo(2),
                      child: const Text('View', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          if (_teamData != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatCard(Icons.emoji_events, 'Rating', '${_teamData!['aegisRating'] ?? 0}', const Color(0xFF06b6d4)),
                    _buildStatCard(Icons.people, 'Members', '${(_teamData!['players'] as List?)?.length ?? 0}/5', const Color(0xFF16a34a)),
                    _buildStatCard(Icons.emoji_events, 'Earnings', '₹${((_teamData!['totalEarnings'] ?? 0) / 100000).toStringAsFixed(1)}L', const Color(0xFFf59e0b)),
                    _buildStatCard(Icons.star, 'Events', '${(_teamData!['qualifiedEvents'] as List?)?.length ?? 0}', const Color(0xFF7c3aed)),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Container(
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
                tabs: const [Tab(text: 'Current'), Tab(text: 'History'), Tab(text: 'Invites')],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [_buildCurrentTeamTab(), _buildHistoryTab(), _buildInvitationsTab()],
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
        border: Border.all(color: const Color(0xFF27272a)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTeamTab() {
    if (_teamData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text('Not in a team', style: TextStyle(color: Colors.grey.shade400, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Create or join a team to start competing', style: TextStyle(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showCreateTeamDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0891b2),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final team = _teamData!;
    final players = (team['players'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF18181b),
              border: Border.all(color: const Color(0xFF27272a)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)]),
                      ),
                      child: team['logo'] != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(team['logo'], fit: BoxFit.cover))
                          : Center(
                        child: Text(
                          team['teamName']?.substring(0, 1).toUpperCase() ?? 'T',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(team['teamName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          if (team['teamTag'] != null)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06b6d4).withOpacity(0.1),
                                border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('[${team['teamTag']}]',
                                  style: const TextStyle(color: Color(0xFF06b6d4), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                    if (_isCaptain)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf59e0b).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield, color: Color(0xFFf59e0b), size: 24),
                      ),
                  ],
                ),
                if (team['bio'] != null) ...[
                  const SizedBox(height: 16),
                  Text(team['bio'], style: TextStyle(color: Colors.grey.shade300, fontSize: 13), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoItem(Icons.sports_esports, team['primaryGame'] ?? 'Unknown'),
                    _buildInfoItem(Icons.public, team['region'] ?? 'Unknown'),
                    _buildInfoItem(Icons.calendar_today, 'Est. ${team['establishedDate'] != null ? DateTime.parse(team['establishedDate']).year : 'N/A'}'),
                  ],
                ),
                if (_isCaptain) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27272a),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showInvitePlayerDialog,
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Invite'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0891b2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Team Roster', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF06b6d4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3)),
                ),
                child: Text('${players.length}/5', style: const TextStyle(color: Color(0xFF06b6d4), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (players.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF18181b),
                border: Border.all(color: const Color(0xFF27272a)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('No players in roster', style: TextStyle(color: Colors.grey.shade500))),
            )
          else
            ...players.map((player) => _buildPlayerCard(player)).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF06b6d4)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final isCaptain = _teamData!['captain'] != null &&
        (player['_id'] == _teamData!['captain']['_id'] || player['_id'] == _teamData!['captain']);
    final isCurrentUser = player['_id'] == _userData!['_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        border: Border.all(color: isCaptain ? const Color(0xFFf59e0b).withOpacity(0.3) : const Color(0xFF27272a)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)]),
            ),
            child: player['profilePicture'] != null
                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(player['profilePicture'], fit: BoxFit.cover))
                : Center(child: Text(player['username']?.substring(0, 1).toUpperCase() ?? 'P',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player['inGameName'] ?? player['username'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCaptain)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf59e0b).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield, size: 10, color: Color(0xFFf59e0b)),
                            SizedBox(width: 2),
                            Text('Captain', style: TextStyle(color: Color(0xFFf59e0b), fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(player['realName'] ?? 'Player', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text('Rating: ${player['aegisRating'] ?? 0}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          if (_isCaptain && !isCaptain)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: const Color(0xFFef4444),
              iconSize: 20,
              onPressed: () => _showKickConfirmation(player),
            )
          else if (!_isCaptain && isCurrentUser)
            TextButton(
              onPressed: () => _showLeaveConfirmation(),
              child: const Text('Leave', style: TextStyle(color: Color(0xFFef4444), fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_previousTeams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text('No team history', style: TextStyle(color: Colors.grey.shade400, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Your previous teams will appear here', style: TextStyle(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _previousTeams.length,
      itemBuilder: (context, index) => _buildPreviousTeamCard(_previousTeams[index]),
    );
  }

  Widget _buildPreviousTeamCard(Map<String, dynamic> team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        border: Border.all(color: const Color(0xFF27272a)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)]),
                ),
                child: team['logo'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(team['logo'], fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          team['teamName']?.substring(0, 1).toUpperCase() ?? 'T',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team['teamName'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (team['teamTag'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06b6d4).withOpacity(0.1),
                          border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '[${team['teamTag']}]',
                          style: const TextStyle(color: Color(0xFF06b6d4), fontSize: 10, fontWeight: FontWeight.bold),
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
              Icon(Icons.sports_esports, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(team['primaryGame'] ?? 'Unknown', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              const SizedBox(width: 12),
              Icon(Icons.public, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(team['region'] ?? 'Unknown', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ],
          ),
          if (team['leftDate'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Left: ${_formatDate(team['leftDate'])}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildInvitationsTab() {
    if (_invitations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_outline, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text('No invitations', style: TextStyle(color: Colors.grey.shade400, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Team invitations will appear here', style: TextStyle(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invitations.length,
      itemBuilder: (context, index) => _buildInvitationCard(_invitations[index]),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final team = invitation['team'] ?? {};
    final fromPlayer = invitation['fromPlayer'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        border: Border.all(color: const Color(0xFF3b82f6).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)]),
                ),
                child: team['logo'] != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(team['logo'], fit: BoxFit.cover))
                    : Center(child: Text(team['teamName']?.substring(0, 1).toUpperCase() ?? 'T',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team['teamName'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('From ${fromPlayer['username'] ?? 'Unknown'}', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    if (invitation['createdAt'] != null)
                      Text(_formatDate(invitation['createdAt']), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          if (invitation['message'] != null && invitation['message'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF27272a).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(invitation['message'], style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleAcceptInvitation(invitation['_id']),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16a34a),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleDeclineInvitation(invitation['_id']),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Decline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27272a),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcceptInvitation(String invitationId) async {
    try {
      final response = await ApiService.acceptInvitation(invitationId);
      if (response['error'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation accepted!'), backgroundColor: Color(0xFF16a34a)),
        );
        _fetchData();
      } else {
        _showError(response['message'] ?? 'Failed to accept invitation');
      }
    } catch (e) {
      _showError('Failed to accept invitation: $e');
    }
  }

  Future<void> _handleDeclineInvitation(String invitationId) async {
    try {
      final response = await ApiService.declineInvitation(invitationId);
      if (response['error'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined'), backgroundColor: Color(0xFF27272a)),
        );
        _fetchData();
      } else {
        _showError(response['message'] ?? 'Failed to decline invitation');
      }
    } catch (e) {
      _showError('Failed to decline invitation: $e');
    }
  }

  void _showKickConfirmation(Map<String, dynamic> player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text('Kick Player', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to kick ${player['username'] ?? 'this player'} from the team?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _kickPlayer(player['_id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kick'),
          ),
        ],
      ),
    );
  }

  Future<void> _kickPlayer(String playerId) async {
    try {
      final response = await ApiService.kickPlayer(_teamData!['_id'], playerId);
      if (response['error'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player kicked successfully'), backgroundColor: Color(0xFF16a34a)),
        );
        _fetchData();
      } else {
        _showError(response['message'] ?? 'Failed to kick player');
      }
    } catch (e) {
      _showError('Failed to kick player: $e');
    }
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text('Leave Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to leave this team?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveTeam();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveTeam() async {
    try {
      final response = await ApiService.leaveTeam(_teamData!['_id']);
      if (response['error'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left team successfully'), backgroundColor: Color(0xFF16a34a)),
        );
        _fetchData();
      } else {
        _showError(response['message'] ?? 'Failed to leave team');
      }
    } catch (e) {
      _showError('Failed to leave team: $e');
    }
  }
}

