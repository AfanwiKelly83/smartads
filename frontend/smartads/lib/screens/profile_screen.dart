import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/role_guard.dart';
import '../services/auth_service.dart';
import 'auth_page.dart';
import '../models/user_model.dart';
import '../widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService().fetchProfile();
      setState(() {
        _user = user;
        _fullNameController.text = user.fullName;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleUpdateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final updatedUser = await ApiService().updateProfile(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _user = updatedUser;
            _isSaving = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.cardDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.accentPrimary),
              ),
              content: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: AppTheme.accentLight),
                  SizedBox(width: 12),
                  Text(
                    'Profile updated successfully!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (err) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade900,
              content: Text(
                err.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: RoleAccess.adminAndAdvertiser,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accentPrimary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header title
                        const Text(
                          'Manage User Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'View and update your personal details below.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Profile Info Card
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.accentPrimary.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Non-editable system badge header
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 36,
                                      backgroundColor: AppTheme.accentPrimary
                                          .withValues(alpha: 0.2),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 40,
                                        color: AppTheme.accentLight,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _user?.fullName ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              // Role Badge
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentDark
                                                      .withValues(alpha: 0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: AppTheme.accentPrimary,
                                                  ),
                                                ),
                                                child: Text(
                                                  _user?.role ?? 'ADVERTISER',
                                                  style: const TextStyle(
                                                    color: AppTheme.accentLight,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),

                                              // User ID Badge
                                              Text(
                                                'ID: #${_user?.userId}',
                                                style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                const Divider(color: AppTheme.borderSubtle),
                                const SizedBox(height: 28),

                                // Editable Fields Section
                                const Text(
                                  'EDITABLE PROFILE DETAILS',
                                  style: TextStyle(
                                    color: AppTheme.accentLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Full Name Input
                                _buildTextFieldLabel('FULL NAME'),
                                TextFormField(
                                  controller: _fullNameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _buildInputDecoration(
                                    'Enter full name',
                                    Icons.person_outline,
                                  ),
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty
                                      ? 'Full name cannot be empty'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Email Address Input
                                _buildTextFieldLabel('EMAIL ADDRESS'),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _buildInputDecoration(
                                    'name@company.com',
                                    Icons.email_outlined,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Email address is required';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(val.trim())) {
                                      return 'Please enter a valid email format';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Phone Number Input
                                _buildTextFieldLabel('PHONE NUMBER'),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _buildInputDecoration(
                                    '+237 670 000 000',
                                    Icons.phone_outlined,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // System Non-editable Info Notice Box
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.borderSubtle.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.shield_outlined,
                                        color: AppTheme.accentLight,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'User ID, Role, Password, and System Timestamps cannot be modified directly via profile edit.',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Save Button
                                PrimaryButton(
                                  text: 'SAVE PROFILE CHANGES',
                                  icon: Icons.save_rounded,
                                  isLoading: _isSaving,
                                  onPressed: _handleUpdateProfile,
                                ),
                                const SizedBox(height: 12),
                                // Logout Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      AuthService().logout();
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AuthPage(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.logout_rounded,
                                      color: AppTheme.accentPrimary,
                                    ),
                                    label: const Text(
                                      'LOGOUT',
                                      style: TextStyle(
                                        color: AppTheme.accentPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: AppTheme.borderSubtle.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
              ),
      ),
    );
  }

  Widget _buildTextFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppTheme.accentLight, size: 20),
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMuted),
      filled: true,
      fillColor: AppTheme.inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppTheme.borderSubtle.withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.accentPrimary, width: 1.5),
      ),
    );
  }
}
