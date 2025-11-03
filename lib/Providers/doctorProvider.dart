import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicare/services/authServices.dart';
import 'package:get/get.dart';

class doctor {
  String? name;
  String? email;
  String? speciality;
  String? uid;
  String? createdAt;
  List<String>? certifications;
  doctor({
    this.name,
    this.email,
    this.speciality,
    this.uid,
    this.createdAt,
    this.certifications,
  });
}

class doctorListNotifier extends Notifier<List<doctor>> {
  @override
  List<doctor> build() {
    return [];
  }

  void setDoctors() async {
    final res = await firebaseServices.getUserList('doctor');
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to retrieve doctors",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    List<doctor> doctors = [];
    for (var doc in res['data']) {
      doctors.add(
        doctor(
          name: doc['name'],
          email: doc['email'],
          speciality: doc['speciality'],
          uid: doc['uid'],
          createdAt: doc['createdAt'],
          certifications: List<String>.from(doc['certifications'] ?? []),
        ),
      );
    }
    state = doctors;
  }
}

final doctorListProvider = NotifierProvider<doctorListNotifier, List<doctor>>(
  () => doctorListNotifier(),
);
