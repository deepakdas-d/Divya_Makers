import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SigninController extends GetxController {
  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isInputEmpty = true.obs;
  var isInputValid = false.obs;

  @override
  void onInit() {
    super.onInit();

    emailOrPhoneController.addListener(() {
      final input = emailOrPhoneController.text.trim();
      isInputEmpty.value = input.isEmpty;
      isInputValid.value = _isValidEmail(input) || _isValidPhone(input);
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<String?> getEmailFromPhone(String phone) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('Makers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.get('email');
      }
    } catch (_) {}
    return null;
  }

  Future<String?> signIn(String input, String password) async {
    try {
      String? email;
      String? uid;

      if (_isValidEmail(input)) {
        email = input;
      } else if (_isValidPhone(input)) {
        final query = await FirebaseFirestore.instance
            .collection('Makers')
            .where('phone', isEqualTo: input)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          email = query.docs.first.get('email');
          uid = query.docs.first.get('uid');
        } else {
          return 'No account found for this phone number.';
        }
      } else {
        return 'Invalid email or phone number format.';
      }

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email!, password: password);

      uid ??= userCredential.user?.uid;

      final makersDoc = await FirebaseFirestore.instance
          .collection('Makers')
          .doc(uid)
          .get();

      if (!makersDoc.exists || makersDoc['role'] != 'Makers') {
        await FirebaseAuth.instance.signOut();
        return 'Access denied. You are not a Makers.';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
