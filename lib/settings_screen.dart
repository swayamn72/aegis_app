import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;
  String? _currentProfilePicture;

  // Controllers for form fields
  final _realNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _inGameNameController = TextEditingController();
  final _discordTagController = TextEditingController();
  final _twitchController = TextEditingController();
  final _youtubeController = TextEditingController();

  // Dropdown values
  String _selectedCountry = '';
  String _selectedPrimaryGame = '';
  String _selectedTeamStatus = '';
  String _selectedAvailability = '';
  String _selectedProfileVisibility = 'public';
  String _selectedCardTheme = 'orange';

  // Multi-select values
  List<String> _selectedLanguages = [];
  List<String> _selectedInGameRoles = [];
  bool _qualifiedEvents = false;
  List<String> _qualifiedEventDetails = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _realNameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _inGameNameController.dispose();
    _discordTagController.dispose();
    _twitchController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getProfile();

    if (result['error'] == false && result['data'] != null) {
      final data = result['data'];
      setState(() {
        _realNameController.text = data['realName'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _locationController.text = data['location'] ?? '';
        _selectedCountry = data['country'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _selectedLanguages = List<String>.from(data['languages'] ?? []);
        _currentProfilePicture = data['profilePicture'];
        _inGameNameController.text = data['inGameName'] ?? '';
        _selectedPrimaryGame = data['primaryGame'] ?? '';
        _qualifiedEvents = data['qualifiedEvents'] ?? false;
        _qualifiedEventDetails = List<String>.from(data['qualifiedEventDetails'] ?? []);
        _selectedInGameRoles = List<String>.from(data['inGameRole'] ?? []);
        _selectedTeamStatus = data['teamStatus'] ?? '';
        _selectedAvailability = data['availability'] ?? '';
        _discordTagController.text = data['discordTag'] ?? '';
        _twitchController.text = data['twitch'] ?? '';
        // FIX: backend uses lowercase 'youtube' field
        _youtubeController.text = data['youtube'] ?? '';
        _selectedProfileVisibility = data['profileVisibility'] ?? 'public';
        _selectedCardTheme = data['cardTheme'] ?? 'orange';
      });
    } else {
      _showError(result['message'] ?? 'Failed to load profile');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload profile picture if selected
      if (_selectedImage != null) {
        final uploadResult = await ApiService.uploadProfilePicture(_selectedImage!);
        if (uploadResult['error'] == true) {
          _showError(uploadResult['message'] ?? 'Failed to upload profile picture');
          setState(() => _isSaving = false);
          return;
        }
        _currentProfilePicture = uploadResult['data']['profilePicture'];
      }

      // Prepare profile data: only include non-empty / non-null fields
      final profileData = <String, dynamic>{};

      void addIfPresent(String key, dynamic value) {
        if (value == null) return;
        if (value is String && value.trim().isEmpty) return;
        profileData[key] = value;
      }

      addIfPresent('realName', _realNameController.text.trim());
      addIfPresent('age', int.tryParse(_ageController.text.trim()));
      addIfPresent('location', _locationController.text.trim());
      addIfPresent('country', _selectedCountry.isNotEmpty ? _selectedCountry : null);
      addIfPresent('bio', _bioController.text.trim());
      addIfPresent('languages', _selectedLanguages.isNotEmpty ? _selectedLanguages : null);
      addIfPresent('profilePicture', _currentProfilePicture);
      addIfPresent('inGameName', _inGameNameController.text.trim());
      addIfPresent('primaryGame', _selectedPrimaryGame.isNotEmpty ? _selectedPrimaryGame : null);
      addIfPresent('qualifiedEvents', _qualifiedEvents);
      addIfPresent('qualifiedEventDetails', _qualifiedEventDetails.isNotEmpty ? _qualifiedEventDetails : null);
      addIfPresent('inGameRole', _selectedInGameRoles.isNotEmpty ? _selectedInGameRoles : null);

      // IMPORTANT: only include enum fields if user selected a valid option (non-empty)
      if (_selectedTeamStatus.isNotEmpty) {
        addIfPresent('teamStatus', _selectedTeamStatus);
      }
      if (_selectedAvailability.isNotEmpty) {
        addIfPresent('availability', _selectedAvailability);
      }

      addIfPresent('discordTag', _discordTagController.text.trim());
      addIfPresent('twitch', _twitchController.text.trim());
      addIfPresent('youtube', _youtubeController.text.trim()); // FIX: lowercase key
      addIfPresent('profileVisibility', _selectedProfileVisibility.isNotEmpty ? _selectedProfileVisibility : null);
      addIfPresent('cardTheme', _selectedCardTheme.isNotEmpty ? _selectedCardTheme : null);

      final result = await ApiService.updateProfile(profileData);

      if (result['error'] == false) {
        _showSuccess('Profile updated successfully!');
        setState(() => _selectedImage = null);
      } else {
        _showError(result['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }

    setState(() => _isSaving = false);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090b),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181b),
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFF06b6d4),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF06b6d4),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Profile Picture',
                      children: [_buildProfilePictureSection()],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Personal Information',
                      children: [
                        _buildTextField(
                          controller: _realNameController,
                          label: 'Real Name',
                          hint: 'Enter your full name',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _ageController,
                          label: 'Age',
                          hint: 'Enter your age',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _locationController,
                          label: 'Location',
                          hint: 'City, State',
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Country',
                          value: _selectedCountry,
                          items: ['India', 'USA', 'UK', 'Canada', 'Australia'], // Example countries
                          hint: 'Select your country',
                          onChanged: (value) => setState(() => _selectedCountry = value!),
                        ),
                         const SizedBox(height: 16),
                        _buildTextField(
                          controller: _bioController,
                          label: 'Bio',
                          hint: 'Tell us about yourself',
                          maxLines: 4,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Gaming Profile',
                      children: [
                        _buildTextField(
                          controller: _inGameNameController,
                          label: 'In-Game Name (IGN)',
                          hint: 'Your primary IGN',
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Primary Game',
                          value: _selectedPrimaryGame,
                          items: ['Valorant', 'BGMI', 'CS:GO', 'Apex Legends'], // Example games
                          hint: 'Select your main game',
                          onChanged: (value) => setState(() => _selectedPrimaryGame = value!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Socials',
                      children: [
                        _buildTextField(
                          controller: _discordTagController,
                          label: 'Discord',
                          hint: 'username#1234',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _twitchController,
                          label: 'Twitch',
                          hint: 'twitch.tv/username',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _youtubeController,
                          label: 'YouTube',
                          hint: 'youtube.com/@username',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Preferences',
                      children: [
                        _buildDropdown(
                          label: 'Profile Visibility',
                          value: _selectedProfileVisibility,
                          // FIX: use allowed backend values only
                          items: const ['public', 'private'],
                          hint: 'Select Visibility',
                          onChanged: (value) {
                            setState(() => _selectedProfileVisibility = value!);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          label: 'Card Theme',
                          value: _selectedCardTheme,
                          items: const ['orange', 'blue', 'purple', 'red', 'green', 'pink'],
                          hint: 'Select Theme',
                          onChanged: (value) {
                            setState(() => _selectedCardTheme = value!);
                          },
                        ),
                        const SizedBox(height: 16),

                        // NEW: Team Status dropdown (backend enum)
                        _buildDropdown(
                          label: 'Team Status',
                          value: _selectedTeamStatus,
                          items: const [
                            'looking for a team',
                            'in a team',
                            'open for offers'
                          ],
                          hint: 'Select Team Status',
                          onChanged: (value) {
                            setState(() => _selectedTeamStatus = value ?? '');
                          },
                        ),
                        const SizedBox(height: 16),

                        // NEW: Availability dropdown (backend enum)
                        _buildDropdown(
                          label: 'Availability',
                          value: _selectedAvailability,
                          items: const [
                            'weekends only',
                            'evenings',
                            'flexible',
                            'full time'
                          ],
                          hint: 'Select Availability',
                          onChanged: (value) {
                            setState(() => _selectedAvailability = value ?? '');
                          },
                        ),

                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF27272a),
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (_currentProfilePicture != null && _currentProfilePicture!.isNotEmpty
                    ? NetworkImage(_currentProfilePicture!)
                    : null) as ImageProvider?,
            child: (_selectedImage == null && (_currentProfilePicture == null || _currentProfilePicture!.isEmpty))
                ? const Icon(Icons.person, size: 60, color: Color(0xFF71717a))
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF06b6d4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? prefix,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFd4d4d8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF27272a),
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: prefix,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF52525b)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF52525b)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF06b6d4)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFd4d4d8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF27272a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF52525b)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isNotEmpty ? value : null,
              hint: Text(hint, style: TextStyle(color: Colors.grey.shade600)),
              isExpanded: true,
              dropdownColor: const Color(0xFF27272a),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
