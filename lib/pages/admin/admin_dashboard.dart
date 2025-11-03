import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:medicare/Providers/UserProvides.dart';
import 'package:medicare/Providers/doctorProvider.dart';
import 'package:medicare/Providers/inventoryProvider.dart';
import 'package:medicare/Providers/labProvider.dart';
import 'package:medicare/Providers/patientPrivider.dart';
import 'package:medicare/Providers/receptionistProviders.dart';
import 'package:medicare/services/authServices.dart';
import 'package:medicare/theme/app_theme.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapData());
  }

  void _bootstrapData() {
    final read = ref.read;
    read(patientListProvider.notifier).setPatients();
    read(doctorListProvider.notifier).setDoctors();
    read(receptionistProvider.notifier).setReceptionists();
    read(labTechnicianListProvider.notifier).setLabTechnicians();
    read(inventoryManagerListProvider.notifier).setInventoryManagers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await ref.read(appStateProvider.notifier).signOutUser();
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(patientListProvider);
    final doctors = ref.watch(doctorListProvider);
    final receptionists = ref.watch(receptionistProvider);
    final labTechs = ref.watch(labTechnicianListProvider);
    final managers = ref.watch(inventoryManagerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Console · ${widget.user['name'] ?? widget.user['email'] ?? 'User'}',
        ),
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: AppColors.secondary),
            label: const Text('Sign out'),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'Patients'),
            Tab(text: 'Doctors'),
            Tab(text: 'Receptionists'),
            Tab(text: 'Lab techs'),
            Tab(text: 'Inventory'),
          ],
        ),
      ),
      body: Container(
        width: Get.width,
        padding: EdgeInsets.symmetric(
          horizontal: Get.width * 0.04,
          vertical: Get.height * 0.03,
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _UserListView(
              emptyMessage: 'No patients found yet.',
              children: patients
                  .map(
                    (patient user) => _UserSummaryCard(
                      title: user.name ?? 'Unknown',
                      subtitle: user.email ?? 'No email',
                      details: {
                        'Phone': user.phone ?? 'N/A',
                        'Address': user.address ?? 'N/A',
                        'Age': user.age ?? 'N/A',
                      },
                    ),
                  )
                  .toList(),
            ),
            _UserListView(
              emptyMessage: 'No doctors registered.',
              children: doctors
                  .map(
                    (doctor doc) => _UserSummaryCard(
                      title: doc.name ?? 'Unknown',
                      subtitle: doc.email ?? 'No email',
                      details: {
                        'Speciality': doc.speciality ?? 'N/A',
                        'Certifications':
                            doc.certifications?.join(', ') ?? 'Not provided',
                      },
                    ),
                  )
                  .toList(),
            ),
            _UserListView(
              emptyMessage: 'No receptionists found.',
              children: receptionists
                  .map(
                    (receptionist staff) => _UserSummaryCard(
                      title: staff.name ?? 'Unknown',
                      subtitle: staff.email ?? 'No email',
                      details: {'Created': staff.createdAt ?? 'N/A'},
                    ),
                  )
                  .toList(),
            ),
            _UserListView(
              emptyMessage: 'No lab technicians registered.',
              children: labTechs
                  .map(
                    (labTechnician tech) => _UserSummaryCard(
                      title: tech.name ?? 'Unknown',
                      subtitle: tech.email ?? 'No email',
                      details: {'Created': tech.createdAt ?? 'N/A'},
                    ),
                  )
                  .toList(),
            ),
            _UserListView(
              emptyMessage: 'No inventory managers registered.',
              children: managers
                  .map(
                    (inventoryManager manager) => _UserSummaryCard(
                      title: manager.name ?? 'Unknown',
                      subtitle: manager.email ?? 'No email',
                      details: {'Created': manager.createdAt ?? 'N/A'},
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.dialog(
          AdminCreateUserDialog(onCreated: _bootstrapData),
          barrierDismissible: false,
        ),
        backgroundColor: AppColors.secondary,
        label: const Text('Create user'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _UserListView extends StatelessWidget {
  const _UserListView({required this.children, required this.emptyMessage});

  final List<Widget> children;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) => children[index],
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemCount: children.length,
    );
  }
}

class _UserSummaryCard extends StatelessWidget {
  const _UserSummaryCard({
    required this.title,
    required this.subtitle,
    required this.details,
  });

  final String title;
  final String subtitle;
  final Map<String, String> details;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: details.entries
                  .map(
                    (entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.value,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCreateUserDialog extends ConsumerStatefulWidget {
  const AdminCreateUserDialog({super.key, required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<AdminCreateUserDialog> createState() =>
      _AdminCreateUserDialogState();
}

class _AdminCreateUserDialogState extends ConsumerState<AdminCreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _specialityController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);

    final authResponse = await firebaseServices.adminCreateUserAccount(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (authResponse['status'] != 'success') {
      setState(() => _isSubmitting = false);
      Get.snackbar(
        'User creation failed',
        authResponse['message'] ?? 'Unable to create authentication account',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    final newUser = authResponse['user'] as User?;
    if (newUser == null) {
      setState(() => _isSubmitting = false);
      Get.snackbar(
        'User creation failed',
        'Authentication user information not available',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    final profileData = <String, dynamic>{
      'uid': newUser.uid,
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'name': _nameController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    switch (_selectedRole) {
      case 'doctor':
        profileData.addAll({
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
        profileData.addAll({'phone': _phoneController.text.trim()});
        break;
      default:
        break;
    }

    final dataResponse = await firebaseServices.createUser(
      _emailController.text.trim(),
      _selectedRole,
      profileData,
    );
    if (dataResponse['status'] != 'success') {
      setState(() => _isSubmitting = false);
      Get.snackbar(
        'User data error',
        dataResponse['message'] ?? 'Unable to create user profile',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    await firebaseServices.setUserData(newUser.uid, profileData);
    widget.onCreated();
    setState(() => _isSubmitting = false);
    Get.back();
    Get.snackbar(
      'Success',
      'User created successfully',
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.2,
        vertical: Get.height * 0.12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create new user',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting ? null : Get.back,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: _roles
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.capitalizeFirst ?? role),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!GetUtils.isEmail(value.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Temporary password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                ..._roleSpecificFields(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _isSubmitting ? 'Creating...' : 'Create user',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            decoration: const InputDecoration(
              labelText: 'Certifications (comma separated)',
            ),
            maxLines: 2,
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
