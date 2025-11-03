import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:medicare/Providers/UserProvides.dart';
import 'package:medicare/pages/admin/admin_dashboard.dart';
import 'package:medicare/pages/auth/sign_in_page.dart';
import 'package:medicare/pages/doctor/doctor_home_page.dart';
import 'package:medicare/pages/inventory/inventory_home_page.dart';
import 'package:medicare/pages/lab/lab_home_page.dart';
import 'package:medicare/pages/receptionist/receptionist_home_page.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialiseUser());
  }

  Future<void> _initialiseUser() async {
    final appState = ref.read(appStateProvider);
    if (appState.user == null || appState.user is! Map<String, dynamic>) {
      await ref.read(appStateProvider.notifier).setUser();
    }
    if (mounted) {
      setState(() => _bootstrapped = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final user = appState.user;

    if ((appState.isLoading && !_bootstrapped) ||
        (!_bootstrapped && user == null)) {
      return const _LandingLoading();
    }

    if (user == null) {
      return const SignInPage();
    }

    if (user is! Map<String, dynamic>) {
      return const SignInPage();
    }

    final role = (user['role'] ?? '').toString();
    switch (role) {
      case 'admin':
        return AdminDashboard(user: user);
      case 'doctor':
        return DoctorHomePage(user: user);
      case 'receptionist':
        return ReceptionistHomePage(user: user);
      case 'inventoryManager':
        return InventoryHomePage(user: user);
      case 'labTechnician':
        return LabHomePage(user: user);
      default:
        return UnknownRoleView(role: role);
    }
  }
}

class _LandingLoading extends StatelessWidget {
  const _LandingLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox.square(
          dimension: Get.width * 0.06,
          child: const CircularProgressIndicator(strokeWidth: 6),
        ),
      ),
    );
  }
}

class UnknownRoleView extends StatelessWidget {
  const UnknownRoleView({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Get.width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.help_outline, size: 72, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                'Unknown role: $role',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Please contact the system administrator to configure access for this account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Get.offAll(() => const SignInPage()),
                child: const Text('Back to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
