import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:medicare/Providers/UserProvides.dart';
import 'package:medicare/Providers/doctorProvider.dart' as doctor_provider;
import 'package:medicare/Providers/labProvider.dart' as lab_provider;
import 'package:medicare/Providers/patientPrivider.dart' as patient_provider;
import 'package:medicare/theme/app_theme.dart';

class LabHomePage extends ConsumerStatefulWidget {
  const LabHomePage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  ConsumerState<LabHomePage> createState() => _LabHomePageState();
}

class _LabHomePageState extends ConsumerState<LabHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    ref.read(lab_provider.labTestsProvider.notifier).setAllLabTests();
    ref.read(patient_provider.patientListProvider.notifier).setPatients();
    ref.read(doctor_provider.doctorListProvider.notifier).setDoctors();
  }

  Future<void> _refresh() async {
    _loadData();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _signOut() async {
    await ref.read(appStateProvider.notifier).signOutUser();
  }

  void _showCreateDialog() {
    final patients = ref.read(patient_provider.patientListProvider);
    final doctors = ref.read(doctor_provider.doctorListProvider);
    Get.dialog(
      _AddLabTestDialog(
        patients: patients,
        doctors: doctors,
        onSubmit: (patientId, doctorId, name, description, price) {
          ref
              .read(lab_provider.labTestsProvider.notifier)
              .setNewLabTest(patientId, doctorId, name, description, price);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labTests = ref.watch(lab_provider.labTestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lab Center · ${widget.user['name'] ?? widget.user['email'] ?? ''}',
        ),
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: AppColors.secondary),
            label: const Text('Sign out'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_chart_outlined),
        label: const Text('New test'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: Get.width * 0.04,
            vertical: Get.height * 0.03,
          ),
          children: [
            _SectionHeader(title: 'Tests in progress (${labTests.length})'),
            if (labTests.isEmpty)
              const _EmptyState(message: 'No lab tests recorded yet.')
            else
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: labTests
                    .map(
                      (lab_provider.labTest test) => SizedBox(
                        width: Get.width * 0.28,
                        child: _LabTestCard(labTest: test),
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

class _LabTestCard extends ConsumerWidget {
  const _LabTestCard({required this.labTest});

  final lab_provider.labTest labTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientList = ref.watch(patient_provider.patientListProvider);
    final doctorList = ref.watch(doctor_provider.doctorListProvider);
    final patient = patientList.firstWhere(
      (patient_provider.patient p) => p.uid == labTest.patientId,
      orElse: () => patient_provider.patient(),
    );
    final doctor = doctorList.firstWhere(
      (doctor_provider.doctor d) => d.uid == labTest.doctorId,
      orElse: () => doctor_provider.doctor(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labTest.testName ?? 'Untitled test',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(labTest.testDescription ?? 'No description provided'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                _InfoChip(
                  icon: Icons.person_outline,
                  label: 'Patient',
                  value: patient.name ?? labTest.patientId ?? 'Unknown',
                ),
                _InfoChip(
                  icon: Icons.medical_services_outlined,
                  label: 'Doctor',
                  value: doctor.name ?? labTest.doctorId ?? 'Unassigned',
                ),
                _InfoChip(
                  icon: Icons.payments_outlined,
                  label: 'Fee',
                  value: labTest.price != null
                      ? labTest.price!.toStringAsFixed(2)
                      : 'Not set',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddLabTestDialog extends StatefulWidget {
  const _AddLabTestDialog({
    required this.patients,
    required this.doctors,
    required this.onSubmit,
  });

  final List<patient_provider.patient> patients;
  final List<doctor_provider.doctor> doctors;
  final void Function(
    String patientId,
    String? doctorId,
    String name,
    String description,
    double price,
  )
  onSubmit;

  @override
  State<_AddLabTestDialog> createState() => _AddLabTestDialogState();
}

class _AddLabTestDialogState extends State<_AddLabTestDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPatient;
  String? _selectedDoctor;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedPatient == null) {
      Get.snackbar('Validation', 'Select a patient for this test');
      return;
    }
    setState(() => _isSubmitting = true);
    widget.onSubmit(
      _selectedPatient!,
      _selectedDoctor,
      _nameController.text.trim(),
      _descriptionController.text.trim(),
      double.parse(_priceController.text.trim()),
    );
    setState(() => _isSubmitting = false);
    Get.back();
    Get.snackbar(
      'Lab test created',
      'Test assigned successfully',
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.22,
        vertical: Get.height * 0.18,
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
                      'Create lab test',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting ? null : Get.back,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPatient,
                  decoration: const InputDecoration(labelText: 'Patient'),
                  items: widget.patients
                      .map(
                        (patient_provider.patient p) => DropdownMenuItem(
                          value: p.uid,
                          child: Text(p.name ?? p.email ?? p.uid ?? 'Patient'),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedPatient = value),
                  validator: (value) =>
                      value == null ? 'Select a patient' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDoctor,
                  decoration: const InputDecoration(
                    labelText: 'Doctor (optional)',
                  ),
                  items: widget.doctors
                      .map(
                        (doctor_provider.doctor d) => DropdownMenuItem(
                          value: d.uid,
                          child: Text(d.name ?? d.email ?? d.uid ?? 'Doctor'),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedDoctor = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Test name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price is required';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _isSubmitting ? 'Creating...' : 'Create test',
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
