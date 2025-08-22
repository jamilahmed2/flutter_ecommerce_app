import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Initialize notifications
  Future<void> initialize() async {
    await _fcm.requestPermission();
    await _setupFCMListeners();
  }

  // Setup FCM listeners
  Future<void> _setupFCMListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNotification(message.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotification(message.data);
    });
  }

  // Handle notification data
  void _handleNotification(Map<String, dynamic> data) {
    final type = data['type'];
    final title = data['title'] ?? 'New Notification';
    final message = data['message'] ?? '';
    final productId = data['productId'];
    final offerId = data['offerId'];
    final orderId = data['orderId'];

    // Add to user's notifications collection
    addUserNotification(
      type: type,
      title: title,
      message: message,
      productId: productId,
      offerId: offerId,
      orderId: orderId,
    );
  }

  // Add notification to current user
  Future<void> addUserNotification({
  required String type,
  required String title,
  required String message,
  String? userId, // ✅ Accept optional target user
  String? productId,
  String? offerId,
  String? orderId,
}) async {
  final targetUserId = userId ?? _auth.currentUser?.uid;
  if (targetUserId == null) return;

  await _firestore
      .collection('users')
      .doc(targetUserId)
      .collection('notifications')
      .add({
    'type': type,
    'title': title,
    'message': message,
    'time': Timestamp.now(),
    'read': false,
    'productId': productId,
    'offerId': offerId,
    'orderId': orderId,
  });
}


  // Add notification to all users
  Future<void> addGlobalNotification({
    required String type,
    required String title,
    required String message,
    String? productId,
    String? offerId,
  }) async {
    final users = await _firestore.collection('users').get();
    for (final user in users.docs) {
      await user.reference.collection('notifications').add({
        'type': type,
        'title': title,
        'message': message,
        'time': Timestamp.now(),
        'read': false,
        'productId': productId,
        'offerId': offerId,
      });
    }
  }
}