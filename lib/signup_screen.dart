import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AegisSignupPage extends StatefulWidget {
  const AegisSignupPage({Key? key}) : super(key: key);

  @override
  State<AegisSignupPage> createState() => _AegisSignupPageState();
}

class _AegisSignupPageState extends State<AegisSignupPage> {
  final _formKey = GlobalKey<FormState>();

  // Form data
  String role = '';
  String username = '';
  String email = '';
  String password = '';
  String orgName = '';
  String country = '';
  String headquarters = '';
  String description = '';
  String contactPhone = '';
  String establishedDate = '';
  String website = '';
  String ownerName = '';
  String ownerInstagram = '';

  bool showPassword = false;
  bool isLoading = false;

  final TextEditingController dateController = TextEditingController();

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        establishedDate = dateController.text;
      });
    }
  }

  void handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    // TODO: Send data to your backend APIs here based on role
    // Use same endpoints: /api/players/signup or /api/organizations/register
    print({
      'role': role,
      'username': username,
      'email': email,
      'password': password,
      'orgName': orgName,
      'country': country,
      'headquarters': headquarters,
      'description': description,
      'contactPhone': contactPhone,
      'establishedDate': establishedDate,
      'website': website,
      'ownerName': ownerName,
      'ownerInstagram': ownerInstagram,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Role Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Player'),
                    selected: role == 'player',
                    onSelected: (_) => setState(() => role = 'player'),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Organization'),
                    selected: role == 'organization',
                    onSelected: (_) => setState(() => role = 'organization'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Player Fields
              if (role == 'player') ...[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                  onSaved: (val) => username = val ?? '',
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter username';
                    if (val.length < 3) return 'Minimum 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Organization Fields
              if (role == 'organization') ...[
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Owner Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  onSaved: (val) => ownerName = val ?? '',
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter owner name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Organization Name',
                    prefixIcon: Icon(Icons.business),
                  ),
                  onSaved: (val) => orgName = val ?? '',
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter organization name';
                    if (val.length < 3) return 'Minimum 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Country',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  onSaved: (val) => country = val ?? '',
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter country';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Headquarters (Optional)',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  onSaved: (val) => headquarters = val ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone (Optional)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  onSaved: (val) => contactPhone = val ?? '',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Website (Optional)',
                    prefixIcon: Icon(Icons.web),
                  ),
                  onSaved: (val) => website = val ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Owner Instagram (Optional)',
                    prefixIcon: Icon(Icons.camera_alt),
                  ),
                  onSaved: (val) => ownerInstagram = val ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  onSaved: (val) => description = val ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Established Date (Optional)',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
              ],

              // Common Fields
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail),
                ),
                onSaved: (val) => email = val ?? '',
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter email';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) return 'Enter valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                ),
                obscureText: !showPassword,
                onSaved: (val) => password = val ?? '',
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter password';
                  if (val.length < 8) return 'Minimum 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isLoading ? null : handleSubmit,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Account'),
              ),
              const SizedBox(height: 16),

              // Social Login Buttons (placeholders)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {}, // TODO: Google signup
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Google'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {}, // TODO: Discord signup
                    icon: const Icon(Icons.chat),
                    label: const Text('Discord'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
