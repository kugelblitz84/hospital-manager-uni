import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState {
  String? role;
  bool isLoading = true;
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

class appStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    return AppState();
  }

  void initUser() {
    state.isLoading = true;
    
  }
}
