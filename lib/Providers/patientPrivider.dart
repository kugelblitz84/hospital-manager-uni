import 'package:medicare/services/authServices.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'dart:ui';

class patient {
  String? name;
  String? email;
  String? uid;
  String? createdAt;
  String? phone;
  String? address;
  String? age;
  String? medicalHistory;
  patient({
    this.name,
    this.email,
    this.uid,
    this.createdAt,
    this.phone,
    this.address,
    this.age,
    this.medicalHistory,
  });
}

class patientListNotifier extends Notifier<List<patient>> {
  @override
  List<patient> build() {
    return [];
  }

  void setPatients() async {
    final res = await firebaseServices.getUserList('patient');
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to retrieve patients",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    List<patient> patients = [];
    for (var doc in res['data']) {
      patients.add(
        patient(
          name: doc['name'],
          email: doc['email'],
          uid: doc['uid'],
          createdAt: doc['createdAt'],
          phone: doc['phone'],
          address: doc['address'],
          age: doc['age'],
          medicalHistory: doc['medicalHistory'],
        ),
      );
    }
    state = patients;
  }

  Future<patient?> registerPatient(patient newPatient) async {
    final email = newPatient.email?.trim() ?? '';
    if (email.isEmpty) {
      Get.snackbar(
        'Missing email',
        'Patient email is required for registration.',
        backgroundColor: const Color(0xFFFF0000),
        colorText: const Color(0xFFFFFFFF),
      );
      return null;
    }

    final createdAt = newPatient.createdAt ?? DateTime.now().toIso8601String();
    final data =
        <String, dynamic>{
          'name': newPatient.name?.trim(),
          'email': email,
          'phone': newPatient.phone?.trim(),
          'address': newPatient.address?.trim(),
          'age': newPatient.age?.trim(),
          'medicalHistory': newPatient.medicalHistory?.trim(),
          'createdAt': createdAt,
        }..removeWhere(
          (key, value) => value == null || (value is String && value.isEmpty),
        );

    final res = await firebaseServices.createUser(email, 'patient', data);
    if (res['status'] != 'success') {
      Get.snackbar(
        'Registration failed',
        res['message'] ?? 'Unable to register patient.',
        backgroundColor: const Color(0xFFFF0000),
        colorText: const Color(0xFFFFFFFF),
      );
      return null;
    }

    final uid = (res['userId'] ?? '').toString();
    final registeredPatient = patient(
      uid: uid.isEmpty ? newPatient.uid : uid,
      name: newPatient.name,
      email: email,
      createdAt: createdAt,
      phone: newPatient.phone,
      address: newPatient.address,
      age: newPatient.age,
      medicalHistory: newPatient.medicalHistory,
    );

    state = [...state, registeredPatient];
    Get.snackbar(
      'Patient registered',
      '${registeredPatient.name ?? registeredPatient.email ?? 'Patient'} has been added.',
      backgroundColor: const Color(0xFF4CAF50),
      colorText: const Color(0xFFFFFFFF),
    );
    return registeredPatient;
  }
}

final patientListProvider =
    NotifierProvider<patientListNotifier, List<patient>>(
      () => patientListNotifier(),
    );
