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
  String? _selectedDoctorId;
  String? _selectedPatientId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final read = ref.read;
    read(doctor_provider.doctorListProvider.notifier).setDoctors();
    read(patient_provider.patientListProvider.notifier).setPatients();
  }

  Future<void> _signOut() async {
    await ref.read(appStateProvider.notifier).signOutUser();
  }

  void _onDoctorChanged(String? value) {
    setState(() => _selectedDoctorId = value);
    if (value != null) {
      ref
          .read(appointments.doctorAppointmentProvider.notifier)
          .setAppointmentsForDoctor(value);
    }
  }

  void _onPatientChanged(String? value) {
    setState(() => _selectedPatientId = value);
    if (value != null) {
      ref
          .read(appointments.patientAppointmentProvider.notifier)
          .setAppointmentsForPatient(value);
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

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(doctor_provider.doctorListProvider);
    final patients = ref.watch(patient_provider.patientListProvider);
    final doctorAppointments = ref.watch(
      appointments.doctorAppointmentProvider,
    );
    final patientAppointments = ref.watch(
      appointments.patientAppointmentProvider,
    );

    final combinedAppointments =
        {
          for (final appt in [...doctorAppointments, ...patientAppointments])
            appt.appointmentId ??
                    '${appt.doctorId}-${appt.patientId}-${appt.dateTime}':
                appt,
        }.values.toList()..sort(
          (a, b) => (a.dateTime ?? DateTime.now()).compareTo(
            b.dateTime ?? DateTime.now(),
          ),
        );

    return Scaffold(
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
                          child: DropdownButtonFormField<String>(
                            value: _selectedDoctorId,
                            decoration: const InputDecoration(
                              labelText: 'Doctor',
                            ),
                            items: doctors
                                .map(
                                  (doctor_provider.doctor doc) =>
                                      DropdownMenuItem(
                                        value: doc.uid,
                                        child: Text(
                                          doc.name ?? doc.email ?? 'Doctor',
                                        ),
                                      ),
                                )
                                .toList(),
                            onChanged: _isBooking ? null : _onDoctorChanged,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPatientId,
                            decoration: const InputDecoration(
                              labelText: 'Patient',
                            ),
                            items: patients
                                .map(
                                  (patient_provider.patient p) =>
                                      DropdownMenuItem(
                                        value: p.uid,
                                        child: Text(
                                          p.name ?? p.email ?? 'Patient',
                                        ),
                                      ),
                                )
                                .toList(),
                            onChanged: _isBooking ? null : _onPatientChanged,
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
                      child: ElevatedButton(
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Appointments overview'),
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
