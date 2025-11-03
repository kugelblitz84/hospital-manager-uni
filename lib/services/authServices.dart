import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class firebaseServices {
  // Firebase authentication methods
  static Future<dynamic> signIn(String email, String password) async {
    try {
      final auth = FirebaseAuth.instance;
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return {"status": "success", "user": userCredential.user};
    } on FirebaseAuthException catch (e) {
      return {"status": "error", "message": e.message};
    }
  }

  static Future<dynamic> signUp(String email, String password) async {
    try {
      final auth = FirebaseAuth.instance;
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {"status": "success", "user": userCredential.user};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return {"status": "error", "message": "The email is already in use."};
      } else {
        return {"status": "error", "message": e.message};
      }
    }
  }

  static Future<dynamic> signOut() async {
    try {
      final auth = FirebaseAuth.instance;
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      await auth.signOut();
      await sharedPreferences.clear();
      return {"status": "success"};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> createUser(
    String email,
    String role,
    dynamic data,
  ) async {
    try {
      // check if this email already exists in the role collection
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection(role)
          .where('email', isEqualTo: email)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return {"status": "error", "message": "Email already exists."};
      }

      final payload = <String, dynamic>{'email': email, 'role': role, ...?data};
      final uid = payload['uid'];
      if (uid is String && uid.isNotEmpty) {
        await firestore.collection(role).doc(uid).set(payload);
        return {"status": "success", "userId": uid};
      }

      final userDoc = await firestore.collection(role).add(payload);
      return {"status": "success", "userId": userDoc.id};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> setUserData(String uid, dynamic data) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userRole = data['role'];
      await firestore.collection(userRole).doc(uid).set(data);
      return {"status": "success"};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> getUserData(String uid, String role) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot doc = await firestore.collection(role).doc(uid).get();
      if (doc.exists) {
        return {"status": "success", "data": doc.data()};
      } else {
        return {"status": "error", "message": "User data not found."};
      }
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> getUserList(String role) async {
    try {
      final firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot = await firestore.collection(role).get();
      List<dynamic> users = querySnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>,
        );
        data.putIfAbsent('uid', () => doc.id);
        data.putIfAbsent('role', () => role);
        return data;
      }).toList();
      return {"status": "success", "data": users};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> adminCreateUserAccount(
    String email,
    String password,
  ) async {
    try {
      final defaultApp = Firebase.app();
      final tempApp = await Firebase.initializeApp(
        name: 'admin-helper-${DateTime.now().millisecondsSinceEpoch}',
        options: defaultApp.options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await tempApp.delete();
      return {"status": "success", "user": credential.user};
    } on FirebaseAuthException catch (e) {
      return {"status": "error", "message": e.message};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }
}
