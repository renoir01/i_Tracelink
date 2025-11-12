import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seed_producer_model.dart';
import '../models/agro_dealer_model.dart';
import '../models/cooperative_model.dart';
import '../models/aggregator_model.dart';
import '../models/institution_model.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/seed_batch_model.dart';
import '../models/payment_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== SEED PRODUCERS ==========
  
  Future<String> createSeedProducer(SeedProducerModel producer) async {
    final docRef = await _firestore
        .collection(AppConstants.seedProducersCollection)
        .add(producer.toMap());
    return docRef.id;
  }

  Future<SeedProducerModel?> getSeedProducer(String id) async {
    final doc = await _firestore
        .collection(AppConstants.seedProducersCollection)
        .doc(id)
        .get();
    
    if (doc.exists) {
      return SeedProducerModel.fromFirestore(doc);
    }
    return null;
  }

  Future<SeedProducerModel?> getSeedProducerByUserId(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.seedProducersCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return SeedProducerModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Stream<List<SeedProducerModel>> getAllSeedProducers() {
    return _firestore
        .collection(AppConstants.seedProducersCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SeedProducerModel.fromFirestore(doc))
            .toList());
  }

  // ========== AGRO-DEALERS ==========

  Future<String> createAgroDealer(AgroDealerModel dealer) async {
    final docRef = await _firestore
        .collection(AppConstants.agroDealersCollection)
        .add(dealer.toMap());
    return docRef.id;
  }

  Future<AgroDealerModel?> getAgroDealer(String id) async {
    final doc = await _firestore
        .collection(AppConstants.agroDealersCollection)
        .doc(id)
        .get();
    
    if (doc.exists) {
      return AgroDealerModel.fromFirestore(doc);
    }
    return null;
  }

  Future<AgroDealerModel?> getAgroDealerByUserId(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.agroDealersCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return AgroDealerModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Stream<List<AgroDealerModel>> getAllAgroDealers() {
    return _firestore
        .collection(AppConstants.agroDealersCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AgroDealerModel.fromFirestore(doc))
            .toList());
  }

  Future<List<AgroDealerModel>> getAllAgroDealersOnce() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.agroDealersCollection)
          .where('isVerified', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => AgroDealerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get agro-dealers: $e');
    }
  }

  Future<List<CooperativeModel>> getAllCooperativesOnce() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.cooperativesCollection)
          .get();

      return snapshot.docs
          .map((doc) => CooperativeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get cooperatives: $e');
    }
  }

  Future<List<AggregatorModel>> getAllAggregatorsOnce() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.aggregatorsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => AggregatorModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get aggregators: $e');
    }
  }

  Future<void> updateAgroDealerInventory(
    String dealerId,
    List<SeedInventory> inventory,
  ) async {
    await _firestore
        .collection(AppConstants.agroDealersCollection)
        .doc(dealerId)
        .update({
      'inventory': inventory.map((i) => i.toMap()).toList(),
    });
  }

  // ========== COOPERATIVES ==========
  
  Future<String> createCooperative(CooperativeModel cooperative) async {
    final docRef = await _firestore
        .collection(AppConstants.cooperativesCollection)
        .add(cooperative.toMap());
    return docRef.id;
  }

  Future<void> updateCooperative(CooperativeModel cooperative) async {
    await _firestore
        .collection(AppConstants.cooperativesCollection)
        .doc(cooperative.id)
        .update(cooperative.toMap());
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

  Future<CooperativeModel?> getCooperativeByUserId(String userId) async {
    final querySnapshot = await _firestore
        .collection(AppConstants.cooperativesCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      return CooperativeModel.fromFirestore(querySnapshot.docs.first);
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

  // ========== AGGREGATORS ==========

  Future<String> createAggregator(AggregatorModel aggregator) async {
    final docRef = await _firestore
        .collection(AppConstants.aggregatorsCollection)
        .add(aggregator.toMap());
    return docRef.id;
  }

  Future<AggregatorModel?> getAggregator(String id) async {
    final doc = await _firestore
        .collection(AppConstants.aggregatorsCollection)
        .doc(id)
        .get();
    
    if (doc.exists) {
      return AggregatorModel.fromFirestore(doc);
    }
    return null;
  }

  Future<AggregatorModel?> getAggregatorByUserId(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.aggregatorsCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return AggregatorModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Stream<List<AggregatorModel>> getAllAggregators() {
    return _firestore
        .collection(AppConstants.aggregatorsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AggregatorModel.fromFirestore(doc))
            .toList());
  }

  // ========== INSTITUTIONS ==========

  Future<String> createInstitution(InstitutionModel institution) async {
    final docRef = await _firestore
        .collection(AppConstants.institutionsCollection)
        .add(institution.toMap());
    return docRef.id;
  }

  Future<InstitutionModel?> getInstitution(String id) async {
    final doc = await _firestore
        .collection(AppConstants.institutionsCollection)
        .doc(id)
        .get();
    
    if (doc.exists) {
      return InstitutionModel.fromFirestore(doc);
    }
    return null;
  }

  Future<InstitutionModel?> getInstitutionByUserId(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.institutionsCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return InstitutionModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Stream<List<InstitutionModel>> getAllInstitutions() {
    return _firestore
        .collection(AppConstants.institutionsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InstitutionModel.fromFirestore(doc))
            .toList());
  }

  // ========== ORDERS ==========

  Future<String> createOrder(OrderModel order) async {
    final docRef = await _firestore
        .collection(AppConstants.ordersCollection)
        .add(order.toMap());
    return docRef.id;
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .get();
    
    if (doc.exists) {
      return OrderModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final Map<String, dynamic> updateData = {
      'status': status,
      'updatedAt': Timestamp.now(),
    };

    // Add timestamp for specific status
    switch (status) {
      case 'accepted':
        updateData['acceptedAt'] = Timestamp.now();
        break;
      case 'rejected':
        updateData['rejectedAt'] = Timestamp.now();
        break;
      case 'preparing':
        updateData['preparingAt'] = Timestamp.now();
        break;
      case 'shipped':
        updateData['shippedAt'] = Timestamp.now();
        break;
      case 'collected':
        updateData['collectedAt'] = Timestamp.now();
        break;
      case 'in_transit':
        updateData['inTransitAt'] = Timestamp.now();
        break;
      case 'delivered':
        updateData['deliveredAt'] = Timestamp.now();
        break;
      case 'completed':
        updateData['completedAt'] = Timestamp.now();
        break;
    }

    await _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update(updateData);
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

  // ========== NOTIFICATIONS ==========

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

  // ========== PROFILE COMPLETION CHECK ==========

  Future<bool> hasCompletedProfile(String userId, String userType) async {
    String collection = '';
    
    switch (userType) {
      case AppConstants.seedProducerType:
        collection = AppConstants.seedProducersCollection;
        break;
      case AppConstants.agroDealerType:
        collection = AppConstants.agroDealersCollection;
        break;
      case AppConstants.farmerType:
        collection = AppConstants.cooperativesCollection;
        break;
      case AppConstants.aggregatorType:
        collection = AppConstants.aggregatorsCollection;
        break;
      case AppConstants.institutionType:
        collection = AppConstants.institutionsCollection;
        break;
      default:
        return false;
    }

    final snapshot = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Traceability Methods
  Future<Map<String, dynamic>?> getTraceabilityByBatch(String batchNumber) async {
    try {
      // Find the batch in seed dealer inventory or transactions
      final inventorySnapshot = await _firestore
          .collection(AppConstants.agroDealersCollection)
          .where('inventory', arrayContains: {
            'batchNumber': batchNumber
          })
          .limit(1)
          .get();

      if (inventorySnapshot.docs.isEmpty) {
        return null;
      }

      final dealerDoc = inventorySnapshot.docs.first;
      final dealerData = dealerDoc.data();

      // Build traceability chain
      final chain = <Map<String, dynamic>>[];

      // 1. Seed Producer
      final seedProducerId = dealerData['seedProducer'];
      if (seedProducerId != null) {
        final producerDoc = await _firestore
            .collection(AppConstants.seedProducersCollection)
            .doc(seedProducerId)
            .get();

        if (producerDoc.exists) {
          final producerData = producerDoc.data()!;
          chain.add({
            'actorType': 'seed_producer',
            'actorName': producerData['organizationName'] ?? 'Unknown Producer',
            'date': DateTime.now().toString().split('T')[0], // Would need actual date
            'location': producerData['location']?['district'] ?? 'Unknown',
          });
        }
      }

      // 2. Agro-Dealer
      chain.add({
        'actorType': 'agro_dealer',
        'actorName': dealerData['businessName'] ?? 'Unknown Dealer',
        'date': DateTime.now().toString().split('T')[0],
        'location': '${dealerData['location']?['district'] ?? 'Unknown'}, ${dealerData['location']?['sector'] ?? ''}',
      });

      // Find farmer who purchased this batch
      final transactionsSnapshot = await _firestore
          .collection(AppConstants.transactionsCollection)
          .where('batchNumber', isEqualTo: batchNumber)
          .where('type', isEqualTo: AppConstants.seedSaleType)
          .limit(1)
          .get();

      if (transactionsSnapshot.docs.isNotEmpty) {
        final transaction = transactionsSnapshot.docs.first.data();
        final farmerId = transaction['toActor'];

        final farmerDoc = await _firestore
            .collection(AppConstants.cooperativesCollection)
            .doc(farmerId)
            .get();

        if (farmerDoc.exists) {
          final farmerData = farmerDoc.data()!;
          chain.add({
            'actorType': 'farmer',
            'actorName': farmerData['cooperativeName'] ?? 'Unknown Cooperative',
            'date': (transaction['date'] as Timestamp?)?.toDate().toString().split('T')[0] ?? DateTime.now().toString().split('T')[0],
            'location': '${farmerData['location']?['district'] ?? 'Unknown'}, ${farmerData['location']?['sector'] ?? ''}',
          });
        }
      }

      return {
        'chain': chain,
        'batchNumber': batchNumber,
        'variety': 'RWR 2245', // Would be dynamic
        'quantity': '2500', // Would be dynamic
        'quality': 'Grade A',
      };
    } catch (e) {
      print('Error getting traceability by batch: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTraceabilityByOrder(String orderId) async {
    try {
      final orderDoc = await _firestore
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        return null;
      }

      final orderData = orderDoc.data()!;
      final chain = <Map<String, dynamic>>[];

      // Get seller and buyer info
      final sellerDoc = await _firestore
          .collection(orderData['sellerType'] == 'aggregator' ? AppConstants.aggregatorsCollection : AppConstants.cooperativesCollection)
          .doc(orderData['sellerId'])
          .get();

      final buyerDoc = await _firestore
          .collection(orderData['buyerType'] == 'aggregator' ? AppConstants.aggregatorsCollection : AppConstants.institutionsCollection)
          .doc(orderData['buyerId'])
          .get();

      if (sellerDoc.exists) {
        final sellerData = sellerDoc.data()!;
        chain.add({
          'actorType': orderData['sellerType'] == 'aggregator' ? 'aggregator' : 'farmer',
          'actorName': sellerData['businessName'] ?? sellerData['cooperativeName'] ?? 'Unknown',
          'date': (orderData['createdAt'] as Timestamp?)?.toDate().toString().split('T')[0] ?? DateTime.now().toString().split('T')[0],
          'location': sellerData['location']?['district'] ?? 'Unknown',
        });
      }

      if (buyerDoc.exists) {
        final buyerData = buyerDoc.data()!;
        chain.add({
          'actorType': orderData['buyerType'] == 'aggregator' ? 'aggregator' : 'institution',
          'actorName': buyerData['businessName'] ?? buyerData['institutionName'] ?? 'Unknown',
          'date': DateTime.now().toString().split('T')[0],
          'location': buyerData['location']?['district'] ?? 'Unknown',
        });
      }

      return {
        'chain': chain,
        'orderId': orderId,
        'quantity': orderData['quantity']?.toString() ?? '0',
        'variety': 'RWR 2245',
        'quality': 'Grade A',
      };
    } catch (e) {
      print('Error getting traceability by order: $e');
      return null;
    }
  }

  // ========== SEED BATCH MANAGEMENT ==========

  Future<String> addSeedBatch(SeedBatchModel batch) async {
    try {
      final docRef = await _firestore.collection('seed_batches').add(batch.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add seed batch: $e');
    }
  }

  Future<List<SeedBatchModel>> getSeedBatchesByProducer(String producerId) async {
    try {
      final snapshot = await _firestore
          .collection('seed_batches')
          .where('producerId', isEqualTo: producerId)
          .get();

      final batches = snapshot.docs.map((doc) {
        return SeedBatchModel.fromMap(doc.id, doc.data());
      }).toList();

      // Sort in memory to avoid needing a composite index
      batches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return batches;
    } catch (e) {
      throw Exception('Failed to get seed batches: $e');
    }
  }

  Future<void> updateSeedBatch(String batchId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('seed_batches').doc(batchId).update(updates);
    } catch (e) {
      throw Exception('Failed to update seed batch: $e');
    }
  }

  Future<void> deleteSeedBatch(String batchId) async {
    try {
      await _firestore.collection('seed_batches').doc(batchId).delete();
    } catch (e) {
      throw Exception('Failed to delete seed batch: $e');
    }
  }

  Future<SeedBatchModel?> getSeedBatchById(String batchId) async {
    try {
      final doc = await _firestore.collection('seed_batches').doc(batchId).get();
      if (doc.exists) {
        return SeedBatchModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get seed batch: $e');
    }
  }

  // Get seed batches by variety for analytics
  Future<List<SeedBatchModel>> getSeedBatchesByVariety(String producerId, String variety) async {
    try {
      final snapshot = await _firestore
          .collection('seed_batches')
          .where('producerId', isEqualTo: producerId)
          .where('variety', isEqualTo: variety)
          .get();

      return snapshot.docs.map((doc) {
        return SeedBatchModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get seed batches by variety: $e');
    }
  }

  // Get low stock alerts
  Future<List<SeedBatchModel>> getLowStockBatches(String producerId) async {
    try {
      final snapshot = await _firestore
          .collection('seed_batches')
          .where('producerId', isEqualTo: producerId)
          .where('quantity', isLessThan: 100)
          .get();

      return snapshot.docs.map((doc) {
        return SeedBatchModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get low stock batches: $e');
    }
  }

  // Get expiring batches (within 30 days)
  Future<List<SeedBatchModel>> getExpiringBatches(String producerId) async {
    try {
      final thirtyDaysFromNow = DateTime.now().add(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('seed_batches')
          .where('producerId', isEqualTo: producerId)
          .where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysFromNow))
          .get();

      return snapshot.docs.map((doc) {
        return SeedBatchModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get expiring batches: $e');
    }
  }

  // ========== USER MANAGEMENT METHODS ==========

  // Get all users for admin panel
  Future<List<UserModel>> getAllUsers() async {
    try {
      final collections = [
        AppConstants.seedProducersCollection,
        AppConstants.agroDealersCollection,
        AppConstants.cooperativesCollection,
        AppConstants.aggregatorsCollection,
        AppConstants.institutionsCollection,
      ];

      List<UserModel> allUsers = [];

      for (String collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final userModel = UserModel.fromFirestore(doc);
          allUsers.add(userModel);
        }
      }

      // Sort by creation date (newest first)
      allUsers.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.now();
        final bDate = b.createdAt ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      return allUsers;
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  String _getUserTypeFromCollection(String collection) {
    switch (collection) {
      case AppConstants.seedProducersCollection:
        return AppConstants.seedProducerType;
      case AppConstants.agroDealersCollection:
        return AppConstants.agroDealerType;
      case AppConstants.cooperativesCollection:
        return AppConstants.cooperativeType;
      case AppConstants.aggregatorsCollection:
        return AppConstants.aggregatorType;
      case AppConstants.institutionsCollection:
        return AppConstants.institutionType;
      default:
        return 'unknown';
    }
  }

  // Verify user account
  Future<void> verifyUser(String userId) async {
    try {
      // Find which collection the user belongs to
      final collections = [
        AppConstants.seedProducersCollection,
        AppConstants.agroDealersCollection,
        AppConstants.cooperativesCollection,
        AppConstants.aggregatorsCollection,
        AppConstants.institutionsCollection,
      ];

      for (String collection in collections) {
        final docRef = _firestore.collection(collection).doc(userId);
        final doc = await docRef.get();

        if (doc.exists) {
          await docRef.update({
            'isVerified': true,
            'status': 'active',
            'verifiedAt': Timestamp.now(),
          });
          break;
        }
      }
    } catch (e) {
      throw Exception('Failed to verify user: $e');
    }
  }

  // Reject user account
  Future<void> rejectUser(String userId, String reason) async {
    try {
      // Find which collection the user belongs to
      final collections = [
        AppConstants.seedProducersCollection,
        AppConstants.agroDealersCollection,
        AppConstants.cooperativesCollection,
        AppConstants.aggregatorsCollection,
        AppConstants.institutionsCollection,
      ];

      for (String collection in collections) {
        final docRef = _firestore.collection(collection).doc(userId);
        final doc = await docRef.get();

        if (doc.exists) {
          await docRef.update({
            'isVerified': false,
            'status': 'rejected',
            'rejectionReason': reason,
            'rejectedAt': Timestamp.now(),
          });
          break;
        }
      }
    } catch (e) {
      throw Exception('Failed to reject user: $e');
    }
  }

  // Delete user account
  Future<void> deleteUser(String userId) async {
    try {
      // Find which collection the user belongs to and delete from there
      final collections = [
        AppConstants.seedProducersCollection,
        AppConstants.agroDealersCollection,
        AppConstants.cooperativesCollection,
        AppConstants.aggregatorsCollection,
        AppConstants.institutionsCollection,
      ];

      for (String collection in collections) {
        final docRef = _firestore.collection(collection).doc(userId);
        final doc = await docRef.get();

        if (doc.exists) {
          await docRef.delete();
          break;
        }
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // Get user by ID from any collection
  Future<UserModel?> getUserById(String userId) async {
    try {
      final collections = [
        AppConstants.seedProducersCollection,
        AppConstants.agroDealersCollection,
        AppConstants.cooperativesCollection,
        AppConstants.aggregatorsCollection,
        AppConstants.institutionsCollection,
      ];

      for (String collection in collections) {
        final doc = await _firestore.collection(collection).doc(userId).get();
        
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Get user statistics for dashboard
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final collections = [
        AppConstants.seedProducersCollection,
        AppConstants.agroDealersCollection,
        AppConstants.cooperativesCollection,
        AppConstants.aggregatorsCollection,
        AppConstants.institutionsCollection,
      ];

      int totalUsers = 0;
      int verifiedUsers = 0;
      int pendingUsers = 0;

      for (String collection in collections) {
        final snapshot = await _firestore.collection(collection).get();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          totalUsers++;

          final isVerified = data['isVerified'] ?? false;
          if (isVerified) {
            verifiedUsers++;
          } else {
            pendingUsers++;
          }
        }
      }

      return {
        'total': totalUsers,
        'verified': verifiedUsers,
        'pending': pendingUsers,
      };
    } catch (e) {
      throw Exception('Failed to get user statistics: $e');
    }
  }

  // ========== PAYMENT MANAGEMENT ==========

  Future<String> createPayment(PaymentModel payment) async {
    try {
      final docRef = await _firestore.collection('payments').add(payment.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  Future<void> updatePaymentStatus(String paymentId, PaymentStatus status, [DateTime? completedAt]) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toString(),
      };

      if (completedAt != null) {
        updates['completedAt'] = Timestamp.fromDate(completedAt);
      }

      if (status == PaymentStatus.failed) {
        updates['failureReason'] = 'Payment failed by provider';
      }

      await _firestore.collection('payments').doc(paymentId).update(updates);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      if (doc.exists) {
        return PaymentModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  Future<List<PaymentModel>> getPaymentsByOrder(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return PaymentModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get payments by order: $e');
    }
  }

  Future<List<PaymentModel>> getPaymentsByUser(String userId, {bool asPayer = true}) async {
    try {
      final field = asPayer ? 'payerId' : 'payeeId';
      final snapshot = await _firestore
          .collection('payments')
          .where(field, isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return PaymentModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      throw Exception('Failed to get payments by user: $e');
    }
  }

  Future<Map<String, dynamic>> getPaymentStatistics(String userId, {bool asPayer = true}) async {
    try {
      final payments = await getPaymentsByUser(userId, asPayer: asPayer);

      double totalAmount = 0;
      int completedPayments = 0;
      int failedPayments = 0;

      for (var payment in payments) {
        totalAmount += payment.amount;
        if (payment.isCompleted) completedPayments++;
        if (payment.isFailed) failedPayments++;
      }

      return {
        'totalPayments': payments.length,
        'totalAmount': totalAmount,
        'completedPayments': completedPayments,
        'failedPayments': failedPayments,
        'successRate': payments.isEmpty ? 0 : (completedPayments / payments.length) * 100,
      };
    } catch (e) {
      throw Exception('Failed to get payment statistics: $e');
    }
  }

  // Process payment webhook from mobile money providers
  Future<void> processPaymentWebhook(String transactionId, Map<String, dynamic> webhookData) async {
    try {
      // Find payment by transaction ID
      final paymentSnapshot = await _firestore
          .collection('payments')
          .where('transactionId', isEqualTo: transactionId)
          .limit(1)
          .get();

      if (paymentSnapshot.docs.isEmpty) {
        throw Exception('Payment not found for transaction: $transactionId');
      }

      final paymentDoc = paymentSnapshot.docs.first;
      final paymentData = paymentDoc.data();

      // Determine status from webhook
      PaymentStatus newStatus;
      final status = webhookData['status'] ?? webhookData['transaction']?['status'];

      if (status == 'SUCCESS' || status == 'SUCCESSFUL') {
        newStatus = PaymentStatus.completed;
      } else if (status == 'FAILED' || status == 'FAILURE') {
        newStatus = PaymentStatus.failed;
      } else {
        newStatus = PaymentStatus.pending;
      }

      // Update payment
      await paymentDoc.reference.update({
        'status': newStatus.toString(),
        'webhookData': webhookData,
        'completedAt': newStatus == PaymentStatus.completed ? Timestamp.now() : null,
        'externalTransactionId': webhookData['externalTransactionId'] ?? webhookData['transaction']?['id'],
      });

      // If payment completed, update order status
      if (newStatus == PaymentStatus.completed) {
        final orderId = paymentData['orderId'];
        if (orderId != null) {
          await _updateOrderStatus(orderId, AppConstants.orderPaid);
        }
      }
    } catch (e) {
      print('Webhook processing error: $e');
      throw Exception('Failed to process payment webhook: $e');
    }
  }

  // Update order status
  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection(AppConstants.ordersCollection).doc(orderId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}
