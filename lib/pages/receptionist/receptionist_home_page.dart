import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:medicare/Providers/UserProvides.dart';
import 'package:medicare/Providers/appointmentProvider.dart' as appointments;
import 'package:medicare/Providers/doctorProvider.dart' as doctor_provider;
import 'package:medicare/Providers/patientPrivider.dart' as patient_provider;
import 'package:medicare/services/appointmentService.dart';
import 'package:medicare/theme/app_theme.dart';

class ReceptionistHomePage extends ConsumerStatefulWidget {
  const ReceptionistHomePage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  ConsumerState<ReceptionistHomePage> createState() =>
      _ReceptionistHomePageState();
}

class _ReceptionistHomePageState extends ConsumerState<ReceptionistHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedDoctorId;
  String? _selectedPatientId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isBooking = false;
  bool _isRegisteringPatient = false;
  int _drawerInitialIndex = 0;

  final _patientFormKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientEmailController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _patientAddressController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _patientHistoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientEmailController.dispose();
    _patientPhoneController.dispose();
    _patientAddressController.dispose();
    _patientAgeController.dispose();
    _patientHistoryController.dispose();
    super.dispose();
  }

  void _bootstrap() {
    final read = ref.read;
    read(doctor_provider.doctorListProvider.notifier).setDoctors();
    read(patient_provider.patientListProvider.notifier).setPatients();
  }

  void _openSelectorDrawer(int initialIndex) {
    setState(() => _drawerInitialIndex = initialIndex);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _signOut() async {
    await ref.read(appStateProvider.notifier).signOutUser();
  }

  Future<void> _registerPatient() async {
    if (!_patientFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isRegisteringPatient = true);
    final notifier = ref.read(patient_provider.patientListProvider.notifier);
    final createdPatient = await notifier.registerPatient(
      patient_provider.patient(
        name: _patientNameController.text.trim(),
        email: _patientEmailController.text.trim(),
        phone: _patientPhoneController.text.trim().isEmpty
            ? null
            : _patientPhoneController.text.trim(),
        address: _patientAddressController.text.trim().isEmpty
            ? null
            : _patientAddressController.text.trim(),
        age: _patientAgeController.text.trim().isEmpty
            ? null
            : _patientAgeController.text.trim(),
        medicalHistory: _patientHistoryController.text.trim().isEmpty
            ? null
            : _patientHistoryController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    if (!mounted) {
      return;
    }

    setState(() => _isRegisteringPatient = false);

    if (createdPatient != null) {
      _resetPatientForm();
      setState(() => _selectedPatientId = createdPatient.uid);
    }
  }

  void _resetPatientForm() {
    _patientFormKey.currentState?.reset();
    _patientNameController.clear();
    _patientEmailController.clear();
    _patientPhoneController.clear();
    _patientAddressController.clear();
    _patientAgeController.clear();
    _patientHistoryController.clear();
    FocusScope.of(context).unfocus();
  }

  void _selectDoctor(String? doctorId) {
    if (doctorId == null || doctorId.isEmpty) {
      return;
    }
    _onDoctorChanged(doctorId);
    Navigator.of(context).maybePop();
  }

  void _selectPatient(String? patientId) {
    if (patientId == null || patientId.isEmpty) {
      return;
    }
    _onPatientChanged(patientId);
    Navigator.of(context).maybePop();
  }

  void _onDoctorChanged(String? value) {
    setState(() => _selectedDoctorId = value);
    final combinedNotifier = ref.read(
      appointments.combinedAppointmentProvider.notifier,
    );
    combinedNotifier.setFilters(doctorId: value, patientId: _selectedPatientId);

    final doctorNotifier = ref.read(
      appointments.doctorAppointmentProvider.notifier,
    );
    if (value != null && value.isNotEmpty) {
      doctorNotifier.setAppointmentsForDoctor(value);
    } else {
      doctorNotifier.clear();
    }
  }

  void _onPatientChanged(String? value) {
    setState(() => _selectedPatientId = value);
    final combinedNotifier = ref.read(
      appointments.combinedAppointmentProvider.notifier,
    );
    combinedNotifier.setFilters(doctorId: _selectedDoctorId, patientId: value);

    final patientNotifier = ref.read(
      appointments.patientAppointmentProvider.notifier,
    );
    if (value != null && value.isNotEmpty) {
      patientNotifier.setAppointmentsForPatient(value);
    } else {
      patientNotifier.clear();
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() => _selectedDate = selected);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (selected != null) {
      setState(() => _selectedTime = selected);
    }
  }

  DateTime? get _selectedDateTime {
    if (_selectedDate == null || _selectedTime == null) {
      return null;
    }
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctorId == null || _selectedPatientId == null) {
      Get.snackbar('Incomplete data', 'Select doctor and patient');
      return;
    }
    final slot = _selectedDateTime;
    if (slot == null) {
      Get.snackbar('Missing date/time', 'Pick a date and time');
      return;
    }

    final doctorAppointments = ref.read(appointments.doctorAppointmentProvider);
    final patientAppointments = ref.read(
      appointments.patientAppointmentProvider,
    );
    if (_hasConflict(slot, doctorAppointments, patientAppointments)) {
      Get.snackbar(
        'Slot unavailable',
        'Choose a different time. The doctor or patient is already booked within an hour.',
      );
      return;
    }

    setState(() => _isBooking = true);
    final response = await AppointmentService.bookAppointment(
      _selectedDoctorId!,
      _selectedPatientId!,
      slot,
      'Scheduled via receptionist portal',
    );
    setState(() => _isBooking = false);

    if (response['status'] == 'success') {
      ref
          .read(appointments.doctorAppointmentProvider.notifier)
          .setAppointmentsForDoctor(_selectedDoctorId!);
      ref
          .read(appointments.patientAppointmentProvider.notifier)
          .setAppointmentsForPatient(_selectedPatientId!);
      ref
          .read(appointments.combinedAppointmentProvider.notifier)
          .refreshCurrentFilters();
      Get.snackbar(
        'Appointment booked',
        'The appointment has been added successfully.',
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
      );
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
      });
    } else {
      Get.snackbar(
        'Booking failed',
        response['message'] ?? 'Unable to book appointment',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _clearScheduling() {
    _onDoctorChanged(null);
    _onPatientChanged(null);
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  Future<void> _deleteAppointment(appointments.appointment appt) async {
    if (appt.appointmentId == null) {
      return;
    }
    final res = await AppointmentService.cancelAppointment(appt.appointmentId!);
    if (res['status'] == 'success') {
      if (_selectedDoctorId != null) {
        ref
            .read(appointments.doctorAppointmentProvider.notifier)
            .setAppointmentsForDoctor(_selectedDoctorId!);
      }
      if (_selectedPatientId != null) {
        ref
            .read(appointments.patientAppointmentProvider.notifier)
            .setAppointmentsForPatient(_selectedPatientId!);
      }
      ref
          .read(appointments.combinedAppointmentProvider.notifier)
          .refreshCurrentFilters();
      Get.snackbar(
        'Appointment removed',
        'The appointment has been cancelled.',
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        res['message'] ?? 'Failed to cancel appointment',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  bool _hasConflict(
    DateTime slot,
    List<appointments.appointment> doctorAppointments,
    List<appointments.appointment> patientAppointments,
  ) {
    bool conflictWith(List<appointments.appointment> list) {
      for (final appt in list) {
        final dateTime = appt.dateTime;
        if (dateTime == null) continue;
        final difference = dateTime.difference(slot).inMinutes.abs();
        if (difference < 60) {
          return true;
        }
      }
      return false;
    }

    return conflictWith(doctorAppointments) ||
        conflictWith(patientAppointments);
  }

  doctor_provider.doctor? _selectedDoctorModel(
    List<doctor_provider.doctor> doctors,
  ) {
    if (_selectedDoctorId == null) {
      return null;
    }
    for (final doc in doctors) {
      if (doc.uid == _selectedDoctorId) {
        return doc;
      }
    }
    return null;
  }

  patient_provider.patient? _selectedPatientModel(
    List<patient_provider.patient> patients,
  ) {
    if (_selectedPatientId == null) {
      return null;
    }
    for (final patient in patients) {
      if (patient.uid == _selectedPatientId) {
        return patient;
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

  String? _selectedDoctorLabel(List<doctor_provider.doctor> doctors) {
    final doctor = _selectedDoctorModel(doctors);
    return _displayIdentity(
      name: doctor?.name,
      email: doctor?.email,
      fallback: doctor?.uid,
    );
  }

  String? _selectedPatientLabel(List<patient_provider.patient> patients) {
    final patient = _selectedPatientModel(patients);
    return _displayIdentity(
      name: patient?.name,
      email: patient?.email,
      fallback: patient?.uid,
    );
  }

  Widget _buildSelectorField({
    required String fieldKey,
    required String label,
    required String hint,
    required String browseTooltip,
    required String clearTooltip,
    required String? value,
    required bool enabled,
    required VoidCallback? onTap,
    required VoidCallback? onClear,
    required VoidCallback? onBrowse,
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
                      onPressed: enabled ? onClear : null,
                    ),
            ),
            initialValue: displayValue,
            onTap: enabled ? onTap : null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: browseTooltip,
          onPressed: enabled ? onBrowse : null,
          icon: const Icon(Icons.menu_open),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(doctor_provider.doctorListProvider);
    final patients = ref.watch(patient_provider.patientListProvider);
    final combinedAppointments = ref.watch(
      appointments.combinedAppointmentProvider,
    );
    final selectedDoctorLabel = _selectedDoctorLabel(doctors);
    final selectedPatientLabel = _selectedPatientLabel(patients);

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _SelectorDrawer(
        initialIndex: _drawerInitialIndex,
        doctors: doctors,
        patients: patients,
        onDoctorSelect: _selectDoctor,
        onPatientSelect: _selectPatient,
        selectedDoctorId: _selectedDoctorId,
        selectedPatientId: _selectedPatientId,
      ),
      appBar: AppBar(
        title: Text(
          'Reception · ${widget.user['name'] ?? widget.user['email'] ?? ''}',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Get.width * 0.04,
          vertical: Get.height * 0.03,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Register new patient'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _patientFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _patientNameController,
                              decoration: const InputDecoration(
                                labelText: 'Patient name',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextFormField(
                              controller: _patientEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!GetUtils.isEmail(value.trim())) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _patientPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextFormField(
                              controller: _patientAgeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Age',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }
                                final age = int.tryParse(value.trim());
                                if (age == null || age <= 0) {
                                  return 'Enter a valid age';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _patientAddressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _patientHistoryController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Medical history / notes',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _isRegisteringPatient
                                  ? null
                                  : () => setState(_resetPatientForm),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Clear fields'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isRegisteringPatient
                                  ? null
                                  : _registerPatient,
                              icon: _isRegisteringPatient
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.person_add_alt_1),
                              label: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Text(
                                  _isRegisteringPatient
                                      ? 'Registering...'
                                      : 'Register patient',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Schedule appointment'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectorField(
                            fieldKey: 'schedule-doctor',
                            label: 'Doctor',
                            hint: 'Select from roster',
                            browseTooltip: 'Browse doctors',
                            clearTooltip: 'Clear doctor',
                            value: selectedDoctorLabel,
                            enabled: !_isBooking,
                            onTap: () => _openSelectorDrawer(0),
                            onClear: () => _onDoctorChanged(null),
                            onBrowse: () => _openSelectorDrawer(0),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildSelectorField(
                            fieldKey: 'schedule-patient',
                            label: 'Patient',
                            hint: 'Select from roster',
                            browseTooltip: 'Browse patients',
                            clearTooltip: 'Clear patient',
                            value: selectedPatientLabel,
                            enabled: !_isBooking,
                            onTap: () => _openSelectorDrawer(1),
                            onClear: () => _onPatientChanged(null),
                            onBrowse: () => _openSelectorDrawer(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            onTap: _isBooking ? null : _pickDate,
                            decoration: InputDecoration(
                              labelText: 'Date',
                              hintText: _selectedDate == null
                                  ? 'Select date'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            onTap: _isBooking ? null : _pickTime,
                            decoration: InputDecoration(
                              labelText: 'Time',
                              hintText: _selectedTime == null
                                  ? 'Select time'
                                  : _selectedTime!.format(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _isBooking
                                ? null
                                : () => _clearScheduling(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Clear selection'),
                          ),
                          ElevatedButton(
                            onPressed: _isBooking ? null : _bookAppointment,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Text(
                                _isBooking ? 'Booking...' : 'Book appointment',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Appointments overview'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectorField(
                            fieldKey: 'overview-doctor',
                            label: 'Doctor',
                            hint: 'Select from roster',
                            browseTooltip: 'Browse doctors',
                            clearTooltip: 'Clear doctor',
                            value: selectedDoctorLabel,
                            enabled: true,
                            onTap: () => _openSelectorDrawer(0),
                            onClear: () => _onDoctorChanged(null),
                            onBrowse: () => _openSelectorDrawer(0),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildSelectorField(
                            fieldKey: 'overview-patient',
                            label: 'Patient',
                            hint: 'Select from roster',
                            browseTooltip: 'Browse patients',
                            clearTooltip: 'Clear patient',
                            value: selectedPatientLabel,
                            enabled: true,
                            onTap: () => _openSelectorDrawer(1),
                            onClear: () => _onPatientChanged(null),
                            onBrowse: () => _openSelectorDrawer(1),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedDoctorId != null || _selectedPatientId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                _onDoctorChanged(null);
                                _onPatientChanged(null);
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear filters'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (combinedAppointments.isEmpty)
              const _EmptyState(
                message: 'No appointments for the selected doctor or patient.',
              )
            else
              ...combinedAppointments.map(
                (appointments.appointment appt) => _AppointmentRow(
                  appointment: appt,
                  doctorName:
                      doctors
                          .firstWhere(
                            (doctor_provider.doctor doc) =>
                                doc.uid == appt.doctorId,
                            orElse: () => doctor_provider.doctor(),
                          )
                          .name ??
                      appt.doctorId ??
                      'Doctor',
                  patientName:
                      patients
                          .firstWhere(
                            (patient_provider.patient p) =>
                                p.uid == appt.patientId,
                            orElse: () => patient_provider.patient(),
                          )
                          .name ??
                      appt.patientId ??
                      'Patient',
                  onDelete: () => _deleteAppointment(appt),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.appointment,
    required this.doctorName,
    required this.patientName,
    required this.onDelete,
  });

  final appointments.appointment appointment;
  final String doctorName;
  final String patientName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = appointment.dateTime;
    final formatted = date != null
        ? '${date.day}/${date.month}/${date.year} · ${TimeOfDay.fromDateTime(date).format(context)}'
        : 'Pending';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.event, color: AppColors.secondary),
        title: Text(formatted),
        subtitle: Text('Doctor: $doctorName · Patient: $patientName'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
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
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
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

class _SelectorDrawer extends StatefulWidget {
  const _SelectorDrawer({
    required this.initialIndex,
    required this.doctors,
    required this.patients,
    required this.onDoctorSelect,
    required this.onPatientSelect,
    required this.selectedDoctorId,
    required this.selectedPatientId,
  });

  final int initialIndex;
  final List<doctor_provider.doctor> doctors;
  final List<patient_provider.patient> patients;
  final void Function(String?) onDoctorSelect;
  final void Function(String?) onPatientSelect;
  final String? selectedDoctorId;
  final String? selectedPatientId;

  @override
  State<_SelectorDrawer> createState() => _SelectorDrawerState();
}

class _SelectorDrawerState extends State<_SelectorDrawer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final initialTab = widget.initialIndex.clamp(0, 1).toInt();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          _searchQuery = '';
          _searchController.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<doctor_provider.doctor> get _filteredDoctors {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.doctors;
    }
    return widget.doctors.where((doc) {
      final name = (doc.name ?? '').toLowerCase();
      final email = (doc.email ?? '').toLowerCase();
      final speciality = (doc.speciality ?? '').toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          speciality.contains(query);
    }).toList();
  }

  List<patient_provider.patient> get _filteredPatients {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.patients;
    }
    return widget.patients.where((patient) {
      final name = (patient.name ?? '').toLowerCase();
      final email = (patient.email ?? '').toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double drawerWidth = screenWidth < 420
        ? screenWidth * 0.9
        : screenWidth > 980
        ? 520
        : screenWidth * 0.55;
    final placeholder = _tabController.index == 0
        ? 'Search doctors by name'
        : 'Search patients by name';
    final trimmedQuery = _searchQuery.trim();

    return Drawer(
      width: drawerWidth,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Browse roster',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: placeholder,
                  suffixIcon: trimmedQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          }),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              indicatorColor: theme.colorScheme.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Doctors'),
                Tab(text: 'Patients'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DrawerListView(
                    emptyLabel: trimmedQuery.isEmpty
                        ? 'No doctors found.'
                        : 'No doctors match "$trimmedQuery".',
                    children: _filteredDoctors
                        .map(
                          (doc) => _DoctorCard(
                            doctor: doc,
                            onSelect: () => widget.onDoctorSelect(doc.uid),
                            isSelected: widget.selectedDoctorId == doc.uid,
                          ),
                        )
                        .toList(),
                  ),
                  _DrawerListView(
                    emptyLabel: trimmedQuery.isEmpty
                        ? 'No patients found.'
                        : 'No patients match "$trimmedQuery".',
                    children: _filteredPatients
                        .map(
                          (patient) => _PatientCard(
                            patient: patient,
                            onSelect: () => widget.onPatientSelect(patient.uid),
                            isSelected: widget.selectedPatientId == patient.uid,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerListView extends StatelessWidget {
  const _DrawerListView({required this.children, required this.emptyLabel});

  final List<Widget> children;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => children[index],
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: children.length,
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.doctor,
    required this.onSelect,
    required this.isSelected,
  });

  final doctor_provider.doctor doctor;
  final VoidCallback onSelect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final speciality = doctor.speciality?.isNotEmpty == true
        ? doctor.speciality!
        : 'Speciality not set';
    return Card(
      color: isSelected ? AppColors.secondary.withOpacity(0.08) : null,
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.secondary,
          child: Icon(Icons.medical_services_outlined, color: Colors.white),
        ),
        title: Text(doctor.name ?? doctor.email ?? 'Unnamed doctor'),
        subtitle: Text(speciality),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        children: [
          _DrawerInfoRow(label: 'Email', value: doctor.email),
          _DrawerInfoRow(label: 'Speciality', value: doctor.speciality),
          _DrawerInfoRow(label: 'Joined', value: doctor.createdAt),
          if ((doctor.certifications ?? []).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certifications',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: doctor.certifications!
                        .map(
                          (cert) => Chip(
                            label: Text(cert),
                            backgroundColor: AppColors.secondary.withOpacity(
                              0.1,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: doctor.uid == null ? null : onSelect,
                icon: Icon(
                  isSelected ? Icons.check_circle : Icons.event_available,
                ),
                label: Text(isSelected ? 'Selected' : 'Select doctor'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.onSelect,
    required this.isSelected,
  });

  final patient_provider.patient patient;
  final VoidCallback onSelect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppColors.secondary.withOpacity(0.08) : null,
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person_outline, color: Colors.white),
        ),
        title: Text(patient.name ?? patient.email ?? 'Unnamed patient'),
        subtitle: Text(patient.email ?? 'Email not provided'),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        children: [
          _DrawerInfoRow(label: 'Email', value: patient.email),
          _DrawerInfoRow(label: 'Phone', value: patient.phone),
          _DrawerInfoRow(label: 'Age', value: patient.age),
          _DrawerInfoRow(label: 'Address', value: patient.address),
          _DrawerInfoRow(label: 'Medical notes', value: patient.medicalHistory),
          _DrawerInfoRow(label: 'Registered', value: patient.createdAt),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: patient.uid == null ? null : onSelect,
                icon: Icon(
                  isSelected ? Icons.check_circle : Icons.event_available,
                ),
                label: Text(isSelected ? 'Selected' : 'Select patient'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerInfoRow extends StatelessWidget {
  const _DrawerInfoRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayValue = (value != null && value!.trim().isNotEmpty)
        ? value!.trim()
        : 'Not provided';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(displayValue, style: textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
