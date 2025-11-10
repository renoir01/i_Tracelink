import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _firestore
          .collection('notifications')
          .add(notification.toMap());
      
      print('✅ Notification created for user: $userId');
    } catch (e) {
      print('⚠️ Error creating notification: $e');
    }
  }

  // Get user notifications stream
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get unread count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('⚠️ Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('⚠️ Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('⚠️ Error deleting notification: $e');
    }
  }

  // ========== NOTIFICATION TEMPLATES ==========

  // Order placed notification
  Future<void> notifyOrderPlaced({
    required String userId,
    required String aggregatorName,
    required String orderId,
    required double quantity,
  }) async {
    await createNotification(
      userId: userId,
      title: 'New Order Received',
      body: '$aggregatorName placed an order for ${quantity.round()}kg',
      type: 'order',
      relatedId: orderId,
    );
  }

  // Order accepted notification
  Future<void> notifyOrderAccepted({
    required String userId,
    required String cooperativeName,
    required String orderId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Order Accepted',
      body: '$cooperativeName accepted your order',
      type: 'order',
      relatedId: orderId,
    );
  }

  // Order rejected notification
  Future<void> notifyOrderRejected({
    required String userId,
    required String cooperativeName,
    required String orderId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Order Declined',
      body: '$cooperativeName declined your order',
      type: 'order',
      relatedId: orderId,
    );
  }

  // Order status update
  Future<void> notifyOrderStatusUpdate({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    String statusText;
    switch (status) {
      case 'collected':
        statusText = 'has been collected';
        break;
      case 'in_transit':
        statusText = 'is now in transit';
        break;
      case 'delivered':
        statusText = 'has been delivered';
        break;
      case 'completed':
        statusText = 'is completed';
        break;
      default:
        statusText = 'updated';
    }

    await createNotification(
      userId: userId,
      title: 'Order Update',
      body: 'Your order $statusText',
      type: 'order',
      relatedId: orderId,
    );
  }

  // Harvest reminder
  Future<void> notifyHarvestReminder({
    required String userId,
    required String cooperativeName,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Harvest Reminder',
      body: 'Expected harvest date approaching for $cooperativeName',
      type: 'harvest',
    );
  }

  // Account verified
  Future<void> notifyAccountVerified({
    required String userId,
    required String userName,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Account Verified',
      body: 'Welcome $userName! Your account has been verified.',
      type: 'account',
    );
  }

  // Payment received
  Future<void> notifyPaymentReceived({
    required String userId,
    required double amount,
    required String orderId,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Payment Received',
      body: 'You received ${amount.round()} RWF',
      type: 'payment',
      relatedId: orderId,
    );
  }
}
