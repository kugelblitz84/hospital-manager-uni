import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare/services/authServices.dart';
import 'package:get/get.dart';

class AppState {
  bool isLoading = true;
  dynamic user;
  dynamic auth;
  AppState({this.isLoading = true, this.user, this.auth});
}

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

class receptionist {
  static String? name;
  static String? email;
  static String? uid;
  static String? createdAt;
}

class inventoryManager {
  static String? name;
  static String? email;
  static String? uid;
  static String? createdAt;
}

class inventoryItem {
  String? itemId;
  String? itemName;
  String? itemDescription;
  int? quantity;
  double? price;
  inventoryItem({
    this.itemId,
    this.itemName,
    this.itemDescription,
    this.quantity,
    this.price,
  });
}

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
  labTest({this.testId, this.testName, this.testDescription, this.price});
}

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

class appStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      return AppState(isLoading: false, auth: auth, user: auth.currentUser);
    }
    return AppState(isLoading: false, auth: auth, user: null);
  }

  void setLoading(bool loading) {
    state = AppState(isLoading: loading, auth: state.auth, user: state.user);
  }

  Future<dynamic> loginUser(String email, String password, String role) async {
    setLoading(true);
    try {
      final response = await firebaseServices.signIn(email, password);
      if (response['status'] == 'success') {
        Get.snackbar(
          "Success",
          "Logged in successfully",
          backgroundColor: const Color(0xFF00FF00),
        );
        final User? user = response['user'];
        final userDataResponse = await firebaseServices.getUserData(
          user!.uid,
          role,
        );
        if (userDataResponse['status'] == 'success') {
          final userData = userDataResponse['data'];
          return userData;
          // You can process userData as needed
        } else {
          Get.snackbar(
            "Data Error",
            userDataResponse['message'] ?? "Failed to retrieve user data",
            backgroundColor: const Color(0xFFFF0000),
          );
        }
        return user;
      } else {
        Get.snackbar(
          "Login Error",
          response['message'] ?? "An error occurred",
          backgroundColor: const Color(0xFFFF0000),
        );
        setLoading(false);
        return null;
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Login Error",
        e.message ?? "An error occurred",
        backgroundColor: const Color(0xFFFF0000),
      );
    }
  }
}
