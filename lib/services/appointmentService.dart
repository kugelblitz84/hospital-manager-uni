import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  static Future<dynamic> bookAppointment(
    String doctorId,
    String patientId,
    DateTime dateTime,
    String reason,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final appointmentDoc = await firestore.collection('appointments').add({
        'doctorId': doctorId,
        'patientId': patientId,
        'dateTime': dateTime,
        'reason': reason,
      });
      return {"status": "success", "appointmentId": appointmentDoc.id};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> getAppointmentsForDoctor(String doctorId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      final appointments = querySnapshot.docs
          .map((doc) => {'appointmentId': doc.id, ...doc.data()})
          .toList();
      return {"status": "success", "appointments": appointments};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> getAppointmentsForPatient(String patientId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .get();
      final appointments = querySnapshot.docs
          .map((doc) => {'appointmentId': doc.id, ...doc.data()})
          .toList();
      return {"status": "success", "appointments": appointments};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> cancelAppointment(String appointmentId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('appointments').doc(appointmentId).delete();
      return {"status": "success"};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }
}
