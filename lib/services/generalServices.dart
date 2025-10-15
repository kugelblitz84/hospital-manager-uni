import 'package:medicare/services/firebaseServices.dart';
import 'package:medicare/Providers/UserProvides.dart';

class GeneralServices {
  static Future<dynamic> initUser() async {
    final response = await AuthServices.isLoggedIn();
    if (response['status'] == 'true') {
      final uid = response['uid'];
      final userResponse = await AuthServices.getUserData(uid);
      if (userResponse['status'] == 'success') {
        return await UserDataRef(userResponse); // Returns {'role': 'doctor'/'patient', 'data': UserData_Doctor/UserData_Patient}
      } else {
        return {'role': 'guest', 'data': null};
      }
    } else {
      // Not logged in
      return {'role': 'guest', 'data': null};
    }
  }

  static Future<dynamic> UserDataRef(dynamic userResponse) async { // use the response['data'] in the user provider ref
    final userData = userResponse['data'];
    final uid = userResponse['uid'];
    if (userResponse['role'] == 'doctor') {
      UserData_Doctor currentDoctor = UserData_Doctor(
        uid: uid,
        email: userData['email'],
        name: userData['name'],
        specialization: userData['specialization'],
      );
      currentDoctor.appointments =
          (userData['appointments'] as List<dynamic>)
              .map(
                (appointment) => Appointments(
                  appointmentId: appointment['appointmentId'],
                  doctorId: appointment['doctorId'],
                  patientId: appointment['patientId'],
                  dateTime: (appointment['dateTime']).toDate(),
                  reason: appointment['reason'],
                  status: appointment['status'],
                ),
              )
              .toList() ??
          [];
      return {'role': 'doctor', 'data': currentDoctor};
    } else if (userResponse['role'] == 'patient') {
      UserData_Patient currentPatient = UserData_Patient(
        uid: uid,
        email: userData['email'],
        name: userData['name'],
        age: userData['age'],
        gender: userData['gender'],
        medicalHistory: userData['medicalHistory'],
      );
      currentPatient.appointments =
          (userData['appointments'] as List<dynamic>)
              .map(
                (appointment) => Appointments(
                  appointmentId: appointment['appointmentId'],
                  doctorId: appointment['doctorId'],
                  patientId: appointment['patientId'],
                  dateTime: (appointment['dateTime']).toDate(),
                  reason: appointment['reason'],
                  status: appointment['status'],
                ),
              )
              .toList() ??
          [];
      return {'role': 'patient', 'data': currentPatient};
    }
  }

  // Add general services methods here
}
