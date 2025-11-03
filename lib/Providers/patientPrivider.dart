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
}

final patientListProvider =
    NotifierProvider<patientListNotifier, List<patient>>(
      () => patientListNotifier(),
    );
