import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// লগইন করা ব্যবহারকারীর প্রোফাইল (রোলসহ), রিয়েলটাইমে।
  Stream<AppUser?> profile(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  /// Firebase-এর ইংরেজি এরর কোডকে বাংলা বার্তায় রূপান্তর।
  static String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'ইমেইল ঠিকানাটি সঠিক নয়।';
        case 'user-disabled':
          return 'এই অ্যাকাউন্টটি বন্ধ করা হয়েছে। সুপার অ্যাডমিনের সাথে যোগাযোগ করুন।';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'ইমেইল বা পাসওয়ার্ড ভুল।';
        case 'too-many-requests':
          return 'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
        case 'network-request-failed':
          return 'ইন্টারনেট সংযোগ পরীক্ষা করুন।';
      }
      return error.message ?? 'লগইন করা যায়নি (${error.code})।';
    }
    return 'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।';
  }
}
