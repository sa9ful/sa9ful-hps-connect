import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// পুশ নোটিফিকেশনের অনুমতি নেয় এবং ডিভাইসের FCM টোকেন
/// `users/{uid}.fcmTokens`-এ সংরক্ষণ করে, যাতে Cloud Functions
/// নির্দিষ্ট ব্যবহারকারী বা রোলকে নোটিফিকেশন পাঠাতে পারে।
class PushService {
  static StreamSubscription<String>? _sub;
  static String? _uid;

  static Future<void> registerDevice(String uid) async {
    if (_uid == uid) return;
    _uid = uid;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      // নতুন বা রিফ্রেশ হওয়া টোকেন onRegistered দিয়ে আসে।
      await _sub?.cancel();
      _sub = messaging.onRegistered.listen((t) => _saveToken(uid, t));
      await messaging.register();
    } catch (e) {
      debugPrint('FCM রেজিস্ট্রেশন ব্যর্থ: $e');
    }
  }

  static Future<void> _saveToken(String uid, String token) =>
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
}
