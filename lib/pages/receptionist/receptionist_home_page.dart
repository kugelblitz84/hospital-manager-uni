import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:medicare/Providers/UserProvides.dart';
import 'package:medicare/Providers/appointmentProvider.dart' as appointments;
import 'package:medicare/Providers/doctorProvider.dart' as doctor_provider;
import 'package:medicare/Providers/patientPrivider.dart' as patient_provider;
import 'package:medicare/services/appointmentService.dart';
import 'package:medicare/theme/app_theme.dart';
import 'package:medicare/widgets/selector_drawer.dart';

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
  final _reasonController = TextEditingController();
  late final VoidCallback _reasonListener;
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
    _reasonListener = () => setState(() {});
    _reasonController.addListener(_reasonListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _reasonController.removeListener(_reasonListener);
    _patientNameController.dispose();
    _patientEmailController.dispose();
    _patientPhoneController.dispose();
    _patientAddressController.dispose();
    _patientAgeController.dispose();
    _patientHistoryController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _hasDoctorSelection => (_selectedDoctorId ?? '').trim().isNotEmpty;

  bool get _hasPatientSelection => (_selectedPatientId ?? '').trim().isNotEmpty;

  bool get _hasRequiredSelections =>
      _hasDoctorSelection && _hasPatientSelection;

  String get _currentReason => _reasonController.text.trim();

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
    if (!_hasDoctorSelection || !_hasPatientSelection) {
      Get.snackbar(
        'Incomplete selection',
        'Select both a doctor and a patient before scheduling.',
      );
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
    final doctorConflict = _findConflict(slot, doctorAppointments);
    final patientConflict = _findConflict(slot, patientAppointments);
    if (doctorConflict != null || patientConflict != null) {
      Get.snackbar(
        'Slot unavailable',
        _buildConflictMessage(doctorConflict, patientConflict),
      );
      return;
    }

    final reasonText = _currentReason;
    if (reasonText.isEmpty) {
      Get.snackbar('Missing reason', 'Provide a short reason for the visit');
      return;
    }

    final doctorId = _selectedDoctorId!.trim();
    final patientId = _selectedPatientId!.trim();

    setState(() => _isBooking = true);
    final response = await AppointmentService.bookAppointment(
      doctorId,
      patientId,
      slot,
      reasonText,
    );
    setState(() => _isBooking = false);

    if (response['status'] == 'success') {
      ref
          .read(appointments.doctorAppointmentProvider.notifier)
          .setAppointmentsForDoctor(doctorId);
      ref
          .read(appointments.patientAppointmentProvider.notifier)
          .setAppointmentsForPatient(patientId);
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
        _reasonController.clear();
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
      _reasonController.clear();
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

  appointments.appointment? _findConflict(
    DateTime slot,
    List<appointments.appointment> list,
  ) {
    for (final appt in list) {
      final dateTime = appt.dateTime;
      if (dateTime == null) {
        continue;
      }
      if (_isSameHour(dateTime, slot)) {
        return appt;
      }
    }
    return null;
  }

  bool _isSameHour(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour;
  }

  String _formatSlot(DateTime dateTime) {
    final timeOfDay = TimeOfDay.fromDateTime(dateTime).format(context);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} · $timeOfDay';
  }

  String _buildConflictMessage(
    appointments.appointment? doctorConflict,
    appointments.appointment? patientConflict,
  ) {
    final messages = <String>[];

    if (doctorConflict != null) {
      final bookingTime = doctorConflict.dateTime;
      if (bookingTime != null) {
        messages.add(
          'Doctor already has an appointment at ${_formatSlot(bookingTime)}.',
        );
      } else {
        messages.add('Doctor already has an appointment during this hour.');
      }
    }

    final sameAppointment =
        doctorConflict?.appointmentId != null &&
        doctorConflict?.appointmentId == patientConflict?.appointmentId;

    if (patientConflict != null && !sameAppointment) {
      final bookingTime = patientConflict.dateTime;
      if (bookingTime != null) {
        messages.add(
          'Patient already has an appointment at ${_formatSlot(bookingTime)}.',
        );
      } else {
        messages.add('Patient already has an appointment during this hour.');
      }
    }

    if (messages.isEmpty) {
      return 'Doctor or patient already has an appointment during this hour.';
    }

    return messages.join(' ');
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
    final doctorAppointments = ref.watch(
      appointments.doctorAppointmentProvider,
    );
    final patientAppointments = ref.watch(
      appointments.patientAppointmentProvider,
    );
    final selectedDoctorLabel = _selectedDoctorLabel(doctors);
    final selectedPatientLabel = _selectedPatientLabel(patients);
    final hasSelections = _hasRequiredSelections;
    final selectedSlot = _selectedDateTime;
    final doctorConflict = hasSelections && selectedSlot != null
        ? _findConflict(selectedSlot, doctorAppointments)
        : null;
    final patientConflict = hasSelections && selectedSlot != null
        ? _findConflict(selectedSlot, patientAppointments)
        : null;
    final hasConflict = doctorConflict != null || patientConflict != null;
    final scheduleFieldsEnabled = hasSelections && !_isBooking;
    final canBook =
        !_isBooking &&
        hasSelections &&
        selectedSlot != null &&
        _currentReason.isNotEmpty &&
        !hasConflict;
    final conflictMessage = hasConflict
        ? _buildConflictMessage(doctorConflict, patientConflict)
        : null;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: SelectorDrawer(
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
                            enabled: scheduleFieldsEnabled,
                            onTap: scheduleFieldsEnabled ? _pickDate : null,
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
                            enabled: scheduleFieldsEnabled,
                            onTap: scheduleFieldsEnabled ? _pickTime : null,
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
                    if (!hasSelections)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Select a doctor and patient to enable date and time options.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    else if (conflictMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          conflictMessage,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.redAccent),
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _reasonController,
                      enabled: scheduleFieldsEnabled,
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                        labelText: 'Reason for visit',
                        hintText: 'Brief description (required)',
                        helperText: hasSelections
                            ? null
                            : 'Select doctor and patient first.',
                      ),
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
                            onPressed: canBook ? _bookAppointment : null,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Doctor: $doctorName · Patient: $patientName'),
            Text(
              appointment.reason?.isNotEmpty == true
                  ? 'Reason: ${appointment.reason}'
                  : 'Reason: Not provided',
            ),
          ],
        ),
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
