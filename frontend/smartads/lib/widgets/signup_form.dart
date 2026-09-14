import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'custom_text_field.dart';
import 'primary_button.dart';
import 'password_strength_widget.dart';
import '../services/auth_service.dart';
import '../screens/main_navigation_screen.dart';

class SignUpForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const SignUpForm({super.key, required this.onSwitchToLogin});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _isLoading = false;
  String _passwordText = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFD32F2F),
            content: Text(
              'Please accept the Terms of Service & Privacy Policy to continue.',
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        await AuthService().register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: 'ADVERTISER',
        );

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
                  Icon(Icons.waving_hand_rounded, color: AppTheme.accentLight),
                  SizedBox(width: 12),
                  Text(
                    'Welcome to SmartAds!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const MainNavigationScreen(isNewRegistration: true),
            ),
          );
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create an Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            ' SmartAds to publish ad campaigns or monetize digital screens.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Full Name Input
          CustomTextField(
            controller: _nameController,
            label: 'FULL NAME / BUSINESS NAME',
            hint: 'John Doe / Apex Media Ltd',
            prefixIcon: Icons.person_outline_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name or business name';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Email Input
          CustomTextField(
            controller: _emailController,
            label: 'BUSINESS EMAIL',
            hint: 'contact@company.com',
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
          const SizedBox(height: 18),

          // Password Input
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

          // Password Strength Widget
          PasswordStrengthWidget(password: _passwordText),
          const SizedBox(height: 18),

          // Confirm Password Input
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

          // Terms Acceptance Checkbox
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
                    color: AppTheme.accentPrimary.withValues(alpha: 0.5),
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
                      TextSpan(text: 'I agree to SmartAds '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppTheme.accentLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
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
          const SizedBox(height: 28),

          // Submit CTA Button
          PrimaryButton(
            text: 'CREATE ACCOUNT',
            icon: Icons.person_add_rounded,
            isLoading: _isLoading,
            onPressed: _handleRegister,
          ),
          const SizedBox(height: 24),

          // Bottom Toggle Switch
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                TextButton(
                  onPressed: widget.onSwitchToLogin,
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: AppTheme.accentLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
