# Admin System Setup Guide

## Creating Admin Accounts

### Method 1: Via Firebase Console (Quick Setup)

1. **Go to Firebase Console** → Firestore Database
2. **Create a new collection:** `admins`
3. **Add a document** with your admin email:

```
Collection: admins
Document ID: your-email@domain.com (use your actual email)

Fields:
- email: "youremail@example.com"
- role: "super_admin"
- name: "Your Name"
- createdAt: (timestamp - use server timestamp)
- isActive: true
- permissions: (array)
  - "verify_users"
  - "manage_users"
  - "view_reports"
  - "manage_orders"
```

4. **Create an Authentication account:**
   - Firebase Console → Authentication
   - Add user with same email
   - Set a strong password

### Method 2: Via Script (Automated)

Run this in Firebase Console's Firestore Rules Playground or create a Cloud Function:

```javascript
// Add to Firestore
db.collection('admins').doc('admin@itracelink.com').set({
  email: 'admin@itracelink.com',
  role: 'super_admin',
  name: 'Admin User',
  createdAt: firebase.firestore.FieldValue.serverTimestamp(),
  isActive: true,
  permissions: [
    'verify_users',
    'manage_users', 
    'view_reports',
    'manage_orders'
  ]
});
```

## Admin Roles

### Super Admin
- Full system access
- Can create other admins
- Verify all user types
- Access all reports

### Regional Admin
- Verify users in specific districts
- Limited reporting access

### Support Admin
- View-only access
- Cannot verify users
- Can view user profiles

## Security Rules

Update Firestore security rules to protect admin collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin collection - only admins can read/write
    match /admins/{email} {
      allow read: if request.auth != null && 
                     exists(/databases/$(database)/documents/admins/$(request.auth.token.email));
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/admins/$(request.auth.token.email)).data.role == 'super_admin';
    }
    
    // Users collection - admins can read all, users can only read their own
    match /users/{userId} {
      allow read: if request.auth != null && 
                     (request.auth.uid == userId || 
                      exists(/databases/$(database)/documents/admins/$(request.auth.token.email)));
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## Next Steps

1. Create your first admin account using Method 1
2. Build admin web portal (see ADMIN_PORTAL_DEVELOPMENT.md)
3. Implement user verification workflow
4. Add audit logging
