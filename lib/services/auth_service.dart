import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      // ✅ 기존 세션 로그아웃 → 항상 계정 선택창 띄우기
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('🚫 로그인 취소됨');
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        debugPrint('✅ 로그인 성공: ${user.displayName} (${user.email})');

        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          debugPrint('🆕 신규 사용자입니다.');
          await _firestore.collection('users').doc(user.uid).set({
            'email': user.email,
            'name': user.displayName,
            'joinedAt': DateTime.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('환영합니다, ${user.displayName ?? user.email}님!')),
          );
        } else {
          debugPrint('🙋 기존 사용자입니다.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('다시 오신 걸 환영합니다, ${user.displayName}!')),
          );
        }
      }

      return user;
    } catch (e, stackTrace) {
      debugPrint('⚠️ 로그인 실패: $e');
      if (e is FirebaseAuthException) {
        debugPrint('에러 코드: ${e.code}');
        debugPrint('에러 메시지: ${e.message}');
      }
      debugPrint('StackTrace: $stackTrace');
      return null;
    }
  }
}
