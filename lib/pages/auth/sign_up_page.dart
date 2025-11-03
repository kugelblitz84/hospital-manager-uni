import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:medicare/Providers/UserProvides.dart';
import 'package:medicare/pages/landingPage.dart';
import 'package:medicare/theme/app_theme.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialityController = TextEditingController();
  final _certificationsController = TextEditingController();

  final _roles = const <String>[
    'admin',
    'doctor',
    'receptionist',
    'inventoryManager',
    'labTechnician',
  ];

  String _selectedRole = 'doctor';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _specialityController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildProfileData() {
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    switch (_selectedRole) {
      case 'doctor':
        data.addAll({
          'speciality': _specialityController.text.trim(),
          'certifications': _certificationsController.text
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(),
        });
        break;
      case 'inventoryManager':
      case 'receptionist':
      case 'labTechnician':
        data.addAll({'phone': _phoneController.text.trim()});
        break;
      default:
        break;
    }

    return data;
  }

  bool _validateRoleSpecificFields() {
    switch (_selectedRole) {
      case 'doctor':
        if (_specialityController.text.trim().isEmpty) {
          Get.snackbar('Validation', 'Speciality is required for doctors');
          return false;
        }
        break;
      default:
        break;
    }
    return true;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_validateRoleSpecificFields()) {
      return;
    }

    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (password != confirmPassword) {
      Get.snackbar('Validation', 'Passwords do not match');
      return;
    }

    final data = _buildProfileData();
    await ref
        .read(appStateProvider.notifier)
        .signUpUser(
          _emailController.text.trim(),
          password,
          _selectedRole,
          data,
        );
    if (!mounted) return;
    final createdUser = ref.read(appStateProvider).user;
    if (createdUser != null) {
      Get.offAll(() => const LandingPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = Size(Get.width, Get.height);
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.background, Colors.white],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
                vertical: size.height * 0.04,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size.width * 0.6),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Create account',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('Back to sign in'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            items: _roles
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(role.capitalizeFirst ?? role),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedRole = value);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Role',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              if (!GetUtils.isEmail(value.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.trim().length < 6) {
                                return 'Minimum 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ..._roleSpecificFields(),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: appState.isLoading ? null : _onSubmit,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  appState.isLoading
                                      ? 'Creating account...'
                                      : 'Create account',
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
        ],
      ),
    );
  }

  List<Widget> _roleSpecificFields() {
    switch (_selectedRole) {
      case 'doctor':
        return [
          TextFormField(
            controller: _specialityController,
            decoration: const InputDecoration(labelText: 'Speciality'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _certificationsController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Certifications (comma separated)',
            ),
          ),
        ];
      case 'inventoryManager':
      case 'receptionist':
      case 'labTechnician':
        return [
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
        ];
      default:
        return const [];
    }
  }
}
