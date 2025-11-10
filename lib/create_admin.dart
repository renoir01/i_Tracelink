import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// One-time script to create admin document in Firestore
/// Run this once, then delete or comment out
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('\n🚀 Starting Admin Creation Script...\n');
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    return;
  }
  
  // Admin email - CHANGE THIS to your email if needed
  final adminEmail = 'r.kaze@alustudent.com';
  
  print('📝 Creating admin document for: $adminEmail\n');
  
  try {
    // Create admin document
    await FirebaseFirestore.instance
        .collection('admins')
        .doc(adminEmail)  // Document ID = email
        .set({
          'email': adminEmail,
          'name': 'Kaze Renoir',
          'role': 'super_admin',
          'isActive': true,
          'permissions': [
            'verify_users',
            'manage_users',
            'view_reports',
          ],
          'createdAt': FieldValue.serverTimestamp(),
        });
    
    print('✅ SUCCESS! Admin document created!\n');
    print('📋 Details:');
    print('   Collection: admins');
    print('   Document ID: $adminEmail');
    print('   Email: $adminEmail');
    print('   Name: Kaze Renoir');
    print('   Role: super_admin');
    print('   isActive: true');
    print('   Permissions: verify_users, manage_users, view_reports\n');
    
    // Verify it was created
    print('🔍 Verifying document exists...');
    final doc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(adminEmail)
        .get();
    
    if (doc.exists) {
      print('✅ VERIFIED! Document exists in Firestore!');
      print('📊 Document data: ${doc.data()}\n');
      
      print('🎉 ADMIN ACCOUNT READY!');
      print('\n📌 LOGIN CREDENTIALS:');
      print('   Email: $adminEmail');
      print('   Password: [Use the password you set in Firebase Authentication]');
      print('\n⚠️  IMPORTANT: Make sure you also created this email in Firebase Authentication!');
      print('   Go to: Firebase Console → Authentication → Users → Add user\n');
    } else {
      print('❌ ERROR: Document not found after creation!');
    }
    
  } catch (e) {
    print('❌ ERROR creating admin document: $e');
    print('\n💡 Common issues:');
    print('   - Check Firestore security rules');
    print('   - Make sure Firebase is properly initialized');
    print('   - Verify internet connection');
  }
  
  print('\n✅ Script complete!\n');
}
