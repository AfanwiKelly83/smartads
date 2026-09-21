import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/password_strength_widget.dart';
import '../../widgets/video_background.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../main_navigation_screen.dart';

class OwnerRegisterScreen extends StatefulWidget {
  const OwnerRegisterScreen({super.key});

  @override
  State<OwnerRegisterScreen> createState() => _OwnerRegisterScreenState();
}

class _OwnerRegisterScreenState extends State<OwnerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _isLoading = false;
  String _passwordText = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleOwnerRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFD32F2F),
            content: Text(
              'Please accept the Terms of Service & Host Agreement to continue.',
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final res = await ApiService().post('/auth/register-owner', {
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'password': _passwordController.text.trim(),
        });

        if (res['success'] == true && res['data'] != null) {
          final data = res['data'];
          if (data['token'] != null) {
            if (data['user'] != null) {
              await ApiService().saveSession(
                data['token'],
                UserModel.fromJson(data['user']),
              );
            } else {
              ApiService().setToken(data['token']);
            }
            await AuthService().restoreSession();
          }

          if (mounted) {
            setState(() => _isLoading = false);

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
                    Icon(Icons.storefront_rounded, color: AppTheme.accentLight),
                    SizedBox(width: 12),
                    Text(
                      'Welcome to SmartAds as a Billboard Owner!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainNavigationScreen(),
              ),
              (route) => false,
            );
          }
        } else {
          throw Exception(res['message'] ?? 'Owner registration failed.');
        }
      } catch (err) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade900,
              content: Text('Registration failed: ${err.toString()}'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: VideoBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 680 : 480),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back to Login Button
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppTheme.accentLight,
                              ),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Back',
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade900,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'BILLBOARD OWNER REGISTRATION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        const Text(
                          'Welcome to SmartAds as a Billboard Owner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Monetize your physical or digital Smart TV displays, generate location QR codes, and receive direct advertiser bookings.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Full Name
                        CustomTextField(
                          controller: _nameController,
                          label: 'FULL NAME / DISPLAY COMPANY',
                          hint: 'Jean Dupont / Yaoundé Outdoor Media',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name or company name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email
                        CustomTextField(
                          controller: _emailController,
                          label: 'BUSINESS EMAIL',
                          hint: 'owner@displaymedia.cm',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone Number
                        CustomTextField(
                          controller: _phoneController,
                          label: 'PHONE NUMBER (MOMO / ORANGE MONEY)',
                          hint: '+237 6XX XXX XXX',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your contact phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        CustomTextField(
                          controller: _passwordController,
                          label: 'CREATE PASSWORD',
                          hint: '••••••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          onChanged: (val) {
                            setState(() => _passwordText = val);
                            _formKey.currentState?.validate();
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        PasswordStrengthWidget(password: _passwordText),
                        const SizedBox(height: 16),

                        // Confirm Password
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'CONFIRM PASSWORD',
                          hint: '••••••••••••',
                          prefixIcon: Icons.lock_reset_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => _formKey.currentState?.validate(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Terms
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _acceptTerms,
                                activeColor: AppTheme.accentPrimary,
                                checkColor: Colors.black,
                                side: BorderSide(
                                  color: AppTheme.accentPrimary.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  setState(() => _acceptTerms = val ?? false);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                  children: const [
                                    TextSpan(text: 'I agree to the SmartAds '),
                                    TextSpan(
                                      text: 'Billboard Host Terms & Privacy',
                                      style: TextStyle(
                                        color: AppTheme.accentLight,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Submit
                        PrimaryButton(
                          text: 'REGISTER AS BILLBOARD OWNER',
                          icon: Icons.tv_rounded,
                          isLoading: _isLoading,
                          onPressed: _handleOwnerRegister,
                        ),
                        const SizedBox(height: 20),

                        // Sign In link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Already registered? Sign In',
                              style: TextStyle(
                                color: AppTheme.accentLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
