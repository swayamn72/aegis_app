import 'package:flutter/material.dart';
import 'services/api_service.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  // 👇 ADD THIS - Keeps the state alive when switching tabs
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  String? _error;
  List<dynamic> _tournaments = [];
  List<dynamic> _liveTournaments = [];
  List<dynamic> _upcomingTournaments = [];
  Map<String, dynamic>? _featuredTournament;

  // Filters
  String _searchTerm = '';
  String _selectedGame = '';
  String _selectedRegion = '';
  String _selectedStatus = '';
  String _selectedTier = '';

  // Filter options
  List<String> _games = [];
  List<String> _regions = [];
  List<String> _statuses = [];
  List<String> _tiers = [];

  @override
  void initState() {
    super.initState();
    _fetchTournaments();
  }

  Future<void> _fetchTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch all, live, and upcoming tournaments in a single call
      final response = await ApiService.getTournaments();

      if (response['error'] == false) {
        final tournaments = response['tournaments'] as List<dynamic>? ?? [];
        final live = response['liveTournaments'] as List<dynamic>? ?? [];
        final upcoming = response['upcomingTournaments'] as List<dynamic>? ?? [];

        // Extract filter options from all tournaments
        final games = <String>{};
        final regions = <String>{};
        final statuses = <String>{};
        final tiers = <String>{};

        for (var t in tournaments) {
          if (t['gameTitle'] != null) games.add(t['gameTitle']);
          if (t['region'] != null) regions.add(t['region']);
          if (t['status'] != null) statuses.add(t['status']);
          if (t['tier'] != null) tiers.add(t['tier']);
        }

        // Determine featured tournament
        Map<String, dynamic>? featured;
        if (live.isNotEmpty) {
          featured = live[0];
        } else if (upcoming.isNotEmpty) {
          featured = upcoming[0];
        } else if (tournaments.isNotEmpty) {
          featured = tournaments[0];
        }

        setState(() {
          _tournaments = tournaments;
          _liveTournaments = live;
          _upcomingTournaments = upcoming;
          _featuredTournament = featured;
          _games = games.toList()..sort();
          _regions = regions.toList()..sort();
          _statuses = statuses.toList()..sort();
          _tiers = tiers.toList()..sort();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] as String? ?? 'Failed to load tournaments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredTournaments {
    return _tournaments.where((tournament) {
      final matchesSearch = _searchTerm.isEmpty ||
          (tournament['tournamentName'] ?? '')
              .toLowerCase()
              .contains(_searchTerm.toLowerCase()) ||
          (tournament['shortName'] ?? '')
              .toLowerCase()
              .contains(_searchTerm.toLowerCase());

      final matchesGame =
          _selectedGame.isEmpty || tournament['gameTitle'] == _selectedGame;
      final matchesRegion =
          _selectedRegion.isEmpty || tournament['region'] == _selectedRegion;
      final matchesStatus =
          _selectedStatus.isEmpty || tournament['status'] == _selectedStatus;
      final matchesTier =
          _selectedTier.isEmpty || tournament['tier'] == _selectedTier;

      return matchesSearch &&
          matchesGame &&
          matchesRegion &&
          matchesStatus &&
          matchesTier;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchTerm.isNotEmpty ||
          _selectedGame.isNotEmpty ||
          _selectedRegion.isNotEmpty ||
          _selectedStatus.isNotEmpty ||
          _selectedTier.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _searchTerm = '';
      _selectedGame = '';
      _selectedRegion = '';
      _selectedStatus = '';
      _selectedTier = '';
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181b),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: Color(0xFFef4444)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF27272a)),
            // Filter options
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  _buildFilterSection(
                    'Game',
                    _games,
                    _selectedGame,
                        (value) => setState(() => _selectedGame = value),
                    Icons.sports_esports,
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    'Region',
                    _regions,
                    _selectedRegion,
                        (value) => setState(() => _selectedRegion = value),
                    Icons.public,
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    'Status',
                    _statuses,
                    _selectedStatus,
                        (value) => setState(() => _selectedStatus = value),
                    Icons.schedule,
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    'Tier',
                    _tiers,
                    _selectedTier,
                        (value) => setState(() => _selectedTier = value),
                    Icons.star,
                  ),
                ],
              ),
            ),
            // Apply button
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0891b2),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
      String title,
      List<String> options,
      String selected,
      Function(String) onSelect,
      IconData icon,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF06b6d4), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // "All" option
            _buildFilterChip(
              'All',
              selected.isEmpty,
                  () {
                onSelect('');
                Navigator.pop(context);
              },
            ),
            // Other options
            ...options.map((option) => _buildFilterChip(
              option,
              selected == option,
                  () {
                onSelect(option);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF06b6d4).withOpacity(0.2)
              : const Color(0xFF27272a),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF06b6d4)
                : const Color(0xFF27272a),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF06b6d4) : Colors.grey.shade400,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 👇 ADD THIS - Required for AutomaticKeepAliveClientMixin
    super.build(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090b),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF06b6d4)),
              const SizedBox(height: 16),
              Text(
                'Loading tournaments...',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090b),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTournaments,
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

    return Scaffold(
      backgroundColor: const Color(0xFF09090b),
      body: RefreshIndicator(
        onRefresh: _fetchTournaments,
        color: const Color(0xFF06b6d4),
        backgroundColor: const Color(0xFF18181b),
        child: CustomScrollView(
          slivers: [
            // Header with stats
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Tournaments',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discover competitive tournaments',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatChip(
                          '${_liveTournaments.length}',
                          'Live',
                          const Color(0xFFef4444),
                        ),
                        const SizedBox(width: 16),
                        _buildStatChip(
                          '${_upcomingTournaments.length}',
                          'Upcoming',
                          const Color(0xFF06b6d4),
                        ),
                        const SizedBox(width: 16),
                        _buildStatChip(
                          '${_tournaments.length}',
                          'Total',
                          Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Featured Tournament
            if (_featuredTournament != null)
              SliverToBoxAdapter(
                child: _buildFeaturedTournament(_featuredTournament!),
              ),

            // Search and Filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      onChanged: (value) => setState(() => _searchTerm = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search tournaments...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF06b6d4)),
                        filled: true,
                        fillColor: const Color(0xFF18181b),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF27272a)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF27272a)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF06b6d4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filter button
                    ElevatedButton.icon(
                      onPressed: _showFilterSheet,
                      icon: const Icon(Icons.filter_list),
                      label: Text(_hasActiveFilters ? 'Filters (Active)' : 'Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasActiveFilters
                            ? const Color(0xFF0891b2)
                            : const Color(0xFF18181b),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _hasActiveFilters
                                ? const Color(0xFF0891b2)
                                : const Color(0xFF27272a),
                          ),
                        ),
                      ),
                    ),
                    // Active filters display
                    if (_hasActiveFilters) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_searchTerm.isNotEmpty)
                            _buildActiveFilterChip(
                              'Search: "$_searchTerm"',
                                  () => setState(() => _searchTerm = ''),
                            ),
                          if (_selectedGame.isNotEmpty)
                            _buildActiveFilterChip(
                              _selectedGame,
                                  () => setState(() => _selectedGame = ''),
                            ),
                          if (_selectedRegion.isNotEmpty)
                            _buildActiveFilterChip(
                              _selectedRegion,
                                  () => setState(() => _selectedRegion = ''),
                            ),
                          if (_selectedStatus.isNotEmpty)
                            _buildActiveFilterChip(
                              _selectedStatus,
                                  () => setState(() => _selectedStatus = ''),
                            ),
                          if (_selectedTier.isNotEmpty)
                            _buildActiveFilterChip(
                              '${_selectedTier}-Tier',
                                  () => setState(() => _selectedTier = ''),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Results count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  '${_filteredTournaments.length} Tournaments Found',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Tournaments list
            if (_filteredTournaments.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🔍',
                        style: TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tournaments found',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasActiveFilters
                            ? 'Try adjusting your filters'
                            : 'No tournaments available',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _clearFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0891b2),
                          ),
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final tournament = _filteredTournaments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildTournamentCard(tournament),
                      );
                    },
                    childCount: _filteredTournaments.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF06b6d4).withOpacity(0.2),
        border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF06b6d4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF06b6d4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTournament(Map<String, dynamic> tournament) {
    final isLive = _liveTournaments.contains(tournament);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b),
        border: Border.all(color: const Color(0xFFf97316).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Live/Featured badge
          Row(
            children: [
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFef4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFef4444).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFef4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE NOW',
                        style: TextStyle(
                          color: Color(0xFFef4444),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf97316).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFf97316).withOpacity(0.3)),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      color: Color(0xFFf97316),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Tournament info
          Row(
            children: [
              // Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
                  ),
                ),
                child: tournament['media']?['logo'] != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    tournament['media']['logo'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.sports_esports, color: Colors.white),
                  ),
                )
                    : const Icon(Icons.sports_esports, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              // Name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament['tournamentName'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tournament['gameTitle'] ?? 'Unknown'} • ${tournament['region'] ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // View Details button
          ElevatedButton(
            onPressed: () {
              // Navigate to tournament details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFf97316),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(Map<String, dynamic> tournament) {
    final liveStatuses = [
      'in_progress',
      'qualifiers_in_progress',
      'group_stage',
      'playoffs',
      'finals'
    ];
    final upcomingStatuses = [
      'announced',
      'registration_open',
      'registration_closed'
    ];
    final status = tournament['status'] ?? '';
    final isLive = liveStatuses.contains(status);
    final isUpcoming = upcomingStatuses.contains(status);
    final isCompleted = status == 'completed';

    return GestureDetector(
      onTap: () {
        // Navigate to tournament details
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181b),
          border: Border.all(color: const Color(0xFF27272a)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with logo and status
            Row(
              children: [
                // Logo
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06b6d4), Color(0xFF7c3aed)],
                    ),
                  ),
                  child: tournament['media']?['logo'] != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      tournament['media']['logo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.sports_esports,
                          color: Colors.white, size: 25),
                    ),
                  )
                      : const Icon(Icons.sports_esports,
                      color: Colors.white, size: 25),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament['tournamentName'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.sports_esports,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            tournament['gameTitle'] ?? 'Unknown',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                if (isLive)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFef4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFef4444).withOpacity(0.3)),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFFef4444),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isUpcoming)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06b6d4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF06b6d4).withOpacity(0.3)),
                    ),
                    child: const Text(
                      'UPCOMING',
                      style: TextStyle(
                        color: Color(0xFF06b6d4),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isCompleted)
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Text(
                        'COMPLETED',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 12),
            // Details row
            Row(
              children: [
                Icon(Icons.public, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  tournament['region'] ?? 'Unknown',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(width: 12),
                if (tournament['tier'] != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTierColor(tournament['tier']).withOpacity(0.1),
                      border: Border.all(
                          color: _getTierColor(tournament['tier']).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${tournament['tier']}-Tier',
                      style: TextStyle(
                        color: _getTierColor(tournament['tier']),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF27272a)),
            const SizedBox(height: 12),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  Icons.emoji_events,
                  'Prize Pool',
                  _formatPrizePool(tournament['prizePool']),
                  const Color(0xFF16a34a),
                ),
                _buildStatColumn(
                  Icons.calendar_today,
                  'Start Date',
                  _formatDate(tournament['startDate']),
                  const Color(0xFF06b6d4),
                ),
                _buildStatColumn(
                  Icons.people,
                  'Teams',
                  '${_getParticipatingTeamsCount(tournament)}/${_getTotalSlots(tournament)}',
                  const Color(0xFF7c3aed),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getTierColor(String? tier) {
    switch (tier) {
      case 'S':
        return const Color(0xFFf59e0b);
      case 'A':
        return const Color(0xFF3b82f6);
      case 'B':
        return const Color(0xFF16a34a);
      case 'C':
        return Colors.grey.shade400;
      default:
        return const Color(0xFFf97316);
    }
  }

  String _formatPrizePool(dynamic prizePool) {
    if (prizePool == null || prizePool['total'] == null || prizePool['total'] == 0) {
      return 'TBD';
    }

    final amount = prizePool['total'] as num;
    final currency = prizePool['currency'] ?? 'INR';
    final symbol = currency == 'INR' ? '₹' : currency == 'USD' ? '\$' : currency;

    if (amount >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol$amount';
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'TBD';
    try {
      final date = DateTime.parse(dateString);
      return '${_getMonthShort(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return 'TBD';
    }
  }

  String _getMonthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  int _getParticipatingTeamsCount(Map<String, dynamic> tournament) {
    if (tournament['participatingTeams'] != null &&
        tournament['participatingTeams'] is List) {
      return (tournament['participatingTeams'] as List).length;
    }
    return tournament['statistics']?['totalParticipatingTeams'] ?? 0;
  }

  dynamic _getTotalSlots(Map<String, dynamic> tournament) {
    return tournament['slots']?['total'] ?? 'TBD';
  }
}