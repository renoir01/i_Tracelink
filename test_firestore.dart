import 'package:cloud_firestore/cloud_firestore.dart';

/// Quick test to verify Firestore connection and admin document
Future<void> testFirestoreAdminDocument() async {
  print('\n=== FIRESTORE ADMIN DOCUMENT TEST ===\n');
  
  final email = 'r.kaze@alustudent.com';
  
  try {
    // Test 1: List all documents in admins collection
    print('📋 Listing all documents in admins collection:');
    final snapshot = await FirebaseFirestore.instance
        .collection('admins')
        .get();
    
    print('   Total documents: ${snapshot.docs.length}');
    for (var doc in snapshot.docs) {
      print('   - Document ID: "${doc.id}"');
      print('     Data: ${doc.data()}');
    }
    
    print('\n');
    
    // Test 2: Try to get specific document
    print('🔍 Looking for document with ID: $email');
    final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(email)
        .get();
    
    if (adminDoc.exists) {
      print('   ✅ Document EXISTS!');
      print('   📊 Data: ${adminDoc.data()}');
      print('   ✅ isActive: ${adminDoc.data()?['isActive']}');
    } else {
      print('   ❌ Document DOES NOT EXIST!');
      print('   💡 Available document IDs in admins collection:');
      for (var doc in snapshot.docs) {
        print('      - "${doc.id}"');
        // Check if it's similar to what we're looking for
        if (doc.id.contains('kaze') || doc.id.contains('alustudent')) {
          print('        ⚠️  This looks similar! Is this what you meant?');
        }
      }
    }
    
  } catch (e) {
    print('❌ ERROR: $e');
  }
  
  print('\n=== TEST COMPLETE ===\n');
}
