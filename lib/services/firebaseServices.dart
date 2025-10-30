import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  //check if user is logged in
  static Future<dynamic> isLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return {'status': 'true', 'uid': user.uid};
    }
    return {'status': 'false'};
  }

  // Sign in with email and password
  static Future<dynamic> registerPatient(
    String email,
    String password,
    String name,
    int age,
    String gender,
    String medicalHistory,
  ) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User ID is null after registration');
      await FirebaseFirestore.instance.collection('patients').doc(uid).set({
        'name': name,
        'age': age,
        'gender': gender,
        'medicalHistory': medicalHistory,
        'email': email,
        'appointments': [],
        'registered': true,
      });
      return {'status': 'success', 'uid': uid};
    } on FirebaseAuthException catch (e) {
      // Get.snackbar(
      //   'Registration Error',
      //   e.message ?? 'An unknown error occurred',
      // );
      return {'status': 'failed', 'message': e.message.toString()};
    }
  }

  static Future<dynamic> registerDoctor(
    String email,
    String password,
    String name,
    String specialization,
  ) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User ID is null after registration');
      await FirebaseFirestore.instance.collection('doctors').doc(uid).set({
        'name': name,
        'specialization': specialization,
        'email': email,
        'appointments': [],
        'active': true,
      });
      return {'status': 'success', 'uid': uid};
    } on FirebaseAuthException catch (e) {
      //Get.snackbar('Registration Error', e.message ?? 'An unknown error occurred');
      return {'status': 'failed', 'message': e.message.toString()};
    }
  }

  static Future<dynamic> registerReceptionist(
    String email,
    String password,
    String name,
    String department,
  ) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User ID is null after registration');
      await FirebaseFirestore.instance.collection('receptionists').doc(uid).set(
        {'name': name, 'department': department, 'email': email},
      );
      return {'status': 'success', 'uid': uid};
    } on FirebaseAuthException catch (e) {
      //Get.snackbar('Registration Error', e.message ?? 'An unknown error occurred');
      return {'status': 'failed', 'message': e.message.toString()};
    }
  }

  // login with email and password
  static Future<dynamic> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User is null after login');
      dynamic userData = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .get();
      if (userData.exists) {
        return {
          'status': 'success',
          'role': 'patient',
          'uid': user.uid,
          'data': userData.data(),
        };
      }
      userData = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();
      if (userData.exists) {
        return {
          'status': 'success',
          'role': 'doctor',
          'uid': user.uid,
          'data': userData.data(),
        };
      }
      return {'status': 'failed', 'message': 'User record not found'};
    } on FirebaseAuthException catch (e) {
      //Get.snackbar('Login Error', e.message ?? 'An unknown error occurred');
      return {'status': 'failed', 'message': e.message.toString()};
    }
  }

  static Future<dynamic> getUserData(String uid) async {
    try {
      dynamic userData = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();
      if (userData.exists) {
        return {
          'status': 'success',
          'role': 'patient',
          'data': userData.data(),
        };
      }
      userData = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .get();
      if (userData.exists) {
        return {'status': 'success', 'role': 'doctor', 'data': userData.data()};
      }
      return {'status': 'failed', 'message': 'User record not found'};
    } catch (e) {
      return {'status': 'failed', 'message': e.toString()};
    }
  }

  static Future<dynamic> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      return {'status': 'success'};
    } on FirebaseAuthException catch (e) {
      return {'status': 'failed', 'message': e.message.toString()};
    }
  }

  static Future<dynamic> sendResetPasswordMail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return {'status': 'success'};
    } on FirebaseAuthException catch (e) {
      return {'status': 'failed', 'message': e.message.toString()};
    }
  }
}

// class FirestoreServices {
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static Future<dynamic> getDoctors() async {
//     try {
//       final querySnapshot = await _firestore.collection('doctors').get();
//       final doctors = querySnapshot.docs
//           .map((doc) => {'id': doc.id, ...doc.data()})
//           .toList();
//       return {'status': 'success', 'doctors': doctors};
//     } catch (e) {
//       return {'status': 'failed', 'message': e.toString()};
//     }
//   }

//   static Future<dynamic> bookAppointment(
//     String doctorId,
//     String patientId,
//     DateTime dateTime,
//     String reason,
//   ) async {
//     try {
//       final appointmentRef = _firestore.collection('appointments').doc();
//       final appointmentRef_public = _firestore
//           .collection('publicAppointmentData')
//           .doc();

//       final appointmentId = appointmentRef.id;

//       // Check if doctor has existing appointments at the same time
//       final existingAppointments = await _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: doctorId)
//           .where('dateTime', isEqualTo: dateTime.toIso8601String())
//           .get();

//       if (existingAppointments.docs.isNotEmpty) {
//         return {
//           'status': 'failed',
//           'message': 'Doctor is not available at this time',
//         };
//       }

//       await appointmentRef.set({
//         'appointmentId': appointmentId,
//         'doctorId': doctorId,
//         'patientId': patientId,
//         'dateTime': dateTime.toIso8601String(),
//         'reason': reason,
//         'status': 'scheduled',
//       });

//       return {
//         'status': 'success',
//         'appointmentId': appointmentId,
//         'dateTime': dateTime,
//       };
//     } catch (e) {
//       return {'status': 'failed', 'message': e.toString()};
//     }
//   }

//   // static Future<dynamic> getAppointmentsByUser(String userId, String role) async {
//   //   try {
//   //     final userDoc = await _firestore.collection(role == 'doctor' ? 'doctors' : 'patients').doc(userId).get();
//   //     if (!userDoc.exists) {
//   //       return {'status': 'failed', 'message': 'User not found'};
//   //     }

//   //     final appointmentIds = List<String>.from(userDoc.data()?['appointments'] ?? []);
//   //     if (appointmentIds.isEmpty) {
//   //       return {'status': 'success', 'appointments': []};
//   //     }

//   //     final appointmentsQuery = await _firestore
//   //         .collection('appointments')
//   //         .where('appointmentId', whereIn: appointmentIds)
//   //         .get();

//   //     final appointments = appointmentsQuery.docs.map((doc) => doc.data()).toList();

//   //     return {'status': 'success', 'appointments': appointments};
//   //   } catch (e) {
//   //     return {'status': 'failed', 'message': e.toString()};
//   //   }
//   // }

//   // methods for handling walk-in patients
//   static Future<dynamic> addWalkinPatient(
//     String name,
//     int age,
//     String gender,
//     String medicalHistory,
//     String email,
//   ) async {
//     try {
//       final patientRef = FirebaseFirestore.instance
//           .collection('patients')
//           .doc();
//       await patientRef.set({
//         'name': name,
//         'age': age,
//         'gender': gender,
//         'medicalHistory': medicalHistory,
//         'appointments': [],
//         'registered': false,
//         'email': email,
//       });
//       return {'status': 'success', 'patientId': patientRef.id};
//     } catch (e) {
//       return {'status': 'failed', 'message': e.toString()};
//     }
//   }

//   static Future<dynamic> getWalkinPatients() async {
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('patients')
//           .where('registered', isEqualTo: false)
//           .get();
//       final walkinPatients = querySnapshot.docs
//           .map((doc) => {'id': doc.id, ...doc.data()})
//           .toList();
//       return {'status': 'success', 'walkinPatients': walkinPatients};
//     } catch (e) {
//       return {'status': 'failed', 'message': e.toString()};
//     }
//   }

//   static Future<dynamic> setAppointmentForWalkinPatient(
//     String patientId,
//     String doctorId,
//     DateTime dateTime,
//     String reason,
//   ) async {
//     try {
//       //check if doctor has existing appointments at the same time
//       final existingAppointments = await _firestore
//           .collection('appointments')
//           .where('doctorId', isEqualTo: doctorId)
//           .where('dateTime', isEqualTo: dateTime.toIso8601String())
//           .get();
//       if (existingAppointments.docs.isNotEmpty) {
//         return {
//           'status': 'failed',
//           'message': 'Doctor is not available at this time',
//         };
//       }
//       final appointmentRef = _firestore.collection('appointments').doc();
//       final appointmentId = appointmentRef.id;

//       await appointmentRef.set({
//         'appointmentId': appointmentId,
//         'doctorId': doctorId,
//         'patientId': patientId,
//         'dateTime': dateTime.toIso8601String(),
//         'reason': reason,
//         'status': 'scheduled',
//       });

//       // Update doctor's appointments
//       await _firestore.collection('doctors').doc(doctorId).update({
//         'appointments': FieldValue.arrayUnion([appointmentId]),
//       });

//       // Update patient's appointments
//       await _firestore.collection('patients').doc(patientId).update({
//         'appointments': FieldValue.arrayUnion([appointmentId]),
//       });

//       return {
//         'status': 'success',
//         'appointmentId': appointmentId,
//         'dateTime': dateTime,
//       };
//     } catch (e) {
//       return {'status': 'failed', 'message': e.toString()};
//     }
//   }
// }
