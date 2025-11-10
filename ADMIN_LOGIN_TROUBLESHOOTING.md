# Admin Login Troubleshooting Guide

## Your Admin Account Details
- Email: nishimweclaire34@gmail.com
- UID: 8yZItuBhPregJ3ji7f0BWPzF1RM2

## Checklist to Fix Login Issues

### 1. Verify Firestore Document
**Go to**: Firebase Console → Firestore Database → admins collection

**Should see**:
```
Document ID: nishimweclaire34@gmail.com

Fields:
- email (string): "nishimweclaire34@gmail.com"
- name (string): "Claire Nishimwe"
- role (string): "super_admin"
- isActive (boolean): true  ← MUST BE TRUE!
- permissions (array): 
  - "verify_users"
  - "manage_users"
  - "view_reports"
```

**If missing**: Create it now!

---

### 2. Verify Authentication Account
**Go to**: Firebase Console → Authentication → Users

**Should see**:
- Email: nishimweclaire34@gmail.com
- UID: 8yZItuBhPregJ3ji7f0BWPzF1RM2
- Status: Enabled (not disabled)

---

### 3. Common Issues

#### Issue: "Access denied"
**Cause**: Document not in `/admins` collection OR `isActive` is false
**Fix**: 
1. Check Firestore `/admins/nishimweclaire34@gmail.com` exists
2. Set `isActive: true`

#### Issue: "Incorrect password"
**Cause**: Wrong password
**Fix**: Use the password you just set via reset email

#### Issue: App doesn't recognize admin
**Cause**: Email mismatch between Firestore and login
**Fix**: 
1. Make sure Firestore document ID is EXACTLY: nishimweclaire34@gmail.com
2. Type email carefully when logging in (no typos!)

---

### 4. Test Login

**Credentials**:
```
Email: nishimweclaire34@gmail.com
Password: [Your new password from reset email]
```

**Steps**:
1. Open app
2. Click "Admin Login"
3. Enter email (copy-paste to avoid typos!)
4. Enter password
5. Click "Login as Admin"

---

### 5. Still Not Working?

**Check Browser Console**:
1. Press F12 (DevTools)
2. Go to Console tab
3. Try logging in
4. Look for error messages
5. Share the error with me!

---

### 6. Nuclear Option - Start Fresh

If nothing works, let's create a clean admin account:

1. **Delete old document**: Firestore → admins → nishimweclaire34@gmail.com → Delete
2. **Create new document**:
   - Document ID: `admin@itracelink.com`
   - Add all 5 fields (email, name, role, isActive, permissions)
3. **Create auth user**: Authentication → Add user
   - Email: admin@itracelink.com
   - Password: Admin123!
4. **Test login** with admin@itracelink.com / Admin123!
