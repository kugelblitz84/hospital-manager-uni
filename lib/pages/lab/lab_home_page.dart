import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:medicare/Providers/UserProvides.dart';
import 'package:medicare/Providers/doctorProvider.dart' as doctor_provider;
import 'package:medicare/Providers/labProvider.dart' as lab_provider;
import 'package:medicare/Providers/patientPrivider.dart' as patient_provider;
import 'package:medicare/theme/app_theme.dart';
import 'package:medicare/widgets/selector_drawer.dart';

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

  Future<void> _startCreateLabTest() async {
    final patients = ref.read(patient_provider.patientListProvider);
    final doctors = ref.read(doctor_provider.doctorListProvider);
    await Get.to(
      () => _LabTestFormPage(
        patients: patients,
        doctors: doctors,
        onSubmit: (patientId, doctorId, name, description, price) async {
          final success = await ref
              .read(lab_provider.labTestsProvider.notifier)
              .setNewLabTest(patientId, doctorId, name, description, price);
          return success;
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
        onPressed: _startCreateLabTest,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    labTest.testName ?? 'Untitled test',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete test',
                  onPressed: labTest.testId == null
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete lab test'),
                              content: Text(
                                'Delete "${labTest.testName ?? 'this test'}"? This cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            final success = await ref
                                .read(lab_provider.labTestsProvider.notifier)
                                .deleteLabTest(labTest.testId!);
                            if (success) {
                              Get.snackbar(
                                'Lab test removed',
                                'The test has been deleted.',
                                backgroundColor: AppColors.secondary,
                                colorText: Colors.white,
                              );
                            }
                          }
                        },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
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

class _LabTestFormPage extends StatefulWidget {
  const _LabTestFormPage({
    required this.patients,
    required this.doctors,
    required this.onSubmit,
  });

  final List<patient_provider.patient> patients;
  final List<doctor_provider.doctor> doctors;
  final Future<bool> Function(
    String patientId,
    String? doctorId,
    String name,
    String description,
    double price,
  )
  onSubmit;

  @override
  State<_LabTestFormPage> createState() => _LabTestFormPageState();
}

class _LabTestFormPageState extends State<_LabTestFormPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedPatientId;
  String? _selectedDoctorId;
  int _drawerInitialIndex = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _openSelectorDrawer(int index) {
    setState(() => _drawerInitialIndex = index);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _onPatientSelect(String? value) {
    if (value == null || value.isEmpty) {
      return;
    }
    setState(() => _selectedPatientId = value);
    Navigator.of(context).maybePop();
  }

  void _onDoctorSelect(String? value) {
    if (value == null || value.isEmpty) {
      return;
    }
    setState(() => _selectedDoctorId = value);
    Navigator.of(context).maybePop();
  }

  patient_provider.patient? _selectedPatient() {
    if (_selectedPatientId == null) {
      return null;
    }
    for (final patient in widget.patients) {
      if (patient.uid == _selectedPatientId) {
        return patient;
      }
    }
    return null;
  }

  doctor_provider.doctor? _selectedDoctor() {
    if (_selectedDoctorId == null) {
      return null;
    }
    for (final doctor in widget.doctors) {
      if (doctor.uid == _selectedDoctorId) {
        return doctor;
      }
    }
    return null;
  }

  String? _displayIdentity({String? name, String? email, String? fallback}) {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return trimmedName;
    }
    final trimmedEmail = email?.trim();
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
      return trimmedEmail;
    }
    final trimmedFallback = fallback?.trim();
    if (trimmedFallback != null && trimmedFallback.isNotEmpty) {
      return trimmedFallback;
    }
    return null;
  }

  String? get _patientLabel {
    final patient = _selectedPatient();
    return _displayIdentity(
      name: patient?.name,
      email: patient?.email,
      fallback: patient?.uid,
    );
  }

  String? get _doctorLabel {
    final doctor = _selectedDoctor();
    return _displayIdentity(
      name: doctor?.name,
      email: doctor?.email,
      fallback: doctor?.uid,
    );
  }

  Widget _buildSelectorField({
    required String fieldKey,
    required String label,
    required String hint,
    required String browseTooltip,
    required String clearTooltip,
    required String? value,
    required VoidCallback onBrowse,
    required VoidCallback? onClear,
    required VoidCallback onTap,
  }) {
    final displayValue = value ?? '';
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: ValueKey('$fieldKey-${value ?? 'none'}'),
            readOnly: true,
            enableInteractiveSelection: false,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              suffixIcon: value == null
                  ? null
                  : IconButton(
                      tooltip: clearTooltip,
                      icon: const Icon(Icons.clear),
                      onPressed: _isSubmitting ? null : onClear,
                    ),
            ),
            initialValue: displayValue,
            onTap: _isSubmitting ? null : onTap,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: browseTooltip,
          onPressed: _isSubmitting ? null : onBrowse,
          icon: const Icon(Icons.menu_open),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_selectedPatientId == null) {
      Get.snackbar('Validation', 'Select a patient for this test');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final price = double.parse(_priceController.text.trim());
    setState(() => _isSubmitting = true);
    final success = await widget.onSubmit(
      _selectedPatientId!,
      _selectedDoctorId,
      _nameController.text.trim(),
      _descriptionController.text.trim(),
      price,
    );
    if (!mounted) {
      return;
    }
    if (success) {
      setState(() => _isSubmitting = false);
      FocusScope.of(context).unfocus();
      Get.back();
      Get.snackbar(
        'Lab test created',
        'Test assigned successfully',
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
      );
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: SelectorDrawer(
        initialIndex: _drawerInitialIndex,
        doctors: widget.doctors,
        patients: widget.patients,
        onDoctorSelect: _onDoctorSelect,
        onPatientSelect: _onPatientSelect,
        selectedDoctorId: _selectedDoctorId,
        selectedPatientId: _selectedPatientId,
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSubmitting ? null : () => Get.back(),
        ),
        title: const Text('Create lab test'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Get.width * 0.08,
          vertical: Get.height * 0.04,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSelectorField(
                fieldKey: 'patient',
                label: 'Patient',
                hint: 'Select from roster',
                browseTooltip: 'Browse patients',
                clearTooltip: 'Clear patient',
                value: _patientLabel,
                onBrowse: () => _openSelectorDrawer(1),
                onClear: () => setState(() => _selectedPatientId = null),
                onTap: () => _openSelectorDrawer(1),
              ),
              const SizedBox(height: 20),
              _buildSelectorField(
                fieldKey: 'doctor',
                label: 'Doctor (optional)',
                hint: 'Select from roster',
                browseTooltip: 'Browse doctors',
                clearTooltip: 'Clear doctor',
                value: _doctorLabel,
                onBrowse: () => _openSelectorDrawer(0),
                onClear: () => setState(() => _selectedDoctorId = null),
                onTap: () => _openSelectorDrawer(0),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Test name'),
                enabled: !_isSubmitting,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                enabled: !_isSubmitting,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                enabled: !_isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Price is required';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(_isSubmitting ? 'Creating...' : 'Create test'),
                  ),
                ),
              ),
            ],
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
