import 'package:cloud_firestore/cloud_firestore.dart';

class LabService {
  static Future<dynamic> addLabTest(
    String patientId,
    String? doctorId,
    String name,
    String description,
    double price,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final testDoc = await firestore.collection('lab_tests').add({
        'name': name,
        'description': description,
        'price': price,
        'patientId': patientId,
        'doctorId': doctorId,
      });
      return {"status": "success", "testId": testDoc.id};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> getLabTests() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore.collection('lab_tests').get();
      final tests = querySnapshot.docs
          .map((doc) => {'testId': doc.id, ...doc.data()})
          .toList();
      return {"status": "success", "tests": tests};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> getLabTestsForPatient(String patientId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('lab_tests')
          .where('patientId', isEqualTo: patientId)
          .get();
      final tests = querySnapshot.docs
          .map((doc) => {'testId': doc.id, ...doc.data()})
          .toList();
      return {"status": "success", "tests": tests};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> deleteLabTest(String testId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('lab_tests').doc(testId).delete();
      return {"status": "success"};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }
}
