import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> loginUser(String email, String password, String role) async {
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
          final rawData = userDataResponse['data'] as Map<String, dynamic>?;
          final userData = <String, dynamic>{
            'uid': user.uid,
            'role': role,
            ...?rawData,
          };
          state = AppState(isLoading: false, auth: state.auth, user: userData);
          SharedPreferences sharedPreferences =
              await SharedPreferences.getInstance();
          sharedPreferences.setString('role', role);
          sharedPreferences.setString('uid', user.uid);
        } else {
          Get.snackbar(
            "Data Error",
            userDataResponse['message'] ?? "Failed to retrieve user data",
            backgroundColor: const Color(0xFFFF0000),
          );
          setLoading(false);
        }
      } else {
        Get.snackbar(
          "Login Error",
          response['message'] ?? "An error occurred",
          backgroundColor: const Color(0xFFFF0000),
        );
        setLoading(false);
        return;
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Login Error",
        e.message ?? "An error occurred",
        backgroundColor: const Color(0xFFFF0000),
      );
      setLoading(false);
    }
  }

  Future<void> signUpUser(
    String email,
    String password,
    String role,
    dynamic data,
  ) async {
    setLoading(true);
    try {
      final response = await firebaseServices.signUp(email, password);
      if (response['status'] == 'success') {
        final User? user = response['user'];
        final Map<String, dynamic>? inputData = data is Map<String, dynamic>
            ? Map<String, dynamic>.from(data)
            : null;
        inputData?.addAll({'uid': user?.uid, 'role': role});
        final createUserResponse = await firebaseServices.createUser(
          email,
          role,
          inputData,
        );
        if (createUserResponse['status'] == 'success' && user != null) {
          final profileData = {
            'uid': user.uid,
            'email': email,
            'role': role,
            ...?inputData,
          };
          await firebaseServices.setUserData(user.uid, profileData);
          final sharedPreferences = await SharedPreferences.getInstance();
          await sharedPreferences.setString('uid', user.uid);
          await sharedPreferences.setString('role', role);
          Get.snackbar(
            "Success",
            "Account created successfully",
            backgroundColor: const Color(0xFF00FF00),
          );
          // set the appState user to the created user data
          state = AppState(
            isLoading: false,
            auth: state.auth,
            user: profileData,
          );
        } else {
          Get.snackbar(
            "Creation Error",
            createUserResponse['message'] ?? "Failed to create user data",
            backgroundColor: const Color(0xFFFF0000),
          );
          setLoading(false);
          return;
        }
      } else {
        Get.snackbar(
          "Sign Up Error",
          response['message'] ?? "An error occurred",
          backgroundColor: const Color(0xFFFF0000),
        );
        setLoading(false);
        return;
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Sign Up Error",
        e.message ?? "An error occurred",
        backgroundColor: const Color(0xFFFF0000),
      );
      setLoading(false);
    }
  }

  //for a loggedin user, fetch and set user data
  Future<void> setUser() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? uid = sharedPreferences.getString('uid');
    String? role = sharedPreferences.getString('role');
    if (uid != null && role != null) {
      final userDataResponse = await firebaseServices.getUserData(uid, role);
      if (userDataResponse['status'] == 'success') {
        final rawData = userDataResponse['data'] as Map<String, dynamic>?;
        final userData = <String, dynamic>{
          'uid': uid,
          'role': role,
          ...?rawData,
        };
        state = AppState(isLoading: false, auth: state.auth, user: userData);
      }
    }
  }

  Future<void> signOutUser() async {
    setLoading(true);
    final response = await firebaseServices.signOut();
    if (response['status'] == 'success') {
      state = AppState(
        isLoading: false,
        auth: FirebaseAuth.instance,
        user: null,
      );
      Get.snackbar(
        "Signed Out",
        "You have been signed out successfully",
        backgroundColor: const Color(0xFF9C27B0),
        colorText: Colors.white,
      );
    } else {
      setLoading(false);
      Get.snackbar(
        "Sign Out Error",
        response['message'] ?? "Failed to sign out",
        backgroundColor: const Color(0xFFFF0000),
      );
    }
  }
}

final appStateProvider = NotifierProvider<appStateNotifier, AppState>(
  () => appStateNotifier(),
);
