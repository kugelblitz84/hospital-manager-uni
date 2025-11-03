import 'package:medicare/services/authServices.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class receptionist {
  String? name;
  String? email;
  String? uid;
  String? createdAt;

  receptionist({this.name, this.email, this.uid, this.createdAt});
}

class receptionistProviders extends Notifier<List<receptionist>> {
  @override
  List<receptionist> build() {
    return [];
  }

  void setReceptionists() async {
    final res = await firebaseServices.getUserList('receptionist');
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to retrieve receptionists",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    List<receptionist> receptionists = [];
    for (var doc in res['data']) {
      receptionists.add(
        receptionist(
          name: doc['name'],
          email: doc['email'],
          uid: doc['uid'],
          createdAt: doc['createdAt'],
        ),
      );
    }
    state = receptionists;
  }
}

final receptionistProvider =
    NotifierProvider<receptionistProviders, List<receptionist>>(
      () => receptionistProviders(),
    );
