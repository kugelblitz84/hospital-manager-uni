import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserData_Doctor {
  final String uid;
  final String email;
  final String name;
  final String specialization;
  late List<Appointments>? appointments;

  UserData_Doctor({
    required this.uid,
    required this.email,
    required this.name,
    required this.specialization,
  });
}

class UserData_Patient {
  final String uid;
  final String email;
  final String name;
  final int age;
  final String gender;
  final String medicalHistory;
  late List<Appointments>? appointments;

  UserData_Patient({
    required this.uid,
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    required this.medicalHistory,
  });
}

class Appointments {
  final String appointmentId;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final String reason;
  final String status;

  Appointments({
    required this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    required this.reason,
    required this.status,
  });
}


class UserData_DoctorNotifier extends Notifier<UserData_Doctor?> {
  @override
  UserData_Doctor? build() {
    return null; // Initial state is null (no user)
  }

  void setUser(UserData_Doctor user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }
}

class UserData_PatientNotifier extends Notifier<UserData_Patient?> {
  @override
  UserData_Patient? build() {
    return null; // Initial state is null (no user)
  }

  void setUser(UserData_Patient user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }
}

class AppointmentsNotifier extends Notifier<List<Appointments>> {
  @override
  List<Appointments> build() {
    return []; // Initial state is an empty list
  }

  void setAppointments(List<Appointments> appointments) {
    state = appointments;
  }
}

final DoctorProvider = NotifierProvider<UserData_DoctorNotifier, UserData_Doctor?>(() => UserData_DoctorNotifier());
final PatientProvider = NotifierProvider<UserData_PatientNotifier, UserData_Patient?>(() => UserData_PatientNotifier());
final AppointmentsProvider = NotifierProvider<AppointmentsNotifier, List<Appointments>>(() => AppointmentsNotifier());
