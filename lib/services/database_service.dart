import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cooperative_model.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cooperatives
  Future<void> createCooperative(CooperativeModel cooperative) async {
    await _firestore
        .collection(AppConstants.cooperativesCollection)
        .doc(cooperative.id)
        .set(cooperative.toMap());
  }

  Future<CooperativeModel?> getCooperative(String id) async {
    final doc = await _firestore
        .collection(AppConstants.cooperativesCollection)
        .doc(id)
        .get();
    
    if (doc.exists) {
      return CooperativeModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<CooperativeModel>> getAvailableCooperatives({
    String? district,
    double? minQuantity,
  }) {
    Query query = _firestore
        .collection(AppConstants.cooperativesCollection)
        .where('availableForSale', isEqualTo: true);

    if (district != null) {
      query = query.where('location.district', isEqualTo: district);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => CooperativeModel.fromFirestore(doc))
        .where((coop) => 
            minQuantity == null || 
            (coop.harvestInfo?.actualQuantity ?? 0) >= minQuantity)
        .toList());
  }

  // Orders
  Future<String> createOrder(OrderModel order) async {
    final docRef = await _firestore
        .collection(AppConstants.ordersCollection)
        .add(order.toMap());
    return docRef.id;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({'status': status});
  }

  Stream<List<OrderModel>> getUserOrders(String userId, {bool isBuyer = true}) {
    final field = isBuyer ? 'buyerId' : 'sellerId';
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where(field, isEqualTo: userId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  // Notifications
  Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }
}
