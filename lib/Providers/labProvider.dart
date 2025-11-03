import 'package:medicare/services/labService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:medicare/services/authServices.dart';

class labTechnician {
  String? name;
  String? email;
  String? uid;
  String? createdAt;
  labTechnician({this.name, this.email, this.uid, this.createdAt});
}

class labTest {
  String? testId;
  String? testName;
  String? patientId;
  String? doctorId;
  String? testDescription;
  double? price;
  labTest({
    this.testId,
    this.testName,
    this.patientId,
    this.doctorId,
    this.testDescription,
    this.price,
  });
}

class labTechnicianListNotifier extends Notifier<List<labTechnician>> {
  @override
  List<labTechnician> build() {
    return [];
  }

  void setLabTechnicians() async {
    final res = await firebaseServices.getUserList('labTechnician');
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to retrieve lab technicians",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    List<labTechnician> labTechnicians = [];
    for (var doc in res['data']) {
      labTechnicians.add(
        labTechnician(
          name: doc['name'],
          email: doc['email'],
          uid: doc['uid'],
          createdAt: doc['createdAt'],
        ),
      );
    }
    state = labTechnicians;
  }
}

class LabTestsNotifier extends Notifier<List<labTest>> {
  @override
  List<labTest> build() {
    return [];
  }

  void setAllLabTests() async {
    final res = await LabService.getLabTests();
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to retrieve lab tests",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    List<labTest> tests = [];
    for (var doc in res['tests']) {
      tests.add(
        labTest(
          testId: doc['testId'],
          testName: doc['name'],
          patientId: doc['patientId'],
          doctorId: doc['doctorId'],
          testDescription: doc['description'],
          price: doc['price'] is num ? (doc['price'] as num).toDouble() : null,
        ),
      );
    }
    state = tests;
  }

  void setLabTestsForPatient(String patientId) async {
    final res = await LabService.getLabTestsForPatient(patientId);
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to retrieve lab tests",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    List<labTest> tests = [];
    for (var doc in res['tests']) {
      tests.add(
        labTest(
          testId: doc['testId'],
          testName: doc['name'],
          patientId: doc['patientId'],
          doctorId: doc['doctorId'],
          testDescription: doc['description'],
          price: doc['price'] is num ? (doc['price'] as num).toDouble() : null,
        ),
      );
    }
    state = tests;
  }

  void setNewLabTest(
    String patientId,
    String? doctorId,
    String name,
    String description,
    double price,
  ) async {
    final res = await LabService.addLabTest(
      patientId,
      doctorId,
      name,
      description,
      price,
    );
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to add lab test",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    labTest newTest = labTest(
      testId: res['testId'],
      testName: name,
      patientId: patientId,
      doctorId: doctorId,
      testDescription: description,
      price: price,
    );
    // add the new test to the state list
    state = [...state, newTest];
  }
}

final labTechnicianListProvider =
    NotifierProvider<labTechnicianListNotifier, List<labTechnician>>(
      () => labTechnicianListNotifier(),
    );

final labTestsProvider = NotifierProvider<LabTestsNotifier, List<labTest>>(
  () => LabTestsNotifier(),
);
