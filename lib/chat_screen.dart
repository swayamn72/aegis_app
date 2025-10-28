import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert'; // <-- FIX 1: Added import
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/chat_service.dart';
// import '../services/api_service.dart'; // This import seems unused in this file
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Socket connection
  IO.Socket? _socket;

  // User data
  String? _userId;
  Map<String, dynamic>? _currentUser;

  // Chat data
  List<dynamic> _connections = [];
  List<dynamic> _tryoutChats = [];
  List<dynamic> _teamApplications = [];
  // List<dynamic> _recruitmentApproaches = []; // <-- FIX 4: Commented out unused variable
  Map<String, int> _unreadCounts = {};

  // Selected chat
  dynamic _selectedChat;
  String _chatType = 'direct'; // 'direct' or 'tryout'
  List<dynamic> _messages = [];

  // UI state
  bool _isLoading = true;
  bool _isLoadingMessages = false;
  bool _showApplications = false;
  String _searchTerm = '';

  // Input
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Modals
  bool _showEndTryoutModal = false;
  bool _showOfferModal = false;
  String _endReason = '';
  String _offerMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeChat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);

    try {
      // Get user data
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString != null) {
        _currentUser = Map<String, dynamic>.from(
            jsonDecode(userDataString) // <-- FIX 2: Changed to jsonDecode
        );
        _userId = _currentUser?['_id'];
      }

      // Initialize socket
      await _connectSocket();

      // Fetch data
      await Future.wait([
        _fetchConnections(),
        _fetchTryoutChats(),
        _fetchTeamApplications(),
        // _fetchRecruitmentApproaches(), // <-- FIX 4: Commented out fetch call
        _fetchUnreadCounts(),
      ]);

      // Select first chat if available
      if (_connections.isNotEmpty) {
        _selectChat(_connections[0], 'direct');
      }

    } catch (e) {
      _showError('Failed to initialize chat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectSocket() async {
    try {
      _socket = IO.io('http://10.0.2.2:5000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket?.connect();

      _socket?.on('connect', (_) {
        print('Socket connected');
        if (_userId != null) {
          _socket?.emit('join', _userId);
        }
      });

      _socket?.on('disconnect', (_) {
        print('Socket disconnected');
      });

      _socket?.on('receiveMessage', (data) {
        _handleReceiveMessage(data);
      });

      _socket?.on('tryoutMessage', (data) {
        _handleTryoutMessage(data);
      });

      _socket?.on('tryoutEnded', (data) {
        _handleTryoutEnded(data);
      });

      _socket?.on('teamOfferSent', (data) {
        _handleTeamOfferSent(data);
      });

      _socket?.on('teamOfferAccepted', (data) {
        _handleTeamOfferAccepted(data);
      });

      _socket?.on('teamOfferRejected', (data) {
        _handleTeamOfferRejected(data);
      });

    } catch (e) {
      print('Socket connection error: $e');
    }
  }

  void _handleReceiveMessage(dynamic data) {
    if (_chatType == 'direct' && _selectedChat != null) {
      final senderId = data['senderId'].toString();
      final receiverId = data['receiverId'].toString();
      final selectedId = _selectedChat['_id'].toString();

      if (senderId == selectedId || receiverId == selectedId) {
        setState(() {
          _messages.add(data);
        });
        _scrollToBottom();
      }
    }
  }

  void _handleTryoutMessage(dynamic data) {
    if (_chatType == 'tryout' && _selectedChat != null) {
      if (data['chatId'] == _selectedChat['_id']) {
        setState(() {
          // Check for duplicates
          final messageExists = _messages.any((m) =>
          m['_id'] == data['message']['_id'] ||
              (m['_id'].toString().startsWith('temp_') &&
                  m['message'] == data['message']['message'])
          );

          if (!messageExists) {
            _messages.add(data['message']);
          }
        });
        _scrollToBottom();
      }
    }
  }

  void _handleTryoutEnded(dynamic data) {
    if (_chatType == 'tryout' && _selectedChat != null) {
      if (data['chatId'] == _selectedChat['_id']) {
        setState(() {
          _selectedChat['tryoutStatus'] = data['tryoutStatus'];
          if (data['message'] != null) {
            _messages.add(data['message']);
          }
        });
        _showSnackBar('Tryout has been ended', isError: false);
      }
    }
  }

  void _handleTeamOfferSent(dynamic data) {
    if (_chatType == 'tryout' && _selectedChat != null) {
      if (data['chatId'] == _selectedChat['_id']) {
        setState(() {
          _selectedChat['tryoutStatus'] = 'offer_sent';
          _selectedChat['teamOffer'] = data['offer'];
          if (data['message'] != null) {
            _messages.add(data['message']);
          }
        });
        _showSnackBar('Team offer received!', isError: false);
      }
    }
  }

  void _handleTeamOfferAccepted(dynamic data) {
    if (_chatType == 'tryout' && _selectedChat != null) {
      if (data['chatId'] == _selectedChat['_id']) {
        setState(() {
          _selectedChat['tryoutStatus'] = 'offer_accepted';
          if (data['message'] != null) {
            _messages.add(data['message']);
          }
        });
        _showSnackBar('Player joined the team!', isError: false);
      }
    }
  }

  void _handleTeamOfferRejected(dynamic data) {
    if (_chatType == 'tryout' && _selectedChat != null) {
      if (data['chatId'] == _selectedChat['_id']) {
        setState(() {
          _selectedChat['tryoutStatus'] = 'offer_rejected';
          if (data['message'] != null) {
            _messages.add(data['message']);
          }
        });
        _showSnackBar('Player declined the team offer', isError: false);
      }
    }
  }

  Future<void> _fetchConnections() async {
    final result = await ChatService.getChatUsers();
    if (result['error'] == false) {
      setState(() {
        _connections = result['data']['users'] ?? [];
      });
    }
  }

  Future<void> _fetchTryoutChats() async {
    final result = await ChatService.getTryoutChats();
    if (result['error'] == false) {
      setState(() {
        _tryoutChats = result['data']['chats'] ?? [];
      });
    }
  }

  Future<void> _fetchTeamApplications() async {
    // Guard if current user not loaded
    if (_currentUser == null) return;

    // Normalize team field and extract a string ID safely
    final dynamic teamField = _currentUser!['team'];
    if (teamField == null) return;

    String? teamId;
    if (teamField is Map) {
      final id = teamField['_id'];
      if (id != null) teamId = id.toString();
    } else {
      teamId = teamField.toString();
    }

    if (teamId == null || teamId.isEmpty) return;

    final result = await ChatService.getTeamApplicationsSummary(teamId);
    if (result['error'] == false) {
      setState(() {
        _teamApplications = result['data']['recentApplications'] ?? [];
      });
    }
  }

  // <-- FIX 4: Commented out unused function
  Future<void> _fetchRecruitmentApproaches() async {
    // final result = await ChatService.getRecruitmentApproaches();
    // if (result['error'] == false) {
    //   setState(() {
    //     _recruitmentApproaches = result['data']['approaches'] ?? [];
    //   });
    // }
  }

  Future<void> _fetchUnreadCounts() async {
    final result = await ChatService.getUnreadCounts();
    if (result['error'] == false) {
      setState(() {
        final counts = result['data']['unreadCounts'] as List?;
        if (counts != null) {
          _unreadCounts = {
            for (var item in counts)
              item['_id'].toString(): item['count'] as int
          };
        }
      });
    }
  }

  Future<void> _selectChat(dynamic chat, String type) async {
    setState(() {
      _selectedChat = chat;
      _chatType = type;
      _isLoadingMessages = true;
      _messages = [];
    });

    try {
      if (type == 'direct') {
        final chatId = chat['_id'];
        if (chatId == 'system') {
          await _fetchSystemMessages();
        } else {
          await _fetchDirectMessages(chatId);
        }
        // Mark as read
        if (chatId != 'system') {
          await ChatService.markMessagesAsRead(chatId);
        }
      } else if (type == 'tryout') {
        await _fetchTryoutMessages(chat['_id']);
        // Join tryout room
        _socket?.emit('joinTryoutChat', chat['_id']);
      }
    } catch (e) {
      _showError('Failed to load messages');
    } finally {
      setState(() => _isLoadingMessages = false);
      _scrollToBottom();
    }
  }

  Future<void> _fetchDirectMessages(String receiverId) async {
    final result = await ChatService.getMessages(receiverId);
    if (result['error'] == false) {
      setState(() {
        _messages = result['messages'] ?? [];
      });
    }
  }

  Future<void> _fetchSystemMessages() async {
    final result = await ChatService.getSystemMessages();
    if (result['error'] == false) {
      setState(() {
        _messages = result['messages'] ?? [];
      });
    }
  }

  Future<void> _fetchTryoutMessages(String chatId) async {
    final result = await ChatService.getTryoutChat(chatId);
    if (result['error'] == false) {
      final chatData = result['data']['chat'];
      setState(() {
        _messages = chatData['messages'] ?? [];
        _selectedChat = chatData;
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _selectedChat == null) return;

    final message = _messageController.text.trim();

    // Check if tryout is ended
    if (_chatType == 'tryout') {
      final restrictedStatuses = [
        'ended_by_team',
        'ended_by_player',
        'offer_sent',
        'offer_accepted',
        'offer_rejected'
      ];
      if (restrictedStatuses.contains(_selectedChat['tryoutStatus'])) {
        _showError('This tryout has ended. No new messages can be sent.');
        return;
      }
    }

    // Prevent sending to 'system'
    if (_chatType == 'direct' && _selectedChat['_id'] == 'system') {
      _showError('You cannot reply to system messages.');
      return;
    }

    if (_chatType == 'direct') {
      final msg = {
        'senderId': _userId,
        'receiverId': _selectedChat['_id'],
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };
      _socket?.emit('sendMessage', msg);
      setState(() {
        _messages.add(msg);
      });
    } else if (_chatType == 'tryout') {
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final optimisticMessage = {
        '_id': tempId,
        'sender': _userId,
        'message': message,
        'messageType': 'text',
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _messages.add(optimisticMessage);
      });

      _socket?.emit('tryoutMessage', {
        'chatId': _selectedChat['_id'],
        'senderId': _userId,
        'message': message,
      });
    }

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startTryout(String applicationId) async {
    final result = await ChatService.startTryout(applicationId);
    if (result['error'] == false) {
      _showSnackBar('Tryout started!', isError: false);
      await _fetchTeamApplications();
      await _fetchTryoutChats();

      final tryoutChat = result['data']['tryoutChat'];
      _selectChat(tryoutChat, 'tryout');
      setState(() => _showApplications = false);
    } else {
      _showError(result['message']);
    }
  }

  Future<void> _rejectApplication(String applicationId) async {
    final result = await ChatService.rejectApplication(
      applicationId,
      'Not suitable at this time',
    );
    if (result['error'] == false) {
      _showSnackBar('Application rejected', isError: false);
      await _fetchTeamApplications();
    } else {
      _showError(result['message']);
    }
  }

  Future<void> _endTryout() async {
    if (_endReason.trim().isEmpty) {
      _showError('Please provide a reason for ending the tryout');
      return;
    }

    final result = await ChatService.endTryout(
      _selectedChat['_id'],
      _endReason,
    );

    if (result['error'] == false) {
      _showSnackBar('Tryout ended successfully', isError: false);
      setState(() {
        _showEndTryoutModal = false;
        _endReason = '';
      });
      await _fetchTryoutMessages(_selectedChat['_id']);
    } else {
      _showError(result['message']);
    }
  }

  Future<void> _sendTeamOffer() async {
    final result = await ChatService.sendTeamOffer(
      _selectedChat['_id'],
      _offerMessage.isEmpty
          ? 'We would like to invite you to join our team!'
          : _offerMessage,
    );

    if (result['error'] == false) {
      _showSnackBar('Team offer sent!', isError: false);
      setState(() {
        _showOfferModal = false;
        _offerMessage = '';
      });
      await _fetchTryoutMessages(_selectedChat['_id']);
    } else {
      _showError(result['message']);
    }
  }

  Future<void> _acceptTeamOffer() async {
    final result = await ChatService.acceptTeamOffer(_selectedChat['_id']);

    if (result['error'] == false) {
      _showSnackBar('You joined the team!', isError: false);
      await _fetchTryoutMessages(_selectedChat['_id']);
    } else {
      _showError(result['message']);
    }
  }

  Future<void> _rejectTeamOffer() async {
    final result = await ChatService.rejectTeamOffer(
      _selectedChat['_id'],
      reason: 'Not interested at this time',
    );

    if (result['error'] == false) {
      _showSnackBar('Team offer declined', isError: false);
      await _fetchTryoutMessages(_selectedChat['_id']);
    } else {
      _showError(result['message']);
    }
  }

  void _showError(String message) {
    _showSnackBar(message, isError: true);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFef4444)
            : const Color(0xFF16a34a),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp == null) {
        return '';
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        // fallback
        return '';
      }

      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return DateFormat('MMM d').format(date);
    } catch (e) {
      return '';
    }
  }

  List<dynamic> get _filteredConnections {
    if (_searchTerm.isEmpty) return _connections;
    return _connections.where((conn) {
      final username = (conn['username'] ?? '').toString().toLowerCase();
      final realName = (conn['realName'] ?? '').toString().toLowerCase();
      final search = _searchTerm.toLowerCase();
      return username.contains(search) || realName.contains(search);
    }).toList();
  }

  // <-- FIX 3: Renamed 'build' to '_buildChatPage'
  Widget _buildChatPage(BuildContext context) {
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
                'Loading chats...',
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

    return Scaffold(
      backgroundColor: const Color(0xFF09090b),
      body: Row(
        children: [
          // Left Sidebar - Chat List
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF18181b).withOpacity(0.5),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF06b6d4),
                                  Color(0xFF7c3aed),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chat_bubble,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Chats',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_teamApplications.isNotEmpty)
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showApplications = true; // <-- FIX 3: Changed comma to semicolon
                                    });
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
                                    child: Text(
                                      '${_teamApplications.length}',
                                      style: const TextStyle(
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Search
                      TextField(
                        onChanged: (value) {
                          setState(() => _searchTerm = value);
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF27272a),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs
                if (_tryoutChats.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272a).withOpacity(0.3),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey.shade400,
                      indicatorColor: const Color(0xFF06b6d4),
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Direct'),
                        Tab(text: 'Tryouts'),
                      ],
                    ),
                  ),

                // Chat List
                Expanded(
                  child: _tryoutChats.isEmpty
                      ? _buildDirectChatsList()
                      : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDirectChatsList(),
                      _buildTryoutChatsList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right Side - Chat Window
          Expanded(
            child: _selectedChat == null
                ? _buildEmptyState()
                : _buildChatWindow(),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectChatsList() {
    if (_filteredConnections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredConnections.length,
      itemBuilder: (context, index) {
        final conn = _filteredConnections[index];
        final isSelected = _selectedChat?['_id'] == conn['_id'] &&
            _chatType == 'direct';
        final unreadCount = _unreadCounts[conn['_id'].toString()] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
              colors: [
                Color(0xFF06b6d4),
                Color(0xFF7c3aed),
              ],
            )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => _selectChat(conn, 'direct'),
            leading: Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.3)
                          : const Color(0xFF27272a),
                      width: 2,
                    ),
                    image: conn['profilePicture'] != null
                        ? DecorationImage(
                      image: NetworkImage(conn['profilePicture']),
                      fit: BoxFit.cover,
                    )
                        : null,
                    gradient: conn['profilePicture'] == null
                        ? LinearGradient(
                      colors: conn['_id'] == 'system'
                          ? [
                        const Color(0xFF3b82f6),
                        const Color(0xFF2563eb),
                      ]
                          : [
                        const Color(0xFF06b6d4),
                        const Color(0xFF7c3aed),
                      ],
                    )
                        : null,
                  ),
                  child: conn['profilePicture'] == null
                      ? Center(
                      child: Icon(
                        conn['_id'] == 'system' ? Icons.info_outline : Icons.person,
                        color: Colors.white,
                        size: conn['_id'] == 'system' ? 24 : 18,
                      )
                  )
                      : null,
                ),
                if (conn['isOnline'] == true && conn['_id'] != 'system')
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16a34a),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF18181b),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              conn['realName'] ?? conn['username'] ?? 'Unknown',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '@${conn['username'] ?? 'unknown'}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade500,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: unreadCount > 0
                ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFef4444),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildTryoutChatsList() {
    if (_tryoutChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'No active tryouts',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _tryoutChats.length,
      itemBuilder: (context, index) {
        final chat = _tryoutChats[index];
        final isSelected = _selectedChat?['_id'] == chat['_id'] &&
            _chatType == 'tryout';

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
              colors: [
                Color(0xFFf59e0b),
                Color(0xFFef4444),
              ],
            )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => _selectChat(chat, 'tryout'),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : const Color(0xFF27272a),
                  width: 2,
                ),
                image: chat['team']?['logo'] != null
                    ? DecorationImage(
                  image: NetworkImage(chat['team']['logo']),
                  fit: BoxFit.cover,
                )
                    : null,
                gradient: chat['team']?['logo'] == null
                    ? const LinearGradient(
                  colors: [
                    Color(0xFFf59e0b),
                    Color(0xFFef4444),
                  ],
                )
                    : null,
              ),
              child: chat['team']?['logo'] == null
                  ? Center(
                child: Text(
                  (chat['team']?['teamName'] ?? 'T')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : null,
            ),
            title: Text(
              '${chat['team']?['teamName'] ?? 'Unknown'} Tryout',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Tryout: ${chat['applicant']?['username'] ?? 'Unknown'}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade500,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFf59e0b).withOpacity(0.2),
                border: Border.all(
                  color: const Color(0xFFf59e0b).withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.bolt,
                color: Color(0xFFf59e0b),
                size: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a chat to start messaging',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatWindow() {
    return Column(
      children: [
        // Chat Header
        _buildChatHeader(),

        // Messages
        Expanded(
          child: _isLoadingMessages
              ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF06b6d4),
            ),
          )
              : _buildMessagesList(),
        ),

        // Input Area
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatHeader() {
    final isTryout = _chatType == 'tryout';
    final tryoutStatus = isTryout ? _selectedChat['tryoutStatus'] : '';
    final isCaptain = _currentUser?['team']?['captain'] == _userId;
    final isApplicant = isTryout && _selectedChat['applicant']?['_id'] == _userId;
    final isSystemChat = _chatType == 'direct' && _selectedChat['_id'] == 'system';


    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b).withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF27272a),
                width: 2,
              ),
              image: _getChatAvatar() != null
                  ? DecorationImage(
                image: NetworkImage(_getChatAvatar()!),
                fit: BoxFit.cover,
              )
                  : null,
              gradient: _getChatAvatar() == null
                  ? LinearGradient(
                colors: isTryout
                    ? [
                  const Color(0xFFf59e0b),
                  const Color(0xFFef4444),
                ]
                    : isSystemChat
                    ? [
                  const Color(0xFF3b82f6),
                  const Color(0xFF2563eb),
                ]
                    : [
                  const Color(0xFF06b6d4),
                  const Color(0xFF7c3aed),
                ],
              )
                  : null,
            ),
            child: _getChatAvatar() == null
                ? Center(
              child: Icon(
                isSystemChat ? Icons.info_outline : Icons.person,
                color: Colors.white,
                size: isSystemChat ? 24 : 18,
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),
          // Chat Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getChatName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isTryout) _buildTryoutStatusBadge(tryoutStatus),
                  ],
                ),
                Text(
                  _getChatSubtitle(),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Actions
          if (isTryout && tryoutStatus == 'active')
            if (isCaptain) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showOfferModal = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16a34a),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text('Offer', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showEndTryoutModal = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFef4444),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('End', style: TextStyle(fontSize: 12)),
              ),
            ] else if (isApplicant) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showEndTryoutModal = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFef4444),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('End', style: TextStyle(fontSize: 12)),
              ),
            ],
          if (isTryout && tryoutStatus == 'offer_sent' && isApplicant) ...[
            ElevatedButton.icon(
              onPressed: _acceptTeamOffer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16a34a),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Accept', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _rejectTeamOffer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFef4444),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Decline', style: TextStyle(fontSize: 12)),
            ),
          ],
          if (!isSystemChat)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                // Show more options
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTryoutStatusBadge(String? status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = const Color(0xFFf59e0b);
        label = 'Active';
        break;
      case 'offer_sent':
        color = const Color(0xFF3b82f6);
        label = 'Offer Pending';
        break;
      case 'offer_accepted':
        color = const Color(0xFF16a34a);
        label = 'Joined';
        break;
      case 'offer_rejected':
        color = const Color(0xFF6b7280);
        label = 'Declined';
        break;
      case 'ended_by_team':
      case 'ended_by_player':
        color = const Color(0xFFef4444);
        label = 'Ended';
        break;
      default:
        color = const Color(0xFF6b7280);
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String? _getChatAvatar() {
    if (_chatType == 'tryout') {
      return _selectedChat['team']?['logo'];
    }
    return _selectedChat['profilePicture']; // Will be null for system
  }

  String _getChatName() {
    if (_chatType == 'tryout') {
      return '${_selectedChat['team']?['teamName'] ?? 'Unknown'} Tryout';
    }
    return _selectedChat['realName'] ??
        _selectedChat['username'] ??
        'Unknown';
  }

  String _getChatSubtitle() {
    if (_chatType == 'tryout') {
      return 'Applicant: ${_selectedChat['applicant']?['username'] ?? 'Unknown'}';
    }
    if (_chatType == 'direct' && _selectedChat['_id'] == 'system') {
      return 'System Notifications';
    }
    return '@${_selectedChat['username'] ?? 'unknown'}';
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 64,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message, index);
      },
    );
  }

  Widget _buildMessageBubble(dynamic message, int index) {
    // Normalize message to a Map to avoid runtime/indexing errors
    final Map<String, dynamic> msg = (message is Map)
        ? Map<String, dynamic>.from(message as Map)
        : {
            'message': message?.toString() ?? '',
            'timestamp': DateTime.now().toIso8601String(),
          };

    final isSystemChat = _chatType == 'direct' && _selectedChat['_id'] == 'system';

    final bool isMine = _chatType == 'direct'
        ? (msg['senderId'] == _userId)
        : (msg['sender'] == _userId ||
            (msg['sender'] is Map && msg['sender']?['_id'] == _userId));

    final bool isSystemMessage = (msg['messageType'] == 'system') ||
        (msg['sender'] == 'system') ||
        isSystemChat;

    if (isSystemMessage) {
      return _buildSystemMessage(msg);
    }

    // Show sender info in group chats
    String? senderName;
    if (_chatType == 'tryout' && !isMine) {
      if (msg['sender'] is Map) {
        senderName = msg['sender']['username']?.toString();
      }
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  senderName,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: isMine
                    ? const LinearGradient(
                        colors: [
                          Color(0xFFf59e0b),
                          Color(0xFFef4444),
                        ],
                      )
                    : null,
                color: isMine ? null : const Color(0xFF27272a),
                borderRadius: BorderRadius.circular(16),
                border: isMine
                    ? null
                    : Border.all(
                        color: const Color(0xFF3f3f46),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['message']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msg['timestamp']),
                    style: TextStyle(
                      color: isMine
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(Map<String, dynamic> message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF27272a).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3f3f46),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3b82f6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF3b82f6),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message['message'] ?? '',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final restrictedStatuses = [
      'ended_by_team',
      'ended_by_player',
      'offer_sent',
      'offer_accepted',
      'offer_rejected'
    ];

    final isTryoutRestricted = _chatType == 'tryout' &&
        restrictedStatuses.contains(_selectedChat['tryoutStatus']);

    final isSystemChat = _chatType == 'direct' && _selectedChat['_id'] == 'system';


    if (isTryoutRestricted || isSystemChat) {
      String message = isSystemChat
          ? 'You cannot reply to system messages.'
          : 'This tryout has ended. No new messages can be sent.';

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181b).withOpacity(0.5),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181b).withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: const Color(0xFF27272a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFf59e0b),
                  Color(0xFFef4444),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modals and Overlays

  Widget _buildApplicationsOverlay() {
    if (!_showApplications) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showApplications = false),
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Container(
                margin: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181b),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFf59e0b),
                                  Color(0xFFef4444),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Team Applications (${_teamApplications.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() => _showApplications = false);
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Color(0xFF27272a),
                      height: 1,
                    ),
                    // Applications List
                    Flexible(
                      child: _teamApplications.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pending applications',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _teamApplications.length,
                        itemBuilder: (context, index) {
                          final app = _teamApplications[index];
                          return _buildApplicationCard(app);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final player = app['player'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272a).withOpacity(0.5),
        border: Border.all(
          color: const Color(0xFF3f3f46),
        ),
        borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3f3f46),
                    width: 2,
                  ),
                  image: player['profilePicture'] != null
                      ? DecorationImage(
                    image: NetworkImage(player['profilePicture']),
                    fit: BoxFit.cover,
                  )
                      : null,
                  gradient: player['profilePicture'] == null
                      ? const LinearGradient(
                    colors: [
                      Color(0xFF06b6d4),
                      Color(0xFF7c3aed),
                    ],
                  )
                      : null,
                ),
                child: player['profilePicture'] == null
                    ? Center(
                  child: Text(
                    (player['username'] ?? 'U')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player['username'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rating: ${player['aegisRating'] ?? 0}',
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
          if (app['appliedRoles'] != null && app['appliedRoles'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (app['appliedRoles'] as List).map((role) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06b6d4).withOpacity(0.2),
                      border: Border.all(
                        color: const Color(0xFF06b6d4).withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role.toString(),
                      style: const TextStyle(
                        color: Color(0xFF06b6d4),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startTryout(app['_id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16a34a),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text(
                    'Start Tryout',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rejectApplication(app['_id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27272a),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text(
                    'Reject',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // This is now the one and only 'build' method
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildChatPage(context), // <-- FIX 3: Call the renamed page-building widget
        _buildApplicationsOverlay(),
        if (_showEndTryoutModal) _buildEndTryoutModal(),
        if (_showOfferModal) _buildOfferModal(),
      ],
    );
  }

  Widget _buildEndTryoutModal() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showEndTryoutModal = false),
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181b),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'End Tryout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Are you sure you want to end this tryout? No further messages can be sent after ending.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        setState(() => _endReason = value);
                      },
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Reason for ending (required)',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: const Color(0xFF27272a),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showEndTryoutModal = false;
                                _endReason = '';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27272a),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _endReason.trim().isEmpty
                                ? null
                                : _endTryout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFef4444),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('End Tryout'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferModal() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showOfferModal = false),
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping inside
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181b),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send Team Join Offer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invite ${_selectedChat['applicant']?['username'] ?? 'player'} to join your team.',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (value) {
                        setState(() => _offerMessage = value);
                      },
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Custom message (optional)',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        filled: true,
                        fillColor: const Color(0xFF27272a),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showOfferModal = false;
                                _offerMessage = '';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27272a),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _sendTeamOffer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16a34a),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Send Offer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

