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
