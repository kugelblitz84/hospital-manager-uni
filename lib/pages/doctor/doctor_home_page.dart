import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:medicare/Providers/UserProvides.dart';
import 'package:medicare/Providers/appointmentProvider.dart' as appointments;
import 'package:medicare/Providers/patientPrivider.dart' as patient_provider;
import 'package:medicare/theme/app_theme.dart';

class DoctorHomePage extends ConsumerStatefulWidget {
  const DoctorHomePage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  ConsumerState<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends ConsumerState<DoctorHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final doctorId = widget.user['uid']?.toString();
    if (doctorId != null) {
      ref
          .read(appointments.doctorAppointmentProvider.notifier)
          .setAppointmentsForDoctor(doctorId);
    }
    ref.read(patient_provider.patientListProvider.notifier).setPatients();
  }

  Future<void> _refresh() async {
    _loadData();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _signOut() async {
    await ref.read(appStateProvider.notifier).signOutUser();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsList = ref.watch(appointments.doctorAppointmentProvider);
    final patients = ref.watch(patient_provider.patientListProvider);

    final sortedAppointments = [...appointmentsList]
      ..sort(
        (a, b) => (a.dateTime ?? DateTime.now()).compareTo(
          b.dateTime ?? DateTime.now(),
        ),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Doctor Workspace · ${widget.user['name'] ?? widget.user['email'] ?? ''}',
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: Get.width * 0.04,
            vertical: Get.height * 0.03,
          ),
          children: [
            _SectionHeader(title: 'Upcoming appointments'),
            if (sortedAppointments.isEmpty)
              _EmptyState(message: 'No appointments scheduled yet.')
            else
              ...sortedAppointments.map((appointments.appointment appt) {
                final match =
                    patients
                        .where(
                          (patient_provider.patient p) =>
                              p.uid == appt.patientId,
                        )
                        .cast<patient_provider.patient?>()
                        .firstWhere(
                          (element) => element != null,
                          orElse: () => null,
                        ) ??
                    patient_provider.patient();
                return _AppointmentCard(appointment: appt, patient: match);
              }),
            const SizedBox(height: 32),
            _SectionHeader(title: 'Patient directory'),
            if (patients.isEmpty)
              _EmptyState(message: 'No patient records available.')
            else
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: patients
                    .map(
                      (patient_provider.patient p) => SizedBox(
                        width: Get.width * 0.28,
                        child: _PatientCard(patient: p),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.patient});

  final appointments.appointment appointment;
  final patient_provider.patient patient;

  @override
  Widget build(BuildContext context) {
    final date = appointment.dateTime;
    final formattedDate = date != null
        ? '${date.day}/${date.month}/${date.year} · ${TimeOfDay.fromDateTime(date).format(context)}'
        : 'Not scheduled';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  patient.name ?? 'Unknown patient',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Chip(
                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                  label: Text(
                    formattedDate,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(patient.email ?? 'No email'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              appointment.reason ?? 'No reason provided',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient});

  final patient_provider.patient patient;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patient.name ?? 'Unknown patient',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(patient.email ?? 'No email')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(patient.phone ?? 'No phone')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Medical history',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              patient.medicalHistory?.isNotEmpty == true
                  ? patient.medicalHistory!
                  : 'Not specified',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
