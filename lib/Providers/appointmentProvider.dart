import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:medicare/services/appointmentService.dart';

class appointment {
  String? appointmentId;
  String? doctorId;
  String? patientId;
  DateTime? dateTime;
  String? reason;
  appointment({
    this.appointmentId,
    this.doctorId,
    this.patientId,
    this.dateTime,
    this.reason,
  });
}

class PatientAppointmentProvider extends Notifier<List<appointment>> {
  @override
  List<appointment> build() {
    return [];
  }

  void setAppointmentsForPatient(String patientId) async {
    final res = await AppointmentService.getAppointmentsForPatient(patientId);
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to retrieve appointments",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    List<appointment> appointments = [];
    for (var doc in res['appointments']) {
      appointments.add(
        appointment(
          appointmentId: doc['appointmentId'],
          doctorId: doc['doctorId'],
          patientId: doc['patientId'],
          dateTime: _parseAppointmentDate(doc['dateTime']),
          reason: doc['reason'],
        ),
      );
    }
    state = appointments;
  }

  void clear() {
    state = [];
  }
}

class DoctorAppointmentProvider extends Notifier<List<appointment>> {
  @override
  List<appointment> build() {
    return [];
  }

  void setAppointmentsForDoctor(String doctorId) async {
    final res = await AppointmentService.getAppointmentsForDoctor(doctorId);
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to retrieve appointments",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    List<appointment> appointments = [];
    for (var doc in res['appointments']) {
      appointments.add(
        appointment(
          appointmentId: doc['appointmentId'],
          doctorId: doc['doctorId'],
          patientId: doc['patientId'],
          dateTime: _parseAppointmentDate(doc['dateTime']),
          reason: doc['reason'],
        ),
      );
    }
    state = appointments;
  }

  void clear() {
    state = [];
  }
}

class CombinedAppointmentNotifier extends Notifier<List<appointment>> {
  String? _doctorId;
  String? _patientId;

  @override
  List<appointment> build() {
    return [];
  }

  void setFilters({String? doctorId, String? patientId}) {
    final normalizedDoctor = doctorId?.trim().isNotEmpty == true
        ? doctorId
        : null;
    final normalizedPatient = patientId?.trim().isNotEmpty == true
        ? patientId
        : null;
    final hasDoctorChanged = normalizedDoctor != _doctorId;
    final hasPatientChanged = normalizedPatient != _patientId;
    _doctorId = normalizedDoctor;
    _patientId = normalizedPatient;
    if (hasDoctorChanged || hasPatientChanged) {
      _loadAppointments();
    }
  }

  void refreshCurrentFilters() {
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final currentDoctor = _doctorId;
    final currentPatient = _patientId;

    if (currentDoctor == null && currentPatient == null) {
      state = [];
      return;
    }

    List<appointment> doctorAppointments = [];
    List<appointment> patientAppointments = [];

    if (currentDoctor != null) {
      final res = await AppointmentService.getAppointmentsForDoctor(
        currentDoctor,
      );
      if (res['status'] == 'success') {
        doctorAppointments = _mapRawAppointments(res['appointments']);
      } else {
        _showError(res['message']);
      }
    }

    if (currentPatient != null &&
        (currentDoctor == null || doctorAppointments.isEmpty)) {
      final res = await AppointmentService.getAppointmentsForPatient(
        currentPatient,
      );
      if (res['status'] == 'success') {
        patientAppointments = _mapRawAppointments(res['appointments']);
      } else {
        _showError(res['message']);
      }
    } else if (currentPatient != null && currentDoctor != null) {
      // Fetch for patient as well so list stays current even if doctor cache misses items.
      final res = await AppointmentService.getAppointmentsForPatient(
        currentPatient,
      );
      if (res['status'] == 'success') {
        patientAppointments = _mapRawAppointments(res['appointments']);
      }
    }

    if (currentDoctor != _doctorId || currentPatient != _patientId) {
      return;
    }

    List<appointment> result;
    if (currentDoctor != null) {
      result = doctorAppointments;
      if (currentPatient != null) {
        result = result
            .where((appt) => appt.patientId == currentPatient)
            .toList();
        if (result.isEmpty && patientAppointments.isNotEmpty) {
          result = patientAppointments
              .where((appt) => appt.doctorId == currentDoctor)
              .toList();
        }
      }
    } else {
      result = patientAppointments;
    }

    final seenKeys = <String>{};
    result = [
      for (final appt in result)
        if (seenKeys.add(_mapKey(appt))) appt,
    ];

    result.sort(
      (a, b) => (a.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(b.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );

    state = result;
  }

  List<appointment> _mapRawAppointments(dynamic raw) {
    if (raw is! List) {
      return [];
    }
    final appointments = <appointment>[];
    for (final entry in raw) {
      if (entry is! Map) {
        continue;
      }
      final data = Map<String, dynamic>.from(entry);
      appointments.add(
        appointment(
          appointmentId: data['appointmentId']?.toString(),
          doctorId: data['doctorId']?.toString(),
          patientId: data['patientId']?.toString(),
          dateTime: _parseAppointmentDate(data['dateTime']),
          reason: data['reason']?.toString(),
        ),
      );
    }
    return appointments;
  }

  String _mapKey(appointment appt) {
    return appt.appointmentId ??
        '${appt.doctorId}-${appt.patientId}-${appt.dateTime?.millisecondsSinceEpoch}';
  }

  void _showError(dynamic message) {
    final display = message?.toString() ?? 'Failed to retrieve appointments';
    Get.snackbar(
      'Error',
      display,
      backgroundColor: const Color.fromARGB(255, 255, 0, 0),
    );
  }
}

DateTime? _parseAppointmentDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

final patientAppointmentProvider =
    NotifierProvider<PatientAppointmentProvider, List<appointment>>(
      () => PatientAppointmentProvider(),
    );

final doctorAppointmentProvider =
    NotifierProvider<DoctorAppointmentProvider, List<appointment>>(
      () => DoctorAppointmentProvider(),
    );

final combinedAppointmentProvider =
    NotifierProvider<CombinedAppointmentNotifier, List<appointment>>(
      () => CombinedAppointmentNotifier(),
    );
